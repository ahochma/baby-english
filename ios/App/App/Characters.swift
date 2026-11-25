import SwiftUI

// ─────────────────────────────────────────────
// MARK: - Word characters (original, drawn in code, same family as Pip)
// ─────────────────────────────────────────────
//
// Every character shares Pip's design language: a big round head, huge
// shiny eyes, rosy cheeks and a small smile. They blink, breathe and
// close their eyes happily when the child gets something right.
// Words without a drawn character fall back to their emoji.

enum CharacterMood: Equatable { case idle, happy }

/// The picture for a word: its drawn character if there is one, otherwise the emoji.
struct WordArt: View {
    let word: WordItem
    var mood: CharacterMood = .idle

    var body: some View {
        GeometryReader { g in
            let d = min(g.size.width, g.size.height)
            Group {
                if let art = CharacterLibrary.view(for: word.id, mood: mood) {
                    art
                } else {
                    Text(word.emoji).font(.system(size: d * 0.86))
                }
            }
            .frame(width: g.size.width, height: g.size.height)
        }
        .accessibilityHidden(true)
    }
}

enum CharacterLibrary {
    static let drawnIds: Set<String> = ["dog", "cat", "duck", "bird", "fish", "cow", "elephant", "lion", "frog", "rabbit"]

    static func has(_ id: String) -> Bool { drawnIds.contains(id) || WorldCharacters.ids.contains(id) }

    static func view(for id: String, mood: CharacterMood) -> AnyView? {
        switch id {
        case "dog": return AnyView(DogCharacter(mood: mood))
        case "cat": return AnyView(CatCharacter(mood: mood))
        case "duck": return AnyView(DuckCharacter(mood: mood))
        case "bird": return AnyView(BirdCharacter(mood: mood))
        case "fish": return AnyView(FishCharacter(mood: mood))
        case "cow": return AnyView(CowCharacter(mood: mood))
        case "elephant": return AnyView(ElephantCharacter(mood: mood))
        case "lion": return AnyView(LionCharacter(mood: mood))
        case "frog": return AnyView(FrogCharacter(mood: mood))
        case "rabbit": return AnyView(RabbitCharacter(mood: mood))
        default: return WorldCharacters.view(for: id, mood: mood)
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - Shared rig: blink, breathe, ground shadow
// ─────────────────────────────────────────────

struct CharacterRig<Content: View>: View {
    var mood: CharacterMood
    /// s = points per unit in a 100×100 design grid; closed = eyes closed (blink or happy)
    @ViewBuilder let content: (_ s: CGFloat, _ closed: Bool) -> Content

    @State private var blink = false
    @State private var breathe = false

    var body: some View {
        GeometryReader { g in
            let s = min(g.size.width, g.size.height) / 100
            ZStack {
                Ellipse()
                    .fill(Color.black.opacity(0.10))
                    .frame(width: (breathe ? 50 : 56) * s, height: 8 * s)
                    .offset(y: 45 * s)
                content(s, blink || mood == .happy)
                    .scaleEffect(x: breathe ? 1.025 : 0.985, y: breathe ? 0.985 : 1.02, anchor: .bottom)
                    .offset(y: (mood == .happy ? -3 : 0) * s)
            }
            .frame(width: g.size.width, height: g.size.height)
        }
        .aspectRatio(1, contentMode: .fit)
        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: mood)
        .onAppear {
            guard !Motion.reduced else { return }
            withAnimation(.easeInOut(duration: Double.random(in: 1.4...1.8)).repeatForever(autoreverses: true)) { breathe = true }
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(Double.random(in: 2.4...5.0) * 1_000_000_000))
                blink = true
                try? await Task.sleep(nanoseconds: 130_000_000)
                blink = false
            }
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - Shared parts
// ─────────────────────────────────────────────

enum Ink {
    static let dark = Color(hex: "#3B2A1E")
    static let blush = Color(hex: "#FF8FA3")
    static let tongue = Color(hex: "#FF7A93")
}

struct CuteEye: View {
    var closed: Bool
    var s: CGFloat
    var size: CGFloat = 17

    var body: some View {
        if closed {
            ArcUp()
                .stroke(Ink.dark, style: StrokeStyle(lineWidth: 3.4 * s, lineCap: .round))
                .frame(width: size * 0.85 * s, height: size * 0.42 * s)
                .frame(width: size * s, height: size * 1.12 * s)
        } else {
            ZStack {
                Ellipse().fill(Color.white).frame(width: size * s, height: size * 1.12 * s)
                Ellipse().fill(Ink.dark).frame(width: size * 0.7 * s, height: size * 0.8 * s)
                    .offset(x: 0.06 * size * s, y: 0.12 * size * s)
                Circle().fill(Color.white).frame(width: size * 0.3 * s)
                    .offset(x: -0.1 * size * s, y: -0.08 * size * s)
                Circle().fill(Color.white.opacity(0.85)).frame(width: size * 0.14 * s)
                    .offset(x: 0.2 * size * s, y: 0.3 * size * s)
            }
        }
    }
}

/// ∩ — closed happy eye
struct ArcUp: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.maxY), control: CGPoint(x: r.midX, y: r.minY - r.height * 0.6))
        return p
    }
}

/// ∪ — smile
struct ArcDown: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.minY), control: CGPoint(x: r.midX, y: r.maxY + r.height * 0.6))
        return p
    }
}

struct RoundedTriangle: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let top = CGPoint(x: r.midX, y: r.minY)
        p.move(to: CGPoint(x: r.minX + r.width * 0.12, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.midX - r.width * 0.08, y: r.minY + r.height * 0.08), control: CGPoint(x: r.minX, y: r.midY))
        p.addQuadCurve(to: CGPoint(x: r.midX + r.width * 0.08, y: r.minY + r.height * 0.08), control: top)
        p.addQuadCurve(to: CGPoint(x: r.maxX - r.width * 0.12, y: r.maxY), control: CGPoint(x: r.maxX, y: r.midY))
        p.addQuadCurve(to: CGPoint(x: r.minX + r.width * 0.12, y: r.maxY), control: CGPoint(x: r.midX, y: r.maxY + r.height * 0.08))
        p.closeSubpath()
        return p
    }
}

private struct Cheeks: View {
    var s: CGFloat
    var spread: CGFloat = 50
    var y: CGFloat = 10
    var body: some View {
        HStack(spacing: spread * s) {
            Ellipse().fill(Ink.blush.opacity(0.5)).frame(width: 12 * s, height: 7 * s)
            Ellipse().fill(Ink.blush.opacity(0.5)).frame(width: 12 * s, height: 7 * s)
        }
        .offset(y: y * s)
    }
}

func shine(_ s: CGFloat, x: CGFloat, y: CGFloat, w: CGFloat = 26, h: CGFloat = 11) -> some View {
    Ellipse()
        .fill(Color.white.opacity(0.4))
        .frame(width: w * s, height: h * s)
        .rotationEffect(.degrees(-20))
        .offset(x: x * s, y: y * s)
}

// ─────────────────────────────────────────────
// MARK: - Dog: floppy-eared puppy with a patch
// ─────────────────────────────────────────────

struct DogCharacter: View {
    var mood: CharacterMood = .idle
    private let fur1 = Color(hex: "#FFE6C4"), fur2 = Color(hex: "#F2C28A")
    private let ear1 = Color(hex: "#A86A42"), ear2 = Color(hex: "#7E4B2C")
    private let patch = Color(hex: "#D9A06A")

    var body: some View {
        CharacterRig(mood: mood) { s, closed in
            ZStack {
                // floppy ears (behind head)
                ForEach([-1.0, 1.0], id: \.self) { side in
                    Ellipse()
                        .fill(LinearGradient(colors: [ear1, ear2], startPoint: .top, endPoint: .bottom))
                        .frame(width: 30 * s, height: 50 * s)
                        .rotationEffect(.degrees(side * (mood == .happy ? 38 : 26)), anchor: .top)
                        .offset(x: side * 40 * s, y: 6 * s)
                }
                // head
                Ellipse()
                    .fill(RadialGradient(colors: [fur1, fur2], center: UnitPoint(x: 0.4, y: 0.3), startRadius: 4 * s, endRadius: 58 * s))
                    .frame(width: 80 * s, height: 74 * s)
                    .offset(y: 2 * s)
                shine(s, x: -16, y: -22)
                // eye patch
                Ellipse().fill(patch.opacity(0.75)).frame(width: 24 * s, height: 22 * s).offset(x: 15 * s, y: -8 * s)
                // eyes
                HStack(spacing: 13 * s) {
                    CuteEye(closed: closed, s: s)
                    CuteEye(closed: closed, s: s)
                }
                .offset(y: -6 * s)
                Cheeks(s: s, spread: 46, y: 10)
                // muzzle
                Ellipse().fill(Color(hex: "#FFF8EE")).frame(width: 36 * s, height: 25 * s).offset(y: 15 * s)
                // tongue (shows when happy)
                if mood == .happy {
                    Capsule().fill(Ink.tongue).frame(width: 9 * s, height: 11 * s).offset(y: 23 * s)
                }
                // smile
                HStack(spacing: 0) {
                    ArcDown().stroke(Ink.dark, style: StrokeStyle(lineWidth: 2.2 * s, lineCap: .round))
                        .frame(width: 8 * s, height: 3.5 * s)
                    ArcDown().stroke(Ink.dark, style: StrokeStyle(lineWidth: 2.2 * s, lineCap: .round))
                        .frame(width: 8 * s, height: 3.5 * s)
                }
                .offset(y: 18 * s)
                // nose
                Ellipse().fill(Ink.dark).frame(width: 14 * s, height: 10 * s).offset(y: 9 * s)
                Ellipse().fill(Color.white.opacity(0.7)).frame(width: 5 * s, height: 2.5 * s).offset(x: -2.5 * s, y: 6.5 * s)
            }
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - Cat: orange kitten with stripes and whiskers
// ─────────────────────────────────────────────

struct CatCharacter: View {
    var mood: CharacterMood = .idle
    private let fur1 = Color(hex: "#FFC98A"), fur2 = Color(hex: "#F59A3C")
    private let stripe = Color(hex: "#E07A22")

    var body: some View {
        CharacterRig(mood: mood) { s, closed in
            ZStack {
                // ears
                ForEach([-1.0, 1.0], id: \.self) { side in
                    ZStack {
                        RoundedTriangle().fill(fur2).frame(width: 28 * s, height: 30 * s)
                        RoundedTriangle().fill(Color(hex: "#FFB3C2")).frame(width: 15 * s, height: 17 * s).offset(y: 4 * s)
                    }
                    .rotationEffect(.degrees(side * (mood == .happy ? 14 : 8)))
                    .offset(x: side * 25 * s, y: -29 * s)
                }
                // head
                Ellipse()
                    .fill(RadialGradient(colors: [fur1, fur2], center: UnitPoint(x: 0.4, y: 0.3), startRadius: 4 * s, endRadius: 58 * s))
                    .frame(width: 84 * s, height: 72 * s)
                    .offset(y: 3 * s)
                shine(s, x: -18, y: -18)
                // forehead stripes
                HStack(spacing: 4 * s) {
                    Capsule().fill(stripe).frame(width: 4 * s, height: 9 * s).rotationEffect(.degrees(-12))
                    Capsule().fill(stripe).frame(width: 4 * s, height: 11 * s)
                    Capsule().fill(stripe).frame(width: 4 * s, height: 9 * s).rotationEffect(.degrees(12))
                }
                .offset(y: -25 * s)
                // eyes
                HStack(spacing: 15 * s) {
                    CuteEye(closed: closed, s: s)
                    CuteEye(closed: closed, s: s)
                }
                .offset(y: -3 * s)
                Cheeks(s: s, spread: 48, y: 12)
                // muzzle
                HStack(spacing: -4 * s) {
                    Ellipse().fill(Color(hex: "#FFF6EA")).frame(width: 18 * s, height: 15 * s)
                    Ellipse().fill(Color(hex: "#FFF6EA")).frame(width: 18 * s, height: 15 * s)
                }
                .offset(y: 15 * s)
                // whiskers
                ForEach([-1.0, 1.0], id: \.self) { side in
                    VStack(spacing: 4 * s) {
                        ForEach([-8.0, 0.0, 8.0], id: \.self) { tilt in
                            Capsule().fill(Ink.dark.opacity(0.45))
                                .frame(width: 16 * s, height: 1.4 * s)
                                .rotationEffect(.degrees(side * tilt))
                        }
                    }
                    .offset(x: side * 30 * s, y: 15 * s)
                }
                // nose
                RoundedTriangle().fill(Color(hex: "#FF8FA3")).frame(width: 9 * s, height: 7 * s)
                    .rotationEffect(.degrees(180)).offset(y: 10 * s)
                // mouth "w" (open when happy)
                if mood == .happy {
                    Ellipse().fill(Ink.dark).frame(width: 8 * s, height: 7 * s).offset(y: 19 * s)
                        .overlay(Ellipse().fill(Ink.tongue).frame(width: 5 * s, height: 3 * s).offset(y: 21 * s))
                } else {
                    HStack(spacing: 0) {
                        ArcDown().stroke(Ink.dark, style: StrokeStyle(lineWidth: 2 * s, lineCap: .round)).frame(width: 6 * s, height: 3 * s)
                        ArcDown().stroke(Ink.dark, style: StrokeStyle(lineWidth: 2 * s, lineCap: .round)).frame(width: 6 * s, height: 3 * s)
                    }
                    .offset(y: 16 * s)
                }
            }
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - Duck: white duckling with a big orange bill
// ─────────────────────────────────────────────

struct DuckCharacter: View {
    var mood: CharacterMood = .idle
    private let feather1 = Color.white, feather2 = Color(hex: "#D3E2F2")
    private let outline = Color(hex: "#BFD2E8")
    private let bill1 = Color(hex: "#FFB341"), bill2 = Color(hex: "#F08A00")

    var body: some View {
        CharacterRig(mood: mood) { s, closed in
            ZStack {
                // little wings peeking out
                ForEach([-1.0, 1.0], id: \.self) { side in
                    Ellipse().fill(feather2)
                        .overlay(Ellipse().stroke(outline, lineWidth: 2 * s))
                        .frame(width: 18 * s, height: 26 * s)
                        .rotationEffect(.degrees(side * (mood == .happy ? -70 : -35)), anchor: .top)
                        .offset(x: side * 36 * s, y: 22 * s)
                }
                // head/body
                Ellipse()
                    .fill(RadialGradient(colors: [feather1, feather2], center: UnitPoint(x: 0.4, y: 0.3), startRadius: 6 * s, endRadius: 60 * s))
                    .frame(width: 80 * s, height: 78 * s)
                Ellipse().stroke(outline, lineWidth: 2.5 * s).frame(width: 80 * s, height: 78 * s)
                shine(s, x: -16, y: -24)
                // tuft
                HStack(spacing: -2 * s) {
                    Capsule().fill(feather2).frame(width: 7 * s, height: 13 * s).rotationEffect(.degrees(-30))
                    Capsule().fill(feather2).frame(width: 7 * s, height: 16 * s)
                    Capsule().fill(feather2).frame(width: 7 * s, height: 12 * s).rotationEffect(.degrees(30))
                }
                .offset(y: -40 * s)
                // eyes
                HStack(spacing: 15 * s) {
                    CuteEye(closed: closed, s: s)
                    CuteEye(closed: closed, s: s)
                }
                .offset(y: -10 * s)
                Cheeks(s: s, spread: 50, y: 6)
                // bill: upper and lower, opens when happy
                ZStack {
                    Capsule().fill(bill2).frame(width: 34 * s, height: 12 * s)
                        .offset(y: (mood == .happy ? 10 : 6) * s)
                    Capsule()
                        .fill(LinearGradient(colors: [bill1, Color(hex: "#FF9F1C")], startPoint: .top, endPoint: .bottom))
                        .frame(width: 40 * s, height: 15 * s)
                    HStack(spacing: 8 * s) {
                        Capsule().fill(bill2.opacity(0.8)).frame(width: 3 * s, height: 2 * s)
                        Capsule().fill(bill2.opacity(0.8)).frame(width: 3 * s, height: 2 * s)
                    }
                    .offset(y: -3 * s)
                    ArcDown().stroke(bill2, style: StrokeStyle(lineWidth: 1.8 * s, lineCap: .round))
                        .frame(width: 22 * s, height: 3 * s).offset(y: 3 * s)
                }
                .offset(y: 12 * s)
                // little blue bow
                HStack(spacing: 0) {
                    RoundedTriangle().fill(Color(hex: "#4FA8F7")).frame(width: 12 * s, height: 11 * s).rotationEffect(.degrees(-90))
                    Circle().fill(Color(hex: "#2E86DE")).frame(width: 6 * s)
                    RoundedTriangle().fill(Color(hex: "#4FA8F7")).frame(width: 12 * s, height: 11 * s).rotationEffect(.degrees(90))
                }
                .offset(y: 36 * s)
            }
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - Bird: sky-blue songbird
// ─────────────────────────────────────────────

struct BirdCharacter: View {
    var mood: CharacterMood = .idle
    private let body1 = Color(hex: "#9ED8FF"), body2 = Color(hex: "#3E9BE6")
    private let belly = Color(hex: "#E6F5FF")
    private let beak = Color(hex: "#FFB341")

    var body: some View {
        CharacterRig(mood: mood) { s, closed in
            ZStack {
                ForEach([-1.0, 1.0], id: \.self) { side in
                    Ellipse().fill(body2)
                        .frame(width: 20 * s, height: 30 * s)
                        .rotationEffect(.degrees(side * (mood == .happy ? -75 : -20)), anchor: .top)
                        .offset(x: side * 37 * s, y: 10 * s)
                }
                // tuft
                HStack(spacing: -1 * s) {
                    Capsule().fill(body2).frame(width: 6 * s, height: 13 * s).rotationEffect(.degrees(-25))
                    Capsule().fill(body2).frame(width: 6 * s, height: 16 * s)
                }
                .offset(x: 2 * s, y: -40 * s)
                Ellipse()
                    .fill(RadialGradient(colors: [body1, body2], center: UnitPoint(x: 0.4, y: 0.3), startRadius: 4 * s, endRadius: 60 * s))
                    .frame(width: 80 * s, height: 78 * s)
                shine(s, x: -16, y: -24)
                Ellipse().fill(belly).frame(width: 46 * s, height: 34 * s).offset(y: 20 * s)
                HStack(spacing: 14 * s) {
                    CuteEye(closed: closed, s: s)
                    CuteEye(closed: closed, s: s)
                }
                .offset(y: -10 * s)
                Cheeks(s: s, spread: 46, y: 5)
                // beak: two triangles, opens when singing (happy)
                VStack(spacing: 0) {
                    RoundedTriangle().fill(beak).frame(width: 13 * s, height: 9 * s).rotationEffect(.degrees(180))
                    if mood == .happy {
                        RoundedTriangle().fill(Color(hex: "#F08A00")).frame(width: 10 * s, height: 6 * s)
                    }
                }
                .offset(y: (mood == .happy ? 6 : 3) * s)
            }
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - Fish: round coral fish, front-facing like the others
// ─────────────────────────────────────────────

struct FishCharacter: View {
    var mood: CharacterMood = .idle
    private let body1 = Color(hex: "#FFB199"), body2 = Color(hex: "#FF6F61")
    private let fin = Color(hex: "#FF8C7A"), finDark = Color(hex: "#F25A4D")

    var body: some View {
        CharacterRig(mood: mood) { s, closed in
            ZStack {
                // big tail on the right, wags when happy
                RoundedTriangle()
                    .fill(LinearGradient(colors: [fin, finDark], startPoint: .leading, endPoint: .trailing))
                    .frame(width: 34 * s, height: 30 * s)
                    .rotationEffect(.degrees(-90 + (mood == .happy ? 14 : 0)))
                    .offset(x: 38 * s, y: 2 * s)
                // top fin
                RoundedTriangle().fill(fin).frame(width: 28 * s, height: 18 * s)
                    .rotationEffect(.degrees(12)).offset(x: 4 * s, y: -34 * s)
                // body
                Ellipse()
                    .fill(RadialGradient(colors: [body1, body2], center: UnitPoint(x: 0.35, y: 0.3), startRadius: 4 * s, endRadius: 58 * s))
                    .frame(width: 76 * s, height: 64 * s)
                    .offset(x: -6 * s)
                shine(s, x: -20, y: -16)
                // scales
                VStack(spacing: 2 * s) {
                    HStack(spacing: 3 * s) {
                        ForEach(0..<2, id: \.self) { _ in
                            ArcDown().stroke(Color.white.opacity(0.5), style: StrokeStyle(lineWidth: 2 * s, lineCap: .round))
                                .frame(width: 8 * s, height: 3.5 * s)
                        }
                    }
                    HStack(spacing: 3 * s) {
                        ForEach(0..<3, id: \.self) { _ in
                            ArcDown().stroke(Color.white.opacity(0.5), style: StrokeStyle(lineWidth: 2 * s, lineCap: .round))
                                .frame(width: 8 * s, height: 3.5 * s)
                        }
                    }
                }
                .offset(x: 14 * s, y: 6 * s)
                // side fin
                Ellipse().fill(finDark.opacity(0.8)).frame(width: 14 * s, height: 9 * s)
                    .rotationEffect(.degrees(mood == .happy ? -40 : 25)).offset(x: 2 * s, y: 20 * s)
                // eyes toward the front (left)
                HStack(spacing: 10 * s) {
                    CuteEye(closed: closed, s: s, size: 16)
                    CuteEye(closed: closed, s: s, size: 16)
                }
                .offset(x: -14 * s, y: -8 * s)
                Ellipse().fill(Ink.blush.opacity(0.5)).frame(width: 11 * s, height: 6 * s).offset(x: -32 * s, y: 6 * s)
                // mouth at the front, blowing bubbles when happy
                Ellipse().stroke(Color(hex: "#C2453A"), lineWidth: 2.4 * s).frame(width: 7 * s, height: 7 * s)
                    .offset(x: -40 * s, y: 6 * s)
                if mood == .happy {
                    Circle().fill(Color(hex: "#BDE9FF")).overlay(Circle().stroke(Color(hex: "#7CCBF2"), lineWidth: 1.4 * s))
                        .frame(width: 9 * s).offset(x: -44 * s, y: -10 * s)
                    Circle().fill(Color(hex: "#BDE9FF")).overlay(Circle().stroke(Color(hex: "#7CCBF2"), lineWidth: 1.2 * s))
                        .frame(width: 6 * s).offset(x: -40 * s, y: -22 * s)
                }
            }
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - Cow: spotted calf with a big pink snout
// ─────────────────────────────────────────────

struct CowCharacter: View {
    var mood: CharacterMood = .idle
    private let snout1 = Color(hex: "#FFC6D0"), snout2 = Color(hex: "#F79AAE")
    private let spot = Color(hex: "#3B2A1E")

    var body: some View {
        CharacterRig(mood: mood) { s, closed in
            ZStack {
                // horns
                ForEach([-1.0, 1.0], id: \.self) { side in
                    Capsule().fill(Color(hex: "#F3E2B8"))
                        .frame(width: 8 * s, height: 16 * s)
                        .rotationEffect(.degrees(side * 25))
                        .offset(x: side * 20 * s, y: -38 * s)
                }
                // ears
                ForEach([-1.0, 1.0], id: \.self) { side in
                    Ellipse().fill(Color(hex: "#E9E3E8"))
                        .overlay(Ellipse().fill(Color(hex: "#FFB3C2")).padding(4 * s))
                        .frame(width: 26 * s, height: 14 * s)
                        .rotationEffect(.degrees(side * (mood == .happy ? -30 : -12)))
                        .offset(x: side * 42 * s, y: -14 * s)
                }
                Ellipse()
                    .fill(RadialGradient(colors: [.white, Color(hex: "#ECE7EE")], center: UnitPoint(x: 0.4, y: 0.3), startRadius: 4 * s, endRadius: 58 * s))
                    .frame(width: 76 * s, height: 78 * s)
                // spots
                Ellipse().fill(spot.opacity(0.85)).frame(width: 22 * s, height: 18 * s).rotationEffect(.degrees(-20)).offset(x: -20 * s, y: -24 * s)
                Ellipse().fill(spot.opacity(0.85)).frame(width: 14 * s, height: 12 * s).offset(x: 24 * s, y: -12 * s)
                shine(s, x: -4, y: -30, w: 18, h: 8)
                HStack(spacing: 14 * s) {
                    CuteEye(closed: closed, s: s)
                    CuteEye(closed: closed, s: s)
                }
                .offset(y: -8 * s)
                // snout
                Ellipse()
                    .fill(LinearGradient(colors: [snout1, snout2], startPoint: .top, endPoint: .bottom))
                    .frame(width: 50 * s, height: 30 * s)
                    .offset(y: 20 * s)
                HStack(spacing: 14 * s) {
                    Ellipse().fill(Color(hex: "#C2566E")).frame(width: 6 * s, height: 8 * s)
                    Ellipse().fill(Color(hex: "#C2566E")).frame(width: 6 * s, height: 8 * s)
                }
                .offset(y: 16 * s)
                ArcDown().stroke(Color(hex: "#C2566E"), style: StrokeStyle(lineWidth: 2.2 * s, lineCap: .round))
                    .frame(width: (mood == .happy ? 18 : 12) * s, height: 4 * s)
                    .offset(y: 27 * s)
            }
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - Elephant: big ears and a curly trunk
// ─────────────────────────────────────────────

struct ElephantCharacter: View {
    var mood: CharacterMood = .idle
    private let skin1 = Color(hex: "#C9D5EA"), skin2 = Color(hex: "#93A4C8")
    private let inner = Color(hex: "#F6C2D2")

    var body: some View {
        CharacterRig(mood: mood) { s, closed in
            ZStack {
                ForEach([-1.0, 1.0], id: \.self) { side in
                    Ellipse().fill(skin2)
                        .overlay(Ellipse().fill(inner).padding(7 * s))
                        .frame(width: 40 * s, height: 48 * s)
                        .rotationEffect(.degrees(side * (mood == .happy ? 18 : 6)))
                        .offset(x: side * 40 * s, y: -2 * s)
                }
                Ellipse()
                    .fill(RadialGradient(colors: [skin1, skin2], center: UnitPoint(x: 0.4, y: 0.3), startRadius: 4 * s, endRadius: 58 * s))
                    .frame(width: 70 * s, height: 70 * s)
                    .offset(y: -4 * s)
                shine(s, x: -12, y: -26, w: 22, h: 9)
                HStack(spacing: 15 * s) {
                    CuteEye(closed: closed, s: s, size: 15)
                    CuteEye(closed: closed, s: s, size: 15)
                }
                .offset(y: -12 * s)
                Cheeks(s: s, spread: 40, y: 2)
                // trunk: hangs down and curls at the tip; lifts and toots when happy
                ZStack(alignment: .top) {
                    Capsule()
                        .fill(LinearGradient(colors: [skin1, skin2], startPoint: .leading, endPoint: .trailing))
                        .frame(width: 15 * s, height: 34 * s)
                    Capsule()
                        .fill(skin2)
                        .frame(width: 13 * s, height: 14 * s)
                        .rotationEffect(.degrees(-55), anchor: .top)
                        .offset(x: 3 * s, y: 28 * s)
                    HStack(spacing: 3 * s) {
                        Circle().fill(Ink.dark.opacity(0.35)).frame(width: 2.6 * s)
                        Circle().fill(Ink.dark.opacity(0.35)).frame(width: 2.6 * s)
                    }
                    .offset(x: 9 * s, y: 36 * s)
                }
                .frame(width: 30 * s, height: 48 * s, alignment: .top)
                .rotationEffect(.degrees(mood == .happy ? -70 : 0), anchor: .top)
                .offset(y: 26 * s)
            }
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - Lion: fluffy mane, golden face
// ─────────────────────────────────────────────

struct LionCharacter: View {
    var mood: CharacterMood = .idle
    private let mane1 = Color(hex: "#F6A23B"), mane2 = Color(hex: "#D9731C")
    private let face1 = Color(hex: "#FFE3A0"), face2 = Color(hex: "#FFC75A")

    var body: some View {
        CharacterRig(mood: mood) { s, closed in
            ZStack {
                // mane: ring of fluffy puffs
                ForEach(0..<12, id: \.self) { i in
                    Circle()
                        .fill(i.isMultiple(of: 2) ? mane1 : mane2)
                        .frame(width: 30 * s)
                        .offset(y: -36 * s)
                        .rotationEffect(.degrees(Double(i) * 30 + (mood == .happy ? 6 : 0)))
                }
                Circle().fill(mane1).frame(width: 82 * s)
                // ears
                ForEach([-1.0, 1.0], id: \.self) { side in
                    Circle().fill(face2).frame(width: 15 * s)
                        .overlay(Circle().fill(Color(hex: "#F7A8A0")).frame(width: 7 * s))
                        .offset(x: side * 24 * s, y: -26 * s)
                }
                Ellipse()
                    .fill(RadialGradient(colors: [face1, face2], center: UnitPoint(x: 0.4, y: 0.3), startRadius: 4 * s, endRadius: 46 * s))
                    .frame(width: 64 * s, height: 60 * s)
                    .offset(y: 3 * s)
                shine(s, x: -12, y: -16, w: 18, h: 8)
                HStack(spacing: 12 * s) {
                    CuteEye(closed: closed, s: s, size: 15)
                    CuteEye(closed: closed, s: s, size: 15)
                }
                .offset(y: -4 * s)
                Cheeks(s: s, spread: 38, y: 11)
                HStack(spacing: -3 * s) {
                    Ellipse().fill(Color(hex: "#FFF4DE")).frame(width: 15 * s, height: 12 * s)
                    Ellipse().fill(Color(hex: "#FFF4DE")).frame(width: 15 * s, height: 12 * s)
                }
                .offset(y: 15 * s)
                RoundedTriangle().fill(Color(hex: "#8A4A2A")).frame(width: 11 * s, height: 8 * s)
                    .rotationEffect(.degrees(180)).offset(y: 10 * s)
                if mood == .happy {   // a friendly little roar
                    Ellipse().fill(Ink.dark).frame(width: 10 * s, height: 8 * s).offset(y: 22 * s)
                        .overlay(Ellipse().fill(Ink.tongue).frame(width: 6 * s, height: 3 * s).offset(y: 24.5 * s))
                } else {
                    HStack(spacing: 0) {
                        ArcDown().stroke(Ink.dark, style: StrokeStyle(lineWidth: 2 * s, lineCap: .round)).frame(width: 6 * s, height: 3 * s)
                        ArcDown().stroke(Ink.dark, style: StrokeStyle(lineWidth: 2 * s, lineCap: .round)).frame(width: 6 * s, height: 3 * s)
                    }
                    .offset(y: 18 * s)
                }
            }
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - Frog: bulging eyes on top, wide smile
// ─────────────────────────────────────────────

struct FrogCharacter: View {
    var mood: CharacterMood = .idle
    private let skin1 = Color(hex: "#A8EA8E"), skin2 = Color(hex: "#4FBF4A")

    var body: some View {
        CharacterRig(mood: mood) { s, closed in
            ZStack {
                // eye domes
                HStack(spacing: 10 * s) {
                    Circle().fill(skin2).frame(width: 30 * s)
                    Circle().fill(skin2).frame(width: 30 * s)
                }
                .offset(y: -28 * s)
                Ellipse()
                    .fill(RadialGradient(colors: [skin1, skin2], center: UnitPoint(x: 0.4, y: 0.3), startRadius: 4 * s, endRadius: 60 * s))
                    .frame(width: 88 * s, height: 64 * s)
                    .offset(y: 6 * s)
                Ellipse().fill(Color(hex: "#DFF7C9")).frame(width: 56 * s, height: 26 * s).offset(y: 22 * s)
                shine(s, x: -18, y: -6, w: 22, h: 8)
                HStack(spacing: 18 * s) {
                    CuteEye(closed: closed, s: s, size: 19)
                    CuteEye(closed: closed, s: s, size: 19)
                }
                .offset(y: -28 * s)
                Cheeks(s: s, spread: 58, y: 10)
                // wide smile; opens into a big grin when happy
                if mood == .happy {
                    ArcDown().fill(Ink.dark).frame(width: 34 * s, height: 10 * s).offset(y: 12 * s)
                        .overlay(Ellipse().fill(Ink.tongue).frame(width: 12 * s, height: 5 * s).offset(y: 17 * s))
                } else {
                    ArcDown().stroke(Ink.dark, style: StrokeStyle(lineWidth: 2.6 * s, lineCap: .round))
                        .frame(width: 34 * s, height: 7 * s)
                        .offset(y: 12 * s)
                }
            }
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - Rabbit: tall ears, twitchy nose, buck teeth
// ─────────────────────────────────────────────

struct RabbitCharacter: View {
    var mood: CharacterMood = .idle
    private let fur1 = Color.white, fur2 = Color(hex: "#E3D9E8")
    private let inner = Color(hex: "#FFB3C7")

    var body: some View {
        CharacterRig(mood: mood) { s, closed in
            ZStack {
                ForEach([-1.0, 1.0], id: \.self) { side in
                    Capsule().fill(fur2)
                        .overlay(Capsule().fill(inner).padding(5 * s))
                        .frame(width: 20 * s, height: 46 * s)
                        .rotationEffect(.degrees(side * (mood == .happy ? 14 : 6) + (side > 0 && mood != .happy ? 18 : 0)), anchor: .bottom)
                        .offset(x: side * 15 * s, y: -38 * s)
                }
                Ellipse()
                    .fill(RadialGradient(colors: [fur1, fur2], center: UnitPoint(x: 0.4, y: 0.3), startRadius: 4 * s, endRadius: 58 * s))
                    .frame(width: 76 * s, height: 70 * s)
                    .offset(y: 6 * s)
                Ellipse().stroke(Color(hex: "#D3C6DB"), lineWidth: 2 * s).frame(width: 76 * s, height: 70 * s).offset(y: 6 * s)
                shine(s, x: -16, y: -14)
                HStack(spacing: 15 * s) {
                    CuteEye(closed: closed, s: s)
                    CuteEye(closed: closed, s: s)
                }
                .offset(y: 0)
                Cheeks(s: s, spread: 46, y: 15)
                // nose + mouth
                Ellipse().fill(Color(hex: "#FF8FA3")).frame(width: 9 * s, height: 6 * s).offset(y: 13 * s)
                HStack(spacing: 0) {
                    ArcDown().stroke(Ink.dark, style: StrokeStyle(lineWidth: 1.8 * s, lineCap: .round)).frame(width: 6 * s, height: 3 * s)
                    ArcDown().stroke(Ink.dark, style: StrokeStyle(lineWidth: 1.8 * s, lineCap: .round)).frame(width: 6 * s, height: 3 * s)
                }
                .offset(y: 18 * s)
                if mood == .happy {
                    HStack(spacing: 1 * s) {
                        RoundedRectangle(cornerRadius: 1 * s).fill(.white).frame(width: 4.5 * s, height: 6 * s)
                        RoundedRectangle(cornerRadius: 1 * s).fill(.white).frame(width: 4.5 * s, height: 6 * s)
                    }
                    .overlay(RoundedRectangle(cornerRadius: 1 * s).stroke(Color(hex: "#D3C6DB"), lineWidth: 0.8 * s))
                    .offset(y: 23 * s)
                }
                // whiskers
                ForEach([-1.0, 1.0], id: \.self) { side in
                    VStack(spacing: 3.5 * s) {
                        Capsule().fill(Ink.dark.opacity(0.35)).frame(width: 13 * s, height: 1.2 * s).rotationEffect(.degrees(side * -8))
                        Capsule().fill(Ink.dark.opacity(0.35)).frame(width: 13 * s, height: 1.2 * s).rotationEffect(.degrees(side * 8))
                    }
                    .offset(x: side * 22 * s, y: 15 * s)
                }
            }
        }
    }
}
