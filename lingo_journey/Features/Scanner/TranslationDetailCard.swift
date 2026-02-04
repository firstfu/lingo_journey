import AVFoundation
import SwiftUI

struct TranslationDetailCard: View {
    let result: ScanResult
    let sourceLanguage: Locale.Language
    let targetLanguage: Locale.Language
    let onDismiss: () -> Void

    @State private var showCopied = false
    @State private var speechSynthesizer = AVSpeechSynthesizer()

    var body: some View {
        VStack(spacing: 0) {
            // 拖曳指示條
            Capsule()
                .fill(Color.appTextMuted)
                .frame(width: 36, height: 4)
                .padding(.top, AppSpacing.md)
                .padding(.bottom, AppSpacing.lg)

            VStack(spacing: AppSpacing.xl) {
                // 原文區塊
                textSection(
                    label: String(localized: "原文"),
                    text: result.originalText,
                    language: sourceLanguage
                )

                Divider().background(Color.appBorder)

                // 譯文區塊
                if result.isTranslating {
                    translatingSection()
                } else if let translatedText = result.translatedText {
                    textSection(
                        label: String(localized: "譯文"),
                        text: translatedText,
                        language: targetLanguage
                    )
                } else {
                    failedSection()
                }

                Divider().background(Color.appBorder)

                // 複製按鈕
                copyButton()
            }
            .padding(.horizontal, AppSpacing.xl)
            .padding(.bottom, AppSpacing.xxxl)
        }
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous))
    }

    // MARK: - Text Section

    private func textSection(label: String, text: String, language: Locale.Language) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text(label)
                    .font(.appCaption)
                    .foregroundStyle(Color.appTextSecondary)

                Spacer()

                Button {
                    speak(text: text, language: language)
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.appBody)
                        .foregroundStyle(Color.appPrimary)
                }
                .accessibilityLabel(String(localized: "朗讀"))
            }

            Text(text)
                .font(.appBody)
                .foregroundStyle(Color.appTextPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Translating Section

    private func translatingSection() -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text(String(localized: "譯文"))
                .font(.appCaption)
                .foregroundStyle(Color.appTextSecondary)

            HStack(spacing: AppSpacing.md) {
                ProgressView()
                    .tint(Color.appPrimary)

                Text(String(localized: "翻譯中..."))
                    .font(.appBody)
                    .foregroundStyle(Color.appTextMuted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Failed Section

    private func failedSection() -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text(String(localized: "譯文"))
                .font(.appCaption)
                .foregroundStyle(Color.appTextSecondary)

            HStack(spacing: AppSpacing.md) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Color.appWarning)

                Text(String(localized: "翻譯失敗"))
                    .font(.appBody)
                    .foregroundStyle(Color.appTextMuted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Copy Button

    private func copyButton() -> some View {
        Button {
            handleCopy()
        } label: {
            HStack(spacing: AppSpacing.md) {
                if showCopied {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.appSuccess)
                    Text(String(localized: "已複製"))
                        .foregroundStyle(Color.appSuccess)
                } else {
                    Image(systemName: "doc.on.doc")
                        .foregroundStyle(Color.appPrimary)
                    Text(String(localized: "複製翻譯結果"))
                        .foregroundStyle(Color.appPrimary)
                }
            }
            .font(.appHeadline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.lg)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                    .fill(showCopied ? Color.appSuccess.opacity(0.15) : Color.appPrimary.opacity(0.15))
            )
        }
        .disabled(result.translatedText == nil)
        .opacity(result.translatedText == nil ? 0.5 : 1.0)
    }

    // MARK: - Actions

    private func handleCopy() {
        guard let translatedText = result.translatedText else { return }

        // 複製到剪貼簿
        UIPasteboard.general.string = "\(result.originalText)\n\(translatedText)"

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        // 顯示已複製狀態
        withAnimation(.easeInOut(duration: 0.2)) {
            showCopied = true
        }

        // 1.5 秒後恢復
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showCopied = false
                }
            }
        }
    }

    private func speak(text: String, language: Locale.Language) {
        // 停止之前的朗讀
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: text)

        // 將 Locale.Language 轉換為語音識別碼
        let languageCode = language.languageCode?.identifier ?? "en"
        let regionCode = language.region?.identifier

        let voiceIdentifier: String
        if let region = regionCode {
            voiceIdentifier = "\(languageCode)-\(region)"
        } else {
            voiceIdentifier = languageCode
        }

        // 嘗試找到對應的語音
        if let voice = AVSpeechSynthesisVoice(language: voiceIdentifier) {
            utterance.voice = voice
        } else if let voice = AVSpeechSynthesisVoice(language: languageCode) {
            utterance.voice = voice
        }

        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0

        speechSynthesizer.speak(utterance)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()

        VStack {
            Spacer()

            TranslationDetailCard(
                result: ScanResult(
                    originalText: "Hello, World!",
                    translatedText: "你好，世界！",
                    boundingBox: .zero
                ),
                sourceLanguage: Locale.Language(identifier: "en"),
                targetLanguage: Locale.Language(identifier: "zh-Hant"),
                onDismiss: {}
            )
        }
    }
}
