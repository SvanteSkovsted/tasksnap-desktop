import ActivityKit
import Foundation

// Single definition shared by the main app and the widget extension.
// Both targets import VocaFlowShared so the fully-qualified type name is
// VocaFlowShared.RecordingActivityAttributes in both — ActivityKit uses
// this name to match the app's activity request with the extension's
// ActivityConfiguration.
public struct RecordingActivityAttributes: ActivityAttributes, Sendable {
    public struct ContentState: Codable, Hashable, Sendable {
        public enum Phase: String, Codable, Sendable {
            case recording  // mic open, waveform + Send button
            case analyzing  // upload in flight, pulsing dots
            case done       // checkmark, auto-dismisses after 2 s
        }
        public var phase: Phase
        public var elapsedSeconds: Int

        public init(phase: Phase, elapsedSeconds: Int) {
            self.phase = phase
            self.elapsedSeconds = elapsedSeconds
        }
    }

    public init() {}
}
