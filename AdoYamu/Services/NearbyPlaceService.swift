import Foundation
import MapKit

@MainActor protocol NearbyPlaceSearching {
    func search(_ query: NearbyQuery) async throws -> [Destination]
    func invalidateCache(for query: NearbyQuery)
}

extension NearbyPlaceSearching { func invalidateCache(for query: NearbyQuery) {} }

@MainActor final class AppleNearbyPlaceService: NearbyPlaceSearching {
    private var cache: [String: (Date, [Destination])] = [:]
    func invalidateCache(for query: NearbyQuery) { cache.removeValue(forKey: query.cacheKey) }
    func search(_ query: NearbyQuery) async throws -> [Destination] {
        if let cached = cache[query.cacheKey], Date.now.timeIntervalSince(cached.0) < 900 { return cached.1 }
        let request = MKLocalPointsOfInterestRequest(center: query.origin.mapCoordinate, radius: Double(query.radiusKilometers) * 1_000)
        request.pointOfInterestFilter = MKPointOfInterestFilter(including: Self.categories(for: query.moods))
        var searches: [MKLocalSearch] = []
        let wantsTemples = query.personalization.experiences.contains(.temple)
        if !wantsTemples || query.personalization.experiences.count > 1 { searches.append(MKLocalSearch(request: request)) }
        if wantsTemples {
            let templeRequest = MKLocalSearch.Request()
            templeRequest.naturalLanguageQuery = "temple"
            templeRequest.region = MKCoordinateRegion(center: query.origin.mapCoordinate, latitudinalMeters: Double(query.radiusKilometers) * 2_000, longitudinalMeters: Double(query.radiusKilometers) * 2_000)
            templeRequest.resultTypes = .pointOfInterest
            searches.append(MKLocalSearch(request: templeRequest))
        }
        var items: [MKMapItem] = [], succeeded = false
        var serviceError: Error = NearbyServiceError.unavailable
        for search in searches {
            do {
                let response = try await withTaskCancellationHandler {
                    try await search.start()
                } onCancel: { Task { @MainActor in search.cancel() } }
                items += response.mapItems; succeeded = true
            } catch { try Task.checkCancellation(); serviceError = error }
        }
        guard succeeded else { throw serviceError }
        try Task.checkCancellation()
        let places = NearbyPlaceDeduplicator.unique(items.compactMap(Self.destination))
            .filter(query.contains)
            .sorted { lhs, rhs in
                let leftScore = query.personalization.score(lhs), rightScore = query.personalization.score(rhs)
                if leftScore != rightScore { return leftScore > rightScore }
                let left = lhs.coordinate.map { query.origin.kilometers(to: $0) } ?? .infinity
                let right = rhs.coordinate.map { query.origin.kilometers(to: $0) } ?? .infinity
                return left < right
            }
        let limited = Array(places.prefix(12))
        cache[query.cacheKey] = (.now, limited)
        return limited
    }
    private static func categories(for moods: Set<Mood>) -> [MKPointOfInterestCategory] {
        let selected = moods.isEmpty ? Set(Mood.allCases) : moods
        var values: Set<MKPointOfInterestCategory> = []
        for mood in selected {
            switch mood {
            case .chill: values.formUnion([.park, .beach, .cafe, .nationalPark])
            case .adventure: values.formUnion([.park, .nationalPark, .campground, .museum, .zoo])
            case .food: values.formUnion([.restaurant, .cafe, .bakery])
            case .romantic: values.formUnion([.park, .beach, .restaurant, .cafe])
            }
        }
        return Array(values)
    }
    static func destination(_ item: MKMapItem) -> Destination? {
        guard let name = item.name?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty else { return nil }
        if let country = item.placemark.isoCountryCode, country.uppercased() != "LK" { return nil }
        let point = item.placemark.coordinate
        let coordinate = Coordinate(latitude: point.latitude, longitude: point.longitude)
        guard coordinate.isInSriLanka else { return nil }
        let category: PlaceCategory
        let moods: Set<Mood>
        if Destination.isTempleName(name) { category = .culture; moods = [.chill, .adventure] }
        else { switch item.pointOfInterestCategory {
        case .restaurant, .cafe, .bakery:
            category = .food; moods = [.food, .chill, .romantic]
        case .beach:
            category = .beaches; moods = [.chill, .romantic]
        case .museum:
            category = .culture; moods = [.adventure]
        default:
            category = .nature; moods = [.chill, .adventure, .romantic]
        } }
        let area = item.placemark.locality ?? item.placemark.subLocality ?? "Sri Lanka"
        let district = SriLankanDistrict.canonical(item.placemark.subAdministrativeArea) ?? ""
        let normalizedName = name.lowercased().folding(options: [.diacriticInsensitive], locale: Locale(identifier: "en"))
        // Recent suggestion IDs are comma-separated in the existing journal.
        let encodedName = normalizedName.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? normalizedName.replacingOccurrences(of: ",", with: " ")
        let id = "apple|\(encodedName)|\(Int((point.latitude * 10_000).rounded()))|\(Int((point.longitude * 10_000).rounded()))"
        var components = URLComponents(string: "https://maps.apple.com/")
        components?.queryItems = [URLQueryItem(name: "ll", value: "\(point.latitude),\(point.longitude)"), URLQueryItem(name: "q", value: name)]
        return Destination(id: id, name: name, district: district, locality: area, category: category, moods: moods,
                           summary: "Discovered near your starting point on Apple Maps. Check the venue’s website or contact them for access, admission prices and opening hours. Plan your own visit length below.",
                           coordinate: coordinate, minutes: 60, budget: .easy, image: "", tags: [category.rawValue, "Online discovery"],
                           source: .appleMaps, sourceURL: components?.url, website: item.url, phone: item.phoneNumber, fetchedAt: .now)
    }
}

enum NearbyPlaceDeduplicator {
    static func unique(_ places: [Destination]) -> [Destination] {
        var accepted: [Destination] = []
        for place in places {
            let normalized = place.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let duplicate = accepted.contains { existing in
                if place.id == existing.id { return true }
                guard normalized == existing.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
                      let left = place.coordinate, let right = existing.coordinate else { return false }
                return left.kilometers(to: right) < 0.15
            }
            if !duplicate { accepted.append(place) }
        }
        return accepted
    }
}

enum SriLankanDistrict {
    static let names = ["Colombo", "Gampaha", "Kalutara", "Kandy", "Matale", "Nuwara Eliya", "Galle", "Matara", "Hambantota", "Jaffna", "Kilinochchi", "Mannar", "Mullaitivu", "Vavuniya", "Puttalam", "Kurunegala", "Anuradhapura", "Polonnaruwa", "Badulla", "Monaragala", "Ratnapura", "Kegalle", "Batticaloa", "Ampara", "Trincomalee"]
    static func canonical(_ supplied: String?) -> String? {
        guard let supplied else { return nil }
        let normalized = supplied.replacingOccurrences(of: " District", with: "", options: .caseInsensitive).trimmingCharacters(in: .whitespacesAndNewlines)
        return names.first { $0.caseInsensitiveCompare(normalized) == .orderedSame }
    }
}
