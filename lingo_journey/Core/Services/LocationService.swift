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
