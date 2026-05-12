import SwiftUI
import AVFoundation

// MARK: - Container

struct OnboardingView: View {
    @Binding var isComplete: Bool
    @State private var page = 0
    @State private var goingForward = true

    var body: some View {
        ZStack {
            Color.cream.ignoresSafeArea()

            // Page area
            ZStack {
                switch page {
                case 0: WelcomeScreen(onNext: advance)
                        .transition(pageTransition)
                        .id(0)
                case 1: HowItWorksScreen(onNext: advance)
                        .transition(pageTransition)
                        .id(1)
                case 2: SmartAIScreen(onNext: advance)
                        .transition(pageTransition)
                        .id(2)
                case 3: MicPermissionScreen(onNext: advance)
                        .transition(pageTransition)
                        .id(3)
                default: ReadyScreen(onComplete: finish)
                        .transition(pageTransition)
                        .id(4)
                }
            }
            .animation(.spring(response: 0.52, dampingFraction: 0.8), value: page)

            // Progress pills
            VStack {
                Spacer()
                HStack(spacing: 7) {
                    ForEach(0..<5, id: \.self) { i in
                        Capsule()
                            .fill(i == page ? Color.dark : Color.dark.opacity(0.16))
                            .frame(width: i == page ? 22 : 7, height: 7)
                            .animation(.spring(response: 0.38, dampingFraction: 0.7), value: page)
                    }
                }
                .padding(.bottom, 44)
            }
        }
        .overlay(alignment: .topTrailing) {
            if page != 3 {
                Button("Skip") { finish() }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color.dark.opacity(0.36))
                    .padding(.top, 60)
                    .padding(.trailing, 24)
            }
        }
    }

    private var pageTransition: AnyTransition {
        goingForward
            ? .asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                          removal:   .move(edge: .leading).combined(with: .opacity))
            : .asymmetric(insertion: .move(edge: .leading).combined(with: .opacity),
                          removal:   .move(edge: .trailing).combined(with: .opacity))
    }

    private func advance() {
        goingForward = true
        guard page < 4 else { finish(); return }
        page += 1
    }

    private func finish() {
        UserDefaults.standard.set(true, forKey: "vocaflow.onboardingComplete")
        withAnimation(.easeInOut(duration: 0.4)) { isComplete = true }
    }
}

// MARK: ─── Screen 1 · Welcome ───────────────────────────────────────────────

private struct WelcomeScreen: View {
    let onNext: () -> Void
    @State private var animate = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Animated wave background (subtle)
            ZStack {
                WaveBackground()
                    .frame(height: 220)
                    .opacity(0.6)

                // Pulsing mic rings + icon
                ZStack {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .stroke(Color.dark.opacity(0.06 - Double(i) * 0.015), lineWidth: 1.5)
                            .frame(width: 110 + CGFloat(i) * 44,
                                   height: 110 + CGFloat(i) * 44)
                            .scaleEffect(animate ? 1.0 : 0.6)
                            .opacity(animate ? 1 : 0)
                            .animation(
                                .spring(response: 0.7, dampingFraction: 0.6)
                                    .delay(0.2 + Double(i) * 0.12),
                                value: animate
                            )
                    }

                    // Breathing outer ring
                    Circle()
                        .stroke(Color.dark.opacity(0.08), lineWidth: 1)
                        .frame(width: 100, height: 100)
                        .scaleEffect(animate ? 1.08 : 1.0)
                        .animation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true), value: animate)

                    // Core button
                    Circle()
                        .fill(Color.dark)
                        .frame(width: 86, height: 86)
                        .shadow(color: Color.dark.opacity(0.22), radius: 18, y: 6)
                        .scaleEffect(animate ? 1 : 0.5)
                        .opacity(animate ? 1 : 0)
                        .animation(.spring(response: 0.55, dampingFraction: 0.65).delay(0.1), value: animate)

                    Image(systemName: "mic.fill")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(Color.cream)
                        .scaleEffect(animate ? 1 : 0.3)
                        .opacity(animate ? 1 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.2), value: animate)
                }
            }
            .frame(height: 220)

            Spacer().frame(height: 48)

            // Wordmark + tagline
            VStack(spacing: 14) {
                Text("VocaFlow")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundColor(Color.dark)
                    .offset(y: animate ? 0 : 24)
                    .opacity(animate ? 1 : 0)
                    .animation(.spring(response: 0.55, dampingFraction: 0.72).delay(0.3), value: animate)

                Text("Your voice, organized instantly")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(Color.dark.opacity(0.45))
                    .offset(y: animate ? 0 : 16)
                    .opacity(animate ? 1 : 0)
                    .animation(.spring(response: 0.55, dampingFraction: 0.72).delay(0.42), value: animate)
            }

            Spacer()

            OnboardingButton("Get Started", action: onNext)
                .offset(y: animate ? 0 : 30)
                .opacity(animate ? 1 : 0)
                .animation(.spring(response: 0.55, dampingFraction: 0.75).delay(0.54), value: animate)
                .padding(.bottom, 110)
        }
        .onAppear { animate = true }
    }
}

// MARK: ─── Screen 2 · How it works ─────────────────────────────────────────

private struct HowItWorksScreen: View {
    let onNext: () -> Void
    @State private var showPhone    = false
    @State private var flashButton  = false
    @State private var showWaveform = false
    @State private var showCard     = false
    @State private var showText     = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Demo illustration
            ZStack(alignment: .bottom) {
                // Phone frame
                RoundedRectangle(cornerRadius: 30)
                    .stroke(Color.dark, lineWidth: 2)
                    .frame(width: 140, height: 240)
                    .background(
                        RoundedRectangle(cornerRadius: 30)
                            .fill(Color.white.opacity(0.55))
                    )
                    .overlay(alignment: .trailing) {
                        // Action button highlight
                        RoundedRectangle(cornerRadius: 3)
                            .fill(flashButton ? Color(hex: "#D4AF37") : Color.dark.opacity(0.35))
                            .frame(width: 5, height: 36)
                            .offset(x: 3.5, y: -50)
                            .animation(.spring(response: 0.25, dampingFraction: 0.5), value: flashButton)
                    }
                    .scaleEffect(showPhone ? 1 : 0.7)
                    .opacity(showPhone ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.68), value: showPhone)

                // Waveform inside phone
                if showWaveform {
                    AnimWaveform()
                        .frame(width: 110, height: 36)
                        .padding(.bottom, 20)
                        .transition(.opacity.combined(with: .scale(scale: 0.85)))
                }
            }
            .frame(width: 160, height: 260)

            // Task card slides in
            if showCard {
                TaskPreviewCard()
                    .padding(.top, 20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                Color.clear.frame(height: 70)
            }

            Spacer().frame(height: 36)

            // Text
            VStack(spacing: 10) {
                Text("One press. That's all it takes.")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(Color.dark)
                    .multilineTextAlignment(.center)

                Text("Press the Action Button and speak.\nVocaFlow does the rest.")
                    .font(.system(size: 15))
                    .foregroundColor(Color.dark.opacity(0.45))
                    .multilineTextAlignment(.center)
            }
            .opacity(showText ? 1 : 0)
            .offset(y: showText ? 0 : 12)
            .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.1), value: showText)

            Spacer()
            OnboardingButton("Continue", action: onNext)
                .opacity(showText ? 1 : 0)
                .padding(.bottom, 110)
        }
        .padding(.horizontal, 32)
        .onAppear(perform: runSequence)
    }

    private func runSequence() {
        after(0.2) { showPhone    = true }
        after(0.8) { withAnimation(.easeInOut(duration: 0.18)) { flashButton = true } }
        after(1.1) { withAnimation(.easeInOut(duration: 0.18)) { flashButton = false } }
        after(1.4) { withAnimation(.easeInOut(duration: 0.18)) { flashButton = true } }
        after(1.7) { withAnimation { showWaveform = true } }
        after(2.6) { withAnimation(.spring(response: 0.55, dampingFraction: 0.7)) { showCard = true } }
        after(2.9) { showText = true }
    }

    private func after(_ s: Double, _ block: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + s, execute: block)
    }
}

// MARK: ─── Screen 3 · Smart AI ──────────────────────────────────────────────

private struct SmartAIScreen: View {
    let onNext: () -> Void
    @State private var animate = false

    private let features: [(String, String, String, String)] = [
        ("bolt.fill",         "#D4AF37", "Priority Detection",  "Identifies urgency and flags what needs attention first"),
        ("calendar",          "#5856D6", "Date Extraction",     "Picks up dates, times and deadlines from natural speech"),
        ("bell.badge.fill",   "#34C759", "Smart Reminders",     "Sets contextual reminders based on what you described"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Header
            VStack(spacing: 10) {
                Text("Built-in AI")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(Color.dark)

                Text("AI understands context,\nurgency and time")
                    .font(.system(size: 15))
                    .foregroundColor(Color.dark.opacity(0.45))
                    .multilineTextAlignment(.center)
            }
            .opacity(animate ? 1 : 0)
            .offset(y: animate ? 0 : 20)
            .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.05), value: animate)

            Spacer().frame(height: 36)

            // Feature cards
            VStack(spacing: 14) {
                ForEach(Array(features.enumerated()), id: \.offset) { i, f in
                    AIFeatureCard(icon: f.0, color: f.1, title: f.2, description: f.3)
                        .offset(x: animate ? 0 : 60)
                        .opacity(animate ? 1 : 0)
                        .animation(
                            .spring(response: 0.55, dampingFraction: 0.72)
                                .delay(0.18 + Double(i) * 0.14),
                            value: animate
                        )
                }
            }

            Spacer()

            OnboardingButton("Continue", action: onNext)
                .opacity(animate ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.62), value: animate)
                .padding(.bottom, 110)
        }
        .padding(.horizontal, 28)
        .onAppear { animate = true }
    }
}

// MARK: ─── Screen 4 · Microphone permission ─────────────────────────────────

private struct MicPermissionScreen: View {
    let onNext: () -> Void
    @State private var status: MicStatus = .idle
    @State private var micScale: CGFloat = 1.0

    enum MicStatus { case idle, granted, denied }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Mic illustration
            ZStack {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .stroke(micRingColor.opacity(0.1 - Double(i) * 0.025), lineWidth: 1.5)
                        .frame(width: 110 + CGFloat(i) * 40, height: 110 + CGFloat(i) * 40)
                        .scaleEffect(micScale)
                        .animation(
                            .easeInOut(duration: 1.8 + Double(i) * 0.3)
                                .repeatForever(autoreverses: true)
                                .delay(Double(i) * 0.4),
                            value: micScale
                        )
                }

                Circle()
                    .fill(micFill)
                    .frame(width: 96, height: 96)
                    .shadow(color: micShadow, radius: 20, y: 6)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: status)

                Image(systemName: micIcon)
                    .font(.system(size: 36, weight: .medium))
                    .foregroundColor(.white)
                    .animation(.spring(response: 0.35), value: status)
            }
            .onAppear { micScale = 1.08 }

            Spacer().frame(height: 44)

            // Text
            VStack(spacing: 12) {
                Text("Allow Microphone")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(Color.dark)

                Text("VocaFlow needs your microphone\nto capture voice tasks instantly.")
                    .font(.system(size: 15))
                    .foregroundColor(Color.dark.opacity(0.45))
                    .multilineTextAlignment(.center)
            }

            Spacer().frame(height: 40)

            // Action
            switch status {
            case .idle:
                OnboardingButton("Allow Microphone Access") { requestPermission() }

            case .granted:
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                    Text("Microphone enabled")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color.dark)
                }
                .transition(.scale.combined(with: .opacity))

            case .denied:
                VStack(spacing: 14) {
                    Text("Microphone access denied")
                        .font(.system(size: 15))
                        .foregroundColor(Color.dark.opacity(0.5))

                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color.dark)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.dark.opacity(0.08))
                    .clipShape(Capsule())
                }
                .transition(.opacity)
            }

            Spacer().frame(height: 20)

            if status != .idle {
                Button(status == .denied ? "Continue anyway" : "Continue") { onNext() }
                    .font(.system(size: 15))
                    .foregroundColor(Color.dark.opacity(0.45))
                    .transition(.opacity)
            }

            Spacer()
        }
        .padding(.horizontal, 32)
        .animation(.spring(response: 0.45, dampingFraction: 0.72), value: status)
    }

    private var micIcon: String {
        switch status {
        case .idle:    return "mic.fill"
        case .granted: return "mic.fill"
        case .denied:  return "mic.slash.fill"
        }
    }
    private var micFill: some ShapeStyle {
        switch status {
        case .idle:    return AnyShapeStyle(Color.dark)
        case .granted: return AnyShapeStyle(Color.green)
        case .denied:  return AnyShapeStyle(Color.red)
        }
    }
    private var micRingColor: Color {
        switch status {
        case .idle:    return Color.dark
        case .granted: return .green
        case .denied:  return .red
        }
    }
    private var micShadow: Color {
        switch status {
        case .idle:    return Color.dark.opacity(0.22)
        case .granted: return Color.green.opacity(0.3)
        case .denied:  return Color.red.opacity(0.25)
        }
    }

    private func requestPermission() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                withAnimation { status = granted ? .granted : .denied }
                if granted {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { onNext() }
                }
            }
        }
    }
}

// MARK: ─── Screen 5 · Ready ─────────────────────────────────────────────────

private struct ReadyScreen: View {
    let onComplete: () -> Void
    @State private var animate   = false
    @State private var particles = [ConfettiParticle]()
    @State private var burst     = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Confetti layer
                ForEach(particles) { p in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(p.color)
                        .frame(width: p.w, height: p.h)
                        .rotationEffect(.degrees(burst ? p.endRot : p.startRot))
                        .position(burst ? p.end : p.start)
                        .opacity(burst ? 0 : 1)
                        .animation(
                            .spring(response: 0.9, dampingFraction: 0.65)
                                .delay(p.delay),
                            value: burst
                        )
                }

                VStack(spacing: 0) {
                    Spacer()

                    // Checkmark
                    ZStack {
                        Circle()
                            .fill(Color.dark)
                            .frame(width: 96, height: 96)
                            .shadow(color: Color.dark.opacity(0.22), radius: 20, y: 6)
                            .scaleEffect(animate ? 1 : 0.4)
                            .opacity(animate ? 1 : 0)
                            .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.05), value: animate)

                        Image(systemName: "checkmark")
                            .font(.system(size: 38, weight: .bold))
                            .foregroundColor(Color.cream)
                            .scaleEffect(animate ? 1 : 0.2)
                            .opacity(animate ? 1 : 0)
                            .animation(.spring(response: 0.45, dampingFraction: 0.55).delay(0.18), value: animate)
                    }

                    Spacer().frame(height: 32)

                    Text("You're all set!")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundColor(Color.dark)
                        .offset(y: animate ? 0 : 20)
                        .opacity(animate ? 1 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.28), value: animate)

                    Spacer().frame(height: 14)

                    Text("VocaFlow is ready to capture\nyour ideas the moment they strike.")
                        .font(.system(size: 15))
                        .foregroundColor(Color.dark.opacity(0.45))
                        .multilineTextAlignment(.center)
                        .offset(y: animate ? 0 : 14)
                        .opacity(animate ? 1 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.38), value: animate)

                    Spacer().frame(height: 36)

                    // Action Button tip
                    HStack(spacing: 12) {
                        Image(systemName: "iphone.gen3.radiowaves.left.and.right")
                            .font(.system(size: 22))
                            .foregroundColor(Color.dark.opacity(0.5))

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Tip: set your Action Button")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Color.dark)
                            Text("Settings → Action Button → VocaFlow")
                                .font(.system(size: 12))
                                .foregroundColor(Color.dark.opacity(0.45))
                        }
                    }
                    .padding(16)
                    .background(Color.dark.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .opacity(animate ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.5), value: animate)

                    Spacer()

                    OnboardingButton("Start Using VocaFlow", action: onComplete)
                        .opacity(animate ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(0.58), value: animate)
                        .padding(.bottom, 110)
                }
                .padding(.horizontal, 32)
            }
            .onAppear {
                spawnConfetti(in: geo.size)
                animate = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation { burst = true }
                }
            }
        }
    }

    private func spawnConfetti(in size: CGSize) {
        let colors: [Color] = [Color(hex: "#D4AF37"), .red, Color(hex: "#5856D6"),
                               .green, .orange, Color(hex: "#FF2D55")]
        let origin = CGPoint(x: size.width / 2, y: size.height * 0.28)
        particles = (0..<70).map { _ in
            let angle  = Double.random(in: 0...(2 * .pi))
            let dist   = CGFloat.random(in: 70...210)
            return ConfettiParticle(
                start:    origin,
                end:      CGPoint(x: origin.x + cos(angle) * dist,
                                  y: origin.y + sin(angle) * dist + CGFloat.random(in: 40...160)),
                color:    colors.randomElement()!,
                w:        CGFloat.random(in: 7...13),
                h:        CGFloat.random(in: 4...8),
                startRot: Double.random(in: 0...360),
                endRot:   Double.random(in: 180...540),
                delay:    Double.random(in: 0...0.25)
            )
        }
    }
}

// MARK: - Shared helpers

private struct ConfettiParticle: Identifiable {
    let id    = UUID()
    let start, end: CGPoint
    let color: Color
    let w, h: CGFloat
    let startRot, endRot: Double
    let delay: Double
}

// Animated waveform (HowItWorks demo)
private struct AnimWaveform: View {
    @State private var on = false
    private let heights: [CGFloat] = [6, 16, 10, 22, 14, 24, 8, 18, 12, 20, 7, 16]

    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            ForEach(Array(heights.enumerated()), id: \.offset) { i, h in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.dark)
                    .frame(width: 5, height: on ? h : 4)
                    .animation(
                        .easeInOut(duration: 0.42 + Double(i % 4) * 0.08)
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.06),
                        value: on
                    )
            }
        }
        .onAppear { on = true }
    }
}

// Task preview card (HowItWorks demo)
private struct TaskPreviewCard: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(Color(hex: "#D4AF37"))
                .font(.title3)

            VStack(alignment: .leading, spacing: 4) {
                Text("Call dentist")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color.dark)
                HStack(spacing: 4) {
                    Image(systemName: "calendar").font(.caption2)
                    Text("Tomorrow, 2 pm")
                        .font(.caption)
                }
                .foregroundColor(Color.dark.opacity(0.45))
            }

            Spacer()

            RoundedRectangle(cornerRadius: 6)
                .fill(Color.red.opacity(0.12))
                .frame(width: 52, height: 22)
                .overlay(
                    Text("Urgent").font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.red)
                )
        }
        .padding(16)
        .background(Color.white.opacity(0.75))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.dark.opacity(0.07), radius: 14, y: 4)
    }
}

// AI feature card (SmartAI screen)
private struct AIFeatureCard: View {
    let icon: String
    let color: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: color).opacity(0.14))
                    .frame(width: 48, height: 48)
                Image(systemName: icon)
                    .foregroundColor(Color(hex: color))
                    .font(.system(size: 20, weight: .semibold))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color.dark)
                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(Color.dark.opacity(0.45))
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(16)
        .background(Color.white.opacity(0.65))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.dark.opacity(0.06), radius: 10, y: 3)
    }
}

// Animated sine-wave background (Welcome screen)
private struct WaveBackground: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1/30)) { tl in
            Canvas { ctx, size in
                let t = tl.date.timeIntervalSinceReferenceDate * 0.38
                for layer in 0..<4 {
                    let amp   = 12.0 + Double(layer) * 8
                    let freq  = 1.8 + Double(layer) * 0.4
                    let phase = t + Double(layer) * 1.1
                    var path  = Path()
                    for xi in stride(from: 0.0, through: Double(size.width), by: 2.0) {
                        let y = Double(size.height) * 0.55 + amp * sin(xi / Double(size.width) * .pi * freq + phase)
                        if xi == 0 { path.move(to: CGPoint(x: xi, y: y)) }
                        else        { path.addLine(to: CGPoint(x: xi, y: y)) }
                    }
                    ctx.stroke(path,
                               with: .color(Color.dark.opacity(0.035 + Double(layer) * 0.008)),
                               lineWidth: 1.5)
                }
            }
        }
    }
}

// Reusable primary button
private struct OnboardingButton: View {
    let title: String
    let action: () -> Void
    init(_ title: String, action: @escaping () -> Void) {
        self.title  = title
        self.action = action
    }
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Color.cream)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.dark)
                        .shadow(color: Color.dark.opacity(0.22), radius: 12, y: 4)
                )
        }
    }
}
