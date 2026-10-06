import Foundation

/// Role: Arbor. Consistency = completed / scheduled. A mended miss still counts.
struct ArborReading: Equatable, Sendable {
    var completed: Int
    var scheduled: Int
    var streak: Int

    var ratio: Double {
        guard scheduled > 0 else { return 0 }
        return Double(completed) / Double(scheduled)
    }
}

/// Role: Arbor. Colour from ended-week consistency. This week does not color until it ends.
enum ArborHue: Equatable, Sendable {
    case sparse
    case steady
    case solid

    static func band(for ratio: Double) -> ArborHue {
        if ratio >= 0.8 { return .solid }
        if ratio >= 0.5 { return .steady }
        return .sparse
    }
}

enum ArborTally {
    static func reading(
        ended: [Arbor],
        current: Arbor,
        now: Date,
        calendar: Calendar
    ) -> ArborReading {
        let today = PalletKey.from(now, calendar: calendar)
        var completed = 0
        var scheduled = 0
        var countable: [(PalletKey, Remontoire)] = []
        for arbor in ended {
            for pallet in arbor.ordered {
                scheduled += 1
                if pallet.remontoire.countsAsCompleted {
                    completed += 1
                }
                countable.append((pallet.key, pallet.remontoire))
            }
        }
        for pallet in current.ordered {
            if pallet.remontoire == .open && pallet.key >= today {
                continue
            }
            scheduled += 1
            if pallet.remontoire.countsAsCompleted {
                completed += 1
            }
            countable.append((pallet.key, pallet.remontoire))
        }
        countable.sort { $0.0 > $1.0 }
        var streak = 0
        for (_, remontoire) in countable {
            if remontoire.countsAsCompleted {
                streak += 1
            } else {
                break
            }
        }
        return ArborReading(completed: completed, scheduled: scheduled, streak: streak)
    }

    /// Colour from ended weeks only. An in-flight week does not tint the rings.
    static func hue(ended: [Arbor]) -> ArborHue {
        var completed = 0
        var scheduled = 0
        for arbor in ended {
            for pallet in arbor.ordered {
                scheduled += 1
                if pallet.remontoire.countsAsCompleted {
                    completed += 1
                }
            }
        }
        guard scheduled > 0 else { return .sparse }
        return ArborHue.band(for: Double(completed) / Double(scheduled))
    }
}
