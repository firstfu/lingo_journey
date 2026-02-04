import SwiftUI

struct TranslationOverlayView: View {
    let result: ScanResult
    let containerSize: CGSize
    let onTap: () -> Void

    var body: some View {
        // 只有當有翻譯結果時才顯示
        if let translatedText = result.translatedText {
            Button(action: onTap) {
                Text(translatedText)
                    .font(.system(size: fontSize, weight: .semibold))
                    .foregroundStyle(Color.black)
                    .lineLimit(2)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white.opacity(0.92))
                            .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 1)
                    )
            }
            .buttonStyle(.plain)
            .position(overlayPosition)
        }
    }

    private var overlayPosition: CGPoint {
        let box = result.boundingBox
        return CGPoint(x: box.midX, y: box.midY)
    }

    private var fontSize: CGFloat {
        let boxHeight = result.boundingBox.height
        return min(max(boxHeight * 0.45, 13), 22)
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.3)
        TranslationOverlayView(
            result: ScanResult(
                originalText: "Hello World",
                translatedText: "你好世界",
                boundingBox: CGRect(x: 150, y: 300, width: 200, height: 40),
                isTranslating: false
            ),
            containerSize: CGSize(width: 400, height: 800),
            onTap: {}
        )
    }
}
