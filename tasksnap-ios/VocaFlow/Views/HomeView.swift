import SwiftUI

enum CapturePhase: Equatable {
    case idle
    case recording
    case analyzing
    case success
    case failure(String)
}

struct HomeView: View {
    @EnvironmentObject var authState: AuthState
    @EnvironmentObject var trigger: RecordingTrigger

    @StateObject  private var recorder  = AudioRecorder()
    // Observe so the view re-renders when the Action Button starts/stops a recording.
    @ObservedObject private var bgService = BackgroundRecordingService.shared

    @State private var phase: CapturePhase = .idle

    var body: some View {
        ZStack {
            Color.cream.ignoresSafeArea()

            VStack(spacing: 0) {
                navbar

                Spacer()

                if bgService.isRecording {
                    // App opened while Action Button recording is in progress.
                    actionButtonRecordingView
                } else {
                    foregroundCaptureView
                }

                Spacer()

                if phase == .idle && !bgService.isRecording {
                    Text("Hold to record · release to send")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 40)
                        .transition(.opacity)
                }
            }
        }
        .onAppear {
            trigger.checkUserDefaults()
            handleTrigger()
        }
        .onChange(of: trigger.pendingStart) { _, pending in
            if pending { handleTrigger() }
        }
        // If Action Button starts a recording while the app is open, stop the
        // foreground recorder to avoid two taps fighting over the microphone.
        .onChange(of: bgService.isRecording) { _, bgRecording in
            if bgRecording && phase == .recording {
                _ = recorder.stopRecording()
                withAnimation { phase = .idle }
            }
        }
    }

    // MARK: - Nav bar

    private var navbar: some View {
        HStack {
            Text("VocaFlow")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
            Spacer()
            Button {
                authState.logOut()
            } label: {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    // MARK: - Action Button in-progress view

    private var actionButtonRecordingView: some View {
        VStack(spacing: 32) {
            // Decorative waveform (no live FFT — mic is owned by BackgroundRecordingService)
            IdleWaveformView()
                .padding(.horizontal, 28)

            VStack(spacing: 8) {
                Text("Recording via Action Button")
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                Text("Press Action Button again or tap Stop to finish")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                Task { await bgService.stopAndUpload() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "stop.fill")
                    Text("Stop & Send")
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(Color.red)
                .foregroundColor(.white)
                .clipShape(Capsule())
            }
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }

    // MARK: - Normal foreground capture view

    private var foregroundCaptureView: some View {
        ZStack {
            switch phase {
            case .idle, .recording:
                recordingStage
                    .transition(.opacity)

            case .analyzing:
                AnalyzingView()
                    .transition(.opacity.combined(with: .scale(scale: 0.92)))

            case .success:
                SuccessView {
                    withAnimation(.easeInOut(duration: 0.35)) { phase = .idle }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.92)))

            case .failure(let msg):
                ErrorView(message: msg) {
                    withAnimation(.easeInOut(duration: 0.25)) { phase = .idle }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.92)))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: phase)
    }

    // MARK: - Recording stage

    private var recordingStage: some View {
        VStack(spacing: 44) {
            Group {
                if case .recording = phase {
                    WaveformView(bands: recorder.frequencyBands, color: Color(hex: "#1A1A1A"))
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                } else {
                    IdleWaveformView()
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: phase == .recording)
            .padding(.horizontal, 28)

            MicButton(
                isRecording: phase == .recording,
                onStart:     startRecording,
                onStop:      stopAndSend
            )
        }
    }

    // MARK: - Foreground recording actions

    private func handleTrigger() {
        guard trigger.pendingStart else { return }
        trigger.consume()
        // Ignore if Action Button recording is already in progress.
        guard !bgService.isRecording else { return }
        if phase == .recording { stopAndSend() }
        else if phase == .idle { startRecording() }
    }

    private func startRecording() {
        // Don't start if Action Button already owns the microphone.
        guard !bgService.isRecording else { return }
        do {
            try recorder.startRecording()
            LiveActivityManager.shared.start()
            withAnimation { phase = .recording }
        } catch {
            withAnimation { phase = .failure(error.localizedDescription) }
        }
    }

    private func stopAndSend() {
        LiveActivityManager.shared.stop()
        guard let url = recorder.stopRecording() else {
            withAnimation { phase = .idle }
            return
        }
        withAnimation { phase = .analyzing }

        Task {
            do {
                let data = try Data(contentsOf: url)
                try await SupabaseService.shared.captureTask(audioData: data)
                try? FileManager.default.removeItem(at: url)
                await MainActor.run {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.65)) {
                        phase = .success
                    }
                }
            } catch {
                await MainActor.run {
                    withAnimation { phase = .failure(error.localizedDescription) }
                }
            }
        }
    }
}
