#if DEBUG
import XCTest
@testable import Bookbinder

final class DebugRoadmapTests: XCTestCase {
    func testBundledRoadmapIsTheSingleReadableCurrentBoard() {
        let board = DebugRoadmap.current
        XCTAssertEqual(board.schemaVersion, 3)
        XCTAssertFalse(board.updated.isEmpty)
        XCTAssertFalse(board.currentWork.isEmpty)
        XCTAssertFalse(board.items.isEmpty)
        XCTAssertEqual(Set(board.items.map(\.id)).count, board.items.count,
                       "roadmap item IDs must remain stable and unique")
        XCTAssertTrue(board.validationErrors().isEmpty)
        XCTAssertEqual(board.currentItems.first?.id, "encounter-scaling")
        XCTAssertEqual(board.campaignBands.first?.id, "band-0")
        XCTAssertEqual(board.campaignBands.last?.id, "band-7")
        XCTAssertEqual(Set(board.campaignBands.flatMap(\.itemIDs)),
                       Set(board.items.filter { $0.status != .complete }.map(\.id)))
    }

    func testCompletedBlockersCannotRegressToQueuedInTheCurrentBoard() throws {
        let byID = Dictionary(uniqueKeysWithValues: DebugRoadmap.current.items.map { ($0.id, $0) })
        for id in ["outcome", "trading-post", "vance", "terrain"] {
            XCTAssertEqual(try XCTUnwrap(byID[id]).status, .complete, "\(id) is already installed")
        }
    }

    func testSourceCompleteReviewCheckpointsCannotRegressToQueued() throws {
        let byID = Dictionary(uniqueKeysWithValues: DebugRoadmap.current.items.map { ($0.id, $0) })
        for id in [
            "channelworks-restoration-receipt",
            "authored-text-first-review",
            "compound-hostility-authority",
            "legacy-token-quirk-cleanup"
        ] {
            XCTAssertEqual(try XCTUnwrap(byID[id]).status, .readyToTest,
                           "\(id) is source-complete and awaits acceptance, not implementation")
        }
    }

    func testIndependentWorkstreamPrimariesCoexistAndArrayOrderDoesNotChooseTheHeader() throws {
        let forward = try decodeBoard(items: [
            item("world", priority: "P0", status: "readyToTest", workstream: "acceptance", primary: true),
            item("asset", status: "inProgress", workstream: "asset", primary: true),
            item("field", status: "inProgress", workstream: "engineering", primary: true)
        ])
        let reversed = try decodeBoard(items: forward.items.reversed().map(encodedItem))

        XCTAssertTrue(forward.validationErrors().isEmpty)
        XCTAssertEqual(forward.currentItems.map(\.id), ["field", "asset", "world"])
        XCTAssertEqual(reversed.currentItems.map(\.id), forward.currentItems.map(\.id))
        XCTAssertTrue(forward.currentWork.contains("Acceptance: Test now · world"))
    }

    func testTwoEngineeringPrimariesDiagnoseBothIDsButZeroGlobalActiveIsValid() throws {
        let conflict = try decodeBoard(items: [
            item("beta", status: "inProgress", workstream: "engineering", primary: true),
            item("alpha", status: "inProgress", workstream: "engineering", primary: true)
        ])
        XCTAssertEqual(conflict.validationErrors(), ["Multiple engineering primaries: alpha, beta"])

        let waiting = try decodeBoard(items: [
            item("later", priority: "P2", status: "queued", workstream: "design"),
            item("test-now", priority: "P0", status: "readyToTest", workstream: "acceptance")
        ])
        XCTAssertTrue(waiting.validationErrors().isEmpty)
        XCTAssertEqual(waiting.currentItems.map(\.id), ["test-now"])
    }

    func testCurrentBoardParksWholeTreeAndOrdersScalingBeforeOpeningNodes() throws {
        let board = DebugRoadmap.current
        let byID = Dictionary(uniqueKeysWithValues: board.items.map { ($0.id, $0) })
        XCTAssertEqual(try XCTUnwrap(byID["encounter-scaling"]).status, .inProgress)
        XCTAssertTrue(try XCTUnwrap(byID["encounter-scaling"]).isPrimary)
        XCTAssertEqual(try XCTUnwrap(byID["combat-tree-opening-choices"]).status, .queued)
        XCTAssertEqual(try XCTUnwrap(byID["combat-tree-first-route"]).status, .queued)
        XCTAssertEqual(try XCTUnwrap(byID["combat-tree-v2"]).status, .paused)
        XCTAssertFalse(try XCTUnwrap(byID["combat-tree-v2"]).isPrimary)
    }

    func testWorldPageWorkFollowsReachabilityAndDoesNotPreemptScaling() throws {
        let board = DebugRoadmap.current
        let bands = Dictionary(uniqueKeysWithValues: board.campaignBands.map { ($0.id, $0.itemIDs) })
        let opening = try XCTUnwrap(bands["band-1"])
        XCTAssertLessThan(try XCTUnwrap(opening.firstIndex(of: "encounter-scaling")),
                          try XCTUnwrap(opening.firstIndex(of: "starter-world-pages")))
        XCTAssertTrue(try XCTUnwrap(bands["band-2"]).contains("rune-dictionary"))
        XCTAssertTrue(try XCTUnwrap(bands["band-2"]).contains("saved-page-templates"))
        XCTAssertTrue(try XCTUnwrap(bands["band-3"]).contains("wild-world-pages"))
        XCTAssertTrue(try XCTUnwrap(bands["band-6"]).contains("authored-world-blueprints"))
    }

    func testSchemaOneDecodesWithDeterministicReviewedWorkstreams() throws {
        let data = try JSONSerialization.data(withJSONObject: [
            "schemaVersion": 1, "updated": "legacy", "essenceBaseline": "old", "paused": [],
            "installedCheckpoint": "must not become authority", "currentWork": "stale mirror",
            "currentNote": "stale note", "items": [
                legacyItem("combat-tree-v2", status: "inProgress"),
                legacyItem("item-character-identities", status: "queued"),
                legacyItem("phone", status: "readyToTest")
            ]
        ])
        let board = try JSONDecoder().decode(DebugRoadmap.Board.self, from: data)
        XCTAssertEqual(board.items.map(\.workstream), [.engineering, .asset, .acceptance])
        XCTAssertEqual(board.currentItems.map(\.id), ["combat-tree-v2"])
        XCTAssertFalse(board.currentWork.contains("stale mirror"))
        XCTAssertFalse(board.currentNote.contains("stale note"))
    }

    func testBundledRoadmapIsDisclosedAsAClaimRatherThanInstalledEvidence() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let roadmap = try String(contentsOf: root.appending(path: "Sources/Debug/DebugRoadmapView.swift"),
                                 encoding: .utf8)
        let reporter = try String(contentsOf: root.appending(path: "Sources/Debug/DebugBugReporterView.swift"),
                                  encoding: .utf8)
        XCTAssertTrue(roadmap.contains("Bundled planning snapshot"))
        XCTAssertTrue(roadmap.contains("not a measurement of the installed commit"))
        XCTAssertFalse(roadmap.contains("Live DEBUG view"))
        XCTAssertTrue(reporter.contains("Bundled roadmap claim"))
        XCTAssertFalse(reporter.contains("LabeledContent(\"Roadmap checkpoint\""))
    }

    private func decodeBoard(items: [[String: Any]]) throws -> DebugRoadmap.Board {
        let data = try JSONSerialization.data(withJSONObject: [
            "schemaVersion": 2, "updated": "test", "essenceBaseline": "test",
            "items": items, "paused": []
        ])
        return try JSONDecoder().decode(DebugRoadmap.Board.self, from: data)
    }

    private func item(_ id: String, priority: String = "P1", status: String,
                      workstream: String, primary: Bool = false) -> [String: Any] {
        var value = legacyItem(id, priority: priority, status: status)
        value["workstream"] = workstream
        value["isPrimary"] = primary
        return value
    }

    private func legacyItem(_ id: String, priority: String = "P1",
                            status: String) -> [String: Any] {
        ["id": id, "priority": priority, "title": id, "status": status,
         "detail": "detail \(id)", "gate": "gate \(id)"]
    }

    private func encodedItem(_ value: DebugRoadmap.Item) -> [String: Any] {
        ["id": value.id, "priority": value.priority, "title": value.title,
         "status": value.status.rawValue, "workstream": value.workstream.rawValue,
         "isPrimary": value.isPrimary, "detail": value.detail, "gate": value.gate]
    }
}

@MainActor
final class DesignHomeworkTests: XCTestCase {
    func testBundledQuestionsAndChoicesHaveStableUniqueIDs() {
        let catalogue = DesignHomeworkCatalogue.current
        XCTAssertEqual(catalogue.schemaVersion, 1)
        XCTAssertEqual(catalogue.questions.count, 20)
        XCTAssertEqual(Set(catalogue.questions.map(\.id)).count, catalogue.questions.count)
        for question in catalogue.questions {
            XCTAssertFalse(question.choices.isEmpty)
            XCTAssertEqual(Set(question.choices.map(\.id)).count, question.choices.count)
            if let reviewItems = question.reviewItems {
                XCTAssertEqual(Set(reviewItems.map(\.id)).count, reviewItems.count)
                XCTAssertTrue(reviewItems.allSatisfy { !$0.candidate.isEmpty })
            }
        }
    }

    func testChoiceAndTextSurviveReloadWithoutChangingQuestionContent() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("homework-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appendingPathComponent("answers.json")

        let first = DesignHomeworkStore(fileURL: file)
        try first.save(questionID: "combat-shatter-effect",
                       choiceID: "strike-and-break",
                       customText: "Keep the armour loss visible in the combat log.")

        let reloaded = DesignHomeworkStore(fileURL: file)
        let answer = try XCTUnwrap(reloaded.answer(for: "combat-shatter-effect"))
        XCTAssertEqual(answer.choiceID, "strike-and-break")
        XCTAssertEqual(answer.customText, "Keep the armour loss visible in the combat log.")
        XCTAssertEqual(answer.questionTitle, "What should Shatter do?")
        XCTAssertEqual(answer.choiceTitle, "Strike and break armour")
        XCTAssertEqual(answer.catalogueUpdated, DesignHomeworkCatalogue.current.updated)
        XCTAssertNotNil(reloaded.exportURL)
    }

    func testFreeTextCanReplaceTheOfferedChoices() throws {
        let file = FileManager.default.temporaryDirectory
            .appendingPathComponent("homework-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: file) }

        let store = DesignHomeworkStore(fileURL: file)
        try store.save(questionID: "combat-distiller-effect", choiceID: nil,
                       customText: "Use two charges, but only after the first Apothecary upgrade.")
        XCTAssertNil(store.answer(for: "combat-distiller-effect")?.choiceID)
        XCTAssertEqual(store.answer(for: "combat-distiller-effect")?.customText,
                       "Use two charges, but only after the first Apothecary upgrade.")
    }
}
#endif
