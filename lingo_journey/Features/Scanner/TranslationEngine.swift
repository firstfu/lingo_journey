import Foundation
import Translation

/// 翻譯引擎 - Apple Translation + 快取
@Observable
final class TranslationEngine {
    // MARK: - Public Properties

    /// 翻譯配置 (設定此值會觸發 .translationTask)
    var configuration: TranslationSession.Configuration?

    let sourceLanguage: Locale.Language
    let targetLanguage: Locale.Language

    // MARK: - Private Properties

    private var cache: [String: String] = [:]
    private var pendingTexts: Set<String> = []
    private var isTranslating = false

    // MARK: - Init

    init(sourceLanguage: Locale.Language, targetLanguage: Locale.Language) {
        self.sourceLanguage = sourceLanguage
        self.targetLanguage = targetLanguage
    }

    // MARK: - Public Methods

    /// 取得翻譯，若無快取則加入待翻譯列表
    /// - Parameter text: 要翻譯的文字
    /// - Returns: 翻譯結果，若尚未翻譯則返回 nil
    func getTranslation(for text: String) -> String? {
        // 先檢查快取
        if let cached = cache[text] {
            return cached
        }

        // 加入待翻譯列表
        if !pendingTexts.contains(text) {
            pendingTexts.insert(text)
            triggerTranslationIfNeeded()
        }

        return nil
    }

    /// 檢查是否有快取的翻譯
    func hasCachedTranslation(for text: String) -> Bool {
        cache[text] != nil
    }

    /// 執行翻譯 (由 .translationTask 呼叫)
    func performTranslation(session: TranslationSession) async {
        let textsToTranslate = Array(pendingTexts)

        await MainActor.run {
            pendingTexts.removeAll()
        }

        guard !textsToTranslate.isEmpty else {
            await MainActor.run {
                configuration = nil
                isTranslating = false
            }
            return
        }

        do {
            // 批次翻譯
            let requests = textsToTranslate.map { TranslationSession.Request(sourceText: $0) }
            let responses = try await session.translations(from: requests)

            await MainActor.run {
                for (index, response) in responses.enumerated() {
                    let originalText = textsToTranslate[index]
                    cache[originalText] = response.targetText
                }
            }
        } catch {
            print("Translation error: \(error)")
        }

        await MainActor.run {
            configuration = nil
            isTranslating = false

            // 如果還有待翻譯項目，繼續
            if !pendingTexts.isEmpty {
                triggerTranslationIfNeeded()
            }
        }
    }

    /// 清除快取
    func clearCache() {
        cache.removeAll()
        pendingTexts.removeAll()
    }

    // MARK: - Private Methods

    private func triggerTranslationIfNeeded() {
        guard !isTranslating, !pendingTexts.isEmpty else { return }

        isTranslating = true
        configuration = TranslationSession.Configuration(
            source: sourceLanguage,
            target: targetLanguage
        )
    }
}
