import XCTest
@testable import CodexUsageBar

final class UpdateCheckerTests: XCTestCase {
    func testSemanticVersionComparison() throws {
        XCTAssertLessThan(try XCTUnwrap(AppVersion("1.0.9")), try XCTUnwrap(AppVersion("1.1.0")))
        XCTAssertLessThan(try XCTUnwrap(AppVersion("v1.1.0")), try XCTUnwrap(AppVersion("2.0")))
        XCTAssertEqual(AppVersion("1.1"), AppVersion("1.1.0"))
    }

    func testRejectsInvalidVersions() {
        XCTAssertNil(AppVersion("release"))
        XCTAssertNil(AppVersion("1.x.0"))
    }
}
