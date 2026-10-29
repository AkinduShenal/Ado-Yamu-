import SwiftUI

struct FeelingCheckInView: View {
    @Environment(ExplorerStore.self) private var store
    private var context: PersonalizationContext { store.personalization }
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                SectionHeading(title: "How are you feeling?")
                Spacer()
                if context.feeling != nil { Button("Skip") { store.checkIn(nil) }.font(.caption.bold()).accessibilityIdentifier("skipFeeling") }
                else { Text("Optional").font(.caption).foregroundStyle(YamuTheme.muted) }
            }
            Text("Different days, different escapes. Choose what feels right for you.").font(.caption).foregroundStyle(YamuTheme.muted)
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 7) { faces }
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 10) { faces }
            }
            if let feeling = context.feeling {
                VStack(alignment: .leading, spacing: 12) {
                    Text("What would feel right today?").font(.subheadline.bold())
                    Text("Choose one or more. We’ll remember your choices for when you select \(feeling.title).")
                        .font(.caption).foregroundStyle(YamuTheme.muted)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 9) {
                        ForEach(PlaceExperience.allCases) { experience in
                            let selected = context.experiences.contains(experience)
                            Button { store.toggleExperience(experience) } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: experience.symbol)
                                    Text(experience.title).fixedSize(horizontal: false, vertical: true)
                                    Spacer(minLength: 0)
                                    if selected { Image(systemName: "checkmark.circle.fill") }
                                }.font(.caption.weight(.semibold)).padding(12).frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                                    .foregroundStyle(selected ? YamuTheme.purple : YamuTheme.ink)
                                    .background(selected ? YamuTheme.purple.opacity(0.10) : .white, in: RoundedRectangle(cornerRadius: 15))
                                    .overlay(RoundedRectangle(cornerRadius: 15).stroke(selected ? YamuTheme.purple.opacity(0.5) : .black.opacity(0.05)))
                            }.buttonStyle(PressStyle()).accessibilityIdentifier("experience-\(experience.id)")
                                .accessibilityAddTraits(selected ? .isSelected : [])
                        }
                    }
                    if context.experiences.isEmpty {
                        Text("All experiences welcome. Pick a favourite above to personalize your results.").font(.caption2).foregroundStyle(YamuTheme.muted)
                    } else {
                        Label(context.experienceSummary, systemImage: "sparkles").font(.caption.weight(.medium)).foregroundStyle(YamuTheme.purple)
                            .accessibilityIdentifier("personalizationSummary")
                    }
                    HStack(alignment: .firstTextBaseline) {
                        Text("Saved on this device. Check in again tomorrow.").font(.caption2).foregroundStyle(YamuTheme.muted)
                        Spacer()
                        Button("Reset choices") { store.clearPersonalization() }.font(.caption2.bold()).accessibilityIdentifier("resetFeelingChoices")
                    }
                }.padding(16).background(YamuTheme.purple.opacity(0.035), in: RoundedRectangle(cornerRadius: 20))
            }
        }
    }
    @ViewBuilder private var faces: some View {
        ForEach(PersonalFeeling.allCases) { feeling in
            let selected = context.feeling == feeling
            Button { store.checkIn(selected ? nil : feeling) } label: {
                VStack(spacing: 7) {
                    Text(feeling.face).font(.system(size: 30)).accessibilityHidden(true)
                    Text(feeling.title).font(.caption2.weight(selected ? .bold : .medium))
                }.padding(.vertical, 12).frame(minWidth: 44, maxWidth: .infinity, minHeight: 78)
                    .foregroundStyle(selected ? YamuTheme.purple : YamuTheme.muted)
                    .background(selected ? YamuTheme.purple.opacity(0.10) : .white, in: RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(selected ? YamuTheme.purple : .black.opacity(0.04), lineWidth: selected ? 1.5 : 1))
            }.buttonStyle(PressStyle()).accessibilityLabel("Feeling \(feeling.title)").accessibilityIdentifier("feeling-\(feeling.id)")
                .accessibilityAddTraits(selected ? .isSelected : [])
        }
    }
}
#Preview { if let store = PreviewEnvironment.store() { ScrollView { FeelingCheckInView().padding(22) }.environment(store).background(YamuTheme.canvas) } }
