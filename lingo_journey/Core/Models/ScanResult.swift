import Foundation
import CoreGraphics

struct ScanResult: Identifiable, Equatable {
    let id: UUID
    let originalText: String
    var translatedText: String?
    let boundingBox: CGRect
    var isTranslating: Bool

    init(
        id: UUID = UUID(),
        originalText: String,
        translatedText: String? = nil,
        boundingBox: CGRect,
        isTranslating: Bool = false
    ) {
        self.id = id
        self.originalText = originalText
        self.translatedText = translatedText
        self.boundingBox = boundingBox
        self.isTranslating = isTranslating
    }
}
