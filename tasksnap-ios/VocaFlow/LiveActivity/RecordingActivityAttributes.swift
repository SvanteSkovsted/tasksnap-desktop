import ActivityKit
import Foundation

// Shared between the main app target and the VocaFlowActivity widget extension.
struct RecordingActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        enum Phase: String, Codable {
            case recording   // mic open, waveform visible
            case analyzing   // upload in flight, spinner
            case done        // task created, checkmark (shown briefly before dismiss)
        }
        var phase: Phase
        var elapsedSeconds: Int
    }
}
