import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Widget

struct RecordingLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RecordingActivityAttributes.self) { ctx in
            // Lock-screen / notification banner view
            LockScreenBanner(state: ctx.state)
        } dynamicIsland: { ctx in
            DynamicIsland {
                // ── Expanded ──────────────────────────────────
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        phaseIcon(ctx.state.phase)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(phaseColor(ctx.state.phase))
                        Text("VocaFlow")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    if ctx.state.phase == .recording {
                        Text(formatTime(ctx.state.elapsedSeconds))
                            .monospacedDigit()
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }

                DynamicIslandExpandedRegion(.center) {
                    Text(phaseLabel(ctx.state.phase))
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                }

                DynamicIslandExpandedRegion(.bottom) {
                    expandedBottom(ctx.state.phase)
                        .padding(.bottom, 4)
                }

            } compactLeading: {
                // ── Compact leading ───────────────────────────
                HStack(spacing: 3) {
                    phaseIcon(ctx.state.phase)
                        .foregroundColor(phaseColor(ctx.state.phase))
                        .font(.system(size: 11, weight: .semibold))
                    if ctx.state.phase == .recording {
                        MiniWaveView()
                    }
                }

            } compactTrailing: {
                // ── Compact trailing ──────────────────────────
                if ctx.state.phase == .recording {
                    Text(formatTime(ctx.state.elapsedSeconds))
                        .monospacedDigit()
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white)
                } else {
                    phaseIcon(ctx.state.phase)
                        .foregroundColor(phaseColor(ctx.state.phase))
                        .font(.caption2)
                }

            } minimal: {
                // ── Minimal ───────────────────────────────────
                phaseIcon(ctx.state.phase)
                    .foregroundColor(phaseColor(ctx.state.phase))
                    .font(.caption2)
            }
            .keylineTint(.red)
        }
    }

    // MARK: - Expanded bottom

    @ViewBuilder
    private func expandedBottom(_ phase: RecordingActivityAttributes.ContentState.Phase) -> some View {
        switch phase {
        case .recording:
            MiniWaveView(barCount: 20, maxHeight: 22, color: .red)
                .frame(height: 28)
        case .analyzing:
            PulsingDotsView(color: .orange)
                .frame(height: 24)
        case .done:
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                Text("Task created!").foregroundColor(.white.opacity(0.8))
            }
            .font(.system(size: 13, weight: .medium))
        }
    }

    // MARK: - Helpers

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

    private func formatTime(_ s: Int) -> String {
        String(format: "%d:%02d", s / 60, s % 60)
    }
}

// MARK: - Lock-screen banner

private struct LockScreenBanner: View {
    let state: RecordingActivityAttributes.ContentState

    var body: some View {
        HStack(spacing: 14) {
            // Phase icon badge
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.18))
                    .frame(width: 40, height: 40)
                Image(systemName: iconName)
                    .foregroundColor(iconColor)
                    .font(.system(size: 16, weight: .semibold))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("VocaFlow")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.55))
            }

            Spacer()

            if state.phase == .recording {
                Text(String(format: "%d:%02d",
                            state.elapsedSeconds / 60,
                            state.elapsedSeconds % 60))
                    .monospacedDigit()
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
            } else if state.phase == .done {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)
            }
        }
        .padding(18)
        .activityBackgroundTint(Color(red: 26/255, green: 26/255, blue: 26/255))
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
        case .done:      return "Task created successfully"
        }
    }
}

// MARK: - Mini waveform

private struct MiniWaveView: View {
    var barCount: Int = 5
    var maxHeight: CGFloat = 12
    var color: Color = .red

    @State private var animate = false

    var body: some View {
        HStack(alignment: .center, spacing: 2) {
            ForEach(0..<barCount, id: \.self) { i in
                RoundedRectangle(cornerRadius: 1)
                    .fill(color)
                    .frame(width: 2.5, height: animate ? randomHeight(i) : 3)
                    .animation(
                        .easeInOut(duration: 0.45 + Double(i % 3) * 0.1)
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.08),
                        value: animate
                    )
            }
        }
        .onAppear { animate = true }
    }

    private func randomHeight(_ i: Int) -> CGFloat {
        let base: CGFloat = 4
        let wave = abs(sin(Double(i) * 0.9 + 1.2))
        return base + CGFloat(wave) * (maxHeight - base)
    }
}

// MARK: - Pulsing dots

private struct PulsingDotsView: View {
    let color: Color
    @State private var scales: [CGFloat] = [1, 1, 1]

    var body: some View {
        HStack(spacing: 7) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                    .scaleEffect(scales[i])
                    .animation(
                        .easeInOut(duration: 0.5)
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.18),
                        value: scales[i]
                    )
            }
        }
        .onAppear { scales = [1.6, 1.6, 1.6] }
    }
}
