# MenuFC — native macOS app

A polished, menu-bar-only (agent) app showing live football scores. **This native app supersedes
the SwiftBar plugin** in [`../client/`](../client) — same data and behavior, but a real shippable
macOS app. It talks **only** to the Cloudflare Worker in [`../worker/`](../worker) and contains no
secrets. The Worker is unchanged.

## Requirements
- macOS 13.0+ (deployment target), Xcode 15+ (built/verified with Xcode 26).
- [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`

## Build & run
```bash
cd app
xcodegen generate                  # produces MenuFC.xcodeproj from project.yml

# Option A — Xcode: open MenuFC.xcodeproj and press Run.
open MenuFC.xcodeproj

# Option B — command line (compile-verify, no signing needed):
xcodebuild -project MenuFC.xcodeproj -scheme MenuFC \
  -derivedDataPath ./build CODE_SIGNING_ALLOWED=NO build
open ./build/Build/Products/Debug/MenuFC.app

# Quit (it's a menu-bar agent — use the in-app Quit, or):
killall MenuFC
```
`project.yml` is the source of truth; `MenuFC.xcodeproj` is generated (gitignored, safe to regenerate).

## Architecture
Deliberately **not** SwiftUI `MenuBarExtra` — the menu bar item and dropdown are our own AppKit
shell, so nothing is framework-injected and we fully control the colored title and dismissal.
SwiftUI is used only to render content *inside* our popover/settings window.

| File | Role |
|------|------|
| `MenuFCApp.swift` / `AppDelegate.swift` | Agent app entry; `.accessory` policy; wires store + status item + poller. |
| `StatusItemController.swift` | `NSStatusItem` + our `NSPopover`; renders the colored attributed title. |
| `DropdownView.swift` | SwiftUI popover: Live/Upcoming/Recent sections, footer, Refresh/Settings/Quit. |
| `SettingsView.swift` / `SettingsWindowController.swift` | Settings/About window + launch-at-login toggle. |
| `LoginItem.swift` | Launch-at-login via `SMAppService`. |
| `ScoresStore.swift` | Observable source of truth; cache + persistent recent history; featured/sections. |
| `Poller.swift` | Smart-poll (live window, hourly idle, wake refresh). |
| `ScoresClient.swift` | `/scores` + `?fresh=1` networking. |
| `CacheStore.swift` | Last-known scores + recent-results history in Application Support. |
| `Models.swift` / `TimeUtil.swift` / `Presentation.swift` | Decoding (+ `displayState`), time, rendering logic. |

## Parity checklist — Python (`client/menufc.30s.py`) → Swift

| Python behavior | Swift implementation |
|---|---|
| `pick_featured` (LIVE/HT → next SCHED → most recent final) | `Presentation.pickFeatured` |
| `title_text` (3 title formats, `vs`, en-dash score) | `Presentation.titleText` |
| `STATE_COLOR` (LIVE `#34c759`, HT `#ff9500`, FT/PP/SUSP/CANC `#8e8e93`, SCHED default) | `Presentation.stateColor` |
| `menubar_title` colored title | `Presentation.attributedTitle` (NSAttributedString; live = bold) |
| `match_row` (score vs `v`, `FT · score N/A`, time suffix) | `MatchRowView` (+ `Presentation.matchRow` parity reference) |
| Footer `Updated …` + offline note | `DropdownView.updatedLine` (local time — see below) |
| Refresh forces `?fresh=1` | `DropdownView` Refresh → `ScoresStore.refresh(force:true)` → `ScoresClient` |
| `Data provided by football-data.org` link | `DropdownView` footer / Settings |
| Day boundary in US Eastern (Worker's slate) | `TimeUtil.etTodayString` (rollover detection only) |
| Crash-proof + offline cache fallback | `CacheStore` + `ScoresStore.offline` |
| Smart-poll: live window 5 min pre → 150 min post, ~25s | `Poller` (`preKick`, `postMatch`, `liveRefresh`) |

### Intentional changes / additions vs the Python client
- **Buy me a coffee link** appears **only in the direct (non-App-Store) build**, gated by the
  `DIRECT_BUILD` compile flag — the App Store build never compiles it (Apple's in-app-payment rules).
- **Added** Quit, a Settings/About window, and launch-at-login (`SMAppService`).
- **Sectioned dropdown** (Live / Upcoming / Recent) + **tap a live match to pin it** to the menu bar
  + **persistent recent-results history** that survives the day rollover (`recent.json`).
- **Local-time display:** kickoff times and the `Updated …` footer render in the **device's**
  timezone/locale (Python hard-coded US Eastern). The **slate day still comes from the Worker (ET)** —
  `TimeUtil.eastern`/`etTodayString` are used only for rollover detection, not display.
- **Live kickoff-lag guard** (`Match.displayState`): a match the feed still calls "scheduled" but that
  already has a score is shown as **LIVE** (a score can't exist before kickoff; works around
  football-data's free-tier status lag).
- **Idle + wake refresh:** the persistent app self-drives (hourly idle refresh + refresh on wake),
  vs SwiftBar re-running the script every 30s.
- Title color is a real `NSAttributedString` foreground color (vs SwiftBar's `| color=`).

## Distribution

Two channels from one codebase. The Worker is untouched by both.

### Mac App Store — `archive.sh`
```bash
TEAM_ID=39PB68QUZJ ./archive.sh        # archive (Automatic signing) → App Store .pkg in build/export
```
Then upload via Xcode → Organizer or Transporter. App Sandbox + only `com.apple.security.network.client`,
Hardened Runtime, `LSUIElement = true`, bundle id `com.rujitraval.menufc`, category Sports.

### Direct download (.dmg) — `build-direct.sh`
Developer-ID-signed + **notarized** DMG, **with** the coffee link (`DIRECT_BUILD` flag).
```bash
# one-time: store notary credentials (app-specific password from appleid.apple.com)
xcrun notarytool store-credentials "MenuFC" \
  --apple-id "<you>" --team-id "39PB68QUZJ" --password "<app-specific-password>"

./build-direct.sh                      # → build/MenuFC.dmg (signed, notarized, stapled)
```
Publish via a GitHub Release; keep the asset named **`MenuFC.dmg`** so the landing page's
`/releases/latest/download/MenuFC.dmg` button resolves.

## Remaining TODOs
- [ ] Verify **launch-at-login** on a signed/installed build (`SMAppService` only toggles when signed).
- [ ] **football-data.org commercial tier** if usage grows (Worker-side; unchanged here).
- [x] App icon, signing Team ID, Apple Developer enrollment, App Store listing + screenshots — done.
