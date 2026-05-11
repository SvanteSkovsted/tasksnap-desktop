import Foundation

@MainActor
final class RecordingTrigger: ObservableObject {
    static let shared = RecordingTrigger()
    nonisolated static let userDefaultsKey = "vocaflow.pendingRecording"

    private init() {}

    @Published var pendingStart = false

    /// Called when the app foregrounds — picks up any flag written by the intent.
    func checkUserDefaults() {
        guard UserDefaults.standard.bool(forKey: Self.userDefaultsKey) else { return }
        UserDefaults.standard.set(false, forKey: Self.userDefaultsKey)
        pendingStart = true
    }

    func consume() {
        pendingStart = false
    }
}
