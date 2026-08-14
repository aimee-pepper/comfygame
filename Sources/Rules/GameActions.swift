import Foundation

enum ReliquaryRules {
    static func revealSites(on map: inout WorldMap, sites: [PlacedSite]) {
        for site in sites where map.contains(site.position) {
            map[site.position].isRevealed = true
        }
    }
}

enum BindAvailability: Equatable {
    case ready(totalCost: Int)
    case activeExpedition
    case anchorageLocked
    case fieldKit(String)
    case unavailable(String)
    case insufficientEssence(available: Int, required: Int)

    var isReady: Bool {
        if case .ready = self { return true }
        return false
    }

    var refusalMessage: String? {
        switch self {
        case .ready:
            nil
        case .activeExpedition:
            "You are already in an expedition. Return Home before binding another world."
        case .anchorageLocked:
            "Born anchored requires the Anchorage. Turn it off or build the Anchorage first."
        case .fieldKit(let reason):
            reason
        case .unavailable(let reason):
            reason
        case let .insufficientEssence(available, required):
            "This binding needs \(required) Essence; you currently have \(available)."
        }
    }
}

/// Real player actions — the ones the shipping UI calls. Anything still faked lives in
/// `Sources/Debug/` and says so.
///
/// Every one of these goes through `mutate`, so every one of them is saved.
extension GameStore {

    // MARK: - Writing Desk

    // MARK: - The page

    /// Whether a symbol can still be fitted onto the page in the player's best hand.
    func canWrite(_ id: SymbolID) -> Bool {
        guard let symbol = ContentCatalog.shared.symbol(id) else { return false }
        guard blockingPrimary(for: id) == nil else { return false }
        return PageRules.placeAnywhere(symbol, hand: state.base.bestHand, on: state.base.page) != nil
    }

    /// The primary already claiming this symbol's target, if one is in the way.
    ///
    /// Surfaced so the palette can say *why* something is unavailable — "Plains already decides the
    /// land" is a rule you can learn; a greyed-out button is not.
    func blockingPrimary(for id: SymbolID) -> SymbolDef? {
        guard let symbol = ContentCatalog.shared.symbol(id) else { return nil }
        return PageRules.exclusivityConflict(writing: symbol, on: state.base.page,
                                             chainingUnlocked: state.base.hasChainingUnlock)
    }

    /// How many cells a symbol will take in the hand the player writes in.
    func footprint(of id: SymbolID) -> Int {
        guard let symbol = ContentCatalog.shared.symbol(id) else { return 0 }
        return PageRules.shape(forCompound: symbol, hand: state.base.bestHand)?.footprint ?? 0
    }

    /// Write a mark at a specific cell. Refused rather than relocated — where it goes is the
    /// player's decision, and quietly moving it would make the packing puzzle meaningless.
    @discardableResult
    func write(_ id: SymbolID, at cell: PageCell) -> Bool {
        guard blockingPrimary(for: id) == nil,
              let symbol = ContentCatalog.shared.symbol(id),
              let updated = PageRules.place(symbol, hand: state.base.bestHand, at: cell, on: state.base.page)
        else { return false }
        mutate("write \(id.rawValue)") { $0.base.page = updated }
        return true
    }

    /// Drop a mark into the first place it fits. For the palette's quick-add.
    @discardableResult
    func write(_ id: SymbolID) -> Bool {
        guard blockingPrimary(for: id) == nil,
              let symbol = ContentCatalog.shared.symbol(id),
              let updated = PageRules.placeAnywhere(symbol, hand: state.base.bestHand, on: state.base.page)
        else { return false }
        mutate("write \(id.rawValue)") { $0.base.page = updated }
        return true
    }

    /// Pick a mark up and put it down elsewhere. Free, and repeatable, until you bind.
    @discardableResult
    func move(_ mark: InstanceID, to cell: PageCell) -> Bool {
        guard let updated = PageRules.move(mark, to: cell, on: state.base.page) else { return false }
        mutate("move a mark") { $0.base.page = updated }
        return true
    }

    /// Write a target, source or qualifier sigil at a cell.
    @discardableResult
    func write(_ content: MarkContent, glyph: String, at cell: PageCell) -> Bool {
        guard let shape = PageRules.shape(for: content, hand: state.base.bestHand),
              PageRules.canPlace(shape: shape, at: cell, on: state.base.page)
        else { return false }
        mutate("write \(glyph)") { state in
            let next = (state.base.page.runes.map(\.id.rawValue).max() ?? 0) + 1
            state.base.page.runes.append(PlacedRune(id: InstanceID(rawValue: next),
                                                    content: content,
                                                    hand: state.base.bestHand,
                                                    origin: cell, shapeID: shape.id))
        }
        return true
    }

    /// Whether a sigil will fit anywhere at all in the current hand.
    func canWrite(_ content: MarkContent) -> Bool {
        guard let shape = PageRules.shape(for: content, hand: state.base.bestHand) else { return false }
        return !PageRules.validOrigins(for: shape, on: state.base.page).isEmpty
    }

    func footprint(_ content: MarkContent) -> Int {
        PageRules.shape(for: content, hand: state.base.bestHand)?.footprint ?? 0
    }

    /// **What binding this source to that target does to the meter.**
    ///
    /// Shown on every palette tile, because otherwise the only way to find out what a sigil costs
    /// is to write it, switch to The World, read the number, and switch back — for each of
    /// forty-one sources. A book you can't plan without tabbing back and forth isn't a book you're
    /// composing, it's one you're discovering by trial.
    ///
    /// Priced on its own, at moderate intensity, rather than against what's already on the page:
    /// a number that changed depending on what else you'd written would be unlearnable, and the
    /// point of putting it on the tile is that you come to know what a Sun costs.
    func stabilityOfWriting(_ source: PressureSourceID, on target: PressureTargetID) -> Int {
        BookRules.greedDelta(for: [Sigil(id: InstanceID(rawValue: 1), source: source, target: target)])
    }

    // MARK: Connecting

    /// Join two adjacent marks. Adjacency constrains; this is the declaration of intent.
    @discardableResult
    func connect(_ a: InstanceID, _ b: InstanceID) -> Bool {
        guard let updated = PageRules.connect(a, b, on: state.base.page,
                                              chainingUnlocked: state.base.hasChainingUnlock)
        else { return false }
        mutate("connect", flush: true) { $0.base.page = updated }
        return true
    }

    func connectionIssue(_ a: InstanceID, _ b: InstanceID) -> PageRules.ConnectionIssue? {
        PageRules.connectionIssue(a, b, on: state.base.page,
                                  chainingUnlocked: state.base.hasChainingUnlock)
    }

    func canConnect(_ a: InstanceID, _ b: InstanceID) -> Bool {
        connectionIssue(a, b) == nil
    }

    func disconnect(_ a: InstanceID, _ b: InstanceID) {
        mutate("disconnect", flush: true) { $0.base.page = PageRules.disconnect(a, b, on: $0.base.page) }
    }

    /// Break every link a mark has, splitting it out of its cluster.
    func disconnectAll(_ mark: InstanceID) {
        mutate("unlink", flush: true) { state in
            state.base.page.links = state.base.page.links.filter { !$0.involves(mark) }
        }
    }

    /// Move a whole cluster. A cluster is one object, so nothing inside it can come apart.
    @discardableResult
    func moveCluster(_ mark: InstanceID, by delta: PageCell) -> Bool {
        guard let updated = PageRules.move(cluster: mark, by: delta, on: state.base.page) else { return false }
        mutate("move cluster") { $0.base.page = updated }
        return true
    }

    /// Turn a cluster a quarter turn. Where the packing gameplay lives.
    @discardableResult
    func rotateCluster(_ mark: InstanceID) -> Bool {
        guard let updated = PageRules.rotate(cluster: mark, on: state.base.page) else { return false }
        mutate("rotate cluster", flush: true) { $0.base.page = updated }
        return true
    }

    func erase(_ mark: InstanceID) {
        mutate("erase mark") { state in
            state.base.page.links = state.base.page.links.filter { !$0.involves(mark) }
            state.base.page = PageRules.remove(mark, from: state.base.page)
        }
    }

    func clearPage() {
        mutate("clear the page") { $0.base.page = Page(width: $0.base.page.width, height: $0.base.page.height) }
    }

    /// What the Writing Desk shows before committing.
    /// Reads the seed the next bind *will* use, without consuming it — so what the preview
    /// promises is what the world delivers, sites included.
    var bookProjection: BookProjection {
        BookProjection.project(page: state.base.page,
                               seed: state.worlds.seeds.peekNextSeed(),
                               analysisTier: state.reality.analysisTier,
                               measuring: state.reality.calibratedSubjects,
                               precision: state.reality.observations.mapValues(\.bestPrecision),
                               tuning: DebugTuningProfile.active,
                               revealRolled: state.reality.visitedWorldSeeds
                                   .contains(state.worlds.seeds.peekNextSeed()))
    }

    /// The price is exact before committing — a slot left to chance costs a flat rate whatever
    /// rolls into it — so there's no worst case to hold back for.
    var canBindAndDepart: Bool {
        bindAvailability(bornAnchored: false).isReady
    }

    var bornAnchoredPremium: Int {
        Self.bornAnchoredPremium(forBookCost: bookProjection.cost)
    }

    nonisolated static func bornAnchoredPremium(forBookCost cost: Int) -> Int {
        max(Tuning.Economy.bornAnchoredBasePremium,
            cost * Tuning.Economy.bornAnchoredBookCostMultiplier)
    }

    func canBindAndDepart(bornAnchored: Bool) -> Bool {
        bindAvailability(bornAnchored: bornAnchored).isReady
    }

    func bindAvailability(bornAnchored: Bool) -> BindAvailability {
        let total = bookProjection.cost + (bornAnchored ? bornAnchoredPremium : 0)
        if state.worlds.activeRun != nil { return .activeExpedition }
        if let refusal = fieldKitDepartureRefusal { return .fieldKit(refusal) }
        if bornAnchored && !state.base.station(Stations.anchorage).isUnlocked {
            return .anchorageLocked
        }
        if state.base.essence < total {
            return .insufficientEssence(available: state.base.essence, required: total)
        }
        return .ready(totalCost: total)
    }

    /// Reconciles the one-time starter folio for saves created before World Pages existed.
    /// A progressed campaign is marked reconciled without receiving retroactive physical stock.
    func reconcileStarterWorldPageBundle() {
        guard !state.base.starterWorldPageBundleFulfilled,
              state.worlds.activeRun == nil else { return }
        mutate("reconcile starter World Pages", flush: true) { state in
            guard !state.base.starterWorldPageBundleFulfilled else { return }
            let mayAdopt = state.worlds.runIndex == 0
                && state.worlds.activeRun == nil
                && state.reality.library.visitedWorlds.isEmpty
                && state.reality.visitedWorldSeeds.isEmpty
                && state.reality.library.foundPages.isEmpty
                && state.reality.library.foundWritings.isEmpty
                && state.reality.library.foundTravellers.isEmpty
                && state.reality.lifetime.runsStarted == 0
                && state.base.collectedWorldPages.isEmpty
            if mayAdopt { state.base.collectedWorldPages = WorldPageCatalog.starterInstances }
            state.base.starterWorldPageBundleFulfilled = true
        }
    }

    /// Returns the owned, exact instance only when its embedded authored snapshot still equals the
    /// canonical generated catalogue. Unknown, stale or tampered definitions fail closed.
    func collectedWorldPage(_ instanceID: InstanceID) -> WorldPageInstance? {
        Self.resolvedWorldPage(instanceID, in: state)
    }

    nonisolated private static func resolvedWorldPage(
        _ instanceID: InstanceID, in state: GameState
    ) -> WorldPageInstance? {
        let matches = state.base.collectedWorldPages.filter { $0.id == instanceID }
        guard matches.count == 1, let owned = matches.first,
              let canonical = WorldPageCatalog.definition(owned.definition.id),
              owned.definition == canonical else { return nil }
        return owned
    }

    func worldPageProjection(_ instanceID: InstanceID) -> BookProjection? {
        guard let instance = collectedWorldPage(instanceID) else { return nil }
        var projection = BookProjection.project(
            page: instance.definition.page, seed: instance.definition.seed,
            analysisTier: state.reality.analysisTier,
            measuring: state.reality.calibratedSubjects,
            precision: state.reality.observations.mapValues(\.bestPrecision),
            tuning: DebugTuningProfile.active,
            revealRolled: false)
        projection.essenceCost = instance.definition.worldPageCost...instance.definition.worldPageCost
        return projection
    }

    func bindAvailability(worldPageInstanceID: InstanceID, bornAnchored: Bool) -> BindAvailability {
        guard let instance = collectedWorldPage(worldPageInstanceID) else {
            return .unavailable("That collected page is no longer available.")
        }
        let premium = bornAnchored
            ? Self.bornAnchoredPremium(forBookCost: instance.definition.worldPageCost) : 0
        let total = instance.definition.worldPageCost + premium
        if state.worlds.activeRun != nil { return .activeExpedition }
        if let refusal = fieldKitDepartureRefusal { return .fieldKit(refusal) }
        if bornAnchored && !state.base.station(Stations.anchorage).isUnlocked {
            return .anchorageLocked
        }
        if state.base.essence < total {
            return .insufficientEssence(available: state.base.essence, required: total)
        }
        return .ready(totalCost: total)
    }

    @discardableResult
    func bindAndDepart(worldPageInstanceID: InstanceID, bornAnchored: Bool = false) -> Bool {
        bindAndDepart(worldPageInstanceID: worldPageInstanceID, bornAnchored: bornAnchored,
                      openColorResolver: { scope, sigil, seed in
            try WorldGrade2BindAdapter.openColor(scope: scope, selectedSigilID: sigil.id,
                                                 mapSeed: seed)
        })
    }

    /// Binds the current draft and departs into the world it describes.
    ///
    /// Flushed to disk before it returns: this is the commitment point where essence turns into a
    /// world, and it's the last thing that should ever be lost to a kill.
    @discardableResult
    func bindAndDepart(bornAnchored: Bool = false) -> Bool {
        bindAndDepart(bornAnchored: bornAnchored,
                      openColorResolver: { scope, sigil, seed in
            try WorldGrade2BindAdapter.openColor(scope: scope,
                                                 selectedSigilID: sigil.id,
                                                 mapSeed: seed)
        })
    }

    /// Injectable only so the atomic-failure contract can be proved without corrupting a real
    /// adapter or save. Production always uses the frozen resolver above.
    @discardableResult
    func bindAndDepart(
        bornAnchored: Bool = false,
        openColorResolver: WorldGrade2BindAdapter.OpenColorResolver
    ) -> Bool {
        bindAndDepart(worldPageInstanceID: nil, bornAnchored: bornAnchored,
                      openColorResolver: openColorResolver)
    }

    @discardableResult
    func bindAndDepart(
        worldPageInstanceID: InstanceID?, bornAnchored: Bool = false,
        openColorResolver: WorldGrade2BindAdapter.OpenColorResolver
    ) -> Bool {
        bindError = nil
        let selectedWorldPage = worldPageInstanceID.flatMap { collectedWorldPage($0) }
        if worldPageInstanceID != nil && selectedWorldPage == nil {
            bindError = "That collected page is no longer available."
            return false
        }
        let availability = worldPageInstanceID.map {
            bindAvailability(worldPageInstanceID: $0, bornAnchored: bornAnchored)
        } ?? bindAvailability(bornAnchored: bornAnchored)
        guard availability.isReady else {
            bindError = availability.refusalMessage
            return false
        }
        let pageCost = selectedWorldPage?.definition.worldPageCost ?? bookProjection.cost
        let anchorPremium = bornAnchored ? Self.bornAnchoredPremium(forBookCost: pageCost) : 0

        // Build the complete world and its immutable visual authority before the commitment
        // mutation. A bad future adapter/schema can therefore spend no Essence, consume no seed,
        // change no page/history fact and create no half-world.
        let reservedCampaignSeed = state.worlds.seeds.peekNextSeed()
        let generationSeed = selectedWorldPage?.definition.seed ?? reservedCampaignSeed
        let sourcePage = selectedWorldPage?.definition.page ?? state.base.page
        let book = selectedWorldPage.map(BookRules.resolveBook(worldPage:))
            ?? BookRules.resolveBook(page: sourcePage)
        let tuning = DebugTuningProfile.active
        let world = Worldgen.generate(book: book, seed: generationSeed, library: state.reality.library,
                                      tuning: tuning,
                                      isFreshFirstExpedition: state.worlds.runIndex == 0)
        let visualReceipt: WorldVisualReceipt
        do {
            visualReceipt = try WorldGrade2BindAdapter.makeReceipt(
                book: book, mapSeed: generationSeed, map: world.map, flora: world.flora,
                openColorResolver: openColorResolver)
        } catch {
#if DEBUG
            bindError = "This world could not be prepared. Your page and Essence were not changed. Visual receipt: \(error)"
#else
            bindError = "This world could not be prepared. Your page and Essence were not changed."
#endif
            return false
        }

        let didCommit = mutateIf("bind book & depart", flush: true) { state in
            guard state.worlds.activeRun == nil,
                  state.base.essence >= book.essencePaid + anchorPremium,
                  !bornAnchored || state.base.station(Stations.anchorage).isUnlocked else { return false }
            guard case .allowed(let fieldKit) = Self.fieldKitDepartureQuote(in: state) else { return false }
            var selectedIndex: Int?
            if let staged = selectedWorldPage {
                guard let current = Self.resolvedWorldPage(staged.id, in: state),
                      current == staged,
                      let index = state.base.collectedWorldPages.firstIndex(where: { $0.id == staged.id })
                else { return false }
                selectedIndex = index
            }
            guard state.worlds.seeds.peekNextSeed() == reservedCampaignSeed else { return false }
            // The actor is synchronous from preview through commit, so the peeked seed is exactly
            // the one consumed here. World generation and visual resolution use isolated streams.
            precondition(state.worlds.seeds.nextSeed() == reservedCampaignSeed,
                         "Bind seed changed inside one synchronous commitment")
            if let selectedIndex { state.base.collectedWorldPages.remove(at: selectedIndex) }
            state.reality.library.applyTravellerArrival(world.diagnostics.travellerArrival)
            // Entering unseals this world: from here on its rolled values may be described.
            state.reality.visitedWorldSeeds.insert(generationSeed)
            // **Whose signature this world matches — not who you have met.**
            //
            // Arriving used to mark them found, silently, in the save. So the forge appeared at
            // Aimee's base for a smith she had never laid eyes on (6 Aug): *"finding a traveller
            // should mean actually running across the person as an entity on a world you find them
            // in."* Quite right — a search loop whose payoff is a database write is not a search.
            //
            // They are *placed on the map* now, and finding them means walking up to them. What
            // arriving buys you is knowing they're here, which is what makes it worth looking.
            for traveller in world.travellers {
                state.reality.library.knownTravellers.insert(traveller)
            }
            // **Recorded, before anything is spent.** The page you wrote and the world it became,
            // kept so you can come back with better instruments and read your own failure (Aimee,
            // 6 Aug). Nothing here is explained now — that would break "explanation is earned".
            let historyRecord = LibraryRules.record(book: book, page: sourcePage, seed: generationSeed,
                                                    runIndex: state.worlds.runIndex + 1,
                                                    travellers: world.travellers,
                                                    worldVisualReceipt: visualReceipt)
            state.reality.library.record(world: historyRecord)
            TutorialRules.reconcileComparisonPair(in: &state)
            TutorialRules.pairNewWorld(historyRecord, in: &state)

            LibraryRules.advancePatience(after: world.pages, library: &state.reality.library)
            state.base.essence -= book.essencePaid
            state.base.essence -= anchorPremium
            state.worlds.runIndex += 1
            state.reality.lifetime.runsStarted += 1
            state.worlds.lastExit = nil

            state.base.inventory = fieldKit.remainingInventory
            var packedItems = fieldKit.packed
            let progressAtStart = state.base.partyMembers.map { member in
                let character = state.base.character(member)
                let name = member.rosterIndex.flatMap { index in
                    state.base.roster.indices.contains(index) ? state.base.roster[index].name : nil
                } ?? "You"
                return RunProgressStart(member: member, name: name,
                                        experience: character.experience, level: character.level)
            }
            for index in packedItems.stacks.indices {
                packedItems.stacks[index].protectedReturnCount = packedItems.stacks[index].count
            }
            let healthCaps = CombatRules.expeditionHealthCaps(in: state, tuning: tuning)
            let binderMaximum = healthCaps.first { $0.member == .binder }?.maximum
                ?? Tuning.Encounter.binderMaxHP
            let companionMaximums = healthCaps.reduce(into: [Int: Int]()) { result, entry in
                if case .member(let index) = entry.member { result[index] = entry.maximum }
            }
            let departingRun = WorldRun(
                runIndex: state.worlds.runIndex,
                book: book,
                mapSeed: generationSeed,
                rng: SeededRNG(seed: generationSeed).derived(0xA11CE),
                map: world.map,
                playerPosition: world.start,
                enemies: world.enemies,
                sites: world.sites,
                travellersHere: world.travellers,
                // The species this world settled on, kept with the run so the same animals are
                // still here after a force-quit — and so anchoring one keeps them forever.
                cast: world.cast,
                // …and what grows here, for the same reasons. Every growth tile points into this,
                // so losing it would leave the world overgrown with nothing in particular.
                flora: world.flora,
                foundWritings: world.writings,
                // **Everybody comes home mended.** Health is run-scoped, so opening a run at full
                // is what "the party heals on returning home" means (Aimee, 6 Aug) — and it reads
                // the Fortitude they've earned rather than a constant.
                binderHP: binderMaximum,
                companionHP: companionMaximums,
                healthCaps: healthCaps,
                // The satchel is its own, smaller capacity — separate from home storage, and
                // separately upgradeable (decisions-log session 2).
                satchelItems: packedItems,
                carriedInstruments: (state.base.hasConfiguredInstrumentLoadout
                                     ? state.base.instrumentLoadout
                                     : state.reality.instruments)
                    .intersection(state.reality.instruments),
                carriedInstrumentPrecisions: Dictionary(uniqueKeysWithValues:
                    ((state.base.hasConfiguredInstrumentLoadout
                        ? state.base.instrumentLoadout
                        : state.reality.instruments)
                     .intersection(state.reality.instruments))
                    .map { ($0, state.reality.instrumentPrecision(for: $0)) }),
                partyProgressAtStart: progressAtStart,
                carriedItemCountsAtStart: packedItems.stacks.reduce(into: [:]) {
                    $0[$1.catalogID, default: 0] += $1.count
                },
                foundPagesAtStart: Set(state.reality.library.foundPages),
                foundWritingsAtStart: Set(state.reality.library.foundWritings.map(\.id)),
                foundTravellersAtStart: state.reality.library.foundTravellers,
                generationDiagnostics: world.diagnostics,
                tuning: tuning,
                worldVisualReceipt: visualReceipt
            )
            state.worlds.activeRun = departingRun
            state.tutorial.complete(.writingPageRequest, fact: "first_bind")
            state.tutorial.complete(.writingPreview, fact: "world_pane_opened")
            state.tutorial.complete(.writingBind, fact: "first_run_created")
            if bornAnchored {
                state.worlds.anchoredRealms.append(
                    AnchoredRealm(runIndex: departingRun.runIndex,
                                  name: "Realm \(departingRun.runIndex)",
                                  route: .bornAnchored,
                                  sustainObligation: Self.sustainObligation(
                                    forExistingRealmCount: state.worlds.anchoredRealms.count),
                                  world: departingRun.anchoredSnapshot)
                )
            }
            return true
        }
        if !didCommit {
            if case .refused(let reason) = Self.fieldKitDepartureQuote(in: state) {
                bindError = reason
            } else if worldPageInstanceID != nil {
                bindError = "That collected page changed before departure. Nothing was spent."
            } else {
                bindError = "The binding changed before departure. Nothing was spent."
            }
        }
        return didCommit
    }

    // MARK: - Essence Spring

    /// Essence trickled on each return from a run. Tier 1 of the Spring is built into the base, so
    /// an un-upgraded (tier 0) Spring still trickles.
    var essenceSpringYield: Int {
        GameStore.essenceSpringYield(for: state)
    }

    nonisolated static func essenceSpringYield(for state: GameState) -> Int {
        let station = state.base.station(Stations.essenceSpring)
        guard station.isUnlocked else { return 0 }
        let index = min(station.tier, Tuning.Economy.essenceSpringPerReturn.count - 1)
        return Tuning.Economy.essenceSpringPerReturn[index]
    }

    /// Credited when the player comes home — an in-session event, never a wall-clock trickle
    /// (pillar 2). Nothing accrues while the app is closed, by construction: there is no code
    /// path that can add essence except a player action.
    nonisolated static func creditEssenceSpring(_ state: inout GameState) {
        state.base.essence += essenceSpringYield(for: state)
    }
}
