import SwiftUI
import Translation

// 用於跨頁面導航到語言包下載的通知
extension Notification.Name {
    static let navigateToLanguagePackages = Notification.Name("navigateToLanguagePackages")
}

struct LanguagePickerSheet: View {
    let title: String
    let currentLanguage: Locale.Language?
    let dismissOnSelect: Bool
    let showDownloadableLanguages: Bool
    let onSelect: (Locale.Language, Bool) -> Void  // (language, isDownloaded)

    @Environment(\.dismiss) private var dismiss
    @State private var supportedLanguages: [Locale.Language] = []
    @State private var downloadedLanguages: Set<String> = []
    @State private var downloadingLanguages: Set<String> = []
    @State private var isLoading = true
    @State private var downloadConfiguration: TranslationSession.Configuration?
    @State private var pendingDownloadLanguage: Locale.Language?
    @State private var downloadTrigger = UUID()

    init(
        title: String,
        currentLanguage: Locale.Language? = nil,
        dismissOnSelect: Bool = true,
        showDownloadableLanguages: Bool = true,
        onSelect: @escaping (Locale.Language, Bool) -> Void
    ) {
        self.title = title
        self.currentLanguage = currentLanguage
        self.dismissOnSelect = dismissOnSelect
        self.showDownloadableLanguages = showDownloadableLanguages
        self.onSelect = onSelect
    }

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
        .translationTask(downloadConfiguration) { session in
            await handleDownloadSession(session: session)
        }
        .id(downloadTrigger)
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
                            isSelected: currentLanguage.map { language.minimalIdentifier == $0.minimalIdentifier } ?? false,
                            isDownloaded: true,
                            isDownloading: false
                        ) {
                            onSelect(language, true)
                            if dismissOnSelect {
                                dismiss()
                            }
                        }
                    }
                } header: {
                    Text("已下載")
                        .font(.appCaption)
                        .foregroundColor(.appTextMuted)
                }
                .listRowBackground(Color.appSurface)
            }

            if showDownloadableLanguages && !availableLanguagesList.isEmpty {
                Section {
                    ForEach(availableLanguagesList, id: \.minimalIdentifier) { language in
                        LanguagePickerRow(
                            language: language,
                            isSelected: currentLanguage.map { language.minimalIdentifier == $0.minimalIdentifier } ?? false,
                            isDownloaded: false,
                            isDownloading: downloadingLanguages.contains(language.minimalIdentifier)
                        ) {
                            startDownload(language)
                            onSelect(language, false)
                            if dismissOnSelect {
                                dismiss()
                            }
                        }
                    }
                } header: {
                    Text("可下載")
                        .font(.appCaption)
                        .foregroundColor(.appTextMuted)
                }
                .listRowBackground(Color.appSurface)
            }

            // 當不顯示可下載語言時，顯示導航提示
            if !showDownloadableLanguages && !availableLanguagesList.isEmpty {
                Section {
                    Button {
                        dismiss()
                        // 延遲發送通知，確保 sheet 關閉後再導航
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            NotificationCenter.default.post(name: .navigateToLanguagePackages, object: nil)
                        }
                    } label: {
                        HStack(spacing: AppSpacing.sm) {
                            Image(systemName: "lightbulb")
                                .foregroundColor(.appPrimary)
                            Text("前往「設定」下載更多語言")
                                .font(.appFootnote)
                                .foregroundColor(.appPrimary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.sm)
                    }
                }
                .listRowBackground(Color.clear)
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

    private func startDownload(_ language: Locale.Language) {
        let identifier = language.minimalIdentifier
        guard !downloadingLanguages.contains(identifier) else { return }

        downloadingLanguages.insert(identifier)
        pendingDownloadLanguage = language

        // 生成新的 UUID 強制 SwiftUI 重建 translationTask
        downloadTrigger = UUID()

        // 觸發 translationTask，系統會自動提示下載
        // 使用適當的目標語言避免同語言配對
        downloadConfiguration = TranslationSession.Configuration(
            source: language,
            target: targetLanguageForPairing(with: language)
        )
    }

    private func handleDownloadSession(session: TranslationSession) async {
        guard let language = pendingDownloadLanguage else { return }
        let identifier = language.minimalIdentifier

        do {
            // 嘗試翻譯一個簡單單字來觸發下載流程
            _ = try await session.translate("hello")
        } catch {
            // 下載被取消或失敗，忽略錯誤
        }

        // 無論成功或失敗，重新檢查語言狀態
        let availability = LanguageAvailability()
        let status = await availability.status(
            from: language,
            to: targetLanguageForPairing(with: language)
        )

        await MainActor.run {
            downloadingLanguages.remove(identifier)
            downloadConfiguration = nil
            pendingDownloadLanguage = nil

            if status == .installed {
                downloadedLanguages.insert(identifier)
            }
        }
    }
}

private struct LanguagePickerRow: View {
    let language: Locale.Language
    let isSelected: Bool
    let isDownloaded: Bool
    let isDownloading: Bool
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

                if isDownloading {
                    ProgressView()
                        .tint(.appPrimary)
                } else if isSelected {
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
        .disabled(isDownloading)
    }

    private func displayName(for language: Locale.Language) -> String {
        let locale = Locale(identifier: language.minimalIdentifier)
        return locale.localizedString(forIdentifier: language.minimalIdentifier)?.capitalized ?? language.minimalIdentifier
    }
}

#Preview {
    LanguagePickerSheet(
        title: "選擇來源語言",
        currentLanguage: Locale.Language(identifier: "en")
    ) { _, _ in }
}
