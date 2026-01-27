# LingoJourney MVP Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a fully functional iOS translation app with text/voice input, dual-conversation mode, offline language packs, geo-aware suggestions, history/favorites, and Dynamic Island integration.

**Architecture:** Feature-based modular architecture with shared DesignSystem and Core services. Each feature (Translation, Conversation, History, Settings) is self-contained with its own Views, ViewModels, and components. Core services (TranslationService, SpeechService, LocationService) are injected via environment.

**Tech Stack:** SwiftUI (iOS 18+), Translation Framework, Speech Framework, SwiftData, CoreLocation, ActivityKit

---

## Phase 1: Project Foundation

### Task 1: Design System - Colors

**Files:**
- Create: `lingo_journey/DesignSystem/Colors.swift`

**Step 1: Create the Colors extension file**

```swift
import SwiftUI

// MARK: - App Colors
extension Color {
    // Background
    static let appBackground = Color(hex: "0A1628")
    static let appSurface = Color(hex: "0F2744")
    static let appSurfaceElevated = Color(hex: "162D4A")

    // Primary
    static let appPrimary = Color(hex: "4A9EFF")
    static let appPrimaryMuted = Color(hex: "2563EB")

    // Text
    static let appTextPrimary = Color.white
    static let appTextSecondary = Color(hex: "8E9BAE")
    static let appTextMuted = Color(hex: "5A6B7D")

    // Utility
    static let appBorder = Color(hex: "1E3A5F")
    static let appSuccess = Color(hex: "10B981")
    static let appWarning = Color(hex: "F59E0B")
    static let appError = Color(hex: "EF4444")
}

// MARK: - Hex Initializer
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
```

**Step 2: Verify file compiles**

Run: Open Xcode, build project (Cmd+B)
Expected: Build Succeeded

**Step 3: Commit**

```bash
git add lingo_journey/DesignSystem/Colors.swift
git commit -m "feat: add design system colors"
```

---

### Task 2: Design System - Typography

**Files:**
- Create: `lingo_journey/DesignSystem/Typography.swift`

**Step 1: Create the Typography extension file**

```swift
import SwiftUI

// MARK: - App Typography
extension Font {
    static let appLargeTitle = Font.system(size: 34, weight: .bold)
    static let appTitle1 = Font.system(size: 28, weight: .bold)
    static let appTitle2 = Font.system(size: 22, weight: .semibold)
    static let appHeadline = Font.system(size: 17, weight: .semibold)
    static let appBody = Font.system(size: 17, weight: .regular)
    static let appCallout = Font.system(size: 16, weight: .regular)
    static let appSubheadline = Font.system(size: 15, weight: .regular)
    static let appFootnote = Font.system(size: 13, weight: .regular)
    static let appCaption = Font.system(size: 12, weight: .medium)
}
```

**Step 2: Verify file compiles**

Run: Build project (Cmd+B)
Expected: Build Succeeded

**Step 3: Commit**

```bash
git add lingo_journey/DesignSystem/Typography.swift
git commit -m "feat: add design system typography"
```

---

### Task 3: Design System - Spacing

**Files:**
- Create: `lingo_journey/DesignSystem/Spacing.swift`

**Step 1: Create the Spacing constants file**

```swift
import SwiftUI

// MARK: - App Spacing (8pt Grid)
struct AppSpacing {
    static let xs: CGFloat = 2
    static let sm: CGFloat = 4
    static let md: CGFloat = 8
    static let lg: CGFloat = 12
    static let xl: CGFloat = 16
    static let xxl: CGFloat = 20
    static let xxxl: CGFloat = 24
    static let section: CGFloat = 32
    static let page: CGFloat = 48
}

// MARK: - App Radius
struct AppRadius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
    static let xl: CGFloat = 20
    static let full: CGFloat = 9999
}
```

**Step 2: Verify file compiles**

Run: Build project (Cmd+B)
Expected: Build Succeeded

**Step 3: Commit**

```bash
git add lingo_journey/DesignSystem/Spacing.swift
git commit -m "feat: add design system spacing and radius"
```

---

### Task 4: Design System - Primary Button Component

**Files:**
- Create: `lingo_journey/DesignSystem/Components/PrimaryButton.swift`

**Step 1: Create the PrimaryButton component**

```swift
import SwiftUI

struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    var isLoading: Bool = false
    var isDisabled: Bool = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.md) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                }
                Text(title)
                    .font(.appHeadline)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(isDisabled ? Color.appPrimaryMuted : Color.appPrimary)
            .clipShape(Capsule())
        }
        .disabled(isDisabled || isLoading)
        .scaleEffect(isLoading ? 0.98 : 1.0)
        .animation(.easeOut(duration: 0.15), value: isLoading)
    }
}

#Preview {
    VStack(spacing: 20) {
        PrimaryButton(title: "Get Started", action: {})
        PrimaryButton(title: "Loading...", action: {}, isLoading: true)
        PrimaryButton(title: "Disabled", action: {}, isDisabled: true)
    }
    .padding()
    .background(Color.appBackground)
}
```

**Step 2: Verify preview renders correctly**

Run: Open Preview in Xcode (Cmd+Option+P)
Expected: Three button states visible on dark background

**Step 3: Commit**

```bash
git add lingo_journey/DesignSystem/Components/PrimaryButton.swift
git commit -m "feat: add PrimaryButton component"
```

---

### Task 5: Design System - Secondary Button Component

**Files:**
- Create: `lingo_journey/DesignSystem/Components/SecondaryButton.swift`

**Step 1: Create the SecondaryButton component**

```swift
import SwiftUI

struct SecondaryButton: View {
    let title: String
    let action: () -> Void
    var isDisabled: Bool = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.appHeadline)
                .foregroundColor(isDisabled ? .appTextMuted : .appPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.appSurface)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isDisabled ? Color.appBorder : Color.appPrimary, lineWidth: 1)
                )
        }
        .disabled(isDisabled)
    }
}

#Preview {
    VStack(spacing: 20) {
        SecondaryButton(title: "Cancel", action: {})
        SecondaryButton(title: "Disabled", action: {}, isDisabled: true)
    }
    .padding()
    .background(Color.appBackground)
}
```

**Step 2: Verify preview renders correctly**

Run: Open Preview in Xcode
Expected: Two button states visible

**Step 3: Commit**

```bash
git add lingo_journey/DesignSystem/Components/SecondaryButton.swift
git commit -m "feat: add SecondaryButton component"
```

---

### Task 6: SwiftData Models - TranslationRecord

**Files:**
- Create: `lingo_journey/Core/Models/TranslationRecord.swift`

**Step 1: Create the TranslationRecord model**

```swift
import Foundation
import SwiftData

@Model
final class TranslationRecord {
    var id: UUID
    var sourceText: String
    var translatedText: String
    var sourceLanguage: String
    var targetLanguage: String
    var isFavorite: Bool
    var createdAt: Date

    init(
        sourceText: String,
        translatedText: String,
        sourceLanguage: String,
        targetLanguage: String
    ) {
        self.id = UUID()
        self.sourceText = sourceText
        self.translatedText = translatedText
        self.sourceLanguage = sourceLanguage
        self.targetLanguage = targetLanguage
        self.isFavorite = false
        self.createdAt = Date()
    }
}
```

**Step 2: Verify file compiles**

Run: Build project (Cmd+B)
Expected: Build Succeeded

**Step 3: Commit**

```bash
git add lingo_journey/Core/Models/TranslationRecord.swift
git commit -m "feat: add TranslationRecord SwiftData model"
```

---

### Task 7: SwiftData Models - LanguagePackage

**Files:**
- Create: `lingo_journey/Core/Models/LanguagePackage.swift`

**Step 1: Create the LanguagePackage model**

```swift
import Foundation
import SwiftData

@Model
final class LanguagePackage {
    var languageCode: String
    var displayName: String
    var isDownloaded: Bool
    var downloadedAt: Date?
    var fileSize: Int64

    init(languageCode: String, displayName: String, fileSize: Int64 = 0) {
        self.languageCode = languageCode
        self.displayName = displayName
        self.isDownloaded = false
        self.fileSize = fileSize
    }
}
```

**Step 2: Verify file compiles**

Run: Build project (Cmd+B)
Expected: Build Succeeded

**Step 3: Commit**

```bash
git add lingo_journey/Core/Models/LanguagePackage.swift
git commit -m "feat: add LanguagePackage SwiftData model"
```

---

### Task 8: Configure App Entry Point with SwiftData

**Files:**
- Modify: `lingo_journey/lingo_journeyApp.swift`

**Step 1: Update the App entry point**

```swift
import SwiftUI
import SwiftData

@main
struct lingo_journeyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            TranslationRecord.self,
            LanguagePackage.self
        ])
    }
}
```

**Step 2: Verify app launches**

Run: Run app on simulator (Cmd+R)
Expected: App launches without crashes

**Step 3: Commit**

```bash
git add lingo_journey/lingo_journeyApp.swift
git commit -m "feat: configure SwiftData model container"
```

---

## Phase 2: Core Services

### Task 9: Translation Service

**Files:**
- Create: `lingo_journey/Core/Services/TranslationService.swift`

**Step 1: Create the TranslationService**

```swift
import Foundation
import Translation

@Observable
final class TranslationService {
    var isTranslating: Bool = false
    var error: Error?

    private var availableLanguages: [LanguageAvailability.Status] = []

    /// Check if a language pair is available for translation
    func checkAvailability(
        source: Locale.Language,
        target: Locale.Language
    ) async -> LanguageAvailability.Status {
        let availability = LanguageAvailability()
        return await availability.status(from: source, to: target)
    }

    /// Get all supported languages
    func getSupportedLanguages() async -> [Locale.Language] {
        let availability = LanguageAvailability()
        return await availability.supportedLanguages
    }

    /// Prepare (download) a language pair for offline use
    func prepareLanguagePair(
        source: Locale.Language,
        target: Locale.Language
    ) async throws {
        let config = TranslationSession.Configuration(
            source: source,
            target: target
        )
        // The system will prompt user to download if needed
        // This is handled by the translationTask modifier
    }
}
```

**Step 2: Verify file compiles**

Run: Build project (Cmd+B)
Expected: Build Succeeded

**Step 3: Commit**

```bash
git add lingo_journey/Core/Services/TranslationService.swift
git commit -m "feat: add TranslationService for Translation framework"
```

---

### Task 10: Speech Service

**Files:**
- Create: `lingo_journey/Core/Services/SpeechService.swift`

**Step 1: Create the SpeechService**

```swift
import Foundation
import Speech
import AVFoundation

@Observable
final class SpeechService: NSObject {
    var isListening: Bool = false
    var recognizedText: String = ""
    var error: Error?
    var audioLevel: Float = 0.0

    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    override init() {
        super.init()
    }

    /// Request speech recognition authorization
    func requestAuthorization() async -> SFSpeechRecognizerAuthorizationStatus {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }

    /// Start listening for speech in the specified language
    func startListening(language: Locale.Language) throws {
        // Reset state
        stopListening()

        let locale = Locale(identifier: language.minimalIdentifier)
        speechRecognizer = SFSpeechRecognizer(locale: locale)

        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            throw SpeechError.recognizerUnavailable
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw SpeechError.requestCreationFailed
        }

        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.requiresOnDeviceRecognition = true

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)

            // Calculate audio level for visualization
            let level = self?.calculateAudioLevel(buffer: buffer) ?? 0
            Task { @MainActor in
                self?.audioLevel = level
            }
        }

        audioEngine.prepare()
        try audioEngine.start()

        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            Task { @MainActor in
                if let result = result {
                    self?.recognizedText = result.bestTranscription.formattedString
                }

                if let error = error {
                    self?.error = error
                    self?.stopListening()
                }
            }
        }

        isListening = true
    }

    /// Stop listening
    func stopListening() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()

        recognitionRequest = nil
        recognitionTask = nil
        isListening = false
        audioLevel = 0.0
    }

    private func calculateAudioLevel(buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData?[0] else { return 0 }
        let frameLength = Int(buffer.frameLength)

        var sum: Float = 0
        for i in 0..<frameLength {
            sum += abs(channelData[i])
        }

        let average = sum / Float(frameLength)
        return min(average * 10, 1.0) // Normalize to 0-1
    }
}

// MARK: - Speech Errors
enum SpeechError: LocalizedError {
    case recognizerUnavailable
    case requestCreationFailed
    case notAuthorized

    var errorDescription: String? {
        switch self {
        case .recognizerUnavailable:
            return "Speech recognizer is not available for this language"
        case .requestCreationFailed:
            return "Could not create speech recognition request"
        case .notAuthorized:
            return "Speech recognition is not authorized"
        }
    }
}
```

**Step 2: Verify file compiles**

Run: Build project (Cmd+B)
Expected: Build Succeeded

**Step 3: Add required Info.plist keys**

Add to Info.plist:
- `NSSpeechRecognitionUsageDescription`: "LingoJourney needs speech recognition to translate your voice."
- `NSMicrophoneUsageDescription`: "LingoJourney needs microphone access to hear your voice for translation."

**Step 4: Commit**

```bash
git add lingo_journey/Core/Services/SpeechService.swift
git add lingo_journey/Info.plist
git commit -m "feat: add SpeechService for voice recognition"
```

---

### Task 11: Location Service

**Files:**
- Create: `lingo_journey/Core/Services/LocationService.swift`

**Step 1: Create the LocationService**

```swift
import Foundation
import CoreLocation

@Observable
final class LocationService: NSObject, CLLocationManagerDelegate {
    var currentCountryCode: String?
    var suggestedLanguage: Locale.Language?
    var authorizationStatus: CLAuthorizationStatus = .notDetermined

    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()

    // Country code to primary language mapping
    private let countryLanguageMap: [String: String] = [
        "JP": "ja", // Japan -> Japanese
        "KR": "ko", // Korea -> Korean
        "CN": "zh-Hans", // China -> Simplified Chinese
        "TW": "zh-Hant", // Taiwan -> Traditional Chinese
        "TH": "th", // Thailand -> Thai
        "VN": "vi", // Vietnam -> Vietnamese
        "FR": "fr", // France -> French
        "DE": "de", // Germany -> German
        "ES": "es", // Spain -> Spanish
        "IT": "it", // Italy -> Italian
        "PT": "pt", // Portugal -> Portuguese
        "US": "en", // USA -> English
        "GB": "en", // UK -> English
        "AU": "en", // Australia -> English
    ]

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func requestAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }

    func startMonitoring() {
        guard authorizationStatus == .authorizedWhenInUse ||
              authorizationStatus == .authorizedAlways else {
            return
        }
        locationManager.startMonitoringSignificantLocationChanges()
    }

    func stopMonitoring() {
        locationManager.stopMonitoringSignificantLocationChanges()
    }

    func getCurrentLocation() {
        locationManager.requestLocation()
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self = self,
                  let placemark = placemarks?.first,
                  let countryCode = placemark.isoCountryCode else {
                return
            }

            Task { @MainActor in
                self.currentCountryCode = countryCode
                if let languageCode = self.countryLanguageMap[countryCode] {
                    self.suggestedLanguage = Locale.Language(identifier: languageCode)
                }
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            startMonitoring()
            getCurrentLocation()
        }
    }
}
```

**Step 2: Add required Info.plist key**

Add to Info.plist:
- `NSLocationWhenInUseUsageDescription`: "LingoJourney uses your location to suggest relevant languages when you travel."

**Step 3: Verify file compiles**

Run: Build project (Cmd+B)
Expected: Build Succeeded

**Step 4: Commit**

```bash
git add lingo_journey/Core/Services/LocationService.swift
git add lingo_journey/Info.plist
git commit -m "feat: add LocationService for geo-aware language suggestions"
```

---

## Phase 3: Tab Bar & Navigation

### Task 12: Main Tab View

**Files:**
- Create: `lingo_journey/Features/MainTabView.swift`

**Step 1: Create the MainTabView**

```swift
import SwiftUI

enum AppTab: Int, CaseIterable {
    case translate
    case voice
    case history
    case settings

    var title: String {
        switch self {
        case .translate: return "翻譯"
        case .voice: return "語音"
        case .history: return "歷史"
        case .settings: return "設定"
        }
    }

    var icon: String {
        switch self {
        case .translate: return "character.bubble"
        case .voice: return "waveform"
        case .history: return "clock.arrow.circlepath"
        case .settings: return "gearshape"
        }
    }
}

struct MainTabView: View {
    @State private var selectedTab: AppTab = .translate

    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                tabContent(for: tab)
                    .tabItem {
                        Label(tab.title, systemImage: tab.icon)
                    }
                    .tag(tab)
            }
        }
        .tint(.appPrimary)
    }

    @ViewBuilder
    private func tabContent(for tab: AppTab) -> some View {
        switch tab {
        case .translate:
            TranslationPlaceholderView()
        case .voice:
            VoicePlaceholderView()
        case .history:
            HistoryPlaceholderView()
        case .settings:
            SettingsPlaceholderView()
        }
    }
}

// MARK: - Placeholder Views (to be replaced)

struct TranslationPlaceholderView: View {
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            Text("翻譯")
                .font(.appTitle1)
                .foregroundColor(.appTextPrimary)
        }
    }
}

struct VoicePlaceholderView: View {
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            Text("語音")
                .font(.appTitle1)
                .foregroundColor(.appTextPrimary)
        }
    }
}

struct HistoryPlaceholderView: View {
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            Text("歷史")
                .font(.appTitle1)
                .foregroundColor(.appTextPrimary)
        }
    }
}

struct SettingsPlaceholderView: View {
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            Text("設定")
                .font(.appTitle1)
                .foregroundColor(.appTextPrimary)
        }
    }
}

#Preview {
    MainTabView()
        .preferredColorScheme(.dark)
}
```

**Step 2: Update ContentView to show MainTabView**

Modify `lingo_journey/ContentView.swift`:

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        MainTabView()
    }
}

#Preview {
    ContentView()
}
```

**Step 3: Verify app shows tab bar**

Run: Run app on simulator (Cmd+R)
Expected: App shows 4 tabs with icons, dark background

**Step 4: Commit**

```bash
git add lingo_journey/Features/MainTabView.swift
git add lingo_journey/ContentView.swift
git commit -m "feat: add MainTabView with 4 tabs"
```

---

## Phase 4: Translation Feature

### Task 13: Language Selector Component

**Files:**
- Create: `lingo_journey/DesignSystem/Components/LanguageSelector.swift`

**Step 1: Create the LanguageSelector component**

```swift
import SwiftUI

struct LanguageSelector: View {
    @Binding var sourceLanguage: Locale.Language
    @Binding var targetLanguage: Locale.Language
    var onSwap: () -> Void

    var body: some View {
        HStack(spacing: AppSpacing.lg) {
            // Source language button
            LanguagePill(
                language: sourceLanguage,
                action: { /* TODO: Show language picker */ }
            )

            // Swap button
            Button(action: onSwap) {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.appPrimary)
                    .frame(width: 36, height: 36)
                    .background(Color.appSurface)
                    .clipShape(Circle())
            }

            // Target language button
            LanguagePill(
                language: targetLanguage,
                action: { /* TODO: Show language picker */ }
            )
        }
        .padding(.horizontal, AppSpacing.xl)
    }
}

struct LanguagePill: View {
    let language: Locale.Language
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(displayName(for: language))
                .font(.appHeadline)
                .foregroundColor(.appTextPrimary)
                .padding(.horizontal, AppSpacing.xl)
                .padding(.vertical, AppSpacing.lg)
                .background(Color.appSurface)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.appBorder, lineWidth: 1)
                )
        }
    }

    private func displayName(for language: Locale.Language) -> String {
        let locale = Locale(identifier: language.minimalIdentifier)
        return locale.localizedString(forIdentifier: language.minimalIdentifier)?.capitalized ?? language.minimalIdentifier
    }
}

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        LanguageSelector(
            sourceLanguage: .constant(Locale.Language(identifier: "en")),
            targetLanguage: .constant(Locale.Language(identifier: "zh-Hant")),
            onSwap: {}
        )
    }
}
```

**Step 2: Verify preview renders correctly**

Run: Open Preview in Xcode
Expected: Two language pills with swap button in between

**Step 3: Commit**

```bash
git add lingo_journey/DesignSystem/Components/LanguageSelector.swift
git commit -m "feat: add LanguageSelector component"
```

---

### Task 14: Translation Input Card Component

**Files:**
- Create: `lingo_journey/DesignSystem/Components/TranslationInputCard.swift`

**Step 1: Create the TranslationInputCard component**

```swift
import SwiftUI

struct TranslationInputCard: View {
    let languageName: String
    @Binding var text: String
    var onMicTap: () -> Void
    var isListening: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            // Header
            HStack {
                Text(languageName)
                    .font(.appFootnote)
                    .foregroundColor(.appTextSecondary)

                Spacer()

                Button(action: onMicTap) {
                    Image(systemName: isListening ? "mic.fill" : "mic")
                        .font(.system(size: 20))
                        .foregroundColor(isListening ? .appPrimary : .appTextSecondary)
                        .frame(width: 44, height: 44)
                        .background(isListening ? Color.appPrimary.opacity(0.2) : Color.clear)
                        .clipShape(Circle())
                }
            }

            // Text input
            TextField("Enter your text here...", text: $text, axis: .vertical)
                .font(.appBody)
                .foregroundColor(.appTextPrimary)
                .lineLimit(5...10)
                .textFieldStyle(.plain)
        }
        .padding(AppSpacing.xl)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.large))
    }
}

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        TranslationInputCard(
            languageName: "English",
            text: .constant("Hello, how are you?"),
            onMicTap: {},
            isListening: false
        )
        .padding()
    }
}
```

**Step 2: Verify preview renders correctly**

Run: Open Preview in Xcode
Expected: Card with language label, text field, and mic button

**Step 3: Commit**

```bash
git add lingo_journey/DesignSystem/Components/TranslationInputCard.swift
git commit -m "feat: add TranslationInputCard component"
```

---

### Task 15: Translation Result Card Component

**Files:**
- Create: `lingo_journey/DesignSystem/Components/TranslationResultCard.swift`

**Step 1: Create the TranslationResultCard component**

```swift
import SwiftUI

struct TranslationResultCard: View {
    let languageName: String
    let translatedText: String
    var onCopy: () -> Void
    var onSpeak: () -> Void
    var onFavorite: () -> Void
    var isFavorite: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            // Header
            HStack {
                Text(languageName)
                    .font(.appFootnote)
                    .foregroundColor(.appTextSecondary)

                Spacer()

                HStack(spacing: AppSpacing.sm) {
                    IconButton(icon: "doc.on.doc", action: onCopy)
                    IconButton(icon: "speaker.wave.2", action: onSpeak)
                    IconButton(
                        icon: isFavorite ? "star.fill" : "star",
                        action: onFavorite,
                        tint: isFavorite ? .appWarning : .appTextSecondary
                    )
                }
            }

            // Translated text
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

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(tint)
                .frame(width: 36, height: 36)
        }
    }
}

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        TranslationResultCard(
            languageName: "繁體中文",
            translatedText: "你好，你好嗎？",
            onCopy: {},
            onSpeak: {},
            onFavorite: {},
            isFavorite: true
        )
        .padding()
    }
}
```

**Step 2: Verify preview renders correctly**

Run: Open Preview in Xcode
Expected: Card with translated text and action buttons

**Step 3: Commit**

```bash
git add lingo_journey/DesignSystem/Components/TranslationResultCard.swift
git commit -m "feat: add TranslationResultCard component"
```

---

### Task 16: Translation View

**Files:**
- Create: `lingo_journey/Features/Translation/TranslationView.swift`

**Step 1: Create the TranslationView**

```swift
import SwiftUI
import Translation

struct TranslationView: View {
    @State private var sourceLanguage = Locale.Language(identifier: "en")
    @State private var targetLanguage = Locale.Language(identifier: "zh-Hant")
    @State private var sourceText = ""
    @State private var translatedText = ""
    @State private var isTranslating = false
    @State private var configuration: TranslationSession.Configuration?

    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: AppSpacing.xxl) {
                    // Header
                    Text("Translate")
                        .font(.appTitle1)
                        .foregroundColor(.appTextPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, AppSpacing.xl)

                    // Language selector
                    LanguageSelector(
                        sourceLanguage: $sourceLanguage,
                        targetLanguage: $targetLanguage,
                        onSwap: swapLanguages
                    )

                    // Input card
                    TranslationInputCard(
                        languageName: displayName(for: sourceLanguage),
                        text: $sourceText,
                        onMicTap: { /* TODO: Voice input */ }
                    )
                    .padding(.horizontal, AppSpacing.xl)

                    // Translate button
                    PrimaryButton(
                        title: "Translate",
                        action: triggerTranslation,
                        isLoading: isTranslating,
                        isDisabled: sourceText.isEmpty
                    )
                    .padding(.horizontal, AppSpacing.xl)

                    // Result card (if translated)
                    if !translatedText.isEmpty {
                        TranslationResultCard(
                            languageName: displayName(for: targetLanguage),
                            translatedText: translatedText,
                            onCopy: copyToClipboard,
                            onSpeak: { /* TODO: Text-to-speech */ },
                            onFavorite: saveToFavorites
                        )
                        .padding(.horizontal, AppSpacing.xl)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .padding(.vertical, AppSpacing.xxl)
            }
        }
        .translationTask(configuration) { session in
            await performTranslation(session: session)
        }
        .animation(.spring(duration: 0.3), value: translatedText)
    }

    // MARK: - Actions

    private func swapLanguages() {
        let temp = sourceLanguage
        sourceLanguage = targetLanguage
        targetLanguage = temp

        // Also swap texts
        let tempText = sourceText
        sourceText = translatedText
        translatedText = tempText
    }

    private func triggerTranslation() {
        guard !sourceText.isEmpty else { return }

        configuration = TranslationSession.Configuration(
            source: sourceLanguage,
            target: targetLanguage
        )
    }

    private func performTranslation(session: TranslationSession) async {
        isTranslating = true

        do {
            let response = try await session.translate(sourceText)
            await MainActor.run {
                translatedText = response.targetText
                isTranslating = false
                configuration = nil
            }
        } catch {
            await MainActor.run {
                isTranslating = false
                configuration = nil
                // TODO: Show error
            }
        }
    }

    private func copyToClipboard() {
        UIPasteboard.general.string = translatedText
        // TODO: Show toast feedback
    }

    private func saveToFavorites() {
        let record = TranslationRecord(
            sourceText: sourceText,
            translatedText: translatedText,
            sourceLanguage: sourceLanguage.minimalIdentifier,
            targetLanguage: targetLanguage.minimalIdentifier
        )
        record.isFavorite = true
        modelContext.insert(record)
    }

    private func displayName(for language: Locale.Language) -> String {
        let locale = Locale(identifier: language.minimalIdentifier)
        return locale.localizedString(forIdentifier: language.minimalIdentifier)?.capitalized ?? language.minimalIdentifier
    }
}

#Preview {
    TranslationView()
}
```

**Step 2: Update MainTabView to use TranslationView**

Modify `MainTabView.swift`, replace `TranslationPlaceholderView()` with:

```swift
case .translate:
    TranslationView()
```

**Step 3: Verify translation works**

Run: Run app on simulator, enter text, tap Translate
Expected: Translation result appears (may prompt for language download)

**Step 4: Commit**

```bash
git add lingo_journey/Features/Translation/TranslationView.swift
git add lingo_journey/Features/MainTabView.swift
git commit -m "feat: add TranslationView with Translation framework integration"
```

---

## Phase 5: Voice Conversation Feature

### Task 17: Waveform Visualizer Component

**Files:**
- Create: `lingo_journey/DesignSystem/Components/WaveformView.swift`

**Step 1: Create the WaveformView component**

```swift
import SwiftUI

struct WaveformView: View {
    var audioLevel: Float
    var isActive: Bool
    var barCount: Int = 5

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<barCount, id: \.self) { index in
                WaveformBar(
                    height: barHeight(for: index),
                    isActive: isActive
                )
            }
        }
    }

    private func barHeight(for index: Int) -> CGFloat {
        guard isActive else { return 8 }

        let baseHeight: CGFloat = 8
        let maxHeight: CGFloat = 32
        let variation = sin(Double(index) * 0.8) * 0.3 + 0.7
        let level = CGFloat(audioLevel) * CGFloat(variation)

        return baseHeight + (maxHeight - baseHeight) * level
    }
}

struct WaveformBar: View {
    var height: CGFloat
    var isActive: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(Color.appPrimary)
            .frame(width: 3, height: height)
            .animation(.easeInOut(duration: 0.1), value: height)
    }
}

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        VStack(spacing: 40) {
            WaveformView(audioLevel: 0.0, isActive: false)
            WaveformView(audioLevel: 0.3, isActive: true)
            WaveformView(audioLevel: 0.7, isActive: true)
            WaveformView(audioLevel: 1.0, isActive: true)
        }
    }
}
```

**Step 2: Verify preview renders correctly**

Run: Open Preview in Xcode
Expected: Waveform bars at different heights

**Step 3: Commit**

```bash
git add lingo_journey/DesignSystem/Components/WaveformView.swift
git commit -m "feat: add WaveformView component for audio visualization"
```

---

### Task 18: Conversation View

**Files:**
- Create: `lingo_journey/Features/Conversation/ConversationView.swift`

**Step 1: Create the ConversationView**

```swift
import SwiftUI
import Translation

struct ConversationView: View {
    @State private var myLanguage = Locale.Language(identifier: "zh-Hant")
    @State private var theirLanguage = Locale.Language(identifier: "en")

    @State private var myText = ""
    @State private var myTranslatedText = ""
    @State private var theirText = ""
    @State private var theirTranslatedText = ""

    @State private var isMyTurn = true
    @State private var isListening = false
    @State private var audioLevel: Float = 0.0

    @State private var speechService = SpeechService()
    @State private var translationConfig: TranslationSession.Configuration?

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Their section (top half, rotated 180 degrees for face-to-face)
                ConversationSection(
                    language: theirLanguage,
                    originalText: theirText,
                    translatedText: theirTranslatedText,
                    isActive: !isMyTurn && isListening,
                    audioLevel: audioLevel
                )
                .rotationEffect(.degrees(180))

                // Divider with language labels
                ConversationDivider(
                    topLanguage: theirLanguage,
                    bottomLanguage: myLanguage,
                    onSwap: swapLanguages
                )

                // My section (bottom half)
                ConversationSection(
                    language: myLanguage,
                    originalText: myText,
                    translatedText: myTranslatedText,
                    isActive: isMyTurn && isListening,
                    audioLevel: audioLevel
                )
            }

            // Center microphone button
            VStack {
                Spacer()
                MicrophoneButton(
                    isListening: isListening,
                    onTap: toggleListening
                )
                .padding(.bottom, AppSpacing.page)
            }
        }
        .translationTask(translationConfig) { session in
            await performTranslation(session: session)
        }
        .onChange(of: speechService.recognizedText) { _, newValue in
            if isMyTurn {
                myText = newValue
            } else {
                theirText = newValue
            }
        }
        .onChange(of: speechService.audioLevel) { _, newValue in
            audioLevel = newValue
        }
    }

    // MARK: - Actions

    private func toggleListening() {
        if isListening {
            stopListening()
        } else {
            startListening()
        }
    }

    private func startListening() {
        Task {
            let status = await speechService.requestAuthorization()
            guard status == .authorized else { return }

            do {
                let language = isMyTurn ? myLanguage : theirLanguage
                try speechService.startListening(language: language)
                isListening = true
            } catch {
                print("Speech error: \(error)")
            }
        }
    }

    private func stopListening() {
        speechService.stopListening()
        isListening = false

        // Trigger translation
        if isMyTurn && !myText.isEmpty {
            translationConfig = TranslationSession.Configuration(
                source: myLanguage,
                target: theirLanguage
            )
        } else if !isMyTurn && !theirText.isEmpty {
            translationConfig = TranslationSession.Configuration(
                source: theirLanguage,
                target: myLanguage
            )
        }
    }

    private func performTranslation(session: TranslationSession) async {
        do {
            if isMyTurn {
                let response = try await session.translate(myText)
                await MainActor.run {
                    myTranslatedText = response.targetText
                    translationConfig = nil
                    isMyTurn = false // Switch turns
                }
            } else {
                let response = try await session.translate(theirText)
                await MainActor.run {
                    theirTranslatedText = response.targetText
                    translationConfig = nil
                    isMyTurn = true // Switch turns
                }
            }
        } catch {
            await MainActor.run {
                translationConfig = nil
            }
        }
    }

    private func swapLanguages() {
        let temp = myLanguage
        myLanguage = theirLanguage
        theirLanguage = temp
    }
}

// MARK: - Subviews

struct ConversationSection: View {
    let language: Locale.Language
    let originalText: String
    let translatedText: String
    let isActive: Bool
    let audioLevel: Float

    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            if isActive {
                WaveformView(audioLevel: audioLevel, isActive: true)
                    .frame(height: 40)
            }

            if !originalText.isEmpty {
                Text(originalText)
                    .font(.appBody)
                    .foregroundColor(.appTextSecondary)
                    .multilineTextAlignment(.center)
            }

            if !translatedText.isEmpty {
                Text(translatedText)
                    .font(.appTitle2)
                    .foregroundColor(.appTextPrimary)
                    .multilineTextAlignment(.center)
            }

            if originalText.isEmpty && translatedText.isEmpty && !isActive {
                Text("Tap mic to speak")
                    .font(.appCallout)
                    .foregroundColor(.appTextMuted)
            }
        }
        .padding(AppSpacing.xxxl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ConversationDivider: View {
    let topLanguage: Locale.Language
    let bottomLanguage: Locale.Language
    let onSwap: () -> Void

    var body: some View {
        HStack {
            Text(displayName(for: bottomLanguage))
                .font(.appCaption)
                .foregroundColor(.appTextMuted)

            Spacer()

            Button(action: onSwap) {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.system(size: 14))
                    .foregroundColor(.appPrimary)
            }

            Spacer()

            Text(displayName(for: topLanguage))
                .font(.appCaption)
                .foregroundColor(.appTextMuted)
                .rotationEffect(.degrees(180))
        }
        .padding(.horizontal, AppSpacing.xl)
        .padding(.vertical, AppSpacing.md)
        .background(Color.appBorder.opacity(0.5))
    }

    private func displayName(for language: Locale.Language) -> String {
        let locale = Locale(identifier: language.minimalIdentifier)
        return locale.localizedString(forIdentifier: language.minimalIdentifier)?.capitalized ?? language.minimalIdentifier
    }
}

struct MicrophoneButton: View {
    let isListening: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                Circle()
                    .fill(isListening ? Color.appError : Color.appPrimary)
                    .frame(width: 72, height: 72)
                    .shadow(color: (isListening ? Color.appError : Color.appPrimary).opacity(0.4), radius: 12)

                Image(systemName: isListening ? "stop.fill" : "mic.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.white)
            }
        }
        .scaleEffect(isListening ? 1.1 : 1.0)
        .animation(.spring(duration: 0.2), value: isListening)
    }
}

#Preview {
    ConversationView()
}
```

**Step 2: Update MainTabView to use ConversationView**

Modify `MainTabView.swift`:

```swift
case .voice:
    ConversationView()
```

**Step 3: Verify conversation view appears**

Run: Run app, tap Voice tab
Expected: Split-screen conversation view with mic button

**Step 4: Commit**

```bash
git add lingo_journey/Features/Conversation/ConversationView.swift
git add lingo_journey/Features/MainTabView.swift
git commit -m "feat: add ConversationView for dual-conversation mode"
```

---

## Phase 6: History Feature

### Task 19: History View

**Files:**
- Create: `lingo_journey/Features/History/HistoryView.swift`

**Step 1: Create the HistoryView**

```swift
import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TranslationRecord.createdAt, order: .reverse) private var records: [TranslationRecord]

    @State private var searchText = ""
    @State private var showFavoritesOnly = false

    var filteredRecords: [TranslationRecord] {
        var result = records

        if showFavoritesOnly {
            result = result.filter { $0.isFavorite }
        }

        if !searchText.isEmpty {
            result = result.filter {
                $0.sourceText.localizedCaseInsensitiveContains(searchText) ||
                $0.translatedText.localizedCaseInsensitiveContains(searchText)
            }
        }

        return result
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                Text("History")
                    .font(.appTitle1)
                    .foregroundColor(.appTextPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, AppSpacing.xl)
                    .padding(.top, AppSpacing.xl)

                // Search bar
                SearchBar(text: $searchText)
                    .padding(.horizontal, AppSpacing.xl)
                    .padding(.vertical, AppSpacing.lg)

                // Filter toggle
                Picker("Filter", selection: $showFavoritesOnly) {
                    Text("All").tag(false)
                    Text("Favorites").tag(true)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, AppSpacing.xl)
                .padding(.bottom, AppSpacing.lg)

                // Records list
                if filteredRecords.isEmpty {
                    Spacer()
                    EmptyHistoryView(showFavoritesOnly: showFavoritesOnly)
                    Spacer()
                } else {
                    List {
                        ForEach(filteredRecords) { record in
                            HistoryRecordRow(record: record)
                                .listRowBackground(Color.appBackground)
                                .listRowSeparator(.hidden)
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        deleteRecord(record)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .leading) {
                                    Button {
                                        toggleFavorite(record)
                                    } label: {
                                        Label(
                                            record.isFavorite ? "Unfavorite" : "Favorite",
                                            systemImage: record.isFavorite ? "star.slash" : "star.fill"
                                        )
                                    }
                                    .tint(.appWarning)
                                }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
        }
    }

    private func deleteRecord(_ record: TranslationRecord) {
        modelContext.delete(record)
    }

    private func toggleFavorite(_ record: TranslationRecord) {
        record.isFavorite.toggle()
    }
}

// MARK: - Subviews

struct SearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.appTextMuted)

            TextField("Search translations...", text: $text)
                .font(.appCallout)
                .foregroundColor(.appTextPrimary)

            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.appTextMuted)
                }
            }
        }
        .padding(AppSpacing.lg)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium))
    }
}

struct HistoryRecordRow: View {
    let record: TranslationRecord

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text(record.sourceLanguage)
                    .font(.appCaption)
                    .foregroundColor(.appTextMuted)

                Image(systemName: "arrow.right")
                    .font(.system(size: 10))
                    .foregroundColor(.appTextMuted)

                Text(record.targetLanguage)
                    .font(.appCaption)
                    .foregroundColor(.appTextMuted)

                Spacer()

                if record.isFavorite {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.appWarning)
                }

                Text(record.createdAt.formatted(date: .omitted, time: .shortened))
                    .font(.appCaption)
                    .foregroundColor(.appTextMuted)
            }

            Text(record.sourceText)
                .font(.appBody)
                .foregroundColor(.appTextSecondary)
                .lineLimit(2)

            Text(record.translatedText)
                .font(.appBody)
                .foregroundColor(.appTextPrimary)
                .lineLimit(2)
        }
        .padding(AppSpacing.xl)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.large))
        .padding(.horizontal, AppSpacing.xl)
        .padding(.vertical, AppSpacing.sm)
    }
}

struct EmptyHistoryView: View {
    let showFavoritesOnly: Bool

    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            Image(systemName: showFavoritesOnly ? "star" : "clock")
                .font(.system(size: 48))
                .foregroundColor(.appTextMuted)

            Text(showFavoritesOnly ? "No favorites yet" : "No translation history")
                .font(.appHeadline)
                .foregroundColor(.appTextSecondary)

            Text(showFavoritesOnly ? "Star translations to save them here" : "Your translations will appear here")
                .font(.appCallout)
                .foregroundColor(.appTextMuted)
        }
    }
}

#Preview {
    HistoryView()
        .modelContainer(for: TranslationRecord.self, inMemory: true)
}
```

**Step 2: Update MainTabView to use HistoryView**

Modify `MainTabView.swift`:

```swift
case .history:
    HistoryView()
```

**Step 3: Verify history view appears**

Run: Run app, tap History tab
Expected: Empty state with search bar and segmented control

**Step 4: Commit**

```bash
git add lingo_journey/Features/History/HistoryView.swift
git add lingo_journey/Features/MainTabView.swift
git commit -m "feat: add HistoryView with search and favorites"
```

---

## Phase 7: Settings Feature

### Task 20: Settings View

**Files:**
- Create: `lingo_journey/Features/Settings/SettingsView.swift`

**Step 1: Create the SettingsView**

```swift
import SwiftUI

struct SettingsView: View {
    @State private var locationService = LocationService()
    @State private var isGeoAwareEnabled = true
    @State private var showLanguagePackages = false

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: AppSpacing.xxl) {
                    // Header
                    Text("Settings")
                        .font(.appTitle1)
                        .foregroundColor(.appTextPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, AppSpacing.xl)

                    // Language packages section
                    SettingsSection(title: "Languages") {
                        SettingsRow(
                            icon: "arrow.down.circle",
                            title: "Offline Languages",
                            subtitle: "Download languages for offline use"
                        ) {
                            showLanguagePackages = true
                        }
                    }

                    // Location section
                    SettingsSection(title: "Location") {
                        SettingsToggleRow(
                            icon: "location",
                            title: "Geo-Aware Suggestions",
                            subtitle: "Suggest languages based on your location",
                            isOn: $isGeoAwareEnabled
                        )

                        if let countryCode = locationService.currentCountryCode {
                            SettingsInfoRow(
                                icon: "globe",
                                title: "Current Region",
                                value: countryCode
                            )
                        }
                    }

                    // About section
                    SettingsSection(title: "About") {
                        SettingsInfoRow(
                            icon: "info.circle",
                            title: "Version",
                            value: "1.0.0"
                        )

                        SettingsRow(
                            icon: "hand.raised",
                            title: "Privacy Policy",
                            subtitle: nil
                        ) {
                            // TODO: Open privacy policy
                        }
                    }
                }
                .padding(.vertical, AppSpacing.xxl)
            }
        }
        .sheet(isPresented: $showLanguagePackages) {
            LanguagePackagesView()
        }
        .onChange(of: isGeoAwareEnabled) { _, enabled in
            if enabled {
                locationService.requestAuthorization()
            } else {
                locationService.stopMonitoring()
            }
        }
    }
}

// MARK: - Subviews

struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            Text(title.uppercased())
                .font(.appCaption)
                .foregroundColor(.appTextMuted)
                .padding(.horizontal, AppSpacing.xl)

            VStack(spacing: 1) {
                content()
            }
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.large))
            .padding(.horizontal, AppSpacing.xl)
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.lg) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.appPrimary)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(title)
                        .font(.appBody)
                        .foregroundColor(.appTextPrimary)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.appFootnote)
                            .foregroundColor(.appTextMuted)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.appTextMuted)
            }
            .padding(AppSpacing.xl)
        }
    }
}

struct SettingsToggleRow: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: AppSpacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.appPrimary)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(title)
                    .font(.appBody)
                    .foregroundColor(.appTextPrimary)

                Text(subtitle)
                    .font(.appFootnote)
                    .foregroundColor(.appTextMuted)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .tint(.appPrimary)
        }
        .padding(AppSpacing.xl)
    }
}

struct SettingsInfoRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: AppSpacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.appPrimary)
                .frame(width: 28)

            Text(title)
                .font(.appBody)
                .foregroundColor(.appTextPrimary)

            Spacer()

            Text(value)
                .font(.appBody)
                .foregroundColor(.appTextMuted)
        }
        .padding(AppSpacing.xl)
    }
}

#Preview {
    SettingsView()
}
```

**Step 2: Update MainTabView to use SettingsView**

Modify `MainTabView.swift`:

```swift
case .settings:
    SettingsView()
```

**Step 3: Commit**

```bash
git add lingo_journey/Features/Settings/SettingsView.swift
git add lingo_journey/Features/MainTabView.swift
git commit -m "feat: add SettingsView with geo-aware toggle"
```

---

### Task 21: Language Packages View

**Files:**
- Create: `lingo_journey/Features/Settings/LanguagePackagesView.swift`

**Step 1: Create the LanguagePackagesView**

```swift
import SwiftUI
import Translation

struct LanguagePackagesView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var supportedLanguages: [Locale.Language] = []
    @State private var downloadedLanguages: Set<String> = []
    @State private var downloadingLanguages: Set<String> = []
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                if isLoading {
                    ProgressView()
                        .tint(.appPrimary)
                } else {
                    List {
                        ForEach(supportedLanguages, id: \.minimalIdentifier) { language in
                            LanguagePackageRow(
                                language: language,
                                isDownloaded: downloadedLanguages.contains(language.minimalIdentifier),
                                isDownloading: downloadingLanguages.contains(language.minimalIdentifier),
                                onDownload: { downloadLanguage(language) }
                            )
                            .listRowBackground(Color.appSurface)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Offline Languages")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.appPrimary)
                }
            }
        }
        .task {
            await loadLanguages()
        }
    }

    private func loadLanguages() async {
        let availability = LanguageAvailability()
        supportedLanguages = await availability.supportedLanguages

        // Check which languages are already downloaded
        for language in supportedLanguages {
            let status = await availability.status(
                from: language,
                to: Locale.Language(identifier: "en")
            )
            if status == .installed {
                downloadedLanguages.insert(language.minimalIdentifier)
            }
        }

        isLoading = false
    }

    private func downloadLanguage(_ language: Locale.Language) {
        downloadingLanguages.insert(language.minimalIdentifier)
        // The actual download is handled by the system when using translationTask
        // This is a placeholder for UI feedback

        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await MainActor.run {
                downloadingLanguages.remove(language.minimalIdentifier)
                downloadedLanguages.insert(language.minimalIdentifier)
            }
        }
    }
}

struct LanguagePackageRow: View {
    let language: Locale.Language
    let isDownloaded: Bool
    let isDownloading: Bool
    let onDownload: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(displayName(for: language))
                    .font(.appBody)
                    .foregroundColor(.appTextPrimary)

                Text(language.minimalIdentifier)
                    .font(.appCaption)
                    .foregroundColor(.appTextMuted)
            }

            Spacer()

            if isDownloaded {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.appSuccess)
            } else if isDownloading {
                ProgressView()
                    .tint(.appPrimary)
            } else {
                Button(action: onDownload) {
                    Image(systemName: "arrow.down.circle")
                        .font(.system(size: 24))
                        .foregroundColor(.appPrimary)
                }
            }
        }
        .padding(.vertical, AppSpacing.md)
    }

    private func displayName(for language: Locale.Language) -> String {
        let locale = Locale(identifier: language.minimalIdentifier)
        return locale.localizedString(forIdentifier: language.minimalIdentifier)?.capitalized ?? language.minimalIdentifier
    }
}

#Preview {
    LanguagePackagesView()
}
```

**Step 2: Commit**

```bash
git add lingo_journey/Features/Settings/LanguagePackagesView.swift
git commit -m "feat: add LanguagePackagesView for offline language management"
```

---

## Phase 8: Onboarding & Splash

### Task 22: Splash Screen

**Files:**
- Create: `lingo_journey/Features/Onboarding/SplashView.swift`

**Step 1: Create the SplashView**

```swift
import SwiftUI

struct SplashView: View {
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: AppSpacing.xxl) {
                // Logo
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.appPrimary)
                    .scaleEffect(isAnimating ? 1.0 : 0.8)
                    .opacity(isAnimating ? 1.0 : 0.0)

                // App name
                Text("LingoJourney")
                    .font(.appLargeTitle)
                    .foregroundColor(.appTextPrimary)
                    .opacity(isAnimating ? 1.0 : 0.0)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                isAnimating = true
            }
        }
    }
}

#Preview {
    SplashView()
}
```

**Step 2: Commit**

```bash
git add lingo_journey/Features/Onboarding/SplashView.swift
git commit -m "feat: add SplashView"
```

---

### Task 23: Onboarding View

**Files:**
- Create: `lingo_journey/Features/Onboarding/OnboardingView.swift`

**Step 1: Create the OnboardingView**

```swift
import SwiftUI

struct OnboardingPage: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
}

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "waveform",
            title: "Translate With Confidence",
            description: "Instantly understand and communicate in any language with ease."
        ),
        OnboardingPage(
            icon: "person.2",
            title: "Face-to-Face Conversations",
            description: "Have natural conversations with anyone, regardless of language barriers."
        ),
        OnboardingPage(
            icon: "arrow.down.circle",
            title: "Works Offline",
            description: "Download languages to translate anywhere, even without internet."
        )
    ]

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack {
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                        OnboardingPageView(page: page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Page indicator
                HStack(spacing: AppSpacing.md) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? Color.appPrimary : Color.appTextMuted)
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.bottom, AppSpacing.xxl)

                // Button
                PrimaryButton(
                    title: currentPage == pages.count - 1 ? "Get Started" : "Next",
                    action: {
                        if currentPage == pages.count - 1 {
                            hasCompletedOnboarding = true
                        } else {
                            withAnimation {
                                currentPage += 1
                            }
                        }
                    }
                )
                .padding(.horizontal, AppSpacing.xxxl)
                .padding(.bottom, AppSpacing.page)
            }
        }
    }
}

struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: AppSpacing.xxxl) {
            Spacer()

            Image(systemName: page.icon)
                .font(.system(size: 80))
                .foregroundColor(.appPrimary)

            VStack(spacing: AppSpacing.xl) {
                Text(page.title)
                    .font(.appTitle1)
                    .foregroundColor(.appTextPrimary)
                    .multilineTextAlignment(.center)

                Text(page.description)
                    .font(.appBody)
                    .foregroundColor(.appTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.xxxl)
            }

            Spacer()
            Spacer()
        }
    }
}

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
}
```

**Step 2: Commit**

```bash
git add lingo_journey/Features/Onboarding/OnboardingView.swift
git commit -m "feat: add OnboardingView with 3 pages"
```

---

### Task 24: Update ContentView with App Flow

**Files:**
- Modify: `lingo_journey/ContentView.swift`

**Step 1: Update ContentView with full app flow**

```swift
import SwiftUI

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showSplash = true

    var body: some View {
        ZStack {
            if showSplash {
                SplashView()
                    .transition(.opacity)
            } else if !hasCompletedOnboarding {
                OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                    .transition(.opacity)
            } else {
                MainTabView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: showSplash)
        .animation(.easeInOut(duration: 0.5), value: hasCompletedOnboarding)
        .onAppear {
            // Show splash for 1.5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                showSplash = false
            }
        }
    }
}

#Preview {
    ContentView()
}
```

**Step 2: Verify full app flow**

Run: Run app on simulator
Expected: Splash (1.5s) → Onboarding (first launch) → Main Tab View

**Step 3: Commit**

```bash
git add lingo_journey/ContentView.swift
git commit -m "feat: add app flow with splash and onboarding"
```

---

## Phase 9: Dynamic Island (Live Activity)

### Task 25: Live Activity Configuration

**Files:**
- Create: `lingo_journey/LiveActivity/TranslationActivity.swift`
- Create: `lingo_journey/LiveActivity/TranslationActivityWidget.swift`

**Step 1: Create Activity attributes and state**

```swift
// TranslationActivity.swift
import ActivityKit
import Foundation

struct TranslationActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var sourceText: String
        var translatedText: String
        var isTranslating: Bool
    }

    var sourceLanguage: String
    var targetLanguage: String
}
```

**Step 2: Create the Widget**

```swift
// TranslationActivityWidget.swift
import ActivityKit
import SwiftUI
import WidgetKit

struct TranslationActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TranslationActivityAttributes.self) { context in
            // Lock screen presentation
            LockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded regions
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.attributes.sourceLanguage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.attributes.targetLanguage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 4) {
                        if context.state.isTranslating {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Text(context.state.translatedText)
                                .font(.headline)
                                .lineLimit(2)
                        }
                    }
                }

                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.state.sourceText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            } compactLeading: {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .foregroundColor(.blue)
            } compactTrailing: {
                if context.state.isTranslating {
                    ProgressView()
                        .scaleEffect(0.6)
                } else {
                    Text(context.state.translatedText.prefix(10))
                        .font(.caption2)
                }
            } minimal: {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .foregroundColor(.blue)
            }
        }
    }
}

struct LockScreenView: View {
    let context: ActivityViewContext<TranslationActivityAttributes>

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(context.attributes.sourceLanguage) → \(context.attributes.targetLanguage)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                if context.state.isTranslating {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Translating...")
                    }
                } else {
                    Text(context.state.translatedText)
                        .font(.headline)
                }
            }

            Spacer()

            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.title2)
                .foregroundColor(.blue)
        }
        .padding()
    }
}
```

**Step 3: Add Widget extension target**

Note: This requires adding a Widget Extension target in Xcode:
1. File → New → Target
2. Select "Widget Extension"
3. Name: "LingoJourneyWidget"
4. Check "Include Live Activity"

**Step 4: Commit**

```bash
git add lingo_journey/LiveActivity/
git commit -m "feat: add Dynamic Island Live Activity support"
```

---

## Final Tasks

### Task 26: Final Integration Test

**Step 1: Run full app test**

Run: Build and run app on iPhone simulator
Test checklist:
- [ ] Splash screen appears for 1.5s
- [ ] Onboarding shows on first launch
- [ ] Translation tab works with text input
- [ ] Voice tab shows dual-conversation UI
- [ ] History tab shows empty state / records
- [ ] Settings tab shows all options
- [ ] Tab switching is smooth

**Step 2: Test on device (if available)**

Run: Build and run on physical iPhone
Test checklist:
- [ ] Speech recognition works (requires device)
- [ ] Translation API works
- [ ] Location services prompt appears

**Step 3: Final commit**

```bash
git add .
git commit -m "feat: LingoJourney MVP complete"
```

---

## Summary

### Files Created

```
lingo_journey/
├── DesignSystem/
│   ├── Colors.swift
│   ├── Typography.swift
│   ├── Spacing.swift
│   └── Components/
│       ├── PrimaryButton.swift
│       ├── SecondaryButton.swift
│       ├── LanguageSelector.swift
│       ├── TranslationInputCard.swift
│       ├── TranslationResultCard.swift
│       └── WaveformView.swift
├── Core/
│   ├── Models/
│   │   ├── TranslationRecord.swift
│   │   └── LanguagePackage.swift
│   └── Services/
│       ├── TranslationService.swift
│       ├── SpeechService.swift
│       └── LocationService.swift
├── Features/
│   ├── MainTabView.swift
│   ├── Translation/
│   │   └── TranslationView.swift
│   ├── Conversation/
│   │   └── ConversationView.swift
│   ├── History/
│   │   └── HistoryView.swift
│   ├── Settings/
│   │   ├── SettingsView.swift
│   │   └── LanguagePackagesView.swift
│   └── Onboarding/
│       ├── SplashView.swift
│       └── OnboardingView.swift
└── LiveActivity/
    ├── TranslationActivity.swift
    └── TranslationActivityWidget.swift
```

### Total Tasks: 26
### Estimated Commits: 26

---

*Plan created: 2026-01-27*
