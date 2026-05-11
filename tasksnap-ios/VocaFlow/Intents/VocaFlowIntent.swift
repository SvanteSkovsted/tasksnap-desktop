import AppIntents

// Start-only intent — stopping is handled by the Send button in the Live Activity.
struct StartRecordingIntent: AppIntent {
    static var title: LocalizedStringResource = "Start VocaFlow Recording"
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult {
        await BackgroundRecordingService.shared.startIfNotRecording()
        return .result()
    }
}
