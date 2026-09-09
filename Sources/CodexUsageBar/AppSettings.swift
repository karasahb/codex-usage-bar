import Combine
import Foundation

enum MenuBarDisplayMode: String, CaseIterable, Equatable {
    case both
    case fiveHour
    case weekly
}

@MainActor
final class AppSettings: ObservableObject {
    private enum Key {
        static let codexExecutablePath = "codexExecutablePath"
        static let refreshInterval = "refreshInterval"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let menuBarDisplayMode = "menuBarDisplayMode"
        static let weeklyFirst = "weeklyFirst"
        static let automaticUpdateChecks = "automaticUpdateChecks"
        static let notificationsEnabled = "notificationsEnabled"
    }

    static let allowedRefreshIntervals: [Double] = [15, 30, 60, 120]

    @Published var codexExecutablePath: String {
        didSet {
            defaults.set(codexExecutablePath.trimmingCharacters(in: .whitespacesAndNewlines),
                         forKey: Key.codexExecutablePath)
        }
    }

    @Published var refreshInterval: Double {
        didSet {
            let safeValue = Self.allowedRefreshIntervals.contains(refreshInterval) ? refreshInterval : 15
            if safeValue != refreshInterval {
                refreshInterval = safeValue
                return
            }
            defaults.set(refreshInterval, forKey: Key.refreshInterval)
        }
    }

    @Published var hasCompletedOnboarding: Bool {
        didSet {
            defaults.set(hasCompletedOnboarding, forKey: Key.hasCompletedOnboarding)
        }
    }

    @Published var menuBarDisplayMode: MenuBarDisplayMode {
        didSet {
            defaults.set(menuBarDisplayMode.rawValue, forKey: Key.menuBarDisplayMode)
        }
    }

    @Published var weeklyFirst: Bool {
        didSet {
            defaults.set(weeklyFirst, forKey: Key.weeklyFirst)
        }
    }

    @Published var automaticUpdateChecks: Bool {
        didSet {
            defaults.set(automaticUpdateChecks, forKey: Key.automaticUpdateChecks)
        }
    }

    @Published var notificationsEnabled: Bool {
        didSet {
            defaults.set(notificationsEnabled, forKey: Key.notificationsEnabled)
        }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        codexExecutablePath = defaults.string(forKey: Key.codexExecutablePath) ?? ""

        let savedInterval = defaults.double(forKey: Key.refreshInterval)
        refreshInterval = Self.allowedRefreshIntervals.contains(savedInterval) ? savedInterval : 15
        hasCompletedOnboarding = defaults.bool(forKey: Key.hasCompletedOnboarding)
        menuBarDisplayMode = MenuBarDisplayMode(
            rawValue: defaults.string(forKey: Key.menuBarDisplayMode) ?? ""
        ) ?? .both
        weeklyFirst = defaults.bool(forKey: Key.weeklyFirst)
        automaticUpdateChecks = defaults.object(forKey: Key.automaticUpdateChecks) == nil
            ? true
            : defaults.bool(forKey: Key.automaticUpdateChecks)
        notificationsEnabled = defaults.bool(forKey: Key.notificationsEnabled)
    }

    var normalizedCodexExecutablePath: String? {
        let value = codexExecutablePath.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }

    func useAutomaticCodexLocation() {
        codexExecutablePath = ""
    }
}
