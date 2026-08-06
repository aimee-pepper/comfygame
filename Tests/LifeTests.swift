import XCTest
@testable import Bookbinder

/// Creatures from budget allocation (creature-system-spec, decisions-session-15).
final class LifeTests: XCTestCase {

    // MARK: - The budget is the mechanism

    /// **No world produces an everything-creature.** The budget is the whole reason: a world pushing
    /// both size and armour cannot have both maxed.
    func testNothingCostsMoreThanTheWorldCanFeed() {
        for seed in UInt64(1)...60 {
            let readings = world([:], seed: seed)
            let budget = WorldTendencies(readings: readings).budget
            for species in LifeRules.cast(for: readings, seed: seed) {
                XCTAssertLessThanOrEqual(species.traits.appetite, budget + 0.001,
                                         "seed \(seed) fed something it couldn't afford")
            }
        }
    }

    /// Superlinear cost is what makes extremes rare. The last five points of an axis must cost
    /// dramatically more than the first five, or every creature maxes everything it's pushed toward.
    func testExtremesAreExpensive() {
        var low = CreatureTraits()
        var high = CreatureTraits()
        high.size = 90
        let first = LifeCost.marginal(.size, to: 5, in: low)
        let last = LifeCost.marginal(.size, to: 95, in: high)
        XCTAssertGreaterThan(last, first * 3, "the cost curve is nearly linear — extremes are cheap")
        low.size = 5
        XCTAssertEqual(low.appetite, first, accuracy: 0.001)
    }

    /// **[PROPOSAL] spec §4** — size raises the price of covering and bone, so large armoured things
    /// are genuinely rare rather than merely uncommon.
    func testGrowingBigRepricesTheArmourYouAlreadyWear() {
        var small = CreatureTraits()
        small.covering = Covering(hardness: 60, length: 20, coverage: 60)
        var large = small
        large.size = 90
        XCTAssertGreaterThan(LifeCost.totalCost(of: large) - LifeCost.price(of: .size, at: 90, size: 90),
                             LifeCost.totalCost(of: small),
                             "armour cost the same on a huge animal as on a tiny one")
    }

    /// Spend must telescope exactly to what the vector says it cost, or "appetite" is a fiction.
    func testWhatWasSpentIsWhatItCost() {
        var rng = SeededRNG(seed: 99)
        var traits = CreatureTraits()
        let weights = Dictionary(uniqueKeysWithValues: CostlyAxis.allCases.map { ($0, 1.0) })
        LifeRules.allocate(400, across: weights, into: &traits, rng: &rng)
        XCTAssertLessThanOrEqual(traits.appetite, 400.001)
        XCTAssertGreaterThan(traits.appetite, 0, "a budget of 400 bought nothing")
    }

    // MARK: - Cast and jitter

    /// **Vitality changes how many species, never how strange they are** (session 15 §2).
    /// Abundance and strangeness stay independent knobs, so you can write a teeming ordinary world
    /// or a sparse bizarre one and have them be different places.
    func testARicherWorldHoldsMoreSpeciesDrawnTheSameWay() {
        let poor = world([:], vitality: 10)
        let rich = world([:], vitality: 95)

        XCTAssertGreaterThan(LifeRules.castSize(for: rich), LifeRules.castSize(for: poor))
        XCTAssertGreaterThan(WorldTendencies(readings: rich).budget,
                             WorldTendencies(readings: poor).budget)

        // The *shape* of the draw must not change with wealth. Ornament is the one axis the spec
        // ties to Vitality directly (costly signalling is only affordable when there's slack), and
        // the weapon axes move with trophic depth, so the comparison is normalised over the rest.
        let body: [CostlyAxis] = [.size, .coveringHardness, .coveringLength, .coveringCoverage, .boneDensity]
        let shapePoor = normalisedWeights(poor, over: body), shapeRich = normalisedWeights(rich, over: body)
        for axis in body {
            XCTAssertEqual(shapePoor[axis] ?? 0, shapeRich[axis] ?? 0, accuracy: 0.001,
                           "wealth changed what \(axis.rawValue) worlds tend to build, not just how much")
        }
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
            XCTAssertGreaterThanOrEqual(count, Tuning.Life.castSizeRange.lowerBound)
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

    /// **Jitter must never change identity, combat behaviour, or which materials drop** (spec §5).
    func testAnIndividualVariesFromItsSpeciesButNotInAnythingThatMatters() {
        let species = LifeRules.cast(for: world(["bloom": "vitality"]), seed: 4242)[0]
        var rng = SeededRNG(seed: 7)
        for _ in 0..<60 {
            let spawn = LifeRules.spawn(of: species, rng: &rng)
            XCTAssertEqual(spawn.armament, species.traits.armament, "jitter changed how it fights")
            XCTAssertEqual(spawn.covering, species.traits.covering, "jitter changed what it drops")
            XCTAssertEqual(spawn.boneDensity, species.traits.boneDensity)
            XCTAssertEqual(CreatureIdentity.match(spawn).key, CreatureIdentity.match(species.traits).key,
                           "jitter changed what the animal is")
            XCTAssertLessThanOrEqual(abs(spawn.size - species.traits.size),
                                     species.traits.size * Tuning.Life.jitter.sizeFraction + 0.001)
        }
    }

    func testAnIndividualIsVisiblyItsOwnAnimal() {
        let species = LifeRules.cast(for: world(["bloom": "vitality"]), seed: 4242)[0]
        var rng = SeededRNG(seed: 7)
        let colours = (0..<20).map { _ in LifeRules.spawn(of: species, rng: &rng).coloration }
        XCTAssertGreaterThan(Set(colours.map { Int($0.depth) }).count, 3,
                             "twenty spawns and no visible difference between any of them")
    }

    // MARK: - Pressures shape what a world tends to build

    /// Cold: bigger, better wrapped, shorter reach. Compared against worlds that differ *only* in
    /// temperature, so the vitality term can't confound the result.
    func testColdWorldsWrapTheirAnimalsUp() {
        let cold = WorldTendencies(readings: world([:], thermal: (floor: 4, peak: 20)))
        let warm = WorldTendencies(readings: world([:], thermal: (floor: 55, peak: 65)))
        XCTAssertGreaterThan(cold.axisWeights[.coveringLength]!, warm.axisWeights[.coveringLength]!,
                             "cold put nothing on its back")
        XCTAssertGreaterThan(cold.axisWeights[.size]!, warm.axisWeights[.size]!)
        XCTAssertGreaterThan(cold.free.reachWeights[.close]!, warm.free.reachWeights[.close]!,
                             "cold didn't shorten extremities")
    }

    /// Fur fails when it's wet, so wet-cold favours bulk and dry-cold favours covering. Both are
    /// valid answers, which is why the model weights rather than decides.
    func testWetColdFavoursFatAndDryColdFavoursFur() {
        let dry = WorldTendencies(readings: world([:], thermal: (floor: 4, peak: 20), hydrology: 5))
        let wet = WorldTendencies(readings: world([:], thermal: (floor: 4, peak: 20), hydrology: 85))
        XCTAssertGreaterThan(dry.axisWeights[.coveringLength]!, wet.axisWeights[.coveringLength]!)
        XCTAssertGreaterThan(wet.free.build, dry.free.build, "wet cold didn't reach for bulk")
    }

    func testHeatMakesThingsSmallerBarerAndLonger() {
        let hot = WorldTendencies(readings: world([:], thermal: (floor: 70, peak: 96)))
        let mild = WorldTendencies(readings: world([:], thermal: (floor: 45, peak: 55)))
        XCTAssertLessThan(hot.axisWeights[.size]!, mild.axisWeights[.size]!)
        XCTAssertLessThan(hot.axisWeights[.coveringCoverage]!, mild.axisWeights[.coveringCoverage]!)
        XCTAssertGreaterThan(hot.free.reachWeights[.far]!, mild.free.reachWeights[.far]!)
        XCTAssertLessThan(hot.free.colorationDepth, mild.free.colorationDepth, "nothing went pale in the sun")
    }

    /// Dim worlds grow eyes; dark ones give up on them entirely. Sensory is an allocation, so
    /// giving up on eyes necessarily buys something else.
    func testDarkWorldsGiveUpOnEyesAndHuntBySomethingElse() {
        let dark = WorldTendencies(readings: world([:], illumination: 4)).free.sensory
        let dim = WorldTendencies(readings: world([:], illumination: 22)).free.sensory
        XCTAssertLessThan(dark.vision, dim.vision, "the dark grew better eyes than the dusk")
        XCTAssertGreaterThan(dark.nonVisual, dark.vision)
        XCTAssertEqual(dark.vision + dark.nonVisual, 100, accuracy: 0.001, "sensory stopped being an allocation")
    }

    func testStoneInTheGroundBecomesStoneOnTheAnimal() {
        let mineral = WorldTendencies(readings: world(["gold": "substrate", "crystal": "substrate"]))
        let soft = WorldTendencies(readings: world(["rain": "hydrology"]))
        XCTAssertGreaterThan(mineral.axisWeights[.coveringHardness]!, soft.axisWeights[.coveringHardness]!)
        XCTAssertGreaterThan(mineral.axisWeights[.boneDensity]!, soft.axisWeights[.boneDensity]!)
    }

    func testEnclosedCountryReachesForAmbushWeaponsAndOpenGroundForDistance() {
        let enclosed = WorldTendencies(readings: world([:], openness: 15))
        let open = WorldTendencies(readings: world([:], openness: 90))
        XCTAssertGreaterThan(enclosed.free.weaponMix.pierce, open.free.weaponMix.pierce)
        XCTAssertGreaterThan(enclosed.free.patterning, open.free.patterning, "nothing learned to hide")
        XCTAssertGreaterThan(open.free.reachWeights[.mid]!, enclosed.free.reachWeights[.mid]!)
    }

    /// Light with nothing in the sky to come from is the bioluminescence case.
    func testSourcelessLightIsWhereGlowingThingsComeFrom() {
        var lit = world([:], illumination: 40, substrate: [:])
        lit.readings["illumination"]?.floor = 30
        lit.readings["illumination"]?.tags = ["sourceless"]
        XCTAssertTrue(WorldTendencies(readings: lit).free.emanationAllowed)

        var sunlit = world([:], illumination: 40, substrate: [:])
        sunlit.readings["illumination"]?.floor = 30
        sunlit.readings["illumination"]?.tags = ["celestial"]
        XCTAssertFalse(WorldTendencies(readings: sunlit).free.emanationAllowed,
                       "a world with a sun grew its own light anyway")
    }

    /// A world whose ground is volatile is the other route to something that glows.
    func testVolatileGroundAlsoGrowsGlowingThings() {
        let volatile = world([:], illumination: 40, substrate: ["volatile": 0.8, "hard": 0.2])
        XCTAssertTrue(WorldTendencies(readings: volatile).free.emanationAllowed)
    }

    // MARK: - Defence branching

    /// **One route, never a blend** (spec §3). Blending is what produces mush.
    func testAThreatenedWorldPicksOneAnswerToPredationPerSpecies() {
        var dangerous = world(["bloom": "vitality"], vitality: 90)
        dangerous.readings["vitality"]?.aspects["trophicDepth"] = 85
        let cast = LifeRules.cast(for: dangerous, seed: 808)
        XCTAssertTrue(cast.allSatisfy { $0.traits.defence != nil },
                      "a world full of predators produced species with no answer to them")

        for species in cast where species.traits.defence == .aposematism {
            XCTAssertTrue(species.traits.isToxic, "warning colours that mean nothing")
            XCTAssertGreaterThan(species.traits.coloration.patterning, 70)
        }
    }

    func testAPeacefulWorldDoesntBotherDefendingItself() {
        var calm = world([:], vitality: 60)
        calm.readings["vitality"]?.aspects["trophicDepth"] = 2
        XCTAssertTrue(LifeRules.cast(for: calm, seed: 5).allSatisfy { $0.traits.defence == nil })
    }

    /// Crypsis matches the ambient rather than simply going dark — a pale world hides pale things.
    func testCrypsisMatchesTheWorldItHidesIn() {
        var traits = CreatureTraits()
        var rng = SeededRNG(seed: 1)
        let bright = WorldTendencies(readings: world([:], illumination: 95))
        LifeRules.applyFreeAxes(of: bright, to: &traits, rng: &rng)
        let dark = WorldTendencies(readings: world([:], illumination: 2))
        XCTAssertGreaterThan(dark.free.ambientDepth, bright.free.ambientDepth)
    }

    // MARK: - Identity is derived, never imposed

    func testASpeciesThatFitsAKnownShapeTakesItsName() {
        var tank = CreatureTraits()
        tank.size = 85
        tank.covering = Covering(hardness: 80, length: 20, coverage: 80)
        XCTAssertEqual(CreatureIdentity.match(tank).region, .tank)

        var drifter = CreatureTraits()
        drifter.boneDensity = 10
        drifter.build = 15
        drifter.appendages = Appendages(count: 0, type: .finned)
        XCTAssertEqual(CreatureIdentity.match(drifter).region, .drifter)
    }

    /// **Unmatched species get composed names.** Forcing a thing into the nearest role is what the
    /// composed fallback exists to avoid, and free sampling guarantees these will happen.
    func testAnAnimalNothingHasAWordForGetsDescribedInstead() {
        var odd = CreatureTraits()
        odd.size = 88                                       // huge, but
        odd.covering = Covering(hardness: 5, length: 0, coverage: 5)   // bare
        odd.boneDensity = 90
        odd.build = 95                                      // and hulking
        odd.appendages = Appendages(count: 8, type: .limbed)

        let match = CreatureIdentity.match(odd)
        XCTAssertTrue(match.isComposed, "an animal with no name for it was forced into \(match.name)")
        XCTAssertTrue(match.name.contains("huge"), match.name)
        XCTAssertTrue(match.name.contains("bare") || match.name.contains("many-limbed"), match.name)
    }

    /// A composed name says the two things you'd actually notice, in plain words.
    func testAComposedNameDescribesWhatStandsOut() {
        var blind = CreatureTraits()
        blind.size = 90
        blind.sensory = Sensory.allocation(vision: 2, mechano: 60, chemo: 30, thermo: 8)
        blind.covering = Covering(hardness: 90, length: 10, coverage: 90)
        XCTAssertEqual(CreatureIdentity.composedName(for: blind), "huge blind armoured walker")

        var glower = CreatureTraits()
        glower.emanation = Emanation(strength: 80, light: 90, heat: 5, caustic: 5)
        glower.appendages = Appendages(count: 0, type: .none)
        glower.build = 20
        XCTAssertTrue(CreatureIdentity.composedName(for: glower).contains("glowing"))
    }

    func testEverySpeciesGetsSomeName() {
        var rng = SeededRNG(seed: 3)
        for _ in 0..<400 {
            var traits = CreatureTraits()
            for axis in CostlyAxis.allCases { traits[axis] = rng.double(in: 0...100) }
            traits.build = rng.double(in: 0...100)
            traits.appendages = Appendages(count: rng.int(in: 0...8),
                                           type: rng.pick(AppendageType.allCases)!)
            let match = CreatureIdentity.match(traits)
            XCTAssertFalse(match.name.isEmpty)
            XCTAssertFalse(match.key.isEmpty)
        }
    }

    /// A name has to be the same every time it's read, or an anchored world's animals get renamed
    /// underneath the player.
    func testANameIsStableForASpecies() {
        let cast = LifeRules.cast(for: world(["bloom": "vitality"]), seed: 616)
        for species in cast {
            XCTAssertEqual(species.displayName, CreatureIdentity.name(for: species.traits))
            XCTAssertEqual(species.displayName, species.displayName)
        }
    }

    /// **Free sampling**: no role is decided in advance, so a world that grew nothing that hunts
    /// simply has no hunters in it.
    func testAWorldWithNothingToEatGrowsNothingThatHunts() {
        var barren = world([:], vitality: 3)
        barren.readings["vitality"]?.aspects["trophicDepth"] = 0
        let regions = LifeRules.cast(for: barren, seed: 11).compactMap { $0.identity.region }
        XCTAssertFalse(regions.contains(.apex), "a dead world produced an apex predator")
    }

    // MARK: - The cast reaches the world

    /// The point of the whole system: what you meet on the map is what the world grew.
    func testEverythingOnTheMapComesFromTheWorldsOwnCast() {
        for seed in UInt64(1)...40 {
            let world = Worldgen.generate(book: BoundBook(written: ["teeming_life"], essencePaid: 0),
                                          seed: seed)
            XCTAssertFalse(world.cast.isEmpty, "seed \(seed) produced a world with no species")
            for enemy in world.enemies {
                XCTAssertNotNil(enemy.traits, "an enemy arrived without a body, seed \(seed)")
                XCTAssertTrue(world.cast.contains { $0.id == enemy.speciesID },
                              "something not in the cast is standing on the map, seed \(seed)")
                XCTAssertNil(enemy.creatureID, "worldgen still reached for an authored creature")
            }
        }
    }

    /// Same seed, same animals, in the same places — including their individual jitter.
    func testTheSameWorldPutsTheSameAnimalsInTheSamePlaces() {
        let book = BoundBook(written: ["teeming_life"], essencePaid: 0)
        let first = Worldgen.generate(book: book, seed: 4242)
        let again = Worldgen.generate(book: book, seed: 4242)
        XCTAssertEqual(first.cast, again.cast)
        XCTAssertEqual(first.enemies, again.enemies)
    }

    /// **Cheap animals are numerous and expensive ones are rare** — the pyramid falls out of the
    /// same appetite number the budget was spent against.
    func testTheCheapestThingInAWorldIsTheCommonestThingInIt() {
        var cheap = CreatureTraits(); cheap.size = 15
        var dear = CreatureTraits(); dear.size = 95
        dear.covering = Covering(hardness: 90, length: 60, coverage: 90)
        let cast = [Species(id: InstanceID(rawValue: 1), traits: cheap, worldSeed: 1),
                    Species(id: InstanceID(rawValue: 2), traits: dear, worldSeed: 1)]

        let table = Worldgen.roster(from: cast, nocturnal: false)
        let cheapWeight = table.first { $0.value.id == InstanceID(rawValue: 1) }?.weight ?? 0
        let dearWeight = table.first { $0.value.id == InstanceID(rawValue: 2) }?.weight ?? 0
        XCTAssertGreaterThan(cheapWeight, dearWeight,
                             "the world's most expensive animal was as common as its cheapest")
    }

    /// How it fights is what it is (spec §7) — not a stat block that happens to travel with it.
    func testABulkyArmouredThingFightsNothingLikeASwiftBareOne() {
        var tank = CreatureTraits()
        tank.size = 90; tank.build = 95; tank.boneDensity = 80
        tank.covering = Covering(hardness: 85, length: 20, coverage: 90)
        var runner = CreatureTraits()
        runner.size = 20; runner.build = Tuning.Life.sleekBuild; runner.boneDensity = 10
        runner.covering = Covering(hardness: 5, length: 5, coverage: 30)

        let heavy = CombatStats.derived(from: tank, name: "tank", icon: "tortoise")
        let quick = CombatStats.derived(from: runner, name: "runner", icon: "hare")

        XCTAssertGreaterThan(heavy.maxHP, quick.maxHP * 2)
        XCTAssertGreaterThan(heavy.armour, quick.armour)
        XCTAssertGreaterThan(quick.initiative, heavy.initiative, "the tank went first")
        XCTAssertGreaterThan(quick.evasion, heavy.evasion)
    }

    /// Warning colours are honest, and far reach beats speed at the moment of contact.
    func testTraitsThatChangeHowAFightOpens() {
        var toxic = CreatureTraits()
        toxic.size = 60
        toxic.isToxic = true
        XCTAssertGreaterThan(CombatStats.derived(from: toxic, name: "x", icon: "y").retaliation, 0)

        var reacher = CreatureTraits()
        reacher.armament.reach = .far
        XCTAssertTrue(CombatStats.derived(from: reacher, name: "x", icon: "y").strikesFirst)
    }

    // MARK: - Persistence

    /// A run in progress when the cast landed must still resolve — its enemies are catalogue
    /// creatures with no trait vector, and emptying the map under a player mid-visit is not a
    /// migration, it's a loss.
    func testAWorldBoundBeforeTheCastStillHasItsAnimals() {
        let legacy = WorldEnemy(id: InstanceID(rawValue: 1), creatureID: "paper_moth",
                                position: GridPoint(x: 2, y: 2))
        XCTAssertEqual(legacy.displayName, "Paper Moth")
        XCTAssertEqual(legacy.identityKey, "paper_moth")
        XCTAssertNotEqual(legacy.icon, "questionmark")
    }

    func testAnEnemyMissingEveryNewFieldStillLoads() throws {
        // Exactly the shape a save written before the cast existed holds.
        let old = OldWorldEnemy(id: InstanceID(rawValue: 7), creatureID: "ink_hound",
                                position: GridPoint(x: 1, y: 1), isAwake: false)
        let data = try SaveCodec.makeEncoder().encode(old)
        let enemy = try SaveCodec.makeDecoder().decode(WorldEnemy.self, from: data)
        XCTAssertNil(enemy.traits)
        XCTAssertEqual(enemy.displayName, "Ink Hound")
    }

    func testTraitsRoundTripThroughASave() throws {
        let species = LifeRules.cast(for: world(["bloom": "vitality"]), seed: 5)[0]
        let data = try SaveCodec.makeEncoder().encode(species)
        XCTAssertEqual(try SaveCodec.makeDecoder().decode(Species.self, from: data), species)
    }

    /// The tolerant-decoding policy, on the newest struct in the save. A vector written before a
    /// field existed must load, not quarantine somebody's world.
    func testATraitVectorMissingEveryFieldStillLoads() throws {
        let data = Data("{}".utf8)
        XCTAssertEqual(try SaveCodec.makeDecoder().decode(CreatureTraits.self, from: data),
                       CreatureTraits())
    }

    // MARK: - Helpers

    /// `WorldEnemy` as it was before worlds grew their own animals.
    private struct OldWorldEnemy: Codable {
        var id: InstanceID
        var creatureID: CreatureID
        var position: GridPoint
        var isAwake: Bool
    }

    private func normalisedWeights(_ readings: PressureReadings,
                                   over axes: [CostlyAxis]) -> [CostlyAxis: Double] {
        let weights = WorldTendencies(readings: readings).axisWeights
        let total = axes.reduce(0) { $0 + (weights[$1] ?? 0) }
        return Dictionary(uniqueKeysWithValues: axes.map { ($0, total > 0 ? (weights[$0] ?? 0) / total : 0) })
    }

    /// A world built from sigils, then overridden on the axes a test wants to isolate — so a claim
    /// about temperature is tested against worlds that differ *only* in temperature.
    private func world(_ pairs: [String: String],
                       seed: UInt64 = 20_260_805,
                       vitality: Double? = nil,
                       thermal: (floor: Double, peak: Double)? = nil,
                       hydrology: Double? = nil,
                       illumination: Double? = nil,
                       openness: Double? = nil,
                       substrate: [String: Double]? = nil) -> PressureReadings {
        var readings = PressureRules.resolve(pairs.sorted { $0.key < $1.key }.enumerated().map { index, pair in
            Sigil(id: InstanceID(rawValue: UInt64(index + 1)),
                  source: PressureSourceID(rawValue: pair.key),
                  target: PressureTargetID(rawValue: pair.value),
                  intensity: .great)
        }, fillingUnwrittenWith: seed)

        if let vitality {
            readings.readings["vitality"]?.peak = vitality
            readings.readings["vitality"]?.floor = vitality
        }
        if let thermal {
            readings.readings["thermal"]?.floor = thermal.floor
            readings.readings["thermal"]?.peak = thermal.peak
        }
        if let hydrology {
            readings.readings["hydrology"]?.peak = hydrology
            readings.readings["hydrology"]?.floor = hydrology
            readings.readings["hydrology"]?.forms = [:]
        }
        if let illumination {
            readings.readings["illumination"]?.peak = illumination
            readings.readings["illumination"]?.floor = 0
        }
        if let openness {
            readings.readings["relief"]?.aspects["openness"] = openness
        }
        if let substrate {
            readings.readings["substrate"]?.forms = substrate
        }
        return readings
    }
}
