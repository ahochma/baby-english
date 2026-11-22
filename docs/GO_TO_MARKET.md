# Go-to-market: the first 50 paying families

## The math

| Step | Assumption | Families |
|---|---|---|
| Installs | from the channels below | **~1,000** |
| Play more than once (day-2 retention) | ~35% | ~350 |
| Parent opens the paywall | ~40% of returning families | ~140 |
| Buy | ~35% of paywall views (one-time, low price, kid already loves it) | **~50** |

So the job is **about 1,000 installs from parents of 3–6 year olds**. That's very doable in
Israel without paid ads, because the Hebrew App Store has almost no polished
"English for babies" apps. Check the numbers weekly in **App Store Connect → Analytics**
(no SDK needed): *First-time downloads*, *IAP units*, and *Proceeds*.

## What the product already does for conversion

- **Generous free tier**: Animals plus all 3 games. The child gets attached first and the parent sees value before any ask.
- **Natural upsell moment**: the locked cards are visible and colorful. When the child taps one, the parent hands over the phone, and the gate leads straight to the paywall.
- **Parent Zone progress** ("10 / 60 words heard") makes the remaining 50 words feel like the obvious next step.
- **Review prompt** only fires for engaged parents (10+ words, 2+ stickers), behind the gate.
- **Honest paywall**: one-time, no subscription, Family Sharing. These are the top objections Israeli parents raise about kids' apps.

## Four-week launch plan

### Week 0: before release
- [ ] TestFlight with 10–20 friends with toddlers. Ask each for a 15-second video of their kid playing Bubbles. **This footage is your whole marketing budget.**
- [ ] Ask the same families to rate the app on day 1 → you launch with 10+ ratings (huge for conversion).
- [ ] Set the launch price ($2.99 / ₪9.90) with an automatic increase in 2 weeks. "Launch price until <date>" creates real urgency.

### Week 1: launch (target 300 installs)
- [ ] Post in Israeli parent Facebook groups (city "mom/parent" groups, "הורים לפעוטות", bilingual-family groups). Lead with a kid's video, not with the app: *"My 4-year-old says 'elephant' in English now 🐘 — we built a tiny ad-free app for it, Animals is free"*. Post a different city group each day; never spam the same one.
- [ ] Send it to every WhatsApp group of parents and kindergartens (גן / מעון) you're in.
- [ ] Instagram + TikTok Reels: 3 short videos (a kid playing Find it! with Pip cheering). Hashtags: #אנגליתלילדים #פעוטות #תינוקות #מילהראשונה.

### Week 2: credibility (target +300)
- [ ] Reach out to 10 Israeli kids' English teachers / private tutors / speech therapists on Instagram. Offer a free unlock via an offer code (App Store Connect → your in-app purchase → Offer Codes) in return for an honest story post.
- [ ] Reach out to 5 parenting micro-influencers (5k–50k followers) with the same offer.
- [ ] Reply to every App Store review personally.

### Week 3–4: compounding (target +400)
- [ ] Ship one new free-to-everyone feature (e.g. a "Body parts" mini-world in the free tier or a lullaby night mode). Each update is a new reason to post.
- [ ] Apply for App Store featuring: App Store Connect → "Featuring nominations" (Kids + Education, no ads, no tracking is exactly what the editors favor).
- [ ] Translate the listing to English-speaking markets (the app UI already is) and repeat the playbook in US/UK parent communities.

## What to watch and when to change

| Signal | If it's low | Do this |
|---|---|---|
| Downloads / product page views < 25% | Listing doesn't sell | Change the first screenshot to Bubbles with a baby-voice caption; add the app preview video |
| Paywall views but < 20% buy | Price or trust | Run the launch price longer; add "Family Sharing" and "no subscription" to the first screenshot |
| Few paywall views | Kids don't hit locked cards | Show a gentle "more worlds" teaser in the celebration screen (behind the gate) |
| Low ratings | Bug or expectation gap | Read every review; ship a fix within a week |

## Next content that would raise the price ceiling
1. More worlds: Body, Home, Clothes, Toys, Nature (re-use the ElevenLabs voice for consistency)
2. "Say it!" game: the microphone listens for the word (on-device speech recognition, no data leaves the phone)
3. Short sentences ("The dog says woof") for 2–3 year olds
