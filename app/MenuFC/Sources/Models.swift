import Foundation

// Mirrors the Worker /scores contract (worker/src/index.js). All fields optional so a
// missing/renamed field can never make decoding throw — resilience over strictness.

struct Team: Codable {
    let tla: String?
    let name: String?
    let flag: String?
}

struct ScorePair: Codable {
    let home: Int?
    let away: Int?
}

struct Match: Codable {
    let id: Int?
    let utcDate: String?
    let status: String?
    let state: String?
    let matchday: Int?
    let group: String?
    let home: Team?
    let away: Team?
    let score: ScorePair?
    let halfTime: ScorePair?
}

struct ScoresPayload: Codable {
    let updated: String?
    let date: String?
    let matches: [Match]?
}

extension Match {
    /// Both score sides present (mirror of Python has_score).
    var hasScore: Bool { score?.home != nil && score?.away != nil }
    var stateOrSched: String { state ?? "SCHED" }
    var isLiveState: Bool { state == "LIVE" || state == "HT" }
}
