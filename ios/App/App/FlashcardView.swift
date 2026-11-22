import SwiftUI

// ─────────────────────────────────────────────
// MARK: - Flashcards
// ─────────────────────────────────────────────

struct FlashcardView: View {
    let category: Category
    @ObservedObject var stickerStore: StickerStore
    let onBack: () -> Void

    @State private var index = 0
    @State private var direction: Edge = .trailing
    @State private var emojiBounce = false
    @State private var showCelebration = false
    @State private var lastAdvance = Date.distantPast
    @State private var idleWork: DispatchWorkItem?

    private var word: WordItem { category.words[index] }

    var body: some View {
        GeometryReader { geo in
            let u = layoutUnit(geo.size)
            ZStack {
                word.bg
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.35), value: index)

                // The whole screen is the "next" button. Swipes go back/forward.
                Color.clear
                    .contentShape(Rectangle())
                    .ignoresSafeArea()
                    .onTapGesture { advance() }
                    .accessibilityElement()
                    .accessibilityLabel(word.label)
                    .accessibilityHint(L10n.t("Double-tap for the next word", "הקישו פעמיים למילה הבאה"))
                    .accessibilityAddTraits(.isButton)
                    .accessibilityAction { advance() }
                    .accessibilityAction(named: L10n.t("Previous word", "המילה הקודמת")) { goBack() }
                    .accessibilityAction(named: L10n.t("Say it again", "להשמיע שוב")) { AudioManager.shared.say(Voice.word(word)) }
                    .gesture(
                        DragGesture(minimumDistance: 40)
                            .onEnded { v in
                                if v.translation.width < -40 { advance() }
                                else if v.translation.width > 40 { goBack() }
                            }
                    )

                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    card(u: u, size: geo.size)
                        .id(index)
                        .transition(.asymmetric(
                            insertion: .move(edge: direction).combined(with: .scale(scale: 0.6)).combined(with: .opacity),
                            removal: .move(edge: direction == .trailing ? .leading : .trailing).combined(with: .opacity)))
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                    Spacer(minLength: 0)
                    progressDots(u: u)
                        .padding(.bottom, max(geo.safeAreaInsets.bottom, 16) + 18)
                        .allowsHitTesting(false)
                }

                VStack {
                    HStack {
                        Spacer()
                        HoldToExitButton(tint: word.textColor, onExit: onBack)
                    }
                    Spacer()
                }
                .padding(.top, max(geo.safeAreaInsets.top, 12) + 8)
                .padding(.horizontal, 20)

                if showCelebration {
                    CelebrationView(stickerPool: category.stickerPool, stickerStore: stickerStore, onDone: onBack)
                        .transition(.opacity.combined(with: .scale(scale: 1.1)))
                        .zIndex(10)
                }
            }
            .ignoresSafeArea()
        }
        .onAppear { present() }
        .onDisappear { idleWork?.cancel() }
    }

    private func card(u: CGFloat, size: CGSize) -> some View {
        let stage = min(size.width * 0.78, size.height * 0.44)
        return VStack(spacing: 22 * u) {
            ZStack {
                // soft halo "stage" so the picture reads like a character, not an icon
                Circle()
                    .fill(RadialGradient(colors: [.white, .white.opacity(0.55)], center: .center,
                                         startRadius: stage * 0.1, endRadius: stage * 0.55))
                    .frame(width: stage, height: stage)
                    .shadow(color: word.textColor.opacity(0.18), radius: 24, y: 12)
                Circle()
                    .strokeBorder(word.textColor.opacity(0.12), lineWidth: 10 * u)
                    .frame(width: stage, height: stage)
                // little ground shadow under the character
                if !CharacterLibrary.has(word.id) {   // drawn characters bring their own shadow
                    Ellipse()
                        .fill(word.textColor.opacity(0.12))
                        .frame(width: stage * (emojiBounce ? 0.38 : 0.46), height: stage * 0.06)
                        .offset(y: stage * 0.33)
                }
                WordArt(word: word, mood: emojiBounce ? .happy : .idle)
                    .frame(width: stage * 0.68, height: stage * 0.68)
                    .scaleEffect(x: emojiBounce ? 0.92 : 1, y: emojiBounce ? 1.14 : 1, anchor: .bottom)
                    .offset(y: emojiBounce ? -stage * 0.06 : 0)
                    .rotationEffect(.degrees(emojiBounce ? -4 : 0))
            }
            Text(word.label)
                .font(.system(size: min(60 * u, size.width * 0.14), weight: .black, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .padding(.horizontal, 34 * u)
                .padding(.vertical, 10 * u)
                .background(
                    ZStack {
                        Capsule().fill(word.textColor).offset(y: 6 * u)
                            .overlay(Capsule().fill(Color.black.opacity(0.2)).offset(y: 6 * u))
                        Capsule().fill(word.textColor)
                        Capsule().fill(LinearGradient(colors: [.white.opacity(0.3), .clear],
                                                      startPoint: .top, endPoint: .center))
                    }
                )
                .padding(.horizontal, 20)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(word.label)
    }

    private func progressDots(u: CGFloat) -> some View {
        HStack(spacing: 9 * u) {
            ForEach(0..<category.words.count, id: \.self) { i in
                Capsule()
                    .fill(word.textColor.opacity(i <= index ? 0.9 : 0.22))
                    .frame(width: i == index ? 26 * u : 10 * u, height: 10 * u)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: index)
        .accessibilityHidden(true)
    }

    // MARK: Logic

    /// Babies tap in bursts; ignore taps that arrive before the word was heard.
    private var canAdvance: Bool { Date().timeIntervalSince(lastAdvance) > 0.65 }

    private func advance() {
        guard canAdvance, !showCelebration else { return }
        lastAdvance = Date()
        Haptics.tap()
        if index < category.words.count - 1 {
            direction = .trailing
            withAnimation(.spring(response: 0.42, dampingFraction: 0.78)) { index += 1 }
            present()
        } else {
            idleWork?.cancel()
            withAnimation(.spring()) { showCelebration = true }
        }
    }

    private func goBack() {
        guard canAdvance, index > 0, !showCelebration else { return }
        lastAdvance = Date()
        Haptics.tap()
        direction = .leading
        withAnimation(.spring(response: 0.42, dampingFraction: 0.78)) { index -= 1 }
        present()
    }

    private func present() {
        let w = word
        stickerStore.markHeard(w.id)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            AudioManager.shared.say(Voice.word(w))
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.35)) { emojiBounce = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { emojiBounce = false }
            }
        }
        scheduleIdleRepeat()
    }

    /// If the child just looks for a while, say the word once more.
    private func scheduleIdleRepeat() {
        idleWork?.cancel()
        let current = index
        let work = DispatchWorkItem {
            guard current == index, !showCelebration else { return }
            AudioManager.shared.say(Voice.word(word))
            withAnimation(.spring(response: 0.25, dampingFraction: 0.35)) { emojiBounce = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring()) { emojiBounce = false }
            }
        }
        idleWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.5, execute: work)
    }
}
