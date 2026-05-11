import SwiftUI

struct AnalyzingView: View {
    @State private var dotScales: [CGFloat] = [1, 1, 1]

    var body: some View {
        VStack(spacing: 28) {
            HStack(spacing: 10) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(Color(hex: "#1A1A1A"))
                        .frame(width: 11, height: 11)
                        .scaleEffect(dotScales[i])
                        .animation(
                            .easeInOut(duration: 0.55)
                                .repeatForever(autoreverses: true)
                                .delay(Double(i) * 0.18),
                            value: dotScales[i]
                        )
                }
            }

            Text("Analyzing…")
                .font(.system(size: 22, weight: .medium, design: .rounded))
                .foregroundColor(Color(hex: "#1A1A1A"))
        }
        .onAppear {
            for i in 0..<3 {
                dotScales[i] = 1.55
            }
        }
    }
}
