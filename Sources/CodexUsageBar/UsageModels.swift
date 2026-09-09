import AppKit
import Foundation

struct RateLimitWindow: Codable, Equatable {
    let usedPercent: Int
    let windowDurationMins: Int64?
    let resetsAt: Int64?

    var remainingPercent: Int {
        min(100, max(0, 100 - usedPercent))
    }

    var resetDate: Date? {
        resetsAt.map { Date(timeIntervalSince1970: TimeInterval($0)) }
    }
}

struct RateLimitSnapshot: Codable, Equatable {
    let primary: RateLimitWindow?
    let secondary: RateLimitWindow?
    let planType: String?
}

struct RateLimitResetCreditsSummary: Codable, Equatable {
    let availableCount: Int
}

struct RateLimitsResponse: Codable, Equatable {
    let rateLimits: RateLimitSnapshot
    let rateLimitsByLimitId: [String: RateLimitSnapshot]?
    let rateLimitResetCredits: RateLimitResetCreditsSummary?

    var codexSnapshot: RateLimitSnapshot {
        rateLimitsByLimitId?["codex"] ?? rateLimits
    }
}

struct UsageDisplaySnapshot: Equatable {
    let fiveHour: RateLimitWindow?
    let weekly: RateLimitWindow?
    let planType: String?
    let resetCreditCount: Int
    let updatedAt: Date

    init(response: RateLimitsResponse, updatedAt: Date = Date()) {
        let limits = response.codexSnapshot
        let windows = [limits.primary, limits.secondary].compactMap { $0 }
        fiveHour = windows.min(by: { Self.duration($0) < Self.duration($1) })
        weekly = windows.max(by: { Self.duration($0) < Self.duration($1) })
        planType = limits.planType
        resetCreditCount = response.rateLimitResetCredits?.availableCount ?? 0
        self.updatedAt = updatedAt
    }

    private static func duration(_ window: RateLimitWindow) -> Int64 {
        window.windowDurationMins ?? .max
    }
}

enum UsageBand: CaseIterable, Equatable {
    case healthy
    case moderate
    case low
    case critical

    init(remainingPercent: Int) {
        switch remainingPercent {
        case 75...: self = .healthy
        case 50..<75: self = .moderate
        case 25..<50: self = .low
        default: self = .critical
        }
    }

    var color: NSColor {
        switch self {
        case .healthy: return .systemGreen
        case .moderate: return .systemYellow
        case .low: return .systemOrange
        case .critical: return .systemRed
        }
    }
}

enum ResetDateFormatter {
    static func string(for date: Date?, relativeTo now: Date = Date()) -> String {
        guard let date else { return "—" }

        let calendar = Calendar.current
        let time = DateFormatter()
        time.locale = Locale(identifier: "tr_TR")
        time.dateFormat = "HH:mm"

        if calendar.isDate(date, inSameDayAs: now) {
            return "Bugün \(time.string(from: date))"
        }
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now),
           calendar.isDate(date, inSameDayAs: tomorrow) {
            return "Yarın \(time.string(from: date))"
        }

        let full = DateFormatter()
        full.locale = Locale(identifier: "tr_TR")
        full.dateFormat = "d MMM, HH:mm"
        return full.string(from: date)
    }

    static func updateTime(_ date: Date?) -> String {
        guard let date else { return "Henüz güncellenmedi" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "HH:mm:ss"
        return "Son güncelleme \(formatter.string(from: date))"
    }
}
