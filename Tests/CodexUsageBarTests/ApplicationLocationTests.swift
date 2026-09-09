import XCTest
@testable import CodexUsageBar

final class ApplicationLocationTests: XCTestCase {
    func testRecognizesAppInsideApplicationsDirectory() {
        let directories = [URL(fileURLWithPath: "/Applications")]
        let app = URL(fileURLWithPath: "/Applications/Codex Usage Bar.app")

        XCTAssertTrue(
            ApplicationLocation.isInApplicationsDirectory(
                app,
                applicationDirectories: directories
            )
        )
    }

    func testRejectsLookalikeAndDownloadDirectories() {
        let directories = [URL(fileURLWithPath: "/Applications")]

        XCTAssertFalse(
            ApplicationLocation.isInApplicationsDirectory(
                URL(fileURLWithPath: "/Applications Backup/Codex Usage Bar.app"),
                applicationDirectories: directories
            )
        )
        XCTAssertFalse(
            ApplicationLocation.isInApplicationsDirectory(
                URL(fileURLWithPath: "/Downloads/Codex Usage Bar.app"),
                applicationDirectories: directories
            )
        )
    }
}
