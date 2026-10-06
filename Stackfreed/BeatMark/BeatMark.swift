import Foundation

/// Role: BeatMark. Written when Beat folds today's Open pallet to Beaten.
struct BeatMark: Equatable, Hashable, Sendable, Codable {
    var palletKey: PalletKey
}

/// Role: Ledger. Habit log of BeatMarks plus LostMarks. Local only, no social.
struct Ledger: Equatable, Sendable {
    var beatMarks: [BeatMark]
    var lostMarks: [LostMark]
}
