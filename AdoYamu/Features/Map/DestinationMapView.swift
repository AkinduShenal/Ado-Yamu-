import SwiftUI
import MapKit

struct DestinationMapView: View {
    let place: Destination
    @Environment(LocationService.self) private var location
    @Environment(ExplorerStore.self) private var store
    @State private var position: MapCameraPosition = .automatic
    @State private var satellite = false
    var body: some View {
        ZStack(alignment: .topTrailing) {
            if let coordinate = place.coordinate {
                Map(position: $position) {
                    Annotation(place.name, coordinate: coordinate.mapCoordinate, anchor: .bottom) {
                        VStack(spacing: 3) {
                            Image(systemName: place.category.symbol).font(.title3).foregroundStyle(.white).frame(width: 48, height: 48).background(YamuTheme.gradient, in: Circle()).overlay(Circle().stroke(.white, lineWidth: 3)).shadow(radius: 5)
                            Image(systemName: "triangle.fill").font(.caption2).rotationEffect(.degrees(180)).foregroundStyle(YamuTheme.purple)
                        }.accessibilityLabel(place.name)
                    }
                    if let user = location.coordinate { Marker("Your location", systemImage: "location.fill", coordinate: user.mapCoordinate).tint(.blue) }
                }.mapStyle(satellite ? .hybrid(elevation: .realistic) : .standard(elevation: .realistic))
                    .mapControls { MapCompass(); MapScaleView() }
                    .onAppear { position = .region(MKCoordinateRegion(center: coordinate.mapCoordinate, span: MKCoordinateSpan(latitudeDelta: 0.045, longitudeDelta: 0.045))) }
            } else { ContentUnavailableView("Map unavailable", systemImage: "map", description: Text("Coordinates are not available for this place.")) }
            VStack(spacing: 12) {
                Button { satellite.toggle() } label: { Image(systemName: satellite ? "map" : "square.3.layers.3d").frame(width: 46, height: 46).background(.regularMaterial, in: RoundedRectangle(cornerRadius: 15)) }.accessibilityLabel(satellite ? "Show standard map" : "Show satellite map")
                Button { location.request() } label: { Image(systemName: "location").frame(width: 46, height: 46).background(.regularMaterial, in: RoundedRectangle(cornerRadius: 15)) }.accessibilityLabel("Show my location").disabled(location.isRequesting)
                Button { position = .automatic } label: { Image(systemName: "arrow.up.left.and.arrow.down.right").frame(width: 46, height: 46).background(.regularMaterial, in: RoundedRectangle(cornerRadius: 15)) }.accessibilityLabel("Fit all markers")
            }.padding(18).padding(.top, 45)
        }.safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(alignment: .leading, spacing: 15) {
                HStack(spacing: 14) {
                    DestinationPhoto(place: place).frame(width: 80, height: 76).clipShape(RoundedRectangle(cornerRadius: 17))
                    VStack(alignment: .leading, spacing: 6) {
                        Text(place.name).font(.system(.headline, design: .rounded))
                        Text(place.locationDescription).font(.caption).foregroundStyle(YamuTheme.muted)
                        Text("Open Apple Maps to check route availability.").font(.caption2).foregroundStyle(YamuTheme.muted)
                    }
                }
                if let message = location.message { Text(message).font(.caption).foregroundStyle(YamuTheme.muted) }
                Text("Map tiles and navigation require an internet connection. Place details remain available offline.").font(.caption2).foregroundStyle(YamuTheme.muted)
                GradientActionButton(title: "Start Navigation", symbol: "location.fill") { openNavigation() }.disabled(place.coordinate == nil)
            }.padding(20).background(YamuTheme.canvas, in: UnevenRoundedRectangle(topLeadingRadius: 26, topTrailingRadius: 26))
        }.navigationTitle("Map & Directions").navigationBarTitleDisplayMode(.inline).toolbar(.visible, for: .navigationBar)
    }
    private func openNavigation() {
        guard let coordinate = place.coordinate else { return }
        let destination = MKMapItem(placemark: MKPlacemark(coordinate: coordinate.mapCoordinate))
        destination.name = place.name
        let mode = store.latestAssessments[place.id]?.plan.travelMode ?? (place.source == .bundled ? .car : store.tripPlan.travelMode)
        let directionsMode: String
        switch mode {
        case .walking: directionsMode = MKLaunchOptionsDirectionsModeWalking
        case .transit: directionsMode = MKLaunchOptionsDirectionsModeTransit
        case .motorbike, .car: directionsMode = MKLaunchOptionsDirectionsModeDriving
        }
        destination.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: directionsMode])
    }
}
