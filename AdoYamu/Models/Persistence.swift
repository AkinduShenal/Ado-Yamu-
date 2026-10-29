import Foundation
import SwiftData

@Model final class FavoritePlace {
    @Attribute(.unique) var destinationID: String
    var savedAt: Date
    init(destinationID: String, savedAt: Date = .now) { self.destinationID = destinationID; self.savedAt = savedAt }
}
@Model final class VisitRecord {
    @Attribute(.unique) var destinationID: String
    var visitedAt: Date
    @Attribute(.externalStorage) var photo: Data?
    init(destinationID: String, visitedAt: Date = .now) { self.destinationID = destinationID; self.visitedAt = visitedAt }
}
@Model final class SavedTrip {
    var id: UUID
    var destinationID: String
    var moodSummary: String
    var budgetLabel: String
    var durationLabel: String
    var savedAt: Date
    init(destinationID: String, moodSummary: String, budgetLabel: String, durationLabel: String) {
        id = UUID(); self.destinationID = destinationID; self.moodSummary = moodSummary
        self.budgetLabel = budgetLabel; self.durationLabel = durationLabel; savedAt = .now
    }
}
@Model final class ExplorerPreferences {
    @Attribute(.unique) var key: String
    var name: String
    var onboardingComplete: Bool
    var cityRaw: String
    var moodRaw: String
    var budgetRaw: Int
    var durationRaw: Int
    var recentIDsRaw: String
    var reminderEnabled: Bool
    init() {
        key = "explorer"; name = "Ado Explorer"; onboardingComplete = false; cityRaw = BaseCity.kandy.rawValue
        moodRaw = Mood.chill.rawValue; budgetRaw = 1; durationRaw = 180; recentIDsRaw = ""; reminderEnabled = false
    }
    var city: BaseCity { BaseCity(rawValue: cityRaw) ?? .kandy }
    var moods: Set<Mood> { Set(moodRaw.split(separator: ",").compactMap { Mood(rawValue: String($0)) }) }
    var budget: BudgetTier { BudgetTier(rawValue: budgetRaw) ?? .easy }
    var duration: AdventureDuration { AdventureDuration(rawValue: durationRaw) ?? .unhurried }
    var recentIDs: [String] { recentIDsRaw.split(separator: ",").map(String.init) }
}
