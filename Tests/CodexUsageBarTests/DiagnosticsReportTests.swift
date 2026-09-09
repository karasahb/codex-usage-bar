import XCTest
@testable import CodexUsageBar

final class DiagnosticsReportTests: XCTestCase {
    func testReportContainsUsefulStateWithoutSensitiveValues() {
        let secretPath = "/Volumes/PrivateTools/secret/codex"
        let report = DiagnosticsReport.make(
            appVersion: "1.1.0",
            build: "2",
            osVersion: "macOS Test",
            architecture: "arm64",
            localeIdentifier: "tr_TR",
            appLocation: .other,
            codexSource: CodexSourceCategory.detect(configuredPath: secretPath),
            connectionState: "Connected",
            launchAtLogin: "enabled",
            automaticUpdates: true,
            notifications: true,
            notificationAuthorization: .authorized
        )

        XCTAssertTrue(report.contains("App: 1.1.0 (2)"))
        XCTAssertTrue(report.contains("Codex source: Custom executable"))
        XCTAssertFalse(report.contains(secretPath))
        XCTAssertFalse(report.contains("PrivateTools"))
        XCTAssertFalse(report.contains("57%"))
        XCTAssertFalse(report.lowercased().contains("token"))
        XCTAssertFalse(report.lowercased().contains("account id"))
    }
}
