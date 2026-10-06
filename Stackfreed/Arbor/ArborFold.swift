import Foundation

/// Role: Arbor. Timeline fold of pallets for the week. Not a records list.
struct FoldedPallet: Equatable, Sendable {
    var key: PalletKey
    var remontoire: Remontoire?
    var isPast: Bool
    var isToday: Bool
    var isFuture: Bool
}

struct FoldedArbor: Equatable, Sendable {
    var pallets: [FoldedPallet]
    var canBeatToday: Bool
    var mendable: [PalletKey]

    /// Week row for views. Pallet stays the domain name.
    var days: [FoldedPallet] { pallets }
}

enum ArborFold {
    static func fold(
        _ arbor: Arbor,
        today: PalletKey,
        lostBeat: LostBeat,
        calendar: Calendar
    ) -> FoldedArbor {
        guard arbor.weekStart.rawValue != 0, let startDate = arbor.weekStart.date(calendar: calendar) else {
            return foldScheduled(arbor, today: today, lostBeat: lostBeat)
        }
        var nodes: [FoldedPallet] = []
        nodes.reserveCapacity(7)
        var mendable: [PalletKey] = []
        for offset in 0 ..< 7 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: startDate) else { continue }
            let key = PalletKey.from(day, calendar: calendar)
            let remontoire = arbor.remontoire(on: key)
            let node = FoldedPallet(
                key: key,
                remontoire: remontoire,
                isPast: key < today,
                isToday: key == today,
                isFuture: key > today
            )
            nodes.append(node)
            if lostBeat.remains, remontoire == .open, key < today {
                mendable.append(key)
            }
        }
        let canBeat = arbor.remontoire(on: today) == .open
        return FoldedArbor(pallets: nodes, canBeatToday: canBeat, mendable: mendable)
    }

    private static func foldScheduled(
        _ arbor: Arbor,
        today: PalletKey,
        lostBeat: LostBeat
    ) -> FoldedArbor {
        let ordered = arbor.ordered
        var mendable: [PalletKey] = []
        let nodes = ordered.map { pallet in
            if lostBeat.remains, pallet.remontoire == .open, pallet.key < today {
                mendable.append(pallet.key)
            }
            return FoldedPallet(
                key: pallet.key,
                remontoire: pallet.remontoire,
                isPast: pallet.key < today,
                isToday: pallet.key == today,
                isFuture: pallet.key > today
            )
        }
        return FoldedArbor(
            pallets: nodes,
            canBeatToday: arbor.remontoire(on: today) == .open,
            mendable: mendable
        )
    }
}
