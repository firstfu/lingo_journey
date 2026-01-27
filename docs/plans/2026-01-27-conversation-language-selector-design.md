# 語音頁面語言選擇器改進設計

## 問題描述

語音頁面（ConversationView）的語言選擇橫條存在以下問題：
1. 語言名稱無法點擊切換語言
2. 中間交換按鈕太小，難以點擊
3. 整體橫條高度太扁

## 解決方案

擴展現有 `LanguageSelector` 元件，添加 `size` 參數支援兩種尺寸。

### 元件架構

為 `LanguageSelector` 添加 size 參數：
- `.regular` — 翻譯頁面使用（現有尺寸）
- `.large` — 語音頁面使用（加大版）

優點：
- 保持程式碼 DRY，不需維護兩個相似元件
- 確保功能完全一致
- 未來調整樣式只需改一處

### 尺寸規格

```swift
enum LanguageSelectorSize {
    case regular  // 翻譯頁面
    case large    // 語音頁面
}
```

| 元素 | `.regular` | `.large` |
|------|-----------|----------|
| 語言文字字體 | `.appHeadline` (17pt) | `.appTitle2` (22pt) |
| 藥丸垂直 padding | `AppSpacing.lg` (12pt) | `AppSpacing.xl` (16pt) |
| 交換按鈕尺寸 | 36×36 | 44×44 |
| 交換按鈕圖示 | 16pt | 20pt |

### 需要修改的檔案

1. **LanguageSelector.swift**
   - 添加 `LanguageSelectorSize` 列舉
   - 修改 `LanguageSelector` 接受 `size` 參數（預設 `.regular`）
   - 修改 `LanguagePill` 根據 size 調整樣式

2. **ConversationView.swift**
   - 添加 `showMyLanguagePicker` 和 `showTheirLanguagePicker` 狀態
   - 將 `ConversationDivider` 替換為 `LanguageSelector(size: .large)`
   - 添加兩個 `LanguagePickerSheet` 的 sheet modifier
   - 移除不再需要的 `ConversationDivider` struct

### 整合程式碼示意

```swift
// ConversationView.swift

@State private var showMyLanguagePicker = false
@State private var showTheirLanguagePicker = false

// 替換 ConversationDivider
LanguageSelector(
    sourceLanguage: $myLanguage,
    targetLanguage: $theirLanguage,
    size: .large,
    onSwap: swapLanguages,
    onSourceTap: { showMyLanguagePicker = true },
    onTargetTap: { showTheirLanguagePicker = true }
)

// 添加 sheet
.sheet(isPresented: $showMyLanguagePicker) {
    LanguagePickerSheet(
        selectedLanguage: myLanguage,
        onSelect: { language in
            myLanguage = language
        }
    )
}
.sheet(isPresented: $showTheirLanguagePicker) {
    LanguagePickerSheet(
        selectedLanguage: theirLanguage,
        onSelect: { language in
            theirLanguage = language
        }
    )
}
```

## 預期結果

- 語音頁面的語言選擇器與翻譯頁面功能一致
- 點擊區域符合 iOS 44pt 最小觸控目標
- 整體視覺更清晰易用
