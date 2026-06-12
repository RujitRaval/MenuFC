# MenuFC — App Store listing kit

Everything you paste into App Store Connect, plus review notes. All copy is written to be
**trademark-safe** — no "FIFA" or "World Cup" marks (see the notes at the bottom).

---

## 1. Name & subtitle

| Field | Value | Limit |
|---|---|---|
| **App Name** | `MenuFC – Live Football Scores` | 30 chars (this is 29) |
| **Subtitle** | `Match scores in your menu bar` | 30 chars (this is 29) |

> The App Name and Subtitle are the heaviest ranking signals. Keep them keyword-rich but
> readable. Don't repeat these words in the Keywords field below — Apple already indexes them.

---

## 2. Promotional text (170 chars, editable anytime without review)

> Follow every match live, right from your menu bar. Scores update on their own while games
> are on — no app to open, no tab to refresh, no notifications to chase.

---

## 3. Description

```
MenuFC puts live football scores in your Mac's menu bar, so the score is always one glance
away — no browser tab, no app to open, no notifications to chase.

A quiet score sits at the top of your screen and updates on its own while a match is in
play. Click it for the full slate: every match on the schedule today, with kickoff times,
live minutes, and half-time and full-time states — color-coded so you can read the
situation in an instant.

Built to stay invisible until you need it:

• Live scores in your menu bar, updated automatically while matches are on
• The full day's fixtures in one click, with kickoff times
• Color-coded states — in play, half-time, full-time — readable at a glance
• Light on your Mac: it only reaches the network while matches are live
• Keeps working offline: shows the last known scores if your connection drops
• No account, no sign-up, no tracking, no ads
• Launches quietly at login and stays out of your way

Free — no subscription, no ads, no catch.

Perfect for following the summer's big national-team tournament and the football you care
about.
```

---

## 4. Keywords (100-char field, comma-separated, no spaces)

```
soccer,livescore,fixtures,results,standings,goals,sport,league,kickoff,scoreboard,tracker,fan
```

Rules to remember: Apple auto-combines your keywords with the title words to form phrases,
so **don't waste space repeating** "football", "live", "scores", "match", "menu", or "bar"
— they're already in the name/subtitle. No spaces after commas (spaces count).

---

## 5. Other listing fields

| Field | What to put |
|---|---|
| **Primary category** | Sports |
| **Secondary category** | Utilities |
| **Price** | **Free** (no in-app purchases on this build). No commission applies to free apps. |
| **Support URL** | Required. A simple page or your GitHub repo's README works (e.g. the repo URL). |
| **Marketing URL** | Optional — a one-page site if you make one. |
| **Privacy Policy URL** | Required. Host `docs/privacy-policy.md` (GitHub Pages is free) and link it. |
| **Copyright** | `© 2026 Rujit Raval` |
| **Age rating** | 4+ (no objectionable content). |

---

## 6. App Privacy questionnaire (App Store Connect → App Privacy)

Your app has no account, no analytics, and no tracking, so this is the simplest possible case:

- **"Do you or your third-party partners collect data from this app?"** → **No**
- Result: your listing shows **"Data Not Collected."**

One honesty check: the app sends anonymous requests to your Cloudflare Worker to fetch
scores. As long as you **don't retain or link request logs (e.g. IP addresses) to identify
users**, "Data Not Collected" is correct — Apple lets you exclude data used only to perform
the request and not stored. If you ever add analytics or crash reporting, you must update this.

---

## 7. Screenshot plan (Mac, required — at least 1, up to 10)

Accepted sizes (16:10): **1280×800, 1440×900, 2560×1600, or 2880×1800.** Shoot on a Retina
Mac at 2880×1800 and let Apple downscale.

Menu bar apps are awkward to screenshot — the trick is to stage the menu bar item **and** the
open dropdown together, on a clean desktop. Suggested set:

1. **Hero** — menu bar showing a live score, dropdown open with the day's matches.
   Caption: *"Live scores, always one glance away."*
2. **At a glance** — dropdown with a mix of live / half-time / full-time rows.
   Caption: *"Color-coded so you read the match in an instant."*
3. **Stays out of the way** — the Settings/About window with launch-at-login.
   Caption: *"Launches at login. No account. No noise."*
4. **Offline** — the "last known scores" state.
   Caption: *"Keeps the score even when the Wi-Fi drops."*

How to capture: set a tidy desktop wallpaper, trigger a live state (or run during a real
match), `⌘⇧4` then Space to grab the menu/dropdown cleanly, and compose onto the required
canvas size with the caption. Keep captions short and benefit-led.

---

## 8. Trademark & review notes (read before you submit)

- **Keep "FIFA" and "World Cup" out of everything** — name, subtitle, keywords, description,
  screenshots, and the icon. Both are protected marks and FIFA enforces them. The copy above
  deliberately says "the summer's big national-team tournament" instead.
- **Coverage decision worth making:** the app currently shows one competition. Your data plan
  (the €12 "Free w/ Livescores" tier) actually covers **12 competitions**. Broadening MenuFC
  to show whichever major competition is in play would (a) make the listing honest year-round
  rather than for one tournament, and (b) remove your dependence on a single trademarked event.
  Worth considering before launch.
- **Guideline 4.2 (minimum functionality):** menu bar utilities are fine, but make sure the
  screenshots and description clearly convey ongoing value so review doesn't read it as "too
  simple."
- **No payment or tip links in the App Store build.** Apple restricts external payment links,
  so the "Buy me a coffee" tip lives **only in the direct-download (.dmg) build**, where Apple's
  rules don't apply. Keep the App Store build clean.
```
