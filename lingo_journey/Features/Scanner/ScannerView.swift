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
            } else {
                unavailableView
            }

            // Top navigation bar
            VStack {
                topBar
                Spacer()
            }

            // Bottom panel
            DraggablePanel(currentDetent: $viewModel.panelDetent) {
                panelContent
            }
        }
        .translationTask(viewModel.translationConfiguration) { session in
            await viewModel.performTranslation(session: session)
        }
        .onDisappear {
            saveToHistory()
        }
    }

    // MARK: - Top Bar
    private var topBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.appTextPrimary)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            Text(languagePairText)
                .font(.appSubheadline)
                .foregroundColor(.appTextPrimary)
        }
        .padding(.horizontal, AppSpacing.xl)
        .frame(height: 56)
        .background(
            Color.appSurface.opacity(0.9)
                .background(.ultraThinMaterial)
        )
    }

    private var languagePairText: String {
        let source = displayName(for: viewModel.sourceLanguage)
        let target = displayName(for: viewModel.targetLanguage)
        return "\(source) → \(target)"
    }

    // MARK: - Panel Content
    private var panelContent: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            // Status text
            Text(statusText)
                .font(.appFootnote)
                .foregroundColor(.appTextSecondary)
                .padding(.horizontal, AppSpacing.xl)

            Divider()
                .background(Color.appBorder)
                .padding(.horizontal, AppSpacing.xl)

            // Results list
            if viewModel.scanResults.isEmpty {
                emptyStateView
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: AppSpacing.lg) {
                            ForEach(viewModel.scanResults) { result in
                                ScanResultCard(
                                    result: result,
                                    isSelected: viewModel.selectedResultId == result.id,
                                    onTap: { viewModel.selectResult(result.id) },
                                    onCopy: {}
                                )
                                .id(result.id)
                            }
                        }
                        .padding(.horizontal, AppSpacing.xl)
                        .padding(.bottom, AppSpacing.xxxl)
                    }
                    .onChange(of: viewModel.selectedResultId) { _, newId in
                        if let id = newId {
                            withAnimation {
                                proxy.scrollTo(id, anchor: .center)
                            }
                        }
                    }
                }
            }
        }
        .padding(.top, AppSpacing.lg)
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

    private var emptyStateView: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: "text.viewfinder")
                .font(.system(size: 48))
                .foregroundColor(.appTextMuted)

            Text("將相機對準文字即可開始掃描翻譯")
                .font(.appBody)
                .foregroundColor(.appTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.xxxl)
    }

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
