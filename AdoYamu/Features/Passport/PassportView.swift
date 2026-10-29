import SwiftUI

struct PassportView: View {
    @Environment(ExplorerStore.self) private var store
    @Environment(Navigator.self) private var navigator
    private var ordered: [Destination] {
        store.visitedPlaces + DestinationCatalog.all.filter { !store.hasVisited($0) }
    }
    var body: some View {
        ZStack {
            ForestBackdrop()
            ScrollView {
                VStack(spacing: 25) {
                    VStack(spacing: 12) {
                        Image(systemName: "sparkles.rectangle.stack.fill").font(.system(size: 34)).foregroundStyle(Color(red: 0.94, green: 0.76, blue: 0.39))
                        Text("My Adventure Passport").font(.system(.title, design: .rounded, weight: .bold)).multilineTextAlignment(.center)
                        Text("Collect stamps as you explore\nbeautiful places in Sri Lanka!").font(.subheadline).multilineTextAlignment(.center).foregroundStyle(.white.opacity(0.8))
                    }.padding(.top, 18)
                    VStack(spacing: 10) {
                        HStack { Text("\(store.visits.count) of \(store.passportPlaces.count) places explored"); Spacer(); Text("\(Int(Double(store.visits.count) / Double(store.passportPlaces.count) * 100))%") }.font(.caption.weight(.semibold))
                        ProgressView(value: Double(store.visits.count), total: Double(store.passportPlaces.count)).tint(Color(red: 0.95, green: 0.76, blue: 0.40))
                    }.padding(18).background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 19))
                    VStack(spacing: 0) {
                        ForEach(Array(ordered.enumerated()), id: \.element.id) { index, place in
                            HStack {
                                if index % 2 == 1 { Spacer(minLength: 0) }
                                Button { navigator.path.append(.details(place.id)) } label: {
                                    PassportStamp(place: place, visited: store.hasVisited(place), date: store.visits.first { $0.destinationID == place.id }?.visitedAt)
                                }.buttonStyle(PressStyle()).frame(width: 160)
                                if index % 2 == 0 { Spacer(minLength: 0) }
                            }
                            if index != ordered.count - 1 {
                                PassportTrail(reverse: index % 2 == 1).stroke(Color(red: 0.83, green: 0.72, blue: 0.35).opacity(0.7), style: StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [3, 7])).frame(height: 38).padding(.horizontal, 76)
                            }
                        }
                    }.padding(.vertical, 10)
                    Text("Stamps are earned only when you mark a place as visited. Your story, at your pace.").font(.caption).multilineTextAlignment(.center).foregroundStyle(.white.opacity(0.65)).padding(.bottom, 25)
                }.pagePadding()
            }
        }.foregroundStyle(.white).navigationBarTitleDisplayMode(.inline).toolbar(.visible, for: .navigationBar).toolbarColorScheme(.dark, for: .navigationBar).tint(.white)
    }
}
struct ForestBackdrop: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                YamuTheme.forest
                Image("welcome").resizable().scaledToFill().frame(width: geometry.size.width, height: geometry.size.height).clipped().opacity(0.13)
                LinearGradient(colors: [YamuTheme.forest.opacity(0.55), Color(red: 0.12, green: 0.23, blue: 0.07).opacity(0.4), YamuTheme.forest], startPoint: .topLeading, endPoint: .bottomTrailing)
                VStack {
                    HStack { Image(systemName: "leaf.fill").rotationEffect(.degrees(38)); Spacer(); Image(systemName: "leaf.fill").rotationEffect(.degrees(-42)) }
                    Spacer()
                    HStack { Image(systemName: "leaf.fill").rotationEffect(.degrees(130)); Spacer(); Image(systemName: "leaf.fill").rotationEffect(.degrees(-120)) }
                }.font(.system(size: 110)).foregroundStyle(Color(red: 0.22, green: 0.35, blue: 0.14).opacity(0.5)).padding(.horizontal, -25)
            }.ignoresSafeArea().accessibilityHidden(true)
        }
    }
}
struct PassportTrail: Shape {
    var reverse: Bool
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let start = CGPoint(x: reverse ? rect.maxX : rect.minX, y: 0)
        let end = CGPoint(x: reverse ? rect.minX : rect.maxX, y: rect.maxY)
        path.move(to: start)
        path.addCurve(to: end, control1: CGPoint(x: rect.midX, y: 0), control2: CGPoint(x: rect.midX, y: rect.maxY))
        return path
    }
}
struct PassportStamp: View {
    let place: Destination
    let visited: Bool
    var date: Date?
    var body: some View {
        VStack(spacing: 9) {
            ZStack(alignment: .bottomTrailing) {
                Group {
                    if visited { DestinationPhoto(place: place) }
                    else { Circle().fill(.white.opacity(0.15)).overlay(Image(systemName: "lock.fill").font(.title2).foregroundStyle(.white.opacity(0.5))) }
                }.frame(width: 92, height: 92).clipShape(Circle())
                    .overlay(Circle().stroke(visited ? .white : .white.opacity(0.3), lineWidth: visited ? 4 : 2))
                    .overlay(Circle().inset(by: -6).stroke(Color(red: 0.91, green: 0.76, blue: 0.40).opacity(visited ? 0.8 : 0.15), style: StrokeStyle(lineWidth: 1, dash: [2, 4])))
                if visited { Image(systemName: "checkmark.seal.fill").font(.title2).foregroundStyle(Color(red: 0.99, green: 0.80, blue: 0.43)).background(YamuTheme.forest, in: Circle()) }
            }
            Text(place.name).font(.system(.subheadline, design: .rounded, weight: .semibold)).multilineTextAlignment(.center).frame(maxWidth: 150)
            if let date, visited { Text(date, format: .dateTime.day().month(.abbreviated).year()).font(.caption2).foregroundStyle(.white.opacity(0.65)) }
            else { Text("A story still to come").font(.caption2).foregroundStyle(.white.opacity(0.5)) }
        }.foregroundStyle(.white).accessibilityElement(children: .combine).accessibilityLabel("\(place.name), \(visited ? "visited, stamp earned" : "not yet visited")")
    }
}
struct StampCelebrationView: View {
    let place: Destination
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false
    var body: some View {
        ZStack {
            ForestBackdrop()
            VStack(spacing: 20) {
                Text("A new story. A new stamp.").font(.system(.title2, design: .rounded, weight: .bold)).multilineTextAlignment(.center)
                PassportStamp(place: place, visited: true, date: .now).scaleEffect(appeared || reduceMotion ? 1 : 1.4).rotationEffect(.degrees(appeared || reduceMotion ? 0 : -12)).opacity(appeared ? 1 : 0)
                Button("Keep exploring") { dismiss() }.font(.headline).foregroundStyle(YamuTheme.forest).padding(.horizontal, 30).padding(.vertical, 14).background(.white, in: Capsule())
            }.foregroundStyle(.white).padding(25)
        }.onAppear { withAnimation(reduceMotion ? nil : .spring(response: 0.55, dampingFraction: 0.58)) { appeared = true } }
    }
}
#Preview { if let store = PreviewEnvironment.store() { NavigationStack { PassportView().environment(store).environment(Navigator()) } } }
