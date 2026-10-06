import Foundation

/// Role: Pallet. Day identity as Int YYYYMMDD from Calendar.startOfDay. Never a Date dictionary key.
struct PalletKey: RawRepresentable, Hashable, Sendable, Codable, Comparable {
    let rawValue: Int

    init(rawValue: Int) {
        self.rawValue = rawValue
    }

    static func from(_ date: Date, calendar: Calendar) -> PalletKey {
        let start = calendar.startOfDay(for: date)
        let parts = calendar.dateComponents([.year, .month, .day], from: start)
        let year = parts.year ?? 1970
        let month = parts.month ?? 1
        let day = parts.day ?? 1
        return PalletKey(rawValue: year * 10_000 + month * 100 + day)
    }

    func date(calendar: Calendar) -> Date? {
        var parts = DateComponents()
        parts.year = rawValue / 10_000
        parts.month = (rawValue / 100) % 100
        parts.day = rawValue % 100
        guard let built = calendar.date(from: parts) else { return nil }
        return calendar.startOfDay(for: built)
    }

    static func weekStart(containing date: Date, calendar: Calendar) -> PalletKey {
        let start = calendar.startOfDay(for: date)
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: start) else {
            return PalletKey.from(start, calendar: calendar)
        }
        return PalletKey.from(interval.start, calendar: calendar)
    }

    static func < (lhs: PalletKey, rhs: PalletKey) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// Role: Pallet. One scheduled day whose remontoire is Open, Beaten, or Mended.
struct Pallet: Equatable, Sendable, Identifiable {
    var key: PalletKey
    var remontoire: Remontoire

    var id: Int { key.rawValue }
}
