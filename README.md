<div align="center">

# 🐣 Pip English (אנגלית עם פיפ)

**First English words for kids aged 3–6, with pictures, a clear voice, a friendly mascot and three games built for little hands.**

![Platform](https://img.shields.io/badge/Platform-iOS%2016%2B%20%7C%20iPadOS-blue?logo=apple)
![Language](https://img.shields.io/badge/Language-Swift-orange?logo=swift)
![UI](https://img.shields.io/badge/UI-SwiftUI-purple)
![Kids](https://img.shields.io/badge/App%20Store-Kids%20Category-green)

</div>

---

## ✨ What's inside

| | Feature | Age |
|---|---|---|
| 🃏 | **Flashcards**: tap anywhere for the next word, swipe back, auto-repeats if the child just looks | 3+ |
| 🫧 | **Bubbles**: floating bubbles carry pictures; popping says the word. Any touch makes a splash, so there's no way to fail | 3+ |
| 🔍 | **Find it!**: hear a word, find the picture. Starts with 2 choices, adapts up to 4, and guides the child after two misses | 3+ |
| 🏆 | **Stickers & celebrations**: every finished round earns a sticker | all |
| 🎁 | **Daily surprise**: once a day Pip leaves a gift with a special sticker | all |
| 🔒 | **Parent Zone** (behind a parental gate): progress, settings, restore, privacy, tips | parents |
| 💳 | **One-time unlock** (StoreKit 2): Animals and all games are free; one purchase unlocks Vehicles, Food, Colors, My Body & Numbers (60 words) | parents |

### Built for little kids (3–6)
- Chunky toy-style buttons that press down like real ones, soft rounded shapes, sky-and-hills scenery
- **Pip**, an original mascot drawn in code: blinks, breathes, cheers when the child succeeds
- **Spoken prompts** ("Where is the dog?", "Great job!", "Oops! Try again!") and a **Hebrew → English mode** ("כלב… Dog!") for Israeli families
- Gentle original **background music** (parent toggle)
- Multi-touch catcher: palms and several fingers register instantly
- Debounced navigation: tap bursts never skip a card or open the wrong screen
- Hold-to-exit house button; status bar and home indicator hidden; system edge gestures deferred
- Plays sound in silent mode and mixes with the parent's music
- Words are cached, so voice starts the moment a finger lands
- Kid screens always read left-to-right; grown-up screens are fully translated into **Hebrew (RTL)**

### App Store ready
- Kids Category compliant: parental gate before purchases, settings and links; no ads, analytics or tracking
- `PrivacyInfo.xcprivacy` privacy manifest
- StoreKit config (`Products.storekit`) wired into the shared scheme for local purchase testing
- Full-bleed app icon, light-mode lock, iPad multi-orientation

---

## 📁 Project structure

```
ios/App/
├── App.xcodeproj               (shared "App" scheme with StoreKit config)
└── App/
    ├── AppDelegate.swift       app entry, kid-safe hosting controller
    ├── RootView.swift          navigation + parent flow (gate → paywall / parent zone)
    ├── Models.swift            words & categories
    ├── Services.swift          audio, haptics, settings, progress store
    ├── PurchaseManager.swift   StoreKit 2 one-time unlock
    ├── Theme.swift             colors, L10n, touch catcher, confetti, shared UI
    ├── Mascot.swift            Pip, the original mascot (vector, animated)
    ├── HomeView.swift
    ├── FlashcardView.swift
    ├── BubblePopView.swift
    ├── FindItView.swift
    ├── CelebrationView.swift
    ├── StickerBoardView.swift
    ├── ParentalGateView.swift
    ├── PaywallView.swift       (+ privacy policy screen)
    ├── ParentZoneView.swift
    ├── Audio/                  ElevenLabs word clips + synthesized sound effects
    ├── PrivacyInfo.xcprivacy
    └── Products.storekit
ios/App/AppTests/               StoreKit purchase-flow tests
docs/
├── APP_STORE.md                submission checklist, listing copy (EN/HE), review notes
├── GO_TO_MARKET.md             plan for the first 50 paying families
└── privacy-policy.md           host this and use its URL in App Store Connect
```

## 🚀 Running

1. Open `ios/App/App.xcodeproj` in Xcode 15+
2. Pick an iPhone or iPad simulator and press **⌘R**
3. Purchases work offline in the simulator through `Products.storekit`

To ship, follow [docs/APP_STORE.md](docs/APP_STORE.md).

---

<div align="center">
Made with ❤️ for little learners
</div>
