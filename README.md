# MenuFC ⚽

A free macOS menu-bar app showing **live FIFA World Cup 2026 scores**, with an optional "Buy me a coffee" tip link.

## How it fits together

```
┌──────────────────────┐        ┌──────────────────────────┐        ┌─────────────────────┐
│  SwiftBar client      │  HTTPS │  Cloudflare Worker        │  HTTPS │  football-data.org   │
│  menufc.30s.py        │ ─────▶ │  menufc-api  (+ KV cache) │ ─────▶ │  /v4/competitions/WC │
│  (on each user's Mac) │ /scores│  holds API key as secret  │        │  (X-Auth-Token)      │
└──────────────────────┘        └──────────────────────────┘        └─────────────────────┘
```

- The **client never calls football-data.org directly** — only the Worker's `/scores` endpoint.
- The **Worker holds the football-data.org key as a secret** (`wrangler secret put`) and caches scores
  centrally, so one upstream fetch serves all users — keeping us under football-data.org's free-tier
  rate limit no matter how many people install the client.
- `/scores` is **open to anyone** — no auth, login, or license gate.
- The **client is safe to open-source**: it contains no secret, only the Worker URL.

## Repo layout

| Path        | What it is                                                        | Phase |
|-------------|-------------------------------------------------------------------|-------|
| `worker/`   | Cloudflare Worker (`menufc-api`) + KV cache. Key lives in a secret. | 2     |
| `app/`      | **Native macOS menu-bar app (Swift/AppKit)** — the shippable client. | 5     |
| `client/`   | SwiftBar plugin `menufc.30s.py` — superseded by `app/`, kept as reference. | 3     |
| `docs/`     | "Setting up MenuFC" guide + one-page runbook.                     | 4     |

> **The native app in [`app/`](app/) supersedes the SwiftBar plugin.** Same data and behavior,
> built to ship on the Mac App Store. See [`app/README.md`](app/README.md) for build/run and the
> Python→Swift parity checklist. The `worker/` backend is unchanged.

## Security invariants (do not break)

- The football-data.org API key appears **only** as a Cloudflare Worker secret — never in the client,
  never in this repo. See [`.gitignore`](.gitignore).
- The client ships with the public Worker URL baked in and nothing else sensitive.

## Install (users)

See **[docs/Setting-up-MenuFC.md](docs/Setting-up-MenuFC.md)** — no key or account needed.
Operators: see the **[runbook](docs/RUNBOOK.md)**.

Live Worker: `https://menufc-api.rujit.workers.dev` · Coffee: `https://buymeacoffee.com/rujitraval`

## Status

✅ Worker deployed, client working. Built in phases (0 → 4). License: [MIT](LICENSE).
