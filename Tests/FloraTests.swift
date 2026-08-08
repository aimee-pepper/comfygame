import XCTest
@testable import Bookbinder

/// Flora — **the terrain half** (`flora-system-spec.md`).
///
/// The material half landed first: the six organic resources stopped growing off Vitality's peak and
/// started reading `produced`. This is the rest of it — the cast, the metabolism axis that decides
/// whether a world can live at all, growth writing the ground, harvest reading what grew, and
/// defended flora costing you something to walk through.
final class FloraTests: XCTestCase {

    // MARK: Metabolism — whether a world can live at all

    /// **The case the axis exists for.** A world lit by nothing and floored in magma is not barren:
    /// something down there is eating the rock. Before metabolism it was capped twice over — once
    /// for darkness and once for dryness — for two reasons neither of which applies.
    func testALightlessMineralWorldIsNotBarren() {
        let sunless = darkVolcanicWorld
        XCTAssertLessThan(sunless["illumination"].peak, 30, "this world was supposed to be dark")
        XCTAssertTrue(FloraRules.eatsTheRock(sunless), "volatile rock fed nothing")
        XCTAssertEqual(FloraRules.dominantMetabolism(in: sunless), .chemosynthetic)
        XCTAssertGreaterThan(FloraRules.castSize(for: sunless), 0,
                             "a lightless volcanic world grew nothing at all")
        XCTAssertFalse(sunless["vitality"].has("barren"),
                       "a world eating its own rock came out barren")
    }

    /// …and it says so, rather than leaving the player to guess why the dark world teemed.
    func testAWorldEatingRockSaysSo() {
        XCTAssertTrue(darkVolcanicWorld["vitality"].has("chemosynthetic"))
    }

    /// **The light cap and the water cap both lift**, because eating rock needs neither. The
    /// lightless volcanic world was capped twice over for two reasons that don't apply to it.
    func testEatingRockLiftsBothCaps() {
        let sunless = darkVolcanicWorld
        XCTAssertFalse(sunless["vitality"].has("light-limited"),
                       "something eating basalt was told it wanted for light")
        XCTAssertFalse(sunless["vitality"].has("water-limited"),
                       "something eating basalt was told it wanted for water")
    }

    /// **Rot is not the base of every damp world.** Fungi live in a meadow too; they are simply not
    /// what the meadow is standing on. Testing the dark routes against a bare threshold made nearly
    /// every world exempt from the light cap, which deleted "little grows, for want of light".
    func testADampLitWorldStillRunsOnTheSun() {
        let meadow = world(["rain": "hydrology", "sun": "illumination", "root": "vitality"])
        XCTAssertEqual(FloraRules.dominantMetabolism(in: meadow), .photosynthetic,
                       "a lit wet meadow was declared fungal")
    }

    /// A world with no light, no damp and no volatile rock can't make a living any way at all.
    func testAWorldWithNoLivingToBeMadeGrowsNothing() {
        let dead = nowhereToMakeALiving
        XCTAssertLessThan(FloraRules.bestViability(in: dead), Tuning.Flora.viabilityFloor)
        XCTAssertEqual(FloraRules.castSize(for: dead), 0, "something grew where nothing could")
        XCTAssertEqual(FloraRules.productivity(in: dead), 0)
        XCTAssertNil(FloraRules.dominantMetabolism(in: dead))
    }

    /// **Rot needs somewhere wet to happen.** A bone-dry world tagged decaying was supporting a
    /// fungal food web on nothing at all.
    func testRotStillNeedsDamp() {
        var bone = nowhereToMakeALiving
        bone.readings["vitality"]?.tags.insert("decaying")
        XCTAssertEqual(FloraRules.viability(in: bone)[.fungal], 0,
                       "a world with no water in it was rotting anyway")
    }

    // MARK: The food web stands on what grows

    /// **No producers, no herbivores, no predators** (§7). Trophic depth used to be capped by raw
    /// producer *demand*, so a page could ask for a deep food web in a world with nowhere for
    /// anything to make a living and get one.
    func testAWorldThatCanGrowNothingCarriesNoFoodWeb() {
        var asked = nowhereToMakeALiving
        // Ask it for a jungle anyway: plenty of life, plenty of producers, a deep web.
        asked.readings["vitality"]?.peak = 80
        asked.readings["vitality"]?.producedPeak = 70
        asked.readings["vitality"]?.aspects["trophicDepth"] = 60

        XCTAssertEqual(FloraRules.productivity(in: asked), 0, accuracy: 0.001,
                       "a world with no viable metabolism was still productive")

        let settled = WorldConstraints.apply(to: asked)
        XCTAssertEqual(settled["vitality"].aspect("trophicDepth"), 0, accuracy: 0.001,
                       "nothing grows here and the food web went on anyway")
        XCTAssertTrue(settled["vitality"].has("nothing-to-eat"))
        XCTAssertTrue(settled["vitality"].has("no-producers"))
    }

    // MARK: The cast

    /// Same world, same plants — which is what an anchored world will need without anything further
    /// being built.
    func testTheSameWorldGrowsTheSameThingsEveryTime() {
        let readings = world(["bloom": "vitality", "sun": "illumination"])
        let first = FloraRules.cast(for: readings, seed: 4242)
        let second = FloraRules.cast(for: readings, seed: 4242)
        XCTAssertEqual(first, second)
        XCTAssertNotEqual(first, FloraRules.cast(for: readings, seed: 4243))
    }

    /// **Vitality sets how many, never how strange** — the same rule the animals get.
    func testARicherWorldGrowsMoreKindsOfThing() {
        let thin = world(["salt": "vitality", "sun": "illumination"])
        let rich = world(["bloom": "vitality", "root": "vitality", "sun": "illumination"])
        XCTAssertGreaterThan(FloraRules.castSize(for: rich), FloraRules.castSize(for: thin))
    }

    /// A plant has to be made of something before it can be tall or thorny.
    func testNothingIsGrownOutOfNothing() {
        let readings = world(["bloom": "vitality", "sun": "illumination"])
        for plant in FloraRules.cast(for: readings, seed: 9) {
            XCTAssertGreaterThan(plant.traits.tissue.total, 0, "a height of nothing")
        }
    }

    // MARK: Pressures → growth

    /// **Light is a race.** Where there is plenty of it, the way to get it is to be taller than
    /// whatever is next to you — which is why a lit world grows canopy and a dark one grows mats.
    func testALitWorldGrowsTallAndADarkOneGrowsFlat() {
        let lit = meanStature(of: world(["bloom": "vitality", "sun": "illumination"]))
        let dark = meanStature(of: world(["bloom": "vitality", "void": "illumination",
                                          "rain": "hydrology"]))
        XCTAssertGreaterThan(lit, dark, "darkness didn't keep anything low")
    }

    /// **Herbivore pressure wins** (§3). Rich ground says don't bother defending; things eating you
    /// says defend anyway, and it overrides — which is what stops flora defence from being a
    /// single-variable readout of soil quality.
    func testThingsEatingYouOverrideGoodSoil() {
        var grazed = world(["bloom": "vitality", "sun": "illumination", "granite": "substrate"])
        var ungrazed = grazed
        grazed.readings["vitality"]?.aspects["trophicDepth"] = 80
        ungrazed.readings["vitality"]?.aspects["trophicDepth"] = 0

        let defended = GrowingConditions(readings: grazed).axisWeights[.defence] ?? 0
        let open = GrowingConditions(readings: ungrazed).axisWeights[.defence] ?? 0
        XCTAssertGreaterThan(defended, open, "nothing grew thorns in a world full of grazers")
    }

    // MARK: Flora → terrain

    /// **Habit decides patterning** (§5): spreading makes swathes, solitary makes scattered tiles.
    /// The test is contiguity — a spreading world's cover should touch itself far more than a
    /// solitary world's does.
    func testSpreadingGrowthMakesSwathesAndSolitaryGrowthMakesSpecks() {
        func clumping(of habit: Habit) -> Double {
            var traits = FloraTraits()
            traits.stature = 55
            traits.tissue.setTotal(50)
            traits.habit = habit
            let plant = Flora(id: InstanceID(rawValue: 1), traits: traits, worldSeed: 1)

            var map = WorldMap(width: 18, height: 18,
                               tiles: Array(repeating: Tile(), count: 324),
                               entry: GridPoint(x: 0, y: 0))
            var rng = SeededRNG(seed: 7)
            TerrainRules.paint(&map, readings: world(["bloom": "vitality", "sun": "illumination"]),
                               flora: [plant], rng: &rng)
            let grown = map.allPoints.filter { map[$0].ground.isOvergrown }
            guard !grown.isEmpty else { return 0 }
            let touching = grown.reduce(0) { total, point in
                total + map.neighbours(of: point).count { map[$0].ground.isOvergrown }
            }
            return Double(touching) / Double(grown.count)
        }
        XCTAssertGreaterThan(clumping(of: .spreading), clumping(of: .solitary),
                             "habit made no difference to how growth is arranged")
    }

    /// **Stature decides whether cover hides anything.** Groundcover shouldn't; canopy should.
    func testTallGrowthWritesThicketAndLowGrowthWritesGroundcover() {
        func ground(atStature stature: Double) -> GroundType? {
            var traits = FloraTraits()
            traits.stature = stature
            traits.tissue.setTotal(40)
            traits.habit = .spreading
            let plant = Flora(id: InstanceID(rawValue: 1), traits: traits, worldSeed: 1)

            var map = WorldMap(width: 18, height: 18,
                               tiles: Array(repeating: Tile(), count: 324),
                               entry: GridPoint(x: 0, y: 0))
            var rng = SeededRNG(seed: 3)
            TerrainRules.paint(&map, readings: world(["bloom": "vitality", "sun": "illumination"]),
                               flora: [plant], rng: &rng)
            return map.allPoints.first { map[$0].ground.isOvergrown }.map { map[$0].ground }
        }
        XCTAssertEqual(ground(atStature: 90), .growth, "a canopy didn't block anything")
        XCTAssertEqual(ground(atStature: 5), .groundcover, "a mat of moss blocked a sightline")
    }

    // MARK: Flora → harvest

    /// **What you cut it for comes off the tissue triangle** (§6), with chemical defence and
    /// chemosynthesis each overriding — a toxic plant is worth more as poison than as timber.
    func testWhatAPlantYieldsComesFromWhatItIsMadeOf() {
        XCTAssertEqual(FloraRules.yield(of: plant(woody: 10, stature: 80)), Resources.timber)
        XCTAssertEqual(FloraRules.yield(of: plant(woody: 10, stature: 10)), Resources.fiber,
                       "a woody thing too short to be timber should still give fibre")
        XCTAssertEqual(FloraRules.yield(of: plant(fibrous: 10)), Resources.fiber)
        XCTAssertEqual(FloraRules.yield(of: plant(fleshy: 10)), Resources.pulp)

        var toxic = plant(woody: 10, stature: 80)
        toxic.defence = 70
        toxic.defenceType = .chemical
        XCTAssertEqual(FloraRules.yield(of: toxic), Resources.toxin,
                       "a poisonous tree was still just timber")

        var rockEater = plant(fleshy: 10)
        rockEater.metabolism = .chemosynthetic
        XCTAssertEqual(FloraRules.yield(of: rockEater), Resources.reagent)
    }

    /// **Quantity from stature**, exactly as creature quantity comes from size.
    func testATallerPlantIsWorthMorePerCut() {
        XCTAssertGreaterThan(FloraRules.harvestQuantity(of: plant(woody: 10, stature: 95)),
                             FloraRules.harvestQuantity(of: plant(woody: 10, stature: 5)))
    }

    /// **Organic nodes stand where something is actually growing.** Timber lying on bare rock is
    /// the fault the whole material half of flora exists to fix.
    func testNothingOrganicIsHarvestedOffBareGround() {
        for seed in UInt64(1)...25 {
            let world = Worldgen.generate(book: BoundBook(written: ["teeming_life", "sun"],
                                                          essencePaid: 0), seed: seed)
            for point in world.map.allPoints {
                guard case .node(let node) = world.map[point].content,
                      FloraRules.isFloraResource(node.resource)
                else { continue }
                let growingNearby = world.map[point].ground.isOvergrown
                    || world.map.neighbours(of: point).contains { world.map[$0].ground.isOvergrown }
                XCTAssertTrue(growingNearby,
                              "\(node.resource.rawValue) was growing on bare ground, seed \(seed)")
            }
        }
    }

    // MARK: Flora → hazard

    /// **Thorns cost you once; poison keeps costing** — which is what makes a toxic thicket a
    /// different decision from a hedge rather than the same one at another number.
    func testThornsHurtOnceAndPoisonStaysWithYou() {
        var thorned = plant(woody: 10, stature: 50)
        thorned.defence = 90
        thorned.defenceType = .physical
        var toxic = thorned
        toxic.defenceType = .chemical

        XCTAssertGreaterThan(FloraRules.harm(of: thorned).immediate,
                             FloraRules.harm(of: toxic).immediate)
        XCTAssertEqual(FloraRules.harm(of: thorned).lingering, 0)
        XCTAssertGreaterThan(FloraRules.harm(of: toxic).lingering, 0)

        // Something you can walk through without noticing shouldn't cost anything at all.
        var open = thorned
        open.defence = 5
        XCTAssertFalse(FloraRules.harm(of: open).isSomething)
    }

    /// Walking into it costs you, and the poison goes on working turn by turn — **because you
    /// moved**, never because time passed (pillar 2).
    func testWalkingIntoPoisonKeepsCostingYouForAFewTurns() throws {
        var toxic = plant(fleshy: 10, stature: 40)
        toxic.defence = 90
        toxic.defenceType = .chemical
        let bramble = Flora(id: InstanceID(rawValue: 77), traits: toxic, worldSeed: 1)

        var map = WorldMap(width: 5, height: 1, tiles: Array(repeating: Tile(), count: 5),
                           entry: GridPoint(x: 0, y: 0))
        map[GridPoint(x: 1, y: 0)].ground = .growth
        map[GridPoint(x: 1, y: 0)].flora = bramble.id

        var state = GameState.newGame()
        state.worlds.activeRun = WorldRun(runIndex: 1,
                                          book: BoundBook(written: [], essencePaid: 0),
                                          mapSeed: 1,
                                          rng: SeededRNG(seed: 1),
                                          map: map,
                                          playerPosition: GridPoint(x: 0, y: 0),
                                          flora: [bramble])

        let full = try XCTUnwrap(state.worlds.activeRun).binderHP
        let events = WorldRules.step(to: GridPoint(x: 1, y: 0), in: &state)
        XCTAssertTrue(events.contains { if case .scratchedByGrowth = $0 { true } else { false } },
                      "you walked into a poisonous thicket and nothing happened")

        let afterEntry = try XCTUnwrap(state.worlds.activeRun).binderHP
        XCTAssertLessThan(afterEntry, full)
        XCTAssertGreaterThan(try XCTUnwrap(state.worlds.activeRun).floraPoisonTurns, 0)

        // Standing still still costs you, because standing still is a turn.
        _ = WorldRules.advanceTurn(in: &state)
        XCTAssertLessThan(try XCTUnwrap(state.worlds.activeRun).binderHP, afterEntry,
                          "the poison stopped working the moment you stopped walking")
    }

    /// **Bare ground is free.** The hazard is what's growing there, not the tile.
    func testWalkingAcrossOpenGroundCostsYouNothing() {
        var state = GameState.newGame()
        state.worlds.activeRun = WorldRun(runIndex: 1,
                                          book: BoundBook(written: [], essencePaid: 0),
                                          mapSeed: 1,
                                          rng: SeededRNG(seed: 1),
                                          map: WorldMap(width: 5, height: 1,
                                                        tiles: Array(repeating: Tile(), count: 5),
                                                        entry: GridPoint(x: 0, y: 0)),
                                          playerPosition: GridPoint(x: 0, y: 0))
        let full = state.worlds.activeRun?.binderHP
        _ = WorldRules.step(to: GridPoint(x: 1, y: 0), in: &state)
        XCTAssertEqual(state.worlds.activeRun?.binderHP, full)
    }

    /// A plant that stands up is armed with its defence and armoured by its woodiness — and it is
    /// still called by the name of the thing you have been walking past all afternoon.
    func testAPredatoryPlantFightsWithWhatItGrew() {
        var thorns = plant(woody: 10, stature: 70)
        thorns.defence = 85
        thorns.defenceType = .active
        XCTAssertTrue(thorns.isPredatory)

        let asFoe = FloraRules.combatant(from: thorns)
        XCTAssertGreaterThan(asFoe.armament.total, 0, "it stood up unarmed")
        XCTAssertEqual(asFoe.appendages.type, AppendageType.none, "it grew legs")
        XCTAssertEqual(asFoe.sensory.vision, 0, "a plant with eyes")
        XCTAssertEqual(asFoe.armament.reach, Reach.close)
    }

    // MARK: Naming

    /// Derived, never imposed — and never two of a world's plants sharing a name.
    func testNoTwoPlantsInAWorldShareAName() {
        for seed in UInt64(1)...30 {
            let cast = FloraRules.cast(for: world(["bloom": "vitality", "root": "vitality",
                                                   "sun": "illumination"]), seed: seed)
            let names = FloraIdentity.names(for: cast).values.map(\.name)
            XCTAssertEqual(Set(names).count, names.count, "two plants shared a name, seed \(seed)")
            XCTAssertFalse(names.contains { $0.isEmpty }, "a plant with no name at all")
        }
    }

    /// The noun says how it makes its living, because that is the strangest thing about anything
    /// growing in a lightless world.
    func testAPlantIsNamedForHowItEats() {
        var crust = plant(fleshy: 10, stature: 5)
        crust.metabolism = .chemosynthetic
        XCTAssertTrue(FloraIdentity.composedName(for: crust).hasSuffix("crust"),
                      "got \"\(FloraIdentity.composedName(for: crust))\"")

        var mould = plant(fleshy: 10, stature: 10)
        mould.metabolism = .fungal
        XCTAssertTrue(FloraIdentity.composedName(for: mould).hasSuffix("mould"),
                      "got \"\(FloraIdentity.composedName(for: mould))\"")

        var tree = plant(woody: 10, stature: 85)
        XCTAssertTrue(FloraIdentity.composedName(for: tree).hasSuffix("tree"),
                      "got \"\(FloraIdentity.composedName(for: tree))\"")
        // …and the same shape, eating rock, is not a tree at all.
        tree.metabolism = .chemosynthetic
        XCTAssertFalse(FloraIdentity.composedName(for: tree).hasSuffix("tree"))
    }

    /// **A chemosynthetic thing is never a succulent**, however short and fleshy it is. Scoring the
    /// wrong metabolism as a near-miss let the crust be named for a plant.
    func testMetabolismIsNotANearMiss() {
        var crust = plant(fleshy: 10, stature: 5)
        crust.metabolism = .chemosynthetic
        XCTAssertNotEqual(FloraIdentity.match(crust).region, .succulent)
    }

    // MARK: Saving

    /// A run is saved after every action, so flora has to survive the round trip — and a world
    /// bound before flora existed has to keep loading.
    func testFloraSurvivesASaveAndAnOlderWorldStillLoads() throws {
        var traits = FloraTraits()
        traits.stature = 62
        traits.tissue.setTotal(48)
        traits.defence = 70
        traits.defenceType = .chemical
        traits.metabolism = .chemosynthetic
        let flora = Flora(id: InstanceID(rawValue: 9), traits: traits, worldSeed: 5)

        let data = try SaveCodec.makeEncoder().encode(flora)
        XCTAssertEqual(try SaveCodec.makeDecoder().decode(Flora.self, from: data), flora)

        // A plant written before defence types existed.
        let old = Data(#"{"id":{"rawValue":9},"worldSeed":5,"traits":{"stature":20}}"#.utf8)
        let loaded = try SaveCodec.makeDecoder().decode(Flora.self, from: old)
        XCTAssertEqual(loaded.traits.stature, 20)
        XCTAssertEqual(loaded.traits.metabolism, .photosynthetic)

        // A tile written before it knew what was growing on it.
        let tile = Data(#"{"ground":"growth","isRevealed":true,"isCrumbled":false,"content":{"empty":{}}}"#.utf8)
        XCTAssertNil(try SaveCodec.makeDecoder().decode(Tile.self, from: tile).flora)
    }

    // MARK: Helpers

    /// **Lit by nothing and floored in sulfur.** `magma` is the obvious volcanic word and it is also
    /// a *light source* — a magma world is not dark, which is why the case wants sulfur and a word
    /// for the dark on top of it.
    private var darkVolcanicWorld: PressureReadings {
        world(["sulfur": "substrate", "void": "illumination", "root": "vitality"])
    }

    /// No light, no damp, no volatile rock. Built rather than written, because a page that says all
    /// three at once is a long one and the claim is about the readings, not the vocabulary.
    private var nowhereToMakeALiving: PressureReadings {
        var dead = world(["root": "vitality"])
        dead.readings["illumination"]?.peak = 0
        dead.readings["illumination"]?.floor = 0
        dead.readings["hydrology"]?.peak = 0
        dead.readings["hydrology"]?.forms = [:]
        dead.readings["substrate"]?.forms = [:]
        return dead
    }

    private func plant(woody: Double = 1, fibrous: Double = 1, fleshy: Double = 1,
                       stature: Double = 50) -> FloraTraits {
        var traits = FloraTraits()
        traits.stature = stature
        traits.tissue.mix = TissueMix(woody: woody, fibrous: fibrous, fleshy: fleshy)
        traits.tissue.setTotal(60)
        return traits
    }

    private func meanStature(of readings: PressureReadings) -> Double {
        let cast = FloraRules.cast(for: readings, seed: 31)
        guard !cast.isEmpty else { return 0 }
        return cast.reduce(0) { $0 + $1.traits.stature } / Double(cast.count)
    }

    private func sigil(_ source: String, _ target: String, _ intensity: Intensity) -> Sigil {
        Sigil(id: InstanceID(rawValue: UInt64.random(in: 1...9_999_999)),
              source: PressureSourceID(rawValue: source),
              target: PressureTargetID(rawValue: target),
              intensity: intensity)
    }

    /// Written, never rolled — an assertion about what a page says shouldn't be breakable by
    /// editing an unrelated focus.
    private func world(_ pairs: [String: String]) -> PressureReadings {
        PressureRules.resolve(pairs.sorted { $0.key < $1.key }.enumerated().map { index, pair in
            Sigil(id: InstanceID(rawValue: UInt64(index + 1)),
                  source: PressureSourceID(rawValue: pair.key),
                  target: PressureTargetID(rawValue: pair.value),
                  intensity: .great)
        })
    }
}
