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
        case enteredSlowGround(String)
        case blocked(String)
        case pickedUp(ResourceID, amount: Int)
        case harvested(ResourceID, amount: Int, exhausted: Bool)
        case foundPortal
        case foundCache
        case cacheOpened(String)
        case foundSite(SiteID)
        case readPage(DiaryPageID)
        case readFoundWriting(FoundWritingID, String)
        case foundTraveller(TravellerID)
        /// You've walked up to somebody. The scene, not the recruitment.
        case metTraveller(TravellerID)
        /// Something used out in the world rather than mid-fight.
        case usedItem(String, on: PartyMember)
        case surveyed([SurveyReading])
        case searchedSite(SiteID, turnsRemaining: Int)
        case siteOpened(SiteID)
        case learnedSymbol(SymbolID)
        /// A word for the page, carved somewhere out there.
        case learnedFocus(PressureSourceID)
        case learnedGambit(GambitComponentID)
        case learnedPattern(String)
        case gainedEssence(Int)
        case pickedUpItem(String)
        case satchelFull(String)
        case hazardHit(damage: Int)
        /// **Something you walked into**, by name. Thorns cost you once; poison stays with you, and
        /// says so (`flora-system-spec.md` §6).
        case scratchedByGrowth(String, damage: Int, lingers: Bool)
        /// One turn of that poison still working.
        case poisonWorking(damage: Int)
        /// What noticed you, by the name it goes by. A name, not an id — what a creature *is* is
        /// read off its traits, so there is no longer a catalogue entry to point at.
        case enemySighted(String)
        case enemyAlerted(String)
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
            case .moved, .enteredSlowGround, .pickedUp, .harvested, .tilesCrumbled: false
            default: true
            }
        }
    }

    struct SurveyReading: Equatable, Sendable {
        var target: PressureTargetID
        var name: String
        var text: String
    }

    // MARK: - Vision

    /// How far the player can see. Dim Sky trades visibility for a longer-lived world — the paired
    /// tradeoff pattern from the decisions log, and the reason `visionDelta` exists on symbols.
    static func visionRadius(for book: BoundBook,
                             base: Int = Tuning.World.baseVisionRadius) -> Int {
        let delta = book.allSymbolIDs.reduce(0) { $0 + (ContentCatalog.shared.symbol($1)?.visionDelta ?? 0) }
        return max(Tuning.World.minimumVisionRadius, base + delta)
    }

    /// Sight, after the dark has taken its share. **Darkness cuts sight** (session 13 §6) — which is
    /// what makes a world with blazing days and black nights genuinely play as two worlds.
    /// **What the party's own eyes add.** Perception is the one stat that does anything outside a
    /// fight (session 17 §1), which is deliberate — a party built to look at things finds more.
    static func sightBonus(in state: GameState) -> Int {
        max(CharacterRules.sightBonus(state.base.binderCharacter.stats),
            CharacterRules.sightBonus(state.base.companion.character.stats))
    }

    static func visionRadius(in run: WorldRun, party: Int = 0) -> Int {
        let base = visionRadius(for: run.book, base: run.tuning.baseVisionRadius)
            + party + run.torchVisionBonus
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

    /// Lowest-turn path, returning the steps *after* the start. Empty if unreachable.
    ///
    /// Prefers routes that avoid known hazards, but will walk through one rather than claim there's
    /// no way — being told "no path" when a path exists is worse than taking the damage.
    static func path(from start: GridPoint, to destination: GridPoint, in map: WorldMap,
                     slowGroundExtraTurns: Int = 1) -> [GridPoint] {
        let safe = search(from: start, to: destination, in: map, avoidingHazards: true,
                          slowGroundExtraTurns: slowGroundExtraTurns)
        return safe.isEmpty ? search(from: start, to: destination, in: map, avoidingHazards: false,
                                     slowGroundExtraTurns: slowGroundExtraTurns) : safe
    }

    private static func search(from start: GridPoint,
                               to destination: GridPoint,
                               in map: WorldMap,
                               avoidingHazards: Bool,
                               slowGroundExtraTurns: Int) -> [GridPoint] {
        guard start != destination, canEnter(destination, in: map) else { return [] }

        var cameFrom: [GridPoint: GridPoint] = [:]
        var cost: [GridPoint: Int] = [start: 0]
        var frontier: Set<GridPoint> = [start]

        while let current = frontier.min(by: {
            let left = cost[$0, default: .max]
            let right = cost[$1, default: .max]
            return left == right ? ($0.y, $0.x) < ($1.y, $1.x) : left < right
        }) {
            frontier.remove(current)
            for next in map.neighbours(of: current) {
                guard canEnter(next, in: map) else { continue }
                // The destination is always enterable even if it's the hazard you're aiming at.
                if avoidingHazards, next != destination, map[next].content == .hazard { continue }
                let candidate = cost[current, default: .max]
                    + movementCost(map[next].ground, slowGroundExtraTurns: slowGroundExtraTurns)
                if candidate < cost[next, default: .max] {
                    cost[next] = candidate
                    cameFrom[next] = current
                    frontier.insert(next)
                }
            }
        }
        guard cost[destination] != nil else { return [] }
        var path = [destination]
        var step = destination
        while let previous = cameFrom[step], previous != start {
            path.append(previous)
            step = previous
        }
        return path.reversed()
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

        let movementCost = movementCost(run.map[destination].ground,
                                        slowGroundExtraTurns: run.tuning.slowGroundExtraTurns)
        var events: [Event] = [.moved(to: destination)]
        if movementCost > 1 { events.append(.enteredSlowGround(run.map[destination].ground.displayName)) }
        run.previousPosition = run.playerPosition
        run.playerPosition = destination
        reveal(around: destination, in: &run.map,
               radius: visionRadius(in: run, party: sightBonus(in: state)))

        // **Defended flora fights back the moment you're in it** (`flora-system-spec.md` §6), and
        // before anything else on the tile resolves — you push through the thorns to reach whatever
        // was growing behind them. Thorns cost you once; poison keeps costing.
        events.append(contentsOf: walkInto(destination, in: &run))

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
            // **Finding pays** (session 17 §2). `.page` and `.species` were defined and never
            // awarded, so two of the three stated sources of discovery experience paid nothing.
            awardDiscovery(.page, in: &state)
            run = state.worlds.activeRun ?? run
            run.map[destination].content = .empty
        case .foundWriting(let id):
            if let writing = run.foundWritings.first(where: { $0.id == id }),
               !state.reality.library.foundWritings.contains(where: { $0.id == id }) {
                state.reality.library.foundWritings.append(writing)
                events.append(.readFoundWriting(id, writing.prose))
                awardDiscovery(.page, in: &state)
                run = state.worlds.activeRun ?? run
            }
            run.map[destination].content = .empty
        case .site(let instance):
            if let site = run.sites.first(where: { $0.id == instance }) {
                events.append(.foundSite(site.siteID))
                let isNew = state.reality.discovery.sites[site.siteID] == nil
                state.reality.discovery.recordSite(site.siteID, runIndex: run.runIndex)
                if isNew { awardDiscovery(.site, in: &state) }
            }
        case .traveller(let id):
            // **Standing on them opens the scene, and nothing else happens yet.** Being found is
            // something they agree to, not something walking over a tile does to them.
            events.append(.metTraveller(id))
        case .empty, .node:
            break
        }

        state.worlds.activeRun = run
        for _ in 0..<movementCost {
            let turn = advanceTurn(in: &state)
            events.append(contentsOf: turn)
            if turn.contains(where: { event in
                if case .floorGaveWay = event { return true }
                if case .ejected = event { return true }
                if case .encounterBegan = event { return true }
                return false
            }) { break }
        }
        return events
    }

    /// **What it costs to walk into what's growing here** (`flora-system-spec.md` §6).
    ///
    /// Three defences, three different experiences of the same square. **Physical** hurts once, on
    /// the way in. **Chemical** hurts less and then stays with you for a few turns, which is what
    /// makes a toxic thicket a different decision from a thorn hedge rather than the same one at
    /// another number. **Active** does nothing here at all — it stands up and fights, and that is a
    /// `WorldEnemy` standing on the tile rather than a property of the tile.
    static func walkInto(_ point: GridPoint, in run: inout WorldRun) -> [Event] {
        guard let plant = run.plant(at: point) else { return [] }
        let harm = FloraRules.harm(of: plant.traits,
                                   severity: run.tuning.floraHazardSeverityMultiplier)
        guard harm.isSomething else { return [] }

        run.binderHP = max(0, run.binderHP - harm.immediate)
        // Walking back into it renews the poison rather than stacking it — the same rule statuses
        // follow in a fight.
        if harm.lingering > 0 { run.floraPoisonTurns = max(run.floraPoisonTurns, harm.lingering) }
        let name = run.floraNames[plant.id]?.name ?? plant.displayName
        return [.scratchedByGrowth(name, damage: harm.immediate, lingers: harm.lingering > 0)]
    }

    static func movementCost(_ ground: GroundType, slowGroundExtraTurns: Int) -> Int {
        ground.movementCost > 1 ? 1 + max(0, slowGroundExtraTurns) : 1
    }

    /// **Finding pays as well as fighting** (session 17 §2). A game whose progression is literacy
    /// shouldn't reward only killing.
    static func awardDiscovery(_ kind: CharacterRules.Discovery, in state: inout GameState) {
        for member in state.base.partyMembers {
            state.base.withCharacter(member) { CharacterRules.award(kind.experience, to: &$0) }
        }
    }

    /// **Talking somebody into coming home with you.**
    ///
    /// This is what "finding" a traveller means now (Aimee, 6 Aug). Arriving in a world that
    /// matches their signature only puts them on the map; reaching them opens the scene; agreeing
    /// is what writes them into the Library and raises their building at the base.
    ///
    /// Declining leaves them standing there. They don't move and they don't hold it against you —
    /// but the world is crumbling, and it will take the tile they're on like any other.
    static func recruit(_ id: TravellerID, in state: inout GameState) -> [Event] {
        guard var run = state.worlds.activeRun,
              case .traveller(let here) = run.map[run.playerPosition].content, here == id
        else { return [.blocked("Nobody here.")] }

        // **Marking somebody found is what stops them ever appearing again**, so it must never
        // happen unless they actually have somewhere to go. A full fire used to mark them found and
        // then quietly decline to seat them, which loses a person permanently — worldgen filters
        // found travellers out, so there is no second chance to come back for them.
        guard state.base.canRecruit || state.base.roster.contains(where: { $0.traveller == id })
        else { return [.blocked("There's no room at your fire. Come back when there is.")] }

        run.map[run.playerPosition].content = .empty
        run.travellersHere.removeAll { $0 == id }
        state.worlds.activeRun = run
        state.reality.library.foundTravellers.insert(id)
        state.reality.library.knownTravellers.insert(id)
        awardDiscovery(.traveller, in: &state)

        // **And she joins you.** This used to be the whole of recruitment: two writes to the
        // Library and nothing else. No roster, no gear, no presence — so Aimee recruited somebody,
        // lost a run, and had "no idea what happened to her". She was never lost; there was simply
        // nothing to show for it, which feels identical.
        state.base.seat(id)
        return [.foundTraveller(id)]
    }

    /// **Using something out in the world, not only mid-fight.**
    ///
    /// Consumables could only be used inside an encounter, so a player who finished a fight hurt
    /// walked the rest of the world hurt, and the only way to use a salve was to start another
    /// fight (Aimee, 6 Aug: *"no way to access items outside of combat either so I can't heal
    /// then"*).
    ///
    /// **It costs a turn** — the currency the world is already charging. That keeps healing from
    /// being free and makes patching yourself up mid-collapse a real decision.
    static func useItem(_ stackID: InstanceID, on member: PartyMember, in state: inout GameState) -> [Event] {
        guard var run = state.worlds.activeRun, run.activeEncounter == nil,
              let index = run.satchelItems.stacks.firstIndex(where: { $0.id == stackID }),
              let item = ContentCatalog.shared.item(run.satchelItems.stacks[index].catalogID),
              item.kind == .consumable
        else { return [.blocked("Nothing to use.")] }

        guard let effect = item.consumable else { return [.blocked("That has no field use.")] }
        switch effect.effect {
        case .heal:
            let healed = effect.potency
            switch member {
            case .binder:
                run.binderHP = min(CombatRules.maximumHealth(of: .binder, in: state), run.binderHP + healed)
            case .member(let index):
                let ceiling = CombatRules.maximumHealth(of: .companion(index), in: state)
                run.companionHP[index] = min(ceiling, (run.companionHP[index] ?? ceiling) + healed)
            }
        case .restoreStability:
            run.stability = min(Tuning.World.startingStability,
                                run.stability + Double(effect.potency))
        case .lightWorld:
            run.torchVisionBonus = max(run.torchVisionBonus, effect.potency)
            reveal(around: run.playerPosition, in: &run.map,
                   radius: visionRadius(in: run, party: sightBonus(in: state)))
        case .farsight:
            let destination = run.sites
                .filter { !run.map[$0.position].isRevealed }
                .min { $0.position.manhattanDistance(to: run.playerPosition)
                    < $1.position.manhattanDistance(to: run.playerPosition) }?.position
                ?? run.playerPosition
            reveal(around: destination, in: &run.map, radius: max(1, effect.potency))
        case .lureCreature:
            guard let nearest = run.enemies.indices
                .filter({ index in
                    let enemy = run.enemies[index]
                    return !enemy.isSessile && !enemy.isApex
                        && run.map[enemy.position].isRevealed
                        && isVisible(enemy, in: run)
                })
                .min(by: { run.enemies[$0].position.manhattanDistance(to: run.playerPosition)
                    < run.enemies[$1].position.manhattanDistance(to: run.playerPosition) })
            else { return [.blocked("No visible roaming creature answers the lure.")] }
            run.enemies[nearest].isAwake = true
        case .returnHome, .clearPoison, .clearElemental, .clearAnyStatus, .preventStatus,
             .coatPoison, .coatBurn, .coatBleed, .coatDazzle, .identifyCurio:
            return [.blocked("Use that at the appropriate moment.")]
        }
        _ = run.satchelItems.stacks[index].removing(1)
        if run.satchelItems.stacks[index].isEmpty { run.satchelItems.stacks.remove(at: index) }

        state.worlds.activeRun = run
        var events: [Event] = [.usedItem(item.name, on: member)]
        events.append(contentsOf: advanceTurn(in: &state))
        return events
    }

    /// Harvests the node under the player. One pull per turn.
    static func harvest(in state: inout GameState) -> [Event] {
        guard var run = state.worlds.activeRun,
              case .node(var node) = run.map[run.playerPosition].content, !node.isExhausted
        else { return [.blocked("Nothing here to harvest.")] }

        node.remainingHarvests -= 1
        let fieldcraftBonus = state.base.station(Stations.wayfarersTable).isUnlocked
            && FloraRules.isFloraResource(node.resource)
            ? Tuning.Economy.fieldcraftOrganicYieldBonus : 0
        let harvested = node.yieldPerHarvest + fieldcraftBonus
        run.satchel.add(harvested, of: node.resource)
        state.reality.discovery.recordResource(node.resource, runIndex: run.runIndex)
        run.map[run.playerPosition].content = node.isExhausted ? .empty : .node(node)

        var events: [Event] = [.harvested(node.resource, amount: harvested, exhausted: node.isExhausted)]
        state.worlds.activeRun = run
        events.append(contentsOf: advanceTurn(in: &state))
        return events
    }

    /// Use every instrument in the field kit at once. The readings become permanent knowledge and
    /// the world advances exactly once, however many subjects were measured.
    static func survey(in state: inout GameState) -> [Event] {
        guard let run = state.worlds.activeRun, run.activeEncounter == nil else {
            return [.blocked("You can't survey now.")]
        }
        let readings = BookRules.readings(for: run.book, seed: run.mapSeed)
        var report: [SurveyReading] = []
        for target in ContentCatalog.shared.pressureTargetsInOrder
        where run.carriedInstruments.contains(target.id) {
            let value = readings[target.id]
            let precision = run.carriedInstrumentPrecisions[target.id] ?? .crude
            if var known = state.reality.observations[target.id] {
                known.add(peak: value.peak, floor: value.floor, precision: precision)
                state.reality.observations[target.id] = known
            } else {
                state.reality.observations[target.id] = .init(count: 1, lowest: value.floor,
                                                               highest: value.peak,
                                                               bestPrecision: precision)
            }
            report.append(SurveyReading(
                target: target.id, name: target.name,
                text: WorldDescription.Reading.text(peak: value.peak, floor: value.floor,
                                                    hasFloor: target.dualValued,
                                                    precision: precision)))
        }
        guard !report.isEmpty else { return [.blocked("You brought no field instruments.")] }
        var events: [Event] = [.surveyed(report)]
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
        if state.reality.library.patiencePage == id {
            state.reality.library.patiencePage = nil
        }
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
        case .focus:
            if let focus = page.teachesFocus, !state.base.ownedSources.contains(focus) {
                state.base.ownedSources.insert(focus)
                events.append(.learnedFocus(focus))
            }
        case .gambit:
            if let component = page.teachesGambit,
               !state.base.ownedGambitComponents.contains(component) {
                state.base.ownedGambitComponents.insert(component)
                events.append(.learnedGambit(component))
            }
        case .pattern:
            if let pattern = page.teachesPattern,
               !state.reality.library.knownPatterns.contains(pattern) {
                state.reality.library.knownPatterns.insert(pattern)
                events.append(.learnedPattern(pattern))
            }
        case .researchLead, .ruin, .worldWorthWriting, .account, .turn:
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
                    let interpreted = amount + (state.base.station(Stations.reliquary).isUnlocked
                                                ? Tuning.Economy.reliquarySiteYieldBonus : 0)
                    run.satchel.add(interpreted, of: resource)
                    state.reality.discovery.recordResource(resource, runIndex: run.runIndex)
                    events.append(.pickedUp(resource, amount: interpreted))
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
                for focus in definition.contents.teachesFocuses
                where !state.base.ownedSources.contains(focus) {
                    state.base.ownedSources.insert(focus)
                    events.append(.learnedFocus(focus))
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
            // **A plant keeps no hours.** It grew there; it is still there at midnight. Swapping it
            // out would replace the thicket you have been walking round with an animal, and take
            // its growth tile's meaning with it.
            // A plant keeps no hours, and an apex is not on anybody's roster.
            guard !run.enemies[index].isSessile, !run.enemies[index].isApex else { continue }
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
        // Whatever you pushed through is still working. Ticked on the world's turn like everything
        // else, so it advances because you moved rather than because time passed (pillar 2).
        if run.floraPoisonTurns > 0 {
            run.floraPoisonTurns -= 1
            let bite = Tuning.Flora.poisonPerTurn
            run.binderHP = max(0, run.binderHP - bite)
            events.append(.poisonWorking(damage: bite))
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

        let concealment = fieldConcealment(in: state)
        events.append(contentsOf: moveEnemies(in: &run, concealment: concealment))
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
            let reason: String
            if events.contains(where: { if case .poisonWorking = $0 { true } else { false } }) {
                reason = "Poison overcame you. You were carried home."
            } else if events.contains(where: { if case .hazardHit = $0 { true } else { false } }) {
                reason = "The world's toxic air overwhelmed you. You were carried home."
            } else {
                reason = "Your injuries overwhelmed you. You were carried home."
            }
            events.append(.ejected(reason: reason))
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
        let rate = crumbleRate(in: run)
        let warnedAtStart = Set(run.map.allPoints.filter { run.map[$0].isCracking })
        var selected: Set<GridPoint> = []

        func pickTarget(from eligible: [GridPoint]) -> GridPoint? {
            var surviving = eligible.filter { !run.map[$0].isCrumbled && !selected.contains($0) }
            // **Portals go last.** They're the way out, and a collapse that eats them first turns
            // "get to a portal in time" into "wait to be thrown out", which is no decision at all.
            let withoutPortals = surviving.filter { !run.map[$0].content.isPortal }
            if !withoutPortals.isEmpty { surviving = withoutPortals }
            guard let outermost = surviving.map({ run.map.ring(of: $0) }).min() else { return nil }
            // Random *within* the ring, off the run's own RNG. Ring order alone would eat the map
            // left-to-right like a progress bar; scattering it feels like the edges closing in,
            // and staying on the seeded stream keeps a force-quit mid-collapse reproducible.
            let candidates = surviving.filter { run.map.ring(of: $0) == outermost }

            // **A spared portal is no use behind a wall.** Entry portals sit on the map edge, which
            // is the first ring to go — so sparing the portal tile while eating everything around
            // it left the player looking at an intact way out they could not reach, waiting to be
            // thrown out. Which is exactly what sparing them was meant to prevent.
            //
            // So a tile is only taken if the player can still walk to a portal afterwards.
            //
            // **And when nothing is left that can be taken safely, the world takes the player's own
            // tile.** By then every surviving tile is on the last corridor between them and the way
            // out, so anything else would sever it and leave them standing on an island waiting to
            // be thrown out. Being caught is the ending; being stranded is a bug wearing its coat.
            let safe = candidates.filter { candidate in
                var projected = run
                // During the warning phase, several cracks are chosen in one turn. Judge each
                // against the whole wave already selected, or individually-safe cracks can form
                // a collectively impassable wall when they fall together next turn.
                for point in selected { projected.map[point].isCrumbled = true }
                return !wouldMaroonPlayer(byCrumbling: candidate, in: projected)
            }
            if let pick = run.rng.pick(safe) {
                return pick
            }
            if eligible.contains(run.playerPosition), !selected.contains(run.playerPosition) {
                return run.playerPosition
            }
            return run.rng.pick(candidates)
        }

        // Pipeline phase one: previously warned tiles give way at the original crumble rate.
        // A tile opened below is not in `warnedAtStart`, so acceleration can never warn and remove
        // it in the same player turn.
        for _ in 0..<rate {
            let eligible = run.map.allPoints.filter { warnedAtStart.contains($0) }
            guard let target = pickTarget(from: eligible) else { break }
            selected.insert(target)
            if run.map[target].content.isLoseable { lost += 1 }
            run.map[target].isCrumbled = true
            run.map[target].isCracking = false
            run.map[target].content = .empty
            crumbled += 1

            // Anything standing there goes with it.
            run.enemies.removeAll { $0.position == target }
        }

        // Pipeline phase two: open the next wave of cracks. Once primed, collapse keeps its
        // original tiles-per-turn pace while every individual tile still gets a full warning.
        selected.removeAll()
        for _ in 0..<rate {
            let eligible = run.map.allPoints.filter {
                !run.map[$0].isCrumbled && !run.map[$0].isCracking
            }
            guard let target = pickTarget(from: eligible) else { break }
            selected.insert(target)
            run.map[target].isCracking = true
        }
        return (crumbled, lost)
    }

    /// Whether taking this tile would leave the player unable to walk to any surviving portal.
    ///
    /// The player's own tile is exempt: being caught is the intended ending, and a tile that is
    /// about to be stood on by nobody can't strand anyone.
    static func wouldMaroonPlayer(byCrumbling point: GridPoint, in run: WorldRun) -> Bool {
        guard point != run.playerPosition else { return false }
        var map = run.map
        map[point].isCrumbled = true
        // No portal left to reach means there's nothing left to protect.
        guard map.allPoints.contains(where: { map[$0].content.isPortal && !map[$0].isCrumbled })
        else { return false }
        return !canReachAPortal(from: run.playerPosition, in: map)
    }

    /// Flood fill from where the player stands to any standing portal.
    static func canReachAPortal(from start: GridPoint, in map: WorldMap) -> Bool {
        if map[start].content.isPortal && !map[start].isCrumbled { return true }
        var seen: Set<GridPoint> = [start]
        var queue = [start]
        var head = 0
        while head < queue.count {
            let current = queue[head]
            head += 1
            for next in map.neighbours(of: current) where !seen.contains(next) {
                guard canEnter(next, in: map) else { continue }
                if map[next].content.isPortal { return true }
                seen.insert(next)
                queue.append(next)
            }
        }
        return false
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
    struct FieldConcealment: Equatable, Sendable {
        var quietStep = false
        var radiusReduction = 0
    }

    static func fieldConcealment(in state: GameState) -> FieldConcealment {
        var result = FieldConcealment()
        for actor in CombatRules.party(of: state) {
            let loadout = CombatRules.loadout(of: actor, in: state)
            result.quietStep = result.quietStep || loadout.encounterChance < 0
            if loadout.sightedAtRange < 0 { result.radiusReduction = max(result.radiusReduction, 1) }
            if loadout.partySightedAtRange < 0 { result.radiusReduction = max(result.radiusReduction, 2) }
        }
        return result
    }

    private static func moveEnemies(in run: inout WorldRun,
                                    concealment: FieldConcealment) -> [Event] {
        var events: [Event] = []
        var taken = Set(run.enemies.map(\.position))

        for index in run.enemies.indices {
            var enemy = run.enemies[index]
            let distance = enemy.position.chebyshevDistance(to: run.playerPosition)

            // **Openness sets ambush versus pursuit.** Across open ground you're seen coming;
            // in enclosed country you aren't, and neither is what's waiting.
            // An apex never ambushes, so it is never woken by proximity — only by you stepping
            // into it, which the bump handles like any other fight.
            let baseSight = enemy.isApex ? 0 : detectionRadius(of: enemy, in: run)
            let skillReduction = enemy.isSessile ? 0 : concealment.radiusReduction
            let sight = max(1, baseSight - skillReduction)
            switch enemy.awareness {
            case .unaware where !enemy.isApex && distance <= sight:
                let canHesitate = concealment.quietStep && !enemy.isSessile
                    && !enemy.quietStepHesitationUsed && distance > 1
                if canHesitate {
                    enemy.awareness = .alert(turn: run.turnsTaken, reason: .quietStep)
                    enemy.quietStepHesitationUsed = true
                    if run.map[enemy.position].isRevealed {
                        events.append(.enemyAlerted(run.name(of: enemy)))
                    }
                } else {
                    enemy.awareness = .pursuing
                    if run.map[enemy.position].isRevealed {
                        events.append(.enemySighted(run.name(of: enemy)))
                    }
                }
            case .alert(let turn, _):
                if distance > sight {
                    enemy.awareness = .unaware
                } else if run.turnsTaken > turn {
                    enemy.awareness = .pursuing
                    if run.map[enemy.position].isRevealed {
                        events.append(.enemySighted(run.name(of: enemy)))
                    }
                }
            default: break
            }
            // **Rooted things don't follow, and neither does an apex.** A predatory plant grew
            // where it is; an apex holds its ground because it has no reason not to. Waking means
            // it is ready, not that it is coming — for both, the approach is the commitment
            // (`apex-encounters.md` §2), which is what keeps them hazards you walk *into*.
            guard enemy.isAwake, distance > 0, !enemy.isSessile, !enemy.isApex else {
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
        // **An apex is marked from the moment its tile is revealed**, whatever it is wearing
        // (`apex-encounters.md` §2). You must be able to see it and walk away — that is the rule
        // that makes hunting one a choice rather than a thing that happens to you.
        if enemy.isApex { return true }
        guard enemy.traits?.defence == .crypsis else { return true }
        // Once it has broken cover it stays broken, and it is never invisible in your own square.
        if enemy.awareness != .unaware { return true }
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

        // **What this world raises its animals to** (session 17 §3). Slowly with the party, and
        // further in worlds that are unstable or greedy — so the risk you priced into those two
        // when you wrote the book comes back as difficulty, not only as more things on the ground.
        let partyLevels = EncounterScalingRules.partyLevels(in: state)
        let partyReference = EncounterScalingRules.upperMedian(partyLevels)
        let worldLevel = CharacterRules.foeLevel(
            partyLevel: partyReference,
            stability: run.stability,
            greed: Double(BookRules.greedDelta(for: BookRules.sigils(for: run.book))))
        var scalingPreview = run.tuning.encounterScalingProfile.rules.map {
            EncounterScalingRules.preview(profile: $0, partyLevels: partyLevels, visibleFoes: group,
                                          mapSeed: run.mapSeed, triggerID: enemy.id, worldLevel: worldLevel,
                                          stability: run.stability,
                                          greed: Double(BookRules.greedDelta(for: BookRules.sigils(for: run.book))))
        }
        let ordinaryLevel = worldLevel + (scalingPreview?.totalOrdinaryLevelAdjustment ?? 0)

        var foes: [FoeState] = []
        var initiallyUnrecordedSpecies: Set<String> = []
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
            // Levelling touches the *derived* numbers, never the traits — so a levelled animal is
            // recognisably the same animal, wearing the same covering, swinging the same corner of
            // the triangle. It is simply more of it.
            let level = member.isApex ? (scalingPreview?.apexLevelFloor ?? worldLevel) : ordinaryLevel
            var levelled = stats
            levelled.maxHP = CharacterRules.scaled(stats.maxHP, toLevel: level)
            levelled.attack = CharacterRules.scaled(stats.attack, toLevel: level)
            levelled.armour = CharacterRules.scaled(stats.armour, toLevel: level)
            if member.isApex, let scalingPreview {
                levelled.maxHP = max(1, Int((Double(levelled.maxHP) * scalingPreview.apexHPMultiplier).rounded()))
                levelled.attack = max(1, Int((Double(levelled.attack) * scalingPreview.apexOffenceMultiplier).rounded()))
            }

            foes.append(FoeState(id: member.id,
                                 creatureID: member.creatureID,
                                 identityKey: member.identityKey,
                                 traits: member.traits,
                                 stats: levelled,
                                 currentHP: levelled.maxHP,
                                 qualifier: qualifier,
                                 level: level,
                                 isApex: member.isApex))
            // The encounter-flag registry: this is what turns a silhouette into a real icon in the
            // Writing Desk's preview. **The species is the entry; this animal is a specimen.**
            //
            // A *first* sighting is worth experience (session 17 §2) — a careful explorer should
            // advance as surely as a fighter, and meeting something new is the explorer's version
            // of a win.
            let isNewSpecies = state.reality.discovery.species[member.identityKey] == nil
            if isNewSpecies { initiallyUnrecordedSpecies.insert(member.identityKey) }
            state.reality.discovery.recordSpecies(member.identityKey, runIndex: run.runIndex)
            if isNewSpecies { awardDiscovery(.species, in: &state) }
            if let traits = member.traits {
                state.reality.discovery.recordSpecimen(traits, of: member.identityKey, runIndex: run.runIndex)
            }
            if let legacy = member.creatureID {
                state.reality.discovery.recordCreature(legacy, runIndex: run.runIndex)
            }
        }
        guard !foes.isEmpty else { return }
        scalingPreview?.finalFoes = foes.map {
            .init(id: $0.id, level: $0.level, maxHP: $0.stats.maxHP, attack: $0.stats.attack,
                  armour: $0.stats.armour, isApex: $0.isApex)
        }

        // **Everybody who came gets a place in the order.** This is the line that makes a party of
        // five a party of five rather than a list on the Firepit screen.
        run.activeEncounter = CombatRules.makeEncounter(id: InstanceID(rawValue: run.rng.next()),
                                                        foes: foes,
                                                        party: CombatRules.party(of: state),
                                                        names: state.base.activeParty.reduce(into: [Int: String]()) {
                                                            guard state.base.roster.indices.contains($1) else { return }
                                                            $0[$1] = state.base.roster[$1].name
                                                        },
                                                        apexActionSlots: scalingPreview.map { preview in
                                                            foes.filter(\.isApex).reduce(into: [:]) {
                                                                $0[$1.id] = preview.apexActionSlots
                                                            }
                                                        } ?? [:],
                                                        initiallyUnrecordedSpecies: initiallyUnrecordedSpecies,
                                                        rng: &run.rng)
        run.activeEncounter?.scalingPreview = scalingPreview
        state.worlds.activeRun = run

        // **Somebody has to move first, and it may not be you.** Automatic turns used to be kicked
        // off only by a player tap, which was safe while the party was always first in the order.
        // With turn order coming off initiative, a fight that opens on a creature's turn would
        // otherwise sit there waiting on nobody: the player's buttons do nothing, because it isn't
        // their turn, and nothing else is running.
        CombatRules.runAutomaticTurns(in: &state)
    }

}
