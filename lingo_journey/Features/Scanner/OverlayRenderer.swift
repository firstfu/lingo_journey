import SwiftUI
import QuartzCore

/// 翻譯覆蓋層 - 繪製模糊遮罩和翻譯文字
struct TranslationOverlay: View {
    let detectedTexts: [DetectedText]
    let viewSize: CGSize
    let onTap: (DetectedText) -> Void

    var body: some View {
        ZStack {
            // Canvas 繪製模糊遮罩和翻譯文字
            Canvas { context, size in
                for text in detectedTexts {
                    guard let translated = text.translatedText else { continue }

                    let screenCorners = text.corners.toScreenCoordinates(in: size)
                    let rect = screenCorners.boundingBox

                    // 1. 繪製模糊背景遮罩 (白色半透明)
                    let path = createQuadPath(from: screenCorners)
                    context.fill(path, with: .color(.white.opacity(0.88)))

                    // 2. 計算字體大小 (根據區域高度)
                    let fontSize = calculateFontSize(for: rect)

                    // 3. 繪製翻譯文字
                    let textPosition = CGPoint(x: rect.midX, y: rect.midY)

                    // 應用旋轉 (如果文字傾斜)
                    let rotation = calculateRotation(from: screenCorners)

                    context.drawLayer { layerContext in
                        // 移動到文字中心
                        layerContext.translateBy(x: textPosition.x, y: textPosition.y)

                        // 應用旋轉
                        if abs(rotation) > 0.02 {
                            layerContext.rotate(by: Angle(radians: rotation))
                        }

                        // 繪製文字
                        layerContext.draw(
                            Text(translated)
                                .font(.system(size: fontSize, weight: .semibold))
                                .foregroundColor(.black),
                            at: .zero,
                            anchor: .center
                        )
                    }
                }
            }
            .allowsHitTesting(false)

            // 疊加可點擊的透明區域
            ForEach(detectedTexts.filter { $0.translatedText != nil }) { text in
                let screenCorners = text.corners.toScreenCoordinates(in: viewSize)
                let rect = screenCorners.boundingBox

                Color.clear
                    .frame(width: rect.width, height: rect.height)
                    .position(x: rect.midX, y: rect.midY)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onTap(text)
                    }
            }
        }
    }

    // MARK: - Private Helpers

    /// 創建四邊形路徑
    private func createQuadPath(from corners: TextCorners) -> Path {
        var path = Path()
        path.move(to: corners.topLeft)
        path.addLine(to: corners.topRight)
        path.addLine(to: corners.bottomRight)
        path.addLine(to: corners.bottomLeft)
        path.closeSubpath()
        return path
    }

    /// 計算字體大小
    private func calculateFontSize(for rect: CGRect) -> CGFloat {
        let height = rect.height
        return min(max(height * 0.65, 12), 28)
    }

    /// 計算旋轉角度 (弧度)
    private func calculateRotation(from corners: TextCorners) -> Double {
        let dx = corners.topRight.x - corners.topLeft.x
        let dy = corners.topRight.y - corners.topLeft.y
        return atan2(dy, dx)
    }
}

// MARK: - 透視變形輔助

extension TextCorners {
    /// 計算透視變形的 CATransform3D
    func perspectiveTransform() -> CATransform3D {
        // 計算傾斜比例
        let topWidth = hypot(topRight.x - topLeft.x, topRight.y - topLeft.y)
        let bottomWidth = hypot(bottomRight.x - bottomLeft.x, bottomRight.y - bottomLeft.y)
        let perspectiveRatio = topWidth / max(bottomWidth, 0.001)

        var transform = CATransform3DIdentity
        transform.m34 = -1.0 / 500.0  // 透視效果

        // 根據比例應用透視傾斜
        if abs(perspectiveRatio - 1.0) > 0.05 {
            let angle = atan((perspectiveRatio - 1.0) * 0.5)
            transform = CATransform3DRotate(transform, angle, 1, 0, 0)
        }

        // 計算 Z 軸旋轉 (文字傾斜)
        let dx = topRight.x - topLeft.x
        let dy = topRight.y - topLeft.y
        let rotation = atan2(dy, dx)

        if abs(rotation) > 0.02 {
            transform = CATransform3DRotate(transform, rotation, 0, 0, 1)
        }

        return transform
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.gray.opacity(0.3)

        TranslationOverlay(
            detectedTexts: [
                DetectedText(
                    text: "Hello World",
                    translatedText: "你好世界",
                    corners: TextCorners(
                        topLeft: CGPoint(x: 0.2, y: 0.6),
                        topRight: CGPoint(x: 0.8, y: 0.6),
                        bottomLeft: CGPoint(x: 0.2, y: 0.55),
                        bottomRight: CGPoint(x: 0.8, y: 0.55)
                    )
                )
            ],
            viewSize: CGSize(width: 400, height: 800),
            onTap: { _ in }
        )
    }
    .frame(width: 400, height: 800)
}
