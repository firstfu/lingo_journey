import Foundation
import CoreGraphics

/// 文字追蹤器 - 穩定文字座標，避免跳動
final class TextTracker {
    // MARK: - Configuration

    private let maxAge: TimeInterval = 0.5          // 超過此時間未見則移除
    private let smoothingFactor: CGFloat = 0.3      // 座標平滑係數 (0~1, 越小越平滑)
    private let similarityThreshold: Double = 0.6   // 文字相似度閾值
    private let positionThreshold: CGFloat = 0.15   // 位置接近度閾值 (normalized)

    // MARK: - State

    private var trackedTexts: [UUID: TrackedTextInfo] = [:]

    struct TrackedTextInfo {
        let id: UUID
        var text: String
        var corners: TextCorners
        var smoothedCorners: TextCorners
        var lastSeenTime: Date
        var translatedText: String?
    }

    // MARK: - Public Methods

    /// 更新追蹤的文字，回傳穩定後的結果
    func update(with recognizedTexts: [RecognizedTextResult]) -> [DetectedText] {
        let now = Date()

        // 移除過期的追蹤
        trackedTexts = trackedTexts.filter { now.timeIntervalSince($0.value.lastSeenTime) < maxAge }

        var matchedIds: Set<UUID> = []

        for recognized in recognizedTexts {
            if let (id, existingInfo) = findMatch(for: recognized) {
                // 更新現有追蹤
                matchedIds.insert(id)
                var updated = existingInfo
                updated.text = recognized.text
                updated.corners = recognized.corners
                updated.smoothedCorners = smoothCorners(
                    current: recognized.corners,
                    previous: existingInfo.smoothedCorners
                )
                updated.lastSeenTime = now
                trackedTexts[id] = updated
            } else {
                // 新增追蹤
                let id = UUID()
                trackedTexts[id] = TrackedTextInfo(
                    id: id,
                    text: recognized.text,
                    corners: recognized.corners,
                    smoothedCorners: recognized.corners,
                    lastSeenTime: now,
                    translatedText: nil
                )
            }
        }

        // 轉換為 DetectedText
        return trackedTexts.values.map { info in
            DetectedText(
                id: info.id,
                text: info.text,
                translatedText: info.translatedText,
                corners: info.smoothedCorners,
                isTranslating: false
            )
        }
    }

    /// 更新翻譯結果
    func updateTranslation(for text: String, translation: String) {
        for (id, var info) in trackedTexts {
            if info.text == text {
                info.translatedText = translation
                trackedTexts[id] = info
            }
        }
    }

    /// 取得快取的翻譯
    func getCachedTranslation(for text: String) -> String? {
        trackedTexts.values.first { $0.text == text }?.translatedText
    }

    /// 清除所有追蹤
    func clear() {
        trackedTexts.removeAll()
    }

    // MARK: - Private Methods

    private func findMatch(for recognized: RecognizedTextResult) -> (UUID, TrackedTextInfo)? {
        for (id, info) in trackedTexts {
            let textSimilarity = stringSimilarity(info.text, recognized.text)
            let positionDistance = cornerDistance(info.corners, recognized.corners)

            if textSimilarity > similarityThreshold && positionDistance < positionThreshold {
                return (id, info)
            }
        }
        return nil
    }

    private func smoothCorners(current: TextCorners, previous: TextCorners) -> TextCorners {
        TextCorners(
            topLeft: smoothPoint(current: current.topLeft, previous: previous.topLeft),
            topRight: smoothPoint(current: current.topRight, previous: previous.topRight),
            bottomLeft: smoothPoint(current: current.bottomLeft, previous: previous.bottomLeft),
            bottomRight: smoothPoint(current: current.bottomRight, previous: previous.bottomRight)
        )
    }

    private func smoothPoint(current: CGPoint, previous: CGPoint) -> CGPoint {
        CGPoint(
            x: previous.x + (current.x - previous.x) * smoothingFactor,
            y: previous.y + (current.y - previous.y) * smoothingFactor
        )
    }

    /// 計算字串相似度 (Jaccard 相似度)
    private func stringSimilarity(_ s1: String, _ s2: String) -> Double {
        if s1 == s2 { return 1.0 }
        if s1.isEmpty || s2.isEmpty { return 0.0 }

        // 檢查包含關係
        let longer = s1.count > s2.count ? s1 : s2
        let shorter = s1.count > s2.count ? s2 : s1

        if longer.contains(shorter) {
            return Double(shorter.count) / Double(longer.count)
        }

        // Jaccard 相似度
        let set1 = Set(s1.lowercased())
        let set2 = Set(s2.lowercased())
        let intersection = set1.intersection(set2)
        let union = set1.union(set2)

        return Double(intersection.count) / Double(union.count)
    }

    /// 計算四角點的平均距離
    private func cornerDistance(_ c1: TextCorners, _ c2: TextCorners) -> CGFloat {
        let d1 = hypot(c1.topLeft.x - c2.topLeft.x, c1.topLeft.y - c2.topLeft.y)
        let d2 = hypot(c1.topRight.x - c2.topRight.x, c1.topRight.y - c2.topRight.y)
        let d3 = hypot(c1.bottomLeft.x - c2.bottomLeft.x, c1.bottomLeft.y - c2.bottomLeft.y)
        let d4 = hypot(c1.bottomRight.x - c2.bottomRight.x, c1.bottomRight.y - c2.bottomRight.y)
        return (d1 + d2 + d3 + d4) / 4
    }
}
