import SwiftUI
import Translation

struct LanguagePickerSheet: View {
    let title: String
    let currentLanguage: Locale.Language
    let onSelect: (Locale.Language, Bool) -> Void  // (language, isDownloaded)

    @Environment(\.dismiss) private var dismiss
    @State private var supportedLanguages: [Locale.Language] = []
    @State private var downloadedLanguages: Set<String> = []
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                if isLoading {
                    ProgressView()
                        .tint(.appPrimary)
                } else {
                    languageList
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.appTextMuted)
                    }
                }
            }
        }
        .task {
            await loadLanguages()
        }
    }

    private var downloadedLanguagesList: [Locale.Language] {
        supportedLanguages.filter { downloadedLanguages.contains($0.minimalIdentifier) }
    }

    private var availableLanguagesList: [Locale.Language] {
        supportedLanguages.filter { !downloadedLanguages.contains($0.minimalIdentifier) }
    }

    private var languageList: some View {
        List {
            if !downloadedLanguagesList.isEmpty {
                Section {
                    ForEach(downloadedLanguagesList, id: \.minimalIdentifier) { language in
                        LanguagePickerRow(
                            language: language,
                            isSelected: language.minimalIdentifier == currentLanguage.minimalIdentifier,
                            isDownloaded: true
                        ) {
                            onSelect(language, true)
                            dismiss()
                        }
                    }
                } header: {
                    Text("已下載")
                        .font(.appCaption)
                        .foregroundColor(.appTextMuted)
                }
                .listRowBackground(Color.appSurface)
            }

            if !availableLanguagesList.isEmpty {
                Section {
                    ForEach(availableLanguagesList, id: \.minimalIdentifier) { language in
                        LanguagePickerRow(
                            language: language,
                            isSelected: language.minimalIdentifier == currentLanguage.minimalIdentifier,
                            isDownloaded: false
                        ) {
                            onSelect(language, false)
                            dismiss()
                        }
                    }
                } header: {
                    Text("可下載")
                        .font(.appCaption)
                        .foregroundColor(.appTextMuted)
                }
                .listRowBackground(Color.appSurface)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }

    private func loadLanguages() async {
        let availability = LanguageAvailability()
        supportedLanguages = await availability.supportedLanguages

        for language in supportedLanguages {
            let status = await availability.status(
                from: language,
                to: Locale.Language(identifier: "en")
            )
            if status == .installed {
                downloadedLanguages.insert(language.minimalIdentifier)
            }
        }

        isLoading = false
    }
}

private struct LanguagePickerRow: View {
    let language: Locale.Language
    let isSelected: Bool
    let isDownloaded: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(displayName(for: language))
                        .font(.appBody)
                        .foregroundColor(.appTextPrimary)

                    Text(language.minimalIdentifier)
                        .font(.appCaption)
                        .foregroundColor(.appTextMuted)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.appPrimary)
                        .fontWeight(.semibold)
                } else if !isDownloaded {
                    Image(systemName: "arrow.down.circle")
                        .foregroundColor(.appTextMuted)
                }
            }
            .padding(.vertical, AppSpacing.sm)
        }
    }

    private func displayName(for language: Locale.Language) -> String {
        let locale = Locale(identifier: language.minimalIdentifier)
        return locale.localizedString(forIdentifier: language.minimalIdentifier)?.capitalized ?? language.minimalIdentifier
    }
}

#Preview {
    LanguagePickerSheet(
        title: "選擇來源語言",
        currentLanguage: Locale.Language(identifier: "en"),
        onSelect: { _, _ in }
    )
}
