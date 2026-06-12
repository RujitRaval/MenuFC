# Claude Code prompt — Native MenuFC menu bar app

> Run this in Claude Code from the root of the MenuFC repo. You can paste the whole
> thing, or just say: "Read BUILD_PROMPT.md and implement it."

## Goal

Replace the SwiftBar-based client with a **native, polished macOS menu bar app** ("MenuFC")
that is ready to ship on the **Mac App Store**. **Do not change the backend** — the
Cloudflare Worker stays exactly as-is.

## Source of truth — read these first

- `worker/src/index.js` — the Cloudflare Worker. Its `/scores` JSON response is the data
  contract. **Leave this file and the whole `worker/` directory untouched.**
- `client/menufc.30s.py` — the existing SwiftBar plugin. Its rendering, state handling,
  and smart-polling logic is the behavior to port. **Match it faithfully** unless this
  document says otherwise.

Read both before writing any code, and treat them as the spec.

## Backend (already live — just call it)

- `GET https://menufc-api.rujit.workers.dev/scores` — today's World Cup matches (US Eastern day). No auth.
- `GET .../scores?fresh=1` — forces an upstream refresh (server-side rate-limited).
- Response shape (confirm against `worker/src/index.js`):

```json
{
  "updated": "ISO-8601",
  "date": "YYYY-MM-DD",
  "matches": [{
    "id": 12345,
    "utcDate": "ISO-8601",
    "status": "<raw upstream status>",
    "state": "LIVE | HT | FT | SCHED | PP | SUSP | CANC",
    "matchday": 1,
    "group": "Group A",
    "home": { "tla": "MEX", "name": "Mexico",       "flag": "🇲🇽" },
    "away": { "tla": "RSA", "name": "South Africa",  "flag": "🇿🇦" },
    "score":    { "home": 2, "away": 1 },
    "halfTime": { "home": 1, "away": 0 }
  }]
}
```

`score`/`halfTime` values can be `null`. Flags arrive as emoji from the Worker — just display them.

## What to build

A native macOS app target **MenuFC**:

- **Swift + SwiftUI**, using `MenuBarExtra`. Menu-bar-only **agent app** (`LSUIElement` /
  no Dock icon).
- **Minimum deployment target: macOS 13.0.**
- Calls only the Worker `/scores` endpoint. Never calls football-data.org directly.
  Contains **no secrets**.

## Behavior to port (see `client/menufc.30s.py` for exact rules)

- **Featured match** (what shows in the menu bar): first `LIVE`/`HT`, else next `SCHED`,
  else most recent finished. If none today: `⚽ No WC matches today`.
- **Menu bar title formats:**
  - live/HT/FT with a score → `🇲🇽 2–1 🇿🇦 LIVE`
  - `SCHED` → `🇲🇽 vs 🇿🇦 7:00 PM`
  - otherwise → `🇲🇽 vs 🇿🇦 {STATE}`
- **State colors** (legible in light + dark): `LIVE` `#34c759`, `HT` `#ff9500`,
  `FT`/`PP`/`SUSP`/`CANC` `#8e8e93`, `SCHED` → default label color.
- **Dropdown:** one row per today's match. With score → `🇲🇽 MEX 2–1 RSA 🇿🇦`; without →
  `🇲🇽 MEX v RSA 🇿🇦`. Suffix: `SCHED` → kickoff time in ET; finished-without-score →
  `FT · score N/A`; otherwise the state.
- **Footer:** `Updated h:mm a ET` (with an offline note when serving cached data); a
  **Refresh** action that forces `?fresh=1`; a `Data provided by football-data.org` link.
- **Remove** the "Buy me a coffee" link entirely (this is a paid app).
- **Timezone:** US Eastern (`America/New_York`) for the day boundary and all displayed times.
- **Crash-proof + offline:** cache last-known scores to disk (Application Support). On
  network failure, render from cache. Never show a broken or empty menu bar.

## Smart polling (persistent-app version of the Python smart-poll)

- Track today's slate. Only hit the network inside a **live window** (from 5 min before any
  kickoff to 150 min after) — poll roughly every 25–30s then.
- Off-hours / idle: do not poll, except a slow ~hourly refresh to catch the ET day rollover.
- On launch: load cache immediately, then refresh.
- (The Worker already caches upstream, so polling is cheap — but mirror this to be
  battery-friendly and polite.)

## Product polish (this is a v1 we intend to sell)

- App icon (a clear placeholder is fine — mark final art as a TODO).
- A **Settings/About** window: launch-at-login toggle, version + credits, link to the data provider.
- **Launch at login** via `SMAppService` (macOS 13+).
- Clean typography and spacing in the dropdown; make live matches visually distinct
  (color/weight). Correct in both light and dark mode.

## App Store readiness

- **App Sandbox** enabled, with the **outgoing network** entitlement
  (`com.apple.security.network.client`) only.
- **Hardened Runtime** on.
- `Info.plist`: `LSUIElement = true`; bundle id `com.rujitraval.menufc`; display name
  `MenuFC`; appropriate app category.
- Provide an **archive/export path**: a documented `xcodebuild archive` + export-options
  flow (or a small script) that produces an App Store-ready build. Use **Automatic**
  signing and leave my Team ID as a clearly-marked TODO — **do not hardcode signing identities**.

## Project structure & build

- Put the app under `app/` (e.g. `app/MenuFC/` for sources).
- Use a **reproducible, git-reviewable** project setup. Prefer an **XcodeGen `project.yml`**
  (commit it) or Swift Package Manager; if neither is available, commit a standard
  `.xcodeproj`. The repo must build with one documented command (e.g. `xcodebuild -scheme MenuFC`).
- Keep `worker/` and `client/` as-is. Update the root `README.md` to note the native app
  supersedes the SwiftBar client, with build/run instructions.

## Constraints

- **Do not modify `worker/`.** Do not add or commit any API keys or secrets.
- Do **not** attempt the business/manual steps — football-data.org commercial plan, Apple
  Developer enrollment, App Store listing/screenshots. Leave short, clearly-marked TODO
  notes where they're needed (signing Team ID, data plan, final icon).

## Verify before finishing

1. The app **builds cleanly** against the macOS 13+ SDK (`xcodebuild`).
2. Run it and confirm: menu bar shows the featured match; the dropdown lists today's
   matches; colors/states match the Python version; **Refresh** forces a fetch; cutting the
   network falls back to cache; **no Dock icon**; the launch-at-login toggle works.
3. Add a short **parity checklist** to the README mapping each Python behavior to its Swift
   implementation, and call out anything you intentionally changed.
