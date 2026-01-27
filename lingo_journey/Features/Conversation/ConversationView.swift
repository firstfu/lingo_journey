import Speech
import SwiftUI
import Translation

struct ConversationView: View {
    @State private var myLanguage = Locale.Language(identifier: "zh-Hant")
    @State private var theirLanguage = Locale.Language(identifier: "en")

    @State private var myText = ""
    @State private var myTranslatedText = ""
    @State private var theirText = ""
    @State private var theirTranslatedText = ""

    @State private var isMyTurn = true
    @State private var isListening = false
    @State private var audioLevel: Float = 0.0

    @State private var speechService = SpeechService()
    @State private var translationConfig: TranslationSession.Configuration?

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                ConversationSection(
                    language: theirLanguage,
                    originalText: theirText,
                    translatedText: theirTranslatedText,
                    isActive: !isMyTurn && isListening,
                    audioLevel: audioLevel
                )
                .rotationEffect(.degrees(180))

                ConversationDivider(
                    topLanguage: theirLanguage,
                    bottomLanguage: myLanguage,
                    onSwap: swapLanguages
                )

                ConversationSection(
                    language: myLanguage,
                    originalText: myText,
                    translatedText: myTranslatedText,
                    isActive: isMyTurn && isListening,
                    audioLevel: audioLevel
                )
            }

            VStack {
                Spacer()
                MicrophoneButton(
                    isListening: isListening,
                    onTap: toggleListening
                )
                .padding(.bottom, AppSpacing.page)
            }
        }
        .translationTask(translationConfig) { session in
            await performTranslation(session: session)
        }
        .onChange(of: speechService.recognizedText) { _, newValue in
            if isMyTurn {
                myText = newValue
            } else {
                theirText = newValue
            }
        }
        .onChange(of: speechService.audioLevel) { _, newValue in
            audioLevel = newValue
        }
    }

    private func toggleListening() {
        if isListening {
            stopListening()
        } else {
            startListening()
        }
    }

    private func startListening() {
        Task {
            let status = await speechService.requestAuthorization()
            guard status == .authorized else { return }

            do {
                let language = isMyTurn ? myLanguage : theirLanguage
                try speechService.startListening(language: language)
                isListening = true
            } catch {
                print("Speech error: \(error)")
            }
        }
    }

    private func stopListening() {
        speechService.stopListening()
        isListening = false

        if isMyTurn && !myText.isEmpty {
            translationConfig = TranslationSession.Configuration(
                source: myLanguage,
                target: theirLanguage
            )
        } else if !isMyTurn && !theirText.isEmpty {
            translationConfig = TranslationSession.Configuration(
                source: theirLanguage,
                target: myLanguage
            )
        }
    }

    private func performTranslation(session: TranslationSession) async {
        do {
            if isMyTurn {
                let response = try await session.translate(myText)
                await MainActor.run {
                    myTranslatedText = response.targetText
                    translationConfig = nil
                    isMyTurn = false
                }
            } else {
                let response = try await session.translate(theirText)
                await MainActor.run {
                    theirTranslatedText = response.targetText
                    translationConfig = nil
                    isMyTurn = true
                }
            }
        } catch {
            await MainActor.run {
                translationConfig = nil
            }
        }
    }

    private func swapLanguages() {
        let temp = myLanguage
        myLanguage = theirLanguage
        theirLanguage = temp
    }
}

// MARK: - Subviews

struct ConversationSection: View {
    let language: Locale.Language
    let originalText: String
    let translatedText: String
    let isActive: Bool
    let audioLevel: Float

    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            if isActive {
                WaveformView(audioLevel: audioLevel, isActive: true)
                    .frame(height: 40)
            }

            if !originalText.isEmpty {
                Text(originalText)
                    .font(.appBody)
                    .foregroundColor(.appTextSecondary)
                    .multilineTextAlignment(.center)
            }

            if !translatedText.isEmpty {
                Text(translatedText)
                    .font(.appTitle2)
                    .foregroundColor(.appTextPrimary)
                    .multilineTextAlignment(.center)
            }

            if originalText.isEmpty && translatedText.isEmpty && !isActive {
                Text("Tap mic to speak")
                    .font(.appCallout)
                    .foregroundColor(.appTextMuted)
            }
        }
        .padding(AppSpacing.xxxl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ConversationDivider: View {
    let topLanguage: Locale.Language
    let bottomLanguage: Locale.Language
    let onSwap: () -> Void

    var body: some View {
        HStack {
            Text(displayName(for: bottomLanguage))
                .font(.appCaption)
                .foregroundColor(.appTextMuted)

            Spacer()

            Button(action: onSwap) {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.system(size: 14))
                    .foregroundColor(.appPrimary)
            }

            Spacer()

            Text(displayName(for: topLanguage))
                .font(.appCaption)
                .foregroundColor(.appTextMuted)
                .rotationEffect(.degrees(180))
        }
        .padding(.horizontal, AppSpacing.xl)
        .padding(.vertical, AppSpacing.md)
        .background(Color.appBorder.opacity(0.5))
    }

    private func displayName(for language: Locale.Language) -> String {
        let locale = Locale(identifier: language.minimalIdentifier)
        return locale.localizedString(forIdentifier: language.minimalIdentifier)?.capitalized ?? language.minimalIdentifier
    }
}

struct MicrophoneButton: View {
    let isListening: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                Circle()
                    .fill(isListening ? Color.appError : Color.appPrimary)
                    .frame(width: 72, height: 72)
                    .shadow(color: (isListening ? Color.appError : Color.appPrimary).opacity(0.4), radius: 12)

                Image(systemName: isListening ? "stop.fill" : "mic.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.white)
            }
        }
        .scaleEffect(isListening ? 1.1 : 1.0)
        .animation(.spring(duration: 0.2), value: isListening)
    }
}

#Preview {
    ConversationView()
}
