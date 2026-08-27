import Foundation

/// What happens when a player takes a turn in a world.
///
/// The single most important rule in this file: **a turn only ever advances because the player did
/// something.** There is no clock, no timer, no wall-clock comparison anywhere in it. Decay,
/// hazards, crumbling and enemy movement all hang off `advanceTurn`, and `advanceTurn` is only ever
/// called from a player action (pillar 2).
enum WorldRules {
    struct PreContactSnapshot: Equatable, Sendable {
        var disclosedEnemyIDs: Set<InstanceID>
        var approachedEnemyID: InstanceID?

        func disclosed(_ enemy: WorldEnemy) -> Bool {
            disclosedEnemyIDs.contains(enemy.id)
        }
    }

    static func preContactSnapshot(in run: WorldRun,
                                   playerDestination: GridPoint? = nil,
                                   partySightBonus: Int = 0) -> PreContactSnapshot {
        let profile = visibilityProfile(in: run, party: partySightBonus)
        let disclosed = Set(run.enemies.compactMap { enemy -> InstanceID? in
            guard isCurrentlyVisible(enemy, in: run, profile: profile) else { return nil }
            return enemy.id
        })
        let approached = playerDestination.flatMap { destination in
            run.enemies.first(where: { enemy in
                guard enemy.position == destination else { return false }
                // A disclosed stationary threat is a deliberate approach only on contact.
                // Ordinary creatures retain mutual-contact/ambush classification.
                return (enemy.isApex || enemy.isSessile) && disclosed.contains(enemy.id)
            })?.id
        }
        return PreContactSnapshot(disclosedEnemyIDs: disclosed, approachedEnemyID: approached)
    }

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
        case seamlightActivated
        case seamwardFoundNoSeam
        case surveyed([SurveyReading])
        case searchedSite(SiteID, turnsRemaining: Int)
        case siteOpened(SiteID)
        case learnedSymbol(SymbolID)
        /// A word for the page, carved somewhere out there.
        case learnedFocus(PressureSourceID)
        case learnedGambit(GambitComponentID)
        case learnedPattern(WorkshopPatternID)
        case learnedSchematic(SchematicID)
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
    static func visionRadius(for book: BoundBook, seed: UInt64,
                             base: Int = Tuning.World.baseVisionRadius) -> Int {
        let delta = book.allSymbolIDs.reduce(0) { $0 + (ContentCatalog.shared.symbol($1)?.visionDelta ?? 0) }
        let light = BookRules.readings(for: book, seed: seed)["illumination"]
        return visibilityProfile(illumination: light.peak, baseRadius: base + delta).fullRadius
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
        visibilityProfile(in: run, party: party).fullRadius
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

        for candidate in map.allPoints where circularDistance(from: point, to: candidate) <= Double(radius) + 0.5 {
            if hasLineOfSight(from: point, to: candidate, in: map, standing: standing) {
                map[candidate].isRevealed = true
            }
        }
    }

    static func circularDistance(from: GridPoint, to: GridPoint) -> Double {
        let dx = to.x - from.x
        let dy = to.y - from.y
        return sqrt(Double(dx * dx + dy * dy))
    }

    /// Walks the line between two tiles and stops at the first thing that blocks it.
    ///
    /// The blocking tile is itself revealed — you can see the thicket, you just can't see past it.
    static func hasLineOfSight(from: GridPoint, to: GridPoint, in map: WorldMap,
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

    /// A blocked step says what the player can directly observe, in stable priority order.
    /// Returning nil means the tile is enterable.
    static func blockedMovementRefusal(to point: GridPoint, in map: WorldMap) -> String? {
        guard map.contains(point) else { return "The edge of the world lies beyond that step." }
        let tile = map[point]
        if tile.isCrumbled { return "Crumbled away — nothing to stand on." }
        switch tile.ground {
        case .deepWater: return "The water is too deep to cross."
        case .chasm: return "A chasm opens there — there is no footing."
        default:
            return tile.isPassable ? nil : "The \(tile.ground.displayName) blocks the way."
        }
    }

    static func isAdjacent(_ a: GridPoint, _ b: GridPoint) -> Bool {
        a.manhattanDistance(to: b) == 1
    }

    static func automaticTravelMustStop(before point: GridPoint, in run: WorldRun,
                                        partySightBonus: Int = 0) -> Bool {
        run.enemies.contains {
            $0.position == point && ($0.isApex || $0.isSessile)
                && isCurrentlyVisible($0, in: run, party: partySightBonus)
        }
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
        if let refusal = blockedMovementRefusal(to: destination, in: run.map) {
            return [.blocked(refusal)]
        }
        let partySightBonus = sightBonus(in: state)
        let preContact = preContactSnapshot(in: run, playerDestination: destination,
                                            partySightBonus: partySightBonus)

        let movementCost = movementCost(run.map[destination].ground,
                                        slowGroundExtraTurns: run.tuning.slowGroundExtraTurns)
        var events: [Event] = [.moved(to: destination)]
        if movementCost > 1 { events.append(.enteredSlowGround(run.map[destination].ground.displayName)) }
        run.previousPosition = run.playerPosition
        run.playerPosition = destination
        reveal(around: destination, in: &run.map,
               radius: visionRadius(in: run, party: partySightBonus))

        // **Defended flora fights back the moment you're in it** (`flora-system-spec.md` §6), and
        // before anything else on the tile resolves — you push through the thorns to reach whatever
        // was growing behind them. Thorns cost you once; poison keeps costing.
        events.append(contentsOf: walkInto(destination, in: &run))

        // Whatever is underfoot resolves before the world takes its turn.
        switch run.map[destination].content {
        case .item(let stack):
            if run.satchelItems.add(stack) {
                run.map[destination].content = .empty
                events.append(.pickedUpItem(ContentCatalog.shared.item(stack.catalogID)?.name
                                            ?? "Something"))
            } else {
                events.append(.satchelFull(ContentCatalog.shared.item(stack.catalogID)?.name
                                           ?? "Something"))
            }
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
            let readingEvents = readPage(page, in: &state)
            events.append(contentsOf: readingEvents)
            // **Finding pays** (session 17 §2). `.page` and `.species` were defined and never
            // awarded, so two of the three stated sources of discovery experience paid nothing.
            // A tolerant old/anchored world can still contain a page already known in Reality.
            // Clearing that stale tile is harmless; paying its discovery XP again is not.
            if readingEvents.contains(where: { if case .readPage = $0 { true } else { false } }) {
                awardDiscovery(.page, run: &run, in: &state)
            }
            run.map[destination].content = .empty
        case .foundWriting(let id):
            if let writing = run.foundWritings.first(where: { $0.id == id }),
               !state.reality.library.foundWritings.contains(where: { $0.id == id }) {
                state.reality.library.foundWritings.append(writing)
                events.append(.readFoundWriting(id, writing.prose))
                awardDiscovery(.page, run: &run, in: &state)
            }
            run.map[destination].content = .empty
        case .site(let instance):
            if let site = run.sites.first(where: { $0.id == instance }) {
                events.append(.foundSite(site.siteID))
                let isNew = state.reality.discovery.sites[site.siteID] == nil
                state.reality.discovery.recordSite(site.siteID, runIndex: run.runIndex)
                if isNew { awardDiscovery(.site, run: &run, in: &state) }
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
            let turn = advanceTurn(in: &state, preContact: preContact)
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
    static func awardDiscovery(_ kind: CharacterRules.Discovery, run: inout WorldRun,
                               in state: inout GameState) {
        for member in state.base.partyMembers {
            state.base.withCharacter(member) { CharacterRules.award(kind.experience, to: &$0) }
        }
        run.experienceBreakdown.record(kind)
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
        awardDiscovery(.traveller, run: &run, in: &state)
        state.worlds.activeRun = run
        state.reality.library.foundTravellers.insert(id)
        state.reality.library.knownTravellers.insert(id)

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
                let ceiling = CombatRules.health(of: .binder, in: run).max
                run.binderHP = min(ceiling, run.binderHP + healed)
            case .member(let index):
                let ceiling = CombatRules.health(of: .companion(index), in: run).max
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
            let visibility = visibilityProfile(in: run, party: sightBonus(in: state))
            guard let nearest = run.enemies.indices
                .filter({ index in
                    let enemy = run.enemies[index]
                    return !enemy.isSessile && !enemy.isApex
                        && isCurrentlyVisible(enemy, in: run, profile: visibility)
                })
                .min(by: { run.enemies[$0].position.manhattanDistance(to: run.playerPosition)
                    < run.enemies[$1].position.manhattanDistance(to: run.playerPosition) })
            else { return [.blocked("No visible roaming creature answers the lure.")] }
            run.enemies[nearest].isAwake = true
        case .maskScent:
            guard run.scentMask == nil else {
                return [.blocked("Already masked · \(run.scentMaskTurnsRemaining) turns remain")]
            }
            run.scentMask = .init(sourceItemInstanceID: stackID,
                                  startTurn: run.turnsTaken,
                                  expiresAfterTurn: run.turnsTaken + scentMaskDuration(effect))
        case .seamlightGuidance:
            switch SeamlightRules.evaluate(sourceItemInstanceID: stackID, in: state) {
            case .failure(let refusal): return [.blocked(SeamlightRules.playerCopy(for: refusal))]
            case .success(let quote):
                switch SeamlightRules.commit(quote, in: &state) {
                case .activated(_, let events): return events
                case .refused(let refusal): return [.blocked(SeamlightRules.playerCopy(for: refusal))]
                }
            }
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

    private static func scentMaskDuration(_ effect: ConsumableDef) -> Int {
        max(1, effect.potency)
    }

    /// Harvests the node under the player. One pull per turn.
    static func harvest(in state: inout GameState) -> [Event] {
        switch ResourceExtractionRules.evaluate(in: state) {
        case .available(let quote):
            let outcome = ResourceExtractionRules.commit(quote, in: &state)
            if case .refused(let refusal) = outcome.result {
                return [.blocked(ResourceExtractionRules.playerCopy(
                    for: refusal, vanishedAtCommit: refusal == .noDisclosedNode))]
            }
            return outcome.events
        case .refused(let refusal):
            let name = ResourceExtractionRules.selectedDisclosedNode(in: state)
                .flatMap { ContentCatalog.shared.resource($0.1.resource)?.name }
            return [.blocked(ResourceExtractionRules.playerCopy(for: refusal, resourceName: name))]
        }
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
        let run = state.worlds.activeRun
        let worldID = run.map { InstanceID(rawValue: $0.mapSeed) }
        let siteID = run.flatMap { current in
            current.sites.first { $0.position == current.playerPosition }?.siteID
        }
        state.reality.library.recordPage(id, worldRecordID: worldID, siteID: siteID)
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
                if component == FoeArmourGambit.subject {
                    // A specialised subject without one compatible mark is unusable. Grant its
                    // first word in the same mutation as the subject; rereading remains a no-op.
                    state.base.ownedGambitComponents.insert("armour_mark_1")
                }
                events.append(.learnedGambit(component))
            }
        case .pattern:
            if let pattern = page.teachesPattern,
               !state.reality.library.knownPatterns.contains(pattern) {
                state.reality.library.knownPatterns.insert(pattern)
                events.append(.learnedPattern(pattern))
            }
        case .schematic:
            if let schematic = page.teachesSchematic,
               !state.reality.library.knownSchematics.contains(schematic) {
                state.reality.library.knownSchematics.insert(schematic)
                events.append(.learnedSchematic(schematic))
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

        if let definition = run.sites[index].definition {
            guard definition.contents.items.allSatisfy({ itemID in
                GearCatalogueDispositionRules.makeAcquiredStack(
                    id: InstanceID(rawValue: 1), catalogID: itemID, route: .authoredSite) != nil
            }) else { return [.blocked("This site's authored contents are invalid.")] }
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
                    guard let stack = GearCatalogueDispositionRules.makeAcquiredStack(
                        id: InstanceID(rawValue: run.rng.next()), catalogID: itemID,
                        route: .authoredSite) else { continue }
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
                    state.base.addEssenceCrystals(definition.contents.essence)
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
            let habitat = run.enemies[index].habitatPlacement?.habitat
            let legalTable = habitat.map { required in
                table.filter { $0.value.habitat == required }
            } ?? table
            guard let replacement = run.rng.pickWeighted(legalTable) else { continue }
            let position = run.enemies[index].position
            let placement = run.enemies[index].habitatPlacement
            run.enemies[index] = Worldgen.spawn(replacement, at: position,
                                                habitat: placement, rng: &run.rng)
        }
    }

    /// Everything the *world* does after the player acts. The only place a turn is consumed.
    static func advanceTurn(in state: inout GameState,
                            preContact suppliedSnapshot: PreContactSnapshot? = nil) -> [Event] {
        guard var run = state.worlds.activeRun else { return [] }
        var events: [Event] = []
        // Non-movement actions can capture this at the turn boundary. A step supplies the snapshot
        // from before reveal/movement changed what the player was actually shown.
        let partySightBonus = sightBonus(in: state)
        let preContact = suppliedSnapshot ?? preContactSnapshot(in: run,
                                                                 partySightBonus: partySightBonus)

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

        if run.seamwardExpedition?.activatedOnTurn != nil,
           SeamwardRules.projection(in: run) == nil,
           run.seamwardExpedition?.noAnsweringSeamReported == false {
            run.seamwardExpedition?.noAnsweringSeamReported = true
            events.append(.seamwardFoundNoSeam)
        }

        let concealment = fieldConcealment(in: state)
        events.append(contentsOf: moveEnemies(in: &run, concealment: concealment,
                                               partySightBonus: partySightBonus))
        if let mask = run.scentMask, run.turnsTaken >= mask.expiresAfterTurn {
            run.scentMask = nil
            for index in run.enemies.indices { run.enemies[index].maskedScentContact = false }
        }
        state.worlds.activeRun = run

        if let bumped = enemyOnPlayer(in: run) {
            if beginEncounter(triggeredBy: bumped, preContact: preContact, in: &state) {
                events.append(.encounterBegan)
            }
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
                                    concealment: FieldConcealment,
                                    partySightBonus: Int) -> [Event] {
        var events: [Event] = []
        var taken = Set(run.enemies.map(\.position))
        let visibility = visibilityProfile(in: run, party: partySightBonus)

        for index in run.enemies.indices {
            var enemy = run.enemies[index]
            let distance = enemy.position.chebyshevDistance(to: run.playerPosition)
            let beganTurnUnaware: Bool = {
                if case .unaware = enemy.awareness { return true }
                return false
            }()

            // **Openness sets ambush versus pursuit.** Across open ground you're seen coming;
            // in enclosed country you aren't, and neither is what's waiting.
            // An apex never ambushes, so it is never woken by proximity — only by you stepping
            // into it, which the bump handles like any other fight.
            let baseSight = enemy.isApex ? 0 : detectionRadius(of: enemy, in: run)
            let skillReduction = enemy.isSessile ? 0 : concealment.radiusReduction
            let sight = max(1, baseSight - skillReduction)
            if distance > baseSight { enemy.maskedScentContact = false }
            switch enemy.awareness {
            case .unaware where !enemy.isApex && distance <= sight:
                let withoutChemo = detectionRadius(of: enemy, in: run, includingChemo: false)
                let scentMaskHesitates = run.isScentMasked && enemy.traits != nil
                    && !enemy.isSessile && distance > 1 && distance > withoutChemo
                    && !enemy.maskedScentContact
                let canHesitate = concealment.quietStep && !enemy.isSessile
                    && !enemy.quietStepHesitationUsed && distance > 1
                if scentMaskHesitates {
                    enemy.awareness = .alert(turn: run.turnsTaken, reason: .maskedScent)
                    enemy.maskedScentContact = true
                    if isCurrentlyVisible(enemy, in: run, profile: visibility) {
                        events.append(.enemyAlerted(run.name(of: enemy)))
                    }
                } else if canHesitate {
                    enemy.awareness = .alert(turn: run.turnsTaken, reason: .quietStep)
                    enemy.quietStepHesitationUsed = true
                    if isCurrentlyVisible(enemy, in: run, profile: visibility) {
                        events.append(.enemyAlerted(run.name(of: enemy)))
                    }
                } else {
                    enemy.awareness = .pursuing
                    if isCurrentlyVisible(enemy, in: run, profile: visibility) {
                        events.append(.enemySighted(run.name(of: enemy)))
                    }
                }
            case .alert(let turn, _):
                if distance > sight {
                    enemy.awareness = .unaware
                } else if run.turnsTaken > turn {
                    enemy.awareness = .pursuing
                    if isCurrentlyVisible(enemy, in: run, profile: visibility) {
                        events.append(.enemySighted(run.name(of: enemy)))
                    }
                }
            default: break
            }
            // **Rooted things don't follow, and neither does an apex.** A predatory plant grew
            // where it is; an apex holds its ground because it has no reason not to. Waking means
            // it is ready, not that it is coming — for both, the approach is the commitment
            // (`apex-encounters.md` §2), which is what keeps them hazards you walk *into*.
            guard enemy.isAwake, !beganTurnUnaware, distance > 0,
                  !enemy.isSessile, !enemy.isApex else {
                run.enemies[index] = enemy
                continue
            }

            let habitatTiles = enemy.habitatPlacement.map { Set($0.legalTiles) }
            if let next = stepToward(run.playerPosition, from: enemy.position, in: run.map,
                                     avoiding: taken, allowed: habitatTiles) {
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
    static func detectionRadius(of enemy: WorldEnemy, in run: WorldRun,
                                includingChemo: Bool = true) -> Int {
        guard let traits = enemy.traits else {
            // Legacy creature from a world bound before the cast.
            return enemy.creatureID.flatMap { ContentCatalog.shared.creature($0) }
                .map { BookRules.sightRadius(of: $0, in: BookRules.readings(for: run.book, seed: run.mapSeed)) }
                ?? Tuning.World.defaultEnemySightRadius
        }
        let byEye = traits.sensory.vision / Tuning.Pressure.scaleMaximum
            * (run.isNight ? Tuning.World.nightVisionFraction : 1)
        let nonVisual = traits.sensory.mechano + traits.sensory.thermo
            + (includingChemo ? traits.sensory.chemo : 0)
        let byEverythingElse = nonVisual / Tuning.Pressure.scaleMaximum
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
                                   avoiding taken: Set<GridPoint>,
                                   allowed: Set<GridPoint>? = nil) -> GridPoint? {
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
        return options.first {
            (allowed?.contains($0) ?? true) && canEnter($0, in: map)
                && (!taken.contains($0) || $0 == target)
        }
    }

    static func enemyOnPlayer(in run: WorldRun) -> WorldEnemy? {
        run.enemies.first { $0.position == run.playerPosition }
    }

    struct EncounterGroupSelection: Equatable {
        let foes: [WorldEnemy]
        let radius: Int
        let inclusionReasons: [String: String]
        let exclusionReasons: [String: String]
    }

    /// Resolves the exact persisted map bodies allowed to enter a fight. The trigger is always
    /// first; every companion body must already be awake, genuinely visible, and connected by a
    /// passable orthogonal path. Array order never decides who joins.
    static func encounterGroup(triggeredBy trigger: WorldEnemy, in run: WorldRun,
                               partyCount: Int, adaptiveRadius: Bool = true,
                               partySightBonus: Int = 0)
        -> EncounterGroupSelection {
        if !adaptiveRadius {
            var foes = [trigger]
            var inclusion = [String(trigger.id.rawValue): "triggering map entity"]
            var exclusion: [String: String] = [:]
            for candidate in run.enemies where candidate.id != trigger.id {
                let key = String(candidate.id.rawValue)
                guard candidate.isAwake else {
                    exclusion[key] = "asleep"
                    continue
                }
                guard candidate.position.chebyshevDistance(to: trigger.position) <= 1 else {
                    exclusion[key] = "outside historical radius 1"
                    continue
                }
                guard foes.count < Tuning.Encounter.maxFoes else {
                    exclusion[key] = "eligible after three-foe cap"
                    continue
                }
                foes.append(candidate)
                inclusion[key] = "historical awake adjacency"
            }
            return EncounterGroupSelection(foes: foes, radius: 1,
                                           inclusionReasons: inclusion,
                                           exclusionReasons: exclusion)
        }
        let clampedCount = max(1, min(Tuning.Party.maximumSize, partyCount))
        let radius = [1, 1, 2, 2, 3][clampedCount - 1]
        let distances = passableDistances(from: trigger.position, in: run.map, limit: radius)
        var included: [(enemy: WorldEnemy, distance: Int)] = [(trigger, 0)]
        var inclusion = [String(trigger.id.rawValue): "triggering map entity"]
        var exclusion: [String: String] = [:]

        for candidate in run.enemies where candidate.id != trigger.id {
            let key = String(candidate.id.rawValue)
            guard candidate.isAwake else {
                exclusion[key] = "asleep"
                continue
            }
            guard run.map.contains(candidate.position),
                  isCurrentlyVisible(candidate, in: run, party: partySightBonus) else {
                exclusion[key] = "not legitimately visible"
                continue
            }
            guard let distance = distances[candidate.position], distance <= radius else {
                exclusion[key] = "outside passable radius \(radius)"
                continue
            }
            included.append((candidate, distance))
        }

        included = [included[0]] + included.dropFirst().sorted {
            ($0.distance, $0.enemy.id.rawValue) < ($1.distance, $1.enemy.id.rawValue)
        }
        if included.count > Tuning.Encounter.maxFoes {
            for excluded in included.dropFirst(Tuning.Encounter.maxFoes) {
                exclusion[String(excluded.enemy.id.rawValue)] = "eligible after three-foe cap"
            }
            included = Array(included.prefix(Tuning.Encounter.maxFoes))
        }
        for entry in included.dropFirst() {
            inclusion[String(entry.enemy.id.rawValue)] = "awake, visible, passable distance \(entry.distance)"
        }
        return EncounterGroupSelection(foes: included.map(\.enemy), radius: radius,
                                       inclusionReasons: inclusion,
                                       exclusionReasons: exclusion)
    }

    private static func passableDistances(from start: GridPoint, in map: WorldMap,
                                          limit: Int) -> [GridPoint: Int] {
        guard map.contains(start) else { return [:] }
        var distances = [start: 0]
        var queue = [start]
        var cursor = 0
        while cursor < queue.count {
            let point = queue[cursor]
            cursor += 1
            let distance = distances[point, default: 0]
            guard distance < limit else { continue }
            for next in map.neighbours(of: point)
            where map[next].isPassable && distances[next] == nil {
                distances[next] = distance + 1
                queue.append(next)
            }
        }
        return distances
    }

    /// Stable largest-remainder allocation of one encounter-wide durability addition. The total
    /// is rounded once; array order cannot move a hit point between otherwise identical foes.
    static func pressureHPAllocation(for foes: [FoeState], additionFraction: Double)
        -> [InstanceID: Int] {
        guard additionFraction > 0 else { return [:] }
        let total = foes.reduce(0) { $0 + max(0, $1.stats.maxHP) }
        guard total > 0 else { return [:] }
        let intended = max(0, Int((Double(total) * additionFraction).rounded()))
        struct Share {
            let id: InstanceID
            let floor: Int
            let remainder: Double
        }
        let shares = foes.map { foe -> Share in
            let exact = Double(intended) * Double(max(0, foe.stats.maxHP)) / Double(total)
            let floorValue = Int(floor(exact))
            return Share(id: foe.id, floor: floorValue, remainder: exact - Double(floorValue))
        }
        var result = Dictionary(uniqueKeysWithValues: shares.map { ($0.id, $0.floor) })
        var left = intended - shares.reduce(0) { $0 + $1.floor }
        for share in shares.sorted(by: {
            $0.remainder == $1.remainder
                ? $0.id.rawValue < $1.id.rawValue
                : $0.remainder > $1.remainder
        }) where left > 0 {
            result[share.id, default: 0] += 1
            left -= 1
        }
        return result.filter { $0.value > 0 }
    }

    /// Opens an encounter with the bumped enemy plus anything awake standing next to it, up to the
    /// party's limit. Milestone 4 replaces the combat itself, not this trigger.
    @discardableResult
    static func beginEncounter(triggeredBy enemy: WorldEnemy,
                               preContact suppliedSnapshot: PreContactSnapshot? = nil,
                               runsAutomaticTurns: Bool = true,
                               debugGodModeEnabled suppliedDebugGodMode: Bool? = nil,
                               in state: inout GameState) -> Bool {
        guard var run = state.worlds.activeRun, run.activeEncounter == nil else { return false }
        // Just fled? You get a moment before anything else can catch you.
        guard run.encounterGraceTurns == 0 else { return false }

        let partyLevels = EncounterScalingRules.partyLevels(in: state)
        let usesAdditiveScaling = run.tuning.encounterScalingProfile == .recommended
            && run.tuning.encounterScalingProfileSchemaVersion
                >= DebugTuningProfile.currentEncounterScalingProfileSchemaVersion
        let grouping = encounterGroup(triggeredBy: enemy, in: run,
                                      partyCount: partyLevels.count,
                                      adaptiveRadius: usesAdditiveScaling,
                                      partySightBonus: sightBonus(in: state))
        let group = grouping.foes

        // **What this world raises its animals to** (session 17 §3). Slowly with the party, and
        // further in worlds that are unstable or greedy — so the risk you priced into those two
        // when you wrote the book comes back as difficulty, not only as more things on the ground.
        // Recommended anchors species/world level to the Binder. Companion differences enter once
        // through the additive power ledger; they never secretly raise or lower every foe level.
        // Historical comparison profiles retain their old median reference for decode/playback.
        let partyReference = usesAdditiveScaling
            ? state.base.binderCharacter.level
            : EncounterScalingRules.upperMedian(partyLevels)
        let worldLevel = CharacterRules.foeLevel(
            partyLevel: partyReference,
            stability: run.stability,
            greed: Double(BookRules.greedDelta(for: BookRules.sigils(for: run.book))))
        let greed = Double(BookRules.greedDelta(for: BookRules.sigils(for: run.book)))
        var scalingPreview: EncounterScalingRules.Preview?
        if usesAdditiveScaling {
            scalingPreview = EncounterScalingRules.additivePreview(
                anchorLevel: state.base.binderCharacter.level,
                companions: EncounterScalingRules.companionInputs(in: state),
                visibleFoes: group, worldLevel: worldLevel, stability: run.stability, greed: greed,
                groupingRadius: grouping.radius, inclusionReasons: grouping.inclusionReasons,
                exclusionReasons: grouping.exclusionReasons)
        } else {
            scalingPreview = run.tuning.encounterScalingProfile.rules.map {
                EncounterScalingRules.preview(profile: $0, partyLevels: partyLevels,
                                              visibleFoes: group, mapSeed: run.mapSeed,
                                              triggerID: enemy.id, worldLevel: worldLevel,
                                              stability: run.stability, greed: greed,
                                              groupingRadius: grouping.radius)
            }
        }
        scalingPreview?.worldLevel = worldLevel
        scalingPreview?.triggerFoeID = enemy.id
        scalingPreview?.scalingProfile = run.tuning.encounterScalingProfile.rawValue
        scalingPreview?.scalingProfileSchemaVersion = run.tuning.encounterScalingProfileSchemaVersion
        let ordinaryLevel = worldLevel + (scalingPreview?.totalOrdinaryLevelAdjustment ?? 0)

        var foes: [FoeState] = []
        var initiallyUnrecordedSpecies: Set<String> = []
        var candidateDiscovery = state.reality.discovery
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
                                 speciesID: member.speciesID,
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
            if let habitat = member.habitatPlacement?.habitat {
                guard candidateDiscovery.recordSpecies(
                    member.identityKey, habitat: habitat, runIndex: run.runIndex) else { return false }
            } else {
                // Legacy/authored bodies remain visible in Bestiary detail but unclassified on
                // the physical habitat shelves.
                candidateDiscovery.recordSpecies(member.identityKey, runIndex: run.runIndex)
            }
            if let traits = member.traits {
                candidateDiscovery.recordSpecimen(traits, of: member.identityKey,
                                                   runIndex: run.runIndex)
            }
            if let legacy = member.creatureID {
                candidateDiscovery.recordCreature(legacy, runIndex: run.runIndex)
            }
        }
        guard !foes.isEmpty else { return false }
        state.reality.discovery = candidateDiscovery
        for _ in initiallyUnrecordedSpecies {
            awardDiscovery(.species, run: &run, in: &state)
        }
        let containsApex = foes.contains(where: \.isApex)
        let ordinaryPressureSlots: Int
        if !containsApex, let fraction = scalingPreview?.totalHPAdditionFraction,
           scalingPreview?.scalingRulesVersion == EncounterScalingRules.additivePartyPowerRulesVersion {
            let allocation = pressureHPAllocation(for: foes, additionFraction: fraction)
            for index in foes.indices {
                let added = allocation[foes[index].id, default: 0]
                foes[index].stats.maxHP += added
                foes[index].currentHP += added
            }
            scalingPreview?.hpAllocationByFoeID = Dictionary(uniqueKeysWithValues:
                allocation.map { (String($0.key.rawValue), $0.value) })
            ordinaryPressureSlots = scalingPreview?.wholePressureSlots ?? 0
        } else {
            // Apex scaling and ordinary pressure are mutually exclusive. A mixed encounter keeps
            // every ordinary body at world-resolved stats with one ordinary action.
            if containsApex {
                scalingPreview?.shortfall = 0
                scalingPreview?.wholePressureSlots = 0
                scalingPreview?.fractionalShortfall = 0
                scalingPreview?.totalHPAdditionFraction = 0
            }
            scalingPreview?.hpAllocationByFoeID = [:]
            ordinaryPressureSlots = 0
        }
        scalingPreview?.finalFoes = foes.map {
            .init(id: $0.id, level: $0.level, maxHP: $0.stats.maxHP, attack: $0.stats.attack,
                  armour: $0.stats.armour, isApex: $0.isApex)
        }

        // **Everybody who came gets a place in the order.** This is the line that makes a party of
        // five a party of five rather than a list on the Firepit screen.
        let preContact = suppliedSnapshot ?? preContactSnapshot(in: run,
                                                                partySightBonus: sightBonus(in: state))
        let initialOpening: EncounterState.Opening
        if preContact.approachedEnemyID == enemy.id {
            initialOpening = .partyApproach
        } else if enemy.isApex || enemy.isSessile {
            // These threats hold their ground. Contact with them is always a deliberate approach,
            // never an ambush inferred from a post-contact awareness value.
            initialOpening = .partyApproach
        } else if preContact.disclosed(enemy) {
            initialOpening = .mutualContact
        } else {
            initialOpening = .creatureAmbush
        }

        let party = CombatRules.party(of: state)
        let slipperyProbability = party.map { CombatRules.loadout(of: $0, in: state).ambushResistance }
            .max().map { min(1, max(0, $0)) } ?? 0
        let watchful = party.contains {
            CombatRules.loadout(of: $0, in: state).partyAmbushResistance > 0
        }
        var slipperyRoll: Double?
        var slipperyPrevented = false
        if initialOpening == .creatureAmbush, slipperyProbability > 0 {
            let roll = run.rng.double(in: 0...1)
            slipperyRoll = roll
            slipperyPrevented = roll < slipperyProbability
        }
        let resolvedOpening: EncounterState.Opening = slipperyPrevented ? .mutualContact : initialOpening
        let watchfulSuppressed = resolvedOpening == .creatureAmbush && watchful

        let combatGraph = ContentCatalog.shared.combatGraph
        let implementedIDs = CombatGraphRules.implementedNodeIDs(in: combatGraph)
        let binderCharacter = state.base.binderCharacter
        var binderNodeIDs = binderCharacter.ownedCombatNodeIDs.intersection(implementedIDs)
        var companionNodeIDs: [PersistentPartyMemberID: Set<CombatNodeID>] = Dictionary(uniqueKeysWithValues: state.base.activeParty.compactMap { id in
            guard let index = state.base.rosterIndex(for: id) else { return nil }
            let nodes = state.base.roster[index].character.ownedCombatNodeIDs
                .intersection(implementedIDs)
            return (id, nodes)
        })
        var binderChoices = binderCharacter.combatNodeChoices.filter { implementedIDs.contains($0.key) }
        var companionChoices: [PersistentPartyMemberID: [CombatNodeID: StableChoiceID]] = Dictionary(uniqueKeysWithValues: state.base.activeParty.compactMap { id in
            guard let index = state.base.rosterIndex(for: id) else { return nil }
            return (id, state.base.roster[index].character.combatNodeChoices
                .filter { implementedIDs.contains($0.key) })
        })
        if run.tuning.debugCombatV2BinderAttackEnabled {
            binderNodeIDs.formUnion(run.tuning.debugCombatV2BinderNodeIDs)
            binderChoices.merge(run.tuning.debugCombatV2BinderChoices) { _, debug in debug }
            for (index, nodes) in run.tuning.debugCombatV2CompanionNodeIDs {
                if let id = state.base.persistentID(forRosterIndex: index) {
                    companionNodeIDs[id, default: []].formUnion(nodes)
                }
            }
            for (index, choices) in run.tuning.debugCombatV2CompanionChoices {
                if let id = state.base.persistentID(forRosterIndex: index) {
                    companionChoices[id, default: [:]].merge(choices) { _, debug in debug }
                }
            }
        }
        let usesStableCombatGraph = run.tuning.debugCombatV2BinderAttackEnabled || !binderNodeIDs.isEmpty
            || companionNodeIDs.values.contains(where: { !$0.isEmpty })

        let debugAttackReceipt = CombatDerivedStatsRules.debugBinderAttackReceipt(
            enabled: usesStableCombatGraph,
            selectedNodeIDs: binderNodeIDs,
            ordinaryWeaponKind: CombatRules.damageKind(for: .binder, in: state))
        let debugInitiativeReceipt = CombatDerivedStatsRules.debugInitiativeReceipt(
            enabled: usesStableCombatGraph,
            party: party, foes: foes,
            binderNodeIDs: binderNodeIDs,
            companionNodeIDs: companionNodeIDs)
        let debugArmourReceipt = CombatRules.debugArmourReceipt(
            enabled: usesStableCombatGraph,
            party: party, in: state,
            binderNodeIDs: binderNodeIDs,
            companionNodeIDs: companionNodeIDs)
        let debugEvasionReceipt = CombatDerivedStatsRules.debugEvasionReceipt(
            enabled: usesStableCombatGraph,
            party: party, in: state,
            binderNodeIDs: binderNodeIDs,
            companionNodeIDs: companionNodeIDs)
        let debugResistanceReceipt = CombatDerivedStatsRules.debugResistanceReceipt(
            enabled: usesStableCombatGraph,
            party: party,
            binderNodeIDs: binderNodeIDs,
            binderChoices: binderChoices,
            companionNodeIDs: companionNodeIDs,
            companionChoices: companionChoices)
        let ghostEvasionAvailable = Set(party.filter { actor in
            if usesStableCombatGraph {
                switch actor {
                case .binder: return binderNodeIDs.contains(CombatDerivedStatsRules.Node.ghost)
                case .companion(let id):
                    return (companionNodeIDs[id] ?? [])
                        .contains(CombatDerivedStatsRules.Node.ghost)
                case .foe: return false
                }
            }
            return CombatRules.loadout(of: actor, in: state).firstAttackAlwaysMisses
        })
        let partyRanks = Dictionary(uniqueKeysWithValues: party.map {
            ($0, CombatRules.rank(of: $0, in: state))
        })
        let debugOwnedNodeIDs: [Combatant: Set<CombatNodeID>]? = usesStableCombatGraph
            ? Dictionary(uniqueKeysWithValues: party.map { actor in
                switch actor {
                case .binder: return (actor, binderNodeIDs)
                case .companion(let id): return (actor, companionNodeIDs[id] ?? [])
                case .foe: return (actor, [])
                }
            })
            : nil
        run.activeEncounter = CombatRules.makeEncounter(id: InstanceID(rawValue: run.rng.next()),
                                                        foes: foes,
                                                        party: party,
                                                        names: state.base.activeParty.reduce(into: [PersistentPartyMemberID: String]()) {
                                                            guard let index = state.base.rosterIndex(for: $1) else { return }
                                                            $0[$1] = state.base.roster[index].name
                                                        },
                                                        apexActionSlots: scalingPreview.map { preview in
                                                            foes.filter(\.isApex).reduce(into: [:]) {
                                                                $0[$1.id] = preview.apexActionSlots
                                                            }
                                                        } ?? [:],
                                                        ordinaryPressureSlots: ordinaryPressureSlots,
                                                        initiallyUnrecordedSpecies: initiallyUnrecordedSpecies,
                                                        debugV2BinderAttack: debugAttackReceipt,
                                                        debugV2Initiative: debugInitiativeReceipt,
                                                        debugV2Armour: debugArmourReceipt,
                                                        debugV2Evasion: debugEvasionReceipt,
                                                        debugV2Resistance: debugResistanceReceipt,
                                                        ghostEvasionAvailable: ghostEvasionAvailable,
                                                        debugV2OwnedNodeIDs: debugOwnedNodeIDs,
                                                        partyRanks: partyRanks,
                                                        rng: &run.rng)
        run.activeEncounter?.scalingPreview = scalingPreview
#if DEBUG
        if suppliedDebugGodMode ?? DebugTuningProfile.active.debugGodModeEnabled {
            run.activeEncounter?.debugGodMode = .init()
        }
#endif
        if var encounter = run.activeEncounter {
            let pending: [InstanceID]
            if resolvedOpening == .creatureAmbush, !watchfulSuppressed {
                pending = encounter.order.compactMap(\.foeID).filter { foeID in
                    encounter.foes.contains { $0.id == foeID && $0.isAlive }
                }
            } else {
                pending = []
            }
            encounter.opening = .init(preContactDisclosed: preContact.disclosed(enemy),
                                      initial: initialOpening,
                                      slipperyProbability: slipperyProbability > 0 ? slipperyProbability : nil,
                                      slipperyRoll: slipperyRoll,
                                      slipperyPrevented: slipperyPrevented,
                                      watchfulSuppressedOpening: watchfulSuppressed,
                                      resolved: resolvedOpening,
                                      pendingFoeActions: pending)
            // Unseen begins after classification. It cannot change an ambush into a safer opening,
            // but its owner is concealed for the first ordinary round.
            for actor in party where CombatRules.loadout(of: actor, in: state).beginsConcealed {
                encounter.concealed[actor] = max(1, encounter.concealed[actor] ?? 0)
            }
            switch resolvedOpening {
            case .creatureAmbush:
                encounter.note(watchfulSuppressed
                               ? "Watchful: you keep the normal opening order."
                               : "They strike from cover before normal turn order begins.")
            case .mutualContact where slipperyPrevented:
                encounter.note("Slippery: the sudden attack becomes mutual contact.")
            default: break
            }
            run.activeEncounter = encounter
        }
        state.worlds.activeRun = run

        // **Somebody has to move first, and it may not be you.** Automatic turns used to be kicked
        // off only by a player tap, which was safe while the party was always first in the order.
        // With turn order coming off initiative, a fight that opens on a creature's turn would
        // otherwise sit there waiting on nobody: the player's buttons do nothing, because it isn't
        // their turn, and nothing else is running.
        if runsAutomaticTurns { CombatRules.runAutomaticTurns(in: &state) }
        return true
    }

}
