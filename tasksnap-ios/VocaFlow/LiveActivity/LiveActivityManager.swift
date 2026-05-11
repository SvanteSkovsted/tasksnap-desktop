import ActivityKit
import Foundation

@MainActor
final class LiveActivityManager: ObservableObject {
    static let shared = LiveActivityManager()
    private init() {}

    private var activity: Activity<RecordingActivityAttributes>?
    private var ticker: Task<Void, Never>?
    private var startDate = Date()

    func start() {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        startDate = Date()

        let initial = RecordingActivityAttributes.ContentState(isRecording: true, elapsedSeconds: 0)
        do {
            activity = try Activity.request(
                attributes: RecordingActivityAttributes(),
                content: .init(state: initial, staleDate: nil),
                pushType: nil
            )
        } catch {
            print("LiveActivity start failed:", error)
            return
        }

        ticker = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                let elapsed = Int(Date().timeIntervalSince(startDate))
                let state = RecordingActivityAttributes.ContentState(isRecording: true, elapsedSeconds: elapsed)
                await activity?.update(.init(state: state, staleDate: nil))
            }
        }
    }

    func stop() {
        ticker?.cancel()
        ticker = nil
        let final = RecordingActivityAttributes.ContentState(isRecording: false, elapsedSeconds: 0)
        Task {
            await activity?.end(.init(state: final, staleDate: nil), dismissalPolicy: .after(.now + 3))
            activity = nil
        }
    }
}
