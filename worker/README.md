# worker/ — Cloudflare Worker `menufc-api`

**Phase 2.** Serves `GET /scores` with a lazily-refreshed KV cache of today's World Cup matches.

The football-data.org API key is stored via `wrangler secret put FOOTBALL_DATA_KEY` — **never in code,
never committed**. See the root [`.gitignore`](../.gitignore).

> Not built yet — placeholder so the folder is tracked.
