import Foundation
import SwiftUI
import Photos

/// 掃描器狀態
enum ScannerState: Equatable {
    case preview                    // 相機預覽
    case processing(ProcessingStep) // 處理中
    case result                     // 顯示結果
}

/// 處理步驟
enum ProcessingStep: Equatable {
    case recognizing  // 辨識文字中
    case translating  // 翻譯中
}

/// 拍照翻譯 ViewModel
@Observable
final class PhotoScannerViewModel {
    // MARK: - Public State

    var state: ScannerState = .preview
    var capturedImage: UIImage?
    var detectedTexts: [DetectedText] = []
    var selectedText: DetectedText?
    var showDetailCard: Bool = false
    var errorMessage: String?
    var showSaveSuccess: Bool = false

    // MARK: - Managers

    let cameraManager = PhotoCameraManager()
    let textRecognitionEngine = TextRecognitionEngine()
    let translationEngine: TranslationEngine

    // MARK: - Init

    init(sourceLanguage: Locale.Language, targetLanguage: Locale.Language) {
        self.translationEngine = TranslationEngine(
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage
        )
    }

    // MARK: - Capture and Process

    /// 拍照並處理
    @MainActor
    func captureAndProcess() async {
        // 1. 拍照
        guard let image = await cameraManager.capturePhoto() else {
            errorMessage = "拍照失敗，請重試"
            return
        }

        capturedImage = image
        state = .processing(.recognizing)

        // 2. 辨識文字
        await recognizeText(in: image)

        // 3. 翻譯文字
        state = .processing(.translating)
        await translateTexts()

        // 4. 顯示結果
        state = .result
    }

    /// 辨識圖片中的文字
    private func recognizeText(in image: UIImage) async {
        guard let cgImage = image.cgImage else { return }

        // 使用 CIImage 進行辨識
        let ciImage = CIImage(cgImage: cgImage)

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            textRecognitionEngine.recognizeText(from: ciImage) { [weak self] results in
                self?.detectedTexts = results.map { result in
                    DetectedText(
                        text: result.text,
                        translatedText: nil,
                        corners: result.corners,
                        isTranslating: true
                    )
                }
                continuation.resume()
            }
        }
    }

    /// 翻譯所有偵測到的文字
    private func translateTexts() async {
        // 收集所有需要翻譯的文字
        for i in detectedTexts.indices {
            let text = detectedTexts[i].text

            // 嘗試從快取獲取
            if let cached = translationEngine.getTranslation(for: text) {
                detectedTexts[i].translatedText = cached
                detectedTexts[i].isTranslating = false
            }
        }

        // 等待翻譯完成 (透過 .translationTask)
        // 這裡需要一些時間讓翻譯引擎處理
        try? await Task.sleep(for: .milliseconds(500))

        // 再次嘗試獲取翻譯結果
        for i in detectedTexts.indices {
            let text = detectedTexts[i].text
            if detectedTexts[i].translatedText == nil,
               let cached = translationEngine.getTranslation(for: text) {
                detectedTexts[i].translatedText = cached
                detectedTexts[i].isTranslating = false
            }
        }
    }

    // MARK: - Actions

    /// 重拍
    @MainActor
    func retake() {
        state = .preview
        capturedImage = nil
        detectedTexts = []
        selectedText = nil
        showDetailCard = false
        errorMessage = nil
    }

    /// 選擇文字查看詳情
    func selectText(_ text: DetectedText) {
        selectedText = text
        showDetailCard = true
    }

    /// 關閉詳情卡片
    func dismissDetailCard() {
        showDetailCard = false
        selectedText = nil
    }

    /// 保存到相簿
    @MainActor
    func saveToPhotos() async -> Bool {
        guard let resultImage = generateResultImage() else {
            errorMessage = "生成圖片失敗"
            return false
        }

        // 請求相簿權限
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            errorMessage = "需要相簿權限才能保存"
            return false
        }

        // 保存圖片
        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: resultImage)
            }
            showSaveSuccess = true
            return true
        } catch {
            errorMessage = "保存失敗: \(error.localizedDescription)"
            return false
        }
    }

    /// 生成疊加翻譯的結果圖片
    func generateResultImage() -> UIImage? {
        guard let originalImage = capturedImage else { return nil }

        let imageSize = originalImage.size
        let renderer = UIGraphicsImageRenderer(size: imageSize)

        return renderer.image { context in
            // 繪製原圖
            originalImage.draw(at: .zero)

            // 繪製翻譯疊加
            for text in detectedTexts {
                guard let translated = text.translatedText else { continue }

                let screenCorners = text.corners.toScreenCoordinates(in: imageSize)
                let rect = screenCorners.boundingBox

                // 繪製半透明背景
                let bgRect = rect.insetBy(dx: -4, dy: -2)
                let bgPath = UIBezierPath(roundedRect: bgRect, cornerRadius: 4)
                UIColor.white.withAlphaComponent(0.88).setFill()
                bgPath.fill()

                // 繪製文字
                let fontSize = min(max(rect.height * 0.6, 12), 28)
                let font = UIFont.systemFont(ofSize: fontSize, weight: .semibold)
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: UIColor.black
                ]

                let textSize = translated.size(withAttributes: attributes)
                let textRect = CGRect(
                    x: rect.midX - textSize.width / 2,
                    y: rect.midY - textSize.height / 2,
                    width: textSize.width,
                    height: textSize.height
                )
                translated.draw(in: textRect, withAttributes: attributes)
            }
        }
    }

    // MARK: - Lifecycle

    func startCamera() {
        cameraManager.startSession()
    }

    func stopCamera() {
        cameraManager.stopSession()
    }
}
