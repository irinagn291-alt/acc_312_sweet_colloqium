import Foundation

/// Role: Arbor. Fold over this week's pallets. Empty arbor writes Hollow.
struct Arbor: Equatable, Sendable {
    var weekStart: PalletKey
    var pallets: [PalletKey: Remontoire]

    static let hollow = Arbor(weekStart: PalletKey(rawValue: 0), pallets: [:])

    var isHollow: Bool { pallets.isEmpty }

    var ordered: [Pallet] {
        pallets.keys.sorted().map { Pallet(key: $0, remontoire: pallets[$0] ?? .open) }
    }

    func remontoire(on key: PalletKey) -> Remontoire? {
        pallets[key]
    }

    func folding(_ key: PalletKey, to remontoire: Remontoire) -> Arbor {
        guard pallets[key] != nil else { return self }
        var next = self
        next.pallets[key] = remontoire
        return next
    }

    var holdsLostMark: Bool {
        pallets.values.contains(.mended)
    }

    static func openWeek(seat: Seat, containing date: Date, calendar: Calendar) -> Arbor {
        let start = PalletKey.weekStart(containing: date, calendar: calendar)
        guard let startDate = start.date(calendar: calendar) else {
            return Arbor(weekStart: start, pallets: [:])
        }
        var pallets: [PalletKey: Remontoire] = [:]
        for offset in 0 ..< 7 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: startDate) else { continue }
            let weekday = calendar.component(.weekday, from: day)
            guard seat.scheduledWeekdays.contains(weekday) else { continue }
            pallets[PalletKey.from(day, calendar: calendar)] = .open
        }
        return Arbor(weekStart: start, pallets: pallets)
    }
}
