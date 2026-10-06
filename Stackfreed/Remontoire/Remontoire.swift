import Foundation

/// Role: Remontoire. Closed ADT with Open, Beaten, and Mended. A fourth case is a defect.
enum Remontoire: String, Equatable, Sendable, Codable, CaseIterable {
    case open
    case beaten
    case mended

    /// A mended miss still counts toward completed over scheduled.
    var countsAsCompleted: Bool {
        switch self {
        case .beaten, .mended:
            return true
        case .open:
            return false
        }
    }
}

/// Role: Seat. The one primary habit seated in the arbor. Named per remontoire lexicon.
struct Seat: Equatable, Sendable, Codable {
    var name: String
    /// Calendar weekday numbers: 1 Sunday through 7 Saturday.
    var scheduledWeekdays: Set<Int>
}

/// Role: Remontoire. Result of Beat or Mend. Views never keep a parallel bool.
enum RemontoireOutcome: Equatable, Sendable {
    case beaten(BeatMark)
    case mended(LostMark)
    case hollow
    case refused(RemontoireRefusal)
}

enum RemontoireRefusal: Equatable, Sendable {
    case futurePallet
    case lostBeatSpent
    case notScheduled
    case alreadyFolded
    case notPast
}
