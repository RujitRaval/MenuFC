import AppKit

// Persistent-app version of the Python smart-poll:
//  - inside a live window (5 min before kickoff → 150 min after, or any LIVE/HT): poll ~25s
//  - idle / same day: don't poll, except a slow ~hourly refresh to catch the ET day rollover
//  - refresh on launch and on wake from sleep
@MainActor
final class Poller {
    private let store: ScoresStore
    private var timer: Timer?
    private var wakeObserver: NSObjectProtocol?

    private let tick: TimeInterval = 15
    private let liveRefresh: TimeInterval = 25
    private let idleRefresh: TimeInterval = 3600
    private let preKick: TimeInterval = 5 * 60
    private let postMatch: TimeInterval = 150 * 60

    init(store: ScoresStore) { self.store = store }

    func start() {
        evaluate(initial: true) // load-then-refresh on launch

        let t = Timer(timeInterval: tick, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.evaluate() }
        }
        t.tolerance = 5 // battery-friendly
        RunLoop.main.add(t, forMode: .common)
        timer = t

        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.store.refresh(force: false) }
        }
    }

    func refreshNow(force: Bool) { store.refresh(force: force) }

    private func evaluate(initial: Bool = false) {
        let now = Date()
        let today = TimeUtil.etTodayString(now)
        var need = initial
        if !need {
            if store.payload == nil || store.payload?.date != today {
                need = true // no cache, or ET day rolled over → fetch today's slate
            } else if inLiveWindow(store.matches, now) {
                if age(now) >= liveRefresh { need = true }
            } else if age(now) >= idleRefresh {
                need = true // slow hourly refresh to catch rollover
            }
        }
        if need { store.refresh(force: false) }
    }

    private func age(_ now: Date) -> TimeInterval {
        guard let f = store.fetchedAt else { return .infinity }
        return now.timeIntervalSince(f)
    }

    private func inLiveWindow(_ matches: [Match], _ now: Date) -> Bool {
        for m in matches {
            if m.isLiveState { return true }
            if let ko = TimeUtil.parseUTC(m.utcDate),
               now >= ko.addingTimeInterval(-preKick),
               now <= ko.addingTimeInterval(postMatch) {
                return true
            }
        }
        return false
    }
}
