import AppIntents

@available(iOS 17.0, *)
struct ToggleRecordingIntent: AppIntent {
    static var title: LocalizedStringResource = "Start VocaFlow Recording"
    // Opens the app so the recording UI is visible and the user can tap Stop & Send.
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        UserDefaults.standard.set(true, forKey: "vocaflow.autoStart")
        return .result()
    }
}
