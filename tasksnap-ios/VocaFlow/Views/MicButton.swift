import SwiftUI

struct MicButton: View {
    let isRecording: Bool
    let onStart: () -> Void
    let onStop: () -> Void

    @State private var isPressed = false
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            // Pulse rings while recording
            if isRecording {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .stroke(Color.red.opacity(0.15 - Double(i) * 0.04), lineWidth: 1)
                        .frame(width: 120 + CGFloat(i) * 30, height: 120 + CGFloat(i) * 30)
                        .scaleEffect(pulseScale)
                        .animation(
                            .easeOut(duration: 1.2)
                                .repeatForever(autoreverses: false)
                                .delay(Double(i) * 0.3),
                            value: pulseScale
                        )
                }
            }

            // Core button
            Circle()
                .fill(isRecording ? Color.red : Color(hex: "#1A1A1A"))
                .frame(width: 108, height: 108)
                .shadow(
                    color: isRecording ? Color.red.opacity(0.45) : Color.black.opacity(0.22),
                    radius: isRecording ? 24 : 10,
                    y: isRecording ? 4 : 6
                )
                .scaleEffect(isPressed ? 0.93 : 1.0)
                .animation(.spring(response: 0.25, dampingFraction: 0.6), value: isPressed)

            Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                .font(.system(size: 38, weight: .medium))
                .foregroundColor(.white)
                .scaleEffect(isPressed ? 0.88 : 1.0)
                .animation(.spring(response: 0.25, dampingFraction: 0.5), value: isPressed)
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard !isPressed else { return }
                    isPressed = true
                    if !isRecording { onStart() }
                }
                .onEnded { _ in
                    isPressed = false
                    if isRecording { onStop() }
                }
        )
        .onChange(of: isRecording) { _, recording in
            if recording {
                withAnimation { pulseScale = 1.6 }
            } else {
                pulseScale = 1.0
            }
        }
    }
}
