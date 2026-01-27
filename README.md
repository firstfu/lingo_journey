# Lingo Journey

iOS 翻譯應用程式，支援離線翻譯與語音辨識。

## 功能特色

- **即時翻譯** - 使用 Apple Translation 框架，支援裝置端離線翻譯
- **語音輸入** - 離線語音辨識，支援多種語言
- **位置感知** - 根據所在國家自動建議翻譯語言
- **翻譯歷史** - 儲存翻譯記錄，支援收藏功能
- **Live Activity** - 動態島與鎖定畫面顯示翻譯狀態
- **語言包管理** - 下載離線語言包
- **多語言介面** - 支援繁體中文、簡體中文、英文、日文、韓文等

## 系統需求

- iOS 18.0+
- Xcode 16.0+
- Swift 6.0+

## 技術架構

### 框架使用

| 框架 | 用途 |
|------|------|
| SwiftUI | 使用者介面 |
| SwiftData | 資料持久化（翻譯歷史、語言包） |
| Translation | Apple 裝置端翻譯 |
| Speech | 語音辨識 (STT) |
| AVFoundation | 音訊輸入處理 |
| CoreLocation | 位置服務 |
| MapKit | 反向地理編碼 |
| ActivityKit | Live Activity |
| WidgetKit | Widget 元件 |

### 專案結構

```
lingo_journey/
├── Core/
│   ├── Models/           # SwiftData 資料模型
│   │   ├── TranslationRecord.swift
│   │   └── LanguagePackage.swift
│   └── Services/         # 核心服務
│       ├── TranslationService.swift
│       ├── SpeechService.swift
│       ├── LanguageManager.swift
│       └── Location/     # 位置相關服務
├── Features/
│   ├── Translation/      # 翻譯功能
│   ├── Conversation/     # 對話翻譯
│   ├── History/          # 歷史記錄
│   ├── Settings/         # 設定
│   └── Onboarding/       # 新手引導
├── DesignSystem/         # 設計系統
│   ├── Colors.swift
│   ├── Typography.swift
│   ├── Spacing.swift
│   └── Components/       # 可重用元件
└── LiveActivity/         # Live Activity
```

## 安裝與執行

1. Clone 專案
```bash
git clone <repository-url>
cd lingo_journey
```

2. 使用 Xcode 開啟專案
```bash
open lingo_journey.xcodeproj
```

3. 選擇目標裝置並執行 (Cmd + R)

## 權限說明

應用程式需要以下權限：

| 權限 | 用途 |
|------|------|
| 麥克風 | 語音輸入辨識 |
| 位置 | 根據位置建議翻譯語言 |
| 語音辨識 | 將語音轉換為文字 |

## 離線功能

本應用程式主打離線使用能力：

- **翻譯** - 下載語言包後可完全離線使用
- **語音辨識** - 使用 `requiresOnDeviceRecognition` 強制裝置端辨識
- **位置快取** - 快取最後已知位置，減少 GPS 請求

## 授權

[待補充]
