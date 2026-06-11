#!/usr/bin/env python3
# <xbar.title>MenuFC</xbar.title>
# <xbar.version>v1.0</xbar.version>
# <xbar.author>Rujit Raval</xbar.author>
# <xbar.desc>Live FIFA World Cup 2026 scores in your menu bar.</xbar.desc>
# <xbar.dependencies>python3</xbar.dependencies>
# <swiftbar.hideAbout>false</swiftbar.hideAbout>
# <swiftbar.hideRunInTerminal>true</swiftbar.hideRunInTerminal>
#
# MenuFC — SwiftBar plugin. Python 3, stdlib only, crash-proof.
#
# Talks ONLY to the MenuFC Cloudflare Worker (never football-data.org directly).
# Contains no secret — safe to open-source. The Worker holds the API key.
#
# Smart polling: caches today's schedule locally and only calls the Worker inside
# live windows (just before kickoff through ~150 min after). Off-hours / idle days
# it renders from the local cache and makes zero network calls. Any failure falls
# back to the last cached scores and never breaks the menu bar.

import json
import os
import time
import urllib.request
from datetime import datetime, timedelta, timezone

# ── Config ───────────────────────────────────────────────────────────────────
WORKER_URL = "https://menufc-api.rujit.workers.dev"
SCORES_URL = WORKER_URL + "/scores"
COFFEE_URL = "https://buymeacoffee.com/rujitraval"
PROVIDER_URL = "https://www.football-data.org"

TIMEOUT = 4               # seconds — short, so a slow network never hangs the menu bar
LIVE_REFRESH = 25         # seconds — min spacing between Worker calls during live windows
PREKICK = timedelta(minutes=5)
POSTMATCH = timedelta(minutes=150)

CACHE_DIR = os.path.expanduser("~/Library/Caches/menufc")
CACHE_FILE = os.path.join(CACHE_DIR, "scores.json")

# US Eastern timezone (World Cup user-facing day). Fall back to fixed EDT if tz db missing.
try:
    from zoneinfo import ZoneInfo
    ET = ZoneInfo("America/New_York")
except Exception:
    ET = timezone(timedelta(hours=-4))

FINAL_STATES = ("FT", "PP", "SUSP", "CANC")


# ── Helpers ──────────────────────────────────────────────────────────────────
def parse_utc(s):
    try:
        return datetime.fromisoformat(s.replace("Z", "+00:00"))
    except Exception:
        return None


def fmt_time_et(utc_iso):
    dt = parse_utc(utc_iso)
    if not dt:
        return "TBD"
    return dt.astimezone(ET).strftime("%I:%M %p").lstrip("0")


def et_today():
    return datetime.now(ET).strftime("%Y-%m-%d")


def load_cache():
    try:
        with open(CACHE_FILE, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return None


def save_cache(obj):
    try:
        os.makedirs(CACHE_DIR, exist_ok=True)
        with open(CACHE_FILE, "w", encoding="utf-8") as f:
            json.dump(obj, f)
    except Exception:
        pass  # cache write failures must never break rendering


def fetch_scores():
    req = urllib.request.Request(SCORES_URL, headers={"User-Agent": "MenuFC-SwiftBar/1.0"})
    with urllib.request.urlopen(req, timeout=TIMEOUT) as r:
        return json.loads(r.read().decode("utf-8"))


def in_live_window(matches, now_utc):
    for m in matches or []:
        if m.get("state") in ("LIVE", "HT"):
            return True
        ko = parse_utc(m.get("utcDate", ""))
        if ko and (ko - PREKICK) <= now_utc <= (ko + POSTMATCH):
            return True
    return False


def has_score(m):
    s = m.get("score") or {}
    return s.get("home") is not None and s.get("away") is not None


# ── Rendering ────────────────────────────────────────────────────────────────
def title_line(m):
    if m is None:
        return "⚽ No WC matches today"
    st = m.get("state")
    home, away = m.get("home", {}), m.get("away", {})
    hf, af = home.get("flag", "⚽"), away.get("flag", "⚽")
    ht, at = home.get("tla", "TBD"), away.get("tla", "TBD")
    if st in ("LIVE", "HT", "FT") and has_score(m):
        s = m["score"]
        return f"{hf} {s['home']}–{s['away']} {af} {st}"
    if st == "SCHED":
        return f"{ht} v {at} {fmt_time_et(m.get('utcDate', ''))}"
    # FINISHED/live with null score, or PP/SUSP/CANC — show matchup + state
    return f"{ht} v {at} {st}"


def match_row(m):
    st = m.get("state", "SCHED")
    home, away = m.get("home", {}), m.get("away", {})
    hf, af = home.get("flag", "⚽"), away.get("flag", "⚽")
    ht, at = home.get("tla", "TBD"), away.get("tla", "TBD")
    if has_score(m):
        s = m["score"]
        core = f"{hf} {ht} {s['home']}–{s['away']} {at} {af}"
    else:
        core = f"{hf} {ht} v {at} {af}"
    suffix = (fmt_time_et(m.get("utcDate", "")) + " ET") if st == "SCHED" else st
    return f"{core}  {suffix}"


def pick_featured(matches):
    if not matches:
        return None
    live = [m for m in matches if m.get("state") in ("LIVE", "HT")]
    if live:
        return live[0]
    upcoming = sorted(
        [m for m in matches if m.get("state") == "SCHED"],
        key=lambda m: m.get("utcDate", ""),
    )
    if upcoming:
        return upcoming[0]
    finished = sorted(
        [m for m in matches if m.get("state") in FINAL_STATES],
        key=lambda m: m.get("utcDate", ""),
    )
    return finished[-1] if finished else None


def render(payload, fetched_at, offline):
    matches = sorted(
        (payload or {}).get("matches", []),
        key=lambda m: m.get("utcDate", ""),
    )

    # Menu bar (title)
    print(title_line(pick_featured(matches)))
    print("---")

    # Dropdown: every WC match today, one per line
    if matches:
        for m in matches:
            print(match_row(m))
    else:
        print("No World Cup matches today | color=gray")

    print("---")
    if fetched_at:
        upd = datetime.fromtimestamp(fetched_at, ET).strftime("%I:%M %p").lstrip("0")
        note = " · offline (last known)" if offline else ""
        print(f"Updated {upd} ET{note} | color=gray size=11")
    elif offline:
        print("Offline — no data yet | color=gray size=11")
    print("Refresh | refresh=true")
    print(f"Data provided by football-data.org | href={PROVIDER_URL}")
    print(f"Buy me a coffee ☕ | href={COFFEE_URL}")


# ── Main ─────────────────────────────────────────────────────────────────────
def main():
    now = datetime.now(timezone.utc)
    today = et_today()
    cache = load_cache()
    payload = cache.get("payload") if cache else None
    fetched_at = cache.get("fetched_at", 0) if cache else 0
    offline = False

    # Decide whether to call the Worker (smart poll):
    #   - no cache yet, or cache is from a previous ET day  -> fetch today's slate
    #   - inside a live window and last call > LIVE_REFRESH  -> refresh
    #   - otherwise (idle, same day)                         -> render cache, no call
    need = False
    if payload is None or payload.get("date") != today:
        need = True
    elif in_live_window(payload.get("matches", []), now):
        if (now.timestamp() - fetched_at) >= LIVE_REFRESH:
            need = True

    if need:
        try:
            payload = fetch_scores()
            fetched_at = now.timestamp()
            save_cache({"payload": payload, "fetched_at": fetched_at})
        except Exception:
            offline = True  # keep last-known payload (may be None on first-ever run)

    render(payload, fetched_at, offline)


if __name__ == "__main__":
    try:
        main()
    except Exception:
        # Absolute last resort — never break the menu bar.
        print("⚽ MenuFC")
        print("---")
        print("Temporary error — will retry | color=gray")
        print("Refresh | refresh=true")
        print(f"Buy me a coffee ☕ | href={COFFEE_URL}")
