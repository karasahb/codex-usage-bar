import XCTest
@testable import CodexUsageBar

final class UsageNotificationTests: XCTestCase {
    func testNotifiesOnlyWhenCrossingBelowTwentyFivePercent() {
        XCTAssertTrue(UsageThresholdCrossing.crossed(previous: 25, current: 24))
        XCTAssertTrue(UsageThresholdCrossing.crossed(previous: 80, current: 10))
        XCTAssertFalse(UsageThresholdCrossing.crossed(previous: 24, current: 20))
        XCTAssertFalse(UsageThresholdCrossing.crossed(previous: 26, current: 25))
        XCTAssertFalse(UsageThresholdCrossing.crossed(previous: nil, current: 20))
        XCTAssertFalse(UsageThresholdCrossing.crossed(previous: 30, current: nil))
    }
}
