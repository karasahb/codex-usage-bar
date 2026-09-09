import XCTest
@testable import CodexUsageBar

final class UsageModelsTests: XCTestCase {
    func testRemainingPercentageIsClamped() {
        XCTAssertEqual(RateLimitWindow(usedPercent: 16, windowDurationMins: 300, resetsAt: nil).remainingPercent, 84)
        XCTAssertEqual(RateLimitWindow(usedPercent: 140, windowDurationMins: 300, resetsAt: nil).remainingPercent, 0)
        XCTAssertEqual(RateLimitWindow(usedPercent: -10, windowDurationMins: 300, resetsAt: nil).remainingPercent, 100)
    }

    func testColorBandsUseQuarterBoundaries() {
        XCTAssertEqual(UsageBand(remainingPercent: 100), .healthy)
        XCTAssertEqual(UsageBand(remainingPercent: 75), .healthy)
        XCTAssertEqual(UsageBand(remainingPercent: 74), .moderate)
        XCTAssertEqual(UsageBand(remainingPercent: 50), .moderate)
        XCTAssertEqual(UsageBand(remainingPercent: 49), .low)
        XCTAssertEqual(UsageBand(remainingPercent: 25), .low)
        XCTAssertEqual(UsageBand(remainingPercent: 24), .critical)
        XCTAssertEqual(UsageBand(remainingPercent: 0), .critical)
    }

    func testResponseChoosesCodexBucketAndOrdersWindows() throws {
        let json = #"""
        {
          "rateLimits": {"primary":{"usedPercent":99,"windowDurationMins":300}},
          "rateLimitsByLimitId": {
            "codex": {
              "limitId":"codex",
              "planType":"plus",
              "primary":{"usedPercent":16,"windowDurationMins":300,"resetsAt":1788990286},
              "secondary":{"usedPercent":43,"windowDurationMins":10080,"resetsAt":1789128773}
            }
          },
          "rateLimitResetCredits":{"availableCount":1},
          "unrelatedBackendField":"ignored"
        }
        """#.data(using: .utf8)!

        let response = try JSONDecoder().decode(RateLimitsResponse.self, from: json)
        let display = UsageDisplaySnapshot(response: response, updatedAt: Date(timeIntervalSince1970: 0))

        XCTAssertEqual(display.fiveHour?.remainingPercent, 84)
        XCTAssertEqual(display.weekly?.remainingPercent, 57)
        XCTAssertEqual(display.planType, "plus")
        XCTAssertEqual(display.resetCreditCount, 1)
    }
}
