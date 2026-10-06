import Foundation

/// Role: Arbor. Simulator-only seat plus an ended week with a LostMark. Device never seeds.
enum ArborSeed {
    static func snapshot(now: Date, calendar: Calendar) -> RemontoireSnapshot {
        let today = PalletKey.from(now, calendar: calendar)
        var weekdays: Set<Int> = [2, 3, 4, 5, 6]
        weekdays.insert(calendar.component(.weekday, from: now))
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: now)) {
            weekdays.insert(calendar.component(.weekday, from: yesterday))
        }
        let seat = Seat(name: "Quiet lap", scheduledWeekdays: weekdays)
        var current = Arbor.openWeek(seat: seat, containing: now, calendar: calendar)
        let pastKeys = current.pallets.keys.filter { $0 < today }.sorted()
        if pastKeys.count >= 2 {
            for key in pastKeys.dropFirst() {
                current = current.folding(key, to: .beaten)
            }
        }
        let priorDate = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        var prior = Arbor.openWeek(seat: seat, containing: priorDate, calendar: calendar)
        let priorKeys = prior.pallets.keys.sorted()
        for (index, key) in priorKeys.enumerated() {
            prior = prior.folding(key, to: index == priorKeys.count - 1 ? .mended : .beaten)
        }
        var beatMarks: [BeatMark] = []
        var lostMarks: [LostMark] = []
        for arbor in [prior, current] {
            for pallet in arbor.ordered {
                switch pallet.remontoire {
                case .beaten:
                    beatMarks.append(BeatMark(palletKey: pallet.key))
                case .mended:
                    lostMarks.append(LostMark(palletKey: pallet.key))
                case .open:
                    break
                }
            }
        }
        return RemontoireSnapshot(
            seat: seat,
            arbor: current,
            lostBeat: .held,
            ended: [prior],
            beatMarks: beatMarks,
            lostMarks: lostMarks,
            onboardingComplete: true
        )
    }
}
