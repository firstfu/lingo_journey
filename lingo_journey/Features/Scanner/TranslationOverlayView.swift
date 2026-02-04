import SwiftUI

struct TranslationOverlayView: View {
    let result: ScanResult
    let containerSize: CGSize
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            overlayContent
        }
        .buttonStyle(.plain)
        .position(overlayPosition)
    }

    @ViewBuilder
    private var overlayContent: some View {
        Group {
            if result.isTranslating {
                // Loading state: pulsating dots
                loadingDotsView
            } else if result.translationFailed {
                // Failed state: original text with red underline
                failedTranslationView
            } else if let translatedText = result.translatedText {
                // Success state: translated text
                translatedTextView(translatedText)
            } else {
                // Fallback: show original text
                translatedTextView(result.originalText)
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
        .background(overlayBackground)
    }

    private var loadingDotsView: some View {
        HStack(spacing: AppSpacing.sm) {
            ForEach(0..<3, id: \.self) { index in
                PulsingDot(delay: Double(index) * 0.2)
            }
        }
        .frame(minWidth: 40, minHeight: fontSize)
    }

    private var failedTranslationView: some View {
        VStack(spacing: 2) {
            Text(result.originalText)
                .font(.system(size: fontSize, weight: .medium))
                .foregroundStyle(Color.appTextPrimary)
                .lineLimit(2)

            Rectangle()
                .fill(Color.appError)
                .frame(height: 2)
        }
    }

    private func translatedTextView(_ text: String) -> some View {
        Text(text)
            .font(.system(size: fontSize, weight: .medium))
            .foregroundStyle(Color.appTextPrimary)
            .lineLimit(3)
            .multilineTextAlignment(.center)
    }

    private var overlayBackground: some View {
        RoundedRectangle(cornerRadius: AppRadius.small)
            .fill(Color.white.opacity(0.85))
            .background(
                RoundedRectangle(cornerRadius: AppRadius.small)
                    .fill(.ultraThinMaterial)
            )
            .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
    }

    private var overlayPosition: CGPoint {
        // VisionKit bounds are already in screen coordinates (pixels), not normalized
        let box = result.boundingBox
        return CGPoint(x: box.midX, y: box.midY)
    }

    private var fontSize: CGFloat {
        // boundingBox.height is already in pixels
        let boxHeight = result.boundingBox.height
        return min(max(boxHeight * 0.5, 14), 28)
    }
}

// MARK: - Pulsing Dot Animation

private struct PulsingDot: View {
    let delay: Double
    @State private var isAnimating = false

    var body: some View {
        Circle()
            .fill(Color.appTextSecondary)
            .frame(width: 8, height: 8)
            .scaleEffect(isAnimating ? 1.0 : 0.5)
            .opacity(isAnimating ? 1.0 : 0.3)
            .animation(
                Animation.easeInOut(duration: 0.6)
                    .repeatForever(autoreverses: true)
                    .delay(delay),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

// MARK: - Preview

#Preview("Translating") {
    ZStack {
        Color.gray.opacity(0.3)
        TranslationOverlayView(
            result: ScanResult(
                originalText: "Hello World",
                boundingBox: CGRect(x: 100, y: 300, width: 200, height: 40),
                isTranslating: true
            ),
            containerSize: CGSize(width: 400, height: 800),
            onTap: {}
        )
    }
}

#Preview("Translated") {
    ZStack {
        Color.gray.opacity(0.3)
        TranslationOverlayView(
            result: ScanResult(
                originalText: "Hello World",
                translatedText: "你好世界",
                boundingBox: CGRect(x: 100, y: 300, width: 200, height: 40),
                isTranslating: false
            ),
            containerSize: CGSize(width: 400, height: 800),
            onTap: {}
        )
    }
}

#Preview("Failed") {
    ZStack {
        Color.gray.opacity(0.3)
        TranslationOverlayView(
            result: ScanResult(
                originalText: "Hello World",
                boundingBox: CGRect(x: 100, y: 300, width: 200, height: 40),
                isTranslating: false,
                translationFailed: true
            ),
            containerSize: CGSize(width: 400, height: 800),
            onTap: {}
        )
    }
}
