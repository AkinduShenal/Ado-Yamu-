import SwiftUI

struct NearbyPlannerView: View {
    @Environment(ExplorerStore.self) private var store
    @Environment(Navigator.self) private var navigator
    @Environment(LocationService.self) private var location
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var model = DiscoveryServices.makeModel()
    @State private var useCurrentLocation = false
    @State private var editing: TripAssessment?
    @State private var customize = false
    @State private var validation: String?
    @State private var finding = false
    @State private var showingResults = false
    private var origin: Coordinate? { useCurrentLocation ? location.coordinate ?? store.preferences.city.coordinate : store.preferences.city.coordinate }
    private var query: NearbyQuery? { origin.map { NearbyQuery(origin: $0, radiusKilometers: store.tripPlan.radiusKilometers, moods: store.preferences.moods, travelMode: store.tripPlan.travelMode, personalization: store.personalization) } }
    private var assessments: [TripAssessment] { model.assessments(store: store) }
    private var fits: [TripAssessment] { assessments.filter { $0.fit == .fits } }
    private var incomplete: [TripAssessment] { assessments.filter { $0.fit == .needsInformation } }
    private var excluded: [TripAssessment] { assessments.filter { $0.fit == .overBudget || $0.fit == .overTime } }
    var body: some View {
        Group {
            if finding || (showingResults && model.isBusy) {
                AdventureFindingScene(messages: ["Discovering places near you", "Finding photos & return routes", "Matching your budget & time"],
                    stage: model.isSearching ? 0 : model.checkedJourneys == 0 ? 1 : 2,
                    footnote: "We’ll show your places when the checks finish. Prices still need your estimates.", primaryTitle: "Stop checks & show places", primaryAction: stopAndReveal,
                    canReveal: !model.isSearching && !model.places.isEmpty, cancel: cancelSearch, online: true,
                    progress: model.isCheckingJourneys && model.totalJourneyChecks > 0 ? Double(model.checkedJourneys) / Double(model.totalJourneyChecks) : nil,
                    progressText: model.isCheckingJourneys ? "Checking return routes · \(model.checkedJourneys) of \(model.totalJourneyChecks)" : model.isSearching ? "Discovering places near you…" : "Finding photos for your adventure…")
            } else if showingResults { discoveries }
            else { preferences }
        }
        .background(YamuTheme.canvas)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if !finding && !model.isBusy {
                VStack(spacing: 8) {
                    if showingResults && fits.isEmpty && !model.places.isEmpty {
                        Text("Check missing costs or time to unlock a budget match.").font(.caption).foregroundStyle(YamuTheme.muted).multilineTextAlignment(.center)
                    }
                    GradientActionButton(title: showingResults && fits.isEmpty ? "Adjust my preferences" : "Surprise Me!", symbol: showingResults && fits.isEmpty ? "slider.horizontal.3" : "shuffle") {
                        if showingResults {
                            if fits.isEmpty { showingResults = false }
                            else if let match = model.surprise(store: store) { navigator.path.append(.details(match.id)) }
                        } else { search() }
                    }.accessibilityIdentifier(showingResults ? (fits.isEmpty ? "adjustOnlinePlan" : "onlineSurprise") : "findOnlinePlaces")
                }.pagePadding().padding(.top, 12).padding(.bottom, 10).background(YamuTheme.canvas)
            }
        }
        .sheet(item: $editing) { PlaceEstimateEditor(assessment: $0) }
        .sheet(isPresented: $customize) { TripPlanOptionsView() }
        .onChange(of: model.readyToReveal) { _, ready in if ready && finding { reveal(chooseMatch: true) } }
        .onChange(of: query) { _, _ in model.cancel(clear: true); finding = false; navigator.isFinding = false; showingResults = false }
        .onChange(of: finding) { _, value in navigator.isFinding = value }
        .onDisappear { model.stopRouteChecks(); navigator.isFinding = false }
        .navigationBarTitleDisplayMode(.inline).toolbar(finding ? .hidden : .visible, for: .navigationBar)
    }
    private var preferences: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(spacing: 8) {
                    Text("Plan Your Adventure").font(.system(.title, design: .rounded, weight: .bold)).multilineTextAlignment(.center)
                    Text("Set your preferences and we’ll find\nlittle adventures near you!").font(.subheadline).foregroundStyle(YamuTheme.muted).multilineTextAlignment(.center)
                }.frame(maxWidth: .infinity).padding(.top, 8)
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeading(title: "What’s your mood?")
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(Mood.allCases) { mood in MoodButton(mood: mood, selected: store.preferences.moods.contains(mood), expanded: true) {
                            var selection = store.preferences.moods
                            if selection.contains(mood) { selection.remove(mood) } else { selection.insert(mood) }
                            store.preferences.moodRaw = selection.map(\.rawValue).sorted().joined(separator: ","); store.save()
                        } }
                    }
                    Text(store.preferences.moods.isEmpty ? "All moods welcome" : "We’ll match any selected mood").font(.caption).foregroundStyle(YamuTheme.muted)
                }
                FeelingCheckInView()
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeading(title: "Budget (per person)")
                    choices { ForEach([500, 1_000, 3_000], id: \.self) { amount in
                        CategoryChip(title: "Rs. \(amount.formatted())", selected: store.tripPlan.totalBudget == amount) { update { $0.totalBudget = amount } }
                    } }
                    Text("Whole trip: return transport, entry & food.").font(.caption2).foregroundStyle(YamuTheme.muted)
                }
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeading(title: "Time available")
                    choices { ForEach(AdventureDuration.allCases) { duration in
                        CategoryChip(title: duration.label, selected: store.tripPlan.availableMinutes == duration.rawValue) { update { $0.availableMinutes = duration.rawValue; $0.visitMinutes = min($0.visitMinutes, max(15, duration.rawValue / 2)) } }
                    } }
                    Text("Includes getting there, enjoying the place & coming home.").font(.caption2).foregroundStyle(YamuTheme.muted)
                }
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeading(title: "From your location")
                    Button { useCurrentLocation = true; location.request() } label: {
                        HStack {
                            Image(systemName: "location.circle.fill").foregroundStyle(YamuTheme.purple)
                            Text(location.isRequesting ? "Finding your location…" : useCurrentLocation && location.coordinate != nil ? "Using your current location" : "Use current location").font(.subheadline.weight(.semibold))
                            Spacer(); if location.isRequesting { ProgressView() } else { Image(systemName: "location.viewfinder") }
                        }.padding(16).yamuCard(radius: 18)
                    }.buttonStyle(.plain).disabled(location.isRequesting)
                    HStack {
                        Picker("Starting city", selection: Binding(get: { store.preferences.cityRaw }, set: { store.preferences.cityRaw = $0; useCurrentLocation = false; store.save() })) {
                            ForEach(BaseCity.allCases) { city in Text(city == .anywhere ? "Choose a starting city" : city.rawValue).tag(city.rawValue) }
                        }.accessibilityIdentifier("onlineStartingCity")
                        Spacer()
                        Picker("Search radius", selection: Binding(get: { store.tripPlan.radiusKilometers }, set: { value in update { $0.radiusKilometers = value } })) {
                            ForEach([2, 5, 10, 20, 30], id: \.self) { Text("\($0) km").tag($0) }
                        }
                    }.tint(YamuTheme.purple)
                    if !useCurrentLocation || location.coordinate == nil { Text("Starting at \(store.preferences.city.rawValue) city centre").font(.caption2).foregroundStyle(YamuTheme.muted) }
                    if let message = location.message { Text(message).font(.caption).foregroundStyle(YamuTheme.muted) }
                }
                Button { customize = true } label: {
                    HStack(spacing: 12) {
                        Image(systemName: store.tripPlan.travelMode.symbol).font(.title3).foregroundStyle(YamuTheme.purple)
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Travel & spending").font(.subheadline.bold())
                            Text("\(store.tripPlan.travelMode.rawValue) · \(store.tripPlan.visitMinutes) min at the place").font(.caption).foregroundStyle(YamuTheme.muted)
                        }
                        Spacer(); Image(systemName: "slider.horizontal.3").foregroundStyle(YamuTheme.purple)
                    }.padding(16).yamuCard(radius: 18)
                }.buttonStyle(.plain).accessibilityIdentifier("customizeOnlinePlan")
                Text("Photos where available. Live entry prices & fares need checking.").font(.caption2).foregroundStyle(YamuTheme.muted)
                if let validation { Text(validation).font(.subheadline).foregroundStyle(.red).accessibilityIdentifier("onlineValidation") }
            }.pagePadding().padding(.bottom, 28)
        }.scrollDismissesKeyboard(.interactively)
    }
    private var discoveries: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(spacing: 9) {
                        Text("A little adventure awaits").font(.system(.title, design: .rounded, weight: .bold)).multilineTextAlignment(.center)
                        Text("Places to make your day, near your starting point.").font(.subheadline).foregroundStyle(YamuTheme.muted).multilineTextAlignment(.center)
                    }.frame(maxWidth: .infinity).id("resultsTop")
                    HStack {
                        Button { showingResults = false } label: { Label("Edit preferences", systemImage: "slider.horizontal.3") }
                        Spacer(); Button("Search again") { search(forceRefresh: true) }
                    }.font(.caption.bold())
                    if let message = model.message { Text(message).font(.subheadline).foregroundStyle(YamuTheme.muted) }
                    Text("\(fits.count) fit your estimates · \(incomplete.count) need costs or time · \(excluded.count) exceed the plan")
                        .font(.caption.weight(.semibold)).foregroundStyle(YamuTheme.purple).accessibilityIdentifier("onlineResultCounts")
                    if !fits.isEmpty { SectionHeading(title: "Picked for your plan"); ForEach(fits) { card($0) } }
                    if !incomplete.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            SectionHeading(title: "A few little possibilities")
                            Text("Check the missing costs or time before treating these as a budget match.").font(.caption).foregroundStyle(YamuTheme.muted)
                        }
                        ForEach(incomplete) { card($0) }
                    }
                    if !excluded.isEmpty { DisclosureGroup("\(excluded.count) outside your plan") { VStack(spacing: 18) { ForEach(excluded) { card($0) } }.padding(.top, 15) } }
                    if model.places.isEmpty { EmptyAdventureView(symbol: "sparkle.magnifyingglass", title: "Let’s make a little more room", message: "Try another experience, mood, city or radius. Offline ideas are always available.") }
                    Text("Up to 12 discoveries and 8 automatic return-route checks. Photos are shown only when a matching source is available.").font(.caption2).foregroundStyle(YamuTheme.muted)
                    SourceAttributionView()
                }.pagePadding().padding(.top, 18).padding(.bottom, 25)
            }.onChange(of: fits.count) { old, new in
                if new > old { if reduceMotion { proxy.scrollTo("resultsTop", anchor: .top) } else { withAnimation { proxy.scrollTo("resultsTop", anchor: .top) } } }
            }
        }
    }
    private func card(_ assessment: TripAssessment) -> some View {
        TripAssessmentCard(assessment: assessment, isCheckingRoute: model.isCheckingJourneys && assessment.journey == nil, edit: { editing = assessment }, open: {
            store.latestAssessments[assessment.id] = assessment; navigator.path.append(.details(assessment.id))
        })
    }
    private func search(forceRefresh: Bool = false) {
        guard let query, query.origin.isInSriLanka else { validation = "Choose a Sri Lankan starting city or a location in Sri Lanka."; return }
        guard store.tripPlan.validationMessage == nil else { validation = store.tripPlan.validationMessage; return }
        validation = nil; finding = true; navigator.isFinding = true; model.search(query, store: store, forceRefresh: forceRefresh)
    }
    private func reveal(chooseMatch: Bool) {
        finding = false; navigator.isFinding = false; showingResults = true
        if chooseMatch, let match = model.surprise(store: store) { navigator.path.append(.details(match.id)) }
    }
    private func stopAndReveal() {
        finding = false; navigator.isFinding = false; showingResults = true
        model.cancel()
    }
    private func cancelSearch() { finding = false; navigator.isFinding = false; showingResults = false; model.cancel(clear: true) }
    private func update(_ change: (inout TripPlan) -> Void) { var plan = store.tripPlan; change(&plan); store.updatePlan(plan) }
    private func choices<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        ViewThatFits(in: .horizontal) { HStack(spacing: 8, content: content); VStack(alignment: .leading, spacing: 8, content: content) }
    }
}

struct TripPlanOptionsView: View {
    @Environment(ExplorerStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Make it your kind of trip").font(.system(.title2, design: .rounded, weight: .bold))
                    PlanNumberField(title: "Total budget per person", placeholder: "1000", value: binding(\.totalBudget), identifier: "totalTripBudget")
                    PlanNumberField(title: "Total time including return travel", placeholder: "Minutes available", value: Binding(get: { store.tripPlan.availableMinutes }, set: { value in update { $0.availableMinutes = value ?? 0 } }), suffix: "min", identifier: "availableTripMinutes")
                    SectionHeading(title: "How will you travel?")
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(TravelMode.allCases) { mode in CategoryChip(title: mode.rawValue, selected: store.tripPlan.travelMode == mode) { update { $0.travelMode = mode } } }
                    }
                    if store.tripPlan.travelMode != .walking {
                        PlanNumberField(title: "Return transport estimate / person", placeholder: "Unknown", value: binding(\.transportRupees), identifier: "transportEstimate")
                        Text("Include both fares or fuel, parking & tolls. This allowance applies to each result; it is not a live fare.").font(.caption).foregroundStyle(YamuTheme.muted)
                    }
                    if store.tripPlan.travelMode == .motorbike { Text("Motorbike times use driving-route estimates.").font(.caption).foregroundStyle(YamuTheme.muted) }
                    PlanNumberField(title: "Food & extras allowance", placeholder: "0 if none", value: binding(\.foodAndExtrasRupees), identifier: "foodAllowance")
                    SectionHeading(title: "Time to enjoy the place")
                    HStack { ForEach([30, 60, 120], id: \.self) { minutes in CategoryChip(title: "\(minutes) min", selected: store.tripPlan.visitMinutes == minutes) { update { $0.visitMinutes = minutes } } } }
                    Text("The app checks your whole budget and both journeys. Unknown admission fees remain unknown until you add an estimate.").font(.caption).foregroundStyle(YamuTheme.muted)
                    if let message = store.tripPlan.validationMessage { Text(message).font(.caption).foregroundStyle(.red) }
                    GradientActionButton(title: "Use these preferences", symbol: "checkmark") { dismiss() }.disabled(store.tripPlan.validationMessage != nil)
                }.padding(22)
            }.background(YamuTheme.canvas).navigationTitle("Travel & spending").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
        }.tint(YamuTheme.purple)
    }
    private func update(_ change: (inout TripPlan) -> Void) { var plan = store.tripPlan; change(&plan); store.updatePlan(plan) }
    private func binding(_ path: WritableKeyPath<TripPlan, Int?>) -> Binding<Int?> { Binding(get: { store.tripPlan[keyPath: path] }, set: { value in update { $0[keyPath: path] = value } }) }
}
struct SourceAttributionView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("Places: Apple Maps & Wikipedia landmarks. Route estimates: Apple Maps, with OpenStreetMap/FOSSGIS fallback where available. Costs are your estimates.").font(.caption2).foregroundStyle(YamuTheme.muted)
            HStack {
                if let url = URL(string: "https://www.openstreetmap.org/copyright") { Link("© OpenStreetMap contributors", destination: url) }
                Spacer()
                if let url = URL(string: "https://www.openstreetmap.org/fixthemap") { Link("Fix the map", destination: url) }
            }.font(.caption2)
            if let url = URL(string: "https://routing.openstreetmap.de/about.html") {
                Link("Routing service & privacy", destination: url).font(.caption2)
            }
            Text("Place photos: matching Wikimedia Commons images where available. Credits and licenses are shown with each photo and in About.").font(.caption2).foregroundStyle(YamuTheme.muted)
        }
    }
}
