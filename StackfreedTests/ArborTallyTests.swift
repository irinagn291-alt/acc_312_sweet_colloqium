import XCTest
@testable import Stackfreed

final class ArborTallyTests: XCTestCase {
    private let calendar = ArborCalendar.make()

    func test_familyInvariant_graceSkipCountsTowardStreakAndConsistency() {
        // habit_rings: 1 grace skip per week still counts toward streak.
        // Week-target: current week not penalized.
        // Consistency = completed/scheduled. Color from consistency.
        let prior = priorWeek(friday: .mended)
        let current = ArborCalendar.arbor(calendar: calendar) { key in
            key.rawValue < 20260827 ? .beaten : .open
        }
        let now = ArborCalendar.day(2026, 8, 27, calendar: calendar)
        let reading = ArborTally.reading(
            ended: [prior],
            current: current,
            now: now,
            calendar: calendar
        )
        XCTAssertEqual(reading.completed, 8)
        XCTAssertEqual(reading.scheduled, 8)
        XCTAssertEqual(reading.ratio, 1, accuracy: 0.0001)
        XCTAssertEqual(reading.streak, 8)
        XCTAssertEqual(ArborTally.hue(ended: [prior]), .solid)
        XCTAssertEqual(ArborHue.band(for: reading.ratio), .solid)
    }

    func test_familyInvariant_missWithoutMendZerosStreak() {
        let prior = priorWeek(friday: .open)
        let current = ArborCalendar.arbor(calendar: calendar) { _ in .open }
        let now = ArborCalendar.day(2026, 8, 27, calendar: calendar)
        let reading = ArborTally.reading(
            ended: [prior],
            current: current,
            now: now,
            calendar: calendar
        )
        XCTAssertEqual(reading.streak, 0)
        XCTAssertLessThan(reading.ratio, 1)
    }

    func test_familyInvariant_currentWeekNotPenalized() {
        let current = ArborCalendar.arbor(calendar: calendar) { key in
            key.rawValue <= 20260825 ? .beaten : .open
        }
        let now = ArborCalendar.day(2026, 8, 27, calendar: calendar)
        let reading = ArborTally.reading(
            ended: [],
            current: current,
            now: now,
            calendar: calendar
        )
        XCTAssertEqual(reading.scheduled, 3)
        XCTAssertEqual(reading.completed, 2)
        XCTAssertEqual(reading.ratio, 2.0 / 3.0, accuracy: 0.0001)
        XCTAssertNotEqual(reading.scheduled, 5)
        XCTAssertEqual(ArborHue.band(for: reading.ratio), .steady)
    }

    func test_familyInvariant_colorFromEndedWeeksOnly() {
        var thin = Arbor.openWeek(
            seat: ArborCalendar.seat,
            containing: ArborCalendar.day(2026, 8, 20, calendar: calendar),
            calendar: calendar
        )
        let keys = thin.pallets.keys.sorted()
        if let first = keys.first {
            thin = thin.folding(first, to: .beaten)
        }
        let current = ArborCalendar.arbor(calendar: calendar) { key in
            key.rawValue < 20260827 ? .beaten : .open
        }
        let now = ArborCalendar.day(2026, 8, 27, calendar: calendar)
        let live = ArborTally.reading(
            ended: [thin],
            current: current,
            now: now,
            calendar: calendar
        )
        let currentOnly = ArborTally.reading(
            ended: [],
            current: current,
            now: now,
            calendar: calendar
        )
        XCTAssertEqual(currentOnly.ratio, 1, accuracy: 0.0001)
        XCTAssertEqual(ArborHue.band(for: currentOnly.ratio), .solid)
        XCTAssertLessThan(live.ratio, currentOnly.ratio)
        XCTAssertEqual(ArborTally.hue(ended: [thin]), .sparse)
        XCTAssertNotEqual(ArborTally.hue(ended: [thin]), ArborHue.band(for: currentOnly.ratio))
        XCTAssertEqual(ArborTally.hue(ended: []), .sparse)
        XCTAssertEqual(ArborHue.band(for: 0.2), .sparse)
        XCTAssertEqual(ArborHue.band(for: 0.5), .steady)
        XCTAssertEqual(ArborHue.band(for: 0.8), .solid)
    }

    func test_mendedMissStillCountsTowardCompletedOverScheduled() {
        let prior = priorWeek(friday: .mended)
        let now = ArborCalendar.day(2026, 8, 31, calendar: calendar)
        let reading = ArborTally.reading(
            ended: [prior],
            current: .hollow,
            now: now,
            calendar: calendar
        )
        XCTAssertEqual(reading.completed, 5)
        XCTAssertEqual(reading.scheduled, 5)
        XCTAssertTrue(Remontoire.mended.countsAsCompleted)
        XCTAssertEqual(Remontoire.allCases.count, 3)
    }

    private func priorWeek(friday: Remontoire) -> Arbor {
        var arbor = Arbor.openWeek(
            seat: ArborCalendar.seat,
            containing: ArborCalendar.day(2026, 8, 20, calendar: calendar),
            calendar: calendar
        )
        let keys = arbor.pallets.keys.sorted()
        for (index, key) in keys.enumerated() {
            arbor = arbor.folding(key, to: index == keys.count - 1 ? friday : .beaten)
        }
        return arbor
    }
}
