import Foundation
import Observation

/// Role: Remontoire. One observable store owns every fold. Views call beatToday and mendPallet.
@MainActor
@Observable
final class RemontoireStore {
    private(set) var seat: Seat?
    private(set) var arbor: Arbor
    private(set) var lostBeat: LostBeat
    private(set) var ended: [Arbor]
    private(set) var beatMarks: [BeatMark]
    private(set) var lostMarks: [LostMark]
    private(set) var warning: ArborWarning?
    private(set) var onboardingComplete: Bool
    private(set) var lastWriteError: String?

    private let vault: any ArborPersisting
    private let calendar: Calendar

    init(vault: any ArborPersisting, calendar: Calendar = .current) {
        self.vault = vault
        self.calendar = calendar
        self.arbor = .hollow
        self.lostBeat = .held
        self.ended = []
        self.beatMarks = []
        self.lostMarks = []
        self.onboardingComplete = false
    }

    var ledger: Ledger {
        Ledger(beatMarks: beatMarks, lostMarks: lostMarks)
    }

    func folded(at now: Date = Date()) -> FoldedArbor {
        let today = PalletKey.from(now, calendar: calendar)
        return ArborFold.fold(arbor, today: today, lostBeat: lostBeat, calendar: calendar)
    }

    func reading(at now: Date = Date()) -> ArborReading {
        ArborTally.reading(ended: ended, current: arbor, now: now, calendar: calendar)
    }

    func hue() -> ArborHue {
        ArborTally.hue(ended: ended)
    }

    var canBeatToday: Bool {
        folded().canBeatToday
    }

    var hasHabit: Bool {
        seat != nil
    }

    var habitName: String {
        seat?.name ?? ArborDraft.name
    }

    var habitWeekdays: Set<Int> {
        seat?.scheduledWeekdays ?? ArborDraft.weekdays(now: Date(), calendar: calendar)
    }

    static func live() -> RemontoireStore {
        let directory: URL
        if let created = try? ArborVault.applicationSupportDirectory() {
            directory = created
        } else {
            directory = FileManager.default.temporaryDirectory.appendingPathComponent("Sweet Colloqium", isDirectory: true)
        }
        return RemontoireStore(vault: ArborVault(directory: directory))
    }

    func load() async {
        let loaded = await vault.load()
        apply(loaded.snapshot)
        warning = loaded.warning
        lastWriteError = nil
    }

    func settle(now: Date = Date()) {
        let before = arbor.weekStart
        applyTurn(now: now)
        if arbor.weekStart != before {
            persistSoon()
        }
    }

    func reopenOnboarding() {
        onboardingComplete = false
        persistSoon()
    }

    func reviseSeat(_ next: Seat, now: Date = Date()) {
        applyTurn(now: now)
        let kept = arbor.pallets
        seat = next
        var rebuilt = Arbor.openWeek(seat: next, containing: now, calendar: calendar)
        for (key, remontoire) in kept where rebuilt.pallets[key] != nil {
            rebuilt.pallets[key] = remontoire
        }
        arbor = rebuilt
        persistSoon()
    }

    func renameHabit(_ name: String, now: Date = Date()) {
        saveHabit(name: name, weekdays: habitWeekdays, now: now)
    }

    func saveHabit(name: String, weekdays: Set<Int>, now: Date = Date()) {
        let next = Seat(
            name: ArborDraft.named(name).name,
            scheduledWeekdays: weekdays
        )
        if seat == nil {
            wind(next, now: now)
        } else {
            reviseSeat(next, now: now)
        }
    }

    func install(_ snapshot: RemontoireSnapshot) {
        apply(snapshot)
        warning = nil
        lastWriteError = nil
    }

    func wind(_ next: Seat, now: Date = Date()) {
        seat = next
        arbor = Arbor.openWeek(seat: next, containing: now, calendar: calendar)
        lostBeat = .held
        persistSoon()
    }

    @discardableResult
    func beatToday(now: Date = Date()) -> RemontoireOutcome {
        applyTurn(now: now)
        let today = PalletKey.from(now, calendar: calendar)
        let folded = RemontoireFold.beat(arbor: arbor, today: today, seated: seat != nil)
        arbor = folded.arbor
        if case .beaten(let mark) = folded.outcome {
            beatMarks.append(mark)
            persistSoon()
        }
        return folded.outcome
    }

    @discardableResult
    func mendPallet(_ key: PalletKey, now: Date = Date()) -> RemontoireOutcome {
        applyTurn(now: now)
        let today = PalletKey.from(now, calendar: calendar)
        let folded = RemontoireFold.mend(
            arbor: arbor,
            key: key,
            today: today,
            lostBeat: lostBeat,
            seated: seat != nil
        )
        arbor = folded.arbor
        lostBeat = folded.lostBeat
        if case .mended(let mark) = folded.outcome {
            lostMarks.append(mark)
            persistSoon()
        }
        return folded.outcome
    }

    func markOnboardingComplete() {
        onboardingComplete = true
        persistSoon()
    }

    func flush() async {
        do {
            try await vault.save(snapshot)
        } catch {
            lastWriteError = String(describing: error)
        }
    }

    func resetAllData() async {
        do {
            try await vault.resetAllData()
        } catch {
            lastWriteError = String(describing: error)
        }
        apply(.empty)
        warning = nil
    }

    func seedDemoIfNeeded(now: Date = Date()) async {
        #if targetEnvironment(simulator)
        if await vault.hasDemoSeed(), onboardingComplete, hasHabit { return }
        apply(ArborSeed.snapshot(now: now, calendar: calendar))
        do {
            try await vault.save(snapshot)
            await vault.markDemoSeed()
        } catch {
            lastWriteError = String(describing: error)
        }
        #endif
    }

    private var snapshot: RemontoireSnapshot {
        RemontoireSnapshot(
            seat: seat,
            arbor: arbor,
            lostBeat: lostBeat,
            ended: ended,
            beatMarks: beatMarks,
            lostMarks: lostMarks,
            onboardingComplete: onboardingComplete
        )
    }

    private func apply(_ snapshot: RemontoireSnapshot) {
        seat = snapshot.seat
        arbor = snapshot.arbor
        lostBeat = snapshot.lostBeat
        ended = snapshot.ended
        beatMarks = snapshot.beatMarks
        lostMarks = snapshot.lostMarks
        onboardingComplete = snapshot.onboardingComplete
    }

    private func applyTurn(now: Date) {
        let turned = RemontoireFold.turn(
            seat: seat,
            arbor: arbor,
            lostBeat: lostBeat,
            ended: ended,
            now: now,
            calendar: calendar
        )
        arbor = turned.arbor
        lostBeat = turned.lostBeat
        ended = turned.ended
    }

    private func persistSoon() {
        let snapshot = snapshot
        Task { await vault.note(snapshot) }
    }
}
