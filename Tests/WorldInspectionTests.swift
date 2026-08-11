import XCTest
@testable import Bookbinder

final class WorldInspectionTests: XCTestCase {
    func testLookReportsTheSameSlowGroundCostWithoutMutatingRun() {
        var run = makeRun()
        let target = GridPoint(x: run.playerPosition.x + 1, y: run.playerPosition.y)
        run.map[target].ground = .mud
        run.map[target].isRevealed = true
        let before = run
        let result = WorldRules.inspect(target, in: run)
        XCTAssertTrue(result.text.contains("\(WorldRules.movementCost(.mud, slowGroundExtraTurns: run.tuning.slowGroundExtraTurns)) turns to enter"))
        XCTAssertTrue(result.text.contains("\(run.tuning.slowGroundExtraTurns) extra"))
        XCTAssertEqual(run, before)
    }

    func testLookUsesNeutralEntryConsequencesWithoutFloraTraitNumbers() {
        XCTAssertEqual(WorldRules.floraEntryWarning(.active),
                       "Entering will start an encounter")
        XCTAssertEqual(WorldRules.floraEntryWarning(.physical),
                       "Visible barbs. Entering will hurt the party")
        XCTAssertEqual(WorldRules.floraEntryWarning(.chemical),
                       "Entering carries a lingering hazard")
        for warning in DefenceType.allCases.map(WorldRules.floraEntryWarning) {
            XCTAssertFalse(warning.contains(where: \.isNumber))
        }
    }

    func testLookNeverRevealsFogOrHiddenCrypsis() {
        var run = makeRun()
        let target = GridPoint(x: run.playerPosition.x + 1, y: run.playerPosition.y)
        run.map[target].isRevealed = false
        let before = run
        XCTAssertEqual(WorldRules.inspect(target, in: run).text, "Unclear · You cannot make out that tile.")
        XCTAssertEqual(run, before)
    }

    func testLookDistinguishesBoundaryAndImpassableGround() {
        var run = makeRun()
        let target = GridPoint(x: run.playerPosition.x + 1, y: run.playerPosition.y)
        run.map[target].ground = .deepWater
        run.map[target].isRevealed = true
        XCTAssertTrue(WorldRules.inspect(target, in: run).text.contains("impassable"))
        XCTAssertEqual(WorldRules.inspect(GridPoint(x: -1, y: -1), in: run).heading, "World boundary")
    }

    private func makeRun() -> WorldRun {
        let book = BoundBook(written: [], essencePaid: 0)
        let seed: UInt64 = 81_919
        let generated = Worldgen.generate(book: book, seed: seed)
        return WorldRun(runIndex: 1, book: book, mapSeed: seed,
                        rng: SeededRNG(seed: seed).derived(0xA11CE), map: generated.map,
                        playerPosition: generated.start, enemies: generated.enemies)
    }
}
