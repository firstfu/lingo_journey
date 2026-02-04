import Foundation
import CoreGraphics

// MARK: - TextCorners (四角點座標)

/// 四角點座標 (用於透視變形)
struct TextCorners: Equatable {
    let topLeft: CGPoint
    let topRight: CGPoint
    let bottomLeft: CGPoint
    let bottomRight: CGPoint

    /// 從 normalized (0~1, 左下原點) 轉換為 screen 座標 (左上原點)
    func toScreenCoordinates(in size: CGSize) -> TextCorners {
        TextCorners(
            topLeft: CGPoint(x: topLeft.x * size.width, y: (1 - topLeft.y) * size.height),
            topRight: CGPoint(x: topRight.x * size.width, y: (1 - topRight.y) * size.height),
            bottomLeft: CGPoint(x: bottomLeft.x * size.width, y: (1 - bottomLeft.y) * size.height),
            bottomRight: CGPoint(x: bottomRight.x * size.width, y: (1 - bottomRight.y) * size.height)
        )
    }

    /// 計算邊界框
    var boundingBox: CGRect {
        let minX = min(topLeft.x, bottomLeft.x)
        let maxX = max(topRight.x, bottomRight.x)
        let minY = min(topLeft.y, topRight.y)
        let maxY = max(bottomLeft.y, bottomRight.y)
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    /// 計算中心點
    var center: CGPoint {
        CGPoint(
            x: (topLeft.x + topRight.x + bottomLeft.x + bottomRight.x) / 4,
            y: (topLeft.y + topRight.y + bottomLeft.y + bottomRight.y) / 4
        )
    }
}

// MARK: - DetectedText (偵測到的文字)

/// 偵測到的文字區塊
struct DetectedText: Identifiable, Equatable {
    let id: UUID
    let text: String
    var translatedText: String?
    let corners: TextCorners
    var isTranslating: Bool

    init(
        id: UUID = UUID(),
        text: String,
        translatedText: String? = nil,
        corners: TextCorners,
        isTranslating: Bool = false
    ) {
        self.id = id
        self.text = text
        self.translatedText = translatedText
        self.corners = corners
        self.isTranslating = isTranslating
    }

    var boundingBox: CGRect {
        corners.boundingBox
    }
}

// MARK: - ScanResult (保留給 TranslationDetailCard 使用)

/// 掃描結果 (兼容舊的 TranslationDetailCard)
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

    /// 從 DetectedText 轉換
    init(from detectedText: DetectedText) {
        self.id = detectedText.id
        self.originalText = detectedText.text
        self.translatedText = detectedText.translatedText
        self.boundingBox = detectedText.boundingBox
        self.isTranslating = detectedText.isTranslating
        self.translationFailed = false
    }
}
