import SwiftUI

struct ExploreView: View {
    @Environment(ExplorerStore.self) private var store
    @Environment(LocationService.self) private var location
    @Environment(Navigator.self) private var navigator
    @State private var query = ""
    @State private var filter = "All"
    private let categories = ["All", "Nearby", "Waterfalls", "Beaches", "Hiking", "Food", "Nature", "Culture"]
    private var results: [Destination] {
        let found = DestinationMatcher.search(store.allKnownPlaces, text: query, category: PlaceCategory(rawValue: filter))
        if filter == "Nearby", let origin = location.coordinate ?? store.preferences.city.coordinate {
            return found.filter { $0.coordinate.map { origin.kilometers(to: $0) <= 120 } ?? false }
                .sorted { ( $0.coordinate.map { origin.kilometers(to: $0) } ?? .infinity ) < ( $1.coordinate.map { origin.kilometers(to: $0) } ?? .infinity ) }
        }
        return found
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Explore").font(.system(size: 33, weight: .heavy, design: .rounded))
                    Text("Discover amazing places across Sri Lanka").font(.subheadline).foregroundStyle(YamuTheme.muted)
                }.padding(.top, 20)
                SearchField(text: $query)
                ScrollView(.horizontal, showsIndicators: false) { HStack(spacing: 8) { ForEach(categories, id: \.self) { category in CategoryChip(title: category, selected: filter == category) { filter = category } } } }
                if filter == "Nearby" {
                    VStack(alignment: .leading, spacing: 10) {
                        Label(location.coordinate != nil ? "Within 120 km of your location" : store.preferences.city == .anywhere ? "Choose a starting point" : "Within 120 km of \(store.preferences.city.rawValue)", systemImage: "location.circle").font(.caption).foregroundStyle(YamuTheme.muted)
                        if location.coordinate == nil {
                            Button(location.isRequesting ? "Finding your location…" : "Use my location") { location.request() }.font(.subheadline.bold()).disabled(location.isRequesting)
                            if store.preferences.city == .anywhere { Text("Choose a city in Settings to filter nearby places without location access.").font(.caption).foregroundStyle(YamuTheme.muted) }
                        }
                        if let message = location.message { Text(message).font(.caption).foregroundStyle(YamuTheme.muted) }
                    }.padding(15).yamuCard(radius: 18)
                }
                HStack { Text("\(results.count) places to make your day").font(.caption.weight(.medium)).foregroundStyle(YamuTheme.muted); Spacer(); Image(systemName: "sparkle").foregroundStyle(YamuTheme.orange) }
                if results.isEmpty { EmptyAdventureView(symbol: "binoculars", title: "Still a little undiscovered", message: "Try a different category or search. Nearby uses a 120 km straight-line radius.") }
                LazyVStack(spacing: 18) { ForEach(results) { place in DestinationCard(place: place) } }
            }.pagePadding().padding(.bottom, 25)
        }.background(YamuTheme.canvas).toolbar(.hidden, for: .navigationBar).scrollDismissesKeyboard(.interactively)
            .onAppear { if !navigator.exploreSearch.isEmpty { query = navigator.exploreSearch; navigator.exploreSearch = "" } }
    }
}
#Preview { if let store = PreviewEnvironment.store() { ExploreView().environment(store).environment(LocationService()).environment(Navigator()) } }
