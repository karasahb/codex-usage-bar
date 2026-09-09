import XCTest
@testable import CodexUsageBar

@MainActor
final class AppSettingsTests: XCTestCase {
    func testStoresOnlyNonSensitivePreferences() throws {
        let suiteName = "CodexUsageBarTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let settings = AppSettings(defaults: defaults)
        settings.codexExecutablePath = "/Applications/ChatGPT.app"
        settings.refreshInterval = 60

        XCTAssertEqual(defaults.string(forKey: "codexExecutablePath"), "/Applications/ChatGPT.app")
        XCTAssertEqual(defaults.double(forKey: "refreshInterval"), 60)
        XCTAssertEqual(defaults.dictionaryRepresentation().keys.filter {
            $0 == "codexExecutablePath" || $0 == "refreshInterval"
        }.count, 2)
    }

    func testUnsupportedRefreshIntervalFallsBackToFifteenSeconds() throws {
        let suiteName = "CodexUsageBarTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let settings = AppSettings(defaults: defaults)
        settings.refreshInterval = 3

        XCTAssertEqual(settings.refreshInterval, 15)
    }
}
