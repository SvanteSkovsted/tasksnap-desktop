import ActivityKit
import Foundation

@MainActor
final class LiveActivityManager {
    static let shared = LiveActivityManager()
    private init() {}

    private var activity: Activity<RecordingActivityAttributes>?
    private var ticker: Task<Void, Never>?
    private var startDate = Date()

    // Resolves the live activity even when this is a fresh process (activity == nil).
    private var liveActivity: Activity<RecordingActivityAttributes>? {
        activity ?? Activity<RecordingActivityAttributes>.activities.first
    }

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

        ticker = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                let elapsed = Int(Date().timeIntervalSince(startDate))
                let state = RecordingActivityAttributes.ContentState(phase: .recording, elapsedSeconds: elapsed)
                await liveActivity?.update(.init(state: state, staleDate: nil))
            }
        }
    }

    /// Stop the ticker and show the analyzing spinner.
    func setAnalyzing() {
        ticker?.cancel()
        ticker = nil
        let state = RecordingActivityAttributes.ContentState(phase: .analyzing, elapsedSeconds: 0)
        Task { await liveActivity?.update(.init(state: state, staleDate: nil)) }
    }

    /// Show green checkmark, then auto-dismiss after 2 s.
    func complete() {
        let state = RecordingActivityAttributes.ContentState(phase: .done, elapsedSeconds: 0)
        Task {
            await liveActivity?.update(.init(state: state, staleDate: nil))
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await liveActivity?.end(.init(state: state, staleDate: nil), dismissalPolicy: .immediate)
            activity = nil
        }
    }

    /// Used by the foreground recorder (no analyzing phase needed).
    func stop() {
        ticker?.cancel()
        ticker = nil
        Task {
            let state = RecordingActivityAttributes.ContentState(phase: .done, elapsedSeconds: 0)
            await liveActivity?.end(.init(state: state, staleDate: nil), dismissalPolicy: .after(.now + 2))
            activity = nil
        }
    }
}
