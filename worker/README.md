# worker/ — Cloudflare Worker `menufc-api`

Serves `GET /scores`: pre-shaped, null-safe FIFA World Cup scores for **today** (US Eastern day),
open to anyone — no auth, no key check.

## Files

| File             | Purpose                                                            |
|------------------|-------------------------------------------------------------------|
| `src/index.js`   | Worker: routing, KV cache, live-window TTL, herd lock, shaping.    |
| `src/flags.js`   | FIFA `tla` → flag-emoji lookup (FIFA codes aren't ISO codes).      |
| `wrangler.toml`  | Worker config, KV binding, tunable non-secret `vars`.             |
| `.dev.vars`      | **gitignored** local secret (`FOOTBALL_DATA_KEY`) for `wrangler dev`. |

## Secret

The football-data.org key is **never** in code or the repo:

- Production: `wrangler secret put FOOTBALL_DATA_KEY`
- Local dev: `worker/.dev.vars` (gitignored), auto-loaded by `wrangler dev`.

## Caching

- `LIVE_TTL_SECONDS` (default 60) while any match is near kickoff or in play; caps upstream at ~1 req/min.
- `IDLE_TTL_SECONDS` (default 3600) off-hours; serves last-known, refreshes hourly to catch the day rollover.
- A KV `lock:refresh` flag makes one stale request the sole upstream refresher (thundering-herd guard).

## `/scores` response shape

```json
{
  "updated": "2026-06-11T21:15:00Z",
  "date": "2026-06-11",
  "matches": [{
    "id": 537327,
    "utcDate": "2026-06-11T19:00:00Z",
    "status": "FINISHED",
    "state": "FT",
    "home": { "tla": "MEX", "name": "Mexico", "flag": "🇲🇽" },
    "away": { "tla": "RSA", "name": "South Africa", "flag": "🇿🇦" },
    "score": { "home": null, "away": null },
    "halfTime": { "home": null, "away": null }
  }]
}
```

`state` is one of `SCHED | LIVE | HT | FT | PP | SUSP | CANC`. Scores are null-safe.
Response header `X-MenuFC-Source` shows cache provenance: `fresh | refreshed | stale-locked | upstream-error-stale | …`.
