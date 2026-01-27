# 語言切換功能實作計劃

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 讓用戶點擊語言按鈕時，能從可用語言清單中選擇來源語言和目標語言。

**Architecture:** 新增 `LanguagePickerSheet` 元件作為語言選擇介面，修改 `LanguageSelector` 加入點擊回調，在 `TranslationView` 中管理 Sheet 狀態和語言下載邏輯。

**Tech Stack:** SwiftUI, Apple Translation Framework (`LanguageAvailability`)

---

## Task 1: 建立 LanguagePickerSheet 元件

**Files:**
- Create: `lingo_journey/DesignSystem/Components/LanguagePickerSheet.swift`

**Step 1: 建立基本結構**

```swift
import SwiftUI
import Translation

struct LanguagePickerSheet: View {
    let title: String
    let currentLanguage: Locale.Language
    let onSelect: (Locale.Language, Bool) -> Void  // (language, isDownloaded)

    @Environment(\.dismiss) private var dismiss
    @State private var supportedLanguages: [Locale.Language] = []
    @State private var downloadedLanguages: Set<String> = []
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                if isLoading {
                    ProgressView()
                        .tint(.appPrimary)
                } else {
                    languageList
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.appTextMuted)
                    }
                }
            }
        }
        .task {
            await loadLanguages()
        }
    }

    private var downloadedLanguagesList: [Locale.Language] {
        supportedLanguages.filter { downloadedLanguages.contains($0.minimalIdentifier) }
    }

    private var availableLanguagesList: [Locale.Language] {
        supportedLanguages.filter { !downloadedLanguages.contains($0.minimalIdentifier) }
    }

    private var languageList: some View {
        List {
            if !downloadedLanguagesList.isEmpty {
                Section {
                    ForEach(downloadedLanguagesList, id: \.minimalIdentifier) { language in
                        LanguageRow(
                            language: language,
                            isSelected: language.minimalIdentifier == currentLanguage.minimalIdentifier,
                            isDownloaded: true
                        ) {
                            onSelect(language, true)
                            dismiss()
                        }
                    }
                } header: {
                    Text("已下載")
                        .font(.appCaption)
                        .foregroundColor(.appTextMuted)
                }
                .listRowBackground(Color.appSurface)
            }

            if !availableLanguagesList.isEmpty {
                Section {
                    ForEach(availableLanguagesList, id: \.minimalIdentifier) { language in
                        LanguageRow(
                            language: language,
                            isSelected: language.minimalIdentifier == currentLanguage.minimalIdentifier,
                            isDownloaded: false
                        ) {
                            onSelect(language, false)
                            dismiss()
                        }
                    }
                } header: {
                    Text("可下載")
                        .font(.appCaption)
                        .foregroundColor(.appTextMuted)
                }
                .listRowBackground(Color.appSurface)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }

    private func loadLanguages() async {
        let availability = LanguageAvailability()
        supportedLanguages = await availability.supportedLanguages

        for language in supportedLanguages {
            let status = await availability.status(
                from: language,
                to: Locale.Language(identifier: "en")
            )
            if status == .installed {
                downloadedLanguages.insert(language.minimalIdentifier)
            }
        }

        isLoading = false
    }
}

private struct LanguageRow: View {
    let language: Locale.Language
    let isSelected: Bool
    let isDownloaded: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(displayName(for: language))
                        .font(.appBody)
                        .foregroundColor(.appTextPrimary)

                    Text(language.minimalIdentifier)
                        .font(.appCaption)
                        .foregroundColor(.appTextMuted)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.appPrimary)
                        .fontWeight(.semibold)
                } else if !isDownloaded {
                    Image(systemName: "arrow.down.circle")
                        .foregroundColor(.appTextMuted)
                }
            }
            .padding(.vertical, AppSpacing.sm)
        }
    }

    private func displayName(for language: Locale.Language) -> String {
        let locale = Locale(identifier: language.minimalIdentifier)
        return locale.localizedString(forIdentifier: language.minimalIdentifier)?.capitalized ?? language.minimalIdentifier
    }
}

#Preview {
    LanguagePickerSheet(
        title: "選擇來源語言",
        currentLanguage: Locale.Language(identifier: "en"),
        onSelect: { _, _ in }
    )
}
```

**Step 2: 驗證編譯**

Run: `xcodebuild -project lingo_journey.xcodeproj -scheme lingo_journey -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build`
Expected: BUILD SUCCEEDED

---

## Task 2: 修改 LanguageSelector 加入點擊回調

**Files:**
- Modify: `lingo_journey/DesignSystem/Components/LanguageSelector.swift`

**Step 1: 更新 LanguageSelector**

將 `LanguageSelector` 修改為：

```swift
import SwiftUI

struct LanguageSelector: View {
    @Binding var sourceLanguage: Locale.Language
    @Binding var targetLanguage: Locale.Language
    var onSwap: () -> Void
    var onSourceTap: () -> Void
    var onTargetTap: () -> Void

    var body: some View {
        HStack(spacing: AppSpacing.lg) {
            LanguagePill(
                language: sourceLanguage,
                action: onSourceTap
            )

            Button(action: onSwap) {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.appPrimary)
                    .frame(width: 36, height: 36)
                    .background(Color.appSurface)
                    .clipShape(Circle())
            }

            LanguagePill(
                language: targetLanguage,
                action: onTargetTap
            )
        }
        .padding(.horizontal, AppSpacing.xl)
    }
}

struct LanguagePill: View {
    let language: Locale.Language
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(displayName(for: language))
                .font(.appHeadline)
                .foregroundColor(.appTextPrimary)
                .padding(.horizontal, AppSpacing.xl)
                .padding(.vertical, AppSpacing.lg)
                .background(Color.appSurface)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.appBorder, lineWidth: 1)
                )
        }
    }

    private func displayName(for language: Locale.Language) -> String {
        let locale = Locale(identifier: language.minimalIdentifier)
        return locale.localizedString(forIdentifier: language.minimalIdentifier)?.capitalized ?? language.minimalIdentifier
    }
}

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        LanguageSelector(
            sourceLanguage: .constant(Locale.Language(identifier: "en")),
            targetLanguage: .constant(Locale.Language(identifier: "zh-Hant")),
            onSwap: {},
            onSourceTap: {},
            onTargetTap: {}
        )
    }
}
```

**Step 2: 驗證編譯**

Run: `xcodebuild -project lingo_journey.xcodeproj -scheme lingo_journey -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build`
Expected: 編譯失敗，因為 TranslationView 還沒更新

---

## Task 3: 建立 LanguageDownloadAlert 元件

**Files:**
- Create: `lingo_journey/DesignSystem/Components/LanguageDownloadAlert.swift`

**Step 1: 建立確認對話框元件**

```swift
import SwiftUI

struct LanguageDownloadAlert: ViewModifier {
    @Binding var isPresented: Bool
    let languageName: String
    let onDownload: () -> Void
    let onUseTemporarily: () -> Void

    func body(content: Content) -> some View {
        content
            .alert("「\(languageName)」尚未下載", isPresented: $isPresented) {
                Button("下載語言包", action: onDownload)
                Button("暫時使用（需網路）", role: .cancel, action: onUseTemporarily)
            } message: {
                Text("下載後可離線使用")
            }
    }
}

extension View {
    func languageDownloadAlert(
        isPresented: Binding<Bool>,
        languageName: String,
        onDownload: @escaping () -> Void,
        onUseTemporarily: @escaping () -> Void
    ) -> some View {
        modifier(LanguageDownloadAlert(
            isPresented: isPresented,
            languageName: languageName,
            onDownload: onDownload,
            onUseTemporarily: onUseTemporarily
        ))
    }
}
```

**Step 2: 驗證編譯**

Run: `xcodebuild -project lingo_journey.xcodeproj -scheme lingo_journey -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build`
Expected: BUILD SUCCEEDED（此檔案獨立，不影響其他）

---

## Task 4: 更新 TranslationView 整合語言選擇

**Files:**
- Modify: `lingo_journey/Features/Translation/TranslationView.swift`

**Step 1: 加入 Sheet 狀態和處理邏輯**

在 `TranslationView` 中加入以下狀態變數（在現有 `@State` 區塊後面）：

```swift
// Language picker states
@State private var showSourceLanguagePicker = false
@State private var showTargetLanguagePicker = false
@State private var showDownloadAlert = false
@State private var pendingLanguage: Locale.Language?
@State private var pendingLanguageIsSource = true
```

**Step 2: 更新 LanguageSelector 呼叫**

將 `LanguageSelector` 呼叫改為：

```swift
LanguageSelector(
    sourceLanguage: $sourceLanguage,
    targetLanguage: $targetLanguage,
    onSwap: swapLanguages,
    onSourceTap: { showSourceLanguagePicker = true },
    onTargetTap: { showTargetLanguagePicker = true }
)
```

**Step 3: 加入 Sheet 和 Alert**

在 `.alert("需要相機權限"...)` 後面加入：

```swift
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
```

**Step 4: 加入處理函數**

在 `handleCameraTap()` 函數後面加入：

```swift
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
```

**Step 5: 驗證編譯**

Run: `xcodebuild -project lingo_journey.xcodeproj -scheme lingo_journey -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build`
Expected: BUILD SUCCEEDED

---

## Task 5: 加入本地化字串

**Files:**
- Modify: `lingo_journey/Resources/Localizable.xcstrings`

**Step 1: 加入語言選擇相關字串**

需要加入的 key：
- `language.picker.source` = "選擇來源語言"
- `language.picker.target` = "選擇目標語言"

（此步驟需要在 Xcode 中編輯 String Catalog）

---

## Task 6: 驗證完整功能

**Step 1: 執行應用程式**

Run: `xcodebuild -project lingo_journey.xcodeproj -scheme lingo_journey -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build`

**Step 2: 測試流程**

1. 啟動應用程式
2. 點擊「English」按鈕 → 應彈出語言選擇 Sheet
3. 選擇已下載的語言 → 應直接切換
4. 選擇未下載的語言 → 應彈出下載確認框
5. 點擊「暫時使用」→ 應切換語言
6. 點擊目標語言按鈕 → 應彈出另一個 Sheet

---

## 檔案清單摘要

| 操作 | 檔案路徑 |
|------|----------|
| 新增 | `lingo_journey/DesignSystem/Components/LanguagePickerSheet.swift` |
| 新增 | `lingo_journey/DesignSystem/Components/LanguageDownloadAlert.swift` |
| 修改 | `lingo_journey/DesignSystem/Components/LanguageSelector.swift` |
| 修改 | `lingo_journey/Features/Translation/TranslationView.swift` |
| 修改 | `lingo_journey/Resources/Localizable.xcstrings` |
