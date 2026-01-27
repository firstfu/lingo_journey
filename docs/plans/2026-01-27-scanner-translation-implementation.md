# 掃描翻譯功能實作計畫

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 在翻譯 Tab 新增相機掃描翻譯功能，使用 DataScannerViewController 即時偵測文字並翻譯。

**Architecture:** 使用 iOS 16+ VisionKit 的 DataScannerViewController 進行即時文字偵測，透過 UIViewControllerRepresentable 整合到 SwiftUI。偵測到的文字透過現有的 Translation Framework 翻譯，結果顯示在可拖曳的底部面板中。

**Tech Stack:** SwiftUI, VisionKit (DataScannerViewController), Translation Framework, SwiftData

---

## Task 1: 建立掃描結果資料模型

**Files:**
- Create: `lingo_journey/Core/Models/ScanResult.swift`

**Step 1: 建立 ScanResult 模型**

```swift
import Foundation

struct ScanResult: Identifiable, Equatable {
    let id: UUID
    let originalText: String
    var translatedText: String?
    let boundingBox: CGRect
    var isTranslating: Bool

    init(
        id: UUID = UUID(),
        originalText: String,
        translatedText: String? = nil,
        boundingBox: CGRect,
        isTranslating: Bool = false
    ) {
        self.id = id
        self.originalText = originalText
        self.translatedText = translatedText
        self.boundingBox = boundingBox
        self.isTranslating = isTranslating
    }
}
```

**Step 2: Commit**

```bash
git add lingo_journey/Core/Models/ScanResult.swift
git commit -m "feat(scanner): add ScanResult data model"
```

---

## Task 2: 建立可拖曳底部面板元件

**Files:**
- Create: `lingo_journey/DesignSystem/Components/DraggablePanel.swift`

**Step 1: 建立 DraggablePanel 元件**

```swift
import SwiftUI

enum PanelDetent {
    case collapsed
    case half
    case full

    var heightRatio: CGFloat {
        switch self {
        case .collapsed: return 0.15
        case .half: return 0.4
        case .full: return 0.85
        }
    }
}

struct DraggablePanel<Content: View>: View {
    @Binding var currentDetent: PanelDetent
    let content: () -> Content

    @GestureState private var dragOffset: CGFloat = 0
    @State private var previousDetent: PanelDetent = .half

    var body: some View {
        GeometryReader { geometry in
            let maxHeight = geometry.size.height
            let currentHeight = maxHeight * currentDetent.heightRatio

            VStack(spacing: 0) {
                // Drag handle
                VStack(spacing: AppSpacing.md) {
                    Capsule()
                        .fill(Color.appTextMuted)
                        .frame(width: 36, height: 4)
                        .padding(.top, AppSpacing.md)

                    content()
                }
                .frame(maxWidth: .infinity)
                .frame(height: currentHeight + dragOffset, alignment: .top)
                .background(Color.appSurface)
                .clipShape(
                    RoundedCorner(radius: AppRadius.xl, corners: [.topLeft, .topRight])
                )
                .gesture(
                    DragGesture()
                        .updating($dragOffset) { value, state, _ in
                            state = -value.translation.height
                        }
                        .onEnded { value in
                            let dragAmount = -value.translation.height
                            let velocity = -value.predictedEndTranslation.height

                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                if velocity > 100 {
                                    // Swiping up
                                    switch currentDetent {
                                    case .collapsed: currentDetent = .half
                                    case .half: currentDetent = .full
                                    case .full: break
                                    }
                                } else if velocity < -100 {
                                    // Swiping down
                                    switch currentDetent {
                                    case .collapsed: break
                                    case .half: currentDetent = .collapsed
                                    case .full: currentDetent = .half
                                    }
                                } else {
                                    // Snap to nearest
                                    let newHeight = currentHeight + dragAmount
                                    let ratio = newHeight / maxHeight

                                    if ratio < 0.25 {
                                        currentDetent = .collapsed
                                    } else if ratio < 0.6 {
                                        currentDetent = .half
                                    } else {
                                        currentDetent = .full
                                    }
                                }
                            }
                        }
                )
            }
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
    }
}

// Helper for rounded corners on specific corners
struct RoundedCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()

        DraggablePanel(currentDetent: .constant(.half)) {
            VStack {
                Text("Panel Content")
                    .foregroundColor(.appTextPrimary)
            }
            .padding()
        }
    }
}
```

**Step 2: Commit**

```bash
git add lingo_journey/DesignSystem/Components/DraggablePanel.swift
git commit -m "feat(scanner): add DraggablePanel component"
```

---

## Task 3: 建立掃描結果卡片元件

**Files:**
- Create: `lingo_journey/DesignSystem/Components/ScanResultCard.swift`

**Step 1: 建立 ScanResultCard 元件**

```swift
import SwiftUI

struct ScanResultCard: View {
    let result: ScanResult
    let isSelected: Bool
    let onTap: () -> Void
    let onCopy: () -> Void

    @State private var showCopied = false

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: AppSpacing.lg) {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text(result.originalText)
                        .font(.appSubheadline)
                        .foregroundColor(.appTextSecondary)
                        .lineLimit(2)

                    if result.isTranslating {
                        HStack(spacing: AppSpacing.md) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .appPrimary))
                                .scaleEffect(0.7)
                            Text("翻譯中...")
                                .font(.appBody)
                                .foregroundColor(.appTextMuted)
                        }
                    } else if let translated = result.translatedText {
                        Text(translated)
                            .font(.appBody)
                            .foregroundColor(.appTextPrimary)
                            .lineLimit(3)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Button(action: handleCopy) {
                    ZStack {
                        Image(systemName: showCopied ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 16))
                            .foregroundColor(showCopied ? .appSuccess : .appTextSecondary)
                    }
                    .frame(width: 44, height: 44)
                }
                .disabled(result.translatedText == nil)
            }
            .padding(AppSpacing.xl)
            .background(isSelected ? Color.appPrimary.opacity(0.15) : Color.appSurfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.medium)
                    .stroke(isSelected ? Color.appPrimary : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    private func handleCopy() {
        guard let text = result.translatedText else { return }
        UIPasteboard.general.string = text

        withAnimation(.easeOut(duration: 0.15)) {
            showCopied = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeOut(duration: 0.3)) {
                showCopied = false
            }
        }

        onCopy()
    }
}

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()

        VStack(spacing: AppSpacing.lg) {
            ScanResultCard(
                result: ScanResult(
                    originalText: "Menu du jour",
                    translatedText: "今日菜單",
                    boundingBox: .zero
                ),
                isSelected: false,
                onTap: {},
                onCopy: {}
            )

            ScanResultCard(
                result: ScanResult(
                    originalText: "Soupe à l'oignon",
                    boundingBox: .zero,
                    isTranslating: true
                ),
                isSelected: true,
                onTap: {},
                onCopy: {}
            )
        }
        .padding()
    }
}
```

**Step 2: Commit**

```bash
git add lingo_journey/DesignSystem/Components/ScanResultCard.swift
git commit -m "feat(scanner): add ScanResultCard component"
```

---

## Task 4: 建立文字辨識服務

**Files:**
- Create: `lingo_journey/Core/Services/TextRecognitionService.swift`

**Step 1: 建立 TextRecognitionService**

```swift
import Foundation
import VisionKit
import AVFoundation

@Observable
final class TextRecognitionService: NSObject {
    var isAvailable: Bool = false
    var permissionStatus: AVAuthorizationStatus = .notDetermined

    override init() {
        super.init()
        checkAvailability()
        checkPermission()
    }

    func checkAvailability() {
        isAvailable = DataScannerViewController.isSupported && DataScannerViewController.isAvailable
    }

    func checkPermission() {
        permissionStatus = AVCaptureDevice.authorizationStatus(for: .video)
    }

    func requestPermission() async -> Bool {
        let granted = await AVCaptureDevice.requestAccess(for: .video)
        await MainActor.run {
            checkPermission()
        }
        return granted
    }

    func createDataScanner(
        recognizedLanguages: [String] = [],
        onTextRecognized: @escaping ([RecognizedItem]) -> Void
    ) -> DataScannerViewController? {
        guard isAvailable else { return nil }

        let scanner = DataScannerViewController(
            recognizedDataTypes: [.text()],
            qualityLevel: .balanced,
            recognizesMultipleItems: true,
            isHighFrameRateTrackingEnabled: true,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )

        return scanner
    }
}
```

**Step 2: Commit**

```bash
git add lingo_journey/Core/Services/TextRecognitionService.swift
git commit -m "feat(scanner): add TextRecognitionService"
```

---

## Task 5: 建立 Scanner ViewModel

**Files:**
- Create: `lingo_journey/Features/Scanner/ScannerViewModel.swift`

**Step 1: 建立 ScannerViewModel**

```swift
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
                    var existing = scanResults[existingIndex]
                    existing = ScanResult(
                        id: existing.id,
                        originalText: existing.originalText,
                        translatedText: existing.translatedText,
                        boundingBox: text.bounds,
                        isTranslating: existing.isTranslating
                    )
                    newResults.append(existing)
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
```

**Step 2: Commit**

```bash
git add lingo_journey/Features/Scanner/ScannerViewModel.swift
git commit -m "feat(scanner): add ScannerViewModel with translation logic"
```

---

## Task 6: 建立 DataScanner UIViewControllerRepresentable

**Files:**
- Create: `lingo_journey/Features/Scanner/DataScannerRepresentable.swift`

**Step 1: 建立 DataScannerRepresentable**

```swift
import SwiftUI
import VisionKit

struct DataScannerRepresentable: UIViewControllerRepresentable {
    let onItemsRecognized: ([RecognizedItem]) -> Void
    let onItemTapped: (RecognizedItem) -> Void

    @Binding var isScanning: Bool

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.text()],
            qualityLevel: .balanced,
            recognizesMultipleItems: true,
            isHighFrameRateTrackingEnabled: true,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator
        return scanner
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        if isScanning {
            try? uiViewController.startScanning()
        } else {
            uiViewController.stopScanning()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            onItemsRecognized: onItemsRecognized,
            onItemTapped: onItemTapped
        )
    }

    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let onItemsRecognized: ([RecognizedItem]) -> Void
        let onItemTapped: (RecognizedItem) -> Void

        init(
            onItemsRecognized: @escaping ([RecognizedItem]) -> Void,
            onItemTapped: @escaping (RecognizedItem) -> Void
        ) {
            self.onItemsRecognized = onItemsRecognized
            self.onItemTapped = onItemTapped
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didUpdate updatedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            onItemsRecognized(allItems)
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            onItemsRecognized(allItems)
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didRemove removedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            onItemsRecognized(allItems)
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
            onItemTapped(item)
        }
    }
}
```

**Step 2: Commit**

```bash
git add lingo_journey/Features/Scanner/DataScannerRepresentable.swift
git commit -m "feat(scanner): add DataScannerRepresentable wrapper"
```

---

## Task 7: 建立掃描畫面主視圖

**Files:**
- Create: `lingo_journey/Features/Scanner/ScannerView.swift`

**Step 1: 建立 ScannerView**

```swift
import SwiftUI
import SwiftData
import VisionKit

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
            return "正在啟動相機..."
        case .scanning:
            return "將相機對準文字"
        case .detected(let count):
            return "偵測到 \(count) 段文字"
        case .noText:
            return "未偵測到文字"
        case .error(let message):
            return "錯誤：\(message)"
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
```

**Step 2: Commit**

```bash
git add lingo_journey/Features/Scanner/ScannerView.swift
git commit -m "feat(scanner): add ScannerView main screen"
```

---

## Task 8: 修改 TranslationInputCard 新增相機按鈕

**Files:**
- Modify: `lingo_journey/DesignSystem/Components/TranslationInputCard.swift`

**Step 1: 新增 onCameraTap 參數和相機按鈕**

修改 `TranslationInputCard.swift`，將按鈕改為 HStack 包含相機和麥克風：

```swift
import SwiftUI

struct TranslationInputCard: View {
    let languageName: String
    @Binding var text: String
    var onCameraTap: (() -> Void)?  // 新增
    var onMicTap: () -> Void
    var isListening: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            HStack {
                Text(languageName)
                    .font(.appFootnote)
                    .foregroundColor(.appTextSecondary)

                Spacer()

                HStack(spacing: AppSpacing.md) {
                    // Camera button (新增)
                    if let onCameraTap = onCameraTap {
                        Button(action: onCameraTap) {
                            Image(systemName: "camera.viewfinder")
                                .font(.system(size: 20))
                                .foregroundColor(.appTextSecondary)
                                .frame(width: 44, height: 44)
                        }
                    }

                    // Mic button
                    Button(action: onMicTap) {
                        Image(systemName: isListening ? "mic.fill" : "mic")
                            .font(.system(size: 20))
                            .foregroundColor(isListening ? .appPrimary : .appTextSecondary)
                            .frame(width: 44, height: 44)
                            .background(isListening ? Color.appPrimary.opacity(0.2) : Color.clear)
                            .clipShape(Circle())
                    }
                }
            }

            TextField("Enter your text here...", text: $text, axis: .vertical)
                .font(.appBody)
                .foregroundColor(.appTextPrimary)
                .lineLimit(5...10)
                .textFieldStyle(.plain)
        }
        .padding(AppSpacing.xl)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.large))
    }
}

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        TranslationInputCard(
            languageName: "English",
            text: .constant("Hello, how are you?"),
            onCameraTap: {},
            onMicTap: {},
            isListening: false
        )
        .padding()
    }
}
```

**Step 2: Commit**

```bash
git add lingo_journey/DesignSystem/Components/TranslationInputCard.swift
git commit -m "feat(scanner): add camera button to TranslationInputCard"
```

---

## Task 9: 修改 TranslationView 整合掃描功能

**Files:**
- Modify: `lingo_journey/Features/Translation/TranslationView.swift`

**Step 1: 新增掃描畫面的 sheet 和權限檢查**

```swift
import SwiftData
import SwiftUI
import Translation
import AVFoundation

struct TranslationView: View {
    @State private var sourceLanguage = Locale.Language(identifier: "en")
    @State private var targetLanguage = Locale.Language(identifier: "zh-Hant")
    @State private var sourceText = ""
    @State private var translatedText = ""
    @State private var isTranslating = false
    @State private var configuration: TranslationSession.Configuration?

    // Scanner states (新增)
    @State private var showScanner = false
    @State private var showCameraPermissionAlert = false

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
                        onCameraTap: handleCameraTap,  // 新增
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
    }

    // MARK: - Camera (新增)
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
```

**Step 2: Commit**

```bash
git add lingo_journey/Features/Translation/TranslationView.swift
git commit -m "feat(scanner): integrate scanner into TranslationView"
```

---

## Task 10: 更新 Info.plist 新增相機權限說明

**Files:**
- Modify: `lingo_journey/Info.plist` (如果不存在則建立)

**Step 1: 確認專案已有相機權限說明**

在 Xcode 專案設定或 Info.plist 中新增：

```xml
<key>NSCameraUsageDescription</key>
<string>需要相機權限以掃描並翻譯文字</string>
```

**Step 2: Commit**

```bash
git add lingo_journey/Info.plist
git commit -m "feat(scanner): add camera permission description"
```

---

## Task 11: 建立 Scanner 目錄結構

**Files:**
- Create directory: `lingo_journey/Features/Scanner/`

**Step 1: 確認目錄結構正確**

確保以下檔案都在正確位置：
- `lingo_journey/Features/Scanner/ScannerView.swift`
- `lingo_journey/Features/Scanner/ScannerViewModel.swift`
- `lingo_journey/Features/Scanner/DataScannerRepresentable.swift`

**Step 2: Final commit**

```bash
git add .
git commit -m "feat(scanner): complete scanner translation feature

- Add DataScannerViewController integration for real-time text recognition
- Add draggable bottom panel for translation results
- Add camera button to TranslationInputCard
- Auto-save translations to history on dismiss
- Handle camera permissions with user guidance"
```

---

## 驗證清單

完成所有 Task 後，執行以下驗證：

1. **Build 測試**
   ```bash
   xcodebuild -scheme lingo_journey -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build
   ```

2. **功能驗證**
   - [ ] 翻譯 Tab 顯示相機按鈕
   - [ ] 點擊相機按鈕請求權限
   - [ ] 權限拒絕時顯示引導
   - [ ] 掃描畫面正常開啟
   - [ ] 即時偵測文字並高亮
   - [ ] 翻譯結果顯示在底部面板
   - [ ] 面板可拖曳（三種高度）
   - [ ] 點擊翻譯項可高亮原文
   - [ ] 複製按鈕正常運作
   - [ ] 關閉時翻譯存入歷史

3. **UX 驗證**
   - [ ] 所有按鈕 >= 44x44px
   - [ ] 動畫流暢 (150-300ms)
   - [ ] 載入狀態有 spinner
