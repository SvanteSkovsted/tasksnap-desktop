import Foundation
import AVFoundation

// Manages recording initiated from the Action Button intent.
//
// iOS may spawn a fresh process for the second intent invocation, so in-memory
// state is unreliable. A JSON state file written to the App Group shared
// container persists across process boundaries — the file's existence means
// "recording is in progress" and it carries the path to the audio file.
@MainActor
final class BackgroundRecordingService: ObservableObject {
    static let shared = BackgroundRecordingService()

    private init() {
        // Restore flag from the group container on cold launch.
        isRecording = Self.readState() != nil
    }

    @Published private(set) var isRecording = false

    private var engine: AVAudioEngine?
    private var audioFile: AVAudioFile?
    private var recordingURL: URL?

    // MARK: - App Group container

    private static let groupID = "group.io.vocaflow.app"

    private struct RecordingState: Codable {
        let recordingPath: String
    }

    /// URL of the state sentinel file in the shared container.
    private static var stateFileURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: groupID)?
            .appendingPathComponent("vocaflow_recording_state.json")
    }

    /// URL for the audio recording file in the shared container.
    private static func newRecordingURL() -> URL {
        let container = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: groupID)
        let dir = container ?? FileManager.default.temporaryDirectory
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

    // MARK: - Toggle (single entry point from the intent)

    func toggle() async {
        if let state = Self.readState() {
            // State file exists → recording is in progress, stop it.
            // Recover the URL from the file in case this is a fresh process.
            let url = recordingURL ?? URL(fileURLWithPath: state.recordingPath)
            await stopAndUpload(url: url)
        } else {
            start()
        }
    }

    // MARK: - Start

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

            // Write state file before the tap fires so the second press always
            // sees the "recording in progress" sentinel.
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

    // MARK: - Stop + upload

    func stopAndUpload() async {
        let url = recordingURL ?? Self.readState().map { URL(fileURLWithPath: $0.recordingPath) }
        await stopAndUpload(url: url)
    }

    private func stopAndUpload(url: URL?) async {
        teardownEngine()

        // Delete state file immediately — any further press will start a new recording.
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

    // MARK: - Engine teardown

    private func teardownEngine() {
        engine?.inputNode.removeTap(onBus: 0)
        engine?.stop()
        engine    = nil
        audioFile = nil
    }
}
