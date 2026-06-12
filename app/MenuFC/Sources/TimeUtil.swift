import Foundation

// US Eastern day boundary + time formatting, matching client/menufc.30s.py.
enum TimeUtil {
    static let eastern: TimeZone =
        TimeZone(identifier: "America/New_York") ?? TimeZone(secondsFromGMT: -4 * 3600)!

    /// Parse an ISO-8601 UTC string (handles both "…Z" and fractional "…787Z").
    static func parseUTC(_ s: String?) -> Date? {
        guard let s = s, !s.isEmpty else { return nil }
        let f1 = ISO8601DateFormatter()
        f1.formatOptions = [.withInternetDateTime]
        if let d = f1.date(from: s) { return d }
        let f2 = ISO8601DateFormatter()
        f2.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f2.date(from: s)
    }

    /// "YYYY-MM-DD" for the given instant in US Eastern (mirror of et_today()).
    static func etTodayString(_ now: Date = Date()) -> String {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = eastern
        let c = cal.dateComponents([.year, .month, .day], from: now)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.timeZone = eastern
        f.locale = Locale(identifier: "en_US")
        f.dateFormat = "h:mm a" // e.g. "3:00 PM" (no leading zero), matching Python
        return f
    }()

    /// Kickoff time in ET from a UTC ISO string (mirror of fmt_time_et).
    static func timeETString(_ utcISO: String?) -> String {
        guard let d = parseUTC(utcISO) else { return "TBD" }
        return timeFormatter.string(from: d)
    }

    /// "h:mm a" in ET for an absolute Date (footer "Updated …").
    static func clockETString(_ date: Date) -> String {
        timeFormatter.string(from: date)
    }
}
