import Foundation

enum PersonalFeeling: String, CaseIterable, Codable, Identifiable {
    case happy, calm, sad, stressed, tired, excited
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var face: String {
        switch self { case .happy: "🙂"; case .calm: "😌"; case .sad: "😔"; case .stressed: "😣"; case .tired: "😴"; case .excited: "🤩" }
    }
}

enum PlaceExperience: String, CaseIterable, Codable, Identifiable {
    case seaside, temple, greenery, wander, food, active
    var id: String { rawValue }
    var title: String {
        switch self { case .seaside: "By the sea"; case .temple: "A temple"; case .greenery: "Green spaces"; case .wander: "A little walk"; case .food: "Food & cafés"; case .active: "An active escape" }
    }
    var symbol: String {
        switch self { case .seaside: "beach.umbrella.fill"; case .temple: "building.columns.fill"; case .greenery: "leaf.fill"; case .wander: "figure.walk"; case .food: "cup.and.saucer.fill"; case .active: "mountain.2.fill" }
    }
}

struct PersonalizationPreferences: Codable, Equatable {
    var feeling: PersonalFeeling?
    var checkedInAt: Date?
    var choicesByFeeling: [String: [PlaceExperience]] = [:]

    func context(at now: Date = .now, calendar: Calendar = .autoupdatingCurrent) -> PersonalizationContext {
        guard let feeling, let checkedInAt, calendar.isDate(checkedInAt, inSameDayAs: now) else { return .none }
        return PersonalizationContext(feeling: feeling, experiences: Set(choicesByFeeling[feeling.rawValue] ?? []))
    }
    mutating func checkIn(_ feeling: PersonalFeeling?, at date: Date = .now) {
        self.feeling = feeling; checkedInAt = feeling == nil ? nil : date
    }
    mutating func toggle(_ experience: PlaceExperience, at date: Date = .now) {
        guard let feeling = context(at: date).feeling else { return }
        var values = Set(choicesByFeeling[feeling.rawValue] ?? [])
        if values.contains(experience) { values.remove(experience) } else { values.insert(experience) }
        choicesByFeeling[feeling.rawValue] = values.sorted { $0.rawValue < $1.rawValue }
    }
}

struct PersonalizationContext: Hashable {
    var feeling: PersonalFeeling?
    var experiences: Set<PlaceExperience> = []
    static let none = PersonalizationContext()
    var experienceSummary: String { PlaceExperience.allCases.filter(experiences.contains).map(\.title).joined(separator: " · ") }
    func accepts(_ place: Destination) -> Bool { experiences.isEmpty || !experiences.isDisjoint(with: place.experiences) }
    func score(_ place: Destination) -> Int { experiences.isEmpty ? 0 : experiences.intersection(place.experiences).count }
    func reason(for place: Destination) -> String? {
        guard feeling != nil else { return nil }
        let matched = PlaceExperience.allCases.filter { experiences.contains($0) && place.experiences.contains($0) }
        guard !matched.isEmpty else { return nil }
        return "Matches your pick: " + matched.map(\.title).joined(separator: " · ")
    }
    func ranked(_ places: [Destination]) -> [Destination] {
        guard !experiences.isEmpty else { return places }
        return places.enumerated().compactMap { index, place -> (index: Int, place: Destination, score: Int)? in
            let value = score(place)
            return value > 0 ? (index, place, value) : nil
        }.sorted { $0.score == $1.score ? $0.index < $1.index : $0.score > $1.score }.map(\.place)
    }
}

extension Destination {
    var experiences: Set<PlaceExperience> {
        if let experienceTags { return Set(experienceTags) }
        // Online providers often lack experience metadata. Use only the venue
        // name/category, never descriptions mentioning a nearby temple or café.
        var result: Set<PlaceExperience> = []
        if Self.isTempleName(name) { result.insert(.temple) }
        switch category {
        case .beaches: result.formUnion([.seaside, .wander])
        case .food: result.insert(.food)
        case .hiking: result.insert(.active)
        case .nature:
            let words = Set(name.lowercased().components(separatedBy: CharacterSet.alphanumerics.inverted))
            if !words.isDisjoint(with: ["park", "garden", "gardens", "lake"]) { result.formUnion([.greenery, .wander]) }
        case .culture, .waterfalls: break
        }
        return result
    }
    static func isTempleName(_ name: String) -> Bool {
        let words = Set(name.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en")).components(separatedBy: CharacterSet.alphanumerics.inverted))
        guard words.isDisjoint(with: ["hotel", "cafe", "restaurant", "road", "museum", "trail", "view", "school"]) else { return false }
        return !words.isDisjoint(with: ["temple", "vihara", "viharaya", "kovil", "maligawa"])
    }
}
