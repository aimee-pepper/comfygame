import XCTest
@testable import Bookbinder

/// **Chasms** — Substrate's first word for *less* (Aimee, 7 Aug):
///
/// > *"there should also be a way to spawn a world with chasms as a negative substrate thing (as
/// > long as pathing is still possible, unless they do maximum chasm and they can only walk back out
/// > of the same portal they came in from because it's so full of empty holes)."*
///
/// Three separate claims, checked separately: holes appear, pathing survives them, and at the
/// maximum the entry is the only way out.
final class ChasmTests: XCTestCase {

    private func book(_ intensity: Intensity) -> BoundBook {
        BoundBook(written: [], composition: [
            Sigil(id: InstanceID(rawValue: 1), source: "chasm", target: "substrate", intensity: intensity)
        ], essencePaid: 0)
    }

    private func seeds(_ count: Int) -> [UInt64] {
        (1...count).map { UInt64($0) &* 2_654_435_761 }
    }

    // MARK: Holes appear, and only when asked for

    func testWritingAChasmPutsHolesInTheGround() {
        for seed in seeds(12) {
            let world = Worldgen.generate(book: book(.great), seed: seed)
            let holes = world.map.tiles.count { $0.ground == .chasm }
            XCTAssertGreaterThan(holes, 0, "a chasm world had nowhere to fall")
        }
    }

    /// The gate is the *word*, not the number. Silt is poor ground and Chasm is absent ground, and
    /// both read as a low substrate — only the one that means holes may make them.
    func testPoorGroundIsNotHollowGround() {
        let silt = BoundBook(written: [], composition: [
            Sigil(id: InstanceID(rawValue: 1), source: "silt", target: "substrate", intensity: .overwhelming)
        ], essencePaid: 0)
        for seed in seeds(8) {
            let world = Worldgen.generate(book: silt, seed: seed)
            XCTAssertEqual(world.map.tiles.count { $0.ground == .chasm }, 0,
                           "washed-out ground is not the same as no ground")
        }
    }

    func testWritingOrdinaryGroundDoesNotMakeHoles() {
        let ordinaryGround = BoundBook(written: [], composition: [
            Sigil(id: InstanceID(rawValue: 1), source: "granite", target: "substrate")
        ], essencePaid: 0)
        for seed in seeds(8) {
            let world = Worldgen.generate(book: ordinaryGround, seed: seed)
            XCTAssertEqual(world.map.tiles.count { $0.ground == .chasm }, 0)
        }
    }

    /// More chasm, more hole. Measured on the **demand**, which is the only thing that still moves
    /// once substrate has bottomed out at zero.
    func testAskingHarderOpensMoreOfIt() {
        func coverage(_ intensity: Intensity) -> Double {
            TerrainRules.chasmCoverage(in: PressureRules.resolve([
                Sigil(id: InstanceID(rawValue: 1), source: "chasm", target: "substrate", intensity: intensity)
            ]))
        }
        XCTAssertGreaterThan(coverage(.moderate), coverage(.faint))
        XCTAssertGreaterThan(coverage(.great), coverage(.moderate))
        XCTAssertGreaterThan(coverage(.overwhelming), coverage(.great))
    }

    // MARK: Pathing survives

    /// **"as long as pathing is still possible."** Everything a world contains has to be somewhere
    /// you can walk to — the portals, the nodes, the sites, the pages, the person standing in it.
    func testNothingIsEverPlacedWhereYouCannotWalk() {
        for intensity: Intensity in [.moderate, .great, .overwhelming] {
            for seed in seeds(10) {
                let world = Worldgen.generate(book: book(intensity), seed: seed, library: LibraryState())
                let walkable = TerrainRules.reachable(from: world.start, in: world.map)

                for point in world.map.allPoints where world.map[point].content != .empty {
                    XCTAssertTrue(walkable.contains(point),
                                  "\(world.map[point].content) at \(point) is cut off (\(intensity), seed \(seed))")
                }
                for enemy in world.enemies {
                    XCTAssertTrue(walkable.contains(enemy.position), "an enemy was stranded")
                }
            }
        }
    }

    /// And the world you arrive in must still be a world, rather than the corner of one.
    func testMostOfTheSolidGroundIsStillWalkableTo() {
        for intensity: Intensity in [.moderate, .great, .overwhelming] {
            for seed in seeds(10) {
                let world = Worldgen.generate(book: book(intensity), seed: seed)
                let solid = world.map.allPoints.count { world.map[$0].isPassable }
                let walkable = TerrainRules.reachable(from: world.start, in: world.map).count
                XCTAssertGreaterThan(Double(walkable) / Double(solid), 0.5,
                                     "arriving in \(walkable) of \(solid) squares isn't a world (seed \(seed))")
            }
        }
    }

    // MARK: The maximum

    /// **"they can only walk back out of the same portal they came in from."**
    func testAMaximumChasmWorldHasOnlyTheWayYouCameIn() {
        var riven = 0
        for seed in seeds(12) {
            let world = Worldgen.generate(book: book(.overwhelming), seed: seed)
            let exits = world.map.tiles.count { $0.content == .portal(isEntry: false) }
            XCTAssertEqual(exits, 0, "a riven world offered a way out other than the way in")
            XCTAssertEqual(world.map[world.start].content, .portal(isEntry: true),
                           "…and the way in must still be there, or it's a trap rather than a price")
            riven += 1
        }
        XCTAssertEqual(riven, 12)
    }

    /// It has to be the *maximum* that costs you the exit, or the price arrives without warning.
    func testAWorldWithSomeHolesStillHasAWayOut() {
        for seed in seeds(12) {
            let world = Worldgen.generate(book: book(.moderate), seed: seed)
            XCTAssertGreaterThan(world.map.tiles.count { $0.content.isPortal }, 1,
                                 "a moderately broken world lost its exit (seed \(seed))")
        }
    }

    /// A world doesn't get holes in it silently.
    func testTheWorldSaysThereAreHolesInIt() {
        let broken = DescriptionRules.describe(page: [
            Sigil(id: InstanceID(rawValue: 1), source: "chasm", target: "substrate", intensity: .moderate)
        ])
        XCTAssertTrue(broken.clauses.contains { $0.id == "broken_ground" || $0.id == "riven_ground" },
                      "a broken world said nothing about its ground: \(broken.sentence)")

        let riven = DescriptionRules.describe(page: [
            Sigil(id: InstanceID(rawValue: 1), source: "chasm", target: "substrate", intensity: .overwhelming)
        ])
        XCTAssertTrue(riven.clauses.contains { $0.id == "riven_ground" },
                      "a riven world didn't warn you the way out was the way in: \(riven.sentence)")
    }

    /// Stillness is Cycle's first word for less, and it has to be readable too.
    func testAStoppedWorldSaysSo() {
        let stopped = DescriptionRules.describe(page: [
            Sigil(id: InstanceID(rawValue: 1), source: "stillness", target: "cycle", intensity: .great)
        ])
        XCTAssertTrue(stopped.clauses.contains { $0.id == "stopped_clock" },
                      "a world where nothing turns didn't mention it: \(stopped.sentence)")
    }

    // MARK: The meter

    /// Asking for less ground is asking for less, so it calms a world — the other half of the
    /// two-axis model, and the reason a broken world is worth writing at all.
    func testHollowGroundCalmsAWorld() {
        let ordinary = BookRules.stabilityScore(of: BoundBook(symbols: [:], randomlyFilled: [], essencePaid: 0))
        XCTAssertGreaterThanOrEqual(BookRules.stabilityScore(of: book(.great)), ordinary)
        XCTAssertGreaterThan(BookRules.greedDelta(for: BookRules.sigils(for: book(.great))), 0)
    }
}
