import SwiftUI

// MARK: - Main view

struct AnalyzingView: View {
    // Step visibility state
    @State private var visibleCount   = 0
    @State private var completedCount = 0
    @State private var currentIcon    = "waveform"
    // Ring + glow entry
    @State private var ringScale: CGFloat = 0.3
    @State private var ringOpacity: Double = 0
    @State private var glowAnim = false

    private let gold = Color(hex: "#C9A96E")

    private let stepDefs: [(icon: String, text: String)] = [
        ("mic.fill",          "Transcribing your voice..."),
        ("sparkles",          "Extracting key details..."),
        ("bolt.fill",         "Detecting priority & urgency..."),
        ("calendar",          "Finding dates & deadlines..."),
        ("checkmark.circle",  "Creating your task..."),
    ]
    // When each step appears (seconds)
    private let showAt   = [0.5,  1.5,  2.5,  3.0,  3.5]
    // When each step transitions to "completed"
    private let doneAt   = [1.3,  2.3,  2.8,  3.3,  4.3]

    var body: some View {
        ZStack {
            Color.cream.ignoresSafeArea()

            // ── Orbital background particles ──────────────────────────
            TimelineView(.animation(minimumInterval: 1/60)) { tl in
                OrbitalParticles(time: tl.date.timeIntervalSinceReferenceDate,
                                 color: gold)
            }

            // ── Gold glow blob ────────────────────────────────────────
            Circle()
                .fill(
                    RadialGradient(
                        colors: [gold.opacity(glowAnim ? 0.28 : 0.10), .clear],
                        center: .center, startRadius: 0, endRadius: 130
                    )
                )
                .frame(width: 280, height: 280)
                .blur(radius: 36)
                .offset(y: -60)
                .animation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true), value: glowAnim)

            // ── Content column ────────────────────────────────────────
            VStack(spacing: 0) {
                Spacer()

                // Breathing ring
                BreathingRingView(icon: currentIcon, gold: gold)
                    .frame(width: 130, height: 130)
                    .scaleEffect(ringScale)
                    .opacity(ringOpacity)
                    .animation(.spring(response: 0.65, dampingFraction: 0.62), value: ringScale)

                Spacer().frame(height: 50)

                // Progress steps
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(0..<visibleCount, id: \.self) { i in
                        StepRow(
                            icon: stepDefs[i].icon,
                            text: stepDefs[i].text,
                            isActive:    i == visibleCount - 1 && completedCount <= i,
                            isCompleted: completedCount > i,
                            gold:        gold
                        )
                        .transition(.asymmetric(
                            insertion: .move(edge: .leading).combined(with: .opacity),
                            removal:   .opacity
                        ))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 36)
                .animation(.spring(response: 0.45, dampingFraction: 0.74), value: visibleCount)

                Spacer()
            }
        }
        .onAppear(perform: begin)
    }

    private func begin() {
        // Ring entry
        withAnimation(.spring(response: 0.65, dampingFraction: 0.62).delay(0.1)) {
            ringScale   = 1.0
            ringOpacity = 1.0
        }
        // Glow pulse
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { glowAnim = true }

        // Step sequencing
        for (i, delay) in showAt.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.74)) {
                    visibleCount = i + 1
                    currentIcon  = stepDefs[i].icon
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + doneAt[i]) {
                withAnimation(.easeOut(duration: 0.3)) {
                    completedCount = i + 1
                    if i == stepDefs.count - 1 { currentIcon = "checkmark.circle.fill" }
                }
            }
        }
    }
}

// MARK: - Breathing ring

private struct BreathingRingView: View {
    let icon: String
    let gold: Color

    @State private var p1: CGFloat = 1.0
    @State private var p2: CGFloat = 1.0
    @State private var p3: CGFloat = 1.0

    var body: some View {
        ZStack {
            // Three concentric rings, each breathing at a different tempo
            Circle()
                .stroke(gold.opacity(0.10), lineWidth: 1)
                .scaleEffect(p3)
                .animation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true).delay(0.6), value: p3)

            Circle()
                .stroke(gold.opacity(0.20), lineWidth: 1.5)
                .scaleEffect(p2)
                .animation(.easeInOut(duration: 1.9).repeatForever(autoreverses: true).delay(0.25), value: p2)

            Circle()
                .fill(
                    RadialGradient(colors: [gold.opacity(0.16), gold.opacity(0.04)],
                                   center: .center, startRadius: 0, endRadius: 48)
                )
                .scaleEffect(p1)
                .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true), value: p1)

            // Icon morphs as each step activates
            Image(systemName: icon)
                .font(.system(size: 30, weight: .medium))
                .foregroundColor(gold)
                .id(icon)
                .transition(.scale(scale: 0.5).combined(with: .opacity))
                .animation(.spring(response: 0.38, dampingFraction: 0.65), value: icon)
        }
        .onAppear { p1 = 1.10; p2 = 1.18; p3 = 1.26 }
    }
}

// MARK: - Orbital particles

private struct OrbitalParticles: View {
    let time: TimeInterval
    let color: Color

    // (orbit radius, period s, dot size, start phase radians, opacity)
    private let cfg: [(CGFloat, Double, CGFloat, Double, Double)] = [
        (95,  9.0,  4.5, 0.0,  0.28),
        (130, 12.5, 3.5, 2.1,  0.18),
        (75,  7.0,  5.0, 4.2,  0.22),
        (155, 15.0, 3.0, 1.05, 0.13),
        (112, 10.5, 4.0, 3.49, 0.20),
        (88,  8.2,  3.5, 5.76, 0.16),
        (142, 13.0, 4.0, 0.79, 0.12),
        (105, 11.0, 3.0, 2.62, 0.18),
    ]

    var body: some View {
        GeometryReader { geo in
            let cx = geo.size.width  / 2
            let cy = geo.size.height * 0.37   // aligned with the breathing ring

            ForEach(Array(cfg.enumerated()), id: \.offset) { _, c in
                let angle = time / c.1 * 2 * .pi + c.3
                Circle()
                    .fill(color)
                    .frame(width: c.2, height: c.2)
                    .opacity(c.4)
                    .position(x: cx + c.0 * cos(angle),
                              y: cy + c.0 * sin(angle))
            }
        }
    }
}

// MARK: - Step row

private struct StepRow: View {
    let icon: String
    let text: String
    let isActive: Bool
    let isCompleted: Bool
    let gold: Color

    @StateObject private var tw = TypewriterTimer()
    @State private var appeared = false
    @State private var iconPulse: CGFloat = 1.0

    var body: some View {
        HStack(spacing: 14) {
            // Icon / checkmark
            ZStack {
                if isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.green)
                        .transition(.scale(scale: 0.4).combined(with: .opacity))
                } else {
                    ZStack {
                        Circle()
                            .fill(isActive ? gold.opacity(0.14) : Color.dark.opacity(0.05))
                            .frame(width: 36, height: 36)
                            .scaleEffect(iconPulse)

                        Image(systemName: icon)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(isActive ? gold : Color.dark.opacity(0.22))
                    }
                    .transition(.identity)
                }
            }
            .frame(width: 36, height: 36)
            .animation(.spring(response: 0.35, dampingFraction: 0.65), value: isCompleted)

            // Typewriter text
            Text(isCompleted ? text : String(text.prefix(tw.count)))
                .font(.system(size: 15,
                              weight: isActive ? .semibold : .regular,
                              design: .monospaced))
                .foregroundColor(isCompleted ? Color.dark
                                 : isActive   ? Color.dark
                                             : Color.dark.opacity(0.3))
                .animation(.easeOut(duration: 0.2), value: isActive)

            Spacer()
        }
        .offset(x: appeared ? 0 : -28)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.44, dampingFraction: 0.72)) { appeared = true }
            tw.start(maxChars: text.count)
            startIconPulse()
        }
        .onChange(of: isCompleted) { _, done in
            if done {
                tw.complete(to: text.count)
                withAnimation { iconPulse = 1.0 }
            }
        }
        .onChange(of: isActive) { _, active in
            startIconPulse()
        }
    }

    private func startIconPulse() {
        guard isActive && !isCompleted else { return }
        withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
            iconPulse = 1.14
        }
    }
}

// MARK: - Typewriter timer (class for stable identity across re-renders)

private final class TypewriterTimer: ObservableObject {
    @Published private(set) var count = 0
    private var timer: Timer?

    func start(maxChars: Int, interval: TimeInterval = 0.026) {
        timer?.invalidate()
        count = 0
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] t in
            guard let self else { t.invalidate(); return }
            if self.count < maxChars { self.count += 1 }
            else { t.invalidate() }
        }
    }

    func complete(to max: Int) {
        timer?.invalidate()
        count = max
    }
}
