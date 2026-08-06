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
        /// What noticed you, by the name it goes by. A name, not an id — what a creature *is* is
        /// read off its traits, so there is no longer a catalogue entry to point at.
        case enemySighted(String)
        case encounterBegan
        case crossedThreshold(StabilityBand)
        case nightfall
        case daybreak
        case tilesCrumbled(Int)
        case lostToCrumbling(Int)
        /// The world has begun to come apart. **Not the end of the run** — see `floorGaveWay`.
        case collapsed
        /// The tile you were standing on crumbled. This is the only thing that throws you out.
        case floorGaveWay
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

    /// What you can see from where you're standing.
    ///
    /// **Cover and elevation stop sight.** Growth and broken ground block it, and anything higher
    /// than you blocks it — so an open plain reveals itself in a glance and an overgrown, broken
    /// world has to be walked. This is the ambush/pursuit distinction becoming something you feel
    /// rather than a tag on a reading.
    static func reveal(around point: GridPoint, in map: inout WorldMap, radius: Int) {
        let standing = map[point].elevation
        map[point].isRevealed = true

        for candidate in map.allPoints where candidate.chebyshevDistance(to: point) <= radius {
            if hasLineOfSight(from: point, to: candidate, in: map, standing: standing) {
                map[candidate].isRevealed = true
            }
        }
    }

    /// Walks the line between two tiles and stops at the first thing that blocks it.
    ///
    /// The blocking tile is itself revealed — you can see the thicket, you just can't see past it.
    private static func hasLineOfSight(from: GridPoint, to: GridPoint, in map: WorldMap,
                                       standing: Int) -> Bool {
        let steps = max(abs(to.x - from.x), abs(to.y - from.y))
        guard steps > 1 else { return true }
        for step in 1..<steps {
            let t = Double(step) / Double(steps)
            let point = GridPoint(x: from.x + Int((Double(to.x - from.x) * t).rounded()),
                                  y: from.y + Int((Double(to.y - from.y) * t).rounded()))
            guard map.contains(point) else { continue }
            if map[point].blocksSight(from: standing) { return false }
        }
        return true
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
        guard !run.cast.isEmpty else { return }
        let onDuty = run.cast.filter { $0.isNocturnal == toNight }
        // Nothing keeps those hours here — the world simply doesn't change shift.
        guard !onDuty.isEmpty else { return }
        let table = Worldgen.roster(from: run.cast, nocturnal: toNight)

        for index in run.enemies.indices {
            let current = run.species(of: run.enemies[index])
            guard current?.isNocturnal != toNight else { continue }
            guard let replacement = run.rng.pickWeighted(table) else { continue }
            let position = run.enemies[index].position
            run.enemies[index] = Worldgen.spawn(replacement, at: position, rng: &run.rng)
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
        // Past the crumble threshold, the world eats itself from the outside in — **and it keeps
        // going after the meter empties**. Stability hitting zero used to end the run on the spot,
        // with the map still ninety per cent intact: you were thrown out of a world that visibly
        // hadn't gone anywhere. Now zero is when it starts coming apart in earnest.
        if run.stability <= Tuning.World.crumbleThreshold {
            if run.stability <= Tuning.World.collapseThreshold, run.collapsedOnTurn == nil {
                run.collapsedOnTurn = run.turnsTaken
                // Said once, the turn it happens: the world has gone, and you are still in it.
                events.append(.collapsed)
            }
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

        // **You are only forced out when the block you're standing on goes** (Aimee, 5 Aug). The
        // meter emptying is the world starting to come apart, not the end of your visit — you can
        // keep working, and getting to a portal before the floor reaches you is the decision the
        // whole collapse exists to create.
        if state.worlds.activeRun?.map[state.worlds.activeRun?.playerPosition ?? GridPoint(x: 0, y: 0)].isCrumbled == true {
            events.append(.floorGaveWay)
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
        for _ in 0..<crumbleRate(in: run) {
            // **The player's own tile is fair game.** It used to be protected, which meant the only
            // way a run could end was a number reaching zero while the ground was still there.
            // Crumbling from the outside in already gives you somewhere to stand and time to use
            // it; being caught is a consequence of where you chose to be.
            var surviving = run.map.allPoints.filter { !run.map[$0].isCrumbled }
            // **Portals go last.** They're the way out, and a collapse that eats them first turns
            // "get to a portal in time" into "wait to be thrown out", which is no decision at all.
            let withoutPortals = surviving.filter { !run.map[$0].content.isPortal }
            if !withoutPortals.isEmpty { surviving = withoutPortals }

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

    /// How fast the world is eating itself, in tiles per turn.
    ///
    /// **It accelerates once the meter is empty**, so a collapsed world genuinely runs out rather
    /// than nibbling its edges for a hundred turns while you carry on harvesting. The longer you
    /// stay past zero the faster it comes.
    static func crumbleRate(in run: WorldRun) -> Int {
        let base = Tuning.World.crumbleTilesPerTurn
        guard let collapsedOn = run.collapsedOnTurn else { return base }
        let since = max(0, run.turnsTaken - collapsedOn)
        return base + Int(Double(since) * Tuning.World.crumbleAccelerationPerTurn)
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
            let sight = detectionRadius(of: enemy, in: run)
            if !enemy.isAwake, distance <= sight {
                enemy.isAwake = true
                if run.map[enemy.position].isRevealed {
                    events.append(.enemySighted(run.name(of: enemy)))
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

    /// Whether the player can see this creature standing there at all.
    ///
    /// **Crypsis is a map behaviour, not a combat stat** (spec §7): something matched to the ambient
    /// doesn't appear until it's on you. In a low-openness world full of `growth` that is genuinely
    /// tense — and it's what makes writing an overgrown world a decision rather than scenery.
    static func isVisible(_ enemy: WorldEnemy, in run: WorldRun) -> Bool {
        guard enemy.traits?.defence == .crypsis else { return true }
        // Once it has broken cover it stays broken, and it is never invisible in your own square.
        if enemy.isAwake { return true }
        return enemy.position.chebyshevDistance(to: run.playerPosition) <= 1
    }

    /// How far off it notices you.
    ///
    /// **Sight is only one way of noticing** (spec §7). A creature that hunts by touch or smell is
    /// unaffected by darkness, and one that lives by its eyes is half-blind at night — so night
    /// genuinely changes who has the advantage rather than only changing your own sight radius.
    static func detectionRadius(of enemy: WorldEnemy, in run: WorldRun) -> Int {
        guard let traits = enemy.traits else {
            // Legacy creature from a world bound before the cast.
            return enemy.creatureID.flatMap { ContentCatalog.shared.creature($0) }
                .map { BookRules.sightRadius(of: $0, in: BookRules.readings(for: run.book, seed: run.mapSeed)) }
                ?? Tuning.World.defaultEnemySightRadius
        }
        let byEye = traits.sensory.vision / Tuning.Pressure.scaleMaximum
            * (run.isNight ? Tuning.World.nightVisionFraction : 1)
        let byEverythingElse = traits.sensory.nonVisual / Tuning.Pressure.scaleMaximum
            * Tuning.World.nonVisualSenseReach
        let open = BookRules.readings(for: run.book, seed: run.mapSeed)["relief"].aspect("openness")
        let inTheOpen = open > Tuning.Pressure.openTerrainThreshold ? Tuning.World.sightBonusInOpenGround : 0

        return max(1, Int((Double(Tuning.World.defaultEnemySightRadius)
                           * (byEye + byEverythingElse)).rounded()) + inTheOpen)
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
            // Stats are resolved here, once, and saved with the foe — not looked up mid-fight.
            // **Derived from the trait vector**, so how it fights is what it is.
            let stats: CombatStats
            var qualifier: String?
            if let traits = member.traits {
                // Named against the whole cast, so two of a world's animals never share a name.
                let identity = run.identity(of: member)
                qualifier = identity?.qualifier
                stats = CombatStats.derived(from: traits,
                                            name: identity?.name ?? member.displayName,
                                            icon: member.icon)
            } else if let creature = member.creatureID.flatMap({ ContentCatalog.shared.creature($0) }) {
                stats = CombatStats.resolved(from: creature)
            } else {
                continue
            }
            foes.append(FoeState(id: member.id,
                                 creatureID: member.creatureID,
                                 identityKey: member.identityKey,
                                 traits: member.traits,
                                 stats: stats,
                                 currentHP: stats.maxHP,
                                 qualifier: qualifier))
            // The encounter-flag registry: this is what turns a silhouette into a real icon in the
            // Writing Desk's preview. **The species is the entry; this animal is a specimen.**
            state.reality.discovery.recordSpecies(member.identityKey, runIndex: run.runIndex)
            if let traits = member.traits {
                state.reality.discovery.recordSpecimen(traits, of: member.identityKey, runIndex: run.runIndex)
            }
            if let legacy = member.creatureID {
                state.reality.discovery.recordCreature(legacy, runIndex: run.runIndex)
            }
        }
        guard !foes.isEmpty else { return }

        run.activeEncounter = CombatRules.makeEncounter(id: InstanceID(rawValue: run.rng.next()),
                                                        foes: foes, rng: &run.rng)
        state.worlds.activeRun = run

        // **Somebody has to move first, and it may not be you.** Automatic turns used to be kicked
        // off only by a player tap, which was safe while the party was always first in the order.
        // With turn order coming off initiative, a fight that opens on a creature's turn would
        // otherwise sit there waiting on nobody: the player's buttons do nothing, because it isn't
        // their turn, and nothing else is running.
        CombatRules.runAutomaticTurns(in: &state)
    }

}
