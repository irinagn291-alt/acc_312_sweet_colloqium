import Foundation
import SwiftUI

/// Role: Remontoire. Locale figures with tabular digits. Views never interpolate counts.
enum RemontoireFigure {
    static func whole(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }

    static func dayKey(_ key: PalletKey) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        formatter.usesGroupingSeparator = false
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: key.rawValue)) ?? "0"
    }

    static func ratio(completed: Int, scheduled: Int) -> String {
        whole(completed) + " of " + whole(scheduled)
    }

    static func streak(_ value: Int) -> String {
        "Streak " + whole(value)
    }

    static func weekdayLetter(_ key: PalletKey, calendar: Calendar = .current) -> String {
        guard let date = key.date(calendar: calendar) else {
            return dayKey(key)
        }
        let index = calendar.component(.weekday, from: date) - 1
        let symbols = calendar.veryShortWeekdaySymbols
        guard symbols.indices.contains(index) else {
            return dayKey(key)
        }
        return symbols[index]
    }

    static func weekdayName(_ key: PalletKey, calendar: Calendar = .current) -> String {
        guard let date = key.date(calendar: calendar) else {
            return dayKey(key)
        }
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = calendar.locale
        formatter.setLocalizedDateFormatFromTemplate("EEEEdMMMM")
        return formatter.string(from: date)
    }

    static func relativeDay(_ key: PalletKey, now: Date = Date(), calendar: Calendar = .current) -> String {
        guard let date = key.date(calendar: calendar) else {
            return weekdayName(key, calendar: calendar)
        }
        if calendar.isDateInToday(date) {
            return "Today"
        }
        if calendar.isDateInYesterday(date) {
            return "Yesterday"
        }
        return weekdayName(key, calendar: calendar)
    }

    static func markWord(closed: Bool) -> String {
        closed ? "Closed" : "Mended"
    }
}

enum RemontoireMotion {
    static let fade = Animation.easeInOut(duration: 0.28)
    static let reduce = Animation.easeInOut(duration: 0.2)
    static let press = Animation.easeInOut(duration: 0.2)
    static let step: Double = 0.04
    static let reveal: Double = 0.12

    static func stagger(index: Int, reduceMotion: Bool) -> Animation {
        if reduceMotion {
            return reduce
        }
        let delay = min(Double(index) * step, 0.36 - reveal)
        return Animation.easeInOut(duration: reveal).delay(delay)
    }
}

/// Role: Remontoire. Warm user copy. Pallet and Seat stay in types and files.
enum RemontoireVoice {
    static let noHabit = "No habit yet."
    static let closeFirst = "Close the first ring."
    static let jobCloseToday = "Tap Close to close today's ring."
    static let jobRest = "Today is rest. A silent day can take this week's lost beat."
    static let jobMendPast = "Today is closed. Tap a silent past day to mend it."
    static let jobHoldsBeat = "Today is closed. This week still holds a lost beat."
    static let jobSpent = "Today is closed. This week's lost beat is spent."
    static let lostHeld = "Tap a silent past day. Future days refuse."
    static let lostSpent = "A second mend this week is refused."
    static let onboardingMend = "Tap a silent past day to spend this week's lost beat. Tomorrow cannot take it."
    static let nameHabitFirst = "Name a habit first. Then a silent day can take this week's lost beat."
    static let twistHow = "Tap an empty past day. Future days refuse. A second mend this week is refused."
    static let noSilentDay = "No silent scheduled day yet. Miss one, then tap that day."
    static let todayAlreadyClosed = "Today is already closed."
    static let todayIsRest = "Today is rest. There is no ring to close."
    static let futureClosed = "Future days stay closed until they arrive."
    static let weekSpentBeat = "This week already spent its lost beat."
    static let thatDayRest = "That day is rest. Mend a scheduled silent day."
    static let thatDayClosed = "That day is already closed."
    static let mendForSlipped = "Close today with Close. Mend is for a day that slipped."

    static func committed(_ outcome: RemontoireOutcome) -> Bool {
        switch outcome {
        case .beaten, .mended:
            return true
        case .hollow, .refused:
            return false
        }
    }

    static func afterBeat(_ outcome: RemontoireOutcome) -> String? {
        switch outcome {
        case .beaten, .mended:
            return nil
        case .hollow:
            return noHabit
        case .refused(.alreadyFolded):
            return todayAlreadyClosed
        case .refused(.notScheduled):
            return todayIsRest
        case .refused:
            return nil
        }
    }

    static func afterMend(_ outcome: RemontoireOutcome) -> String? {
        switch outcome {
        case .beaten, .mended:
            return nil
        case .hollow:
            return noHabit
        case .refused(.futurePallet):
            return futureClosed
        case .refused(.lostBeatSpent):
            return weekSpentBeat
        case .refused(.notScheduled):
            return thatDayRest
        case .refused(.alreadyFolded):
            return thatDayClosed
        case .refused(.notPast):
            return mendForSlipped
        }
    }

    static var userFacing: [String] {
        [
            noHabit,
            closeFirst,
            jobCloseToday,
            jobRest,
            jobMendPast,
            jobHoldsBeat,
            jobSpent,
            lostHeld,
            lostSpent,
            onboardingMend,
            nameHabitFirst,
            twistHow,
            noSilentDay,
            todayAlreadyClosed,
            todayIsRest,
            futureClosed,
            weekSpentBeat,
            thatDayRest,
            thatDayClosed,
            mendForSlipped,
        ]
    }
}

enum ArborDraft {
    static let name = "Daily lap"

    static func weekdays(now: Date = Date(), calendar: Calendar = .current) -> Set<Int> {
        var days: Set<Int> = [2, 3, 4, 5, 6]
        days.insert(calendar.component(.weekday, from: now))
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: now)) {
            days.insert(calendar.component(.weekday, from: yesterday))
        }
        return days
    }

    static func seat(name: String = name, now: Date = Date(), calendar: Calendar = .current) -> Seat {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return Seat(
            name: trimmed.isEmpty ? Self.name : trimmed,
            scheduledWeekdays: weekdays(now: now, calendar: calendar)
        )
    }

    static func named(_ name: String = name, now: Date = Date(), calendar: Calendar = .current) -> Seat {
        seat(name: name, now: now, calendar: calendar)
    }
}
