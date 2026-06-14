import SwiftUI

// Neutral, easily-changeable competition label (avoids protected sports trademarks).
// Change this single string to re-label the app (e.g. "Live Football", "Football Today").
let competitionTitle = "Today's Matches"

// The popover content: today's matches + footer. Hosted in our own NSPopover by
// StatusItemController (no MenuBarExtra, nothing injected).
struct DropdownView: View {
    @ObservedObject var store: ScoresStore
    var onSettings: () -> Void
    var onQuit: () -> Void
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider().padding(.vertical, 2)
            content
            Divider().padding(.vertical, 2)
            footer
        }
        .padding(.vertical, 4)
        .frame(width: 256)
    }

    private var header: some View {
        HStack {
            Text(competitionTitle).font(.headline)
            Spacer()
            if let d = store.payload?.date {
                Text(prettyDate(d)).font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 14)
    }

    @ViewBuilder private var content: some View {
        if store.matches.isEmpty {
            HStack {
                Spacer()
                Text("⚽ No matches today")
                    .font(.callout).foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.vertical, 12)
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 1) {
                    section("Live", store.liveMatches, selectable: true)
                    section("Upcoming", store.upcomingMatches, selectable: false)
                    section("Recent", store.recentMatches, selectable: false)
                }
                .padding(.vertical, 1)
            }
            .frame(maxHeight: 360)
        }
    }

    @ViewBuilder private func section(_ title: String, _ matches: [Match], selectable: Bool) -> some View {
        if !matches.isEmpty {
            Text(title.uppercased())
                .font(.caption2).fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 14)
                .padding(.top, 4).padding(.bottom, 0)
            ForEach(Array(matches.enumerated()), id: \.offset) { _, m in
                MatchRowView(
                    match: m,
                    isFeatured: store.isFeatured(m),
                    selectable: selectable,
                    onSelect: selectable ? { store.setFeatured(m) } : nil
                )
            }
        }
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 0) {
            updatedLine.padding(.horizontal, 14).padding(.bottom, 2)
            MenuRowButton(title: "Refresh", systemImage: "arrow.clockwise") {
                store.refresh(force: true)
            }
            MenuRowButton(title: "Data provided by football-data.org", systemImage: "link") {
                if let u = URL(string: "https://www.football-data.org") { openURL(u) }
            }
            #if DIRECT_BUILD
            // Shown ONLY in the directly-distributed (non-App-Store) build. The App Store
            // build never compiles this, so Apple's external-payment rules don't apply.
            MenuRowButton(title: "Buy me a coffee ☕", systemImage: "cup.and.saucer") {
                if let u = URL(string: "https://buymeacoffee.com/rujitraval") { openURL(u) }
            }
            #endif
            Divider().padding(.vertical, 2)
            MenuRowButton(title: "Settings…", systemImage: "gearshape", action: onSettings)
            MenuRowButton(title: "Quit MenuFC", systemImage: "power", action: onQuit)
        }
    }

    @ViewBuilder private var updatedLine: some View {
        if let f = store.fetchedAt {
            Text(updatedText(f)).font(.caption2).foregroundStyle(.secondary)
        } else if store.offline {
            Text("Offline — no data yet").font(.caption2).foregroundStyle(.secondary)
        } else {
            Text("Updating…").font(.caption2).foregroundStyle(.secondary)
        }
    }

    // Footer text: local clock time + clean local zone abbrev (e.g. "Updated 2:14 PM PT").
    // Display only — the slate day still comes from the Worker (ET).
    private func updatedText(_ f: Date) -> String {
        let zone = TimeUtil.localZoneShortName().map { " \($0)" } ?? ""
        let offline = store.offline ? " · offline (last known)" : ""
        return "Updated \(TimeUtil.clockString(f))\(zone)\(offline)"
    }

    private func prettyDate(_ ymd: String) -> String {
        let inF = DateFormatter()
        inF.dateFormat = "yyyy-MM-dd"
        inF.timeZone = TimeUtil.eastern
        guard let d = inF.date(from: ymd) else { return ymd }
        let outF = DateFormatter()
        outF.dateFormat = "EEE, MMM d"
        outF.timeZone = TimeUtil.eastern
        return outF.string(from: d)
    }
}

// One match row: a "shown in menu bar" dot, flags + TLAs + colored score/time + state badge.
// Live rows are bolded and tappable to pin them to the menu bar.
struct MatchRowView: View {
    let match: Match
    var isFeatured: Bool = false
    var selectable: Bool = false
    var onSelect: (() -> Void)? = nil
    @State private var hovering = false

    var body: some View {
        if selectable, let onSelect {
            Button(action: onSelect) { rowContent }
                .buttonStyle(.plain)
                .onHover { hovering = $0 }
                .help(isFeatured ? "Shown in the menu bar — tap to unpin" : "Show this match in the menu bar")
        } else {
            rowContent
                .help(isFeatured ? "Shown in the menu bar" : "")
        }
    }

    private var rowContent: some View {
        HStack(spacing: 5) {
            // "shown in the menu bar" indicator slot (keeps all rows aligned).
            ZStack {
                if isFeatured {
                    Circle().fill(Color.accentColor).frame(width: 6, height: 6)
                }
            }
            .frame(width: 8)
            // Matchup grouped tightly together (fixed columns keep scores aligned).
            Text(match.home?.flag ?? "⚽")
            Text(match.home?.tla ?? "TBD")
                .fontWeight(.medium)
                .frame(width: 32, alignment: .leading)
            Text(centerText)
                .monospacedDigit()
                .fontWeight(match.isLiveState ? .bold : .regular)
                .foregroundStyle(centerColor)
                .frame(width: 30)
            Text(match.away?.tla ?? "TBD")
                .fontWeight(.medium)
                .frame(width: 32, alignment: .trailing)
            Text(match.away?.flag ?? "⚽")
            Spacer(minLength: 6)
            Text(badgeText)
                .font(.caption)
                .foregroundStyle(badgeColor)
                .lineLimit(1)
                .fixedSize()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .background((hovering && selectable) ? Color.accentColor.opacity(0.15) : Color.clear)
    }

    private var centerText: String {
        if match.hasScore, let h = match.score?.home, let a = match.score?.away {
            return "\(h)–\(a)"
        }
        return "v"
    }

    private var centerColor: Color {
        if let c = Presentation.stateColor(match.displayState) { return Color(nsColor: c) }
        return .primary
    }

    private var badgeText: String {
        let st = match.displayState
        if st == "SCHED" { return TimeUtil.timeString(match.utcDate) }
        if Presentation.finalStates.contains(st) && !match.hasScore { return "\(st) · N/A" }
        return st
    }

    private var badgeColor: Color {
        let st = match.displayState
        if st == "SCHED" { return .secondary }
        if let c = Presentation.stateColor(st) { return Color(nsColor: c) }
        return .secondary
    }
}

// A menu-style row button with hover highlight (native feel inside our custom popover).
struct MenuRowButton: View {
    let title: String
    var systemImage: String? = nil
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let s = systemImage {
                    Image(systemName: s).frame(width: 16)
                }
                Text(title)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 3)
            .contentShape(Rectangle())
            .background(hovering ? Color.accentColor.opacity(0.18) : Color.clear)
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}
