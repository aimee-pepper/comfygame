import XCTest
@testable import Bookbinder

final class FieldNoteTests: XCTestCase {
    func testStructuredFieldNoteRoundTripsWithoutReconstructingItsProse() throws {
        let original = FoundWritingRecord(
            id: "saved-note", family: .fieldNote,
            prose: "The ground rises toward the east; the old scratches follow the same line.",
            position: .init(x: 4, y: 5), templateID: "field_terrain_height_01",
            fieldFact: .terrain(.init(direction: "east", relation: "rises")),
            originWorldSeed: 991)

        let decoded = try JSONDecoder().decode(
            FoundWritingRecord.self, from: JSONEncoder().encode(original))
        XCTAssertEqual(decoded, original)
    }

    func testGeneratedFieldNotesFreezeDeterministicWorldLocalFactsInsteadOfGenericFiller() throws {
        let book = BoundBook(written: [], essencePaid: 0)
        var tuning = DebugTuningProfile.defaults
        tuning.diaryWritingShare = 0
        tuning.additionalPageChance = 0
        for seed in UInt64(1)...80 {
            let first = Worldgen.generate(book: book, seed: seed, tuning: tuning)
            let second = Worldgen.generate(book: book, seed: seed, tuning: tuning)
            XCTAssertEqual(first.writings, second.writings)
            XCTAssertFalse(first.writings.isEmpty)

            for note in first.writings {
                XCTAssertEqual(note.family, .fieldNote)
                XCTAssertEqual(note.originWorldSeed, seed)
                XCTAssertNotNil(note.templateID)
                XCTAssertNotNil(note.fieldFact)
                XCTAssertFalse(note.prose.contains("marked the firmer way through this place"))
                XCTAssertTrue(first.map.contains(note.position))
                assertLocalTruth(note, map: first.map, book: book, seed: seed)
            }
        }
    }

    func testSecondFieldNotePrefersAnotherTemplateAndFactWhenTheWorldProvidesIt() {
        let book = BoundBook(written: ["teeming_life", "wet_world"], essencePaid: 0)
        var library = LibraryState()
        library.foundPages = ContentCatalog.shared.diaryPages.map(\.id)
        var tuning = DebugTuningProfile.defaults
        tuning.diaryWritingShare = 0
        tuning.additionalPageChance = 1
        var checked = 0
        for seed in UInt64(1)...300 {
            let notes = Worldgen.generate(book: book, seed: seed, library: library,
                                          tuning: tuning).writings
            guard notes.count > 1 else { continue }
            checked += 1
            XCTAssertEqual(Set(notes.compactMap(\.templateID)).count, notes.count)
            XCTAssertEqual(Set(notes.compactMap { factSignature($0.fieldFact) }).count, notes.count)
            if checked == 12 { break }
        }
        XCTAssertGreaterThan(checked, 0)
    }

    func testUnknownFutureFieldFactKeepsFrozenProseReadable() throws {
        let note = FoundWritingRecord(
            id: "legacy-note", family: .fieldNote, prose: "The saved words remain.",
            position: .init(x: 2, y: 3), templateID: "retired_template",
            fieldFact: .terrain(.init(groundA: "soil")), originWorldSeed: 44)
        var object = try XCTUnwrap(JSONSerialization.jsonObject(
            with: JSONEncoder().encode(note)) as? [String: Any])
        object["fieldFact"] = ["futureCase": ["value": "unknown"]]

        let decoded = try JSONDecoder().decode(
            FoundWritingRecord.self, from: JSONSerialization.data(withJSONObject: object))
        XCTAssertEqual(decoded.prose, "The saved words remain.")
        XCTAssertEqual(decoded.templateID, "retired_template")
        XCTAssertEqual(decoded.originWorldSeed, 44)
        XCTAssertNil(decoded.fieldFact)
    }

    private func assertLocalTruth(_ note: FoundWritingRecord, map: WorldMap,
                                  book: BoundBook, seed: UInt64,
                                  file: StaticString = #filePath, line: UInt = #line) {
        let host = map[note.position]
        let local = [note.position] + map.neighbours(of: note.position)
        let localGrounds = Set(local.map { map[$0].ground.displayName })
        guard let fact = note.fieldFact else {
            return XCTFail("generated note lacks fact", file: file, line: line)
        }
        switch fact {
        case .terrain(let tokens):
            if let ground = tokens.groundA { XCTAssertTrue(localGrounds.contains(ground), file: file, line: line) }
            if let ground = tokens.groundB { XCTAssertTrue(localGrounds.contains(ground), file: file, line: line) }
            if tokens.relation == "two turns" {
                XCTAssertTrue(local.contains { map[$0].ground.movementCost == 2 }, file: file, line: line)
            }
            if tokens.relation == "blocks sight" {
                XCTAssertTrue(local.contains { map[$0].ground.blocksSight }, file: file, line: line)
            }
            if tokens.relation == "impassable" {
                XCTAssertTrue(local.contains { !map[$0].isPassable }, file: file, line: line)
            }
        case .growth(let tokens):
            XCTAssertTrue(local.contains { map[$0].ground.isOvergrown }, file: file, line: line)
            if tokens.relation == "blocks sight" {
                XCTAssertTrue(local.contains { map[$0].ground.blocksSight }, file: file, line: line)
            }
        case .water(let tokens):
            let kinds: Set<GroundType> = [.water, .deepWater, .ice, .mud]
            XCTAssertTrue(local.contains { kinds.contains(map[$0].ground) }, file: file, line: line)
            if tokens.relation == "two turns" {
                XCTAssertTrue(local.contains { map[$0].ground == .mud }, file: file, line: line)
            }
        case .lightAir(let tokens):
            let readings = BookRules.readings(for: book, seed: seed)
            switch tokens.quality {
            case "dark": XCTAssertLessThanOrEqual(readings["illumination"].peak, 25, file: file, line: line)
            case "bright": XCTAssertGreaterThanOrEqual(readings["illumination"].floor, 75, file: file, line: line)
            default: break
            }
            if tokens.relation == "moving air" {
                XCTAssertGreaterThan(readings["atmosphere"].aspect("motion"), 50, file: file, line: line)
            }
            if tokens.relation == "still air" {
                XCTAssertLessThanOrEqual(readings["atmosphere"].aspect("motion"), 50, file: file, line: line)
            }
        }
        XCTAssertEqual(host.content, .foundWriting(note.id), file: file, line: line)
    }

    private func factSignature(_ fact: FieldNoteFact?) -> String? {
        guard let data = try? JSONEncoder().encode(fact),
              let string = String(data: data, encoding: .utf8) else { return nil }
        return string
    }
}
