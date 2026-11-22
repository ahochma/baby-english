import SwiftUI
import UIKit

// ─────────────────────────────────────────────
// MARK: - Localization (parent-facing text only)
// ─────────────────────────────────────────────

/// Children see pictures and hear English words; only grown-up screens
/// (gate, paywall, parent zone) are translated. Hebrew is the launch market.
enum L10n {
    static let isHebrew: Bool = {
        (Locale.preferredLanguages.first ?? "en").lowercased().hasPrefix("he")
    }()
    static var direction: LayoutDirection { isHebrew ? .rightToLeft : .leftToRight }
    static func t(_ en: String, _ he: String) -> String { isHebrew ? he : en }
}

// ─────────────────────────────────────────────
// MARK: - Demo mode (DEBUG only: store screenshots & preview video)
// ─────────────────────────────────────────────

/// `-startScreen bubbles|findit|stickers|cards` opens a screen directly and
/// `-demoMode` lets the games play themselves. Compiled out of Release builds.
enum DemoMode {
    #if DEBUG
    static let args = ProcessInfo.processInfo.arguments
    static let isOn = args.contains("-demoMode")
    static var startScreen: String? {
        guard let i = args.firstIndex(of: "-startScreen"), i + 1 < args.count else { return nil }
        return args[i + 1]
    }
    #else
    static let isOn = false
    static let startScreen: String? = nil
    #endif
}

// ─────────────────────────────────────────────
// MARK: - Colors
// ─────────────────────────────────────────────

extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

enum Palette {
    static let ink = Color(hex: "#1A237E")
    static let cream = Color(hex: "#FFF8E1")
    static let sun = Color(hex: "#FFB300")
    static let sunDeep = Color(hex: "#FF8F00")
    static let parentInk = Color(hex: "#263238")
    static let parentBG = Color(hex: "#F6F7FB")
    static let accent = Color(hex: "#5E5CE6")
}

// ─────────────────────────────────────────────
// MARK: - Accessibility helpers
// ─────────────────────────────────────────────

extension Font {
    /// Rounded font for grown-up screens that scales with the user's text size
    /// setting (Dynamic Type). Kid screens keep fixed, huge sizes on purpose.
    static func parent(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: UIFontMetrics.default.scaledValue(for: size), weight: weight, design: .rounded)
    }
}

/// Continuous decorative motion (bobbing, drifting clouds, spinning sun,
/// confetti) is switched off when the device asks for reduced motion or a
/// parent turns on Calm mode.
enum Motion {
    static var reduced: Bool { UIAccessibility.isReduceMotionEnabled || SettingsStore.shared.calmMode }
}

// ─────────────────────────────────────────────
// MARK: - Sizing
// ─────────────────────────────────────────────

/// One "unit" equals 1pt on a 390pt-wide iPhone; grows on iPad, shrinks on SE.
func layoutUnit(_ size: CGSize) -> CGFloat {
    let base = min(size.width, size.height) / 390
    return max(0.82, min(base, 2.0))
}

// ─────────────────────────────────────────────
// MARK: - Button styles
// ─────────────────────────────────────────────

struct SquishyButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.92
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .brightness(configuration.isPressed ? -0.03 : 0)
            .animation(.spring(response: 0.25, dampingFraction: 0.55), value: configuration.isPressed)
    }
}

/// Toddler-friendly button: fires on touch-down (babies don't "lift" reliably),
/// with a squish animation and a soft tap sound.
struct BabyPressable<Content: View>: View {
    let action: () -> Void
    @ViewBuilder let content: () -> Content
    @State private var pressed = false

    var body: some View {
        content()
            .scaleEffect(pressed ? 0.92 : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.5), value: pressed)
            .contentShape(Rectangle())
            .onTapGesture {
                pressed = true
                Haptics.tap()
                AudioManager.shared.play(.tap, volume: 0.35)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                    pressed = false
                    action()
                }
            }
            .accessibilityAddTraits(.isButton)
    }
}

// ─────────────────────────────────────────────
// MARK: - Multi-touch catcher
// ─────────────────────────────────────────────

/// SwiftUI tap gestures fail when a baby touches with a palm or several fingers.
/// This UIKit view reports *every* finger the instant it lands.
struct TouchCatcher: UIViewRepresentable {
    let onTouch: (CGPoint) -> Void

    func makeUIView(context: Context) -> TouchView {
        let v = TouchView()
        v.isMultipleTouchEnabled = true
        v.backgroundColor = .clear
        v.onTouch = onTouch
        return v
    }

    func updateUIView(_ uiView: TouchView, context: Context) {
        uiView.onTouch = onTouch
    }

    final class TouchView: UIView {
        var onTouch: ((CGPoint) -> Void)?
        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            for t in touches { onTouch?(t.location(in: self)) }
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - Hold-to-exit home button
// ─────────────────────────────────────────────

/// Children can't leave a game by accident: a grown-up holds the house for 1.5s.
struct HoldToExitButton: View {
    var tint: Color = .white
    var duration: Double = 1.5
    let onExit: () -> Void

    @State private var progress: CGFloat = 0
    @State private var holding = false
    @State private var showHint = false
    @State private var startedAt: Date?

    var body: some View {
        ZStack {
            Circle().fill(Color.white.opacity(0.55))
                .frame(width: 60, height: 60)
                .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(tint, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .frame(width: 52, height: 52)
                .rotationEffect(.degrees(-90))
            Text("🏠").font(.system(size: 28))
        }
        .overlay(alignment: .bottom) {
            if showHint {
                Text(L10n.t("Hold to exit", "החזיקו ליציאה"))
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Capsule().fill(Color.black.opacity(0.45)))
                    .fixedSize()
                    .offset(y: 28)
                    .transition(.opacity)
            }
        }
        .contentShape(Circle().inset(by: -10))
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard !holding else { return }
                    holding = true
                    startedAt = Date()
                    withAnimation(.linear(duration: duration)) { progress = 1 }
                    let started = startedAt
                    DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                        guard holding, startedAt == started else { return }
                        holding = false
                        Haptics.success()
                        onExit()
                    }
                }
                .onEnded { _ in
                    let quick = (startedAt.map { Date().timeIntervalSince($0) } ?? 0) < duration
                    holding = false
                    startedAt = nil
                    withAnimation(.easeOut(duration: 0.2)) { progress = 0 }
                    if quick {
                        withAnimation { showHint = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                            withAnimation { showHint = false }
                        }
                    }
                }
        )
        .accessibilityLabel(L10n.t("Home", "בית"))
        .accessibilityHint(L10n.t("Hold to go back to the home screen", "החזיקו כדי לחזור למסך הבית"))
        .accessibilityAction { onExit() }
    }
}

// ─────────────────────────────────────────────
// MARK: - Confetti
// ─────────────────────────────────────────────

struct ConfettiPiece: Identifiable {
    let id = UUID()
    let emoji: String
    let startX: CGFloat      // 0…1 of width
    let drift: CGFloat       // pts
    let size: CGFloat
    let spin: Double
    let delay: Double
    let fall: Double         // seconds
}

/// Time-driven confetti so dozens of pieces stay smooth.
struct ConfettiView: View {
    var emojis: [String] = ["⭐", "🌟", "✨", "🎈", "🎊", "💖"]
    var count: Int = 36
    @State private var pieces: [ConfettiPiece] = []
    @State private var start = Date()

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation) { timeline in
                let t = timeline.date.timeIntervalSince(start)
                ZStack {
                    ForEach(pieces) { p in
                        let local = max(0, t - p.delay)
                        let progress = min(1, local / p.fall)
                        let y = -40 + (geo.size.height + 80) * progress
                        let x = p.startX * geo.size.width + sin(local * 2.2 + p.spin) * p.drift
                        Text(p.emoji)
                            .font(.system(size: p.size))
                            .rotationEffect(.degrees(p.spin * 40 + local * p.spin * 60))
                            .position(x: x, y: y)
                            .opacity(local > 0 && progress < 1 ? 1 : 0)
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            start = Date()
            pieces = (0..<count).map { _ in
                ConfettiPiece(emoji: emojis.randomElement() ?? "⭐",
                              startX: .random(in: 0.05...0.95),
                              drift: .random(in: 10...40),
                              size: .random(in: 22...44),
                              spin: .random(in: -3...3),
                              delay: .random(in: 0...0.9),
                              fall: .random(in: 2.2...3.6))
            }
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - Soap bubble
// ─────────────────────────────────────────────

struct SoapBubble: View {
    var tint: Color = .white
    var body: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [tint.opacity(0.05), tint.opacity(0.22), Color.white.opacity(0.55)],
                                     center: .center, startRadius: 0, endRadius: 60))
            Circle()
                .strokeBorder(LinearGradient(colors: [.white.opacity(0.95), Color(hex: "#B3E5FC").opacity(0.7), Color(hex: "#F8BBD0").opacity(0.8)],
                                             startPoint: .topLeading, endPoint: .bottomTrailing),
                              lineWidth: 3)
            GeometryReader { g in
                Ellipse()
                    .fill(Color.white.opacity(0.85))
                    .frame(width: g.size.width * 0.22, height: g.size.height * 0.12)
                    .rotationEffect(.degrees(-35))
                    .position(x: g.size.width * 0.3, y: g.size.height * 0.24)
            }
        }
    }
}

/// Gentle floating decoration used behind the home screen.
struct FloatingBackdrop: View {
    let items: [String]
    @State private var start = Date()

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation(minimumInterval: 1 / 30)) { tl in
                let t = tl.date.timeIntervalSince(start)
                ZStack {
                    ForEach(Array(items.enumerated()), id: \.offset) { i, e in
                        let fx = Double(i) * 0.37 + 0.1
                        let x = (fx.truncatingRemainder(dividingBy: 1)) * geo.size.width
                        let y = (Double(i) * 0.23 + 0.05).truncatingRemainder(dividingBy: 1) * geo.size.height
                        Text(e)
                            .font(.system(size: 34))
                            .opacity(0.13)
                            .position(x: x + sin(t * 0.4 + Double(i)) * 14,
                                      y: y + cos(t * 0.35 + Double(i) * 1.3) * 18)
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// ─────────────────────────────────────────────
// MARK: - Chunky toy button
// ─────────────────────────────────────────────

/// A thick, rounded "toy block" surface with a darker lip underneath.
/// Pressing it pushes the face down onto the lip, like a real button,
/// which children 3–6 understand instantly.
struct ChunkyButton<Label: View>: View {
    var colors: [Color]
    var lip: Color
    var radius: CGFloat = 30
    var depth: CGFloat = 7
    let action: () -> Void
    @ViewBuilder let label: () -> Label

    @State private var pressed = false

    var body: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(lip)
                .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).fill(Color.black.opacity(0.18)))
                .offset(y: depth)
                .shadow(color: lip.opacity(0.35), radius: 10, y: depth + 4)
            ZStack {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom))
                // glossy sheen across the top third
                GeometryReader { g in
                    Capsule()
                        .fill(LinearGradient(colors: [.white.opacity(0.45), .white.opacity(0.0)],
                                             startPoint: .top, endPoint: .bottom))
                        .frame(width: g.size.width * 0.82, height: max(10, g.size.height * 0.28))
                        .position(x: g.size.width / 2, y: max(10, g.size.height * 0.28) / 2 + 6)
                }
                .allowsHitTesting(false)
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.35), lineWidth: 2)
                label()
            }
            .offset(y: pressed ? depth : 0)
        }
        .padding(.bottom, depth)
        .animation(.spring(response: 0.18, dampingFraction: 0.6), value: pressed)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !pressed {
                        pressed = true
                        Haptics.tap()
                        AudioManager.shared.play(.tap, volume: 0.35)
                    }
                }
                .onEnded { v in
                    pressed = false
                    // A wandering finger that slides far away cancels the press.
                    if abs(v.translation.width) < 60 && abs(v.translation.height) < 60 {
                        action()
                    }
                }
        )
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { action() }
    }
}

/// White circle "porthole" that makes an emoji look like a sticker character.
struct CharacterBadge: View {
    let emoji: String
    var ring: Color = .white
    @State private var bob = false

    var body: some View {
        GeometryReader { g in
            let d = min(g.size.width, g.size.height)
            ZStack {
                Circle()
                    .fill(RadialGradient(colors: [.white, Color(hex: "#F3F6FF")], center: .topLeading,
                                         startRadius: 0, endRadius: d))
                    .shadow(color: .black.opacity(0.12), radius: d * 0.05, y: d * 0.04)
                Circle().strokeBorder(ring.opacity(0.9), lineWidth: max(3, d * 0.045))
                Text(emoji)
                    .font(.system(size: d * 0.56))
                    .scaleEffect(x: bob ? 1.04 : 0.97, y: bob ? 0.97 : 1.04, anchor: .bottom)
                    .offset(y: bob ? 0 : -d * 0.02)
            }
            .frame(width: d, height: d)
            .position(x: g.size.width / 2, y: g.size.height / 2)
        }
        .onAppear {
            guard !Motion.reduced else { return }
            withAnimation(.easeInOut(duration: Double.random(in: 1.1...1.6)).repeatForever(autoreverses: true)) { bob = true }
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - Scenery: sky, sun, clouds, rolling hills
// ─────────────────────────────────────────────

struct Scenery: View {
    var skyTop = Color(hex: "#7FD3FF")
    var skyBottom = Color(hex: "#D8F3FF")
    var hillBack = Color(hex: "#A6E36B")
    var hillFront = Color(hex: "#73CC4A")
    var hillHeight: CGFloat = 0.2
    var showSun = true

    @State private var start = Date()

    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack {
                LinearGradient(colors: [skyTop, skyBottom], startPoint: .top, endPoint: .bottom)

                if showSun {
                    SunView()
                        .frame(width: min(w, h) * 0.26, height: min(w, h) * 0.26)
                        .position(x: w * 0.9, y: h * 0.035)
                }

                TimelineView(.animation(minimumInterval: 1 / 30, paused: Motion.reduced)) { tl in
                    let t = Motion.reduced ? 0 : tl.date.timeIntervalSince(start)
                    ZStack {
                        cloud(t: t, speed: 9, y: 0.16, scale: 1.0, phase: 0.1, w: w, h: h)
                        cloud(t: t, speed: 6, y: 0.30, scale: 0.7, phase: 0.55, w: w, h: h)
                        cloud(t: t, speed: 12, y: 0.08, scale: 0.55, phase: 0.8, w: w, h: h)
                    }
                }

                HillShape(base: 1 - hillHeight * 1.05, bump: 0.06, phase: 0.2)
                    .fill(hillBack)
                HillShape(base: 1 - hillHeight * 0.7, bump: 0.05, phase: 0.75)
                    .fill(hillFront)
                // tiny flowers on the front hill
                ForEach(0..<7, id: \.self) { i in
                    Flower(color: [Color(hex: "#FF6B8B"), Color(hex: "#FFD93D"), .white][i % 3])
                        .frame(width: 14, height: 14)
                        .position(x: w * (0.08 + Double(i) * 0.14), y: h * (1 - hillHeight * 0.45) + CGFloat(i % 2) * 14)
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func cloud(t: Double, speed: Double, y: CGFloat, scale: CGFloat, phase: CGFloat, w: CGFloat, h: CGFloat) -> some View {
        let cw = 150 * scale
        let span = w + cw * 2
        let x = (phase * span + CGFloat(t * speed)).truncatingRemainder(dividingBy: span) - cw
        return CloudShape()
            .fill(Color.white)
            .frame(width: cw, height: cw * 0.5)
            .shadow(color: Color(hex: "#5BB8E8").opacity(0.15), radius: 6, y: 4)
            .position(x: x, y: h * y)
    }
}

struct SunView: View {
    @State private var spin = false
    var body: some View {
        GeometryReader { g in
            let d = min(g.size.width, g.size.height)
            ZStack {
                ForEach(0..<10, id: \.self) { i in
                    Capsule()
                        .fill(Color(hex: "#FFD93D").opacity(0.7))
                        .frame(width: d * 0.08, height: d * 0.2)
                        .offset(y: -d * 0.42)
                        .rotationEffect(.degrees(Double(i) * 36))
                }
                .rotationEffect(.degrees(spin ? 360 : 0))
                Circle()
                    .fill(RadialGradient(colors: [Color(hex: "#FFF07A"), Color(hex: "#FFC93C")],
                                         center: .topLeading, startRadius: 0, endRadius: d * 0.5))
                    .frame(width: d * 0.56, height: d * 0.56)
                    .shadow(color: Color(hex: "#FFC93C").opacity(0.6), radius: d * 0.1)
            }
            .frame(width: d, height: d)
        }
        .onAppear {
            guard !Motion.reduced else { return }
            withAnimation(.linear(duration: 40).repeatForever(autoreverses: false)) { spin = true }
        }
    }
}

struct CloudShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let w = r.width, h = r.height
        p.addEllipse(in: CGRect(x: r.minX, y: r.minY + h * 0.35, width: w * 0.42, height: h * 0.6))
        p.addEllipse(in: CGRect(x: r.minX + w * 0.2, y: r.minY, width: w * 0.45, height: h * 0.85))
        p.addEllipse(in: CGRect(x: r.minX + w * 0.48, y: r.minY + h * 0.18, width: w * 0.4, height: h * 0.72))
        p.addRoundedRect(in: CGRect(x: r.minX + w * 0.1, y: r.minY + h * 0.55, width: w * 0.8, height: h * 0.45),
                         cornerSize: CGSize(width: h * 0.22, height: h * 0.22))
        return p
    }
}

struct HillShape: Shape {
    var base: CGFloat   // 0…1 of height where the hill line sits
    var bump: CGFloat   // amplitude as fraction of height
    var phase: CGFloat

    func path(in r: CGRect) -> Path {
        var p = Path()
        let y0 = r.height * base
        p.move(to: CGPoint(x: 0, y: y0))
        p.addCurve(to: CGPoint(x: r.width, y: y0 + r.height * bump * 0.3),
                   control1: CGPoint(x: r.width * phase, y: y0 - r.height * bump * 1.6),
                   control2: CGPoint(x: r.width * (phase + 0.4), y: y0 + r.height * bump * 1.2))
        p.addLine(to: CGPoint(x: r.width, y: r.height))
        p.addLine(to: CGPoint(x: 0, y: r.height))
        p.closeSubpath()
        return p
    }
}

struct Flower: View {
    let color: Color
    var body: some View {
        ZStack {
            ForEach(0..<5, id: \.self) { i in
                Circle().fill(color)
                    .frame(width: 6, height: 6)
                    .offset(y: -4)
                    .rotationEffect(.degrees(Double(i) * 72))
            }
            Circle().fill(Color(hex: "#FFB627")).frame(width: 5, height: 5)
        }
    }
}
