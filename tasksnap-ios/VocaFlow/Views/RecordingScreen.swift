import SwiftUI

enum RecordingPhase: Equatable {
    case idle
    case recording
    case analyzing
    case success(String?)
    case error(String)
}

struct RecordingScreen: View {
    @EnvironmentObject var authState: AuthState
    @StateObject private var recorder = AudioRecorder()
    @State private var phase: RecordingPhase = .idle

    var body: some View {
        ZStack {
            Color.cream.ignoresSafeArea()

            // ── Base mic UI ────────────────────────────────────────────
            VStack(spacing: 0) {
                navbar
                Spacer()
                if phase == .idle || phase == .recording {
                    micStage
                        .transition(.opacity)
                }
                Spacer()
                bottomSection
            }

            // ── Full-screen overlays ───────────────────────────────────
            if case .analyzing = phase {
                AnalyzingView()
                    .ignoresSafeArea()
                    .transition(.opacity)
            }

            if case .success(let title) = phase {
                ZStack {
                    Color.cream.ignoresSafeArea()
                    SuccessView(taskTitle: title) {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) {
                            phase = .idle
                        }
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal:   .opacity
                ))
            }

            if case .error(let msg) = phase {
                ZStack {
                    Color.cream.ignoresSafeArea()
                    ErrorView(message: msg) {
                        withAnimation { phase = .idle }
                    }
                    .padding(.horizontal, 28)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .animation(.spring(response: 0.52, dampingFraction: 0.78), value: phase)
        .onAppear(perform: handleAutoStart)
    }

    // MARK: - Nav

    private var navbar: some View {
        HStack {
            Text("VocaFlow")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundColor(Color.dark)
            Spacer()
            Button {
                authState.logOut()
            } label: {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color.dark.opacity(0.4))
            }
        }
        .padding(.horizontal, 28)
        .padding(.top, 20)
    }

    // MARK: - Mic stage

    private var micStage: some View {
        VStack(spacing: 40) {
            Text(phase == .recording ? "Tap to stop & send" : "Tap to record")
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundColor(Color.dark.opacity(0.4))
                .animation(.easeInOut(duration: 0.2), value: phase == .recording)

            TapMicButton(isRecording: phase == .recording, onTap: handleTap)
        }
    }

    // MARK: - Bottom waveform

    private var bottomSection: some View {
        Group {
            if phase == .recording {
                WaveformView(bands: recorder.frequencyBands, color: Color.dark)
                    .frame(height: 100)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 52)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                Color.clear.frame(height: 152)
            }
        }
    }

    // MARK: - Actions

    private func handleAutoStart() {
        guard UserDefaults.standard.bool(forKey: "vocaflow.autoStart") else { return }
        UserDefaults.standard.set(false, forKey: "vocaflow.autoStart")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { startRecording() }
    }

    private func handleTap() {
        switch phase {
        case .idle:      startRecording()
        case .recording: stopAndSend()
        default:         break
        }
    }

    private func startRecording() {
        do {
            try recorder.startRecording()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { phase = .recording }
        } catch {
            withAnimation { phase = .error(error.localizedDescription) }
        }
    }

    private func stopAndSend() {
        guard let url = recorder.stopRecording() else {
            withAnimation { phase = .idle }
            return
        }
        withAnimation { phase = .analyzing }
        let startedAt = Date()

        Task {
            do {
                let data  = try Data(contentsOf: url)
                let title = try await SupabaseService.shared.captureTask(audioData: data)
                try? FileManager.default.removeItem(at: url)

                // Keep AnalyzingView on screen until all 5 steps complete (~4.3s)
                // plus a brief pause so the user sees the last checkmark.
                let elapsed  = Date().timeIntervalSince(startedAt)
                let minTotal = 4.8
                if elapsed < minTotal {
                    try await Task.sleep(nanoseconds: UInt64((minTotal - elapsed) * 1_000_000_000))
                }

                await MainActor.run {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.72)) {
                        phase = .success(title)
                    }
                }
            } catch {
                await MainActor.run {
                    withAnimation { phase = .error(error.localizedDescription) }
                }
            }
        }
    }
}

// MARK: - Tap mic button

private struct TapMicButton: View {
    let isRecording: Bool
    let onTap: () -> Void

    @State private var pulseScale: CGFloat = 1.0
    @State private var idlePulse: CGFloat  = 1.0

    var body: some View {
        ZStack {
            if isRecording {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .stroke(
                            LinearGradient(colors: [Color(hex: "#D4AF37").opacity(0.35),
                                                    Color.red.opacity(0.15)],
                                           startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 1.5
                        )
                        .frame(width: 148 + CGFloat(i) * 38,
                               height: 148 + CGFloat(i) * 38)
                        .scaleEffect(pulseScale)
                        .animation(
                            .easeOut(duration: 1.6)
                                .repeatForever(autoreverses: false)
                                .delay(Double(i) * 0.45),
                            value: pulseScale
                        )
                }
            }

            if !isRecording {
                Circle()
                    .stroke(Color.dark.opacity(0.07), lineWidth: 1)
                    .frame(width: 148, height: 148)
                    .scaleEffect(idlePulse)
                    .animation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true), value: idlePulse)
            }

            Circle()
                .fill(isRecording ? AnyShapeStyle(Color.red) : AnyShapeStyle(Color.dark))
                .frame(width: 120, height: 120)
                .shadow(color: isRecording ? Color.red.opacity(0.4) : Color.dark.opacity(0.22),
                        radius: isRecording ? 28 : 14, y: 6)
                .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isRecording)

            Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                .font(.system(size: 44, weight: .medium))
                .foregroundColor(Color.cream)
                .scaleEffect(isRecording ? 0.82 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isRecording)
        }
        .onTapGesture(perform: onTap)
        .onAppear { idlePulse = 1.06 }
        .onChange(of: isRecording) { _, recording in
            pulseScale = recording ? 1.65 : 1.0
        }
    }
}
