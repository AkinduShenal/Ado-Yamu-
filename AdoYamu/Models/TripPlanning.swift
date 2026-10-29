import Foundation
import SwiftData

enum TravelMode: String, CaseIterable, Codable, Identifiable {
    case walking = "Walking", transit = "Bus / train", motorbike = "Motorbike", car = "Car"
    var id: String { rawValue }
    var symbol: String { switch self { case .walking: "figure.walk"; case .transit: "bus.fill"; case .motorbike: "motorcycle.fill"; case .car: "car.fill" } }
}

struct TripPlan: Codable, Equatable {
    var totalBudget: Int? = 1_000
    var availableMinutes = 180
    var visitMinutes = 60
    var travelMode: TravelMode = .walking
    var transportRupees: Int? = nil
    var foodAndExtrasRupees: Int? = 0
    var radiusKilometers = 5
    var personalization: PersonalizationPreferences? = nil

    var effectiveTransportRupees: Int? { travelMode == .walking ? 0 : transportRupees }
    var validationMessage: String? {
        guard let totalBudget, (1...1_000_000).contains(totalBudget) else { return "Enter a total budget between Rs. 1 and Rs. 1,000,000." }
        guard (1...1_440).contains(availableMinutes), visitMinutes > 0, visitMinutes <= availableMinutes else { return "Your visit time must fit within the total time available. Return travel will also be checked." }
        guard (1...30).contains(radiusKilometers) else { return "Choose a search radius between 1 and 30 km." }
        guard let foodAndExtrasRupees, (0...1_000_000).contains(foodAndExtrasRupees) else { return "Enter your food and extras allowance, including 0 if you don't plan to spend on these." }
        if let transportRupees, !(0...1_000_000).contains(transportRupees) { return "Enter a valid return-transport estimate." }
        return nil
    }
}

struct NearbyQuery: Hashable {
    var origin: Coordinate
    var radiusKilometers: Int
    var moods: Set<Mood>
    var travelMode: TravelMode
    var personalization: PersonalizationContext = .none
    var cacheKey: String {
        let lat = (origin.latitude * 1_000).rounded() / 1_000
        let lon = (origin.longitude * 1_000).rounded() / 1_000
        return "\(lat)|\(lon)|\(radiusKilometers)|\(moods.map(\.rawValue).sorted().joined(separator: ","))|\(travelMode.rawValue)|\(personalization.experiences.map(\.rawValue).sorted().joined(separator: ","))"
    }
    func contains(_ place: Destination) -> Bool {
        guard let coordinate = place.coordinate, coordinate.isInSriLanka else { return false }
        return origin.kilometers(to: coordinate) <= Double(radiusKilometers) &&
            (moods.isEmpty || !place.moods.isDisjoint(with: moods)) && personalization.accepts(place)
    }
    func estimateKey(for id: String) -> String {
        // Manual journey times apply only to this origin, destination and travel mode.
        "\(id)|\(origin.latitude)|\(origin.longitude)|\(travelMode.rawValue)"
    }
}

extension Coordinate {
    var isInSriLanka: Bool { (5.8...10).contains(latitude) && (79.4...82).contains(longitude) }
}

struct PlaceEstimate: Codable, Equatable {
    var entryAndActivityRupees: Int?
    var manualRoundTripMinutes: Int?
    var updatedAt: Date = .now
}

struct JourneyEstimate: Codable, Equatable {
    let roundTripSeconds: Double
    let roundTripMeters: Double
    let source: String
    let checkedAt: Date
    var minutes: Int? {
        guard roundTripSeconds.isFinite, roundTripSeconds >= 0, roundTripSeconds < 86_400 * 7 else { return nil }
        return Int(ceil(roundTripSeconds / 60))
    }
}

enum TripFit: String {
    case fits = "Fits your estimates"
    case needsInformation = "Check costs / time"
    case overBudget = "Over your budget"
    case overTime = "Needs more time"
}

struct TripAssessment: Identifiable {
    let place: Destination
    let plan: TripPlan
    let query: NearbyQuery
    let estimate: PlaceEstimate?
    let journey: JourneyEstimate?
    var id: String { place.id }
    var transportCost: Int? { plan.effectiveTransportRupees }
    var entryCost: Int? { estimate?.entryAndActivityRupees }
    var travelMinutes: Int? {
        if let manual = estimate?.manualRoundTripMinutes { return (0...1_440).contains(manual) ? manual : nil }
        return journey?.minutes
    }
    var totalCost: Int? {
        guard let transportCost, let entryCost, let extras = plan.foodAndExtrasRupees,
              [transportCost, entryCost, extras].allSatisfy({ (0...1_000_000).contains($0) }) else { return nil }
        return transportCost + entryCost + extras
    }
    var totalMinutes: Int? { travelMinutes.map { $0 + plan.visitMinutes } }
    var missingInformation: [String] {
        var items: [String] = []
        if entryCost == nil { items.append("entry / activity cost") }
        if transportCost == nil { items.append("return transport cost") }
        if plan.foodAndExtrasRupees == nil { items.append("food / extras allowance") }
        if travelMinutes == nil { items.append("return journey time") }
        return items
    }
    var fit: TripFit {
        guard plan.validationMessage == nil, query.contains(place) else { return .needsInformation }
        // Known failures take priority, even when another component is still unknown.
        let knownCost = max(0, transportCost ?? 0) + max(0, entryCost ?? 0) + max(0, plan.foodAndExtrasRupees ?? 0)
        if knownCost > (plan.totalBudget ?? 0) { return .overBudget }
        if let minutes = totalMinutes, minutes > plan.availableMinutes { return .overTime }
        guard totalCost != nil, totalMinutes != nil else { return .needsInformation }
        return .fits
    }
    var notes: String {
        let total = totalCost.map { "Rs. \($0)" } ?? "Cost incomplete"
        let time = totalMinutes.map { "\($0) min including return travel" } ?? "Journey time not available"
        return "\(fit.rawValue) · \(plan.travelMode.rawValue) · \(total) · \(time). Costs are your estimates, not verified venue prices."
    }
}

@Model final class DiscoveryJournal {
    @Attribute(.unique) var key: String
    var planData: Data?
    var placesData: Data?
    var estimatesData: Data?
    init() { key = "nearby-planning" }
}
