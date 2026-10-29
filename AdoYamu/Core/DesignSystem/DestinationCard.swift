import SwiftUI
import MapKit

struct DestinationPhoto: View {
    let place: Destination
    @Environment(ExplorerStore.self) private var store
    private var resolved: Destination { store.destination(place.id) ?? place }
    var body: some View {
        GeometryReader { proxy in
            if !resolved.image.isEmpty {
                Image(resolved.image).resizable().scaledToFill().frame(width: proxy.size.width, height: proxy.size.height).clipped()
            } else if let photo = resolved.photo {
                RemotePlacePhoto(place: resolved, photo: photo).frame(width: proxy.size.width, height: proxy.size.height).clipped()
            } else {
                OnlinePlaceMapPreview(place: resolved).frame(width: proxy.size.width, height: proxy.size.height).clipped()
            }
        }.clipped().contentShape(Rectangle()).accessibilityLabel(resolved.image.isEmpty && resolved.photo == nil ? "Map preview of \(place.name)" : "\(place.name) photograph")
    }
}
struct FavoriteButton: View {
    @Environment(ExplorerStore.self) private var store
    let place: Destination
    var onPhoto = false
    var body: some View {
        Button { store.toggleFavorite(place) } label: {
            Image(systemName: store.isFavorite(place) ? "heart.fill" : "heart")
                .font(.system(size: 19, weight: .semibold)).foregroundStyle(store.isFavorite(place) ? .red : onPhoto ? .white : YamuTheme.muted)
                .frame(width: 44, height: 44).background(onPhoto ? .black.opacity(0.23) : .clear, in: Circle())
        }.buttonStyle(PressStyle()).accessibilityLabel("\(store.isFavorite(place) ? "Unsave" : "Save") \(place.name)")
            .accessibilityIdentifier("favorite-\(place.id)")
    }
}
struct DestinationCard: View {
    @Environment(Navigator.self) private var navigator
    let place: Destination
    var compact = false
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                Button { navigator.path.append(.details(place.id)) } label: {
                    DestinationPhoto(place: place).frame(height: compact ? 142 : 190)
                        .overlay(alignment: .bottomLeading) {
                            Label(place.category.rawValue, systemImage: place.category.symbol).font(.caption2.bold())
                                .padding(.horizontal, 10).padding(.vertical, 7).background(.ultraThinMaterial, in: Capsule()).padding(12)
                        }
                }.buttonStyle(.plain).accessibilityLabel("Explore \(place.name)")
                FavoriteButton(place: place, onPhoto: true).padding(8)
            }
            Button { navigator.path.append(.details(place.id)) } label: {
                VStack(alignment: .leading, spacing: 6) {
                    Text(place.name).font(.system(compact ? .subheadline : .headline, design: .rounded, weight: .bold)).foregroundStyle(YamuTheme.ink)
                    if !compact { Text(place.tags.prefix(2).joined(separator: " · ")).font(.caption).foregroundStyle(YamuTheme.muted).lineLimit(2) }
                    Label(place.locationDescription, systemImage: "mappin.and.ellipse").font(.caption2).foregroundStyle(YamuTheme.muted)
                }.frame(maxWidth: .infinity, alignment: .leading).padding(14)
            }.buttonStyle(.plain)
        }.yamuCard(radius: 22).clipShape(RoundedRectangle(cornerRadius: 22))
    }
}
struct SavedDestinationRow: View {
    @Environment(Navigator.self) private var navigator
    let place: Destination
    var body: some View {
        HStack(spacing: 13) {
            Button { navigator.path.append(.details(place.id)) } label: {
                HStack(spacing: 13) {
                    DestinationPhoto(place: place).frame(width: 88, height: 94).clipShape(RoundedRectangle(cornerRadius: 15))
                    VStack(alignment: .leading, spacing: 8) {
                        Text(place.name).font(.system(.subheadline, design: .rounded, weight: .bold)).foregroundStyle(YamuTheme.ink)
                        Text(place.locality).font(.caption).foregroundStyle(YamuTheme.muted)
                        Text(place.category.rawValue).font(.caption2.weight(.medium)).padding(.horizontal, 9).padding(.vertical, 5).background(.black.opacity(0.045), in: Capsule())
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }
            }.buttonStyle(.plain)
            FavoriteButton(place: place)
        }.padding(10).yamuCard(radius: 20)
    }
}

@MainActor private enum PlaceSnapshotCache {
    static let images: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>(); cache.countLimit = 24; return cache
    }()
}
struct OnlinePlaceMapPreview: View {
    let place: Destination
    @State private var snapshot: UIImage?
    @State private var snapshotter: MKMapSnapshotter?
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                YamuTheme.gradient.opacity(0.2)
                if let snapshot { Image(uiImage: snapshot).resizable().scaledToFill().frame(width: geometry.size.width, height: geometry.size.height).clipped() }
                else { Image(systemName: "map").font(.system(size: 44)).foregroundStyle(YamuTheme.purple.opacity(0.45)) }
                Image(systemName: "mappin.circle.fill").font(.system(size: 35)).foregroundStyle(YamuTheme.purple, .white).shadow(radius: 3)
            }.overlay(alignment: .topLeading) {
                Text("Map preview").font(.caption2.bold()).padding(7).background(.regularMaterial, in: Capsule()).padding(10)
            }.clipped().contentShape(Rectangle())
        }.allowsHitTesting(false).task(id: place.id) {
            if let cached = PlaceSnapshotCache.images.object(forKey: place.id as NSString) { snapshot = cached; return }
            guard let coordinate = place.coordinate else { return }
            let options = MKMapSnapshotter.Options()
            options.region = MKCoordinateRegion(center: coordinate.mapCoordinate, span: MKCoordinateSpan(latitudeDelta: 0.012, longitudeDelta: 0.012))
            options.size = CGSize(width: 480, height: 300); options.scale = 1
            let request = MKMapSnapshotter(options: options); snapshotter = request
            do {
                let result = try await request.start()
                guard !Task.isCancelled else { return }
                snapshot = result.image; PlaceSnapshotCache.images.setObject(result.image, forKey: place.id as NSString)
            } catch { /* Keep the labelled map illustration when tiles are unavailable. */ }
        }.onDisappear { snapshotter?.cancel() }
    }
}
