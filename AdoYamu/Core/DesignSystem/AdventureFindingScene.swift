import SwiftUI

struct AdventureFindingScene: View {
    let messages: [String]
    let stage: Int
    let footnote: String
    let primaryTitle: String
    let primaryAction: () -> Void
    var canReveal = true
    var cancel: (() -> Void)? = nil
    var online = false
    var progress: Double? = nil
    var progressText: String? = nil
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var float = false
    var body: some View {
        GeometryReader { geometry in
            let compact = geometry.size.height < 700
            ZStack {
                ScenicBackdrop(blurred: true)
                Color.black.opacity(0.42).ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: compact ? 16 : 28) {
                        Text("Finding\nyour adventure…").font(.system(size: compact ? 30 : 35, weight: .heavy, design: .rounded))
                            .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                            .accessibilityIdentifier(online ? "onlineFinding" : "offlineFinding")
                        Text("A small escape, chosen just for you.").font(.subheadline).multilineTextAlignment(.center)
                        ZStack {
                            RoundedRectangle(cornerRadius: 28).fill(.orange.opacity(0.85)).frame(width: 176, height: 142).rotationEffect(.degrees(-8))
                            Image(systemName: "map.fill").font(.system(size: 120)).foregroundStyle(Color(red: 1, green: 0.87, blue: 0.58)).rotationEffect(.degrees(-8))
                            Image(systemName: "mappin.circle.fill").font(.system(size: 76)).foregroundStyle(YamuTheme.orange, .white).offset(y: float && !reduceMotion ? -25 : -18)
                        }.scaleEffect(compact ? 0.8 : 1).frame(height: compact ? 126 : 190).accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: compact ? 12 : 18) {
                            ForEach(Array(messages.enumerated()), id: \.offset) { index, message in
                                Label(message, systemImage: index < stage ? "checkmark.circle.fill" : index == stage ? "sparkles" : "circle.dotted")
                                    .font(compact ? .caption : .subheadline).fixedSize(horizontal: false, vertical: true)
                                    .foregroundStyle(index <= stage ? .white : .white.opacity(0.5))
                            }
                        }
                        if online {
                            VStack(spacing: 10) {
                                if let progress {
                                    ProgressView(value: min(1, max(0, progress))).tint(YamuTheme.orange)
                                        .accessibilityLabel("Return route checks")
                                } else { ProgressView().tint(.white).accessibilityLabel("Searching nearby adventures") }
                                if let progressText {
                                    Text(progressText).font(.caption.weight(.semibold)).multilineTextAlignment(.center)
                                        .accessibilityIdentifier("onlineLoadingProgress")
                                }
                            }.frame(maxWidth: 290).padding(16).background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 20))
                        }
                        if canReveal {
                            Button(primaryTitle, action: primaryAction).font(.subheadline.bold()).padding(16).background(.white.opacity(0.18), in: Capsule())
                        }
                        if let cancel { Button("Cancel search", action: cancel).font(.subheadline.weight(.medium)).padding(8) }
                        Text(footnote).font(.caption2).multilineTextAlignment(.center).foregroundStyle(.white.opacity(0.8)).fixedSize(horizontal: false, vertical: true)
                    }.foregroundStyle(.white).padding(28).frame(maxWidth: .infinity, minHeight: geometry.size.height)
                }
            }
        }.background(YamuTheme.forest).onAppear {
            if !reduceMotion { withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) { float = true } }
        }
    }
}
#Preview { AdventureFindingScene(messages: ["Discovering places near you", "Finding photos & return routes", "Matching your budget & time"], stage: 1, footnote: "Searching online", primaryTitle: "Show discoveries") {} }
