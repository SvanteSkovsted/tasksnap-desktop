import ActivityKit
import Foundation

// Shared between the main app and the widget extension.
struct RecordingActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var isRecording: Bool
        var elapsedSeconds: Int
    }
}
