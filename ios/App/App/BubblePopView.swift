import SwiftUI
import Combine

// ─────────────────────────────────────────────
// MARK: - Bubble Pop (ages 6 months+)
// ─────────────────────────────────────────────
//
// Pure cause-and-effect: bubbles carrying pictures float up slowly.
// Any touch does something delightful — popping a bubble says the word,
// touching empty water makes a little splash of sparkles. There is no way
// to fail, no timer and no score pressure.

private struct Bubble: Identifiable {
    let id = UUID()
    let word: WordItem
    let born: Date
    let x0: CGFloat          // 0…1 of width
    let diameter: CGFloat
    let speed: CGFloat       // points per second
    let swayAmp: CGFloat
    let swayFreq: Double
    let phase: Double
    let tint: Color
}

private struct Burst: Identifiable {
    let id = UUID()
    let at: CGPoint
    let born: Date
    let emoji: String?
    let tint: Color
    let big: Bool
}

private struct Banner: Identifiable, Equatable {
    let id = UUID()
    let word: WordItem
    static func == (a: Banner, b: Banner) -> Bool { a.id == b.id }
}

struct BubblePopView: View {
    let words: [WordItem]
    @ObservedObject var stickerStore: StickerStore
    let onBack: () -> Void

    @State private var bubbles: [Bubble] = []
    @State private var bursts: [Burst] = []
    @State private var banner: Banner?
    @State private var lastSpawn = Date.distantPast
    @State private var pops = 0
    @State private var showCelebration = false
    @State private var area: CGSize = .zero
    @State private var recentWords: [String] = []

    private let popsPerSticker = 12
    private let tints: [Color] = [Color(hex: "#81D4FA"), Color(hex: "#F48FB1"), Color(hex: "#CE93D8"),
                                  Color(hex: "#A5D6A7"), Color(hex: "#FFE082")]
    private let ticker = Timer.publish(every: 0.25, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geo in
            let u = layoutUnit(geo.size)
            ZStack {
                LinearGradient(colors: [Color(hex: "#E1F5FE"), Color(hex: "#B3E5FC"), Color(hex: "#E1BEE7")],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                TimelineView(.animation) { tl in
                    let now = tl.date
                    ZStack {
                        ForEach(bubbles) { b in
                            ZStack {
                                SoapBubble(tint: b.tint)
                                Text(b.word.emoji)
                                    .font(.system(size: b.diameter * 0.5))
                                    .rotationEffect(.degrees(sin(now.timeIntervalSince(b.born) * 1.3 + b.phase) * 8))
                            }
                            .frame(width: b.diameter, height: b.diameter)
                            .position(position(of: b, at: now))
                        }
                        ForEach(bursts) { burst in
                            BurstView(burst: burst, now: now, unit: u)
                        }
                    }
                }
                .allowsHitTesting(false)
                .accessibilityHidden(true)

                TouchCatcher { point in handleTouch(at: point, unit: u) }
                    .ignoresSafeArea()
                    .accessibilityLabel(L10n.t("Bubbles. Touch a bubble to pop it.", "בועות. געו בבועה כדי לפוצץ אותה."))
                    .accessibilityAddTraits(.allowsDirectInteraction)

                // Word banner
                VStack {
                    Spacer()
                    if let banner {
                        HStack(spacing: 14 * u) {
                            Text(banner.word.emoji).font(.system(size: 54 * u))
                            Text(banner.word.label)
                                .font(.system(size: 46 * u, weight: .black, design: .rounded))
                                .foregroundColor(Palette.ink)
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                        }
                        .padding(.horizontal, 28 * u)
                        .padding(.vertical, 12 * u)
                        .background(Capsule().fill(Color.white.opacity(0.92)))
                        .shadow(color: Color(hex: "#0277BD").opacity(0.25), radius: 14, y: 6)
                        .id(banner.id)
                        .transition(.scale(scale: 0.4).combined(with: .opacity))
                    }
                }
                .padding(.bottom, max(geo.safeAreaInsets.bottom, 16) + 24)
                .allowsHitTesting(false)
                .animation(.spring(response: 0.35, dampingFraction: 0.6), value: banner)

                // Sticker progress (little bubbles filling up)
                VStack {
                    HStack(alignment: .top) {
                        progressMeter(u: u)
                        Spacer()
                        HoldToExitButton(tint: Color(hex: "#0288D1"), onExit: onBack)
                    }
                    Spacer()
                }
                .padding(.top, max(geo.safeAreaInsets.top, 12) + 8)
                .padding(.horizontal, 20)

                if showCelebration {
                    CelebrationView(stickerPool: words.map(\.emoji) + ["🫧", "🐳", "🐠"],
                                    stickerStore: stickerStore,
                                    autoDismissAfter: 4.5,
                                    onDone: { withAnimation { showCelebration = false } })
                        .transition(.opacity)
                        .zIndex(10)
                }
            }
            .ignoresSafeArea()
            .onAppear {
                area = geo.size
                seed()
            }
            .onChange(of: geo.size) { area = $0 }
        }
        .onReceive(ticker) { _ in tick() }
    }

    private func progressMeter(u: CGFloat) -> some View {
        let filled = pops % popsPerSticker
        return HStack(spacing: 4) {
            ForEach(0..<popsPerSticker, id: \.self) { i in
                Circle()
                    .fill(i < filled ? Color.white : Color.white.opacity(0.35))
                    .overlay(Circle().stroke(Color(hex: "#4FC3F7"), lineWidth: 1.5))
                    .frame(width: 11 * u, height: 11 * u)
                    .scaleEffect(i == filled - 1 ? 1.25 : 1)
            }
            Text("🏆").font(.system(size: 18 * u)).padding(.leading, 2)
        }
        .padding(.horizontal, 10).padding(.vertical, 8)
        .background(Capsule().fill(Color.white.opacity(0.4)))
        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: pops)
        .accessibilityHidden(true)
    }

    // MARK: Simulation

    private func position(of b: Bubble, at date: Date) -> CGPoint {
        let t = date.timeIntervalSince(b.born)
        let y = area.height + b.diameter / 2 - CGFloat(t) * b.speed
        let x = b.x0 * area.width + CGFloat(sin(t * b.swayFreq + b.phase)) * b.swayAmp
        return CGPoint(x: x, y: y)
    }

    private var maxBubbles: Int { area.width > 700 ? 8 : 5 }

    private func seed() {
        guard bubbles.isEmpty else { return }
        // Start with bubbles already on screen so there's something to touch immediately.
        for i in 0..<3 {
            spawn(ageOffset: Double(i) * 2.6 + 1.5)
        }
    }

    private func spawn(ageOffset: Double = 0) {
        guard area.width > 0, let word = nextWord() else { return }
        let u = layoutUnit(area)
        let d = CGFloat.random(in: 118...150) * u
        let margin = d / 2 / max(area.width, 1) + 0.03
        // Spread bubbles horizontally so they don't overlap at birth.
        var x = CGFloat.random(in: margin...(1 - margin))
        for _ in 0..<6 {
            let clash = bubbles.contains { abs($0.x0 - x) < 0.22 && Date().timeIntervalSince($0.born) < 2.2 }
            if !clash { break }
            x = CGFloat.random(in: margin...(1 - margin))
        }
        let b = Bubble(word: word,
                       born: Date().addingTimeInterval(-ageOffset),
                       x0: x,
                       diameter: d,
                       speed: CGFloat.random(in: 55...80) * u,
                       swayAmp: CGFloat.random(in: 12...26) * u,
                       swayFreq: Double.random(in: 0.6...1.1),
                       phase: Double.random(in: 0...6.28),
                       tint: tints.randomElement()!)
        bubbles.append(b)
        lastSpawn = Date()
    }

    /// Avoid repeating the same picture back-to-back.
    private func nextWord() -> WordItem? {
        let onScreen = Set(bubbles.map(\.word.id))
        let pool = words.filter { !onScreen.contains($0.id) && !recentWords.contains($0.id) }
        let word = (pool.isEmpty ? words : pool).randomElement()
        if let word {
            recentWords.append(word.id)
            if recentWords.count > 4 { recentWords.removeFirst() }
        }
        return word
    }

    private func tick() {
        guard !showCelebration else { return }
        let now = Date()
        bubbles.removeAll { position(of: $0, at: now).y < -$0.diameter }
        bursts.removeAll { now.timeIntervalSince($0.born) > 1.0 }
        let interval = bubbles.count < 2 ? 0.6 : 1.4
        if bubbles.count < maxBubbles && now.timeIntervalSince(lastSpawn) > interval {
            spawn()
        }
    }

    private func handleTouch(at point: CGPoint, unit u: CGFloat) {
        guard !showCelebration else { return }
        let now = Date()
        // Generous hit area: little fingers land near, not on.
        let hit = bubbles
            .map { ($0, position(of: $0, at: now)) }
            .filter { hypot($0.1.x - point.x, $0.1.y - point.y) < $0.0.diameter * 0.62 }
            .min { hypot($0.1.x - point.x, $0.1.y - point.y) < hypot($1.1.x - point.x, $1.1.y - point.y) }

        if let hit {
            let bubble = hit.0, pos = hit.1
            bubbles.removeAll { $0.id == bubble.id }
            bursts.append(Burst(at: pos, born: now, emoji: bubble.word.emoji, tint: bubble.tint, big: true))
            AudioManager.shared.play(.pop, volume: 0.8)
            Haptics.pop()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                AudioManager.shared.play(bubble.word.id)
            }
            stickerStore.markHeard(bubble.word.id)
            let b = Banner(word: bubble.word)
            banner = b
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                if banner == b { banner = nil }
            }
            pops += 1
            if pops % popsPerSticker == 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    withAnimation { showCelebration = true }
                }
            }
            if bubbles.count < 2 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { spawn() }
            }
        } else {
            // Even "missing" is rewarded with a tiny splash.
            bursts.append(Burst(at: point, born: now, emoji: nil, tint: tints.randomElement()!, big: false))
            AudioManager.shared.play(.tap, volume: 0.25)
            if bursts.count > 24 { bursts.removeFirst(bursts.count - 24) }
        }
    }
}

private struct BurstView: View {
    let burst: Burst
    let now: Date
    let unit: CGFloat

    var body: some View {
        let t = now.timeIntervalSince(burst.born)
        let p = min(1, t / (burst.big ? 0.7 : 0.5))
        let ease = 1 - pow(1 - p, 3)
        let radius = (burst.big ? 95 : 42) * unit * ease
        let count = burst.big ? 10 : 6
        ZStack {
            Circle()
                .stroke(burst.tint.opacity(0.8 * (1 - p)), lineWidth: (burst.big ? 6 : 3) * (1 - p) + 0.5)
                .frame(width: radius * 1.6, height: radius * 1.6)
            ForEach(0..<count, id: \.self) { i in
                let a = Double(i) / Double(count) * 2 * .pi + Double(burst.id.hashValue % 10) * 0.1
                Circle()
                    .fill(i % 2 == 0 ? Color.white : burst.tint)
                    .frame(width: (burst.big ? 14 : 8) * unit * (1 - p * 0.7),
                           height: (burst.big ? 14 : 8) * unit * (1 - p * 0.7))
                    .offset(x: cos(a) * radius, y: sin(a) * radius)
            }
            if let e = burst.emoji {
                Text(e)
                    .font(.system(size: 70 * unit))
                    .scaleEffect(1 + ease * 0.7)
                    .opacity(1 - p)
            }
        }
        .opacity(p >= 1 ? 0 : 1)
        .position(burst.at)
    }
}
