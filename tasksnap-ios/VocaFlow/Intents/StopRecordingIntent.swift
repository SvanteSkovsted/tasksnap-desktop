import AppIntents

// Included in both the main app target and VocaFlowActivity widget extension.
//
// The widget extension needs this type to compile Button(intent: StopRecordingIntent()).
// At runtime, App Intents always execute in the main app's process — the extension
// process never runs perform() — so the #if guard below prevents a link error
// in the extension without affecting runtime behaviour.
@available(iOS 17.0, *)
struct StopRecordingIntent: AppIntent {
    static var title: LocalizedStringResource = "Stop VocaFlow Recording"
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult {
        #if APP_TARGET
        await BackgroundRecordingService.shared.stopAndUpload()
        #endif
        return .result()
    }
}
