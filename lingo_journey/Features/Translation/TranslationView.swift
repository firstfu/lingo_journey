import ActivityKit
import AVFoundation
import Speech
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
    @State private var translationTrigger = UUID()
    @State private var currentRecord: TranslationRecord?

    // Scanner states
    @State private var showScanner = false
    @State private var showCameraPermissionAlert = false

    // Speech states
    @State private var speechService = SpeechService()
    @State private var isListening = false
    @State private var showSpeechPermissionAlert = false

    // Language picker states
    @State private var showSourceLanguagePicker = false
    @State private var showTargetLanguagePicker = false
    @State private var showDownloadAlert = false
    @State private var pendingLanguage: Locale.Language?
    @State private var pendingLanguageIsSource = true

    // Translation guide states
    @State private var showTranslationGuide = false
    @AppStorage("hasSeenTranslationGuide") private var hasSeenGuide = false
    @State private var dontShowGuideAgain = false

    @Environment(\.modelContext) private var modelContext

    private let liveActivityManager = LiveActivityManager.shared

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: AppSpacing.xxl) {
                    Text("translation.title")
                        .font(.appTitle1)
                        .foregroundColor(.appTextPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, AppSpacing.xl)

                    LanguageSelector(
                        sourceLanguage: $sourceLanguage,
                        targetLanguage: $targetLanguage,
                        onSwap: swapLanguages,
                        onSourceTap: { showSourceLanguagePicker = true },
                        onTargetTap: { showTargetLanguagePicker = true }
                    )

                    TranslationInputCard(
                        languageName: displayName(for: sourceLanguage),
                        text: $sourceText,
                        onCameraTap: handleCameraTap,
                        onMicTap: handleMicTap,
                        isListening: isListening
                    )
                    .padding(.horizontal, AppSpacing.xl)

                    PrimaryButton(
                        title: String(localized: "translation.button"),
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
                            onFavorite: toggleFavorite,
                            isFavorite: currentRecord?.isFavorite ?? false
                        )
                        .padding(.horizontal, AppSpacing.xl)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .padding(.vertical, AppSpacing.xxl)
            }
            .scrollDismissesKeyboard(.interactively)
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        }
        .translationTask(configuration) { session in
            await performTranslation(session: session)
        }
        .id(translationTrigger)
        .animation(.spring(duration: 0.3), value: translatedText)
        .onChange(of: speechService.recognizedText) { _, newValue in
            sourceText = newValue
        }
        .fullScreenCover(isPresented: $showScanner) {
            ScannerView(
                sourceLanguage: sourceLanguage,
                targetLanguage: targetLanguage
            )
        }
        .alert("需要相機權限", isPresented: $showCameraPermissionAlert) {
            Button("取消", role: .cancel) { }
            Button("開啟設定") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        } message: {
            Text("請在設定中開啟相機權限以使用掃描翻譯功能")
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
        .sheet(isPresented: $showSourceLanguagePicker) {
            LanguagePickerSheet(
                title: String(localized: "language.picker.source"),
                currentLanguage: sourceLanguage
            ) { language, isDownloaded in
                handleLanguageSelection(language: language, isDownloaded: isDownloaded, isSource: true)
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showTargetLanguagePicker) {
            LanguagePickerSheet(
                title: String(localized: "language.picker.target"),
                currentLanguage: targetLanguage
            ) { language, isDownloaded in
                handleLanguageSelection(language: language, isDownloaded: isDownloaded, isSource: false)
            }
            .presentationDetents([.medium, .large])
        }
        .languageDownloadAlert(
            isPresented: $showDownloadAlert,
            languageName: pendingLanguage.map { displayName(for: $0) } ?? "",
            onDownload: handleDownloadLanguage,
            onUseTemporarily: handleUseTemporarily
        )
        .sheet(isPresented: $showTranslationGuide) {
            TranslationGuideSheet(
                isPresented: $showTranslationGuide,
                dontShowAgain: $dontShowGuideAgain
            ) {
                // 用戶確認後，更新設定並開始翻譯
                if dontShowGuideAgain {
                    hasSeenGuide = true
                }
                startTranslation()
            }
        }
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

        Task {
            // 檢查語言包是否已下載
            let isInstalled = await checkLanguageAvailability(
                source: sourceLanguage,
                target: targetLanguage
            )

            await MainActor.run {
                if !isInstalled && !hasSeenGuide {
                    // 語言包未下載且用戶未看過引導，顯示引導提示
                    showTranslationGuide = true
                } else {
                    // 直接開始翻譯
                    startTranslation()
                }
            }
        }
    }

    private func startTranslation() {
        // Start Live Activity
        liveActivityManager.startActivity(
            sourceLanguage: displayName(for: sourceLanguage),
            targetLanguage: displayName(for: targetLanguage),
            sourceText: sourceText
        )

        // 生成新的 UUID 強制 SwiftUI 重建 translationTask
        translationTrigger = UUID()
        configuration = TranslationSession.Configuration(
            source: sourceLanguage,
            target: targetLanguage
        )
    }

    private func checkLanguageAvailability(
        source: Locale.Language,
        target: Locale.Language
    ) async -> Bool {
        let availability = LanguageAvailability()
        let status = await availability.status(from: source, to: target)
        return status == .installed
    }

    private func performTranslation(session: TranslationSession) async {
        isTranslating = true
        let textToTranslate = sourceText

        do {
            let response = try await session.translate(textToTranslate)

            // Update Live Activity with result
            await liveActivityManager.updateActivity(
                translatedText: response.targetText,
                sourceText: textToTranslate
            )

            await MainActor.run {
                translatedText = response.targetText
                isTranslating = false
                configuration = nil

                // 自動保存到歷史記錄
                let record = TranslationRecord(
                    sourceText: textToTranslate,
                    translatedText: response.targetText,
                    sourceLanguage: sourceLanguage.minimalIdentifier,
                    targetLanguage: targetLanguage.minimalIdentifier
                )
                modelContext.insert(record)
                currentRecord = record
            }

            // End Live Activity after showing result
            liveActivityManager.endActivityAfterDelay(seconds: 5.0)

        } catch {
            // End Live Activity on error
            await liveActivityManager.endActivity()

            await MainActor.run {
                isTranslating = false
                configuration = nil
            }
        }
    }

    private func copyToClipboard() {
        UIPasteboard.general.string = translatedText
    }

    private func toggleFavorite() {
        guard let record = currentRecord else { return }
        record.isFavorite.toggle()
    }

    private func displayName(for language: Locale.Language) -> String {
        let locale = Locale(identifier: language.minimalIdentifier)
        return locale.localizedString(forIdentifier: language.minimalIdentifier)?.capitalized ?? language.minimalIdentifier
    }

    // MARK: - Microphone
    private func handleMicTap() {
        if isListening {
            stopListening()
        } else {
            startListening()
        }
    }

    private func startListening() {
        Task {
            let status = await speechService.requestAuthorization()
            guard status == .authorized else {
                await MainActor.run {
                    showSpeechPermissionAlert = true
                }
                return
            }

            do {
                try speechService.startListening(language: sourceLanguage)
                await MainActor.run {
                    isListening = true
                }
            } catch {
                print("Speech error: \(error)")
            }
        }
    }

    private func stopListening() {
        speechService.stopListening()
        isListening = false
    }

    // MARK: - Camera
    private func handleCameraTap() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)

        switch status {
        case .authorized:
            showScanner = true
        case .notDetermined:
            Task {
                let granted = await AVCaptureDevice.requestAccess(for: .video)
                await MainActor.run {
                    if granted {
                        showScanner = true
                    } else {
                        showCameraPermissionAlert = true
                    }
                }
            }
        case .denied, .restricted:
            showCameraPermissionAlert = true
        @unknown default:
            showCameraPermissionAlert = true
        }
    }

    // MARK: - Language Selection
    private func handleLanguageSelection(language: Locale.Language, isDownloaded: Bool, isSource: Bool) {
        if isDownloaded {
            if isSource {
                sourceLanguage = language
            } else {
                targetLanguage = language
            }
        } else {
            pendingLanguage = language
            pendingLanguageIsSource = isSource
            showDownloadAlert = true
        }
    }

    private func handleDownloadLanguage() {
        guard let language = pendingLanguage else { return }

        // TODO: Implement actual download using LanguageAvailability
        // For now, just set the language
        if pendingLanguageIsSource {
            sourceLanguage = language
        } else {
            targetLanguage = language
        }
        pendingLanguage = nil
    }

    private func handleUseTemporarily() {
        guard let language = pendingLanguage else { return }

        if pendingLanguageIsSource {
            sourceLanguage = language
        } else {
            targetLanguage = language
        }
        pendingLanguage = nil
    }
}

#Preview {
    TranslationView()
}
