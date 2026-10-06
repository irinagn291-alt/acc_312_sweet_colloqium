import XCTest
@testable import Stackfreed

final class RemontoireFoldTests: XCTestCase {
    private let calendar = ArborCalendar.make()
    private let thursday = PalletKey(rawValue: 20260827)
    private let friday = PalletKey(rawValue: 20260828)
    private let monday = PalletKey(rawValue: 20260824)

    func test_beatOnTodaysOpenPalletFoldsToBeaten() {
        let arbor = Arbor.openWeek(
            seat: ArborCalendar.seat,
            containing: ArborCalendar.day(2026, 8, 27, calendar: calendar),
            calendar: calendar
        )
        let folded = RemontoireFold.beat(arbor: arbor, today: thursday, seated: true)
        XCTAssertEqual(folded.outcome, .beaten(BeatMark(palletKey: thursday)))
        XCTAssertEqual(folded.arbor.remontoire(on: thursday), .beaten)
        XCTAssertEqual(folded.arbor.remontoire(on: friday), .open)
        XCTAssertEqual(arbor.remontoire(on: thursday), .open)
    }

    func test_beatEmptyAndInvalidPaths() {
        let hollow = RemontoireFold.beat(arbor: .hollow, today: thursday, seated: false)
        XCTAssertEqual(hollow.outcome, .hollow)

        let emptyArbor = RemontoireFold.beat(arbor: .hollow, today: thursday, seated: true)
        XCTAssertEqual(emptyArbor.outcome, .hollow)

        let arbor = Arbor.openWeek(
            seat: ArborCalendar.seat,
            containing: ArborCalendar.day(2026, 8, 27, calendar: calendar),
            calendar: calendar
        )
        let weekend = RemontoireFold.beat(arbor: arbor, today: PalletKey(rawValue: 20260829), seated: true)
        XCTAssertEqual(weekend.outcome, .refused(.notScheduled))

        let beaten = RemontoireFold.beat(arbor: arbor.folding(thursday, to: .beaten), today: thursday, seated: true)
        XCTAssertEqual(beaten.outcome, .refused(.alreadyFolded))
    }

    func test_mendPastEmptyPalletWhileLostBeatRemains() {
        let arbor = Arbor.openWeek(
            seat: ArborCalendar.seat,
            containing: ArborCalendar.day(2026, 8, 27, calendar: calendar),
            calendar: calendar
        )
        let folded = RemontoireFold.mend(
            arbor: arbor,
            key: monday,
            today: thursday,
            lostBeat: .held,
            seated: true
        )
        XCTAssertEqual(folded.outcome, .mended(LostMark(palletKey: monday)))
        XCTAssertEqual(folded.lostBeat, .spent)
        XCTAssertEqual(folded.arbor.remontoire(on: monday), .mended)
        XCTAssertTrue(folded.arbor.remontoire(on: monday)?.countsAsCompleted ?? false)
    }

    func test_mendRefusesFuturePalletAndSecondLostBeat() {
        let arbor = Arbor.openWeek(
            seat: ArborCalendar.seat,
            containing: ArborCalendar.day(2026, 8, 27, calendar: calendar),
            calendar: calendar
        )
        let future = RemontoireFold.mend(
            arbor: arbor,
            key: friday,
            today: thursday,
            lostBeat: .held,
            seated: true
        )
        XCTAssertEqual(future.outcome, .refused(.futurePallet))
        XCTAssertEqual(future.lostBeat, .held)

        let first = RemontoireFold.mend(
            arbor: arbor,
            key: monday,
            today: thursday,
            lostBeat: .held,
            seated: true
        )
        let second = RemontoireFold.mend(
            arbor: first.arbor,
            key: PalletKey(rawValue: 20260825),
            today: thursday,
            lostBeat: first.lostBeat,
            seated: true
        )
        XCTAssertEqual(second.outcome, .refused(.lostBeatSpent))
    }

    func test_unusedLostBeatDropsWhenTheWeekTurns() {
        var arbor = Arbor.openWeek(
            seat: ArborCalendar.seat,
            containing: ArborCalendar.day(2026, 8, 27, calendar: calendar),
            calendar: calendar
        )
        arbor = arbor.folding(monday, to: .beaten)
        let turned = RemontoireFold.turn(
            seat: ArborCalendar.seat,
            arbor: arbor,
            lostBeat: .held,
            ended: [],
            now: ArborCalendar.day(2026, 8, 31, calendar: calendar),
            calendar: calendar
        )
        XCTAssertEqual(turned.ended.count, 1)
        XCTAssertEqual(turned.ended[0].remontoire(on: friday), .open)
        XCTAssertFalse(turned.ended[0].holdsLostMark)
        XCTAssertEqual(turned.lostBeat, .held)
        XCTAssertEqual(turned.arbor.weekStart.rawValue, 20260831)
    }

    func test_architecture_arborIsFoldOverPallets() {
        let arbor = Arbor.openWeek(
            seat: ArborCalendar.seat,
            containing: ArborCalendar.day(2026, 8, 27, calendar: calendar),
            calendar: calendar
        )
        let folded = ArborFold.fold(arbor, today: thursday, lostBeat: .held, calendar: calendar)
        XCTAssertEqual(folded.pallets.count, 7)
        XCTAssertEqual(folded.pallets.filter { $0.remontoire != nil }.count, 5)
        XCTAssertTrue(folded.canBeatToday)
        XCTAssertTrue(folded.mendable.contains(monday))
        XCTAssertFalse(folded.mendable.contains(friday))

        let beaten = RemontoireFold.beat(arbor: arbor, today: thursday, seated: true)
        let refolded = ArborFold.fold(beaten.arbor, today: thursday, lostBeat: .held, calendar: calendar)
        XCTAssertEqual(refolded.pallets.first { $0.key == thursday }?.remontoire, .beaten)
        XCTAssertFalse(refolded.canBeatToday)
        XCTAssertEqual(Remontoire.allCases, [.open, .beaten, .mended])
    }
}

@MainActor
final class RemontoireStoreFoldTests: XCTestCase {
    private let calendar = ArborCalendar.make()

    func test_storeBeatAndMendDoNotKeepAParallelBool() {
        let store = RemontoireStore(vault: ArborMemory(), calendar: calendar)
        let now = ArborCalendar.day(2026, 8, 27, calendar: calendar)
        XCTAssertEqual(store.beatToday(now: now), .hollow)
        store.wind(ArborCalendar.seat, now: now)
        XCTAssertEqual(store.beatToday(now: now), .beaten(BeatMark(palletKey: PalletKey(rawValue: 20260827))))
        XCTAssertEqual(store.arbor.remontoire(on: PalletKey(rawValue: 20260827)), .beaten)
        XCTAssertEqual(
            store.mendPallet(PalletKey(rawValue: 20260824), now: now),
            .mended(LostMark(palletKey: PalletKey(rawValue: 20260824)))
        )
        XCTAssertEqual(store.lostBeat, .spent)
        XCTAssertEqual(store.folded(at: now), ArborFold.fold(store.arbor, today: PalletKey(rawValue: 20260827), lostBeat: store.lostBeat, calendar: calendar))
        XCTAssertEqual(store.folded(at: now).days, store.folded(at: now).pallets)
        XCTAssertTrue(store.hasHabit)
        store.renameHabit("New lap", now: now)
        XCTAssertEqual(store.habitName, "New lap")
        XCTAssertEqual(store.habitWeekdays, ArborCalendar.seat.scheduledWeekdays)
        store.saveHabit(name: "Quiet lap", weekdays: [2, 3, 4], now: now)
        XCTAssertEqual(store.habitName, "Quiet lap")
        XCTAssertEqual(store.habitWeekdays, [2, 3, 4])
    }
}
