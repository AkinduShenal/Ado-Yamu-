import SwiftUI

enum AppTab: String, CaseIterable, Identifiable {
    case home = "Home", explore = "Explore", saved = "Saved", profile = "Profile"
    var id: String { rawValue }
    var symbol: String { switch self { case .home: "house"; case .explore: "magnifyingglass.circle"; case .saved: "heart"; case .profile: "person.crop.circle" } }
}
enum Route: Hashable {
    case details(String), map(String), planner, passport, settings, memories, about, achievements
    var isImmersive: Bool {
        switch self { case .passport, .details: true; default: false }
    }
}
@MainActor @Observable final class Navigator {
    var tab: AppTab = .home
    var path: [Route] = []
    var exploreSearch = ""
    var isFinding = false
    func plan(mood: Mood? = nil, store: ExplorerStore) {
        if let mood { store.preferences.moodRaw = mood.rawValue; store.save() }
        path.append(.planner)
    }
}
struct BottomNavigationBar: View {
    @Environment(Navigator.self) private var navigator
    @Environment(ExplorerStore.self) private var store
    var body: some View {
        HStack(spacing: 4) {
            tabButton(.home); tabButton(.explore)
            Button { navigator.plan(store: store) } label: {
                VStack(spacing: 4) {
                    Image(systemName: "shuffle").font(.system(size: 23, weight: .bold)).foregroundStyle(.white)
                        .frame(width: 56, height: 56).background(YamuTheme.gradient, in: Circle())
                        .shadow(color: YamuTheme.purple.opacity(0.26), radius: 8, y: 4)
                    Text("Surprise").font(.caption2).foregroundStyle(YamuTheme.muted)
                }.frame(maxWidth: .infinity)
            }.buttonStyle(PressStyle()).accessibilityLabel("Plan a surprise adventure").accessibilityIdentifier("tab-surprise")
            tabButton(.saved); tabButton(.profile)
        }.padding(.horizontal, 14).padding(.top, 10).padding(.bottom, 4)
            .background(YamuTheme.canvas.opacity(0.98)).overlay(alignment: .top) { Rectangle().fill(.black.opacity(0.05)).frame(height: 0.5) }
    }
    private func tabButton(_ tab: AppTab) -> some View {
        Button { navigator.tab = tab } label: {
            VStack(spacing: 7) {
                Image(systemName: navigator.tab == tab && tab != .explore ? tab.symbol + ".fill" : tab.symbol).font(.system(size: 21))
                Text(tab.rawValue).font(.caption2)
            }.foregroundStyle(navigator.tab == tab ? YamuTheme.purple : YamuTheme.muted).frame(maxWidth: .infinity, minHeight: 60)
        }.buttonStyle(.plain).accessibilityIdentifier("tab-\(tab.rawValue.lowercased())").accessibilityAddTraits(navigator.tab == tab ? .isSelected : [])
    }
}
