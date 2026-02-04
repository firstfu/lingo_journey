import Foundation
import CoreGraphics

struct ScanResult: Identifiable, Equatable {
    let id: UUID
    let originalText: String
    var translatedText: String?
    let boundingBox: CGRect
    var isTranslating: Bool
    var translationFailed: Bool

    init(
        id: UUID = UUID(),
        originalText: String,
        translatedText: String? = nil,
        boundingBox: CGRect,
        isTranslating: Bool = false,
        translationFailed: Bool = false
    ) {
        self.id = id
        self.originalText = originalText
        self.translatedText = translatedText
        self.boundingBox = boundingBox
        self.isTranslating = isTranslating
        self.translationFailed = translationFailed
    }
}
