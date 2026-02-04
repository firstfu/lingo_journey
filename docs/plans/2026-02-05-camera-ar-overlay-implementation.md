# 相機翻譯 AR 疊加實作計畫

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 將相機翻譯從底部面板改為 AR 疊加模式，翻譯文字直接覆蓋在原文位置

**Architecture:** 移除 DraggablePanel，新增 TranslationOverlayView（AR 疊加元件）和 TranslationDetailCard（點擊詳情卡片）。利用 VisionKit 的 boundingBox 座標定位翻譯文字，點擊時彈出詳細卡片。

**Tech Stack:** SwiftUI, VisionKit, Translation, AVFoundation (TTS)

---

## Task 1: 建立 ScanResult 的翻譯失敗狀態

**Files:**
- Modify: `lingo_journey/Core/Models/ScanResult.swift`

**Step 1: 新增 translationFailed 屬性**

編輯 `ScanResult.swift`，新增失敗狀態：

```swift
import Foundation
import CoreGraphics

struct ScanResult: Identifiable, Equatable {
    let id: UUID
    let originalText: String
    var translatedText: String?
    let boundingBox: CGRect
    var isTranslating: Bool
    var translationFailed: Bool

    init(
        id: UUID = UUID(),
        originalText: String,
        translatedText: String? = nil,
        boundingBox: CGRect,
        isTranslating: Bool = false,
        translationFailed: Bool = false
    ) {
        self.id = id
        self.originalText = originalText
        self.translatedText = translatedText
        self.boundingBox = boundingBox
        self.isTranslating = isTranslating
        self.translationFailed = translationFailed
    }
}
```

**Step 2: Build 驗證**

Run: `xcodebuild -project lingo_journey.xcodeproj -scheme lingo_journey -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build 2>&1 | tail -20`

Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add lingo_journey/Core/Models/ScanResult.swift
git commit -m "feat(scanner): add translationFailed state to ScanResult"
```

---

## Task 2: 建立 TranslationOverlayView 元件

**Files:**
- Create: `lingo_journey/Features/Scanner/TranslationOverlayView.swift`

**Step 1: 建立 AR 疊加元件**

建立 `TranslationOverlayView.swift`：

```swift
import SwiftUI

struct TranslationOverlayView: View {
    let result: ScanResult
    let containerSize: CGSize
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            overlayContent
        }
        .buttonStyle(.plain)
        .position(overlayPosition)
    }

    @ViewBuilder
    private var overlayContent: some View {
        if result.isTranslating {
            // 翻譯中：顯示脈動點
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(Color.appTextPrimary)
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(overlayBackground)
        } else if result.translationFailed {
            // 翻譯失敗：顯示原文 + 紅色底線
            Text(result.originalText)
                .font(.system(size: fontSize, weight: .medium))
                .foregroundColor(.appTextPrimary)
                .lineLimit(3)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(overlayBackground)
                .overlay(
                    Rectangle()
                        .fill(Color.red)
                        .frame(height: 2),
                    alignment: .bottom
                )
        } else if let translated = result.translatedText {
            // 翻譯完成：顯示譯文
            Text(translated)
                .font(.system(size: fontSize, weight: .medium))
                .foregroundColor(.appTextPrimary)
                .lineLimit(3)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(overlayBackground)
        }
    }

    private var overlayBackground: some View {
        RoundedRectangle(cornerRadius: AppRadius.small)
            .fill(Color.white.opacity(0.85))
            .background(
                RoundedRectangle(cornerRadius: AppRadius.small)
                    .fill(.ultraThinMaterial)
            )
    }

    private var overlayPosition: CGPoint {
        let box = result.boundingBox
        let x = box.midX * containerSize.width
        let y = box.midY * containerSize.height
        return CGPoint(x: x, y: y)
    }

    private var fontSize: CGFloat {
        let boxHeight = result.boundingBox.height * containerSize.height
        return min(max(boxHeight * 0.6, 12), 24)
    }
}

#Preview {
    ZStack {
        Color.gray
        TranslationOverlayView(
            result: ScanResult(
                originalText: "Hello",
                translatedText: "你好",
                boundingBox: CGRect(x: 0.3, y: 0.3, width: 0.4, height: 0.1)
            ),
            containerSize: CGSize(width: 400, height: 800),
            onTap: {}
        )
    }
}
```

**Step 2: Build 驗證**

Run: `xcodebuild -project lingo_journey.xcodeproj -scheme lingo_journey -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build 2>&1 | tail -20`

Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add lingo_journey/Features/Scanner/TranslationOverlayView.swift
git commit -m "feat(scanner): add TranslationOverlayView for AR text overlay"
```

---

## Task 3: 建立 TranslationDetailCard 元件

**Files:**
- Create: `lingo_journey/Features/Scanner/TranslationDetailCard.swift`

**Step 1: 建立詳情卡片元件**

建立 `TranslationDetailCard.swift`：

```swift
import SwiftUI
import AVFoundation

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
                    label: "原文",
                    text: result.originalText,
                    language: sourceLanguage
                )

                Divider()
                    .background(Color.appBorder)

                // 譯文區塊
                if let translated = result.translatedText {
                    textSection(
                        label: "譯文",
                        text: translated,
                        language: targetLanguage
                    )
                } else if result.translationFailed {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text("翻譯失敗")
                            .font(.appBody)
                            .foregroundColor(.appTextSecondary)
                    }
                }

                Divider()
                    .background(Color.appBorder)

                // 複製按鈕
                Button(action: handleCopy) {
                    HStack(spacing: AppSpacing.md) {
                        Image(systemName: showCopied ? "checkmark" : "doc.on.doc")
                        Text(showCopied ? "已複製" : "複製譯文")
                    }
                    .font(.appHeadline)
                    .foregroundColor(showCopied ? .appSuccess : .appPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.lg)
                    .background(Color.appPrimary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium))
                }
                .disabled(result.translatedText == nil)
            }
            .padding(.horizontal, AppSpacing.xl)
            .padding(.bottom, AppSpacing.xxxl)
        }
        .background(Color.appSurface)
        .clipShape(
            RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
        )
    }

    private func textSection(label: String, text: String, language: Locale.Language) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text(label)
                    .font(.appCaption)
                    .foregroundColor(.appTextSecondary)

                Spacer()

                Button(action: { speak(text: text, language: language) }) {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.appPrimary)
                        .frame(width: 44, height: 44)
                }
            }

            Text(text)
                .font(.appBody)
                .foregroundColor(.appTextPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func handleCopy() {
        guard let text = result.translatedText else { return }
        UIPasteboard.general.string = text

        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        withAnimation(.easeOut(duration: 0.15)) {
            showCopied = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeOut(duration: 0.3)) {
                showCopied = false
            }
        }
    }

    private func speak(text: String, language: Locale.Language) {
        speechSynthesizer.stopSpeaking(at: .immediate)

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language.minimalIdentifier)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate

        speechSynthesizer.speak(utterance)
    }
}

#Preview {
    ZStack {
        Color.black.opacity(0.5).ignoresSafeArea()

        VStack {
            Spacer()
            TranslationDetailCard(
                result: ScanResult(
                    originalText: "Hello, how are you?",
                    translatedText: "你好，你好嗎？",
                    boundingBox: .zero
                ),
                sourceLanguage: Locale.Language(identifier: "en"),
                targetLanguage: Locale.Language(identifier: "zh-Hant"),
                onDismiss: {}
            )
        }
    }
}
```

**Step 2: Build 驗證**

Run: `xcodebuild -project lingo_journey.xcodeproj -scheme lingo_journey -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build 2>&1 | tail -20`

Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add lingo_journey/Features/Scanner/TranslationDetailCard.swift
git commit -m "feat(scanner): add TranslationDetailCard with TTS and copy"
```

---

## Task 4: 更新 ScannerViewModel 支援新互動

**Files:**
- Modify: `lingo_journey/Features/Scanner/ScannerViewModel.swift`

**Step 1: 新增卡片顯示狀態和更新翻譯失敗處理**

編輯 `ScannerViewModel.swift`：

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
    var showDetailCard: Bool = false
    var scannerState: ScannerState = .initializing

    // MARK: - Languages
    var sourceLanguage: Locale.Language
    var targetLanguage: Locale.Language

    // MARK: - Translation
    var translationConfiguration: TranslationSession.Configuration?
    private var pendingTranslations: [UUID: String] = [:]

    // MARK: - Constants
    private let maxOverlayCount = 10
    private let minBoundingBoxArea: CGFloat = 0.001

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

                let boundingBox = CGRect(
                    x: text.bounds.topLeft.x,
                    y: text.bounds.topLeft.y,
                    width: text.bounds.topRight.x - text.bounds.topLeft.x,
                    height: text.bounds.bottomLeft.y - text.bounds.topLeft.y
                )

                // 過濾太小的文字區塊
                let area = boundingBox.width * boundingBox.height
                guard area >= minBoundingBoxArea else { continue }

                if let existingIndex = scanResults.firstIndex(where: { $0.originalText == transcript }) {
                    let existing = scanResults[existingIndex]
                    let updated = ScanResult(
                        id: existing.id,
                        originalText: existing.originalText,
                        translatedText: existing.translatedText,
                        boundingBox: boundingBox,
                        isTranslating: existing.isTranslating,
                        translationFailed: existing.translationFailed
                    )
                    newResults.append(updated)
                } else {
                    let result = ScanResult(
                        originalText: transcript,
                        boundingBox: boundingBox,
                        isTranslating: true
                    )
                    newResults.append(result)
                    pendingTranslations[result.id] = transcript
                }
            }
        }

        // 限制顯示數量
        scanResults = Array(newResults.prefix(maxOverlayCount))

        if newResults.isEmpty {
            scannerState = .noText
        } else {
            scannerState = .detected(count: min(newResults.count, maxOverlayCount))
        }

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
                            isTranslating: false,
                            translationFailed: false
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
                            isTranslating: false,
                            translationFailed: true
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
        selectedResultId = id
        showDetailCard = true
    }

    func dismissDetailCard() {
        showDetailCard = false
        selectedResultId = nil
    }

    func getSelectedResult() -> ScanResult? {
        guard let id = selectedResultId else { return nil }
        return scanResults.first { $0.id == id }
    }
}
```

**Step 2: Build 驗證**

Run: `xcodebuild -project lingo_journey.xcodeproj -scheme lingo_journey -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build 2>&1 | tail -20`

Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add lingo_journey/Features/Scanner/ScannerViewModel.swift
git commit -m "feat(scanner): update ViewModel for AR overlay mode"
```

---

## Task 5: 重構 ScannerView 為 AR 疊加模式

**Files:**
- Modify: `lingo_journey/Features/Scanner/ScannerView.swift`

**Step 1: 移除 DraggablePanel，新增 AR 疊加層和詳情卡片**

完全重寫 `ScannerView.swift`：

```swift
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
```

**Step 2: Build 驗證**

Run: `xcodebuild -project lingo_journey.xcodeproj -scheme lingo_journey -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build 2>&1 | tail -20`

Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add lingo_journey/Features/Scanner/ScannerView.swift
git commit -m "feat(scanner): refactor to AR overlay mode with detail card"
```

---

## Task 6: 更新 ScanResultCard 編譯相容（保留供其他地方使用）

**Files:**
- Modify: `lingo_journey/DesignSystem/Components/ScanResultCard.swift`

**Step 1: 更新 ScanResultCard 支援新的 ScanResult 屬性**

編輯 `ScanResultCard.swift` 的 Preview 區塊：

```swift
#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()

        VStack(spacing: AppSpacing.lg) {
            ScanResultCard(
                result: ScanResult(
                    originalText: "Menu du jour",
                    translatedText: "今日菜單",
                    boundingBox: .zero,
                    translationFailed: false
                ),
                isSelected: false,
                onTap: {},
                onCopy: {}
            )

            ScanResultCard(
                result: ScanResult(
                    originalText: "Soupe à l'oignon",
                    boundingBox: .zero,
                    isTranslating: true,
                    translationFailed: false
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

**Step 2: Build 驗證**

Run: `xcodebuild -project lingo_journey.xcodeproj -scheme lingo_journey -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build 2>&1 | tail -20`

Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add lingo_journey/DesignSystem/Components/ScanResultCard.swift
git commit -m "fix(scanner): update ScanResultCard preview for new ScanResult"
```

---

## Task 7: 整合測試與最終驗證

**Step 1: 完整 Build**

Run: `xcodebuild -project lingo_journey.xcodeproj -scheme lingo_journey -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build 2>&1 | tail -30`

Expected: BUILD SUCCEEDED

**Step 2: 執行測試**

Run: `xcodebuild -project lingo_journey.xcodeproj -scheme lingo_journey -destination 'platform=iOS Simulator,name=iPhone 16 Pro' test 2>&1 | tail -30`

Expected: Tests pass (或無相關測試)

**Step 3: Final Commit**

```bash
git add -A
git commit -m "feat(scanner): complete AR overlay camera translation

- Add TranslationOverlayView for AR text overlay
- Add TranslationDetailCard with TTS and copy
- Remove DraggablePanel from scanner
- Add translationFailed state to ScanResult
- Limit overlay count to 10 for performance"
```

---

## 檔案變更總覽

| 操作 | 檔案 |
|------|------|
| 修改 | `lingo_journey/Core/Models/ScanResult.swift` |
| 新增 | `lingo_journey/Features/Scanner/TranslationOverlayView.swift` |
| 新增 | `lingo_journey/Features/Scanner/TranslationDetailCard.swift` |
| 修改 | `lingo_journey/Features/Scanner/ScannerViewModel.swift` |
| 修改 | `lingo_journey/Features/Scanner/ScannerView.swift` |
| 修改 | `lingo_journey/DesignSystem/Components/ScanResultCard.swift` |

**保留未刪除**：
- `DraggablePanel.swift` - 可能其他地方使用，暫時保留
- `ScanResultCard.swift` - 可能其他地方使用，暫時保留
