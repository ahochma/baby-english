import SwiftUI

// ─────────────────────────────────────────────
// MARK: - Navigation
// ─────────────────────────────────────────────

enum Screen: Equatable {
    case home
    case flashcards(Category)
    case bubbles
    case findIt
    case stickers

    var key: String {
        switch self {
        case .home: return "home"
        case .flashcards(let c): return "cards-\(c.id)"
        case .bubbles: return "bubbles"
        case .findIt: return "findit"
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
        case "stickers": return .stickers
        case "cards": return .flashcards(ALL_CATEGORIES[0])
        default: return .home
        }
    }()
    @State private var parentRoute: ParentRoute?
    @State private var lastNavigation = Date.distantPast

    /// Toddlers tap in bursts. While a screen is fading out it still receives
    /// touches, so ignore navigation requests that arrive mid-transition.
    private func go(_ next: Screen) {
        guard Date().timeIntervalSince(lastNavigation) > 0.6 else { return }
        lastNavigation = Date()
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
                onBubbles: { go(.bubbles) },
                onFindIt: { go(.findIt) },
                onStickers: { go(.stickers) },
                onParents: { openParent(.parentZone) }
            )
        case .flashcards(let cat):
            FlashcardView(category: cat, stickerStore: stickers, onBack: { go(.home) })
        case .bubbles:
            BubblePopView(words: store.availableWords, stickerStore: stickers, onBack: { go(.home) })
        case .findIt:
            FindItView(words: store.availableWords, stickerStore: stickers, onBack: { go(.home) })
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
