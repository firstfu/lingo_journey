import SwiftUI

struct TranslationResultCard: View {
    let languageName: String
    let translatedText: String
    var onCopy: () -> Void
    var onSpeak: () -> Void
    var onFavorite: () -> Void
    var isFavorite: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            HStack {
                Text(languageName)
                    .font(.appFootnote)
                    .foregroundColor(.appTextSecondary)

                Spacer()

                HStack(spacing: AppSpacing.sm) {
                    IconButton(icon: "doc.on.doc", action: onCopy)
                    IconButton(icon: "speaker.wave.2", action: onSpeak)
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

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(tint)
                .frame(width: 36, height: 36)
        }
    }
}

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        TranslationResultCard(
            languageName: "繁體中文",
            translatedText: "你好，你好嗎？",
            onCopy: {},
            onSpeak: {},
            onFavorite: {},
            isFavorite: true
        )
        .padding()
    }
}
