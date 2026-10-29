import SwiftUI

struct HomeView: View {
    @Environment(ExplorerStore.self) private var store
    @Environment(Navigator.self) private var navigator
    @Environment(LocationService.self) private var location
    @State private var query = ""
    private var popular: [Destination] {
        let origin = location.coordinate ?? store.preferences.city.coordinate
        let places = origin.map { origin in DestinationCatalog.all.filter { $0.coordinate.map { origin.kilometers(to: $0) <= 120 } ?? false } } ?? DestinationCatalog.all
        let ordered = !store.personalization.experiences.isEmpty && origin != nil ? places.sorted { lhs, rhs in
            guard let origin else { return false }
            return (lhs.coordinate.map { origin.kilometers(to: $0) } ?? .infinity) < (rhs.coordinate.map { origin.kilometers(to: $0) } ?? .infinity)
        } : places
        return Array(store.personalization.ranked(ordered).prefix(6))
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 17) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Ayubowan, \(store.preferences.name == "Ado Explorer" ? "Explorer" : store.preferences.name) ☀️").font(.caption.weight(.medium)).foregroundStyle(YamuTheme.muted)
                        Text("Ado Yamu!").font(.system(size: 33, weight: .heavy, design: .rounded)).italic()
                        Text("What kind of day are you in for?").font(.subheadline).foregroundStyle(YamuTheme.muted)
                    }
                    Spacer()
                    Button { navigator.path.append(.settings) } label: {
                        Image(systemName: store.preferences.reminderEnabled ? "bell.badge" : "bell").font(.title3).frame(width: 45, height: 45).background(.white, in: Circle())
                    }.foregroundStyle(YamuTheme.ink).accessibilityLabel("Adventure reminders and settings")
                }
                SearchField(text: $query)
                if !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    let results = DestinationMatcher.search(DestinationCatalog.all, text: query)
                    Text("\(results.count) places to discover").font(.caption).foregroundStyle(YamuTheme.muted)
                    if results.isEmpty { EmptyAdventureView(symbol: "magnifyingglass", title: "A little further afield?", message: "Try a district, beach or waterfall name.") }
                    ForEach(results) { SavedDestinationRow(place: $0) }
                } else {
                    HStack(alignment: .top, spacing: 12) {
                        ForEach(Mood.allCases) { mood in MoodButton(mood: mood) { navigator.plan(mood: mood, store: store) } }
                    }
                    HStack {
                        SectionHeading(title: store.personalization.experiences.isEmpty ? "Popular Near You" : "Picked for You")
                        Spacer()
                        Button("See all") { navigator.tab = .explore }.font(.caption).foregroundStyle(YamuTheme.muted)
                    }
                    HStack(spacing: 5) {
                        Image(systemName: "location.fill").font(.caption2)
                        Text(location.coordinate == nil ? "Around \(store.preferences.city == .anywhere ? "Sri Lanka" : store.preferences.city.rawValue) · curated picks" : "Within 120 km · straight-line radius")
                    }.font(.caption).foregroundStyle(YamuTheme.muted).padding(.top, -10)
                    if let feeling = store.personalization.feeling, !store.personalization.experiences.isEmpty {
                        Button { navigator.plan(store: store) } label: {
                            HStack { Text(feeling.face); Text(store.personalization.experienceSummary); Spacer(); Image(systemName: "slider.horizontal.3") }.font(.caption.weight(.medium)).foregroundStyle(YamuTheme.purple)
                        }.accessibilityLabel("Edit your personal adventure preferences")
                    }
                    if popular.isEmpty {
                        Text("No curated places nearby match your choices yet. Try Online nearby or adjust your preferences.").font(.caption).foregroundStyle(YamuTheme.muted).padding(.vertical, 12)
                    }
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .top, spacing: 15) { ForEach(popular) { place in DestinationCard(place: place, compact: true).frame(width: 204) } }.padding(.bottom, 8)
                    }.contentMargins(.trailing, 3)
                    Button { navigator.plan(store: store) } label: {
                        HStack(spacing: 13) {
                            Image(systemName: "map.fill").font(.system(size: 29)).foregroundStyle(Color(red: 0.64, green: 0.33, blue: 0.03)).frame(width: 51, height: 57).background(.white.opacity(0.28), in: RoundedRectangle(cornerRadius: 16))
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Need an Idea?").font(.system(.headline, design: .rounded, weight: .bold))
                                Text("Let’s pick a surprise adventure for you!").font(.caption).multilineTextAlignment(.leading)
                            }
                            Spacer(minLength: 0)
                            Image(systemName: "arrow.right").font(.title3.bold()).foregroundStyle(.white).frame(width: 40, height: 40).background(YamuTheme.gradient, in: Circle())
                        }.foregroundStyle(YamuTheme.ink).padding(16).background(LinearGradient(colors: [Color(red: 1, green: 0.85, blue: 0.58), Color(red: 1, green: 0.72, blue: 0.47)], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 25))
                    }.buttonStyle(PressStyle()).accessibilityIdentifier("needIdea")

                }
            }.pagePadding().padding(.top, 20).padding(.bottom, 22)
        }.background(YamuTheme.canvas).toolbar(.hidden, for: .navigationBar).scrollDismissesKeyboard(.interactively)
    }
}
#Preview { if let store = PreviewEnvironment.store() { NavigationStack { HomeView().environment(store).environment(Navigator()).environment(LocationService()) } } }
