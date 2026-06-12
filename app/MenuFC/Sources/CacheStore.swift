import Foundation

// Last-known scores persisted to Application Support (inside the sandbox container),
// so the menu bar survives launches and network failures.
struct CacheStore {
    struct Cached: Codable {
        let payload: ScoresPayload
        let fetchedAt: Double // seconds since 1970
    }

    private let fileURL: URL

    init() {
        let base = (try? FileManager.default.url(
            for: .applicationSupportDirectory, in: .userDomainMask,
            appropriateFor: nil, create: true)) ?? FileManager.default.temporaryDirectory
        let dir = base.appendingPathComponent("MenuFC", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent("scores.json")
    }

    func load() -> Cached? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? JSONDecoder().decode(Cached.self, from: data)
    }

    func save(_ cached: Cached) {
        guard let data = try? JSONEncoder().encode(cached) else { return }
        try? data.write(to: fileURL, options: .atomic) // failures must never break the app
    }
}
