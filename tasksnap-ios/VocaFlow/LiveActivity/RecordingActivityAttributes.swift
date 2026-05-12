import ActivityKit
import Foundation

struct RecordingActivityAttributes: ActivityAttributes, Sendable {
    struct ContentState: Codable, Hashable, Sendable {
        enum Phase: String, Codable, Sendable {
            case recording  // mic open, waveform + Send button
            case analyzing  // upload in flight, pulsing dots
            case done       // checkmark, auto-dismisses after 2 s
        }
        var phase: Phase
        var elapsedSeconds: Int
    }
}
