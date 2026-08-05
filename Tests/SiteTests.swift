import XCTest
@testable import Bookbinder

/// Sites — the fourth layer. What a world *contains*, as opposed to what it *is*.
final class SiteTests: XCTestCase {

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
                XCTAssertNotEqual(site.position, world.start, "site on the entry portal, seed \(seed)")
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

    func testGuardedSitesGetTheirGuardian() {
        for seed in UInt64(1)...120 {
            let world = Worldgen.generate(
                book: BoundBook(symbols: [SlotID(rawValue: "bounty"): SymbolID(rawValue: "teeming_life")],
                                randomlyFilled: [], essencePaid: 0), seed: seed)
            for site in world.sites {
                guard let guardian = site.definition?.contents.guardian else { continue }
                XCTAssertTrue(
                    world.enemies.contains { $0.position == site.position && $0.creatureID == guardian },
                    "\(site.siteID.rawValue) went unguarded, seed \(seed)")
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
    func testTaughtSymbolsSurviveTheWorldTheyWereFoundIn() throws {
        // Literacy is permanent (rune spec §1): knowledge banks to Base immediately rather than
        // riding home in the satchel, so a collapse can't take it back.
        let (store, site) = try makeStoreInWorld { !($0.definition?.contents.teaches.isEmpty ?? true) }
        guard let taught = site.definition?.contents.teaches.first else {
            return XCTFail("site lost what it teaches")
        }

        store.mutate("test: forget") { state in
            state.base.ownedSymbols.remove(taught)
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
        store.setSymbol("plains", in: "terrain")
        for _ in 0..<attempts {
            store.mutate("test: fund") { state in state.base.essence = 500 }
            store.bindAndDepart()
            if let site = store.state.worlds.activeRun?.sites.first(where: wanted) {
                return (store, site)
            }
            store.mutate("test: next world") { state in state.worlds.activeRun = nil }
        }
        throw XCTSkip("no world in \(attempts) departures held the site this test needs")
    }
}
