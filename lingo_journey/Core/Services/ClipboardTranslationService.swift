import Foundation
import Translation
import UIKit

@Observable
final class ClipboardTranslationService {
    static let shared = ClipboardTranslationService()

    private let liveActivityManager = LiveActivityManager.shared
    private let maxTextLength = 500

    // 翻譯狀態
    var textToTranslate: String = ""
    var isTruncated: Bool = false
    var translationConfiguration: TranslationSession.Configuration?

    private init() {}

    /// 準備剪貼簿翻譯（讀取剪貼簿並設定翻譯配置）
    /// 返回 true 表示成功準備，false 表示失敗
    @MainActor
    func prepareClipboardTranslation() async -> Bool {
        // 1. 讀取剪貼簿
        guard let clipboardText = UIPasteboard.general.string else {
            await liveActivityManager.showError("剪貼簿無內容")
            return false
        }

        let trimmedText = clipboardText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedText.isEmpty else {
            await liveActivityManager.showError("剪貼簿無內容")
            return false
        }

        // 2. 截取過長文字
        if trimmedText.count > maxTextLength {
            textToTranslate = String(trimmedText.prefix(maxTextLength))
            isTruncated = true
        } else {
            textToTranslate = trimmedText
            isTruncated = false
        }

        // 3. 更新為翻譯中狀態
        await liveActivityManager.setTranslating(sourceText: textToTranslate)

        // 4. 設定翻譯配置（觸發 SwiftUI translationTask）
        let sourceLanguage = Locale.Language(identifier: liveActivityManager.lastSourceLanguage)
        let targetLanguage = Locale.Language(identifier: liveActivityManager.lastTargetLanguage)

        translationConfiguration = TranslationSession.Configuration(
            source: sourceLanguage,
            target: targetLanguage
        )

        return true
    }

    /// 執行翻譯（由 SwiftUI translationTask 呼叫）
    func performTranslation(session: TranslationSession) async {
        do {
            let response = try await session.translate(textToTranslate)

            var resultText = response.targetText
            if isTruncated {
                resultText += "..."
            }

            // 顯示結果
            await liveActivityManager.showResultThenStandby(
                sourceText: textToTranslate,
                translatedText: resultText
            )

        } catch {
            await liveActivityManager.showError("翻譯失敗")
        }

        // 清除配置
        await MainActor.run {
            translationConfiguration = nil
        }
    }

    /// 重置狀態
    @MainActor
    func reset() {
        textToTranslate = ""
        isTruncated = false
        translationConfiguration = nil
    }
}
