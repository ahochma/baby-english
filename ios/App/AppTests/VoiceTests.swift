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
