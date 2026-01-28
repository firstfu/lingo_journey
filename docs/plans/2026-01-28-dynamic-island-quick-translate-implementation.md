# 動態島快速翻譯功能實作計劃

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 實現常駐動態島功能，點擊可快速翻譯剪貼簿內容

**Architecture:** 透過 Deep Link 處理動態島點擊事件，讀取剪貼簿並使用 Translation API 翻譯，結果更新回動態島。使用 UserDefaults 持久化設定和語言偏好。

**Tech Stack:** SwiftUI, ActivityKit, Translation Framework, Deep Links (URL Scheme)

---

## Task 1: 更新 TranslationActivityAttributes 支援待機狀態

**Files:**
- Modify: `LingoJourneyWidgetExtension/TranslationActivityAttributes.swift`
- Modify: `lingo_journey/LiveActivity/TranslationActivity.swift` (保持同步)

**Step 1: 修改 Widget Extension 中的 Attributes**

```swift
import ActivityKit
import Foundation

/// Shared attributes for Translation Live Activity
struct TranslationActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var sourceText: String
        var translatedText: String
        var isTranslating: Bool
        var isStandby: Bool  // 新增：待機狀態
        var errorMessage: String?  // 新增：錯誤訊息
    }

    var sourceLanguage: String
    var targetLanguage: String
}
```

**Step 2: 同步更新主 App 中的 Attributes**

將相同的程式碼更新到 `lingo_journey/LiveActivity/TranslationActivity.swift`

**Step 3: 驗證編譯**

Run: `xcodebuild -project lingo_journey.xcodeproj -scheme lingo_journey -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | grep -E "(BUILD|error:)"`
Expected: BUILD SUCCEEDED

**Step 4: Commit**

```bash
git add LingoJourneyWidgetExtension/TranslationActivityAttributes.swift lingo_journey/LiveActivity/TranslationActivity.swift
git commit -m "feat: add standby and error states to TranslationActivityAttributes"
```

---

## Task 2: 更新動態島 UI 支援待機狀態

**Files:**
- Modify: `LingoJourneyWidgetExtension/TranslationLiveActivityWidget.swift`

**Step 1: 添加待機狀態 UI 和點擊 Deep Link**

```swift
import ActivityKit
import SwiftUI
import WidgetKit

struct TranslationLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TranslationActivityAttributes.self) { context in
            // Lock Screen / Banner UI
            LockScreenLiveActivityView(context: context)
                .widgetURL(URL(string: "lingojourney://translate-clipboard"))
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.attributes.sourceLanguage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.attributes.targetLanguage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                DynamicIslandExpandedRegion(.center) {
                    expandedCenterView(context: context)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    if !context.state.isStandby {
                        Text(context.state.sourceText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            } compactLeading: {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .foregroundColor(.blue)
            } compactTrailing: {
                compactTrailingView(context: context)
            } minimal: {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .foregroundColor(.blue)
            }
            .widgetURL(URL(string: "lingojourney://translate-clipboard"))
        }
    }

    @ViewBuilder
    private func expandedCenterView(context: ActivityViewContext<TranslationActivityAttributes>) -> some View {
        VStack(spacing: 4) {
            if context.state.isStandby {
                Text("點擊翻譯剪貼簿")
                    .font(.headline)
                    .foregroundColor(.secondary)
            } else if let error = context.state.errorMessage {
                Text(error)
                    .font(.subheadline)
                    .foregroundColor(.red)
            } else if context.state.isTranslating {
                ProgressView()
                    .scaleEffect(0.8)
            } else {
                Text(context.state.translatedText)
                    .font(.headline)
                    .lineLimit(2)
            }
        }
    }

    @ViewBuilder
    private func compactTrailingView(context: ActivityViewContext<TranslationActivityAttributes>) -> some View {
        if context.state.isStandby {
            Text("點擊翻譯")
                .font(.caption2)
                .foregroundColor(.secondary)
        } else if context.state.errorMessage != nil {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
        } else if context.state.isTranslating {
            ProgressView()
                .scaleEffect(0.6)
        } else {
            Text(context.state.translatedText.prefix(10))
                .font(.caption2)
        }
    }
}

struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<TranslationActivityAttributes>

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(context.attributes.sourceLanguage) → \(context.attributes.targetLanguage)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                if context.state.isStandby {
                    Text("點擊翻譯剪貼簿內容")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else if let error = context.state.errorMessage {
                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(.red)
                } else if context.state.isTranslating {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("翻譯中...")
                    }
                } else {
                    Text(context.state.translatedText)
                        .font(.headline)
                }
            }

            Spacer()

            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.title2)
                .foregroundColor(.blue)
        }
        .padding()
    }
}
```

**Step 2: 驗證編譯**

Run: `xcodebuild -project lingo_journey.xcodeproj -scheme lingo_journey -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | grep -E "(BUILD|error:)"`
Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add LingoJourneyWidgetExtension/TranslationLiveActivityWidget.swift
git commit -m "feat: add standby UI and deep link to Dynamic Island widget"
```

---

## Task 3: 擴展 LiveActivityManager 支援常駐模式

**Files:**
- Modify: `lingo_journey/Core/Services/LiveActivityManager.swift`

**Step 1: 添加常駐模式功能**

```swift
import ActivityKit
import Foundation

@Observable
final class LiveActivityManager {
    static let shared = LiveActivityManager()

    private var currentActivity: Activity<TranslationActivityAttributes>?

    // 常駐模式設定
    @ObservationIgnored
    private let persistentKey = "persistentLiveActivityEnabled"

    @ObservationIgnored
    private let lastSourceLanguageKey = "lastSourceLanguage"

    @ObservationIgnored
    private let lastTargetLanguageKey = "lastTargetLanguage"

    var isActivityActive: Bool {
        currentActivity != nil
    }

    var isPersistentEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: persistentKey) }
        set { UserDefaults.standard.set(newValue, forKey: persistentKey) }
    }

    var lastSourceLanguage: String {
        get { UserDefaults.standard.string(forKey: lastSourceLanguageKey) ?? "en" }
        set { UserDefaults.standard.set(newValue, forKey: lastSourceLanguageKey) }
    }

    var lastTargetLanguage: String {
        get { UserDefaults.standard.string(forKey: lastTargetLanguageKey) ?? "zh-Hant" }
        set { UserDefaults.standard.set(newValue, forKey: lastTargetLanguageKey) }
    }

    private init() {}

    // MARK: - 常駐模式

    /// 啟動常駐模式（待機狀態）
    func startPersistentActivity() {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        guard currentActivity == nil else { return }

        let attributes = TranslationActivityAttributes(
            sourceLanguage: displayName(for: lastSourceLanguage),
            targetLanguage: displayName(for: lastTargetLanguage)
        )

        let standbyState = TranslationActivityAttributes.ContentState(
            sourceText: "",
            translatedText: "",
            isTranslating: false,
            isStandby: true,
            errorMessage: nil
        )

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: standbyState, staleDate: nil),
                pushType: nil
            )
            currentActivity = activity
        } catch {
            print("Failed to start persistent Live Activity: \(error)")
        }
    }

    /// 恢復到待機狀態
    func resetToStandby() async {
        guard let activity = currentActivity else { return }

        let standbyState = TranslationActivityAttributes.ContentState(
            sourceText: "",
            translatedText: "",
            isTranslating: false,
            isStandby: true,
            errorMessage: nil
        )

        await activity.update(ActivityContent(state: standbyState, staleDate: nil))
    }

    /// 顯示錯誤訊息，然後恢復待機
    func showError(_ message: String) async {
        guard let activity = currentActivity else { return }

        let errorState = TranslationActivityAttributes.ContentState(
            sourceText: "",
            translatedText: "",
            isTranslating: false,
            isStandby: false,
            errorMessage: message
        )

        await activity.update(ActivityContent(state: errorState, staleDate: nil))

        // 2 秒後恢復待機
        try? await Task.sleep(for: .seconds(2))
        await resetToStandby()
    }

    /// 更新為翻譯中狀態
    func setTranslating(sourceText: String) async {
        guard let activity = currentActivity else { return }

        let translatingState = TranslationActivityAttributes.ContentState(
            sourceText: sourceText,
            translatedText: "",
            isTranslating: true,
            isStandby: false,
            errorMessage: nil
        )

        await activity.update(ActivityContent(state: translatingState, staleDate: nil))
    }

    /// 更新翻譯結果，然後恢復待機
    func showResultThenStandby(sourceText: String, translatedText: String) async {
        guard let activity = currentActivity else { return }

        let resultState = TranslationActivityAttributes.ContentState(
            sourceText: sourceText,
            translatedText: translatedText,
            isTranslating: false,
            isStandby: false,
            errorMessage: nil
        )

        await activity.update(ActivityContent(state: resultState, staleDate: nil))

        // 5 秒後恢復待機
        try? await Task.sleep(for: .seconds(5))

        // 只有在常駐模式下才恢復待機
        if isPersistentEnabled {
            await resetToStandby()
        } else {
            await endActivity()
        }
    }

    private func displayName(for languageCode: String) -> String {
        let locale = Locale(identifier: languageCode)
        return locale.localizedString(forIdentifier: languageCode)?.capitalized ?? languageCode
    }

    // MARK: - 原有功能（保留相容性）

    /// Start a new Live Activity for translation
    func startActivity(
        sourceLanguage: String,
        targetLanguage: String,
        sourceText: String
    ) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            return
        }

        // End any existing activity first
        Task {
            await endActivity()
        }

        let attributes = TranslationActivityAttributes(
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage
        )

        let initialState = TranslationActivityAttributes.ContentState(
            sourceText: sourceText,
            translatedText: "",
            isTranslating: true,
            isStandby: false,
            errorMessage: nil
        )

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil),
                pushType: nil
            )
            currentActivity = activity
        } catch {
            print("Failed to start Live Activity: \(error)")
        }
    }

    /// Update the Live Activity with translation result
    func updateActivity(translatedText: String, sourceText: String) async {
        guard let activity = currentActivity else { return }

        let updatedState = TranslationActivityAttributes.ContentState(
            sourceText: sourceText,
            translatedText: translatedText,
            isTranslating: false,
            isStandby: false,
            errorMessage: nil
        )

        await activity.update(
            ActivityContent(state: updatedState, staleDate: nil)
        )
    }

    /// End the current Live Activity
    func endActivity() async {
        guard let activity = currentActivity else { return }

        let finalState = TranslationActivityAttributes.ContentState(
            sourceText: "",
            translatedText: "",
            isTranslating: false,
            isStandby: false,
            errorMessage: nil
        )

        await activity.end(
            ActivityContent(state: finalState, staleDate: nil),
            dismissalPolicy: .immediate
        )

        currentActivity = nil
    }

    /// End activity after a delay (useful for showing result briefly)
    func endActivityAfterDelay(seconds: TimeInterval = 5.0) {
        Task {
            try? await Task.sleep(for: .seconds(seconds))

            // 如果是常駐模式，恢復待機而不是結束
            if isPersistentEnabled {
                await resetToStandby()
            } else {
                await endActivity()
            }
        }
    }
}
```

**Step 2: 驗證編譯**

Run: `xcodebuild -project lingo_journey.xcodeproj -scheme lingo_journey -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | grep -E "(BUILD|error:)"`
Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add lingo_journey/Core/Services/LiveActivityManager.swift
git commit -m "feat: add persistent mode and standby state management to LiveActivityManager"
```

---

## Task 4: 創建剪貼簿翻譯服務

**Files:**
- Create: `lingo_journey/Core/Services/ClipboardTranslationService.swift`

**Step 1: 創建剪貼簿翻譯服務**

```swift
import Foundation
import Translation
import UIKit

@Observable
final class ClipboardTranslationService {
    static let shared = ClipboardTranslationService()

    private let liveActivityManager = LiveActivityManager.shared
    private let maxTextLength = 500

    private init() {}

    /// 翻譯剪貼簿內容
    func translateClipboard() async {
        // 1. 讀取剪貼簿
        guard let clipboardText = UIPasteboard.general.string else {
            await liveActivityManager.showError("剪貼簿無內容")
            return
        }

        let trimmedText = clipboardText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedText.isEmpty else {
            await liveActivityManager.showError("剪貼簿無內容")
            return
        }

        // 2. 截取過長文字
        let textToTranslate: String
        let isTruncated: Bool
        if trimmedText.count > maxTextLength {
            textToTranslate = String(trimmedText.prefix(maxTextLength))
            isTruncated = true
        } else {
            textToTranslate = trimmedText
            isTruncated = false
        }

        // 3. 更新為翻譯中狀態
        await liveActivityManager.setTranslating(sourceText: textToTranslate)

        // 4. 執行翻譯
        do {
            let sourceLanguage = Locale.Language(identifier: liveActivityManager.lastSourceLanguage)
            let targetLanguage = Locale.Language(identifier: liveActivityManager.lastTargetLanguage)

            let configuration = TranslationSession.Configuration(
                source: sourceLanguage,
                target: targetLanguage
            )

            let session = try await TranslationSession(configuration: configuration)
            let response = try await session.translate(textToTranslate)

            var resultText = response.targetText
            if isTruncated {
                resultText += "..."
            }

            // 5. 顯示結果
            await liveActivityManager.showResultThenStandby(
                sourceText: textToTranslate,
                translatedText: resultText
            )

        } catch {
            await liveActivityManager.showError("翻譯失敗")
        }
    }
}
```

**Step 2: 驗證編譯**

Run: `xcodebuild -project lingo_journey.xcodeproj -scheme lingo_journey -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | grep -E "(BUILD|error:)"`
Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add lingo_journey/Core/Services/ClipboardTranslationService.swift
git commit -m "feat: add ClipboardTranslationService for quick translation"
```

---

## Task 5: 添加 URL Scheme 和 Deep Link 處理

**Files:**
- Modify: `lingo_journey/lingo_journeyApp.swift`

**Step 1: 添加 URL 處理**

```swift
//
//  lingo_journeyApp.swift
//  lingo_journey
//
//  Created by firstfu on 2026/1/27.
//

import SwiftUI
import SwiftData

@main
struct lingo_journeyApp: App {
    @State private var languageManager = LanguageManager.shared
    private let liveActivityManager = LiveActivityManager.shared
    private let clipboardService = ClipboardTranslationService.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.locale, languageManager.currentLocale)
                .environment(languageManager)
                .onOpenURL { url in
                    handleDeepLink(url)
                }
                .task {
                    // App 啟動時，如果常駐模式開啟，恢復動態島
                    if liveActivityManager.isPersistentEnabled {
                        liveActivityManager.startPersistentActivity()
                    }
                }
        }
        .modelContainer(for: [
            TranslationRecord.self,
            LanguagePackage.self
        ])
    }

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "lingojourney" else { return }

        switch url.host {
        case "translate-clipboard":
            Task {
                await clipboardService.translateClipboard()
            }
        default:
            break
        }
    }
}
```

**Step 2: 在 Info.plist 中註冊 URL Scheme**

需要在 Xcode 的 target 設定中添加 URL Types，或直接編輯 build settings：

在 project.pbxproj 的 lingo_journey target build settings 中添加：
```
INFOPLIST_KEY_CFBundleURLTypes = "(
    {
        CFBundleURLName = \"com.firstfu.com.lingo-journey\";
        CFBundleURLSchemes = (lingojourney);
    }
)";
```

**Step 3: 驗證編譯**

Run: `xcodebuild -project lingo_journey.xcodeproj -scheme lingo_journey -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | grep -E "(BUILD|error:)"`
Expected: BUILD SUCCEEDED

**Step 4: Commit**

```bash
git add lingo_journey/lingo_journeyApp.swift
git commit -m "feat: add deep link handling for clipboard translation"
```

---

## Task 6: 在設定頁面添加常駐動態島開關

**Files:**
- Modify: `lingo_journey/Features/Settings/SettingsView.swift`

**Step 1: 添加快速翻譯設定區塊**

在 `SettingsView` 的 body 中，在第一個 `SettingsSection` 之前添加：

```swift
// 在 VStack(spacing: AppSpacing.xxl) 內，Text("settings.title") 之後添加：

SettingsSection(title: String(localized: "settings.quickTranslate")) {
    QuickTranslateToggleRow()
}
```

**Step 2: 創建 QuickTranslateToggleRow 組件**

在 `SettingsView.swift` 文件末尾（`#Preview` 之前）添加：

```swift
struct QuickTranslateToggleRow: View {
    private let liveActivityManager = LiveActivityManager.shared
    @State private var isEnabled: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: AppSpacing.lg) {
                Image(systemName: "sparkles.rectangle.stack")
                    .font(.system(size: 20))
                    .foregroundColor(.appPrimary)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("settings.persistentDynamicIsland")
                        .font(.appBody)
                        .foregroundColor(.appTextPrimary)

                    Text("settings.persistentDynamicIsland.subtitle")
                        .font(.appFootnote)
                        .foregroundColor(.appTextMuted)
                }

                Spacer()

                Toggle("", isOn: $isEnabled)
                    .tint(.appPrimary)
            }
            .padding(AppSpacing.xl)

            // 提示文字
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.yellow)

                Text("settings.persistentDynamicIsland.hint")
                    .font(.appFootnote)
                    .foregroundColor(.appTextMuted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, AppSpacing.xl)
            .padding(.bottom, AppSpacing.lg)
        }
        .onAppear {
            isEnabled = liveActivityManager.isPersistentEnabled
        }
        .onChange(of: isEnabled) { _, newValue in
            liveActivityManager.isPersistentEnabled = newValue
            if newValue {
                liveActivityManager.startPersistentActivity()
            } else {
                Task {
                    await liveActivityManager.endActivity()
                }
            }
        }
    }
}
```

**Step 3: 添加本地化字串**

需要在 `Resources/Localizable.xcstrings` 中添加：
- `settings.quickTranslate` = "快速翻譯"
- `settings.persistentDynamicIsland` = "常駐動態島"
- `settings.persistentDynamicIsland.subtitle` = "在動態島顯示翻譯快捷鍵"
- `settings.persistentDynamicIsland.hint` = "開啟後，點擊動態島可快速翻譯剪貼簿中的文字"

**Step 4: 驗證編譯**

Run: `xcodebuild -project lingo_journey.xcodeproj -scheme lingo_journey -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | grep -E "(BUILD|error:)"`
Expected: BUILD SUCCEEDED

**Step 5: Commit**

```bash
git add lingo_journey/Features/Settings/SettingsView.swift
git commit -m "feat: add persistent Dynamic Island toggle in settings"
```

---

## Task 7: 保存翻譯語言設定

**Files:**
- Modify: `lingo_journey/Features/Translation/TranslationView.swift`

**Step 1: 在翻譯時保存語言設定**

在 `TranslationView` 的 `startTranslation()` 方法中，添加保存語言設定的邏輯：

```swift
private func startTranslation() {
    // 保存語言設定供快速翻譯使用
    liveActivityManager.lastSourceLanguage = sourceLanguage.minimalIdentifier
    liveActivityManager.lastTargetLanguage = targetLanguage.minimalIdentifier

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
```

**Step 2: 驗證編譯**

Run: `xcodebuild -project lingo_journey.xcodeproj -scheme lingo_journey -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | grep -E "(BUILD|error:)"`
Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add lingo_journey/Features/Translation/TranslationView.swift
git commit -m "feat: save language settings for quick translation feature"
```

---

## Task 8: 添加 URL Scheme 到專案配置

**Files:**
- Modify: `lingo_journey.xcodeproj/project.pbxproj`

**Step 1: 在 build settings 中添加 URL Types**

在 lingo_journey target 的 Debug 和 Release build settings 中添加：

```
INFOPLIST_KEY_CFBundleURLTypes = "({CFBundleURLName = \"com.firstfu.com.lingo-journey\"; CFBundleURLSchemes = (lingojourney); })";
```

**Step 2: 驗證編譯**

Run: `xcodebuild -project lingo_journey.xcodeproj -scheme lingo_journey -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | grep -E "(BUILD|error:)"`
Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add lingo_journey.xcodeproj/project.pbxproj
git commit -m "feat: register lingojourney URL scheme"
```

---

## Task 9: 添加本地化字串

**Files:**
- Modify: `lingo_journey/Resources/Localizable.xcstrings`

**Step 1: 添加設定頁面的本地化字串**

在 xcstrings 文件中添加以下鍵值（需要為各語言添加翻譯）：

- `settings.quickTranslate`
- `settings.persistentDynamicIsland`
- `settings.persistentDynamicIsland.subtitle`
- `settings.persistentDynamicIsland.hint`

**Step 2: Commit**

```bash
git add lingo_journey/Resources/Localizable.xcstrings
git commit -m "feat: add localization strings for quick translate settings"
```

---

## Task 10: 完整測試

**測試流程：**

1. 開啟 App → 設定 → 開啟「常駐動態島」
2. 確認動態島顯示待機狀態
3. 複製任意文字
4. 點擊動態島
5. 確認顯示翻譯中 → 翻譯結果 → 恢復待機
6. 測試錯誤情況（清空剪貼簿後點擊）
7. 關閉開關，確認動態島消失
8. 重啟 App，確認開關狀態恢復

**Final Commit**

```bash
git add -A
git commit -m "feat: complete Dynamic Island quick translate feature"
```
