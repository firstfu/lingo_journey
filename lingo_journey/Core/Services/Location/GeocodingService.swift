import Foundation
import CoreLocation
import MapKit

enum GeocodingError: Error {
    case noResult
    case noCountryCode
}

final class GeocodingService {
    func reverseGeocode(_ location: CLLocation) async throws -> String {
        let request = MKReverseGeocodingRequest(location)
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
