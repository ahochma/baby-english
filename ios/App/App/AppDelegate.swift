import UIKit
import SwiftUI
import AVFoundation

// ─────────────────────────────────────────────
// MARK: - App Entry Point
// ─────────────────────────────────────────────

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        return true
    }
    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let config = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        config.delegateClass = SceneDelegate.self
        return config
    }
}

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = UIHostingController(rootView: ContentView())
        self.window = window
        window.makeKeyAndVisible()
    }
}

// ─────────────────────────────────────────────
// MARK: - Data Model
// ─────────────────────────────────────────────

struct WordItem: Identifiable {
    let id: String
    let label: String
    let emoji: String
    let bg: Color
    let textColor: Color
    var letter: String? = nil
    var word: String? = nil
}

struct Category: Identifiable {
    let id: String
    let label: String
    let emoji: String
    let gradientStart: Color
    let gradientEnd: Color
    let words: [WordItem]
    var type: String = "word"
}

let letterColors: [(bg: Color, text: Color)] = [
    (Color(hex: "#FF5252"), .white), (Color(hex: "#FF7043"), .white),
    (Color(hex: "#FFA726"), .white), (Color(hex: "#FFCA28"), Color(hex: "#333333")),
    (Color(hex: "#D4E157"), Color(hex: "#333333")), (Color(hex: "#66BB6A"), .white),
    (Color(hex: "#26A69A"), .white), (Color(hex: "#42A5F5"), .white),
    (Color(hex: "#5C6BC0"), .white), (Color(hex: "#AB47BC"), .white),
    (Color(hex: "#EC407A"), .white), (Color(hex: "#EF5350"), .white),
    (Color(hex: "#FF8A65"), .white), (Color(hex: "#FFF176"), Color(hex: "#333333")),
    (Color(hex: "#AED581"), Color(hex: "#333333")), (Color(hex: "#4DB6AC"), .white),
    (Color(hex: "#4FC3F7"), .white), (Color(hex: "#7986CB"), .white),
    (Color(hex: "#CE93D8"), Color(hex: "#333333")), (Color(hex: "#F48FB1"), Color(hex: "#333333")),
    (Color(hex: "#FFAB91"), Color(hex: "#333333")), (Color(hex: "#A5D6A7"), Color(hex: "#333333")),
    (Color(hex: "#80DEEA"), Color(hex: "#333333")), (Color(hex: "#9FA8DA"), .white),
    (Color(hex: "#FFF59D"), Color(hex: "#333333")), (Color(hex: "#80CBC4"), Color(hex: "#333333")),
]

let abcData: [(letter: String, word: String, emoji: String)] = [
    ("A","Apple","🍎"),("B","Ball","🏀"),("C","Cat","🐱"),("D","Dog","🐶"),
    ("E","Egg","🥚"),("F","Fish","🐟"),("G","Grapes","🍇"),("H","Hat","🎩"),
    ("I","Ice Cream","🍦"),("J","Juice","🧃"),("K","Kite","🪁"),("L","Lion","🦁"),
    ("M","Moon","🌙"),("N","Nest","🪺"),("O","Orange","🍊"),("P","Pig","🐷"),
    ("Q","Queen","👸"),("R","Rabbit","🐰"),("S","Star","⭐"),("T","Tiger","🐯"),
    ("U","Umbrella","☂️"),("V","Violin","🎻"),("W","Watermelon","🍉"),
    ("X","X-ray","🩻"),("Y","Yo-yo","🪀"),("Z","Zebra","🦓"),
]

let ALL_CATEGORIES: [Category] = [
    Category(id: "abc", label: "ABC", emoji: "🔤",
             gradientStart: Color(hex: "#42A5F5"), gradientEnd: Color(hex: "#0D47A1"),
             words: abcData.enumerated().map { i, d in
                 WordItem(id: d.letter.lowercased(), label: d.letter, emoji: d.emoji,
                          bg: letterColors[i].bg, textColor: letterColors[i].text,
                          letter: d.letter, word: d.word)
             }, type: "letter"),
    Category(id: "animals", label: "Animals", emoji: "🐾",
             gradientStart: Color(hex: "#66BB6A"), gradientEnd: Color(hex: "#2E7D32"),
             words: [
                WordItem(id:"dog",   label:"Dog",      emoji:"🐶", bg:Color(hex:"#FFF8E1"), textColor:Color(hex:"#5D4037")),
                WordItem(id:"cat",   label:"Cat",      emoji:"🐱", bg:Color(hex:"#FCE4EC"), textColor:Color(hex:"#880E4F")),
                WordItem(id:"bird",  label:"Bird",     emoji:"🐦", bg:Color(hex:"#E3F2FD"), textColor:Color(hex:"#0D47A1")),
                WordItem(id:"fish",  label:"Fish",     emoji:"🐟", bg:Color(hex:"#E0F7FA"), textColor:Color(hex:"#006064")),
                WordItem(id:"cow",   label:"Cow",      emoji:"🐮", bg:Color(hex:"#F3E5F5"), textColor:Color(hex:"#4A148C")),
                WordItem(id:"duck",  label:"Duck",     emoji:"🦆", bg:Color(hex:"#FFFDE7"), textColor:Color(hex:"#F57F17")),
                WordItem(id:"elephant",label:"Elephant",emoji:"🐘",bg:Color(hex:"#EDE7F6"), textColor:Color(hex:"#311B92")),
                WordItem(id:"lion",  label:"Lion",     emoji:"🦁", bg:Color(hex:"#FFF3E0"), textColor:Color(hex:"#E65100")),
                WordItem(id:"frog",  label:"Frog",     emoji:"🐸", bg:Color(hex:"#E8F5E9"), textColor:Color(hex:"#1B5E20")),
                WordItem(id:"rabbit",label:"Rabbit",   emoji:"🐰", bg:Color(hex:"#FCE4EC"), textColor:Color(hex:"#880E4F")),
             ]),
    Category(id: "colors", label: "Colors", emoji: "🎨",
             gradientStart: Color(hex: "#BA68C8"), gradientEnd: Color(hex: "#6A1B9A"),
             words: [
                WordItem(id:"red",   label:"Red",    emoji:"🔴", bg:Color(hex:"#EF5350"), textColor:.white),
                WordItem(id:"blue",  label:"Blue",   emoji:"🔵", bg:Color(hex:"#42A5F5"), textColor:.white),
                WordItem(id:"green", label:"Green",  emoji:"🟢", bg:Color(hex:"#66BB6A"), textColor:.white),
                WordItem(id:"yellow",label:"Yellow", emoji:"🟡", bg:Color(hex:"#FFEE58"), textColor:Color(hex:"#333333")),
                WordItem(id:"orange",label:"Orange", emoji:"🟠", bg:Color(hex:"#FFA726"), textColor:.white),
                WordItem(id:"purple",label:"Purple", emoji:"🟣", bg:Color(hex:"#AB47BC"), textColor:.white),
                WordItem(id:"pink",  label:"Pink",   emoji:"🩷", bg:Color(hex:"#F48FB1"), textColor:.white),
                WordItem(id:"white", label:"White",  emoji:"⬜", bg:Color(hex:"#F5F5F5"), textColor:Color(hex:"#333333")),
                WordItem(id:"black", label:"Black",  emoji:"⬛", bg:Color(hex:"#424242"), textColor:.white),
                WordItem(id:"brown", label:"Brown",  emoji:"🟤", bg:Color(hex:"#8D6E63"), textColor:.white),
             ]),
    Category(id: "food", label: "Food", emoji: "🍎",
             gradientStart: Color(hex: "#FF7043"), gradientEnd: Color(hex: "#BF360C"),
             words: [
                WordItem(id:"apple",     label:"Apple",      emoji:"🍎", bg:Color(hex:"#FFEBEE"), textColor:Color(hex:"#B71C1C")),
                WordItem(id:"banana",    label:"Banana",     emoji:"🍌", bg:Color(hex:"#FFFDE7"), textColor:Color(hex:"#F57F17")),
                WordItem(id:"milk",      label:"Milk",       emoji:"🥛", bg:Color(hex:"#F5F5F5"), textColor:Color(hex:"#333333")),
                WordItem(id:"bread",     label:"Bread",      emoji:"🍞", bg:Color(hex:"#FFF8E1"), textColor:Color(hex:"#E65100")),
                WordItem(id:"egg",       label:"Egg",        emoji:"🥚", bg:Color(hex:"#FFF9C4"), textColor:Color(hex:"#F57F17")),
                WordItem(id:"orange2",   label:"Orange",     emoji:"🍊", bg:Color(hex:"#FFF3E0"), textColor:Color(hex:"#E65100")),
                WordItem(id:"strawberry",label:"Strawberry", emoji:"🍓", bg:Color(hex:"#FCE4EC"), textColor:Color(hex:"#880E4F")),
                WordItem(id:"carrot",    label:"Carrot",     emoji:"🥕", bg:Color(hex:"#FFF3E0"), textColor:Color(hex:"#E65100")),
                WordItem(id:"cake",      label:"Cake",       emoji:"🎂", bg:Color(hex:"#F8BBD0"), textColor:Color(hex:"#880E4F")),
                WordItem(id:"grapes",    label:"Grapes",     emoji:"🍇", bg:Color(hex:"#EDE7F6"), textColor:Color(hex:"#4A148C")),
             ]),
]

// ─────────────────────────────────────────────
// MARK: - Audio
// ─────────────────────────────────────────────

class AudioManager {
    static let shared = AudioManager()
    private let synthesizer = AVSpeechSynthesizer()

    func speak(_ text: String) {
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.38
        utterance.pitchMultiplier = 1.15
        utterance.volume = 1.0
        synthesizer.speak(utterance)
    }
}

// ─────────────────────────────────────────────
// MARK: - Color Helper
// ─────────────────────────────────────────────

extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8)  & 0xFF) / 255
        let b = Double(int         & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// ─────────────────────────────────────────────
// MARK: - Content View
// ─────────────────────────────────────────────

struct ContentView: View {
    @State private var selectedCategory: Category? = nil

    var body: some View {
        if let category = selectedCategory {
            FlashcardView(category: category, onBack: { selectedCategory = nil })
        } else {
            HomeView(onSelectCategory: { selectedCategory = $0 })
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - Home Screen
// ─────────────────────────────────────────────

struct HomeView: View {
    let onSelectCategory: (Category) -> Void

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: "#E3F2FD"), Color(hex: "#F3E5F5")],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Title
                VStack(spacing: 6) {
                    Text("🌟")
                        .font(.system(size: 70))
                    Text("Baby English")
                        .font(.system(size: 46, weight: .black, design: .rounded))
                        .foregroundColor(Color(hex: "#1A237E"))
                }
                .padding(.top, 50)
                .padding(.bottom, 32)

                // Category Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                    ForEach(ALL_CATEGORIES) { category in
                        CategoryCard(category: category, onTap: { onSelectCategory(category) })
                    }
                }
                .padding(.horizontal, 20)

                Spacer()
            }
        }
    }
}

struct CategoryCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.93 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct CategoryCard: View {
    let category: Category
    let onTap: () -> Void
    @State private var emojiScale: CGFloat = 1.0

    var body: some View {
        Button(action: onTap) {
            ZStack {
                LinearGradient(colors: [category.gradientStart, category.gradientEnd],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                VStack(spacing: 10) {
                    Text(category.emoji)
                        .font(.system(size: 72))
                        .scaleEffect(emojiScale)
                    Text(category.label)
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                }
                .padding(.vertical, 36)
            }
            .clipShape(RoundedRectangle(cornerRadius: 28))
            .shadow(color: category.gradientEnd.opacity(0.45), radius: 14, x: 0, y: 7)
        }
        .buttonStyle(CategoryCardButtonStyle())
        .onAppear {
            // Gentle pulse to attract attention
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                emojiScale = 1.1
            }
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - Flashcard Screen
// ─────────────────────────────────────────────

struct FlashcardView: View {
    let category: Category
    let onBack: () -> Void

    @State private var currentIndex = 0
    @State private var cardScale: CGFloat = 0.4
    @State private var emojiScale: CGFloat = 1.0
    @State private var showCelebration = false
    @State private var longPressProgress: CGFloat = 0
    @State private var isLongPressing = false

    var currentWord: WordItem { category.words[currentIndex] }

    var body: some View {
        ZStack {
            if showCelebration {
                CelebrationView(onDone: onBack)
            } else {
                // Full-screen background
                currentWord.bg.ignoresSafeArea()

                // Full-screen tap area
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { handleTap() }
                    .ignoresSafeArea()

                // Card content centered
                VStack(spacing: 0) {
                    Spacer()

                    if category.type == "letter", let letter = currentWord.letter, let word = currentWord.word {
                        // Letter card
                        VStack(spacing: 12) {
                            Text(currentWord.emoji)
                                .font(.system(size: 120))
                                .scaleEffect(emojiScale)
                            HStack(alignment: .bottom, spacing: 10) {
                                Text(letter)
                                    .font(.system(size: 160, weight: .black, design: .rounded))
                                    .foregroundColor(currentWord.textColor)
                                Text(letter.lowercased())
                                    .font(.system(size: 110, weight: .bold, design: .rounded))
                                    .foregroundColor(currentWord.textColor.opacity(0.65))
                                    .padding(.bottom, 12)
                            }
                            Text(word)
                                .font(.system(size: 48, weight: .black, design: .rounded))
                                .foregroundColor(currentWord.textColor)
                        }
                    } else {
                        // Word card
                        VStack(spacing: 16) {
                            Text(currentWord.emoji)
                                .font(.system(size: 180))
                                .scaleEffect(emojiScale)
                            Text(currentWord.label)
                                .font(.system(size: 68, weight: .black, design: .rounded))
                                .foregroundColor(currentWord.textColor)
                        }
                    }

                    Spacer()

                    // Progress dots
                    HStack(spacing: 10) {
                        ForEach(0..<category.words.count, id: \.self) { i in
                            Circle()
                                .fill(i == currentIndex
                                      ? currentWord.textColor
                                      : currentWord.textColor.opacity(0.25))
                                .frame(width: i == currentIndex ? 14 : 9,
                                       height: i == currentIndex ? 14 : 9)
                                .animation(.spring(), value: currentIndex)
                        }
                    }
                    .padding(.bottom, 50)
                }
                .scaleEffect(cardScale)
                .id(currentIndex)

                // Long-press home button (top-right)
                VStack {
                    HStack {
                        Spacer()
                        ZStack {
                            // Background circle
                            Circle()
                                .fill(Color.white.opacity(0.25))
                                .frame(width: 64, height: 64)

                            // Progress ring (fills as user holds)
                            Circle()
                                .trim(from: 0, to: longPressProgress)
                                .stroke(currentWord.textColor.opacity(0.8),
                                        style: StrokeStyle(lineWidth: 4, lineCap: .round))
                                .frame(width: 56, height: 56)
                                .rotationEffect(.degrees(-90))
                                .animation(.linear(duration: 0.05), value: longPressProgress)

                            Text("🏠")
                                .font(.system(size: 30))
                        }
                        .padding(.top, 60)
                        .padding(.trailing, 20)
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { _ in
                                    if !isLongPressing {
                                        isLongPressing = true
                                        startLongPress()
                                    }
                                }
                                .onEnded { _ in
                                    cancelLongPress()
                                }
                        )
                    }
                    Spacer()
                }
            }
        }
        .onAppear {
            animateCardIn()
            speakCurrent()
        }
    }

    // ── Tap: advance card or celebrate ──
    private func handleTap() {
        if currentIndex < category.words.count - 1 {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                currentIndex += 1
                cardScale = 0.4
                emojiScale = 1.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                animateCardIn()
                speakCurrent()
            }
        } else {
            // Last card — celebrate!
            withAnimation(.spring()) { showCelebration = true }
        }
    }

    // ── Animate card bouncing in ──
    private func animateCardIn() {
        cardScale = 0.4
        withAnimation(.spring(response: 0.45, dampingFraction: 0.55)) {
            cardScale = 1.0
        }
        // Emoji secondary bounce
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) {
                emojiScale = 1.18
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                withAnimation(.spring()) { emojiScale = 1.0 }
            }
        }
    }

    // ── Speak current word ──
    private func speakCurrent() {
        let text = currentWord.word ?? currentWord.label
        AudioManager.shared.speak(text)
    }

    // ── Long press home logic ──
    private func startLongPress() {
        longPressProgress = 0
        animateLongPress()
    }

    private func animateLongPress() {
        guard isLongPressing else { return }
        if longPressProgress >= 1.0 {
            isLongPressing = false
            longPressProgress = 0
            onBack()
            return
        }
        longPressProgress += 0.033  // ~30 steps over ~1s
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.033) {
            animateLongPress()
        }
    }

    private func cancelLongPress() {
        isLongPressing = false
        withAnimation(.easeOut(duration: 0.2)) { longPressProgress = 0 }
    }
}

// ─────────────────────────────────────────────
// MARK: - Celebration Screen
// ─────────────────────────────────────────────

struct CelebrationView: View {
    let onDone: () -> Void
    @State private var scale: CGFloat = 0.3
    @State private var stars: [StarParticle] = (0..<20).map { _ in StarParticle() }

    var body: some View {
        ZStack {
            Color(hex: "#FFF9C4").ignoresSafeArea()

            // Flying stars
            ForEach(stars) { star in
                Text(star.emoji)
                    .font(.system(size: star.size))
                    .position(x: star.x, y: star.y)
                    .opacity(star.opacity)
                    .rotationEffect(.degrees(star.rotation))
            }

            VStack(spacing: 24) {
                Text("🎉")
                    .font(.system(size: 140))
                    .scaleEffect(scale)

                Text("Yay!")
                    .font(.system(size: 80, weight: .black, design: .rounded))
                    .foregroundColor(Color(hex: "#F57F17"))
                    .scaleEffect(scale)

                Text("🌟🌟🌟")
                    .font(.system(size: 60))
                    .scaleEffect(scale)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.5)) {
                scale = 1.0
            }
            animateStars()
            // Auto-return after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                onDone()
            }
        }
    }

    private func animateStars() {
        for i in 0..<stars.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.08) {
                withAnimation(.easeOut(duration: 1.5)) {
                    stars[i].y -= CGFloat.random(in: 200...500)
                    stars[i].x += CGFloat.random(in: -150...150)
                    stars[i].opacity = 0
                    stars[i].rotation += Double.random(in: -180...180)
                }
            }
        }
    }
}

struct StarParticle: Identifiable {
    let id = UUID()
    var x: CGFloat = CGFloat.random(in: 100...320)
    var y: CGFloat = CGFloat.random(in: 300...600)
    var size: CGFloat = CGFloat.random(in: 24...56)
    var opacity: Double = 1.0
    var rotation: Double = Double.random(in: -45...45)
    let emoji: String = ["⭐", "🌟", "✨", "💫", "🎊"].randomElement()!
}
