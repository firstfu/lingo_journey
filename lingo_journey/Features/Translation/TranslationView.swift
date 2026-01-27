import SwiftData
import SwiftUI
import Translation

struct TranslationView: View {
    @State private var sourceLanguage = Locale.Language(identifier: "en")
    @State private var targetLanguage = Locale.Language(identifier: "zh-Hant")
    @State private var sourceText = ""
    @State private var translatedText = ""
    @State private var isTranslating = false
    @State private var configuration: TranslationSession.Configuration?

    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: AppSpacing.xxl) {
                    Text("Translate")
                        .font(.appTitle1)
                        .foregroundColor(.appTextPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, AppSpacing.xl)

                    LanguageSelector(
                        sourceLanguage: $sourceLanguage,
                        targetLanguage: $targetLanguage,
                        onSwap: swapLanguages
                    )

                    TranslationInputCard(
                        languageName: displayName(for: sourceLanguage),
                        text: $sourceText,
                        onMicTap: { }
                    )
                    .padding(.horizontal, AppSpacing.xl)

                    PrimaryButton(
                        title: "Translate",
                        action: triggerTranslation,
                        isLoading: isTranslating,
                        isDisabled: sourceText.isEmpty
                    )
                    .padding(.horizontal, AppSpacing.xl)

                    if !translatedText.isEmpty {
                        TranslationResultCard(
                            languageName: displayName(for: targetLanguage),
                            translatedText: translatedText,
                            onCopy: copyToClipboard,
                            onSpeak: { },
                            onFavorite: saveToFavorites
                        )
                        .padding(.horizontal, AppSpacing.xl)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .padding(.vertical, AppSpacing.xxl)
            }
        }
        .translationTask(configuration) { session in
            await performTranslation(session: session)
        }
        .animation(.spring(duration: 0.3), value: translatedText)
    }

    private func swapLanguages() {
        let temp = sourceLanguage
        sourceLanguage = targetLanguage
        targetLanguage = temp

        let tempText = sourceText
        sourceText = translatedText
        translatedText = tempText
    }

    private func triggerTranslation() {
        guard !sourceText.isEmpty else { return }
        configuration = TranslationSession.Configuration(
            source: sourceLanguage,
            target: targetLanguage
        )
    }

    private func performTranslation(session: TranslationSession) async {
        isTranslating = true
        do {
            let response = try await session.translate(sourceText)
            await MainActor.run {
                translatedText = response.targetText
                isTranslating = false
                configuration = nil
            }
        } catch {
            await MainActor.run {
                isTranslating = false
                configuration = nil
            }
        }
    }

    private func copyToClipboard() {
        UIPasteboard.general.string = translatedText
    }

    private func saveToFavorites() {
        let record = TranslationRecord(
            sourceText: sourceText,
            translatedText: translatedText,
            sourceLanguage: sourceLanguage.minimalIdentifier,
            targetLanguage: targetLanguage.minimalIdentifier
        )
        record.isFavorite = true
        modelContext.insert(record)
    }

    private func displayName(for language: Locale.Language) -> String {
        let locale = Locale(identifier: language.minimalIdentifier)
        return locale.localizedString(forIdentifier: language.minimalIdentifier)?.capitalized ?? language.minimalIdentifier
    }
}

#Preview {
    TranslationView()
}
