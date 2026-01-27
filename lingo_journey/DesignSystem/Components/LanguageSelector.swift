import SwiftUI

struct LanguageSelector: View {
    @Binding var sourceLanguage: Locale.Language
    @Binding var targetLanguage: Locale.Language
    var onSwap: () -> Void
    var onSourceTap: () -> Void
    var onTargetTap: () -> Void

    var body: some View {
        HStack(spacing: AppSpacing.lg) {
            LanguagePill(
                language: sourceLanguage,
                action: onSourceTap
            )

            Button(action: onSwap) {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.appPrimary)
                    .frame(width: 36, height: 36)
                    .background(Color.appSurface)
                    .clipShape(Circle())
            }

            LanguagePill(
                language: targetLanguage,
                action: onTargetTap
            )
        }
        .padding(.horizontal, AppSpacing.xl)
    }
}

struct LanguagePill: View {
    let language: Locale.Language
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(displayName(for: language))
                .font(.appHeadline)
                .foregroundColor(.appTextPrimary)
                .padding(.horizontal, AppSpacing.xl)
                .padding(.vertical, AppSpacing.lg)
                .background(Color.appSurface)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.appBorder, lineWidth: 1)
                )
        }
    }

    private func displayName(for language: Locale.Language) -> String {
        let locale = Locale(identifier: language.minimalIdentifier)
        return locale.localizedString(forIdentifier: language.minimalIdentifier)?.capitalized ?? language.minimalIdentifier
    }
}

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        LanguageSelector(
            sourceLanguage: .constant(Locale.Language(identifier: "en")),
            targetLanguage: .constant(Locale.Language(identifier: "zh-Hant")),
            onSwap: {},
            onSourceTap: {},
            onTargetTap: {}
        )
    }
}
