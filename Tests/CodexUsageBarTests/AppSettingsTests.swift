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
        settings.menuBarDisplayMode = .weekly
        settings.weeklyFirst = true
        settings.automaticUpdateChecks = false
        settings.notificationsEnabled = true

        XCTAssertEqual(defaults.string(forKey: "codexExecutablePath"), "/Applications/ChatGPT.app")
        XCTAssertEqual(defaults.double(forKey: "refreshInterval"), 60)
        XCTAssertTrue(defaults.bool(forKey: "hasCompletedOnboarding"))
        XCTAssertEqual(defaults.string(forKey: "menuBarDisplayMode"), "weekly")
        XCTAssertTrue(defaults.bool(forKey: "weeklyFirst"))
        XCTAssertFalse(defaults.bool(forKey: "automaticUpdateChecks"))
        XCTAssertTrue(defaults.bool(forKey: "notificationsEnabled"))
        XCTAssertEqual(defaults.dictionaryRepresentation().keys.filter {
            $0 == "codexExecutablePath"
                || $0 == "refreshInterval"
                || $0 == "hasCompletedOnboarding"
                || $0 == "menuBarDisplayMode"
                || $0 == "weeklyFirst"
                || $0 == "automaticUpdateChecks"
                || $0 == "notificationsEnabled"
        }.count, 7)
    }

    func testUnsupportedRefreshIntervalFallsBackToFifteenSeconds() throws {
        let suiteName = "CodexUsageBarTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let settings = AppSettings(defaults: defaults)
        settings.refreshInterval = 3

        XCTAssertEqual(settings.refreshInterval, 15)
    }

    func testAutomaticUpdateChecksDefaultToEnabled() throws {
        let suiteName = "CodexUsageBarTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let settings = AppSettings(defaults: defaults)

        XCTAssertTrue(settings.automaticUpdateChecks)
        XCTAssertFalse(settings.notificationsEnabled)
        XCTAssertEqual(settings.menuBarDisplayMode, .both)
        XCTAssertFalse(settings.weeklyFirst)
    }
}
