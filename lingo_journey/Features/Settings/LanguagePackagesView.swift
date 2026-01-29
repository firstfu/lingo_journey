import SwiftUI
import Translation

struct LanguagePackagesView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var supportedLanguages: [Locale.Language] = []
    @State private var downloadedLanguages: Set<String> = []
    @State private var downloadingLanguages: Set<String> = []
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                if isLoading {
                    ProgressView()
                        .tint(.appPrimary)
                } else {
                    List {
                        ForEach(supportedLanguages, id: \.minimalIdentifier) { language in
                            LanguagePackageRow(
                                language: language,
                                isDownloaded: downloadedLanguages.contains(language.minimalIdentifier),
                                isDownloading: downloadingLanguages.contains(language.minimalIdentifier),
                                onDownload: { downloadLanguage(language) }
                            )
                            .listRowBackground(Color.appSurface)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Offline Languages")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.appPrimary)
                }
            }
        }
        .task {
            await loadLanguages()
        }
    }

    private func loadLanguages() async {
        let availability = LanguageAvailability()
        supportedLanguages = await availability.supportedLanguages

        for language in supportedLanguages {
            let status = await availability.status(
                from: language,
                to: targetLanguageForPairing(with: language)
            )
            if status == .installed {
                downloadedLanguages.insert(language.minimalIdentifier)
            }
        }

        isLoading = false
    }

    /// 取得用於配對檢查的目標語言（避免同語言配對）
    private func targetLanguageForPairing(with language: Locale.Language) -> Locale.Language {
        let identifier = language.minimalIdentifier
        // 如果是英文，用中文配對；否則用英文配對
        if identifier == "en" || identifier.hasPrefix("en-") {
            return Locale.Language(identifier: "zh-Hant")
        }
        return Locale.Language(identifier: "en")
    }

    private func downloadLanguage(_ language: Locale.Language) {
        downloadingLanguages.insert(language.minimalIdentifier)

        // TODO: 實作真正的下載邏輯，應使用 TranslationSession.Configuration 觸發系統下載提示
        // 目前此處只是模擬下載完成，實際應參考 LanguagePickerSheet 的 startDownload 實作
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await MainActor.run {
                downloadingLanguages.remove(language.minimalIdentifier)
                downloadedLanguages.insert(language.minimalIdentifier)
            }
        }
    }
}

struct LanguagePackageRow: View {
    let language: Locale.Language
    let isDownloaded: Bool
    let isDownloading: Bool
    let onDownload: () -> Void

    var body: some View {
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

            if isDownloaded {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.appSuccess)
            } else if isDownloading {
                ProgressView()
                    .tint(.appPrimary)
            } else {
                Button(action: onDownload) {
                    Image(systemName: "arrow.down.circle")
                        .font(.system(size: 24))
                        .foregroundColor(.appPrimary)
                }
            }
        }
        .padding(.vertical, AppSpacing.md)
    }

    private func displayName(for language: Locale.Language) -> String {
        let locale = Locale(identifier: language.minimalIdentifier)
        return locale.localizedString(forIdentifier: language.minimalIdentifier)?.capitalized ?? language.minimalIdentifier
    }
}

#Preview {
    LanguagePackagesView()
}
