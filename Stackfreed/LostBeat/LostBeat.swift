import Foundation

/// Role: LostBeat. One grace per week. Unused drops when the week turns.
enum LostBeat: String, Equatable, Sendable, Codable {
    case held
    case spent

    var remains: Bool { self == .held }
}
