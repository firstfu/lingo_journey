import Foundation
import CoreLocation
import MapKit

enum GeocodingError: Error {
    case requestFailed
    case noResult
    case noCountryCode
}

final class GeocodingService {
    func reverseGeocode(_ location: CLLocation) async throws -> String {
        guard let request = MKReverseGeocodingRequest(location: location) else {
            throw GeocodingError.requestFailed
        }

        let mapItems = try await request.mapItems

        guard let mapItem = mapItems.first else {
            throw GeocodingError.noResult
        }

        // 從 MKMapItem 的 placemark 獲取國家代碼
        guard let countryCode = mapItem.placemark.countryCode else {
            throw GeocodingError.noCountryCode
        }

        return countryCode
    }
}
