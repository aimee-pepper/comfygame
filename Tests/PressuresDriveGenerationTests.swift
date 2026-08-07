import XCTest
@testable import Bookbinder

/// The gap `audit-what-pressures-actually-do.md` found: the eight targets described worlds they did
/// not generate. A world could read *"frozen over, barren, nothing keeps time"* while its spawns
/// came from a symbol's flat table.
///
/// These tests exist so that can't quietly come back.
final class PressuresDriveGenerationTests: XCTestCase {

    // MARK: What the ground is made of

    func testARichSubstrateWorldHoldsMoreOreThanABarrenOne() {
        let rich = readings(["gold": "substrate", "iron": "substrate"])
        let bare = readings(["sun": "illumination"])

        XCTAssertGreaterThan(weight(of: "ore", in: rich), weight(of: "ore", in: bare),
                             "what the ground is made of didn't decide what's in it")
    }

    func testAWorldWithNoLifeInItGrowsNoFiber() {
        let sterile = readings(["void": "illumination", "salt": "hydrology"])
        XCTAssertEqual(weight(of: "fiber", in: sterile), 0,
                       "fiber grew somewhere nothing lives")
    }

    func testMotesOnlyTurnUpWhereTheGroundIsWorthSomething() throws {
        // Motes are Reality currency, so they're deliberately not in the ordinary yield table —
        // the abundance rule is what's under test here.
        let mote = try XCTUnwrap(ContentCatalog.shared.resource("mote"))
        XCTAssertEqual(mote.abundance(in: readings(["granite": "substrate"])), 0,
                       "motes turned up in ordinary rock")
        XCTAssertGreaterThan(mote.abundance(in: readings(["gold": "substrate", "crystal": "substrate"])), 0)
    }

    /// Dispersion is specced as concentrated ↔ pervasive and has to reach the map, or it's a word.
    func testDispersionDecidesWhetherThingsAreSpreadOrGathered() {
        var rng = SeededRNG(seed: 42)
        var other = SeededRNG(seed: 42)
        let pervasive = Worldgen.nodeCount(for: readings(["sand": "substrate", "rain": "hydrology"]), rng: &rng)
        let concentrated = Worldgen.nodeCount(for: readings(["gold": "substrate"]), rng: &other)
        XCTAssertNotEqual(pervasive, concentrated,
                          "dispersion made no difference to how much is lying about")
    }

    // MARK: Who lives here

    func testAWorldTooPoorToFeedAnythingCannotAffordTheExpensiveThings() {
        let poor = lived(["void": "illumination", "thin_air": "atmosphere"])
        let lush = lived(["bloom": "vitality", "root": "vitality", "sun": "illumination"])

        let poorAppetite = BookRules.enemyTable(from: poor).map(\.value.appetite).max() ?? 0
        let lushAppetite = BookRules.enemyTable(from: lush).map(\.value.appetite).max() ?? 0
        XCTAssertLessThanOrEqual(poorAppetite, lushAppetite,
                                 "a barren world fed something a rich one couldn't")
    }

    func testAWorldAlwaysHoldsSomething() {
        // Empty for reasons the player can't see is worse than sparse.
        for seed in UInt64(1)...30 {
            let table = BookRules.enemyTable(from: PressureRules.resolve([], fillingUnwrittenWith: seed))
            XCTAssertFalse(table.isEmpty, "seed \(seed) produced a world with nothing alive in it")
        }
    }

    func testTheRosterFollowsTheWorldRatherThanTheSymbol() {
        // **Bare resolves now**, which is what moving the floor to ordinary bought: this used to
        // need the chance fill, because a page that said nothing left illumination at zero and the
        // life caps correctly emptied the world. An unwritten subject sits at ordinary now, so the
        // two worlds differ by exactly the thing under test — and the assertion stops sampling the
        // dice, which was making it fail whenever a roll put a moon in the dark world.
        let dark = readings(["void": "illumination"])
        let bright = readings(["sun": "illumination"])
        func share(_ id: CreatureID, _ r: PressureReadings) -> Double {
            let table = BookRules.enemyTable(from: r)
            let total = table.reduce(0) { $0 + $1.weight }
            guard total > 0 else { return 0 }
            return (table.first { $0.value.id == id }?.weight ?? 0) / total
        }
        XCTAssertGreaterThan(share("margin_wraith", dark), share("margin_wraith", bright),
                             "the thing that likes the dark was no likelier in the dark")
    }

    /// Openness sets ambush versus pursuit — specced from the beginning, doing nothing until now.
    func testThingsSeeYouFurtherAcrossOpenGround() throws {
        let open = readings(["sand": "relief", "wind": "relief"])
        let enclosed = readings(["canopy": "relief", "granite": "relief"])
        let hound = try XCTUnwrap(ContentCatalog.shared.creature("ink_hound"))

        XCTAssertTrue(WorldConstraints.character(of: open).contains("pursuit"))
        XCTAssertTrue(WorldConstraints.character(of: enclosed).contains("ambush"))
        XCTAssertGreaterThan(BookRules.sightRadius(of: hound, in: open),
                             BookRules.sightRadius(of: hound, in: enclosed))
    }

    // MARK: The old parallel system is no longer what generates a world

    func testGenerationDoesNotConsultTheLegacySymbolTables() {
        // Two books with identical pressures but different legacy `yieldModifiers` must produce the
        // same yield table — if they don't, the flat per-symbol tables are still driving.
        let readings = PressureRules.resolve([])
        let table = BookRules.yieldTable(from: readings)
        XCTAssertFalse(table.isEmpty)
        for entry in table {
            XCTAssertGreaterThan(entry.weight, 0)
        }
    }

    // MARK: Helpers

    private func readings(_ pairs: [String: String]) -> PressureReadings {
        PressureRules.resolve(pairs.sorted { $0.key < $1.key }.enumerated().map { index, pair in
            Sigil(id: InstanceID(rawValue: UInt64(index + 1)),
                  source: PressureSourceID(rawValue: pair.key),
                  target: PressureTargetID(rawValue: pair.value),
                  intensity: .great)
        })
    }

    /// A world the way binding actually makes one: what the page says, and the world's own answer
    /// for everything it didn't.
    private func lived(_ pairs: [String: String], seed: UInt64 = 20_260_805) -> PressureReadings {
        PressureRules.resolve(pairs.sorted { $0.key < $1.key }.enumerated().map { index, pair in
            Sigil(id: InstanceID(rawValue: UInt64(index + 1)),
                  source: PressureSourceID(rawValue: pair.key),
                  target: PressureTargetID(rawValue: pair.value),
                  intensity: .great)
        }, fillingUnwrittenWith: seed)
    }

    private func weight(of resource: ResourceID, in readings: PressureReadings) -> Double {
        BookRules.yieldTable(from: readings).first { $0.value == resource }?.weight ?? 0
    }
}
