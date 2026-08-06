import XCTest
@testable import Bookbinder

/// Creatures from trait distributions (decisions-session-15, generation-spine §3).
final class LifeTests: XCTestCase {

    // MARK: Cast and jitter

    /// **Vitality sets cast size, not spread.** A rich world holds more species; it does not hold
    /// stranger ones. Abundance and strangeness stay independent knobs.
    func testARicherWorldHoldsMoreSpeciesButNotStrangerOnes() {
        let lush = world(["bloom": "vitality", "root": "vitality", "sun": "illumination"])
        let bare = world(["salt": "hydrology", "void": "illumination"])

        XCTAssertGreaterThan(LifeRules.castSize(for: lush), LifeRules.castSize(for: bare),
                             "a teeming world held no more species than a barren one")
        XCTAssertEqual(LifeRules.distribution(from: lush).spread,
                       LifeRules.distribution(from: bare).spread, accuracy: 0.001,
                       "vitality widened the spread — abundance and strangeness collapsed into one knob")
    }

    func testEveryWorldHoldsSomething() {
        for seed in UInt64(1)...40 {
            XCTAssertFalse(LifeRules.cast(for: world([:], seed: seed), seed: seed).isEmpty,
                           "seed \(seed) produced a world with nothing alive in it")
        }
    }

    func testTheCastStaysSmall() {
        // Free sampling is only safe because the cast is small — a strange animal should be the one
        // you remember from that world, not one of fifty.
        for seed in UInt64(1)...30 {
            let count = LifeRules.cast(for: world([:], seed: seed), seed: seed).count
            XCTAssertLessThanOrEqual(count, Tuning.Life.castSizeRange.upperBound)
        }
    }

    /// **An anchored world keeps its cast forever.** The same animals live there; you learn them.
    func testTheSameWorldAlwaysHoldsTheSameSpecies() {
        let readings = world(["bloom": "vitality"])
        let first = LifeRules.cast(for: readings, seed: 20_260_805)
        let again = LifeRules.cast(for: readings, seed: 20_260_805)
        XCTAssertEqual(first, again)
        XCTAssertNotEqual(first.map(\.traits), LifeRules.cast(for: readings, seed: 99).map(\.traits))
    }

    /// Jitter is deliberately small: each animal is visibly its own, never enough to change what it
    /// is or how it fights.
    func testAnIndividualVariesFromItsSpeciesButNotMuch() {
        let species = LifeRules.cast(for: world(["bloom": "vitality"]), seed: 4242)[0]
        var rng = SeededRNG(seed: 7)
        var seenIdentity = Set<String>()
        for _ in 0..<40 {
            let spawn = LifeRules.spawn(of: species, rng: &rng)
            XCTAssertLessThanOrEqual(abs(spawn.armament - species.traits.armament),
                                     Tuning.Life.jitter * 0.4 + 0.001,
                                     "jitter changed how hard it hits")
            seenIdentity.insert(CreatureIdentity.name(for: spawn))
        }
        XCTAssertLessThanOrEqual(seenIdentity.count, 2, "jitter changed what the animal is")
    }

    // MARK: Pressures shape the animals

    /// Cold shortens extremities — the one thermal effect that isn't confounded by wealth.
    ///
    /// **Size deliberately isn't asserted here.** Cold nudges size up, but cold worlds are also
    /// *poor* worlds (cold caps what can grow, and productivity pays for size), and poverty is the
    /// stronger of the two. So a cold world's animals usually come out *smaller*, not bigger, which
    /// may be right — Bergmann's rule is about warm-blooded animals in otherwise liveable places —
    /// or may mean the thermal nudge is too weak against the vitality term. Flagged as Q25 rather
    /// than papered over with a test that picks convenient worlds.
    func testColdShortensExtremities() {
        let warmth = ["sun": "illumination", "bloom": "vitality"]
        let cold = LifeRules.distribution(from: world(warmth.merging(["glacier": "thermal"]) { a, _ in a })).centre
        let hot = LifeRules.distribution(from: world(warmth.merging(["magma": "thermal"]) { a, _ in a })).centre
        XCTAssertLessThan(cold.reach, hot.reach, "cold didn't shorten extremities")
        XCTAssertGreaterThan(cold.covering, hot.covering, "cold didn't put anything on its back")
    }

    func testDarkWorldsGiveUpOnEyes() {
        let dark = LifeRules.distribution(from: world(["void": "illumination"])).centre
        let dim = LifeRules.distribution(from: world(["moon": "illumination"])).centre
        XCTAssertLessThan(dark.vision, dim.vision, "the dark grew better eyes than the dusk")
        XCTAssertGreaterThan(dark.nonVisualSense, dark.vision)
    }

    func testEnclosedCountryMakesAmbushersAndOpenGroundMakesCoursers() {
        let enclosed = LifeRules.distribution(from: world(["canopy": "vitality", "granite": "substrate"])).centre
        let open = LifeRules.distribution(from: world(["sand": "substrate", "wind": "atmosphere"])).centre
        XCTAssertLessThan(enclosed.conspicuousness, open.conspicuousness, "nothing learned to hide")
        XCTAssertGreaterThan(open.reach, enclosed.reach)
    }

    func testStoneInTheGroundBecomesStoneOnTheAnimal() {
        let mineral = LifeRules.distribution(from: world(["gold": "substrate", "crystal": "substrate"])).centre
        let soft = LifeRules.distribution(from: world(["rain": "hydrology"])).centre
        XCTAssertGreaterThan(mineral.coveringHardness, soft.coveringHardness)
    }

    /// A world that swings breeds generalists and widens everything.
    func testASwingingWorldProducesMoreVariedAnimals() {
        var restless = world(["rift": "cycle"])
        var still = world(["stars": "illumination"])
        restless.readings["cycle"]?.aspects["amplitude"] = 90
        still.readings["cycle"]?.aspects["amplitude"] = 10
        XCTAssertGreaterThan(LifeRules.distribution(from: restless).spread,
                             LifeRules.distribution(from: still).spread)
    }

    // MARK: Identity is derived

    func testWhatAnAnimalIsIsReadOffItRatherThanAssignedToIt() {
        var ambusher = CreatureTraits()
        ambusher.armament = 80
        ambusher.conspicuousness = 20
        XCTAssertEqual(CreatureIdentity.name(for: ambusher), "ambusher")

        var lantern = CreatureTraits()
        lantern.emanation = 80
        XCTAssertEqual(CreatureIdentity.name(for: lantern), "lantern")

        // Everything resolves to something. A world that made nothing that hunts simply has no
        // hunters in it — no role is handed out in advance.
        var rng = SeededRNG(seed: 3)
        for _ in 0..<200 {
            var t = CreatureTraits()
            t.size = rng.double(in: 0...100); t.armament = rng.double(in: 0...100)
            t.conspicuousness = rng.double(in: 0...100); t.emanation = rng.double(in: 0...100)
            XCTAssertFalse(CreatureIdentity.name(for: t).isEmpty)
        }
    }

    func testAWorldWithNoHuntersSimplyHasNone() {
        // Barren worlds can't afford armament, so nothing in them hunts. That's the point of
        // deriving identity rather than assigning it.
        let barren = world(["salt": "hydrology", "void": "illumination"])
        let names = LifeRules.cast(for: barren, seed: 11).map(\.identity)
        XCTAssertFalse(names.contains("courser"), "a dead world produced a pursuit predator")
    }

    // MARK: The budget

    func testNoWorldProducesAnEverythingCreature() {
        for seed in UInt64(1)...40 {
            let readings = world([:], seed: seed)
            let budget = WorldConstraints.energyBudget(in: readings)
            for species in LifeRules.cast(for: readings, seed: seed) where budget > 0 {
                XCTAssertLessThanOrEqual(species.traits.appetite, budget + 0.001,
                                         "a world fed something it couldn't afford, seed \(seed)")
            }
        }
    }

    func testTraitsRoundTripThroughASave() throws {
        let species = LifeRules.cast(for: world(["bloom": "vitality"]), seed: 5)[0]
        let data = try SaveCodec.makeEncoder().encode(species)
        XCTAssertEqual(try SaveCodec.makeDecoder().decode(Species.self, from: data), species)
    }

    // MARK: Helpers

    private func world(_ pairs: [String: String], seed: UInt64 = 20_260_805) -> PressureReadings {
        PressureRules.resolve(pairs.sorted { $0.key < $1.key }.enumerated().map { index, pair in
            Sigil(id: InstanceID(rawValue: UInt64(index + 1)),
                  source: PressureSourceID(rawValue: pair.key),
                  target: PressureTargetID(rawValue: pair.value),
                  intensity: .great)
        }, fillingUnwrittenWith: seed)
    }
}
