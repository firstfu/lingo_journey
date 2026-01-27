# 翻譯畫面麥克風功能設計

**日期**：2026-01-27
**狀態**：已核准

## 問題

翻譯畫面（TranslationView）的麥克風按鈕點擊後沒有反應，因為事件處理是空的閉包。

## 設計目標

讓使用者能夠透過語音輸入來源文字，使用裝置端離線語音辨識。

## 功能規格

### 使用者流程

1. 使用者點擊麥克風按鈕
2. 系統請求麥克風/語音辨識權限（首次使用）
3. 按鈕變為填滿狀態（`mic.fill`）+ 主色調
4. 開始錄音並即時辨識
5. 辨識到的文字即時填入輸入框
6. 使用者再次點擊麥克風停止錄音
7. 按鈕恢復原狀

### 錯誤處理

- 權限被拒絕 → 顯示提示，引導至設定
- 辨識失敗 → 顯示錯誤訊息，保留已辨識的文字

### 視覺回饋

- 僅透過按鈕狀態變化提供回饋
- 不顯示波形動畫（保持介面簡潔）

## 技術設計

### 修改檔案

`TranslationView.swift`

### 新增內容

1. **狀態變數**
   ```swift
   @State private var speechService = SpeechService()
   @State private var isListening = false
   ```

2. **handleMicTap() 方法**
   - 切換 `isListening` 狀態
   - 呼叫 `speechService.startListening(language:)` 或 `stopListening()`
   - 使用 `sourceLanguage` 作為辨識語言

3. **監聽辨識結果**
   ```swift
   .onChange(of: speechService.recognizedText) { _, newValue in
       sourceText = newValue
   }
   ```

4. **連接 UI**
   - `onMicTap: handleMicTap`
   - 傳入 `isListening: isListening`

### 不需修改

- `SpeechService.swift` - 已完整實作
- `TranslationInputCard.swift` - 已支援 `isListening` 狀態

### 參考實作

`ConversationView.swift` 第 74-95 行

## 預估變更

- 修改檔案：1 個
- 新增程式碼：約 30-40 行
