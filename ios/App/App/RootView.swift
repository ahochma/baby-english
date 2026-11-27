import SwiftUI

// ─────────────────────────────────────────────
// MARK: - Navigation
// ─────────────────────────────────────────────

enum Screen: Equatable {
    case home
    case games
    case flashcards(Category)
    case bubbles
    case findIt
    case feedPip
    case peekaboo
    case balloons
    case shadows
    case stickers

    /// Music plays only where nothing is being taught.
    var allowsMusic: Bool {
        switch self {
        case .home, .games, .stickers: return true
        case .flashcards, .bubbles, .findIt, .feedPip, .peekaboo, .balloons, .shadows: return false
        }
    }

    /// A screen where the child is playing or learning (counts toward the parent tip).
    var isPlay: Bool {
        switch self {
        case .home, .games, .stickers: return false
        default: return true
        }
    }

    var key: String {
        switch self {
        case .home: return "home"
        case .games: return "games"
        case .flashcards(let c): return "cards-\(c.id)"
        case .bubbles: return "bubbles"
        case .findIt: return "findit"
        case .feedPip: return "feedpip"
        case .peekaboo: return "peekaboo"
        case .balloons: return "balloons"
        case .shadows: return "shadows"
        case .stickers: return "stickers"
        }
    }
}

/// Everything a grown-up does lives behind the parental gate.
enum ParentRoute: String, Identifiable {
    case paywall, parentZone
    var id: String { rawValue }
}

struct RootView: View {
    @ObservedObject private var stickers = StickerStore.shared
    @ObservedObject private var store = PurchaseManager.shared
    @State private var screen: Screen = {
        switch DemoMode.startScreen {
        case "bubbles": return .bubbles
        case "findit": return .findIt
        case "feedpip": return .feedPip
        case "peekaboo": return .peekaboo
        case "balloons": return .balloons
        case "shadows": return .shadows
        case "stickers": return .stickers
        case "games": return .games
        case "cards": return .flashcards(ALL_CATEGORIES[0])
        case let s? where s.hasPrefix("cards:"):   // e.g. cards:vehicles
            let id = String(s.dropFirst(6))
            return .flashcards(ALL_CATEGORIES.first { $0.id == id } ?? ALL_CATEGORIES[0])
        default: return .home
        }
    }()
    @State private var parentRoute: ParentRoute?
    @State private var lastNavigation = Date.distantPast
    @State private var gameStartedAt: Date?

    /// Toddlers tap in bursts. While a screen is fading out it still receives
    /// touches, so ignore navigation requests that arrive mid-transition.
    private func go(_ next: Screen) {
        guard Date().timeIntervalSince(lastNavigation) > 0.6 else { return }
        lastNavigation = Date()
        // A game counts once the child really played it (not a quick open-and-close).
        if let start = gameStartedAt, Date().timeIntervalSince(start) > 20 {
            SettingsStore.shared.recordGamePlayed()
        }
        gameStartedAt = next.isPlay ? Date() : nil
        screen = next
    }

    private func openParent(_ route: ParentRoute) {
        guard Date().timeIntervalSince(lastNavigation) > 0.6 else { return }
        lastNavigation = Date()
        parentRoute = route
    }

    var body: some View {
        ZStack {
            content
                .id(screen.key)
                .transition(.asymmetric(insertion: .opacity.combined(with: .scale(scale: 1.03)),
                                        removal: .opacity))
        }
        .animation(.easeInOut(duration: 0.28), value: screen.key)
        .onAppear { AudioManager.shared.setMusicScene(allowed: screen.allowsMusic) }
        .onChange(of: screen.key) { _ in AudioManager.shared.setMusicScene(allowed: screen.allowsMusic) }
        // The child's world is English, so it always reads left-to-right even on
        // a Hebrew device. Grown-up screens set their own direction.
        .environment(\.layoutDirection, .leftToRight)
        .fullScreenCover(item: $parentRoute) { route in
            ParentFlowView(route: route, onClose: { parentRoute = nil })
        }
    }

    @ViewBuilder
    private var content: some View {
        switch screen {
        case .home:
            HomeView(
                stickers: stickers,
                store: store,
                onSelectCategory: { cat in
                    if store.isAvailable(cat) { go(.flashcards(cat)) } else { openParent(.paywall) }
                },
                onGames: { go(.games) },
                onStickers: { go(.stickers) },
                onParents: { openParent(.parentZone) }
            )
        case .games:
            GamesView(onBubbles: { go(.bubbles) },
                      onFindIt: { go(.findIt) },
                      onFeedPip: { go(.feedPip) },
                      onPeekaboo: { go(.peekaboo) },
                      onBalloons: { go(.balloons) },
                      onShadows: { go(.shadows) },
                      onBack: { go(.home) })
        case .flashcards(let cat):
            FlashcardView(category: cat, stickerStore: stickers, onBack: { go(.home) })
        case .bubbles:
            BubblePopView(words: store.availableWords, stickerStore: stickers, onBack: { go(.games) })
        case .findIt:
            FindItView(words: store.availableWords, stickerStore: stickers, onBack: { go(.games) })
        case .feedPip:
            FeedPipView(foods: store.availableWords.filter { FeedPipView.foodIDs.contains($0.id) },
                        stickerStore: stickers, onBack: { go(.games) })
        case .peekaboo:
            PeekabooView(words: store.availableWords, stickerStore: stickers, onBack: { go(.games) })
        case .balloons:
            BalloonsView(colors: store.availableWords.filter { BalloonsView.colorIDs.contains($0.id) },
                         stickerStore: stickers, onBack: { go(.games) })
        case .shadows:
            ShadowsView(words: store.availableWords.filter { !BalloonsView.colorIDs.contains($0.id) },
                        stickerStore: stickers, onBack: { go(.games) })
        case .stickers:
            StickerBoardView(stickerStore: stickers, onBack: { go(.home) })
        }
    }
}

/// Gate first, then the grown-up screen that was requested.
struct ParentFlowView: View {
    let route: ParentRoute
    let onClose: () -> Void
    @State private var passed = false

    var body: some View {
        ZStack {
            if passed {
                switch route {
                case .paywall:
                    PaywallView(onClose: onClose)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                case .parentZone:
                    ParentZoneView(onClose: onClose)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            } else {
                ParentalGateView(onPass: { withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) { passed = true } },
                                 onCancel: onClose)
                    .transition(.opacity)
            }
        }
        .environment(\.layoutDirection, L10n.direction)
    }
}
