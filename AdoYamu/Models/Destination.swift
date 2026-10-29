import Foundation
import CoreLocation

enum Mood: String, CaseIterable, Codable, Identifiable {
    case chill = "Chill", adventure = "Adventure", food = "Food", romantic = "Romantic"
    var id: String { rawValue }
    var symbol: String { switch self { case .chill: "cup.and.saucer.fill"; case .adventure: "mountain.2.fill"; case .food: "fork.knife"; case .romantic: "heart.fill" } }
    var subtitle: String { switch self { case .chill: "Relax & unwind"; case .adventure: "Explore nature"; case .food: "Taste local gems"; case .romantic: "Special moments" } }
}

enum PlaceCategory: String, CaseIterable, Codable {
    case hiking = "Hiking", waterfalls = "Waterfalls", beaches = "Beaches", food = "Food", nature = "Nature", culture = "Culture"
    var symbol: String { switch self { case .hiking: "mountain.2.fill"; case .waterfalls: "water.waves"; case .beaches: "beach.umbrella.fill"; case .food: "fork.knife"; case .nature: "leaf.fill"; case .culture: "building.columns.fill" } }
}

enum BudgetTier: Int, CaseIterable, Codable, Identifiable {
    case pocket = 0, easy = 1, flexible = 2
    var id: Int { rawValue }
    var label: String { switch self { case .pocket: "Rs. 500"; case .easy: "Rs. 1,000"; case .flexible: "Rs. 3,000+" } }
}

enum AdventureDuration: Int, CaseIterable, Codable, Identifiable {
    case quick = 60, unhurried = 180, halfDay = 300
    var id: Int { rawValue }
    var label: String { switch self { case .quick: "1 hour"; case .unhurried: "2–3 hours"; case .halfDay: "Half day" } }
}

struct Coordinate: Hashable, Codable {
    let latitude: Double
    let longitude: Double
    var location: CLLocation { CLLocation(latitude: latitude, longitude: longitude) }
    var mapCoordinate: CLLocationCoordinate2D { .init(latitude: latitude, longitude: longitude) }
    func kilometers(to other: Coordinate) -> Double { location.distance(from: other.location) / 1_000 }
}

struct Destination: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let district: String
    let locality: String
    let category: PlaceCategory
    let moods: Set<Mood>
    let summary: String
    let coordinate: Coordinate?
    let minutes: Int
    let budget: BudgetTier
    var image: String
    let tags: [String]
    var source: PlaceSource = .bundled
    var sourceURL: URL? = nil
    var website: URL? = nil
    var phone: String? = nil
    var fetchedAt: Date? = nil
    var photo: PlacePhoto? = nil
    var experienceTags: [PlaceExperience]? = nil
    var locationDescription: String {
        let parts = [locality, district].filter { !$0.isEmpty }
        return parts.isEmpty ? "Sri Lanka" : parts.enumerated().filter { index, value in !parts.prefix(index).contains(value) }.map(\.element).joined(separator: ", ")
    }
    var durationLabel: String { minutes <= 60 ? "About 1 hour" : minutes <= 180 ? "2–3 hours" : "Half day" }
    var shareText: String { "Ado Yamu! Let’s explore \(name), \(district), Sri Lanka.\n\(summary)" }
}

struct PlacePhoto: Hashable, Codable {
    let url: URL
    let sourceURL: URL
    let author: String
    let license: String
    let licenseURL: URL
    var credit: String { "\(author) · \(license) · Wikimedia Commons" }
}

enum BaseCity: String, CaseIterable, Identifiable {
    case anywhere = "Anywhere in Sri Lanka", colombo = "Colombo", kandy = "Kandy", ella = "Ella", galle = "Galle", sigiriya = "Sigiriya", matara = "Matara"
    var id: String { rawValue }
    var coordinate: Coordinate? {
        switch self {
        case .anywhere: nil
        case .colombo: .init(latitude: 6.9271, longitude: 79.8612)
        case .kandy: .init(latitude: 7.2906, longitude: 80.6337)
        case .ella: .init(latitude: 6.8667, longitude: 81.0466)
        case .galle: .init(latitude: 6.0329, longitude: 80.2168)
        case .sigiriya: .init(latitude: 7.9570, longitude: 80.7603)
        case .matara: .init(latitude: 5.9549, longitude: 80.5550)
        }
    }
}

enum PlaceSource: String, Codable {
    case bundled, appleMaps, wikipedia
    var label: String { switch self { case .bundled: "Bundled place"; case .appleMaps: "Apple Maps"; case .wikipedia: "Wikipedia" } }
}
