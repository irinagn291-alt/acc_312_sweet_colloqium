import Foundation

/// Role: Arbor. In-process vault for fixtures. Views never persist through this.
actor ArborMemory: ArborPersisting {
    private var snapshot: RemontoireSnapshot
    private var demo = false

    init(snapshot: RemontoireSnapshot = .empty) {
        self.snapshot = snapshot
    }

    func load() async -> (snapshot: RemontoireSnapshot, warning: ArborWarning?) {
        (snapshot, nil)
    }

    func note(_ snapshot: RemontoireSnapshot) async {
        self.snapshot = snapshot
    }

    func save(_ snapshot: RemontoireSnapshot) async throws {
        self.snapshot = snapshot
    }

    func flush() async throws {}

    func resetAllData() async throws {
        snapshot = .empty
    }

    func hasDemoSeed() async -> Bool {
        demo
    }

    func markDemoSeed() async {
        demo = true
    }
}
