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
}

struct Category: Identifiable {
    let id: String
    let label: String
    let emoji: String
    let gradientStart: Color
    let gradientEnd: Color
    let words: [WordItem]
    let stickerPool: [String]
}

// ─────────────────────────────────────────────
// MARK: - Categories Data
// ─────────────────────────────────────────────

let ALL_CATEGORIES: [Category] = [
    Category(id: "vehicles", label: "Vehicles", emoji: "🚒",
             gradientStart: Color(hex: "#EF5350"), gradientEnd: Color(hex: "#B71C1C"),
             words: [
                WordItem(id:"firetruck",  label:"Fire Truck",  emoji:"🚒", bg:Color(hex:"#FFEBEE"), textColor:Color(hex:"#B71C1C")),
                WordItem(id:"helicopter", label:"Helicopter",  emoji:"🚁", bg:Color(hex:"#E3F2FD"), textColor:Color(hex:"#0D47A1")),
                WordItem(id:"truck",      label:"Truck",       emoji:"🚚", bg:Color(hex:"#FFF3E0"), textColor:Color(hex:"#E65100")),
                WordItem(id:"ambulance",  label:"Ambulance",   emoji:"🚑", bg:Color(hex:"#FCE4EC"), textColor:Color(hex:"#880E4F")),
                WordItem(id:"policecar",  label:"Police Car",  emoji:"🚓", bg:Color(hex:"#E8EAF6"), textColor:Color(hex:"#1A237E")),
                WordItem(id:"tractor",    label:"Tractor",     emoji:"🚜", bg:Color(hex:"#F1F8E9"), textColor:Color(hex:"#33691E")),
                WordItem(id:"train",      label:"Train",       emoji:"🚂", bg:Color(hex:"#EFEBE9"), textColor:Color(hex:"#3E2723")),
                WordItem(id:"rocket",     label:"Rocket",      emoji:"🚀", bg:Color(hex:"#EDE7F6"), textColor:Color(hex:"#311B92")),
                WordItem(id:"airplane",   label:"Airplane",    emoji:"✈️",  bg:Color(hex:"#E0F7FA"), textColor:Color(hex:"#006064")),
                WordItem(id:"bus",        label:"Bus",         emoji:"🚌", bg:Color(hex:"#FFFDE7"), textColor:Color(hex:"#F57F17")),
             ],
             stickerPool: ["🚒","🚁","🚚","🚑","🚓","🚜","🚂","🚀","✈️","🚌","🏎️","⛵"]),
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
             ],
             stickerPool: ["🐶","🐱","🐦","🐟","🐮","🦆","🐘","🦁","🐸","🐰","🦊","🐻"]),
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
             ],
             stickerPool: ["🔴","🔵","🟢","🟡","🟠","🟣","🩷","⬜","⬛","🟤","🌈","🎨"]),
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
             ],
             stickerPool: ["🍎","🍌","🥛","🍞","🥚","🍊","🍓","🥕","🎂","🍇","🍕","🍪"]),
]

// ─────────────────────────────────────────────
// MARK: - Audio
// ─────────────────────────────────────────────

class AudioManager {
    static let shared = AudioManager()
    private var player: AVAudioPlayer?

    func play(_ audioId: String) {
        guard let url = Bundle.main.url(forResource: audioId, withExtension: "mp3") else {
            return
        }
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.play()
        } catch {}
    }
}

// ─────────────────────────────────────────────
// MARK: - Sticker Store
// ─────────────────────────────────────────────

class StickerStore: ObservableObject {
    static let shared = StickerStore()

    @Published var stickers: [String] {
        didSet { save() }
    }
    @Published var streak: Int {
        didSet { UserDefaults.standard.set(streak, forKey: "streak") }
    }

    private let lastPlayedKey = "lastPlayedDate"
    private let stickersKey = "earnedStickers"
    private let streakKey = "streak"

    private init() {
        self.stickers = (UserDefaults.standard.array(forKey: "earnedStickers") as? [String]) ?? []
        self.streak = UserDefaults.standard.integer(forKey: "streak")
        updateStreak()
    }

    private func save() {
        UserDefaults.standard.set(stickers, forKey: stickersKey)
    }

    func addSticker(from pool: [String]) -> String {
        let sticker = pool.randomElement() ?? "⭐"
        stickers.append(sticker)
        return sticker
    }

    func updateStreak() {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        if let last = UserDefaults.standard.object(forKey: lastPlayedKey) as? Date {
            let lastDay = cal.startOfDay(for: last)
            let diff = cal.dateComponents([.day], from: lastDay, to: today).day ?? 0
            if diff == 1 {
                streak += 1
            } else if diff > 1 {
                streak = 1
            }
        } else {
            streak = 1
        }
        UserDefaults.standard.set(today, forKey: lastPlayedKey)
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

enum AppScreen {
    case home
    case category(Category)
    case stickerBoard
}

struct ContentView: View {
    @StateObject private var stickerStore = StickerStore.shared
    @State private var screen: AppScreen = .home

    var body: some View {
        switch screen {
        case .home:
            HomeView(
                stickerStore: stickerStore,
                onSelectCategory: { screen = .category($0) },
                onShowStickers: { screen = .stickerBoard }
            )
        case .category(let cat):
            FlashcardView(category: cat, stickerStore: stickerStore, onBack: { screen = .home })
        case .stickerBoard:
            StickerBoardView(stickerStore: stickerStore, onBack: { screen = .home })
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - Home Screen
// ─────────────────────────────────────────────

struct HomeView: View {
    @ObservedObject var stickerStore: StickerStore
    let onSelectCategory: (Category) -> Void
    let onShowStickers: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: "#E3F2FD"), Color(hex: "#F3E5F5")],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Title + streak
                VStack(spacing: 6) {
                    Text("🌟")
                        .font(.system(size: 70))
                    Text("Baby English")
                        .font(.system(size: 46, weight: .black, design: .rounded))
                        .foregroundColor(Color(hex: "#1A237E"))
                    if stickerStore.streak > 1 {
                        HStack(spacing: 4) {
                            Text("🔥")
                                .font(.system(size: 22))
                            Text("\(stickerStore.streak) days")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(Color(hex: "#E65100"))
                        }
                    }
                }
                .padding(.top, 50)
                .padding(.bottom, 24)

                // Category Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                    ForEach(ALL_CATEGORIES) { category in
                        CategoryCard(category: category, onTap: { onSelectCategory(category) })
                    }
                }
                .padding(.horizontal, 20)

                Spacer()

                // Sticker board button
                Button(action: onShowStickers) {
                    HStack(spacing: 10) {
                        Text("🏆")
                            .font(.system(size: 32))
                        Text("My Stickers")
                            .font(.system(size: 24, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                        if !stickerStore.stickers.isEmpty {
                            Text("\(stickerStore.stickers.count)")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(Color(hex: "#F57F17"))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.white)
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(colors: [Color(hex: "#FFB300"), Color(hex: "#FF8F00")],
                                       startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(Capsule())
                    .shadow(color: Color(hex: "#FF8F00").opacity(0.4), radius: 10, x: 0, y: 5)
                }
                .buttonStyle(CategoryCardButtonStyle())
                .padding(.bottom, 40)
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
    @ObservedObject var stickerStore: StickerStore
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
                CelebrationView(category: category, stickerStore: stickerStore, onDone: onBack)
            } else {
                currentWord.bg.ignoresSafeArea()

                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { handleTap() }
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer()

                    VStack(spacing: 16) {
                        Text(currentWord.emoji)
                            .font(.system(size: 180))
                            .scaleEffect(emojiScale)
                        Text(currentWord.label)
                            .font(.system(size: 68, weight: .black, design: .rounded))
                            .foregroundColor(currentWord.textColor)
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
                            Circle()
                                .fill(Color.white.opacity(0.25))
                                .frame(width: 64, height: 64)
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

    private func handleTap() {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()

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
            withAnimation(.spring()) { showCelebration = true }
        }
    }

    private func animateCardIn() {
        cardScale = 0.4
        withAnimation(.spring(response: 0.45, dampingFraction: 0.55)) {
            cardScale = 1.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) {
                emojiScale = 1.18
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                withAnimation(.spring()) { emojiScale = 1.0 }
            }
        }
    }

    private func speakCurrent() {
        AudioManager.shared.play(currentWord.id)
    }

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
        longPressProgress += 0.033
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
    let category: Category
    @ObservedObject var stickerStore: StickerStore
    let onDone: () -> Void

    @State private var scale: CGFloat = 0.3
    @State private var stickerScale: CGFloat = 0.0
    @State private var earnedSticker: String = ""
    @State private var stars: [StarParticle] = (0..<20).map { _ in StarParticle() }

    var body: some View {
        ZStack {
            Color(hex: "#FFF9C4").ignoresSafeArea()

            ForEach(stars) { star in
                Text(star.emoji)
                    .font(.system(size: star.size))
                    .position(x: star.x, y: star.y)
                    .opacity(star.opacity)
                    .rotationEffect(.degrees(star.rotation))
            }

            VStack(spacing: 24) {
                Text("🎉")
                    .font(.system(size: 120))
                    .scaleEffect(scale)

                Text("Yay!")
                    .font(.system(size: 80, weight: .black, design: .rounded))
                    .foregroundColor(Color(hex: "#F57F17"))
                    .scaleEffect(scale)

                // Earned sticker reveal
                if !earnedSticker.isEmpty {
                    VStack(spacing: 8) {
                        Text("You earned a sticker!")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(Color(hex: "#5D4037"))
                        Text(earnedSticker)
                            .font(.system(size: 100))
                            .scaleEffect(stickerScale)
                    }
                }

                Text("🌟🌟🌟")
                    .font(.system(size: 50))
                    .scaleEffect(scale)
            }
        }
        .onAppear {
            let impact = UINotificationFeedbackGenerator()
            impact.notificationOccurred(.success)

            earnedSticker = stickerStore.addSticker(from: category.stickerPool)

            withAnimation(.spring(response: 0.5, dampingFraction: 0.5)) {
                scale = 1.0
            }
            // Sticker reveal with delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.4)) {
                    stickerScale = 1.0
                }
            }
            animateStars()
            AudioManager.shared.play("celebration")
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
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

// ─────────────────────────────────────────────
// MARK: - Sticker Board
// ─────────────────────────────────────────────

struct StickerBoardView: View {
    @ObservedObject var stickerStore: StickerStore
    let onBack: () -> Void
    @State private var appeared = false

    private let totalSlots = 24

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: "#FFF8E1"), Color(hex: "#FFECB3")],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // Header
                HStack {
                    Button(action: onBack) {
                        HStack(spacing: 6) {
                            Text("🏠")
                                .font(.system(size: 28))
                            Text("Back")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(Color(hex: "#5D4037"))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.6))
                        .clipShape(Capsule())
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)

                Text("🏆 My Stickers")
                    .font(.system(size: 38, weight: .black, design: .rounded))
                    .foregroundColor(Color(hex: "#E65100"))

                Text("\(stickerStore.stickers.count) collected")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "#8D6E63"))

                // Sticker grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
                    ForEach(0..<totalSlots, id: \.self) { i in
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)

                            if i < stickerStore.stickers.count {
                                Text(stickerStore.stickers[i])
                                    .font(.system(size: 44))
                                    .scaleEffect(appeared ? 1.0 : 0.3)
                                    .animation(
                                        .spring(response: 0.4, dampingFraction: 0.5)
                                            .delay(Double(i) * 0.05),
                                        value: appeared
                                    )
                            } else {
                                Text("?")
                                    .font(.system(size: 36, weight: .bold, design: .rounded))
                                    .foregroundColor(Color(hex: "#E0E0E0"))
                            }
                        }
                        .frame(height: 72)
                    }
                }
                .padding(.horizontal, 20)

                Spacer()
            }
        }
        .onAppear { appeared = true }
    }
}
