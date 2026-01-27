import AVFoundation
import Speech
import SwiftUI
import Translation

// MARK: - Conversation Message Model

struct ConversationMessage: Identifiable {
    let id = UUID()
    let isFromMe: Bool
    let timestamp: Date

    // 存儲雙語版本
    let myLanguageText: String      // 用我的語言顯示的版本
    let theirLanguageText: String   // 用對方的語言顯示的版本

    // 標記哪個是原文
    let originalIsMyLanguage: Bool
}

// MARK: - Conversation View

struct ConversationView: View {
    @State private var myLanguage = Locale.Language(identifier: "zh-Hant")
    @State private var theirLanguage = Locale.Language(identifier: "en")

    @State private var messages: [ConversationMessage] = []
    @State private var currentText = ""

    @State private var isListening = false
    @State private var currentSpeakerIsMe: Bool? = nil  // nil = 沒在說話
    @State private var audioLevel: Float = 0.0

    @State private var showMyLanguagePicker = false
    @State private var showTheirLanguagePicker = false
    @State private var showSpeechPermissionAlert = false

    @State private var speechService = SpeechService()
    @State private var translationConfig: TranslationSession.Configuration?
    @State private var pendingTranslationText = ""
    @State private var pendingIsFromMe = true

    // Silence detection
    @State private var silenceTimer: Timer?
    @State private var lastSpeechTime = Date()
    private let silenceThreshold: TimeInterval = 1.5

    private let synthesizer = AVSpeechSynthesizer()

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: - Their Section (Top - Rotated 180°)
                ConversationHalf(
                    messages: messages,
                    currentText: currentSpeakerIsMe == false ? currentText : "",
                    showInTheirLanguage: true,
                    isActive: isListening && currentSpeakerIsMe == false,
                    audioLevel: audioLevel,
                    language: theirLanguage,
                    onLanguageTap: { showTheirLanguagePicker = true },
                    onMicTap: { startListening(isMe: false) },
                    onStopTap: stopListening,
                    isListening: isListening && currentSpeakerIsMe == false
                )
                .rotationEffect(.degrees(180))

                Divider()
                    .background(Color.appBorder)

                // MARK: - My Section (Bottom)
                ConversationHalf(
                    messages: messages,
                    currentText: currentSpeakerIsMe == true ? currentText : "",
                    showInTheirLanguage: false,
                    isActive: isListening && currentSpeakerIsMe == true,
                    audioLevel: audioLevel,
                    language: myLanguage,
                    onLanguageTap: { showMyLanguagePicker = true },
                    onMicTap: { startListening(isMe: true) },
                    onStopTap: stopListening,
                    isListening: isListening && currentSpeakerIsMe == true
                )
            }
        }
        .translationTask(translationConfig) { session in
            await performTranslation(session: session)
        }
        .sheet(isPresented: $showMyLanguagePicker) {
            LanguagePickerSheet(
                title: String(localized: "conversation.selectMyLanguage"),
                currentLanguage: myLanguage,
                onSelect: { language, _ in myLanguage = language }
            )
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showTheirLanguagePicker) {
            LanguagePickerSheet(
                title: String(localized: "conversation.selectTheirLanguage"),
                currentLanguage: theirLanguage,
                onSelect: { language, _ in theirLanguage = language }
            )
            .presentationDetents([.medium, .large])
        }
        .alert("需要語音辨識權限", isPresented: $showSpeechPermissionAlert) {
            Button("取消", role: .cancel) { }
            Button("開啟設定") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        } message: {
            Text("請在設定中開啟麥克風與語音辨識權限以使用語音輸入功能")
        }
        .onChange(of: speechService.recognizedText) { _, newValue in
            if !newValue.isEmpty {
                currentText = newValue
                lastSpeechTime = Date()
            }
        }
        .onChange(of: speechService.audioLevel) { _, newValue in
            audioLevel = newValue
            if newValue > 0.1 {
                lastSpeechTime = Date()
            }
        }
        .onDisappear {
            stopListening()
        }
    }

    // MARK: - Listening Control

    private func startListening(isMe: Bool) {
        // 如果已在聆聽，先停止
        if isListening {
            stopListening()
        }

        Task {
            let status = await speechService.requestAuthorization()
            guard status == .authorized else {
                await MainActor.run {
                    showSpeechPermissionAlert = true
                }
                return
            }

            await MainActor.run {
                currentText = ""
                speechService.recognizedText = ""
                currentSpeakerIsMe = isMe

                let language = isMe ? myLanguage : theirLanguage

                do {
                    try speechService.startListening(language: language)
                    isListening = true
                    startSilenceDetection()
                } catch {
                    print("Speech error: \(error)")
                }
            }
        }
    }

    private func stopListening() {
        silenceTimer?.invalidate()
        silenceTimer = nil
        speechService.stopListening()

        // 如果有文字，觸發翻譯
        if !currentText.isEmpty, let isMe = currentSpeakerIsMe {
            triggerTranslation(isFromMe: isMe)
        } else {
            isListening = false
            currentSpeakerIsMe = nil
            currentText = ""
        }
    }

    // MARK: - Silence Detection

    private func startSilenceDetection() {
        lastSpeechTime = Date()
        silenceTimer?.invalidate()
        silenceTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [self] _ in
            let silenceDuration = Date().timeIntervalSince(lastSpeechTime)

            if !currentText.isEmpty && silenceDuration >= silenceThreshold {
                Task { @MainActor in
                    stopListening()
                }
            }
        }
    }

    // MARK: - Translation

    private func triggerTranslation(isFromMe: Bool) {
        pendingTranslationText = currentText
        pendingIsFromMe = isFromMe

        if isFromMe {
            translationConfig = TranslationSession.Configuration(
                source: myLanguage,
                target: theirLanguage
            )
        } else {
            translationConfig = TranslationSession.Configuration(
                source: theirLanguage,
                target: myLanguage
            )
        }
    }

    private func performTranslation(session: TranslationSession) async {
        do {
            let response = try await session.translate(pendingTranslationText)

            await MainActor.run {
                let message: ConversationMessage

                if pendingIsFromMe {
                    message = ConversationMessage(
                        isFromMe: true,
                        timestamp: Date(),
                        myLanguageText: pendingTranslationText,
                        theirLanguageText: response.targetText,
                        originalIsMyLanguage: true
                    )
                    speakText(response.targetText, language: theirLanguage)
                } else {
                    message = ConversationMessage(
                        isFromMe: false,
                        timestamp: Date(),
                        myLanguageText: response.targetText,
                        theirLanguageText: pendingTranslationText,
                        originalIsMyLanguage: false
                    )
                    speakText(response.targetText, language: myLanguage)
                }

                messages.append(message)

                // Reset
                translationConfig = nil
                currentText = ""
                pendingTranslationText = ""
                isListening = false
                currentSpeakerIsMe = nil
            }
        } catch {
            await MainActor.run {
                translationConfig = nil
                currentText = ""
                pendingTranslationText = ""
                isListening = false
                currentSpeakerIsMe = nil
            }
        }
    }

    private func speakText(_ text: String, language: Locale.Language) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language.minimalIdentifier)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        synthesizer.speak(utterance)
    }
}

// MARK: - Conversation Half

struct ConversationHalf: View {
    let messages: [ConversationMessage]
    let currentText: String
    let showInTheirLanguage: Bool
    let isActive: Bool
    let audioLevel: Float
    let language: Locale.Language
    let onLanguageTap: () -> Void
    let onMicTap: () -> Void
    let onStopTap: () -> Void
    let isListening: Bool

    private var displayName: String {
        let locale = Locale(identifier: language.minimalIdentifier)
        return locale.localizedString(forIdentifier: language.minimalIdentifier)?.capitalized ?? language.minimalIdentifier
    }

    var body: some View {
        VStack(spacing: 0) {
            // Language header
            HStack {
                Button(action: onLanguageTap) {
                    HStack(spacing: AppSpacing.sm) {
                        Text(displayName)
                            .font(.appHeadline)
                            .foregroundColor(.appTextPrimary)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12))
                            .foregroundColor(.appTextSecondary)
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.vertical, AppSpacing.md)
                    .background(Color.appSurface)
                    .clipShape(Capsule())
                }

                Spacer()

                // Mic button
                Button(action: isListening ? onStopTap : onMicTap) {
                    ZStack {
                        Circle()
                            .fill(isListening ? Color.appError : Color.appPrimary)
                            .frame(width: 52, height: 52)
                            .shadow(color: (isListening ? Color.appError : Color.appPrimary).opacity(0.3), radius: 8)

                        Image(systemName: isListening ? "stop.fill" : "mic.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    }
                }
                .scaleEffect(isListening ? 1.1 : 1.0)
                .animation(.spring(duration: 0.2), value: isListening)
            }
            .padding(.horizontal, AppSpacing.xl)
            .padding(.vertical, AppSpacing.lg)

            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: AppSpacing.md) {
                        ForEach(messages) { message in
                            MessageRow(
                                text: showInTheirLanguage ? message.theirLanguageText : message.myLanguageText,
                                isFromMe: message.isFromMe,
                                isOriginal: showInTheirLanguage ? !message.originalIsMyLanguage : message.originalIsMyLanguage
                            )
                            .id(message.id)
                        }

                        if !currentText.isEmpty {
                            MessageRow(
                                text: currentText,
                                isFromMe: !showInTheirLanguage,
                                isOriginal: true,
                                isHighlighted: true
                            )
                            .id("current")
                        }
                    }
                    .padding(.horizontal, AppSpacing.xl)
                    .padding(.bottom, AppSpacing.xl)
                }
                .onChange(of: messages.count) { _, _ in
                    withAnimation {
                        proxy.scrollTo(messages.last?.id, anchor: .bottom)
                    }
                }
                .onChange(of: currentText) { _, _ in
                    withAnimation {
                        proxy.scrollTo("current", anchor: .bottom)
                    }
                }
            }

            // Waveform when listening
            if isActive {
                HStack(spacing: AppSpacing.md) {
                    WaveformView(audioLevel: audioLevel, isActive: true, barCount: 7)
                        .frame(height: 28)
                    Text("conversation.listening")
                        .font(.appCaption)
                        .foregroundColor(.appPrimary)
                }
                .padding(.horizontal, AppSpacing.xl)
                .padding(.bottom, AppSpacing.lg)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appSurface.opacity(0.3))
    }
}

// MARK: - Message Row

struct MessageRow: View {
    let text: String
    let isFromMe: Bool
    let isOriginal: Bool
    var isHighlighted: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(text)
                .font(.appBody)
                .foregroundColor(isHighlighted ? .appPrimary : .appTextPrimary)
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.md)
                .background(bubbleBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium))

            if !isHighlighted {
                HStack(spacing: AppSpacing.sm) {
                    Circle()
                        .fill(isFromMe ? Color.appPrimary : Color.appTextSecondary)
                        .frame(width: 6, height: 6)
                    Text(isOriginal ? "conversation.original" : "conversation.translated")
                        .font(.appCaption)
                        .foregroundColor(.appTextMuted)
                }
                .padding(.leading, AppSpacing.sm)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var bubbleBackground: Color {
        if isHighlighted {
            return Color.appPrimary.opacity(0.15)
        }
        return Color.appSurface
    }
}

#Preview {
    ConversationView()
}
