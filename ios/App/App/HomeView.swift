import SwiftUI

// ─────────────────────────────────────────────
// MARK: - Home Screen
// ─────────────────────────────────────────────

struct HomeView: View {
    @ObservedObject var stickers: StickerStore
    @ObservedObject var store: PurchaseManager
    let onSelectCategory: (Category) -> Void
    let onBubbles: () -> Void
    let onFindIt: () -> Void
    let onStickers: () -> Void
    let onParents: () -> Void

    @State private var appeared = false
    @State private var mascotMood: MascotMood = .idle
    @State private var mascotHop = false
    @State private var showGift = false

    var body: some View {
        GeometryReader { geo in
            let u = layoutUnit(geo.size)
            let wide = geo.size.width > geo.size.height * 1.05
            let spacing = 16 * u
            let topPad = max(geo.safeAreaInsets.top, 12) + 2
            let bottomPad = max(geo.safeAreaInsets.bottom, 12) + 4
            let headerH = 64 * u
            let stickerH = 62 * u
            let fullH = geo.size.height + geo.safeAreaInsets.top + geo.safeAreaInsets.bottom
            let rest = max(200, fullH - topPad - bottomPad - headerH - stickerH - spacing * 3)
            let gamesH = min(rest * (wide ? 0.3 : 0.22), 170 * u)
            let catsH = rest - gamesH

            ZStack {
                Scenery(hillHeight: 0.17)
                    .ignoresSafeArea()

                VStack(spacing: spacing) {
                    header(u: u)
                        .frame(height: headerH)

                    // Word worlds
                    let columns = wide ? 3 : 2
                    let rows = ALL_CATEGORIES.chunked(columns)
                    let rowH = (catsH - spacing * CGFloat(rows.count - 1)) / CGFloat(rows.count)
                    VStack(spacing: spacing) {
                        ForEach(Array(rows.enumerated()), id: \.offset) { r, row in
                            HStack(spacing: spacing) {
                                ForEach(Array(row.enumerated()), id: \.element.id) { c, cat in
                                    CategoryCard(category: cat,
                                                 locked: !store.isAvailable(cat),
                                                 unit: u,
                                                 onTap: { onSelectCategory(cat) })
                                        .appearPop(appeared, delay: Double(r * columns + c) * 0.07)
                                }
                            }
                            .frame(height: rowH)
                        }
                    }
                    .frame(height: catsH)

                    // Games
                    HStack(spacing: spacing) {
                        GameCard(title: "Bubbles", subtitle: "Pop!", emoji: "🫧",
                                 colors: [Color(hex: "#5CCBFF"), Color(hex: "#2E9BF0")],
                                 unit: u, onTap: onBubbles)
                            .appearPop(appeared, delay: 0.32)
                        GameCard(title: "Find it!", subtitle: "Listen!", emoji: "🔍",
                                 colors: [Color(hex: "#FFCF4A"), Color(hex: "#FF9F1C")],
                                 unit: u, onTap: onFindIt)
                            .appearPop(appeared, delay: 0.38)
                    }
                    .frame(height: gamesH)

                    stickerButton(u: u)
                        .frame(width: min(geo.size.width - 60, 340 * u), height: stickerH)
                        .appearPop(appeared, delay: 0.44)
                }
                .padding(.horizontal, wide ? 32 * u : 18 * u)
                .padding(.top, topPad)
                .padding(.bottom, bottomPad)
                .frame(maxWidth: wide ? 1100 : 700)
                .frame(maxWidth: .infinity)

                if showGift {
                    CelebrationView(stickerPool: StickerStore.giftPool, stickerStore: stickers,
                                    autoDismissAfter: 4.5, isDailyGift: true,
                                    onDone: { withAnimation { showGift = false } })
                        .transition(.opacity.combined(with: .scale(scale: 1.05)))
                        .zIndex(10)
                }
            }
            .ignoresSafeArea()
        }
        .onAppear { appeared = true }
    }

    private func header(u: CGFloat) -> some View {
        HStack(alignment: .center, spacing: 0) {
            // Daily gift for the child (or the parents' streak once it's opened)
            Group {
                if stickers.giftAvailable && !showGift {
                    GiftButton(unit: u) {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) { showGift = true }
                    }
                } else if stickers.streak > 1 {
                    HStack(spacing: 3) {
                        Text("🔥").font(.system(size: 17 * u))
                        Text("\(stickers.streak)")
                            .font(.system(size: 17 * u, weight: .black, design: .rounded))
                            .foregroundColor(Color(hex: "#E65100"))
                    }
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(Capsule().fill(Color.white.opacity(0.85)))
                    .accessibilityLabel(L10n.t("\(stickers.streak) days in a row", "\(stickers.streak) ימים ברצף"))
                } else {
                    Color.clear
                }
            }
            .frame(width: 64 * u, height: 40, alignment: .leading)

            Spacer(minLength: 0)
            HStack(spacing: 6 * u) {
                Mascot(mood: mascotMood)
                    .frame(width: 62 * u, height: 62 * u)
                    .offset(y: mascotHop ? -14 * u : 0)
                    .onTapGesture(perform: hopMascot)
                Text("Pip English")
                    .font(.system(size: 31 * u, weight: .black, design: .rounded))
                    .foregroundColor(Palette.ink)
                    .shadow(color: .white.opacity(0.9), radius: 0, x: 0, y: 2.5)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 0)

            // Grown-ups (gated) — small and quiet on purpose
            Button(action: onParents) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 15 * u, weight: .bold))
                    .foregroundColor(Palette.ink.opacity(0.5))
                    .frame(width: 40 * u, height: 40 * u)
                    .background(Circle().fill(Color.white.opacity(0.8)))
            }
            .frame(width: 64 * u, alignment: .trailing)
            .accessibilityLabel(L10n.t("For parents", "להורים"))
        }
    }

    private func hopMascot() {
        Haptics.tap()
        AudioManager.shared.play(.sparkle, volume: 0.4)
        AudioManager.shared.play("hi_pip")
        withAnimation(.spring(response: 0.28, dampingFraction: 0.45)) {
            mascotHop = true
            mascotMood = .cheer
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.5)) { mascotHop = false }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation { mascotMood = .idle }
        }
    }

    private func stickerButton(u: CGFloat) -> some View {
        ChunkyButton(colors: [Color(hex: "#FFD54A"), Color(hex: "#FFA41B")],
                     lip: Color(hex: "#F08A00"),
                     radius: 31 * u, depth: 6 * u,
                     action: onStickers) {
            HStack(spacing: 10 * u) {
                Text("🏆").font(.system(size: 28 * u))
                Text("My Stickers")
                    .font(.system(size: 23 * u, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: Color(hex: "#C76A00").opacity(0.6), radius: 0, y: 2)
                if !stickers.stickers.isEmpty {
                    Text("\(stickers.stickers.count)")
                        .font(.system(size: 16 * u, weight: .black, design: .rounded))
                        .foregroundColor(Color(hex: "#F08A00"))
                        .padding(.horizontal, 10).padding(.vertical, 3)
                        .background(Capsule().fill(Color.white))
                }
            }
        }
        .accessibilityLabel("My Stickers, \(stickers.stickers.count)")
    }
}

// ─────────────────────────────────────────────
// MARK: - Cards
// ─────────────────────────────────────────────

struct CategoryCard: View {
    let category: Category
    let locked: Bool
    let unit: CGFloat
    let onTap: () -> Void

    var body: some View {
        ChunkyButton(colors: [category.gradientStart, category.gradientEnd],
                     lip: category.gradientEnd,
                     radius: 32 * unit, depth: 8 * unit,
                     action: onTap) {
            GeometryReader { g in
                VStack(spacing: 6 * unit) {
                    CharacterBadge(emoji: category.emoji, ring: .white,
                                   word: coverWord(for: category))
                        .frame(height: g.size.height * 0.6)
                    Text(category.label)
                        .font(.system(size: min(25 * unit, g.size.height * 0.15), weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: category.gradientEnd.opacity(0.9), radius: 0, x: 0, y: 2)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
                .padding(.vertical, 10 * unit)
                .frame(width: g.size.width, height: g.size.height)
                .saturation(locked ? 0.6 : 1)
                .overlay(alignment: .topTrailing) {
                    if locked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 13 * unit, weight: .heavy))
                            .foregroundColor(category.gradientEnd)
                            .frame(width: 30 * unit, height: 30 * unit)
                            .background(Circle().fill(Color.white))
                            .shadow(color: .black.opacity(0.15), radius: 3, y: 2)
                            .padding(10 * unit)
                    }
                }
            }
        }
        .accessibilityLabel(locked ? "\(category.label), \(L10n.t("locked", "נעול"))" : category.label)
    }
}

struct GameCard: View {
    let title: String
    let subtitle: String
    let emoji: String
    let colors: [Color]
    let unit: CGFloat
    let onTap: () -> Void

    var body: some View {
        ChunkyButton(colors: colors, lip: colors.last!, radius: 30 * unit, depth: 7 * unit, action: onTap) {
            GeometryReader { g in
                HStack(spacing: 8 * unit) {
                    CharacterBadge(emoji: emoji)
                        .frame(width: min(g.size.height * 0.66, g.size.width * 0.34))
                    VStack(alignment: .leading, spacing: 0) {
                        Text(title)
                            .font(.system(size: min(23 * unit, g.size.height * 0.24), weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: colors.last!.opacity(0.9), radius: 0, y: 2)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                        Text(subtitle)
                            .font(.system(size: min(15 * unit, g.size.height * 0.15), weight: .heavy, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 12 * unit)
                .frame(width: g.size.width, height: g.size.height)
            }
        }
        .accessibilityLabel(title)
    }
}

/// A wobbling present with sparkles. One tap opens today's surprise sticker.
struct GiftButton: View {
    let unit: CGFloat
    let onOpen: () -> Void
    @State private var wobble = false

    var body: some View {
        Text("🎁")
            .font(.system(size: 36 * unit))
            .rotationEffect(.degrees(wobble ? 10 : -10))
            .scaleEffect(wobble ? 1.1 : 0.95)
            .overlay(alignment: .topTrailing) {
                Text("✨").font(.system(size: 16 * unit)).offset(x: 8, y: -6)
                    .opacity(wobble ? 1 : 0.3)
            }
            .frame(width: 56 * unit, height: 56 * unit)
            .contentShape(Rectangle())
            .onTapGesture {
                Haptics.tap()
                AudioManager.shared.play(.sparkle, volume: 0.6)
                onOpen()
            }
            .onAppear {
                if Motion.reduced { wobble = true; return }
                withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) { wobble = true }
            }
            .accessibilityLabel(L10n.t("Surprise gift", "הפתעה"))
            .accessibilityAddTraits(.isButton)
    }
}

// ─────────────────────────────────────────────
// MARK: - Helpers
// ─────────────────────────────────────────────

extension Array {
    func chunked(_ size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map { Array(self[$0..<Swift.min($0 + size, count)]) }
    }
}

private struct AppearPop: ViewModifier {
    let appeared: Bool
    let delay: Double
    func body(content: Content) -> some View {
        content
            .scaleEffect(appeared ? 1 : 0.6)
            .opacity(appeared ? 1 : 0)
            .animation(.spring(response: 0.5, dampingFraction: 0.62).delay(delay), value: appeared)
    }
}

extension View {
    func appearPop(_ appeared: Bool, delay: Double) -> some View {
        modifier(AppearPop(appeared: appeared, delay: delay))
    }
}

/// The drawn character that represents a world on its home card.
private func coverWord(for category: Category) -> WordItem? {
    let fallback = ["colors": "purple", "numbers": "three"]
    return category.words.first { $0.emoji == category.emoji }
        ?? category.words.first { $0.id == fallback[category.id] }
}
