import XCTest
@testable import Stackfreed

final class ArborVaultTests: XCTestCase {
    private var directory: URL!
    private var suiteName: String!
    private var defaults: UserDefaults!
    private let calendar = ArborCalendar.make()

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        suiteName = "skf.test.\(UUID().uuidString)"
        defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDownWithError() throws {
        if let directory {
            try? FileManager.default.removeItem(at: directory)
        }
        if let suiteName {
            defaults?.removePersistentDomain(forName: suiteName)
        }
        directory = nil
        defaults = nil
        suiteName = nil
    }

    func test_roundTrip_reloadPreservesBeatAndLostMark() async throws {
        let vault = makeVault()
        let now = ArborCalendar.day(2026, 8, 27, calendar: calendar)
        var snapshot = ArborSeed.snapshot(now: now, calendar: calendar)
        snapshot.arbor = snapshot.arbor.folding(PalletKey(rawValue: 20260824), to: .mended)
        snapshot.lostBeat = .spent
        snapshot.lostMarks.append(LostMark(palletKey: PalletKey(rawValue: 20260824)))
        try await vault.save(snapshot)

        let relaunched = makeVault()
        let loaded = await relaunched.load()
        XCTAssertNil(loaded.warning)
        XCTAssertEqual(loaded.snapshot.seat?.name, "Quiet lap")
        XCTAssertEqual(loaded.snapshot.lostBeat, .spent)
        XCTAssertEqual(loaded.snapshot.arbor.remontoire(on: PalletKey(rawValue: 20260824)), .mended)
        XCTAssertEqual(loaded.snapshot.ended.count, 1)
        XCTAssertTrue(loaded.snapshot.onboardingComplete)
        XCTAssertNotNil(defaults.data(forKey: ArborKey.document))
        XCTAssertTrue(FileManager.default.fileExists(atPath: directory.appendingPathComponent("arbor.json").path))
    }

    func test_corruptFileFallsBackToBackup() async throws {
        let vault = makeVault()
        let snapshot = ArborSeed.snapshot(now: ArborCalendar.day(2026, 8, 27, calendar: calendar), calendar: calendar)
        try await vault.save(snapshot)
        if let good = defaults.data(forKey: ArborKey.document) {
            defaults.set(good, forKey: ArborKey.backup)
        }
        defaults.set(Data("{not-json".utf8), forKey: ArborKey.document)
        try Data("{not-json".utf8).write(to: directory.appendingPathComponent("arbor.json"))

        let loaded = await makeVault().load()
        XCTAssertEqual(loaded.warning, .recoveredFromBackup)
        XCTAssertEqual(loaded.snapshot.seat?.name, snapshot.seat?.name)
    }

    func test_corruptWithoutBackupStartsEmptyWithNoWrites() async throws {
        defaults.set(Data("nope".utf8), forKey: ArborKey.document)
        let loaded = await makeVault().load()
        XCTAssertEqual(loaded.warning, .startedEmpty)
        XCTAssertNil(loaded.snapshot.seat)
        XCTAssertEqual(loaded.snapshot.arbor, .hollow)
        XCTAssertEqual(defaults.data(forKey: ArborKey.document), Data("nope".utf8))
    }

    func test_resetAllDataClearsDocument() async throws {
        let vault = makeVault()
        try await vault.save(ArborSeed.snapshot(now: ArborCalendar.day(2026, 8, 27, calendar: calendar), calendar: calendar))
        try await vault.resetAllData()
        let loaded = await vault.load()
        XCTAssertNil(loaded.snapshot.seat)
        XCTAssertNil(defaults.data(forKey: ArborKey.document))
        XCTAssertFalse(FileManager.default.fileExists(atPath: directory.appendingPathComponent("arbor.json").path))
    }

    func test_seedKeepsBeatEnabledAndAMendablePastPallet() {
        let now = ArborCalendar.day(2026, 8, 27, calendar: calendar)
        let snap = ArborSeed.snapshot(now: now, calendar: calendar)
        let today = PalletKey.from(now, calendar: calendar)
        XCTAssertEqual(snap.arbor.remontoire(on: today), .open)
        XCTAssertEqual(snap.lostBeat, .held)
        XCTAssertTrue(snap.onboardingComplete)
        XCTAssertEqual(snap.ended.count, 1)
        XCTAssertFalse(snap.beatMarks.isEmpty)
        XCTAssertEqual(snap.lostMarks.count, 1)
        let pastOpen = snap.arbor.pallets.filter { $0.key < today && $0.value == .open }
        XCTAssertFalse(pastOpen.isEmpty)
        XCTAssertNotEqual(snap.lostBeat, .spent)
    }

    func test_codecSwitchesOnSchemaVersion() throws {
        let snapshot = RemontoireSnapshot.empty
        let data = try RemontoireCodec.encode(snapshot)
        let decoded = try RemontoireCodec.decode(data)
        XCTAssertEqual(decoded.arbor.weekStart.rawValue, 0)

        XCTAssertThrowsError(try RemontoireCodec.decode(Data("{\"schemaVersion\":99}".utf8))) { error in
            XCTAssertEqual(error as? RemontoireCodec.Failure, .unsupportedSchema(99))
        }
        XCTAssertThrowsError(try RemontoireCodec.decode(Data("[]".utf8))) { error in
            XCTAssertEqual(error as? RemontoireCodec.Failure, .corrupt)
        }
    }

    @MainActor
    func test_storeBeatAndReloadThroughVault() async throws {
        let vault = makeVault()
        let store = RemontoireStore(vault: vault, calendar: calendar)
        let now = ArborCalendar.day(2026, 8, 27, calendar: calendar)
        store.wind(ArborCalendar.seat, now: now)
        XCTAssertEqual(store.beatToday(now: now), .beaten(BeatMark(palletKey: PalletKey(rawValue: 20260827))))
        await store.flush()

        let relaunched = RemontoireStore(vault: makeVault(), calendar: calendar)
        await relaunched.load()
        XCTAssertEqual(relaunched.arbor.remontoire(on: PalletKey(rawValue: 20260827)), .beaten)
        XCTAssertEqual(relaunched.beatMarks, [BeatMark(palletKey: PalletKey(rawValue: 20260827))])
        XCTAssertTrue(relaunched.folded(at: now).pallets.contains { $0.key.rawValue == 20260827 && $0.remontoire == .beaten })
    }

    @MainActor
    func test_storeEmptyPopulatedInvalidBeat() async {
        let store = RemontoireStore(vault: makeVault(), calendar: calendar)
        let now = ArborCalendar.day(2026, 8, 27, calendar: calendar)
        XCTAssertEqual(store.beatToday(now: now), .hollow)
        store.wind(ArborCalendar.seat, now: now)
        XCTAssertEqual(store.beatToday(now: now), .beaten(BeatMark(palletKey: PalletKey(rawValue: 20260827))))
        XCTAssertEqual(store.beatToday(now: now), .refused(.alreadyFolded))
    }

    #if targetEnvironment(simulator)
    @MainActor
    func test_simulatorSeedWritesOnce() async throws {
        let vault = makeVault()
        let store = RemontoireStore(vault: vault, calendar: calendar)
        let now = ArborCalendar.day(2026, 8, 27, calendar: calendar)
        await store.seedDemoIfNeeded(now: now)
        await store.seedDemoIfNeeded(now: now)
        XCTAssertEqual(store.seat?.name, "Quiet lap")
        XCTAssertTrue(store.onboardingComplete)
        XCTAssertTrue(defaults.bool(forKey: ArborKey.demo))
        XCTAssertEqual(store.ended.count, 1)
        XCTAssertTrue(store.folded(at: now).canBeatToday)
    }
    #endif

    private func makeVault() -> ArborVault {
        ArborVault(directory: directory, defaultsSuiteName: suiteName, writeDelayNanoseconds: 0)
    }
}
