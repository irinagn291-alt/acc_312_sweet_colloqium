import Foundation

/// Role: Remontoire. Codable envelope for skf.arbor.v1. Domain types never decode this JSON themselves.
struct RemontoireDocument: Codable, Equatable, Sendable {
    var schemaVersion: Int
    var seatName: String?
    var scheduledWeekdays: [Int]
    var weekStart: Int
    var pallets: [PalletRecord]
    var beatMarks: [Int]
    var lostMarks: [Int]
    var lostBeat: String
    var ended: [ArborRecord]
    var onboardingComplete: Bool
}

struct ArborRecord: Codable, Equatable, Sendable {
    var weekStart: Int
    var pallets: [PalletRecord]
}

struct PalletRecord: Codable, Equatable, Sendable {
    var day: Int
    var remontoire: String
}

/// Role: Remontoire. In-memory projection. UserDefaults is the projection, not the source of truth.
struct RemontoireSnapshot: Equatable, Sendable {
    var seat: Seat?
    var arbor: Arbor
    var lostBeat: LostBeat
    var ended: [Arbor]
    var beatMarks: [BeatMark]
    var lostMarks: [LostMark]
    var onboardingComplete: Bool

    static let empty = RemontoireSnapshot(
        seat: nil,
        arbor: .hollow,
        lostBeat: .held,
        ended: [],
        beatMarks: [],
        lostMarks: [],
        onboardingComplete: false
    )

    var ledger: Ledger {
        Ledger(beatMarks: beatMarks, lostMarks: lostMarks)
    }
}

enum RemontoireCodec {
    static let currentSchema = 1

    enum Failure: Error, Equatable {
        case unsupportedSchema(Int)
        case corrupt
    }

    static func encode(_ snapshot: RemontoireSnapshot) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(document(from: snapshot))
    }

    static func decode(_ data: Data) throws -> RemontoireSnapshot {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        let probe: SchemaProbe
        do {
            probe = try decoder.decode(SchemaProbe.self, from: data)
        } catch {
            throw Failure.corrupt
        }
        switch probe.schemaVersion {
        case 1:
            do {
                return snapshot(from: try decoder.decode(RemontoireDocument.self, from: data))
            } catch let failure as Failure {
                throw failure
            } catch {
                throw Failure.corrupt
            }
        default:
            throw Failure.unsupportedSchema(probe.schemaVersion)
        }
    }

    static func document(from snapshot: RemontoireSnapshot) -> RemontoireDocument {
        RemontoireDocument(
            schemaVersion: currentSchema,
            seatName: snapshot.seat?.name,
            scheduledWeekdays: (snapshot.seat?.scheduledWeekdays ?? []).sorted(),
            weekStart: snapshot.arbor.weekStart.rawValue,
            pallets: palletRecords(snapshot.arbor.pallets),
            beatMarks: snapshot.beatMarks.map(\.palletKey.rawValue).sorted(),
            lostMarks: snapshot.lostMarks.map(\.palletKey.rawValue).sorted(),
            lostBeat: snapshot.lostBeat.rawValue,
            ended: snapshot.ended.map { arbor in
                ArborRecord(weekStart: arbor.weekStart.rawValue, pallets: palletRecords(arbor.pallets))
            },
            onboardingComplete: snapshot.onboardingComplete
        )
    }

    static func snapshot(from document: RemontoireDocument) -> RemontoireSnapshot {
        let seat: Seat?
        if let name = document.seatName {
            seat = Seat(name: name, scheduledWeekdays: Set(document.scheduledWeekdays))
        } else {
            seat = nil
        }
        let arbor = Arbor(
            weekStart: PalletKey(rawValue: document.weekStart),
            pallets: pallets(from: document.pallets)
        )
        let lostBeat = LostBeat(rawValue: document.lostBeat) ?? .held
        return RemontoireSnapshot(
            seat: seat,
            arbor: arbor,
            lostBeat: arbor.holdsLostMark ? .spent : lostBeat,
            ended: document.ended.map { record in
                Arbor(weekStart: PalletKey(rawValue: record.weekStart), pallets: pallets(from: record.pallets))
            },
            beatMarks: document.beatMarks.map { BeatMark(palletKey: PalletKey(rawValue: $0)) },
            lostMarks: document.lostMarks.map { LostMark(palletKey: PalletKey(rawValue: $0)) },
            onboardingComplete: document.onboardingComplete
        )
    }

    private static func palletRecords(_ pallets: [PalletKey: Remontoire]) -> [PalletRecord] {
        pallets.keys.sorted().map { key in
            PalletRecord(day: key.rawValue, remontoire: (pallets[key] ?? .open).rawValue)
        }
    }

    private static func pallets(from records: [PalletRecord]) -> [PalletKey: Remontoire] {
        var result: [PalletKey: Remontoire] = [:]
        for record in records {
            result[PalletKey(rawValue: record.day)] = Remontoire(rawValue: record.remontoire) ?? .open
        }
        return result
    }
}

private struct SchemaProbe: Decodable {
    var schemaVersion: Int
}
