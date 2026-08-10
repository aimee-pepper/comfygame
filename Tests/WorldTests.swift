import XCTest
@testable import Bookbinder

/// Worldgen determinism, movement, decay, and the rules that end a run.
final class WorldTests: XCTestCase {

    private let owned = Set(ContentCatalog.shared.starterSymbolIDs)

    private func book(_ symbols: [SlotID: SymbolID]) -> BoundBook {
        BoundBook(symbols: symbols, randomlyFilled: [], essencePaid: 0)
    }

    // MARK: Worldgen

    func testSameSeedRegeneratesTheSameWorld() {
        let composition = book(["terrain": "caverns", "biome": "ashen", "bounty": "rich_ore", "quirk": "gilded_veins"])
        let first = Worldgen.generate(book: composition, seed: 8_675_309)
        let second = Worldgen.generate(book: composition, seed: 8_675_309)

        XCTAssertEqual(first.map, second.map)
        XCTAssertEqual(first.enemies, second.enemies)
        XCTAssertEqual(first.start, second.start)
    }

    func testDifferentSeedsGiveDifferentWorlds() {
        let composition = book(["terrain": "plains"])
        XCTAssertNotEqual(Worldgen.generate(book: composition, seed: 1).map,
                          Worldgen.generate(book: composition, seed: 2).map)
    }

    /// Acceptance criterion: two books with different symbols must produce visibly different worlds.
    func testGreedyBooksProduceDenserMoreDangerousWorlds() {
        // Averaged over seeds — any single world can be an outlier.
        var calmNodes = 0, greedyNodes = 0, calmEnemies = 0, greedyEnemies = 0
        // **Same terrain and biome on both sides**, so only the greed dials differ — the bounty and
        // the quirk. Population answers to vitality now (Aimee, 6 Aug), so a pairing that also
        // swapped verdant for ashen would be measuring how *alive* the two worlds are rather than
        // how greedy, and an ash-choked world genuinely should hold less.
        let calm = book(["terrain": "plains", "biome": "verdant", "bounty": "sparse_ore", "quirk": "dim_sky"])
        let greedy = book(["terrain": "plains", "biome": "verdant", "bounty": "rich_ore", "quirk": "gilded_veins"])

        for seed in (1...25).map({ UInt64($0) &* 1_000_003 }) {
            let a = Worldgen.generate(book: calm, seed: seed)
            let b = Worldgen.generate(book: greedy, seed: seed)
            calmNodes += a.map.tiles.count { if case .node = $0.content { true } else { false } }
            greedyNodes += b.map.tiles.count { if case .node = $0.content { true } else { false } }
            calmEnemies += a.enemies.count
            greedyEnemies += b.enemies.count
        }

        XCTAssertGreaterThan(greedyNodes, calmNodes, "A greedier book must put more on the ground")
        XCTAssertGreaterThan(greedyEnemies, calmEnemies, "…and more in the way")
    }

    func testEveryWorldHasAnEntryAndAtLeastOneOtherPortal() {
        for seed in (1...30).map({ UInt64($0) &* 65_537 }) {
            let world = Worldgen.generate(book: book(["terrain": "plains"]), seed: seed)
            XCTAssertEqual(world.map[world.start].content, .portal(isEntry: true))
            let portals = world.map.tiles.count { $0.content.isPortal }
            XCTAssertGreaterThanOrEqual(portals, 2, "Brief requires at least one exit besides the entry")
        }
    }

    func testNothingIsPlacedOnTopOfAnythingElse() {
        let world = Worldgen.generate(book: book(["bounty": "teeming_life"]), seed: 4242)
        var seen = Set<GridPoint>()
        for point in world.map.allPoints where world.map[point].content != .empty {
            XCTAssertTrue(seen.insert(point).inserted)
        }
        // A guardian stands *on* its site — the fight is the price of the search, not a separate
        // mechanic (`sites-system.md`). Everything else stands on open ground.
        let guarded = Set(world.sites.filter { $0.definition?.contents.guardian != nil }.map(\.position))
        for enemy in world.enemies where !guarded.contains(enemy.position) {
            XCTAssertEqual(world.map[enemy.position].content, .empty, "Enemies stand on open ground")
        }
    }

    func testYouDoNotArriveNextToAnEnemy() {
        for seed in (1...30).map({ UInt64($0) &* 2_654_435_761 }) {
            let world = Worldgen.generate(book: book(["biome": "ashen"]), seed: seed)
            for enemy in world.enemies {
                XCTAssertGreaterThanOrEqual(
                    enemy.position.chebyshevDistance(to: world.start),
                    Tuning.World.enemyFreeRadiusAroundEntry,
                    "No ambush the moment you arrive"
                )
            }
        }
    }

    /// Dim Sky's paired tradeoff: a longer-lived world costs you a ring of sight.
    func testDimSkyReducesVision() {
        let plain = book(["terrain": "plains"])
        let dim = book(["terrain": "plains", "quirk": "dim_sky"])
        XCTAssertLessThan(WorldRules.visionRadius(for: dim), WorldRules.visionRadius(for: plain))
        XCTAssertGreaterThanOrEqual(WorldRules.visionRadius(for: dim), Tuning.World.minimumVisionRadius)

        // Measure the two radii on deliberately open ground. A generated fixture makes this claim
        // depend on whichever chance-filled focuses happen to exist in the content catalogue: a
        // ridge or thicket beside the entry can hide both outer rings and make the counts equal.
        let centre = GridPoint(x: 5, y: 5)
        let openMap = WorldMap(width: 11, height: 11,
                               tiles: Array(repeating: Tile(), count: 121), entry: centre)
        func revealed(radius: Int) -> Int {
            var map = openMap
            WorldRules.reveal(around: centre, in: &map, radius: radius)
            return map.revealedCount
        }
        XCTAssertLessThan(revealed(radius: WorldRules.visionRadius(for: dim)),
                          revealed(radius: WorldRules.visionRadius(for: plain)),
                          "You arrive seeing less of a dim world")
    }

    func testExpeditionTuningChangesProjectionAndIsSnapshottedOnTheRun() throws {
        let composition = book(["terrain": "plains"])
        var tuning = DebugTuningProfile.defaults
        tuning.stabilityDurationMultiplier = 2
        tuning.collapseRecoveryFraction = 1
        tuning.baseVisionRadius = 6
        tuning.slowGroundExtraTurns = 3
        tuning.activeFloraFrequencyMultiplier = 0
        tuning.floraHazardSeverityMultiplier = 2

        let ordinary = BookProjection.project(page: Page(), seed: 991)
        let tuned = BookProjection.project(page: Page(), seed: 991, tuning: tuning)
        XCTAssertEqual(tuned.turnsUntilCollapse.lowerBound,
                       ordinary.turnsUntilCollapse.lowerBound * 2)
        XCTAssertGreaterThan(tuned.visionRadius.lowerBound, ordinary.visionRadius.lowerBound)

        let generated = Worldgen.generate(book: composition, seed: 991, tuning: tuning)
        let run = WorldRun(runIndex: 1, book: composition, mapSeed: 991,
                           rng: SeededRNG(seed: 991), map: generated.map,
                           playerPosition: generated.start, tuning: tuning)
        let baseline = WorldRun(runIndex: 1, book: composition, mapSeed: 991,
                                rng: SeededRNG(seed: 991), map: generated.map,
                                playerPosition: generated.start)
        XCTAssertEqual(run.decayPerTurn, baseline.decayPerTurn / 2, accuracy: 0.000_001)
        XCTAssertGreaterThan(WorldRules.visionRadius(in: run), WorldRules.visionRadius(in: baseline))

        let data = try SaveCodec.makeEncoder().encode(run)
        XCTAssertEqual(try SaveCodec.makeDecoder().decode(WorldRun.self, from: data).tuning, tuning)
    }

    func testSlowGroundDebugCostUsesTheRunSnapshot() {
        XCTAssertEqual(WorldRules.movementCost(.growth, slowGroundExtraTurns: 0), 1)
        XCTAssertEqual(WorldRules.movementCost(.mud, slowGroundExtraTurns: 3), 4)
        XCTAssertEqual(WorldRules.movementCost(.stone, slowGroundExtraTurns: 3), 1)
    }

    func testZeroApexMultiplierActuallyMeansNone() {
        var tuning = DebugTuningProfile.defaults
        tuning.apexChanceMultiplier = 0
        let greedy = book(["terrain": "caverns", "biome": "verdant",
                           "bounty": "rich_ore", "quirk": "gilded_veins"])
        for seed in UInt64(1)...40 {
            XCTAssertFalse(Worldgen.generate(book: greedy, seed: seed, tuning: tuning)
                .enemies.contains(where: \.isApex))
        }
    }

    func testGenerationDiagnosticsAreDeterministicAndSurviveMutableMapChanges() throws {
        var tuning = DebugTuningProfile.defaults
        tuning.additionalPageChance = 1
        let composition = book(["terrain": "plains", "biome": "verdant"])
        let first = Worldgen.generate(book: composition, seed: 20_260_809, tuning: tuning)
        let again = Worldgen.generate(book: composition, seed: 20_260_809, tuning: tuning)

        XCTAssertEqual(first.diagnostics, again.diagnostics)
        XCTAssertEqual(first.diagnostics.placedDiaryPages, first.pages)
        XCTAssertEqual(first.diagnostics.placedOtherWritings, first.writings.map(\.id))
        XCTAssertEqual(first.diagnostics.rawEssenceDropsPlaced,
                       first.map.tiles.count {
                           if case .wildDrop(let resource, _) = $0.content {
                               return resource == Resources.essenceRaw
                           }
                           return false
                       })

        var run = WorldRun(runIndex: 1, book: composition, mapSeed: 20_260_809,
                           rng: SeededRNG(seed: 20_260_809), map: first.map,
                           playerPosition: first.start,
                           generationDiagnostics: first.diagnostics, tuning: tuning)
        if let page = run.map.allPoints.first(where: {
            if case .diaryPage = run.map[$0].content { return true }
            return false
        }) {
            run.map[page].content = .empty
        }
        XCTAssertEqual(run.generationDiagnostics.placedDiaryPages,
                       first.diagnostics.placedDiaryPages,
                       "Initial placement is a snapshot, not a scan of collectible tiles")

        let data = try SaveCodec.makeEncoder().encode(run)
        XCTAssertEqual(try SaveCodec.makeDecoder().decode(WorldRun.self, from: data)
            .generationDiagnostics, first.diagnostics)
    }

    func testOpeningEnvelopeRelocatesRatherThanDeletesOnlyOnFreshFirstExpedition() throws {
        let composition = book(["terrain": "plains", "biome": "teeming_life"])
        var clear = DebugTuningProfile.defaults
        clear.creatureDensityMultiplier = 3
        clear.baseVisionRadius = 6
        clear.openingEncounterEnvelope = .clearApproach

        let seed = try XCTUnwrap((UInt64(1)...500).first { candidate in
            let world = Worldgen.generate(book: composition, seed: candidate, tuning: clear,
                                          isFreshFirstExpedition: false)
            return world.enemies.count { enemy in
                world.map[enemy.position].isRevealed && !enemy.isSessile && !enemy.isApex
                    && !world.sites.map(\.position).contains(enemy.position)
            } >= 2
        })
        let natural = Worldgen.generate(book: composition, seed: seed, tuning: clear,
                                        isFreshFirstExpedition: false)
        let protectedPositions = Set(natural.sites.map(\.position))
        let protectedEnemies = natural.enemies.filter {
            $0.isSessile || $0.isApex || protectedPositions.contains($0.position)
        }

        let cleared = Worldgen.generate(book: composition, seed: seed, tuning: clear,
                                        isFreshFirstExpedition: true)
        XCTAssertEqual(cleared.enemies.count, natural.enemies.count)
        XCTAssertEqual(cleared.enemies.filter { $0.isSessile || $0.isApex
            || protectedPositions.contains($0.position) }, protectedEnemies)
        XCTAssertFalse(cleared.enemies.contains {
            cleared.map[$0.position].isRevealed && !$0.isSessile && !$0.isApex
                && !protectedPositions.contains($0.position)
        })
        XCTAssertTrue(cleared.diagnostics.openingEnvelopeApplied)
        XCTAssertGreaterThan(cleared.diagnostics.openingEnemiesRelocated, 0)

        let ignored = Worldgen.generate(book: composition, seed: seed, tuning: clear,
                                        isFreshFirstExpedition: false)
        XCTAssertEqual(ignored.enemies, natural.enemies)
        XCTAssertFalse(ignored.diagnostics.openingEnvelopeApplied)

        var gentle = clear
        gentle.openingEncounterEnvelope = .gentle
        let softened = Worldgen.generate(book: composition, seed: seed, tuning: gentle,
                                         isFreshFirstExpedition: true)
        XCTAssertLessThanOrEqual(softened.enemies.count {
            softened.map[$0.position].isRevealed && !$0.isSessile && !$0.isApex
                && !protectedPositions.contains($0.position)
        }, 1)
        XCTAssertEqual(softened.enemies.count, natural.enemies.count)
    }

    // MARK: Fog and movement

    func testFogRevealsAroundThePlayerAndStaysRevealed() {
        var state = startedRun(book(["terrain": "plains"]), seed: 31)
        let run = state.worlds.activeRun!
        let start = run.playerPosition
        XCTAssertTrue(run.map[start].isRevealed)

        let step = run.map.neighbours(of: start).first { WorldRules.canEnter($0, in: run.map) }!
        _ = WorldRules.step(to: step, in: &state)
        let after = state.worlds.activeRun!

        XCTAssertTrue(after.map[start].isRevealed, "Revealed tiles stay revealed")
        XCTAssertTrue(after.map[step].isRevealed)
        XCTAssertEqual(after.playerPosition, step)
    }

    func testAStepIsExactlyOneTurn() {
        var state = startedRun(book(["terrain": "plains"]), seed: 12)
        let before = state.worlds.activeRun!
        let step = before.map.neighbours(of: before.playerPosition).first { WorldRules.canEnter($0, in: before.map) }!

        _ = WorldRules.step(to: step, in: &state)
        let after = state.worlds.activeRun!

        XCTAssertEqual(after.turnsTaken, before.turnsTaken + 1)
        XCTAssertEqual(after.stability, before.stability - BookRules.decayPerTurn(for: before.book), accuracy: 0.0001)
    }

    func testTallGrowthAndMudEachCostTwoTurns() {
        for ground in [GroundType.growth, .mud] {
            var state = startedRun(book(["terrain": "plains"]), seed: 120)
            let before = state.worlds.activeRun!
            let step = before.map.neighbours(of: before.playerPosition)
                .first { WorldRules.canEnter($0, in: before.map) }!
            state.worlds.activeRun?.map[step].ground = ground

            let events = WorldRules.step(to: step, in: &state)

            XCTAssertEqual(state.worlds.activeRun?.turnsTaken, before.turnsTaken + 2)
            XCTAssertTrue(events.contains(.enteredSlowGround(ground.displayName)))
        }
    }

    func testPathfindingPrefersAQuickerRouteAroundSlowGround() {
        var map = WorldMap(width: 5, height: 3,
                           tiles: Array(repeating: Tile(), count: 15),
                           entry: GridPoint(x: 0, y: 1))
        let start = GridPoint(x: 0, y: 1)
        let destination = GridPoint(x: 4, y: 1)
        for x in 1...3 { map[GridPoint(x: x, y: 1)].ground = .growth }

        let route = WorldRules.path(from: start, to: destination, in: map)

        XCTAssertFalse(route.dropLast().contains { map[$0].ground == .growth },
                       "the route chose fewer squares even though they cost more turns")
        XCTAssertEqual(route.last, destination)

        let freeSlowRoute = WorldRules.path(from: start, to: destination, in: map,
                                            slowGroundExtraTurns: 0)
        XCTAssertTrue(freeSlowRoute.dropLast().contains { map[$0].ground == .growth },
                      "path weights ignored the zero-extra-turn run snapshot")
    }

    func testNonAdjacentStepsAreRefused() {
        var state = startedRun(book(["terrain": "plains"]), seed: 13)
        let run = state.worlds.activeRun!
        let far = run.map.allPoints.first { $0.manhattanDistance(to: run.playerPosition) > 3 }!

        let events = WorldRules.step(to: far, in: &state)
        XCTAssertEqual(state.worlds.activeRun?.playerPosition, run.playerPosition)
        XCTAssertEqual(state.worlds.activeRun?.turnsTaken, 0, "A refused move must not burn a turn")
        XCTAssertTrue(events.contains { if case .blocked = $0 { true } else { false } })
    }

    func testPathfindingReachesAndRoutesAroundCrumbledGround() {
        var state = startedRun(book(["terrain": "plains"]), seed: 14)
        var run = state.worlds.activeRun!
        let start = run.playerPosition
        let target = run.map.allPoints.last { $0 != start && WorldRules.canEnter($0, in: run.map) }!

        let route = WorldRules.path(from: start, to: target, in: run.map)
        XCTAssertFalse(route.isEmpty)
        XCTAssertEqual(route.last, target)
        for (index, point) in route.enumerated() {
            let previous = index == 0 ? start : route[index - 1]
            XCTAssertTrue(WorldRules.isAdjacent(previous, point), "Every path step must be one tile")
        }

        // Wall off a neighbour and confirm the route never crosses crumbled ground.
        for neighbour in run.map.neighbours(of: start).dropLast() {
            run.map[neighbour].isCrumbled = true
        }
        state.worlds.activeRun = run
        let detour = WorldRules.path(from: start, to: target, in: run.map)
        for point in detour {
            XCTAssertFalse(run.map[point].isCrumbled)
        }
    }

    // MARK: Harvesting

    func testHarvestingFillsTheSatchelAndExhaustsTheNode() throws {
        var state = startedRun(book(["bounty": "teeming_life"]), seed: 99)
        var run = state.worlds.activeRun!
        // Put a known node under the player rather than hunting the map for one.
        run.map[run.playerPosition].content = .node(ResourceNode(resource: Resources.fiber,
                                                                 remainingHarvests: 2,
                                                                 yieldPerHarvest: 3))
        state.worlds.activeRun = run

        _ = WorldRules.harvest(in: &state)
        XCTAssertEqual(state.worlds.activeRun?.satchel[Resources.fiber], 3)
        XCTAssertEqual(state.worlds.activeRun?.turnsTaken, 1, "A pull costs a turn")
        XCTAssertTrue(state.reality.discovery.hasEncountered(resource: Resources.fiber),
                      "Harvesting logs the resource for the preview's silhouettes")

        _ = WorldRules.harvest(in: &state)
        XCTAssertEqual(state.worlds.activeRun?.satchel[Resources.fiber], 6)
        XCTAssertEqual(state.worlds.activeRun?.map[state.worlds.activeRun!.playerPosition].content, .empty,
                       "A spent node clears itself off the map")
    }

    func testWayfarersTableImprovesOrganicHarvestAndPacking() throws {
        var state = startedRun(book(["bounty": "teeming_life"]), seed: 99)
        let ordinaryCapacity = state.base.satchelCapacity
        state.base.stations[Stations.wayfarersTable] = StationState(isUnlocked: true, tier: 0)
        XCTAssertEqual(state.base.satchelCapacity,
                       ordinaryCapacity + Tuning.Economy.fieldcraftSatchelBonus)

        var run = try XCTUnwrap(state.worlds.activeRun)
        run.map[run.playerPosition].content = .node(ResourceNode(resource: Resources.fiber,
                                                                 remainingHarvests: 1,
                                                                 yieldPerHarvest: 3))
        state.worlds.activeRun = run
        _ = WorldRules.harvest(in: &state)
        XCTAssertEqual(state.worlds.activeRun?.satchel[Resources.fiber],
                       3 + Tuning.Economy.fieldcraftOrganicYieldBonus)
    }

    func testWildDropsArePickedUpByWalkingOverThem() {
        var state = startedRun(book(["terrain": "plains"]), seed: 21)
        var run = state.worlds.activeRun!
        let target = run.map.neighbours(of: run.playerPosition).first { WorldRules.canEnter($0, in: run.map) }!
        run.map[target].content = .wildDrop(resource: Resources.essenceRaw, amount: 2)
        state.worlds.activeRun = run

        _ = WorldRules.step(to: target, in: &state)
        XCTAssertEqual(state.worlds.activeRun?.satchel[Resources.essenceRaw], 2)
        XCTAssertEqual(state.worlds.activeRun?.map[target].content, .empty, "A wild drop is taken, not left")
    }

    // MARK: The world turning against you

    func testHazardsOnlyAppearOnceStabilityFalls() {
        var state = startedRun(book(["terrain": "plains"]), seed: 55)
        func hazardCount() -> Int { state.worlds.activeRun?.map.tiles.count { $0.content == .hazard } ?? 0 }

        // Well above the threshold: nothing changes.
        for _ in 0..<3 { _ = WorldRules.advanceTurn(in: &state) }
        XCTAssertEqual(hazardCount(), 0)

        // Drop below it and the edges start turning.
        state.worlds.activeRun?.stability = Tuning.World.hazardThreshold - 1
        for _ in 0..<6 { _ = WorldRules.advanceTurn(in: &state) }
        XCTAssertGreaterThan(hazardCount(), 0, "Past the threshold, hazards spawn at the edges")
    }

    func testCrumblingWarnsTheOutsideRingBeforeItFalls() {
        var state = startedRun(book(["terrain": "plains"]), seed: 56)
        state.worlds.activeRun?.stability = Tuning.World.crumbleThreshold - 1
        state.worlds.activeRun?.playerPosition = GridPoint(x: 7, y: 7) // middle of the map

        _ = WorldRules.advanceTurn(in: &state)
        let run = state.worlds.activeRun!

        let cracking = run.map.allPoints.filter { run.map[$0].isCracking }
        XCTAssertFalse(cracking.isEmpty)
        XCTAssertTrue(run.map.allPoints.allSatisfy { !run.map[$0].isCrumbled },
                      "a tile vanished on the same turn its warning appeared")
        for point in cracking {
            XCTAssertEqual(run.map.ring(of: point), 0, "Crumbling starts at the outermost ring")
        }
    }

    func testThePlayersTileGetsAFullWarningTurnBeforeItFalls() {
        var state = startedRun(book(["terrain": "plains"]), seed: 561)
        state.worlds.activeRun?.stability = 0
        state.worlds.activeRun?.collapsedOnTurn = 0
        guard let player = state.worlds.activeRun?.playerPosition else { return XCTFail("no player") }
        // Leave only the player's block, forcing it to be the next target.
        for point in state.worlds.activeRun!.map.allPoints where point != player {
            state.worlds.activeRun?.map[point].isCrumbled = true
        }

        var events = WorldRules.advanceTurn(in: &state)
        XCTAssertTrue(state.worlds.activeRun?.map[player].isCracking == true)
        XCTAssertFalse(state.worlds.activeRun?.map[player].isCrumbled == true)
        XCTAssertFalse(events.contains(.floorGaveWay))

        events = WorldRules.advanceTurn(in: &state)
        XCTAssertTrue(events.contains(.floorGaveWay))
    }

    func testCrackWarningsDoNotHalveSteadyStateCollapseSpeed() {
        var state = startedRun(book(["terrain": "plains"]), seed: 562)
        state.worlds.activeRun?.stability = 0
        state.worlds.activeRun?.collapsedOnTurn = 0

        _ = WorldRules.advanceTurn(in: &state) // primes the warning pipeline
        guard let primed = state.worlds.activeRun else { return XCTFail("run ended while priming") }
        let expected = WorldRules.crumbleRate(in: primed)
        let before = primed.map.allPoints.count { primed.map[$0].isCrumbled }
        _ = WorldRules.advanceTurn(in: &state)
        guard let afterRun = state.worlds.activeRun else { return XCTFail("run ended too early") }
        let after = afterRun.map.allPoints.count { afterRun.map[$0].isCrumbled }
        XCTAssertEqual(after - before, expected)
        XCTAssertGreaterThan(afterRun.map.allPoints.count { afterRun.map[$0].isCracking }, 0,
                             "collapse removed the warned wave but failed to warn the next one")
    }

    /// The meter emptying is announced — and **does not end the run**. You are still standing in a
    /// world that has begun to come apart, which is the whole of the decision it creates.
    func testCollapseIsAnnouncedAtZeroStabilityAndDoesNotEndTheRun() {
        let composition = book(["terrain": "plains"])
        var state = startedRun(composition, seed: 57)
        // Exactly one turn's worth left, whatever this book's rate happens to be — pinning a
        // literal here would break every time the stability scale is retuned.
        state.worlds.activeRun?.stability = BookRules.decayPerTurn(for: composition)

        let events = WorldRules.advanceTurn(in: &state)
        XCTAssertTrue(events.contains(.collapsed))
        XCTAssertFalse(events.contains(.floorGaveWay),
                       "an empty meter threw the player out of a world that was still there")
        XCTAssertNotNil(state.worlds.activeRun, "the run ended on a number rather than on the floor")
    }

    /// **You are only forced out when the block you're standing on goes.**
    func testYouAreOnlyThrownOutWhenTheFloorUnderYouGoes() {
        var state = startedRun(book(["terrain": "plains"]), seed: 57)
        state.worlds.activeRun?.stability = 0
        state.worlds.activeRun?.collapsedOnTurn = 0

        // Crumble until it reaches the player, which it now can.
        var events: [WorldRules.Event] = []
        for _ in 0..<400 where !events.contains(.floorGaveWay) {
            events = WorldRules.advanceTurn(in: &state)
            guard state.worlds.activeRun != nil else { break }
        }
        XCTAssertTrue(events.contains(.floorGaveWay),
                      "a world crumbled away entirely and never reached the player standing in it")
    }

    /// A collapsed world genuinely runs out rather than nibbling its edges forever.
    func testACollapsedWorldSpeedsUpTheLongerYouStay() {
        var state = startedRun(book(["terrain": "plains"]), seed: 57)
        state.worlds.activeRun?.stability = 0
        state.worlds.activeRun?.collapsedOnTurn = 0
        state.worlds.activeRun?.turnsTaken = 0
        let atOnce = WorldRules.crumbleRate(in: state.worlds.activeRun!)

        state.worlds.activeRun?.turnsTaken = 30
        XCTAssertGreaterThan(WorldRules.crumbleRate(in: state.worlds.activeRun!), atOnce)
    }

    /// **A spared portal is no use behind a wall.** Entry portals sit on the map edge, which is the
    /// first ring to crumble — so sparing the portal tile while eating everything around it left
    /// the player looking at an intact way out they couldn't reach, waiting to be thrown out. Which
    /// is exactly what sparing them was meant to prevent.
    func testAPortalStaysReachableForAsLongAsThePlayerIsStanding() {
        for seed in [UInt64(3), 57, 909] {
            var state = startedRun(book(["terrain": "plains"]), seed: seed)
            state.worlds.activeRun?.stability = 0
            state.worlds.activeRun?.collapsedOnTurn = 0
            // **Standing away from the way out**, which is the whole case. The run starts *on* the
            // entry portal, so a test that leaves the player there proves nothing at all.
            if let run = state.worlds.activeRun {
                let middle = run.map.allPoints
                    .filter { WorldRules.canEnter($0, in: run.map) && !run.map[$0].content.isPortal }
                    .max { run.map.ring(of: $0) < run.map.ring(of: $1) }
                if let middle { state.worlds.activeRun?.playerPosition = middle }
            }
            XCTAssertFalse(state.worlds.activeRun?.map[state.worlds.activeRun!.playerPosition]
                .content.isPortal ?? true, "the player has to start away from a portal")

            for _ in 0..<200 {
                let events = WorldRules.advanceTurn(in: &state)
                guard let run = state.worlds.activeRun, !events.contains(.floorGaveWay) else { break }
                XCTAssertTrue(
                    WorldRules.canReachAPortal(from: run.playerPosition, in: run.map),
                    "seed \(seed): the player was marooned with a portal standing and their own floor intact")
            }
        }
    }

    /// The way out is the last thing to go, or "reach a portal in time" becomes "wait to be thrown
    /// out", which is no decision at all.
    func testPortalsAreTheLastThingToCrumble() {
        var state = startedRun(book(["terrain": "plains"]), seed: 57)
        state.worlds.activeRun?.stability = 0
        state.worlds.activeRun?.collapsedOnTurn = 0

        for _ in 0..<60 {
            _ = WorldRules.advanceTurn(in: &state)
            guard let run = state.worlds.activeRun else { break }
            let portalsGone = run.map.allPoints.contains {
                run.map[$0].isCrumbled && run.map[$0].content.isPortal
            }
            let floorLeft = run.map.allPoints.contains {
                !run.map[$0].isCrumbled && !run.map[$0].content.isPortal
            }
            XCTAssertFalse(portalsGone && floorLeft, "a portal went while there was still floor")
        }
    }

    // MARK: Enemies

    func testEnemiesSleepUntilYouAreCloseThenWalkAtYou() {
        var state = startedRun(book(["terrain": "plains"]), seed: 61)
        var run = state.worlds.activeRun!
        run.enemies = []
        run.playerPosition = GridPoint(x: 7, y: 7)
        let sleeper = GridPoint(x: 7, y: 12) // far away
        run.enemies = [WorldEnemy(id: InstanceID(rawValue: 1), creatureID: "paper_moth", position: sleeper)]
        state.worlds.activeRun = run

        _ = WorldRules.advanceTurn(in: &state)
        XCTAssertEqual(state.worlds.activeRun?.enemies.first?.position, sleeper, "Inert until you come close")
        XCTAssertFalse(state.worlds.activeRun?.enemies.first?.isAwake ?? true)

        // Move it inside the aggro radius and it starts closing.
        state.worlds.activeRun?.enemies[0].position = GridPoint(x: 7, y: 9)
        _ = WorldRules.advanceTurn(in: &state)
        let enemy = state.worlds.activeRun!.enemies[0]
        XCTAssertTrue(enemy.isAwake)
        XCTAssertLessThan(enemy.position.chebyshevDistance(to: GridPoint(x: 7, y: 7)), 2)
    }

    func testWalkingIntoAnEnemyOpensAnEncounterAndLogsTheCreature() {
        var state = startedRun(book(["terrain": "plains"]), seed: 62)
        var run = state.worlds.activeRun!
        let target = run.map.neighbours(of: run.playerPosition).first { WorldRules.canEnter($0, in: run.map) }!
        run.enemies = [WorldEnemy(id: InstanceID(rawValue: 7), creatureID: "ink_hound", position: target, isAwake: true)]
        state.worlds.activeRun = run

        let events = WorldRules.step(to: target, in: &state)
        XCTAssertTrue(events.contains(.encounterBegan))
        XCTAssertNotNil(state.worlds.activeRun?.activeEncounter)
        XCTAssertEqual(state.worlds.activeRun?.activeEncounter?.foes.first?.creatureID, "ink_hound")
        XCTAssertTrue(state.reality.discovery.hasEncountered(creature: "ink_hound"))
    }

    // MARK: Banking

    @MainActor
    func testPortalHomeKeepsEverything() {
        let store = GameStore(io: .temporary(name: "portal-\(UUID().uuidString)"))
        store.write("plains")
        store.bindAndDepart()
        store.mutate("stock the satchel") { $0.worlds.activeRun?.satchel.add(9, of: Resources.ore) }

        XCTAssertTrue(store.canPortalHere)
        store.portalHome()

        XCTAssertNil(store.state.worlds.activeRun)
        XCTAssertEqual(store.state.base.resources[Resources.ore], 9, "Portalling out keeps the lot")
        XCTAssertEqual(store.state.reality.lifetime.runsBankedViaPortal, 1)
    }

    @MainActor
    func testCollapseKeepsOnlyAFractionAndBanksMotesToReality() {
        let store = GameStore(io: .temporary(name: "collapse-\(UUID().uuidString)"))
        store.write("plains")
        store.bindAndDepart()
        store.mutate("stock the satchel") { state in
            state.worlds.activeRun?.satchel.add(10, of: Resources.ore)
            state.worlds.activeRun?.satchel.add(4, of: Resources.mote)
        }

        store.endRunWithPartialHaul(reason: "collapse")

        XCTAssertNil(store.state.worlds.activeRun)
        XCTAssertEqual(store.state.base.resources[Resources.ore],
                       Int(10 * Tuning.World.collapseHaulKeptFraction))
        XCTAssertEqual(store.state.reality.motes, Int(4 * Tuning.World.collapseHaulKeptFraction),
                       "Motes bank to Reality, not Base")
        XCTAssertEqual(store.state.reality.lifetime.runsLostToCollapse, 1)
        XCTAssertEqual(store.state.worlds.lastExit?.kind, .collapse)
        XCTAssertEqual(store.state.worlds.lastExit?.lostResources.reduce(0) { $0 + $1.count }, 7,
                       "the recap should list the five ore and two motes that did not return")
    }

    @MainActor
    func testCollapseUsesTheRecoveryFractionFrozenIntoTheRun() {
        let store = GameStore(io: .temporary(name: "collapse-tuning-\(UUID().uuidString)"))
        store.write("plains")
        store.bindAndDepart()
        store.mutate("tune this fixture") { state in
            state.worlds.activeRun?.tuning.collapseRecoveryFraction = 1
            state.worlds.activeRun?.satchel.add(10, of: Resources.ore)
        }

        store.endRunWithPartialHaul(reason: "collapse")

        XCTAssertEqual(store.state.base.resources[Resources.ore], 10)
        XCTAssertEqual(store.state.worlds.lastExit?.haulKeptFraction, 1)
        XCTAssertTrue(store.state.worlds.lastExit?.lostResources.isEmpty == true)
    }

    @MainActor
    func testDefeatIsNotCountedAsCollapse() {
        let store = GameStore(io: .temporary(name: "defeat-outcome-\(UUID().uuidString)"))
        store.write("plains")
        store.bindAndDepart()

        store.endRunWithPartialHaul(reason: "You were carried home.", kind: .defeat)

        XCTAssertEqual(store.state.worlds.lastExit?.kind, .defeat)
        XCTAssertEqual(store.state.reality.lifetime.runsLostToCollapse, 0)
    }

    func testPartialHaulAlwaysReturnsUnusedStartingItems() {
        var state = GameState.newGame()
        state.base.inventory.stacks = []
        var run = WorldRun(runIndex: 1, book: book([:]), mapSeed: 1, rng: SeededRNG(seed: 1),
                           map: WorldMap(width: 1, height: 1, tiles: [Tile()],
                                         entry: GridPoint(x: 0, y: 0)),
                           playerPosition: GridPoint(x: 0, y: 0))
        var salves = ItemStack(id: InstanceID(rawValue: 10), catalogID: "salve", count: 2)
        salves.protectedReturnCount = 2
        run.satchelItems = Inventory(slots: 4, stacks: [salves])
        var rng = SeededRNG(seed: 3)

        GameStore.bankHaul(of: run, into: &state, fraction: 0, rng: &rng)

        XCTAssertEqual(state.base.inventory.stacks.first { $0.catalogID == "salve" }?.count, 2)
        XCTAssertEqual(state.base.inventory.stacks.first?.protectedReturnCount, 0)
    }

    func testConsumedStartingItemsDoNotDuplicateOnPartialReturn() {
        var state = GameState.newGame()
        state.base.inventory.stacks = []
        var run = WorldRun(runIndex: 1, book: book([:]), mapSeed: 1, rng: SeededRNG(seed: 1),
                           map: WorldMap(width: 1, height: 1, tiles: [Tile()],
                                         entry: GridPoint(x: 0, y: 0)),
                           playerPosition: GridPoint(x: 0, y: 0))
        var salves = ItemStack(id: InstanceID(rawValue: 10), catalogID: "salve", count: 2)
        salves.protectedReturnCount = 2
        _ = salves.removing(1)
        run.satchelItems = Inventory(slots: 4, stacks: [salves])
        var rng = SeededRNG(seed: 3)

        GameStore.bankHaul(of: run, into: &state, fraction: 0, rng: &rng)

        XCTAssertEqual(state.base.inventory.stacks.first { $0.catalogID == "salve" }?.count, 1)
    }

    func testNewLootMergedIntoStartingStackRemainsAtRisk() {
        var state = GameState.newGame()
        state.base.inventory.stacks = []
        var run = WorldRun(runIndex: 1, book: book([:]), mapSeed: 1, rng: SeededRNG(seed: 1),
                           map: WorldMap(width: 1, height: 1, tiles: [Tile()],
                                         entry: GridPoint(x: 0, y: 0)),
                           playerPosition: GridPoint(x: 0, y: 0))
        var salves = ItemStack(id: InstanceID(rawValue: 10), catalogID: "salve", count: 2)
        salves.protectedReturnCount = 2
        run.satchelItems = Inventory(slots: 4, stacks: [salves])
        _ = run.satchelItems.add(ItemStack(id: InstanceID(rawValue: 11), catalogID: "salve", count: 2))
        var rng = SeededRNG(seed: 3)

        let banked = GameStore.bankHaul(of: run, into: &state, fraction: 0, rng: &rng)

        XCTAssertEqual(state.base.inventory.stacks.first { $0.catalogID == "salve" }?.count, 2,
                       "the packed pair returns, while the acquired pair is exposed to loss")
        XCTAssertEqual(banked.lostItems.first { $0.name == "Salve" }?.count, 2)
    }

    /// The pillar, at world scale: a kill mid-run resumes on the same tile of the same map.
    @MainActor
    func testTheWholeMapSurvivesAForceQuit() throws {
        let io = SaveFileIO.temporary(name: "world-kill-\(UUID().uuidString)")
        defer { io.deleteEverything() }

        let first = GameStore(io: io)
        // Every slot filled. This test is about the map surviving a kill, and a book left partly
        // to chance can roll itself a world that collapses inside these five steps — which fails
        // it for a reason that has nothing to do with persistence.
        first.write("caverns")
        first.write("frostbound")
        first.write("sparse_ore")
        first.write("dim_sky")
        first.bindAndDepart()
        // Wander a bit so fog, position and RNG have all moved off their initial values.
        for _ in 0..<5 {
            guard let run = first.state.worlds.activeRun else { break }
            guard let step = run.map.neighbours(of: run.playerPosition)
                .first(where: { WorldRules.canEnter($0, in: run.map) }) else { break }
            first.step(to: step)
        }
        first.flushNow()
        let before = try XCTUnwrap(first.state.worlds.activeRun)

        let second = GameStore(io: io) // cold launch
        let after = try XCTUnwrap(second.state.worlds.activeRun)

        XCTAssertEqual(after.map, before.map)
        XCTAssertEqual(after.playerPosition, before.playerPosition)
        XCTAssertEqual(after.enemies, before.enemies)
        XCTAssertEqual(after.turnsTaken, before.turnsTaken)
        XCTAssertEqual(after.rng, before.rng)
    }

    /// Pillar 2, stated as a test: nothing advances unless the player acts.
    @MainActor
    func testNothingHappensWithoutAPlayerAction() async throws {
        let store = GameStore(io: .temporary(name: "idle-\(UUID().uuidString)"))
        store.write("gilded_veins") // fastest-decaying symbol we have
        store.bindAndDepart()
        let before = try XCTUnwrap(store.state.worlds.activeRun)

        try await Task.sleep(for: .milliseconds(300))

        let after = try XCTUnwrap(store.state.worlds.activeRun)
        XCTAssertEqual(after.stability, before.stability, "Time passing must not decay a world")
        XCTAssertEqual(after.turnsTaken, before.turnsTaken)
        XCTAssertEqual(after.enemies, before.enemies)
    }

    // MARK: Helpers

    private func startedRun(_ composition: BoundBook, seed: UInt64) -> GameState {
        var state = GameState.newGame()
        let world = Worldgen.generate(book: composition, seed: seed)
        state.worlds.runIndex = 1
        state.worlds.activeRun = WorldRun(
            runIndex: 1,
            book: composition,
            mapSeed: seed,
            rng: SeededRNG(seed: seed).derived(0xA11CE),
            map: world.map,
            playerPosition: world.start,
            enemies: world.enemies
        )
        return state
    }

    /// **Stability is a range, because the world is** (Aimee, 6 Aug).
    ///
    /// The headline counted only what you wrote, which is right — the panel must not reveal rolled
    /// content. But every unwritten subject is rolled at bind, and a rolled focus carries its own
    /// stability delta, its own greed, and its own capacity to contradict what you wrote. Six of
    /// eight unwritten is normal, so the number shown could be off by a lot.
    ///
    /// The design is careful about this everywhere else: **the price is certain, the world is not.**
    func testStabilityIsRangedWhileTheWorldIsUnwritten() {
        var page = Page()
        page.runes = [
            PlacedRune(id: InstanceID(rawValue: 1), content: .target("illumination"),
                       hand: .crude, origin: PageCell(column: 0, row: 0), shapeID: "crude_block"),
            PlacedRune(id: InstanceID(rawValue: 2), content: .source("sun"),
                       hand: .crude, origin: PageCell(column: 2, row: 0), shapeID: "crude_block"),
        ]
        page.links = [MarkLink(InstanceID(rawValue: 1), InstanceID(rawValue: 2))]

        let sparse = BookProjection.project(page: page, seed: 99)
        XCTAssertLessThan(sparse.stabilityScore.lowerBound, sparse.stabilityScore.upperBound,
                          "one subject written of eight and stability is shown as a certainty")
        XCTAssertLessThanOrEqual(sparse.turnsUntilCollapse.lowerBound,
                                 sparse.turnsUntilCollapse.upperBound)
    }

    /// Write every subject and there is nothing left to roll — so the band closes to a point, and
    /// the promise "the price is certain, the world is not" becomes "and you can make it certain".
    func testAFullyWrittenPageIsCertain() {
        var page = Page()
        var next: UInt64 = 1
        let pairs: [(PressureTargetID, PressureSourceID)] = [
            ("illumination", "sun"), ("thermal", "magma"), ("hydrology", "sea"),
            ("substrate", "granite"), ("relief", "granite"), ("vitality", "root"),
            ("atmosphere", "wind"), ("cycle", "moon"),
        ]
        for (index, pair) in pairs.enumerated() {
            page.runes.append(PlacedRune(id: InstanceID(rawValue: next), content: .target(pair.0),
                                         hand: .crude, origin: PageCell(column: 0, row: index),
                                         shapeID: "refined_dot"))
            let target = next
            next += 1
            page.runes.append(PlacedRune(id: InstanceID(rawValue: next), content: .source(pair.1),
                                         hand: .crude, origin: PageCell(column: 1, row: index),
                                         shapeID: "refined_dot"))
            page.links.insert(MarkLink(InstanceID(rawValue: target), InstanceID(rawValue: next)))
            next += 1
        }
        XCTAssertTrue(BookProjection.project(page: page, seed: 7).stabilityScore.isPoint,
                      "nothing left unwritten and the world is still uncertain")
    }

    /// **And writing more narrows the band** — which makes the value of specificity a number for
    /// the first time.
    func testWritingMoreSubjectsNarrowsTheStabilityBand() {
        func band(_ subjects: [(PressureTargetID, PressureSourceID)]) -> Int {
            var page = Page()
            var next: UInt64 = 1
            for (index, pair) in subjects.enumerated() {
                page.runes.append(PlacedRune(id: InstanceID(rawValue: next), content: .target(pair.0),
                                             hand: .crude,
                                             origin: PageCell(column: 0, row: index * 2),
                                             shapeID: "refined_dot"))
                let target = next
                next += 1
                page.runes.append(PlacedRune(id: InstanceID(rawValue: next), content: .source(pair.1),
                                             hand: .crude,
                                             origin: PageCell(column: 1, row: index * 2),
                                             shapeID: "refined_dot"))
                page.links.insert(MarkLink(InstanceID(rawValue: target), InstanceID(rawValue: next)))
                next += 1
            }
            let projection = BookProjection.project(page: page, seed: 4242)
            return projection.stabilityScore.upperBound - projection.stabilityScore.lowerBound
        }

        let one = band([("illumination", "sun")])
        let many = band([("illumination", "sun"), ("thermal", "magma"), ("hydrology", "sea"),
                         ("substrate", "granite"), ("relief", "granite"), ("vitality", "root"),
                         ("atmosphere", "wind"), ("cycle", "moon")])
        XCTAssertLessThan(many, one,
                          "writing every subject left as much uncertainty as writing one")
    }

    func testReportWhatEachFocusCostsNow() {
        let cases: [(PressureSourceID, PressureTargetID)] = [
            ("sun","illumination"), ("gold","substrate"), ("magma","illumination"),
            ("root","vitality"), ("crystal","illumination"), ("sea","hydrology"),
            ("granite","substrate"), ("ice","hydrology"), ("wind","atmosphere"),
            ("salt","vitality"), ("granite","relief"),
        ]
        print("WHAT A FOCUS COSTS (was: sun −25, gold −18, wind +16)")
        for (source, target) in cases {
            let cost = BookRules.greedDelta(for: [Sigil(id: InstanceID(rawValue: 1),
                                                        source: source, target: target)])
            print(String(format: "  %-10s on %-13s %+d", (source.rawValue as NSString).utf8String!,
                         (target.rawValue as NSString).utf8String!, cost))
        }
    }

    func testReportWhatARealBookCostsNow() {
        let books: [(String, [SlotID: SymbolID])] = [
            ("plains · verdant · sparse ore · dim sky",
             ["terrain": "plains", "biome": "verdant", "bounty": "sparse_ore", "quirk": "dim_sky"]),
            ("plains · verdant · rich ore · gilded",
             ["terrain": "plains", "biome": "verdant", "bounty": "rich_ore", "quirk": "gilded_veins"]),
            ("caverns · ashen · rich ore · gilded",
             ["terrain": "caverns", "biome": "ashen", "bounty": "rich_ore", "quirk": "gilded_veins"]),
        ]
        print("WHAT A BOOK SCORES — authored deltas vs emergent greed")
        for (label, symbols) in books {
            let bound = book(symbols)
            let authored = BookRules.dangerTradeDelta(symbolIDs: bound.allSymbolIDs)
            let greed = BookRules.greedDelta(for: BookRules.sigils(for: bound))
            print(String(format: "  %-42s authored %+4d   greed %+4d   score %3d",
                         (label as NSString).utf8String!, authored, greed,
                         BookRules.stabilityScore(delta: authored + greed)))
        }
    }

    /// **A sun is not an outrage** (Aimee, 7 Aug: *"the sun as a focus SHOULD NOT DESTABILIZE SO
    /// MUCH MORE THAN EVERYTHING ELSE WHEN IT IS THE MOST STANDARD SOURCE OF ILLUMINATION IN ANY
    /// WORLD"*).
    ///
    /// Greed was charged against each subject's *baseline*, and four of eight baselines are zero —
    /// so "ordinary" meant pitch dark, and any light at all read as an extravagant demand. A sun
    /// cost −25: more than a vein of gold, and more than half of Rich Ore, whose whole identity is
    /// greed. The meter was teaching that light is reckless and darkness is safe, which is exactly
    /// backwards from the fiction.
    func testASunCostsLessThanAVeinOfGold() {
        func cost(_ source: PressureSourceID, _ target: PressureTargetID) -> Int {
            BookRules.greedDelta(for: [Sigil(id: InstanceID(rawValue: 1),
                                             source: source, target: target)])
        }
        let sun = cost("sun", "illumination")
        let gold = cost("gold", "substrate")
        XCTAssertGreaterThan(sun, gold, "a sunny world is greedier than a gold-veined one")
        XCTAssertGreaterThan(sun, -10, "a plain sun is still being charged like a demand")
    }

    /// **A world resists being asked for more; it does not resist being asked for less.**
    ///
    /// So a barren world is a gift and a teeming one scales — which is the half Aimee described:
    /// *"a barren world increases stability since it's worse than the norm, and a verdant lush
    /// world slowly scales up destabilization."*
    func testAskingForLessThanOrdinaryCalmsAWorld() {
        let teeming = BookRules.greedDelta(for: [
            Sigil(id: InstanceID(rawValue: 1), source: "bloom", target: "vitality", intensity: .great),
            Sigil(id: InstanceID(rawValue: 2), source: "root", target: "vitality", intensity: .great),
        ])
        let barren = BookRules.greedDelta(for: [
            Sigil(id: InstanceID(rawValue: 1), source: "salt", target: "vitality", intensity: .great),
        ])
        XCTAssertLessThan(teeming, 0, "a lush world costs nothing to hold open")
        XCTAssertGreaterThan(barren, 0, "a dead world isn't easier to hold than a living one")
    }

    /// **Wealth is charged heavily; strangeness lightly.** Deviation alone would bill a mountainous
    /// world like a gold-veined one, which is the other half of the fault — greed was supposed to
    /// mean *you asked the world for wealth*, and it meant *you asked the world for anything*.
    func testWealthCostsMoreThanMereStrangeness() {
        func cost(_ source: PressureSourceID, _ target: PressureTargetID) -> Int {
            BookRules.greedDelta(for: [Sigil(id: InstanceID(rawValue: 1), source: source,
                                             target: target, intensity: .great)])
        }
        XCTAssertLessThan(cost("gold", "substrate"), cost("granite", "relief"),
                          "a mountain is billed like a gold seam")
    }

    @MainActor
    func testNaturalAnchorIsAVisibleCheaperRouteToTheSameDurableRealm() throws {
        let blank = book([:])
        var found: (seed: UInt64, map: WorldMap, sites: [PlacedSite], anchor: PlacedSite)?
        for seed in UInt64(1)...200 {
            let world = Worldgen.generate(book: blank, seed: seed)
            if let anchor = world.sites.first(where: { $0.definition?.providesNaturalAnchor == true }) {
                found = (seed, world.map, world.sites, anchor)
                break
            }
        }
        let seeded = try XCTUnwrap(found)
        let store = GameStore(io: .temporary(name: "natural-anchor-\(UUID().uuidString)"))
        store.mutate("stand at an anchor point") { state in
            state.base.stations[Stations.anchorage] = StationState(isUnlocked: true, tier: 0)
            state.base.essence = 100
            state.worlds.runIndex = 1
            state.worlds.activeRun = WorldRun(runIndex: 1, book: blank, mapSeed: seeded.seed,
                                               rng: SeededRNG(seed: seeded.seed), map: seeded.map,
                                               playerPosition: seeded.anchor.position,
                                               sites: seeded.sites)
        }

        XCTAssertNotNil(store.naturalAnchorHere)
        let cost = store.naturalAnchorCost
        XCTAssertEqual(cost, 25, "a blank book's 100-essence born premium makes a 25-essence seam")
        XCTAssertTrue(store.anchorAtNaturalPoint())
        XCTAssertEqual(store.state.base.essence, 100 - cost)
        XCTAssertEqual(store.state.worlds.anchoredRealms.first?.route, .naturalPoint)
        XCTAssertEqual(store.state.worlds.anchoredRealms.first?.world.map, seeded.map)
        XCTAssertFalse(store.anchorAtNaturalPoint(), "one realm cannot be paid for twice")
    }

    @MainActor
    func testAnchorFrameOnlyConsumesOnValidOrdinaryGroundAndChargesNoEssence() throws {
        let blank = book([:])
        let generated = Worldgen.generate(book: blank, seed: 404)
        let clear = try XCTUnwrap(generated.map.allPoints.first {
            generated.map[$0].content == .empty && !generated.map[$0].isCrumbled
        })
        var run = WorldRun(runIndex: 1, book: blank, mapSeed: 404, rng: SeededRNG(seed: 404),
                           map: generated.map, playerPosition: generated.start)
        XCTAssertTrue(run.satchelItems.add(ItemStack(id: InstanceID(rawValue: 77),
                                                     catalogID: Items.anchorFrame)))
        let store = GameStore(io: .temporary(name: "anchor-frame-\(UUID().uuidString)"))
        store.mutate("carry frame") { state in
            state.base.stations[Stations.anchorage] = StationState(isUnlocked: true, tier: 0)
            state.base.essence = 63
            state.worlds.activeRun = run
        }

        XCTAssertFalse(store.placeAnchorFrame(), "a portal is not a valid placement tile")
        XCTAssertNotNil(store.carriedAnchorFrame, "an invalid attempt must not consume the frame")
        store.mutate("step onto clear ground") { $0.worlds.activeRun?.playerPosition = clear }

        XCTAssertTrue(store.placeAnchorFrame())
        XCTAssertNil(store.carriedAnchorFrame)
        XCTAssertEqual(store.state.base.essence, 63, "the crafted frame has no second essence cost")
        XCTAssertEqual(store.state.worlds.anchoredRealms.first?.route, .craftedFrame)
    }

    @MainActor
    func testAnchorFrameRecipeUsesSixDistinctWeakestQualifyingSamples() throws {
        func sample(hardness: Double = 0, density: Double = 0,
                    flexibility: Double = 0, reactivity: Double = 0) -> MaterialSample {
            MaterialSample(kind: .chitin,
                           properties: MaterialProperties(hardness: hardness, density: density,
                                                          flexibility: flexibility, reactivity: reactivity),
                           grade: max(hardness, density, flexibility, reactivity), source: "test world")
        }
        let store = GameStore(io: .temporary(name: "frame-recipe-\(UUID().uuidString)"))
        store.mutate("stock Anchorage") { state in
            state.base.stations[Stations.anchorage] = StationState(isUnlocked: true, tier: 0)
            state.base.essence = 100
            state.base.inventory.stacks = [ItemStack(
                id: InstanceID(rawValue: 800), catalogID: Items.material,
                materials: [sample(hardness: 65), sample(hardness: 66),
                            sample(density: 65), sample(density: 66),
                            sample(flexibility: 55), sample(reactivity: 65),
                            sample(hardness: 100, density: 100, flexibility: 100, reactivity: 100)])]
        }

        XCTAssertTrue(store.craftAnchorFrame())
        XCTAssertEqual(store.state.base.essence, 40)
        XCTAssertEqual(store.state.base.inventory.stacks.first(where: { $0.catalogID == Items.material })?
            .materials.map(\.grade), [100], "weakest qualifying stock should be consumed first")
        XCTAssertEqual(store.state.base.inventory.stacks.first(where: { $0.catalogID == Items.anchorFrame })?.count, 1)
    }

    @MainActor
    func testSustainSettlementSpendsOnlyChosenEssenceAndDormancyNeverDeletes() {
        let blank = book([:])
        let generated = Worldgen.generate(book: blank, seed: 9)
        let run = WorldRun(runIndex: 1, book: blank, mapSeed: 9, rng: SeededRNG(seed: 9),
                           map: generated.map, playerPosition: generated.start)
        let store = GameStore(io: .temporary(name: "sustain-\(UUID().uuidString)"))
        store.mutate("prepare settlement") { state in
            state.base.essence = 40
            state.worlds.anchoredRealms = [
                AnchoredRealm(runIndex: 1, name: "First", route: .bornAnchored, world: run),
                AnchoredRealm(runIndex: 2, name: "Chosen", route: .naturalPoint,
                              sustainObligation: 10, world: run),
                AnchoredRealm(runIndex: 3, name: "Resting", route: .craftedFrame,
                              sustainObligation: 20, assignedCompanions: [0], world: run),
            ]
            state.worlds.pendingAnchorSettlement = true
        }

        XCTAssertTrue(store.settleAnchoredRealms(paying: [2]))
        XCTAssertEqual(store.state.base.essence, 30)
        XCTAssertFalse(store.state.worlds.anchoredRealms[1].isDormant)
        XCTAssertTrue(store.state.worlds.anchoredRealms[2].isDormant)
        XCTAssertTrue(store.state.worlds.anchoredRealms[2].assignedCompanions.isEmpty)
        XCTAssertEqual(store.state.worlds.anchoredRealms.count, 3, "dormancy must never delete a realm")
        XCTAssertTrue(store.reactivateAnchoredRealm(3))
        XCTAssertFalse(store.state.worlds.anchoredRealms[2].isDormant)
    }

    @MainActor
    func testRealmAssignmentIsExclusiveAndProductionIsVisible() {
        let blank = book([:])
        let generated = Worldgen.generate(book: blank, seed: 12)
        let run = WorldRun(runIndex: 1, book: blank, mapSeed: 12, rng: SeededRNG(seed: 12),
                           map: generated.map, playerPosition: generated.start)
        let store = GameStore(io: .temporary(name: "realm-assignment-\(UUID().uuidString)"))
        store.mutate("prepare realms") { state in
            state.worlds.anchoredRealms = [
                AnchoredRealm(runIndex: 1, name: "One", route: .bornAnchored, world: run),
                AnchoredRealm(runIndex: 2, name: "Two", route: .naturalPoint, world: run),
            ]
        }

        XCTAssertTrue(store.assignCompanion(0, toAnchoredRealm: 1))
        XCTAssertFalse(store.state.base.activeParty.contains(0))
        XCTAssertEqual(store.state.worlds.anchoredRealms[0].productionContribution,
                       Tuning.Anchoring.worldworkBaseContribution + store.state.base.roster[0].worldwork)
        XCTAssertTrue(store.assignCompanion(0, toAnchoredRealm: 2))
        XCTAssertTrue(store.state.worlds.anchoredRealms[0].assignedCompanions.isEmpty)
        XCTAssertEqual(store.state.worlds.anchoredRealms[0].productionContribution, 0)
        XCTAssertEqual(store.state.worlds.anchoredRealms[1].assignedCompanions, [0])
    }
}
