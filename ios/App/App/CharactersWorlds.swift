import SwiftUI

// ─────────────────────────────────────────────
// MARK: - Characters for the other worlds
// ─────────────────────────────────────────────
//
// Vehicles, food, colours, body parts and numbers, drawn in the same
// family as Pip and the animals: soft gradients, rounded shapes, big shiny
// eyes. Everything lives in the shared 100×100 grid of CharacterRig, so
// it blinks, breathes and celebrates exactly like the animals.

enum WorldCharacters {
    static let ids: Set<String> = {
        var all = Set<String>(vehicles)
        all.formUnion(food)
        all.formUnion(body)
        all.formUnion(PaintColor.all.keys)
        all.formUnion(NumberBuddy.words.keys)
        return all
    }()

    static let vehicles = ["firetruck", "helicopter", "truck", "ambulance", "policecar", "tractor", "train", "rocket", "airplane", "bus"]
    static let food = ["apple", "banana", "milk", "bread", "egg", "orange2", "strawberry", "carrot", "cake", "grapes"]
    static let body = ["eyes", "nose", "mouth", "ear", "hand", "foot", "tooth", "tongue", "leg", "arm"]

    static func view(for id: String, mood: CharacterMood) -> AnyView? {
        if let paint = PaintColor.all[id] { return AnyView(PaintDropCharacter(mood: mood, paint: paint)) }
        if let n = NumberBuddy.words[id] { return AnyView(NumberBuddy(mood: mood, n: n)) }
        switch id {
        // vehicles
        case "firetruck": return AnyView(FireTruckCharacter(mood: mood))
        case "helicopter": return AnyView(HelicopterCharacter(mood: mood))
        case "truck": return AnyView(TruckCharacter(mood: mood))
        case "ambulance": return AnyView(AmbulanceCharacter(mood: mood))
        case "policecar": return AnyView(PoliceCarCharacter(mood: mood))
        case "tractor": return AnyView(TractorCharacter(mood: mood))
        case "train": return AnyView(TrainCharacter(mood: mood))
        case "rocket": return AnyView(RocketCharacter(mood: mood))
        case "airplane": return AnyView(AirplaneCharacter(mood: mood))
        case "bus": return AnyView(BusCharacter(mood: mood))
        // food
        case "apple": return AnyView(AppleCharacter(mood: mood))
        case "banana": return AnyView(BananaCharacter(mood: mood))
        case "milk": return AnyView(MilkCharacter(mood: mood))
        case "bread": return AnyView(BreadCharacter(mood: mood))
        case "egg": return AnyView(EggCharacter(mood: mood))
        case "orange2": return AnyView(OrangeCharacter(mood: mood))
        case "strawberry": return AnyView(StrawberryCharacter(mood: mood))
        case "carrot": return AnyView(CarrotCharacter(mood: mood))
        case "cake": return AnyView(CakeCharacter(mood: mood))
        case "grapes": return AnyView(GrapesCharacter(mood: mood))
        // body
        case "eyes": return AnyView(EyesCharacter(mood: mood))
        case "nose": return AnyView(NoseCharacter(mood: mood))
        case "mouth": return AnyView(MouthCharacter(mood: mood))
        case "ear": return AnyView(EarCharacter(mood: mood))
        case "hand": return AnyView(HandCharacter(mood: mood))
        case "foot": return AnyView(FootCharacter(mood: mood))
        case "tooth": return AnyView(ToothCharacter(mood: mood))
        case "tongue": return AnyView(TongueCharacter(mood: mood))
        case "leg": return AnyView(LegCharacter(mood: mood))
        case "arm": return AnyView(ArmCharacter(mood: mood))
        default: return nil
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - Shared pieces
// ─────────────────────────────────────────────

private func vgrad(_ a: String, _ b: String) -> LinearGradient {
    LinearGradient(colors: [Color(hex: a), Color(hex: b)], startPoint: .top, endPoint: .bottom)
}

private func rgrad(_ a: String, _ b: String, _ s: CGFloat, r: CGFloat = 58) -> RadialGradient {
    RadialGradient(colors: [Color(hex: a), Color(hex: b)], center: UnitPoint(x: 0.38, y: 0.3), startRadius: 3 * s, endRadius: r * s)
}

private extension CGRect {
    /// A point in unit coordinates of this rect.
    func u(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: minX + x * width, y: minY + y * height) }
}

/// Eyes, cheeks and a smile that opens when happy — the face every character shares.
struct KawaiiFace: View {
    var s: CGFloat
    var closed: Bool
    var mood: CharacterMood
    var eye: CGFloat = 12
    var gap: CGFloat = 10
    var mouthDrop: CGFloat? = nil
    var cheeks: Bool = true
    var ink: Color = Ink.dark

    var body: some View {
        let drop = mouthDrop ?? eye * 0.85
        ZStack {
            HStack(spacing: gap * s) {
                CuteEye(closed: closed, s: s, size: eye)
                CuteEye(closed: closed, s: s, size: eye)
            }
            if cheeks {
                HStack(spacing: (gap + eye * 0.85) * s) {
                    Ellipse().fill(Ink.blush.opacity(0.55)).frame(width: eye * 0.75 * s, height: eye * 0.45 * s)
                    Ellipse().fill(Ink.blush.opacity(0.55)).frame(width: eye * 0.75 * s, height: eye * 0.45 * s)
                }
                .offset(y: eye * 0.62 * s)
            }
            if mood == .happy {
                ArcDown().fill(ink)
                    .frame(width: eye * 0.95 * s, height: eye * 0.42 * s)
                    .overlay(Ellipse().fill(Ink.tongue).frame(width: eye * 0.42 * s, height: eye * 0.18 * s).offset(y: eye * 0.07 * s))
                    .offset(y: drop * s)
            } else {
                ArcDown().stroke(ink, style: StrokeStyle(lineWidth: max(1.6, eye * 0.17) * s, lineCap: .round))
                    .frame(width: eye * 0.62 * s, height: eye * 0.24 * s)
                    .offset(y: drop * s)
            }
        }
    }
}

private let glass = LinearGradient(colors: [Color(hex: "#E8F7FF"), Color(hex: "#A6D8F7")], startPoint: .top, endPoint: .bottom)

/// A windscreen with the vehicle's face looking out of it.
private struct FaceWindow: View {
    var s: CGFloat
    var closed: Bool
    var mood: CharacterMood
    var w: CGFloat = 28
    var h: CGFloat = 22
    var eye: CGFloat = 9
    var round: CGFloat = 7

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: round * s).fill(glass)
            RoundedRectangle(cornerRadius: round * s).stroke(Color.white.opacity(0.8), lineWidth: 1.6 * s)
            KawaiiFace(s: s, closed: closed, mood: mood, eye: eye, gap: eye * 0.55, mouthDrop: eye * 0.82, cheeks: false)
                .offset(y: -h * 0.12 * s)
        }
        .frame(width: w * s, height: h * s)
    }
}

private struct Wheel: View {
    var s: CGFloat
    var d: CGFloat = 20
    var body: some View {
        ZStack {
            Circle().fill(Color(hex: "#3A3A48"))
            Circle().fill(Color(hex: "#D3D8E0")).frame(width: d * 0.5 * s)
            Circle().fill(Color.white).frame(width: d * 0.18 * s)
        }
        .frame(width: d * s, height: d * s)
    }
}

/// Little light glow for sirens and headlamps when the vehicle is happy.
private func glow(_ hex: String, _ s: CGFloat, d: CGFloat = 24) -> some View {
    Circle().fill(Color(hex: hex).opacity(0.35)).frame(width: d * s)
}

// ─────────────────────────────────────────────
// MARK: - Vehicles (side view, nose to the left)
// ─────────────────────────────────────────────

struct FireTruckCharacter: View {
    var mood: CharacterMood = .idle
    var body: some View {
        CharacterRig(mood: mood) { s, closed in
            ZStack {
                // ladder lifts when happy
                ZStack {
                    RoundedRectangle(cornerRadius: 2 * s).stroke(Color(hex: "#AEB8C4"), lineWidth: 2.6 * s)
                    HStack(spacing: 6 * s) {
                        ForEach(0..<6, id: \.self) { _ in
                            Capsule().fill(Color(hex: "#AEB8C4")).frame(width: 2.4 * s, height: 9 * s)
                        }
                    }
                }
                .frame(width: 54 * s, height: 9 * s)
                .rotationEffect(.degrees(mood == .happy ? -14 : -4), anchor: .trailing)
                .offset(x: 14 * s, y: -15 * s)
                RoundedRectangle(cornerRadius: 9 * s).fill(vgrad("#FF6E61", "#E0322B"))
                    .frame(width: 60 * s, height: 36 * s).offset(x: 14 * s, y: 8 * s)
                RoundedRectangle(cornerRadius: 11 * s).fill(vgrad("#FF7B6E", "#E0322B"))
                    .frame(width: 38 * s, height: 50 * s).offset(x: -26 * s, y: 1 * s)
                Capsule().fill(Color.white.opacity(0.92)).frame(width: 90 * s, height: 4.5 * s).offset(x: -2 * s, y: 16 * s)
                Circle().fill(Color(hex: "#FFD54F")).frame(width: 14 * s)
                    .overlay(Circle().fill(Color(hex: "#F9A825")).frame(width: 5 * s))
                    .offset(x: 18 * s, y: 3 * s)
                FaceWindow(s: s, closed: closed, mood: mood).offset(x: -27 * s, y: -10 * s)
                if mood == .happy { glow("#4FC3F7", s).offset(x: -26 * s, y: -28 * s) }
                Capsule().fill(Color(hex: mood == .happy ? "#4FC3F7" : "#2E86DE"))
                    .frame(width: 13 * s, height: 8 * s).offset(x: -26 * s, y: -28 * s)
                Circle().fill(Color(hex: "#FFF59D")).frame(width: 6 * s).offset(x: -43 * s, y: 12 * s)
                Wheel(s: s, d: 22).offset(x: -24 * s, y: 29 * s)
                Wheel(s: s, d: 22).offset(x: 26 * s, y: 29 * s)
            }
        }
    }
}

struct AmbulanceCharacter: View {
    var mood: CharacterMood = .idle
    private let line = Color(hex: "#D5DCE6")
    var body: some View {
        CharacterRig(mood: mood) { s, closed in
            ZStack {
                RoundedRectangle(cornerRadius: 10 * s).fill(vgrad("#FFFFFF", "#E8EDF4"))
                    .overlay(RoundedRectangle(cornerRadius: 10 * s).stroke(line, lineWidth: 2 * s))
                    .frame(width: 58 * s, height: 54 * s).offset(x: 15 * s, y: -1 * s)
                RoundedRectangle(cornerRadius: 10 * s).fill(vgrad("#FFFFFF", "#E8EDF4"))
                    .overlay(RoundedRectangle(cornerRadius: 10 * s).stroke(line, lineWidth: 2 * s))
                    .frame(width: 36 * s, height: 40 * s).offset(x: -26 * s, y: 6 * s)
                Capsule().fill(Color(hex: "#F0435A")).frame(width: 88 * s, height: 5 * s).offset(x: -4 * s, y: 17 * s)
                // red cross
                ZStack {
                    RoundedRectangle(cornerRadius: 1.5 * s).fill(Color(hex: "#F0435A")).frame(width: 18 * s, height: 6 * s)
                    RoundedRectangle(cornerRadius: 1.5 * s).fill(Color(hex: "#F0435A")).frame(width: 6 * s, height: 18 * s)
                }
                .offset(x: 16 * s, y: -6 * s)
                FaceWindow(s: s, closed: closed, mood: mood, w: 26, h: 20).offset(x: -28 * s, y: -1 * s)
                if mood == .happy { glow("#FF5A6E", s).offset(x: -24 * s, y: -17 * s) }
                Capsule().fill(Color(hex: mood == .happy ? "#FF5A6E" : "#E53950"))
                    .frame(width: 12 * s, height: 7 * s).offset(x: -24 * s, y: -17 * s)
                Wheel(s: s, d: 21).offset(x: -24 * s, y: 29 * s)
                Wheel(s: s, d: 21).offset(x: 26 * s, y: 29 * s)
            }
        }
    }
}

struct PoliceCarCharacter: View {
    var mood: CharacterMood = .idle
    var body: some View {
        CharacterRig(mood: mood) { s, closed in
            ZStack {
                // light bar: red/blue swap when happy
                HStack(spacing: 1 * s) {
                    Capsule().fill(Color(hex: mood == .happy ? "#42A5F5" : "#EF5350")).frame(width: 11 * s, height: 7 * s)
                    Capsule().fill(Color(hex: mood == .happy ? "#EF5350" : "#42A5F5")).frame(width: 11 * s, height: 7 * s)
                }
                .background { if mood == .happy { glow("#90CAF9", s, d: 30) } }
                .offset(x: 2 * s, y: -25 * s)
                RoundedRectangle(cornerRadius: 13 * s).fill(vgrad("#FFFFFF", "#E3E8F0"))
                    .frame(width: 54 * s, height: 30 * s).offset(x: 2 * s, y: -6 * s)
                FaceWindow(s: s, closed: closed, mood: mood, w: 24, h: 19, eye: 8.5, round: 6).offset(x: -10 * s, y: -6 * s)
                RoundedRectangle(cornerRadius: 6 * s).fill(glass).frame(width: 15 * s, height: 19 * s).offset(x: 17 * s, y: -6 * s)
                RoundedRectangle(cornerRadius: 14 * s).fill(vgrad("#3F5BD8", "#22328F"))
                    .frame(width: 92 * s, height: 28 * s).offset(y: 14 * s)
                RoundedRectangle(cornerRadius: 5 * s).fill(Color.white).frame(width: 30 * s, height: 18 * s).offset(x: 3 * s, y: 13 * s)
                Image(systemName: "star.fill").font(.system(size: 10 * s)).foregroundStyle(Color(hex: "#FFC93C")).offset(x: 3 * s, y: 13 * s)
                Circle().fill(Color(hex: "#FFF59D")).frame(width: 7 * s).offset(x: -42 * s, y: 9 * s)
                Wheel(s: s, d: 21).offset(x: -26 * s, y: 29 * s)
                Wheel(s: s, d: 21).offset(x: 27 * s, y: 29 * s)
            }
        }
    }
}

struct BusCharacter: View {
    var mood: CharacterMood = .idle
    var body: some View {
        CharacterRig(mood: mood) { s, closed in
            ZStack {
                RoundedRectangle(cornerRadius: 14 * s).fill(vgrad("#FFE36E", "#FFBE1A"))
                    .frame(width: 92 * s, height: 58 * s).offset(y: 1 * s)
                shine(s, x: -10, y: -22, w: 40, h: 6)
                Capsule().fill(Color(hex: "#FF8F1F")).frame(width: 88 * s, height: 5 * s).offset(y: 17 * s)
                FaceWindow(s: s, closed: closed, mood: mood, w: 26, h: 24, eye: 9.5).offset(x: -29 * s, y: -7 * s)
                HStack(spacing: 4 * s) {
                    ForEach(0..<3, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 4 * s).fill(glass).frame(width: 15 * s, height: 16 * s)
                    }
                }
                .offset(x: 15 * s, y: -9 * s)
                if mood == .happy { glow("#FFF59D", s, d: 16).offset(x: -43 * s, y: 9 * s) }
                Circle().fill(Color(hex: "#FFFDE7")).frame(width: 7 * s).offset(x: -43 * s, y: 9 * s)
                Wheel(s: s, d: 21).offset(x: -26 * s, y: 30 * s)
                Wheel(s: s, d: 21).offset(x: 27 * s, y: 30 * s)
            }
        }
    }
}

struct TruckCharacter: View {
    var mood: CharacterMood = .idle
    var body: some View {
        CharacterRig(mood: mood) { s, closed in
            ZStack {
                Capsule().fill(Color(hex: "#5B5F6E")).frame(width: 88 * s, height: 7 * s).offset(y: 23 * s)
                RoundedRectangle(cornerRadius: 9 * s).fill(vgrad("#6EC6FF", "#2E8BE0"))
                    .frame(width: 56 * s, height: 50 * s).offset(x: 17 * s, y: -3 * s)
                VStack(spacing: 9 * s) {
                    ForEach(0..<3, id: \.self) { _ in
                        Capsule().fill(Color.white.opacity(0.35)).frame(width: 44 * s, height: 2.4 * s)
                    }
                }
                .offset(x: 17 * s, y: -3 * s)
                RoundedRectangle(cornerRadius: 11 * s).fill(vgrad("#FFB74D", "#F57C00"))
                    .frame(width: 36 * s, height: 42 * s).offset(x: -27 * s, y: 3 * s)
                FaceWindow(s: s, closed: closed, mood: mood, w: 24, h: 20).offset(x: -29 * s, y: -5 * s)
                Circle().fill(Color(hex: "#FFF59D")).frame(width: 6 * s).offset(x: -42 * s, y: 15 * s)
                Wheel(s: s, d: 19).offset(x: -27 * s, y: 30 * s)
                Wheel(s: s, d: 19).offset(x: 9 * s, y: 30 * s)
                Wheel(s: s, d: 19).offset(x: 31 * s, y: 30 * s)
            }
        }
    }
}

struct TractorCharacter: View {
    var mood: CharacterMood = .idle
    var body: some View {
        CharacterRig(mood: mood) { s, closed in
            ZStack {
                // exhaust puffs when happy
                if mood == .happy {
                    Circle().fill(Color(hex: "#E3E7EE")).frame(width: 9 * s).offset(x: -26 * s, y: -26 * s)
                    Circle().fill(Color(hex: "#EEF1F5")).frame(width: 12 * s).offset(x: -20 * s, y: -36 * s)
                }
                Capsule().fill(Color(hex: "#6B6F7C")).frame(width: 5 * s, height: 20 * s).offset(x: -26 * s, y: -9 * s)
                Capsule().fill(Color(hex: "#2E7D32")).frame(width: 46 * s, height: 7 * s).offset(x: 16 * s, y: -38 * s)
                RoundedRectangle(cornerRadius: 8 * s).fill(vgrad("#7BD46A", "#3FA545"))
                    .frame(width: 36 * s, height: 46 * s).offset(x: 16 * s, y: -13 * s)
                FaceWindow(s: s, closed: closed, mood: mood, w: 26, h: 24, eye: 9.5, round: 6).offset(x: 16 * s, y: -17 * s)
                RoundedRectangle(cornerRadius: 9 * s).fill(vgrad("#8EE07A", "#43A047"))
                    .frame(width: 52 * s, height: 24 * s).offset(x: -16 * s, y: 9 * s)
                VStack(spacing: 4 * s) {
                    ForEach(0..<3, id: \.self) { _ in
                        Capsule().fill(Color(hex: "#2E7D32").opacity(0.6)).frame(width: 7 * s, height: 2.2 * s)
                    }
                }
                .offset(x: -36 * s, y: 9 * s)
                Wheel(s: s, d: 38).offset(x: 20 * s, y: 22 * s)
                Wheel(s: s, d: 22).offset(x: -27 * s, y: 30 * s)
            }
        }
    }
}

struct TrainCharacter: View {
    var mood: CharacterMood = .idle
    var body: some View {
        CharacterRig(mood: mood) { s, closed in
            ZStack {
                // steam when happy
                if mood == .happy {
                    Circle().fill(Color(hex: "#EEF1F5")).frame(width: 12 * s).offset(x: -26 * s, y: -34 * s)
                    Circle().fill(Color(hex: "#F5F7FA")).frame(width: 16 * s).offset(x: -16 * s, y: -42 * s)
                }
                Capsule().fill(Color(hex: "#4A4E5C")).frame(width: 18 * s, height: 6 * s).offset(x: -30 * s, y: -24 * s)
                RoundedRectangle(cornerRadius: 3 * s).fill(Color(hex: "#5B5F6E")).frame(width: 11 * s, height: 16 * s).offset(x: -30 * s, y: -15 * s)
                Capsule().fill(Color(hex: "#5B5F6E")).frame(width: 90 * s, height: 7 * s).offset(y: 22 * s)
                Capsule().fill(vgrad("#64B5F6", "#1E88E5"))
                    .frame(width: 58 * s, height: 32 * s).offset(x: -16 * s, y: 5 * s)
                ForEach([-30.0, -14.0], id: \.self) { x in
                    Capsule().fill(Color(hex: "#FFD54F")).frame(width: 3.5 * s, height: 32 * s).offset(x: x * s, y: 5 * s)
                }
                RoundedRectangle(cornerRadius: 9 * s).fill(vgrad("#FF7B6E", "#E0322B"))
                    .frame(width: 38 * s, height: 56 * s).offset(x: 25 * s, y: -4 * s)
                Capsule().fill(Color(hex: "#8E1C1C")).frame(width: 46 * s, height: 7 * s).offset(x: 25 * s, y: -33 * s)
                FaceWindow(s: s, closed: closed, mood: mood, w: 26, h: 22).offset(x: 25 * s, y: -12 * s)
                RoundedTriangle().fill(Color(hex: "#FFC93C")).frame(width: 14 * s, height: 14 * s)
                    .rotationEffect(.degrees(-90)).offset(x: -45 * s, y: 20 * s)
                Wheel(s: s, d: 16).offset(x: -32 * s, y: 30 * s)
                Wheel(s: s, d: 16).offset(x: -12 * s, y: 30 * s)
                Wheel(s: s, d: 22).offset(x: 24 * s, y: 28 * s)
            }
        }
    }
}

struct RocketCharacter: View {
    var mood: CharacterMood = .idle
    private let red = Color(hex: "#F0435A")
    var body: some View {
        CharacterRig(mood: mood) { s, closed in
            ZStack {
                // flame grows when happy
                ZStack {
                    RoundedTriangle().fill(Color(hex: "#FF9F1C"))
                        .frame(width: 20 * s, height: (mood == .happy ? 26 : 16) * s)
                    RoundedTriangle().fill(Color(hex: "#FFE066"))
                        .frame(width: 11 * s, height: (mood == .happy ? 16 : 9) * s)
                }
                .rotationEffect(.degrees(180))
                .offset(y: (mood == .happy ? 44 : 39) * s)
                ForEach([-1.0, 1.0], id: \.self) { side in
                    RoundedTriangle().fill(red).frame(width: 22 * s, height: 26 * s)
                        .rotationEffect(.degrees(side * 18))
                        .offset(x: side * 21 * s, y: 22 * s)
                }
                Capsule()
                    .fill(LinearGradient(stops: [
                        .init(color: Color(hex: "#FF6B7D"), location: 0),
                        .init(color: red, location: 0.24),
                        .init(color: Color.white, location: 0.24),
                        .init(color: Color(hex: "#DCE3EE"), location: 1),
                    ], startPoint: .top, endPoint: .bottom))
                    .frame(width: 42 * s, height: 76 * s).offset(y: -3 * s)
                shine(s, x: -9, y: -14, w: 6, h: 22)
                Circle().fill(glass).frame(width: 16 * s)
                    .overlay(Circle().stroke(Color(hex: "#AEB8C4"), lineWidth: 2.6 * s))
                    .offset(y: -14 * s)
                KawaiiFace(s: s, closed: closed, mood: mood, eye: 10, gap: 5, mouthDrop: 8).offset(y: 6 * s)
                Capsule().fill(red).frame(width: 30 * s, height: 5 * s).offset(y: 27 * s)
            }
        }
    }
}

struct AirplaneCharacter: View {
    var mood: CharacterMood = .idle
    private let blue = Color(hex: "#2E8BE0")
    var body: some View {
        CharacterRig(mood: mood) { s, closed in
            ZStack {
                RoundedTriangle().fill(vgrad("#6EC6FF", "#2E8BE0")).frame(width: 22 * s, height: 30 * s)
                    .rotationEffect(.degrees(14)).offset(x: 36 * s, y: -15 * s)
                Ellipse().fill(Color(hex: "#1F6FBF")).frame(width: 40 * s, height: 10 * s)
                    .rotationEffect(.degrees(-12)).offset(x: 8 * s, y: -4 * s)
                Capsule().fill(vgrad("#FFFFFF", "#DFE7F2")).frame(width: 94 * s, height: 32 * s).offset(y: 4 * s)
                shine(s, x: -14, y: -6, w: 36, h: 5)
                Capsule().fill(blue).frame(width: 82 * s, height: 4 * s).offset(x: 4 * s, y: 13 * s)
                HStack(spacing: 4 * s) {
                    ForEach(0..<4, id: \.self) { _ in Circle().fill(glass).frame(width: 7 * s) }
                }
                .offset(x: 17 * s, y: 1 * s)
                KawaiiFace(s: s, closed: closed, mood: mood, eye: 9.5, gap: 5, mouthDrop: 8).offset(x: -27 * s, y: 0)
                Ellipse().fill(vgrad("#6EC6FF", "#2E8BE0")).frame(width: 48 * s, height: 13 * s)
                    .rotationEffect(.degrees(mood == .happy ? 24 : 14)).offset(x: 6 * s, y: 18 * s)
                if mood == .happy {
                    Circle().fill(Color.white.opacity(0.9)).frame(width: 9 * s).offset(x: 47 * s, y: 12 * s)
                    Circle().fill(Color.white.opacity(0.7)).frame(width: 6 * s).offset(x: 46 * s, y: 22 * s)
                }
            }
        }
    }
}

struct HelicopterCharacter: View {
    var mood: CharacterMood = .idle
    var body: some View {
        CharacterRig(mood: mood) { s, closed in
            ZStack {
                Capsule().fill(Color(hex: "#5B5F6E")).frame(width: 4 * s, height: 10 * s).offset(x: -6 * s, y: -32 * s)
                // rotor spins (shortens like a blur) when happy
                Capsule().fill(Color(hex: "#4A4E5C")).frame(width: (mood == .happy ? 70 : 92) * s, height: 5 * s).offset(x: -6 * s, y: -38 * s)
                if mood == .happy {
                    Capsule().fill(Color(hex: "#4A4E5C").opacity(0.35)).frame(width: 92 * s, height: 3 * s).offset(x: -6 * s, y: -38 * s)
                }
                Capsule().fill(vgrad("#FFB27A", "#F4511E")).frame(width: 46 * s, height: 11 * s).offset(x: 26 * s, y: -3 * s)
                Circle().stroke(Color(hex: "#4A4E5C"), lineWidth: 2.4 * s).frame(width: 15 * s).offset(x: 46 * s, y: -8 * s)
                Capsule().fill(Color(hex: "#4A4E5C")).frame(width: 3 * s, height: 12 * s).offset(x: -22 * s, y: 30 * s)
                Capsule().fill(Color(hex: "#4A4E5C")).frame(width: 3 * s, height: 12 * s).offset(x: 8 * s, y: 30 * s)
                Capsule().fill(Color(hex: "#4A4E5C")).frame(width: 62 * s, height: 5 * s).offset(x: -6 * s, y: 36 * s)
                Ellipse().fill(rgrad("#FFB27A", "#F4511E", s, r: 50)).frame(width: 62 * s, height: 52 * s).offset(x: -8 * s, y: 2 * s)
                shine(s, x: -18, y: -16, w: 16, h: 6)
                Ellipse().fill(glass).frame(width: 36 * s, height: 28 * s).offset(x: -16 * s, y: 0)
                Ellipse().stroke(Color.white.opacity(0.8), lineWidth: 1.6 * s).frame(width: 36 * s, height: 28 * s).offset(x: -16 * s, y: 0)
                KawaiiFace(s: s, closed: closed, mood: mood, eye: 10, gap: 6, mouthDrop: 8.5, cheeks: false).offset(x: -16 * s, y: -3 * s)
            }
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - Food (faces right on the food)
// ─────────────────────────────────────────────

private struct AppleShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: r.u(0.5, 0.16))
        p.addCurve(to: r.u(0, 0.45), control1: r.u(0.32, 0), control2: r.u(0, 0.06))
        p.addCurve(to: r.u(0.5, 1), control1: r.u(0, 0.85), control2: r.u(0.3, 1.02))
        p.addCurve(to: r.u(1, 0.45), control1: r.u(0.7, 1.02), control2: r.u(1, 0.85))
        p.addCurve(to: r.u(0.5, 0.16), control1: r.u(1, 0.06), control2: r.u(0.68, 0))
        p.closeSubpath()
        return p
    }
}

private struct Leaf: View {
    var s: CGFloat
    var w: CGFloat = 20
    var body: some View {
        Ellipse().fill(vgrad("#8EE07A", "#43A047"))
            .overlay(Capsule().fill(Color(hex: "#2E7D32").opacity(0.5)).frame(width: w * 0.7 * s, height: 1.4 * s))
            .frame(width: w * s, height: w * 0.5 * s)
    }
}

struct AppleCharacter: View {
    var mood: CharacterMood = .idle
    var body: some View {
        CharacterRig(mood: mood) { s, closed in
            ZStack {
                Capsule().fill(Color(hex: "#7E4B2C")).frame(width: 5 * s, height: 15 * s)
                    .rotationEffect(.degrees(10)).offset(x: 1 * s, y: -33 * s)
                Leaf(s: s).rotationEffect(.degrees(mood == .happy ? -40 : -25)).offset(x: 12 * s, y: -36 * s)
                AppleShape().fill(rgrad("#FF7A70", "#D9262B", s)).frame(width: 82 * s, height: 74 * s).offset(y: 5 * s)
                shine(s, x: -20, y: -12)
                KawaiiFace(s: s, closed: closed, mood: mood, eye: 14, gap: 13).offset(y: 6 * s)
            }
        }
    }
}

private struct BananaShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: r.u(0.04, 0.22))
        p.addCurve(to: r.u(0.96, 0.24), control1: r.u(0.2, 1.08), control2: r.u(0.8, 1.08))
        p.addCurve(to: r.u(0.04, 0.22), control1: r.u(0.72, 0.54), control2: r.u(0.28, 0.52))
        p.closeSubpath()
        return p
    }
}

private struct BananaRidge: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: r.u(0.2, 0.62))
        p.addCurve(to: r.u(0.82, 0.6), control1: r.u(0.36, 0.86), control2: r.u(0.66, 0.86))
        return p
    }
}

struct BananaCharacter: View {
    var mood: CharacterMood = .idle
    var body: some View {
        CharacterRig(mood: mood) { s, closed in
            ZStack {
                ZStack {
                    BananaShape().fill(vgrad("#FFF07A", "#FFC928"))
                    BananaShape().stroke(Color(hex: "#E8B21A"), lineWidth: 1.6 * s)
                    BananaRidge().stroke(Color(hex: "#F2C21F"), style: StrokeStyle(lineWidth: 2 * s, lineCap: .round))
                }
                .frame(width: 94 * s, height: 80 * s)
                .rotationEffect(.degrees(-10))
                .offset(y: 2 * s)
                Capsule().fill(Color(hex: "#7E5A2C")).frame(width: 6 * s, height: 10 * s)
                    .rotationEffect(.degrees(-40)).offset(x: 42 * s, y: -30 * s)
                Circle().fill(Color(hex: "#5D4037")).frame(width: 5 * s).offset(x: -45 * s, y: -12 * s)
                KawaiiFace(s: s, closed: closed, mood: mood, eye: 12, gap: 11, mouthDrop: 9).offset(x: -2 * s, y: 12 * s)
            }
            .rotationEffect(.degrees(mood == .happy ? -6 : 0))
        }
    }
}

struct MilkCharacter: View {
    var mood: CharacterMood = .idle
    private let line = Color(hex: "#C9D6E6")
    var body: some View {
        CharacterRig(mood: mood) { s, closed in
            ZStack {
                Capsule().fill(Color.white).overlay(Capsule().stroke(line, lineWidth: 2 * s))
                    .frame(width: 22 * s, height: 7 * s).offset(y: -39 * s)
                RoundedTriangle().fill(vgrad("#FFFFFF", "#E8F1FB")).frame(width: 58 * s, height: 26 * s).offset(y: -26 * s)
                RoundedTriangle().stroke(line, lineWidth: 2 * s).frame(width: 58 * s, height: 26 * s).offset(y: -26 * s)
                ZStack(alignment: .bottom) {
                    vgrad("#FFFFFF", "#E8F1FB")
                    vgrad("#6EC6FF", "#2E8BE0").frame(height: 20 * s)
                }
                .frame(width: 56 * s, height: 62 * s)
                .clipShape(RoundedRectangle(cornerRadius: 9 * s))
                .offset(y: 9 * s)
                RoundedRectangle(cornerRadius: 9 * s).stroke(line, lineWidth: 2 * s).frame(width: 56 * s, height: 62 * s).offset(y: 9 * s)
                Image(systemName: "drop.fill").font(.system(size: 10 * s)).foregroundStyle(Color.white).offset(y: 30 * s)
                KawaiiFace(s: s, closed: closed, mood: mood, eye: 12, gap: 10).offset(y: 0)
            }
        }
    }
}

struct BreadCharacter: View {
    var mood: CharacterMood = .idle
    private let crust = Color(hex: "#D9893E"), crumb = Color(hex: "#FFE7B3")
    var body: some View {
        CharacterRig(mood: mood) { s, closed in
            ZStack {
                Ellipse().fill(crust).frame(width: 86 * s, height: 42 * s).offset(y: -18 * s)
                RoundedRectangle(cornerRadius: 10 * s).fill(crust).frame(width: 72 * s, height: 54 * s).offset(y: 11 * s)
                Ellipse().fill(crumb).frame(width: 76 * s, height: 33 * s).offset(y: -17 * s)
                RoundedRectangle(cornerRadius: 7 * s).fill(crumb).frame(width: 63 * s, height: 49 * s).offset(y: 9 * s)
                if mood == .happy {   // a pat of butter
                    RoundedRectangle(cornerRadius: 3 * s).fill(vgrad("#FFF59D", "#FFE04D"))
                        .frame(width: 20 * s, height: 12 * s).rotationEffect(.degrees(-8)).offset(y: -22 * s)
                }
                KawaiiFace(s: s, closed: closed, mood: mood, eye: 13, gap: 12).offset(y: 4 * s)
            }
        }
    }
}

private struct EggShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: r.u(0.5, 0))
        p.addCurve(to: r.u(1, 0.62), control1: r.u(0.82, 0), control2: r.u(1, 0.32))
        p.addCurve(to: r.u(0.5, 1), control1: r.u(1, 0.86), control2: r.u(0.78, 1))
        p.addCurve(to: r.u(0, 0.62), control1: r.u(0.22, 1), control2: r.u(0, 0.86))
        p.addCurve(to: r.u(0.5, 0), control1: r.u(0, 0.32), control2: r.u(0.18, 0))
        p.closeSubpath()
        return p
    }
}

struct EggCharacter: View {
    var mood: CharacterMood = .idle
    var body: some View {
        CharacterRig(mood: mood) { s, closed in
            ZStack {
                EggShape().fill(rgrad("#FFFFFF", "#F2E2CB", s)).frame(width: 62 * s, height: 80 * s).offset(y: 1 * s)
                EggShape().stroke(Color(hex: "#E6D2B5"), lineWidth: 2 * s).frame(width: 62 * s, height: 80 * s).offset(y: 1 * s)
                shine(s, x: -12, y: -20, w: 12, h: 18)
                KawaiiFace(s: s, closed: closed, mood: mood, eye: 13, gap: 10).offset(y: 10 * s)
            }
            .rotationEffect(.degrees(mood == .happy ? 6 : 0))
        }
    }
}

struct OrangeCharacter: View {
    var mood: CharacterMood = .idle
    private let dots: [(CGFloat, CGFloat)] = [(-24, -14), (22, -18), (-30, 12), (30, 8), (-14, 28), (18, 28), (4, -26)]
    var body: some View {
        CharacterRig(mood: mood) { s, closed in
            ZStack {
                Circle().fill(rgrad("#FFC86B", "#FF8A1F", s)).frame(width: 78 * s).offset(y: 4 * s)
                ForEach(0..<dots.count, id: \.self) { i in
                    Circle().fill(Color(hex: "#F07A10").opacity(0.45)).frame(width: 2.6 * s)
                        .offset(x: dots[i].0 * s, y: (dots[i].1 + 4) * s)
                }
                shine(s, x: -18, y: -16)
                Capsule().fill(Color(hex: "#6D8B3A")).frame(width: 4 * s, height: 8 * s).offset(y: -35 * s)
                Leaf(s: s, w: 22).rotationEffect(.degrees(mood == .happy ? -35 : -20)).offset(x: 12 * s, y: -37 * s)
                KawaiiFace(s: s, closed: closed, mood: mood, eye: 14, gap: 13).offset(y: 4 * s)
            }
        }
    }
}

private struct BerryShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: r.u(0.5, 1))
        p.addCurve(to: r.u(0, 0.25), control1: r.u(0.16, 0.95), control2: r.u(0, 0.6))
        p.addCurve(to: r.u(0.5, 0.04), control1: r.u(0, 0.04), control2: r.u(0.25, 0.02))
        p.addCurve(to: r.u(1, 0.25), control1: r.u(0.75, 0.02), control2: r.u(1, 0.04))
        p.addCurve(to: r.u(0.5, 1), control1: r.u(1, 0.6), control2: r.u(0.84, 0.95))
        p.closeSubpath()
        return p
    }
}

struct StrawberryCharacter: View {
    var mood: CharacterMood = .idle
    private let seeds: [(CGFloat, CGFloat)] = [(-26, -12), (26, -12), (-30, 6), (30, 6), (-18, 22), (18, 22), (0, 32), (-8, 26), (8, 26)]
    var body: some View {
        CharacterRig(mood: mood) { s, closed in
            ZStack {
                BerryShape().fill(rgrad("#FF7B88", "#E2263F", s)).frame(width: 76 * s, height: 82 * s).offset(y: 3 * s)
                ForEach(0..<seeds.count, id: \.self) { i in
                    Ellipse().fill(Color(hex: "#FFE27A")).frame(width: 2.8 * s, height: 4.2 * s)
                        .offset(x: seeds[i].0 * s, y: seeds[i].1 * s)
                }
                shine(s, x: -18, y: -18, w: 18, h: 8)
                ForEach([-50.0, -25.0, 0.0, 25.0, 50.0], id: \.self) { a in
                    Ellipse().fill(Color(hex: "#43A047")).frame(width: 10 * s, height: 22 * s)
                        .offset(y: -9 * s)
                        .rotationEffect(.degrees(a * (mood == .happy ? 1.3 : 1)))
                        .offset(y: -32 * s)
                }
                Capsule().fill(Color(hex: "#2E7D32")).frame(width: 4 * s, height: 10 * s).offset(y: -42 * s)
                KawaiiFace(s: s, closed: closed, mood: mood, eye: 13, gap: 11).offset(y: 0)
            }
        }
    }
}

private struct CarrotShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: r.u(0.5, 1))
        p.addCurve(to: r.u(0, 0.15), control1: r.u(0.34, 0.92), control2: r.u(0, 0.45))
        p.addCurve(to: r.u(1, 0.15), control1: r.u(0, -0.05), control2: r.u(1, -0.05))
        p.addCurve(to: r.u(0.5, 1), control1: r.u(1, 0.45), control2: r.u(0.66, 0.92))
        p.closeSubpath()
        return p
    }
}

struct CarrotCharacter: View {
    var mood: CharacterMood = .idle
    var body: some View {
        CharacterRig(mood: mood) { s, closed in
            ZStack {
                ForEach([-28.0, 0.0, 28.0], id: \.self) { a in
                    Capsule().fill(vgrad("#8EE07A", "#43A047")).frame(width: 9 * s, height: 28 * s)
                        .offset(y: -12 * s)
                        .rotationEffect(.degrees(a * (mood == .happy ? 1.4 : 1)))
                        .offset(y: -26 * s)
                }
                CarrotShape().fill(LinearGradient(colors: [Color(hex: "#FFB24D"), Color(hex: "#F57C00")], startPoint: .leading, endPoint: .trailing))
                    .frame(width: 56 * s, height: 78 * s).offset(y: 6 * s)
                ForEach([(-14.0, 16.0), (12.0, 24.0), (-6.0, 32.0)], id: \.0) { pos in
                    Capsule().fill(Color(hex: "#E06A00").opacity(0.6)).frame(width: 10 * s, height: 2.4 * s)
                        .offset(x: pos.0 * s, y: pos.1 * s)
                }
                shine(s, x: -12, y: -18, w: 10, h: 16)
                KawaiiFace(s: s, closed: closed, mood: mood, eye: 11, gap: 8, mouthDrop: 9).offset(y: -9 * s)
            }
        }
    }
}

struct CakeCharacter: View {
    var mood: CharacterMood = .idle
    var body: some View {
        CharacterRig(mood: mood) { s, closed in
            ZStack {
                // candle
                ZStack {
                    Ellipse().fill(Color(hex: "#FF9F1C")).frame(width: (mood == .happy ? 11 : 8) * s, height: (mood == .happy ? 17 : 12) * s)
                    Ellipse().fill(Color(hex: "#FFE066")).frame(width: 4 * s, height: 7 * s).offset(y: 2 * s)
                }
                .offset(y: -36 * s)
                RoundedRectangle(cornerRadius: 2 * s).fill(vgrad("#8EC5FF", "#4FA8F7")).frame(width: 7 * s, height: 18 * s).offset(y: -21 * s)
                Capsule().fill(Color(hex: "#E9EDF3")).frame(width: 88 * s, height: 9 * s).offset(y: 37 * s)
                RoundedRectangle(cornerRadius: 11 * s).fill(vgrad("#FFB3CC", "#F06E9C"))
                    .frame(width: 74 * s, height: 46 * s).offset(y: 13 * s)
                RoundedRectangle(cornerRadius: 9 * s).fill(Color(hex: "#FFF8FB")).frame(width: 78 * s, height: 15 * s).offset(y: -8 * s)
                ForEach([-26.0, -9.0, 9.0, 26.0], id: \.self) { x in
                    Capsule().fill(Color(hex: "#FFF8FB")).frame(width: 8 * s, height: (x == -9 || x == 26 ? 15 : 11) * s)
                        .offset(x: x * s, y: 0)
                }
                ForEach([(-24.0, "#FF6B6B"), (-6.0, "#4FA8F7"), (12.0, "#FFC93C"), (28.0, "#43C35E")], id: \.0) { pos in
                    Capsule().fill(Color(hex: pos.1)).frame(width: 5 * s, height: 2 * s)
                        .rotationEffect(.degrees(pos.0 > 0 ? 30 : -30)).offset(x: pos.0 * s, y: -10 * s)
                }
                KawaiiFace(s: s, closed: closed, mood: mood, eye: 12, gap: 12, mouthDrop: 9).offset(y: 16 * s)
            }
        }
    }
}

struct GrapesCharacter: View {
    var mood: CharacterMood = .idle
    private let grapes: [(CGFloat, CGFloat)] = [
        (-20, -24), (0, -24), (20, -24),
        (-30, -6), (-10, -6), (10, -6), (30, -6),
        (-20, 12), (0, 12), (20, 12),
        (-10, 28), (10, 28),
    ]
    var body: some View {
        CharacterRig(mood: mood) { s, closed in
            ZStack {
                Capsule().fill(Color(hex: "#7E5A2C")).frame(width: 4 * s, height: 12 * s).offset(y: -39 * s)
                Leaf(s: s, w: 24).rotationEffect(.degrees(mood == .happy ? -30 : -15)).offset(x: 14 * s, y: -38 * s)
                ForEach(0..<grapes.count, id: \.self) { i in
                    ZStack {
                        Circle().fill(rgrad("#C79BF0", "#7B3FB5", s, r: 16))
                        Circle().fill(Color.white.opacity(0.45)).frame(width: 6 * s).offset(x: -4 * s, y: -4 * s)
                    }
                    .frame(width: 24 * s, height: 24 * s)
                    .offset(x: grapes[i].0 * s, y: grapes[i].1 * s)
                }
                ZStack {
                    Circle().fill(rgrad("#D2AAF5", "#8A4CC6", s, r: 26))
                    Circle().fill(Color.white.opacity(0.45)).frame(width: 9 * s).offset(x: -10 * s, y: -10 * s)
                }
                .frame(width: 40 * s, height: 40 * s)
                .offset(y: 0)
                KawaiiFace(s: s, closed: closed, mood: mood, eye: 11, gap: 7, mouthDrop: 8.5).offset(y: -1 * s)
            }
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - Colours: a cheerful paint drop in each colour
// ─────────────────────────────────────────────

struct PaintColor {
    let base: Color
    let light: Color
    var outline: Color? = nil
    var lightInk = false

    static let all: [String: PaintColor] = [
        "red": PaintColor(base: Color(hex: "#EE3B3B"), light: Color(hex: "#FF8A80")),
        "blue": PaintColor(base: Color(hex: "#2F7FF0"), light: Color(hex: "#8EC5FF")),
        "green": PaintColor(base: Color(hex: "#34B553"), light: Color(hex: "#9BE7A6")),
        "yellow": PaintColor(base: Color(hex: "#FFD12E"), light: Color(hex: "#FFF3A6"), outline: Color(hex: "#E8B91A")),
        "orange": PaintColor(base: Color(hex: "#FF8A1F"), light: Color(hex: "#FFC78A")),
        "purple": PaintColor(base: Color(hex: "#8E4FD9"), light: Color(hex: "#CDB0F5")),
        "pink": PaintColor(base: Color(hex: "#FF6FAE"), light: Color(hex: "#FFC2DD")),
        "white": PaintColor(base: Color(hex: "#F1F3F7"), light: Color.white, outline: Color(hex: "#C9D0DA")),
        "black": PaintColor(base: Color(hex: "#24242C"), light: Color(hex: "#5A5A66"), lightInk: true),
        "brown": PaintColor(base: Color(hex: "#86543A"), light: Color(hex: "#C08B63"), lightInk: true),
    ]
}

private struct DropShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: r.u(0.5, 0))
        p.addCurve(to: r.u(1, 0.64), control1: r.u(0.62, 0.2), control2: r.u(1, 0.38))
        p.addCurve(to: r.u(0.5, 1), control1: r.u(1, 0.86), control2: r.u(0.78, 1))
        p.addCurve(to: r.u(0, 0.64), control1: r.u(0.22, 1), control2: r.u(0, 0.86))
        p.addCurve(to: r.u(0.5, 0), control1: r.u(0, 0.38), control2: r.u(0.38, 0.2))
        p.closeSubpath()
        return p
    }
}

struct PaintDropCharacter: View {
    var mood: CharacterMood = .idle
    let paint: PaintColor

    var body: some View {
        CharacterRig(mood: mood) { s, closed in
            ZStack {
                // little splashes jump out when happy
                ForEach([(-38.0, 30.0, 9.0), (38.0, 22.0, 7.0), (31.0, 36.0, 5.0)], id: \.0) { d in
                    Circle().fill(paint.base)
                        .overlay(paint.outline.map { Circle().stroke($0, lineWidth: 1.4 * s) })
                        .frame(width: d.2 * s)
                        .offset(x: d.0 * s * (mood == .happy ? 1.12 : 1), y: (d.1 - (mood == .happy ? 6 : 0)) * s)
                }
                DropShape()
                    .fill(RadialGradient(colors: [paint.light, paint.base], center: UnitPoint(x: 0.36, y: 0.5), startRadius: 2 * s, endRadius: 50 * s))
                    .frame(width: 66 * s, height: 84 * s).offset(y: 1 * s)
                if let o = paint.outline {
                    DropShape().stroke(o, lineWidth: 2.2 * s).frame(width: 66 * s, height: 84 * s).offset(y: 1 * s)
                }
                shine(s, x: -14, y: -4, w: 10, h: 18)
                KawaiiFace(s: s, closed: closed, mood: mood, eye: 15, gap: 11, mouthDrop: 13,
                           ink: paint.lightInk ? Color.white : Ink.dark)
                    .offset(y: 12 * s)
            }
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - Numbers: a big friendly numeral and dots to count
// ─────────────────────────────────────────────

struct NumberBuddy: View {
    var mood: CharacterMood = .idle
    let n: Int

    static let words: [String: Int] = ["one": 1, "two": 2, "three": 3, "four": 4, "five": 5,
                                       "six": 6, "seven": 7, "eight": 8, "nine": 9, "ten": 10]
    private static let palette: [(String, String)] = [
        ("#6EC6FF", "#1E88E5"), ("#8EE07A", "#2E9E44"), ("#FFC266", "#F57C00"), ("#D1A6F5", "#8E4FD9"), ("#FFE36E", "#F2A900"),
        ("#FF9EC4", "#E0407F"), ("#7EE3EF", "#00A3B5"), ("#B5A8F5", "#5E4FD9"), ("#FF8A80", "#E0322B"), ("#FFC98A", "#C46A1C"),
    ]

    var body: some View {
        let colors = Self.palette[(n - 1) % Self.palette.count]
        let light = Color(hex: colors.0), base = Color(hex: colors.1)
        CharacterRig(mood: mood) { s, closed in
            ZStack {
                Text("\(n)")
                    .font(.system(size: 66 * s, weight: .black, design: .rounded))
                    .foregroundStyle(LinearGradient(colors: [light, base], startPoint: .top, endPoint: .bottom))
                    .shadow(color: base.opacity(0.45), radius: 0, x: 0, y: 3 * s)
                    .shadow(color: .white, radius: 0, x: 0, y: -1.5 * s)
                    .offset(y: -14 * s)
                // eyes peek over the numeral
                HStack(spacing: 3 * s) {
                    CuteEye(closed: closed, s: s, size: 9)
                    CuteEye(closed: closed, s: s, size: 9)
                }
                .offset(x: n == 1 ? 2 * s : (n == 10 ? 9 * s : 0), y: -31 * s)
                dots(s, base: base, light: light)
            }
        }
    }

    private func dots(_ s: CGFloat, base: Color, light: Color) -> some View {
        let rows = n <= 5 ? [n] : [5, n - 5]
        let d: CGFloat = n <= 5 ? 11 : 9.5
        return VStack(spacing: 3 * s) {
            ForEach(0..<rows.count, id: \.self) { r in
                HStack(spacing: 3.5 * s) {
                    ForEach(0..<rows[r], id: \.self) { _ in
                        Circle().fill(RadialGradient(colors: [light, base], center: UnitPoint(x: 0.35, y: 0.3), startRadius: 0, endRadius: d * 0.7 * s))
                            .frame(width: d * s, height: d * s)
                            .scaleEffect(mood == .happy ? 1.18 : 1)
                    }
                }
            }
        }
        .padding(.horizontal, 5 * s)
        .padding(.vertical, 4 * s)
        .background(Capsule().fill(light.opacity(0.28)))
        .offset(y: (n <= 5 ? 30 : 28) * s)
    }
}

// ─────────────────────────────────────────────
// MARK: - Body parts
// ─────────────────────────────────────────────

private enum Skin {
    static let light = Color(hex: "#FAD3B4")
    static let base = Color(hex: "#F2B48C")
    static let shade = Color(hex: "#DE946C")
    static let line = Color(hex: "#C47A55")
}

struct EyesCharacter: View {
    var mood: CharacterMood = .idle
    var body: some View {
        CharacterRig(mood: mood) { s, closed in
            ZStack {
                ForEach([-1.0, 1.0], id: \.self) { side in
                    Capsule().fill(Color(hex: "#6D4C41")).frame(width: 24 * s, height: 5 * s)
                        .rotationEffect(.degrees(side * (mood == .happy ? 14 : 6)))
                        .offset(x: side * 22 * s, y: (mood == .happy ? -32 : -29) * s)
                }
                HStack(spacing: 10 * s) {
                    ZStack {
                        CuteEye(closed: closed, s: s, size: 34)
                        if !closed { lashes(s, side: -1) }
                    }
                    ZStack {
                        CuteEye(closed: closed, s: s, size: 34)
                        if !closed { lashes(s, side: 1) }
                    }
                }
                .offset(y: 2 * s)
                HStack(spacing: 34 * s) {
                    Ellipse().fill(Ink.blush.opacity(0.45)).frame(width: 18 * s, height: 9 * s)
                    Ellipse().fill(Ink.blush.opacity(0.45)).frame(width: 18 * s, height: 9 * s)
                }
                .offset(y: 28 * s)
            }
        }
    }

    private func lashes(_ s: CGFloat, side: CGFloat) -> some View {
        ZStack {
            ForEach([0.0, 1.0], id: \.self) { i in
                Capsule().fill(Ink.dark).frame(width: 3 * s, height: 8 * s)
                    .rotationEffect(.degrees(side * (30 + i * 25)))
                    .offset(x: side * (13 + i * 4) * s, y: (-17 + i * 5) * s)
            }
        }
    }
}

struct NoseCharacter: View {
    var mood: CharacterMood = .idle
    var body: some View {
        CharacterRig(mood: mood) { s, _ in
            ZStack {
                Capsule().fill(Skin.base).frame(width: 26 * s, height: 56 * s).offset(y: -12 * s)
                ForEach([-1.0, 1.0], id: \.self) { side in
                    Circle().fill(Skin.base).frame(width: 26 * s).offset(x: side * 19 * s, y: 17 * s)
                }
                Ellipse().fill(Skin.base).frame(width: 40 * s, height: 34 * s).offset(y: 10 * s)
                Ellipse().fill(Skin.light).frame(width: 9 * s, height: 30 * s).offset(x: -4 * s, y: -14 * s)
                Ellipse().fill(Skin.light).frame(width: 14 * s, height: 9 * s).offset(x: -5 * s, y: 4 * s)
                ForEach([-1.0, 1.0], id: \.self) { side in
                    Ellipse().fill(Skin.line).frame(width: 9 * s, height: (mood == .happy ? 7 : 5) * s)
                        .rotationEffect(.degrees(side * 20))
                        .offset(x: side * 9 * s, y: 23 * s)
                    ArcUp().stroke(Skin.shade, style: StrokeStyle(lineWidth: 2.2 * s, lineCap: .round))
                        .frame(width: 14 * s, height: 6 * s)
                        .rotationEffect(.degrees(side * 60))
                        .offset(x: side * 23 * s, y: 13 * s)
                }
                if mood == .happy {
                    Image(systemName: "sparkle").font(.system(size: 13 * s, weight: .bold)).foregroundStyle(Color(hex: "#FFC93C"))
                        .offset(x: 28 * s, y: -24 * s)
                }
            }
        }
    }
}

struct MouthCharacter: View {
    var mood: CharacterMood = .idle
    private let lip = Color(hex: "#F2546B")
    var body: some View {
        CharacterRig(mood: mood) { s, _ in
            let h: CGFloat = mood == .happy ? 46 : 38
            ZStack {
                ZStack(alignment: .top) {
                    Color(hex: "#7E1E33")
                    RoundedRectangle(cornerRadius: 3 * s).fill(Color.white).frame(width: 46 * s, height: 11 * s)
                    HStack(spacing: 0) {
                        ForEach(0..<3, id: \.self) { _ in
                            Rectangle().fill(Color(hex: "#E3E8F0")).frame(width: 1 * s, height: 11 * s).frame(width: 15 * s)
                        }
                    }
                    Ellipse().fill(Color(hex: "#FF7A93")).frame(width: 34 * s, height: 18 * s).offset(y: (h * 0.8 - 12) * s)
                }
                .frame(width: 70 * s, height: h * s)
                .clipShape(ArcDown())
                ArcDown().stroke(lip, style: StrokeStyle(lineWidth: 7 * s, lineCap: .round)).frame(width: 70 * s, height: h * s)
                Capsule().fill(lip).frame(width: 76 * s, height: 7 * s).offset(y: -h / 2 * s)
                ForEach([-1.0, 1.0], id: \.self) { side in
                    Ellipse().fill(Ink.blush.opacity(0.45)).frame(width: 14 * s, height: 8 * s).offset(x: side * 40 * s, y: (-h / 2 - 6) * s)
                }
            }
            .offset(y: -2 * s)
        }
    }
}

private struct EarShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: r.u(0.5, 0))
        p.addCurve(to: r.u(1, 0.4), control1: r.u(0.82, 0), control2: r.u(1, 0.18))
        p.addCurve(to: r.u(0.58, 0.98), control1: r.u(1, 0.68), control2: r.u(0.78, 0.92))
        p.addCurve(to: r.u(0.22, 0.86), control1: r.u(0.4, 1.03), control2: r.u(0.26, 0.98))
        p.addCurve(to: r.u(0.04, 0.36), control1: r.u(0.16, 0.66), control2: r.u(0, 0.56))
        p.addCurve(to: r.u(0.5, 0), control1: r.u(0.08, 0.1), control2: r.u(0.28, 0))
        p.closeSubpath()
        return p
    }
}

/// The curl just inside the rim of the ear.
private struct HelixShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: r.u(0.26, 0.34))
        p.addCurve(to: r.u(0.74, 0.3), control1: r.u(0.3, 0.12), control2: r.u(0.66, 0.1))
        p.addCurve(to: r.u(0.66, 0.66), control1: r.u(0.84, 0.46), control2: r.u(0.76, 0.58))
        p.addCurve(to: r.u(0.5, 0.78), control1: r.u(0.58, 0.72), control2: r.u(0.52, 0.72))
        return p
    }
}

struct EarCharacter: View {
    var mood: CharacterMood = .idle
    var body: some View {
        CharacterRig(mood: mood) { s, _ in
            ZStack {
                EarShape().fill(rgrad("#FAD3B4", "#EBA77E", s, r: 50)).frame(width: 58 * s, height: 80 * s)
                Ellipse().fill(Skin.shade.opacity(0.55)).frame(width: 20 * s, height: 26 * s).offset(x: -1 * s, y: 2 * s)
                HelixShape().stroke(Skin.shade, style: StrokeStyle(lineWidth: 6 * s, lineCap: .round))
                    .frame(width: 58 * s, height: 80 * s)
                Ellipse().fill(Ink.blush.opacity(0.4)).frame(width: 13 * s, height: 9 * s).offset(x: 2 * s, y: 30 * s)
                shine(s, x: -10, y: -28, w: 14, h: 6)
                if mood == .happy {   // listening to music
                    Image(systemName: "music.note").font(.system(size: 16 * s, weight: .bold)).foregroundStyle(Color(hex: "#8E4FD9"))
                        .offset(x: 36 * s, y: -26 * s)
                    Image(systemName: "music.note").font(.system(size: 11 * s, weight: .bold)).foregroundStyle(Color(hex: "#2F7FF0"))
                        .offset(x: 40 * s, y: -6 * s)
                }
            }
            .rotationEffect(.degrees(mood == .happy ? -8 : 0))
        }
    }
}

struct HandCharacter: View {
    var mood: CharacterMood = .idle
    private let fingers: [(x: CGFloat, y: CGFloat, h: CGFloat)] = [(-14, -14, 30), (-2, -19, 36), (10, -17, 34), (21, -11, 28)]
    var body: some View {
        CharacterRig(mood: mood) { s, _ in
            ZStack {
                ForEach(0..<fingers.count, id: \.self) { i in
                    Capsule().fill(Skin.base).frame(width: 11.5 * s, height: fingers[i].h * s)
                        .offset(x: fingers[i].x * s, y: fingers[i].y * s)
                    Ellipse().fill(Skin.light).frame(width: 6 * s, height: 7 * s)
                        .offset(x: fingers[i].x * s, y: (fingers[i].y - fingers[i].h / 2 + 6) * s)
                }
                Capsule().fill(Skin.base).frame(width: 13 * s, height: 30 * s)
                    .rotationEffect(.degrees(-50)).offset(x: -24 * s, y: 12 * s)
                RoundedRectangle(cornerRadius: 18 * s).fill(Skin.base).frame(width: 46 * s, height: 44 * s).offset(x: 3 * s, y: 14 * s)
                ArcDown().stroke(Skin.shade, style: StrokeStyle(lineWidth: 2 * s, lineCap: .round))
                    .frame(width: 20 * s, height: 5 * s).rotationEffect(.degrees(-20)).offset(x: 2 * s, y: 18 * s)
                Capsule().fill(Skin.base).frame(width: 26 * s, height: 16 * s).offset(x: 4 * s, y: 36 * s)
                Ellipse().fill(Skin.light.opacity(0.8)).frame(width: 14 * s, height: 9 * s).offset(x: -6 * s, y: 6 * s)
            }
            .rotationEffect(.degrees(mood == .happy ? -16 : 0), anchor: .bottom)
        }
    }
}

struct FootCharacter: View {
    var mood: CharacterMood = .idle
    private let toes: [(x: CGFloat, y: CGFloat, d: CGFloat)] = [(-11, -30, 17), (4, -33, 12.5), (14.5, -30, 11.5), (22.5, -24, 10.5), (28, -16, 9.5)]
    var body: some View {
        CharacterRig(mood: mood) { s, _ in
            ZStack {
                Ellipse().fill(Skin.base).frame(width: 48 * s, height: 66 * s).offset(x: 2 * s, y: 6 * s)
                Ellipse().fill(Skin.base).frame(width: 34 * s, height: 30 * s).offset(x: 12 * s, y: -10 * s)
                Ellipse().fill(Skin.light.opacity(0.85)).frame(width: 22 * s, height: 26 * s).offset(x: 0, y: 22 * s)
                Ellipse().fill(Skin.light.opacity(0.85)).frame(width: 26 * s, height: 16 * s).offset(x: 4 * s, y: -10 * s)
                ForEach(0..<toes.count, id: \.self) { i in
                    Circle().fill(Skin.base).frame(width: toes[i].d * s)
                        .overlay(Ellipse().fill(Skin.light).frame(width: toes[i].d * 0.45 * s, height: toes[i].d * 0.35 * s).offset(y: -toes[i].d * 0.15 * s))
                        .offset(x: toes[i].x * s, y: (toes[i].y - (mood == .happy && i.isMultiple(of: 2) ? 3 : 0)) * s)
                }
            }
        }
    }
}

private struct ToothShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: r.u(0.12, 0.15))
        p.addCurve(to: r.u(0.5, 0.08), control1: r.u(0.25, 0), control2: r.u(0.38, 0.02))
        p.addCurve(to: r.u(0.88, 0.15), control1: r.u(0.62, 0.02), control2: r.u(0.75, 0))
        p.addCurve(to: r.u(0.85, 0.65), control1: r.u(1.02, 0.35), control2: r.u(0.95, 0.5))
        p.addCurve(to: r.u(0.7, 1), control1: r.u(0.8, 0.8), control2: r.u(0.78, 1))
        p.addCurve(to: r.u(0.5, 0.72), control1: r.u(0.6, 1), control2: r.u(0.6, 0.72))
        p.addCurve(to: r.u(0.3, 1), control1: r.u(0.4, 0.72), control2: r.u(0.4, 1))
        p.addCurve(to: r.u(0.15, 0.65), control1: r.u(0.22, 1), control2: r.u(0.2, 0.8))
        p.addCurve(to: r.u(0.12, 0.15), control1: r.u(0.05, 0.5), control2: r.u(-0.02, 0.35))
        p.closeSubpath()
        return p
    }
}

struct ToothCharacter: View {
    var mood: CharacterMood = .idle
    var body: some View {
        CharacterRig(mood: mood) { s, closed in
            ZStack {
                ToothShape().fill(rgrad("#FFFFFF", "#E3EBF5", s)).frame(width: 70 * s, height: 82 * s).offset(y: 1 * s)
                ToothShape().stroke(Color(hex: "#C7D3E3"), lineWidth: 2.2 * s).frame(width: 70 * s, height: 82 * s).offset(y: 1 * s)
                shine(s, x: -16, y: -26, w: 16, h: 7)
                KawaiiFace(s: s, closed: closed, mood: mood, eye: 13, gap: 11).offset(y: -8 * s)
                Image(systemName: "sparkle").font(.system(size: (mood == .happy ? 18 : 12) * s, weight: .bold))
                    .foregroundStyle(Color(hex: "#7CCBF2")).offset(x: 33 * s, y: -32 * s)
            }
        }
    }
}

struct TongueCharacter: View {
    var mood: CharacterMood = .idle
    var body: some View {
        CharacterRig(mood: mood) { s, closed in
            ZStack {
                Circle().fill(rgrad("#FAD3B4", "#EBA77E", s, r: 52)).frame(width: 80 * s).offset(y: 0)
                shine(s, x: -18, y: -22, w: 20, h: 8)
                // one eye winks — a playful "bleh!"
                HStack(spacing: 14 * s) {
                    CuteEye(closed: closed, s: s, size: 14)
                    CuteEye(closed: true, s: s, size: 14)
                }
                .offset(y: -8 * s)
                HStack(spacing: 46 * s) {
                    Ellipse().fill(Ink.blush.opacity(0.55)).frame(width: 12 * s, height: 7 * s)
                    Ellipse().fill(Ink.blush.opacity(0.55)).frame(width: 12 * s, height: 7 * s)
                }
                .offset(y: 6 * s)
                Ellipse().fill(Color(hex: "#7E1E33")).frame(width: 26 * s, height: 13 * s).offset(y: 16 * s)
                let t: CGFloat = mood == .happy ? 32 : 26
                ZStack(alignment: .top) {
                    RoundedRectangle(cornerRadius: 10 * s).fill(vgrad("#FF8FA6", "#F0567A"))
                    Capsule().fill(Color(hex: "#D9406A").opacity(0.7)).frame(width: 2 * s, height: t * 0.45 * s).offset(y: 4 * s)
                }
                .frame(width: 20 * s, height: t * s)
                .offset(y: (17 + t / 2) * s)
            }
        }
    }
}

struct LegCharacter: View {
    var mood: CharacterMood = .idle
    var body: some View {
        CharacterRig(mood: mood) { s, _ in
            ZStack {
                Capsule().fill(Skin.base).frame(width: 24 * s, height: 62 * s).offset(x: -4 * s, y: -10 * s)
                Ellipse().fill(Skin.light.opacity(0.8)).frame(width: 7 * s, height: 26 * s).offset(x: -10 * s, y: -12 * s)
                ArcDown().stroke(Skin.shade, style: StrokeStyle(lineWidth: 2 * s, lineCap: .round))
                    .frame(width: 10 * s, height: 3 * s).offset(x: -4 * s, y: -6 * s)
                RoundedRectangle(cornerRadius: 9 * s).fill(vgrad("#6EC6FF", "#2E8BE0")).frame(width: 36 * s, height: 22 * s).offset(x: -4 * s, y: -36 * s)
                RoundedRectangle(cornerRadius: 4 * s).fill(Color.white).frame(width: 26 * s, height: 16 * s).offset(x: -4 * s, y: 17 * s)
                Capsule().fill(Color(hex: "#FF6B6B")).frame(width: 26 * s, height: 3 * s).offset(x: -4 * s, y: 13 * s)
                Capsule().fill(vgrad("#FF7B6E", "#E0322B")).frame(width: 46 * s, height: 22 * s).offset(x: 4 * s, y: 28 * s)
                Capsule().fill(Color.white).frame(width: 48 * s, height: 6 * s).offset(x: 4 * s, y: 38 * s)
                Circle().fill(Color.white.opacity(0.9)).frame(width: 5 * s).offset(x: 14 * s, y: 24 * s)
            }
            .rotationEffect(.degrees(mood == .happy ? -18 : 0), anchor: .top)
        }
    }
}

struct ArmCharacter: View {
    var mood: CharacterMood = .idle
    var body: some View {
        CharacterRig(mood: mood) { s, _ in
            ZStack {
                Capsule().fill(Skin.base).frame(width: 58 * s, height: 24 * s).offset(x: -12 * s, y: 20 * s)
                Ellipse().fill(Skin.base).frame(width: 32 * s, height: (mood == .happy ? 30 : 22) * s)
                    .offset(x: -14 * s, y: (mood == .happy ? 6 : 9) * s)
                Capsule().fill(Skin.base).frame(width: 22 * s, height: 50 * s)
                    .rotationEffect(.degrees(-8)).offset(x: 18 * s, y: -2 * s)
                Circle().fill(Skin.base).frame(width: 28 * s).offset(x: 21 * s, y: -26 * s)
                VStack(spacing: 3 * s) {
                    ForEach(0..<3, id: \.self) { _ in
                        Capsule().fill(Skin.shade).frame(width: 9 * s, height: 2 * s)
                    }
                }
                .offset(x: 14 * s, y: -26 * s)
                Ellipse().fill(Skin.light).frame(width: 14 * s, height: 7 * s).rotationEffect(.degrees(-20)).offset(x: -18 * s, y: (mood == .happy ? -1 : 3) * s)
                RoundedRectangle(cornerRadius: 9 * s).fill(vgrad("#FFE36E", "#FFBE1A")).frame(width: 24 * s, height: 32 * s).offset(x: -40 * s, y: 20 * s)
                if mood == .happy {
                    Image(systemName: "sparkle").font(.system(size: 14 * s, weight: .bold)).foregroundStyle(Color(hex: "#FFC93C"))
                        .offset(x: -26 * s, y: -18 * s)
                }
            }
        }
    }
}
