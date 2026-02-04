import Vision
import CoreImage

/// Vision OCR 辨識結果
struct RecognizedTextResult {
    let text: String
    let corners: TextCorners  // normalized 座標 (0~1, 左下原點)
    let confidence: Float
}

/// Vision OCR 引擎
final class TextRecognitionEngine {
    private let requestQueue = DispatchQueue(label: "text.recognition.queue", qos: .userInitiated)

    /// 辨識圖像中的文字
    /// - Parameters:
    ///   - pixelBuffer: 來自相機的像素緩衝區
    ///   - completion: 辨識完成後的回調，在主線程執行
    func recognizeText(
        in pixelBuffer: CVPixelBuffer,
        completion: @escaping ([RecognizedTextResult]) -> Void
    ) {
        requestQueue.async {
            let request = VNRecognizeTextRequest { request, error in
                guard error == nil,
                      let observations = request.results as? [VNRecognizedTextObservation] else {
                    DispatchQueue.main.async { completion([]) }
                    return
                }

                let results = observations.compactMap { observation -> RecognizedTextResult? in
                    guard let candidate = observation.topCandidates(1).first else { return nil }

                    let text = candidate.string.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !text.isEmpty, text.count >= 2 else { return nil }  // 過濾太短的文字

                    // Vision 回傳 normalized 座標 (0~1, 左下原點)
                    let corners = TextCorners(
                        topLeft: observation.topLeft,
                        topRight: observation.topRight,
                        bottomLeft: observation.bottomLeft,
                        bottomRight: observation.bottomRight
                    )

                    return RecognizedTextResult(
                        text: text,
                        corners: corners,
                        confidence: candidate.confidence
                    )
                }

                DispatchQueue.main.async { completion(results) }
            }

            // 配置辨識參數
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["en", "zh-Hant", "zh-Hans", "ja", "ko"]

            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
            try? handler.perform([request])
        }
    }
}
