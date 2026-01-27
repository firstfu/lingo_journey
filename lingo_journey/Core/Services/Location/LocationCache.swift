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
