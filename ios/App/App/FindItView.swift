import SwiftUI

// ─────────────────────────────────────────────
// MARK: - Find It! (ages 18 months+)
// ─────────────────────────────────────────────
//
// The child hears a word and touches the matching picture.
// - Starts with only 2 big pictures, adapts up to 4 as the child succeeds.
// - A wrong touch is never punished: the card wiggles and the word repeats.
// - After two misses the right card glows to guide the child (scaffolding).

struct FindItView: View {
    let words: [WordItem]
    @ObservedObject var stickerStore: StickerStore
    let onBack: () -> Void

    @State private var target: WordItem?
    @State private var choices: [WordItem] = []
    @State private var choiceCount = 2
    @State private var firstTryStreak = 0
    @State private var missesThisRound = 0
    @State private var solved = false
    @State private var shakes: [String: Int] = [:]
    @State private var roundsWon = 0
    @State private var recentTargets: [String] = []
    @State private var showCelebration = false
    @State private var listening = false
    @State private var roundID = UUID()
    @State private var idleWork: DispatchWorkItem?

    private let roundsPerSticker = 5

    var body: some View {
        GeometryReader { geo in
            let u = layoutUnit(geo.size)
            ZStack {
                LinearGradient(colors: [Color(hex: "#FFF8E1"), Color(hex: "#FFE0B2")],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                VStack(spacing: 18 * u) {
                    // Top bar
                    HStack(alignment: .center) {
                        stars(u: u)
                        Spacer()
                        HoldToExitButton(tint: Color(hex: "#FB8C00"), onExit: onBack)
                    }

                    HStack(spacing: 10 * u) {
                        Mascot(mood: solved ? .cheer : .idle)
                            .frame(width: 84 * u, height: 84 * u)
                        listenButton(u: u)
                    }

                    choiceGrid(size: geo.size, u: u)
                        .id(roundID)
                        .transition(.asymmetric(insertion: .scale(scale: 0.7).combined(with: .opacity),
                                                removal: .opacity))
                        .frame(maxHeight: .infinity)
                }
                .padding(.top, max(geo.safeAreaInsets.top, 12) + 8)
                .padding(.bottom, max(geo.safeAreaInsets.bottom, 12) + 12)
                .padding(.horizontal, 20 * u)
                .frame(maxWidth: 1000)
                .frame(maxWidth: .infinity)

                if solved {
                    ConfettiView(emojis: ["⭐", "🌟", "✨"], count: 18)
                        .ignoresSafeArea()
                }

                if showCelebration {
                    CelebrationView(stickerPool: words.map(\.emoji) + ["🔍", "🏅"],
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
        .onAppear { if target == nil { newRound() } }
        .onDisappear { idleWork?.cancel() }
    }

    // MARK: Pieces

    private func stars(u: CGFloat) -> some View {
        HStack(spacing: 4 * u) {
            ForEach(0..<roundsPerSticker, id: \.self) { i in
                Image(systemName: i < roundsWon ? "star.fill" : "star")
                    .font(.system(size: 22 * u, weight: .bold))
                    .foregroundColor(i < roundsWon ? Color(hex: "#FFB300") : Color(hex: "#FFCC80"))
                    .scaleEffect(i == roundsWon - 1 ? 1.2 : 1)
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(Capsule().fill(Color.white.opacity(0.6)))
        .animation(.spring(response: 0.35, dampingFraction: 0.45), value: roundsWon)
        .accessibilityLabel(L10n.t("\(roundsWon) of \(roundsPerSticker) stars", "\(roundsWon) מתוך \(roundsPerSticker) כוכבים"))
    }

    private func listenButton(u: CGFloat) -> some View {
        BabyPressable(action: sayTarget) {
            HStack(spacing: 12 * u) {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.system(size: 30 * u, weight: .bold))
                    .foregroundColor(.white)
                    .scaleEffect(listening ? 1.15 : 1)
                if solved, let target {
                    Text(target.label)
                        .font(.system(size: 32 * u, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Text("?")
                        .font(.system(size: 34 * u, weight: .black, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                }
            }
            .padding(.horizontal, 30 * u)
            .padding(.vertical, 14 * u)
            .background(Capsule().fill(LinearGradient(colors: [Color(hex: "#FFCA28"), Color(hex: "#FB8C00")],
                                                     startPoint: .top, endPoint: .bottom)))
            .shadow(color: Color(hex: "#FB8C00").opacity(0.4), radius: listening ? 16 : 8, y: 5)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: solved)
            .animation(.easeInOut(duration: 0.3), value: listening)
        }
        .accessibilityLabel(L10n.t("Hear the word again", "שמעו שוב את המילה"))
    }

    private func choiceGrid(size: CGSize, u: CGFloat) -> some View {
        let wide = size.width > size.height
        let columns: Int = {
            switch choices.count {
            case 2: return wide ? 2 : 1
            case 3: return wide ? 3 : 2
            default: return 2
            }
        }()
        let rows = choices.chunked(columns)
        return VStack(spacing: 16 * u) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: 16 * u) {
                    ForEach(row) { w in
                        ChoiceCard(word: w,
                                   unit: u,
                                   phase: cardState(for: w),
                                   shakes: shakes[w.id, default: 0],
                                   hint: missesThisRound >= 2 && w.id == target?.id && !solved,
                                   onTap: { choose(w) })
                    }
                }
            }
        }
    }

    private func cardState(for w: WordItem) -> ChoiceCard.Phase {
        guard solved else { return .normal }
        return w.id == target?.id ? .correct : .faded
    }

    // MARK: Game logic

    private func newRound() {
        idleWork?.cancel()
        guard words.count >= 2 else { return }
        let fresh = words.filter { !recentTargets.contains($0.id) }
        let t = (fresh.isEmpty ? words : fresh).randomElement()!
        recentTargets.append(t.id)
        if recentTargets.count > 3 { recentTargets.removeFirst() }

        // Distractors with different labels ("Orange" the fruit vs the color).
        var picks = [t]
        for w in words.shuffled() where picks.count < min(choiceCount, words.count) {
            if !picks.contains(where: { $0.label == w.label || $0.emoji == w.emoji }) { picks.append(w) }
        }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
            target = t
            choices = picks.shuffled()
            solved = false
            missesThisRound = 0
            shakes = [:]
            roundID = UUID()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { sayTarget() }
    }

    private func sayTarget() {
        guard let target else { return }
        if DemoMode.isOn && !solved {
            let round = roundID
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                if round == roundID, let t = self.target { choose(t) }
            }
        }
        let length = AudioManager.shared.say(Voice.whereIs(target))
        listening = true
        DispatchQueue.main.asyncAfter(deadline: .now() + max(0.6, length)) {
            listening = false
        }
        scheduleIdleRepeat()
    }

    private func scheduleIdleRepeat() {
        idleWork?.cancel()
        let round = roundID
        let work = DispatchWorkItem {
            guard round == roundID, !solved, !showCelebration else { return }
            sayTarget()
        }
        idleWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 7, execute: work)
    }

    private func choose(_ w: WordItem) {
        guard !solved, !showCelebration, let target else { return }
        if w.id == target.id {
            idleWork?.cancel()
            Haptics.success()
            AudioManager.shared.play(.chime, volume: 0.6)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                AudioManager.shared.say([target.id, Voice.praise()], gap: 0.3)
            }
            stickerStore.markHeard(target.id)
            withAnimation(.spring(response: 0.4, dampingFraction: 0.55)) {
                solved = true
                roundsWon += 1
            }
            // Adapt difficulty
            if missesThisRound == 0 {
                firstTryStreak += 1
                if firstTryStreak >= 3 && choiceCount < 4 { choiceCount += 1; firstTryStreak = 0 }
            } else {
                firstTryStreak = 0
                if missesThisRound >= 2 && choiceCount > 2 { choiceCount -= 1 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
                if roundsWon >= roundsPerSticker {
                    roundsWon = 0
                    withAnimation { showCelebration = true }
                } else {
                    newRound()
                }
            }
        } else {
            missesThisRound += 1
            Haptics.tap()
            AudioManager.shared.play(.boing, volume: 0.35)
            withAnimation(.linear(duration: 0.45)) { shakes[w.id, default: 0] += 1 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                guard !solved else { return }
                let length = AudioManager.shared.say(["try_again"] + Voice.whereIs(target), gap: 0.3)
                listening = true
                DispatchQueue.main.asyncAfter(deadline: .now() + max(0.6, length)) { listening = false }
                scheduleIdleRepeat()
            }
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - Choice card
// ─────────────────────────────────────────────

struct ChoiceCard: View {
    enum Phase { case normal, correct, faded }

    let word: WordItem
    let unit: CGFloat
    let phase: Phase
    let shakes: Int
    let hint: Bool
    let onTap: () -> Void
    @State private var glow = false

    var body: some View {
        ChunkyButton(colors: [.white, Color(hex: "#F4F7FF")],
                     lip: phase == .correct ? Color(hex: "#43A047") : Color(hex: "#C9D3E6"),
                     radius: 34 * unit, depth: 8 * unit,
                     action: onTap) {
            GeometryReader { g in
                ZStack {
                    RoundedRectangle(cornerRadius: 34 * unit, style: .continuous)
                        .fill(word.bg.opacity(0.45))
                        .padding(8 * unit)
                    RoundedRectangle(cornerRadius: 34 * unit, style: .continuous)
                        .strokeBorder(phase == .correct ? Color(hex: "#66BB6A") : (hint && glow ? Color(hex: "#FFCA28") : Color.clear),
                                      lineWidth: 7 * unit)
                    Text(word.emoji)
                        .font(.system(size: min(g.size.width, g.size.height) * 0.58))
                    if phase == .correct {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 40 * unit))
                            .foregroundColor(Color(hex: "#43A047"))
                            .background(Circle().fill(Color.white))
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                            .padding(14 * unit)
                            .transition(.scale)
                    }
                }
                .frame(width: g.size.width, height: g.size.height)
            }
        }
        .scaleEffect(phase == .correct ? 1.05 : (phase == .faded ? 0.88 : (hint && glow ? 1.04 : 1)))
        .opacity(phase == .faded ? 0.3 : 1)
        .modifier(ShakeEffect(shakes: CGFloat(shakes)))
        .onChange(of: hint) { on in
            if on {
                withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) { glow = true }
            } else {
                glow = false
            }
        }
        .accessibilityLabel(word.label)
    }
}

struct ShakeEffect: GeometryEffect {
    var shakes: CGFloat
    var animatableData: CGFloat {
        get { shakes }
        set { shakes = newValue }
    }
    func effectValue(size: CGSize) -> ProjectionTransform {
        let angle = sin(shakes * .pi * 4) * 0.06
        let dx = sin(shakes * .pi * 4) * 10
        return ProjectionTransform(CGAffineTransform(translationX: dx, y: 0)
            .translatedBy(x: size.width / 2, y: size.height / 2)
            .rotated(by: angle)
            .translatedBy(x: -size.width / 2, y: -size.height / 2))
    }
}
