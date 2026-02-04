import SwiftUI
import SwiftData
import VisionKit
import Translation

struct ScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var viewModel: ScannerViewModel
    @State private var isScanning = true
    @State private var textRecognitionService = TextRecognitionService()

    init(sourceLanguage: Locale.Language, targetLanguage: Locale.Language) {
        _viewModel = State(initialValue: ScannerViewModel(
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage
        ))
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Camera view
                if textRecognitionService.isAvailable {
                    DataScannerRepresentable(
                        onItemsRecognized: { items in
                            viewModel.handleRecognizedItems(items)
                        },
                        onItemTapped: { item in
                            if case .text(let text) = item {
                                if let result = viewModel.scanResults.first(where: { $0.originalText == text.transcript }) {
                                    viewModel.selectResult(result.id)
                                }
                            }
                        },
                        isScanning: $isScanning
                    )
                    .ignoresSafeArea()

                    // AR Overlay Layer
                    overlayLayer(containerSize: geometry.size)
                } else {
                    unavailableView
                }

                // Top navigation bar
                VStack {
                    topBar
                    Spacer()
                }

                // Status indicator at bottom
                VStack {
                    Spacer()
                    statusIndicator
                        .padding(.bottom, AppSpacing.xxxl)
                }

                // Detail card overlay
                if viewModel.showDetailCard, let selectedResult = viewModel.getSelectedResult() {
                    detailCardOverlay(result: selectedResult)
                }
            }
        }
        .translationTask(viewModel.translationConfiguration) { session in
            await viewModel.performTranslation(session: session)
        }
        .onDisappear {
            saveToHistory()
        }
    }

    // MARK: - AR Overlay Layer
    private func overlayLayer(containerSize: CGSize) -> some View {
        ZStack {
            ForEach(viewModel.scanResults) { result in
                TranslationOverlayView(
                    result: result,
                    containerSize: containerSize,
                    onTap: {
                        viewModel.selectResult(result.id)
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
        let source = displayName(for: viewModel.sourceLanguage)
        let target = displayName(for: viewModel.targetLanguage)
        return "\(source) → \(target)"
    }

    // MARK: - Status Indicator
    private var statusIndicator: some View {
        Text(statusText)
            .font(.appFootnote)
            .foregroundColor(.white)
            .padding(.horizontal, AppSpacing.xl)
            .padding(.vertical, AppSpacing.md)
            .background(Color.black.opacity(0.5))
            .clipShape(Capsule())
    }

    private var statusText: String {
        switch viewModel.scannerState {
        case .initializing:
            return String(localized: "正在啟動相機...")
        case .scanning:
            return String(localized: "將相機對準文字")
        case .detected(let count):
            return String(localized: "偵測到 \(count) 段文字")
        case .noText:
            return String(localized: "未偵測到文字")
        case .error(let message):
            return String(localized: "錯誤：\(message)")
        }
    }

    // MARK: - Detail Card Overlay
    private func detailCardOverlay(result: ScanResult) -> some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    viewModel.dismissDetailCard()
                }

            // Card from bottom
            VStack {
                Spacer()
                TranslationDetailCard(
                    result: result,
                    sourceLanguage: viewModel.sourceLanguage,
                    targetLanguage: viewModel.targetLanguage,
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

            Text("掃描功能不可用")
                .font(.appTitle2)
                .foregroundColor(.appTextPrimary)

            Text("您的裝置不支援即時文字掃描功能，或相機權限未開啟。")
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
        for result in viewModel.scanResults {
            guard let translated = result.translatedText else { continue }

            let record = TranslationRecord(
                sourceText: result.originalText,
                translatedText: translated,
                sourceLanguage: viewModel.sourceLanguage.minimalIdentifier,
                targetLanguage: viewModel.targetLanguage.minimalIdentifier
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
