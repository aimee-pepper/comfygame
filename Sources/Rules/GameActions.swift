import Foundation

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
        guard let updated = PageRules.connect(a, b, on: state.base.page) else { return false }
        mutate("connect", flush: true) { $0.base.page = updated }
        return true
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
                               revealRolled: state.reality.visitedWorldSeeds
                                   .contains(state.worlds.seeds.peekNextSeed()))
    }

    /// The price is exact before committing — a slot left to chance costs a flat rate whatever
    /// rolls into it — so there's no worst case to hold back for.
    var canBindAndDepart: Bool {
        state.worlds.activeRun == nil && state.base.essence >= bookProjection.cost
    }

    /// Binds the current draft and departs into the world it describes.
    ///
    /// Flushed to disk before it returns: this is the commitment point where essence turns into a
    /// world, and it's the last thing that should ever be lost to a kill.
    @discardableResult
    func bindAndDepart() -> Bool {
        guard canBindAndDepart else { return false }

        mutate("bind book & depart", flush: true) { state in
            let seed = state.worlds.seeds.nextSeed()
            let book = BookRules.resolveBook(page: state.base.page)

            // Generated here, once, and saved with the run. Worldgen draws from streams derived
            // from the seed, never from the run's live RNG, so in-run rolls resume cleanly.
            let world = Worldgen.generate(book: book, seed: seed, library: state.reality.library)

            // Entering unseals this world: from here on its rolled values may be described.
            state.reality.visitedWorldSeeds.insert(seed)
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
            state.reality.library.record(
                world: LibraryRules.record(book: book, page: state.base.page, seed: seed,
                                           runIndex: state.worlds.runIndex + 1,
                                           travellers: world.travellers))

            // Pages that didn't surface here have waited one world longer.
            for page in ContentCatalog.shared.diaryPages
            where !state.reality.library.hasFound(page.id) && !world.pages.contains(page.id) {
                state.reality.library.pagesWaiting[page.id, default: 0] += 1
            }
            state.base.essence -= book.essencePaid
            state.worlds.runIndex += 1
            state.reality.lifetime.runsStarted += 1
            state.worlds.activeRun = WorldRun(
                runIndex: state.worlds.runIndex,
                book: book,
                mapSeed: seed,
                rng: SeededRNG(seed: seed).derived(0xA11CE),
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
                // **Everybody comes home mended.** Health is run-scoped, so opening a run at full
                // is what "the party heals on returning home" means (Aimee, 6 Aug) — and it reads
                // the Fortitude they've earned rather than a constant.
                binderHP: CombatRules.maximumHealth(of: .binder, in: state),
                companionHP: state.base.activeParty.reduce(into: [Int: Int]()) { hp, index in
                    hp[index] = CombatRules.maximumHealth(of: .companion(index), in: state)
                },
                // The satchel is its own, smaller capacity — separate from home storage, and
                // separately upgradeable (decisions-log session 2).
                satchelItems: Inventory(slots: state.base.satchelCapacity)
            )
        }
        return true
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
