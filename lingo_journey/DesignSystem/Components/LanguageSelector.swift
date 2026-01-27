import SwiftUI

enum LanguageSelectorSize {
    case regular
    case large

    var font: Font {
        switch self {
        case .regular: return .appHeadline
        case .large: return .appTitle2
        }
    }

    var pillVerticalPadding: CGFloat {
        switch self {
        case .regular: return AppSpacing.lg
        case .large: return AppSpacing.xl
        }
    }

    var swapButtonSize: CGFloat {
        switch self {
        case .regular: return 36
        case .large: return 44
        }
    }

    var swapIconSize: CGFloat {
        switch self {
        case .regular: return 16
        case .large: return 20
        }
    }
}

struct LanguageSelector: View {
    @Binding var sourceLanguage: Locale.Language
    @Binding var targetLanguage: Locale.Language
    var size: LanguageSelectorSize = .regular
    var onSwap: () -> Void
    var onSourceTap: () -> Void
    var onTargetTap: () -> Void

    var body: some View {
        HStack(spacing: AppSpacing.lg) {
            LanguagePill(
                language: sourceLanguage,
                size: size,
                action: onSourceTap
            )

            Button(action: onSwap) {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: size.swapIconSize, weight: .medium))
                    .foregroundColor(.appPrimary)
                    .frame(width: size.swapButtonSize, height: size.swapButtonSize)
                    .background(Color.appSurface)
                    .clipShape(Circle())
            }

            LanguagePill(
                language: targetLanguage,
                size: size,
                action: onTargetTap
            )
        }
        .padding(.horizontal, AppSpacing.xl)
    }
}

struct LanguagePill: View {
    let language: Locale.Language
    var size: LanguageSelectorSize = .regular
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(displayName(for: language))
                .font(size.font)
                .foregroundColor(.appTextPrimary)
                .padding(.horizontal, AppSpacing.xl)
                .padding(.vertical, size.pillVerticalPadding)
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
