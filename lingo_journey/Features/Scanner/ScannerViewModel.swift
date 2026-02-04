import Foundation
import SwiftUI
import VisionKit
import Translation

@Observable
final class ScannerViewModel {
    // MARK: - State
    var scanResults: [ScanResult] = []
    var selectedResultId: UUID?
    var scannerState: ScannerState = .initializing
    var showDetailCard: Bool = false

    // MARK: - Legacy (deprecated, for backward compatibility until ScannerView is refactored)
    var panelDetent: PanelDetent = .half

    // MARK: - Constants
    private let maxOverlayCount = 10
    private let minBoundingBoxArea: CGFloat = 0.001

    // MARK: - Languages
    var sourceLanguage: Locale.Language
    var targetLanguage: Locale.Language

    // MARK: - Translation
    var translationConfiguration: TranslationSession.Configuration?
    private var pendingTranslations: [UUID: String] = [:]

    enum ScannerState {
        case initializing
        case scanning
        case detected(count: Int)
        case noText
        case error(String)
    }

    init(sourceLanguage: Locale.Language, targetLanguage: Locale.Language) {
        self.sourceLanguage = sourceLanguage
        self.targetLanguage = targetLanguage
    }

    // MARK: - Text Recognition
    func handleRecognizedItems(_ items: [RecognizedItem]) {
        var newResults: [ScanResult] = []

        for item in items {
            if case .text(let text) = item {
                let transcript = text.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !transcript.isEmpty else { continue }

                // Convert bounds to CGRect
                let boundingBox = CGRect(
                    x: text.bounds.topLeft.x,
                    y: text.bounds.topLeft.y,
                    width: text.bounds.topRight.x - text.bounds.topLeft.x,
                    height: text.bounds.bottomLeft.y - text.bounds.topLeft.y
                )

                // Filter out bounding boxes that are too small
                let area = boundingBox.width * boundingBox.height
                guard area >= minBoundingBoxArea else { continue }

                if let existingIndex = scanResults.firstIndex(where: { $0.originalText == transcript }) {
                    let existing = scanResults[existingIndex]
                    let updated = ScanResult(
                        id: existing.id,
                        originalText: existing.originalText,
                        translatedText: existing.translatedText,
                        boundingBox: boundingBox,
                        isTranslating: existing.isTranslating,
                        translationFailed: existing.translationFailed
                    )
                    newResults.append(updated)
                } else {
                    let result = ScanResult(
                        originalText: transcript,
                        boundingBox: boundingBox,
                        isTranslating: true,
                        translationFailed: false
                    )
                    newResults.append(result)
                    pendingTranslations[result.id] = transcript
                }

                // Limit the number of overlay results
                if newResults.count >= maxOverlayCount {
                    break
                }
            }
        }

        scanResults = newResults

        if newResults.isEmpty {
            scannerState = .noText
        } else {
            scannerState = .detected(count: newResults.count)
        }

        // Trigger translation for pending items
        if !pendingTranslations.isEmpty {
            triggerTranslation()
        }
    }

    // MARK: - Translation
    private func triggerTranslation() {
        translationConfiguration = TranslationSession.Configuration(
            source: sourceLanguage,
            target: targetLanguage
        )
    }

    func performTranslation(session: TranslationSession) async {
        let pending = pendingTranslations
        pendingTranslations.removeAll()

        for (id, text) in pending {
            do {
                let response = try await session.translate(text)
                await MainActor.run {
                    if let index = scanResults.firstIndex(where: { $0.id == id }) {
                        scanResults[index] = ScanResult(
                            id: id,
                            originalText: scanResults[index].originalText,
                            translatedText: response.targetText,
                            boundingBox: scanResults[index].boundingBox,
                            isTranslating: false,
                            translationFailed: false
                        )
                    }
                }
            } catch {
                await MainActor.run {
                    if let index = scanResults.firstIndex(where: { $0.id == id }) {
                        scanResults[index] = ScanResult(
                            id: id,
                            originalText: scanResults[index].originalText,
                            translatedText: nil,
                            boundingBox: scanResults[index].boundingBox,
                            isTranslating: false,
                            translationFailed: true
                        )
                    }
                }
            }
        }

        await MainActor.run {
            translationConfiguration = nil
        }
    }

    // MARK: - Selection
    func selectResult(_ id: UUID) {
        selectedResultId = selectedResultId == id ? nil : id
        showDetailCard = selectedResultId != nil
    }

    func dismissDetailCard() {
        showDetailCard = false
        selectedResultId = nil
    }

    func getSelectedResult() -> ScanResult? {
        guard let id = selectedResultId else { return nil }
        return scanResults.first { $0.id == id }
    }
}
