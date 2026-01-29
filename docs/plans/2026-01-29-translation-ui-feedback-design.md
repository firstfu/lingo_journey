# Translation UI Feedback 設計文檔

**日期**: 2026-01-29
**狀態**: 已確認，待實作

## 概述

針對翻譯頁面三個互動元件的視覺/觸覺反饋改進：
1. 麥克風按鈕 - 新增音量波形動畫
2. 播放按鈕 - 修復 TTS 功能並新增播放狀態指示
3. 複製按鈕 - 新增複製成功反饋

---

## 1. 麥克風音量波形動畫

### 視覺設計
- 在麥克風按鈕下方新增波形視圖，包含 **5 條垂直波形條**
- 波形條使用 `appPrimary` 顏色，圓角末端
- 未錄音時：波形條隱藏或高度為最小值
- 錄音中時：波形條根據 `SpeechService` 的即時音量數據動態變化高度

### 技術實作
- 新增 `AudioWaveformView` 元件到 `DesignSystem/Components/`
- 從 `SpeechService` 取得 `audioLevel` 數據（已有實作）
- 使用 `withAnimation(.easeInOut(duration: 0.1))` 讓波形平滑過渡
- 波形高度範圍：8pt（靜音）~ 32pt（最大音量）

### 觸發邏輯
- `isListening = true` 時顯示波形並開始動畫
- `isListening = false` 時波形淡出隱藏

---

## 2. 播放按鈕（TTS）

### 視覺設計
- 靜止狀態：`speaker.wave.2` 圖示
- 播放中狀態：`speaker.wave.3.fill` 圖示 + 波浪漸變動畫（opacity 循環變化）
- 播放中按鈕可點擊停止

### 技術實作
- 在 `TranslationView` 新增 `AVSpeechSynthesizer` 實例
- 新增 `@State private var isSpeaking = false` 追蹤播放狀態
- 實作 `speakText()` 函數（參考 `ConversationView` 現有實作）
- 實作 `AVSpeechSynthesizerDelegate` 監聽播放完成事件，自動重置 `isSpeaking`
- 將 `onSpeak` 回調從 `{ }` 改為呼叫 `toggleSpeak()`

### 播放邏輯
```
點擊 → 如果未播放 → 開始播放，isSpeaking = true
點擊 → 如果播放中 → 停止播放，isSpeaking = false
播放完成 → 自動重置 isSpeaking = false
```

---

## 3. 複製按鈕反饋

### 視覺設計
- 預設狀態：`doc.on.doc` 圖示
- 複製成功：圖示變為 `checkmark`，顏色變為綠色（`Color.green`）
- 1.5 秒後自動恢復原狀

### 觸覺反饋
- 複製成功時觸發 `UIImpactFeedbackGenerator(style: .light).impactOccurred()`

### 技術實作
- 在 `TranslationView` 新增 `@State private var showCopySuccess = false`
- 修改 `copyToClipboard()` 函數：
  1. 執行複製到剪貼簿
  2. 觸發觸覺反饋
  3. 設定 `showCopySuccess = true`
  4. 1.5 秒後重置 `showCopySuccess = false`
- 在 `TranslationResultCard` 新增 `showCopySuccess` 參數，控制圖示顯示

### 動畫
- 圖示切換使用 `withAnimation(.easeInOut(duration: 0.2))` 平滑過渡

---

## 影響檔案

| 檔案 | 變更 |
|------|------|
| `DesignSystem/Components/AudioWaveformView.swift` | 新增 |
| `DesignSystem/Components/TranslationInputCard.swift` | 整合波形視圖 |
| `DesignSystem/Components/TranslationResultCard.swift` | 新增播放狀態、複製成功參數 |
| `Features/Translation/TranslationView.swift` | 新增 TTS、複製反饋邏輯 |

---

## 驗收標準

- [ ] 麥克風錄音時顯示即時音量波形
- [ ] 播放按鈕可正常播放翻譯結果語音
- [ ] 播放中顯示動態圖示，可點擊停止
- [ ] 複製成功後顯示打勾圖示 + 觸覺反饋
- [ ] 所有動畫流暢，無卡頓
