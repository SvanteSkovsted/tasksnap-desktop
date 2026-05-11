import SwiftUI

struct SuccessView: View {
    let onDismiss: () -> Void

    @State private var ringScale: CGFloat  = 0.4
    @State private var ringOpacity: Double = 0
    @State private var checkScale: CGFloat = 0
    @State private var labelOpacity: Double = 0

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                // Expanding ring
                Circle()
                    .stroke(Color.green.opacity(0.18), lineWidth: 2)
                    .frame(width: 150, height: 150)
                    .scaleEffect(ringScale)
                    .opacity(ringOpacity)

                // Fill
                Circle()
                    .fill(Color.green.opacity(0.10))
                    .frame(width: 118, height: 118)
                    .scaleEffect(checkScale)

                // Checkmark
                Image(systemName: "checkmark")
                    .font(.system(size: 46, weight: .bold))
                    .foregroundColor(Color.green)
                    .scaleEffect(checkScale)
            }

            Text("Task created!")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundColor(Color(hex: "#1A1A1A"))
                .opacity(labelOpacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.55)) {
                checkScale = 1
            }
            withAnimation(.easeOut(duration: 0.7)) {
                ringScale   = 1.6
                ringOpacity = 1
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.15)) {
                labelOpacity = 1
            }
            // Fade ring out
            withAnimation(.easeIn(duration: 0.4).delay(0.5)) {
                ringOpacity = 0
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                onDismiss()
            }
        }
    }
}
