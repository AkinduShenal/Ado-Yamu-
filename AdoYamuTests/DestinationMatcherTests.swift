import XCTest
import SwiftData
import UIKit
@testable import AdoYamu

final class DestinationMatcherTests: XCTestCase {
    func testEveryFilterIsAppliedAndMultipleMoodsUseOR() {
        let criteria = AdventureConstraints(moods: [.food, .chill], budget: .pocket, duration: .quick, origin: BaseCity.colombo.coordinate)
        let matches = DestinationMatcher.eligible(in: DestinationCatalog.all, for: criteria)
        XCTAssertEqual(Set(matches.map(\.id)), ["colombo", "kandy"])
        for match in matches {
            XCTAssertFalse(match.moods.isDisjoint(with: criteria.moods))
            XCTAssertLessThanOrEqual(match.budget.rawValue, criteria.budget.rawValue)
            XCTAssertLessThanOrEqual(match.minutes, criteria.duration.rawValue)
            if let origin = criteria.origin, let coordinate = match.coordinate { XCTAssertLessThanOrEqual(origin.kilometers(to: coordinate), criteria.radiusKilometers) }
        }
    }
    func testNoMatchDoesNotSilentlyIgnoreConstraints() {
        let criteria = AdventureConstraints(moods: [.adventure], budget: .pocket, duration: .quick, origin: BaseCity.galle.coordinate, radiusKilometers: 10)
        XCTAssertTrue(DestinationMatcher.eligible(in: DestinationCatalog.all, for: criteria).isEmpty)
    }
    func testEmptyMoodMeansAnyMoodAndHalfDayIsInclusive() {
        let all = DestinationMatcher.eligible(in: DestinationCatalog.all, for: AdventureConstraints(moods: [], budget: .flexible, duration: .halfDay))
        XCTAssertEqual(all.count, DestinationCatalog.all.count)
        XCTAssertTrue(all.contains { $0.id == "horton" })
    }
    func testSelectionAvoidsRecentAndImmediateRepeatsWhenAlternativesExist() throws {
        let places = Array(DestinationCatalog.all.prefix(3))
        let first = try XCTUnwrap(places.first)
        let second = places[1]
        let third = places[2]
        var generator = SeededGenerator(seed: 42)
        for _ in 0..<30 {
            XCTAssertEqual(DestinationMatcher.select(from: places, recentIDs: [first.id, second.id], using: &generator)?.id, third.id)
            let exhausted = DestinationMatcher.select(from: places, recentIDs: places.map(\.id), using: &generator)
            XCTAssertNotEqual(exhausted?.id, third.id)
        }
        XCTAssertEqual(DestinationMatcher.select(from: [first], recentIDs: [first.id], using: &generator), first)
        XCTAssertNil(DestinationMatcher.select(from: [], recentIDs: [], using: &generator))
    }
    func testSearchTrimsWhitespaceAndCombinesCategoryAndDistrict() {
        let matches = DestinationMatcher.search(DestinationCatalog.all, text: "  BADULLA  ", category: .waterfalls)
        XCTAssertEqual(Set(matches.map(\.id)), ["ravana", "diyaluma", "bambarakanda", "dunhinda"])
        XCTAssertTrue(DestinationMatcher.search(DestinationCatalog.all, text: "Matale", category: .beaches).isEmpty)
        XCTAssertEqual(DestinationMatcher.search(DestinationCatalog.all, text: "nInE aRcHeS").first?.id, "bridge")
    }
    func testCatalogHasValidUniquePlacesAndBundledPhotography() {
        XCTAssertGreaterThanOrEqual(DestinationCatalog.all.count, 12)
        XCTAssertEqual(Set(DestinationCatalog.all.map(\.id)).count, DestinationCatalog.all.count)
        for place in DestinationCatalog.all {
            XCTAssertFalse(place.summary.isEmpty)
            XCTAssertNotNil(place.coordinate)
            if let coordinate = place.coordinate {
                XCTAssertTrue((5.8...10).contains(coordinate.latitude)); XCTAssertTrue((79.4...82).contains(coordinate.longitude))
            }
            XCTAssertNotNil(UIImage(named: place.image), "Missing photo: \(place.image)")
        }
        XCTAssertEqual(DestinationCatalog.find("pidurangala")?.district, "Matale")
        XCTAssertEqual(DestinationCatalog.find("hiriketiya")?.district, "Matara")
        XCTAssertEqual(DestinationCatalog.find("bridge")?.district, "Badulla")
    }
}
private struct SeededGenerator: RandomNumberGenerator {
    var seed: UInt64
    mutating func next() -> UInt64 { seed = seed &* 6364136223846793005 &+ 1442695040888963407; return seed }
}

@MainActor final class PersistenceTests: XCTestCase {
    func testJournalAndPreferencesSurviveReopeningDiskStore() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let schema = Schema([FavoritePlace.self, VisitRecord.self, SavedTrip.self, ExplorerPreferences.self, DiscoveryJournal.self])
        let configuration = ModelConfiguration(schema: schema, url: directory.appendingPathComponent("journal.store"))
        let place = try XCTUnwrap(DestinationCatalog.find("pidurangala"))
        do {
            let container = try ModelContainer(for: schema, configurations: [configuration])
            let store = try ExplorerStore(context: container.mainContext)
            XCTAssertTrue(store.visits.isEmpty)
            store.preferences.name = "Test Explorer"; store.preferences.onboardingComplete = true
            store.preferences.cityRaw = BaseCity.ella.rawValue; store.preferences.moodRaw = Mood.adventure.rawValue
            store.toggleFavorite(place); store.markVisited(place); store.markVisited(place)
            store.saveTrip(place); store.saveTrip(place); store.recordSuggestion(place)
            XCTAssertTrue(store.save()); XCTAssertNil(store.errorMessage)
        }
        let reopened = try ModelContainer(for: schema, configurations: [configuration])
        let store = try ExplorerStore(context: reopened.mainContext)
        XCTAssertTrue(store.preferences.onboardingComplete)
        XCTAssertEqual(store.preferences.name, "Test Explorer")
        XCTAssertEqual(store.preferences.city, .ella)
        XCTAssertEqual(store.preferences.moods, [.adventure])
        XCTAssertEqual(store.favorites.count, 1); XCTAssertTrue(store.isFavorite(place))
        XCTAssertEqual(store.visits.count, 1); XCTAssertEqual(store.districtCount, 1)
        XCTAssertEqual(store.earnedBadges, 1); XCTAssertEqual(store.trips.count, 1)
        XCTAssertEqual(store.preferences.recentIDs, [place.id])
        store.toggleFavorite(place)
        XCTAssertTrue(try reopened.mainContext.fetch(FetchDescriptor<FavoritePlace>()).isEmpty)
    }
    func testVisitsAreExplicitAndStatsUseDistinctDistricts() throws {
        let container = try ModelContainer(for: FavoritePlace.self, VisitRecord.self, SavedTrip.self, ExplorerPreferences.self, DiscoveryJournal.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let store = try ExplorerStore(context: container.mainContext)
        let first = try XCTUnwrap(DestinationCatalog.find("ravana"))
        let second = try XCTUnwrap(DestinationCatalog.find("bridge"))
        store.toggleFavorite(first); store.recordSuggestion(first); store.saveTrip(first)
        XCTAssertEqual(store.visits.count, 0)
        store.markVisited(first); store.markVisited(second)
        XCTAssertEqual(store.visits.count, 2); XCTAssertEqual(store.districtCount, 1); XCTAssertEqual(store.earnedBadges, 2)
    }
}
