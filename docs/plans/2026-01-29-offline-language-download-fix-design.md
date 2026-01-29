# 離線語言下載修復設計

## 問題描述

用戶在「離線語言」頁面點擊下載按鈕後：
1. 顯示載入中狀態（旋轉圖示）
2. 載入結束後沒有顯示打勾
3. 系統設定中也沒有實際下載到該語言包

## 根因分析

`LanguagePickerSheet.startDownload()` 函數的實作問題：

```swift
// 目前的實作（錯誤）
private func startDownload(_ language: Locale.Language) {
    downloadingLanguages.insert(identifier)
    Task {
        try? await Task.sleep(for: .seconds(2))  // 只是等待
        let status = await availability.status(...)  // 只是查詢
        // 沒有觸發任何實際下載動作
    }
}
```

`LanguageAvailability` API 只能**查詢**語言包狀態，**無法觸發下載**。

## 解決方案

使用 `.translationTask(configuration)` modifier 觸發系統原生下載流程。這是 Apple Translation 框架設計的預期使用方式。

## 修改範圍

僅修改 `LanguagePickerSheet.swift` 一個檔案。

### 新增 State 變數

```swift
@State private var downloadConfiguration: TranslationSession.Configuration?
@State private var pendingDownloadLanguage: Locale.Language?
```

### 修改 startDownload 函數

```swift
private func startDownload(_ language: Locale.Language) {
    let identifier = language.minimalIdentifier
    guard !downloadingLanguages.contains(identifier) else { return }

    downloadingLanguages.insert(identifier)
    pendingDownloadLanguage = language

    // 觸發 translationTask，系統會自動提示下載
    downloadConfiguration = TranslationSession.Configuration(
        source: language,
        target: Locale.Language(identifier: "en")
    )
}
```

### 新增 translationTask modifier

在 View body 中新增：

```swift
.translationTask(downloadConfiguration) { session in
    await handleDownloadSession(session: session)
}
```

### 新增下載處理函數

```swift
private func handleDownloadSession(session: TranslationSession) async {
    guard let language = pendingDownloadLanguage else { return }
    let identifier = language.minimalIdentifier

    do {
        // 嘗試翻譯一個簡單單字來觸發下載流程
        _ = try await session.translate("hello")
    } catch {
        // 下載被取消或失敗，忽略錯誤
    }

    // 無論成功或失敗，重新檢查語言狀態
    let availability = LanguageAvailability()
    let status = await availability.status(
        from: language,
        to: Locale.Language(identifier: "en")
    )

    await MainActor.run {
        downloadingLanguages.remove(identifier)
        downloadConfiguration = nil
        pendingDownloadLanguage = nil

        if status == .installed {
            downloadedLanguages.insert(identifier)
        }
    }
}
```

## 預期行為

1. 用戶點擊下載按鈕 → 顯示載入中圖示
2. 系統彈出原生下載對話框
3. 用戶確認下載 → 系統下載語言包
4. 下載完成 → 語言移到「已下載」區並顯示打勾
5. 系統設定中也會出現該語言

## 不需要修改的部分

- `loadLanguages()` - 初始載入邏輯保持不變
- `LanguagePickerRow` - UI 組件保持不變
- 其他使用此組件的頁面 - 無需修改
