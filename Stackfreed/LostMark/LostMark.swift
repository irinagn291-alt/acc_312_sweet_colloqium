import Foundation

/// Role: LostMark. Written when Mend spends this week's LostBeat on a past empty pallet.
struct LostMark: Equatable, Hashable, Sendable, Codable {
    var palletKey: PalletKey
}
