import XCTest
@testable import App

/// Guards the voice content: every word must have its English clip and its
/// Hebrew bridge clip, and the prompts must exist, or a child hears silence.
final class VoiceTests: XCTestCase {
    func testEveryWordHasEnglishAndHebrewClips() {
        for w in ALL_WORDS {
            XCTAssertTrue(AudioManager.shared.has(w.id), "missing English clip: \(w.id)")
            XCTAssertTrue(AudioManager.shared.has("he_\(w.id)"), "missing Hebrew clip: he_\(w.id)")
        }
    }

    func testPromptClipsExist() {
        for id in ["great_job", "you_did_it", "yay_pip", "try_again", "hi_pip", "celebration", "music_loop"] {
            XCTAssertTrue(AudioManager.shared.has(id), "missing prompt clip: \(id)")
        }
        for w in ALL_WORDS {
            XCTAssertTrue(AudioManager.shared.has("ask_\(w.id)"), "missing question clip: ask_\(w.id)")
            XCTAssertTrue(AudioManager.shared.has("he_ask_\(w.id)"), "missing Hebrew question clip: he_ask_\(w.id)")
        }
    }

    func testBilingualSequencePutsEnglishLast() {
        let dog = ALL_WORDS.first { $0.id == "dog" }!
        let saved = SettingsStore.shared.bilingualHebrew
        defer { SettingsStore.shared.bilingualHebrew = saved }

        SettingsStore.shared.bilingualHebrew = true
        XCTAssertEqual(Voice.word(dog), ["he_dog", "dog"])
        XCTAssertEqual(Voice.whereIs(dog), ["he_ask_dog", "dog"])

        SettingsStore.shared.bilingualHebrew = false
        XCTAssertEqual(Voice.word(dog), ["dog"])
        XCTAssertEqual(Voice.whereIs(dog), ["ask_dog"])
    }

    func testSequenceDurationCoversAllClips() {
        let single = AudioManager.shared.duration(of: "dog")
        let both = AudioManager.shared.say(["he_dog", "dog"], gap: 0.2)
        XCTAssertGreaterThan(both, single + 0.2)
    }
}

final class PromptAndGiftTests: XCTestCase {
    func testPromptMatchesWordKind() {
        let saved = SettingsStore.shared.bilingualHebrew
        defer { SettingsStore.shared.bilingualHebrew = saved }
        SettingsStore.shared.bilingualHebrew = false
        let eyes = ALL_WORDS.first { $0.id == "eyes" }!
        let three = ALL_WORDS.first { $0.id == "three" }!
        XCTAssertEqual(Voice.whereIs(eyes), ["ask_eyes"])
        XCTAssertEqual(Voice.whereIs(three), ["ask_three"])
        SettingsStore.shared.bilingualHebrew = true
        XCTAssertEqual(Voice.whereIs(three), ["he_ask_three", "three"])
    }

    func testWordIdsAreUnique() {
        let ids = ALL_WORDS.map(\.id)
        XCTAssertEqual(ids.count, Set(ids).count)
    }

    func testEveryWordHasADrawnCharacter() {
        for word in ALL_WORDS {
            XCTAssertTrue(CharacterLibrary.has(word.id), "\(word.id) has no drawn character (falls back to emoji)")
            XCTAssertNotNil(CharacterLibrary.view(for: word.id, mood: .idle), word.id)
        }
    }

    func testDailyGiftOnlyOncePerDay() {
        let store = StickerStore.shared
        if store.giftAvailable {
            let before = store.stickers.count
            XCTAssertNotNil(store.claimDailyGift())
            XCTAssertEqual(store.stickers.count, before + 1)
            XCTAssertTrue(StickerStore.giftPool.contains(store.stickers.last!))
        }
        XCTAssertFalse(store.giftAvailable)
        XCTAssertNil(store.claimDailyGift(), "a second gift on the same day must not be possible")
    }
}

final class SmartRepetitionTests: XCTestCase {
    private let store = StickerStore.shared

    func testNewWordIsFavouredOverAverage() {
        let id = "test_\(UUID().uuidString)"
        XCTAssertEqual(store.practiceWeight(id), 1.5)
        XCTAssertFalse(store.isKnown(id))
        XCTAssertFalse(store.isPracticing(id))
    }

    func testMissedWordComesBackMoreOftenUntilKnown() {
        let id = "test_\(UUID().uuidString)"
        store.recordMiss(id)
        XCTAssertTrue(store.isPracticing(id))
        XCTAssertGreaterThan(store.practiceWeight(id), 1.5)

        store.recordCorrect(id, firstTry: true)
        XCTAssertFalse(store.isKnown(id), "one win is not enough")
        store.recordCorrect(id, firstTry: true)
        XCTAssertTrue(store.isKnown(id))
        XCTAssertFalse(store.isPracticing(id))
        XCTAssertLessThan(store.practiceWeight(id), 1)
    }

    func testWinAfterMissesDoesNotBuildStreak() {
        let id = "test_\(UUID().uuidString)"
        store.recordCorrect(id, firstTry: true)
        store.recordCorrect(id, firstTry: false)
        store.recordCorrect(id, firstTry: true)
        XCTAssertFalse(store.isKnown(id))
    }

    func testWeightedPickPrefersStrugglingWords() {
        let hard = WordItem(id: "test_hard_\(UUID().uuidString)", label: "Hard", emoji: "🧩", bg: .white, textColor: .black)
        let easy = WordItem(id: "test_easy_\(UUID().uuidString)", label: "Easy", emoji: "🍬", bg: .white, textColor: .black)
        for _ in 0..<4 { store.recordMiss(hard.id) }
        store.recordCorrect(easy.id, firstTry: true); store.recordCorrect(easy.id, firstTry: true)
        var hardCount = 0
        for _ in 0..<2000 where store.pickForPractice(from: [hard, easy])?.id == hard.id { hardCount += 1 }
        XCTAssertGreaterThan(hardCount, 1600, "a struggling word should be asked far more often than a known one")
    }
}

final class FeedbackTests: XCTestCase {
    func testFeedbackEmailCarriesOnlyTechnicalInfo() {
        let body = FeedbackMail.body(.okay)
        XCTAssertTrue(body.contains(AppInfo.version))
        XCTAssertTrue(body.contains(UIDevice.current.systemVersion))
        // nothing about the child: no words, stickers or progress
        for w in ALL_WORDS.prefix(10) { XCTAssertFalse(body.contains(w.label)) }
        XCTAssertFalse(body.lowercased().contains("sticker"))
    }

    func testMailtoNeedsAnAddress() {
        if AppInfo.supportEmail.isEmpty {
            XCTAssertNil(FeedbackMail.mailtoURL(.okay))
        } else {
            let url = FeedbackMail.mailtoURL(.notForUs)
            XCTAssertEqual(url?.scheme, "mailto")
            XCTAssertTrue(url?.absoluteString.contains("subject=") ?? false)
        }
    }

    func testSupportEmailIsSetBeforeRelease() throws {
        try XCTSkipIf(AppInfo.supportEmail.isEmpty,
                      "Set AppInfo.supportEmail (Feedback.swift) before submitting, so unhappy parents can email instead of leaving a 1-star review")
        XCTAssertTrue(AppInfo.supportEmail.contains("@"))
    }
}

final class MusicTests: XCTestCase {
    func testMusicPlaysOnlyWhereNothingIsTaught() {
        let s = SettingsStore.shared, a = AudioManager.shared
        let (wasOn, wasCalm) = (s.musicOn, s.calmMode)
        defer {
            s.musicOn = wasOn; s.calmMode = wasCalm
            a.setCelebrating(false); a.setMusicScene(allowed: true); a.pauseMusic()
        }
        s.musicOn = true; s.calmMode = false
        a.setMusicScene(allowed: Screen.home.allowsMusic)
        XCTAssertTrue(a.musicShouldPlay, "home has music")
        a.setMusicScene(allowed: Screen.findIt.allowsMusic)
        XCTAssertFalse(a.musicShouldPlay, "learning games are quiet")
        a.setMusicScene(allowed: Screen.bubbles.allowsMusic)
        XCTAssertFalse(a.musicShouldPlay)
        a.setCelebrating(true)
        XCTAssertTrue(a.musicShouldPlay, "celebrations bring the music back")
        a.setCelebrating(false)
        a.setMusicScene(allowed: Screen.stickers.allowsMusic)
        s.calmMode = true
        XCTAssertFalse(a.musicShouldPlay, "calm mode is silent")
        s.calmMode = false; s.musicOn = false
        XCTAssertFalse(a.musicShouldPlay, "parent switched it off")
    }
}

@MainActor
final class DeveloperUnlockTests: XCTestCase {
    override func setUp() async throws {
        try await super.setUp()
        PurchaseManager.paywallEnabled = true
    }

    override func tearDown() async throws {
        PurchaseManager.paywallEnabled = false
        try await super.tearDown()
    }

    func testDeveloperUnlockOpensEveryWorldInDebugBuilds() {
        let store = PurchaseManager.shared
        let saved = store.developerUnlock
        defer { store.developerUnlock = saved }
        store.developerUnlock = false
        if !store.isUnlocked {
            XCTAssertFalse(ALL_CATEGORIES.allSatisfy { store.isAvailable($0) })
        }
        store.developerUnlock = true
        XCTAssertTrue(ALL_CATEGORIES.allSatisfy { store.isAvailable($0) })
        XCTAssertEqual(store.availableWords.count, ALL_WORDS.count)
    }
}
