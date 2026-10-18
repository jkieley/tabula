import Foundation
import Testing
@testable import TabulaCore

struct ValueClassifierTests {
    @Test(arguments: [
        ("+12.4%", ValueTone.positive, String?.none),
        ("\u{2212}0.6%", .negative, nil),
        ("+0.0%", .neutral, nil),
        ("✅ Passed", .positive, "Passed"),
        ("❌", .negative, ""),
        ("FAIL", .negative, "FAIL"),
        ("modified", .changed, "modified"),
        ("⚠️ Degraded", .warning, "Degraded"),
        ("Passed with warnings", .neutral, nil),
    ])
    func classify(input: String, tone: ValueTone, badge: String?) {
        let result = ValueClassifier.classify(input)
        #expect(result.tone == tone)
        #expect(result.badge?.label == badge)
        if let badge = result.badge { #expect(badge.tone == tone) }
    }

    @Test func parseNumber() {
        #expect(ValueClassifier.parseNumber("1,204")?.value == 1204)
        #expect(ValueClassifier.parseNumber("$1.5")?.value == 1.5)
        #expect(ValueClassifier.parseNumber("12%")?.value == 12)
        #expect(ValueClassifier.parseNumber(".5")?.value == 0.5)
        let minus = ValueClassifier.parseNumber("\u{2212}3")
        #expect(minus?.value == -3)
        #expect(minus?.sign == .minus)
        #expect(ValueClassifier.parseNumber("1,2345") == nil)
        #expect(ValueClassifier.parseNumber("12 ms") == nil)
        #expect(ValueClassifier.parseNumber("1.") == nil)
        #expect(ValueClassifier.parseNumber("-") == nil)
    }

    @Test func parseDate() throws {
        let local = try #require(ValueClassifier.parseDate("2026-10-16T22:15"))
        let offset = try #require(ValueClassifier.parseDate("2026-10-16 22:15:00+02:00"))
        #expect(local.timeIntervalSince(offset) == 7200)
        #expect(ValueClassifier.parseDate("2026-10-16T20:15:00.5Z") != nil)
        #expect(ValueClassifier.parseDate("2026-13-01") == nil)
        #expect(ValueClassifier.parseDate("2026-02-30") == nil)
        #expect(ValueClassifier.parseDate("2026-10-16x") == nil)
    }
}
