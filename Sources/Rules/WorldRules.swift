import Foundation

/// What happens when a player takes a turn in a world.
///
/// The single most important rule in this file: **a turn only ever advances because the player did
/// something.** There is no clock, no timer, no wall-clock comparison anywhere in it. Decay,
/// hazards, crumbling and enemy movement all hang off `advanceTurn`, and `advanceTurn` is only ever
/// called from a player action (pillar 2).
enum WorldRules {

    /// Things that happened during a turn, for the UI to narrate and for travel to interrupt on.
    enum Event: Equatable {
        case moved(to: GridPoint)
        case blocked(String)
        case pickedUp(ResourceID, amount: Int)
        case harvested(ResourceID, amount: Int, exhausted: Bool)
        case foundPortal
        case foundCache
        case cacheOpened(String)
        case foundSite(SiteID)
        case readPage(DiaryPageID)
        case foundTraveller(TravellerID)
        case searchedSite(SiteID, turnsRemaining: Int)
        case siteOpened(SiteID)
        case learnedSymbol(SymbolID)
        case gainedEssence(Int)
        case pickedUpItem(String)
        case satchelFull(String)
        case hazardHit(damage: Int)
        case enemySighted(CreatureID)
        case encounterBegan
        case crossedThreshold(StabilityBand)
        case nightfall
        case daybreak
        case tilesCrumbled(Int)
        case lostToCrumbling(Int)
        case collapsed
        case ejected(reason: String)

        /// Events that should stop an auto-path in its tracks. Walking blindly into a fight, a
        /// hazard, or a world starting to fall apart is exactly what the interrupt is for.
        var interruptsTravel: Bool {
            switch self {
            case .moved, .pickedUp, .harvested, .tilesCrumbled: false
            default: true
            }
        }
    }

    // MARK: - Vision

    /// How far the player can see. Dim Sky trades visibility for a longer-lived world — the paired
    /// tradeoff pattern from the decisions log, and the reason `visionDelta` exists on symbols.
    static func visionRadius(for book: BoundBook) -> Int {
        let delta = book.allSymbolIDs.reduce(0) { $0 + (ContentCatalog.shared.symbol($1)?.visionDelta ?? 0) }
        return max(Tuning.World.minimumVisionRadius, Tuning.World.baseVisionRadius + delta)
    }

    /// Sight, after the dark has taken its share. **Darkness cuts sight** (session 13 §6) — which is
    /// what makes a world with blazing days and black nights genuinely play as two worlds.
    static func visionRadius(in run: WorldRun) -> Int {
        let base = visionRadius(for: run.book)
        guard run.isNight else { return base }
        return max(Tuning.World.minimumVisionRadius, base - Tuning.DayNight.sightLostAtNight)
    }

    static func reveal(around point: GridPoint, in map: inout WorldMap, radius: Int) {
        for candidate in map.allPoints where candidate.chebyshevDistance(to: point) <= radius {
            map[candidate].isRevealed = true
        }
    }

    // MARK: - Movement

    static func canEnter(_ point: GridPoint, in map: WorldMap) -> Bool {
        map.contains(point) && map[point].isPassable
    }

    static func isAdjacent(_ a: GridPoint, _ b: GridPoint) -> Bool {
        a.manhattanDistance(to: b) == 1
    }

    /// Breadth-first path, returning the steps *after* the start. Empty if unreachable.
    ///
    /// Prefers routes that avoid known hazards, but will walk through one rather than claim there's
    /// no way — being told "no path" when a path exists is worse than taking the damage.
    static func path(from start: GridPoint, to destination: GridPoint, in map: WorldMap) -> [GridPoint] {
        let safe = search(from: start, to: destination, in: map, avoidingHazards: true)
        return safe.isEmpty ? search(from: start, to: destination, in: map, avoidingHazards: false) : safe
    }

    private static func search(from start: GridPoint,
                               to destination: GridPoint,
                               in map: WorldMap,
                               avoidingHazards: Bool) -> [GridPoint] {
        guard start != destination, canEnter(destination, in: map) else { return [] }

        var cameFrom: [GridPoint: GridPoint] = [:]
        var visited: Set<GridPoint> = [start]
        var queue = [start]
        var head = 0

        while head < queue.count {
            let current = queue[head]
            head += 1
            for next in map.neighbours(of: current) where !visited.contains(next) {
                guard canEnter(next, in: map) else { continue }
                // The destination is always enterable even if it's the hazard you're aiming at.
                if avoidingHazards, next != destination, map[next].content == .hazard { continue }
                visited.insert(next)
                cameFrom[next] = current
                if next == destination {
                    var path = [next]
                    var step = next
                    while let previous = cameFrom[step], previous != start {
                        path.append(previous)
                        step = previous
                    }
                    return path.reversed()
                }
                queue.append(next)
            }
        }
        return []
    }

    // MARK: - The turn

    /// Moves the player one tile and resolves the turn that follows.
    /// Returns everything that happened, in order.
    static func step(to destination: GridPoint, in state: inout GameState) -> [Event] {
        guard var run = state.worlds.activeRun else { return [] }
        guard isAdjacent(run.playerPosition, destination) else {
            return [.blocked("That's not a step away.")]
        }
        guard canEnter(destination, in: run.map) else {
            return [.blocked("Crumbled away — nothing to stand on.")]
        }

        var events: [Event] = [.moved(to: destination)]
        run.previousPosition = run.playerPosition
        run.playerPosition = destination
        reveal(around: destination, in: &run.map, radius: visionRadius(in: run))

        // Whatever is underfoot resolves before the world takes its turn.
        switch run.map[destination].content {
        case .wildDrop(let resource, let amount):
            run.satchel.add(amount, of: resource)
            run.map[destination].content = .empty
            state.reality.discovery.recordResource(resource, runIndex: run.runIndex)
            events.append(.pickedUp(resource, amount: amount))
        case .hazard:
            run.binderHP = max(0, run.binderHP - Tuning.World.hazardDamage)
            events.append(.hazardHit(damage: Tuning.World.hazardDamage))
        case .portal:
            events.append(.foundPortal)
        case .lockedCache:
            events.append(.foundCache)
        case .diaryPage(let page):
            // Reading is the whole interaction: one page, one unlock, and it's yours permanently.
            events.append(contentsOf: readPage(page, in: &state))
            run = state.worlds.activeRun ?? run
            run.map[destination].content = .empty
        case .site(let instance):
            if let site = run.sites.first(where: { $0.id == instance }) {
                events.append(.foundSite(site.siteID))
                state.reality.discovery.recordSite(site.siteID, runIndex: run.runIndex)
            }
        case .empty, .node:
            break
        }

        state.worlds.activeRun = run
        events.append(contentsOf: advanceTurn(in: &state))
        return events
    }

    /// Harvests the node under the player. One pull per turn.
    static func harvest(in state: inout GameState) -> [Event] {
        guard var run = state.worlds.activeRun,
              case .node(var node) = run.map[run.playerPosition].content, !node.isExhausted
        else { return [.blocked("Nothing here to harvest.")] }

        node.remainingHarvests -= 1
        run.satchel.add(node.yieldPerHarvest, of: node.resource)
        state.reality.discovery.recordResource(node.resource, runIndex: run.runIndex)
        run.map[run.playerPosition].content = node.isExhausted ? .empty : .node(node)

        var events: [Event] = [.harvested(node.resource, amount: node.yieldPerHarvest, exhausted: node.isExhausted)]
        state.worlds.activeRun = run
        events.append(contentsOf: advanceTurn(in: &state))
        return events
    }

    /// Take a page into the Library and apply the single thing it unlocks.
    ///
    /// **One page, one unlock**, and it lands in Reality immediately — pages are knowledge, and a
    /// collapse must never cost you something you've already read.
    static func readPage(_ id: DiaryPageID, in state: inout GameState) -> [Event] {
        guard !state.reality.library.hasFound(id), let page = ContentCatalog.shared.diaryPage(id) else {
            return []
        }
        state.reality.library.foundPages.append(id)
        state.reality.library.pagesWaiting[id] = nil
        var events: [Event] = [.readPage(id)]

        switch page.kind {
        case .locationClue:
            // Knowing where someone is means knowing they exist.
            if let about = page.about { state.reality.library.knownTravellers.insert(about) }
        case .whereabouts:
            if let about = page.about { state.reality.library.knownTravellers.insert(about) }
        case .symbol:
            if let symbol = page.teaches, !state.base.ownedSymbols.contains(symbol) {
                state.base.ownedSymbols.insert(symbol)
                events.append(.learnedSymbol(symbol))
            }
        case .researchLead, .ruin, .worldWorthWriting:
            // Recorded in the Library; the systems that read it come later.
            break
        }
        return events
    }

    /// Searches the site under the player. One turn per pull, like harvesting — a site is worth
    /// walking to *and* worth standing still for.
    ///
    /// Contents land only on the turn the search completes, so a force-quit part-way through
    /// resumes mid-search with nothing yet granted and nothing lost (pillar 2).
    static func searchSite(in state: inout GameState) -> [Event] {
        guard var run = state.worlds.activeRun,
              case .site(let instance) = run.map[run.playerPosition].content,
              let index = run.sites.firstIndex(where: { $0.id == instance }),
              !run.sites[index].isLooted
        else { return [.blocked("Nothing here to search.")] }

        guard !run.enemies.contains(where: { $0.position == run.playerPosition }) else {
            return [.blocked("Not while that's standing over you.")]
        }

        run.sites[index].searchTurnsRemaining -= 1
        let site = run.sites[index]
        var events: [Event] = []

        if site.searchTurnsRemaining > 0 {
            events.append(.searchedSite(site.siteID, turnsRemaining: site.searchTurnsRemaining))
        } else {
            run.sites[index].isLooted = true
            events.append(.siteOpened(site.siteID))
            if let definition = site.definition {
                for (resource, amount) in definition.contents.yields.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
                    run.satchel.add(amount, of: resource)
                    state.reality.discovery.recordResource(resource, runIndex: run.runIndex)
                    events.append(.pickedUp(resource, amount: amount))
                }
                // Items go into the satchel like any other haul, so a site's gear is something
                // you still have to carry home — and can still lose to a collapse.
                for itemID in definition.contents.items {
                    let stack = ItemStack(id: InstanceID(rawValue: run.rng.next()), catalogID: itemID)
                    if run.satchelItems.add(stack) {
                        events.append(.pickedUpItem(ContentCatalog.shared.item(itemID)?.name ?? "Something"))
                    } else {
                        // No room. The choice is the player's, held in the save until they make it.
                        run.offeredItems.append(stack)
                        events.append(.satchelFull(ContentCatalog.shared.item(itemID)?.name ?? "Something"))
                    }
                }
                // Knowledge is banked to Reality immediately rather than carried in the satchel:
                // literacy is permanent and cannot be lost to a collapse (rune spec §1).
                for symbol in definition.contents.teaches where !state.base.ownedSymbols.contains(symbol) {
                    state.base.ownedSymbols.insert(symbol)
                    events.append(.learnedSymbol(symbol))
                }
                if definition.contents.essence > 0 {
                    state.base.essence += definition.contents.essence
                    events.append(.gainedEssence(definition.contents.essence))
                }
            }
        }

        state.worlds.activeRun = run
        events.append(contentsOf: advanceTurn(in: &state))
        return events
    }

    /// What replaces a creature when the roster turns over at nightfall.
    ///
    /// The world doesn't repopulate — the things that were out in the day go, and the things that
    /// are out at night arrive in their place. Deterministic in the run's stream, so a resume finds
    /// the same night.
    static func swapRoster(in run: inout WorldRun, toNight: Bool) {
        let table = BookRules.enemyTable(for: run.book)
            .filter { $0.value.isNocturnal == toNight }
        guard !table.isEmpty else { return }
        for index in run.enemies.indices {
            let current = ContentCatalog.shared.creature(run.enemies[index].creatureID)
            guard current?.isNocturnal != toNight else { continue }
            guard let replacement = run.rng.pickWeighted(table) else { continue }
            run.enemies[index].creatureID = replacement.id
            run.enemies[index].isAwake = false
        }
    }

    /// Everything the *world* does after the player acts. The only place a turn is consumed.
    static func advanceTurn(in state: inout GameState) -> [Event] {
        guard var run = state.worlds.activeRun else { return [] }
        var events: [Event] = []

        let bandBefore = run.stabilityBand
        let wasNight = run.isNight
        run.turnsTaken += 1
        if run.isNight != wasNight {
            // Vision *and* spawns (session 13 §6) — the nocturnal roster swaps in.
            swapRoster(in: &run, toNight: run.isNight)
            events.append(run.isNight ? .nightfall : .daybreak)
        }

        // Miasma and Blight: the world itself costs you, every turn, just for being in it.
        let damage = BookRules.dangerProfile(for: run.book).damagePerTurn
        if damage > 0 {
            run.binderHP = max(0, run.binderHP - damage)
            events.append(.hazardHit(damage: damage))
        }
        run.encounterGraceTurns = max(0, run.encounterGraceTurns - 1)
        state.reality.lifetime.worldTurnsTaken += 1
        run.stability = max(0, run.stability - run.decayPerTurn)
        let bandAfter = run.stabilityBand
        if bandAfter != bandBefore { events.append(.crossedThreshold(bandAfter)) }

        // Past the hazard threshold, the edges of the world start turning against you.
        if run.stability <= Tuning.World.hazardThreshold, run.stability > 0 {
            spawnHazard(in: &run)
        }
        // Past the crumble threshold, the world eats itself from the outside in.
        if run.stability <= Tuning.World.crumbleThreshold, run.stability > 0 {
            let (crumbled, lost) = crumble(in: &run)
            if crumbled > 0 { events.append(.tilesCrumbled(crumbled)) }
            if lost > 0 { events.append(.lostToCrumbling(lost)) }
        }

        events.append(contentsOf: moveEnemies(in: &run))
        state.worlds.activeRun = run

        if let bumped = enemyOnPlayer(in: run) {
            beginEncounter(triggeredBy: bumped, in: &state)
            events.append(.encounterBegan)
        }

        if state.worlds.activeRun?.stability ?? 0 <= Tuning.World.collapseThreshold {
            events.append(.collapsed)
        } else if state.worlds.activeRun?.binderHP ?? 1 <= 0 {
            // No death state in v0 — running out of health ejects you home with a partial haul,
            // the same as being caught in a collapse.
            events.append(.ejected(reason: "You can't go on."))
        }
        return events
    }

    // MARK: - The world turning against you

    private static func spawnHazard(in run: inout WorldRun) {
        guard run.turnsTaken % Tuning.World.hazardSpawnInterval == 0 else { return }
        let candidates = run.map.allPoints.filter { point in
            run.map.ring(of: point) == 0
                && run.map[point].isPassable
                && run.map[point].content == .empty
                && point != run.playerPosition
        }
        guard let point = run.rng.pick(candidates) else { return }
        run.map[point].content = .hazard
    }

    /// Crumbles from the outside in. Returns (tiles crumbled, tiles that took something with them).
    private static func crumble(in run: inout WorldRun) -> (crumbled: Int, lost: Int) {
        var crumbled = 0
        var lost = 0
        for _ in 0..<Tuning.World.crumbleTilesPerTurn {
            // Outermost surviving ring first. The player's own tile is never taken out from under
            // them — being deleted by the floor isn't a decision, it's just a rug-pull.
            let surviving = run.map.allPoints.filter {
                !run.map[$0].isCrumbled && $0 != run.playerPosition
            }
            guard let outermost = surviving.map({ run.map.ring(of: $0) }).min() else { break }
            // Random *within* the ring, off the run's own RNG. Ring order alone would eat the map
            // left-to-right like a progress bar; scattering it feels like the edges closing in,
            // and staying on the seeded stream keeps a force-quit mid-collapse reproducible.
            let candidates = surviving.filter { run.map.ring(of: $0) == outermost }
            guard let target = run.rng.pick(candidates) else { break }

            if run.map[target].content.isLoseable { lost += 1 }
            run.map[target].isCrumbled = true
            run.map[target].content = .empty
            crumbled += 1

            // Anything standing there goes with it.
            run.enemies.removeAll { $0.position == target }
        }
        return (crumbled, lost)
    }

    // MARK: - Enemies

    /// Inert until the player is within the aggro radius, then one step toward them per turn.
    private static func moveEnemies(in run: inout WorldRun) -> [Event] {
        var events: [Event] = []
        var taken = Set(run.enemies.map(\.position))

        for index in run.enemies.indices {
            var enemy = run.enemies[index]
            let distance = enemy.position.chebyshevDistance(to: run.playerPosition)

            // **Openness sets ambush versus pursuit.** Across open ground you're seen coming;
            // in enclosed country you aren't, and neither is what's waiting.
            let sight = ContentCatalog.shared.creature(enemy.creatureID)
                .map { BookRules.sightRadius(of: $0, in: BookRules.readings(for: run.book, seed: run.mapSeed)) }
                ?? Tuning.World.defaultEnemySightRadius
            if !enemy.isAwake, distance <= sight {
                enemy.isAwake = true
                if run.map[enemy.position].isRevealed {
                    events.append(.enemySighted(enemy.creatureID))
                }
            }
            guard enemy.isAwake, distance > 0 else {
                run.enemies[index] = enemy
                continue
            }

            if let next = stepToward(run.playerPosition, from: enemy.position, in: run.map, avoiding: taken) {
                taken.remove(enemy.position)
                taken.insert(next)
                enemy.position = next
            }
            run.enemies[index] = enemy
        }
        return events
    }

    /// Greedy pursuit: close the bigger gap first, fall back to the other axis when blocked.
    private static func stepToward(_ target: GridPoint,
                                   from origin: GridPoint,
                                   in map: WorldMap,
                                   avoiding taken: Set<GridPoint>) -> GridPoint? {
        let dx = target.x - origin.x
        let dy = target.y - origin.y
        var options: [GridPoint] = []
        if abs(dx) >= abs(dy) {
            if dx != 0 { options.append(GridPoint(x: origin.x + (dx > 0 ? 1 : -1), y: origin.y)) }
            if dy != 0 { options.append(GridPoint(x: origin.x, y: origin.y + (dy > 0 ? 1 : -1))) }
        } else {
            if dy != 0 { options.append(GridPoint(x: origin.x, y: origin.y + (dy > 0 ? 1 : -1))) }
            if dx != 0 { options.append(GridPoint(x: origin.x + (dx > 0 ? 1 : -1), y: origin.y)) }
        }
        return options.first { canEnter($0, in: map) && (!taken.contains($0) || $0 == target) }
    }

    static func enemyOnPlayer(in run: WorldRun) -> WorldEnemy? {
        run.enemies.first { $0.position == run.playerPosition }
    }

    /// Opens an encounter with the bumped enemy plus anything awake standing next to it, up to the
    /// party's limit. Milestone 4 replaces the combat itself, not this trigger.
    static func beginEncounter(triggeredBy enemy: WorldEnemy, in state: inout GameState) {
        guard var run = state.worlds.activeRun, run.activeEncounter == nil else { return }
        // Just fled? You get a moment before anything else can catch you.
        guard run.encounterGraceTurns == 0 else { return }

        var group = [enemy]
        for other in run.enemies where other.id != enemy.id && other.isAwake {
            guard group.count < Tuning.Encounter.maxFoes else { break }
            if other.position.chebyshevDistance(to: enemy.position) <= 1 { group.append(other) }
        }

        var foes: [FoeState] = []
        for member in group {
            guard let creature = ContentCatalog.shared.creature(member.creatureID) else { continue }
            // Stats are resolved here, once, and saved with the foe — not looked up mid-fight.
            let stats = CombatStats.resolved(from: creature)
            foes.append(FoeState(id: member.id,
                                 creatureID: member.creatureID,
                                 stats: stats,
                                 currentHP: stats.maxHP))
            // The encounter-flag registry: this is what turns a silhouette into a real icon in the
            // Writing Desk's preview.
            state.reality.discovery.recordCreature(member.creatureID, runIndex: run.runIndex)
        }
        guard !foes.isEmpty else { return }

        run.activeEncounter = CombatRules.makeEncounter(id: InstanceID(rawValue: run.rng.next()), foes: foes)
        state.worlds.activeRun = run
    }

}
