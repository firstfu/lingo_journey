import ActivityKit
import Foundation

struct TranslationActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var sourceText: String
        var translatedText: String
        var isTranslating: Bool
    }

    var sourceLanguage: String
    var targetLanguage: String
}
