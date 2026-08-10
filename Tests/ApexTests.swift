import XCTest
@testable import Bookbinder

/// **Apex encounters** (`apex-encounters.md`) — a creature the world cannot afford.
///
/// `LifeRules` filters on what a world can feed. An apex breaks that filter on purpose, which is
/// both the mechanic and the fiction: something too large for this world to feed either came from
/// somewhere else or is eating everything else, and both are true of what it does to the map.
@MainActor
final class ApexTests: XCTestCase {

    // MARK: What it is

    /// **The budget lifted, and nothing else changed.** No new creature model — its identity still
    /// derives, and its butchery yields are exceptional because its traits are.
    func testAnApexIsMoreThanTheWorldCouldAfford() throws {
        let readings = world(["bloom": "vitality", "sun": "illumination"])
        let ordinary = LifeRules.cast(for: readings, seed: 9)
        let apex = try XCTUnwrap(ApexRules.sample(for: readings, seed: 9, chance: 1))

        let dearest = ordinary.map(\.traits.appetite).max() ?? 0
        XCTAssertGreaterThan(apex.traits.appetite, dearest,
                             "the apex cost this world no more than its ordinary animals did")
        XCTAssertGreaterThan(apex.traits.appetite,
                             WorldConstraints.energyBudget(in: readings),
                             "a world that can afford its apex hasn't got one")
        XCTAssertFalse(apex.displayName.isEmpty, "it arrived without a name")
    }

    /// Even a thin world's apex is an apex — the floor under the budget is what guarantees that.
    func testEvenAPoorWorldsApexIsFormidable() throws {
        let thin = world(["salt": "vitality"])
        let apex = try XCTUnwrap(ApexRules.sample(for: thin, seed: 3, chance: 1))
        XCTAssertGreaterThan(apex.traits.appetite, WorldConstraints.energyBudget(in: thin))
    }

    /// Deterministic in the seed, like everything else — a resume finds the same animal.
    func testTheSameWorldHoldsTheSameApex() {
        let readings = world(["bloom": "vitality", "sun": "illumination"])
        XCTAssertEqual(ApexRules.sample(for: readings, seed: 44, chance: 1),
                       ApexRules.sample(for: readings, seed: 44, chance: 1))
    }

    // MARK: What draws one

    /// **The greed link is the important one** (§3). Writing a greedy world costs stability and buys
    /// materials; now it also draws something, which gives the dial a third consequence and makes
    /// the decision richer rather than merely more expensive.
    func testGreedDrawsThem() {
        let plain = ApexRules.chance(greed: 0, stabilityScore: 100, dangerTiles: 0, sites: 0)
        let greedy = ApexRules.chance(greed: 60, stabilityScore: 100, dangerTiles: 0, sites: 0)
        let dangerous = ApexRules.chance(greed: 0, stabilityScore: 20, dangerTiles: 0, sites: 0)
        let guarded = ApexRules.chance(greed: 0, stabilityScore: 100, dangerTiles: 0, sites: 2)

        XCTAssertGreaterThan(greedy, plain, "greed drew nothing")
        XCTAssertGreaterThan(dangerous, plain, "instability drew nothing")
        XCTAssertGreaterThan(guarded, plain, "a site drew nothing")
        XCTAssertGreaterThan(greedy - plain, dangerous - plain, "greed should be the loudest term")
    }

    /// **Never a certainty.** A guaranteed apex is a chore with a health bar.
    func testTheWorstWorldStillOnlyMightHaveOne() {
        XCTAssertLessThan(
            ApexRules.chance(greed: 500, stabilityScore: 0, dangerTiles: 8, sites: 3), 1.0)
    }

    // MARK: The restraint rules — the design

    /// **You must be able to see it and walk away** (§2). All three of these together are what make
    /// hunting one a choice rather than a thing that happens to you.
    func testItIsVisibleNeverAmbushesAndDoesNotFollow() throws {
        let readings = world(["bloom": "vitality", "sun": "illumination"])
        var cryptic = try XCTUnwrap(ApexRules.sample(for: readings, seed: 5, chance: 1)).traits
        cryptic.defence = .crypsis    // the hard case: it would be hidden if it were anything else

        var run = WorldRun(runIndex: 1,
                           book: BoundBook(written: [], essencePaid: 0),
                           mapSeed: 5,
                           rng: SeededRNG(seed: 5),
                           map: WorldMap(width: 9, height: 1,
                                         tiles: Array(repeating: Tile(), count: 9),
                                         entry: GridPoint(x: 0, y: 0)),
                           playerPosition: GridPoint(x: 0, y: 0))
        let standing = GridPoint(x: 6, y: 0)
        run.enemies = [WorldEnemy(id: InstanceID(rawValue: 1), traits: cryptic,
                                  position: standing, isApex: true)]

        XCTAssertTrue(WorldRules.isVisible(run.enemies[0], in: run),
                      "a cryptic apex hid — you must be able to see it and walk away")

        var state = GameState.newGame()
        state.worlds.activeRun = run
        for _ in 0..<6 { _ = WorldRules.advanceTurn(in: &state) }

        let after = try XCTUnwrap(state.worlds.activeRun?.enemies.first)
        XCTAssertEqual(after.position, standing, "it came after you")
        XCTAssertFalse(after.isAwake, "it woke on its own — an apex that jumps you isn't a choice")
    }

    /// One per world at most. Two makes them scenery.
    func testAtMostOneStandsInAWorld() {
        for seed in UInt64(1)...60 {
            let world = Worldgen.generate(
                book: BoundBook(written: ["rich_ore", "gilded_veins"], essencePaid: 0), seed: seed)
            XCTAssertLessThanOrEqual(world.enemies.count { $0.isApex }, 1, "seed \(seed)")
        }
    }

    /// **Never near the entry portal** (§3). You should have to go in.
    func testYouHaveToGoInToFindOne() {
        for seed in UInt64(1)...120 {
            let world = Worldgen.generate(
                book: BoundBook(written: ["rich_ore", "gilded_veins"], essencePaid: 0), seed: seed)
            for apex in world.enemies where apex.isApex {
                XCTAssertGreaterThanOrEqual(apex.position.chebyshevDistance(to: world.start),
                                            Tuning.Apex.minimumDistanceFromEntry,
                                            "an apex was waiting by the door, seed \(seed)")
            }
        }
    }

    // MARK: The drops

    /// **Eight sentences a crafted weapon can't say**, and each breaks exactly one rule.
    func testEveryWildWeaponExistsAndBreaksExactlyOneRule() throws {
        var broken: Set<WildRule> = []
        for id in ApexRules.wildWeapons {
            let item = try XCTUnwrap(ContentCatalog.shared.item(id), "missing \(id.rawValue)")
            let rule = try XCTUnwrap(item.gear?.breaks, "\(id.rawValue) breaks no rule")
            XCTAssertTrue(broken.insert(rule).inserted,
                          "two weapons break the same rule (\(rule.rawValue))")
        }
        XCTAssertEqual(broken.count, WildRule.allCases.count,
                       "a rule nothing breaks: \(Set(WildRule.allCases).subtracting(broken))")
    }

    func testThroughstrokeCarriesHalfTheHitIntoAnotherFoe() throws {
        let store = combatStore(weapon: "ranked_spear", foeCount: 2)
        let targets = try XCTUnwrap(store.activeEncounter?.foes)
        let primary = targets[0]
        let secondBefore = targets[1].currentHP

        store.mutate("throughstroke") { state in
            CombatRules.perform(.attack(foe: primary.id), by: .binder, in: &state)
        }

        XCTAssertLessThan(store.activeEncounter?.foes[1].currentHP ?? secondBefore, secondBefore)
    }

    func testLivingHookGrowsFromWinsAndStopsAfterTwoTiers() throws {
        let store = combatStore(weapon: "living_hook", foeCount: 1)
        for _ in 0..<3 {
            store.mutate("win with hook") { state in
                state.worlds.activeRun?.activeEncounter?.foes[0].currentHP = 0
                state.worlds.activeRun?.activeEncounter?.outcome = nil
                CombatRules.checkOutcome(in: &state)
            }
        }
        XCTAssertEqual(store.state.base.binderEquipped[.weapon]?.wildGrowth, 2)
    }

    func testWardedHaftOnlyTurnsAsideItsAuthoredBlow() {
        var state = GameState.newGame()
        state.base.binderEquipped[.weapon] = "warded_haft"
        XCTAssertEqual(CombatRules.wardedHaftMultiplier(against: .crush, for: .binder, in: state),
                       1 - Tuning.Apex.wardedHaftReduction)
        XCTAssertEqual(CombatRules.wardedHaftMultiplier(against: .pierce, for: .binder, in: state), 1)
    }

    func testApexSightingsBadgeTheDerivedSpeciesAndDeduplicateReads() {
        var log = DiscoveryLog()
        let id = InstanceID(rawValue: 99)
        log.recordSpecies("glass-hare", runIndex: 4)
        log.recordApex(id, species: "glass-hare", runIndex: 4)
        log.recordApex(id, species: "glass-hare", runIndex: 4)
        let entry = BestiaryRules.entries(in: log).first
        XCTAssertEqual(entry?.apexSightings, 1)
        XCTAssertTrue(entry?.isApexSpecies == true)
    }

    func testCacheWeaponIsAnIndependentBonusLottery() {
        let readings = world(["bloom": "vitality"])
        var never = SeededRNG(seed: 8)
        var certain = SeededRNG(seed: 8)
        XCTAssertNil(ApexRules.cacheBonus(for: readings, chance: 0, rng: &never))
        XCTAssertNotNil(ApexRules.cacheBonus(for: readings, chance: 1, rng: &certain))
    }

    func testLivingHookGrowthSurvivesUnequippingAndSaving() throws {
        var piece = EquippedPiece(catalogID: "living_hook", wildGrowth: 2)
        let stack = piece.asStack(id: InstanceID(rawValue: 7))
        let data = try SaveCodec.makeEncoder().encode(stack)
        let restored = try SaveCodec.makeDecoder().decode(ItemStack.self, from: data)
        XCTAssertEqual(restored.wildGrowth, 2)
        piece = EquippedPiece(restored)
        XCTAssertEqual(piece.effectiveTier,
                       (ContentCatalog.shared.item("living_hook")?.gear?.tier ?? 0) + 2)
    }

    /// **You're buying the rule, not the numbers** (§4). A wild weapon must not simply out-stat the
    /// best thing you could otherwise find, or the trade it exists to offer isn't a trade.
    func testAWildWeaponIsNotSimplyBetter() throws {
        let bestFound = ContentCatalog.shared.items
            .filter { $0.kind == .gear && $0.gear?.slot == .weapon && !ApexRules.wildWeapons.contains($0.id) }
            .compactMap { $0.gear?.tier }
            .max() ?? 0
        for id in ApexRules.wildWeapons {
            let tier = try XCTUnwrap(ContentCatalog.shared.item(id)?.gear?.tier)
            XCTAssertLessThanOrEqual(tier, bestFound,
                                     "\(id.rawValue) out-stats everything craftable as well as breaking a rule")
        }
    }

    private func combatStore(weapon: ItemID, foeCount: Int) -> GameStore {
        let store = GameStore(io: .temporary(name: "apex-weapon-\(UUID().uuidString)"))
        store.write("plains")
        _ = store.bindAndDepart()
        store.mutate("stage wild weapon") { state in
            state.base.binderEquipped[.weapon] = EquippedPiece(catalogID: weapon)
            guard var run = state.worlds.activeRun else { return }
            let enemies = (0..<foeCount).map { index in
                WorldEnemy(id: InstanceID(rawValue: UInt64(index + 1)), creatureID: "paper_moth",
                           position: run.playerPosition, isAwake: true)
            }
            run.enemies = enemies
            state.worlds.activeRun = run
            WorldRules.beginEncounter(triggeredBy: enemies[0], in: &state)
            state.worlds.activeRun?.activeEncounter?.foes.indices.forEach {
                state.worlds.activeRun?.activeEncounter?.foes[$0].stats.evasion = 0
                state.worlds.activeRun?.activeEncounter?.foes[$0].stats.armour = 0
                state.worlds.activeRun?.activeEncounter?.foes[$0].currentHP = 100
            }
        }
        return store
    }

    /// A two-natured blade picks whichever edge the covering likes least — the one thing no
    /// material can do, because nothing has two dominant armaments.
    func testATwoNaturedBladePicksTheBetterEdge() {
        let plated = Covering(hardness: 95, length: 5, coverage: 95)
        let ordinary = CombatRules.effectiveness(of: .rend, against: plated, breaking: nil)
        let wild = CombatRules.effectiveness(of: .rend, against: plated, breaking: .twoNatured)
        XCTAssertGreaterThan(wild, ordinary, "it swung with the wrong edge anyway")
        XCTAssertEqual(wild, CombatRules.effectiveness(of: .crush, against: plated),
                       accuracy: 0.001, "it should be exactly as good as the right edge, never better")
    }

    // MARK: Helpers

    private func world(_ pairs: [String: String]) -> PressureReadings {
        PressureRules.resolve(pairs.sorted { $0.key < $1.key }.enumerated().map { index, pair in
            Sigil(id: InstanceID(rawValue: UInt64(index + 1)),
                  source: PressureSourceID(rawValue: pair.key),
                  target: PressureTargetID(rawValue: pair.value),
                  intensity: .great)
        })
    }
}
