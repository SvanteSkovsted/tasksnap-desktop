import ActivityKit
import Foundation
import VocaFlowShared

@MainActor
final class LiveActivityManager {
    static let shared = LiveActivityManager()
    private init() {}

    private var activity: Activity<RecordingActivityAttributes>?
    private var ticker: Task<Void, Never>?
    private var startDate = Date()

    // Falls back to the system registry when this is a fresh process.
    private var liveActivity: Activity<RecordingActivityAttributes>? {
        if let a = activity { return a }
        let found = Activity<RecordingActivityAttributes>.activities.first
        print("[LiveActivity] liveActivity — in-memory nil, registry: \(found?.id ?? "none")")
        return found
    }

    // MARK: - Start

    func start() {
        print("[LiveActivity] ── start() ──────────────────────────")

        let info = ActivityAuthorizationInfo()
        print("[LiveActivity] areActivitiesEnabled      : \(info.areActivitiesEnabled)")
        print("[LiveActivity] frequentPushesEnabled     : \(info.frequentPushesEnabled)")

        guard info.areActivitiesEnabled else {
            print("[LiveActivity] ❌ Activities not enabled.")
            print("[LiveActivity]    → Check: Settings › VocaFlow › Live Activities")
            print("[LiveActivity]    → Check: Settings › Face ID & Passcode › Live Activities")
            return
        }

        // End any stale activity from a previous session.
        if let stale = Activity<RecordingActivityAttributes>.activities.first {
            print("[LiveActivity] Found stale activity \(stale.id) — ending it first")
            Task { await stale.end(nil, dismissalPolicy: .immediate) }
        }

        startDate = Date()
        let initial = RecordingActivityAttributes.ContentState(phase: .recording, elapsedSeconds: 0)
        print("[LiveActivity] Requesting activity with state: \(initial)")

        do {
            let a = try Activity.request(
                attributes: RecordingActivityAttributes(),
                content: .init(state: initial, staleDate: nil),
                pushType: nil
            )
            activity = a
            print("[LiveActivity] ✅ Activity started — id: \(a.id)")
        } catch let error as ActivityAuthorizationError {
            print("[LiveActivity] ❌ ActivityAuthorizationError: \(error)")
            return
        } catch {
            print("[LiveActivity] ❌ Activity.request threw: \(error)")
            print("[LiveActivity]    localizedDescription: \(error.localizedDescription)")
            return
        }

        ticker = Task {
            print("[LiveActivity] Ticker started")
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                let elapsed = Int(Date().timeIntervalSince(startDate))
                let state = RecordingActivityAttributes.ContentState(phase: .recording,
                                                                     elapsedSeconds: elapsed)
                print("[LiveActivity] Tick \(elapsed)s → updating \(liveActivity?.id ?? "nil")")
                await liveActivity?.update(.init(state: state, staleDate: nil))
            }
            print("[LiveActivity] Ticker cancelled")
        }
    }

    // MARK: - Phase transitions

    func setAnalyzing() {
        print("[LiveActivity] setAnalyzing() — activity: \(liveActivity?.id ?? "nil")")
        ticker?.cancel()
        ticker = nil
        let state = RecordingActivityAttributes.ContentState(phase: .analyzing, elapsedSeconds: 0)
        Task {
            await liveActivity?.update(.init(state: state, staleDate: nil))
            print("[LiveActivity] → analyzing state pushed")
        }
    }

    func complete() {
        print("[LiveActivity] complete() — activity: \(liveActivity?.id ?? "nil")")
        let state = RecordingActivityAttributes.ContentState(phase: .done, elapsedSeconds: 0)
        Task {
            await liveActivity?.update(.init(state: state, staleDate: nil))
            print("[LiveActivity] → done state pushed, waiting 2 s…")
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await liveActivity?.end(.init(state: state, staleDate: nil), dismissalPolicy: .immediate)
            print("[LiveActivity] → activity ended")
            activity = nil
        }
    }

    func stop() {
        print("[LiveActivity] stop() — activity: \(liveActivity?.id ?? "nil")")
        ticker?.cancel()
        ticker = nil
        Task {
            let state = RecordingActivityAttributes.ContentState(phase: .done, elapsedSeconds: 0)
            await liveActivity?.end(.init(state: state, staleDate: nil), dismissalPolicy: .after(.now + 2))
            print("[LiveActivity] → activity ended via stop()")
            activity = nil
        }
    }
}
