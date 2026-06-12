import AppKit
import Combine

// The single source of truth for the UI. Holds the current payload, loads/saves cache,
// and exposes derived values (sorted matches, featured match, attributed title).
@MainActor
final class ScoresStore: ObservableObject {
    @Published private(set) var payload: ScoresPayload?
    @Published private(set) var fetchedAt: Date?
    @Published private(set) var offline = false
    /// User's chosen menu-bar match (only honored while that match is still live).
    @Published private(set) var pinnedMatchID: Int?

    private let client = ScoresClient()
    private let cache = CacheStore()
    private let recentStore = RecentStore()
    private var inFlight: Task<Void, Never>?

    /// Finished matches seen over time (most recent first), persisted across days.
    @Published private(set) var recentHistory: [Match] = []

    init() {
        if let c = cache.load() {
            payload = c.payload
            fetchedAt = Date(timeIntervalSince1970: c.fetchedAt)
        }
        recentHistory = recentStore.load()
        mergeFinished(from: payload?.matches ?? []) // fold today's cached finals in on launch
    }

    var matches: [Match] {
        (payload?.matches ?? []).sorted { ($0.utcDate ?? "") < ($1.utcDate ?? "") }
    }

    // Dropdown sections.
    var liveMatches: [Match] { matches.filter { $0.isLiveState } }
    var upcomingMatches: [Match] { matches.filter { $0.state == "SCHED" } }
    /// Last 3 finished matches (across days), most recent first.
    var recentMatches: [Match] {
        Array(recentHistory.prefix(3))
    }

    /// Menu-bar match: a still-live pinned match if the user chose one, else the default
    /// (first LIVE/HT → next SCHED → most recent final).
    var featured: Match? {
        if let pid = pinnedMatchID, let pinned = liveMatches.first(where: { $0.id == pid }) {
            return pinned
        }
        return Presentation.pickFeatured(matches)
    }

    var attributedTitle: NSAttributedString { Presentation.attributedTitle(featured) }

    func isFeatured(_ m: Match) -> Bool {
        guard let id = m.id, let f = featured else { return false }
        return f.id == id
    }

    /// Pin a live match to the menu bar (tapping a live row). Non-live taps are ignored.
    func setFeatured(_ m: Match) {
        guard m.isLiveState else { return }
        pinnedMatchID = (pinnedMatchID == m.id) ? nil : m.id // tap again to unpin
    }

    /// Fold completed matches (state FT) into the persistent recent history, keyed by id
    /// (newer data updates an existing entry, e.g. a late-published score). Capped + saved.
    private func mergeFinished(from matches: [Match]) {
        var byID: [Int: Match] = [:]
        for m in recentHistory { if let id = m.id { byID[id] = m } }
        var changed = false
        for m in matches where m.id != nil && m.state == "FT" {
            let prev = byID[m.id!]
            if prev == nil || prev?.score?.home != m.score?.home || prev?.score?.away != m.score?.away {
                changed = true
            }
            byID[m.id!] = m
        }
        guard changed else { return }
        recentHistory = Array(
            byID.values
                .sorted { ($0.utcDate ?? "") > ($1.utcDate ?? "") }
                .prefix(20)
        )
        recentStore.save(recentHistory)
    }

    /// Fetch from the Worker. force=true => ?fresh=1. On failure, keep last-known + mark offline.
    func refresh(force: Bool) {
        inFlight?.cancel()
        inFlight = Task { [weak self] in
            guard let self else { return }
            do {
                let fresh = try await self.client.fetch(force: force)
                guard !Task.isCancelled else { return }
                let now = Date()
                self.payload = fresh
                self.fetchedAt = now
                self.offline = false
                self.cache.save(.init(payload: fresh, fetchedAt: now.timeIntervalSince1970))
                self.mergeFinished(from: fresh.matches ?? [])
            } catch is CancellationError {
                // superseded by a newer refresh — ignore
            } catch {
                self.offline = true // keep last-known payload
            }
        }
    }
}
