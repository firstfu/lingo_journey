# LocationService 重構設計

日期：2026-01-27

## 背景

iOS 26.0 棄用了 `CLGeocoder` 和 `reverseGeocodeLocation`，需要改用 MapKit 的 `MKReverseGeocodingRequest`。藉此機會進行全面更新。

## 需求

- 修復 iOS 26.0 deprecation 警告
- 改用 async/await 現代風格
- 靜默錯誤處理 + 內部狀態記錄
- 持久化快取 + 背景更新

## 架構設計

### 檔案結構

```
Core/Services/Location/
├── LocationService.swift      # 協調者，對外唯一介面
├── LocationProvider.swift     # 處理 CLLocationManager，取得 GPS 座標
├── GeocodingService.swift     # 用 MKReverseGeocodingRequest 轉換座標→國家
└── LocationCache.swift        # UserDefaults 快取管理
```

### 各組件職責

| 組件 | 職責 | 對外 API |
|------|------|----------|
| `LocationService` | 協調者，對外唯一介面 | `initialize()`, `refresh()` |
| `LocationProvider` | 取得 GPS 座標 | `requestLocation() async throws → CLLocation` |
| `GeocodingService` | 座標轉國家代碼 | `reverseGeocode(_:) async throws → String` |
| `LocationCache` | 快取讀寫 | `save(countryCode:)`, `load() → String?` |

## 資料流

```
App 啟動
    ↓
LocationService.initialize()
    ↓
┌─────────────────────────────────────┐
│ 1. 立即從 Cache 讀取              │ → 馬上更新 UI
│ 2. 背景：請求位置授權              │
│ 3. 背景：取得 GPS 座標            │
│ 4. 背景：反向地理編碼              │
│ 5. 比對結果，若不同則更新 Cache + UI │
└─────────────────────────────────────┘
```

## 狀態管理

```swift
enum LocationStatus {
    case unknown          // 尚未偵測
    case cached(String)   // 使用快取中的國家代碼
    case current(String)  // 已取得最新國家代碼
    case denied           // 用戶拒絕授權
    case failed           // 偵測失敗（靜默處理）
}
```

## 錯誤處理

| 層級 | 可能錯誤 | 處理方式 |
|------|----------|----------|
| `LocationProvider` | 授權被拒、定位失敗 | throw error，由上層處理 |
| `GeocodingService` | 網路錯誤、無結果 | throw error，由上層處理 |
| `LocationService` | 捕獲所有錯誤 | 更新 status，靜默處理 |

原則：內部錯誤記錄到 status，不打擾用戶。使用快取值（如果有）或保持 nil（讓用戶手動選語言）。

## 快取策略

```swift
struct CachedLocation: Codable {
    let countryCode: String
    let timestamp: Date
}
```

- 快取位置：UserDefaults 的 `cachedLocation` key
- 快取時機：每次成功取得國家代碼後
- 讀取時機：App 啟動時立即讀取
- 過期策略：不設過期，永遠優先顯示快取，背景更新

## API 介面

### LocationProvider.swift

```swift
final class LocationProvider: NSObject, CLLocationManagerDelegate {
    func requestAuthorization() async -> CLAuthorizationStatus
    func requestLocation() async throws -> CLLocation
}
```

### GeocodingService.swift

```swift
import MapKit

final class GeocodingService {
    func reverseGeocode(_ location: CLLocation) async throws -> String
}
```

### LocationCache.swift

```swift
final class LocationCache {
    func save(countryCode: String)
    func load() -> String?
    func clear()
}
```

### LocationService.swift

```swift
@Observable
final class LocationService {
    var status: LocationStatus
    var countryCode: String?
    var suggestedLanguage: Locale.Language?

    func initialize() async
    func refresh() async
}
```

## 改動範圍

1. 刪除舊的 `Core/Services/LocationService.swift`
2. 建立 `Core/Services/Location/` 資料夾與 4 個新檔案
3. 更新 App 中引用 `LocationService` 的地方
