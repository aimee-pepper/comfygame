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
        XCTAssertEqual(board.items.first { $0.id == "encounter-scaling" }?.status, .readyToTest)
        XCTAssertEqual(board.items.first { $0.id == "godmode-testing" }?.status, .readyToTest)
        XCTAssertFalse(board.items.first { $0.id == "godmode-testing" }?.isPrimary == true)
        XCTAssertFalse(board.currentItems.contains { $0.id == "item-character-identities" },
                       "a source-complete Asset checkpoint is not active work")
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

    func testCommittedProgressionFeaturesAwaitAcceptanceInsteadOfImplementation() throws {
        let byID = Dictionary(uniqueKeysWithValues: DebugRoadmap.current.items.map { ($0.id, $0) })
        for id in [
            "collapse-hud-truth",
            "terrain-blocked-feedback",
            "field-note-generator",
            "rune-dictionary",
            "saved-page-templates",
            "wild-world-pages",
            "starter-world-pages",
            "early-knowledge-stations"
        ] {
            let item = try XCTUnwrap(byID[id])
            XCTAssertEqual(item.status, .readyToTest,
                           "\(id) is committed and awaits ordinary-phone acceptance")
            XCTAssertFalse(item.isPrimary, "\(id) must not become an Engineering primary")
        }
    }

    func testScentMaskAwaitsHonestPhoneAcceptance() throws {
        let item = try XCTUnwrap(DebugRoadmap.current.items.first { $0.id == "scent-mask" })
        XCTAssertEqual(item.status, .readyToTest)
        XCTAssertFalse(item.isPrimary, "Scent Mask must not become an Engineering primary")
        for checkpoint in ["7772df0", "5e5aa14", "2ced55a", "543ddfe"] {
            XCTAssertTrue(item.detail.contains(checkpoint), "missing Scent Mask evidence \(checkpoint)")
        }
        for pendingGate in ["Phone-only", "sensory behavior", "Quiet Step", "relaunch", "protected Field Kit"] {
            XCTAssertTrue(item.gate.contains(pendingGate), "missing pending phone gate: \(pendingGate)")
        }
        XCTAssertTrue(item.detail.contains("grade-25+ animal-world-resource ingredient is transitional"))
        for finalIngredient in ["Hide", "Pelt", "Down", "Oil", "no grade"] {
            XCTAssertTrue(item.gate.contains(finalIngredient),
                          "missing final Creature-material gate: \(finalIngredient)")
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
        XCTAssertTrue(forward.currentWork.contains("Acceptance: Awaiting acceptance · world"))
    }

    func testTwoPrimariesInOneWorkstreamDiagnoseBothIDsRegardlessOfActiveStatus() throws {
        let conflict = try decodeBoard(items: [
            item("beta", status: "readyToTest", workstream: "engineering", primary: true),
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
        XCTAssertEqual(try XCTUnwrap(byID["encounter-scaling"]).status, .readyToTest)
        XCTAssertFalse(try XCTUnwrap(byID["encounter-scaling"]).isPrimary)
        XCTAssertEqual(try XCTUnwrap(byID["godmode-testing"]).status, .readyToTest)
        XCTAssertFalse(try XCTUnwrap(byID["godmode-testing"]).isPrimary)
        let opening = try XCTUnwrap(byID["combat-tree-opening-choices"])
        XCTAssertEqual(opening.status, .readyToTest)
        XCTAssertFalse(opening.isPrimary)
        XCTAssertTrue(opening.detail.contains("13bb6ec"))
        XCTAssertTrue(opening.detail.contains("825a8a2"))
        XCTAssertTrue(opening.detail.contains("3932c7e"))
        XCTAssertTrue(opening.gate.contains("24/24"))
        XCTAssertTrue(opening.gate.contains("200/200"))
        XCTAssertEqual(try XCTUnwrap(byID["combat-tree-first-route"]).status, .queued)
        XCTAssertEqual(try XCTUnwrap(byID["combat-tree-v2"]).status, .paused)
        XCTAssertFalse(try XCTUnwrap(byID["combat-tree-v2"]).isPrimary)
    }

    func testEarlyKnowledgeContributionsAwaitPhoneAcceptanceInsteadOfImplementation() throws {
        let item = try XCTUnwrap(DebugRoadmap.current.items.first {
            $0.id == "early-knowledge-stations"
        })
        XCTAssertEqual(item.status, .readyToTest)
        XCTAssertFalse(item.isPrimary)
        for checkpoint in ["c917c27", "1f6cfce", "460c2cd", "12c5759"] {
            XCTAssertTrue(item.detail.contains(checkpoint), "missing evidence \(checkpoint)")
        }
        XCTAssertTrue(item.detail.contains("visible-flora recognition"))
        XCTAssertTrue(item.detail.contains("no decorative room"))
        XCTAssertTrue(item.gate.contains("real expeditions"))
        XCTAssertTrue(item.gate.contains("hidden flora never leaks"))
        XCTAssertTrue(item.gate.contains("miniature Tavern"))
    }

    func testCurrentBoardKeepsCanonicalTerminologyPrimaryAfterInstalledWritingTerrainAndArrival() throws {
        let board = DebugRoadmap.current
        let primaries = Dictionary(grouping: board.items.filter(\.isPrimary), by: \.workstream)
        XCTAssertTrue(primaries.values.allSatisfy { $0.count <= 1 },
                      "each workstream may disclose at most one primary")
        XCTAssertEqual(board.items.filter(\.isPrimary).map(\.id), ["canonical-ui-terminology"])
        let engineering = try XCTUnwrap(primaries[.engineering])
        XCTAssertEqual(engineering.count, 1)
        let terminology = try XCTUnwrap(engineering.first)
        XCTAssertEqual(terminology.status, .inProgress)
        XCTAssertTrue(terminology.gate.contains("human-visible string census"))
        XCTAssertTrue(terminology.gate.contains("GameWiki derives canonical labels"))

        let arrival = try XCTUnwrap(board.items.first { $0.id == "world-arrival-reveal" })
        XCTAssertEqual(arrival.status, .readyToTest)
        XCTAssertFalse(arrival.isPrimary)
        XCTAssertTrue(arrival.detail.contains("05b3a5d8"))

        let writing = try XCTUnwrap(board.items.first { $0.id == "writing-causal-presentation" })
        XCTAssertEqual(writing.status, .readyToTest)
        XCTAssertFalse(writing.isPrimary)
        XCTAssertTrue(writing.detail.contains("source-complete through shared revision f7c4fa45"))
        XCTAssertTrue(writing.gate.contains("exact signed physical-phone build"))

        let terrain = try XCTUnwrap(board.items.first { $0.id == "terrain-layering-animation" })
        XCTAssertEqual(terrain.status, .readyToTest)
        XCTAssertFalse(terrain.isPrimary)
        XCTAssertTrue(terrain.detail.contains("366f5ccf"))
        XCTAssertTrue(terrain.detail.contains("integrationReady:false"))
        XCTAssertTrue(terrain.detail.contains("installed in place"))
        XCTAssertTrue(terrain.gate.contains("Ice remains static"))
        XCTAssertTrue(terrain.gate.contains("contact shade never substitutes for the wall"))

        let wiki = try XCTUnwrap(board.items.first { $0.id == "game-wiki" })
        XCTAssertEqual(wiki.status, .complete)
        XCTAssertTrue(wiki.detail.contains("all 108 canonical writing lexemes"))
    }

    func testEncounterScalingRecordsAcceptedPhoneEvidenceAndRemainingMatrix() throws {
        let scaling = try XCTUnwrap(DebugRoadmap.current.items.first {
            $0.id == "encounter-scaling"
        })
        XCTAssertEqual(scaling.status, .readyToTest)
        XCTAssertEqual(scaling.workstream, .engineering)
        XCTAssertFalse(scaling.isPrimary)
        XCTAssertTrue(scaling.detail.contains("Source and deterministic matrix closure is complete"))
        XCTAssertTrue(scaling.detail.contains("no known source P0 remains"))
        XCTAssertTrue(scaling.detail.contains("Teeming remains an intentionally overwhelming disclosed profile"))
        XCTAssertTrue(scaling.gate.contains("Nonblocking ordinary-phone acceptance"))
        XCTAssertTrue(scaling.gate.contains("2–4-round/5–20%-HP Normal target"))
        XCTAssertTrue(scaling.gate.contains("does not block Engineering progression"))
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
        XCTAssertEqual(catalogue.questions.count, 12)
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

    func testRetiredQuestionAnswerRemainsInExportHistory() throws {
        let file = FileManager.default.temporaryDirectory
            .appendingPathComponent("homework-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: file) }

        let retired = DesignHomeworkAnswer(
            questionID: "isolde-dialogue-revision",
            choiceID: "approve-exact-set",
            customText: "",
            savedAt: Date(timeIntervalSince1970: 1),
            catalogueUpdated: "12 Aug 2026",
            questionTitle: "Approve Isolde's revised replies?",
            choiceTitle: "Approve exact set"
        )
        let frozenExport = DesignHomeworkExport(
            schemaVersion: 1,
            catalogueUpdated: "12 Aug 2026",
            answers: [retired]
        )
        try JSONEncoder().encode(frozenExport).write(to: file, options: .atomic)

        let store = DesignHomeworkStore(fileURL: file)
        XCTAssertFalse(store.catalogue.questions.contains { $0.id == retired.questionID })
        XCTAssertEqual(store.answer(for: retired.questionID), retired)

        let exportURL = try XCTUnwrap(store.exportURL)
        let exported = try JSONDecoder().decode(
            DesignHomeworkExport.self,
            from: Data(contentsOf: exportURL)
        )
        XCTAssertEqual(exported.answers, [retired])
    }
}
#endif
