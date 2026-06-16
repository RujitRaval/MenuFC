// menufc-api — Cloudflare Worker
//
// GET /scores  -> pre-shaped, null-safe World Cup (WC) scores for "today" (US Eastern day).
//                 Open to anyone. No auth, no key check.
//
// Caching model (keeps upstream football-data.org usage flat regardless of user count):
//   - One KV-backed cache of today's matches, lazily refreshed.
//   - A stale /scores request becomes the single refresher; everyone else serves cache.
//   - Live window (any match near kickoff or in play): short TTL (LIVE_TTL_SECONDS).
//     Off-hours: long TTL (IDLE_TTL_SECONDS) — serve last-known, refresh hourly to catch
//     the day rollover.
//   - A KV "refresh lock" stops simultaneous stale requests from all hitting upstream.
//
// The football-data.org key is env.FOOTBALL_DATA_KEY — a secret (wrangler secret put),
// never in code or the repo. For local `wrangler dev` it comes from worker/.dev.vars.

import { flagFor } from "./flags.js";

// Use the top-level /matches endpoint (competition-filtered). It returns FRESH, correct
// scores, whereas /competitions/WC/matches serves stale/null scores on the free tier.
const UPSTREAM = "https://api.football-data.org/v4/matches";
const WC_COMPETITION_ID = 2000; // FIFA World Cup (code "WC")
const CACHE_KEY = "cache:v1";
const LOCK_KEY = "lock:refresh";
const FORCE_MIN_AGE_MS = 15000; // a ?fresh=1 request only refetches if cache is older than this (anti-abuse)

// YYYY-MM-DD in US Eastern, DST-safe (en-CA renders ISO order).
const ET_FMT = new Intl.DateTimeFormat("en-CA", {
  timeZone: "America/New_York",
  year: "numeric",
  month: "2-digit",
  day: "2-digit",
});

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);

    if (request.method === "OPTIONS") return cors(new Response(null, { status: 204 }));
    if (request.method !== "GET") return json({ error: "method_not_allowed" }, 405);

    if (url.pathname === "/" || url.pathname === "/health") {
      return json({ ok: true, service: "menufc-api" });
    }
    if (url.pathname === "/scores") {
      // Best-effort, privacy-preserving usage count — runs after responding, never blocks/breaks it.
      ctx.waitUntil(recordHit(request, env).catch(() => {}));
      try {
        return await handleScores(env, url.searchParams.has("fresh"));
      } catch (err) {
        // Last-resort guard: never 500 the menu bar.
        return scoresResponse(emptyPayload(etDateString(new Date())), "error:" + (err && err.message));
      }
    }
    if (url.pathname === "/stats") {
      return await handleStats(env, url.searchParams.get("key"));
    }
    return json({ error: "not_found" }, 404);
  },
};

async function handleScores(env, forced) {
  const now = Date.now();
  const etDate = etDateString(new Date(now));
  const cache = await readCache(env);

  // Manual Refresh (?fresh=1) punches through the idle cache to upstream, but only if the
  // cache is older than FORCE_MIN_AGE_MS — so a burst of forced refreshes still hits upstream
  // at most ~once per 15s (and the herd lock below dedupes concurrent ones).
  const age = cache && cache.fetchedAt ? now - cache.fetchedAt : Infinity;
  const forceRefetch = forced && age >= FORCE_MIN_AGE_MS;

  if (!forceRefetch && !isStale(cache, now, etDate, env)) {
    return scoresResponse(cache.payload, "fresh");
  }

  // Stale — try to become the single refresher.
  const gotLock = await acquireLock(env);
  if (!gotLock) {
    if (cache && cache.payload) return scoresResponse(cache.payload, "stale-locked");
    return scoresResponse(emptyPayload(etDate, now), "empty-locked");
  }

  try {
    const fresh = await fetchAndShape(env, now, etDate);
    await writeCache(env, fresh);
    return scoresResponse(fresh.payload, "refreshed");
  } catch (err) {
    // Upstream failed — serve last-known if we have it, else empty. Never crash.
    if (cache && cache.payload) return scoresResponse(cache.payload, "upstream-error-stale");
    return scoresResponse(emptyPayload(etDate, now), "upstream-error-empty");
  } finally {
    await releaseLock(env);
  }
}

// ── staleness / live-window ────────────────────────────────────────────────
function isStale(cache, now, etDate, env) {
  if (!cache || !cache.payload) return true;
  if (cache.etDate !== etDate) return true; // ET day rolled over -> new slate
  const ttl =
    (inLiveWindow(cache.payload.matches, now, env)
      ? num(env.LIVE_TTL_SECONDS, 60)
      : num(env.IDLE_TTL_SECONDS, 3600)) * 1000;
  return now - cache.fetchedAt > ttl;
}

function inLiveWindow(matches, now, env) {
  const pre = num(env.PREKICK_MINUTES, 5) * 60000;
  const post = num(env.POSTMATCH_MINUTES, 150) * 60000;
  return (matches || []).some((m) => {
    if (m.state === "LIVE" || m.state === "HT") return true; // definitely live
    const ko = Date.parse(m.utcDate);
    return Number.isFinite(ko) && now >= ko - pre && now <= ko + post;
  });
}

// ── upstream fetch + shaping ───────────────────────────────────────────────
async function fetchAndShape(env, now, etDate) {
  // The ET day spans two UTC dates; this endpoint's dateTo window runs narrow, so fetch a
  // 3-day UTC window and filter to the ET day below.
  const from = etDate;
  const to = addDays(etDate, 2);
  const url = `${UPSTREAM}?competitions=${WC_COMPETITION_ID}&dateFrom=${from}&dateTo=${to}`;
  const res = await fetch(url, {
    headers: {
      "X-Auth-Token": env.FOOTBALL_DATA_KEY,
      // Opt into the live `minute` / `injuryTime` fields (football-data Livescore add-on).
      "X-Api-Version": "v4.1",
      Accept: "application/json",
    },
  });
  if (!res.ok) throw new Error("upstream_" + res.status);
  const data = await res.json();
  const matches = (data.matches || [])
    .filter((m) => etDateString(new Date(m.utcDate)) === etDate)
    .map(shapeMatch)
    .sort((a, b) => a.utcDate.localeCompare(b.utcDate));
  return {
    fetchedAt: now,
    etDate,
    payload: { updated: new Date(now).toISOString(), date: etDate, matches },
  };
}

function shapeMatch(m) {
  const ft = (m.score && m.score.fullTime) || {};
  const ht = (m.score && m.score.halfTime) || {};
  return {
    id: m.id,
    utcDate: m.utcDate,
    status: m.status,
    state: mapState(m.status),
    matchday: m.matchday ?? null,
    group: m.group ?? null,
    minute: m.minute ?? null,        // live elapsed minute (v4.1); null off-play
    injuryTime: m.injuryTime ?? null, // added minutes, e.g. 45+2
    home: shapeTeam(m.homeTeam),
    away: shapeTeam(m.awayTeam),
    score: { home: ft.home ?? null, away: ft.away ?? null },
    halfTime: { home: ht.home ?? null, away: ht.away ?? null },
  };
}

function shapeTeam(t) {
  if (!t) return { tla: "TBD", name: "TBD", flag: "⚽" };
  const tla = t.tla || null;
  return { tla: tla || "TBD", name: t.shortName || t.name || "TBD", flag: flagFor(tla) };
}

function mapState(status) {
  switch (status) {
    case "IN_PLAY": return "LIVE";
    case "PAUSED": return "HT";
    case "FINISHED":
    case "AWARDED": return "FT";
    case "TIMED":
    case "SCHEDULED": return "SCHED";
    case "POSTPONED": return "PP";
    case "SUSPENDED": return "SUSP";
    case "CANCELLED": return "CANC";
    default: return "SCHED";
  }
}

// ── KV cache + lock ────────────────────────────────────────────────────────
async function readCache(env) {
  const raw = await env.MENUFC_CACHE.get(CACHE_KEY);
  if (!raw) return null;
  try { return JSON.parse(raw); } catch { return null; }
}
async function writeCache(env, entry) {
  await env.MENUFC_CACHE.put(CACHE_KEY, JSON.stringify(entry));
}
async function acquireLock(env) {
  if (await env.MENUFC_CACHE.get(LOCK_KEY)) return false;
  // 60s is the KV minimum expirationTtl; also a safety auto-release if releaseLock is missed.
  await env.MENUFC_CACHE.put(LOCK_KEY, "1", { expirationTtl: 60 });
  return true;
}
async function releaseLock(env) {
  try { await env.MENUFC_CACHE.delete(LOCK_KEY); } catch {}
}

// ── usage analytics (privacy-preserving, server-side, no app changes) ────────
// Counts distinct daily visitors WITHOUT storing personal data. We never store an IP — only
// a per-day pseudonymous token = SHA-256(ip + day + secret salt), which cannot be reversed to
// an IP and cannot be linked across days, plus a daily integer count. Runs in ctx.waitUntil,
// so it never affects /scores latency or reliability. Set two secrets:
//   wrangler secret put STATS_SALT   (any long random string — keeps tokens unguessable)
//   wrangler secret put STATS_KEY    (the password for reading /stats)
async function recordHit(request, env) {
  const ip = request.headers.get("CF-Connecting-IP") || "";
  if (!ip) return;
  const day = etDateString(new Date());
  const token = await sha256hex(ip + "|" + day + "|" + (env.STATS_SALT || "menufc"));
  const seenKey = `u:${day}:${token}`;
  if (await env.MENUFC_CACHE.get(seenKey)) return;                       // already counted today
  await env.MENUFC_CACHE.put(seenKey, "1", { expirationTtl: 172800 });   // 2-day TTL, self-cleaning
  // Channel split: the .dmg build sends ?ch=direct; everything else counts as App Store.
  const ch = new URL(request.url).searchParams.get("ch") === "direct" ? "direct" : "appstore";
  for (const key of [`dau:${day}`, `dau:${day}:${ch}`]) {
    const cur = parseInt((await env.MENUFC_CACHE.get(key)) || "0", 10);
    await env.MENUFC_CACHE.put(key, String(cur + 1), { expirationTtl: 60 * 60 * 24 * 120 });
  }
}

// GET /stats?key=YOUR_STATS_KEY
//   -> { dailyActiveUsers: {date:count}, byChannel: { appstore:{date:count}, direct:{date:count} } }
async function handleStats(env, key) {
  if (!env.STATS_KEY || key !== env.STATS_KEY) return json({ error: "forbidden" }, 403);
  const list = await env.MENUFC_CACHE.list({ prefix: "dau:" });
  const total = {}, appstore = {}, direct = {};
  for (const k of list.keys) {
    const parts = k.name.split(":");           // dau:DATE  or  dau:DATE:CHANNEL
    const day = parts[1];
    const val = Number(await env.MENUFC_CACHE.get(k.name));
    if (parts.length === 2) total[day] = val;
    else if (parts[2] === "appstore") appstore[day] = val;
    else if (parts[2] === "direct") direct[day] = val;
  }
  const sort = (o) => Object.fromEntries(Object.entries(o).sort((a, b) => b[0].localeCompare(a[0])));
  return json({ dailyActiveUsers: sort(total), byChannel: { appstore: sort(appstore), direct: sort(direct) } });
}

async function sha256hex(str) {
  const buf = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(str));
  return [...new Uint8Array(buf)].map((b) => b.toString(16).padStart(2, "0")).join("");
}

// ── helpers ────────────────────────────────────────────────────────────────
function etDateString(d) { return ET_FMT.format(d); }
function addDays(dateStr, n) {
  const [y, m, d] = dateStr.split("-").map(Number);
  const dt = new Date(Date.UTC(y, m - 1, d));
  dt.setUTCDate(dt.getUTCDate() + n);
  return dt.toISOString().slice(0, 10);
}
function emptyPayload(etDate, now) {
  return { updated: new Date(now || Date.now()).toISOString(), date: etDate, matches: [] };
}
function num(v, dflt) { const n = Number(v); return Number.isFinite(n) ? n : dflt; }

function scoresResponse(payload, source) {
  return json(payload, 200, { "X-MenuFC-Source": source });
}
function cors(resp) {
  resp.headers.set("access-control-allow-origin", "*");
  resp.headers.set("access-control-allow-methods", "GET, OPTIONS");
  return resp;
}
function json(obj, status = 200, extraHeaders = {}) {
  return new Response(JSON.stringify(obj), {
    status,
    headers: {
      "content-type": "application/json; charset=utf-8",
      "access-control-allow-origin": "*",
      "cache-control": "no-store",
      ...extraHeaders,
    },
  });
}
