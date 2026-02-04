import SwiftUI

/// 拍照結果視圖 - 顯示照片 + 翻譯疊加
struct PhotoResultView: View {
    let image: UIImage
    let detectedTexts: [DetectedText]
    let onTextTap: (DetectedText) -> Void
    let onRetake: () -> Void
    let onSave: () -> Void
    let onShare: () -> Void

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景照片
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                // 翻譯疊加層
                translationOverlay(in: geometry.size)
            }
        }
        .safeAreaInset(edge: .bottom) {
            actionBar
        }
    }

    // MARK: - Translation Overlay

    @ViewBuilder
    private func translationOverlay(in viewSize: CGSize) -> some View {
        // 計算圖片在視圖中的實際尺寸和位置
        let imageFrame = calculateImageFrame(imageSize: image.size, viewSize: viewSize)

        ZStack {
            ForEach(detectedTexts.filter { $0.translatedText != nil }) { text in
                let screenCorners = text.corners.toScreenCoordinates(in: imageFrame.size)
                let rect = screenCorners.boundingBox

                // 翻譯標籤
                translationLabel(
                    text: text.translatedText ?? "",
                    rect: rect,
                    rotation: calculateRotation(from: screenCorners)
                )
                .position(
                    x: imageFrame.origin.x + rect.midX,
                    y: imageFrame.origin.y + rect.midY
                )
                .onTapGesture {
                    onTextTap(text)
                }
            }
        }
    }

    private func translationLabel(text: String, rect: CGRect, rotation: Double) -> some View {
        Text(text)
            .font(.system(size: calculateFontSize(for: rect), weight: .semibold))
            .foregroundColor(.black)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.88))
            )
            .rotationEffect(.radians(rotation))
    }

    private func calculateFontSize(for rect: CGRect) -> CGFloat {
        let height = rect.height
        return min(max(height * 0.6, 10), 24)
    }

    private func calculateRotation(from corners: TextCorners) -> Double {
        let dx = corners.topRight.x - corners.topLeft.x
        let dy = corners.topRight.y - corners.topLeft.y
        return atan2(dy, dx)
    }

    /// 計算圖片在視圖中的實際 frame (scaledToFit)
    private func calculateImageFrame(imageSize: CGSize, viewSize: CGSize) -> CGRect {
        let imageAspect = imageSize.width / imageSize.height
        let viewAspect = viewSize.width / viewSize.height

        var width: CGFloat
        var height: CGFloat

        if imageAspect > viewAspect {
            // 圖片較寬，以寬度為準
            width = viewSize.width
            height = width / imageAspect
        } else {
            // 圖片較高，以高度為準
            height = viewSize.height
            width = height * imageAspect
        }

        let x = (viewSize.width - width) / 2
        let y = (viewSize.height - height) / 2

        return CGRect(x: x, y: y, width: width, height: height)
    }

    // MARK: - Action Bar

    private var actionBar: some View {
        HStack(spacing: AppSpacing.xxl) {
            // 重拍按鈕
            actionButton(icon: "arrow.counterclockwise", label: "重拍", action: onRetake)

            // 保存按鈕
            actionButton(icon: "square.and.arrow.down", label: "保存", action: onSave)

            // 分享按鈕
            actionButton(icon: "square.and.arrow.up", label: "分享", action: onShare)
        }
        .padding(.vertical, AppSpacing.lg)
        .padding(.horizontal, AppSpacing.xxl)
        .background(
            Color.black.opacity(0.6)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func actionButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: AppSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                Text(label)
                    .font(.appCaption)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Preview

#Preview {
    PhotoResultView(
        image: UIImage(systemName: "photo")!,
        detectedTexts: [
            DetectedText(
                text: "Hello",
                translatedText: "你好",
                corners: TextCorners(
                    topLeft: CGPoint(x: 0.2, y: 0.6),
                    topRight: CGPoint(x: 0.5, y: 0.6),
                    bottomLeft: CGPoint(x: 0.2, y: 0.55),
                    bottomRight: CGPoint(x: 0.5, y: 0.55)
                )
            )
        ],
        onTextTap: { _ in },
        onRetake: {},
        onSave: {},
        onShare: {}
    )
}
