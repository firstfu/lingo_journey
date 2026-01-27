# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Lingo Journey** 是一款 iOS 翻譯應用程式，主打全離線使用能力。

### 核心功能
- **即時翻譯** - 使用 Apple Translation 框架，裝置端離線翻譯
- **語音輸入** - 離線語音辨識 (Speech framework)
- **位置感知** - 根據 GPS 位置自動建議當地語言
- **Live Activity** - 動態島與鎖定畫面顯示翻譯進度
- **翻譯歷史** - SwiftData 儲存，支援收藏功能

### 系統需求
- iOS 18.0+ / Xcode 16.0+ / Swift 6.0+

## Build Commands

```bash
# Build (use iPhone 17 Pro simulator)
xcodebuild -project lingo_journey.xcodeproj -scheme lingo_journey -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# Run tests
xcodebuild -project lingo_journey.xcodeproj -scheme lingo_journey -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test

# Open in Xcode
open lingo_journey.xcodeproj
```

## Architecture

### Project Structure
- **Core/Models/** - SwiftData models (`@Model` classes)
- **Core/Services/** - Business logic services using `@Observable` pattern
- **Features/** - Feature modules (Translation, History, Settings, etc.)
- **DesignSystem/** - Reusable UI tokens and components
- **LiveActivity/** - ActivityKit definitions for Dynamic Island

### Key Patterns

**Services**: Use `@Observable final class` with singleton pattern
```swift
@Observable
final class SomeService {
    static let shared = SomeService()
    private init() {}
}
```

**Data Persistence**:
- SwiftData for structured data (TranslationRecord, LanguagePackage)
- UserDefaults/@AppStorage for simple preferences

**SwiftData Container**: Configured in `lingo_journeyApp.swift` with `.modelContainer(for:)`

### Design System Conventions

Use these prefixed tokens instead of raw values:

| Type | Prefix | Example |
|------|--------|---------|
| Colors | `Color.app*` | `.appPrimary`, `.appBackground`, `.appTextSecondary` |
| Fonts | `Font.app*` | `.appTitle1`, `.appBody`, `.appCaption` |
| Spacing | `AppSpacing.*` | `.xl` (16pt), `.xxl` (20pt), `.section` (32pt) |
| Radius | `AppRadius.*` | `.small` (8pt), `.medium` (12pt), `.large` (16pt) |

### Localization

- String Catalog at `Resources/Localizable.xcstrings`
- Use `String(localized:)` or `Text("key")` for localized strings
- Supported: zh-Hant, zh-Hans, en, ja, ko, es, fr, de, pt

## Framework Dependencies

| Framework | Usage |
|-----------|-------|
| Translation | On-device translation (iOS 17.4+) |
| Speech | Speech-to-text with `requiresOnDeviceRecognition` |
| ActivityKit | Live Activity for translation status |
| CoreLocation + MapKit | Location-based language suggestions |
