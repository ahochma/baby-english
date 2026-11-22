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

/// Plays the bundled voice clips and synthesized sound effects.
/// Voice clips are cached so playback starts instantly — toddlers expect the
/// word the very moment they touch something.
final class AudioManager {
    static let shared = AudioManager()

    private var voiceCache: [String: AVAudioPlayer] = [:]
    private var currentVoice: AVAudioPlayer?
    private var sfxPools: [SFX: [AVAudioPlayer]] = [:]

    private init() {}

    /// `.playback` keeps sound on even when the ring/silent switch is on —
    /// parents almost always have their phone on silent, and a "broken" silent
    /// app is the #1 complaint for baby apps. `mixWithOthers` avoids stopping
    /// a parent's podcast or music.
    func configureSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)
        preload()
    }

    private func preload() {
        DispatchQueue.global(qos: .userInitiated).async {
            var voices: [String: AVAudioPlayer] = [:]
            for word in ALL_WORDS + [WordItem(id: "celebration", label: "", emoji: "", bg: .clear, textColor: .clear)] {
                if let url = Bundle.main.url(forResource: word.id, withExtension: "mp3"),
                   let p = try? AVAudioPlayer(contentsOf: url) {
                    p.prepareToPlay()
                    voices[word.id] = p
                }
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

    /// Plays a spoken word. A new word always interrupts the previous one so
    /// the voice matches what the child is looking at.
    func play(_ audioId: String) {
        currentVoice?.stop()
        let player: AVAudioPlayer?
        if let cached = voiceCache[audioId] {
            player = cached
        } else if let url = Bundle.main.url(forResource: audioId, withExtension: "mp3") {
            player = try? AVAudioPlayer(contentsOf: url)
            if let player { voiceCache[audioId] = player }
        } else {
            player = nil
        }
        player?.currentTime = 0
        player?.volume = 1.0
        player?.play()
        currentVoice = player
    }

    func duration(of audioId: String) -> TimeInterval {
        voiceCache[audioId]?.duration ?? 1.0
    }

    func play(_ sfx: SFX, volume: Float = 0.7) {
        guard SettingsStore.shared.soundEffectsOn else { return }
        guard let pool = sfxPools[sfx], !pool.isEmpty else { return }
        let player = pool.first(where: { !$0.isPlaying }) ?? pool[0]
        player.currentTime = 0
        player.volume = volume
        player.play()
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

    private init() {
        soundEffectsOn = UserDefaults.standard.object(forKey: "soundEffectsOn") as? Bool ?? true
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
