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
