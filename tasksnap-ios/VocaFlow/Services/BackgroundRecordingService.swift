import Foundation
import AVFoundation

@MainActor
final class BackgroundRecordingService: ObservableObject {
    static let shared = BackgroundRecordingService()

    private init() {
        isRecording = Self.readState() != nil
    }

    @Published private(set) var isRecording = false

    private var engine: AVAudioEngine?
    private var audioFile: AVAudioFile?
    private var recordingURL: URL?

    // MARK: - App Group shared container

    private static let groupID = "group.io.vocaflow.app"

    private struct RecordingState: Codable {
        let recordingPath: String
    }

    private static var stateFileURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: groupID)?
            .appendingPathComponent("vocaflow_recording_state.json")
    }

    private static func newRecordingURL() -> URL {
        let dir = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: groupID)
            ?? FileManager.default.temporaryDirectory
        return dir.appendingPathComponent("vf_bg_\(Int(Date().timeIntervalSince1970)).m4a")
    }

    private static func readState() -> RecordingState? {
        guard let url = stateFileURL,
              FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(RecordingState.self, from: data)
    }

    private static func writeState(_ state: RecordingState) {
        guard let url = stateFileURL,
              let data = try? JSONEncoder().encode(state) else { return }
        try? data.write(to: url, options: .atomic)
    }

    private static func deleteState() {
        guard let url = stateFileURL else { return }
        try? FileManager.default.removeItem(at: url)
    }

    // MARK: - Public API

    /// Called by StartRecordingIntent. No-op if recording is already in progress
    /// (the Send button in the Live Activity handles stopping).
    func startIfNotRecording() {
        guard Self.readState() == nil else { return }
        start()
    }

    /// Called by StopRecordingIntent (from the Live Activity Send button)
    /// and by HomeView's "Stop & Send" button.
    func stopAndUpload() async {
        let url = recordingURL
            ?? Self.readState().map { URL(fileURLWithPath: $0.recordingPath) }

        teardownEngine()
        Self.deleteState()
        recordingURL = nil
        isRecording  = false

        LiveActivityManager.shared.setAnalyzing()

        guard let url else {
            LiveActivityManager.shared.complete()
            return
        }

        do {
            let data = try Data(contentsOf: url)
            try await SupabaseService.shared.captureTask(audioData: data)
            try? FileManager.default.removeItem(at: url)
        } catch {
            print("BackgroundRecordingService upload error:", error)
        }

        LiveActivityManager.shared.complete()
    }

    // MARK: - Private

    private func start() {
        let newEngine = AVAudioEngine()
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .measurement,
                                   options: [.defaultToSpeaker, .allowBluetoothHFP])
            try session.setActive(true)

            let input  = newEngine.inputNode
            let format = input.outputFormat(forBus: 0)
            let url    = Self.newRecordingURL()

            let settings: [String: Any] = [
                AVFormatIDKey:            kAudioFormatMPEG4AAC,
                AVSampleRateKey:          format.sampleRate,
                AVNumberOfChannelsKey:    1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]

            let file = try AVAudioFile(forWriting: url, settings: settings)
            Self.writeState(RecordingState(recordingPath: url.path))

            audioFile    = file
            recordingURL = url
            engine       = newEngine

            input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
                try? file.write(from: buffer)
            }

            try newEngine.start()
            isRecording = true
            LiveActivityManager.shared.start()
        } catch {
            print("BackgroundRecordingService start error:", error)
            Self.deleteState()
            teardownEngine()
        }
    }

    private func teardownEngine() {
        engine?.inputNode.removeTap(onBus: 0)
        engine?.stop()
        engine    = nil
        audioFile = nil
    }
}
