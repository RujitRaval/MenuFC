# MenuFC — distribution & running costs

Strategy: **MenuFC is free.** Two ways to get it:

1. **Mac App Store** — free download, one-click install, automatic updates. Best for
   non-technical fans.
2. **Direct `.dmg`** — a notarized download hosted on **GitHub Releases**, for people who
   don't want the App Store.

Both come from the same codebase; they differ only in how they're signed and exported. The
build tooling for the direct path is added by `DIRECT_DIST_PROMPT.md` (run it in Claude Code).

---

## Running costs (it's free, so these are out-of-pocket)

| Cost | Amount | Notes |
|---|---|---|
| Apple Developer Program | $99/yr ≈ **$8.25/mo** | Required for *both* the App Store and a notarized `.dmg`. |
| Data — €12 "Free w/ Livescores" | ≈ **$13/mo** | Still required — the app needs live scores. +VAT may apply. |
| **Total** | **≈ $21/mo** | No revenue offsets this now. |

This is fine for a passion project — just go in knowing it's a ~$21/mo cost, not a profit
center. The **tip link in the direct-download build** ("Buy me a coffee") can offset some or
all of it; tips are unpredictable, so treat anything that comes in as a bonus.

> If you later want real revenue, the cleanest options are a paid tier or an in-app "tip jar"
> on the App Store — but those re-introduce Apple's cut and review overhead. Out of scope for now.

---

## The data plan (unchanged by going free)

Your Cloudflare Worker centralizes all traffic, so regardless of install count the upstream
sees only **~2–3 calls/min during live matches**. You need a tier that has **live scores** and
**permits your use** — not a high rate limit. The **€12/mo "Free w/ Livescores"** tier is the
baseline.

### Email to send (to daniel@football-data.org)

> **Subject:** Which plan for a free macOS scores app?
>
> Hi Daniel,
>
> I've built a small, **free** macOS menu-bar app that shows live football scores, and I'm about
> to publish it on the Mac App Store and as a direct download.
>
> It doesn't call your API directly — all traffic goes through a single Cloudflare Worker I run,
> which caches results and refreshes about once every 25 seconds **only while matches are live**.
> So no matter how many people install it, you'd see roughly **2–3 requests per minute during
> games, and almost none otherwise**, for live scores on a small number of competitions.
>
> Two questions:
>
> 1. Which plan is right for this? I'm looking at **"Free w/ Livescores" (€12/mo)** given the
>    low, centralized call volume — does that tier's terms cover a free, publicly distributed app?
> 2. Anything in your terms I should know about, or attribution you'd like? I currently show
>    "Data provided by football-data.org" in the app.
>
> Thanks for building such a clean API.
>
> Best,
> Rujit Raval — rujitraval@gmail.com

---

## How the two channels differ

| | **Mac App Store** | **Direct `.dmg`** |
|---|---|---|
| Price | Free | Free |
| Signing | Apple Distribution (App Store) | **Developer ID Application** |
| Notarization | Handled by Apple | **You notarize + staple** (`notarytool`, `stapler`) |
| Sandbox | Required (already on) | Optional (we keep it on) |
| Hardened Runtime | Yes | **Yes (required for notarization)** |
| Install | One-click "Get" | Open `.dmg`, drag to Applications |
| Updates | Automatic | Manual re-download (or add Sparkle later) |
| Tip link | Not allowed | **Allowed** (included in this build) |
| Export script | `app/archive.sh` | `app/notarize.sh` (added by the prompt) |

### What "notarization" is and why it matters
Notarization is Apple scanning your signed app and issuing a ticket that says "this is from a
known developer and is malware-free." Without it, recent macOS (Sequoia and later) makes users
dig into **System Settings → Privacy & Security** just to open the app — a dealbreaker for
non-technical users. With it stapled to the `.dmg`, the app opens cleanly. Notarization is
**free** with your $99 developer account.

---

## Publishing the direct download on GitHub Releases

You already host the project on GitHub, so releases are the natural home — free, versioned, and
trusted. Once `notarize.sh` has produced a stapled `MenuFC.dmg`:

1. Tag a version: `git tag v1.0 && git push origin v1.0`.
2. On GitHub → **Releases → Draft a new release** → pick the tag.
3. Title it (e.g., "MenuFC 1.0"), write short notes, and **attach `MenuFC.dmg`** as a binary.
4. Publish. Share the release page link (or a "Download for Mac" button on a simple page).
5. For each update: bump the version, re-run `notarize.sh`, and attach the new `.dmg` to a new release.

> Tip: link the App Store listing **and** the `.dmg` from one small landing page (also satisfies
> Apple's required Support/Marketing URL). I can draft that page if you want.
