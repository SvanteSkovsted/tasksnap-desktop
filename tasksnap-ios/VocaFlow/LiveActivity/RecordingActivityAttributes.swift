import ActivityKit
import Foundation

struct RecordingActivityAttributes: ActivityAttributes, Sendable {
    struct ContentState: Codable, Hashable, Sendable {
        enum Phase: String, Codable, Sendable {
            case recording   // mic open, waveform
            case analyzing   // upload in flight
            case done        // task created, auto-dismisses
        }
        var phase: Phase
        var elapsedSeconds: Int
    }
}
