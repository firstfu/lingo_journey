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
    var panelDetent: PanelDetent = .half

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

                // Check if this text already exists
                if let existingIndex = scanResults.firstIndex(where: { $0.originalText == transcript }) {
                    let existing = scanResults[existingIndex]
                    let updated = ScanResult(
                        id: existing.id,
                        originalText: existing.originalText,
                        translatedText: existing.translatedText,
                        boundingBox: text.bounds,
                        isTranslating: existing.isTranslating
                    )
                    newResults.append(updated)
                } else {
                    let result = ScanResult(
                        originalText: transcript,
                        boundingBox: text.bounds,
                        isTranslating: true
                    )
                    newResults.append(result)
                    pendingTranslations[result.id] = transcript
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
                            isTranslating: false
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
                            isTranslating: false
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
    }

    func getSelectedResult() -> ScanResult? {
        guard let id = selectedResultId else { return nil }
        return scanResults.first { $0.id == id }
    }
}
