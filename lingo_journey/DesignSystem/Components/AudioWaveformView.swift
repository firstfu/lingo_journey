import SwiftUI

struct AudioWaveformView: View {
    let audioLevel: Float
    let barCount: Int = 5

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<barCount, id: \.self) { index in
                AudioWaveformBar(
                    height: barHeight(for: index),
                    isActive: audioLevel > 0
                )
            }
        }
        .frame(height: 32)
    }

    private func barHeight(for index: Int) -> CGFloat {
        let baseHeight: CGFloat = 8
        let maxHeight: CGFloat = 32
        let variation = sin(Double(index) * 0.8) * 0.3 + 0.7
        let level = CGFloat(audioLevel) * variation
        return baseHeight + (maxHeight - baseHeight) * level
    }
}

private struct AudioWaveformBar: View {
    let height: CGFloat
    let isActive: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(Color.appPrimary)
            .frame(width: 4, height: height)
            .animation(.easeInOut(duration: 0.1), value: height)
    }
}

#Preview {
    VStack(spacing: 20) {
        AudioWaveformView(audioLevel: 0.0)
        AudioWaveformView(audioLevel: 0.3)
        AudioWaveformView(audioLevel: 0.7)
        AudioWaveformView(audioLevel: 1.0)
    }
    .padding()
    .background(Color.appBackground)
}
