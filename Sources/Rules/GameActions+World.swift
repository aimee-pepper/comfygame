import Foundation

/// Player actions inside a world. Each one is a turn, and each one is saved.
extension GameStore {

    var activeRun: WorldRun? { state.worlds.activeRun }

    /// The most recent turn's events, for the World screen to narrate. Not persisted — a resumed
    /// run shows the state, not a replay of how it got there.
    private static let eventLimit = 4

    // MARK: - Queries the UI asks

    var tileUnderPlayer: Tile? {
        guard let run = activeRun else { return nil }
        return run.map[run.playerPosition]
    }

    var harvestableHere: ResourceNode? {
        guard case .node(let node) = tileUnderPlayer?.content, !node.isExhausted else { return nil }
        return node
    }

    var canPortalHere: Bool { tileUnderPlayer?.content.isPortal ?? false }

    /// The site under the player, if there's one still worth searching.
    var searchableHere: PlacedSite? {
        guard let run = activeRun,
              case .site(let instance) = tileUnderPlayer?.content,
              let site = run.sites.first(where: { $0.id == instance }),
              !site.isLooted
        else { return nil }
        return site
    }

    /// Loot that wouldn't fit and is waiting on a decision.
    var pendingLoot: [ItemStack] { activeRun?.offeredItems ?? [] }

    /// Take the offered item, dropping something you're carrying to make room. The satchel is
    /// smaller than home storage precisely so this choice exists; making it for the player would
    /// be the thing that empties the design out.
    func takeOffered(_ offered: ItemStack, dropping carried: ItemStack) {
        mutate("swap loot", flush: true) { state in
            guard var run = state.worlds.activeRun else { return }
            run.satchelItems.remove(carried.id)
            _ = run.satchelItems.add(offered)
            run.offeredItems.removeAll { $0.id == offered.id }
            state.worlds.activeRun = run
        }
    }

    func leaveOffered(_ offered: ItemStack) {
        mutate("leave loot behind", flush: true) { state in
            state.worlds.activeRun?.offeredItems.removeAll { $0.id == offered.id }
        }
    }
    var isOnLockedCache: Bool { tileUnderPlayer?.content == .lockedCache }

    /// Whether the player is carrying anything a cache would take. Keys are found in *other*
    /// worlds, so this is nearly always false until milestone 5 delivers the identify flow.
    var carriedCacheKey: ItemStack? {
        state.base.inventory.stacks.first {
            $0.identified && ContentCatalog.shared.item($0.catalogID)?.kind == .key
        }
    }

    // MARK: - Turns

    /// A single step onto an adjacent tile.
    func step(to point: GridPoint) {
        guard activeRun?.activeEncounter == nil else { return }
        var events: [WorldRules.Event] = []
        mutate("step") { state in
            events = WorldRules.step(to: point, in: &state)
        }
        finishTurn(events)
    }

    /// Tap-to-path: walk toward a tile turn by turn, stopping the moment anything happens worth
    /// stopping for — an enemy waking, a hazard, a threshold, a fight (SPD-style, locked decision).
    func travel(to destination: GridPoint) {
        guard let run = activeRun, run.activeEncounter == nil else { return }
        guard destination != run.playerPosition else { return }

        let route = WorldRules.path(from: run.playerPosition, to: destination, in: run.map)
        guard !route.isEmpty else {
            recentEvents = [.blocked("No way through.")]
            return
        }

        var events: [WorldRules.Event] = []
        mutate("travel") { state in
            for next in route {
                let stepEvents = WorldRules.step(to: next, in: &state)
                events.append(contentsOf: stepEvents)
                if stepEvents.contains(where: \.interruptsTravel) { break }
                if state.worlds.activeRun == nil { break }
            }
        }
        finishTurn(events)
    }

    /// One pull from the node underfoot.
    func harvest() {
        guard harvestableHere != nil, activeRun?.activeEncounter == nil else { return }
        var events: [WorldRules.Event] = []
        mutate("harvest", flush: true) { state in
            events = WorldRules.harvest(in: &state)
        }
        finishTurn(events)
    }

    /// One turn of searching the site underfoot. Contents land on the turn it completes.
    func searchSite() {
        guard searchableHere != nil, activeRun?.activeEncounter == nil else { return }
        var events: [WorldRules.Event] = []
        mutate("search site", flush: true) { state in
            events = WorldRules.searchSite(in: &state)
        }
        finishTurn(events)
    }

    /// Leave through a portal, keeping the whole haul. The good ending.
    func portalHome() {
        guard canPortalHere, activeRun?.activeEncounter == nil else { return }
        mutate("portal home", flush: true) { state in
            guard let run = state.worlds.activeRun else { return }
            GameStore.bankHaul(of: run, into: &state, fraction: 1.0)
            state.reality.lifetime.runsBankedViaPortal += 1
            GameStore.creditEssenceSpring(&state)
            state.worlds.activeRun = nil
        }
        recentEvents = []
        ensureDepartureIsPossible()
    }

    /// Caught by the collapse (or carried out unconscious): keep a fraction, chosen at random.
    func endRunWithPartialHaul(reason: String) {
        guard activeRun != nil else { return }
        mutate("run ended: \(reason)", flush: true) { state in
            guard var run = state.worlds.activeRun else { return }
            let fraction = Tuning.World.collapseHaulKeptFraction
            GameStore.bankHaul(of: run, into: &state, fraction: fraction, rng: &run.rng)
            state.reality.lifetime.runsLostToCollapse += 1
            GameStore.creditEssenceSpring(&state)
            state.worlds.activeRun = nil
        }
        recentEvents = []
        ensureDepartureIsPossible()
    }

    // MARK: - Turn bookkeeping

    /// Applies the consequences a turn's events imply, and hands the rest to the UI.
    private func finishTurn(_ events: [WorldRules.Event]) {
        recentEvents = Array(events.suffix(GameStore.eventLimit))

        // **Only the floor going out from under you ends a run.** The meter emptying is the world
        // beginning to come apart — you can keep working, and reaching a portal before the
        // crumbling reaches you is the decision the collapse exists to create.
        if events.contains(.floorGaveWay) {
            endRunWithPartialHaul(reason: "the ground went")
        } else if let ejection = events.first(where: { if case .ejected = $0 { true } else { false } }),
                  case .ejected(let reason) = ejection {
            endRunWithPartialHaul(reason: reason)
        }
    }

    /// Banking respects the layer split: motes are Reality, everything else is Base.
    ///
    /// With a fraction below 1 the item loss is rolled off the run's own RNG, so a kill during the
    /// collapse resumes to the same outcome rather than re-rolling in the player's favour.
    nonisolated static func bankHaul(of run: WorldRun,
                                     into state: inout GameState,
                                     fraction: Double,
                                     rng: inout SeededRNG) {
        for (id, amount) in run.satchel.scaled(by: fraction).nonZero {
            if ContentCatalog.shared.resource(id)?.isRealityCurrency == true {
                state.reality.motes += amount
            } else {
                state.base.resources.add(amount, of: id)
            }
        }
        let kept = fraction >= 1
            ? run.satchelItems
            : run.satchelItems.randomlyKeeping(fraction: fraction, rng: &rng)
        for stack in kept.stacks where !state.base.inventory.add(stack) {
            // Full Storehouse. It waits rather than evaporating — see `BaseState.spillover`.
            state.base.spillover.append(stack)
        }
    }

    nonisolated static func bankHaul(of run: WorldRun, into state: inout GameState, fraction: Double) {
        var unused = run.rng
        bankHaul(of: run, into: &state, fraction: fraction, rng: &unused)
    }
}
