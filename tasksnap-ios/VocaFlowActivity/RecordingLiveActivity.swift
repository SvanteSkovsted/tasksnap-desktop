import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Live Activity widget (add this file to the VocaFlowActivity widget extension target)

struct RecordingLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RecordingActivityAttributes.self) { ctx in
            // Lock screen / banner view
            LockScreenBannerView(state: ctx.state)
                .padding(16)
                .activityBackgroundTint(Color.black)
        } dynamicIsland: { ctx in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        Image(systemName: "mic.fill")
                            .foregroundColor(.red)
                            .font(.system(size: 15))
                        Text("VocaFlow")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(formattedTime(ctx.state.elapsedSeconds))
                        .monospacedDigit()
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white.opacity(0.75))
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(ctx.state.isRecording ? "Recording…" : "Processing…")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.6))
                }
                DynamicIslandExpandedRegion(.bottom) {
                    // Static decorative waveform (real-time updates require live data push)
                    MiniWaveformView()
                        .padding(.top, 4)
                }
            } compactLeading: {
                Image(systemName: "mic.fill")
                    .foregroundColor(.red)
                    .font(.caption)
            } compactTrailing: {
                Text(formattedTime(ctx.state.elapsedSeconds))
                    .monospacedDigit()
                    .font(.caption2)
                    .foregroundColor(.white)
            } minimal: {
                Image(systemName: "mic.fill")
                    .foregroundColor(.red)
                    .font(.caption2)
            }
            .keylineTint(.red)
        }
    }

    private func formattedTime(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}

// MARK: - Lock screen banner

private struct LockScreenBannerView: View {
    let state: RecordingActivityAttributes.ContentState

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: state.isRecording ? "mic.fill" : "waveform")
                .foregroundColor(.red)
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                Text("VocaFlow")
                    .font(.headline)
                    .foregroundColor(.white)
                Text(state.isRecording ? "Recording in progress" : "Processing audio…")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.65))
            }

            Spacer()

            Text(String(format: "%d:%02d", state.elapsedSeconds / 60, state.elapsedSeconds % 60))
                .monospacedDigit()
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Decorative mini waveform

private struct MiniWaveformView: View {
    // Heights cycle through a fixed pattern — gives a "recording" feel without live data
    private let heights: [CGFloat] = [6, 14, 9, 18, 12, 22, 8, 17, 11, 20, 7, 15, 10, 19, 6, 14, 9, 18, 12, 22]
    @State private var animate = false

    var body: some View {
        HStack(alignment: .center, spacing: 3) {
            ForEach(Array(heights.enumerated()), id: \.offset) { i, h in
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(Color.red.opacity(0.8))
                    .frame(width: 3, height: animate ? h : 4)
                    .animation(
                        .easeInOut(duration: 0.6)
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.05),
                        value: animate
                    )
            }
        }
        .frame(height: 24)
        .onAppear { animate = true }
    }
}
