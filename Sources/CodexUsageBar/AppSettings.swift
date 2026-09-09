import Combine
import Foundation

@MainActor
final class AppSettings: ObservableObject {
    private enum Key {
        static let codexExecutablePath = "codexExecutablePath"
        static let refreshInterval = "refreshInterval"
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

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        codexExecutablePath = defaults.string(forKey: Key.codexExecutablePath) ?? ""

        let savedInterval = defaults.double(forKey: Key.refreshInterval)
        refreshInterval = Self.allowedRefreshIntervals.contains(savedInterval) ? savedInterval : 15
    }

    var normalizedCodexExecutablePath: String? {
        let value = codexExecutablePath.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }

    func useAutomaticCodexLocation() {
        codexExecutablePath = ""
    }
}
