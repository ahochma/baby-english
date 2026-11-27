import UIKit
import SwiftUI
import AVFoundation

// ─────────────────────────────────────────────
// MARK: - Audio
// ─────────────────────────────────────────────

/// A screen's "still open" switch. Delayed callbacks check it, so a game that
/// has closed can't keep talking (a class, so callbacks share one value).
final class LiveFlag { var on = true }

enum SFX: String, CaseIterable {
    case pop = "sfx_pop"
    case chime = "sfx_chime"
    case sparkle = "sfx_sparkle"
    case boing = "sfx_boing"
    case tap = "sfx_tap"
}

/// Plays the bundled voice clips, synthesized sound effects and background music.
/// Voice clips are cached so playback starts the moment a finger lands.
final class AudioManager {
    static let shared = AudioManager()

    private var voiceCache: [String: AVAudioPlayer] = [:]
    private var currentVoice: AVAudioPlayer?
    private var sequenceToken = UUID()
    private var sfxPools: [SFX: [AVAudioPlayer]] = [:]
    private var music: AVAudioPlayer?
    /// False while the app is in the background: no voice may start then.
    private(set) var inForeground = true

    private init() {}

    /// Leaving the app cuts the voice and music at once.
    func enterBackground() {
        inForeground = false
        sequenceToken = UUID()
        currentVoice?.stop()
        pauseMusic()
    }

    func enterForeground() {
        inForeground = true
        updateMusic()
    }

    /// `.playback` keeps sound on even when the ring/silent switch is on —
    /// parents almost always have their phone on silent, and a "broken" silent
    /// app is the #1 complaint for kids' apps. `mixWithOthers` avoids stopping
    /// a parent's podcast or music.
    func configureSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)
        preload()
    }

    /// Final ElevenLabs clips are .mp3; temporary placeholders are .m4a.
    /// The .mp3 always wins, so dropping in new clips needs no code change.
    private static func url(for id: String) -> URL? {
        for ext in ["mp3", "m4a", "wav"] {
            if let u = Bundle.main.url(forResource: id, withExtension: ext) { return u }
        }
        return nil
    }

    func has(_ id: String) -> Bool { voiceCache[id] != nil || Self.url(for: id) != nil }

    private func preload() {
        DispatchQueue.global(qos: .userInitiated).async {
            var voices: [String: AVAudioPlayer] = [:]
            let urls = (Bundle.main.urls(forResourcesWithExtension: "mp3", subdirectory: nil) ?? [])
                     + (Bundle.main.urls(forResourcesWithExtension: "m4a", subdirectory: nil) ?? [])
            for url in urls {
                let id = url.deletingPathExtension().lastPathComponent
                guard id != "music_loop", voices[id] == nil || url.pathExtension == "mp3",
                      let p = try? AVAudioPlayer(contentsOf: url) else { continue }
                p.prepareToPlay()
                voices[id] = p
            }
            var pools: [SFX: [AVAudioPlayer]] = [:]
            for sfx in SFX.allCases {
                guard let url = Bundle.main.url(forResource: sfx.rawValue, withExtension: "wav") else { continue }
                pools[sfx] = (0..<4).compactMap { _ in
                    let p = try? AVAudioPlayer(contentsOf: url)
                    p?.prepareToPlay()
                    return p
                }
            }
            DispatchQueue.main.async {
                self.voiceCache.merge(voices) { a, _ in a }
                self.sfxPools.merge(pools) { a, _ in a }
            }
        }
    }

    private func player(for id: String) -> AVAudioPlayer? {
        if let cached = voiceCache[id] { return cached }
        guard let url = Self.url(for: id), let p = try? AVAudioPlayer(contentsOf: url) else { return nil }
        voiceCache[id] = p
        return p
    }

    /// Plays one spoken clip. A new clip always interrupts the previous one
    /// (and any running sequence) so the voice matches what's on screen.
    func play(_ audioId: String) {
        say([audioId])
    }

    /// Speaks clips back to back, e.g. ["he_dog", "dog"] → "כלב… Dog!".
    /// Missing clips are skipped silently. Returns the total duration.
    @discardableResult
    func say(_ ids: [String], gap: TimeInterval = 0.18) -> TimeInterval {
        currentVoice?.stop()
        let token = UUID()
        sequenceToken = token
        guard inForeground else { return 0 }
        let clips = ids.compactMap { player(for: $0) }
        var t: TimeInterval = 0
        for (i, p) in clips.enumerated() {
            let delay = t
            if i == 0 {
                start(p)
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                    guard let self, self.sequenceToken == token else { return }
                    self.start(p)
                }
            }
            t += p.duration + gap
        }
        return max(0, t - gap)
    }

    private func start(_ p: AVAudioPlayer) {
        guard inForeground else { return }
        currentVoice?.stop()
        p.currentTime = 0
        p.volume = 1.0
        p.play()
        currentVoice = p
    }

    func duration(of audioId: String) -> TimeInterval {
        player(for: audioId)?.duration ?? 1.0
    }

    func play(_ sfx: SFX, volume: Float = 0.7) {
        guard SettingsStore.shared.soundEffectsOn else { return }
        guard let pool = sfxPools[sfx], !pool.isEmpty else { return }
        let player = pool.first(where: { !$0.isPlaying }) ?? pool[0]
        player.currentTime = 0
        player.volume = volume
        player.play()
    }

    // MARK: Background music

    /// Soft music-box loop. It plays only where nothing is being taught (home,
    /// sticker album, celebrations) and fades out as soon as a learning game
    /// starts, so the child hears each word clean, with no background sound.
    private static let musicVolume: Float = 0.13
    private var sceneAllowsMusic = true
    private var celebrating = false
    private var musicGeneration = 0

    /// Called by the root view whenever the screen changes.
    func setMusicScene(allowed: Bool) {
        sceneAllowsMusic = allowed
        updateMusic()
    }

    /// Celebrations get the music back even in the middle of a game.
    func setCelebrating(_ on: Bool) {
        celebrating = on
        updateMusic()
    }

    var musicShouldPlay: Bool {
        let s = SettingsStore.shared
        return s.musicOn && !s.calmMode && (sceneAllowsMusic || celebrating)
    }

    func updateMusic() {
        musicGeneration += 1
        let generation = musicGeneration
        guard musicShouldPlay else {
            guard let music, music.isPlaying else { return }
            music.setVolume(0, fadeDuration: 0.5)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) { [weak self] in
                guard let self, self.musicGeneration == generation else { return }
                self.music?.pause()
            }
            return
        }
        if music == nil, let url = Bundle.main.url(forResource: "music_loop", withExtension: "m4a") {
            music = try? AVAudioPlayer(contentsOf: url)
            music?.numberOfLoops = -1
            music?.volume = 0
            music?.prepareToPlay()
        }
        guard let music else { return }
        if !music.isPlaying {
            music.volume = 0
            music.play()
        }
        music.setVolume(Self.musicVolume, fadeDuration: 0.8)
    }

    func pauseMusic() {
        musicGeneration += 1
        music?.pause()
    }
}

// ─────────────────────────────────────────────
// MARK: - Voice lines
// ─────────────────────────────────────────────

/// What the app says. Bilingual mode adds the Hebrew word first ("כלב… Dog!"),
/// a bridge Israeli parents use naturally; the English word always comes last
/// so it's the one that sticks.
enum Voice {
    static var bilingual: Bool { SettingsStore.shared.bilingualHebrew }

    static func word(_ w: WordItem) -> [String] {
        bilingual ? ["he_\(w.id)", w.id] : [w.id]
    }

    /// The question is one recorded sentence ("Where is the dog?"), never
    /// stitched from pieces, so it sounds like a real person asking. In
    /// bilingual mode the child hears "איפה הכלב?" and then "Dog!".
    static func whereIs(_ w: WordItem) -> [String] {
        bilingual ? ["he_ask_\(w.id)", w.id] : ["ask_\(w.id)"]
    }

    static func praise() -> String {
        ["great_job", "you_did_it", "yay_pip"].randomElement()!
    }
}

// ─────────────────────────────────────────────
// MARK: - Haptics
// ─────────────────────────────────────────────

enum Haptics {
    private static let light = UIImpactFeedbackGenerator(style: .light)
    private static let soft = UIImpactFeedbackGenerator(style: .soft)
    private static let notify = UINotificationFeedbackGenerator()

    static func tap() { light.impactOccurred() }
    static func pop() { soft.impactOccurred(intensity: 0.9) }
    static func success() { notify.notificationOccurred(.success) }
}

// ─────────────────────────────────────────────
// MARK: - Settings
// ─────────────────────────────────────────────

final class SettingsStore: ObservableObject {
    static let shared = SettingsStore()

    @Published var soundEffectsOn: Bool {
        didSet { UserDefaults.standard.set(soundEffectsOn, forKey: "soundEffectsOn") }
    }
    @Published var musicOn: Bool {
        didSet {
            UserDefaults.standard.set(musicOn, forKey: "musicOn")
            AudioManager.shared.updateMusic()
        }
    }
    /// Calm mode: no confetti, no spinning or bobbing decorations. For children
    /// who get over-excited, or for bedtime.
    @Published var calmMode: Bool {
        didSet {
            UserDefaults.standard.set(calmMode, forKey: "calmMode")
            AudioManager.shared.updateMusic()
        }
    }
    /// Say the Hebrew word before the English one. On by default for Hebrew devices.
    @Published var bilingualHebrew: Bool {
        didSet { UserDefaults.standard.set(bilingualHebrew, forKey: "bilingualHebrew") }
    }

    private init() {
        let d = UserDefaults.standard
        soundEffectsOn = d.object(forKey: "soundEffectsOn") as? Bool ?? true
        musicOn = d.object(forKey: "musicOn") as? Bool ?? true
        calmMode = d.bool(forKey: "calmMode")
        bilingualHebrew = d.object(forKey: "bilingualHebrew") as? Bool ?? L10n.isHebrew
    }
}

// ─────────────────────────────────────────────
// MARK: - Progress (stickers, streak, words heard)
// ─────────────────────────────────────────────

/// What Find it! has learned about one word.
struct WordStat: Codable, Equatable {
    var correctStreak = 0   // first-try wins in a row
    var firstTryWins = 0
    var misses = 0
}

final class StickerStore: ObservableObject {
    static let shared = StickerStore()

    /// Per-word results from Find it!, used for smart repetition and parent progress.
    @Published private(set) var wordStats: [String: WordStat] {
        didSet {
            if let data = try? JSONEncoder().encode(wordStats) {
                UserDefaults.standard.set(data, forKey: statsKey)
            }
        }
    }

    @Published private(set) var stickers: [String] {
        didSet { UserDefaults.standard.set(stickers, forKey: stickersKey) }
    }
    @Published private(set) var streak: Int {
        didSet { UserDefaults.standard.set(streak, forKey: streakKey) }
    }
    /// Word ids the child has heard at least once — shown to parents as progress.
    @Published private(set) var heardWords: Set<String> {
        didSet { UserDefaults.standard.set(Array(heardWords), forKey: heardKey) }
    }
    @Published private(set) var gamesFinished: Int {
        didSet { UserDefaults.standard.set(gamesFinished, forKey: gamesKey) }
    }
    /// The day Pip's daily surprise was last opened.
    @Published private(set) var lastGiftDay: Date? {
        didSet { UserDefaults.standard.set(lastGiftDay, forKey: giftKey) }
    }

    /// Special stickers that only come from the daily gift, so it feels like a treat.
    static let giftPool = ["🦄", "🌈", "🐉", "🦋", "🍦", "🎈", "🪁", "🧸", "🎠", "🐳", "🦖", "🌻", "🍭", "🚂"]

    var giftAvailable: Bool {
        guard let last = lastGiftDay else { return true }
        return !Calendar.current.isDateInToday(last)
    }

    private let lastPlayedKey = "lastPlayedDate"
    private let stickersKey = "earnedStickers"
    private let streakKey = "streak"
    private let heardKey = "heardWords"
    private let gamesKey = "gamesFinished"
    private let giftKey = "lastGiftDay"
    private let statsKey = "wordStats"

    private init() {
        let d = UserDefaults.standard
        stickers = (d.array(forKey: stickersKey) as? [String]) ?? []
        streak = d.integer(forKey: streakKey)
        heardWords = Set((d.array(forKey: heardKey) as? [String]) ?? [])
        gamesFinished = d.integer(forKey: gamesKey)
        lastGiftDay = d.object(forKey: giftKey) as? Date
        wordStats = (d.data(forKey: statsKey)).flatMap { try? JSONDecoder().decode([String: WordStat].self, from: $0) } ?? [:]
        updateStreak()
    }

    @discardableResult
    func addSticker(from pool: [String]) -> String {
        // Prefer stickers the child doesn't own yet so the board keeps growing.
        let owned = Set(stickers)
        let fresh = pool.filter { !owned.contains($0) }
        let sticker = (fresh.isEmpty ? pool : fresh).randomElement() ?? "⭐"
        stickers.append(sticker)
        gamesFinished += 1
        return sticker
    }

    /// Opens today's gift. Returns the sticker, or nil if it was already opened today.
    @discardableResult
    func claimDailyGift() -> String? {
        guard giftAvailable else { return nil }
        let owned = Set(stickers)
        let fresh = Self.giftPool.filter { !owned.contains($0) }
        let sticker = (fresh.isEmpty ? Self.giftPool : fresh).randomElement() ?? "🦄"
        stickers.append(sticker)
        lastGiftDay = Date()
        return sticker
    }

    // MARK: Smart repetition

    /// A word counts as known after two first-try wins in a row in Find it!.
    static let knownStreak = 2

    func isKnown(_ wordId: String) -> Bool {
        (wordStats[wordId]?.correctStreak ?? 0) >= Self.knownStreak
    }

    /// Practicing = missed at least once and not yet known again.
    func isPracticing(_ wordId: String) -> Bool {
        guard let s = wordStats[wordId] else { return false }
        return s.misses > 0 && s.correctStreak < Self.knownStreak
    }

    /// Correct answer. A first-try win builds the streak; a win after misses doesn't.
    func recordCorrect(_ wordId: String, firstTry: Bool) {
        var s = wordStats[wordId] ?? WordStat()
        if firstTry {
            s.correctStreak += 1
            s.firstTryWins += 1
        } else {
            s.correctStreak = 0
        }
        wordStats[wordId] = s
    }

    /// The child tapped a wrong picture while this word was being asked.
    func recordMiss(_ wordId: String) {
        var s = wordStats[wordId] ?? WordStat()
        s.misses += 1
        s.correctStreak = 0
        wordStats[wordId] = s
    }

    /// How likely a word is to be asked next: struggling words come back
    /// often, new words get a fair chance, known words are rare reviews.
    func practiceWeight(_ wordId: String) -> Double {
        guard let s = wordStats[wordId] else { return 1.5 }
        if s.correctStreak >= Self.knownStreak { return 0.35 }
        if s.misses > 0 { return 1 + Double(min(s.misses, 4)) * 0.75 }
        return 1
    }

    /// Weighted random pick, used by Find it!.
    func pickForPractice(from words: [WordItem]) -> WordItem? {
        let weights = words.map { practiceWeight($0.id) }
        let total = weights.reduce(0, +)
        guard total > 0 else { return words.randomElement() }
        var r = Double.random(in: 0..<total)
        for (w, weight) in zip(words, weights) {
            r -= weight
            if r < 0 { return w }
        }
        return words.last
    }

    func markHeard(_ wordId: String) {
        if !heardWords.contains(wordId) { heardWords.insert(wordId) }
    }

    func updateStreak() {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        if let last = UserDefaults.standard.object(forKey: lastPlayedKey) as? Date {
            let diff = cal.dateComponents([.day], from: cal.startOfDay(for: last), to: today).day ?? 0
            if diff == 1 { streak += 1 } else if diff > 1 { streak = 1 }
            if streak == 0 { streak = 1 }
        } else {
            streak = 1
        }
        UserDefaults.standard.set(today, forKey: lastPlayedKey)
    }
}
