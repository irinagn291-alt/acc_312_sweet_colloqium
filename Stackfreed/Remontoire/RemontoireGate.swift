import Foundation

/// Role: Remontoire. Launch-argument fold after onboarding. today, log, and goals are keys, not tabs.
enum RemontoireGate {
    static let flag = "-ReviewScreen"

    enum Leaf: String, Equatable, Sendable {
        case rings
        case dashboard
        case settings
        case lostBeat
        case onboarding
    }

    /// Parsed once, on first consume after onboarding. Tests call `leaf(from:)`.
    private static let liveLeaf: Leaf = leaf(from: ProcessInfo.processInfo.arguments)

    static func consume() -> Leaf { liveLeaf }

    static func leaf(from arguments: [String]) -> Leaf {
        guard let index = arguments.firstIndex(of: flag) else {
            return .rings
        }
        let token = arguments.dropFirst(index + 1).first?.lowercased() ?? Leaf.rings.rawValue
        switch token {
        case "today", "rings":
            return .rings
        case "log", "dashboard", "beatmark":
            return .dashboard
        case "goals", "settings", "arborsettings":
            return .settings
        case "onboarding":
            return .onboarding
        case "lostbeat", "lostbeatpage", "mend":
            return .lostBeat
        default:
            return .rings
        }
    }
}
