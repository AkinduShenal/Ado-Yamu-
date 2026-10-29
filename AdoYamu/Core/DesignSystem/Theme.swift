import SwiftUI

enum YamuTheme {
    static let purple = Color(red: 0.39, green: 0.24, blue: 0.96)
    static let violet = Color(red: 0.53, green: 0.36, blue: 1)
    static let orange = Color(red: 1, green: 0.61, blue: 0.27)
    static let ink = Color(red: 0.08, green: 0.09, blue: 0.16)
    static let muted = Color(red: 0.43, green: 0.43, blue: 0.49)
    static let canvas = Color(red: 0.985, green: 0.979, blue: 0.964)
    static let forest = Color(red: 0.025, green: 0.14, blue: 0.11)
    static let gradient = LinearGradient(colors: [violet, purple], startPoint: .topLeading, endPoint: .bottomTrailing)
    static func moodColor(_ mood: Mood) -> Color {
        switch mood { case .chill: Color(red: 0.88, green: 0.85, blue: 1)
        case .adventure: Color(red: 0.86, green: 0.94, blue: 0.80)
        case .food: Color(red: 1, green: 0.90, blue: 0.74)
        case .romantic: Color(red: 1, green: 0.85, blue: 0.86) }
    }
    static func moodInk(_ mood: Mood) -> Color {
        switch mood { case .chill: purple; case .adventure: Color(red: 0.22, green: 0.46, blue: 0.20); case .food: Color(red: 0.72, green: 0.36, blue: 0.02); case .romantic: Color(red: 0.78, green: 0.19, blue: 0.26) }
    }
}

extension View {
    func yamuCard(radius: CGFloat = 24) -> some View {
        background(.white, in: RoundedRectangle(cornerRadius: radius))
            .shadow(color: YamuTheme.ink.opacity(0.055), radius: 12, x: 0, y: 5)
    }
    func pagePadding() -> some View { padding(.horizontal, 22) }
}

struct GradientActionButton: View {
    let title: LocalizedStringKey
    var symbol = "arrow.right"
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) { Text(title).font(.system(.headline, design: .rounded)); Image(systemName: symbol) }
                .frame(maxWidth: .infinity).padding(.vertical, 18).padding(.horizontal, 15)
                .foregroundStyle(.white).background(YamuTheme.gradient, in: Capsule())
                .shadow(color: YamuTheme.purple.opacity(0.20), radius: 9, y: 5)
        }.buttonStyle(PressStyle())
    }
}
struct PressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
            .animation(reduceMotion ? nil : .spring(response: 0.25), value: configuration.isPressed)
    }
}
struct CategoryChip: View {
    let title: String
    var selected = false
    var action: () -> Void
    var body: some View {
        Button(action: action) { Text(LocalizedStringKey(title)).font(.subheadline.weight(.semibold)).padding(.horizontal, 17).padding(.vertical, 12)
                .foregroundStyle(selected ? .white : YamuTheme.ink)
                .background(selected ? AnyShapeStyle(YamuTheme.gradient) : AnyShapeStyle(Color.black.opacity(0.045)), in: Capsule())
        }.buttonStyle(PressStyle()).accessibilityAddTraits(selected ? .isSelected : [])
    }
}
struct MoodButton: View {
    let mood: Mood
    var selected = false
    var expanded = false
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Group {
                if expanded {
                    HStack(spacing: 10) {
                        Image(systemName: mood.symbol).font(.title3).frame(width: 32)
                        VStack(alignment: .leading, spacing: 4) { Text(LocalizedStringKey(mood.rawValue)).font(.subheadline.bold()); Text(LocalizedStringKey(mood.subtitle)).font(.caption2) }
                        Spacer(minLength: 0)
                    }.padding(14).frame(maxWidth: .infinity, minHeight: 76)
                } else {
                    VStack(spacing: 9) {
                        Image(systemName: mood.symbol).font(.title2).frame(maxWidth: .infinity).frame(height: 66)
                            .background(YamuTheme.moodColor(mood), in: RoundedRectangle(cornerRadius: 23))
                        Text(LocalizedStringKey(mood.rawValue)).font(.caption.weight(.semibold)).foregroundStyle(YamuTheme.ink)
                    }
                }
            }.foregroundStyle(YamuTheme.moodInk(mood))
                .background(expanded ? YamuTheme.moodColor(mood).opacity(selected ? 1 : 0.65) : .clear, in: RoundedRectangle(cornerRadius: 20))
                .overlay { if selected { RoundedRectangle(cornerRadius: 20).stroke(YamuTheme.moodInk(mood), lineWidth: 1.5) } }
        }.buttonStyle(PressStyle()).accessibilityLabel("\(mood.rawValue), \(mood.subtitle)").accessibilityIdentifier("mood-\(mood.id.lowercased())")
            .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
struct SearchField: View {
    @FocusState private var focused: Bool
    @Binding var text: String
    var placeholder = "Search places, districts, activities…"
    var body: some View {
        HStack(spacing: 11) {
            Image(systemName: "magnifyingglass").foregroundStyle(YamuTheme.muted)
            TextField(placeholder, text: $text).font(.subheadline).autocorrectionDisabled().submitLabel(.search)
                .accessibilityIdentifier("placeSearch").focused($focused).onSubmit { focused = false }
            if !text.isEmpty { Button { text = "" } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(YamuTheme.muted) }.accessibilityLabel("Clear search") }
        }.padding(16).background(.white, in: Capsule()).overlay(Capsule().stroke(.black.opacity(0.07)))
            .shadow(color: .black.opacity(0.04), radius: 6, y: 3).contentShape(Capsule()).onTapGesture { focused = true }
    }
}
struct AdventureStat: View {
    let value: String
    let label: String
    var body: some View {
        VStack(spacing: 5) { Text(value).font(.system(.title2, design: .rounded, weight: .bold)); Text(label).font(.caption).foregroundStyle(YamuTheme.muted) }
            .frame(maxWidth: .infinity).accessibilityElement(children: .combine)
    }
}
struct EmptyAdventureView: View {
    let symbol: String
    let title: String
    let message: String
    var body: some View {
        VStack(spacing: 15) {
            Image(systemName: symbol).font(.system(size: 38)).foregroundStyle(YamuTheme.purple).frame(width: 88, height: 88).background(YamuTheme.purple.opacity(0.09), in: Circle())
            Text(title).font(.system(.title3, design: .rounded, weight: .bold))
            Text(message).font(.subheadline).foregroundStyle(YamuTheme.muted).multilineTextAlignment(.center)
        }.padding(30).frame(maxWidth: .infinity)
    }
}
struct SectionHeading: View {
    let title: String
    var body: some View { Text(title).font(.system(.title3, design: .rounded, weight: .bold)).foregroundStyle(YamuTheme.ink) }
}
#Preview("Mood tiles") { HStack { ForEach(Mood.allCases) { mood in MoodButton(mood: mood) {} } }.padding() }
#Preview("Primary action") { GradientActionButton(title: "Surprise Me!", symbol: "shuffle") {}.padding() }
