# 拍照翻譯設計文件

> **日期**: 2026-02-05
> **目標**: 將即時相機翻譯改為拍照後翻譯疊加模式

## 一、核心改變

| 項目 | 舊方式 (即時) | 新方式 (拍照) |
|------|---------------|---------------|
| 觸發時機 | 每幀處理 | 拍照後一次處理 |
| 文字追蹤 | 需要 TextTracker | 不需要 |
| 顯示方式 | 即時疊加到預覽 | 疊加到靜態照片 |
| 用戶操作 | 自動 | 拍照 → 查看 → 保存/分享 |

## 二、整體流程

```
[狀態 1: 預覽模式]
    │
    │ 用戶點擊拍照
    ▼
[狀態 2: 處理中]
    │ 1. 辨識文字 (Vision OCR)
    │ 2. 翻譯文字 (Apple Translation)
    ▼
[狀態 3: 結果顯示]
    │ - 照片 + 翻譯疊加
    │ - 點擊查看詳情
    │ - 保存/分享/重拍
    ▼
[用戶選擇] → 重拍 → 回到狀態 1
           → 保存 → 存到相簿
           → 分享 → 系統分享
           → 關閉 → 離開
```

## 三、技術架構

```
PhotoScannerView (主視圖)
    │
    ├── state == .preview
    │   └── CameraPreviewView + 拍照按鈕
    │
    ├── state == .processing
    │   └── 照片 + 進度指示
    │
    └── state == .result
        └── PhotoResultView (照片 + 翻譯疊加 + 操作按鈕)

PhotoScannerViewModel
    ├── PhotoCameraManager (拍照)
    ├── TextRecognitionEngine (OCR)
    └── TranslationEngine (翻譯)
```

## 四、檔案結構

### 刪除的檔案
- `CameraManager.swift` - 改用簡化版
- `TextTracker.swift` - 不需要追蹤
- `OverlayRenderer.swift` - 改用靜態版
- `ScannerView.swift` - 重寫
- `ScannerViewModel.swift` - 重寫

### 保留的檔案
- `CameraPreviewView.swift` - 複用
- `TextRecognitionEngine.swift` - 複用
- `TranslationEngine.swift` - 複用
- `TranslationDetailCard.swift` - 複用

### 新建的檔案
- `PhotoCameraManager.swift` - 簡化版相機 (拍照功能)
- `PhotoResultView.swift` - 結果顯示 + 翻譯疊加
- `PhotoScannerView.swift` - 主視圖 (狀態機)
- `PhotoScannerViewModel.swift` - 狀態管理

## 五、狀態機

```swift
enum ScannerState {
    case preview                    // 相機預覽
    case processing(ProcessingStep) // 處理中
    case result                     // 顯示結果
}

enum ProcessingStep {
    case recognizing  // "辨識文字中..."
    case translating  // "翻譯中..."
}
```

## 六、功能清單

- [x] 相機預覽
- [x] 拍照功能
- [x] 文字辨識 (Vision OCR)
- [x] 批次翻譯 (Apple Translation)
- [x] 翻譯疊加顯示 (半透明背景)
- [x] 點擊查看詳情 (TTS/複製)
- [x] 保存到相簿
- [x] 分享功能
- [x] 重新拍攝

## 七、UI 設計

### 預覽模式
- 全螢幕相機預覽
- 頂部：關閉按鈕、語言顯示
- 底部：拍照按鈕 (圓形白色)

### 處理中
- 顯示拍攝的照片 (半透明遮罩)
- 中央：進度指示 + 文字說明

### 結果顯示
- 照片 + 翻譯疊加
- 頂部：關閉按鈕
- 底部：重拍、保存、分享按鈕
- 點擊翻譯區塊：顯示詳情卡片
