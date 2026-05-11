import SwiftUI

struct ErrorView: View {
    let message: String
    let onRetry: () -> Void

    @State private var appear = false

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.10))
                    .frame(width: 118, height: 118)

                Image(systemName: "xmark")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundColor(.red)
            }
            .scaleEffect(appear ? 1 : 0.5)
            .opacity(appear ? 1 : 0)

            Text(message)
                .font(.callout)
                .foregroundColor(Color.dark.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .opacity(appear ? 1 : 0)

            Button(action: onRetry) {
                Text("Try again")
                    .fontWeight(.medium)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(Color(hex: "#1A1A1A"))
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
            .opacity(appear ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.65)) {
                appear = true
            }
        }
    }
}
