import Foundation
import AVFoundation

// Manages recording initiated from the Action Button intent.
// State is persisted to UserDefaults so a second intent invocation works even if
// the process was suspended and relaunched between the two Action Button presses.
@MainActor
final class BackgroundRecordingService: ObservableObject {
    static let shared = BackgroundRecordingService()
    private init() {
        // Restore in-memory flag from persisted state on cold launch.
        isRecording = UserDefaults.standard.bool(forKey: Keys.isRecording)
    }

    @Published private(set) var isRecording = false

    private enum Keys {
        static let isRecording   = "vocaflow.bg.isRecording"
        static let recordingPath = "vocaflow.bg.recordingPath"
    }

    private var engine: AVAudioEngine?
    private var audioFile: AVAudioFile?
    // In-memory URL; the path is also persisted so we can recover it after a relaunch.
    private var recordingURL: URL?

    // MARK: - Toggle (single entry point from the intent)

    func toggle() async {
        // Check persisted state — not just in-memory — so the second press works
        // even if the process was suspended and relaunched between presses.
        if UserDefaults.standard.bool(forKey: Keys.isRecording) {
            await stopAndUpload()
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

            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("vf_bg_\(Int(Date().timeIntervalSince1970)).m4a")

            let settings: [String: Any] = [
                AVFormatIDKey:            kAudioFormatMPEG4AAC,
                AVSampleRateKey:          format.sampleRate,
                AVNumberOfChannelsKey:    1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]

            let file = try AVAudioFile(forWriting: url, settings: settings)

            // Persist BEFORE starting so state is correct if the tap fires immediately.
            UserDefaults.standard.set(url.path, forKey: Keys.recordingPath)
            UserDefaults.standard.set(true, forKey: Keys.isRecording)

            audioFile    = file
            recordingURL = url
            engine       = newEngine

            // The tap closure captures `file` by value to avoid a data race; the
            // write happens on a real-time audio thread.
            input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
                try? file.write(from: buffer)
            }

            try newEngine.start()
            isRecording = true
            LiveActivityManager.shared.start()
        } catch {
            print("BackgroundRecordingService start error:", error)
            // Roll back persisted state if setup failed.
            UserDefaults.standard.removeObject(forKey: Keys.isRecording)
            UserDefaults.standard.removeObject(forKey: Keys.recordingPath)
            teardownEngine()
        }
    }

    // MARK: - Stop + upload

    func stopAndUpload() async {
        // Resolve URL from memory first, fall back to persisted path (process relaunch case).
        let url = recordingURL
            ?? UserDefaults.standard.string(forKey: Keys.recordingPath)
                .map { URL(fileURLWithPath: $0) }

        teardownEngine()

        // Clear persisted state immediately so a race-condition third press doesn't
        // try to upload the same file twice.
        UserDefaults.standard.removeObject(forKey: Keys.isRecording)
        UserDefaults.standard.removeObject(forKey: Keys.recordingPath)
        recordingURL = nil
        isRecording  = false

        // Transition Dynamic Island to "analyzing" while we upload.
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

        // Show checkmark in Dynamic Island regardless of upload outcome,
        // then auto-dismiss after 3 s.
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
