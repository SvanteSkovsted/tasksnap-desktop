import ActivityKit
import Foundation

// Shared between the main app target and the VocaFlowActivity widget extension.
// Explicit Sendable conformance satisfies ActivityKit's concurrency requirements.
struct RecordingActivityAttributes: ActivityAttributes, Sendable {
    // ContentState must be Codable + Hashable per ActivityAttributes requirements.
    struct ContentState: Codable, Hashable, Sendable {
        enum Phase: String, Codable, Sendable {
            case recording  // mic open, waveform visible
            case analyzing  // upload in flight, spinner
            case done       // task created, checkmark (auto-dismisses)
        }
        var phase: Phase
        var elapsedSeconds: Int
    }
}
