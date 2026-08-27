import XCTest
@testable import Bookbinder

/// `[qualifier] [kind]`, derived from traits (name-generation-spec).
final class NamingTests: XCTestCase {

    // MARK: Distinctiveness is relative to the world

    /// **On a world where everything is armoured, "armoured" says nothing.** The same creature is
    /// named differently in two worlds, which is correct: distinctiveness is relative.
    func testTheSameAnimalIsNamedDifferentlyInDifferentWorlds() {
        var armoured = CreatureTraits()
        armoured.size = 40
        armoured.covering = Covering(hardness: 85, length: 10, coverage: 80)

        // A world of soft things: what stands out about it is the armour.
        var soft = CreatureTraits()
        soft.size = 40
        soft.covering = Covering(hardness: 5, length: 10, coverage: 80)
        let amongSoft = Naming.Context(of: [armoured, soft, soft, soft])

        // A world of armoured things: the armour is unremarkable, so something else has to be said.
        var bigger = armoured
        bigger.size = 85
        let amongArmoured = Naming.Context(of: [armoured, bigger, bigger, bigger])

        let first = Naming.qualifier(for: armoured, in: amongSoft)
        let second = Naming.qualifier(for: armoured, in: amongArmoured)
        XCTAssertNotNil(first)
        XCTAssertNotEqual(first, second,
                          "the same animal got the same name in a world that made it ordinary")
        XCTAssertTrue(["scaled", "carapaced", "ironbound"].contains(first ?? ""), first ?? "nil")
    }

    /// A thoroughly average member of its own world has nothing worth saying about it.
    func testSomethingUnremarkableForItsWorldGetsNoQualifier() {
        var ordinary = CreatureTraits()
        ordinary.size = 50
        ordinary.covering = Covering(hardness: 40, length: 40, coverage: 40)
        let context = Naming.Context(of: [ordinary, ordinary, ordinary])
        XCTAssertNil(Naming.qualifier(for: ordinary, in: context))
    }

    /// Further out earns a stronger word — a slightly big thing is *great*, a giant is *monstrous*.
    func testBeingFurtherOutEarnsAStrongerWord() {
        var large = ordinary(); large.size = 62
        var vast = ordinary(); vast.size = 99

        XCTAssertEqual(Naming.qualifier(for: large, in: .none), "great")
        XCTAssertEqual(Naming.qualifier(for: vast, in: .none), "monstrous")
    }

    /// Unremarkable on every axis, so anything set on top of it is the only thing worth saying.
    private func ordinary() -> CreatureTraits {
        var traits = CreatureTraits()
        traits.size = 50
        traits.build = 50
        traits.boneDensity = 50
        traits.ornament = 50
        traits.covering = Covering(hardness: 50, length: 50, coverage: 50)
        traits.armament.setTotal(50)
        traits.armament.reach = .mid
        traits.coloration.depth = 50
        traits.coloration.patterning = 50
        traits.sensory = Sensory.allocation(vision: 50, mechano: 20, chemo: 20, thermo: 10)
        return traits
    }

    // MARK: Collisions

    /// **Never number them.** A world with two shaggy browsers gets a shaggy browser and a pale one.
    func testTwoAnimalsInAWorldNeverShareAName() {
        var rng = SeededRNG(seed: 20_260_805)
        var cast: [Species] = []
        for index in 0..<5 {
            var traits = CreatureTraits()
            traits.size = 45 + Double(index)              // nearly identical on purpose
            traits.covering = Covering(hardness: 70, length: 60, coverage: 70)
            traits.boneDensity = 40 + rng.double(in: -3...3)
            cast.append(Species(id: InstanceID(rawValue: UInt64(index + 1)),
                                traits: traits, worldSeed: 1))
        }

        let names = CreatureIdentity.names(for: cast)
        XCTAssertEqual(names.count, cast.count)
        let qualifiers = names.values.compactMap(\.qualifier)
        XCTAssertEqual(Set(qualifiers).count, qualifiers.count,
                       "two of a world's animals ended up with the same adjective: \(qualifiers)")
        XCTAssertFalse(names.values.contains { $0.name.contains("2") }, "something got numbered")
    }

    /// A name must never change under a player, so it can't depend on iteration order.
    func testNamingAWorldTwiceGivesTheSameNames() {
        let readings = PressureRules.resolve([], fillingUnwrittenWith: 4242)
        let cast = LifeRules.cast(for: readings, seed: 4242)
        XCTAssertEqual(CreatureIdentity.names(for: cast).mapValues(\.name),
                       CreatureIdentity.names(for: cast).mapValues(\.name))
    }

    // MARK: The shape of a name

    func testANameIsAnAdjectiveAndANoun() {
        var tank = CreatureTraits()
        tank.size = 85
        tank.covering = Covering(hardness: 80, length: 20, coverage: 80)

        let match = CreatureIdentity.match(tank, in: .none)
        XCTAssertEqual(match.region, .tank)
        XCTAssertNotNil(match.qualifier)
        XCTAssertEqual(match.name, "\(match.qualifier!) tank")
    }

    /// **The fallback must never be a bare "creature".** Anything unmatched is described.
    func testNothingIsEverJustCalledCreature() {
        var rng = SeededRNG(seed: 3)
        for _ in 0..<300 {
            var traits = CreatureTraits()
            for axis in CostlyAxis.allCases { traits[axis] = rng.double(in: 0...100) }
            traits.build = rng.double(in: 0...100)
            traits.appendages = Appendages(count: rng.int(in: 0...8),
                                           type: rng.pick(AppendageType.allCases)!)
            let name = CreatureIdentity.match(traits, in: .none).name
            XCTAssertNotEqual(name, "creature")
            XCTAssertNotEqual(name, "thing")
            XCTAssertGreaterThanOrEqual(name.split(separator: " ").count, 2, name)
        }
    }

    // MARK: Materials inherit the name

    /// **A pelt off a shaggy browser is a shaggy pelt.** That inheritance is what makes loot read as
    /// coming from somewhere.
    func testAMaterialCarriesTheNameOfWhatItCameOff() throws {
        var shaggy = CreatureTraits()
        shaggy.size = 55
        shaggy.covering = Covering(hardness: 10, length: 90, coverage: 85)

        let match = CreatureIdentity.match(shaggy, in: .none)
        let qualifier = try XCTUnwrap(match.qualifier)
        let samples = ButcheryRules.materials(from: shaggy, named: match.name, qualifier: qualifier)
        let pelt = try XCTUnwrap(samples.first { $0.kind == .pelt })

        XCTAssertEqual(pelt.qualifier, qualifier)
        XCTAssertTrue(pelt.displayName.lowercased().contains(qualifier), pelt.displayName)
    }

    /// `[grade] [qualifier] [kind]` — and an ordinary one needs no grade word.
    func testAMaterialsNameReadsAsGradeQualifierKind() {
        let superb = CraftMaterialUnitV1(kind: .plate, properties: MaterialProperties(hardness: 90),
                                    grade: 80, source: "x", qualifier: "ironbound")
        XCTAssertEqual(superb.displayName, "Superb ironbound plate")

        let plain = CraftMaterialUnitV1(kind: .hide, properties: MaterialProperties(),
                                   grade: 40, source: "x", qualifier: "pale")
        XCTAssertEqual(plain.displayName, "Pale hide")

        let bare = CraftMaterialUnitV1(kind: .bone, properties: MaterialProperties(), grade: 40,
                                  source: "x")
        XCTAssertEqual(bare.displayName, "Bone")
    }

    func testAMaterialWithNoQualifierStillLoads() throws {
        let json = """
        {"kind": "pelt", "grade": 60, "source": "browser"}
        """
        let sample = try SaveCodec.makeDecoder().decode(CraftMaterialUnitV1.self, from: Data(json.utf8))
        XCTAssertNil(sample.qualifier)
        XCTAssertEqual(sample.displayName, "Fine pelt")
    }

    // MARK: It reaches the player

    /// A world's animals arrive already named against their own world.
    func testAWorldsAnimalsAreNamedAgainstTheirOwnWorld() {
        let world = Worldgen.generate(book: BoundBook(written: ["teeming_life"], essencePaid: 0),
                                      seed: 909)
        let run = WorldRun(runIndex: 1, book: BoundBook(written: ["teeming_life"], essencePaid: 0),
                           mapSeed: 909, rng: SeededRNG(seed: 1), map: world.map,
                           playerPosition: world.start, enemies: world.enemies, cast: world.cast)

        for enemy in run.enemies {
            let name = run.name(of: enemy)
            XCTAssertFalse(name.isEmpty)
            XCTAssertFalse(name.hasPrefix(" "), name)
        }

        // Every species in the world goes by a different name, whatever else it shares.
        let names = run.cast.map { run.castNames[$0.id]?.name ?? "" }
        XCTAssertEqual(Set(names).count, names.count, "two of this world's animals share a name: \(names)")
    }
}
