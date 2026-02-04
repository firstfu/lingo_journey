# 相機翻譯重寫設計文件

> **日期**: 2026-02-05
> **目標**: 使用 AVFoundation + Vision 重寫相機翻譯功能，達到 Google 相機翻譯等級的 AR 覆蓋效果

## 一、技術選擇

| 項目 | 選擇 | 原因 |
|------|------|------|
| 相機 | AVFoundation | 完整控制每一幀 |
| OCR | Vision Framework | 標準化 normalized 座標 |
| 翻譯 | Apple Translation | 離線、免費、隱私 |
| 背景修補 | 模糊遮罩 | 效果好、效能佳 |
| 透視變形 | Vision 四角點 + CATransform3D | 精確變形 |

## 二、整體架構

```
┌─────────────────────────────────────────────────┐
│                   ScannerView                    │
│  ┌─────────────────────────────────────────────┐│
│  │           CameraPreviewView                 ││
│  │      (AVCaptureVideoPreviewLayer)           ││
│  ├─────────────────────────────────────────────┤│
│  │         TranslationOverlayLayer             ││
│  │  ┌─────────┐ ┌─────────┐ ┌─────────┐       ││
│  │  │模糊遮罩 │ │模糊遮罩 │ │模糊遮罩 │       ││
│  │  │翻譯文字 │ │翻譯文字 │ │翻譯文字 │       ││
│  │  │(透視)   │ │(透視)   │ │(透視)   │       ││
│  │  └─────────┘ └─────────┘ └─────────┘       ││
│  └─────────────────────────────────────────────┤│
│                 TopBar (關閉/語言)              ││
│                 DetailCard (點擊後顯示)         ││
└─────────────────────────────────────────────────┘
```

### 核心組件

- **CameraManager** - 管理 AVCaptureSession，輸出每幀 CMSampleBuffer
- **TextRecognitionEngine** - Vision OCR，辨識文字 + 四角點座標
- **TextTracker** - 追蹤文字，穩定座標避免跳動
- **TranslationEngine** - Apple Translation，批次翻譯 + 快取
- **OverlayRenderer** - 計算透視變形、繪製模糊遮罩 + 翻譯文字

## 三、資料流與處理管線

```
相機幀 (30fps)
    │
    ▼ (每 5 幀處理一次，降低 CPU 負擔)
┌─────────────────────────────┐
│   TextRecognitionEngine     │
│   - VNRecognizeTextRequest  │
│   - 回傳: 文字 + 四角點     │
│   - normalized 座標 (0~1)   │
└─────────────────────────────┘
    │
    ▼ (文字追蹤：比對前後幀，穩定座標)
┌─────────────────────────────┐
│     TextTracker             │
│   - 比對相似文字            │
│   - 平滑座標移動            │
│   - 避免跳動               │
└─────────────────────────────┘
    │
    ▼ (只翻譯新文字，已翻譯的用快取)
┌─────────────────────────────┐
│   TranslationEngine         │
│   - 快取: [原文: 翻譯]      │
│   - 批次翻譯 (session.translations) │
└─────────────────────────────┘
    │
    ▼
┌─────────────────────────────┐
│   OverlayRenderer           │
│   - 座標轉換 (normalized → screen) │
│   - 計算透視矩陣            │
│   - 繪製模糊遮罩 + 翻譯文字 │
└─────────────────────────────┘
```

### 關鍵設計決策

- **每 5 幀辨識一次** - 平衡效能與即時性 (約 6 FPS OCR)
- **TextTracker** - 用文字相似度 + 位置接近度，穩定追蹤同一段文字
- **翻譯快取** - 避免重複翻譯相同文字

## 四、座標轉換

### Vision vs SwiftUI 座標系統

```
Vision (normalized 0~1, 左下原點)     SwiftUI (pixels, 左上原點)

    (0,1)───────(1,1)                 (0,0)───────(w,0)
      │           │                     │           │
      │           │        ──►          │           │
      │           │                     │           │
    (0,0)───────(1,0)                 (0,h)───────(w,h)
```

### 轉換公式

```swift
func convert(_ point: CGPoint, in size: CGSize) -> CGPoint {
    CGPoint(
        x: point.x * size.width,
        y: (1 - point.y) * size.height  // Y 軸翻轉
    )
}
```

## 五、透視變形

### 流程

```
Vision 回傳四角點 (topLeft, topRight, bottomLeft, bottomRight)
    │
    ▼ 轉換為 screen 座標
    │
    ▼ 計算透視矩陣 (CATransform3D)
    │
    ▼ 套用到翻譯文字 View
```

### 透視矩陣計算

使用四角點計算 homography matrix，轉換為 CATransform3D 應用於 UIView/SwiftUI View。

## 六、模糊遮罩 (Inpainting)

### 實作步驟

1. 擷取原文字區域的圖像
2. 套用 CIGaussianBlur (radius: 10-15)
3. 疊加半透明背景色 (white 0.85 opacity)
4. 繪製翻譯文字於上方

### 效果

- 原文字被模糊覆蓋
- 翻譯文字清晰顯示
- 視覺上接近 Google 相機翻譯效果

## 七、檔案結構

### 刪除的檔案

```
Features/Scanner/
├── DataScannerRepresentable.swift  ❌ 刪除 (VisionKit)
├── ScannerView.swift               ❌ 刪除 (重寫)
├── ScannerViewModel.swift          ❌ 刪除 (重寫)
└── TranslationOverlayView.swift    ❌ 刪除 (重寫)
```

### 新建的檔案

```
Features/Scanner/
├── CameraPreviewView.swift         ✚ AVCaptureVideoPreviewLayer 包裝
├── CameraManager.swift             ✚ AVCaptureSession 管理
├── TextRecognitionEngine.swift     ✚ Vision OCR 處理
├── TextTracker.swift               ✚ 文字追蹤與穩定
├── TranslationEngine.swift         ✚ Apple Translation + 快取
├── OverlayRenderer.swift           ✚ 模糊遮罩 + 透視變形
├── ScannerView.swift               ✚ 主視圖 (重寫)
├── ScannerViewModel.swift          ✚ 狀態管理 (重寫)
└── TranslationDetailCard.swift     ✓ 保留
```

### 保留的檔案

```
Features/Scanner/
└── TranslationDetailCard.swift     ✓ 保留 (TTS/複製功能)

Core/Models/
└── ScanResult.swift                ✓ 保留 (需修改以支援四角點)
```

## 八、資料模型

```swift
/// 偵測到的文字區塊
struct DetectedText: Identifiable {
    let id: UUID
    let text: String                    // 原始文字
    var translatedText: String?         // 翻譯結果
    let corners: TextCorners            // 四角點 (用於透視)
    let boundingBox: CGRect             // 邊界框 (screen 座標)
    var isTranslating: Bool
}

/// 四角點座標 (用於透視變形)
struct TextCorners {
    let topLeft: CGPoint
    let topRight: CGPoint
    let bottomLeft: CGPoint
    let bottomRight: CGPoint
}

/// 追蹤中的文字 (用於穩定追蹤)
struct TrackedText {
    let id: UUID
    var text: String
    var corners: TextCorners
    var lastSeenTime: Date
    var smoothedCorners: TextCorners    // 平滑後的座標
}
```

### 狀態管理

```swift
@Observable
final class ScannerViewModel {
    var detectedTexts: [DetectedText] = []
    var selectedTextId: UUID?
    var showDetailCard: Bool = false

    // 內部狀態
    private var translationCache: [String: String] = [:]
    private var trackedTexts: [UUID: TrackedText] = [:]
}
```

## 九、功能清單

- [x] 基礎 AR 覆蓋 - 翻譯文字疊加到原文位置
- [x] 點擊查看詳情 - 顯示詳情卡片 (TTS/複製)
- [x] 文字追蹤 - 避免畫面移動時跳動
- [x] 背景修補 - 模糊遮罩覆蓋原文字
- [x] 透視變形 - 傾斜招牌同步變形翻譯文字
