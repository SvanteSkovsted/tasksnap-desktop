import SwiftUI

struct SuccessView: View {
    var taskTitle: String?
    let onDismiss: () -> Void

    @State private var ringScale: CGFloat  = 0.5
    @State private var ringOpacity: Double = 0
    @State private var checkScale: CGFloat = 0
    @State private var contentOpacity: Double = 0

    var body: some View {
        VStack(spacing: 24) {
            // Checkmark
            ZStack {
                Circle()
                    .stroke(Color.green.opacity(0.15), lineWidth: 2)
                    .frame(width: 148, height: 148)
                    .scaleEffect(ringScale)
                    .opacity(ringOpacity)

                Circle()
                    .fill(Color.green.opacity(0.08))
                    .frame(width: 116, height: 116)
                    .scaleEffect(checkScale)

                Image(systemName: "checkmark")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(Color.green)
                    .scaleEffect(checkScale)
            }

            // Labels
            VStack(spacing: 8) {
                Text("Task created!")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.dark)

                if let title = taskTitle, !title.isEmpty {
                    Text("\"\(title)\"")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(Color.dark.opacity(0.5))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .lineLimit(2)
                }
            }
            .opacity(contentOpacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.55)) {
                checkScale = 1
            }
            withAnimation(.easeOut(duration: 0.65)) {
                ringScale   = 1.55
                ringOpacity = 1
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.15)) {
                contentOpacity = 1
            }
            withAnimation(.easeIn(duration: 0.35).delay(0.55)) {
                ringOpacity = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.2, execute: onDismiss)
        }
    }
}
