import Foundation

/// Real player actions — the ones the shipping UI calls. Anything still faked lives in
/// `Sources/Debug/` and says so.
///
/// Every one of these goes through `mutate`, so every one of them is saved.
extension GameStore {

    // MARK: - Writing Desk

    /// Places a symbol in a slot, or clears it (`nil`).
    ///
    /// **The slot taxonomy is no longer the composition surface** — the page is. This remains so
    /// that saves and tests written against slots keep working, and it writes through to the page
    /// so they keep *meaning* what they meant: a test that says "give me a dim-sky world" still
    /// gets one. Where the mark lands is arbitrary, which is fine, because position is never
    /// meaning.
    func setSymbol(_ id: SymbolID?, in slot: SlotID) {
        let previous = state.base.bookDraft[slot]
        mutate("compose: \(slot.rawValue) = \(id?.rawValue ?? "random")") { state in
            state.base.bookDraft[slot] = id
            if let previous, let mark = state.base.page.runes.first(where: { $0.symbolID == previous }) {
                state.base.page = PageRules.remove(mark.id, from: state.base.page)
            }
        }
        if let id { write(id) }
    }

    // MARK: - The page

    /// Whether a symbol can still be fitted onto the page in the player's best hand.
    func canWrite(_ id: SymbolID) -> Bool {
        guard let symbol = ContentCatalog.shared.symbol(id) else { return false }
        return PageRules.placeAnywhere(symbol, hand: state.base.bestHand, on: state.base.page) != nil
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
        guard let symbol = ContentCatalog.shared.symbol(id),
              let updated = PageRules.place(symbol, hand: state.base.bestHand, at: cell, on: state.base.page)
        else { return false }
        mutate("write \(id.rawValue)") { $0.base.page = updated }
        return true
    }

    /// Drop a mark into the first place it fits. For the palette's quick-add.
    @discardableResult
    func write(_ id: SymbolID) -> Bool {
        guard let symbol = ContentCatalog.shared.symbol(id),
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

    func erase(_ mark: InstanceID) {
        mutate("erase mark") { $0.base.page = PageRules.remove(mark, from: $0.base.page) }
    }

    func clearPage() {
        mutate("clear the page") { $0.base.page = Page(width: $0.base.page.width, height: $0.base.page.height) }
    }

    func clearBookDraft() {
        mutate("clear book draft") { $0.base.bookDraft = BookDraft() }
    }

    /// What the Writing Desk shows before committing.
    /// Reads the seed the next bind *will* use, without consuming it — so what the preview
    /// promises is what the world delivers, sites included.
    var bookProjection: BookProjection {
        BookProjection.project(page: state.base.page,
                               seed: state.worlds.seeds.peekNextSeed(),
                               analysisTier: state.reality.analysisTier)
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
            let world = Worldgen.generate(book: book, seed: seed)

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
