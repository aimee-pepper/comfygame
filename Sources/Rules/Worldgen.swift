import Foundation

enum WildWorldPageSelectionRules {
    struct Context: Equatable, Sendable {
        var resolvedExpeditions: Int
        var drought: Int
        var ownedCopies: [WorldPageDefinitionID: Int]
        var worldContextTags: Set<String>
        var suppressesRandomPage: Bool
    }

    struct Selection: Equatable, Sendable {
        var definition: WorldPageDefinition
        var generationSeed: UInt64
        var instanceID: InstanceID
    }

    static let baseChance = 0.15
    static let guaranteeDrought = 5
    static let copyLimit = 2

    static func contextTags(for book: BoundBook, seed: UInt64) -> Set<String> {
        BookRules.readings(for: book, seed: seed).inOrder.reduce(into: Set<String>()) {
            tags, reading in
            if reading.peak > 0 || reading.demand > 0 || reading.floor > 0 {
                tags.insert(reading.target.rawValue)
                tags.formUnion(reading.tags)
            }
        }
    }

    static func select(seed: UInt64, context: Context,
                       definitions: [WorldPageDefinition] = WorldPageCatalog.repeatableDefinitions)
        -> Selection? {
        guard !context.suppressesRandomPage, context.resolvedExpeditions >= 1 else { return nil }
        var rng = SeededRNG(seed: seed).derived(0x5750_4147_45)
        let eligible = definitions
            .filter { definition in
                definition.disposition.isRandom
                    && definition.minimumResolvedExpeditions <= context.resolvedExpeditions
                    && context.ownedCopies[definition.id, default: 0] < copyLimit
            }
            .sorted { $0.id.rawValue < $1.id.rawValue }
        guard !eligible.isEmpty else { return nil }
        let guaranteed = context.drought >= guaranteeDrought
        guard guaranteed || rng.chance(baseChance) else { return nil }
        let weighted = eligible.map { definition in
            let contextMultiplier = definition.contextTags.contains {
                context.worldContextTags.contains($0)
            } ? 3.0 : 1.0
            return (value: definition,
                    weight: definition.baseWeightMultiplier * contextMultiplier)
        }
        guard let definition = rng.pickWeighted(weighted) else { return nil }
        let generationSeed = rng.next()
        var rawID = rng.next()
        if rawID == 0 { rawID = 1 }
        return Selection(definition: definition, generationSeed: generationSeed,
                         instanceID: InstanceID(rawValue: rawID))
    }
}

enum WildWorldPageFieldRules {
    enum DiscardedPayload: Equatable, Sendable {
        case itemStack(ItemStack)
        case worldPage(WorldPageInstance)
    }

    enum SlotOccupant: Equatable, Sendable, Identifiable {
        case itemStack(InstanceID)
        case worldPage(InstanceID)

        var id: String {
            switch self {
            case .itemStack(let id): "item-\(id.rawValue)"
            case .worldPage(let id): "page-\(id.rawValue)"
            }
        }
    }
    struct Quote: Equatable, Sendable {
        var instance: WorldPageInstance
        var position: GridPoint
    }

    enum Result: Equatable, Sendable {
        case inspected(WorldPageInstance)
        case taken(WorldPageInstance)
        case swapped(WorldPageInstance, discarded: DiscardedPayload)
        case stale
        case notHere
        case satchelFull
        case duplicateIdentity
    }

    static func quote(_ instanceID: InstanceID, in run: WorldRun) -> Quote? {
        let matches = run.offeredWorldPages.filter { $0.id == instanceID }
        guard matches.count == 1, let instance = matches.first,
              let position = instance.fieldProvenance?.position,
              position == run.playerPosition,
              run.map.contains(position), run.map[position].isRevealed,
              WorldPageCatalog.definition(instance.definition.id) == instance.definition
        else { return nil }
        return Quote(instance: instance, position: position)
    }

    @discardableResult
    static func inspect(_ quote: Quote, in run: inout WorldRun) -> Result {
        guard let current = self.quote(quote.instance.id, in: run), current == quote else {
            return .stale
        }
        guard !run.carriedWorldPages.contains(where: { $0.id == quote.instance.id }) else {
            return .duplicateIdentity
        }
        guard let index = run.offeredWorldPages.firstIndex(where: { $0.id == quote.instance.id })
        else { return .stale }
        run.offeredWorldPages[index].inspected = true
        return .inspected(run.offeredWorldPages[index])
    }

    @discardableResult
    static func take(_ quote: Quote, in run: inout WorldRun) -> Result {
        guard let current = self.quote(quote.instance.id, in: run), current == quote else {
            return .stale
        }
        guard !run.carriedWorldPages.contains(where: { $0.id == quote.instance.id }) else {
            return .duplicateIdentity
        }
        guard run.freeSatchelSlots >= 1 else { return .satchelFull }
        guard let index = run.offeredWorldPages.firstIndex(where: { $0.id == quote.instance.id })
        else { return .stale }
        let instance = run.offeredWorldPages.remove(at: index)
        run.carriedWorldPages.append(instance)
        return .taken(instance)
    }

    static func swap(_ quote: Quote, discarding occupant: SlotOccupant,
                     in run: inout WorldRun) -> Result {
        guard let current = self.quote(quote.instance.id, in: run), current == quote,
              run.freeSatchelSlots == 0,
              !run.carriedWorldPages.contains(where: { $0.id == quote.instance.id }),
              let offeredIndex = run.offeredWorldPages.firstIndex(where: {
                  $0.id == quote.instance.id
              })
        else { return .stale }
        let discarded: DiscardedPayload
        switch occupant {
        case .itemStack(let id):
            let matches = run.satchelItems.stacks.indices.filter {
                run.satchelItems.stacks[$0].id == id
            }
            guard matches.count == 1 else { return .stale }
            discarded = .itemStack(run.satchelItems.stacks.remove(at: matches[0]))
        case .worldPage(let id):
            let matches = run.carriedWorldPages.indices.filter {
                run.carriedWorldPages[$0].id == id
            }
            guard matches.count == 1 else { return .stale }
            discarded = .worldPage(run.carriedWorldPages.remove(at: matches[0]))
        }
        let taken = run.offeredWorldPages.remove(at: offeredIndex)
        run.carriedWorldPages.append(taken)
        return .swapped(taken, discarded: discarded)
    }
}

enum WildWorldPagePlacementRules {
    static func place(_ selection: WildWorldPageSelectionRules.Selection,
                      originRunIndex: Int, originWorldSeed: UInt64,
                      in map: WorldMap) -> WorldPageInstance? {
        let reachable = reachablePoints(from: map.entry, in: map)
        let candidates = reachable.filter { point in
            point != map.entry && map[point].content == .empty
        }.sorted { ($0.y, $0.x) < ($1.y, $1.x) }
        guard !candidates.isEmpty else { return nil }
        var rng = SeededRNG(seed: selection.generationSeed).derived(0x504C_4143_45)
        let point = candidates[rng.int(in: 0...(candidates.count - 1))]
        return WorldPageInstance(
            id: selection.instanceID, definition: selection.definition,
            fieldProvenance: .init(originRunIndex: originRunIndex,
                                   originWorldSeed: originWorldSeed,
                                   generationSeed: selection.generationSeed,
                                   position: point))
    }

    private static func reachablePoints(from entry: GridPoint, in map: WorldMap) -> Set<GridPoint> {
        guard map.contains(entry), map[entry].isPassable else { return [] }
        var reached: Set<GridPoint> = [entry]
        var queue = [entry]
        while !queue.isEmpty {
            let point = queue.removeFirst()
            for neighbour in map.neighbours(of: point)
            where map[neighbour].isPassable && reached.insert(neighbour).inserted {
                queue.append(neighbour)
            }
        }
        return reached
    }
}

/// Turns (book, seed) into a tile grid.
///
/// Every roll comes off a stream derived from the world's seed with a fixed salt per pass, so
/// generation is reproducible and — importantly — *stable under change*: adding a new pass later
/// doesn't shift the terrain an existing seed produces, because each pass has its own stream.
///
/// The run's live `rng` is deliberately untouched here. Worldgen must not consume from the stream
/// that in-run rolls draw from, or a resume would need to know how much generation had eaten.
enum Worldgen {

    private enum Salt {
        static let layout: UInt64 = 0x1A70
        static let nodes: UInt64 = 0x2D0DE
        static let enemies: UInt64 = 0x3F0E
        static let features: UInt64 = 0x4CAC
        static let sites: UInt64 = 0x5175
        static let pages: UInt64 = 0x9A6E
        static let travellerArrival: UInt64 = 0x7A4E2
    }

    static func generate(book: BoundBook, seed: UInt64, library: LibraryState = LibraryState(),
                         tuning: DebugTuningProfile = .defaults,
                         isFreshFirstExpedition: Bool = false,
                         wildPageSelection: WildWorldPageSelectionRules.Selection? = nil,
                         wildPageOriginRunIndex: Int? = nil)
        -> (map: WorldMap, enemies: [WorldEnemy], sites: [PlacedSite],
            pages: [DiaryPageID], writings: [FoundWritingRecord], wildPage: WorldPageInstance?,
            travellers: [TravellerID], cast: [Species], flora: [Flora],
            start: GridPoint, diagnostics: WorldGenerationDiagnostics) {
        // **Size is written, not fixed** (session 13 §5). The book carries the Scale it was
        // written at, so the same book always makes the same size of world.
        let width = book.scale.gridSide
        let height = book.scale.gridSide
        var map = WorldMap(
            width: width,
            height: height,
            tiles: Array(repeating: Tile(), count: width * height),
            entry: GridPoint(x: 0, y: 0)
        )

        let root = SeededRNG(seed: seed)
        var terrainRNG = root.derived(0x7E44)
        var layoutRNG = root.derived(Salt.layout)
        var nodeRNG = root.derived(Salt.nodes)
        var enemyRNG = root.derived(Salt.enemies)
        var featureRNG = root.derived(Salt.features)
        var siteRNG = root.derived(Salt.sites)
        var pageRNG = root.derived(Salt.pages)

        // Everything below reads the world's *pressures*. What a world is made of and what lives
        // in it now come from the eight targets rather than from flat per-symbol tables.
        let sigils = BookRules.sigils(for: book)
        let pressurePair = travellerCausalityReadings(authoredSigils: sigils, seed: seed)
        let readings = pressurePair.actual
        let withoutAuthoredPressure = pressurePair.withoutAuthoredPressure
        let resolvedStabilityScore = BookRules.resolvedStabilityScore(of: book, seed: seed)
        // The same world with nothing rolled into it. Chasms read this as a floor, and the exit rule
        // reads it alone — see `TerrainRules.isRiven(asWritten:)`.
        let asWritten = PressureRules.resolve(sigils)

        // 0. **What grows here, before the ground is painted.** Flora is sampled first because it
        //    writes terrain: cover, and therefore ambush, and therefore the whole openness axis.
        //    A world with no viable metabolism grows nothing, and that is a real answer rather than
        //    a failure — see `FloraRules.viability`.
        let flora = FloraRules.cast(for: readings, seed: seed)

        // 0a. The ground itself, before anything is placed on it. Relief, Substrate, Hydrology,
        //    Thermal and Vitality all write here — this is the surface the pressure model was
        //    missing, and without it Relief had nothing to say.
        TerrainRules.paint(&map, readings: readings, asWritten: asWritten, flora: flora,
                           rng: &terrainRNG)

        // 1. Where you arrive: a portal on the edge. It works as an exit too, so retreating the
        //    way you came is always possible — it just costs you the turns to walk back.
        //    (Whether that's too forgiving is Q6 in questions-for-aimee.md.)
        let entry = TerrainRules.firmGround(near: randomEdgePoint(in: map, rng: &layoutRNG), in: map)
        map.entry = entry
        map[entry].content = .portal(isEntry: true)

        // 1a. **Nothing may be stranded.** Chasms are carved from several mouths and can cut a world
        //     into islands, so the way is opened until most of the solid ground is walkable-to — and
        //     everything that can't be reached is then treated as occupied, which is the one line
        //     that stops a node, a site, a page or a person being placed somewhere you can't go.
        let walkable = TerrainRules.openTheWay(from: entry, in: &map, rng: &terrainRNG)
        var occupied: Set<GridPoint> = [entry]
        occupied.formUnion(map.allPoints.filter { !walkable.contains($0) })

        // 2. At least one more portal, placed away from the entry so it's worth finding — unless the
        //    world is so full of empty holes that the only way out is the way you came in (Aimee, 7
        //    Aug). That world is not a trap: the entry has always worked as an exit. It just costs
        //    you the whole walk back, which is what writing a world that riven is worth.
        let exitCount = TerrainRules.isRiven(asWritten: asWritten)
            ? 0 : layoutRNG.int(in: Tuning.World.exitPortalCountRange)
        for _ in 0..<exitCount {
            guard let point = randomFreePoint(in: map, avoiding: occupied, minimumDistanceFrom: entry,
                                              distance: Tuning.World.minimumExitPortalDistance, rng: &layoutRNG)
            else { continue }
            map[point].content = .portal(isEntry: false)
            occupied.insert(point)
        }

        // 2a. Found writing reserves its host before optional resources, sites and creatures can
        //     consume every useful tile. Content is still selected first; host selection then uses
        //     the nearest third of the start-connected region, beyond the first two steps.
        let diaryCandidates = LibraryRules.placePages(in: readings, library: library,
                                                      additionalPageChance: 1,
                                                      patienceInWorlds: tuning.diaryPatienceWorlds,
                                                      rng: &pageRNG)
        var pages: [DiaryPageID] = []
        var noteCount = 0
        if let first = diaryCandidates.first, pageRNG.chance(tuning.diaryWritingShare) {
            pages.append(first)
        } else {
            noteCount = 1
        }
        let secondWritingRollSucceeded = pageRNG.chance(tuning.additionalPageChance)
        if secondWritingRollSucceeded {
            if pages.isEmpty, let first = diaryCandidates.first {
                pages.append(first)
            } else {
                noteCount += 1
            }
        }

        var placedPages: [DiaryPageID] = []
        for page in pages {
            guard let point = writingPoint(in: map, from: entry, avoiding: occupied, rng: &pageRNG)
            else { continue }
            map[point].content = .diaryPage(page)
            occupied.insert(point)
            placedPages.append(page)
        }
        var foundWritings: [FoundWritingRecord] = []
        var usedFieldNoteKeys: Set<String> = []
        for index in 0..<noteCount {
            guard let point = writingPoint(in: map, from: entry, avoiding: occupied, rng: &pageRNG)
            else { continue }
            let id = FoundWritingID(rawValue: "world_\(seed)_field_\(index)")
            let record = fieldNote(id: id, at: point, in: map, flora: flora,
                                   readings: readings, seed: seed,
                                   excluding: &usedFieldNoteKeys, rng: &pageRNG)
            map[point].content = .foundWriting(id)
            occupied.insert(point)
            foundWritings.append(record)
        }
        if placedPages.isEmpty, foundWritings.isEmpty,
           let point = writingPoint(in: map, from: entry, avoiding: occupied, rng: &pageRNG) {
            let id = FoundWritingID(rawValue: "world_\(seed)_field_fallback")
            let record = fieldNote(id: id, at: point, in: map, flora: flora,
                                   readings: readings, seed: seed,
                                   excluding: &usedFieldNoteKeys, rng: &pageRNG)
            map[point].content = .foundWriting(id)
            occupied.insert(point)
            foundWritings.append(record)
        }

        // The loose World Page reserves an already reachable empty host only after ordinary
        // writing has been guaranteed. Adding optional nodes/sites below therefore cannot displace
        // that writing or consume the page's host.
        let wildPage = wildPageSelection.flatMap { selection in
            WildWorldPagePlacementRules.place(
                selection, originRunIndex: wildPageOriginRunIndex ?? 0,
                originWorldSeed: seed, in: map)
        }
        if let point = wildPage?.fieldProvenance?.position { occupied.insert(point) }

        // 3. Resource nodes. Count and richness both come from the book — a bounty-heavy book is
        //    visibly denser on the grid, not just better per pull.
        //
        //    **Organic nodes stand where something is actually growing** (`flora-system-spec.md`
        //    §6). Which one it is comes off the plant on that tile rather than off the yield table:
        //    a thicket of woody stuff is timber, and the same thicket somewhere toxic is poison. The
        //    table still decides *whether* this world holds a given resource at all; the flora
        //    decides which of them this particular node is.
        let yieldTable = BookRules.yieldTable(from: readings)
        let nodeCount = nodeCount(for: readings, multiplier: tuning.resourceNodeDensityMultiplier,
                                  rng: &nodeRNG)
        let floraByID = Dictionary(uniqueKeysWithValues: flora.map { ($0.id, $0) })
        for _ in 0..<nodeCount {
            guard var resource = nodeRNG.pickWeighted(yieldTable) else { continue }
            let organic = FloraRules.isFloraResource(resource)
            guard let point = randomFreePoint(in: map, avoiding: occupied,
                                              preferringGrowth: organic, rng: &nodeRNG)
            else { continue }
            // Standing in it, or standing next to it — a thicket is harvested from its edge as
            // readily as from inside.
            let plant = organic ? growth(nearest: point, in: map, from: floraByID) : nil
            if organic {
                // Nothing grows on this square, so nothing organic comes off it. Better a slightly
                // thinner world than timber lying on bare rock.
                guard let plant else { continue }
                resource = FloraRules.yield(of: plant.traits)
            }
            map[point].content = .node(ResourceNode(
                resource: resource,
                remainingHarvests: nodeRNG.int(in: Tuning.World.harvestTurnsRange),
                // **Quantity from stature**, where a plant is what you're cutting. Otherwise the
                // substrate's concentration decides, as it always has.
                yieldPerHarvest: plant.map { FloraRules.harvestQuantity(of: $0.traits) }
                    ?? nodeYield(dispersion: readings["substrate"].aspect("dispersion"),
                                 rng: &nodeRNG)
            ))
            occupied.insert(point)
        }

        // 4. Wild drops — single pickups you get just by walking over them. Raw essence arrives
        //    this way (Aimee's stated design), so it's a reason to wander off your path.
        let rawEssenceEligibleTiles = map.allPoints.count {
            !occupied.contains($0) && map[$0].content == .empty && map[$0].isPassable
        }
        let wildCount = scaled(featureRNG.int(in: tuning.rawEssenceProfile.dropRange),
                               by: tuning.rawEssenceFrequencyMultiplier)
        var rawEssenceDropsPlaced = 0
        var rawEssenceObtainable = 0
        for _ in 0..<wildCount {
            guard let point = randomFreePoint(in: map, avoiding: occupied, rng: &featureRNG) else { continue }
            let amount = scaled(featureRNG.int(in: tuning.rawEssenceProfile.amountRange),
                                by: tuning.rawEssenceYieldMultiplier)
            map[point].content = .wildDrop(resource: Resources.essenceRaw, amount: amount)
            occupied.insert(point)
            rawEssenceDropsPlaced += 1
            rawEssenceObtainable += amount
        }

        // 5. A locked cache, sometimes. It can only be opened with a key found in a *different*
        //    world — the whole point is that you see it long before you can have it.
        if featureRNG.chance(Tuning.World.lockedCacheChance),
           let point = randomFreePoint(in: map, avoiding: occupied, rng: &featureRNG) {
            map[point].content = .lockedCache
            occupied.insert(point)
        }

        // 6. Hazard tiles the *book* asked for, as opposed to the ones a collapsing world grows
        //    later. Storm and Tremor buy their stability with these.
        // **And the ones the sky put there.** A meteor is a hazard rather than a light (Aimee):
        // falling rock that damages, cracks the ground, and leaves material behind. Written as a
        // tag rather than a danger profile because it is a *focus* — danger profiles belong to the
        // seven runes that trade hostility for time, and a meteor isn't a bargain, it's a thing
        // that happened.
        let danger = BookRules.dangerProfile(for: book)
        let impacts = readings["substrate"].has("impact") ? Tuning.World.meteorCraters : 0
        for _ in 0..<(danger.hazardTiles + impacts) {
            guard let point = randomFreePoint(in: map, avoiding: occupied,
                                              minimumDistanceFrom: entry,
                                              distance: Tuning.World.enemyFreeRadiusAroundEntry,
                                              rng: &featureRNG)
            else { break }
            map[point].content = .hazard
            occupied.insert(point)
        }

        // 7. Sites — the discrete placed things. Eligibility is read off the world's *pressures*
        //    rather than off its symbols, so a site is found by writing a kind of place rather than
        //    by writing a specific recipe (docs/sites-system.md §2).
        var sites = SiteRules.place(in: map,
                                    readings: readings,
                                    contradictions: ContradictionRules.fired(in: sigils, readings: readings),
                                    avoiding: occupied, rng: &siteRNG)
        let sitePositions = occupied.union(sites.map(\.position))
        if let anchor = SiteRules.placeNaturalAnchor(in: map, avoiding: sitePositions, rng: &siteRNG) {
            sites.append(anchor)
        }
        // 7a. **The cast** — the species this world settled on, before anything is placed. Drawn
        //     from the readings and the seed, so the same world always holds the same animals.
        let cast = LifeRules.cast(for: readings, seed: seed)

        var guardians: [WorldEnemy] = []
        for site in sites {
            map[site.position].content = .site(site.id)
            occupied.insert(site.position)
            // A guarded site is placed by the site system and statted by the creature system. The
            // guardian stands *on* the site, so the fight is the price of the search rather than a
            // separate mechanic.
            //
            // **Guarded by something local.** A world's most formidable animal is what has moved
            // into its ruins — an authored guardian would be a creature from nowhere, in a world
            // that grew everything else it holds.
            if site.definition?.contents.guardian != nil {
                let guardian = cast.max { $0.traits.appetite < $1.traits.appetite } ?? cast.first
                if let guardian {
                    guardians.append(spawn(guardian, at: site.position, rng: &siteRNG))
                }
            }
        }

        // 9. Whoever this world's conditions describe is *standing here*, on a tile, waiting.
        //
        // They used to be a list on the run that nothing ever placed, and arriving marked them
        // found in the save — so the payoff for writing somebody's world was a database write
        // (Aimee, 6 Aug). Now you have to walk to them, and talk to them.
        let travellerCandidates = ContentCatalog.shared.travellersInAuthoredOrder
            .map(\.id)
            .filter { !library.foundTravellers.contains($0) }
        let matchingTravellerDefs = LibraryRules.travellersPresent(in: readings)
            .filter { !library.foundTravellers.contains($0.id) }
        let travellers = matchingTravellerDefs.map(\.id)
        let causalConditionIndices = Dictionary(uniqueKeysWithValues: matchingTravellerDefs.map { traveller in
            (traveller.id, LibraryRules.causalConditionIndices(
                for: traveller, actual: readings,
                withoutAuthoredPressure: withoutAuthoredPressure))
        })
        let travellerSelection = LibraryRules.selectTravellerForNewWorld(
            from: matchingTravellerDefs, library: library,
            blindDiscoveryWindow: tuning.blindDiscoveryWindow,
            causalConditionIndices: causalConditionIndices,
            clueWeight: tuning.travellerClueEvidenceWeight,
            authoredWeight: tuning.travellerAuthoredEvidenceWeight)
        var placedTravellers: [TravellerID] = []
        var travellerExclusions = travellerSelection.exclusions
        var travellerRNG = SeededRNG(seed: seed).derived(0x7A4E1)
        var arrivalRNG = SeededRNG(seed: seed).derived(Salt.travellerArrival)
        var travellerArrival = TravellerArrivalReceipt()
        if let traveller = travellerSelection.selected,
           let definition = matchingTravellerDefs.first(where: { $0.id == traveller }) {
            let evidence = travellerSelection.evidence[traveller]
                ?? .init(recoveredClues: 0, causallyAuthoredConditions: 0,
                         causallyAuthoredKnownConditions: 0, evidenceScore: 0)
            let priorNearMisses = library.travellerArrivalNearMisses[traveller] ?? 0
            let chance = LibraryRules.travellerArrivalChance(
                causallyAuthoredConditions: evidence.causallyAuthoredConditions,
                totalConditions: definition.signature.count,
                priorNearMisses: priorNearMisses,
                floor: tuning.travellerArrivalChanceFloor,
                nearMissIncrement: tuning.travellerArrivalNearMissIncrement)
            let roll = arrivalRNG.double(in: 0...1)
            travellerArrival = TravellerArrivalReceipt(
                selectedTraveller: traveller,
                storyArrivalBand: definition.storyArrivalBand,
                authoredOrder: definition.authoredOrder,
                totalConditions: definition.signature.count,
                recoveredLocationClues: evidence.recoveredClues,
                causallyAuthoredConditions: evidence.causallyAuthoredConditions,
                causallyAuthoredKnownConditions: evidence.causallyAuthoredKnownConditions,
                accidentalSatisfiedConditions: max(0, definition.signature.count
                    - evidence.causallyAuthoredConditions),
                evidenceScore: evidence.evidenceScore,
                priorNearMisses: priorNearMisses,
                arrivalChance: chance,
                arrivalRoll: roll,
                outcome: roll < chance || chance >= 1 ? .placementFailed : .confidenceFailed)
            if travellerArrival.outcome == .confidenceFailed {
                travellerExclusions.append(.init(traveller: traveller, reason: .arrivalRollFailed))
            }
            if travellerArrival.outcome != .confidenceFailed {
            // **Beside something, where there is something to be beside** (Q39.4, answered).
            //
            // A smith found next to a landmark is much better than a smith on a random tile — but
            // only as a *preference*: as a requirement it would mean a world that satisfies
            // somebody's signature and happens to generate no suitable site silently can't host
            // them, which is the marooning bug's shape. Right in the common case, dead end in the
            // uncommon one.
            let beside = sites
                .filter { $0.position.chebyshevDistance(to: entry) >= Tuning.World.travellerMinimumDistance }
                .flatMap { site in map.neighbours(of: site.position) }
                .filter { !occupied.contains($0) && map[$0].content == .empty && map[$0].isPassable }

            let point = travellerRNG.pick(beside)
                ?? randomFreePoint(in: map, avoiding: occupied,
                                   minimumDistanceFrom: entry,
                                   distance: Tuning.World.travellerMinimumDistance,
                                   rng: &travellerRNG)
            if let point {
                map[point].content = .traveller(traveller)
                occupied.insert(point)
                placedTravellers.append(traveller)
                travellerArrival.outcome = .placed
            } else {
                travellerExclusions.append(.init(traveller: traveller, reason: .noPlacementTile))
            }
            }
        }

        // 10. Enemies, drawn from the world's own cast. It's daytime when you arrive, so it's the
        //     day roster you meet; the night roster swaps in when the world turns.
        let dayRoster = roster(from: cast, nocturnal: false)
        let enemyCount = enemyCount(for: book, readings: readings,
                                    multiplier: tuning.creatureDensityMultiplier,
                                    rng: &enemyRNG, tiles: map.width * map.height)
        var enemies: [WorldEnemy] = guardians
            + plantPredators(flora, in: map, avoiding: &occupied, clearOf: entry,
                             multiplier: tuning.activeFloraFrequencyMultiplier, rng: &enemyRNG)

        // 9a. **Something this world cannot afford** (`apex-encounters.md`). Drawn by the things
        //     that already mean *dangerous and worth it* — greed above all, which gives the
        //     stability dial a third consequence after instability and loot. At most one: two
        //     makes them scenery.
        var apexRNG = SeededRNG(seed: seed).derived(0xA9E00)
        let apexChance = min(1, ApexRules.chance(
            greed: BookRules.greedDelta(for: sigils),
            stabilityScore: resolvedStabilityScore,
            dangerTiles: danger.hazardTiles,
            sites: sites.count) * max(0, tuning.apexChanceMultiplier))
        var apexDecisionRNG = SeededRNG(seed: seed).derived(0xA9E)
        let apexRollSucceeded = apexDecisionRNG.chance(apexChance)
        if let apex = ApexRules.sample(for: readings, seed: seed, chance: apexChance),
           let point = randomFreePoint(in: map, avoiding: occupied,
                                       minimumDistanceFrom: entry,
                                       distance: Tuning.Apex.minimumDistanceFromEntry,
                                       rng: &apexRNG) {
            var standing = spawn(apex, at: point, rng: &apexRNG)
            standing.isApex = true
            enemies.append(standing)
            occupied.insert(point)
        }
        for _ in 0..<enemyCount {
            guard let species = enemyRNG.pickWeighted(dayRoster),
                  let point = randomFreePoint(in: map, avoiding: occupied,
                                              minimumDistanceFrom: entry,
                                              distance: Tuning.World.enemyFreeRadiusAroundEntry,
                                              rng: &enemyRNG)
            else { continue }
            enemies.append(spawn(species, at: point, rng: &enemyRNG))
            occupied.insert(point)
        }

        WorldRules.reveal(around: entry, in: &map,
                          radius: WorldRules.visionRadius(for: book, seed: seed,
                                                          base: tuning.baseVisionRadius))
        let envelopeApplied = isFreshFirstExpedition
            && tuning.openingEncounterEnvelope != .natural
        let relocated = envelopeApplied
            ? applyOpeningEnvelope(tuning.openingEncounterEnvelope, to: &enemies, in: map,
                                   sites: sites, occupied: &occupied, seed: seed)
            : 0

        let nodeDiagnostics = map.tiles.reduce(into: [ResourceID: Int]()) { result, tile in
            if case .node(let node) = tile.content { result[node.resource, default: 0] += 1 }
        }
        let decay = BookRules.decayPerTurn(stabilityScore: resolvedStabilityScore)
            / max(0.01, tuning.stabilityDurationMultiplier)
        let turnBudget = decay > 0
            ? Int(ceil(Tuning.World.startingStability / decay))
            : Tuning.World.indefiniteTurns
        var diagnostics = WorldGenerationDiagnostics()
        diagnostics.selectedDiaryPages = pages
        diagnostics.selectedOtherWritingCount = noteCount
        diagnostics.placedDiaryPages = placedPages
        diagnostics.placedOtherWritings = foundWritings.map(\.id)
        diagnostics.secondWritingRollSucceeded = secondWritingRollSucceeded
        diagnostics.rawEssenceEligibleTiles = rawEssenceEligibleTiles
        diagnostics.rawEssencePlacementAttempts = wildCount
        diagnostics.rawEssenceDropsPlaced = rawEssenceDropsPlaced
        diagnostics.rawEssenceObtainable = rawEssenceObtainable
        diagnostics.ordinaryResourceNodes = nodeDiagnostics
        diagnostics.creatureSpeciesCount = cast.count
        diagnostics.creatureInstancesPlaced = enemies.count { !$0.isSessile && !$0.isApex }
        diagnostics.floraSpeciesCount = flora.count
        diagnostics.floraInstancesPlaced = map.tiles.count { $0.flora != nil }
        diagnostics.activeFloraPlaced = enemies.count(where: \.isSessile)
        diagnostics.apexChance = apexChance
        diagnostics.apexRollSucceeded = apexRollSucceeded
        diagnostics.apexPlaced = enemies.contains(where: \.isApex)
        diagnostics.initialTurnBudget = turnBudget
        diagnostics.projectedCollapseTurn = turnBudget
        diagnostics.travellerCandidates = travellerCandidates
        diagnostics.travellerSignatureMatches = travellers
        diagnostics.travellerEligibleMatches = travellerSelection.eligible
        diagnostics.travellerExclusions = travellerExclusions
        diagnostics.travellersPlaced = placedTravellers
        diagnostics.travellerArrival = travellerArrival
        diagnostics.openingEnvelopeRequested = tuning.openingEncounterEnvelope
        diagnostics.openingEnvelopeApplied = envelopeApplied
        diagnostics.openingEnemiesRelocated = relocated
        return (map, enemies, sites, placedPages, foundWritings, wildPage, placedTravellers,
                cast, flora, entry,
                diagnostics)
    }

    /// The actual world and the same seed with the player's pressure removed.
    ///
    /// Removing authored pressure makes those targets silent again, so they must participate in
    /// the ordinary unwritten roll. Reusing only the actual world's already-rolled sigils would
    /// leave the newly silent targets empty and falsely credit every authored target as causal.
    static func travellerCausalityReadings(authoredSigils: [Sigil], seed: UInt64)
        -> (actual: PressureReadings, withoutAuthoredPressure: PressureReadings) {
        let actualRolled = PressureRules.rollUnwritten(after: authoredSigils, seed: seed)
        let counterfactualRolled = PressureRules.rollUnwritten(after: [], seed: seed)
        return (
            PressureRules.resolve(authoredSigils + actualRolled),
            PressureRules.resolve(counterfactualRolled)
        )
    }

    private static func applyOpeningEnvelope(
        _ envelope: DebugTuningProfile.OpeningEncounterEnvelope,
        to enemies: inout [WorldEnemy], in map: WorldMap, sites: [PlacedSite],
        occupied: inout Set<GridPoint>, seed: UInt64
    ) -> Int {
        let allowed = envelope == .gentle ? 1 : 0
        let guardianPositions = Set(sites.map(\.position))
        let nearby = enemies.indices.filter { index in
            let enemy = enemies[index]
            return map[enemy.position].isRevealed && !enemy.isSessile && !enemy.isApex
                && !guardianPositions.contains(enemy.position)
        }
        guard nearby.count > allowed else { return 0 }
        var rng = SeededRNG(seed: seed).derived(0xE17E10)
        var moved = 0
        for index in nearby.dropFirst(allowed) {
            let old = enemies[index].position
            occupied.remove(old)
            let candidates = map.allPoints.filter { point in
                !map[point].isRevealed && map[point].isPassable && map[point].content == .empty
                    && !occupied.contains(point)
            }
            guard let destination = rng.pick(candidates) else {
                occupied.insert(old)
                continue
            }
            enemies[index].position = destination
            occupied.insert(destination)
            moved += 1
        }
        return moved
    }

    private static func writingPoint(in map: WorldMap, from entry: GridPoint,
                                     avoiding occupied: Set<GridPoint>, rng: inout SeededRNG) -> GridPoint? {
        var distances: [GridPoint: Int] = [entry: 0]
        var queue = [entry]
        var cursor = 0
        while cursor < queue.count {
            let point = queue[cursor]
            cursor += 1
            for next in map.neighbours(of: point)
            where map[next].isPassable && distances[next] == nil {
                distances[next] = (distances[point] ?? 0) + map[next].ground.movementCost
                queue.append(next)
            }
        }
        let candidates = map.allPoints.filter {
            !occupied.contains($0) && map[$0].isPassable && map[$0].content == .empty
                && $0.chebyshevDistance(to: entry) > 2
                && distances[$0] != nil
        }.sorted {
            let left = distances[$0] ?? .max
            let right = distances[$1] ?? .max
            return (left, $0.y, $0.x) < (right, $1.y, $1.x)
        }
        guard !candidates.isEmpty else { return nil }
        return rng.pick(Array(candidates.prefix(max(1, candidates.count / 3))))
    }

    private enum FieldNoteFamily: Int, CaseIterable { case terrain, lightAir, growth, water }

    private struct FieldNoteCandidate {
        var family: FieldNoteFamily
        var templateID: String
        var fact: FieldNoteFact
        var prose: String
        var signature: String
        var weight: Int
    }

    /// Resolves one local witness statement and freezes both its safe fact and final prose. The
    /// candidate list is sorted before the one weighted draw, so collection/dictionary ordering
    /// can never rewrite an existing seed.
    private static func fieldNote(id: FoundWritingID, at point: GridPoint, in map: WorldMap,
                                  flora: [Flora], readings: PressureReadings, seed: UInt64,
                                  excluding used: inout Set<String>, rng: inout SeededRNG)
        -> FoundWritingRecord {
        var candidates = fieldNoteCandidates(at: point, in: map, flora: flora, readings: readings)
            .sorted { ($0.family.rawValue, $0.templateID, $0.signature)
                < ($1.family.rawValue, $1.templateID, $1.signature) }
        let distinct = candidates.filter {
            !used.contains("template:\($0.templateID)") && !used.contains("fact:\($0.signature)")
        }
        if !distinct.isEmpty { candidates = distinct }
        let familyGroups = Dictionary(grouping: candidates, by: \FieldNoteCandidate.family)
        let eligibleFamilies = FieldNoteFamily.allCases.filter { familyGroups[$0] != nil }
        let total = eligibleFamilies.reduce(0) { total, family in
            total + (familyGroups[family]?.first?.weight ?? 0)
        }
        var roll = rng.int(in: 1...total)
        let selectedFamily = eligibleFamilies.first { family in
            roll -= familyGroups[family]?.first?.weight ?? 0
            return roll <= 0
        } ?? .terrain
        let familyCandidates = familyGroups[selectedFamily] ?? candidates
        let index = Int(fieldNoteStableHash("\(seed)|\(id.rawValue)|\(selectedFamily.rawValue)")
                        % UInt64(familyCandidates.count))
        let selected = familyCandidates[index]
        used.insert("template:\(selected.templateID)")
        used.insert("fact:\(selected.signature)")
        return FoundWritingRecord(id: id, family: .fieldNote, prose: selected.prose,
                                  position: point, templateID: selected.templateID,
                                  fieldFact: selected.fact, originWorldSeed: seed)
    }

    private static func fieldNoteCandidates(at point: GridPoint, in map: WorldMap,
                                            flora: [Flora], readings: PressureReadings)
        -> [FieldNoteCandidate] {
        let host = map[point]
        let neighbours = cardinalNeighbours(of: point, in: map)
        var result: [FieldNoteCandidate] = []

        func add(_ family: FieldNoteFamily, _ template: String, _ tokens: FieldNoteTokens,
                 _ prose: String, _ signature: String) {
            let fact: FieldNoteFact = switch family {
            case .terrain: .terrain(tokens)
            case .lightAir: .lightAir(tokens)
            case .growth: .growth(tokens)
            case .water: .water(tokens)
            }
            let weight = switch family {
            case .terrain: 35
            case .lightAir, .growth: 20
            case .water: 15
            }
            result.append(.init(family: family, templateID: template, fact: fact,
                                prose: prose, signature: signature, weight: weight))
        }

        for neighbour in neighbours {
            let tile = map[neighbour.point]
            let direction = neighbour.direction
            if tile.ground != host.ground,
               tile.isPassable,
               tile.ground.movementCost == 1 {
                let tokens = FieldNoteTokens(groundA: host.ground.displayName,
                                             groundB: tile.ground.displayName,
                                             direction: direction)
                add(.terrain, "field_terrain_boundary_01", tokens,
                    "The \(host.ground.displayName) ends \(direction). I kept to the \(tile.ground.displayName), where each step held.",
                    "\(host.ground.rawValue)|\(tile.ground.rawValue)|\(direction)")
            }
            if tile.ground.movementCost == 2,
               let clearer = neighbours.first(where: { map[$0.point].ground.movementCost == 1
                   && map[$0.point].isPassable }) {
                let tokens = FieldNoteTokens(groundA: tile.ground.displayName,
                                             direction: clearer.direction, relation: "two turns")
                add(.terrain, "field_terrain_cost_01", tokens,
                    "The \(tile.ground.displayName) took twice the effort. I went \(clearer.direction) along the clearer edge.",
                    "\(tile.ground.rawValue)|\(clearer.direction)")
            }
            if tile.ground.blocksSight {
                let tokens = FieldNoteTokens(groundA: tile.ground.displayName,
                                             direction: direction, relation: "blocks sight")
                add(.terrain, "field_terrain_sight_01", tokens,
                    "Past the \(tile.ground.displayName), I could no longer see the mark behind me.",
                    "\(tile.ground.rawValue)|\(direction)")
            }
            if tile.elevation != host.elevation {
                let relation = tile.elevation > host.elevation ? "rises" : "falls"
                let tokens = FieldNoteTokens(direction: direction, relation: relation)
                add(.terrain, "field_terrain_height_01", tokens,
                    "The ground \(relation) toward the \(direction); the old scratches follow the same line.",
                    "\(relation)|\(direction)")
            }
            if !tile.isPassable {
                let tokens = FieldNoteTokens(groundA: tile.ground.displayName,
                                             direction: direction, relation: "impassable")
                add(.terrain, "field_terrain_edge_01", tokens,
                    "I turned \(direction) before the \(tile.ground.displayName). The rim continues farther than this page.",
                    "\(tile.ground.rawValue)|\(direction)")
            }
        }

        if neighbours.allSatisfy({ map[$0.point].ground == host.ground }) {
            let terrainTokens = FieldNoteTokens(groundA: host.ground.displayName,
                                                relation: "continues locally")
            add(.terrain, "field_terrain_single_01", terrainTokens,
                "I set this down on \(host.ground.displayName). The same ground continues on every visible side.",
                host.ground.rawValue)
        }

        let illumination = readings["illumination"]
        if illumination.peak <= 25 {
            add(.lightAir, "field_light_dark_01", .init(quality: "dark"),
                "I counted the next few steps by touch and kept the written side covered.", "dark")
        } else if illumination.floor >= 75 {
            add(.lightAir, "field_light_bright_01", .init(quality: "bright"),
                "I turned the page face-down. Even the unmarked side held the light.", "bright")
        } else if illumination.range >= Tuning.Pressure.wideRangeThreshold {
            add(.lightAir, "field_light_change_01", .init(relation: "changing light"),
                "The light changed before the ink dried; the ground did not.", "changing")
        } else {
            add(.lightAir, "field_light_held_01", .init(relation: "steady light"),
                "The light held while I wrote. I stopped waiting for it to turn.", "steady")
        }
        let movingAir = readings["atmosphere"].aspect("motion") > 50
        add(.lightAir, movingAir ? "field_air_moving_01" : "field_air_still_01",
            .init(relation: movingAir ? "moving air" : "still air"),
            movingAir
                ? "I weighted three corners. The air found the fourth whichever way I turned."
                : "The dust on this line had not shifted when I came back.",
            movingAir ? "moving" : "still")

        let local = [(point: point, direction: "here")] + neighbours
        for item in local where map[item.point].ground.isOvergrown {
            let tile = map[item.point]
            let height = tile.ground == .growth ? "tall" : "low"
            if let bare = cardinalNeighbours(of: item.point, in: map)
                .first(where: { !map[$0.point].ground.isOvergrown }) {
                let tokens = FieldNoteTokens(groundA: map[bare.point].ground.displayName,
                                             direction: bare.direction, quality: height)
                add(.growth, "field_growth_boundary_01", tokens,
                    "The \(height) growth stops at the \(map[bare.point].ground.displayName) as neatly as a cut thread.",
                    "\(height)|\(map[bare.point].ground.rawValue)|\(bare.direction)")
            }
            if let floraID = tile.flora, let plant = flora.first(where: { $0.id == floraID }) {
                let template: String
                let prose: String
                switch plant.traits.habit {
                case .spreading where height == "low":
                    template = "field_growth_spread_01"
                    prose = "The low growth crosses the path in one sheet; footsteps divide it, then it closes again."
                case .clustered:
                    template = "field_growth_cluster_01"
                    prose = "The growth gathers in separate knots. Bare ground remains between them."
                case .solitary where height == "tall":
                    template = "field_growth_solitary_01"
                    prose = "One tall form stands apart here. I could see its outline before its base."
                default:
                    template = "field_growth_form_01"
                    prose = "The \(height) growth keeps a \(plant.traits.habit.rawValue) shape here. Bare ground shows its edge."
                }
                add(.growth, template, .init(relation: plant.traits.habit.rawValue,
                                              quality: height), prose,
                    "\(floraID.rawValue)|\(plant.traits.habit.rawValue)|\(item.direction)")
            }
            if tile.ground.blocksSight {
                add(.growth, "field_growth_sight_01",
                    .init(direction: item.direction, relation: "blocks sight", quality: "tall"),
                    "The tall growth swallowed the mark behind me. I made the next one higher.",
                    "sight|\(item.direction)")
            }
        }

        for item in local {
            let ground = map[item.point].ground
            let tokens = FieldNoteTokens(groundA: host.ground.displayName,
                                         direction: item.direction, quality: ground.displayName)
            switch ground {
            case .water:
                add(.water, "field_water_shallow_01", tokens,
                    "The shallow water keeps the shape of the ground beneath it.", "water|\(item.direction)")
            case .deepWater:
                add(.water, "field_water_deep_01", tokens,
                    "The colour changes past the \(item.direction) edge. I did not test the deeper part.",
                    "deep|\(item.direction)")
            case .ice:
                add(.water, "field_water_ice_01", tokens,
                    "The surface held my weight here; the trapped line beneath it points \(item.direction).",
                    "ice|\(item.direction)")
            case .mud:
                if let firm = neighbours.first(where: { map[$0.point].ground.movementCost == 1
                    && map[$0.point].isPassable }) {
                    let firmTokens = FieldNoteTokens(direction: firm.direction,
                                                     relation: "two turns", quality: "mud")
                    add(.water, "field_water_mud_01", firmTokens,
                        "The mud kept every step and charged for each one. Firmer ground lies \(firm.direction).",
                        "mud|\(firm.direction)")
                }
            default: break
            }
        }
        return result
    }

    private static func cardinalNeighbours(of point: GridPoint, in map: WorldMap)
        -> [(point: GridPoint, direction: String)] {
        [(GridPoint(x: point.x, y: point.y - 1), "north"),
         (GridPoint(x: point.x + 1, y: point.y), "east"),
         (GridPoint(x: point.x, y: point.y + 1), "south"),
         (GridPoint(x: point.x - 1, y: point.y), "west")]
            .filter { map.contains($0.0) }
    }

    private static func fieldNoteStableHash(_ text: String) -> UInt64 {
        var hash: UInt64 = 0xcbf29ce484222325
        for byte in text.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x100000001b3
        }
        return hash
    }

    // MARK: The roster

    /// One animal of a species, standing somewhere. Its own jitter is rolled here and kept, so a
    /// resume finds the same creature rather than re-rolling it.
    static func spawn(_ species: Species, at point: GridPoint, rng: inout SeededRNG) -> WorldEnemy {
        WorldEnemy(id: InstanceID(rawValue: rng.next()),
                   speciesID: species.id,
                   traits: LifeRules.spawn(of: species, rng: &rng),
                   position: point)
    }

    /// Who's out, and how common each of them is.
    ///
    /// **Cheap animals are numerous and expensive ones are rare** — the pyramid falls out of the
    /// same appetite number the budget is spent against, rather than being an authored spawn weight.
    /// Falls back to the whole cast where a world has nobody on the roster it asked for, because an
    /// empty world at nightfall is worse than a world whose animals keep odd hours.
    static func roster(from cast: [Species], nocturnal: Bool) -> [(value: Species, weight: Double)] {
        let onDuty = cast.filter { $0.isNocturnal == nocturnal }
        let pool = onDuty.isEmpty ? cast : onDuty
        guard let dearest = pool.map({ $0.traits.appetite }).max(), dearest > 0 else {
            return pool.map { (value: $0, weight: 1) }
        }
        return pool.map { (value: $0, weight: max(0.15, 1.15 - $0.traits.appetite / dearest)) }
    }

    // MARK: Counts

    /// Richer books put more nodes on the ground. Scales off the book's yield multipliers so a new
    /// bounty symbol automatically affects density without touching this function.
    /// How much is lying about, from how much the world actually holds.
    ///
    /// Dispersion decides whether it's spread thin or gathered into fewer, richer places — which is
    /// what makes the concentrated↔pervasive axis worth writing.
    static func nodeCount(for readings: PressureReadings, multiplier: Double = 1,
                          rng: inout SeededRNG) -> Int {
        let substrate = readings["substrate"]
        let vitality = readings["vitality"]
        let richness = (substrate.peak + vitality.peak) / Tuning.Pressure.scaleMaximum
        let dispersion = substrate.aspect("dispersion") / Tuning.Pressure.scaleMaximum

        let base = Double(rng.int(in: Tuning.World.baseNodeCountRange))
        // Pervasive: more nodes, each ordinary. Concentrated: fewer, and worth finding.
        //
        // **Narrower than it was**, because the two terms could cancel outright: a scattered poor
        // world and a concentrated rich one came out at 277 and 276 nodes, so "a greedier book puts
        // more on the ground" stopped being true. Spread decides how the same wealth is *arranged*;
        // richness decides how much of it there is, and has to be the louder of the two.
        let spread = Tuning.World.nodeSpreadFloor
            + dispersion * (1 - Tuning.World.nodeSpreadFloor) * 2
        return max(1, Int((base * (0.4 + richness) * spread * multiplier).rounded()))
    }

    /// **What one node is worth, given how the world arranged its wealth.**
    ///
    /// The other half of the same sentence, and it was never built: "concentrated: fewer, and worth
    /// finding" set the count and left every node paying the same flat roll, so concentration was
    /// all cost and no reward.
    static func nodeYield(dispersion: Double, rng: inout SeededRNG) -> Int {
        let concentration = 1 - min(1, max(0, dispersion / Tuning.Pressure.scaleMaximum))
        let bonus = 1 + concentration * Tuning.World.nodeYieldConcentrationBonus
        return max(1, Int((Double(rng.int(in: Tuning.World.nodeYieldRange)) * bonus).rounded()))
    }

    /// How many things are actually standing in the world.
    ///
    /// **Danger says what they are; vitality says how many** (Aimee, 6 Aug: a world written for
    /// life should be *crawling*). The productivity term used to run `0.5 + vitality/100`, which
    /// tops out at 1.5 and dips *below* 1 for anything short of teeming — so a barren world and a
    /// paradise both held about four animals and "teeming life" was a word rather than a
    /// difference. It now runs from a fifth of the base to three times it.
    ///
    /// And it scales with **how much world there is**. The count was flat, so writing a large world
    /// bought you the same handful of animals spread over four times the ground — the bigger the
    /// world, the emptier it read.
    static func enemyCount(for book: BoundBook, readings: PressureReadings,
                           multiplier: Double = 1, rng: inout SeededRNG,
                           tiles: Int = Tuning.World.gridWidth * Tuning.World.gridHeight) -> Int {
        let tier = BookRules.enemyTier(of: book)
        let base = rng.int(in: Tuning.World.baseEnemyCountRange)
        let scaled = base + (tier - Tuning.World.baseEnemyTier) * Tuning.World.enemiesPerDangerTier
        // Swarm multiplies the count and drops the tier; Predation does the reverse. Applied after
        // the tier term so the two really do pull against each other rather than one winning.
        let productivity = min(1, readings["vitality"].peak / Tuning.World.teemingVitality)
        let life = Tuning.World.enemyCountAtDeath
            + productivity * (Tuning.World.enemyCountWhenTeeming - Tuning.World.enemyCountAtDeath)
        let area = Double(tiles) / Double(Tuning.World.gridWidth * Tuning.World.gridHeight)
        let multiplied = Double(scaled) * BookRules.dangerProfile(for: book).spawnMultiplier
            * life * area * multiplier
        return max(1, Int(multiplied.rounded()))
    }

    private static func scaled(_ value: Int, by multiplier: Double) -> Int {
        max(1, Int((Double(value) * multiplier).rounded()))
    }

    // MARK: Placement

    private static func randomEdgePoint(in map: WorldMap, rng: inout SeededRNG) -> GridPoint {
        let edges = map.allPoints.filter { map.ring(of: $0) == 0 }
        return rng.pick(edges) ?? GridPoint(x: 0, y: 0)
    }

    /// A point with nothing on it yet, optionally kept clear of somewhere.
    ///
    /// - Parameter preferringGrowth: weights the draw toward ground something is growing on or
    ///   beside. A *preference* rather than a filter, for the same reason travellers prefer sites:
    ///   as a requirement it would mean a world whose growth all happens to be occupied silently
    ///   drops its organic nodes, which is the marooning bug's shape.
    private static func randomFreePoint(in map: WorldMap,
                                        avoiding occupied: Set<GridPoint>,
                                        minimumDistanceFrom origin: GridPoint? = nil,
                                        distance: Int = 0,
                                        preferringGrowth: Bool = false,
                                        rng: inout SeededRNG) -> GridPoint? {
        var candidates = map.allPoints.filter { point in
            // Nothing is placed where nobody can stand.
            !occupied.contains(point) && map[point].content == .empty && map[point].isPassable
        }
        if let origin, distance > 0 {
            let far = candidates.filter { $0.chebyshevDistance(to: origin) >= distance }
            // Fall back to the unfiltered set rather than placing nothing at all — on a small or
            // crowded map the distance constraint can be unsatisfiable.
            if !far.isEmpty { candidates = far }
        }
        guard preferringGrowth else { return rng.pick(candidates) }
        let weighted = candidates.map { point in
            (value: point,
             weight: isNearGrowth(point, in: map) ? Tuning.Flora.nodeGrowthPreference : 1)
        }
        return rng.pickWeighted(weighted)
    }

    private static func isNearGrowth(_ point: GridPoint, in map: WorldMap) -> Bool {
        map[point].ground.isOvergrown || map.neighbours(of: point).contains { map[$0].ground.isOvergrown }
    }

    /// **What is growing here, or failing that, next door.** A thicket is harvested from its edge as
    /// readily as from inside it, which is what lets a node sit *beside* growth rather than only on
    /// it (`flora-system-spec.md` §6).
    private static func growth(nearest point: GridPoint, in map: WorldMap,
                               from cast: [InstanceID: Flora]) -> Flora? {
        if let here = map[point].flora, let plant = cast[here] { return plant }
        for neighbour in map.neighbours(of: point) {
            if let there = map[neighbour].flora, let plant = cast[there] { return plant }
        }
        return nil
    }

    /// **The undergrowth that stands up.**
    ///
    /// Grown by the flora system, fought by the creature system (`flora-system-spec.md` §9.3), so
    /// there is no second combat model. It stands on its own growth, it is rooted there, and it is
    /// awake from the start — you are not ambushed by it, you walk into it.
    static func plantPredators(_ flora: [Flora], in map: WorldMap,
                                       avoiding occupied: inout Set<GridPoint>,
                                       clearOf entry: GridPoint,
                                       multiplier: Double,
                                       rng: inout SeededRNG) -> [WorldEnemy] {
        let predatory = flora.filter { $0.traits.isPredatory }.sorted { $0.id.rawValue < $1.id.rawValue }
        guard !predatory.isEmpty else { return [] }

        var standing: [WorldEnemy] = []
        for plant in predatory {
            let tiles = map.allPoints.filter { point in
                map[point].flora == plant.id
                    && !occupied.contains(point)
                    && map[point].content == .empty
                    && map[point].isPassable
                    && point.chebyshevDistance(to: entry) >= Tuning.World.enemyFreeRadiusAroundEntry
            }
            // Rare, and rarer still per world: a patch of it, not a field.
            let count = max(0, Int((Double(Tuning.Flora.predatorsPerKind) * multiplier).rounded()))
            for _ in 0..<count {
                guard let point = rng.pick(tiles.filter { !occupied.contains($0) }) else { break }
                standing.append(WorldEnemy(id: InstanceID(rawValue: rng.next()),
                                           traits: FloraRules.combatant(from: plant.traits),
                                           position: point,
                                           isAwake: true,
                                           isSessile: true,
                                           floraID: plant.id))
                occupied.insert(point)
            }
        }
        return standing
    }
}
