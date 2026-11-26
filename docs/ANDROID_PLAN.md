# Pip English for Android: build and launch plan

This plan rebuilds **Pip English** (the iOS app in this repo) as a **native Android app** in its own repository, then publishes it on **Google Play**. The aim is the same product built the same way:

- characters drawn in code
- ElevenLabs voices recorded as whole sentences
- one purchase that unlocks everything, with no subscription
- a parental gate in front of anything meant for grown-ups
- no ads, no tracking and no accounts
- a demo mode for screenshots
- tests and CI on every change

> **How to use this file:** create the new repository (suggested name `pip-english-android`) and copy this file into it as `PLAN.md`. Keep this iOS repo checked out next to it. The Android app ports code from here, and the **audio, voice script, word list and store copy are reused as they are**. Work one phase at a time. Each phase ends with a "Done when" check.

Requirements below were checked against Google's documentation on 26 Nov 2026 (see [Sources](#sources)). Re-check the Play Console before submitting, because Google changes these yearly.

---

## 0. Summary: cost, timeline and the critical path

| Item | Cost / time |
|---|---|
| Google Play developer account | **US$25 once** (no yearly fee); identity verification takes about 3 business days |
| Mac / Apple fee | Not needed. Android Studio runs on macOS, Windows or Linux |
| ElevenLabs | Already paid; the existing clips are reused (Starter plan includes a commercial license) |
| Build (phases 1–7) | About 3–5 weeks of evenings with Claude Code |
| **Closed test before production** | **12 testers opted in for 14 days in a row.** This applies to every personal account created after 13 Nov 2023 |

**Critical path:** the 14-day closed test is the longest wait you can't speed up. Open the Play Console account **on day 1** and upload a first internal build as soon as phase 2 works. Then start the closed test with 12+ friends and family early, while you finish the app. Testers can keep using new builds during the 14 days.

---

## 1. Decisions (already made, so they stay consistent with iOS)

| Decision | Value | Why |
|---|---|---|
| Language / UI | **Kotlin + Jetpack Compose** | The direct counterpart of Swift + SwiftUI; the iOS code ports almost 1:1 |
| Package name | **`com.pipenglish.app`** | Same as the iOS bundle ID. **It can never be changed after the first upload** |
| Product ID (one-time) | **`full_unlock`** | Play product IDs are lowercase; one non-consumable "Unlock everything" |
| minSdk / targetSdk | **24 / 36** | 24 (Android 7) reaches nearly all devices; **36 is required for new apps since 31 Aug 2026** |
| Billing | **Play Billing Library 8.x** | v7 can no longer be used for new apps or updates since 2026; v8 is the minimum until Aug 2027 |
| Free tier | Animals world and every game | Same as iOS (`FREE_CATEGORY_ID = "animals"`) |
| Price | Same as iOS, set per country in Play Console | Decide later, after seeing real buyers (same approach as iOS) |
| Third-party SDKs | **None** (no analytics, crash reporting or ads) | Families policy, and a Data safety form that says "No data collected" |
| Internet permission | **Not requested** | Billing runs through the Play Store app; the app itself never goes online |
| Fonts | **Nunito** (English) + **Varela Round** (Hebrew), both open-source (OFL) | Stand-ins for SF Rounded, which is Apple-only |

---

## 2. What carries over unchanged

Copy these from the iOS repo into the Android repo. Don't recreate them.

| From iOS repo | To Android repo | Notes |
|---|---|---|
| `ios/App/App/Audio/*.m4a` (247 voice clips + `music_loop.m4a`) | `app/src/main/res/raw/` | AAC `.m4a` plays natively on Android. All file names are already valid resource names (lowercase, `a-z 0-9 _`). |
| `ios/App/App/Audio/sfx_*.wav` (5 effects) | `app/src/main/res/raw/` | Don't copy `dog.mp3.wav`; it's a leftover, not a sound effect. |
| `scripts/voice_lines.json`, `scripts/generate_voice.py`, `scripts/.env.example` | `scripts/` | Add an `--out` option that points at `res/raw`. The same ElevenLabs voices are used (Teacher Ella EN, Dalit HE, `eleven_v3`, whole sentences). Keep `scripts/.env` **gitignored**. |
| `scripts/generate_music.py` | `scripts/` | The original music-box loop. |
| Word list and categories (`ios/App/App/Models.swift`) | `app/.../model/Words.kt` | 6 worlds × 10 words = 60. Keep the same ids, labels, emoji fallbacks, colors and prompt kinds, plus the sticker pools and the gift pool. |
| Store copy (`fastlane/metadata/en-US`, `fastlane/metadata/he`) | `fastlane/metadata/android/en-US`, `.../iw-IL` | Play uses different file names and length limits (see Phase 8). |
| Privacy policy + site (`docs/`, GitHub Pages) | Same URLs | Add an "Android" line. Nothing else changes, because neither app collects data. |
| Brand (`scripts/brand/`, Pip icon render) | `app/src/main/res/` adaptive icon + 512×512 store icon | |
| Docs: `GO_TO_MARKET.md`, `LAUNCH_50.md`, `ANALYTICS.md` | Link to them | Same audience, same message ("Pay once. No subscription. No account."). |

---

## 3. iOS to Android map (file by file)

| iOS (this repo, `ios/App/App/`) | Android (new repo, `app/src/main/java/com/pipenglish/app/`) | How |
|---|---|---|
| `AppDelegate.swift` | `PipApp.kt` (Application) + `MainActivity.kt` | Activity sets content with `setContent { PipRoot() }`. Music pauses in `onStop` and resumes in `onStart` (lifecycle observer). |
| `RootView.swift` (`Screen` enum, 0.6 s navigation debounce, kid screens forced left-to-right) | `ui/PipRoot.kt` | `sealed interface Screen`, `AnimatedContent` with fade + 1.03 scale, the same 600 ms debounce, and `CompositionLocalProvider(LocalLayoutDirection provides Ltr)` around kid screens. **New on Android:** a `BackHandler` on every kid screen goes to Home and never exits a game by accident. |
| `Theme.swift` (Palette, ChunkyButton, CharacterBadge, `Motion.reduced`, `DemoMode`, `L10n`) | `ui/theme/*.kt` | The same hex colors. `ChunkyButton` is a custom composable (shadow offset that sinks on press, with `interactionSource`). `Motion.reduced` = system "Remove animations" (`ANIMATOR_DURATION_SCALE == 0`) **or** calm mode. |
| `Characters.swift`, `CharactersWorlds.swift`, `Mascot.swift` | `ui/characters/*.kt` | See **§4**: the biggest port, drawn on `Canvas` in the same 100×100 grid. |
| `HomeView.swift` | `ui/home/HomeScreen.kt` | 6 world cards with drawn cover characters (colors → purple drop, numbers → "3"), Bubbles, Find it!, My Stickers, daily gift, lock badges. |
| `FlashcardView.swift` | `ui/games/FlashcardScreen.kt` | `HorizontalPager`; tapping plays `Voice.word`; the character turns happy on bounce. |
| `BubblePopView.swift` | `ui/games/BubblePopScreen.kt` | Bubbles float on a `withFrameNanos` loop; **12 pops = 1 sticker**; the burst shows the character + word banner. |
| `FindItView.swift` | `ui/games/FindItScreen.kt` | Asks with `Voice.whereIs`; **5 rounds = 1 sticker**; uses the smart-repetition pick; 2 or 4 cards. |
| `CelebrationView.swift` | `ui/games/Celebration.kt` | Sticker reveal (`StickerArt`, happy mood), confetti (off in calm mode), "Yaaay! Great job!" clip, auto-dismiss after 4.5 s in games. |
| `StickerBoardView.swift` (`StickerArt`) | `ui/stickers/StickerBoardScreen.kt` | Albums by world + Surprises + Extras. A sticker whose emoji matches a word shows the drawn character; otherwise it shows the emoji. |
| `ParentalGateView.swift` | `ui/parents/ParentalGate.kt` | The same gate: a random multiplication (3–9 × 4–9) on a number pad, with a shake when wrong. |
| `ParentZoneView.swift` | `ui/parents/ParentZoneScreen.kt` | Toggles: Hebrew→English, calm mode, music ("only home/stickers/celebrations"), sound effects. Buttons: restore, **redeem a code**, feedback, privacy. Debug builds only: **Developer: unlock everything**. |
| `PaywallView.swift` | `ui/parents/PaywallScreen.kt` | The same copy: "Pay once. No subscription, no trial that turns into charges, nothing ever renews." |
| `PurchaseManager.swift` | `billing/PurchaseManager.kt` | See **§6**. |
| `Services.swift`: `AudioManager` | `audio/AudioManager.kt` | See **§5**. |
| `Services.swift`: `Voice` | `audio/Voice.kt` | `word(w)` = bilingual ? `["he_$id", id]` : `[id]`. `whereIs(w)` = bilingual ? `["he_ask_$id", id]` : `["ask_$id"]`. `praise()` = one of `great_job`, `you_did_it`, `yay_pip`. |
| `Services.swift`: `SettingsStore`, `StickerStore` | `data/SettingsRepository.kt`, `data/ProgressRepository.kt` | **DataStore (Preferences)** + `kotlinx.serialization` for `wordStats`, exposed as `StateFlow`. |
| `Services.swift`: `Haptics` | `ui/Haptics.kt` | `LocalHapticFeedback` for taps; `VibrationEffect.createPredefined(EFFECT_CLICK)` for success on API 29+, with `createOneShot(30, DEFAULT_AMPLITUDE)` below that (minSdk is 24). |
| `Feedback.swift` | `ui/parents/Feedback.kt` | `Intent(ACTION_SENDTO, "mailto:")` with only technical info (app version, Android version, device model): no IDs and nothing about the child. `SUPPORT_EMAIL` must be set before release (there's a test for it, as on iOS). |
| `Info.plist`, `PrivacyInfo.xcprivacy` | `AndroidManifest.xml` | `supportsRtl=true`, no `INTERNET`, `locales_config.xml` (en, iw). |
| `Products.storekit` + `AppTests/PurchaseTests.swift` | Play Console **license testers** + `PurchaseManagerTest.kt` with a fake BillingClient | There's no local StoreKit file on Android; test the logic against a fake and the real flow with license testers. |
| `AppTests/VoiceTests.swift` (all test classes) | `app/src/test/...` (JVM, Robolectric) | Port every test: every word has EN + HE clips and `ask_` + `he_ask_` questions, the bilingual sequence puts English last, gift once a day, smart repetition, music only where nothing is taught, the dev unlock opens everything, every word has a drawn character, and the feedback email holds only technical info. |

**Rules carried over exactly (put them in code as named constants):**

| Rule | Value |
|---|---|
| Navigation debounce | 600 ms |
| Find it! | 5 rounds per sticker |
| Bubbles | 12 pops per sticker |
| Smart repetition | known after **2** first-try wins in a row; pick weight: new **1.5**, known **0.35**, missed **1 + 0.75 × min(misses, 4)**, otherwise **1**; a win after misses resets the streak |
| Daily gift | once per calendar day, drawn from the gift pool, preferring stickers not owned yet |
| Music | volume **0.13**, fade in 0.8 s / out 0.5 s; plays only on Home, Stickers and Celebration; off in calm mode or when the parent switches it off |
| Free world | `animals` |

---

## 4. Characters: porting the drawings

On iOS every character is a SwiftUI view inside `CharacterRig`. The rig blinks every 2.4–5 s for 130 ms and breathes with a 1.4–1.8 s squash-and-stretch. In the happy mood it lifts by 3 units with closed ∩ eyes. Everything lives in a **100×100 grid**, where the shadow sits at y = +45.

**Android version:**

```kotlin
@Composable
fun CharacterRig(mood: Mood, modifier: Modifier = Modifier, draw: DrawScope.(closed: Boolean) -> Unit) {
    // blink: LaunchedEffect loop with random delay 2.4–5 s, 130 ms closed
    // breathe: rememberInfiniteTransition (skipped when Motion.reduced)
    // happy: animate lift -3 units with spring(dampingRatio = 0.5f)
    Canvas(modifier.aspectRatio(1f)) {
        val s = size.minDimension / 100f            // same "s" as iOS
        translate(size.width / 2, size.height / 2) { // iOS offsets are from the centre
            drawOval(Color.Black.copy(alpha = .10f), topLeft = Offset(-28 * s, 41 * s), size = Size(56 * s, 8 * s))
            withTransform({ scale(sx, sy, pivot = Offset(0f, 45 * s)); translate(0f, lift * s) }) { draw(closed) }
        }
    }
}
```

**Translation table for drawing primitives:**

| SwiftUI | Compose `DrawScope` |
|---|---|
| `Ellipse().frame(w, h).offset(x, y)` | `drawOval(brush, topLeft = Offset((x - w/2)*s, (y - h/2)*s), size = Size(w*s, h*s))` |
| `Circle().frame(width: d)` | `drawCircle(brush, radius = d/2*s, center = Offset(x*s, y*s))` |
| `Capsule()` | `drawRoundRect(..., cornerRadius = CornerRadius(min(w, h)/2*s))` |
| `RoundedRectangle(cornerRadius: r)` | `drawRoundRect(..., cornerRadius = CornerRadius(r*s))` |
| Custom `Shape` (`AppleShape`, `BananaShape`, `DropShape`, `ToothShape`, `EarShape`, …) | `Path().apply { moveTo(); cubicTo(); close() }`: copy the unit points `r.u(x, y)` directly |
| `.stroke(color, lineWidth)` | `drawPath(path, color, style = Stroke(width = lw*s, cap = StrokeCap.Round))` |
| `RadialGradient(center: (0.38, 0.3), endRadius: r)` | `Brush.radialGradient(colors, center = shapeTopLeft + shapeSize * (0.38, 0.3), radius = r*s)` |
| `LinearGradient(top → bottom)` | `Brush.verticalGradient(colors, startY, endY)` |
| `.rotationEffect(.degrees(a), anchor:)` | `rotate(a, pivot = …)` inside `withTransform` |
| `ForEach([-1.0, 1.0]) { side in … }` | `for (side in listOf(-1f, 1f)) { … }` |
| `Text("\(n)")` (NumberBuddy) | `drawText(textMeasurer, …)` with Nunito Black |
| `Image(systemName: "sparkle" / "star.fill" / "music.note")` | Small `Path`s, or Material Symbols vector drawables |

**Order of work:**
1. Pip (the mascot).
2. Animals (dog, cat, duck first: the original pilot).
3. Vehicles, food, colors (one parameterized `PaintDrop`), body, then numbers (`NumberBuddy`).

**Checking the drawings:** add **Roborazzi** (JVM screenshot tests). For each world, render a sheet in the same layout as iOS: idle + happy per word. Compare it side by side with `marketing/raw/characters_<world>.png` from this repo. The snapshots then guard against drawing regressions in CI. This is the same "render a sheet, look at it, fix" loop the iOS characters went through.

Add the same test as iOS: **every word has a drawn character**.

---

## 5. Audio

| Need | Android |
|---|---|
| Sound effects (5 short `.wav`) | **`SoundPool`** (4 streams), loaded at start |
| Voice sequences (`say(ids, gap)`, which returns its total duration) | **Media3 ExoPlayer** with a playlist of `res/raw` clips plus short silences, or two pre-prepared `MediaPlayer`s ping-ponging. One sequence plays at a time, and a new one stops the old one. |
| Clip durations (the games time their UI to the voice) | Have `generate_voice.py` also write **`res/raw/durations.json`** (id → ms), so the timing is exact and costs nothing at run time |
| Music loop | `MediaPlayer(isLooping = true)`, with volume ramped by a coroutine (0 → 0.13 in 0.8 s; down in 0.5 s, then pause). Music follows `Screen.allowsMusic` plus a "celebrating" flag, exactly like iOS. |
| Audio focus | `AudioAttributes(USAGE_GAME)`; request focus while playing and pause on loss (phone call, other apps) |
| Silent mode | Android has no silent switch for media; music and voice follow the media volume, which is expected on Android |

---

## 6. Billing (Play Billing Library 8)

**Setup:** in Play Console → *Monetize → Products → One-time products*, create `full_unlock` and give it the same name and description as iOS.

**Code (`billing/PurchaseManager.kt`):**
- **Connect:** build the `BillingClient` with `enablePendingPurchases(PendingPurchasesParams.newBuilder().enableOneTimeProducts().build())`, then `startConnection`, with a retry and backoff when the connection is lost.
- **Load:** `queryProductDetailsAsync(full_unlock)` → `formattedPrice` for the paywall.
- **Buy:** `launchBillingFlow`.
  - In `onPurchasesUpdated`, a purchase in state `PURCHASED` unlocks everything, then you **`acknowledgePurchase`**. Unacknowledged purchases are **refunded automatically after 3 days**.
  - State `PENDING` shows the iOS message "waiting for approval, will unlock automatically".
- **Entitlement on every start and resume:** `queryPurchasesAsync(INAPP)`.
  - This also handles restores (automatic on Android, but keep the **Restore** button; it simply re-queries).
  - It also handles refunds: a refunded purchase stops appearing, and the app locks again.
  - Cache the result in DataStore, so the app works offline.
- **No server:** verification is local. At this price that's a reasonable trade-off, the same choice as iOS. Server-side verification can be added later if fraud shows up.

**Free access for you and friends (the Android version of what iOS has):**

| Who | How |
|---|---|
| **You, on your phone** | Debug builds only: the "Developer: unlock everything" toggle, plus a launch extra, compiled out of release builds through `BuildConfig.DEBUG`: `adb shell am start -n com.pipenglish.app/.MainActivity --ez developerUnlock true` |
| **Friends during testing** | Add their Gmail addresses under **Play Console → Settings → License testing**. Their purchases go through the real flow but **are never charged.** This works on the internal, closed and production tracks. |
| **Friends after launch** | **Promo codes:** up to **500 per quarter** for one-time products. Unused codes expire at the end of the quarter. They redeem the code in the Play Store app, or through the in-app **"Redeem a code"** button (behind the parental gate), which opens `https://play.google.com/redeem?code=`. The purchase then arrives through `onPurchasesUpdated` / `queryPurchasesAsync`. |

As on iOS, **never** add a secret password that unlocks paid content. Google Play's Payments policy requires the Play billing system for unlocking digital content.

---

## 7. Phases

Each phase ends with commits, a green CI run and a short demo on a real device.

### Phase 0: accounts and repository (day 1)
1. Open a **Google Play Console** account (personal, US$25) and complete identity verification (about 3 business days).
2. Create the GitHub repo `pip-english-android` with this file as `PLAN.md`, plus `.gitignore` covering:
   - `local.properties`
   - `*.jks`
   - `keystore.properties`
   - `scripts/.env`
   - `play-service-account.json`
3. Install Android Studio (latest stable) and create an emulator (Pixel, API 36). Enable **USB debugging** on your Android phone. If you don't own one, borrow one, because real-device testing matters for audio and touch.
4. In Play Console, create the app (name "Pip English: First Words", default language English). The package name is set by the first upload.

**Done when:** the account is verified and the app exists in Play Console.

### Phase 1: skeleton
- Set up the Gradle version catalog, Compose BOM, Kotlin, minSdk 24 / target and compile 36, and R8 for release.
- Build the theme (colors, Nunito / Varela Round, ChunkyButton), plus `PipRoot` navigation with debounce, LTR kid screens and BackHandler.
- Copy in the audio; write `AudioManager` and `Voice`.
- Build Home with **emoji placeholders**, and set up edge-to-edge insets. Edge-to-edge is enforced when targeting API 35+, and on 36 it can't be turned off.
- Add the debug **demo mode**: `--es startScreen bubbles|findit|stickers|cards|cards:<world>` and `--ez demoMode true`.

**Done when:** Home shows all 6 worlds, tapping one plays its word, and CI builds.

### Phase 2: the three games + rewards
- Flashcards, Bubbles (12 pops), Find it! (5 rounds, 2/4 cards), Celebration, the sticker album, the daily gift and smart repetition, using the exact constants from §3.
- Port all the non-billing unit tests.
- **Upload the first internal-testing build now** (signed AAB, see Phase 9), and **start the closed test with 12+ testers.**

**Done when:** a child can play every game end to end on a real phone.

### Phase 3: characters
- Pip + 60 characters, per §4, with Roborazzi sheets for every world, plus the "every word has a drawn character" test.

**Done when:** the sheets match the iOS sheets and no emoji is left in the kid screens.

### Phase 4: parents
- Parental gate, Parent Zone (all toggles), paywall, feedback, privacy page, and the developer unlock (debug only).
- Hebrew strings in `values-iw/strings.xml`; grown-up screens follow the device direction.

**Done when:** every grown-up surface sits behind the gate, and a release build contains no developer toggle (verify, as on iOS, by checking the release APK).

### Phase 5: billing
- `PurchaseManager` per §6, tested with a fake client.
- Real buy, refund and promo-code flows tested with license testers on the internal track.

**Done when:** buy → unlocked → refund in Play Console → locked again on next launch.

### Phase 6: polish and accessibility
- TalkBack labels on all controls (the same labels as iOS).
- Touch targets ≥ 64 dp.
- System "Remove animations" respected, and calm mode.
- Tablet layout (`sw600dp`), landscape check, Hebrew-device check.
- Parent tip: **App pinning** (Settings → Security → App pinning) keeps a child inside the app. It's the Android counterpart of iPhone's Guided Access.

**Done when:** a full pass with TalkBack on, and a pass on a tablet emulator.

### Phase 7: store assets
- **Screenshots:**
  - Run demo mode on the emulator and capture with `adb exec-out screencap -p > shot.png`.
  - Frame them with the same captions and colors as the iOS set, at 1080×1920 (9:16).
  - The iOS compositor (`compose.swift`, a scratch tool, not in the repo) can be rewritten in Python/Pillow.
  - Produce at least 2 phone shots (use the same 6), plus 7" and 10" tablet shots if possible.
- **Feature graphic:** 1024×500 (required): Pip + a few characters + "Pay once · No ads".
- **Icon:** a 512×512 PNG, plus an adaptive icon with a monochrome layer for themed icons.

### Phase 8: Play Console listing and policy forms
- **Store listing** (fastlane `supply` folder `fastlane/metadata/android/<locale>/`):
  - `title.txt` (≤ 30): "Pip English: First Words"; Hebrew "אנגלית עם פיפ: מילים ראשונות"
  - `short_description.txt` (≤ 80)
  - `full_description.txt` (≤ 4000)
  - images under `images/phoneScreenshots/`, `featureGraphic.png`, `icon.png`
  - Locales: `en-US` and **`iw-IL`** (Play's code for Hebrew)
- **App content** (all required):
  - **Target audience:** ages **5 and under** and **6–8** (the app is for 3–6). This puts the app under the **Families policy**.
  - **Data safety:** no data collected, no data shared, no third-party SDKs. Feedback opens the parent's own email app; the app itself sends nothing.
  - **Ads:** no.
  - **Content rating:** the IARC questionnaire (expect "Everyone" / PEGI 3).
  - **Privacy policy URL:** the GitHub Pages page.
  - **App access:** everything is available without login.
  - Declarations for news / government / financial / health: not applicable.
- Category: **Education**; tags: kids, language learning.
- **Teacher Approved:** there's no application. Apps in the Families program are considered automatically, and a well-made, ad-free app like this one has a real chance. The badge is one that parents trust.

### Phase 9: signing, testing tracks and release
1. **Signing:**
   - Create an **upload keystore** (`keytool -genkeypair …`) and turn on **Play App Signing**, so Google holds the app signing key.
   - **Back up the upload keystore and its passwords outside the repo** (for example a password manager). If it's lost, you have to ask Google to reset it.
2. **Build:** `./gradlew bundleRelease` → an `.aab`. `versionCode` goes up on every upload.
3. **Internal testing** (up to 100 testers, available within minutes): the first smoke test.
4. **Closed testing:** **12+ testers opted in continuously for 14 days.** Ask them to really open the app a few times. Then answer the production-access questionnaire in Play Console.
5. **Production:** a staged rollout (for example 20% → 100%), watching the Play Console vitals (crashes / ANRs, which Play collects with no SDK).
6. **Automation (optional, after the first manual release):**
   - fastlane `supply`, with a Google Play service-account JSON (gitignored), to upload metadata, screenshots and AABs.
   - Same command style as the iOS `Deliverfile`.

### Phase 10: CI (GitHub Actions, `ubuntu-latest`)
- `./gradlew lint testDebugUnitTest verifyRoborazziDebug assembleDebug`
- `./gradlew assembleRelease`: the release build must compile with demo mode and the developer unlock stripped out (same idea as the iOS CI step).
- Upload test reports when a run fails.

---

## 8. Working method with Claude Code (the same loop as iOS)

For every feature:
1. **Port.** Point Claude at the iOS source file and the target Kotlin file, for example: "Port `ios/App/App/FindItView.swift` from `../baby-english` to `ui/games/FindItScreen.kt`. Keep the constants and the voice ids."
2. **Build and test:** `./gradlew testDebugUnitTest assembleDebug`.
3. **Run it on the emulator / phone:**
   - Install with `./gradlew installDebug`, then launch with `adb shell am start -n com.pipenglish.app/.MainActivity --es startScreen findit --ez demoMode true`.
   - Screenshot with `adb exec-out screencap -p`, and look at it.
4. **Fix** what looks or sounds wrong, then **commit** one feature per commit, plus a PR per phase.
5. **Voices:** never hand-stitch sentences. Add whole lines to `voice_lines.json`, regenerate them, then run the same automatic quality scan used on iOS (one utterance, normal length, no noisy tail), and listen on a real phone.

**Keep one source of truth for content.** Words, voice lines and store copy change together. When one changes in either repo, mirror it in the other in the same week. A later improvement: move the word list into a shared `content/words.json` that both apps read.

---

## 9. Launch-day checklist

- [ ] `SUPPORT_EMAIL` set (its test passes)
- [ ] Release build contains no developer unlock and no demo mode
- [ ] `full_unlock` active in Play Console at the chosen price; buy + refund tested with a license tester
- [ ] Data safety = no data collected; target audience 5 and under + 6–8; ads = no; content rating done
- [ ] Privacy policy URL live (GitHub Pages)
- [ ] EN + HE listings, 6 screenshots, feature graphic and icon uploaded
- [ ] Closed test: 12+ testers × 14 days completed; production access granted
- [ ] Upload keystore backed up outside the repo
- [ ] Staged rollout started; Play Console vitals watched for the first 48 h

---

## Sources

- Play Console: [Closed-testing requirement for new personal accounts](https://support.google.com/googleplay/android-developer/answer/14151465)
- Play Console: [Target API level requirements](https://support.google.com/googleplay/android-developer/answer/11926878) · [developer.android.com: target SDK](https://developer.android.com/google/play/requirements/target-sdk)
- [Play Billing Library deprecation FAQ (version deadlines)](https://developer.android.com/google/play/billing/deprecation-faq) · [Play Billing 8 migration notes (RevenueCat)](https://www.revenuecat.com/blog/engineering/play-billing-8-migration)
- [Promo codes (developer.android.com)](https://developer.android.com/google/play/billing/promo) · [Create promotions (Play Console Help)](https://support.google.com/googleplay/android-developer/answer/6321495)
- [Families policy requirements](https://support.google.com/googleplay/android-developer/answer/9893335) · [Target audience and app content](https://support.google.com/googleplay/android-developer/answer/9867159) · [Designing for children and families](https://play.google.com/intl/en-GB_ALL/console/about/programs/families)
- [Play Console registration (fee and verification)](https://support.google.com/googleplay/android-developer/answer/6112435)
