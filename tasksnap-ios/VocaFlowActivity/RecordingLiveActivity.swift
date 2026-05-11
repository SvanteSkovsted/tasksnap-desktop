import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Live Activity widget (VocaFlowActivity widget extension target)

struct RecordingLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RecordingActivityAttributes.self) { ctx in
            LockScreenView(state: ctx.state)
                .padding(16)
                .activityBackgroundTint(.black)
        } dynamicIsland: { ctx in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    phaseIcon(ctx.state.phase)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(phaseColor(ctx.state.phase))
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if ctx.state.phase == .recording {
                        Text(formatTime(ctx.state.elapsedSeconds))
                            .monospacedDigit()
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white.opacity(0.75))
                    }
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(phaseLabel(ctx.state.phase))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                DynamicIslandExpandedRegion(.bottom) {
                    expandedBottom(ctx.state.phase)
                        .padding(.top, 4)
                }
            } compactLeading: {
                phaseIcon(ctx.state.phase)
                    .foregroundColor(phaseColor(ctx.state.phase))
                    .font(.caption)
            } compactTrailing: {
                if ctx.state.phase == .recording {
                    Text(formatTime(ctx.state.elapsedSeconds))
                        .monospacedDigit()
                        .font(.caption2)
                        .foregroundColor(.white)
                } else {
                    phaseIcon(ctx.state.phase)
                        .foregroundColor(phaseColor(ctx.state.phase))
                        .font(.caption2)
                }
            } minimal: {
                phaseIcon(ctx.state.phase)
                    .foregroundColor(phaseColor(ctx.state.phase))
                    .font(.caption2)
            }
            .keylineTint(phaseColor(.recording))
        }
    }

    // MARK: - Phase helpers

    private func phaseIcon(_ phase: RecordingActivityAttributes.ContentState.Phase) -> Image {
        switch phase {
        case .recording: return Image(systemName: "mic.fill")
        case .analyzing: return Image(systemName: "waveform")
        case .done:      return Image(systemName: "checkmark.circle.fill")
        }
    }

    private func phaseColor(_ phase: RecordingActivityAttributes.ContentState.Phase) -> Color {
        switch phase {
        case .recording: return .red
        case .analyzing: return .orange
        case .done:      return .green
        }
    }

    private func phaseLabel(_ phase: RecordingActivityAttributes.ContentState.Phase) -> String {
        switch phase {
        case .recording: return "Recording"
        case .analyzing: return "Analyzing…"
        case .done:      return "Task created!"
        }
    }

    @ViewBuilder
    private func expandedBottom(_ phase: RecordingActivityAttributes.ContentState.Phase) -> some View {
        switch phase {
        case .recording:
            MiniWaveformView()
        case .analyzing:
            AnalyzingDotsView()
        case .done:
            Label("Task saved to your list", systemImage: "checkmark")
                .font(.caption)
                .foregroundColor(.green.opacity(0.85))
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}

// MARK: - Lock screen / banner

private struct LockScreenView: View {
    let state: RecordingActivityAttributes.ContentState

    var body: some View {
        HStack(spacing: 14) {
            iconView
                .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 3) {
                Text("VocaFlow")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()

            if state.phase == .recording {
                Text(String(format: "%d:%02d", state.elapsedSeconds / 60, state.elapsedSeconds % 60))
                    .monospacedDigit()
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
            }
        }
    }

    private var iconView: some View {
        ZStack {
            Circle()
                .fill(iconColor.opacity(0.2))
            Image(systemName: iconName)
                .foregroundColor(iconColor)
                .font(.system(size: 16, weight: .semibold))
        }
    }

    private var iconName: String {
        switch state.phase {
        case .recording: return "mic.fill"
        case .analyzing: return "waveform"
        case .done:      return "checkmark.circle.fill"
        }
    }

    private var iconColor: Color {
        switch state.phase {
        case .recording: return .red
        case .analyzing: return .orange
        case .done:      return .green
        }
    }

    private var subtitle: String {
        switch state.phase {
        case .recording: return "Recording in progress"
        case .analyzing: return "Creating your task…"
        case .done:      return "Task created successfully!"
        }
    }
}

// MARK: - Animated waveform (recording phase)

private struct MiniWaveformView: View {
    private let heights: [CGFloat] = [6, 14, 9, 18, 12, 22, 8, 17, 11, 20, 7, 15, 10, 19, 6, 14, 9, 18, 12, 22]
    @State private var animate = false

    var body: some View {
        HStack(alignment: .center, spacing: 3) {
            ForEach(Array(heights.enumerated()), id: \.offset) { i, h in
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(Color.red.opacity(0.85))
                    .frame(width: 3, height: animate ? h : 4)
                    .animation(
                        .easeInOut(duration: 0.55)
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

// MARK: - Pulsing dots (analyzing phase)

private struct AnalyzingDotsView: View {
    @State private var scales: [CGFloat] = [1, 1, 1]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(Color.orange)
                    .frame(width: 7, height: 7)
                    .scaleEffect(scales[i])
                    .animation(
                        .easeInOut(duration: 0.5)
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.18),
                        value: scales[i]
                    )
            }
        }
        .frame(height: 24)
        .onAppear { scales = [1.6, 1.6, 1.6] }
    }
}
