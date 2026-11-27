import SwiftUI

// ─────────────────────────────────────────────
// MARK: - Shadows
// ─────────────────────────────────────────────
//
// A calm, slow game: a friend hides as a dark shadow and Pip asks "Who's
// hiding in the shadow?". The child picks the matching picture; the shadow
// fills with colour and says its name. A wrong picture wiggles and says its
// own name. Two pictures to start, three as the child succeeds; after two
// misses the right one glows. Colours are left out (all paint drops share
// one shape), so every shadow is a different outline.

struct ShadowsView: View {
    let words: [WordItem]
    @ObservedObject var stickerStore: StickerStore
    let onBack: () -> Void

    @State private var target: WordItem?
    @State private var choices: [WordItem] = []
    @State private var choiceCount = 2
    @State private var firstTryStreak = 0
    @State private var misses = 0
    @State private var revealed = false
    @State private var shakes: [String: Int] = [:]
    @State private var roundsWon = 0
    @State private var recent: [String] = []
    @State private var showCelebration = false
    @State private var listening = false
    @State private var roundID = UUID()
    @State private var idleWork: DispatchWorkItem?
    /// Off once the game closes, so delayed callbacks can't keep talking.
    @State private var live = LiveFlag()

    private let roundsPerSticker = 5

    var body: some View {
        GeometryReader { geo in
            let u = layoutUnit(geo.size)
            let wide = geo.size.width > geo.size.height
            let stage = min(geo.size.width * 0.62, geo.size.height * 0.32)
            ZStack {
                LinearGradient(colors: [Color(hex: "#E8EAF6"), Color(hex: "#C5CAE9")],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                VStack(spacing: 16 * u) {
                    HStack(alignment: .center) {
                        StarRow(won: roundsWon, total: roundsPerSticker, unit: u)
                        Spacer()
                        HoldToExitButton(tint: Color(hex: "#5C6BC0"), onExit: onBack)
                    }

                    // The shadow on a soft spotlight; tap it to hear the question again
                    ZStack {
                        Circle()
                            .fill(RadialGradient(colors: [.white, .white.opacity(0.4)], center: .center,
                                                 startRadius: stage * 0.1, endRadius: stage * 0.55))
                            .frame(width: stage, height: stage)
                        if let target {
                            WordArt(word: target, mood: revealed ? .happy : .idle)
                                .frame(width: stage * 0.7, height: stage * 0.7)
                                .brightness(revealed ? 0 : -1)   // pure black outline, fades to colour on reveal
                                .compositingGroup()   // one flat shadow, no inner details showing through
                                .opacity(revealed ? 1 : 0.82)
                                .scaleEffect(revealed ? 1.1 : 1)
                                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: revealed)
                        }
                        if !revealed {
                            Image(systemName: listening ? "speaker.wave.2.fill" : "questionmark.circle.fill")
                                .font(.system(size: 34 * u, weight: .bold))
                                .foregroundColor(Color(hex: "#5C6BC0"))
                                .background(Circle().fill(Color.white).padding(2))
                                .frame(width: stage, height: stage, alignment: .topTrailing)
                        } else if let target {
                            Text(target.label)
                                .font(.system(size: 30 * u, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.horizontal, 22 * u).padding(.vertical, 8 * u)
                                .background(Capsule().fill(target.textColor))
                                .frame(width: stage, height: stage, alignment: .bottom)
                                .offset(y: 16 * u)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .contentShape(Circle())
                    .onTapGesture(perform: sayTarget)
                    .accessibilityElement()
                    .accessibilityLabel(revealed ? (target?.label ?? "") : L10n.t("A shadow. Tap to hear the question", "צל. הקישו כדי לשמוע את השאלה"))
                    .accessibilityAddTraits(.isButton)

                    HStack(spacing: 16 * u) {
                        ForEach(choices) { w in
                            ChoiceCard(word: w,
                                       unit: u,
                                       phase: revealed ? (w.id == target?.id ? .correct : .faded) : .normal,
                                       shakes: shakes[w.id, default: 0],
                                       hint: misses >= 2 && w.id == target?.id && !revealed,
                                       onTap: { choose(w) })
                                .aspectRatio(1, contentMode: .fit)
                        }
                    }
                    .id(roundID)
                    .transition(.asymmetric(insertion: .scale(scale: 0.7).combined(with: .opacity), removal: .opacity))
                    .frame(maxHeight: wide ? geo.size.height * 0.34 : geo.size.height * 0.3)
                    .frame(maxHeight: .infinity)
                }
                .padding(.top, max(geo.safeAreaInsets.top, 12) + 8)
                .padding(.bottom, max(geo.safeAreaInsets.bottom, 12) + 12)
                .padding(.horizontal, 20 * u)
                .frame(maxWidth: 1000)
                .frame(maxWidth: .infinity)

                if showCelebration {
                    CelebrationView(stickerPool: words.map(\.emoji) + ["🌙", "⭐"],
                                    stickerStore: stickerStore,
                                    autoDismissAfter: 4.5,
                                    onDone: {
                                        withAnimation { showCelebration = false }
                                        newRound()
                                    })
                        .transition(.opacity)
                        .zIndex(10)
                }
            }
            .ignoresSafeArea()
        }
        .onAppear {
            live.on = true
            if target == nil { newRound() } else { scheduleIdleRepeat() }
        }
        .onDisappear {
            live.on = false
            idleWork?.cancel()
        }
    }

    // MARK: Game logic

    private func newRound() {
        idleWork?.cancel()
        guard live.on, words.count >= 2 else { return }
        let fresh = words.filter { !recent.contains($0.id) }
        let t = stickerStore.pickForPractice(from: fresh.isEmpty ? words : fresh)!
        recent.append(t.id)
        if recent.count > 3 { recent.removeFirst() }

        var picks = [t]
        for w in words.shuffled() where picks.count < min(choiceCount, words.count) {
            if !picks.contains(where: { $0.label == w.label || $0.emoji == w.emoji }) { picks.append(w) }
        }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
            target = t
            choices = picks.shuffled()
            revealed = false
            misses = 0
            shakes = [:]
            roundID = UUID()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { sayTarget() }
    }

    private func sayTarget() {
        guard live.on, target != nil, !revealed else { return }
        if DemoMode.isOn {
            let round = roundID
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                if round == roundID, let t = self.target { choose(t) }
            }
        }
        let length = AudioManager.shared.say(Voice.whoseShadow)
        listening = true
        DispatchQueue.main.asyncAfter(deadline: .now() + max(0.6, length)) { listening = false }
        scheduleIdleRepeat(after: 9)
    }

    private func scheduleIdleRepeat(after delay: Double = 9) {
        idleWork?.cancel()
        guard live.on else { return }
        let round = roundID
        let work = DispatchWorkItem {
            guard live.on, AudioManager.shared.inForeground,
                  round == roundID, !revealed, !showCelebration else { return }
            sayTarget()
        }
        idleWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }

    private func choose(_ w: WordItem) {
        guard live.on, !revealed, !showCelebration, let target else { return }
        if w.id == target.id {
            idleWork?.cancel()
            stickerStore.recordCorrect(target.id, firstTry: misses == 0)
            stickerStore.markHeard(target.id)
            Haptics.success()
            AudioManager.shared.play(.sparkle, volume: 0.5)
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                revealed = true
                roundsWon += 1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                guard live.on else { return }
                AudioManager.shared.say(Voice.word(target) + [Voice.praise()], gap: 0.3)
            }
            if misses == 0 {
                firstTryStreak += 1
                if firstTryStreak >= 3 && choiceCount < 3 { choiceCount += 1; firstTryStreak = 0 }
            } else {
                firstTryStreak = 0
                if misses >= 2 && choiceCount > 2 { choiceCount -= 1 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) {
                guard live.on else { return }
                if roundsWon >= roundsPerSticker {
                    roundsWon = 0
                    withAnimation { showCelebration = true }
                } else {
                    newRound()
                }
            }
        } else {
            misses += 1
            if misses == 1 { stickerStore.recordMiss(target.id) }
            Haptics.tap()
            withAnimation(.linear(duration: 0.45)) { shakes[w.id, default: 0] += 1 }
            // Not this one: it says its own name, then Pip asks again.
            let length = AudioManager.shared.say(Voice.word(w))
            stickerStore.markHeard(w.id)
            scheduleIdleRepeat(after: max(2.4, length + 1.2))
        }
    }
}
