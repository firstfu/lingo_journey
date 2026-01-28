import ActivityKit
import Foundation

/// Shared attributes for Translation Live Activity
/// This file must be included in both main app and widget extension targets
struct TranslationActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var sourceText: String
        var translatedText: String
        var isTranslating: Bool
        var isStandby: Bool  // 待機狀態
        var errorMessage: String?  // 錯誤訊息
    }

    var sourceLanguage: String
    var targetLanguage: String
}
