import Foundation

/// Role: Arbor. Versioned UserDefaults keys. Views never touch these.
enum ArborKey {
    static let document = "skf.arbor.v1"
    static let backup = "skf.arbor.v1.backup"
    static let demo = "skf.demo.v1"
}

enum ArborWarning: Equatable, Sendable {
    case recoveredFromBackup
    case startedEmpty
}

protocol ArborPersisting: Sendable {
    func load() async -> (snapshot: RemontoireSnapshot, warning: ArborWarning?)
    func note(_ snapshot: RemontoireSnapshot) async
    func save(_ snapshot: RemontoireSnapshot) async throws
    func flush() async throws
    func resetAllData() async throws
    func hasDemoSeed() async -> Bool
    func markDemoSeed() async
}

/// Role: Arbor. One seam. Memory on RemontoireStore is the source of truth; UserDefaults is the projection.
actor ArborVault: ArborPersisting {
    private let directory: URL
    private let defaultsSuiteName: String?
    private let fileManager: FileManager
    private let writeDelayNanoseconds: UInt64

    private var latest: RemontoireSnapshot?
    private var writeTask: Task<Void, Never>?
    private(set) var lastWriteError: String?

    init(
        directory: URL,
        defaultsSuiteName: String? = nil,
        fileManager: FileManager = .default,
        writeDelayNanoseconds: UInt64 = 300_000_000
    ) {
        self.directory = directory
        self.defaultsSuiteName = defaultsSuiteName
        self.fileManager = fileManager
        self.writeDelayNanoseconds = writeDelayNanoseconds
    }

    static func applicationSupportDirectory(fileManager: FileManager = .default) throws -> URL {
        let root = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return root.appendingPathComponent("Sweet Colloqium", isDirectory: true)
    }

    func load() async -> (snapshot: RemontoireSnapshot, warning: ArborWarning?) {
        prepareDirectory()
        if let snapshot = decode(defaults().data(forKey: ArborKey.document)) {
            latest = snapshot
            return (snapshot, nil)
        }
        if let snapshot = decodeFile(fileURL()) {
            latest = snapshot
            return (snapshot, nil)
        }
        if let snapshot = decode(defaults().data(forKey: ArborKey.backup)) {
            latest = snapshot
            return (snapshot, .recoveredFromBackup)
        }
        if let snapshot = decodeFile(backupURL()) {
            latest = snapshot
            return (snapshot, .recoveredFromBackup)
        }
        if hasAnyPayload() {
            latest = .empty
            return (.empty, .startedEmpty)
        }
        latest = .empty
        return (.empty, nil)
    }

    func note(_ snapshot: RemontoireSnapshot) async {
        latest = snapshot
        scheduleFlush()
    }

    func save(_ snapshot: RemontoireSnapshot) async throws {
        writeTask?.cancel()
        writeTask = nil
        latest = snapshot
        try persist(snapshot)
    }

    func flush() async throws {
        writeTask?.cancel()
        writeTask = nil
        if let latest {
            try persist(latest)
        }
    }

    func resetAllData() async throws {
        writeTask?.cancel()
        writeTask = nil
        latest = .empty
        lastWriteError = nil
        let defaults = defaults()
        defaults.removeObject(forKey: ArborKey.document)
        defaults.removeObject(forKey: ArborKey.backup)
        defaults.synchronize()
        if fileManager.fileExists(atPath: fileURL().path) {
            try fileManager.removeItem(at: fileURL())
        }
        if fileManager.fileExists(atPath: backupURL().path) {
            try fileManager.removeItem(at: backupURL())
        }
    }

    func hasDemoSeed() async -> Bool {
        defaults().object(forKey: ArborKey.demo) != nil
    }

    func markDemoSeed() async {
        defaults().set(true, forKey: ArborKey.demo)
        defaults().synchronize()
    }

    private func scheduleFlush() {
        writeTask?.cancel()
        let delay = writeDelayNanoseconds
        writeTask = Task { [weak self] in
            if delay > 0 {
                try? await Task.sleep(nanoseconds: delay)
            }
            guard !Task.isCancelled else { return }
            await self?.flushIfNeeded()
        }
    }

    private func flushIfNeeded() async {
        writeTask = nil
        do {
            if let latest {
                try persist(latest)
            }
        } catch {
            lastWriteError = String(describing: error)
        }
    }

    private func persist(_ snapshot: RemontoireSnapshot) throws {
        prepareDirectory()
        let data = try RemontoireCodec.encode(snapshot)
        let defaults = defaults()
        if let previous = defaults.data(forKey: ArborKey.document) {
            defaults.set(previous, forKey: ArborKey.backup)
        }
        if fileManager.fileExists(atPath: fileURL().path) {
            try? fileManager.removeItem(at: backupURL())
            try? fileManager.copyItem(at: fileURL(), to: backupURL())
        }
        try data.write(to: fileURL(), options: .atomic)
        defaults.set(data, forKey: ArborKey.document)
        defaults.synchronize()
        lastWriteError = nil
    }

    private func decode(_ data: Data?) -> RemontoireSnapshot? {
        guard let data else { return nil }
        return try? RemontoireCodec.decode(data)
    }

    private func decodeFile(_ url: URL) -> RemontoireSnapshot? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? RemontoireCodec.decode(data)
    }

    private func hasAnyPayload() -> Bool {
        defaults().data(forKey: ArborKey.document) != nil
            || defaults().data(forKey: ArborKey.backup) != nil
            || fileManager.fileExists(atPath: fileURL().path)
            || fileManager.fileExists(atPath: backupURL().path)
    }

    private func fileURL() -> URL {
        directory.appendingPathComponent("arbor.json")
    }

    private func backupURL() -> URL {
        directory.appendingPathComponent("arbor.json.backup")
    }

    private func defaults() -> UserDefaults {
        if let defaultsSuiteName {
            return UserDefaults(suiteName: defaultsSuiteName) ?? .standard
        }
        return .standard
    }

    private func prepareDirectory() {
        if !fileManager.fileExists(atPath: directory.path) {
            try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
    }
}
