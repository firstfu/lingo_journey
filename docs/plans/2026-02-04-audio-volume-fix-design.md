# 語音播放音量修復設計

## 問題描述

語音播放（TTS）在所有場景下音量都太小，即使裝置音量已調到最大。

**影響範圍：**
- 翻譯結果播放（TranslationView）
- 對話模式自動朗讀（ConversationView）

## 根本原因

App 沒有設定 `AVAudioSession`，導致：
- 使用預設的音訊類別，音量較低
- 可能受靜音開關影響

## 解決方案

在 App 啟動時統一設定 `AVAudioSession`。

### 設定參數

| 參數 | 值 | 說明 |
|------|-----|------|
| Category | `.playback` | 使用媒體音量通道，音量最大化 |
| Mode | `.default` | 預設模式 |
| Options | `.mixWithOthers` | 不中斷背景音樂 |
| Options | `.duckOthers` | 播放時降低背景音樂音量 |

### 改動範圍

| 檔案 | 改動 |
|------|------|
| `lingo_journeyApp.swift` | 新增 `import AVFoundation` + `init()` + `configureAudioSession()` |

## 實作程式碼

```swift
import AVFoundation

@main
struct lingo_journeyApp: App {
    init() {
        configureAudioSession()
    }

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .default,
                options: [.mixWithOthers, .duckOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }
}
```

## 預期效果

1. 語音播放使用媒體音量（與音樂相同）
2. 即使靜音開關開啟，語音仍會播放
3. 背景音樂播放時，語音播放會自動降低背景音量
