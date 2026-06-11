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
| `client/`   | SwiftBar plugin `menufc.30s.py` (Python 3, stdlib only).          | 3     |
| `docs/`     | "Setting up MenuFC" guide + one-page runbook.                     | 4     |

## Security invariants (do not break)

- The football-data.org API key appears **only** as a Cloudflare Worker secret — never in the client,
  never in this repo. See [`.gitignore`](.gitignore).
- The client ships with the public Worker URL baked in and nothing else sensitive.

## Status

🚧 Under construction — built in phases. Currently: **Phase 0 (prereqs) / repo setup**.
