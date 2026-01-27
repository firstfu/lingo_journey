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
