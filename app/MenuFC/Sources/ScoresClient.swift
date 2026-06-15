import Foundation

// Talks ONLY to the MenuFC Cloudflare Worker. No secrets, never football-data.org directly.
struct ScoresClient {
    static let workerBase = "https://menufc-api.rujit.workers.dev"
    private let scoresURL = URL(string: workerBase + "/scores")!
    private let timeout: TimeInterval = 4 // short — a slow network must never hang the UI

    /// Fetch today's scores. force=true appends ?fresh=1 to make the Worker punch through
    /// its idle cache to upstream (server-side rate-limited).
    func fetch(force: Bool) async throws -> ScoresPayload {
        var comps = URLComponents(url: scoresURL, resolvingAgainstBaseURL: false)!
        var items: [URLQueryItem] = []
        if force { items.append(URLQueryItem(name: "fresh", value: "1")) }
        #if DIRECT_BUILD
        // Tag direct (.dmg) installs so the Worker's /stats can split them from App Store users.
        items.append(URLQueryItem(name: "ch", value: "direct"))
        #endif
        if !items.isEmpty { comps.queryItems = items }
        var req = URLRequest(url: comps.url!)
        req.timeoutInterval = timeout
        req.cachePolicy = .reloadIgnoringLocalCacheData
        req.setValue("MenuFC-macOS/1.0", forHTTPHeaderField: "User-Agent")

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(ScoresPayload.self, from: data)
    }
}
