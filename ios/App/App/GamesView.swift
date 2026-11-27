import SwiftUI

// ─────────────────────────────────────────────
// MARK: - Games menu
// ─────────────────────────────────────────────
//
// Home shows only the six word worlds, a "Let's play!" button and the
// stickers. The games live here, one tap away, as six big tiles, so
// Home stays calm and new games have room to arrive.

struct GamesView: View {
    let onBubbles: () -> Void
    let onFindIt: () -> Void
    let onFeedPip: () -> Void
    let onPeekaboo: () -> Void
    let onBalloons: () -> Void
    let onShadows: () -> Void
    let onBack: () -> Void

    @State private var appeared = false
    @State private var cheer = false

    private struct Game: Identifiable {
        let id: String
        let title: String
        let subtitle: String
        let emoji: String
        let colors: [Color]
        let action: () -> Void
    }

    private var games: [Game] {
        [
            Game(id: "bubbles", title: "Bubbles", subtitle: "Pop!", emoji: "🫧",
                 colors: [Color(hex: "#5CCBFF"), Color(hex: "#2E9BF0")], action: onBubbles),
            Game(id: "findit", title: "Find it!", subtitle: "Listen!", emoji: "🔍",
                 colors: [Color(hex: "#FFCF4A"), Color(hex: "#FF9F1C")], action: onFindIt),
            Game(id: "feedpip", title: "Feed Pip", subtitle: "Yum!", emoji: "🍓",
                 colors: [Color(hex: "#FF8A80"), Color(hex: "#F4511E")], action: onFeedPip),
            Game(id: "peekaboo", title: "Peekaboo", subtitle: "Knock!", emoji: "🚪",
                 colors: [Color(hex: "#B388FF"), Color(hex: "#7C4DFF")], action: onPeekaboo),
            Game(id: "balloons", title: "Balloons", subtitle: "Pop it!", emoji: "🎈",
                 colors: [Color(hex: "#F48FB1"), Color(hex: "#EC407A")], action: onBalloons),
            Game(id: "shadows", title: "Shadows", subtitle: "Who's that?", emoji: "👤",
                 colors: [Color(hex: "#9FA8DA"), Color(hex: "#5C6BC0")], action: onShadows),
        ]
    }

    var body: some View {
        GeometryReader { geo in
            let u = layoutUnit(geo.size)
            let wide = geo.size.width > geo.size.height * 1.05
            let spacing = 18 * u
            let topPad = max(geo.safeAreaInsets.top, 12) + 4
            let bottomPad = max(geo.safeAreaInsets.bottom, 12) + 12
            let headerH = 86 * u
            let columns = wide ? 3 : 2
            let rows = games.chunked(columns)

            ZStack {
                Scenery(hillHeight: 0.15)
                    .ignoresSafeArea()

                VStack(spacing: spacing) {
                    // Home button · Pip says "Let's play!"
                    ZStack {
                        HStack(spacing: 8 * u) {
                            Mascot(mood: cheer ? .cheer : .happy)
                                .frame(width: 76 * u, height: 76 * u)
                                .onTapGesture(perform: sayLetsPlay)
                            SpeechBubble(text: "Let's play!", size: 24 * u)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityAddTraits(.isHeader)
                        HStack {
                            Spacer()
                            BabyPressable(action: onBack) {
                                Text("🏠")
                                    .font(.system(size: 30 * u))
                                    .frame(width: 58 * u, height: 58 * u)
                                    .background(Circle().fill(Color.white.opacity(0.85)))
                                    .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                            }
                            .accessibilityLabel(L10n.t("Home", "בית"))
                        }
                    }
                    .frame(height: headerH)

                    VStack(spacing: spacing) {
                        ForEach(Array(rows.enumerated()), id: \.offset) { r, row in
                            HStack(spacing: spacing) {
                                ForEach(Array(row.enumerated()), id: \.element.id) { c, game in
                                    GameTile(title: game.title, subtitle: game.subtitle, emoji: game.emoji,
                                             colors: game.colors, unit: u, onTap: game.action)
                                        .appearPop(appeared, delay: Double(r * columns + c) * 0.07)
                                }
                            }
                        }
                    }
                    .frame(maxHeight: .infinity)
                }
                .padding(.horizontal, wide ? 32 * u : 18 * u)
                .padding(.top, topPad)
                .padding(.bottom, bottomPad)
                .frame(maxWidth: wide ? 1100 : 700)
                .frame(maxWidth: .infinity)
            }
            .ignoresSafeArea()
        }
        .onAppear {
            appeared = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: sayLetsPlay)
        }
    }

    private func sayLetsPlay() {
        AudioManager.shared.play("lets_play")
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { cheer = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation { cheer = false }
        }
    }
}

/// A big game tile: the game's picture on top, its name and a one-word call below.
struct GameTile: View {
    let title: String
    let subtitle: String
    let emoji: String
    let colors: [Color]
    let unit: CGFloat
    let onTap: () -> Void

    var body: some View {
        ChunkyButton(colors: colors, lip: colors.last!, radius: 34 * unit, depth: 8 * unit, action: onTap) {
            GeometryReader { g in
                VStack(spacing: 6 * unit) {
                    CharacterBadge(emoji: emoji, ring: .white)
                        .frame(height: g.size.height * 0.52)
                    Text(title)
                        .font(.system(size: min(30 * unit, g.size.height * 0.15), weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: colors.last!.opacity(0.9), radius: 0, y: 2)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    Text(subtitle)
                        .font(.system(size: min(18 * unit, g.size.height * 0.09), weight: .heavy, design: .rounded))
                        .foregroundColor(.white.opacity(0.92))
                        .lineLimit(1)
                }
                .padding(.vertical, 10 * unit)
                .frame(width: g.size.width, height: g.size.height)
            }
        }
        .accessibilityLabel(title)
    }
}
