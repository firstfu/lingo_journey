import Foundation
import SwiftUI
import VisionKit
import Translation

@Observable
final class ScannerViewModel {
    // MARK: - State
    var scanResults: [ScanResult] = []
    var selectedResultId: UUID?
    var showDetailCard: Bool = false

    // MARK: - Translation Cache
    /// 翻譯快取：key = 原始文字, value = 翻譯結果
    private var translationCache: [String: String] = [:]

    // MARK: - Constants
    private let maxOverlayCount = 15

    // MARK: - Languages
    var sourceLanguage: Locale.Language
    var targetLanguage: Locale.Language

    // MARK: - Translation
    var translationConfiguration: TranslationSession.Configuration?
    private var pendingTranslations: [UUID: String] = [:]
    private var isTranslating = false

    init(sourceLanguage: Locale.Language, targetLanguage: Locale.Language) {
        self.sourceLanguage = sourceLanguage
        self.targetLanguage = targetLanguage
    }

    // MARK: - Text Recognition
    func handleRecognizedItems(_ items: [RecognizedItem]) {
        var newResults: [ScanResult] = []

        for item in items {
            if case .text(let text) = item {
                let transcript = text.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !transcript.isEmpty else { continue }

                // Convert bounds to CGRect
                let boundingBox = CGRect(
                    x: text.bounds.topLeft.x,
                    y: text.bounds.topLeft.y,
                    width: text.bounds.topRight.x - text.bounds.topLeft.x,
                    height: text.bounds.bottomLeft.y - text.bounds.topLeft.y
                )

                // 檢查快取中是否已有翻譯
                if let cachedTranslation = translationCache[transcript] {
                    // 已有翻譯，直接使用
                    let result = ScanResult(
                        originalText: transcript,
                        translatedText: cachedTranslation,
                        boundingBox: boundingBox,
                        isTranslating: false,
                        translationFailed: false
                    )
                    newResults.append(result)
                } else if let existingIndex = scanResults.firstIndex(where: { $0.originalText == transcript }) {
                    // 正在翻譯中，保留狀態並更新位置
                    let existing = scanResults[existingIndex]
                    let updated = ScanResult(
                        id: existing.id,
                        originalText: existing.originalText,
                        translatedText: existing.translatedText,
                        boundingBox: boundingBox,
                        isTranslating: existing.isTranslating,
                        translationFailed: existing.translationFailed
                    )
                    newResults.append(updated)
                } else {
                    // 新文字，加入待翻譯佇列
                    let result = ScanResult(
                        originalText: transcript,
                        boundingBox: boundingBox,
                        isTranslating: true,
                        translationFailed: false
                    )
                    newResults.append(result)
                    pendingTranslations[result.id] = transcript
                }

                // Limit the number of overlay results
                if newResults.count >= maxOverlayCount {
                    break
                }
            }
        }

        scanResults = newResults

        // Trigger translation for pending items (debounced)
        if !pendingTranslations.isEmpty && !isTranslating {
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
        let pending = pendingTranslations
        pendingTranslations.removeAll()

        for (id, text) in pending {
            // 再次檢查快取（可能在等待期間已被翻譯）
            if let cached = translationCache[text] {
                await MainActor.run {
                    if let index = scanResults.firstIndex(where: { $0.id == id }) {
                        scanResults[index] = ScanResult(
                            id: id,
                            originalText: text,
                            translatedText: cached,
                            boundingBox: scanResults[index].boundingBox,
                            isTranslating: false,
                            translationFailed: false
                        )
                    }
                }
                continue
            }

            do {
                let response = try await session.translate(text)
                let translatedText = response.targetText

                // 存入快取
                await MainActor.run {
                    translationCache[text] = translatedText

                    if let index = scanResults.firstIndex(where: { $0.id == id }) {
                        scanResults[index] = ScanResult(
                            id: id,
                            originalText: scanResults[index].originalText,
                            translatedText: translatedText,
                            boundingBox: scanResults[index].boundingBox,
                            isTranslating: false,
                            translationFailed: false
                        )
                    }
                }
            } catch {
                await MainActor.run {
                    if let index = scanResults.firstIndex(where: { $0.id == id }) {
                        scanResults[index] = ScanResult(
                            id: id,
                            originalText: scanResults[index].originalText,
                            translatedText: nil,
                            boundingBox: scanResults[index].boundingBox,
                            isTranslating: false,
                            translationFailed: true
                        )
                    }
                }
            }
        }

        await MainActor.run {
            translationConfiguration = nil
            isTranslating = false

            // 如果還有待翻譯的項目，繼續翻譯
            if !pendingTranslations.isEmpty {
                triggerTranslation()
            }
        }
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
        return scanResults.first { $0.id == id }
    }
}
