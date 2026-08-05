import Foundation

/// Real player actions — the ones the shipping UI calls. Anything still faked lives in
/// `Sources/Debug/` and says so.
///
/// Every one of these goes through `mutate`, so every one of them is saved.
extension GameStore {

    // MARK: - Writing Desk

    /// Places a symbol in a slot, or clears it (`nil`) to leave that slot to chance.
    func setSymbol(_ id: SymbolID?, in slot: SlotID) {
        // The draft lives in the save, so a force-quit half-way through composing a book resumes
        // with the same half-composed book.
        mutate("compose: \(slot.rawValue) = \(id?.rawValue ?? "random")") { state in
            state.base.bookDraft[slot] = id
        }
    }

    func clearBookDraft() {
        mutate("clear book draft") { $0.base.bookDraft = BookDraft() }
    }

    /// What the Writing Desk shows before committing.
    var bookProjection: BookProjection {
        BookProjection.project(draft: state.base.bookDraft, ownedSymbols: state.base.ownedSymbols)
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
            let book = BookRules.resolveBook(
                draft: state.base.bookDraft,
                ownedSymbols: state.base.ownedSymbols,
                seed: seed
            )

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
