import Foundation

/// Role: Remontoire. Store-only folds. Beat samples today's Open pallet. Mend spends LostBeat on a past empty pallet.
enum RemontoireFold {
    static func beat(
        arbor: Arbor,
        today: PalletKey,
        seated: Bool
    ) -> (arbor: Arbor, outcome: RemontoireOutcome) {
        guard seated else { return (arbor, .hollow) }
        guard !arbor.isHollow else { return (arbor, .hollow) }
        guard let state = arbor.remontoire(on: today) else {
            return (arbor, .refused(.notScheduled))
        }
        guard state == .open else {
            return (arbor, .refused(.alreadyFolded))
        }
        let next = arbor.folding(today, to: .beaten)
        return (next, .beaten(BeatMark(palletKey: today)))
    }

    static func mend(
        arbor: Arbor,
        key: PalletKey,
        today: PalletKey,
        lostBeat: LostBeat,
        seated: Bool
    ) -> (arbor: Arbor, lostBeat: LostBeat, outcome: RemontoireOutcome) {
        guard seated else { return (arbor, lostBeat, .hollow) }
        guard !arbor.isHollow else { return (arbor, lostBeat, .hollow) }
        if key > today {
            return (arbor, lostBeat, .refused(.futurePallet))
        }
        if key == today {
            return (arbor, lostBeat, .refused(.notPast))
        }
        if !lostBeat.remains || arbor.holdsLostMark {
            return (arbor, lostBeat, .refused(.lostBeatSpent))
        }
        guard let state = arbor.remontoire(on: key) else {
            return (arbor, lostBeat, .refused(.notScheduled))
        }
        guard state == .open else {
            return (arbor, lostBeat, .refused(.alreadyFolded))
        }
        let next = arbor.folding(key, to: .mended)
        return (next, .spent, .mended(LostMark(palletKey: key)))
    }

    static func turn(
        seat: Seat?,
        arbor: Arbor,
        lostBeat: LostBeat,
        ended: [Arbor],
        now: Date,
        calendar: Calendar
    ) -> (arbor: Arbor, lostBeat: LostBeat, ended: [Arbor]) {
        let start = PalletKey.weekStart(containing: now, calendar: calendar)
        if arbor.weekStart.rawValue == 0 && arbor.isHollow {
            if let seat {
                return (Arbor.openWeek(seat: seat, containing: now, calendar: calendar), .held, ended)
            }
            return (.hollow, lostBeat, ended)
        }
        guard arbor.weekStart != start else {
            return (arbor, lostBeat, ended)
        }
        var archived = ended
        if !arbor.isHollow || arbor.weekStart.rawValue != 0 {
            archived.append(arbor)
        }
        let next: Arbor
        if let seat {
            next = Arbor.openWeek(seat: seat, containing: now, calendar: calendar)
        } else {
            next = Arbor(weekStart: start, pallets: [:])
        }
        return (next, .held, archived)
    }
}
