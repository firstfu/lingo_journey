import Foundation
import SwiftUI
import VisionKit
import Translation

@Observable
final class ScannerViewModel {
    // MARK: - State

    /// 當前偵測到的文字（用於顯示 AR 疊加）
    var displayResults: [ScanResult] = []
    var selectedResultId: UUID?
    var showDetailCard: Bool = false

    // MARK: - Translation Cache
    /// 翻譯快取：key = 原始文字, value = 翻譯結果
    private var translationCache: [String: String] = [:]

    /// 已翻譯的結果（持久化顯示）
    private var translatedResults: [String: ScanResult] = [:]

    // MARK: - Constants
    private let maxOverlayCount = 10
    private let debounceInterval: TimeInterval = 0.3  // 防抖動間隔

    // MARK: - Languages
    var sourceLanguage: Locale.Language
    var targetLanguage: Locale.Language

    // MARK: - Translation
    var translationConfiguration: TranslationSession.Configuration?
    private var pendingTexts: Set<String> = []
    private var isTranslating = false
    private var lastUpdateTime: Date = .distantPast
    private var debounceTask: Task<Void, Never>?

    init(sourceLanguage: Locale.Language, targetLanguage: Locale.Language) {
        self.sourceLanguage = sourceLanguage
        self.targetLanguage = targetLanguage
    }

    // MARK: - Text Recognition
    func handleRecognizedItems(_ items: [RecognizedItem]) {
        // 防抖動：取消之前的任務
        debounceTask?.cancel()

        debounceTask = Task { @MainActor in
            // 等待一小段時間，避免頻繁更新
            try? await Task.sleep(for: .milliseconds(100))
            guard !Task.isCancelled else { return }

            processRecognizedItems(items)
        }
    }

    @MainActor
    private func processRecognizedItems(_ items: [RecognizedItem]) {
        var newDisplayResults: [ScanResult] = []
        var textsNeedTranslation: [String] = []

        for item in items {
            guard case .text(let text) = item else { continue }

            let transcript = text.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !transcript.isEmpty else { continue }
            guard newDisplayResults.count < maxOverlayCount else { break }

            // 計算 boundingBox
            let boundingBox = CGRect(
                x: text.bounds.topLeft.x,
                y: text.bounds.topLeft.y,
                width: text.bounds.topRight.x - text.bounds.topLeft.x,
                height: text.bounds.bottomLeft.y - text.bounds.topLeft.y
            )

            // 檢查快取
            if let cachedTranslation = translationCache[transcript] {
                // 已有翻譯，直接顯示
                let result = ScanResult(
                    originalText: transcript,
                    translatedText: cachedTranslation,
                    boundingBox: boundingBox,
                    isTranslating: false,
                    translationFailed: false
                )
                newDisplayResults.append(result)
                translatedResults[transcript] = result
            } else if !pendingTexts.contains(transcript) {
                // 需要翻譯，但不顯示 loading 狀態
                // 只有翻譯完成後才會顯示
                textsNeedTranslation.append(transcript)
                pendingTexts.insert(transcript)
            }
        }

        // 更新顯示結果
        displayResults = newDisplayResults

        // 觸發翻譯
        if !textsNeedTranslation.isEmpty && !isTranslating {
            triggerTranslation()
        }
    }

    // MARK: - Translation
    private func triggerTranslation() {
        isTranslating = true
        translationConfiguration = TranslationSession.Configuration(
            source: sourceLanguage,
            target: targetLanguage
        )
    }

    func performTranslation(session: TranslationSession) async {
        let textsToTranslate = Array(pendingTexts)

        await MainActor.run {
            pendingTexts.removeAll()
        }

        guard !textsToTranslate.isEmpty else {
            await MainActor.run {
                translationConfiguration = nil
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
                    let translatedText = response.targetText

                    // 存入快取
                    translationCache[originalText] = translatedText
                }
            }
        } catch {
            // 翻譯失敗，從 pending 中移除（下次會重試）
            print("Translation error: \(error)")
        }

        await MainActor.run {
            translationConfiguration = nil
            isTranslating = false

            // 如果還有待翻譯的項目，繼續翻譯
            if !pendingTexts.isEmpty {
                triggerTranslation()
            }
        }
    }

    // MARK: - Public accessor for view
    var scanResults: [ScanResult] {
        displayResults
    }

    // MARK: - Selection
    func selectResult(_ id: UUID) {
        selectedResultId = selectedResultId == id ? nil : id
        showDetailCard = selectedResultId != nil
    }

    func dismissDetailCard() {
        showDetailCard = false
        selectedResultId = nil
    }

    func getSelectedResult() -> ScanResult? {
        guard let id = selectedResultId else { return nil }
        return displayResults.first { $0.id == id }
    }
}
