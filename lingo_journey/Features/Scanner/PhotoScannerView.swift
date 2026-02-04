import SwiftUI
import SwiftData
import Translation

/// 拍照翻譯主視圖
struct PhotoScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var viewModel: PhotoScannerViewModel

    init(sourceLanguage: Locale.Language, targetLanguage: Locale.Language) {
        _viewModel = State(initialValue: PhotoScannerViewModel(
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage
        ))
    }

    var body: some View {
        ZStack {
            // 根據狀態顯示不同內容
            switch viewModel.state {
            case .preview:
                previewView

            case .processing(let step):
                processingView(step: step)

            case .result:
                resultView
            }

            // 頂部導航欄 (始終顯示)
            VStack {
                topBar
                Spacer()
            }

            // 詳情卡片
            if viewModel.showDetailCard, let selectedText = viewModel.selectedText {
                detailCardOverlay(text: selectedText)
            }

            // 錯誤提示
            if let error = viewModel.errorMessage {
                errorToast(message: error)
            }

            // 保存成功提示
            if viewModel.showSaveSuccess {
                saveSuccessToast
            }
        }
        .onAppear {
            viewModel.startCamera()
        }
        .onDisappear {
            viewModel.stopCamera()
            saveToHistory()
        }
        .translationTask(viewModel.translationEngine.configuration) { session in
            await viewModel.translationEngine.performTranslation(session: session)
        }
    }

    // MARK: - Preview View

    private var previewView: some View {
        ZStack {
            // 相機預覽
            if viewModel.cameraManager.permissionGranted {
                CameraPreviewView(session: viewModel.cameraManager.session)
                    .ignoresSafeArea()

                // 拍照按鈕
                VStack {
                    Spacer()
                    captureButton
                        .padding(.bottom, AppSpacing.xxxl)
                }
            } else {
                unavailableView
            }
        }
    }

    private var captureButton: some View {
        Button {
            Task {
                await viewModel.captureAndProcess()
            }
        } label: {
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 70, height: 70)

                Circle()
                    .stroke(Color.white, lineWidth: 4)
                    .frame(width: 80, height: 80)
            }
        }
    }

    // MARK: - Processing View

    private func processingView(step: ProcessingStep) -> some View {
        ZStack {
            // 顯示拍攝的照片 (半透明遮罩)
            if let image = viewModel.capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                Color.black.opacity(0.5)
                    .ignoresSafeArea()
            }

            // 進度指示
            VStack(spacing: AppSpacing.lg) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)

                Text(step == .recognizing ? "辨識文字中..." : "翻譯中...")
                    .font(.appHeadline)
                    .foregroundColor(.white)
            }
        }
    }

    // MARK: - Result View

    private var resultView: some View {
        Group {
            if let image = viewModel.capturedImage {
                PhotoResultView(
                    image: image,
                    detectedTexts: viewModel.detectedTexts,
                    onTextTap: { text in
                        viewModel.selectText(text)
                    },
                    onRetake: {
                        viewModel.retake()
                    },
                    onSave: {
                        Task {
                            await viewModel.saveToPhotos()
                        }
                    },
                    onShare: {
                        shareImage()
                    }
                )
            }
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

    // MARK: - Toasts

    private func errorToast(message: String) -> some View {
        VStack {
            Spacer()
            Text(message)
                .font(.appBody)
                .foregroundColor(.white)
                .padding()
                .background(Color.red.opacity(0.9))
                .cornerRadius(AppRadius.medium)
                .padding(.bottom, 100)
        }
        .transition(.move(edge: .bottom))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                viewModel.errorMessage = nil
            }
        }
    }

    private var saveSuccessToast: some View {
        VStack {
            Spacer()
            HStack {
                Image(systemName: "checkmark.circle.fill")
                Text("已保存到相簿")
            }
            .font(.appBody)
            .foregroundColor(.white)
            .padding()
            .background(Color.green.opacity(0.9))
            .cornerRadius(AppRadius.medium)
            .padding(.bottom, 100)
        }
        .transition(.move(edge: .bottom))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                viewModel.showSaveSuccess = false
            }
        }
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

    private func shareImage() {
        guard let image = viewModel.generateResultImage() else { return }

        let activityVC = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
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

// MARK: - Renamed for backward compatibility

typealias ScannerView = PhotoScannerView

#Preview {
    PhotoScannerView(
        sourceLanguage: Locale.Language(identifier: "en"),
        targetLanguage: Locale.Language(identifier: "zh-Hant")
    )
}
