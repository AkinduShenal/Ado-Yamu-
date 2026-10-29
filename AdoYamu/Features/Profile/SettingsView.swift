import SwiftUI
import UserNotifications

struct SettingsView: View {
    @Environment(ExplorerStore.self) private var store
    @Environment(\.openURL) private var openURL
    @State private var name = ""
    @State private var requesting = false
    @State private var notificationMessage: String?
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 25) {
                VStack(alignment: .leading, spacing: 15) {
                    SectionHeading(title: "Make it yours")
                    TextField("Explorer name", text: $name).textContentType(.nickname).submitLabel(.done).padding(15).background(.white, in: RoundedRectangle(cornerRadius: 16))
                        .onSubmit { saveName() }.onChange(of: name) { _, value in
                            store.preferences.name = String(value.prefix(40)); store.save()
                        }.accessibilityLabel("Explorer name")
                    HStack { Label("Starting city", systemImage: "mappin.and.ellipse"); Spacer(); Picker("Starting city", selection: Binding(get: { store.preferences.cityRaw }, set: { store.preferences.cityRaw = $0; store.save() })) { ForEach(BaseCity.allCases) { Text($0.rawValue).tag($0.rawValue) } }.labelsHidden() }.font(.subheadline).padding(15).yamuCard(radius: 18)
                }
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeading(title: "A gentle nudge")
                    Toggle(isOn: Binding(get: { store.preferences.reminderEnabled }, set: updateReminder)) {
                        VStack(alignment: .leading, spacing: 5) { Text("Weekend adventure reminder").font(.subheadline.weight(.semibold)); Text("Saturdays at 9:00 AM, your local time").font(.caption).foregroundStyle(YamuTheme.muted) }
                    }.tint(YamuTheme.purple).padding(18).yamuCard(radius: 20).disabled(requesting)
                    if requesting { ProgressView("Setting up your reminder…").font(.caption) }
                    if let message = notificationMessage {
                        Text(message).font(.caption).foregroundStyle(YamuTheme.muted)
                        Button("Open iOS Settings") { if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) } }.font(.subheadline.bold())
                    }
                }
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeading(title: "Language")
                    Label("English", systemImage: "globe").font(.subheadline).padding(18).frame(maxWidth: .infinity, alignment: .leading).yamuCard(radius: 18)
                    Text("Sinhala and Tamil translations are planned. Place names are currently shown in English.").font(.caption).foregroundStyle(YamuTheme.muted)
                }
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeading(title: "Personal suggestions")
                    Text("Optional feeling check-ins and your preferred experiences stay on this device. Each check-in applies today; your choices can be recalled when you select that feeling again. Online search uses the kinds of places you choose, not your feeling label.").font(.subheadline).foregroundStyle(YamuTheme.muted)
                    Button("Reset feeling & experience choices") { store.clearPersonalization() }.font(.subheadline.bold()).disabled(store.tripPlan.personalization == nil)
                }.padding(19).yamuCard()
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeading(title: "Your little journal stays yours")
                    Text("Favourites, visits, trip ideas, preferences and photo memories are stored on this device. No account or app-operated backend is used. Online search sends your chosen starting area to Apple Maps. Photo lookup uses that area with Wikimedia; route estimates can also use OpenStreetMap/FOSSGIS. Location is requested only when you tap a location control; you can always choose a city instead.").font(.subheadline).foregroundStyle(YamuTheme.muted).lineSpacing(4)
                    Text("iOS may include app data in your device backups. Uninstalling the app removes its local journal.").font(.caption).foregroundStyle(YamuTheme.muted)
                }.padding(19).yamuCard()
            }.padding(22)
        }.background(YamuTheme.canvas).navigationTitle("Settings").navigationBarTitleDisplayMode(.inline).toolbar(.visible, for: .navigationBar)
            .onAppear { name = store.preferences.name }.onDisappear { saveName() }
    }
    private func saveName() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        store.preferences.name = trimmed.isEmpty ? "Ado Explorer" : String(trimmed.prefix(40)); store.save()
    }
    private func updateReminder(_ enabled: Bool) {
        notificationMessage = nil
        if !enabled { ReminderService.disable(); store.preferences.reminderEnabled = false; store.save(); return }
        requesting = true
        Task {
            do {
                let granted = try await ReminderService.enable()
                store.preferences.reminderEnabled = granted
                if !granted { notificationMessage = "Notifications are off. You can enable them in iOS Settings whenever you like." }
                store.save()
            } catch { notificationMessage = "The reminder couldn’t be scheduled. Please check notification settings and try again." }
            requesting = false
        }
    }
}
struct PhotoCredit: Decodable, Identifiable {
    let asset: String
    let title: String
    let file: String
    let page: String
    let artist: String
    let license: String
    let licenseURL: String
    let changes: String
    var id: String { asset }
    var artistName: String { artist.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression).replacingOccurrences(of: "&amp;", with: "&").replacingOccurrences(of: "&#160;", with: " ").trimmingCharacters(in: .whitespacesAndNewlines) }
    static var bundled: [PhotoCredit] {
        guard let url = Bundle.main.url(forResource: "PhotoCredits", withExtension: "json"), let data = try? Data(contentsOf: url), let credits = try? JSONDecoder().decode([PhotoCredit].self, from: data) else { return [] }
        return credits.sorted { $0.title < $1.title }
    }
}
struct AboutView: View {
    @Environment(ExplorerStore.self) private var store
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Ado Yamu! 🌴").font(.system(.largeTitle, design: .rounded, weight: .heavy))
                    Text("Little adventures. Lasting memories.").font(.headline).foregroundStyle(YamuTheme.purple)
                    Text("A playful, offline-first collection of places to explore in Sri Lanka. Built with native SwiftUI, SwiftData and MapKit. Version 1.0.").font(.subheadline).foregroundStyle(YamuTheme.muted).lineSpacing(4)
                }
                VStack(alignment: .leading, spacing: 10) {
                    SectionHeading(title: "Planning, with a little perspective")
                    Text("Suggested budgets and visit durations are illustrative. They are not verified admission fees, opening times, travel times or availability. The local collection does not include live conditions. Map pins are approximate destination locations; follow official access signs and local guidance.").font(.subheadline).foregroundStyle(YamuTheme.muted)
                    if let url = URL(string: "https://www.srilanka.travel/") { Link("Sri Lanka Tourism", destination: url).font(.subheadline.bold()) }
                }
                VStack(alignment: .leading, spacing: 10) {
                    SectionHeading(title: "Online discovery & trip planning")
                    Text("Nearby places come from Apple Maps and photo-backed Wikipedia landmarks. Route times include both journeys where available, using Apple Maps with an OpenStreetMap/FOSSGIS fallback. Motorbike times use driving routes. Unknown prices remain unknown until you enter an estimate; transport and food allowances are your inputs.").font(.subheadline).foregroundStyle(YamuTheme.muted)
                    SourceAttributionView()
                }
                VStack(alignment: .leading, spacing: 10) {
                    SectionHeading(title: "Artwork & photography")
                    Text("The welcome landscape is an AI-generated illustration inspired by the supplied design, rather than a geographic photograph. Destination photographs below are bundled for offline use. UI icons use SF Symbols.").font(.subheadline).foregroundStyle(YamuTheme.muted)
                    ForEach(PhotoCredit.bundled) { credit in
                        VStack(alignment: .leading, spacing: 7) {
                            Text(credit.title).font(.headline)
                            Text(credit.artistName).font(.caption).textSelection(.enabled)
                            Text(credit.changes).font(.caption2).foregroundStyle(YamuTheme.muted)
                            HStack {
                                if let url = URL(string: credit.page) { Link("Photo source", destination: url) }
                                Spacer()
                                if let url = URL(string: credit.licenseURL), !credit.licenseURL.isEmpty { Link(credit.license, destination: url) } else { Text(credit.license) }
                            }.font(.caption.weight(.semibold))
                        }.padding(16).yamuCard(radius: 18)
                    }
                }
                if store.onlinePlaces.contains(where: { $0.photo != nil }) {
                    VStack(alignment: .leading, spacing: 14) {
                        SectionHeading(title: "Online place photos")
                        Text("Matched by venue name and coordinates. Images are cropped to fit cards; source and license links are preserved.").font(.caption).foregroundStyle(YamuTheme.muted)
                        ForEach(store.onlinePlaces.filter { $0.photo != nil }) { place in
                            if let photo = place.photo {
                                VStack(alignment: .leading, spacing: 9) { Text(place.name).font(.headline); PlacePhotoCredit(photo: photo) }.padding(16).yamuCard(radius: 18)
                            }
                        }
                    }
                }
            }.padding(22)
        }.background(YamuTheme.canvas).navigationTitle("About Ado Yamu!").navigationBarTitleDisplayMode(.inline).toolbar(.visible, for: .navigationBar)
    }
}
