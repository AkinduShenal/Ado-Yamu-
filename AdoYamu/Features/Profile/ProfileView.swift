import SwiftUI
import PhotosUI

struct ProfileView: View {
    @Environment(ExplorerStore.self) private var store
    @Environment(Navigator.self) private var navigator
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                HStack { Spacer(); Button { navigator.path.append(.settings) } label: { Image(systemName: "gearshape").font(.title3).frame(width: 44, height: 44) }.accessibilityLabel("Settings") }
                VStack(spacing: 12) {
                    ZStack {
                        Image("welcome").resizable().scaledToFill().frame(width: 92, height: 92).clipShape(Circle())
                        Image(systemName: "figure.hiking").font(.system(size: 45, weight: .bold)).foregroundStyle(.white).shadow(radius: 4)
                    }.overlay(Circle().stroke(.white, lineWidth: 4)).shadow(color: .black.opacity(0.08), radius: 12, y: 5)
                    Text(store.preferences.name.isEmpty ? "Ado Explorer" : store.preferences.name).font(.system(.title2, design: .rounded, weight: .bold))
                    Text("Exploring Sri Lanka, one adventure\nat a time. 🇱🇰").font(.subheadline).foregroundStyle(YamuTheme.muted).multilineTextAlignment(.center)
                }.padding(.top, -28)
                HStack {
                    AdventureStat(value: "\(store.visits.count)", label: "Places visited")
                    Divider().frame(height: 30)
                    AdventureStat(value: "\(store.districtCount)", label: "Districts")
                    Divider().frame(height: 30)
                    AdventureStat(value: "\(store.earnedBadges)", label: "Badges")
                }.padding(.vertical, 22).yamuCard()
                Button { navigator.path.append(.passport) } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "book.closed.fill").font(.title2).foregroundStyle(Color(red: 0.97, green: 0.80, blue: 0.40))
                        VStack(alignment: .leading, spacing: 5) { Text("My Adventure Passport").font(.system(.headline, design: .rounded)); Text("Your places. Your stories. Your stamps.").font(.caption).foregroundStyle(.white.opacity(0.7)) }
                        Spacer(minLength: 0); Image(systemName: "arrow.right")
                    }.foregroundStyle(.white).padding(20).background(LinearGradient(colors: [YamuTheme.forest, Color(red: 0.14, green: 0.29, blue: 0.17)], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 24))
                }.buttonStyle(PressStyle()).accessibilityIdentifier("openPassport")
                VStack(alignment: .leading, spacing: 18) {
                    HStack { SectionHeading(title: "Achievements"); Spacer(); Button("See all") { navigator.path.append(.achievements) }.font(.caption).foregroundStyle(YamuTheme.muted) }
                    HStack(alignment: .top, spacing: 12) { ForEach(ExplorerBadge.all) { badge in BadgeView(badge: badge, earned: badge.isEarned(store)) } }
                }
                VStack(spacing: 2) {
                    profileRow("My Photo Memories", symbol: "photo.on.rectangle.angled", route: .memories)
                    profileRow("Settings", symbol: "gearshape", route: .settings)
                    profileRow("About Ado Yamu!", symbol: "info.circle", route: .about)
                }.padding(.horizontal, 14).yamuCard(radius: 22)
                Text("Made for the joy of a little detour.").font(.caption).foregroundStyle(YamuTheme.muted).padding(.bottom, 5)
            }.pagePadding().padding(.top, 10).padding(.bottom, 22)
        }.background(YamuTheme.canvas).toolbar(.hidden, for: .navigationBar)
    }
    private func profileRow(_ title: String, symbol: String, route: Route) -> some View {
        Button { navigator.path.append(route) } label: {
            HStack(spacing: 14) { Image(systemName: symbol).frame(width: 24); Text(title).font(.subheadline); Spacer(); Image(systemName: "chevron.right").font(.caption).foregroundStyle(YamuTheme.muted) }.foregroundStyle(YamuTheme.ink).padding(.vertical, 18)
        }.buttonStyle(.plain)
    }
}
struct ExplorerBadge: Identifiable {
    let id: String
    let name: String
    let symbol: String
    let color: Color
    let explanation: String
    @MainActor func isEarned(_ store: ExplorerStore) -> Bool {
        switch id { case "first": !store.visits.isEmpty
        case "waterfall": store.visitedPlaces.contains { $0.category == .waterfalls }
        default: store.visitedPlaces.contains { $0.category == .beaches } }
    }
    static let all = [
        ExplorerBadge(id: "first", name: "First Adventure", symbol: "medal.fill", color: .red, explanation: "Mark your first destination as visited."),
        ExplorerBadge(id: "waterfall", name: "Waterfall Lover", symbol: "water.waves", color: .green, explanation: "Visit a waterfall and earn its passport stamp."),
        ExplorerBadge(id: "coast", name: "Coast Explorer", symbol: "sun.horizon.fill", color: .orange, explanation: "Visit a beach and mark it in your passport.")
    ]
}
struct BadgeView: View {
    let badge: ExplorerBadge
    let earned: Bool
    var body: some View {
        VStack(spacing: 10) {
            ZStack(alignment: .bottomTrailing) {
                Image(systemName: badge.symbol).font(.system(size: 29, weight: .medium)).foregroundStyle(earned ? badge.color : YamuTheme.muted)
                    .frame(width: 74, height: 74).background((earned ? badge.color : Color.gray).opacity(0.12), in: Circle())
                    .overlay(Circle().inset(by: 4).stroke((earned ? badge.color : Color.gray).opacity(0.45), lineWidth: 2))
                if !earned { Image(systemName: "lock.circle.fill").foregroundStyle(YamuTheme.muted, .white) }
            }
            Text(badge.name).font(.caption2.weight(.medium)).multilineTextAlignment(.center)
        }.frame(maxWidth: .infinity).accessibilityElement(children: .combine).accessibilityLabel("\(badge.name), \(earned ? "earned" : "locked")")
    }
}
struct AchievementsView: View {
    @Environment(ExplorerStore.self) private var store
    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Text("Every little adventure counts.").font(.system(.title2, design: .rounded, weight: .bold)).frame(maxWidth: .infinity, alignment: .leading)
                ForEach(ExplorerBadge.all) { badge in HStack(spacing: 18) {
                    BadgeView(badge: badge, earned: badge.isEarned(store)).frame(width: 95)
                    VStack(alignment: .leading, spacing: 7) { Text(badge.isEarned(store) ? "Earned!" : "Still to discover").font(.headline); Text(badge.explanation).font(.subheadline).foregroundStyle(YamuTheme.muted) }
                    Spacer(minLength: 0)
                }.padding(18).yamuCard() }
            }.padding(22)
        }.background(YamuTheme.canvas).navigationTitle("Achievements").navigationBarTitleDisplayMode(.inline).toolbar(.visible, for: .navigationBar)
    }
}

struct MemoriesView: View {
    @Environment(ExplorerStore.self) private var store
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("A little moment, kept forever.").font(.system(.title2, design: .rounded, weight: .bold))
                Text("Attach a photo to a place you’ve visited. Photos stay in your on-device journal.").font(.subheadline).foregroundStyle(YamuTheme.muted)
                if store.visits.isEmpty { EmptyAdventureView(symbol: "camera.macro", title: "Make your first memory", message: "Mark a destination as visited, then add your own photo here.") }
                ForEach(store.visits) { visit in
                    if let place = store.destination(visit.destinationID) { MemoryCard(visit: visit, place: place) }
                }
            }.padding(22)
        }.background(YamuTheme.canvas).navigationTitle("Photo Memories").navigationBarTitleDisplayMode(.inline).toolbar(.visible, for: .navigationBar)
    }
}
private struct MemoryCard: View {
    let visit: VisitRecord
    let place: Destination
    @Environment(ExplorerStore.self) private var store
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoError: String?
    @State private var loading = false
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let data = visit.photo, let image = UIImage(data: data) {
                GeometryReader { geometry in
                    Image(uiImage: image).resizable().scaledToFill().frame(width: geometry.size.width, height: 210).clipped()
                }.frame(height: 210).clipShape(RoundedRectangle(cornerRadius: 18)).accessibilityLabel("Your photo from \(place.name)")
            }
            HStack {
                VStack(alignment: .leading, spacing: 4) { Text(place.name).font(.headline); Text(visit.visitedAt, format: .dateTime.day().month().year()).font(.caption).foregroundStyle(YamuTheme.muted) }
                Spacer()
                if loading { ProgressView() }
                else { PhotosPicker(selection: $selectedPhoto, matching: .images) { Label(visit.photo == nil ? "Add photo" : "Change", systemImage: "photo.badge.plus").font(.caption.bold()) } }
            }
            if visit.photo != nil { Button("Remove photo", role: .destructive) { visit.photo = nil; store.save() }.font(.caption) }
        }.padding(16).yamuCard()
            .onChange(of: selectedPhoto) { _, item in
                guard let item else { return }
                loading = true
                Task {
                    defer { loading = false; selectedPhoto = nil }
                    do {
                        guard let data = try await item.loadTransferable(type: Data.self), let image = UIImage(data: data),
                              let resized = await image.byPreparingThumbnail(ofSize: CGSize(width: 1600, height: 1600)),
                              let jpeg = resized.jpegData(compressionQuality: 0.8) else { photoError = "This photo couldn’t be opened. Please try another image."; return }
                        visit.photo = jpeg; store.save()
                    } catch { photoError = "This photo couldn’t be loaded. Please try again." }
                }
            }.alert("Photo unavailable", isPresented: Binding(get: { photoError != nil }, set: { if !$0 { photoError = nil } })) { Button("OK") { photoError = nil } } message: { Text(photoError ?? "") }
    }
}
#Preview { if let store = PreviewEnvironment.store() { ProfileView().environment(store).environment(Navigator()) } }
