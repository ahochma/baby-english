import SwiftUI

// ─────────────────────────────────────────────
// MARK: - Feed Pip
// ─────────────────────────────────────────────
//
// Pip is hungry and asks for one food: "I'm hungry! Can I have the banana,
// please?". The child drags it to Pip's beak, or simply taps it (little
// fingers can't always drag). The right food is gobbled up with a happy
// "Mmm! Yummy!"; a wrong one makes Pip shake his head, and after two misses
// a thought bubble shows what he wants. Five meals earn a sticker.

struct FeedPipView: View {
    static let foodIDs: Set<String> = Set(ALL_CATEGORIES.first { $0.id == "food" }?.words.map(\.id) ?? [])

    let foods: [WordItem]
    @ObservedObject var stickerStore: StickerStore
    let onBack: () -> Void

    @State private var target: WordItem?
    @State private var choices: [WordItem] = []
    @State private var choiceCount = 2
    @State private var firstTryStreak = 0
    @State private var misses = 0
    @State private var eaten: String?
    @State private var mood: MascotMood = .hungry
    @State private var headShakes = 0
    @State private var chew = false
    @State private var drags: [String: CGSize] = [:]
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
            let w = geo.size.width, h = geo.size.height
            let top = max(geo.safeAreaInsets.top, 12) + 8
            let pipSize = min(w * 0.5, h * 0.3)
            let pipCenter = CGPoint(x: w / 2, y: h * 0.4)
            let mouth = CGPoint(x: pipCenter.x, y: pipCenter.y + pipSize * 0.06)
            let tableY = h * 0.74
            let slot = min((w - 40 * u) / CGFloat(max(choices.count, 1)), 260 * u)
            let itemSize = min(slot * 0.74, h * 0.16)

            ZStack {
                LinearGradient(colors: [Color(hex: "#FFF3E0"), Color(hex: "#FFE0B2")],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                // the table
                RoundedRectangle(cornerRadius: 30 * u, style: .continuous)
                    .fill(LinearGradient(colors: [Color(hex: "#C98B5E"), Color(hex: "#A86B43")],
                                         startPoint: .top, endPoint: .bottom))
                    .overlay(alignment: .top) {
                        RoundedRectangle(cornerRadius: 30 * u, style: .continuous)
                            .fill(Color(hex: "#DDA77C"))
                            .frame(height: 26 * u)
                    }
                    .frame(width: w + 60, height: h - tableY + itemSize * 0.15 + 60)
                    .position(x: w / 2, y: tableY + itemSize * 0.15 + (h - tableY + 60) / 2)

                // top bar
                HStack(alignment: .center) {
                    StarRow(won: roundsWon, total: roundsPerSticker, unit: u)
                    Spacer()
                    HoldToExitButton(tint: Color(hex: "#FB8C00"), onExit: onBack)
                }
                .padding(.horizontal, 20 * u)
                .frame(maxWidth: 1000)
                .position(x: w / 2, y: top + 26 * u)

                // Pip, with a thought bubble that shows the food after two misses
                Mascot(mood: mood)
                    .frame(width: pipSize, height: pipSize)
                    .scaleEffect(x: chew ? 1.06 : 1, y: chew ? 0.93 : 1, anchor: .bottom)
                    .modifier(ShakeEffect(shakes: CGFloat(headShakes)))
                    .position(pipCenter)
                    .onTapGesture(perform: sayTarget)
                    .accessibilityLabel(L10n.t("Pip. Tap to hear again", "פיפ. הקישו כדי לשמוע שוב"))
                    .accessibilityAddTraits(.isButton)

                thoughtBubble(u: u)
                    .frame(width: pipSize * 0.5, height: pipSize * 0.5)
                    .position(x: pipCenter.x + pipSize * 0.55, y: pipCenter.y - pipSize * 0.55)

                // the foods on their plates
                ForEach(Array(choices.enumerated()), id: \.element.id) { i, food in
                    let home = CGPoint(x: w / 2 + (CGFloat(i) - CGFloat(choices.count - 1) / 2) * slot, y: tableY)
                    foodOnPlate(food, size: itemSize, u: u)
                        .offset(eaten == food.id
                                ? CGSize(width: mouth.x - home.x, height: mouth.y - home.y)
                                : drags[food.id, default: .zero])
                        .scaleEffect(eaten == food.id ? 0.15 : 1)
                        .opacity(eaten == food.id ? 0 : (eaten != nil ? 0.35 : 1))
                        .position(home)
                        .gesture(
                            DragGesture(minimumDistance: 6)
                                .onChanged { v in
                                    guard eaten == nil, !showCelebration else { return }
                                    drags[food.id] = v.translation
                                }
                                .onEnded { v in
                                    let end = CGPoint(x: home.x + v.translation.width, y: home.y + v.translation.height)
                                    if hypot(end.x - pipCenter.x, end.y - pipCenter.y) < pipSize * 0.65 {
                                        choose(food)
                                    } else {
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { drags[food.id] = .zero }
                                    }
                                }
                        )
                        .simultaneousGesture(TapGesture().onEnded { choose(food) })
                        .zIndex(drags[food.id] == nil || drags[food.id] == .zero ? 0 : 5)
                        .id("\(roundID)-\(food.id)")
                        .transition(.scale(scale: 0.6).combined(with: .opacity))
                }

                if eaten != nil && !Motion.reduced {
                    ConfettiView(emojis: ["⭐", "✨", "💛"], count: 16)
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                }

                if showCelebration {
                    CelebrationView(stickerPool: foods.map(\.emoji) + ["😋", "🍽️"],
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

    // MARK: Pieces

    @ViewBuilder
    private func thoughtBubble(u: CGFloat) -> some View {
        GeometryReader { g in
            let d = min(g.size.width, g.size.height)
            ZStack(alignment: .bottomLeading) {
                Circle().fill(Color.white).frame(width: d * 0.16).offset(x: -d * 0.12, y: d * 0.16)
                Circle().fill(Color.white).frame(width: d * 0.1).offset(x: -d * 0.24, y: d * 0.3)
                ZStack {
                    Circle().fill(Color.white)
                        .shadow(color: .black.opacity(0.1), radius: 5, y: 3)
                    if misses >= 2, let target, eaten == nil {
                        WordArt(word: target)
                            .frame(width: d * 0.66, height: d * 0.66)
                            .transition(.scale.combined(with: .opacity))
                    } else {
                        Image(systemName: listening ? "speaker.wave.2.fill" : "questionmark")
                            .font(.system(size: d * 0.36, weight: .black, design: .rounded))
                            .foregroundColor(Color(hex: "#FB8C00"))
                    }
                }
                .frame(width: d, height: d)
            }
            .frame(width: g.size.width, height: g.size.height)
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: misses)
        .onTapGesture(perform: sayTarget)
        .accessibilityLabel(L10n.t("Hear what Pip wants", "שמעו מה פיפ רוצה"))
        .accessibilityAddTraits(.isButton)
    }

    private func foodOnPlate(_ food: WordItem, size: CGFloat, u: CGFloat) -> some View {
        let hint = misses >= 2 && food.id == target?.id && eaten == nil
        return ZStack {
            Ellipse()
                .fill(Color.white)
                .overlay(Ellipse().strokeBorder(Color(hex: "#E3E8F0"), lineWidth: 6 * u))
                .frame(width: size * 1.2, height: size * 0.42)
                .offset(y: size * 0.42)
                .shadow(color: .black.opacity(0.15), radius: 4, y: 3)
            if hint {
                Circle()
                    .fill(Color(hex: "#FFCA28").opacity(0.45))
                    .frame(width: size * 1.15, height: size * 1.15)
                    .modifier(Pulse())
            }
            WordArt(word: food, mood: eaten == food.id ? .happy : .idle)
                .frame(width: size, height: size)
        }
        .frame(width: size * 1.2, height: size * 1.3)
        .contentShape(Rectangle())
        .modifier(ShakeEffect(shakes: CGFloat(shakes[food.id, default: 0])))
        .accessibilityElement()
        .accessibilityLabel(food.label)
        .accessibilityAddTraits(.isButton)
    }

    // MARK: Game logic

    private func newRound() {
        idleWork?.cancel()
        guard live.on, foods.count >= 2 else { return }
        let fresh = foods.filter { !recent.contains($0.id) }
        let t = stickerStore.pickForPractice(from: fresh.isEmpty ? foods : fresh)!
        recent.append(t.id)
        if recent.count > 3 { recent.removeFirst() }

        var picks = [t]
        for f in foods.shuffled() where picks.count < min(choiceCount, foods.count) {
            if !picks.contains(where: { $0.id == f.id }) { picks.append(f) }
        }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
            target = t
            choices = picks.shuffled()
            misses = 0
            eaten = nil
            drags = [:]
            shakes = [:]
            mood = .hungry
            roundID = UUID()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { sayTarget() }
    }

    private func sayTarget() {
        guard live.on, let target, eaten == nil else { return }
        if DemoMode.isOn {
            let round = roundID
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                if round == roundID, let t = self.target { choose(t) }
            }
        }
        let length = AudioManager.shared.say(Voice.want(target))
        listening = true
        DispatchQueue.main.asyncAfter(deadline: .now() + max(0.6, length)) { listening = false }
        scheduleIdleRepeat(after: 8)
    }

    private func scheduleIdleRepeat(after delay: Double = 8) {
        idleWork?.cancel()
        guard live.on else { return }
        let round = roundID
        let work = DispatchWorkItem {
            guard live.on, AudioManager.shared.inForeground,
                  round == roundID, eaten == nil, !showCelebration else { return }
            sayTarget()
        }
        idleWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }

    private func choose(_ food: WordItem) {
        guard live.on, eaten == nil, !showCelebration, let target else { return }
        if food.id == target.id {
            idleWork?.cancel()
            stickerStore.recordCorrect(target.id, firstTry: misses == 0)
            stickerStore.markHeard(target.id)
            Haptics.success()
            AudioManager.shared.play(.chime, volume: 0.5)
            withAnimation(.easeIn(duration: 0.4)) { eaten = food.id }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.55)) { roundsWon += 1 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                guard live.on else { return }
                mood = .yum
                chewAnimation(times: 4)
                AudioManager.shared.say(Voice.word(target) + ["yum"], gap: 0.3)
            }
            // Adapt difficulty
            if misses == 0 {
                firstTryStreak += 1
                if firstTryStreak >= 3 && choiceCount < 4 { choiceCount += 1; firstTryStreak = 0 }
            } else {
                firstTryStreak = 0
                if misses >= 2 && choiceCount > 2 { choiceCount -= 1 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.4) {
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
            AudioManager.shared.play(.boing, volume: 0.35)
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { drags[food.id] = .zero }
            withAnimation(.linear(duration: 0.45)) {
                shakes[food.id, default: 0] += 1
                headShakes += 1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                guard live.on, eaten == nil else { return }
                let length = AudioManager.shared.say(["not_that"] + Voice.want(target), gap: 0.3)
                listening = true
                DispatchQueue.main.asyncAfter(deadline: .now() + max(0.6, length)) { listening = false }
                scheduleIdleRepeat(after: max(8, length + 6))
            }
        }
    }

    private func chewAnimation(times: Int) {
        guard times > 0, live.on else {
            withAnimation(.spring()) { chew = false }
            return
        }
        withAnimation(.easeInOut(duration: 0.16)) { chew.toggle() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            withAnimation(.easeInOut(duration: 0.16)) { chew.toggle() }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) { chewAnimation(times: times - 1) }
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - Shared game pieces
// ─────────────────────────────────────────────

/// Progress toward the next sticker: five stars at the top of a game.
struct StarRow: View {
    let won: Int
    let total: Int
    let unit: CGFloat

    var body: some View {
        HStack(spacing: 4 * unit) {
            ForEach(0..<total, id: \.self) { i in
                Image(systemName: i < won ? "star.fill" : "star")
                    .font(.system(size: 22 * unit, weight: .bold))
                    .foregroundColor(i < won ? Color(hex: "#FFB300") : Color(hex: "#FFCC80"))
                    .scaleEffect(i == won - 1 ? 1.2 : 1)
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(Capsule().fill(Color.white.opacity(0.6)))
        .animation(.spring(response: 0.35, dampingFraction: 0.45), value: won)
        .accessibilityElement()
        .accessibilityLabel(L10n.t("\(won) of \(total) stars", "\(won) מתוך \(total) כוכבים"))
    }
}

/// A gentle repeating pulse, used for hints (still in calm mode, just slower).
struct Pulse: ViewModifier {
    @State private var on = false
    func body(content: Content) -> some View {
        content
            .scaleEffect(on ? 1.08 : 0.94)
            .opacity(on ? 1 : 0.6)
            .onAppear {
                withAnimation(.easeInOut(duration: Motion.reduced ? 1.4 : 0.7).repeatForever(autoreverses: true)) { on = true }
            }
    }
}
