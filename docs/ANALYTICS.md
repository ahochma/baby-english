# Knowing your users without tracking them

Pip English is in the Kids Category and promises "no tracking", and parents choose it for that.
So there is **no analytics SDK in the app**. Everything below comes from Apple (aggregated,
privacy-safe, no code needed) or from parents who choose to write to you.

The privacy label stays **"Data Not Collected"**.

---

## 1. Where each number lives

All of these are in **App Store Connect → Apps → Pip English → Analytics** (also in the free
**App Store Connect** iPhone app, under Trends, for a daily look on your phone).
Data shows up about 24–48 hours late.

| Question | Where | Metric |
|---|---|---|
| How many people saw the app in the store? | Analytics → Acquisition | **Impressions** |
| How many opened the product page? | Acquisition | **Product Page Views** |
| Does the listing convince them? | Acquisition | **Conversion Rate** (page views → downloads) |
| How many downloaded? | Acquisition / Trends | **First-Time Downloads** (← the 50-user goal) |
| Where did they come from? | Acquisition → *Source Type* | App Store Search / Browse / Web Referrer / **App Referrer** / **Campaigns** |
| Which post brought them? | Acquisition → *Campaigns* | downloads per `ct=` campaign (see §2) |
| Do kids come back? | Usage → **Retention** | Day 1 / Day 7 / Day 28 |
| How much is it used? | Usage | **Sessions**, **Active Devices** |
| Who buys the unlock? | Sales → **In-App Purchases** | units, **Proceeds** |
| Free → paid conversion | your math | IAP units ÷ first-time downloads |
| Crashes | Xcode → Window → **Organizer** → Crashes | crash logs + affected versions |
| What do parents think? | your inbox + Ratings & Reviews | Parent Zone feedback card (§3) |

> Usage and retention only count people who allowed "Share with App Developers"
> (usually a minority), so read them as trends, not exact counts.

---

## 2. Campaign links: one link per post

Never post the plain App Store link. Give every post, group and person its own link, so
Analytics → Campaigns shows exactly what worked.

**Make the links:** App Store Connect → Analytics → (top right) **Campaign Generator**,
type a campaign name, and it builds the link with your provider token. Or build them yourself:

```
https://apps.apple.com/app/apple-store/id<APP_ID>?pt=<PROVIDER_TOKEN>&ct=<CAMPAIGN>&mt=8
```

`<APP_ID>` appears once the app exists in App Store Connect. `<PROVIDER_TOKEN>` is shown in the
campaign generator. Campaign names: up to 40 characters, lowercase, no spaces.

**Naming plan for the launch (copy and fill):**

| Where | `ct=` campaign name |
|---|---|
| Landing page button (docs/index.html, docs/en.html) | `landing-he`, `landing-en` |
| Facebook group posts | `fb-<group>` e.g. `fb-raanana-parents` |
| WhatsApp groups / gan groups | `wa-<group>` e.g. `wa-gan-alon` |
| Personal messages to friends | `friends` |
| Instagram / TikTok reels | `ig-reel-1`, `tt-reel-1` … |
| English teachers / tutors | `teacher-<name>` |
| TestFlight testers telling friends | `beta-referral` |

Keep a little table of which link went where; after a week you'll see which channel deserves more effort.

---

## 3. Hearing from parents (built into the app)

**Parent Zone → "How is Pip English going?"** (behind the parental gate):

- **😍 We love it**: opens Apple's rating prompt. Happy parents become store ratings.
- **🙂 It's OK / 😕 Not for us**: opens an email to you, with app version, iOS version and
  device model pre-filled. Nothing about the child is attached, and the parent sees everything
  before sending.

**Before submitting:** set your support address in `ios/App/App/Feedback.swift`:

```swift
static let supportEmail = "you@example.com"
```

Until then the email options are hidden, and the test suite reminds you with a skipped test.
Put the same address on the support page (docs/index.html "תמיכה" section) instead of the GitHub link.

Reply to every email within a day; at this stage each one is gold.

---

## 4. Weekly 10-minute check (copy into Notes)

| Week | Impressions | Page views | Conv. rate | Downloads | IAP units | Free→paid | D1 retention | Best campaign | Emails |
|---|---|---|---|---|---|---|---|---|---|
| 1 | | | | | | | | | |
| 2 | | | | | | | | | |

**What to do with it** (targets from GO_TO_MARKET.md):

| If… | Then… |
|---|---|
| Conversion rate < 25% | improve screenshot 1 / add the app preview video |
| Downloads fine, IAP < 5% of downloads | check the Parent Zone upsell; consider launch price; read the "It's OK" emails |
| D1 retention low | the first 2 minutes aren't fun enough: watch a child play and fix the first screen they see |
| One campaign clearly wins | do more of exactly that (more groups like it, a second reel in that style) |

---

## 5. If one day you need in-app numbers

For example "how many open Find it!" or "how many reach the paywall": use **anonymous aggregate
counters only** (no user or device id), sent to your own small endpoint rather than a third-party SDK.
Then update the privacy label to "Usage Data – Not Linked to You", update the privacy policy,
and have a lawyer review it for COPPA. Do this only once a real question can't be answered
from §1–§3.
