import SwiftUI
import SwiftData
import UserNotifications

@MainActor @Observable final class ExplorerStore {
    let container: ModelContainer
    let context: ModelContext
    var preferences: ExplorerPreferences
    private(set) var favorites: [FavoritePlace] = []
    private(set) var visits: [VisitRecord] = []
    private(set) var trips: [SavedTrip] = []
    private let discoveryJournal: DiscoveryJournal
    private(set) var onlinePlaces: [Destination] = []
    private(set) var tripPlan = TripPlan()
    private(set) var placeEstimates: [String: PlaceEstimate] = [:]
    var latestAssessments: [String: TripAssessment] = [:]
    var errorMessage: String?
    var stampDestination: Destination?

    init(context: ModelContext) throws {
        self.container = context.container
        self.context = context
        if let existing = try context.fetch(FetchDescriptor<ExplorerPreferences>()).first {
            preferences = existing
        } else {
            let preference = ExplorerPreferences(); context.insert(preference); try context.save(); preferences = preference
        }
        if let journal = try context.fetch(FetchDescriptor<DiscoveryJournal>()).first {
            discoveryJournal = journal
        } else {
            let journal = DiscoveryJournal(); context.insert(journal); try context.save(); discoveryJournal = journal
        }
        try refresh()
    }
    func refresh() throws {
        favorites = try context.fetch(FetchDescriptor<FavoritePlace>(sortBy: [SortDescriptor(\.savedAt, order: .reverse)]))
        visits = try context.fetch(FetchDescriptor<VisitRecord>(sortBy: [SortDescriptor(\.visitedAt, order: .reverse)]))
        trips = try context.fetch(FetchDescriptor<SavedTrip>(sortBy: [SortDescriptor(\.savedAt, order: .reverse)]))
        onlinePlaces = decode([Destination].self, data: discoveryJournal.placesData) ?? []
        tripPlan = decode(TripPlan.self, data: discoveryJournal.planData) ?? TripPlan()
        placeEstimates = decode([String: PlaceEstimate].self, data: discoveryJournal.estimatesData) ?? [:]
    }
    @discardableResult func save() -> Bool {
        do { try context.save(); try refresh(); return true }
        catch { context.rollback(); errorMessage = "Your changes couldn’t be saved. Please try again. \(error.localizedDescription)"; try? refresh(); return false }
    }
    private func decode<T: Decodable>(_ type: T.Type, data: Data?) -> T? {
        guard let data else { return nil }; return try? JSONDecoder().decode(type, from: data)
    }
    func destination(_ id: String) -> Destination? {
        DestinationCatalog.find(id) ?? onlinePlaces.first { $0.id == id }
    }
    var allKnownPlaces: [Destination] { DestinationCatalog.all + onlinePlaces }
    var passportPlaces: [Destination] {
        DestinationCatalog.all + visitedPlaces.filter { $0.source != .bundled }
    }
    func updatePlan(_ value: TripPlan) {
        do { discoveryJournal.planData = try JSONEncoder().encode(value); save() }
        catch { errorMessage = "Your trip preferences couldn’t be saved." }
    }
    var personalization: PersonalizationContext { (tripPlan.personalization ?? PersonalizationPreferences()).context() }
    func checkIn(_ feeling: PersonalFeeling?) {
        var plan = tripPlan; var preferences = plan.personalization ?? PersonalizationPreferences()
        preferences.checkIn(feeling); plan.personalization = preferences; updatePlan(plan)
    }
    func toggleExperience(_ experience: PlaceExperience) {
        var plan = tripPlan; var preferences = plan.personalization ?? PersonalizationPreferences()
        preferences.toggle(experience); plan.personalization = preferences; updatePlan(plan)
    }
    func clearPersonalization() { var plan = tripPlan; plan.personalization = nil; updatePlan(plan) }
    func cachePlaces(_ places: [Destination]) {
        let retainedIDs = Set(favorites.map(\.destinationID) + visits.map(\.destinationID) + trips.map(\.destinationID))
        var merged = Dictionary(onlinePlaces.map { ($0.id, $0) }, uniquingKeysWith: { _, new in new })
        for place in places where place.source != .bundled { merged[place.id] = place }
        let pinned = merged.values.filter { retainedIDs.contains($0.id) }
        let recent = merged.values.filter { !retainedIDs.contains($0.id) }.sorted { ($0.fetchedAt ?? .distantPast) > ($1.fetchedAt ?? .distantPast) }.prefix(150)
        do { discoveryJournal.placesData = try JSONEncoder().encode(Array(pinned) + Array(recent)); save() }
        catch { errorMessage = "The online places couldn’t be saved for offline access." }
    }
    func saveEstimate(_ estimate: PlaceEstimate, for place: Destination, query: NearbyQuery) {
        var values = placeEstimates; values[query.estimateKey(for: place.id)] = estimate
        do { discoveryJournal.estimatesData = try JSONEncoder().encode(values); save() }
        catch { errorMessage = "Your cost estimate couldn’t be saved." }
    }
    func estimate(for place: Destination, query: NearbyQuery) -> PlaceEstimate? { placeEstimates[query.estimateKey(for: place.id)] }
    func isFavorite(_ place: Destination) -> Bool { favorites.contains { $0.destinationID == place.id } }
    func hasVisited(_ place: Destination) -> Bool { visits.contains { $0.destinationID == place.id } }
    func toggleFavorite(_ place: Destination) {
        if let favorite = favorites.first(where: { $0.destinationID == place.id }) { context.delete(favorite) }
        else { context.insert(FavoritePlace(destinationID: place.id)) }
        if save() { UIImpactFeedbackGenerator(style: .soft).impactOccurred() }
    }
    func markVisited(_ place: Destination) {
        guard !hasVisited(place) else { return }
        context.insert(VisitRecord(destinationID: place.id))
        if save() { stampDestination = place; UINotificationFeedbackGenerator().notificationOccurred(.success) }
    }
    func saveTrip(_ place: Destination) {
        guard !trips.contains(where: { $0.destinationID == place.id }) else { return }
        let selectedMoods = preferences.moods.intersection(place.moods)
        let moods = selectedMoods.isEmpty ? place.moods : selectedMoods
        let assessment = latestAssessments[place.id]
        let budget = assessment?.totalCost.map { "Rs. \($0) estimated total" } ?? (place.source == .bundled ? place.budget.label : "Cost not checked")
        let duration = assessment?.totalMinutes.map { "\($0) min incl. return travel" } ?? (place.source == .bundled ? place.durationLabel : "Visit time not checked")
        context.insert(SavedTrip(destinationID: place.id, moodSummary: moods.map(\.rawValue).sorted().joined(separator: " · "), budgetLabel: budget, durationLabel: duration))
        save()
    }
    func removeTrip(_ trip: SavedTrip) { context.delete(trip); save() }
    func recordSuggestion(_ place: Destination) {
        preferences.recentIDsRaw = (preferences.recentIDs.filter { $0 != place.id } + [place.id]).suffix(5).joined(separator: ",")
        save()
    }
    var visitedPlaces: [Destination] { visits.compactMap { destination($0.destinationID) } }
    var districtCount: Int { Set(visitedPlaces.map(\.district).filter { !$0.isEmpty }).count }
    var earnedBadges: Int {
        (visits.isEmpty ? 0 : 1) + (visitedPlaces.contains { $0.category == .waterfalls } ? 1 : 0) + (visitedPlaces.contains { $0.category == .beaches } ? 1 : 0)
    }
}

@MainActor enum ReminderService {
    static func enable() async throws -> Bool {
        let center = UNUserNotificationCenter.current()
        let granted = try await center.requestAuthorization(options: [.alert, .sound])
        guard granted else { return false }
        let content = UNMutableNotificationContent()
        content.title = "A little adventure awaits 🌴"
        content.body = "Make a little room for discovery. Your next Ado Yamu adventure is waiting."
        content.sound = .default
        var date = DateComponents(); date.weekday = 7; date.hour = 9
        let request = UNNotificationRequest(identifier: "weekend-adventure", content: content, trigger: UNCalendarNotificationTrigger(dateMatching: date, repeats: true))
        center.removePendingNotificationRequests(withIdentifiers: ["weekend-adventure"])
        try await center.add(request)
        return true
    }
    static func disable() { UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["weekend-adventure"]) }
}
