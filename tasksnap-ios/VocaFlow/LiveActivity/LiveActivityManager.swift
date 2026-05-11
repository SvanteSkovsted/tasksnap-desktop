import ActivityKit
import Foundation

@MainActor
final class LiveActivityManager {
    static let shared = LiveActivityManager()
    private init() {}

    private var activity: Activity<RecordingActivityAttributes>?
    private var ticker: Task<Void, Never>?
    private var startDate = Date()

    // MARK: - Phase transitions

    func start() {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        startDate = Date()

        let initial = RecordingActivityAttributes.ContentState(phase: .recording, elapsedSeconds: 0)
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

        // Tick elapsed time once per second while recording.
        ticker = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                let elapsed = Int(Date().timeIntervalSince(startDate))
                let state = RecordingActivityAttributes.ContentState(phase: .recording, elapsedSeconds: elapsed)
                await activity?.update(.init(state: state, staleDate: nil))
            }
        }
    }

    /// Call immediately after stopping the microphone — shows a spinner.
    func setAnalyzing() {
        ticker?.cancel()
        ticker = nil
        let state = RecordingActivityAttributes.ContentState(phase: .analyzing, elapsedSeconds: 0)
        Task { await activity?.update(.init(state: state, staleDate: nil)) }
    }

    /// Call when the upload succeeds — shows checkmark, then auto-dismisses after 3 s.
    func complete() {
        let state = RecordingActivityAttributes.ContentState(phase: .done, elapsedSeconds: 0)
        Task {
            await activity?.update(.init(state: state, staleDate: nil))
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            await activity?.end(.init(state: state, staleDate: nil), dismissalPolicy: .immediate)
            activity = nil
        }
    }

    /// Convenience for the foreground recorder path (no distinct analyzing step needed).
    func stop() {
        ticker?.cancel()
        ticker = nil
        Task {
            let state = RecordingActivityAttributes.ContentState(phase: .done, elapsedSeconds: 0)
            await activity?.end(.init(state: state, staleDate: nil), dismissalPolicy: .after(.now + 3))
            activity = nil
        }
    }
}
