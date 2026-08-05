import Foundation

/// Real player actions — the ones the shipping UI calls. Anything still faked lives in
/// `Sources/Debug/` and says so.
///
/// Every one of these goes through `mutate`, so every one of them is saved.
extension GameStore {

    // MARK: - Writing Desk

    /// Places a symbol in a slot, or clears it (`nil`) to leave that slot to chance.
    func setSymbol(_ id: SymbolID?, in slot: SymbolSlot) {
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

    /// The player must be able to cover the worst case of an under-specified book, since which
    /// symbols get random-filled isn't known until the bind happens.
    var canBindAndDepart: Bool {
        state.worlds.activeRun == nil && state.base.essence >= bookProjection.maximumCost
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

            state.base.essence -= book.essencePaid
            state.worlds.runIndex += 1
            state.reality.lifetime.runsStarted += 1
            state.worlds.activeRun = WorldRun(
                runIndex: state.worlds.runIndex,
                book: book,
                mapSeed: seed,
                rng: SeededRNG(seed: seed).derived(0xA11CE),
                // The satchel carries what the Storehouse can hold. Whether that's the right rule
                // is Q6 in docs/questions-for-design.md.
                satchelItems: Inventory(slots: state.base.inventory.slots)
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
