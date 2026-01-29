import Foundation
import SwiftUI

struct TranslationResultCard: View {
    let languageName: String
    let translatedText: String
    var onCopy: () -> Void
    var onSpeak: () -> Void
    var onFavorite: () -> Void
    var isFavorite: Bool = false
    var isSpeaking: Bool = false
    var showCopySuccess: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            HStack {
                Text(languageName)
                    .font(.appFootnote)
                    .foregroundColor(.appTextSecondary)

                Spacer()

                HStack(spacing: AppSpacing.sm) {
                    // Copy button with success state
                    IconButton(
                        icon: showCopySuccess ? "checkmark" : "doc.on.doc",
                        action: onCopy,
                        tint: showCopySuccess ? .green : .appTextSecondary
                    )

                    // Speak button with speaking state
                    IconButton(
                        icon: isSpeaking ? "speaker.wave.3.fill" : "speaker.wave.2",
                        action: onSpeak,
                        tint: isSpeaking ? .appPrimary : .appTextSecondary,
                        isAnimating: isSpeaking
                    )

                    IconButton(
                        icon: isFavorite ? "star.fill" : "star",
                        action: onFavorite,
                        tint: isFavorite ? .appWarning : .appTextSecondary
                    )
                }
            }

            Text(translatedText)
                .font(.appBody)
                .foregroundColor(.appTextPrimary)
                .textSelection(.enabled)
        }
        .padding(AppSpacing.xl)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.large))
    }
}

struct IconButton: View {
    let icon: String
    let action: () -> Void
    var tint: Color = .appTextSecondary
    var isAnimating: Bool = false

    @State private var animationPhase: CGFloat = 0

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(tint)
                .opacity(isAnimating ? (0.5 + 0.5 * Darwin.sin(animationPhase)) : 1.0)
                .frame(width: 36, height: 36)
        }
        .onChange(of: isAnimating) { _, newValue in
            if newValue {
                withAnimation(.linear(duration: 0.8).repeatForever(autoreverses: false)) {
                    animationPhase = .pi * 2
                }
            } else {
                animationPhase = 0
            }
        }
        .animation(.easeInOut(duration: 0.2), value: icon)
        .animation(.easeInOut(duration: 0.2), value: tint)
    }
}

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        VStack(spacing: 20) {
            TranslationResultCard(
                languageName: "繁體中文",
                translatedText: "你好，你好嗎？",
                onCopy: {},
                onSpeak: {},
                onFavorite: {},
                isFavorite: false,
                isSpeaking: false,
                showCopySuccess: false
            )
            TranslationResultCard(
                languageName: "繁體中文",
                translatedText: "你好，你好嗎？",
                onCopy: {},
                onSpeak: {},
                onFavorite: {},
                isFavorite: true,
                isSpeaking: true,
                showCopySuccess: true
            )
        }
        .padding()
    }
}
