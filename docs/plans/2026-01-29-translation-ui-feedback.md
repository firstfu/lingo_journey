# Translation UI Feedback Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 為翻譯頁面的麥克風、播放、複製按鈕添加視覺和觸覺反饋

**Architecture:** 新增 AudioWaveformView 組件顯示音量波形，修改 TranslationResultCard 支援播放狀態和複製反饋，在 TranslationView 整合 AVSpeechSynthesizer 和觸覺反饋

**Tech Stack:** SwiftUI, AVFoundation (AVSpeechSynthesizer), UIKit (UIImpactFeedbackGenerator)

---

## Task 1: 創建 AudioWaveformView 組件

**Files:**
- Create: `lingo_journey/DesignSystem/Components/AudioWaveformView.swift`

**Step 1: 創建波形視圖組件**

```swift
import SwiftUI

struct AudioWaveformView: View {
    let audioLevel: Float
    let barCount: Int = 5

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<barCount, id: \.self) { index in
                WaveformBar(
                    height: barHeight(for: index),
                    isActive: audioLevel > 0
                )
            }
        }
        .frame(height: 32)
    }

    private func barHeight(for index: Int) -> CGFloat {
        let baseHeight: CGFloat = 8
        let maxHeight: CGFloat = 32
        let variation = sin(Double(index) * 0.8) * 0.3 + 0.7
        let level = CGFloat(audioLevel) * variation
        return baseHeight + (maxHeight - baseHeight) * level
    }
}

private struct WaveformBar: View {
    let height: CGFloat
    let isActive: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(Color.appPrimary)
            .frame(width: 4, height: height)
            .animation(.easeInOut(duration: 0.1), value: height)
    }
}

#Preview {
    VStack(spacing: 20) {
        AudioWaveformView(audioLevel: 0.0)
        AudioWaveformView(audioLevel: 0.3)
        AudioWaveformView(audioLevel: 0.7)
        AudioWaveformView(audioLevel: 1.0)
    }
    .padding()
    .background(Color.appBackground)
}
```

**Step 2: 驗證 build**

Run: `cd /Users/firstfu/Desktop/lingo_journey/.worktrees/translation-ui-feedback && xcodebuild -project lingo_journey.xcodeproj -scheme lingo_journey -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | grep -E '(error:|BUILD SUCCEEDED|BUILD FAILED)'`

Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add lingo_journey/DesignSystem/Components/AudioWaveformView.swift
git commit -m "feat: add AudioWaveformView component for mic visualization"
```

---

## Task 2: 整合波形視圖到 TranslationInputCard

**Files:**
- Modify: `lingo_journey/DesignSystem/Components/TranslationInputCard.swift`

**Step 1: 添加 audioLevel 參數並顯示波形**

將 TranslationInputCard.swift 修改為：

```swift
import SwiftUI

struct TranslationInputCard: View {
    let languageName: String
    @Binding var text: String
    var onCameraTap: (() -> Void)?
    var onMicTap: () -> Void
    var isListening: Bool = false
    var audioLevel: Float = 0.0

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            HStack {
                Text(languageName)
                    .font(.appFootnote)
                    .foregroundColor(.appTextSecondary)

                Spacer()

                HStack(spacing: AppSpacing.md) {
                    // Camera button
                    if let onCameraTap = onCameraTap {
                        Button(action: onCameraTap) {
                            Image(systemName: "camera.viewfinder")
                                .font(.system(size: 20))
                                .foregroundColor(.appTextSecondary)
                                .frame(width: 44, height: 44)
                        }
                    }

                    // Mic button
                    Button(action: onMicTap) {
                        Image(systemName: isListening ? "mic.fill" : "mic")
                            .font(.system(size: 20))
                            .foregroundColor(isListening ? .appPrimary : .appTextSecondary)
                            .frame(width: 44, height: 44)
                            .background(isListening ? Color.appPrimary.opacity(0.2) : Color.clear)
                            .clipShape(Circle())
                    }
                }
            }

            // Audio waveform when listening
            if isListening {
                AudioWaveformView(audioLevel: audioLevel)
                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
            }

            TextField("Enter your text here...", text: $text, axis: .vertical)
                .font(.appBody)
                .foregroundColor(.appTextPrimary)
                .lineLimit(5...10)
                .textFieldStyle(.plain)
        }
        .padding(AppSpacing.xl)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.large))
        .animation(.easeInOut(duration: 0.2), value: isListening)
    }
}

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        VStack(spacing: 20) {
            TranslationInputCard(
                languageName: "English",
                text: .constant("Hello"),
                onCameraTap: {},
                onMicTap: {},
                isListening: false
            )
            TranslationInputCard(
                languageName: "English",
                text: .constant("Hello"),
                onCameraTap: {},
                onMicTap: {},
                isListening: true,
                audioLevel: 0.6
            )
        }
        .padding()
    }
}
```

**Step 2: 更新 TranslationView 傳遞 audioLevel**

在 `TranslationView.swift` 第 60-66 行，修改 TranslationInputCard 調用：

```swift
TranslationInputCard(
    languageName: displayName(for: sourceLanguage),
    text: $sourceText,
    onCameraTap: handleCameraTap,
    onMicTap: handleMicTap,
    isListening: isListening,
    audioLevel: speechService.audioLevel
)
.padding(.horizontal, AppSpacing.xl)
```

**Step 3: 驗證 build**

Run: `cd /Users/firstfu/Desktop/lingo_journey/.worktrees/translation-ui-feedback && xcodebuild -project lingo_journey.xcodeproj -scheme lingo_journey -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | grep -E '(error:|BUILD SUCCEEDED|BUILD FAILED)'`

Expected: BUILD SUCCEEDED

**Step 4: Commit**

```bash
git add lingo_journey/DesignSystem/Components/TranslationInputCard.swift lingo_journey/Features/Translation/TranslationView.swift
git commit -m "feat: integrate audio waveform into TranslationInputCard"
```

---

## Task 3: 修改 TranslationResultCard 支援播放和複製狀態

**Files:**
- Modify: `lingo_journey/DesignSystem/Components/TranslationResultCard.swift`

**Step 1: 添加狀態參數並更新 IconButton**

```swift
import SwiftUI

struct TranslationResultCard: View {
    let languageName: String
    let translatedText: String
    var onCopy: () -> Void
    var onSpeak: () -> Void
    var onFavorite: () -> Void
    var isFavorite: Bool = false
    var isSpeaking: Bool = false
    var showCopySuccess: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            HStack {
                Text(languageName)
                    .font(.appFootnote)
                    .foregroundColor(.appTextSecondary)

                Spacer()

                HStack(spacing: AppSpacing.sm) {
                    // Copy button with success state
                    IconButton(
                        icon: showCopySuccess ? "checkmark" : "doc.on.doc",
                        action: onCopy,
                        tint: showCopySuccess ? .green : .appTextSecondary
                    )

                    // Speak button with speaking state
                    IconButton(
                        icon: isSpeaking ? "speaker.wave.3.fill" : "speaker.wave.2",
                        action: onSpeak,
                        tint: isSpeaking ? .appPrimary : .appTextSecondary,
                        isAnimating: isSpeaking
                    )

                    IconButton(
                        icon: isFavorite ? "star.fill" : "star",
                        action: onFavorite,
                        tint: isFavorite ? .appWarning : .appTextSecondary
                    )
                }
            }

            Text(translatedText)
                .font(.appBody)
                .foregroundColor(.appTextPrimary)
                .textSelection(.enabled)
        }
        .padding(AppSpacing.xl)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.large))
    }
}

struct IconButton: View {
    let icon: String
    let action: () -> Void
    var tint: Color = .appTextSecondary
    var isAnimating: Bool = false

    @State private var animationPhase: CGFloat = 0

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(tint)
                .opacity(isAnimating ? (0.5 + 0.5 * sin(animationPhase)) : 1.0)
                .frame(width: 36, height: 36)
        }
        .onChange(of: isAnimating) { _, newValue in
            if newValue {
                withAnimation(.linear(duration: 0.8).repeatForever(autoreverses: false)) {
                    animationPhase = .pi * 2
                }
            } else {
                animationPhase = 0
            }
        }
        .animation(.easeInOut(duration: 0.2), value: icon)
        .animation(.easeInOut(duration: 0.2), value: tint)
    }
}

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        VStack(spacing: 20) {
            TranslationResultCard(
                languageName: "繁體中文",
                translatedText: "你好，你好嗎？",
                onCopy: {},
                onSpeak: {},
                onFavorite: {},
                isFavorite: false,
                isSpeaking: false,
                showCopySuccess: false
            )
            TranslationResultCard(
                languageName: "繁體中文",
                translatedText: "你好，你好嗎？",
                onCopy: {},
                onSpeak: {},
                onFavorite: {},
                isFavorite: true,
                isSpeaking: true,
                showCopySuccess: true
            )
        }
        .padding()
    }
}
```

**Step 2: 驗證 build**

Run: `cd /Users/firstfu/Desktop/lingo_journey/.worktrees/translation-ui-feedback && xcodebuild -project lingo_journey.xcodeproj -scheme lingo_journey -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | grep -E '(error:|BUILD SUCCEEDED|BUILD FAILED)'`

Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add lingo_journey/DesignSystem/Components/TranslationResultCard.swift
git commit -m "feat: add speaking and copy success states to TranslationResultCard"
```

---

## Task 4: 實作 TTS 和複製反饋邏輯

**Files:**
- Modify: `lingo_journey/Features/Translation/TranslationView.swift`

**Step 1: 添加 TTS 和反饋相關狀態與邏輯**

在 TranslationView.swift 中進行以下修改：

1. 在第 1 行的 import 區塊確認已有 `import AVFoundation`

2. 在第 24 行後添加新狀態：

```swift
// TTS states
@State private var isSpeaking = false
@State private var speechSynthesizer = AVSpeechSynthesizer()

// Copy feedback states
@State private var showCopySuccess = false
```

3. 在 struct 定義後添加 init 和 delegate 設置，在第 39 行之前：

```swift
init() {
    // Will set delegate in onAppear
}
```

4. 修改 TranslationResultCard 調用（第 78-86 行）：

```swift
TranslationResultCard(
    languageName: displayName(for: targetLanguage),
    translatedText: translatedText,
    onCopy: copyToClipboard,
    onSpeak: toggleSpeak,
    onFavorite: toggleFavorite,
    isFavorite: currentRecord?.isFavorite ?? false,
    isSpeaking: isSpeaking,
    showCopySuccess: showCopySuccess
)
.padding(.horizontal, AppSpacing.xl)
.transition(.move(edge: .bottom).combined(with: .opacity))
```

5. 替換 copyToClipboard 函數（第 251-253 行）：

```swift
private func copyToClipboard() {
    UIPasteboard.general.string = translatedText

    // Haptic feedback
    let generator = UIImpactFeedbackGenerator(style: .light)
    generator.impactOccurred()

    // Show success state
    withAnimation(.easeInOut(duration: 0.2)) {
        showCopySuccess = true
    }

    // Reset after 1.5 seconds
    Task {
        try? await Task.sleep(for: .seconds(1.5))
        await MainActor.run {
            withAnimation(.easeInOut(duration: 0.2)) {
                showCopySuccess = false
            }
        }
    }
}
```

6. 在 toggleFavorite 函數後添加 TTS 函數：

```swift
private func toggleSpeak() {
    if isSpeaking {
        speechSynthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
    } else {
        speakText(translatedText, language: targetLanguage)
    }
}

private func speakText(_ text: String, language: Locale.Language) {
    let utterance = AVSpeechUtterance(string: text)
    utterance.voice = AVSpeechSynthesisVoice(language: language.minimalIdentifier)
    utterance.rate = AVSpeechUtteranceDefaultSpeechRate

    isSpeaking = true
    speechSynthesizer.speak(utterance)

    // Monitor completion
    Task {
        while speechSynthesizer.isSpeaking {
            try? await Task.sleep(for: .milliseconds(100))
        }
        await MainActor.run {
            isSpeaking = false
        }
    }
}
```

**Step 2: 驗證 build**

Run: `cd /Users/firstfu/Desktop/lingo_journey/.worktrees/translation-ui-feedback && xcodebuild -project lingo_journey.xcodeproj -scheme lingo_journey -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | grep -E '(error:|BUILD SUCCEEDED|BUILD FAILED)'`

Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add lingo_journey/Features/Translation/TranslationView.swift
git commit -m "feat: implement TTS playback and copy haptic feedback"
```

---

## Task 5: 最終驗證與合併準備

**Files:**
- All modified files

**Step 1: 執行完整 build**

Run: `cd /Users/firstfu/Desktop/lingo_journey/.worktrees/translation-ui-feedback && xcodebuild -project lingo_journey.xcodeproj -scheme lingo_journey -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | tail -20`

Expected: BUILD SUCCEEDED

**Step 2: 更新設計文檔狀態**

修改 `docs/plans/2026-01-29-translation-ui-feedback-design.md` 的驗收標準，將完成項目打勾。

**Step 3: Final commit**

```bash
git add docs/plans/
git commit -m "docs: mark implementation tasks as complete"
```

---

## 檔案變更摘要

| 檔案 | 操作 | 說明 |
|------|------|------|
| `DesignSystem/Components/AudioWaveformView.swift` | 新增 | 音量波形視圖組件 |
| `DesignSystem/Components/TranslationInputCard.swift` | 修改 | 整合波形視圖 |
| `DesignSystem/Components/TranslationResultCard.swift` | 修改 | 添加播放/複製狀態 |
| `Features/Translation/TranslationView.swift` | 修改 | TTS 和觸覺反饋邏輯 |
