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
#endif
