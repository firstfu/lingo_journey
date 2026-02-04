import Foundation
import SwiftUI

/// Scanner 視圖模型 - 整合相機、OCR、翻譯引擎
@Observable
final class ScannerViewModel {
    // MARK: - Public State

    var detectedTexts: [DetectedText] = []
    var selectedText: DetectedText?
    var showDetailCard: Bool = false
    var viewSize: CGSize = .zero

    // MARK: - Engines

    let cameraManager = CameraManager()
    let textRecognitionEngine = TextRecognitionEngine()
    let textTracker = TextTracker()
    let translationEngine: TranslationEngine

    // MARK: - Init

    init(sourceLanguage: Locale.Language, targetLanguage: Locale.Language) {
        self.translationEngine = TranslationEngine(
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage
        )

        setupCameraCallback()
    }

    // MARK: - Setup

    private func setupCameraCallback() {
        cameraManager.onFrameCaptured = { [weak self] pixelBuffer in
            self?.processFrame(pixelBuffer)
        }
    }

    // MARK: - Frame Processing

    private func processFrame(_ pixelBuffer: CVPixelBuffer) {
        textRecognitionEngine.recognizeText(in: pixelBuffer) { [weak self] results in
            self?.handleRecognizedTexts(results)
        }
    }

    private func handleRecognizedTexts(_ results: [RecognizedTextResult]) {
        // 1. 透過 TextTracker 追蹤並穩定座標
        var trackedTexts = textTracker.update(with: results)

        // 2. 為每個文字取得翻譯
        for i in trackedTexts.indices {
            let text = trackedTexts[i].text

            // 嘗試從 TranslationEngine 取得翻譯
            if let cached = translationEngine.getTranslation(for: text) {
                trackedTexts[i].translatedText = cached
                textTracker.updateTranslation(for: text, translation: cached)
            }
        }

        // 3. 更新顯示
        detectedTexts = trackedTexts
    }

    // MARK: - Lifecycle

    func startScanning() {
        cameraManager.startSession()
    }

    func stopScanning() {
        cameraManager.stopSession()
        textTracker.clear()
    }

    // MARK: - Selection

    func selectText(_ text: DetectedText) {
        selectedText = text
        showDetailCard = true
    }

    func dismissDetailCard() {
        showDetailCard = false
        selectedText = nil
    }
}
