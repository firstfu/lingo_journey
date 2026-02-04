# 相機翻譯 AR 疊加設計

> 日期：2026-02-05
> 狀態：待實作

## 目標

將相機翻譯功能從「底部列表」改為「AR 疊加」模式，模仿 Google Translate 相機翻譯的效果。

## 核心改動

| 現狀 | 改為 |
|------|------|
| 翻譯結果顯示在底部拖曳面板 | 翻譯文字直接疊加在相機畫面的原文位置 |
| 需要看面板才知道翻譯內容 | 掃到即看到，沉浸式體驗 |

## AR 疊加視覺規格

### 翻譯文字樣式

- **背景**：半透明毛玻璃（`Color.white.opacity(0.85)` + blur）
- **文字**：黑色，字體大小根據原文邊界框自動調整
- **圓角**：`AppRadius.small`（8pt）
- **內距**：水平 8pt、垂直 4pt

### 位置追蹤

- 利用 VisionKit 回傳的 `boundingBox` 座標
- 翻譯文字疊加在原文的正上方（完全覆蓋）
- 當相機移動，文字跟著即時更新位置

### 狀態顯示

- **識別中**：原文位置顯示小型脈動點（...）
- **翻譯完成**：顯示譯文
- **翻譯失敗**：顯示原文 + 紅色底線

## 互動設計

### 點擊行為

點擊任一 AR 翻譯文字 → 彈出詳細卡片

### 詳細卡片內容

```
┌─────────────────────────────┐
│  原文                    🔊  │  ← 朗讀原文
│  Hello, how are you?        │
├─────────────────────────────┤
│  譯文                    🔊  │  ← 朗讀譯文
│  你好，你好嗎？              │
├─────────────────────────────┤
│      [ 📋 複製譯文 ]         │  ← 複製按鈕
└─────────────────────────────┘
```

### 卡片呈現方式

- 從底部滑入的小型卡片（非全螢幕）
- 點擊卡片外區域或下滑關閉
- 背景相機畫面保持可見（暗化處理）

### 複製反饋

- 按鈕短暫變成 ✓ 已複製
- 輕觸覺回饋（haptic feedback）

## 檔案改動

### 需修改

| 檔案 | 改動內容 |
|------|----------|
| `ScannerView.swift` | 移除 DraggablePanel，加入 AR 疊加層 + 點擊卡片 |
| `ScannerViewModel.swift` | 新增選中狀態管理、卡片顯示邏輯 |
| `DataScannerRepresentable.swift` | 確保 boundingBox 座標正確轉換 |

### 需新增

| 檔案 | 用途 |
|------|------|
| `TranslationOverlayView.swift` | AR 疊加的單個翻譯文字元件 |
| `TranslationDetailCard.swift` | 點擊後顯示的詳細卡片 |

### 可移除

| 檔案 | 原因 |
|------|------|
| `ScanResultCard.swift` | 被新的 `TranslationDetailCard` 取代 |
| `DraggablePanel.swift` | 不再需要底部面板（需確認其他地方是否有使用） |

## 資料流

```
VisionKit 偵測文字
       ↓
回傳 RecognizedItem（含 boundingBox）
       ↓
轉換座標 → 建立 ScanResult
       ↓
畫面上即時顯示 TranslationOverlayView（位置 = boundingBox）
       ↓
觸發 .translationTask() 翻譯
       ↓
更新 ScanResult.translatedText
       ↓
AR 疊加文字從「...」變成譯文
       ↓
用戶點擊 → 顯示 TranslationDetailCard
```

## 技術要點

### 座標轉換

- VisionKit 的 boundingBox 是正規化座標（0~1）
- 需乘以相機預覽的實際尺寸轉成螢幕座標

### 效能考量

- 限制同時顯示的 AR 文字數量（建議最多 10 個）
- 文字太小（boundingBox 面積 < 閾值）不顯示，避免畫面雜亂

### 退場時機

- 文字離開畫面 → AR 疊加消失
- 返回時自動儲存翻譯歷史（保留現有邏輯）
