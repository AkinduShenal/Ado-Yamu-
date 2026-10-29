import SwiftUI
import SwiftData

@main struct AdoYamuApp: App {
    private let startup: Result<ExplorerStore, Error>
    init() {
        do {
            let schema = Schema([FavoritePlace.self, VisitRecord.self, SavedTrip.self, ExplorerPreferences.self, DiscoveryJournal.self])
            let testing = ProcessInfo.processInfo.arguments.contains("--uitesting")
            let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: testing)
            let container = try ModelContainer(for: schema, configurations: [configuration])
            startup = .success(try ExplorerStore(context: container.mainContext))
        } catch { startup = .failure(error) }
    }
    var body: some Scene {
        WindowGroup {
            switch startup {
            case .success(let store): RootView().environment(store).modelContainer(store.container)
            case .failure(let error):
                ContentUnavailableView("Couldn’t open your adventure journal", systemImage: "externaldrive.badge.exclamationmark", description: Text("Please restart the app. Your stored data has not been replaced. \(error.localizedDescription)"))
            }
        }
    }
}
struct RootView: View {
    @Environment(ExplorerStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showsLaunchSplash = true
    @State private var navigator = Navigator()
    @State private var location = LocationService()
    var body: some View {
        @Bindable var navigation = navigator
        @Bindable var storage = store
        ZStack {
            Group {
                if store.preferences.onboardingComplete {
                    NavigationStack(path: $navigation.path) {
                        Group {
                            switch navigator.tab {
                            case .home: HomeView()
                            case .explore: ExploreView()
                            case .saved: SavedView()
                            case .profile: ProfileView()
                            }
                        }.safeAreaInset(edge: .bottom, spacing: 0) { BottomNavigationBar() }
                            .navigationDestination(for: Route.self) { route in
                                switch route {
                                case .details(let id): if let place = store.destination(id) { AdventureDetailsView(place: place) }
                                case .map(let id): if let place = store.destination(id) { DestinationMapView(place: place) }
                                case .planner: AdventurePlannerView()
                                case .passport: PassportView()
                                case .settings: SettingsView()
                                case .memories: MemoriesView()
                                case .about: AboutView()
                                case .achievements: AchievementsView()
                                }
                            }
                    }.tint(navigator.path.last == .passport ? .white : YamuTheme.purple)
                } else { WelcomeView() }
            }
            .allowsHitTesting(!showsLaunchSplash)
            .accessibilityHidden(showsLaunchSplash)

            if showsLaunchSplash {
                WelcomeView(showsGetStarted: false)
                    .transition(reduceMotion ? .identity : .opacity)
                    .zIndex(1)
            }
        }.environment(navigator).environment(location).preferredColorScheme(showsLaunchSplash || !store.preferences.onboardingComplete || navigator.isFinding || navigator.path.last?.isImmersive == true ? .dark : .light)
            .foregroundStyle(YamuTheme.ink)
            .onChange(of: scenePhase) { _, phase in
                // Inactive also occurs for permission alerts and Control Centre.
                // Show the splash again only after the app actually enters the background.
                if phase == .background { showsLaunchSplash = true }
            }
            .task(id: scenePhase) {
                guard scenePhase == .active, showsLaunchSplash else { return }
                do { try await Task.sleep(for: .milliseconds(900)) }
                catch { return }
                guard !Task.isCancelled else { return }
                withAnimation(reduceMotion ? nil : .easeOut(duration: 0.15)) {
                    showsLaunchSplash = false
                }
            }
            .alert("Couldn’t save changes", isPresented: Binding(get: { store.errorMessage != nil }, set: { if !$0 { store.errorMessage = nil } })) {
                Button("OK", role: .cancel) { store.errorMessage = nil }
            } message: { Text(store.errorMessage ?? "Please try again.") }
            .sheet(item: $storage.stampDestination) { place in StampCelebrationView(place: place).presentationDetents([.medium]) }
    }
}
@MainActor enum PreviewEnvironment {
    static func store() -> ExplorerStore? {
        guard let container = try? ModelContainer(for: FavoritePlace.self, VisitRecord.self, SavedTrip.self, ExplorerPreferences.self, DiscoveryJournal.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)) else { return nil }
        return try? ExplorerStore(context: container.mainContext)
    }
}
#Preview { if let store = PreviewEnvironment.store() { RootView().environment(store) } }
