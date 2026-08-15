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
                       "Entering will hurt the party")
        XCTAssertEqual(WorldRules.floraEntryWarning(.chemical),
                       "Entering carries a lingering hazard")
        for warning in DefenceType.allCases.map(WorldRules.floraEntryWarning) {
            XCTAssertFalse(warning.contains(where: \.isNumber))
        }
    }

    func testWayfarersTableAddsExactDerivedFloraFieldNoteWithoutChangingConsequences() throws {
        let target = GridPoint(x: 1, y: 0)
        for (index, defence) in DefenceType.allCases.enumerated() {
            var run = makeRun()
            var traits = FloraTraits()
            traits.tissue.woody = defence == .physical ? 10 : 1
            traits.tissue.fibrous = defence == .active ? 10 : 1
            traits.tissue.fleshy = defence == .chemical ? 10 : 1
            traits.stature = defence == .physical ? 80 : 20
            traits.defence = 100
            traits.defenceType = defence
            let plant = Flora(id: InstanceID(rawValue: UInt64(900 + index)),
                              traits: traits, worldSeed: run.mapSeed)
            run.flora = [plant]
            run.map[target].flora = plant.id
            run.map[target].isRevealed = true
            let before = run

            let without = WorldRules.inspect(target, in: run)
            var base = BaseState()
            base.stations[Stations.wayfarersTable] = StationState(isUnlocked: true, tier: 0)
            let with = WorldRules.inspect(target, in: run, base: base)
            let expectedName = run.floraNames[plant.id]?.name ?? plant.displayName
            let expectedYield = try XCTUnwrap(ContentCatalog.shared.resource(
                FloraRules.yield(of: traits))).name

            XCTAssertFalse(without.text.contains(expectedName))
            XCTAssertFalse(without.text.contains("Sela's field note"))
            XCTAssertTrue(with.text.contains(WorldRules.floraEntryWarning(defence)))
            XCTAssertTrue(with.text.contains("Sela's field note · \(expectedName)"))
            XCTAssertTrue(with.text.contains("yields \(expectedYield)"))
            XCTAssertEqual(run, before, "recognition must remain a zero-state Look")
            XCTAssertFalse(WorldRules.floraFieldNote(for: plant, in: run)
                .contains(String(FloraRules.harvestQuantity(of: traits))))
        }
    }

    func testHiddenFloraNeverProducesFieldNoteAndStationSurvivesRelaunch() throws {
        var run = makeRun()
        let target = GridPoint(x: 1, y: 0)
        let plant = Flora(id: InstanceID(rawValue: 999), traits: FloraTraits(), worldSeed: run.mapSeed)
        run.flora = [plant]
        run.map[target].flora = plant.id
        run.map[target].isRevealed = false
        var state = GameState.newGame()
        state.base.stations[Stations.wayfarersTable] = StationState(isUnlocked: true, tier: 0)
        let decoded = try SaveCodec.makeDecoder().decode(
            GameState.self, from: SaveCodec.makeEncoder().encode(state))

        XCTAssertTrue(decoded.base.station(Stations.wayfarersTable).isUnlocked)
        XCTAssertFalse(WorldRules.inspect(target, in: run, base: decoded.base).text
            .contains("Sela's field note"))
    }

    func testFieldNoteYieldCoversEveryCurrentFloraYieldBranch() {
        var vectors: [FloraTraits] = []
        func plant(woody: Double, fibrous: Double, fleshy: Double,
                   stature: Double = 20) -> FloraTraits {
            var traits = FloraTraits()
            traits.tissue.woody = woody
            traits.tissue.fibrous = fibrous
            traits.tissue.fleshy = fleshy
            traits.stature = stature
            return traits
        }
        vectors.append(plant(woody: 10, fibrous: 1, fleshy: 1, stature: 80))
        vectors.append(plant(woody: 1, fibrous: 10, fleshy: 1))
        vectors.append(plant(woody: 1, fibrous: 1, fleshy: 10))
        var toxic = vectors[0]; toxic.defence = 100; toxic.defenceType = .chemical; vectors.append(toxic)
        var reagent = vectors[2]; reagent.metabolism = .chemosynthetic; vectors.append(reagent)
        var spores = vectors[2]; spores.metabolism = .fungal; vectors.append(spores)

        var run = makeRun()
        for (index, traits) in vectors.enumerated() {
            let flora = Flora(id: InstanceID(rawValue: UInt64(1_100 + index)),
                              traits: traits, worldSeed: run.mapSeed)
            run.flora = [flora]
            let resource = FloraRules.yield(of: traits)
            let name = ContentCatalog.shared.resource(resource)?.name ?? resource.rawValue.capitalized
            XCTAssertTrue(WorldRules.floraFieldNote(for: flora, in: run).hasSuffix("yields \(name)"))
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
