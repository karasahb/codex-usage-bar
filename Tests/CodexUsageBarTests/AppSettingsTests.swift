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
        settings.hasCompletedOnboarding = true

        XCTAssertEqual(defaults.string(forKey: "codexExecutablePath"), "/Applications/ChatGPT.app")
        XCTAssertEqual(defaults.double(forKey: "refreshInterval"), 60)
        XCTAssertTrue(defaults.bool(forKey: "hasCompletedOnboarding"))
        XCTAssertEqual(defaults.dictionaryRepresentation().keys.filter {
            $0 == "codexExecutablePath"
                || $0 == "refreshInterval"
                || $0 == "hasCompletedOnboarding"
        }.count, 3)
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
