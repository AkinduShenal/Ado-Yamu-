import XCTest
import SwiftData
import MapKit
import UIKit
@testable import AdoYamu

final class TripPlanningTests: XCTestCase {
    private let origin = Coordinate(latitude: 6.9271, longitude: 79.8612)
    private func place(id: String = "online-park", latitude: Double = 6.929) -> Destination {
        Destination(id: id, name: "Online test park", district: "", locality: "Colombo", category: .nature, moods: [.chill],
                    summary: "A test venue", coordinate: .init(latitude: latitude, longitude: 79.8612), minutes: 60, budget: .pocket,
                    image: "", tags: [], source: .appleMaps, sourceURL: URL(string: "https://maps.apple.com/"), fetchedAt: .now)
    }
    private func assessment(plan: TripPlan = TripPlan(), entry: Int? = nil, manual: Int? = nil,
                            seconds: Double? = 1_200, venue: Destination? = nil) -> TripAssessment {
        let query = NearbyQuery(origin: origin, radiusKilometers: 5, moods: [.chill], travelMode: plan.travelMode)
        return TripAssessment(place: venue ?? place(), plan: plan, query: query,
                              estimate: PlaceEstimate(entryAndActivityRupees: entry, manualRoundTripMinutes: manual),
                              journey: seconds.map { JourneyEstimate(roundTripSeconds: $0, roundTripMeters: 1_000, source: "Test route", checkedAt: .now) })
    }
    func testUnknownAdmissionIsNeverTreatedAsFreeOrSelectedFromBudgetBand() {
        let result = assessment()
        XCTAssertNil(result.totalCost)
        XCTAssertEqual(result.fit, .needsInformation)
        XCTAssertTrue(result.missingInformation.contains("entry / activity cost"))
    }
    func testWholeBudgetIncludesReturnTransportAdmissionAndExtrasAtBoundary() {
        var plan = TripPlan(); plan.travelMode = .transit; plan.transportRupees = 500; plan.foodAndExtrasRupees = 200
        XCTAssertEqual(assessment(plan: plan, entry: 300).totalCost, 1_000)
        XCTAssertEqual(assessment(plan: plan, entry: 300).fit, .fits)
        plan.totalBudget = 999
        XCTAssertEqual(assessment(plan: plan, entry: 300).fit, .overBudget)
    }
    func testMissingFareAndMissingRouteRemainIncomplete() {
        var plan = TripPlan(); plan.travelMode = .car
        XCTAssertEqual(assessment(plan: plan, entry: 0).fit, .needsInformation)
        XCTAssertNil(assessment(entry: 0, seconds: nil).totalMinutes)
        XCTAssertEqual(assessment(entry: 0, seconds: nil).fit, .needsInformation)
        XCTAssertEqual(assessment(entry: 0, manual: 20, seconds: nil).fit, .fits)
    }
    func testTimeIncludesBothJourneysAndVisitAndRoundsUp() {
        var plan = TripPlan(); plan.availableMinutes = 60; plan.visitMinutes = 30
        XCTAssertEqual(assessment(plan: plan, entry: 0, seconds: 1_801).totalMinutes, 61)
        XCTAssertEqual(assessment(plan: plan, entry: 0, seconds: 1_801).fit, .overTime)
        XCTAssertEqual(assessment(plan: plan, entry: 0, seconds: 1_800).fit, .fits)
        XCTAssertEqual(assessment(plan: plan, entry: 0, manual: 40, seconds: 300).fit, .overTime)
    }
    func testColomboRadiusRejectsDistantLowBudgetDestination() throws {
        let query = NearbyQuery(origin: origin, radiusKilometers: 5, moods: [], travelMode: .walking)
        XCTAssertTrue(query.contains(place()))
        let kandy = try XCTUnwrap(DestinationCatalog.find("kandy"))
        XCTAssertFalse(query.contains(kandy))
        XCTAssertEqual(assessment(entry: 0, venue: kandy).fit, .needsInformation)
    }
    func testInvalidAmountsAndJourneyValuesCannotQualify() {
        var plan = TripPlan(); plan.totalBudget = -1
        XCTAssertNotNil(plan.validationMessage)
        XCTAssertNotEqual(assessment(plan: plan, entry: 0).fit, .fits)
        XCTAssertNotEqual(assessment(entry: -100).fit, .fits)
        XCTAssertNotEqual(assessment(entry: 0, seconds: .nan).fit, .fits)
        XCTAssertNotEqual(assessment(entry: 0, seconds: .infinity).fit, .fits)
    }
    func testOnlineMetadataSurvivesEncodingAndDeduplicationPreservesDistinctBranches() throws {
        let original = place()
        let restored = try JSONDecoder().decode(Destination.self, from: JSONEncoder().encode(original))
        XCTAssertEqual(restored, original); XCTAssertEqual(restored.source, .appleMaps)
        XCTAssertEqual(restored.locationDescription, "Colombo")
        XCTAssertEqual(NearbyPlaceDeduplicator.unique([original, original]).count, 1)
        XCTAssertEqual(NearbyPlaceDeduplicator.unique([original, place(id: "branch", latitude: 6.96)]).count, 2)
    }
    @MainActor func testOnlineNamesWithCommasPreserveRecentSuggestionIDs() throws {
        let item = MKMapItem(placemark: MKPlacemark(coordinate: origin.mapCoordinate))
        item.name = "Park, Café & Garden"
        let mapped = try XCTUnwrap(AppleNearbyPlaceService.destination(item))
        XCTAssertEqual(mapped.name, "Park, Café & Garden")
        let preferences = ExplorerPreferences(); preferences.recentIDsRaw = mapped.id
        XCTAssertEqual(preferences.recentIDs, [mapped.id])
    }
}

@MainActor final class OnlineJournalTests: XCTestCase {
    private var schema: Schema { Schema([FavoritePlace.self, VisitRecord.self, SavedTrip.self, ExplorerPreferences.self, DiscoveryJournal.self]) }
    private func venue() throws -> Destination {
        var place = try XCTUnwrap(DestinationCatalog.find("colombo"))
        // Use the service's online representation, including missing district/photo data.
        let data = try JSONEncoder().encode(place)
        place = try JSONDecoder().decode(Destination.self, from: data)
        return Destination(id: "apple-test", name: "Persisted online park", district: "", locality: "Colombo", category: .nature, moods: [.chill], summary: "Online journal test", coordinate: place.coordinate, minutes: 60, budget: .easy, image: "", tags: [], source: .appleMaps, fetchedAt: .now)
    }
    func testOnlinePlaceFavoriteVisitPlanAndEstimatesSurviveRelaunch() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let config = ModelConfiguration(schema: schema, url: folder.appendingPathComponent("journal.store"))
        let place = try venue()
        let origin = try XCTUnwrap(BaseCity.colombo.coordinate)
        let query = NearbyQuery(origin: origin, radiusKilometers: 5, moods: [.chill], travelMode: .walking)
        do {
            let container = try ModelContainer(for: schema, configurations: [config])
            let store = try ExplorerStore(context: container.mainContext)
            store.cachePlaces([place]); store.toggleFavorite(place); store.markVisited(place); store.saveTrip(place)
            var plan = TripPlan(); plan.totalBudget = 700; plan.foodAndExtrasRupees = 100; store.updatePlan(plan)
            store.saveEstimate(PlaceEstimate(entryAndActivityRupees: 250, manualRoundTripMinutes: 25), for: place, query: query)
            XCTAssertNil(store.errorMessage)
        }
        let container = try ModelContainer(for: schema, configurations: [config])
        let store = try ExplorerStore(context: container.mainContext)
        XCTAssertEqual(store.destination(place.id), place)
        XCTAssertTrue(store.isFavorite(place)); XCTAssertTrue(store.hasVisited(place))
        XCTAssertEqual(store.districtCount, 0, "Missing district data must not count as a known district")
        XCTAssertEqual(store.passportPlaces.count, DestinationCatalog.all.count + 1)
        XCTAssertEqual(store.tripPlan.totalBudget, 700)
        XCTAssertEqual(store.estimate(for: place, query: query)?.entryAndActivityRupees, 250)
        XCTAssertEqual(store.estimate(for: place, query: query)?.manualRoundTripMinutes, 25)
        var otherQuery = query; otherQuery.travelMode = .car
        XCTAssertNil(store.estimate(for: place, query: otherQuery), "Journey estimates must not leak to a different mode")
    }
    func testExistingFourModelJournalMigratesWithoutLosingFavoritesOrOnboarding() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appendingPathComponent("original.store")
        do {
            let oldSchema = Schema([FavoritePlace.self, VisitRecord.self, SavedTrip.self, ExplorerPreferences.self])
            let old = try ModelContainer(for: oldSchema, configurations: [ModelConfiguration(schema: oldSchema, url: url)])
            let preferences = ExplorerPreferences(); preferences.onboardingComplete = true; preferences.name = "Original Explorer"
            old.mainContext.insert(preferences); old.mainContext.insert(FavoritePlace(destinationID: "pidurangala")); try old.mainContext.save()
        }
        let migrated = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, url: url)])
        let store = try ExplorerStore(context: migrated.mainContext)
        XCTAssertTrue(store.preferences.onboardingComplete)
        XCTAssertEqual(store.preferences.name, "Original Explorer")
        XCTAssertEqual(store.favorites.first?.destinationID, "pidurangala")
        XCTAssertEqual(store.tripPlan.totalBudget, 1_000)
        XCTAssertNil(store.errorMessage)
    }
    func testSearchFailureUsesSavedPlacesWithExplicitOfflineStatusAndNoFalseFit() async throws {
        let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)])
        let store = try ExplorerStore(context: container.mainContext)
        let place = try venue(); store.cachePlaces([place])
        let query = NearbyQuery(origin: try XCTUnwrap(BaseCity.colombo.coordinate), radiusKilometers: 5, moods: [.chill], travelMode: .walking)
        let model = NearbyPlanningModel(searcher: FailingSearcher(), router: TestJourneyProvider())
        model.search(query, store: store)
        let deadline = ContinuousClock.now.advanced(by: .seconds(3))
        while (model.isSearching || model.isCheckingJourneys) && ContinuousClock.now < deadline { try await Task.sleep(for: .milliseconds(10)) }
        XCTAssertFalse(model.isSearching); XCTAssertTrue(model.isOfflineFallback)
        XCTAssertEqual(model.places.map(\.id), [place.id]); XCTAssertNotNil(model.message)
        XCTAssertNil(model.surprise(store: store), "Unknown entry fees must not produce a supposedly affordable surprise")
        store.saveEstimate(PlaceEstimate(entryAndActivityRupees: 0, manualRoundTripMinutes: nil), for: place, query: query)
        XCTAssertEqual(model.surprise(store: store)?.place.id, place.id)
    }
}
@MainActor private final class FailingSearcher: NearbyPlaceSearching {
    func search(_ query: NearbyQuery) async throws -> [Destination] { throw URLError(.notConnectedToInternet) }
}
@MainActor private final class TestJourneyProvider: JourneyEstimating {
    func estimate(from: Coordinate, to: Coordinate, mode: TravelMode) async throws -> JourneyEstimate {
        JourneyEstimate(roundTripSeconds: 600, roundTripMeters: 800, source: "Test route", checkedAt: .now)
    }
}


final class PlacePhotoMatchingTests: XCTestCase {
    private func article(_ title: String, lat: Double = 6.9139, lon: Double = 79.8606) -> PhotoArticle {
        PhotoArticle(title: title, pageimage: "Park.jpg", coordinates: [.init(lat: lat, lon: lon)])
    }
    func testPhotoRequiresBothVenueIdentityAndNearbyCoordinates() {
        let point = Coordinate(latitude: 6.914, longitude: 79.86)
        XCTAssertTrue(PhotoPlaceMatcher.matches(name: "Viharamahadevi Park", point: point, article: article("Viharamahadevi Park")))
        XCTAssertFalse(PhotoPlaceMatcher.matches(name: "Viharamahadevi Park", point: point, article: article("Gangaramaya Temple")))
        XCTAssertFalse(PhotoPlaceMatcher.matches(name: "Viharamahadevi Park Café", point: point, article: article("Viharamahadevi Park")))
        XCTAssertFalse(PhotoPlaceMatcher.matches(name: "Viharamahadevi Park", point: point, article: article("Viharamahadevi Park", lat: 7.3)))
        XCTAssertFalse(PhotoPlaceMatcher.matches(name: "Park Café", point: point, article: article("Colombo Park")))
    }
    func testFreeLicenseAndCreditHandling() {
        XCTAssertTrue(PhotoPlaceMatcher.isReusableLicense("CC BY-SA 4.0"))
        XCTAssertTrue(PhotoPlaceMatcher.isReusableLicense("Public domain"))
        XCTAssertFalse(PhotoPlaceMatcher.isReusableLicense("Fair use"))
        XCTAssertFalse(PhotoPlaceMatcher.isReusableLicense("All rights reserved"))
        XCTAssertEqual(PhotoPlaceMatcher.plainText("<a href='x'>A &amp; B</a>"), "A & B")
    }
    func testLandmarksExcludeEventsAndNonVisitorInstitutions() {
        XCTAssertEqual(PhotoPlaceMatcher.landmarkCategory("Viharamahadevi Park"), .nature)
        XCTAssertEqual(PhotoPlaceMatcher.landmarkCategory("Gangaramaya Temple"), .culture)
        XCTAssertNil(PhotoPlaceMatcher.landmarkCategory("Fort railway station bombing"))
        XCTAssertNil(PhotoPlaceMatcher.landmarkCategory("Garden College"))
        XCTAssertNil(PhotoPlaceMatcher.landmarkCategory("National Hospital"))
    }
    func testPhotoMetadataPersistsAndOlderDestinationsStillDecode() throws {
        var place = try XCTUnwrap(DestinationCatalog.find("colombo"))
        let photo = PlacePhoto(url: try XCTUnwrap(URL(string: "https://upload.wikimedia.org/photo.jpg")),
                               sourceURL: try XCTUnwrap(URL(string: "https://commons.wikimedia.org/wiki/File:Photo.jpg")),
                               author: "Test author", license: "CC BY-SA 4.0", licenseURL: try XCTUnwrap(URL(string: "https://creativecommons.org/licenses/by-sa/4.0/")))
        place.photo = photo
        XCTAssertEqual(try JSONDecoder().decode(Destination.self, from: JSONEncoder().encode(place)).photo, photo)
        var legacy = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(place)) as? [String: Any])
        legacy.removeValue(forKey: "photo")
        XCTAssertNil(try JSONDecoder().decode(Destination.self, from: JSONSerialization.data(withJSONObject: legacy)).photo)
    }
    @MainActor func testLiveWikimediaPhotoWhenRequested() async throws {
        guard ProcessInfo.processInfo.environment["ADO_LIVE_PHOTOS"] == "1" else { throw XCTSkip("Opt-in Wikimedia integration test; set TEST_RUNNER_ADO_LIVE_PHOTOS=1.") }
        let point = Coordinate(latitude: 6.9139, longitude: 79.8606)
        let place = Destination(id: "live-photo-park", name: "Viharamahadevi Park", district: "Colombo", locality: "Colombo", category: .nature,
            moods: [.chill], summary: "Real Wikimedia photo integration check", coordinate: point, minutes: 60, budget: .easy, image: "", tags: [], source: .appleMaps)
        let places = try await WikimediaPhotoService().enrich([place], near: point)
        let photo = try XCTUnwrap(places.first?.photo)
        XCTAssertFalse(photo.author.isEmpty); XCTAssertTrue(PhotoPlaceMatcher.isReusableLicense(photo.license))
        let (data, response) = try await URLSession.shared.data(from: photo.url)
        XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 200)
        XCTAssertGreaterThan(data.count, 1_000)
        let image = try XCTUnwrap(UIImage(data: data))
        let attachment = XCTAttachment(image: image); attachment.name = "Live-Wikimedia-Viharamahadevi-photo"; attachment.lifetime = .keepAlways; add(attachment)
    }
}


@MainActor final class PhotoHandoffTests: XCTestCase {
    func testOpeningDetailsKeepsRequestedPhotoLookupAndCredits() async throws {
        let store = try XCTUnwrap(PreviewEnvironment.store())
        let point = try XCTUnwrap(BaseCity.colombo.coordinate)
        let place = Destination(id: "photo-handoff", name: "Photo handoff fixture", district: "Colombo", locality: "Colombo", category: .nature,
            moods: [.chill], summary: "Unit test fixture", coordinate: point, minutes: 60, budget: .easy, image: "", tags: [], source: .appleMaps)
        let photo = PlacePhoto(url: try XCTUnwrap(URL(string: "https://upload.wikimedia.org/test.jpg")), sourceURL: try XCTUnwrap(URL(string: "https://commons.wikimedia.org/wiki/File:Test.jpg")),
            author: "Test author", license: "CC BY 4.0", licenseURL: try XCTUnwrap(URL(string: "https://creativecommons.org/licenses/by/4.0/")))
        let model = NearbyPlanningModel(searcher: SinglePlaceSearcher(place: place), router: TestJourneyProvider(), photos: DelayedPhotoProvider(photo: photo))
        model.search(NearbyQuery(origin: point, radiusKilometers: 5, moods: [.chill], travelMode: .walking), store: store)
        let deadline = ContinuousClock.now.advanced(by: .seconds(2))
        while model.isSearching && ContinuousClock.now < deadline { try await Task.sleep(for: .milliseconds(10)) }
        model.stopRouteChecks()
        while store.destination(place.id)?.photo == nil && ContinuousClock.now < deadline { try await Task.sleep(for: .milliseconds(10)) }
        XCTAssertEqual(store.destination(place.id)?.photo, photo)
        XCTAssertNil(store.errorMessage)
    }
}
@MainActor private final class SinglePlaceSearcher: NearbyPlaceSearching {
    let place: Destination
    init(place: Destination) { self.place = place }
    func search(_ query: NearbyQuery) async throws -> [Destination] { [place] }
}
@MainActor private final class DelayedPhotoProvider: PlacePhotoSearching {
    let photo: PlacePhoto
    init(photo: PlacePhoto) { self.photo = photo }
    func enrich(_ places: [Destination], near origin: Coordinate) async throws -> [Destination] {
        try await Task.sleep(for: .milliseconds(80))
        return places.map { place in var result = place; result.photo = photo; return result }
    }
}
