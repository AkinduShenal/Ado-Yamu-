import SwiftUI

struct AdventureDetailsView: View {
    let place: Destination
    @Environment(ExplorerStore.self) private var store
    @Environment(Navigator.self) private var navigator
    @Environment(\.dismiss) private var dismiss
    @State private var showPhoto = false
    private var tripSaved: Bool { store.trips.contains { $0.destinationID == place.id } }
    private var currentPlace: Destination { store.destination(place.id) ?? place }
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                DestinationPhoto(place: place).frame(height: 340)
                    .overlay(LinearGradient(colors: [.black.opacity(0.20), .clear, .black.opacity(0.08)], startPoint: .top, endPoint: .bottom))
                    .overlay(alignment: .bottomLeading) {
                        Label("A little adventure awaits", systemImage: "sparkles").font(.caption.bold()).foregroundStyle(Color(red: 0.53, green: 0.27, blue: 0.06))
                            .padding(.horizontal, 14).padding(.vertical, 10).background(Color(red: 1, green: 0.88, blue: 0.66), in: Capsule()).padding(.leading, 23).padding(.bottom, 28)
                    }
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 9) {
                        Text(place.name).font(.system(.largeTitle, design: .rounded, weight: .heavy)).fixedSize(horizontal: false, vertical: true)
                        Label(place.locationDescription, systemImage: "mappin.and.ellipse").font(.subheadline).foregroundStyle(YamuTheme.muted)
                    }
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 17) { metadata }
                        VStack(alignment: .leading, spacing: 10) { metadata }
                    }.font(.caption.weight(.medium))
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 7) { ForEach(place.tags, id: \.self) { tag in Text(tag).font(.caption.weight(.medium)).padding(.horizontal, 13).padding(.vertical, 8).background(YamuTheme.orange.opacity(0.16), in: Capsule()) } }
                    }
                    if let reason = store.personalization.reason(for: place) {
                        Label(reason, systemImage: "sparkles").font(.subheadline.weight(.medium)).foregroundStyle(YamuTheme.purple)
                            .padding(14).frame(maxWidth: .infinity, alignment: .leading).background(YamuTheme.purple.opacity(0.06), in: RoundedRectangle(cornerRadius: 16))
                            .accessibilityIdentifier("personalizedMatchReason")
                    }
                    if place.source == .bundled, let website = place.website { Link("Check venue access", destination: website).font(.subheadline.bold()) }
                    Text(place.summary).font(.body).lineSpacing(5).foregroundStyle(YamuTheme.ink.opacity(0.85))
                    HStack(spacing: 10) {
                        Image(systemName: "info.circle").foregroundStyle(YamuTheme.purple)
                        Text(place.source == .bundled ? "Budget is an illustrative planning band, not an admission fee. Visit duration excludes travel. Confirm local access before leaving." : "Online search does not supply admission prices or a visit duration. Use your trip plan and confirm prices and access with the venue.").font(.caption).foregroundStyle(YamuTheme.muted)
                    }.padding(14).background(YamuTheme.purple.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
                    if let photo = currentPlace.photo { PlacePhotoCredit(photo: photo) }
                    if !currentPlace.image.isEmpty || currentPlace.photo != nil { Button { showPhoto = true } label: {
                        DestinationPhoto(place: place).frame(height: 145).clipShape(RoundedRectangle(cornerRadius: 20))
                            .overlay(alignment: .bottomTrailing) { Label("View photo", systemImage: "arrow.up.left.and.arrow.down.right").font(.caption.bold()).foregroundStyle(.white).padding(10).background(.black.opacity(0.35), in: Capsule()).padding(12) }
                    }.buttonStyle(.plain).accessibilityLabel("Enlarge photo of \(place.name)") }
                    if place.source != .bundled {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Discovered on \(place.source.label)", systemImage: "network").font(.subheadline.bold())
                            if let date = place.fetchedAt { Text("Fetched \(date.formatted(date: .abbreviated, time: .shortened))").font(.caption).foregroundStyle(YamuTheme.muted) }
                            if let url = place.website { Link("Venue website", destination: url) }
                            if let phone = place.phone { Text("Phone: \(phone)").font(.subheadline).textSelection(.enabled) }
                            if let url = place.sourceURL { Link("View source on \(place.source.label)", destination: url) }
                            if let assessment = store.latestAssessments[place.id] { Text(assessment.notes).font(.caption).foregroundStyle(YamuTheme.muted) }
                        }.padding(16).yamuCard(radius: 18)
                    }
                    GradientActionButton(title: "View Map & Directions", symbol: "arrow.up.right") { navigator.path.append(.map(place.id)) }.disabled(place.coordinate == nil)
                    Button { store.markVisited(place) } label: {
                        Label(store.hasVisited(place) ? "Stamped in your passport" : "Mark as Visited", systemImage: store.hasVisited(place) ? "checkmark.seal.fill" : "checkmark.seal")
                            .font(.system(.headline, design: .rounded)).frame(maxWidth: .infinity).padding(17)
                            .foregroundStyle(store.hasVisited(place) ? Color.green : YamuTheme.purple)
                            .background(YamuTheme.purple.opacity(0.08), in: Capsule())
                    }.buttonStyle(PressStyle()).disabled(store.hasVisited(place)).accessibilityIdentifier("markVisited")
                    HStack(spacing: 16) {
                        Button { store.saveTrip(place) } label: { Label(tripSaved ? "Trip idea saved" : "Save trip idea", systemImage: tripSaved ? "bookmark.fill" : "bookmark") }.disabled(tripSaved)
                        Spacer()
                        Button("Try another") { navigator.path.append(.planner) }
                    }.font(.subheadline.weight(.semibold)).padding(.vertical, 5)
                }.padding(23).frame(maxWidth: .infinity, alignment: .leading).background(YamuTheme.canvas, in: UnevenRoundedRectangle(topLeadingRadius: 30, topTrailingRadius: 30)).padding(.top, -18)
            }
        }.background(YamuTheme.canvas).ignoresSafeArea(edges: .top).navigationBarBackButtonHidden().toolbar(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button { dismiss() } label: { Image(systemName: "arrow.left").font(.headline).foregroundStyle(.white).frame(width: 40, height: 40).background(.ultraThinMaterial, in: Circle()) }.accessibilityLabel("Back") }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    FavoriteButton(place: place, onPhoto: true)
                    ShareLink(item: place.shareText) { Image(systemName: "square.and.arrow.up").font(.headline).foregroundStyle(.white).frame(width: 40, height: 40).background(.ultraThinMaterial, in: Circle()) }.accessibilityLabel("Share \(place.name)")
                }
            }.sheet(isPresented: $showPhoto) {
                NavigationStack {
                    ZStack {
                        Color.black.ignoresSafeArea()
                        if !currentPlace.image.isEmpty { Image(currentPlace.image).resizable().scaledToFit().accessibilityLabel("\(place.name) photograph") }
                        else if let photo = currentPlace.photo { RemotePlacePhoto(place: currentPlace, photo: photo, contentMode: .fit).accessibilityLabel("\(place.name) photograph") }
                    }
                        .navigationTitle(place.name).navigationBarTitleDisplayMode(.inline).toolbar(.visible, for: .navigationBar)
                        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { showPhoto = false } } }
                }.preferredColorScheme(.dark)
            }
    }
    @ViewBuilder private var metadata: some View {
        Label(place.category.rawValue, systemImage: place.category.symbol)
        if place.source == .bundled {
            Label(place.durationLabel, systemImage: "clock")
            Label("\(place.budget.label) band", systemImage: "banknote")
        } else {
            if let assessment = store.latestAssessments[place.id] {
                Label(assessment.totalMinutes.map { "\($0) min incl. travel" } ?? "Check journey time", systemImage: "clock")
                Label(assessment.totalCost.map { "Rs. \($0) estimated" } ?? "Costs need checking", systemImage: "banknote")
            } else { Label("Costs need checking", systemImage: "banknote") }
        }
    }
}
#Preview { if let store = PreviewEnvironment.store(), let place = DestinationCatalog.all.first { NavigationStack { AdventureDetailsView(place: place).environment(store).environment(Navigator()) } } }
