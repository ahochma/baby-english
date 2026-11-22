import SwiftUI

// ─────────────────────────────────────────────
// MARK: - Celebration + sticker reward
// ─────────────────────────────────────────────

struct CelebrationView: View {
    let stickerPool: [String]
    @ObservedObject var stickerStore: StickerStore
    var autoDismissAfter: Double = 5.0
    /// Opening Pip's daily gift instead of finishing a round.
    var isDailyGift = false
    let onDone: () -> Void

    @State private var titleIn = false
    @State private var stickerIn = false
    @State private var sticker = ""
    @State private var canTap = false
    @State private var finished = false

    var body: some View {
        GeometryReader { geo in
            let u = layoutUnit(geo.size)
            ZStack {
                RadialGradient(colors: [Color(hex: "#FFFDE7"), Color(hex: "#FFE082")],
                               center: .center, startRadius: 10, endRadius: max(geo.size.width, geo.size.height))
                    .ignoresSafeArea()

                // rotating sunburst
                SunburstView()
                    .scaleEffect(u * 1.3)
                    .opacity(0.35)
                    .position(x: geo.size.width / 2, y: geo.size.height * 0.52)

                if !Motion.reduced {
                    ConfettiView()
                        .ignoresSafeArea()
                }

                VStack(spacing: 18 * u) {
                    Mascot(mood: .cheer)
                        .frame(width: 120 * u, height: 120 * u)
                        .scaleEffect(titleIn ? 1 : 0.2)
                        .offset(y: titleIn ? 0 : 200)
                    Text("Yay!")
                        .font(.system(size: 72 * u, weight: .black, design: .rounded))
                        .foregroundColor(Color(hex: "#F57F17"))
                        .shadow(color: .white, radius: 0, x: 3, y: 3)
                        .scaleEffect(titleIn ? 1 : 0.2)
                        .rotationEffect(.degrees(titleIn ? 0 : -20))

                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 170 * u, height: 170 * u)
                            .shadow(color: Color(hex: "#FF8F00").opacity(0.35), radius: 20, y: 8)
                        Circle()
                            .strokeBorder(Color(hex: "#FFCA28"), style: StrokeStyle(lineWidth: 6 * u, dash: [14 * u, 10 * u]))
                            .frame(width: 152 * u, height: 152 * u)
                        Text(sticker)
                            .font(.system(size: 96 * u))
                    }
                    .scaleEffect(stickerIn ? 1 : 0.01)
                    .rotationEffect(.degrees(stickerIn ? 0 : 180))

                    Text("⭐️⭐️⭐️")
                        .font(.system(size: 44 * u))
                        .opacity(stickerIn ? 1 : 0)
                        .offset(y: stickerIn ? 0 : 30)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { if canTap { finish() } }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L10n.t("Great job! You earned a sticker.", "כל הכבוד! קיבלתם מדבקה."))
        .accessibilityAction { finish() }
        .onAppear(perform: start)
    }

    private func start() {
        if isDailyGift {
            sticker = stickerStore.claimDailyGift() ?? StickerStore.giftPool[0]
        } else {
            sticker = stickerStore.addSticker(from: stickerPool)
        }
        Haptics.success()
        AudioManager.shared.play("celebration")
        withAnimation(.spring(response: 0.5, dampingFraction: 0.5)) { titleIn = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            AudioManager.shared.play(.sparkle)
            withAnimation(.spring(response: 0.55, dampingFraction: 0.55)) { stickerIn = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { canTap = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + autoDismissAfter) { finish() }
    }

    private func finish() {
        guard !finished else { return }
        finished = true
        onDone()
    }
}

struct SunburstView: View {
    @State private var spin = false
    var body: some View {
        ZStack {
            ForEach(0..<16, id: \.self) { i in
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 60, height: 450)
                    .offset(y: -225)
                    .rotationEffect(.degrees(Double(i) * 22.5))
            }
        }
        .mask(RadialGradient(colors: [.white, .clear], center: .center, startRadius: 40, endRadius: 420))
        .rotationEffect(.degrees(spin ? 360 : 0))
        .onAppear {
            guard !Motion.reduced else { return }
            withAnimation(.linear(duration: 30).repeatForever(autoreverses: false)) { spin = true }
        }
        .allowsHitTesting(false)
    }
}
