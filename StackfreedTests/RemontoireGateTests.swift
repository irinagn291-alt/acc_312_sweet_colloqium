import XCTest
@testable import Stackfreed

final class RemontoireGateTests: XCTestCase {
    func test_reviewScreenParser_todayLogGoalsAreDistinctLeaves() {
        XCTAssertEqual(RemontoireGate.flag, "-ReviewScreen")
        XCTAssertEqual(RemontoireGate.leaf(from: ["-ReviewScreen", "today"]), .rings)
        XCTAssertEqual(RemontoireGate.leaf(from: ["-ReviewScreen", "log"]), .dashboard)
        XCTAssertEqual(RemontoireGate.leaf(from: ["-ReviewScreen", "goals"]), .settings)
        XCTAssertNotEqual(RemontoireGate.leaf(from: ["-ReviewScreen", "today"]), RemontoireGate.leaf(from: ["-ReviewScreen", "log"]))
        XCTAssertNotEqual(RemontoireGate.leaf(from: ["-ReviewScreen", "log"]), RemontoireGate.leaf(from: ["-ReviewScreen", "goals"]))
    }

    func test_reviewScreenParser_readsProcessInfoArgumentsOncePattern() {
        let fromMissingFlag = RemontoireGate.leaf(from: ["-AppleLanguages", "en"])
        XCTAssertEqual(fromMissingFlag, .rings)
        XCTAssertEqual(RemontoireGate.leaf(from: ["-ReviewScreen"]), .rings)
        XCTAssertEqual(RemontoireGate.leaf(from: ["-ReviewScreen", "onboarding"]), .onboarding)
        XCTAssertEqual(RemontoireGate.leaf(from: ["-ReviewScreen", "rings"]), .rings)
        XCTAssertEqual(RemontoireGate.leaf(from: ["-ReviewScreen", "dashboard"]), .dashboard)
        XCTAssertEqual(RemontoireGate.leaf(from: ["-ReviewScreen", "settings"]), .settings)
        XCTAssertEqual(RemontoireGate.leaf(from: ["-ReviewScreen", "lostbeat"]), .lostBeat)
        XCTAssertEqual(RemontoireGate.leaf(from: ["-ReviewScreen", "arborsettings"]), .settings)
        XCTAssertEqual(RemontoireGate.leaf(from: ["-ReviewScreen", "beatmark"]), .dashboard)
        XCTAssertEqual(RemontoireGate.leaf(from: ["-ReviewScreen", "unknown"]), .rings)
    }

    func test_figuresUseNumberFormatter() {
        XCTAssertFalse(RemontoireFigure.whole(12).isEmpty)
        XCTAssertEqual(RemontoireFigure.dayKey(PalletKey(rawValue: 20260827)), "20260827")
        XCTAssertEqual(RemontoireFigure.markWord(closed: true), "Closed")
        XCTAssertEqual(RemontoireFigure.markWord(closed: false), "Mended")
        XCTAssertTrue(RemontoireFigure.ratio(completed: 3, scheduled: 5).contains(RemontoireFigure.whole(3)))
        XCTAssertTrue(RemontoireFigure.ratio(completed: 3, scheduled: 5).contains(RemontoireFigure.whole(5)))
        XCTAssertTrue(RemontoireFigure.streak(8).contains(RemontoireFigure.whole(8)))
        XCTAssertEqual(RemontoireGate.consume(), RemontoireGate.consume())
        XCTAssertEqual(RemontoireGate.leaf(from: ProcessInfo.processInfo.arguments), RemontoireGate.consume())
    }

    func test_userCopyOmitsRemontoireTypeNames() throws {
        let banned = ["pallet", "seated", "seat a", "beatmark", "lostmark", "hollow", "arbor", "remontoire"]
        for line in RemontoireVoice.userFacing {
            let lower = line.lowercased()
            for word in banned {
                XCTAssertFalse(lower.contains(word), "\(line) contains \(word)")
            }
        }
        XCTAssertEqual(RemontoireVoice.lostHeld, "Tap a silent past day. Future days refuse.")
        XCTAssertEqual(RemontoireVoice.jobMendPast, "Today is closed. Tap a silent past day to mend it.")
        XCTAssertEqual(RemontoireVoice.noHabit, "No habit yet.")
        XCTAssertEqual(RemontoireVoice.onboardingMend, "Tap a silent past day to spend this week's lost beat. Tomorrow cannot take it.")
        XCTAssertEqual(RemontoireVoice.nameHabitFirst, "Name a habit first. Then a silent day can take this week's lost beat.")
        XCTAssertEqual(RemontoireVoice.afterMend(.hollow), RemontoireVoice.noHabit)
        XCTAssertEqual(RemontoireVoice.afterMend(.refused(.futurePallet)), RemontoireVoice.futureClosed)
        XCTAssertNil(RemontoireVoice.afterMend(.mended(LostMark(palletKey: PalletKey(rawValue: 20260824)))))

        let screens = [
            "Arbor/Rings.swift",
            "Remontoire/Onboarding.swift",
            "LostBeat/LostBeatPage.swift",
        ]
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Stackfreed")
        for screen in screens {
            let source = try String(contentsOf: root.appendingPathComponent(screen), encoding: .utf8)
            let lower = source.lowercased()
            XCTAssertFalse(lower.contains("pallet"), "\(screen) still names Pallet in a user screen")
            XCTAssertFalse(lower.contains("seated"), "\(screen) still names seated in a user screen")
            XCTAssertFalse(lower.contains("seat"), "\(screen) still names Seat in a user screen")
        }

        let timeline = try String(
            contentsOf: root.appendingPathComponent("Pallet/PalletTimeline.swift"),
            encoding: .utf8
        )
        XCTAssertTrue(timeline.contains("mendPallet"), "PalletTimeline must call mendPallet")
        XCTAssertTrue(timeline.contains("struct PalletTimeline"), "SpriteKit host stays PalletTimeline")
    }
}
