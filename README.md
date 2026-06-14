# MenuFC ⚽

[![.dmg downloads](https://img.shields.io/github/downloads/RujitRaval/MenuFC/total?label=.dmg%20downloads&color=2ea043)](https://github.com/RujitRaval/MenuFC/releases)

A free macOS menu-bar app showing **live football scores**, one glance away. Distributed on the
**Mac App Store** (free) and as a **direct notarized download**.

## How it fits together

```
┌───────────────────────────┐        ┌──────────────────────────┐        ┌──────────────────────────┐
│  macOS menu-bar app        │  HTTPS │  Cloudflare Worker        │  HTTPS │  football-data.org        │
│  (App Store + .dmg)        │ ─────▶ │  menufc-api  (+ KV cache) │ ─────▶ │  /v4/matches?competitions │
│  app/  (Swift/AppKit)      │ /scores│  holds API key as secret  │        │  (X-Auth-Token)           │
└───────────────────────────┘        └──────────────────────────┘        └──────────────────────────┘
```

- The **app never calls football-data.org directly** — only the Worker's `/scores` endpoint.
- The **Worker holds the football-data.org key as a secret** (`wrangler secret put`) and caches scores
  centrally, so one upstream fetch serves all users — keeping us under football-data.org's free-tier
  rate limit no matter how many people install the app.
- `/scores` is **open to anyone** — no auth, login, or license gate.
- The **app is safe to open-source**: it contains no secret, only the public Worker URL.

## Repo layout

| Path        | What it is                                                                       |
|-------------|----------------------------------------------------------------------------------|
| `app/`      | **Native macOS menu-bar app (Swift/AppKit)** — the shipping client. See [`app/README.md`](app/README.md). |
| `worker/`   | Cloudflare Worker (`menufc-api`) + KV cache. API key lives in a secret.          |
| `client/`   | Original SwiftBar plugin (`menufc.30s.py`) — **superseded by `app/`**, kept as reference. |
| `docs/`     | Public website (landing page + privacy policy), served via GitHub Pages.         |

## Get it

- **Mac App Store** — free (submitted for review).
- **Direct download** — a Developer-ID-signed, **notarized `.dmg`** via [GitHub Releases](https://github.com/RujitRaval/MenuFC/releases). The direct build also includes an optional **Buy me a coffee** link (the App Store build doesn't, per Apple's in-app-payment rules).
- **Landing page:** https://rujitraval.github.io/MenuFC

## Security invariants (do not break)

- The football-data.org API key appears **only** as a Cloudflare Worker secret — never in the app,
  never in this repo. See [`.gitignore`](.gitignore).
- The app ships with the public Worker URL baked in and nothing else sensitive.

## Status

✅ Worker deployed · native app built, notarized, and submitted to the Mac App Store · direct `.dmg`
distribution ready. License: [MIT](LICENSE). Live Worker: `https://menufc-api.rujit.workers.dev`.
