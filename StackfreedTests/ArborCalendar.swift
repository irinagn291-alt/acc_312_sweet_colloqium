import XCTest
@testable import Stackfreed

enum ArborCalendar {
    static func make() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.firstWeekday = 2
        return calendar
    }

    static func day(_ year: Int, _ month: Int, _ day: Int, calendar: Calendar = make()) -> Date {
        var parts = DateComponents()
        parts.year = year
        parts.month = month
        parts.day = day
        return calendar.date(from: parts) ?? Date(timeIntervalSince1970: 0)
    }

    static let seat = Seat(name: "Quiet lap", scheduledWeekdays: [2, 3, 4, 5, 6])

    /// Monday 24 Aug 2026 through Friday 28 Aug. Thursday 27 is the live day.
    static func arbor(calendar: Calendar = make(), marking: (PalletKey) -> Remontoire) -> Arbor {
        var arbor = Arbor.openWeek(
            seat: seat,
            containing: day(2026, 8, 27, calendar: calendar),
            calendar: calendar
        )
        for key in arbor.pallets.keys {
            arbor = arbor.folding(key, to: marking(key))
        }
        return arbor
    }
}
