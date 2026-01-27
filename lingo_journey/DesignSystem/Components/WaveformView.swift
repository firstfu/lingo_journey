import SwiftUI

struct WaveformView: View {
    var audioLevel: Float
    var isActive: Bool
    var barCount: Int = 5

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<barCount, id: \.self) { index in
                WaveformBar(
                    height: barHeight(for: index),
                    isActive: isActive
                )
            }
        }
    }

    private func barHeight(for index: Int) -> CGFloat {
        guard isActive else { return 8 }

        let baseHeight: CGFloat = 8
        let maxHeight: CGFloat = 32
        let variation = sin(Double(index) * 0.8) * 0.3 + 0.7
        let level = CGFloat(audioLevel) * CGFloat(variation)

        return baseHeight + (maxHeight - baseHeight) * level
    }
}

struct WaveformBar: View {
    var height: CGFloat
    var isActive: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(Color.appPrimary)
            .frame(width: 3, height: height)
            .animation(.easeInOut(duration: 0.1), value: height)
    }
}

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        VStack(spacing: 40) {
            WaveformView(audioLevel: 0.0, isActive: false)
            WaveformView(audioLevel: 0.3, isActive: true)
            WaveformView(audioLevel: 0.7, isActive: true)
            WaveformView(audioLevel: 1.0, isActive: true)
        }
    }
}
