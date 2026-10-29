import Foundation

@MainActor enum DiscoveryServices {
    static func makeModel() -> NearbyPlanningModel {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--discovery-fixtures") && ProcessInfo.processInfo.arguments.contains("--uitesting") {
            return NearbyPlanningModel(searcher: DiscoveryFixtureSearcher(), router: DiscoveryFixtureRouter(), photos: DiscoveryFixturePhotos())
        }
        #endif
        return NearbyPlanningModel()
    }
}

#if DEBUG
@MainActor private final class DiscoveryFixturePhotos: PlacePhotoSearching {
    func enrich(_ places: [Destination], near origin: Coordinate) async throws -> [Destination] {
        places.map { place in
            var value = place
            value.image = place.id == "fixture-temple" ? "gangaramaya" : place.id == "fixture-beach" ? "mirissa" : "colombo"
            return value
        }
    }
}
// Deterministic providers are available only to the explicitly opted-in UI tests.
// A normal launch always uses real online services.
@MainActor private final class DiscoveryFixtureSearcher: NearbyPlaceSearching {
    func search(_ query: NearbyQuery) async throws -> [Destination] {
        if ProcessInfo.processInfo.arguments.contains("--slow-discovery-fixture") { try await Task.sleep(for: .seconds(8)) }
        try Task.checkCancellation()
        return [
            Destination(id: "fixture-park", name: "Fixture Park", district: "Colombo", locality: "Colombo", category: .nature,
                        moods: [.chill, .adventure, .romantic], summary: "UI test fixture, not a live place.",
                        coordinate: .init(latitude: query.origin.latitude + 0.003, longitude: query.origin.longitude), minutes: 60,
                        budget: .easy, image: "", tags: ["UI test fixture"], source: .appleMaps, fetchedAt: .now),
            Destination(id: "fixture-cafe", name: "Fixture Café", district: "Colombo", locality: "Colombo", category: .food,
                        moods: [.chill, .food, .romantic], summary: "UI test fixture, not a live place.",
                        coordinate: .init(latitude: query.origin.latitude + 0.006, longitude: query.origin.longitude), minutes: 60,
                        budget: .easy, image: "", tags: ["UI test fixture"], source: .appleMaps, fetchedAt: .now),
            Destination(id: "fixture-temple", name: "Fixture Temple", district: "Colombo", locality: "Colombo", category: .culture,
                        moods: [.chill, .adventure], summary: "UI test fixture, not a live place.",
                        coordinate: .init(latitude: query.origin.latitude + 0.007, longitude: query.origin.longitude), minutes: 60,
                        budget: .easy, image: "", tags: ["UI test fixture"], source: .appleMaps, fetchedAt: .now, experienceTags: [.temple]),
            Destination(id: "fixture-beach", name: "Fixture Beach", district: "Colombo", locality: "Colombo", category: .beaches,
                        moods: [.chill, .romantic], summary: "UI test fixture, not a live place.",
                        coordinate: .init(latitude: query.origin.latitude + 0.009, longitude: query.origin.longitude), minutes: 60,
                        budget: .easy, image: "", tags: ["UI test fixture"], source: .appleMaps, fetchedAt: .now, experienceTags: [.seaside])
        ].filter(query.contains)
    }
}
@MainActor private final class DiscoveryFixtureRouter: JourneyEstimating {
    func estimate(from: Coordinate, to: Coordinate, mode: TravelMode) async throws -> JourneyEstimate {
        if ProcessInfo.processInfo.arguments.contains("--slow-route-fixture"), to.latitude - from.latitude > 0.0065 {
            try await Task.sleep(for: .seconds(6))
        }
        try Task.checkCancellation()
        return JourneyEstimate(roundTripSeconds: 1_200, roundTripMeters: 1_000, source: "UI test fixture", checkedAt: .now)
    }
}
#endif
