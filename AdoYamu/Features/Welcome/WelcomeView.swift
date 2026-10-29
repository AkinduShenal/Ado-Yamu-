import SwiftUI

struct ScenicBackdrop: View {
    var blurred = false
    var body: some View {
        GeometryReader { geometry in
            Image("welcome").resizable().scaledToFill().frame(width: geometry.size.width, height: geometry.size.height).clipped().blur(radius: blurred ? 8 : 0)
        }.ignoresSafeArea().accessibilityHidden(true)
    }
}
struct WelcomeView: View {
    var showsGetStarted = true
    @Environment(ExplorerStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false
    var body: some View {
        ZStack {
            ScenicBackdrop()
            LinearGradient(colors: [.black.opacity(0.08), .clear, .black.opacity(0.28)], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer(minLength: 25)
                VStack(spacing: 13) {
                    Image(systemName: "mappin").font(.system(size: 52, weight: .heavy)).foregroundStyle(YamuTheme.orange).rotationEffect(.degrees(9))
                    Text("Ado\nYamu!").font(.system(size: 69, weight: .heavy, design: .rounded)).italic().lineSpacing(-8).multilineTextAlignment(.center)
                        .shadow(color: .black.opacity(0.12), radius: 5, y: 3).accessibilityLabel("Ado Yamu!")
                        .accessibilityIdentifier(showsGetStarted ? "welcomeBrand" : "launchSplash")
                    Capsule().fill(YamuTheme.orange).frame(width: 134, height: 7).rotationEffect(.degrees(-7))
                    Text("Discover little adventures\nin Sri Lanka").font(.system(.title3, design: .rounded, weight: .medium)).multilineTextAlignment(.center).padding(.top, 15)
                }.foregroundStyle(.white)
                    .opacity(!showsGetStarted || appeared ? 1 : 0)
                    .offset(y: !showsGetStarted || appeared || reduceMotion ? 0 : 10)
                Spacer(minLength: 55)
                if showsGetStarted {
                    Button {
                        store.preferences.onboardingComplete = true
                        store.save()
                    } label: {
                        HStack(spacing: 14) { Text("Get Started").fontWeight(.bold); Image(systemName: "arrow.right") }
                            .font(.system(.headline, design: .rounded)).foregroundStyle(YamuTheme.ink).frame(maxWidth: .infinity).padding(20).background(.white, in: Capsule())
                    }.buttonStyle(PressStyle()).accessibilityIdentifier("getStarted")
                    Text("A little spontaneous. A lot of Sri Lanka.").font(.caption).foregroundStyle(.white.opacity(0.85)).padding(.top, 18)
                } else {
                    // Keep the brand in the same position as the welcome composition.
                    Color.clear.frame(height: 100).accessibilityHidden(true)
                }
            }.padding(.horizontal, 38).padding(.bottom, 30)
        }.onAppear { withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) { appeared = true } }
    }
}
#Preview { if let store = PreviewEnvironment.store() { WelcomeView().environment(store).preferredColorScheme(.dark) } }
#Preview("Launch splash") { if let store = PreviewEnvironment.store() { WelcomeView(showsGetStarted: false).environment(store).preferredColorScheme(.dark) } }
