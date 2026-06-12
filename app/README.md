# MenuFC — native macOS app

A polished, menu-bar-only (agent) app showing live FIFA World Cup 2026 scores. **This native
app supersedes the SwiftBar plugin** in [`../client/`](../client) — same data, same behavior,
but a real shippable macOS app. It talks **only** to the Cloudflare Worker in
[`../worker/`](../worker) and contains no secrets. The Worker is unchanged.

## Requirements
- macOS 13.0+ (deployment target), Xcode 15+ (built/verified with Xcode 26).
- [XcodeGen](https://github.com/yonsson/XcodeGen): `brew install xcodegen`

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
`project.yml` is the source of truth; `MenuFC.xcodeproj` is generated (safe to gitignore/regenerate).

## Architecture
Deliberately **not** SwiftUI `MenuBarExtra` — the menu bar item and dropdown are our own
AppKit shell, so nothing is framework-injected and we fully control the colored title and
dismissal. SwiftUI is used only to render content *inside* our popover/settings window.

| File | Role |
|------|------|
| `MenuFCApp.swift` / `AppDelegate.swift` | Agent app entry; sets `.accessory` policy; wires store + status item + poller. |
| `StatusItemController.swift` | `NSStatusItem` + our `NSPopover`; renders the colored attributed title. |
| `DropdownView.swift` | SwiftUI popover content: match rows, footer, Refresh/Settings/Quit. |
| `SettingsView.swift` / `SettingsWindowController.swift` | Settings/About window. |
| `LoginItem.swift` | Launch-at-login via `SMAppService`. |
| `ScoresStore.swift` | Observable source of truth; cache load/save; derived featured/title. |
| `Poller.swift` | Smart-poll (live window, hourly idle, wake refresh). |
| `ScoresClient.swift` | `/scores` + `?fresh=1` networking. |
| `CacheStore.swift` | Last-known scores in Application Support. |
| `Models.swift` / `TimeUtil.swift` / `Presentation.swift` | Decoding, ET time, rendering logic. |

## Parity checklist — Python (`client/menufc.30s.py`) → Swift

| Python behavior | Swift implementation |
|---|---|
| `pick_featured` (LIVE/HT → next SCHED → most recent final) | `Presentation.pickFeatured` |
| `title_text` (3 title formats, `vs`, en-dash score) | `Presentation.titleText` |
| `STATE_COLOR` (LIVE `#34c759`, HT `#ff9500`, FT/PP/SUSP/CANC `#8e8e93`, SCHED default) | `Presentation.stateColor` |
| `menubar_title` colored title | `Presentation.attributedTitle` (NSAttributedString; live = bold) |
| `match_row` (score vs `v`, `FT · score N/A`, time suffix) | `MatchRowView` (+ `Presentation.matchRow` as a string-parity reference) |
| Footer `Updated h:mm a ET` + offline note | `DropdownView.updatedLine` |
| Refresh forces `?fresh=1` | `DropdownView` Refresh → `ScoresStore.refresh(force:true)` → `ScoresClient` |
| `Data provided by football-data.org` link | `DropdownView` footer / Settings |
| ET timezone + day boundary | `TimeUtil` (`America/New_York`) |
| Crash-proof + offline cache fallback | `CacheStore` + `ScoresStore.offline` |
| Smart-poll: live window 5 min pre → 150 min post, ~25s | `Poller` (`preKick`, `postMatch`, `liveRefresh`) |

### Intentional changes from the Python client
- **Removed** the "Buy me a coffee" link (this is a paid app).
- **Added** Quit, a Settings/About window, and launch-at-login (native apps need these).
- **Idle refresh + wake refresh:** the Python client relied on SwiftBar re-running it every
  30s; a persistent app self-drives, so `Poller` adds a slow ~hourly idle refresh (ET-rollover)
  and a refresh on wake from sleep.
- Title color is a real `NSAttributedString` foreground color instead of SwiftBar's `| color=`.

## App Store readiness
- App Sandbox + **only** `com.apple.security.network.client` (see `MenuFC/Resources/MenuFC.entitlements`).
- Hardened Runtime on; `LSUIElement = true`; bundle id `com.rujitraval.menufc`; category Sports.
- Archive/export: **`./archive.sh`** (Automatic signing) → App Store package.

### TODO before submission (manual — not done here)
- [ ] **Signing Team ID** — `export TEAM_ID="…"` for `archive.sh` (and set `DEVELOPMENT_TEAM` in `project.yml`).
- [ ] **Final app icon** — drop art into `MenuFC/Resources/Assets.xcassets/AppIcon.appiconset`.
- [ ] **football-data.org plan** — confirm a commercial tier if usage grows (Worker-side; unchanged here).
- [ ] **Apple Developer enrollment**, App Store Connect listing, screenshots.
- [ ] Verify **launch-at-login** on a *signed* build (`SMAppService` needs a valid signature).
