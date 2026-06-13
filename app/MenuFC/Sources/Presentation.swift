import AppKit

// Pure rendering logic — a faithful port of the Python render functions
// (pick_featured, title_text, menubar_title, match_row, STATE_COLOR).
enum Presentation {
    static let finalStates: Set<String> = ["FT", "PP", "SUSP", "CANC"]

    static func hexColor(_ hex: UInt32) -> NSColor {
        NSColor(srgbRed: CGFloat((hex >> 16) & 0xff) / 255.0,
                green: CGFloat((hex >> 8) & 0xff) / 255.0,
                blue: CGFloat(hex & 0xff) / 255.0,
                alpha: 1.0)
    }

    /// State → menu-bar color. SCHED returns nil → caller uses the default label color.
    static func stateColor(_ state: String?) -> NSColor? {
        switch state {
        case "LIVE": return hexColor(0x34c759) // green — in play
        case "HT": return hexColor(0xff9500)   // amber — half time
        case "FT", "PP", "SUSP", "CANC": return hexColor(0x8e8e93) // gray
        default: return nil // SCHED / unknown → default label color
        }
    }

    /// Featured match for the menu bar: first LIVE/HT, else next SCHED, else most recent final.
    static func pickFeatured(_ matches: [Match]) -> Match? {
        if matches.isEmpty { return nil }
        if let live = matches.first(where: { $0.isLiveState }) { return live }
        let upcoming = matches
            .filter { $0.displayState == "SCHED" }
            .sorted { ($0.utcDate ?? "") < ($1.utcDate ?? "") }
        if let next = upcoming.first { return next }
        let finished = matches
            .filter { finalStates.contains($0.displayState) }
            .sorted { ($0.utcDate ?? "") < ($1.utcDate ?? "") }
        return finished.last
    }

    /// Menu-bar title text (mirror of title_text).
    static func titleText(_ m: Match?) -> String {
        guard let m = m else { return "⚽ No WC matches today" }
        let hf = m.home?.flag ?? "⚽"
        let af = m.away?.flag ?? "⚽"
        let st = m.displayState
        if (st == "LIVE" || st == "HT" || st == "FT"), m.hasScore,
           let h = m.score?.home, let a = m.score?.away {
            return "\(hf) \(h)–\(a) \(af) \(st)"
        }
        if st == "SCHED" {
            return "\(hf) vs \(af) \(TimeUtil.timeString(m.utcDate))"
        }
        return "\(hf) vs \(af) \(st)"
    }

    /// Colored, weighted attributed title for the status item (mirror of menubar_title).
    static func attributedTitle(_ m: Match?) -> NSAttributedString {
        let text = titleText(m)
        let color: NSColor
        if m == nil {
            color = hexColor(0x8e8e93) // "no matches" → gray, like the Python default
        } else {
            color = stateColor(m?.displayState) ?? NSColor.labelColor
        }
        let base = NSFont.menuBarFont(ofSize: 0)
        let font: NSFont = (m?.isLiveState == true)
            ? NSFontManager.shared.convert(base, toHaveTrait: .boldFontMask)
            : base
        return NSAttributedString(string: text, attributes: [.foregroundColor: color, .font: font])
    }

    /// Plain dropdown row string (mirror of match_row) — used as a parity reference;
    /// the SwiftUI dropdown renders a structured version of the same content.
    static func matchRow(_ m: Match) -> String {
        let hf = m.home?.flag ?? "⚽"
        let af = m.away?.flag ?? "⚽"
        let ht = m.home?.tla ?? "TBD"
        let at = m.away?.tla ?? "TBD"
        let st = m.displayState
        let core: String
        if m.hasScore, let h = m.score?.home, let a = m.score?.away {
            core = "\(hf) \(ht) \(h)–\(a) \(at) \(af)"
        } else {
            core = "\(hf) \(ht) v \(at) \(af)"
        }
        let suffix: String
        if st == "SCHED" {
            suffix = TimeUtil.timeString(m.utcDate)
        } else if finalStates.contains(st) && !m.hasScore {
            suffix = "\(st) · score N/A"
        } else {
            suffix = st
        }
        return "\(core)  \(suffix)"
    }
}
