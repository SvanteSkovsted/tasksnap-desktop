import AppIntents

// No AppShortcutsProvider — avoids AppIntentsSSUTraining phrase-extraction failures.
// The intent still appears in Settings → Action Button and the Shortcuts app.

struct ToggleRecordingIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle VocaFlow Recording"

    // false = recording starts/stops without opening the app.
    // UIBackgroundModes:audio in Info.plist keeps the process alive while recording.
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult {
        await BackgroundRecordingService.shared.toggle()
        return .result()
    }
}
