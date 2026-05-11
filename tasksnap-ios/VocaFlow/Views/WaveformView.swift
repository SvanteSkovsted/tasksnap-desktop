import SwiftUI

struct WaveformView: View {
    let bands: [Float]
    var color: Color = .primary

    private let barCount = 30
    private let minHeight: CGFloat = 3
    private let maxHeight: CGFloat = 110

    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            ForEach(0..<barCount, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(color.opacity(barOpacity(at: i)))
                    .frame(width: 4, height: barHeight(at: i))
                    .animation(.easeOut(duration: 0.06), value: bands[safe: i] ?? 0)
            }
        }
        .frame(height: maxHeight)
    }

    private func barHeight(at index: Int) -> CGFloat {
        let value = CGFloat(bands[safe: index] ?? 0)
        return minHeight + value * (maxHeight - minHeight)
    }

    private func barOpacity(at index: Int) -> Double {
        let value = Double(bands[safe: index] ?? 0)
        return 0.4 + value * 0.6
    }
}

// MARK: - Idle placeholder

struct IdleWaveformView: View {
    @State private var phase: CGFloat = 0

    private let barCount = 30

    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            ForEach(0..<barCount, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.secondary.opacity(0.25))
                    .frame(width: 4, height: idleHeight(for: i))
                    .animation(.easeInOut(duration: 1.6).delay(Double(i) * 0.04).repeatForever(autoreverses: true), value: phase)
            }
        }
        .frame(height: 110)
        .onAppear { phase = 1 }
    }

    private func idleHeight(for i: Int) -> CGFloat {
        let normalized = sin(CGFloat(i) / CGFloat(barCount) * .pi + phase * .pi)
        return 4 + abs(normalized) * 20
    }
}

// MARK: - Safe subscript

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
