import SwiftUI
import SwiftData
import Translation

/// 相機翻譯主視圖
struct ScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var viewModel: ScannerViewModel

    init(sourceLanguage: Locale.Language, targetLanguage: Locale.Language) {
        _viewModel = State(initialValue: ScannerViewModel(
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage
        ))
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 1. 相機預覽
                if viewModel.cameraManager.permissionGranted {
                    CameraPreviewView(session: viewModel.cameraManager.session)
                        .ignoresSafeArea()

                    // 2. 翻譯覆蓋層
                    TranslationOverlay(
                        detectedTexts: viewModel.detectedTexts,
                        viewSize: geometry.size,
                        onTap: { text in
                            viewModel.selectText(text)
                        }
                    )
                } else {
                    unavailableView
                }

                // 3. 頂部導航欄
                VStack {
                    topBar
                    Spacer()
                }

                // 4. 詳情卡片
                if viewModel.showDetailCard, let selectedText = viewModel.selectedText {
                    detailCardOverlay(text: selectedText)
                }
            }
            .onAppear {
                viewModel.viewSize = geometry.size
                viewModel.startScanning()
            }
            .onDisappear {
                viewModel.stopScanning()
                saveToHistory()
            }
        }
        .translationTask(viewModel.translationEngine.configuration) { session in
            await viewModel.translationEngine.performTranslation(session: session)
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.black.opacity(0.3))
                    .clipShape(Circle())
            }

            Spacer()

            Text(languagePairText)
                .font(.appSubheadline)
                .foregroundColor(.white)
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.md)
                .background(Color.black.opacity(0.3))
                .clipShape(Capsule())
        }
        .padding(.horizontal, AppSpacing.xl)
        .padding(.top, AppSpacing.md)
    }

    private var languagePairText: String {
        let source = displayName(for: viewModel.translationEngine.sourceLanguage)
        let target = displayName(for: viewModel.translationEngine.targetLanguage)
        return "\(source) → \(target)"
    }

    // MARK: - Detail Card Overlay

    private func detailCardOverlay(text: DetectedText) -> some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    viewModel.dismissDetailCard()
                }

            VStack {
                Spacer()
                TranslationDetailCard(
                    result: ScanResult(from: text),
                    sourceLanguage: viewModel.translationEngine.sourceLanguage,
                    targetLanguage: viewModel.translationEngine.targetLanguage,
                    onDismiss: {
                        viewModel.dismissDetailCard()
                    }
                )
            }
            .transition(.move(edge: .bottom))
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewModel.showDetailCard)
    }

    // MARK: - Unavailable View

    private var unavailableView: some View {
        VStack(spacing: AppSpacing.xxl) {
            Image(systemName: "camera.fill")
                .font(.system(size: 64))
                .foregroundColor(.appTextMuted)

            Text("相機權限未開啟")
                .font(.appTitle2)
                .foregroundColor(.appTextPrimary)

            Text("請在設定中開啟相機權限以使用掃描翻譯功能。")
                .font(.appBody)
                .foregroundColor(.appTextSecondary)
                .multilineTextAlignment(.center)

            Button(action: openSettings) {
                Text("開啟設定")
                    .font(.appHeadline)
                    .foregroundColor(.appPrimary)
            }
        }
        .padding(AppSpacing.xxxl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
    }

    // MARK: - Helpers

    private func displayName(for language: Locale.Language) -> String {
        let locale = Locale(identifier: language.minimalIdentifier)
        return locale.localizedString(forIdentifier: language.minimalIdentifier)?.capitalized ?? language.minimalIdentifier
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    private func saveToHistory() {
        for text in viewModel.detectedTexts {
            guard let translated = text.translatedText else { continue }

            let record = TranslationRecord(
                sourceText: text.text,
                translatedText: translated,
                sourceLanguage: viewModel.translationEngine.sourceLanguage.minimalIdentifier,
                targetLanguage: viewModel.translationEngine.targetLanguage.minimalIdentifier
            )
            modelContext.insert(record)
        }
    }
}

#Preview {
    ScannerView(
        sourceLanguage: Locale.Language(identifier: "en"),
        targetLanguage: Locale.Language(identifier: "zh-Hant")
    )
}
