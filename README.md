# Baby English 🍼

A native iOS flashcard app for toddlers (ages 1–3) to learn English words through pictures and audio.

## What it does
- Shows emoji flashcards grouped by category (Animals, Food, Colors, etc.)
- Speaks each word aloud automatically when the card appears
- Tap anywhere on screen to advance to the next card
- Long-press the 🏠 button (2 seconds) to go back home — prevents accidental exits
- Celebration screen after completing a category

## Tech Stack
- **100% native SwiftUI** — no web views, no JavaScript
- **AVSpeechSynthesizer** for audio (no audio files needed)
- Supports iPhone and iPad

## Project Structure
```
baby-english/
├── ios/
│   └── App/
│       └── App/
│           ├── AppDelegate.swift   ← entire app lives here
│           ├── Info.plist
│           └── Assets.xcassets/   ← app icon + splash
└── assets/
    └── icon.png                   ← source app icon
```

## Running the app
1. Open `ios/App/App.xcodeproj` in Xcode
2. Select your iPhone or iPad as the target device
3. Press ▶ Run (Cmd+R)
