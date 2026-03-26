<div align="center">

# 🍼 Baby English

**A native iOS flashcard app that helps toddlers (ages 1–3) learn English words through pictures and audio.**

![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20iPadOS-blue?logo=apple)
![Language](https://img.shields.io/badge/Language-Swift-orange?logo=swift)
![UI](https://img.shields.io/badge/UI-SwiftUI-purple)
![License](https://img.shields.io/badge/License-MIT-green)

</div>

---

## ✨ Features

| Feature | Description |
|---|---|
| 🃏 **Flashcards** | Emoji-based cards grouped by category (Animals, Food, Colors & more) |
| 🔊 **Auto Audio** | Word is spoken aloud the moment each card appears |
| 👆 **Tap Anywhere** | The entire screen advances to the next card — no small buttons |
| 🏠 **Toddler-Safe Nav** | Long-press 🏠 for 2 seconds to go home — prevents accidental exits |
| 🎉 **Celebration** | Animated star burst after completing a category |
| 📱 **Universal** | Runs natively on both iPhone and iPad |

---

## 🛠 Tech Stack

- **100% native SwiftUI** — zero web views, zero JavaScript
- **AVSpeechSynthesizer** — built-in iOS text-to-speech, no audio files needed
- **Single-file architecture** — entire app lives in `AppDelegate.swift`

---

## 📁 Project Structure

```
baby-english/
├── ios/
│   └── App/
│       └── App/
│           ├── AppDelegate.swift     ← entire app (UI + logic + data)
│           ├── Info.plist            ← app configuration
│           └── Assets.xcassets/      ← app icon & splash screen
└── assets/
    └── icon.png                      ← source app icon
```

---

## 🚀 Running the App

1. Open `ios/App/App.xcodeproj` in **Xcode**
2. Select your **iPhone or iPad** as the target device
3. Press **▶ Run** (`Cmd + R`)

> **Requirements:** Xcode 15+, iOS 16+, an Apple Developer account (free tier works for personal devices)

---

## 🎨 Design Philosophy

Designed specifically for 2-year-olds — one giant tap area, instant audio feedback, zero cognitive load, and pure visual delight. A child can use this app completely independently.

---

<div align="center">
Made with ❤️ for little learners
</div>
