# MenuFC — Start Here: your step-by-step to launch

**What's already done:** the finished native app (built from `BUILD_PROMPT.md`), the app icon,
and all the launch docs below. **What's left** is mostly accounts, paperwork, and running two
build scripts — in this order.

**Reference docs (all in this repo):**
- `docs/app-store-listing.md` — copy/paste text for the App Store listing
- `docs/privacy-policy.md` — host this; Apple requires the URL
- `docs/distribution-and-costs.md` — costs, data plan, notarization, GitHub Releases
- `BUILD_PROMPT.md` / `DIRECT_DIST_PROMPT.md` — the Claude Code prompts

---

## Phase 1 — Accounts & data (start now; these have lead time)

1. [ ] **Enroll in the Apple Developer Program** — $99/yr at developer.apple.com. Identity
   verification can take 1–2 days. **This gates everything below** (signing, notarizing, listing).
2. [ ] **Subscribe to football-data.org "Free w/ Livescores"** (€12/mo). Send the email in
   `docs/distribution-and-costs.md` to confirm it covers a free app. If the plan issues a new API
   key, update the Worker secret (`wrangler secret put` — see `docs/RUNBOOK.md`).

## Phase 2 — Finish the app (on your Mac)

3. [ ] **Run `DIRECT_DIST_PROMPT.md` in Claude Code** to add the notarized build + the
   direct-only tip link. (The app and icon are already built.)
4. [ ] **Add your Apple Team ID** where the TODOs say: `app/project.yml`, `app/archive.sh`,
   `app/notarize.sh`.
5. [ ] **QA during a live match:** score updates, offline fallback, light/dark mode,
   launch-at-login (on a signed build).

## Phase 3 — Ship on the Mac App Store (free)

6. [ ] **Host the privacy policy** (`docs/privacy-policy.md`) at a public URL — GitHub Pages is free.
7. [ ] **Create the app in App Store Connect:** bundle id `com.rujitraval.menufc`, name from the
   listing kit, category Sports, **price Free**.
8. [ ] **Fill the listing** from `docs/app-store-listing.md` (subtitle, description, keywords),
   add the privacy-policy URL, set **App Privacy = Data Not Collected**, and upload screenshots
   (plan is in the listing kit).
9. [ ] **Build & upload:** `TEAM_ID=… ./app/archive.sh`, then upload with Transporter (or Xcode
   Organizer).
10. [ ] **Submit for review** → release when approved.

## Phase 4 — Ship the direct .dmg (GitHub Releases)

11. [ ] **One-time:** create the notarization credential —
    `xcrun notarytool store-credentials "MenuFC-notary"`.
12. [ ] **Build the DMG:** `TEAM_ID=… NOTARY_PROFILE="MenuFC-notary" ./app/notarize.sh` → produces
    a stapled `build/MenuFC.dmg`.
13. [ ] **Publish:** GitHub → Releases → draft a release, tag it (e.g. `v1.0`), attach
    `MenuFC.dmg`, publish. Share the link.

---

## Every future update
Bump the version → run `./app/archive.sh` (App Store) **and** `./app/notarize.sh` (.dmg) →
submit the App Store update and attach the new `.dmg` to a new GitHub Release.

## Keep in mind
- **Running cost ≈ $21/mo** (Apple + data); the tip link in the `.dmg` can offset it.
- **Keep "FIFA"/"World Cup" out** of the name, icon, screenshots, and copy.
- The App Store build has **no tip link** by design; the `.dmg` build does.
