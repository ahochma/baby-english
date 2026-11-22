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
        for id in ["where_is", "where_are", "where_is_number", "he_where_is", "he_where_is_number",
                   "great_job", "you_did_it", "yay_pip", "try_again", "hi_pip", "celebration", "music_loop"] {
            XCTAssertTrue(AudioManager.shared.has(id), "missing prompt clip: \(id)")
        }
    }

    func testBilingualSequencePutsEnglishLast() {
        let dog = ALL_WORDS.first { $0.id == "dog" }!
        let saved = SettingsStore.shared.bilingualHebrew
        defer { SettingsStore.shared.bilingualHebrew = saved }

        SettingsStore.shared.bilingualHebrew = true
        XCTAssertEqual(Voice.word(dog), ["he_dog", "dog"])
        XCTAssertEqual(Voice.whereIs(dog), ["he_where_is", "dog"])

        SettingsStore.shared.bilingualHebrew = false
        XCTAssertEqual(Voice.word(dog), ["dog"])
        XCTAssertEqual(Voice.whereIs(dog), ["where_is", "dog"])
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
        XCTAssertEqual(Voice.whereIs(eyes), ["where_are", "eyes"])
        XCTAssertEqual(Voice.whereIs(three), ["where_is_number", "three"])
        SettingsStore.shared.bilingualHebrew = true
        XCTAssertEqual(Voice.whereIs(three), ["he_where_is_number", "three"])
    }

    func testWordIdsAreUnique() {
        let ids = ALL_WORDS.map(\.id)
        XCTAssertEqual(ids.count, Set(ids).count)
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
