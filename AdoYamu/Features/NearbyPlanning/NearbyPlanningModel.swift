import SwiftUI

@MainActor @Observable final class NearbyPlanningModel {
    private let searcher: any NearbyPlaceSearching
    private let router: any JourneyEstimating
    private let photos: any PlacePhotoSearching
    private var task: Task<Void, Never>?
    private var photoTask: Task<Void, Never>?
    private var requestID = UUID()
    private(set) var query: NearbyQuery?
    private(set) var places: [Destination] = []
    private(set) var journeys: [String: JourneyEstimate] = [:]
    private(set) var isSearching = false
    private(set) var isCheckingJourneys = false
    private(set) var checkedJourneys = 0
    private(set) var message: String?
    private(set) var isOfflineFallback = false
    private(set) var didSearch = false
    private(set) var isLoadingPhotos = false
    private(set) var isPreparing = false
    var isBusy: Bool { isSearching || isPreparing || isLoadingPhotos || isCheckingJourneys }
    var totalJourneyChecks: Int { min(places.count, 8) }
    var readyToReveal: Bool { didSearch && !isBusy }
    init(searcher: (any NearbyPlaceSearching)? = nil, router: (any JourneyEstimating)? = nil, photos: (any PlacePhotoSearching)? = nil) {
        self.searcher = searcher ?? AppleNearbyPlaceService(); self.router = router ?? JourneyService()
        self.photos = photos ?? WikimediaPhotoService()
    }
    func search(_ query: NearbyQuery, store: ExplorerStore, forceRefresh: Bool = false) {
        cancel(clear: true)
        if forceRefresh { searcher.invalidateCache(for: query) }
        let id = UUID(); requestID = id; self.query = query
        isSearching = true; isPreparing = true; didSearch = true
        task = Task { [weak self] in
            guard let self else { return }
            do {
                let found = try await searcher.search(query)
                try Task.checkCancellation()
                guard id == requestID else { return }
                places = found.map { place in
                    var value = place
                    if let cached = store.destination(place.id) { value.photo = cached.photo; value.image = cached.image }
                    if value.image.isEmpty, let bundled = PhotoPlaceMatcher.bundledPhoto(for: value) { value.image = bundled }
                    return value
                }
                store.cachePlaces(places)
                loadPhotos(query, id: id, store: store)
                message = found.isEmpty ? "No online places matched these choices. Try another experience, mood or a wider radius." : nil
            } catch {
                guard !Task.isCancelled, id == requestID else { return }
                let cached = store.onlinePlaces.filter(query.contains)
                places = cached.isEmpty ? DestinationCatalog.all.filter(query.contains) : cached
                isOfflineFallback = true
                message = places.isEmpty ? "Online search couldn’t connect. Try again, or open Offline ideas for the bundled collection." : "Online search couldn’t refresh. Showing saved or bundled places in this area. Check the source date on each place."
            }
            guard id == requestID else { return }
            isSearching = false
            await photoTask?.value
            guard !Task.isCancelled, id == requestID else { return }
            isCheckingJourneys = !places.isEmpty; isPreparing = false
            await checkJourneys(query, id: id)
        }
    }
    func cancel(clear: Bool = false) {
        requestID = UUID(); task?.cancel(); task = nil; photoTask?.cancel(); photoTask = nil
        isSearching = false; isCheckingJourneys = false; isLoadingPhotos = false; isPreparing = false
        if clear { places = []; journeys = [:]; query = nil; message = nil; isOfflineFallback = false; didSearch = false; checkedJourneys = 0 }
    }
    func stopRouteChecks() {
        // The requested photo lookup may finish while a result's detail view is open.
        task?.cancel(); task = nil; isSearching = false; isCheckingJourneys = false; isPreparing = false
    }
    private func loadPhotos(_ query: NearbyQuery, id: UUID, store: ExplorerStore) {
        let candidates = places
        isLoadingPhotos = true
        photoTask = Task { [weak self] in
            guard let self else { return }
            do {
                let enriched = try await photos.enrich(candidates, near: query.origin)
                try Task.checkCancellation()
                guard id == requestID else { return }
                places = Array(enriched.filter(query.contains).sorted { lhs, rhs in
                    let leftPreference = query.personalization.score(lhs), rightPreference = query.personalization.score(rhs)
                    if leftPreference != rightPreference { return leftPreference > rightPreference }
                    let leftPhoto = !lhs.image.isEmpty || lhs.photo != nil, rightPhoto = !rhs.image.isEmpty || rhs.photo != nil
                    if leftPhoto != rightPhoto { return leftPhoto }
                    let left = lhs.coordinate.map { query.origin.kilometers(to: $0) } ?? .infinity
                    let right = rhs.coordinate.map { query.origin.kilometers(to: $0) } ?? .infinity
                    return left == right ? lhs.id < rhs.id : left < right
                }.prefix(12))
                if !places.isEmpty && !isOfflineFallback { message = nil }
                store.cachePlaces(places)
            } catch { /* Keep place results and the labelled map preview when photos are unavailable. */ }
            if id == requestID { isLoadingPhotos = false }
        }
    }
    private func checkJourneys(_ query: NearbyQuery, id: UUID) async {
        let candidates = Array(places.prefix(8))
        guard !candidates.isEmpty else { return }
        isCheckingJourneys = true; checkedJourneys = 0
        let routeProvider = router
        await withTaskGroup(of: (String, JourneyEstimate?).self) { group in
            var next = 0
            func submit(_ place: Destination) {
                group.addTask { @MainActor in
                    guard let coordinate = place.coordinate else { return (place.id, nil) }
                    let result = try? await routeProvider.estimate(from: query.origin, to: coordinate, mode: query.travelMode)
                    return (place.id, result)
                }
            }
            for _ in 0..<min(2, candidates.count) { submit(candidates[next]); next += 1 }
            for await (placeID, journey) in group {
                guard !Task.isCancelled, id == requestID else { group.cancelAll(); return }
                if let journey { journeys[placeID] = journey }
                checkedJourneys += 1
                if next < candidates.count { submit(candidates[next]); next += 1 }
            }
        }
        guard id == requestID else { return }
        isCheckingJourneys = false
    }
    func assessments(store: ExplorerStore) -> [TripAssessment] {
        guard let query else { return [] }
        return places.map { place in
            TripAssessment(place: place, plan: store.tripPlan, query: query, estimate: store.estimate(for: place, query: query), journey: journeys[place.id])
        }
    }
    func surprise(store: ExplorerStore) -> TripAssessment? {
        let eligible = assessments(store: store).filter { $0.fit == .fits }
        var generator = SystemRandomNumberGenerator()
        guard let place = DestinationMatcher.select(from: eligible.map(\.place), recentIDs: store.preferences.recentIDs, personalization: query?.personalization ?? .none, using: &generator),
              let match = eligible.first(where: { $0.id == place.id }) else { return nil }
        store.latestAssessments[place.id] = match
        store.recordSuggestion(place)
        return match
    }
}
