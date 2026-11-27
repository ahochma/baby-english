import SwiftUI

// ─────────────────────────────────────────────
// MARK: - Balloons
// ─────────────────────────────────────────────
//
// Coloured balloons float up from behind the hills and Pip asks "Pop the
// blue balloon!". The right one bursts with a pop and "Blue!"; a wrong one
// wobbles and says its own colour, so every tap teaches. Three balloons to
// start, up to five as the child succeeds; after two misses the right one
// glows. Balloons keep drifting up and come round again, so nothing is lost.

struct BalloonsView: View {
    static let colorIDs: Set<String> = Set(ALL_CATEGORIES.first { $0.id == "colors" }?.words.map(\.id) ?? [])

    let colors: [WordItem]
    @ObservedObject var stickerStore: StickerStore
    let onBack: () -> Void

    private struct Balloon: Identifiable {
        let word: WordItem
        let lane: Int
        let duration: Double   // seconds to float from the bottom to past the top
        let offset: Double     // 0…1, where in its journey it starts
        var id: String { word.id }
    }

    @State private var balloons: [Balloon] = []
    @State private var target: WordItem?
    @State private var count = 3
    @State private var firstTryStreak = 0
    @State private var misses = 0
    @State private var popped: String?
    @State private var popAt = Date()
    @State private var shakes: [String: Int] = [:]
    @State private var roundStart = Date()
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
            let size = min(w / CGFloat(max(balloons.count, 1)) * 0.82, h * 0.2, 170 * u)

            ZStack {
                Scenery(hillHeight: 0.16)
                    .ignoresSafeArea()

                TimelineView(.animation(paused: showCelebration)) { tl in
                    let t = tl.date.timeIntervalSince(roundStart)
                    ZStack {
                        ForEach(balloons) { b in
                            let laneW = w / CGFloat(balloons.count)
                            let phase = (t / b.duration + b.offset).truncatingRemainder(dividingBy: 1)
                            let travel = h + size * 2.6
                            let y = h + size * 1.3 - CGFloat(phase) * travel
                            let sway = Motion.reduced ? 0 : CGFloat(sin(t * 0.9 + Double(b.lane) * 1.7)) * 10 * u
                            let x = laneW * (CGFloat(b.lane) + 0.5) + sway
                            let isPopped = popped == b.id
                            let burst = isPopped ? min(1, tl.date.timeIntervalSince(popAt) / 0.25) : 0
                            BalloonView(color: b.word.bg, rim: b.word.textColor, size: size,
                                        hint: misses >= 2 && b.id == target?.id && popped == nil)
                                .modifier(ShakeEffect(shakes: CGFloat(shakes[b.id, default: 0])))
                                .scaleEffect(1 + burst * 0.6)
                                .opacity(1 - burst)
                                .position(x: x, y: y)
                                .onTapGesture { tap(b.word) }
                                .accessibilityElement()
                                .accessibilityLabel(L10n.t("\(b.word.label) balloon", "בלון \(b.word.label)"))
                                .accessibilityAddTraits(.isButton)
                        }
                    }
                }
                .id(roundID)

                if popped != nil && !Motion.reduced {
                    ConfettiView(emojis: ["✨", "⭐", "🎉"], count: 18)
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                }

                // top bar
                HStack(alignment: .center) {
                    StarRow(won: roundsWon, total: roundsPerSticker, unit: u)
                    Spacer()
                    HoldToExitButton(tint: Color(hex: "#EC407A"), onExit: onBack)
                }
                .padding(.horizontal, 20 * u)
                .frame(maxWidth: 1000)
                .position(x: w / 2, y: top + 26 * u)

                // Pip asks; tap to hear again
                HStack(spacing: 10 * u) {
                    Mascot(mood: popped != nil ? .cheer : .idle)
                        .frame(width: 76 * u, height: 76 * u)
                    BabyPressable(action: sayTarget) {
                        HStack(spacing: 12 * u) {
                            Image(systemName: "speaker.wave.2.fill")
                                .font(.system(size: 28 * u, weight: .bold))
                                .scaleEffect(listening ? 1.15 : 1)
                            Text(popped != nil ? (target?.label ?? "") : "?")
                                .font(.system(size: 32 * u, weight: .black, design: .rounded))
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 28 * u)
                        .padding(.vertical, 13 * u)
                        .background(Capsule().fill(LinearGradient(colors: [Color(hex: "#F48FB1"), Color(hex: "#EC407A")],
                                                                 startPoint: .top, endPoint: .bottom)))
                        .shadow(color: Color(hex: "#EC407A").opacity(0.4), radius: listening ? 14 : 7, y: 5)
                        .animation(.easeInOut(duration: 0.3), value: listening)
                    }
                    .accessibilityLabel(L10n.t("Hear the colour again", "שמעו שוב את הצבע"))
                }
                .position(x: w / 2, y: top + 26 * u + 86 * u)

                if showCelebration {
                    CelebrationView(stickerPool: ["🎈", "🎈", "🎉", "🌈"] + colors.map(\.emoji),
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
        guard live.on, colors.count >= 2 else { return }
        let fresh = colors.filter { !recent.contains($0.id) }
        let t = stickerStore.pickForPractice(from: fresh.isEmpty ? colors : fresh)!
        recent.append(t.id)
        if recent.count > 3 { recent.removeFirst() }

        var picks = [t]
        for c in colors.shuffled() where picks.count < min(count, colors.count) {
            if !picks.contains(where: { $0.id == c.id }) { picks.append(c) }
        }
        picks.shuffle()
        // Spread the balloons over the screen from the start, the target low enough to be seen soon.
        let slow = Motion.reduced ? 1.4 : 1.0
        let made = picks.enumerated().map { i, word in
            Balloon(word: word, lane: i,
                    duration: Double.random(in: 9...12) * slow,
                    offset: word.id == t.id ? 0.22 : Double(i) / Double(picks.count) * 0.7 + 0.1)
        }
        withAnimation(.easeOut(duration: 0.3)) {
            target = t
            balloons = made
            popped = nil
            misses = 0
            shakes = [:]
            roundStart = Date()
            roundID = UUID()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { sayTarget() }
    }

    private func sayTarget() {
        guard live.on, let target, popped == nil else { return }
        if DemoMode.isOn {
            let round = roundID
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                if round == roundID, let t = self.target { tap(t) }
            }
        }
        let length = AudioManager.shared.say(Voice.pop(target))
        listening = true
        DispatchQueue.main.asyncAfter(deadline: .now() + max(0.6, length)) { listening = false }
        scheduleIdleRepeat()
    }

    private func scheduleIdleRepeat(after delay: Double = 7) {
        idleWork?.cancel()
        guard live.on else { return }
        let round = roundID
        let work = DispatchWorkItem {
            guard live.on, AudioManager.shared.inForeground,
                  round == roundID, popped == nil, !showCelebration else { return }
            sayTarget()
        }
        idleWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }

    private func tap(_ word: WordItem) {
        guard live.on, popped == nil, !showCelebration, let target else { return }
        if word.id == target.id {
            idleWork?.cancel()
            stickerStore.recordCorrect(target.id, firstTry: misses == 0)
            stickerStore.markHeard(target.id)
            Haptics.pop()
            AudioManager.shared.play(.pop, volume: 0.8)
            popAt = Date()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.55)) {
                popped = word.id
                roundsWon += 1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                guard live.on else { return }
                AudioManager.shared.say(Voice.word(target) + [Voice.praise()], gap: 0.3)
            }
            if misses == 0 {
                firstTryStreak += 1
                if firstTryStreak >= 3 && count < 5 { count += 1; firstTryStreak = 0 }
            } else {
                firstTryStreak = 0
                if misses >= 2 && count > 3 { count -= 1 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
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
            AudioManager.shared.play(.boing, volume: 0.3)
            withAnimation(.linear(duration: 0.45)) { shakes[word.id, default: 0] += 1 }
            // The balloon says its own colour, then Pip asks again.
            let length = AudioManager.shared.say(Voice.word(word))
            stickerStore.markHeard(word.id)
            scheduleIdleRepeat(after: max(2.2, length + 1))
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - Balloon
// ─────────────────────────────────────────────

private struct BalloonView: View {
    let color: Color
    let rim: Color
    let size: CGFloat
    let hint: Bool

    var body: some View {
        ZStack {
            // string
            StringShape()
                .stroke(Color.white.opacity(0.85), style: StrokeStyle(lineWidth: max(1.5, size * 0.015), lineCap: .round))
                .frame(width: size * 0.2, height: size * 0.7)
                .offset(y: size * 0.92)
            if hint {
                Ellipse()
                    .fill(Color(hex: "#FFF59D").opacity(0.7))
                    .frame(width: size * 1.12, height: size * 1.3)
                    .modifier(Pulse())
            }
            // knot
            Triangle()
                .fill(rim)
                .frame(width: size * 0.14, height: size * 0.1)
                .offset(y: size * 0.58)
            // body
            Ellipse()
                .fill(RadialGradient(colors: [color.opacity(0.85), color], center: UnitPoint(x: 0.35, y: 0.3),
                                     startRadius: size * 0.05, endRadius: size * 0.7))
                .overlay(Ellipse().stroke(rim.opacity(0.55), lineWidth: max(2, size * 0.025)))
                .frame(width: size * 0.86, height: size)
            // shine
            Ellipse()
                .fill(Color.white.opacity(0.55))
                .frame(width: size * 0.16, height: size * 0.28)
                .rotationEffect(.degrees(25))
                .offset(x: -size * 0.2, y: -size * 0.2)
        }
        .frame(width: size, height: size * 1.8)
        .contentShape(Rectangle())   // the string counts too: bigger target for small fingers
    }
}

private struct Triangle: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.midX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

private struct StringShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.midX, y: r.minY))
        p.addCurve(to: CGPoint(x: r.midX, y: r.maxY),
                   control1: CGPoint(x: r.maxX, y: r.minY + r.height * 0.35),
                   control2: CGPoint(x: r.minX, y: r.minY + r.height * 0.65))
        return p
    }
}
