import ActivityKit
import Foundation

@MainActor
final class LiveActivityManager {
    static let shared = LiveActivityManager()
    private init() {}

    private var activity: Activity<RecordingActivityAttributes>?
    private var ticker: Task<Void, Never>?
    private var startDate = Date()

    private var liveActivity: Activity<RecordingActivityAttributes>? {
        activity ?? Activity<RecordingActivityAttributes>.activities.first
    }

    // MARK: - Lifecycle

    func start() {
        let info = ActivityAuthorizationInfo()
        guard info.areActivitiesEnabled else {
            print("[LiveActivity] not enabled — skip")
            return
        }

        // End any stale activity first.
        if let stale = Activity<RecordingActivityAttributes>.activities.first {
            Task { await stale.end(nil, dismissalPolicy: .immediate) }
        }

        startDate = Date()
        let state = RecordingActivityAttributes.ContentState(phase: .recording, elapsedSeconds: 0)
        do {
            activity = try Activity.request(
                attributes: RecordingActivityAttributes(),
                content: .init(state: state, staleDate: nil),
                pushType: nil
            )
            print("[LiveActivity] started: \(activity?.id ?? "?")")
        } catch {
            print("[LiveActivity] request failed: \(error)")
            return
        }

        ticker = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                let elapsed = Int(Date().timeIntervalSince(startDate))
                let s = RecordingActivityAttributes.ContentState(phase: .recording, elapsedSeconds: elapsed)
                await liveActivity?.update(.init(state: s, staleDate: nil))
            }
        }
    }

    func setAnalyzing() {
        ticker?.cancel(); ticker = nil
        let s = RecordingActivityAttributes.ContentState(phase: .analyzing, elapsedSeconds: 0)
        Task { await liveActivity?.update(.init(state: s, staleDate: nil)) }
    }

    func complete() {
        let s = RecordingActivityAttributes.ContentState(phase: .done, elapsedSeconds: 0)
        Task {
            await liveActivity?.update(.init(state: s, staleDate: nil))
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await liveActivity?.end(.init(state: s, staleDate: nil), dismissalPolicy: .immediate)
            activity = nil
        }
    }

    func stop() {
        ticker?.cancel(); ticker = nil
        Task {
            let s = RecordingActivityAttributes.ContentState(phase: .done, elapsedSeconds: 0)
            await liveActivity?.end(.init(state: s, staleDate: nil), dismissalPolicy: .after(.now + 2))
            activity = nil
        }
    }
}
