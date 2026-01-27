import Foundation
import SwiftData

@Model
final class TranslationRecord {
    var id: UUID
    var sourceText: String
    var translatedText: String
    var sourceLanguage: String
    var targetLanguage: String
    var isFavorite: Bool
    var createdAt: Date

    init(
        sourceText: String,
        translatedText: String,
        sourceLanguage: String,
        targetLanguage: String
    ) {
        self.id = UUID()
        self.sourceText = sourceText
        self.translatedText = translatedText
        self.sourceLanguage = sourceLanguage
        self.targetLanguage = targetLanguage
        self.isFavorite = false
        self.createdAt = Date()
    }
}
