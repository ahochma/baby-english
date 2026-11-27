import SwiftUI

// ─────────────────────────────────────────────
// MARK: - Peekaboo (hide and seek)
// ─────────────────────────────────────────────
//
// Friends hide behind colourful doors and Pip asks "Where is the cat?".
// The child opens doors: the right friend pops out with "Peekaboo! You
// found it!"; any other friend waves and says its own name (so every tap
// teaches a word) before the door closes again. Two doors to start, up to
// four as the child succeeds; after two misses the right door wiggles.

struct PeekabooView: View {
    let words: [WordItem]
    @ObservedObject var stickerStore: StickerStore
    let onBack: () -> Void

    @State private var doorCount = 2
    @State private var hiders: [WordItem] = []
    @State private var target: WordItem?
    @State private var open: Set<Int> = []
    @State private var found = false
    @State private var misses = 0
    @State private var firstTryStreak = 0
    @State private var roundsWon = 0
    @State private var recent: [String] = []
    @State private var showCelebration = false
    @State private var listening = false
    @State private var roundID = UUID()
    @State private var idleWork: DispatchWorkItem?
    /// Off once the game closes, so delayed callbacks can't keep talking.
    @State private var live = LiveFlag()

    private let roundsPerSticker = 5
    private static let doorColors: [(Color, Color)] = [
        (Color(hex: "#EF5350"), Color(hex: "#C62828")),
        (Color(hex: "#42A5F5"), Color(hex: "#1565C0")),
        (Color(hex: "#FFCA28"), Color(hex: "#F9A825")),
        (Color(hex: "#66BB6A"), Color(hex: "#2E7D32")),
    ]

    var body: some View {
        GeometryReader { geo in
            let u = layoutUnit(geo.size)
            let w = geo.size.width, h = geo.size.height
            let top = max(geo.safeAreaInsets.top, 12) + 8
            let houseW = min(w - 32 * u, 1000)
            let gap = 14 * u
            let doorW = min((houseW - 40 * u - gap * CGFloat(hiders.count - 1)) / CGFloat(max(hiders.count, 1)), h * 0.26)
            let doorH = doorW * 1.45
            let doorsY = h * 0.66

            ZStack {
                Scenery(hillHeight: 0.14)
                    .ignoresSafeArea()

                // the house front the doors are set into
                VStack(spacing: 0) {
                    RoofShape()
                        .fill(Color(hex: "#E57373"))
                        .overlay(RoofShape().stroke(Color(hex: "#C62828"), lineWidth: 5 * u))
                        .frame(width: houseW + 14 * u, height: 70 * u)
                    RoundedRectangle(cornerRadius: 22 * u, style: .continuous)
                        .fill(Color(hex: "#FFF3E0"))
                        .overlay(RoundedRectangle(cornerRadius: 22 * u, style: .continuous)
                            .strokeBorder(Color(hex: "#FFCC80"), lineWidth: 5 * u))
                        .frame(width: houseW, height: doorH + 60 * u)
                }
                .position(x: w / 2, y: doorsY - 35 * u + 0)

                // top bar
                HStack(alignment: .center) {
                    StarRow(won: roundsWon, total: roundsPerSticker, unit: u)
                    Spacer()
                    HoldToExitButton(tint: Color(hex: "#1E88E5"), onExit: onBack)
                }
                .padding(.horizontal, 20 * u)
                .frame(maxWidth: 1000)
                .position(x: w / 2, y: top + 26 * u)

                // Pip asks; tap to hear again
                HStack(spacing: 10 * u) {
                    Mascot(mood: found ? .cheer : .idle)
                        .frame(width: 80 * u, height: 80 * u)
                    BabyPressable(action: sayTarget) {
                        HStack(spacing: 12 * u) {
                            Image(systemName: "speaker.wave.2.fill")
                                .font(.system(size: 28 * u, weight: .bold))
                                .scaleEffect(listening ? 1.15 : 1)
                            Text(found ? (target?.label ?? "") : "?")
                                .font(.system(size: 32 * u, weight: .black, design: .rounded))
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 28 * u)
                        .padding(.vertical, 13 * u)
                        .background(Capsule().fill(LinearGradient(colors: [Color(hex: "#64B5F6"), Color(hex: "#1E88E5")],
                                                                 startPoint: .top, endPoint: .bottom)))
                        .shadow(color: Color(hex: "#1E88E5").opacity(0.4), radius: listening ? 14 : 7, y: 5)
                        .animation(.easeInOut(duration: 0.3), value: listening)
                    }
                    .accessibilityLabel(L10n.t("Hear the word again", "שמעו שוב את המילה"))
                }
                .position(x: w / 2, y: top + 26 * u + 90 * u)

                // the doors
                HStack(alignment: .bottom, spacing: gap) {
                    ForEach(Array(hiders.enumerated()), id: \.offset) { i, friend in
                        let colors = Self.doorColors[i % Self.doorColors.count]
                        DoorView(friend: friend,
                                 isOpen: open.contains(i),
                                 isFound: found && friend.id == target?.id,
                                 hint: misses >= 2 && !found && friend.id == target?.id,
                                 color: colors.0, trim: colors.1, unit: u)
                            .frame(width: doorW, height: doorH)
                            .onTapGesture { knock(i) }
                            .accessibilityElement()
                            .accessibilityLabel(open.contains(i) ? friend.label : L10n.t("Door \(i + 1)", "דלת \(i + 1)"))
                            .accessibilityAddTraits(.isButton)
                    }
                }
                .id(roundID)
                .transition(.scale(scale: 0.85).combined(with: .opacity))
                .position(x: w / 2, y: doorsY + 18 * u)

                if found && !Motion.reduced {
                    ConfettiView(emojis: ["⭐", "🌟", "✨"], count: 18)
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                }

                if showCelebration {
                    CelebrationView(stickerPool: words.map(\.emoji) + ["🚪", "🙈"],
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

        // Other friends with different names and pictures ("Orange" the fruit vs the colour).
        var picks = [t]
        for w in words.shuffled() where picks.count < min(doorCount, words.count) {
            if !picks.contains(where: { $0.label == w.label || $0.emoji == w.emoji }) { picks.append(w) }
        }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
            target = t
            hiders = picks.shuffled()
            open = []
            found = false
            misses = 0
            roundID = UUID()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { sayTarget() }
    }

    private func sayTarget() {
        guard live.on, let target, !found else { return }
        if DemoMode.isOn {
            let round = roundID
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                if round == roundID, let i = hiders.firstIndex(where: { $0.id == self.target?.id }) { knock(i) }
            }
        }
        let length = AudioManager.shared.say(Voice.whereIs(target))
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
                  round == roundID, !found, !showCelebration else { return }
            sayTarget()
        }
        idleWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }

    private func knock(_ i: Int) {
        guard live.on, !found, !showCelebration, let target, i < hiders.count, !open.contains(i) else { return }
        let friend = hiders[i]
        withAnimation(.spring(response: 0.45, dampingFraction: 0.62)) { _ = open.insert(i) }

        if friend.id == target.id {
            idleWork?.cancel()
            stickerStore.recordCorrect(target.id, firstTry: misses == 0)
            stickerStore.markHeard(target.id)
            Haptics.success()
            AudioManager.shared.play(.chime, volume: 0.5)
            withAnimation(.spring(response: 0.4, dampingFraction: 0.55)) {
                found = true
                roundsWon += 1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                guard live.on else { return }
                AudioManager.shared.say(["peekaboo"] + Voice.word(target), gap: 0.3)
            }
            if misses == 0 {
                firstTryStreak += 1
                if firstTryStreak >= 3 && doorCount < 4 { doorCount += 1; firstTryStreak = 0 }
            } else {
                firstTryStreak = 0
                if misses >= 2 && doorCount > 2 { doorCount -= 1 }
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
            AudioManager.shared.play(.pop, volume: 0.4)
            // The friend behind the door says its own name, then hides again.
            let length = AudioManager.shared.say(Voice.word(friend))
            stickerStore.markHeard(friend.id)
            let round = roundID
            DispatchQueue.main.asyncAfter(deadline: .now() + max(1.6, length + 0.5)) {
                guard live.on, round == roundID, !found else { return }
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { _ = open.remove(i) }
            }
            scheduleIdleRepeat(after: max(2.2, length + 1))
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - Door
// ─────────────────────────────────────────────

private struct DoorView: View {
    let friend: WordItem
    let isOpen: Bool
    let isFound: Bool
    let hint: Bool
    let color: Color
    let trim: Color
    let unit: CGFloat
    @State private var wiggle = false

    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack(alignment: .bottom) {
                // the doorway: dark inside, the friend waits there
                ArchShape()
                    .fill(LinearGradient(colors: [Color(hex: "#5D4037"), Color(hex: "#3E2723")],
                                         startPoint: .top, endPoint: .bottom))
                WordArt(word: friend, mood: isFound ? .happy : .idle)
                    .frame(width: w * 0.82, height: w * 0.82)
                    .scaleEffect(isOpen ? (isFound ? 1.12 : 1) : 0.5)
                    .offset(y: isOpen ? -h * 0.12 : 0)
                    .opacity(isOpen ? 1 : 0)
                    .padding(.bottom, h * 0.06)

                // the door itself swings open on its hinges
                ZStack {
                    ArchShape().fill(LinearGradient(colors: [color, trim], startPoint: .top, endPoint: .bottom))
                    ArchShape().stroke(trim, lineWidth: 5 * unit)
                    VStack(spacing: h * 0.06) {
                        Circle()
                            .fill(Color(hex: "#E3F2FD"))
                            .overlay(Circle().stroke(trim, lineWidth: 4 * unit))
                            .frame(width: w * 0.34, height: w * 0.34)
                        RoundedRectangle(cornerRadius: 8 * unit)
                            .stroke(trim.opacity(0.7), lineWidth: 4 * unit)
                            .frame(width: w * 0.56, height: h * 0.3)
                    }
                    .offset(y: -h * 0.04)
                    Circle()
                        .fill(Color(hex: "#FFD54F"))
                        .overlay(Circle().stroke(Color(hex: "#F9A825"), lineWidth: 2 * unit))
                        .frame(width: w * 0.12, height: w * 0.12)
                        .offset(x: w * 0.3, y: h * 0.06)
                }
                .rotation3DEffect(.degrees(isOpen ? -108 : (hint && wiggle ? -14 : 0)),
                                  axis: (x: 0, y: 1, z: 0), anchor: .leading, perspective: 0.45)
                .shadow(color: .black.opacity(isOpen ? 0.25 : 0.12), radius: 6, x: isOpen ? -4 : 0, y: 4)
            }
            .frame(width: w, height: h)
        }
        .contentShape(Rectangle())
        .onChange(of: hint) { on in
            if on {
                withAnimation(.easeInOut(duration: Motion.reduced ? 0.9 : 0.45).repeatForever(autoreverses: true)) { wiggle = true }
            } else {
                wiggle = false
            }
        }
    }
}

/// A door shape: straight sides with a round top.
private struct ArchShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let radius = r.width / 2
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.minY + radius))
        p.addArc(center: CGPoint(x: r.midX, y: r.minY + radius), radius: radius,
                 startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

private struct RoofShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.midX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}
