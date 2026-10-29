import XCTest
import SwiftData
@testable import AdoYamu

final class PersonalizationTests: XCTestCase {
    func testSameSadFeelingCanLeadToSeaOrTempleForDifferentPeople() throws {
        let seaside = PersonalizationContext(feeling: .sad, experiences: [.seaside])
        let temples = PersonalizationContext(feeling: .sad, experiences: [.temple])
        let seaResults = DestinationMatcher.eligible(in: DestinationCatalog.all, for: AdventureConstraints(budget: .easy, duration: .unhurried, personalization: seaside))
        let templeResults = DestinationMatcher.eligible(in: DestinationCatalog.all, for: AdventureConstraints(budget: .easy, duration: .unhurried, personalization: temples))
        XCTAssertFalse(seaResults.isEmpty); XCTAssertFalse(templeResults.isEmpty)
        XCTAssertTrue(seaResults.allSatisfy { $0.experiences.contains(.seaside) })
        XCTAssertEqual(Set(templeResults.map(\.id)), ["gangaramaya", "dalada"])
        XCTAssertTrue(Set(seaResults.map(\.id)).isDisjoint(with: templeResults.map(\.id)))
    }
    func testFeelingAloneDoesNotStereotypeAndSkippingKeepsOriginalMatching() {
        let original = DestinationMatcher.eligible(in: DestinationCatalog.all, for: AdventureConstraints())
        let sad = DestinationMatcher.eligible(in: DestinationCatalog.all, for: AdventureConstraints(personalization: .init(feeling: .sad)))
        let happy = DestinationMatcher.eligible(in: DestinationCatalog.all, for: AdventureConstraints(personalization: .init(feeling: .happy)))
        XCTAssertEqual(original.map(\.id), sad.map(\.id)); XCTAssertEqual(original.map(\.id), happy.map(\.id))
    }
    func testPersonalPreferenceNeverBypassesBudgetTimeOrLocation() {
        let personal = PersonalizationContext(feeling: .sad, experiences: [.temple])
        var criteria = AdventureConstraints(budget: .pocket, duration: .quick, origin: BaseCity.colombo.coordinate, radiusKilometers: 5, personalization: personal)
        XCTAssertTrue(DestinationMatcher.eligible(in: DestinationCatalog.all, for: criteria).isEmpty)
        criteria.budget = .easy
        XCTAssertEqual(DestinationMatcher.eligible(in: DestinationCatalog.all, for: criteria).map(\.id), ["gangaramaya"])
        criteria.moods = [.romantic]
        XCTAssertTrue(DestinationMatcher.eligible(in: DestinationCatalog.all, for: criteria).isEmpty)
    }
    func testExperienceChoicesAreORAndSpecificTempleMetadataIsRequired() throws {
        let context = PersonalizationContext(feeling: .stressed, experiences: [.temple, .seaside])
        XCTAssertTrue(context.accepts(try XCTUnwrap(DestinationCatalog.find("mirissa"))))
        XCTAssertTrue(context.accepts(try XCTUnwrap(DestinationCatalog.find("gangaramaya"))))
        XCTAssertFalse(context.accepts(try XCTUnwrap(DestinationCatalog.find("bridge"))))
        XCTAssertFalse(try XCTUnwrap(DestinationCatalog.find("pidurangala")).experiences.contains(.temple), "A hiking trail passing a temple is not a temple visit")
        XCTAssertFalse(Destination.isTempleName("Temple Road Café"))
        XCTAssertFalse(Destination.isTempleName("Temple Museum"))
        XCTAssertTrue(Destination.isTempleName("Kelaniya Raja Maha Viharaya"))
    }
    func testRankingAndSurpriseUseChosenExperiencesWhileAvoidingRecentRepeats() throws {
        let context = PersonalizationContext(feeling: .happy, experiences: [.seaside, .wander, .food])
        let colombo = try XCTUnwrap(DestinationCatalog.find("colombo"))
        let mirissa = try XCTUnwrap(DestinationCatalog.find("mirissa"))
        let pettah = try XCTUnwrap(DestinationCatalog.find("pettah"))
        let places = [mirissa, pettah, colombo]
        XCTAssertEqual(context.ranked(places).first?.id, colombo.id)
        var generator = SystemRandomNumberGenerator()
        XCTAssertEqual(DestinationMatcher.select(from: places, recentIDs: [], personalization: context, using: &generator)?.id, colombo.id)
        XCTAssertNotEqual(DestinationMatcher.select(from: places, recentIDs: [colombo.id], personalization: context, using: &generator)?.id, colombo.id)
    }
    func testChoicesAreRememberedSeparatelyForEachFeelingAndSkipIsOptional() {
        let date = Date()
        var preferences = PersonalizationPreferences()
        preferences.checkIn(.sad, at: date); preferences.toggle(.temple, at: date)
        preferences.checkIn(.happy, at: date)
        XCTAssertTrue(preferences.context(at: date).experiences.isEmpty)
        preferences.toggle(.seaside, at: date)
        preferences.checkIn(.sad, at: date)
        XCTAssertEqual(preferences.context(at: date).experiences, [.temple])
        preferences.checkIn(nil, at: date)
        XCTAssertEqual(preferences.context(at: date), .none)
        preferences.checkIn(.happy, at: date)
        XCTAssertEqual(preferences.context(at: date).experiences, [.seaside])
    }
    func testYesterdayFeelingExpiresButPreferredExperiencesCanBeRecalled() throws {
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = try XCTUnwrap(TimeZone(secondsFromGMT: 0))
        let today = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 10, day: 29, hour: 12)))
        let tomorrow = try XCTUnwrap(calendar.date(byAdding: .day, value: 1, to: today))
        var preferences = PersonalizationPreferences(); preferences.checkIn(.sad, at: today); preferences.toggle(.temple, at: today)
        XCTAssertEqual(preferences.context(at: tomorrow, calendar: calendar), .none)
        preferences.checkIn(.sad, at: tomorrow)
        XCTAssertEqual(preferences.context(at: tomorrow, calendar: calendar).experiences, [.temple])
    }
    func testOnlineFilteringKeepsEmotionOutOfCacheKeysAndKeepsCostEstimates() throws {
        let place = try XCTUnwrap(DestinationCatalog.find("gangaramaya"))
        var query = NearbyQuery(origin: try XCTUnwrap(BaseCity.colombo.coordinate), radiusKilometers: 5, moods: [.chill], travelMode: .walking,
            personalization: .init(feeling: .sad, experiences: [.temple]))
        XCTAssertTrue(query.contains(place)); XCTAssertFalse(query.contains(try XCTUnwrap(DestinationCatalog.find("colombo"))))
        let cacheKey = query.cacheKey, estimateKey = query.estimateKey(for: place.id)
        XCTAssertFalse(cacheKey.contains("sad"))
        query.personalization.feeling = .happy
        XCTAssertEqual(query.cacheKey, cacheKey)
        XCTAssertEqual(query.estimateKey(for: place.id), estimateKey)
        let unknown = TripAssessment(place: place, plan: TripPlan(), query: query, estimate: nil, journey: nil)
        XCTAssertEqual(unknown.fit, .needsInformation)
        query.personalization.experiences = [.seaside]
        XCTAssertNotEqual(query.cacheKey, cacheKey); XCTAssertFalse(query.contains(place))
    }
    func testOlderPlanAndDestinationDataRemainReadable() throws {
        let plan = TripPlan()
        var oldPlan = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(plan)) as? [String: Any])
        oldPlan.removeValue(forKey: "personalization")
        let decoded = try JSONDecoder().decode(TripPlan.self, from: JSONSerialization.data(withJSONObject: oldPlan))
        XCTAssertNil(decoded.personalization); XCTAssertEqual(decoded.totalBudget, plan.totalBudget)
        let place = try XCTUnwrap(DestinationCatalog.find("mirissa"))
        var oldPlace = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(place)) as? [String: Any])
        oldPlace.removeValue(forKey: "experienceTags")
        let decodedPlace = try JSONDecoder().decode(Destination.self, from: JSONSerialization.data(withJSONObject: oldPlace))
        XCTAssertTrue(decodedPlace.experiences.contains(.seaside))
    }
}

@MainActor final class PersonalizationPersistenceTests: XCTestCase {
    func testFeelingPreferencesSurviveDiskRelaunchAndCanBeClearedWithoutLosingJournal() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let schema = Schema([FavoritePlace.self, VisitRecord.self, SavedTrip.self, ExplorerPreferences.self, DiscoveryJournal.self])
        let configuration = ModelConfiguration(schema: schema, url: directory.appendingPathComponent("journal.store"))
        let place = try XCTUnwrap(DestinationCatalog.find("gangaramaya"))
        do {
            let container = try ModelContainer(for: schema, configurations: [configuration])
            let store = try ExplorerStore(context: container.mainContext)
            store.preferences.onboardingComplete = true; store.toggleFavorite(place)
            store.checkIn(.sad); store.toggleExperience(.temple)
            store.checkIn(.happy); store.toggleExperience(.seaside)
            store.checkIn(.sad)
            XCTAssertNil(store.errorMessage)
        }
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let store = try ExplorerStore(context: container.mainContext)
        XCTAssertEqual(store.personalization.feeling, .sad); XCTAssertEqual(store.personalization.experiences, [.temple])
        store.checkIn(.happy); XCTAssertEqual(store.personalization.experiences, [.seaside])
        store.clearPersonalization()
        XCTAssertEqual(store.personalization, .none); XCTAssertNil(store.tripPlan.personalization)
        XCTAssertTrue(store.preferences.onboardingComplete); XCTAssertTrue(store.isFavorite(place))
    }
}
