import SwiftUI

struct BundledPlannerView: View {
    @Environment(ExplorerStore.self) private var store
    @Environment(Navigator.self) private var navigator
    @Environment(LocationService.self) private var location
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var useCurrentLocation = false
    @State private var finding = false
    @State private var match: Destination?
    @State private var noMatch = false
    private var criteria: AdventureConstraints {
        AdventureConstraints(moods: store.preferences.moods, budget: store.preferences.budget, duration: store.preferences.duration,
                             origin: useCurrentLocation ? location.coordinate ?? store.preferences.city.coordinate : store.preferences.city.coordinate,
                             personalization: store.personalization)
    }
    var body: some View {
        Group {
            if finding { FindingAdventureView(reveal: reveal) }
            else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        VStack(spacing: 8) {
                            Text("Plan Your Adventure").font(.system(.title, design: .rounded, weight: .bold)).multilineTextAlignment(.center)
                            Text("Bundled sample ideas, available offline.\nFor a full return-trip budget, choose Online nearby.").font(.subheadline).foregroundStyle(YamuTheme.muted).multilineTextAlignment(.center)
                        }.frame(maxWidth: .infinity).padding(.top, 8)
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeading(title: "What’s your mood?")
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                ForEach(Mood.allCases) { mood in
                                    MoodButton(mood: mood, selected: store.preferences.moods.contains(mood), expanded: true) {
                                        var selection = store.preferences.moods
                                        if selection.contains(mood) { selection.remove(mood) } else { selection.insert(mood) }
                                        store.preferences.moodRaw = selection.map(\.rawValue).sorted().joined(separator: ","); store.save()
                                    }
                                }
                            }
                            Text(store.preferences.moods.isEmpty ? "All moods welcome" : "We’ll match any selected mood").font(.caption).foregroundStyle(YamuTheme.muted)
                        }
                        FeelingCheckInView()
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeading(title: "Budget (per person)")
                            adaptiveChoices { ForEach(BudgetTier.allCases) { tier in CategoryChip(title: tier.label, selected: store.preferences.budget == tier) { store.preferences.budgetRaw = tier.rawValue; store.save() } } }
                            Text("Illustrative planning bands · not admission prices. Travel costs excluded.").font(.caption2).foregroundStyle(YamuTheme.muted)
                        }
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeading(title: "Time available")
                            adaptiveChoices { ForEach(AdventureDuration.allCases) { duration in CategoryChip(title: duration.label, selected: store.preferences.duration == duration) { store.preferences.durationRaw = duration.rawValue; store.save() } } }
                            Text("Time to enjoy the place, excluding your journey.").font(.caption2).foregroundStyle(YamuTheme.muted)
                        }
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeading(title: "From your location")
                            Button {
                                useCurrentLocation = true; location.request()
                            } label: {
                                HStack {
                                    Image(systemName: "location.circle.fill").foregroundStyle(YamuTheme.purple)
                                    Text(location.isRequesting ? "Finding your location…" : useCurrentLocation && location.coordinate != nil ? "Using your current location" : "Use current location").font(.subheadline.weight(.semibold))
                                    Spacer(); if location.isRequesting { ProgressView() } else { Image(systemName: "location.viewfinder") }
                                }.padding(16).yamuCard(radius: 18)
                            }.buttonStyle(.plain).disabled(location.isRequesting)
                            Picker("Fallback city", selection: Binding(get: { store.preferences.cityRaw }, set: { store.preferences.cityRaw = $0; useCurrentLocation = false; store.save() })) {
                                ForEach(BaseCity.allCases) { city in Text(city.rawValue).tag(city.rawValue) }
                            }.pickerStyle(.menu).tint(YamuTheme.purple).accessibilityIdentifier("fallbackCity")
                            Text("City selections include places within 120 km, measured in a straight line.").font(.caption2).foregroundStyle(YamuTheme.muted)
                            if let message = location.message { Text(message).font(.caption).foregroundStyle(YamuTheme.muted) }
                        }
                    }.pagePadding().padding(.bottom, 30)
                }.background(YamuTheme.canvas)
            }
        }.safeAreaInset(edge: .bottom, spacing: 0) {
            if !finding {
                GradientActionButton(title: "Surprise Me!", symbol: "shuffle", action: choose).accessibilityIdentifier("findAdventure")
                    .pagePadding().padding(.top, 12).padding(.bottom, 10).background(YamuTheme.canvas)
            }
        }.sheet(isPresented: $noMatch) {
            ScrollView { VStack(spacing: 16) {
                EmptyAdventureView(symbol: "sparkle.magnifyingglass", title: "Let’s make a little more room", message: "No places match all these choices. Try another experience, more time, a larger budget or a different starting city.")
                GradientActionButton(title: "Open up my options", symbol: "sparkles") {
                    store.preferences.cityRaw = BaseCity.anywhere.rawValue; store.preferences.budgetRaw = BudgetTier.flexible.rawValue
                    store.preferences.durationRaw = AdventureDuration.halfDay.rawValue; store.preferences.moodRaw = ""
                    useCurrentLocation = false; noMatch = false; store.save()
                }
                Button("Adjust my preferences") { noMatch = false }.font(.subheadline.bold()).padding(10)
            }.padding(22).fixedSize(horizontal: false, vertical: true) }.background(YamuTheme.canvas).presentationDetents([.large])
        }.onChange(of: finding) { _, value in navigator.isFinding = value }
            .onDisappear { navigator.isFinding = false }
            .navigationBarTitleDisplayMode(.inline).toolbar(finding ? .hidden : .visible, for: .navigationBar)
    }
    private func adaptiveChoices<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ViewThatFits(in: .horizontal) { HStack(spacing: 8, content: content); VStack(alignment: .leading, spacing: 8, content: content) }
    }
    private func choose() {
        let candidates = DestinationMatcher.eligible(in: DestinationCatalog.all, for: criteria)
        var generator = SystemRandomNumberGenerator()
        match = DestinationMatcher.select(from: candidates, recentIDs: store.preferences.recentIDs, personalization: store.personalization, using: &generator)
        guard match != nil else { noMatch = true; return }
        noMatch = false
        if reduceMotion { reveal() } else { finding = true }
    }
    private func reveal() {
        guard let destination = match else { return }
        match = nil; finding = false
        store.recordSuggestion(destination)
        navigator.path.append(.details(destination.id))
    }
}

struct FindingAdventureView: View {
    var reveal: () -> Void
    @State private var stage = 0
    var body: some View {
        AdventureFindingScene(messages: ["Checking your local collection", "Matching your mood, budget & time", "Adding a bit of surprise"], stage: stage,
                              footnote: "Chosen from bundled places. No connection needed.", primaryTitle: "Show my match", primaryAction: reveal)
            .task {
                for next in 0...2 {
                    guard !Task.isCancelled else { return }; stage = next
                    do { try await Task.sleep(for: .milliseconds(320)) } catch { return }
                }
                guard !Task.isCancelled else { return }; reveal()
            }
    }
}
struct AdventurePlannerView: View {
    @Environment(Navigator.self) private var navigator
    @State private var online = true
    var body: some View {
        VStack(spacing: 0) {
            if !navigator.isFinding {
                HStack(spacing: 10) {
                    CategoryChip(title: "Online nearby", selected: online) { online = true }
                    CategoryChip(title: "Offline ideas", selected: !online) { online = false }
                }.frame(maxWidth: .infinity).padding(.vertical, 10).background(YamuTheme.canvas)
            }
            if online { NearbyPlannerView() } else { BundledPlannerView() }
        }.background(YamuTheme.canvas).navigationBarTitleDisplayMode(.inline)
    }
}
#Preview { if let store = PreviewEnvironment.store() { NavigationStack { AdventurePlannerView().environment(store).environment(Navigator()).environment(LocationService()) } } }
