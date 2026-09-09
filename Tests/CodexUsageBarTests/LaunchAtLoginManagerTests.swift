import ServiceManagement
import XCTest
@testable import CodexUsageBar

final class LaunchAtLoginManagerTests: XCTestCase {
    func testMapsServiceStatusesToDisplayState() {
        XCTAssertEqual(LaunchAtLoginState(serviceStatus: .notRegistered), .disabled)
        XCTAssertEqual(LaunchAtLoginState(serviceStatus: .enabled), .enabled)
        XCTAssertEqual(LaunchAtLoginState(serviceStatus: .requiresApproval), .requiresApproval)
        XCTAssertEqual(LaunchAtLoginState(serviceStatus: .notFound), .unavailable)
    }

    func testOnlyRegisteredStatesAppearSelected() {
        XCTAssertFalse(LaunchAtLoginState.disabled.isSelected)
        XCTAssertTrue(LaunchAtLoginState.enabled.isSelected)
        XCTAssertTrue(LaunchAtLoginState.requiresApproval.isSelected)
        XCTAssertFalse(LaunchAtLoginState.unavailable.isSelected)
    }
}
