# MenuFC Runbook

One page on how MenuFC fits together, how to operate it, and how to test it end-to-end.

## How it fits together

```
SwiftBar client                 Cloudflare Worker                 football-data.org
menufc.30s.py        ──HTTPS──▶ menufc-api  +  KV cache  ──HTTPS──▶ /v4/competitions/WC
(each user's Mac)     /scores    (holds API key as secret)  X-Auth-Token   /matches
```

- The **client** only ever calls the Worker's `/scores`. It holds no secret and is safe to open-source.
- The **Worker** holds the football-data.org key (Cloudflare secret) and caches centrally, so **one
  upstream fetch serves all users** — usage stays flat no matter how many people install the client.
- `/scores` is **open** — no auth, login, or license gate.

## Where things live

| Thing                     | Location                                                              |
|---------------------------|----------------------------------------------------------------------|
| Worker code               | `worker/src/index.js`, `worker/src/flags.js`                         |
| Worker config + cache     | `worker/wrangler.toml` (KV binding `MENUFC_CACHE`, tunable `vars`)   |
| **API key (production)**  | Cloudflare secret `FOOTBALL_DATA_KEY` — `wrangler secret put`        |
| **API key (local dev)**   | `worker/.dev.vars` — **gitignored**, never committed                |
| Client plugin             | `client/menufc.30s.py` (Worker URL baked in; no secret)             |
| Live Worker               | `https://menufc-api.rujit.workers.dev`                              |
| Coffee link               | `https://buymeacoffee.com/rujitraval`                              |

## Deploy / update the Worker

```bash
cd worker
wrangler deploy                       # deploy code changes
wrangler tail                         # live logs (debug)
wrangler secret put FOOTBALL_DATA_KEY # set/rotate the API key (paste at prompt)
```

Tunable knobs in `worker/wrangler.toml` `[vars]` (no code change needed, just redeploy):
`LIVE_TTL_SECONDS` (60), `IDLE_TTL_SECONDS` (3600), `PREKICK_MINUTES` (5), `POSTMATCH_MINUTES` (150).

## Update the client

Edit `client/menufc.30s.py`, then re-copy it into each user's SwiftBar plugins folder (or cut a new
GitHub Release `.zip` — see below). The Worker URL is the only environment-specific value.

## End-to-end test (do this after any deploy)

1. **Worker health:** `curl -s https://menufc-api.rujit.workers.dev/health` → `{"ok":true,...}`
2. **Scores in a browser:** open `https://menufc-api.rujit.workers.dev/scores` → JSON with `matches`.
   Hit reload twice; response header `X-MenuFC-Source` should go `refreshed` → `fresh` (cache working).
3. **Client locally:** `python3 client/menufc.30s.py` → prints the menu-bar title + dropdown.
4. **In the menu bar:** ensure `menufc.30s.py` is in the SwiftBar plugins folder → MenuFC shows the
   featured match; clicking shows all matches.
5. **Coffee link:** click **Buy me a coffee ☕** → opens `buymeacoffee.com/rujitraval`.
6. **Crash-proofing:** temporarily turn off Wi-Fi → MenuFC shows last scores + "offline", never breaks.

## Cost ceiling

- Cloudflare **Workers Free = 100k requests/day**. Client smart-polls (only during live windows), so
  realistically a few hundred casual users fit on free. **$5/mo Workers Paid** lifts to 10M req/month.
- **KV Free = 1,000 writes/day**; at 60s live TTL we write ~600/day max on a heavy match day — under cap.
- Upstream stays ~1 fetch/min during live windows regardless of user count (well under the ~10/min limit).

## Distribution (GitHub Release)

```bash
# Bundle the client + guide, then attach to a versioned release:
mkdir -p dist/MenuFC && cp client/menufc.30s.py docs/Setting-up-MenuFC.md dist/MenuFC/
(cd dist && zip -r MenuFC-v1.0.zip MenuFC)
gh release create v1.0 dist/MenuFC-v1.0.zip \
  --title "MenuFC v1.0" \
  --notes "Live FIFA World Cup 2026 scores in your macOS menu bar. Unzip and follow Setting-up-MenuFC."
```

## Incident notes

- **Scores look stale/null:** football-data.org sometimes serves provisional/null scores; the Worker and
  client are null-safe by design (show `–`/matchup form, never crash).
- **Worker erroring:** `wrangler tail` to watch logs; `/scores` falls back to last-known cache on upstream
  failure (`X-MenuFC-Source: upstream-error-stale`).
- **Rotating the key:** `wrangler secret put FOOTBALL_DATA_KEY` then `wrangler deploy`. Also update
  `worker/.dev.vars` locally. Never commit the key.
