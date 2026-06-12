# Claude Code prompt — Direct-download (.dmg) distribution for MenuFC

> Run this in Claude Code from the repo root (after the native app from `BUILD_PROMPT.md`
> exists). You can paste the whole thing, or say: "Read DIRECT_DIST_PROMPT.md and implement it."

## Goal

Add a **second distribution channel** for the existing MenuFC app: a **Developer ID-signed,
notarized `.dmg`** for direct download (hosted on GitHub Releases), alongside the existing Mac
App Store build. **The App Store build and behavior must stay exactly as they are.** The only
user-facing difference in the direct build is an added **"Buy me a coffee" tip link**.

MenuFC is now a **free** app on both channels.

## Source of truth — read these first

- `app/README.md`, `app/project.yml`, `app/archive.sh`, `app/ExportOptions.plist` — the current
  App Store build setup.
- `app/MenuFC/Sources/DropdownView.swift` and `SettingsView.swift` — where the tip link goes.
- Leave `worker/` and `client/` untouched.

## What to implement

### 1. A `DIRECT_BUILD` compile flag (direct build only)
- Make the direct/notarized build define the Swift active compilation condition `DIRECT_BUILD`,
  while the App Store build (`archive.sh`) does **not**.
- Prefer the low-churn approach: pass it at archive time in `notarize.sh` via
  `SWIFT_ACTIVE_COMPILATION_CONDITIONS="$(inherited) DIRECT_BUILD"` on the `xcodebuild` line,
  rather than restructuring `project.yml`. (A dedicated build configuration is acceptable if you
  think it's cleaner — your call — but do not alter the App Store output.)

### 2. The tip link — wrapped in `#if DIRECT_BUILD`
- In the dropdown (and/or the Settings/About window), add a **"Buy me a coffee ☕"** item that
  opens `https://buymeacoffee.com/rujitraval`.
- Wrap it in `#if DIRECT_BUILD … #endif` so it is **absent from the App Store build** and present
  only in the direct `.dmg`. Match the existing UI style; keep the "Data provided by
  football-data.org" link in both builds.

### 3. `app/ExportOptions-DeveloperID.plist`
- A new export-options plist with `method = developer-id`, `signingStyle = automatic`,
  `teamID = __TEAM_ID__` (substituted by the script, like the existing `ExportOptions.plist`).

### 4. `app/notarize.sh` — Developer ID → DMG → notarize → staple
Mirror the style of `archive.sh`. Steps:
1. Require env vars and fail fast if missing: `TEAM_ID` and a notarytool credential
   (`NOTARY_PROFILE` = a keychain profile name created once via
   `xcrun notarytool store-credentials`). Document both clearly at the top.
2. `xcodegen generate`.
3. `xcodebuild archive` — Release, `DEVELOPMENT_TEAM="$TEAM_ID"`, Automatic signing,
   **Hardened Runtime on**, `-allowProvisioningUpdates` (so xcodebuild can create/download signing
   certs), and `SWIFT_ACTIVE_COMPILATION_CONDITIONS` including `DIRECT_BUILD`.
4. `xcodebuild -exportArchive` with `ExportOptions-DeveloperID.plist` (team substituted) → a
   signed `MenuFC.app`.
5. Package into `build/MenuFC.dmg` using built-in `hdiutil` (no extra brew deps): stage a temp
   folder containing `MenuFC.app` + an `/Applications` symlink, then
   `hdiutil create -volname "MenuFC" -srcfolder <stage> -ov -format UDZO build/MenuFC.dmg`.
6. Notarize and wait: `xcrun notarytool submit build/MenuFC.dmg --keychain-profile "$NOTARY_PROFILE" --wait`.
7. Staple: `xcrun stapler staple build/MenuFC.dmg` (and the `.app` before packaging is fine too).
8. Print a clear "✅ Notarized DMG ready at build/MenuFC.dmg — attach it to a GitHub Release."
- **Do not hardcode secrets or Team IDs.** Leave them as env vars / `__TEAM_ID__` placeholders
  with TODO comments.

### 5. Docs
- Update `app/README.md`: document the two channels and two scripts (`archive.sh` = App Store,
  `notarize.sh` = direct), the `DIRECT_BUILD` flag and what it gates, the notarytool credential
  setup (`store-credentials`), and a short **GitHub Releases** checklist (tag → draft release →
  attach `MenuFC.dmg` → publish). Reference `docs/distribution-and-costs.md`.
- Update the **root `README.md`**: the app is **free**, available on the Mac App Store and as a
  direct `.dmg` from GitHub Releases.

## Constraints
- The **App Store build must be unchanged**: same sandbox + entitlements, and **no tip link**.
- Hardened Runtime must be on for the Developer ID build (notarization requires it).
- Keep App Sandbox enabled for the direct build too (it's fine with Developer ID).
- Don't modify `worker/` or `client/`. Don't commit secrets, Team IDs, or credentials.

## Verify before finishing
1. **Both builds compile** via `xcodebuild`:
   - App Store config (as `archive.sh` builds it) — confirm **no** `DIRECT_BUILD` and **no tip link**.
   - Direct config (with `SWIFT_ACTIVE_COMPILATION_CONDITIONS=…DIRECT_BUILD`) — compiles **with** the tip link.
2. Grep to prove the tip link is guarded by `#if DIRECT_BUILD` and appears nowhere unguarded.
3. `notarize.sh` is shellcheck-clean and exits with a helpful message if `TEAM_ID` or
   `NOTARY_PROFILE` is unset. (Actual signing/notarization needs the developer's Apple account on
   a Mac — don't attempt real notarization here; just prove the script is correct and the project
   archives.)
4. Note in the README that the first notarization requires a one-time
   `xcrun notarytool store-credentials` setup.
