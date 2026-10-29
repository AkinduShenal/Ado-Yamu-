import SwiftUI

struct PlanNumberField: View {
    let title: String
    let placeholder: String
    @Binding var value: Int?
    var suffix = "Rs."
    var identifier = ""
    @State private var text = ""
    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title).font(.caption.weight(.semibold)).foregroundStyle(YamuTheme.muted)
            HStack {
                if suffix == "Rs." { Text("Rs.").foregroundStyle(YamuTheme.muted) }
                TextField(placeholder, text: $text).keyboardType(.numberPad).font(.system(.headline, design: .rounded))
                    .accessibilityLabel(title).accessibilityIdentifier(identifier)
                if suffix != "Rs." { Text(suffix).font(.caption).foregroundStyle(YamuTheme.muted) }
            }.padding(14).background(.white, in: RoundedRectangle(cornerRadius: 16)).overlay(RoundedRectangle(cornerRadius: 16).stroke(.black.opacity(0.06)))
        }.onAppear { text = value.map(String.init) ?? "" }
            .onChange(of: text) { _, new in
                let digits = String(new.filter(\.isNumber).prefix(7))
                if digits != new { text = digits }
                value = Int(digits)
            }
            .onChange(of: value) { _, new in
                if Int(text) != new { text = new.map(String.init) ?? "" }
            }
    }
}
struct PlanningAmountRow: View {
    let title: String
    let value: String
    var emphasized = false
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(title).foregroundStyle(emphasized ? YamuTheme.ink : YamuTheme.muted)
            Spacer(minLength: 8)
            Text(value).fontWeight(emphasized ? .bold : .medium).multilineTextAlignment(.trailing)
        }.font(.subheadline).accessibilityElement(children: .combine)
    }
}
struct TripAssessmentCard: View {
    let assessment: TripAssessment
    var isCheckingRoute = false
    let edit: () -> Void
    let open: () -> Void
    private var fitColor: Color {
        switch assessment.fit { case .fits: Color(red: 0.16, green: 0.48, blue: 0.28); case .needsInformation: YamuTheme.purple; case .overBudget, .overTime: .orange }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                Button(action: open) {
                    DestinationPhoto(place: assessment.place).frame(height: 210)
                        .overlay(alignment: .bottomLeading) {
                            Label(assessment.place.category.rawValue, systemImage: assessment.place.category.symbol)
                                .font(.caption.bold()).padding(.horizontal, 12).padding(.vertical, 8)
                                .background(.regularMaterial, in: Capsule()).foregroundStyle(YamuTheme.ink).padding(14)
                        }
                }.buttonStyle(.plain).accessibilityLabel("Explore \(assessment.place.name)")
                FavoriteButton(place: assessment.place, onPhoto: true).padding(10)
            }
            VStack(alignment: .leading, spacing: 14) {
                Button(action: open) {
                    VStack(alignment: .leading, spacing: 7) {
                        Text(assessment.place.name).font(.system(.title2, design: .rounded, weight: .bold)).foregroundStyle(YamuTheme.ink)
                        Label(assessment.place.locationDescription, systemImage: "mappin.and.ellipse").font(.caption).foregroundStyle(YamuTheme.muted)
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }.buttonStyle(.plain)
                Text(assessment.fit.rawValue).font(.caption.bold()).foregroundStyle(fitColor).padding(.horizontal, 12).padding(.vertical, 7).background(fitColor.opacity(0.09), in: Capsule())
                if let reason = assessment.query.personalization.reason(for: assessment.place) {
                    Label(reason, systemImage: "sparkles").font(.caption).foregroundStyle(YamuTheme.purple)
                }
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 16) { summary }
                    VStack(alignment: .leading, spacing: 8) { summary }
                }.font(.caption.weight(.semibold)).foregroundStyle(YamuTheme.muted)
                DisclosureGroup("Trip cost & time") {
                    VStack(spacing: 9) {
                        PlanningAmountRow(title: "Return transport", value: assessment.transportCost.map { "Rs. \($0)" } ?? "Add estimate")
                        PlanningAmountRow(title: "Entry / activity", value: assessment.entryCost.map { "Rs. \($0)" } ?? "Unknown price")
                        PlanningAmountRow(title: "Food & extras", value: assessment.plan.foodAndExtrasRupees.map { "Rs. \($0)" } ?? "Not entered")
                        Divider()
                        PlanningAmountRow(title: "Estimated total", value: assessment.totalCost.map { "Rs. \($0) / person" } ?? "Incomplete", emphasized: true)
                        PlanningAmountRow(title: "Return travel + visit", value: assessment.totalMinutes.map { "\($0) min total" } ?? (isCheckingRoute ? "Checking route…" : "Add journey time"))
                        if let manual = assessment.estimate?.manualRoundTripMinutes {
                            Text("Your return-journey estimate: \(manual) min. Visit: \(assessment.plan.visitMinutes) min.").font(.caption2).foregroundStyle(YamuTheme.muted)
                        } else if let journey = assessment.journey {
                            Text("\(journey.source). Both legs included; actual conditions may vary.").font(.caption2).foregroundStyle(YamuTheme.muted)
                        }
                    }.padding(.top, 12)
                }.font(.caption.weight(.semibold)).tint(YamuTheme.purple)
                Text("Costs are your estimates. Venue prices and availability need checking.").font(.caption2).foregroundStyle(YamuTheme.muted)
                HStack {
                    Button(action: edit) { Label("Edit cost / time", systemImage: "slider.horizontal.3") }.accessibilityIdentifier("edit-plan-\(assessment.id)")
                    Spacer()
                    Button(action: open) { Label("Details", systemImage: "arrow.right") }
                }.font(.subheadline.bold()).padding(.vertical, 4)
                if let photo = assessment.place.photo { PlacePhotoCredit(photo: photo) }
                HStack {
                    Text(assessment.place.source.label).font(.caption2.weight(.semibold))
                    Spacer()
                    if let date = assessment.place.fetchedAt { Text(date, format: .dateTime.day().month(.abbreviated).hour().minute()).font(.caption2) }
                }.foregroundStyle(YamuTheme.muted)
            }.padding(18)
        }.yamuCard(radius: 24).clipShape(RoundedRectangle(cornerRadius: 24))
    }
    @ViewBuilder private var summary: some View {
        Label(assessment.totalCost.map { "Rs. \($0) est." } ?? "Check costs", systemImage: "banknote")
        Label(assessment.totalMinutes.map { "\($0) min total" } ?? (isCheckingRoute ? "Checking route…" : "Check travel time"), systemImage: "clock")
    }
}

struct PlaceEstimateEditor: View {
    let assessment: TripAssessment
    @Environment(ExplorerStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var entry: Int?
    @State private var minutes: Int?
    @State private var message: String?
    init(assessment: TripAssessment) {
        self.assessment = assessment
        _entry = State(initialValue: assessment.estimate?.entryAndActivityRupees)
        _minutes = State(initialValue: assessment.estimate?.manualRoundTripMinutes)
    }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(assessment.place.name).font(.system(.title2, design: .rounded, weight: .bold))
                    Text("Enter amounts you’ve checked or your own planning estimates. A blank entry fee remains unknown; it is never treated as free.").font(.subheadline).foregroundStyle(YamuTheme.muted)
                    if assessment.plan.travelMode != .walking {
                        PlanNumberField(title: "Return transport / person", placeholder: "Unknown fare or cost", value: Binding(get: { store.tripPlan.transportRupees }, set: { value in var plan = store.tripPlan; plan.transportRupees = value; store.updatePlan(plan) }), identifier: "editorTransport")
                    }
                    PlanNumberField(title: "Food & extras allowance", placeholder: "0 if none", value: Binding(get: { store.tripPlan.foodAndExtrasRupees }, set: { value in var plan = store.tripPlan; plan.foodAndExtrasRupees = value; store.updatePlan(plan) }), identifier: "editorFood")
                    PlanNumberField(title: "Entry / activity per person", placeholder: "Unknown", value: $entry, identifier: "entryEstimate")
                    Button("No entry or activity spending planned: Rs. 0") { entry = 0 }.font(.caption.bold()).accessibilityIdentifier("entryZero")
                    PlanNumberField(title: "Your total return-journey time (optional)", placeholder: "Use route time if available", value: $minutes, suffix: "min", identifier: "journeyEstimate")
                    Text("Include both journeys, waiting and transfers. For bus/train routes that aren’t available online, enter a time you have checked.").font(.caption).foregroundStyle(YamuTheme.muted)
                    if assessment.journey != nil && minutes != nil { Button("Use the online route time instead") { minutes = nil }.font(.subheadline.bold()) }
                    HStack { Text("Visit time"); Spacer(); Text("\(assessment.plan.visitMinutes) min") }.font(.subheadline)
                    if let url = assessment.place.website { Link("Venue website", destination: url).font(.headline) }
                    if let phone = assessment.place.phone { Text("Venue phone: \(phone)").font(.subheadline).textSelection(.enabled) }
                    if let url = assessment.place.sourceURL { Link("Check place on \(assessment.place.source.label)", destination: url).font(.subheadline.bold()) }
                    if let message { Text(message).font(.caption).foregroundStyle(.red) }
                    GradientActionButton(title: "Save my estimates", symbol: "checkmark") {
                        guard entry.map({ (0...1_000_000).contains($0) }) ?? true,
                              minutes.map({ (0...1_440).contains($0) }) ?? true else { message = "Use non-negative amounts up to Rs. 1,000,000 and a journey time up to 1,440 minutes."; return }
                        store.saveEstimate(PlaceEstimate(entryAndActivityRupees: entry, manualRoundTripMinutes: minutes), for: assessment.place, query: assessment.query)
                        if store.errorMessage == nil { dismiss() }
                    }.accessibilityIdentifier("savePlaceEstimate")
                }.padding(22)
            }.background(YamuTheme.canvas).navigationTitle("Trip estimate").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
        }.tint(YamuTheme.purple).preferredColorScheme(.light)
    }
}
