import AppIntents

// Named ToggleRecordingIntent for backwards compatibility with existing
// Action Button assignments. Behaviour is now start-only — stopping is
// handled by the Send button embedded in the Live Activity.
@available(iOS 17.0, *)
struct ToggleRecordingIntent: AppIntent {
    static var title: LocalizedStringResource = "Start VocaFlow Recording"
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult {
        await BackgroundRecordingService.shared.startIfNotRecording()
        return .result()
    }
}
