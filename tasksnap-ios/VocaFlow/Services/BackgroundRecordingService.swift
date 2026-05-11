import Foundation
import AVFoundation

// Manages recording initiated from the Action Button intent.
// Runs entirely without the app's UI — Live Activity is the only visual feedback.
@MainActor
final class BackgroundRecordingService: ObservableObject {
    static let shared = BackgroundRecordingService()
    private init() {}

    @Published private(set) var isRecording = false

    private var engine: AVAudioEngine?
    private var audioFile: AVAudioFile?
    private var recordingURL: URL?

    // MARK: - Toggle (called from intent and from HomeView stop button)

    func toggle() async {
        if isRecording {
            await stopAndUpload()
        } else {
            start()
        }
    }

    // MARK: - Start

    private func start() {
        guard !isRecording else { return }

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
            audioFile    = file
            recordingURL = url
            engine       = newEngine

            // Tap runs on a real-time audio thread; capture file by value to be safe.
            input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
                try? file.write(from: buffer)
            }

            try newEngine.start()
            isRecording = true
            LiveActivityManager.shared.start()
        } catch {
            print("BackgroundRecordingService start error:", error)
            cleanup()
        }
    }

    // MARK: - Stop + upload

    func stopAndUpload() async {
        guard isRecording else { return }
        cleanup()
        LiveActivityManager.shared.stop()

        guard let url = recordingURL else { return }
        recordingURL = nil

        do {
            let data = try Data(contentsOf: url)
            try await SupabaseService.shared.captureTask(audioData: data)
            try? FileManager.default.removeItem(at: url)
        } catch {
            print("BackgroundRecordingService upload error:", error)
        }
    }

    // MARK: - Helpers

    private func cleanup() {
        engine?.inputNode.removeTap(onBus: 0)
        engine?.stop()
        engine    = nil
        audioFile = nil
        isRecording = false
    }
}
