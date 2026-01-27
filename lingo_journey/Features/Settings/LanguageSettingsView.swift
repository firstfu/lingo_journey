import SwiftUI

struct LanguageSettingsView: View {
    @State private var languageManager = LanguageManager.shared

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 1) {
                    ForEach(AppLanguage.allCases) { language in
                        LanguageRow(
                            language: language,
                            isSelected: languageManager.selectedLanguage == language
                        ) {
                            languageManager.selectedLanguage = language
                        }
                    }
                }
                .background(Color.appSurface)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium))
                .padding(.horizontal, AppSpacing.xl)
                .padding(.vertical, AppSpacing.xl)
            }
        }
        .navigationTitle(String(localized: "settings.appLanguage"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Language Row

struct LanguageRow: View {
    let language: AppLanguage
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.lg) {
                Text(language.displayName)
                    .font(.appBody)
                    .foregroundColor(.appTextPrimary)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.appPrimary)
                }
            }
            .padding(AppSpacing.xl)
            .background(Color.appSurface)
        }
    }
}

#Preview {
    NavigationStack {
        LanguageSettingsView()
    }
}
