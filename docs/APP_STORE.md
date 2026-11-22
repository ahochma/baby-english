# App Store submission kit

Everything needed to take Baby English from this repo to "Ready for Sale".
Work through the checklist top to bottom.

---

## 1. One-time setup in App Store Connect

| Step | Where | Value |
|---|---|---|
| Create the app | My Apps → + | Bundle ID `com.babyenglish.app`, SKU `babyenglish-ios` |
| Primary category | App Information | **Education** |
| Kids Category | App Information → Kids | **Ages 5 and Under** |
| Age rating | App Information → Age Rating | answer "None" to everything → **4+** |
| Privacy policy URL | App Privacy | Host `docs/privacy-policy.md` (GitHub Pages works) and paste the URL |
| Privacy "nutrition label" | App Privacy | **Data Not Collected** |
| Support URL | Version page | Any page with a contact form/email (can be the same GitHub Pages site) |
| Content rights | App Information | Confirm you own or licensed the audio (ElevenLabs paid plan includes commercial use; keep the invoice) |

## 2. The in-app purchase

| Field | Value |
|---|---|
| Type | **Non-Consumable** |
| Product ID | `com.babyenglish.app.fullunlock` (must match `PurchaseManager.productID`) |
| Reference name | Full Unlock |
| Family Sharing | **On** (the paywall promises it) |
| Display name (EN) | Unlock Everything |
| Description (EN) | All word worlds in every game. One-time purchase. |
| Display name (HE) | לפתוח הכל |
| Description (HE) | כל עולמות המילים בכל המשחקים. רכישה חד-פעמית. |
| Review screenshot | Screenshot of the paywall (gate answer is shown on screen) |
| Price | see §5 |

Attach the IAP to the first version submission ("In-App Purchases" section on the version page) or it will not be reviewed.

## 3. Testing purchases before submitting

1. Open `ios/App/App.xcodeproj` in Xcode and run the **App** scheme on a simulator.
   The shared scheme already points at `App/Products.storekit`, so purchases work offline.
   If Xcode shows the StoreKit file as missing: Product → Scheme → Edit Scheme → Run → Options → StoreKit Configuration → `Products.storekit`.
2. Tap a locked world → answer the gate → buy. Everything should unlock with a confetti screen.
3. Debug → StoreKit → Manage Transactions → refund it → the worlds lock again on next launch.
4. Then do a TestFlight build with a Sandbox tester (Settings → App Store → Sandbox Account).

## 4. Listing copy

> All listing text and the captioned screenshots are ready to upload in `fastlane/` (`fastlane deliver`, or paste the text files by hand). The copy below is the same text for reference.

### English
- **Name:** Baby English: First Words
- **Subtitle:** English words & games, ages 3–6
- **Promotional text:** New: Bubbles for babies and Find it! for toddlers. Animals and all games are free.
- **Keywords:** `toddler,baby,first words,flashcards,kids,learn english,preschool,abc,animals,colors,vehicles,esl`
- **Description:**

> Your little one's first English words, with a clear, friendly voice and big, happy pictures.
>
> Made for ages 3 to 6. No reading needed. Meet Pip, a cheerful little chick who plays along. No ads. No tracking.
>
> THREE WAYS TO PLAY
> • Flashcards: tap anywhere to see and hear the next word.
> • Bubbles: pop floating bubbles to hear each word. Every touch does something, so there's no way to fail.
> • Find it!: hear a word and find the picture. It starts with 2 big pictures and grows with your child.
>
> BUILT FOR LITTLE HANDS
> • Huge touch targets that react the moment a finger lands
> • Rapid taps and palm touches don't skip ahead or exit by accident
> • Games can only be closed by holding the house button
> • Sticker rewards and gentle celebrations
>
> FOR PARENTS
> • Progress: see which words your child has heard
> • Works offline and on silent mode
> • Everything grown-up sits behind a parental gate
>
> FREE TO TRY
> The Animals world and every game are free forever. One small, one-time purchase unlocks Vehicles, Food and Colors. No subscription. Family Sharing included.

### עברית (Hebrew localization; add "Hebrew" in App Store Connect)
- **שם:** Baby English: מילים ראשונות
- **כותרת משנה:** אנגלית לילדים בגילאי 3–6
- **מילות מפתח:** `אנגלית,תינוק,פעוט,מילים ראשונות,כרטיסיות,ילדים,גן,לימוד,חיות,צבעים,משחק,english`
- **תיאור:**

> המילים הראשונות באנגלית של הקטנטנים שלכם, בקול ברור וחם ועם תמונות גדולות ושמחות.
>
> מתאים לגילאי 3 עד 6. הכירו את פיפ, אפרוח עליז שמשחק יחד עם הילדים. לא צריך לדעת לקרוא. בלי פרסומות. בלי מעקב.
>
> שלוש דרכים לשחק
> • כרטיסיות: נוגעים בכל מקום על המסך כדי לראות ולשמוע את המילה הבאה.
> • בועות: מפוצצים בועות ושומעים את המילה. כל נגיעה משמיעה משהו, ואין דרך להיכשל.
> • Find it!: שומעים מילה ומוצאים את התמונה. מתחיל עם 2 תמונות ומתקדם יחד עם הילד.
>
> נבנה לידיים קטנות
> • כפתורים ענקיים שמגיבים ברגע שהאצבע נוגעת
> • לחיצות מהירות ונגיעות כף יד לא מדלגות ולא יוצאות בטעות
> • יוצאים ממשחק רק בלחיצה ארוכה על כפתור הבית
> • מדבקות וחגיגות קטנות כפרס
>
> להורים
> • מעקב התקדמות: אילו מילים הילד כבר שמע
> • עובד בלי אינטרנט וגם במצב שקט
> • כל מה שמיועד למבוגרים נמצא מאחורי שער הורים
>
> אפשר לנסות בחינם
> עולם החיות וכל המשחקים חינמיים לתמיד. רכישה קטנה וחד-פעמית פותחת את כלי התחבורה, האוכל והצבעים. בלי מנוי. כולל שיתוף משפחתי.

## 5. Pricing

- **Launch price: $2.99 / ₪9.90 for the first 2 weeks**, then **$4.99 / ₪19.90**.
  Use App Store Connect's price schedule to set both prices ahead of time.
- A one-time unlock converts much better than a subscription for a 40-word app, and the
  Kids Category forbids pushy upsells anyway. Raise the price once you add more worlds.

## 6. Screenshots (required: 6.9" iPhone + 13" iPad)

Take them in the simulator (⌘S), then add a short caption above each in Keynote/Figma:

1. Home screen: "First English words for little ones"
2. Bubbles mid-pop with a word banner: "Pop bubbles, hear words"
3. Find it! with Pip cheering: "Hear it, find it!"
4. A flashcard (Fire Truck): "Big pictures, clear voice"
5. Celebration with a sticker: "Stickers and celebrations"
6. Parent Zone: "No ads. No tracking. Progress for parents."

Do the same in Hebrew for the Hebrew localization (only the captions change).
App preview video (optional, big conversion win): a 15-second screen recording of Bubbles.

## 7. Notes for App Review (paste into "App Review Information → Notes")

> Baby English is a Kids Category app (ages 5 and under).
> • The parental gate is a multiplication question with a number pad. It appears before the paywall, the Parent Zone, restore purchase and the external Terms link.
> • To reach the purchase: tap any card with a lock (e.g. "Vehicles"), solve the gate, and you'll see the "Unlock Everything" non-consumable IAP.
> • The app collects no data, contains no third-party SDKs, no ads and no analytics.
> • Audio plays in silent mode on purpose (category .playback) because parents keep phones on silent.

## 8. Final pre-flight

- [ ] **Replace the temporary voice clips** (prompts + Hebrew words are macOS voices for now):
      `ELEVENLABS_API_KEY=… ELEVENLABS_VOICE_EN=… ELEVENLABS_VOICE_HE=… python3 scripts/generate_voice.py --engine elevenlabs`
      It overwrites the same files, so nothing changes in Xcode. Use the voice id of the original word clips for EN.

- [ ] Bump `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION` for each upload
- [ ] Product → Archive (Any iOS Device) → Distribute → App Store Connect
- [ ] Tested purchase + restore in TestFlight with a sandbox account
- [ ] Privacy policy URL is live
- [ ] Screenshots uploaded for iPhone and iPad, EN + HE
- [ ] IAP attached to the version and in "Ready to Submit"
