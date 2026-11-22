import UIKit
import SwiftUI
import AVFoundation

// ─────────────────────────────────────────────
// MARK: - Audio
// ─────────────────────────────────────────────

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

    private init() {}

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

    /// Soft music-box loop, kept quiet so every spoken word stays clear.
    func updateMusic() {
        guard SettingsStore.shared.musicOn else {
            music?.pause()
            return
        }
        if music == nil, let url = Bundle.main.url(forResource: "music_loop", withExtension: "m4a") {
            music = try? AVAudioPlayer(contentsOf: url)
            music?.numberOfLoops = -1
            music?.volume = 0.13
            music?.prepareToPlay()
        }
        if music?.isPlaying == false { music?.play() }
    }

    func pauseMusic() { music?.pause() }
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

    static func whereIs(_ w: WordItem) -> [String] {
        bilingual ? ["he_where_is", w.id] : ["where_is", w.id]
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
    /// Say the Hebrew word before the English one. On by default for Hebrew devices.
    @Published var bilingualHebrew: Bool {
        didSet { UserDefaults.standard.set(bilingualHebrew, forKey: "bilingualHebrew") }
    }

    private init() {
        let d = UserDefaults.standard
        soundEffectsOn = d.object(forKey: "soundEffectsOn") as? Bool ?? true
        musicOn = d.object(forKey: "musicOn") as? Bool ?? true
        bilingualHebrew = d.object(forKey: "bilingualHebrew") as? Bool ?? L10n.isHebrew
    }
}

// ─────────────────────────────────────────────
// MARK: - Progress (stickers, streak, words heard)
// ─────────────────────────────────────────────

final class StickerStore: ObservableObject {
    static let shared = StickerStore()

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

    private let lastPlayedKey = "lastPlayedDate"
    private let stickersKey = "earnedStickers"
    private let streakKey = "streak"
    private let heardKey = "heardWords"
    private let gamesKey = "gamesFinished"

    private init() {
        let d = UserDefaults.standard
        stickers = (d.array(forKey: stickersKey) as? [String]) ?? []
        streak = d.integer(forKey: streakKey)
        heardWords = Set((d.array(forKey: heardKey) as? [String]) ?? [])
        gamesFinished = d.integer(forKey: gamesKey)
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
