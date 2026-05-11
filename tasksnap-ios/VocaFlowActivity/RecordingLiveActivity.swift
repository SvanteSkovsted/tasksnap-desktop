import ActivityKit
import AppIntents
import VocaFlowShared
import WidgetKit
import SwiftUI

// MARK: - Widget

struct RecordingLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RecordingActivityAttributes.self) { ctx in
            LockScreenBanner(state: ctx.state)
        } dynamicIsland: { ctx in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        phaseIcon(ctx.state.phase)
                            .font(.system(size: 15, weight: .semibold))
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
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.65))
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
                HStack(spacing: 4) {
                    phaseIcon(ctx.state.phase)
                        .foregroundColor(phaseColor(ctx.state.phase))
                        .font(.system(size: 11, weight: .semibold))
                    if ctx.state.phase == .recording {
                        MiniWaveformView(color: .red, barCount: 5, maxHeight: 12)
                    }
                }
            } compactTrailing: {
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
                phaseIcon(ctx.state.phase)
                    .foregroundColor(phaseColor(ctx.state.phase))
                    .font(.caption2)
            }
            .keylineTint(.red)
        }
    }

    // MARK: - Expanded bottom region

    @ViewBuilder
    private func expandedBottom(_ phase: RecordingActivityAttributes.ContentState.Phase) -> some View {
        switch phase {
        case .recording:
            HStack(spacing: 14) {
                MiniWaveformView(color: .red, barCount: 18, maxHeight: 22)
                    .frame(maxWidth: .infinity)

                Button(intent: StopRecordingIntent()) {
                    HStack(spacing: 6) {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 12, weight: .bold))
                        Text("Send")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.cream)
                    .foregroundColor(Color.dark)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 4)

        case .analyzing:
            PulsingDotsView(color: .orange)
                .frame(height: 24)

        case .done:
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Task created!")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
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

    private func formatTime(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}

// MARK: - Lock screen / notification banner

private struct LockScreenBanner: View {
    let state: RecordingActivityAttributes.ContentState

    var body: some View {
        VStack(spacing: 14) {
            header
            content
        }
        .padding(20)
        .background(Color.dark)
    }

    private var header: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(headerColor.opacity(0.18))
                    .frame(width: 34, height: 34)
                Image(systemName: headerIcon)
                    .foregroundColor(headerColor)
                    .font(.system(size: 15, weight: .semibold))
            }
            Text("VocaFlow")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            Spacer()
            if state.phase == .recording {
                Text(String(format: "%d:%02d", state.elapsedSeconds / 60, state.elapsedSeconds % 60))
                    .monospacedDigit()
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch state.phase {
        case .recording:
            VStack(spacing: 14) {
                MiniWaveformView(color: .red, barCount: 28, maxHeight: 44)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)

                Button(intent: StopRecordingIntent()) {
                    HStack(spacing: 8) {
                        Image(systemName: "paperplane.fill")
                        Text("Stop & Send")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.cream)
                    .foregroundColor(Color.dark)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
            }

        case .analyzing:
            PulsingDotsView(color: .orange)
                .frame(height: 50)

        case .done:
            VStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 44))
                    .foregroundColor(.green)
                Text("Task created successfully!")
                    .font(.callout)
                    .foregroundColor(.white.opacity(0.7))
            }
            .frame(height: 80)
        }
    }

    private var headerIcon: String {
        switch state.phase {
        case .recording: return "mic.fill"
        case .analyzing: return "waveform"
        case .done:      return "checkmark.circle.fill"
        }
    }

    private var headerColor: Color {
        switch state.phase {
        case .recording: return .red
        case .analyzing: return .orange
        case .done:      return .green
        }
    }
}

// MARK: - Animated waveform bars

private struct MiniWaveformView: View {
    let color: Color
    let barCount: Int
    let maxHeight: CGFloat

    // Phase offset creates an organic, non-uniform wave feeling.
    private static let phases: [Double] = (0..<30).map { Double($0) * 0.37 }

    @State private var tick = false

    var body: some View {
        HStack(alignment: .center, spacing: 2.5) {
            ForEach(0..<barCount, id: \.self) { i in
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(color)
                    .frame(width: 3, height: barHeight(i))
                    .animation(
                        .easeInOut(duration: 0.5 + Double(i % 5) * 0.07)
                            .repeatForever(autoreverses: true)
                            .delay(Self.phases[i % Self.phases.count] * 0.15),
                        value: tick
                    )
            }
        }
        .onAppear { tick = true }
    }

    private func barHeight(_ i: Int) -> CGFloat {
        let base: CGFloat = 3
        let wave = sin(Double(i) / Double(barCount) * .pi * 2 + (tick ? 1 : 0))
        return base + CGFloat(abs(wave)) * (maxHeight - base)
    }
}

// MARK: - Pulsing dots (analyzing state)

private struct PulsingDotsView: View {
    let color: Color
    @State private var scales: [CGFloat] = [1, 1, 1]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(color)
                    .frame(width: 9, height: 9)
                    .scaleEffect(scales[i])
                    .animation(
                        .easeInOut(duration: 0.52)
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.2),
                        value: scales[i]
                    )
            }
        }
        .onAppear { scales = [1.65, 1.65, 1.65] }
    }
}

// Color.cream and Color.dark are defined in Color+Hex.swift (shared source).
