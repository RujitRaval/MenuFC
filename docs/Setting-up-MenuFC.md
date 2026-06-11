# Setting up MenuFC

**MenuFC** puts live FIFA World Cup 2026 scores right in your Mac's menu bar. ⚽

It's free, there's **no account, no login, and no API key to set up** — just install and go.
Takes about 2 minutes.

---

## What you need

A Mac. That's it. (MenuFC uses two free tools — SwiftBar and Python — installed below.)

---

## Step 1 — Install SwiftBar

SwiftBar is the free app that runs little tools in your menu bar.

**Easiest:** download it from **https://swiftbar.app** → open the downloaded file → drag **SwiftBar** into
your **Applications** folder.

*(If you use Homebrew, you can instead run `brew install --cask swiftbar`.)*

Open **SwiftBar** once. The first time, it will ask you to **choose a plugins folder** — pick or create a
folder called **SwiftBar** in your home folder (so: `~/SwiftBar`). Remember this folder for Step 3.

---

## Step 2 — Make sure you have Python 3

Most Macs already have it. To check, open the **Terminal** app and type:

```
python3 --version
```

If you see a version number (like `Python 3.11`), you're set — skip to Step 3.

If it says "command not found," install Python from **https://www.python.org/downloads/macos/**
(download, open, click through the installer), then try the check again.

---

## Step 3 — Add MenuFC

1. Find the file **`menufc.30s.py`** (from the MenuFC download).
2. Move it into the SwiftBar plugins folder you chose in Step 1 (e.g. `~/SwiftBar`).
3. SwiftBar picks it up automatically within a few seconds.

That's it — you'll see today's World Cup match in your menu bar.

---

## Using MenuFC

- **Menu bar** shows the featured match — live score, half-time (HT), full-time (FT), or the next
  kickoff time (in US Eastern). When there are no games, it shows **⚽ No WC matches today**.
- **Click it** to see every World Cup match today, plus:
  - **Refresh** — update right now
  - **Data provided by football-data.org** — the score source
  - **Buy me a coffee ☕** — if you'd like to support the app (totally optional 🙏)

Scores update automatically during games. On days with no matches, MenuFC stays quiet and uses
no internet — it won't drain anything.

---

## Troubleshooting

- **Nothing in the menu bar?** Make sure SwiftBar is running and that `menufc.30s.py` is in the
  plugins folder you chose. In SwiftBar's menu, click **Refresh All**.
- **Says "offline"?** It just means it couldn't reach the internet for a moment — it'll show the last
  scores and recover on its own.
- **Want to remove it?** Delete `menufc.30s.py` from the plugins folder.

No keys, no settings, no accounts. Enjoy the tournament! 🏆
