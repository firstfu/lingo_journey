import Foundation
import Translation

@Observable
final class TranslationService {
    var isTranslating: Bool = false
    var error: Error?

    /// Check if a language pair is available for translation
    func checkAvailability(
        source: Locale.Language,
        target: Locale.Language
    ) async -> LanguageAvailability.Status {
        let availability = LanguageAvailability()
        return await availability.status(from: source, to: target)
    }

    /// Get all supported languages
    func getSupportedLanguages() async -> [Locale.Language] {
        let availability = LanguageAvailability()
        return await availability.supportedLanguages
    }
}
