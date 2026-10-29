import SwiftUI

struct SavedView: View {
    @Environment(ExplorerStore.self) private var store
    @Environment(Navigator.self) private var navigator
    @State private var tripsSelected = false
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Saved Places").font(.system(size: 33, weight: .heavy, design: .rounded))
                    Text("Keep a little adventure for later.").font(.subheadline).foregroundStyle(YamuTheme.muted)
                }.padding(.top, 20)
                HStack(spacing: 5) { segment("Places", selected: !tripsSelected) { tripsSelected = false }; segment("Trips", selected: tripsSelected) { tripsSelected = true } }.padding(5).background(.black.opacity(0.04), in: Capsule())
                if tripsSelected {
                    if store.trips.isEmpty {
                        EmptyAdventureView(symbol: "bookmark", title: "Your next chapter is unwritten", message: "Save a trip idea from an adventure’s details. Its mood, planning band and suggested visit time are kept with it.")
                        GradientActionButton(title: "Find an adventure", symbol: "shuffle") { navigator.plan(store: store) }
                    }
                    ForEach(store.trips) { trip in
                        if let place = store.destination(trip.destinationID) {
                            VStack(alignment: .leading, spacing: 12) {
                                SavedDestinationRow(place: place)
                                HStack(alignment: .top) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(trip.moodSummary.isEmpty ? "Any mood" : trip.moodSummary).font(.caption.bold())
                                        Text("\(trip.budgetLabel) · \(trip.durationLabel)").font(.caption).foregroundStyle(YamuTheme.muted)
                                    }
                                    Spacer()
                                    Button(role: .destructive) { store.removeTrip(trip) } label: { Image(systemName: "trash").frame(width: 44, height: 36) }.accessibilityLabel("Remove trip idea for \(place.name)")
                                }.padding(.horizontal, 13).padding(.bottom, 12)
                            }.background(.white, in: RoundedRectangle(cornerRadius: 22))
                        }
                    }
                } else {
                    if store.favorites.isEmpty {
                        EmptyAdventureView(symbol: "heart", title: "A place for your favourites", message: "Tap a heart on any place to keep it here. Your next favourite corner of Sri Lanka is waiting.")
                        GradientActionButton(title: "Explore places", symbol: "magnifyingglass") { navigator.tab = .explore }
                    }
                    LazyVStack(spacing: 13) { ForEach(store.favorites) { favorite in if let place = store.destination(favorite.destinationID) { SavedDestinationRow(place: place) } } }
                }
            }.pagePadding().padding(.bottom, 25)
        }.background(YamuTheme.canvas).toolbar(.hidden, for: .navigationBar)
    }
    private func segment(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) { Text(title).font(.subheadline.weight(.semibold)).frame(maxWidth: .infinity).padding(.vertical, 13).foregroundStyle(selected ? .white : YamuTheme.ink).background(selected ? AnyShapeStyle(YamuTheme.gradient) : AnyShapeStyle(.clear), in: Capsule()) }.buttonStyle(.plain).accessibilityAddTraits(selected ? .isSelected : [])
    }
}
