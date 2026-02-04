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

    /// 辨識圖像中的文字 (從 CVPixelBuffer)
    func recognizeText(
        in pixelBuffer: CVPixelBuffer,
        completion: @escaping ([RecognizedTextResult]) -> Void
    ) {
        performRecognition(
            handler: VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]),
            completion: completion
        )
    }

    /// 辨識圖像中的文字 (從 CIImage)
    func recognizeText(
        from ciImage: CIImage,
        completion: @escaping ([RecognizedTextResult]) -> Void
    ) {
        performRecognition(
            handler: VNImageRequestHandler(ciImage: ciImage, options: [:]),
            completion: completion
        )
    }

    /// 執行文字辨識
    private func performRecognition(
        handler: VNImageRequestHandler,
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
                    guard !text.isEmpty, text.count >= 2 else { return nil }

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

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["en", "zh-Hant", "zh-Hans", "ja", "ko"]

            try? handler.perform([request])
        }
    }
}
