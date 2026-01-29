# Lingo Journey

iOS 翻譯應用程式，主打全離線使用能力。

## 功能特色

- **即時翻譯** - 使用 Apple Translation 框架，支援裝置端離線翻譯
- **語音輸入** - 離線語音辨識，支援多種語言
- **相機掃描** - VisionKit OCR 即時辨識並翻譯文字
- **位置感知** - 根據所在國家自動建議翻譯語言
- **翻譯歷史** - SwiftData 儲存翻譯記錄，支援收藏功能
- **語言包管理** - 下載離線語言包，完全離線使用
- **多語言介面** - 支援繁體中文、簡體中文、英文、日文、韓文等 9 種語言

## 系統需求

- iOS 18.0+
- Xcode 16.0+
- Swift 6.0+

## 快速開始

### 安裝

```bash
# Clone 專案
git clone <repository-url>
cd lingo_journey

# 使用 Xcode 開啟
open lingo_journey.xcodeproj
```

### 建置與執行

```bash
# 建置專案
xcodebuild -project lingo_journey.xcodeproj -scheme lingo_journey -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# 執行測試
xcodebuild -project lingo_journey.xcodeproj -scheme lingo_journey -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```

或在 Xcode 中選擇目標裝置後按 `Cmd + R` 執行。

## 技術架構

### 框架使用

| 框架 | 用途 |
|------|------|
| SwiftUI | 使用者介面 |
| SwiftData | 資料持久化（翻譯歷史、語言包） |
| Translation | Apple 裝置端翻譯 |
| Speech | 語音辨識 (STT) |
| VisionKit | OCR 文字辨識 |
| CoreLocation + MapKit | 位置服務與反向地理編碼 |

### 專案結構

```
lingo_journey/
├── Core/
│   ├── Models/           # SwiftData 資料模型
│   └── Services/         # 核心服務（翻譯、語音、位置）
├── Features/             # 功能模組
│   ├── Translation/      # 翻譯功能
│   ├── Scanner/          # 相機掃描
│   ├── Conversation/     # 對話翻譯
│   ├── History/          # 歷史記錄
│   ├── Settings/         # 設定
│   └── Onboarding/       # 新手引導
├── DesignSystem/         # 設計系統（顏色、字型、間距、元件）
└── Resources/            # 資源檔案（本地化字串等）
```

## 權限說明

| 權限 | 用途 |
|------|------|
| 麥克風 | 語音輸入辨識 |
| 相機 | OCR 文字掃描翻譯 |
| 位置 | 根據位置建議翻譯語言 |
| 語音辨識 | 將語音轉換為文字 |

## 離線功能

本應用程式主打離線使用能力：

- **翻譯** - 下載語言包後可完全離線使用
- **語音辨識** - 使用 `requiresOnDeviceRecognition` 強制裝置端辨識
- **位置快取** - 快取最後已知位置，減少 GPS 請求

## 授權

[待補充]
