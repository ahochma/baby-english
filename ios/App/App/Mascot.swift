import SwiftUI

// ─────────────────────────────────────────────
// MARK: - Pip, the app's mascot (original character, drawn in code)
// ─────────────────────────────────────────────
//
// A round, sunny chick with big shiny eyes and rosy cheeks. Pip blinks,
// breathes, and reacts: happy eyes when the child succeeds, flapping wings
// when celebrating. Drawn with vector shapes so it stays crisp on every
// screen and costs nothing in app size.

enum MascotMood: Equatable {
    case idle, happy, cheer
}

struct Mascot: View {
    var mood: MascotMood = .idle

    @State private var blink = false
    @State private var breathe = false
    @State private var flap = false

    private let body1 = Color(hex: "#FFD93D")
    private let body2 = Color(hex: "#FFB627")
    private let belly = Color(hex: "#FFF1B3")
    private let wing = Color(hex: "#FFC21A")
    private let beak = Color(hex: "#FF8A3D")
    private let ink = Color(hex: "#3B2A1E")
    private let blush = Color(hex: "#FF8FA3")

    var body: some View {
        GeometryReader { g in
            let s = min(g.size.width, g.size.height) / 100
            ZStack {
                // ground shadow
                Ellipse()
                    .fill(Color.black.opacity(0.12))
                    .frame(width: (breathe ? 54 : 60) * s, height: 9 * s)
                    .offset(y: 46 * s)

                ZStack {
                    // feet
                    HStack(spacing: 14 * s) {
                        Capsule().fill(beak).frame(width: 14 * s, height: 7 * s)
                        Capsule().fill(beak).frame(width: 14 * s, height: 7 * s)
                    }
                    .offset(y: 40 * s)

                    // wings (behind body)
                    wingView(s: s, left: true)
                    wingView(s: s, left: false)

                    // tuft
                    ZStack {
                        Capsule().fill(body2).frame(width: 7 * s, height: 16 * s).rotationEffect(.degrees(-25)).offset(x: -5 * s)
                        Capsule().fill(body2).frame(width: 7 * s, height: 19 * s)
                        Capsule().fill(body2).frame(width: 7 * s, height: 15 * s).rotationEffect(.degrees(25)).offset(x: 5 * s)
                    }
                    .offset(y: -42 * s)

                    // body
                    Ellipse()
                        .fill(RadialGradient(colors: [body1, body2], center: UnitPoint(x: 0.4, y: 0.3),
                                             startRadius: 4 * s, endRadius: 60 * s))
                        .frame(width: 84 * s, height: 80 * s)
                    // soft top shine
                    Ellipse()
                        .fill(Color.white.opacity(0.35))
                        .frame(width: 30 * s, height: 14 * s)
                        .rotationEffect(.degrees(-20))
                        .offset(x: -18 * s, y: -26 * s)
                    // belly
                    Ellipse()
                        .fill(belly)
                        .frame(width: 50 * s, height: 34 * s)
                        .offset(y: 20 * s)

                    // eyes
                    HStack(spacing: 14 * s) {
                        eye(s: s)
                        eye(s: s)
                    }
                    .offset(y: -8 * s)

                    // cheeks
                    HStack(spacing: 40 * s) {
                        Ellipse().fill(blush.opacity(0.55)).frame(width: 13 * s, height: 8 * s)
                        Ellipse().fill(blush.opacity(0.55)).frame(width: 13 * s, height: 8 * s)
                    }
                    .offset(y: 6 * s)

                    // beak (opens when cheering)
                    VStack(spacing: 0) {
                        BeakShape().fill(beak).frame(width: 14 * s, height: 8 * s)
                        if mood == .cheer {
                            BeakShape().fill(Color(hex: "#E8682A"))
                                .frame(width: 11 * s, height: 6 * s)
                                .rotationEffect(.degrees(180))
                        }
                    }
                    .offset(y: mood == .cheer ? 7 * s : 4 * s)
                }
                .scaleEffect(x: breathe ? 1.03 : 0.98, y: breathe ? 0.97 : 1.02, anchor: .bottom)
                .offset(y: breathe ? 1 * s : -2 * s)
            }
            .frame(width: g.size.width, height: g.size.height)
        }
        .aspectRatio(1, contentMode: .fit)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) { breathe = true }
            updateFlap()
        }
        .onChange(of: mood) { _ in updateFlap() }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(Double.random(in: 2.2...4.5) * 1_000_000_000))
                blink = true
                try? await Task.sleep(nanoseconds: 130_000_000)
                blink = false
            }
        }
        .accessibilityHidden(true)
    }

    private func updateFlap() {
        if mood == .cheer {
            withAnimation(.easeInOut(duration: 0.22).repeatForever(autoreverses: true)) { flap = true }
        } else {
            withAnimation(.easeOut(duration: 0.2)) { flap = false }
        }
    }

    @ViewBuilder
    private func wingView(s: CGFloat, left: Bool) -> some View {
        let raised = mood == .cheer
        let base: Double = raised ? (flap ? 78 : 52) : 25
        Ellipse()
            .fill(wing)
            .overlay(Ellipse().stroke(body2, lineWidth: 1.5 * s))
            .frame(width: 22 * s, height: 32 * s)
            .rotationEffect(.degrees(left ? base : -base), anchor: .top)
            .offset(x: (left ? -38 : 38) * s, y: (raised ? 4 : 2) * s)
    }

    @ViewBuilder
    private func eye(s: CGFloat) -> some View {
        if mood != .idle || blink {
            // happy / closed eye: a smiling arc
            HappyEyeShape()
                .stroke(ink, style: StrokeStyle(lineWidth: 3.5 * s, lineCap: .round))
                .frame(width: 15 * s, height: 8 * s)
                .frame(width: 18 * s, height: 20 * s)
        } else {
            ZStack {
                Ellipse().fill(Color.white).frame(width: 18 * s, height: 20 * s)
                Ellipse().fill(ink).frame(width: 12 * s, height: 14 * s).offset(x: 1 * s, y: 2 * s)
                Circle().fill(Color.white).frame(width: 5 * s, height: 5 * s).offset(x: -2 * s, y: -2 * s)
                Circle().fill(Color.white.opacity(0.8)).frame(width: 2.5 * s, height: 2.5 * s).offset(x: 4 * s, y: 5 * s)
            }
        }
    }
}

private struct BeakShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY + r.height * 0.15))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.minY + r.height * 0.15), control: CGPoint(x: r.midX, y: r.minY - r.height * 0.2))
        p.addQuadCurve(to: CGPoint(x: r.minX, y: r.minY + r.height * 0.15), control: CGPoint(x: r.midX, y: r.maxY + r.height * 0.6))
        p.closeSubpath()
        return p
    }
}

private struct HappyEyeShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.maxY), control: CGPoint(x: r.midX, y: r.minY - r.height * 0.6))
        return p
    }
}

// ─────────────────────────────────────────────
// MARK: - Speech bubble
// ─────────────────────────────────────────────

struct SpeechBubble: View {
    let text: String
    var size: CGFloat = 22

    var body: some View {
        Text(text)
            .font(.system(size: size, weight: .black, design: .rounded))
            .foregroundColor(Palette.ink)
            .padding(.horizontal, size * 0.7)
            .padding(.vertical, size * 0.35)
            .background(
                Capsule().fill(Color.white)
                    .shadow(color: .black.opacity(0.12), radius: 6, y: 3)
            )
    }
}
