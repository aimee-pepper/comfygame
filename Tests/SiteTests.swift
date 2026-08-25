import XCTest
@testable import Bookbinder

/// Sites — the fourth layer. What a world *contains*, as opposed to what it *is*.
final class SiteTests: XCTestCase {

    @MainActor
    func testBlockedMovementNamesObservableTerrainAndSpendsNoWorldTurn() throws {
        var map = WorldMap(width: 2, height: 2,
                           tiles: Array(repeating: Tile(ground: .soil), count: 4),
                           entry: GridPoint(x: 0, y: 0))
        map[GridPoint(x: 1, y: 0)] = Tile(ground: .deepWater)
        map[GridPoint(x: 0, y: 1)] = Tile(ground: .chasm)
        XCTAssertEqual(WorldRules.blockedMovementRefusal(
            to: GridPoint(x: 2, y: 0), in: map),
                       "The edge of the world lies beyond that step.")
        XCTAssertEqual(WorldRules.blockedMovementRefusal(
            to: GridPoint(x: 1, y: 0), in: map),
                       "The water is too deep to cross.")
        XCTAssertEqual(WorldRules.blockedMovementRefusal(
            to: GridPoint(x: 0, y: 1), in: map),
                       "A chasm opens there — there is no footing.")
        map[GridPoint(x: 1, y: 0)].isCrumbled = true
        XCTAssertEqual(WorldRules.blockedMovementRefusal(
            to: GridPoint(x: 1, y: 0), in: map),
                       "Crumbled away — nothing to stand on.")

        let store = GameStore(io: .temporary(name: "blocked-step-\(UUID().uuidString)"))
        XCTAssertTrue(store.bindAndDepart())
        store.mutate("place adjacent deep water") { state in
            guard var run = state.worlds.activeRun else { return }
            let destination = run.map.neighbours(of: run.playerPosition).first!
            run.map[destination].ground = .deepWater
            run.map[destination].isCrumbled = false
            run.enemies.removeAll()
            state.worlds.activeRun = run
        }
        let before = try XCTUnwrap(store.state.worlds.activeRun)
        let destination = try XCTUnwrap(before.map.neighbours(of: before.playerPosition).first)
        store.step(to: destination)
        let after = try XCTUnwrap(store.state.worlds.activeRun)
        XCTAssertEqual(after, before)
        XCTAssertEqual(store.recentEvents, [.blocked("The water is too deep to cross.")])
    }

    // MARK: Content

    func testEverySiteIsReachableBySomeWorld() {
        // A site nothing can ever satisfy is authored content that will never be seen. Rarity is
        // supposed to come from condition *narrowness*, not from impossibility.
        let catalog = ContentCatalog.shared
        var unreachable: [SiteID] = []
        for site in catalog.sites {
            let found = (0..<400).contains { seed in
                let sigils = PressureRules.rollUnwritten(after: [], seed: UInt64(seed))
                let readings = PressureRules.resolve(sigils)
                return site.isEligible(in: readings,
                                       contradictions: ContradictionRules.fired(in: sigils, readings: readings))
            }
            if !found { unreachable.append(site.id) }
        }
        XCTAssertTrue(unreachable.isEmpty,
                      "no world in 400 rolls can host: \(unreachable.map(\.rawValue).joined(separator: ", "))")
    }

    func testCatalogValidates() throws {
        try ContentCatalog.shared.validate()
        XCTAssertFalse(ContentCatalog.shared.sites.isEmpty)
    }

    // MARK: Conditions

    func testConditionsAreRangesNotExactMatches() {
        // The property that makes sites huntable: a *family* of worlds produces a given site, so
        // you find one by understanding conditions rather than by memorising a recipe.
        guard let vault = ContentCatalog.shared.site(SiteID(rawValue: "glacial_vault")) else {
            return XCTFail("glacial_vault missing")
        }
        let matching = (0..<300).filter { seed in
            vault.isEligible(in: PressureRules.resolve([], fillingUnwrittenWith: UInt64(seed)))
        }
        XCTAssertGreaterThan(matching.count, 1,
                             "a site only one specific world can host is a recipe, not a condition")
    }

    func testColdVaultRefusesAWarmWorld() {
        guard let vault = ContentCatalog.shared.site(SiteID(rawValue: "glacial_vault")) else {
            return XCTFail("glacial_vault missing")
        }
        let scorched = PressureRules.resolve([
            Sigil(id: InstanceID(rawValue: 1), source: PressureSourceID(rawValue: "sun"),
                  target: PressureTargetID(rawValue: "illumination"), intensity: .overwhelming),
            Sigil(id: InstanceID(rawValue: 2), source: PressureSourceID(rawValue: "magma"),
                  target: PressureTargetID(rawValue: "thermal"), intensity: .overwhelming)
        ])
        XCTAssertFalse(vault.isEligible(in: scorched))
    }

    /// Hazard sites key off **named** contradictions, never off opposed force.
    ///
    /// This test used to assert the opposite — that piling up opposed magnitude tore the world —
    /// which `contradiction-danger-spec.md` §1 rules out precisely because it punishes honest
    /// worldbuilding. The full treatment is in `ContradictionTests`; this keeps the site side
    /// honest.
    func testAHazardSiteIgnoresOpposedForce() throws {
        let tear = try XCTUnwrap(ContentCatalog.shared.site("the_tear"))
        let violentlyOpposed = [
            Sigil(id: InstanceID(rawValue: 1), source: "sun", target: "illumination", intensity: .overwhelming),
            Sigil(id: InstanceID(rawValue: 2), source: "void", target: "illumination", intensity: .overwhelming),
            Sigil(id: InstanceID(rawValue: 3), source: "magma", target: "thermal", intensity: .overwhelming),
            Sigil(id: InstanceID(rawValue: 4), source: "glacier", target: "thermal", intensity: .overwhelming)
        ]
        let readings = PressureRules.resolve(violentlyOpposed)
        XCTAssertGreaterThan(readings.totalOpposed, 0, "the test page isn't actually opposed")
        XCTAssertFalse(
            tear.isEligible(in: readings,
                            contradictions: ContradictionRules.fired(in: violentlyOpposed, readings: readings)),
            "a world can be violently opposed and still perfectly honest — it must not tear")
    }

    // MARK: Placement

    func testReliquaryRevealsSiteLocationsWithoutOpeningThem() throws {
        let generated = (UInt64(1)...200).lazy
            .map { Worldgen.generate(book: BoundBook(symbols: [:], randomlyFilled: [], essencePaid: 0), seed: $0) }
            .first { !$0.sites.isEmpty }
        var world = try XCTUnwrap(generated)
        for site in world.sites { world.map[site.position].isRevealed = false }

        ReliquaryRules.revealSites(on: &world.map, sites: world.sites)

        XCTAssertTrue(world.sites.allSatisfy { world.map[$0.position].isRevealed })
        XCTAssertTrue(world.sites.allSatisfy { !$0.isLooted })
    }

    func testPlacementIsDeterministicInTheSeed() {
        let book = BoundBook(symbols: [SlotID(rawValue: "biome"): SymbolID(rawValue: "frostbound")],
                             randomlyFilled: [], essencePaid: 0)
        let first = Worldgen.generate(book: book, seed: 20_260_805)
        let second = Worldgen.generate(book: book, seed: 20_260_805)
        XCTAssertEqual(first.sites, second.sites)
    }

    func testSitesNeverLandOnTopOfSomethingElse() {
        for seed in UInt64(1)...60 {
            let world = Worldgen.generate(
                book: BoundBook(symbols: [:], randomlyFilled: [], essencePaid: 0), seed: seed)
            var seen: Set<GridPoint> = []
            for site in world.sites {
                XCTAssertNotEqual(site.position, world.start, "site on the reserved start, seed \(seed)")
                XCTAssertNotEqual(site.position, world.map.entry,
                                  "site on the return portal, seed \(seed)")
                XCTAssertTrue(seen.insert(site.position).inserted, "two sites stacked, seed \(seed)")
                guard case .site = world.map[site.position].content else {
                    return XCTFail("tile under site \(site.siteID) isn't a site, seed \(seed)")
                }
            }
        }
    }

    func testExclusionsAreSymmetric() {
        // Workshop and Vault name each other; only one may ever appear.
        for seed in UInt64(1)...120 {
            let world = Worldgen.generate(
                book: BoundBook(symbols: [:], randomlyFilled: [], essencePaid: 0), seed: seed)
            let ids = Set(world.sites.map(\.siteID.rawValue))
            XCTAssertFalse(ids.contains("binders_workshop") && ids.contains("glacial_vault"),
                           "excluded pair co-occurred, seed \(seed)")
        }
    }

    func testCapsAreRespected() {
        for seed in UInt64(1)...80 {
            let world = Worldgen.generate(
                book: BoundBook(symbols: [:], randomlyFilled: [], essencePaid: 0), seed: seed)
            let counts = Dictionary(grouping: world.sites, by: \.siteID).mapValues(\.count)
            for (id, count) in counts {
                let cap = ContentCatalog.shared.site(id)?.maximumPerWorld ?? 1
                XCTAssertLessThanOrEqual(count, cap, "\(id.rawValue) exceeded its cap, seed \(seed)")
            }
        }
    }

    /// A guarded site is guarded by **something local** — the most formidable animal the world
    /// grew, rather than a creature from nowhere standing in a world that made everything else.
    func testGuardedSitesGetTheirGuardianAndItBelongsThere() {
        for seed in UInt64(1)...120 {
            let world = Worldgen.generate(
                book: BoundBook(symbols: [SlotID(rawValue: "bounty"): SymbolID(rawValue: "teeming_life")],
                                randomlyFilled: [], essencePaid: 0), seed: seed)
            let dearest = world.cast.map { $0.traits.appetite }.max() ?? 0
            for site in world.sites {
                guard site.definition?.contents.guardian != nil else { continue }
                guard let guardian = world.enemies.first(where: { $0.position == site.position }) else {
                    XCTFail("\(site.siteID.rawValue) went unguarded, seed \(seed)")
                    continue
                }
                XCTAssertTrue(world.cast.contains { $0.id == guardian.speciesID },
                              "the guardian isn't one of this world's animals, seed \(seed)")
                XCTAssertEqual(world.cast.first { $0.id == guardian.speciesID }?.traits.appetite ?? -1,
                               dearest, accuracy: 0.001,
                               "a ruin got an ordinary tenant rather than the world's worst thing")
            }
        }
    }

    // MARK: Instability

    func testValuableSitesDestabiliseTheWorldTheyreIn() {
        // Greed is charged on the world's total value, not on the substrate symbol alone.
        let sites = [PlacedSite(id: InstanceID(rawValue: 1),
                                siteID: SiteID(rawValue: "crystal_cavern"),
                                position: GridPoint(x: 1, y: 1),
                                searchTurnsRemaining: 3)]
        XCTAssertLessThan(SiteRules.stabilityDelta(of: sites), 0)
        XCTAssertEqual(SiteRules.stabilityDelta(of: []), 0)
    }

    /// **The loaded gun** (`comprehensive-audit.md` §4).
    ///
    /// `sites.json` carries real `stabilityDelta` values — landmark −8, living −5, hazard −12 — and
    /// `SiteRules.stabilityDelta` is built, tested, and *deliberately not wired*. Q19 chose guarding
    /// now and derived instability later, and this is that decision held rather than drifted.
    ///
    /// The audit's point was that the comment saying so lives in Swift while the values live in
    /// JSON, and those are read by different people. **A comment can't fail; this can.** The moment
    /// somebody adds the call, sites start destabilising worlds and the ruling silently reverses —
    /// so it has to reverse *loudly*, by breaking here.
    @MainActor
    func testWhatASiteWouldCostIsAuthoredAndDeliberatelyNotCharged() throws {
        let authored = ContentCatalog.shared.sites.filter { $0.stabilityDelta != 0 }
        XCTAssertFalse(authored.isEmpty, "sites.json stopped carrying the values Q19 is waiting on")

        let store = GameStore(io: .temporary(name: "q19-\(UUID().uuidString)"))
        store.write("caverns")
        store.bindAndDepart()
        let run = try XCTUnwrap(store.state.worlds.activeRun)

        XCTAssertEqual(run.effectiveStabilityScore,
                       BookRules.resolvedStabilityScore(of: run.book, seed: run.mapSeed),
                       "a site moved the headline — Q19 says the book's own words move it and "
                       + "nothing else, until the preview is allowed to show what a world contains")
    }

    // MARK: Searching

    @MainActor
    func testSearchingTakesItsTurnsBeforeItPaysOut() throws {
        let (store, site) = try makeStoreInWorld {
            ($0.definition?.contents.searchTurns ?? 0) > 1 && ($0.definition?.contents.essence ?? 0) > 0
        }
        guard let definition = site.definition else { return XCTFail("site lost its definition") }

        // Stand on it, with nothing in the way.
        store.mutate("test: teleport") { state in
            state.worlds.activeRun?.playerPosition = site.position
            state.worlds.activeRun?.enemies.removeAll()
            state.worlds.activeRun?.stability = Tuning.World.startingStability
        }

        // Driven off live state rather than off the definition: what matters is that *this* site
        // pays nothing until it opens, however many turns it happens to have left.
        let essenceBefore = store.state.base.essence
        var turnsSpent = 0
        while let live = store.state.worlds.activeRun?.sites.first(where: { $0.id == site.id }),
              !live.isLooted, turnsSpent < 10 {
            turnsSpent += 1
            store.searchSite()
            let after = store.state.worlds.activeRun?.sites.first { $0.id == site.id }
            if after?.isLooted != true {
                XCTAssertEqual(store.state.base.essence, essenceBefore,
                               "paid out with \(after?.searchTurnsRemaining ?? 0) turns still owed")
            }
        }

        XCTAssertGreaterThan(turnsSpent, 1, "this site was chosen for taking more than one turn")
        XCTAssertTrue(store.state.worlds.activeRun?.sites.first { $0.id == site.id }?.isLooted ?? false)
        XCTAssertEqual(store.state.base.essence, essenceBefore + definition.contents.essence)
        XCTAssertNil(store.searchableHere, "a looted site is still offering to be searched")
    }

    @MainActor
    func testAGuardianBlocksTheSearch() throws {
        let (store, site) = try makeStoreInWorld { _ in true }
        store.mutate("test: teleport") { state in
            state.worlds.activeRun?.playerPosition = site.position
            state.worlds.activeRun?.enemies.append(
                WorldEnemy(id: InstanceID(rawValue: 999),
                           creatureID: CreatureID(rawValue: "ink_hound"),
                           position: site.position))
        }
        let before = store.state.worlds.activeRun?.turnsTaken ?? 0
        store.searchSite()
        XCTAssertEqual(store.state.worlds.activeRun?.turnsTaken, before,
                       "searching under a guardian shouldn't even cost a turn")
    }

    @MainActor
    func testReliquaryRecoversMoreFromAuthoredSiteYields() throws {
        let (store, site) = try makeStoreInWorld {
            !($0.definition?.contents.yields.isEmpty ?? true)
        }
        let yields = try XCTUnwrap(site.definition?.contents.yields)
        store.mutate("test: build reliquary and enter site") { state in
            state.base.stations[Stations.reliquary] = StationState(isUnlocked: true, tier: 0)
            state.worlds.activeRun?.playerPosition = site.position
            state.worlds.activeRun?.enemies.removeAll()
        }
        for _ in 0..<(site.definition?.contents.searchTurns ?? 1) { store.searchSite() }
        for (resource, authored) in yields {
            XCTAssertEqual(store.state.worlds.activeRun?.satchel[resource],
                           authored + Tuning.Economy.reliquarySiteYieldBonus)
        }
    }

    @MainActor
    func testTaughtSymbolsSurviveTheWorldTheyWereFoundIn() throws {
        // Literacy is permanent (rune spec §1): knowledge banks to Base immediately rather than
        // riding home in the satchel, so a collapse can't take it back.
        let (store, site) = try makeStoreInWorld { !($0.definition?.contents.teaches.isEmpty ?? true) }
        guard let taught = site.definition?.contents.teaches.first else {
            return XCTFail("site lost what it teaches")
        }

        store.mutate("test: forget") { state in
            state.base.ownedSymbols.remove(taught)
            state.worlds.activeRun?.stability = Tuning.World.startingStability
            state.worlds.activeRun?.playerPosition = site.position
            // Clear the board entirely: this test is about literacy surviving a collapse, and a
            // wandering enemy interrupting the search would fail it for the wrong reason.
            state.worlds.activeRun?.enemies.removeAll()
        }
        for _ in 0..<(site.definition?.contents.searchTurns ?? 1) { store.searchSite() }
        XCTAssertTrue(store.state.base.ownedSymbols.contains(taught),
                      "searching a teaching site didn't teach: \(store.recentEvents)")

        // Collapse the world out from under them: literacy must not be part of the haul.
        store.mutate("test: collapse") { state in state.worlds.activeRun?.stability = 0 }
        if let run = store.state.worlds.activeRun {
            store.step(to: run.map.neighbours(of: run.playerPosition).first ?? run.playerPosition)
        }
        XCTAssertTrue(store.state.base.ownedSymbols.contains(taught),
                      "a collapse took back something the player had learned")
    }

    // MARK: Helpers

    /// Departs repeatedly until it lands in a world whose sites satisfy `wanted`.
    ///
    /// The seed sequence belongs to the save rather than to the caller, so tests hunt for the
    /// world they need instead of dictating it — which also proves such worlds are actually
    /// reachable through the ordinary loop rather than only in a constructed one.
    @MainActor
    private func makeStoreInWorld(matching wanted: (PlacedSite) -> Bool,
                                  attempts: Int = 60) throws -> (GameStore, PlacedSite) {
        let store = GameStore(io: .temporary(name: "sites-\(UUID().uuidString)"))
        // One slot written, the rest left to chance — so departures range over genuinely different
        // worlds and the site being hunted is actually reachable. Pinning the whole book made these
        // tests skip instead of run, which is barely better than not having them.
        store.write("plains")
        for _ in 0..<attempts {
            store.mutate("test: fund") { state in state.base.essence = 500 }
            store.bindAndDepart()
            if let site = store.state.worlds.activeRun?.sites.first(where: wanted) {
                // Take the teeth out *after* generation: these tests are about how sites behave,
                // and a world that collapses or kills you mid-search fails them for reasons that
                // have nothing to do with sites.
                store.mutate("test: becalm") { state in
                    state.worlds.activeRun?.stability = Tuning.World.startingStability
                    state.worlds.activeRun?.enemies.removeAll()
                    state.worlds.activeRun?.binderHP = Tuning.Encounter.binderMaxHP
                }
                return (store, site)
            }
            store.mutate("test: next world") { state in state.worlds.activeRun = nil }
        }
        throw XCTSkip("no world in \(attempts) departures held the site this test needs")
    }
}
