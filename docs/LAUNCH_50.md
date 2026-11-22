# 50 users by November 30: launch kit

Today is **Sunday, November 22**. You have 8 days. Apple's review usually takes **24–48 hours**, so the critical path is:
**submit by Tuesday → live by Thursday → 50 downloads by Sunday the 30th.**

Everything that can be prepared is already in the repo:

| What | Where |
|---|---|
| App Store screenshots, EN + HE, 6.9" | `fastlane/screenshots/` |
| Listing text (name, subtitle, description, keywords, review notes) | `fastlane/metadata/` |
| Landing page (HE + EN) + privacy policy | `docs/index.html`, `docs/en.html`, `docs/privacy.html` |
| Full submission checklist | `docs/APP_STORE.md` |

---

## Day by day

### Sun 22 – Mon 23: submit
1. **Turn on GitHub Pages** (Settings → Pages → Branch `main`, folder `/docs`) once the PR is merged. Your privacy URL becomes `https://ahochma.github.io/baby-english/privacy.html` (already filled in the metadata).
2. **App Store Connect:** create the app (bundle `com.babyenglish.app`), Kids Category "5 and under", privacy label "Data Not Collected", and the IAP `com.babyenglish.app.fullunlock` (non-consumable, Family Sharing on).
3. **Upload the listing in one command:**
   ```
   fastlane deliver
   ```
   (or paste from `fastlane/metadata/*` by hand: it's plain text).
4. **iPad screenshots:** required because the app supports iPad. In the iPad Pro 13" simulator run the app and press ⌘S on each screen (or ask me once you approve simulator access, and I'll generate them the same way as the iPhone set).
5. **Xcode → Product → Archive → Distribute → App Store Connect**, attach the build and the IAP, **Submit for Review**.
6. While waiting: **TestFlight** the same build to 10–20 friends with kids aged 3–6. Ask each one for a 10-second video of their kid playing Bubbles or Find it!.

### Tue 24 – Wed 25: warm up (while in review)
- Post a teaser in 2–3 parent groups: "Building a small ad-free English app for 3–6 year olds, launching this week. Who wants the link first?" Collect a list of people who reply "me".
- Prepare 3 Reels/TikToks from the TestFlight videos (or from the simulator: demo mode plays itself, see the end).

### Thu 26: launch day (target 25 downloads)
- As soon as it's "Ready for Sale": put the link in `docs/index.html` (`APP_STORE_URL` at the top of the generator, or just replace the "Coming soon" button) and send it to **everyone who said "me"**.
- Post the main launch post (below) in **3 groups**, staggered morning / noon / evening.
- Personally message 20 friends with kids. Personal messages convert 5–10× better than posts.

### Fri 27 – Sat 28: second wave (target +15)
- Post in 3 new groups (different cities). Share the Reels.
- Ask the first happy parents to leave a rating. 5 early ratings make a big difference to everyone who comes after.

### Sun 29 – Mon 30: final push (target +10)
- WhatsApp kindergarten/gan parent groups you're in.
- 5 English teachers / tutors for kids: offer a free unlock (App Store Connect → your in-app purchase → Offer Codes) in return for sharing with their parents.

**Counting:** App Store Connect → Analytics → *First-time downloads* (updates once a day, about a day behind).

---

## Ready-to-post copy (Hebrew)

Fill the bracketed parts with real details only. Made-up testimonials hurt trust and break Facebook group rules.

### Main launch post (Facebook parent groups)
> 🐣 השקנו אפליקציה קטנה ללימוד אנגלית לילדים בגילאי 3–6!
>
> [משפט אישי אמיתי שלכם: למה בניתם את זה. למשל מה קרה בבית שגרם לכם להתחיל]
> אז בנינו את **Baby English**:
> 🫧 מפוצצים בועות ושומעים מילים
> 🔍 Find it! – שומעים מילה ומוצאים את התמונה
> 🃏 כרטיסיות עם קול ברור ותמונות גדולות
> 🗣️ אומרת קודם בעברית ואז באנגלית: ״כלב… Dog!״
> 🐥 ופיפ, אפרוח שמריע על כל הצלחה
>
> ✅ בלי פרסומות, בלי מעקב, בלי מנוי
> ✅ עולם החיות וכל המשחקים בחינם
>
> הורדה: [קישור]
> נשמח מאוד לשמוע מה הילדים אמרו 🙏

### Short version (WhatsApp)
> היי! השקנו אפליקציה קטנה לילדים 3–6 שמלמדת מילים ראשונות באנגלית עם משחקים. בלי פרסומות, חיות וכל המשחקים בחינם 🐣 [קישור] — אשמח אם תנסו ותספרו לי מה הילד/ה חשב/ה!

### Teaser (Tue/Wed)
> אנחנו משיקים השבוע אפליקציה קטנה וללא פרסומות ללימוד אנגלית לילדים בגילאי 3–6 🐣 מי רוצה לקבל את הקישור ראשון? תכתבו "אני" 👇

### Message to English teachers / tutors
> היי [שם], ראיתי את העבודה שלך עם ילדים ואהבתי. בנינו אפליקציה קטנה וללא פרסומות לגילאי 3–6 שמלמדת 40 מילים ראשונות באנגלית עם משחקים. אשמח לתת לך קוד גישה מלא במתנה. אם תאהבי, אשמח שתשתפי עם ההורים. [קישור]

### Reel captions
- "[שם/גיל הילד מהסרטון] מפוצץ/ת בועות ואומר/ת את המילים באנגלית 🫧 #אנגליתלילדים"  ← only with a real video and the parent's permission
- "פיפ מריע כשמוצאים את התמונה הנכונה 🐣 #גיל3 #גן #אנגלית"
- "בלי פרסומות, בלי מעקב. סוף סוף אפליקציה לילדים שאפשר לסמוך עליה ✅"

Hashtags: #אנגליתלילדים #אפליקציהלילדים #הורות #גן #פעוטות #לימודאנגלית

---

## Video footage without a phone camera

Debug builds have a demo mode that plays the games by themselves:
```
xcrun simctl launch booted com.babyenglish.app -startScreen bubbles -demoMode
xcrun simctl launch booted com.babyenglish.app -startScreen findit -demoMode
xcrun simctl io booted recordVideo bubbles.mov   # Ctrl+C to stop
```
A 15–30 second recording makes a good App Preview video and a good Reel.
