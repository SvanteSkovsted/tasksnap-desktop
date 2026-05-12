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

            VStack(spacing: 0) {
                navbar
                Spacer()
                centerStage
                Spacer()
                bottomSection
            }
        }
        .onAppear(perform: handleAutoStart)
        .animation(.easeInOut(duration: 0.35), value: phase)
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

    // MARK: - Center stage

    @ViewBuilder
    private var centerStage: some View {
        switch phase {
        case .idle, .recording:
            micStage
                .transition(.opacity)
        case .analyzing:
            AnalyzingView()
                .transition(.opacity.combined(with: .scale(scale: 0.94)))
        case .success(let title):
            SuccessView(taskTitle: title) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                    phase = .idle
                }
            }
            .transition(.opacity.combined(with: .scale(scale: 0.9)))
        case .error(let msg):
            ErrorView(message: msg) {
                withAnimation { phase = .idle }
            }
            .transition(.opacity.combined(with: .scale(scale: 0.94)))
        }
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
        // Small delay so the screen has rendered before recording starts.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { startRecording() }
    }

    private func handleTap() {
        switch phase {
        case .idle:     startRecording()
        case .recording: stopAndSend()
        default:        break
        }
    }

    private func startRecording() {
        do {
            try recorder.startRecording()
            LiveActivityManager.shared.start()
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
        LiveActivityManager.shared.setAnalyzing()
        withAnimation { phase = .analyzing }

        Task {
            do {
                let data  = try Data(contentsOf: url)
                let title = try await SupabaseService.shared.captureTask(audioData: data)
                try? FileManager.default.removeItem(at: url)
                await MainActor.run {
                    LiveActivityManager.shared.complete()
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.65)) {
                        phase = .success(title)
                    }
                }
            } catch {
                await MainActor.run {
                    LiveActivityManager.shared.stop()
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
            // Gold expanding rings while recording
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

            // Subtle idle breathe ring
            if !isRecording {
                Circle()
                    .stroke(Color.dark.opacity(0.07), lineWidth: 1)
                    .frame(width: 148, height: 148)
                    .scaleEffect(idlePulse)
                    .animation(
                        .easeInOut(duration: 2.8).repeatForever(autoreverses: true),
                        value: idlePulse
                    )
            }

            // Main button
            Circle()
                .fill(
                    isRecording
                        ? AnyShapeStyle(Color.red)
                        : AnyShapeStyle(Color.dark)
                )
                .frame(width: 120, height: 120)
                .shadow(
                    color: isRecording
                        ? Color.red.opacity(0.4)
                        : Color.dark.opacity(0.22),
                    radius: isRecording ? 28 : 14,
                    y: 6
                )
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
