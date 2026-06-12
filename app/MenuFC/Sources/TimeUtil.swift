import Foundation

// Time helpers.
//
// Display only — the daily slate still comes from the Worker (ET day); localizing the day
// boundary is a separate, larger change. So:
//   • Clock times shown to the user (kickoff, "Updated …") use the DEVICE's local timezone.
//   • `eastern` / `etTodayString` stay US Eastern — they are used ONLY to detect the Worker's
//     ET-day rollover (Poller), never for display.
enum TimeUtil {
    /// US Eastern — used ONLY for Worker ET-day rollover detection, not for display.
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

    /// "YYYY-MM-DD" in US Eastern — matches the Worker's slate day for rollover detection.
    static func etTodayString(_ now: Date = Date()) -> String {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = eastern
        let c = cal.dateComponents([.year, .month, .day], from: now)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    // Display formatter — DEVICE local timezone + device locale (so 12h/24h follows the user).
    // Reconfigured per call from TimeZone.current/Locale.current so a runtime timezone change
    // is picked up on the next render. Display only — see the file note above.
    private static let sharedFormatter = DateFormatter()
    private static func localFormatter() -> DateFormatter {
        let f = sharedFormatter
        f.timeZone = .current
        f.locale = .current
        f.setLocalizedDateFormatFromTemplate("jmm") // hour:minute in the locale's 12h/24h style
        return f
    }

    /// Kickoff time from a UTC ISO string, in the device's local timezone.
    static func timeString(_ utcISO: String?) -> String {
        guard let d = parseUTC(utcISO) else { return "TBD" }
        return localFormatter().string(from: d)
    }

    /// Clock time for an absolute Date (footer "Updated …"), device-local.
    static func clockString(_ date: Date) -> String {
        localFormatter().string(from: date)
    }

    /// Clean short zone name for the footer (e.g. "PDT", "CET", "JST"). Returns nil for
    /// offset-style abbreviations like "GMT+5:30" that don't render cleanly.
    static func localZoneShortName() -> String? {
        guard let abbr = TimeZone.current.abbreviation(), abbr.allSatisfy({ $0.isLetter }) else {
            return nil
        }
        return abbr
    }
}
