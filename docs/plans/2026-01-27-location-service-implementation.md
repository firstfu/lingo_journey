# LocationService 重構實作計劃

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 將 LocationService 重構為模組化架構，修復 iOS 26.0 deprecation 警告，改用 async/await 風格。

**Architecture:** 拆分成四個組件：LocationCache（快取）、LocationProvider（GPS）、GeocodingService（地理編碼）、LocationService（協調者）。

**Tech Stack:** Swift, CoreLocation, MapKit (MKReverseGeocodingRequest), @Observable macro

---

### Task 1: 建立 Location 資料夾結構

**Files:**
- Create: `lingo_journey/Core/Services/Location/` (directory)

**Step 1: 建立資料夾**

Run: `mkdir -p lingo_journey/Core/Services/Location`

**Step 2: 確認資料夾建立成功**

Run: `ls -la lingo_journey/Core/Services/`
Expected: 看到 `Location` 資料夾

---

### Task 2: 建立 LocationCache.swift

**Files:**
- Create: `lingo_journey/Core/Services/Location/LocationCache.swift`

**Step 1: 建立 LocationCache**

```swift
import Foundation

struct CachedLocation: Codable {
    let countryCode: String
    let timestamp: Date
}

final class LocationCache {
    private let key = "cachedLocation"
    private let defaults = UserDefaults.standard

    func save(countryCode: String) {
        let cached = CachedLocation(countryCode: countryCode, timestamp: Date())
        if let data = try? JSONEncoder().encode(cached) {
            defaults.set(data, forKey: key)
        }
    }

    func load() -> String? {
        guard let data = defaults.data(forKey: key),
              let cached = try? JSONDecoder().decode(CachedLocation.self, from: data) else {
            return nil
        }
        return cached.countryCode
    }

    func clear() {
        defaults.removeObject(forKey: key)
    }
}
```

**Step 2: 確認檔案建立**

Run: `ls lingo_journey/Core/Services/Location/`
Expected: 看到 `LocationCache.swift`

---

### Task 3: 建立 LocationProvider.swift

**Files:**
- Create: `lingo_journey/Core/Services/Location/LocationProvider.swift`

**Step 1: 建立 LocationProvider**

```swift
import Foundation
import CoreLocation

enum LocationProviderError: Error {
    case authorizationDenied
    case authorizationRestricted
    case locationUnavailable
    case timeout
}

final class LocationProvider: NSObject {
    private let locationManager = CLLocationManager()
    private var locationContinuation: CheckedContinuation<CLLocation, Error>?
    private var authorizationContinuation: CheckedContinuation<CLAuthorizationStatus, Never>?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func requestAuthorization() async -> CLAuthorizationStatus {
        let currentStatus = locationManager.authorizationStatus

        if currentStatus != .notDetermined {
            return currentStatus
        }

        return await withCheckedContinuation { continuation in
            authorizationContinuation = continuation
            locationManager.requestWhenInUseAuthorization()
        }
    }

    func requestLocation() async throws -> CLLocation {
        let status = await requestAuthorization()

        guard status == .authorizedWhenInUse || status == .authorizedAlways else {
            if status == .restricted {
                throw LocationProviderError.authorizationRestricted
            }
            throw LocationProviderError.authorizationDenied
        }

        return try await withCheckedThrowingContinuation { continuation in
            locationContinuation = continuation
            locationManager.requestLocation()
        }
    }
}

extension LocationProvider: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            locationContinuation?.resume(throwing: LocationProviderError.locationUnavailable)
            locationContinuation = nil
            return
        }
        locationContinuation?.resume(returning: location)
        locationContinuation = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationContinuation?.resume(throwing: error)
        locationContinuation = nil
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        if status != .notDetermined {
            authorizationContinuation?.resume(returning: status)
            authorizationContinuation = nil
        }
    }
}
```

**Step 2: 確認檔案建立**

Run: `ls lingo_journey/Core/Services/Location/`
Expected: 看到 `LocationCache.swift` 和 `LocationProvider.swift`

---

### Task 4: 建立 GeocodingService.swift

**Files:**
- Create: `lingo_journey/Core/Services/Location/GeocodingService.swift`

**Step 1: 建立 GeocodingService**

```swift
import Foundation
import CoreLocation
import MapKit

enum GeocodingError: Error {
    case noResult
    case noCountryCode
}

final class GeocodingService {
    func reverseGeocode(_ location: CLLocation) async throws -> String {
        let request = MKReverseGeocodingRequest(coordinate: location.coordinate)
        let response = try await request.start()

        guard let result = response.results.first else {
            throw GeocodingError.noResult
        }

        guard let countryCode = result.isoCountryCode else {
            throw GeocodingError.noCountryCode
        }

        return countryCode
    }
}
```

**Step 2: 確認檔案建立**

Run: `ls lingo_journey/Core/Services/Location/`
Expected: 看到三個檔案

---

### Task 5: 建立新的 LocationService.swift

**Files:**
- Create: `lingo_journey/Core/Services/Location/LocationService.swift`

**Step 1: 建立 LocationService**

```swift
import Foundation
import CoreLocation

enum LocationStatus: Equatable {
    case unknown
    case cached(String)
    case current(String)
    case denied
    case failed
}

@Observable
final class LocationService {
    var status: LocationStatus = .unknown
    var countryCode: String?
    var suggestedLanguage: Locale.Language?

    private let provider = LocationProvider()
    private let geocoding = GeocodingService()
    private let cache = LocationCache()

    private let countryLanguageMap: [String: String] = [
        "JP": "ja",
        "KR": "ko",
        "CN": "zh-Hans",
        "TW": "zh-Hant",
        "TH": "th",
        "VN": "vi",
        "FR": "fr",
        "DE": "de",
        "ES": "es",
        "IT": "it",
        "PT": "pt",
        "US": "en",
        "GB": "en",
        "AU": "en",
    ]

    func initialize() async {
        // 1. 立即從快取讀取
        if let cachedCode = cache.load() {
            countryCode = cachedCode
            suggestedLanguage = languageFor(countryCode: cachedCode)
            status = .cached(cachedCode)
        }

        // 2. 背景更新
        await refresh()
    }

    func refresh() async {
        do {
            let location = try await provider.requestLocation()
            let newCountryCode = try await geocoding.reverseGeocode(location)

            // 更新快取和狀態
            cache.save(countryCode: newCountryCode)
            countryCode = newCountryCode
            suggestedLanguage = languageFor(countryCode: newCountryCode)
            status = .current(newCountryCode)
        } catch let error as LocationProviderError {
            switch error {
            case .authorizationDenied, .authorizationRestricted:
                status = .denied
            default:
                status = .failed
            }
        } catch {
            status = .failed
        }
    }

    func requestAuthorization() async -> CLAuthorizationStatus {
        await provider.requestAuthorization()
    }

    private func languageFor(countryCode: String) -> Locale.Language? {
        guard let languageCode = countryLanguageMap[countryCode] else {
            return nil
        }
        return Locale.Language(identifier: languageCode)
    }
}
```

**Step 2: 確認檔案建立**

Run: `ls lingo_journey/Core/Services/Location/`
Expected: 看到四個檔案

---

### Task 6: 更新 SettingsView.swift

**Files:**
- Modify: `lingo_journey/Features/Settings/SettingsView.swift`

**Step 1: 更新 LocationService 使用方式**

將第 4 行：
```swift
@State private var locationService = LocationService()
```

改為：
```swift
@State private var locationService = LocationService()
```
（類別名稱不變，但引用的是新的 LocationService）

將第 38 行的 `currentCountryCode` 改為 `countryCode`：
```swift
if let countryCode = locationService.countryCode {
```

將第 69-75 行的 `.onChange` 改為：
```swift
.onChange(of: isGeoAwareEnabled) { _, enabled in
    if enabled {
        Task {
            _ = await locationService.requestAuthorization()
            await locationService.refresh()
        }
    }
}
.task {
    if isGeoAwareEnabled {
        await locationService.initialize()
    }
}
```

---

### Task 7: 刪除舊的 LocationService.swift

**Files:**
- Delete: `lingo_journey/Core/Services/LocationService.swift`

**Step 1: 刪除舊檔案**

Run: `rm lingo_journey/Core/Services/LocationService.swift`

**Step 2: 確認刪除成功**

Run: `ls lingo_journey/Core/Services/`
Expected: 看到 `Location/` 資料夾，不再有 `LocationService.swift`

---

### Task 8: 編譯驗證

**Step 1: 嘗試編譯專案**

Run: `cd /Users/firstfu/Desktop/lingo_journey && xcodebuild -scheme lingo_journey -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | head -50`

Expected: BUILD SUCCEEDED 或可以看到編譯進度

---

## 改動摘要

| 操作 | 檔案 |
|------|------|
| 建立 | `Core/Services/Location/LocationCache.swift` |
| 建立 | `Core/Services/Location/LocationProvider.swift` |
| 建立 | `Core/Services/Location/GeocodingService.swift` |
| 建立 | `Core/Services/Location/LocationService.swift` |
| 修改 | `Features/Settings/SettingsView.swift` |
| 刪除 | `Core/Services/LocationService.swift` |
