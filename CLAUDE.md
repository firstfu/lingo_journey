# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

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
