#if DEBUG
import XCTest
@testable import Bookbinder

final class DebugRoadmapTests: XCTestCase {
    func testBundledRoadmapIsTheSingleReadableCurrentBoard() {
        let board = DebugRoadmap.current
        XCTAssertEqual(board.schemaVersion, 1)
        XCTAssertFalse(board.updated.isEmpty)
        XCTAssertFalse(board.currentWork.isEmpty)
        XCTAssertFalse(board.items.isEmpty)
        XCTAssertEqual(Set(board.items.map(\.id)).count, board.items.count,
                       "roadmap item IDs must remain stable and unique")
        XCTAssertEqual(board.items.filter { $0.status == .inProgress }.count, 1,
                       "the operational board must identify exactly one active checkpoint")
    }

    func testCompletedBlockersCannotRegressToQueuedInTheCurrentBoard() throws {
        let byID = Dictionary(uniqueKeysWithValues: DebugRoadmap.current.items.map { ($0.id, $0) })
        for id in ["outcome", "trading-post", "vance", "terrain"] {
            XCTAssertEqual(try XCTUnwrap(byID[id]).status, .complete, "\(id) is already installed")
        }
    }
}

@MainActor
final class DesignHomeworkTests: XCTestCase {
    func testBundledQuestionsAndChoicesHaveStableUniqueIDs() {
        let catalogue = DesignHomeworkCatalogue.current
        XCTAssertEqual(catalogue.schemaVersion, 1)
        XCTAssertEqual(catalogue.questions.count, 19)
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
