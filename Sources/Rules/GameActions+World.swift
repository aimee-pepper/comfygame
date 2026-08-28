import Foundation

enum CurrentStateCommitResult: Equatable, Sendable {
    case committed
    case refused(String)
}

struct LootSwapQuote: Equatable, Sendable {
    let offered: ItemStack
    let carried: ItemStack
}

enum LootSwapEvaluation: Equatable, Sendable {
    case allowed(LootSwapQuote)
    case refused(String)
}

struct FieldKitShortage: Equatable, Sendable {
    let itemID: ItemID
    let wanted: Int
    let available: Int
}

struct FieldKitDeparturePlan: Equatable, Sendable {
    let packed: Inventory
    let remainingInventory: Inventory
    let shortages: [FieldKitShortage]
}

enum FieldKitDepartureEvaluation: Equatable, Sendable {
    case allowed(FieldKitDeparturePlan)
    case refused(String)
}

/// Player actions inside a world. Each one is a turn, and each one is saved.
extension GameStore {
    static func legacyFieldKitSuggestion(in state: GameState) -> [FieldKitPreparationEntry] {
        let capacity = state.base.satchelCapacity
        let available: (ItemID) -> Int = { itemID in
            state.base.inventory.stacks.filter { $0.catalogID == itemID && $0.identified }
                .reduce(0) { $0 + $1.count }
        }
        var result: [FieldKitPreparationEntry] = []
        func append(_ itemID: ItemID, count: Int) {
            guard count > 0, result.count < capacity else { return }
            result.append(.init(itemID: itemID, desiredCount: count, order: result.count))
        }
        let salve: ItemID = "salve_lesser"
        append(salve, count: min(2, available(salve)))
        let eligible = ContentCatalog.shared.items.filter {
            $0.kind == .consumable && available($0.id) > 0
        }.sorted { $0.id.rawValue < $1.id.rawValue }
        if let cure = eligible.first(where: {
            [.clearPoison, .clearElemental, .clearAnyStatus].contains($0.consumable?.effect)
        }) {
            append(cure.id, count: 1)
        }
        if let escape = eligible.first(where: {
            [.restoreStability, .returnHome].contains($0.consumable?.effect)
        }) {
            append(escape.id, count: 1)
        } else if available(Items.anchorFrame) > 0 {
            append(Items.anchorFrame, count: 1)
        }
        return result
    }

    static func isFieldKitEligible(_ itemID: ItemID) -> Bool {
        itemID == Items.anchorFrame || ContentCatalog.shared.item(itemID)?.kind == .consumable
    }

    static func canonicalFieldKitEntries(_ entries: [FieldKitPreparationEntry])
        -> [FieldKitPreparationEntry] {
        var merged: [ItemID: FieldKitPreparationEntry] = [:]
        for entry in entries where isFieldKitEligible(entry.itemID) {
            let candidate = FieldKitPreparationEntry(itemID: entry.itemID,
                                                      desiredCount: max(0, entry.desiredCount),
                                                      order: entry.order)
            if let current = merged[entry.itemID] {
                merged[entry.itemID] = .init(itemID: entry.itemID,
                                             desiredCount: max(current.desiredCount,
                                                               candidate.desiredCount),
                                             order: min(current.order, candidate.order))
            } else {
                merged[entry.itemID] = candidate
            }
        }
        return merged.values.sorted {
            $0.order != $1.order ? $0.order < $1.order : $0.itemID.rawValue < $1.itemID.rawValue
        }
    }

    var fieldKitDepartureRefusal: String? {
        if case .refused(let reason) = Self.fieldKitDepartureQuote(in: state) { return reason }
        return nil
    }

    static func fieldKitDepartureQuote(in state: GameState) -> FieldKitDepartureEvaluation {
        if state.base.preparationLoadoutNeedsReview || state.base.preparationLoadout == nil {
            return .refused("Review and confirm the suggested Field Kit before departure.")
        }
        let capacity = state.base.satchelCapacity
        let entries = canonicalFieldKitEntries(state.base.preparationLoadout ?? [])
            .filter { $0.desiredCount > 0 }
        if entries.count > capacity {
            return .refused("Resolve \(entries.count - capacity) excess Field Kit selections.")
        }
        var source = state.base.inventory
        var packed = Inventory(slots: capacity)
        var shortages: [FieldKitShortage] = []
        for entry in entries {
            var remaining = entry.desiredCount
            while remaining > 0,
                  let selectedID = source.stacks.filter({
                      $0.catalogID == entry.itemID && $0.identified
                          && Self.isFieldKitEligible($0.catalogID)
                  }).map(\.id).min(by: { $0.rawValue < $1.rawValue }),
                  let index = source.stacks.firstIndex(where: { $0.id == selectedID }) {
                let amount = min(remaining, source.stacks[index].count)
                var candidateSource = source
                guard let selected = candidateSource.stacks[index].removing(amount) else {
                    return .refused("The Field Kit stock changed. Review it and try again.")
                }
                if candidateSource.stacks[index].isEmpty { candidateSource.stacks.remove(at: index) }
                var candidatePacked = packed
                guard candidatePacked.add(selected) else {
                    return .refused("The selected supplies cannot share the available Field Kit bins.")
                }
                source = candidateSource
                packed = candidatePacked
                remaining -= amount
            }
            if remaining > 0 {
                shortages.append(.init(itemID: entry.itemID, wanted: entry.desiredCount,
                                       available: entry.desiredCount - remaining))
            }
        }
        return .allowed(.init(packed: packed, remainingInventory: source, shortages: shortages))
    }

    /// Re-enter a permanent realm without regenerating it. Layout, depleted sites and named life
    /// come from the saved snapshot; health, carried supplies and recap baselines belong to the
    /// new expedition and are rebuilt at the threshold.
    func revisitAnchoredRealm(_ id: Int) -> Bool {
        guard fieldKitDepartureRefusal == nil,
              state.worlds.activeRun == nil,
              let realm = state.worlds.anchoredRealms.first(where: { $0.id == id }),
              !realm.isDormant,
              realm.world.generationDiagnostics.playableEntry?.isAccepted != false,
              WorldRules.canReachAPortal(from: realm.world.playerPosition,
                                         in: realm.world.map) else { return false }

        var didCommit = false
        mutate("revisit anchored realm", flush: true, scope: .expedition) { state in
            guard let realm = state.worlds.anchoredRealms.first(where: { $0.id == id }),
                  !realm.isDormant,
                  realm.world.generationDiagnostics.playableEntry?.isAccepted != false,
                  WorldRules.canReachAPortal(from: realm.world.playerPosition,
                                             in: realm.world.map),
                  case .allowed(let fieldKit) = Self.fieldKitDepartureQuote(in: state) else { return }
            var run = realm.world
            run.activeEncounter = nil
            run.animalsAttackedThisExpedition = []
            run.offeredItems = []
            let healthCaps = CombatRules.expeditionHealthCaps(in: state, tuning: DebugTuningProfile.active)
            run.healthCaps = healthCaps
            run.binderHP = healthCaps.first { $0.member == .binder }?.maximum
                ?? Tuning.Encounter.binderMaxHP
            run.companionHP = healthCaps.reduce(into: [:]) { hp, entry in
                if case .member(let id) = entry.member { hp[id] = entry.maximum }
            }

            state.base.inventory = fieldKit.remainingInventory
            var packedItems = fieldKit.packed
            for index in packedItems.stacks.indices {
                packedItems.stacks[index].protectedReturnCount = packedItems.stacks[index].count
            }
            run.satchelItems = packedItems
            run.carriedItemCountsAtStart = packedItems.stacks.reduce(into: [:]) {
                $0[$1.catalogID, default: 0] += $1.count
            }
            run.carriedInstruments = (state.base.hasConfiguredInstrumentLoadout
                                      ? state.base.instrumentLoadout
                                      : state.reality.instruments)
                .intersection(state.reality.instruments)
            run.carriedInstrumentPrecisions = Dictionary(uniqueKeysWithValues:
                run.carriedInstruments.map { ($0, state.reality.instrumentPrecision(for: $0)) })
            run.partyProgressAtStart = state.base.partyMembers.map { member in
                let character = state.base.character(member)
                let name = member.persistentID.flatMap { id in
                    state.base.rosterIndex(for: id).map { state.base.roster[$0].name }
                } ?? "You"
                return RunProgressStart(member: member, name: name,
                                        experience: character.experience, level: character.level)
            }
            run.foundPagesAtStart = Set(state.reality.library.foundPages)
            run.foundWritingsAtStart = Set(state.reality.library.foundWritings.map(\.id))
            run.foundTravellersAtStart = state.reality.library.foundTravellers
            run.seamwardExpedition = EquipmentInscriptionRules.expeditionReceipt(
                from: state.base, activatedOnTurn: run.turnsTaken)
            run.anatomyButcheryReceipt = CreatureMaterialRewardRules.anatomyReceipt(in: state)
            state.reality.lifetime.runsStarted += 1
            state.worlds.activeRun = run
            didCommit = true
        }
        return didCommit
    }


    var selectedInstrumentLoadout: Set<PressureTargetID> {
        state.base.hasConfiguredInstrumentLoadout
            ? state.base.instrumentLoadout.intersection(state.reality.instruments)
            : state.reality.instruments
    }

    func setInstrument(_ target: PressureTargetID, carried: Bool) {
        guard state.reality.instruments.contains(target), activeRun == nil else { return }
        mutate("change field kit", flush: true, scope: .expedition) { state in
            if !state.base.hasConfiguredInstrumentLoadout {
                state.base.instrumentLoadout = state.reality.instruments
                state.base.hasConfiguredInstrumentLoadout = true
            }
            if carried { state.base.instrumentLoadout.insert(target) }
            else { state.base.instrumentLoadout.remove(target) }
        }
    }

    var activeRun: WorldRun? { state.worlds.activeRun }

    var offeredWorldPageHere: WorldPageInstance? {
        guard let run = activeRun else { return nil }
        let matches = run.offeredWorldPages.filter {
            $0.fieldProvenance?.position == run.playerPosition
        }
        guard matches.count == 1 else { return nil }
        return matches[0]
    }

    func offeredWorldPageQuote(_ instanceID: InstanceID) -> WildWorldPageFieldRules.Quote? {
        activeRun.flatMap { WildWorldPageFieldRules.quote(instanceID, in: $0) }
    }

    @discardableResult
    func inspectOfferedWorldPage(_ quote: WildWorldPageFieldRules.Quote)
        -> WildWorldPageFieldRules.Result {
        var result: WildWorldPageFieldRules.Result = .stale
        mutate("inspect loose World Page", flush: true, scope: .expedition) { state in
            guard var run = state.worlds.activeRun else { return }
            result = WildWorldPageFieldRules.inspect(quote, in: &run)
            guard case .inspected(let page) = result else { return }
            state.reality.recordEncounter(on: page.definition.page)
            state.worlds.activeRun = run
        }
        return result
    }

    @discardableResult
    func takeOfferedWorldPage(_ quote: WildWorldPageFieldRules.Quote)
        -> WildWorldPageFieldRules.Result {
        var result: WildWorldPageFieldRules.Result = .stale
        mutate("take loose World Page", flush: true, scope: .expedition) { state in
            guard var run = state.worlds.activeRun else { return }
            result = WildWorldPageFieldRules.take(quote, in: &run)
            guard case .taken = result else { return }
            state.worlds.activeRun = run
        }
        if case .taken = result { refreshWorldFieldContext() }
        return result
    }

    @discardableResult
    func swapOfferedWorldPage(_ quote: WildWorldPageFieldRules.Quote,
                              discarding occupant: WildWorldPageFieldRules.SlotOccupant)
        -> WildWorldPageFieldRules.Result {
        var result: WildWorldPageFieldRules.Result = .stale
        mutate("swap loose World Page", flush: true, scope: .expedition) { state in
            guard var run = state.worlds.activeRun else { return }
            result = WildWorldPageFieldRules.swap(quote, discarding: occupant, in: &run)
            guard case .swapped = result else { return }
            state.worlds.activeRun = run
        }
        if case .swapped = result { refreshWorldFieldContext() }
        return result
    }

    /// The most recent turn's events, for the World screen to narrate. Not persisted — a resumed
    /// run shows the state, not a replay of how it got there.
    private static let eventLimit = 4

    // MARK: - Queries the UI asks

    var tileUnderPlayer: Tile? {
        guard let run = activeRun else { return nil }
        return run.map[run.playerPosition]
    }

    var harvestableHere: ResourceNode? {
        guard let (_, node) = ResourceExtractionRules.selectedDisclosedNode(in: state),
              !node.isExhausted else { return nil }
        return node
    }

    var resourceExtractionEvaluation: ResourceExtractionRules.ResourceExtractionEvaluation {
        ResourceExtractionRules.evaluate(in: state)
    }

    var canExtractResource: Bool {
        if case .available = resourceExtractionEvaluation { return true }
        return false
    }

    var canPortalHere: Bool { tileUnderPlayer?.content.isPortal ?? false }
    var canLeaveMalformedOlderWorld: Bool {
        guard let run = activeRun, run.activeEncounter == nil,
              run.generationDiagnostics.playableEntry == nil,
              run.collapsedOnTurn == nil else { return false }
        return !WorldRules.canReachAPortal(from: run.playerPosition, in: run.map)
    }

    var naturalAnchorHere: PlacedSite? {
        guard let run = activeRun,
              case .site(let instance) = tileUnderPlayer?.content,
              let site = run.sites.first(where: { $0.id == instance }),
              site.definition?.providesNaturalAnchor == true else { return nil }
        return site
    }

    var canUseNaturalAnchor: Bool {
        naturalAnchorHere != nil
            && state.base.station(Stations.anchorage).isUnlocked
            && state.base.essenceCrystalCount >= naturalAnchorCost
            && !(activeRun.map { run in state.worlds.anchoredRealms.contains { $0.runIndex == run.runIndex } } ?? true)
    }

    var naturalAnchorCost: Int {
        guard let run = activeRun else { return Tuning.Anchoring.naturalAnchorMinimumCost }
        let premium = Self.bornAnchoredPremium(forBookCost: run.book.essencePaid)
        let quarterRoundedUp = (premium + Tuning.Anchoring.naturalAnchorPremiumDivisor - 1)
            / Tuning.Anchoring.naturalAnchorPremiumDivisor
        return max(Tuning.Anchoring.naturalAnchorMinimumCost, quarterRoundedUp)
    }

    func anchorAtNaturalPoint() -> Bool {
        guard canUseNaturalAnchor else { return false }
        let cost = naturalAnchorCost
        mutate("anchor realm at natural point", flush: true, scope: .expedition) { state in
            guard let run = state.worlds.activeRun,
                  !state.worlds.anchoredRealms.contains(where: { $0.runIndex == run.runIndex }),
                  state.base.essenceCrystalCount >= cost else { return }
            guard state.base.spendEssenceCrystals(cost) else { return }
            state.worlds.anchoredRealms.append(
                AnchoredRealm(runIndex: run.runIndex, name: "Realm \(run.runIndex)",
                              route: .naturalPoint,
                              sustainObligation: Self.sustainObligation(
                                forExistingRealmCount: state.worlds.anchoredRealms.count),
                              world: run.anchoredSnapshot)
            )
        }
        refreshWorldFieldContext()
        return true
    }

    /// The site under the player, if there's one still worth searching.
    var searchableHere: PlacedSite? {
        guard let run = activeRun,
              case .site(let instance) = tileUnderPlayer?.content,
              let site = run.sites.first(where: { $0.id == instance }),
              site.definition?.providesNaturalAnchor != true,
              !site.isLooted
        else { return nil }
        return site
    }

    /// Loot that wouldn't fit and is waiting on a decision.
    var pendingLoot: [ItemStack] { activeRun?.offeredItems ?? [] }

    /// Take the offered item, dropping something you're carrying to make room. The satchel is
    /// smaller than home storage precisely so this choice exists; making it for the player would
    /// be the thing that empties the design out.
    func lootSwapQuote(offered: ItemStack, dropping carried: ItemStack) -> LootSwapEvaluation {
        guard let run = state.worlds.activeRun else { return .refused("There is no active expedition.") }
        guard run.offeredItems.contains(offered) else {
            return .refused("That offered item is no longer waiting.")
        }
        guard run.satchelItems.stacks.contains(carried) else {
            return .refused("That carried stack has changed.")
        }
        var simulated = run.satchelItems
        simulated.remove(carried.id)
        guard simulated.add(offered) else {
            return .refused("The offered item no longer fits after that swap.")
        }
        return .allowed(LootSwapQuote(offered: offered, carried: carried))
    }

    @discardableResult
    func takeOffered(_ quote: LootSwapQuote) -> CurrentStateCommitResult {
        guard case .allowed(let fresh) = lootSwapQuote(offered: quote.offered,
                                                       dropping: quote.carried),
              fresh == quote else {
            return .refused("The satchel changed. Review the current items and try again.")
        }
        var committed = false
        mutate("swap loot", flush: true, scope: .expedition) { state in
            guard var run = state.worlds.activeRun,
                  run.offeredItems.contains(quote.offered),
                  run.satchelItems.stacks.contains(quote.carried) else { return }
            var updated = run.satchelItems
            updated.remove(quote.carried.id)
            guard updated.add(quote.offered) else { return }
            run.satchelItems = updated
            run.offeredItems.removeAll { $0.id == quote.offered.id }
            state.worlds.activeRun = run
            committed = true
        }
        return committed ? .committed
            : .refused("The satchel changed. Review the current items and try again.")
    }

    @available(*, deprecated, message: "Use a rules-owned LootSwapQuote and inspect the result")
    func takeOffered(_ offered: ItemStack, dropping carried: ItemStack) {
        guard case .allowed(let quote) = lootSwapQuote(offered: offered, dropping: carried) else { return }
        _ = takeOffered(quote)
    }

    func leaveOffered(_ offered: ItemStack) {
        mutate("leave loot behind", flush: true, scope: .expedition) { state in
            state.worlds.activeRun?.offeredItems.removeAll { $0.id == offered.id }
        }
    }
    var isOnLockedCache: Bool { tileUnderPlayer?.content == .lockedCache }

    /// Whether the player is carrying anything a cache would take. Keys are found in *other*
    /// worlds, so this is nearly always false until milestone 5 delivers the identify flow.
    var carriedCacheKey: ItemStack? {
        state.base.inventory.stacks.first {
            if $0.identified { return ContentCatalog.shared.item($0.catalogID)?.kind == .key }
            guard isOnLockedCache,
                  let revealed = EconomyRules.identification(of: $0) else { return false }
            return revealed.kind == .key
        }
    }

    var carriedCacheKeyIsUnidentified: Bool { carriedCacheKey?.identified == false }

    // MARK: - Turns

    /// A single step onto an adjacent tile.
    func step(to point: GridPoint) {
        guard activeRun?.activeEncounter == nil else { return }
        guard let run = activeRun else { return }
        let priorPosition = run.playerPosition
        guard let attempt = beginWorldFieldAttempt(.step) else { return }
        guard WorldRules.isAdjacent(run.playerPosition, point) else {
            let events: [WorldRules.Event] = [.blocked("That's not a step away.")]
            recentEvents = events
            submitWorldFieldEvents(events, for: attempt)
            return
        }
        if let refusal = WorldRules.blockedMovementRefusal(to: point, in: run.map) {
            let events: [WorldRules.Event] = [.blocked(refusal)]
            recentEvents = events
            submitWorldFieldEvents(events, for: attempt)
            return
        }
        var events: [WorldRules.Event] = []
        mutate("step", scope: .expedition) { state in
            events = WorldRules.step(to: point, in: &state)
        }
        finishTurn(events, attempt: attempt)
        presentTravellerSpeechAfterMovement(from: priorPosition, sourceAction: .step)
    }

    /// What's in the satchel that could be used right now, out in the world.
    var carriedConsumables: [ItemStack] {
        (activeRun?.satchelItems.stacks ?? []).filter {
            if !$0.identified { return !curioTryTargets($0).isEmpty }
            guard $0.identified,
                  let item = ContentCatalog.shared.item($0.catalogID),
                  item.kind == .consumable,
                  let effect = item.consumable?.effect else { return false }
            return [.heal, .restoreStability, .returnHome, .lightWorld, .farsight,
                    .identifyCurio, .lureCreature].contains(effect)
        }
    }

    func curioTryTargets(_ stack: ItemStack) -> [PartyMember] {
        guard !stack.identified, let run = activeRun,
              let revealed = EconomyRules.identification(of: stack),
              revealed.consumable?.effect == .heal else { return [] }
        return partyMembers.filter { member in
            let health = CombatRules.health(of: member.combatant, in: run)
            return health.current < health.max
        }
    }

    var carriedUnidentifiedCurios: [ItemStack] {
        (activeRun?.satchelItems.stacks ?? []).filter {
            !$0.identified && EconomyRules.identification(of: $0) != nil
        }
    }

    var carriedAnchorFrame: ItemStack? {
        activeRun?.satchelItems.stacks.first { $0.catalogID == Items.anchorFrame && $0.count > 0 }
    }

    var canPlaceAnchorFrame: Bool {
        guard let run = activeRun, run.activeEncounter == nil, carriedAnchorFrame != nil,
              state.base.station(Stations.anchorage).isUnlocked,
              !state.worlds.anchoredRealms.contains(where: { $0.runIndex == run.runIndex }),
              !run.map[run.playerPosition].isCrumbled,
              run.map[run.playerPosition].content == .empty else { return false }
        return true
    }

    func placeAnchorFrame() -> Bool {
        guard canPlaceAnchorFrame, let frame = carriedAnchorFrame else { return false }
        mutate("place Anchor Frame", flush: true, scope: .expedition) { state in
            guard var run = state.worlds.activeRun,
                  run.map[run.playerPosition].content == .empty,
                  !run.map[run.playerPosition].isCrumbled,
                  !state.worlds.anchoredRealms.contains(where: { $0.runIndex == run.runIndex }),
                  let index = run.satchelItems.stacks.firstIndex(where: { $0.id == frame.id })
            else { return }
            _ = run.satchelItems.stacks[index].removing(1)
            if run.satchelItems.stacks[index].isEmpty { run.satchelItems.stacks.remove(at: index) }
            state.worlds.anchoredRealms.append(
                AnchoredRealm(runIndex: run.runIndex, name: "Realm \(run.runIndex)",
                              route: .craftedFrame,
                              sustainObligation: Self.sustainObligation(
                                forExistingRealmCount: state.worlds.anchoredRealms.count),
                              world: run.anchoredSnapshot)
            )
            state.worlds.activeRun = run
        }
        refreshWorldFieldContext()
        return true
    }

    /// Solvent performs the Storehouse's identification transformation in the field. Both the
    /// solvent and one curio leave their bins atomically, and the revealed item goes back into the
    /// same satchel before the world charges its turn.
    func useSolventInWorld(_ solvent: ItemStack, on curio: ItemStack) {
        guard activeRun?.activeEncounter == nil,
              ContentCatalog.shared.item(solvent.catalogID)?.consumable?.effect == .identifyCurio,
              let run = activeRun,
              run.satchelItems.stacks.first(where: { $0.id == solvent.id }) == solvent,
              run.satchelItems.stacks.first(where: { $0.id == curio.id }) == curio,
              EconomyRules.identification(of: curio) != nil
        else { return }
        guard let attempt = beginWorldFieldAttempt(.useItem) else { return }
        var events: [WorldRules.Event] = []
        let committed = mutateIf("use solvent", flush: true, scope: .expedition) { state in
            var candidate = state
            guard var run = candidate.worlds.activeRun,
                  let revealed = EconomyRules.identification(of: curio),
                  run.satchelItems.stacks.contains(where: { $0.id == solvent.id }),
                  let curioIndex = run.satchelItems.stacks.firstIndex(where: { $0.id == curio.id }),
                  var transformed = run.satchelItems.stacks[curioIndex].removing(1)
            else { return false }

            transformed.catalogID = revealed.id
            transformed.identified = true
            if run.satchelItems.stacks[curioIndex].isEmpty {
                run.satchelItems.stacks.remove(at: curioIndex)
            }
            // Resolve the solvent again because removing the curio may shift its array index.
            guard let currentSolvent = run.satchelItems.stacks.firstIndex(where: { $0.id == solvent.id })
            else { return false }
            _ = run.satchelItems.stacks[currentSolvent].removing(1)
            if run.satchelItems.stacks[currentSolvent].isEmpty {
                run.satchelItems.stacks.remove(at: currentSolvent)
            }
            // Placement is part of the transaction. If both source bins remain live and the
            // revealed identity needs a third full-satchel bin, publish none of the staged work.
            guard run.satchelItems.add(transformed) else { return false }
            candidate.worlds.activeRun = run
            guard EconomyRules.recordCurioResolution(familyID: curio.catalogID, in: &candidate)
                    || candidate.reality.curioFamilyKnowledge[curio.catalogID] != nil else { return false }
            events = [.usedItem("Solvent", on: .binder)]
            events.append(contentsOf: WorldRules.advanceTurn(in: &candidate))
            state = candidate
            return true
        }
        if committed { finishTurn(events, attempt: attempt) }
    }

    /// Use something out here. Costs a turn, like everything else the world charges for.
    func useItemInWorld(_ stack: ItemStack, on member: PartyMember) {
        if !stack.identified {
            guard activeRun?.activeEncounter == nil,
                  activeRun?.satchelItems.stacks.first(where: { $0.id == stack.id }) == stack,
                  curioTryTargets(stack).contains(member),
                  let attempt = beginWorldFieldAttempt(.useItem) else { return }
            var events: [WorldRules.Event] = []
            mutate("try unidentified curio", flush: true, scope: .expedition) { state in
                var candidate = state
                guard var run = candidate.worlds.activeRun,
                      let index = run.satchelItems.stacks.firstIndex(where: { $0.id == stack.id }),
                      run.satchelItems.stacks[index] == stack,
                      let revealed = EconomyRules.identification(of: stack),
                      revealed.consumable?.effect == .heal else { return }
                run.satchelItems.stacks[index].catalogID = revealed.id
                run.satchelItems.stacks[index].identified = true
                candidate.worlds.activeRun = run
                let committed = WorldRules.useItem(stack.id, on: member, in: &candidate)
                guard !committed.contains(where: { if case .blocked = $0 { return true }; return false }),
                      EconomyRules.recordCurioResolution(familyID: stack.catalogID, in: &candidate)
                        || candidate.reality.curioFamilyKnowledge[stack.catalogID] != nil else { return }
                events = committed
                state = candidate
            }
            finishTurn(events, attempt: attempt)
            return
        }
        if ContentCatalog.shared.item(stack.catalogID)?.consumable?.effect == .seamlightGuidance {
            guard let attempt = beginWorldFieldAttempt(.useItem) else { return }
            var events: [WorldRules.Event] = []
            mutate("use seamlight", flush: true, scope: .expedition) { state in
                switch SeamlightRules.evaluate(sourceItemInstanceID: stack.id, in: state) {
                case .failure(let refusal):
                    events = [.blocked(SeamlightRules.playerCopy(for: refusal))]
                case .success(let quote):
                    switch SeamlightRules.commit(quote, in: &state) {
                    case .activated(_, let committed): events = committed
                    case .refused(let refusal):
                        events = [.blocked(SeamlightRules.playerCopy(for: refusal))]
                    }
                }
            }
            finishTurn(events, attempt: attempt)
            return
        }
        guard activeRun?.activeEncounter == nil else { return }
        if ContentCatalog.shared.item(stack.catalogID)?.consumable?.effect == .returnHome {
            returnHomeWithFullHaul(
                reason: "A Waystone carried you home before the world could close.",
                kind: .waystone,
                consuming: stack.id)
            return
        }
        guard let attempt = beginWorldFieldAttempt(.useItem) else { return }
        var events: [WorldRules.Event] = []
        mutate("use \(stack.catalogID.rawValue)", flush: true, scope: .expedition) { state in
            events = WorldRules.useItem(stack.id, on: member, in: &state)
        }
        finishTurn(events, attempt: attempt)
    }

    /// **Whoever you're standing on**, so the world screen can open the scene.
    var travellerHere: TravellerDef? {
        guard let run = activeRun, case .traveller(let id) = run.map[run.playerPosition].content
        else { return nil }
        return ContentCatalog.shared.traveller(id)
    }

    /// Talk them into coming home. The only thing that marks somebody found (Aimee, 6 Aug).
    func recruit(_ id: TravellerID) {
        guard let attempt = beginWorldFieldAttempt(.interact) else { return }
        var events: [WorldRules.Event] = []
        mutate("recruit \(id.rawValue)", flush: true, scope: .expedition) { state in
            events = WorldRules.recruit(id, in: &state)
        }
        recentEvents = events
        submitWorldFieldEvents(events, for: attempt)
        refreshWorldFieldContext()
    }

    /// Tap-to-path: walk toward a tile turn by turn, stopping the moment anything happens worth
    /// stopping for — an enemy waking, a hazard, a threshold, a fight (SPD-style, locked decision).
    func travel(to destination: GridPoint) {
        guard let run = activeRun, run.activeEncounter == nil else { return }
        let priorPosition = run.playerPosition
        guard destination != run.playerPosition else { return }
        guard let attempt = beginWorldFieldAttempt(.travel) else { return }

        let route = WorldRules.path(from: run.playerPosition, to: destination, in: run.map,
                                    slowGroundExtraTurns: run.tuning.slowGroundExtraTurns)
        guard !route.isEmpty else {
            let events: [WorldRules.Event] = [.blocked("No way through.")]
            recentEvents = events
            submitWorldFieldEvents(events, for: attempt)
            return
        }

        var events: [WorldRules.Event] = []
        mutate("travel", scope: .expedition) { state in
            for next in route {
                if let current = state.worlds.activeRun,
                   WorldRules.automaticTravelMustStop(before: next, in: current,
                                                      partySightBonus: WorldRules.sightBonus(in: state)) {
                    events.append(.blocked("Something dangerous occupies that tile. Step onto it deliberately."))
                    break
                }
                if let current = state.worlds.activeRun,
                   current.map[next].ground.movementCost > 1,
                   current.enemies.contains(where: {
                       $0.position.manhattanDistance(to: next) <= 2
                           && WorldRules.isVisible($0, in: current)
                   }) {
                    events.append(.blocked("\(current.map[next].ground.displayName.capitalized) ahead. Something dangerous is nearby; step into it deliberately."))
                    break
                }
                let stepEvents = WorldRules.step(to: next, in: &state)
                events.append(contentsOf: stepEvents)
                if stepEvents.contains(where: \.interruptsTravel) { break }
                if state.worlds.activeRun == nil { break }
            }
        }
        finishTurn(events, attempt: attempt)
        presentTravellerSpeechAfterMovement(from: priorPosition, sourceAction: .travel)
    }

    /// One pull from the node underfoot.
    func harvest() {
        let evaluation = resourceExtractionEvaluation
        switch evaluation {
        case .available, .refused(.underEquipped): break
        case .refused: return
        }
        guard let attempt = beginWorldFieldAttempt(.harvest) else { return }
        if case .refused(let refusal) = evaluation {
            let name = ResourceExtractionRules.selectedDisclosedNode(in: state)
                .flatMap { ContentCatalog.shared.resource($0.1.resource)?.name }
            finishTurn([.blocked(ResourceExtractionRules.playerCopy(
                for: refusal, resourceName: name))], attempt: attempt)
            return
        }
        var events: [WorldRules.Event] = []
        mutate("harvest", flush: true, scope: .expedition) { state in
            events = WorldRules.harvest(in: &state)
        }
        finishTurn(events, attempt: attempt)
    }

    /// One turn of searching the site underfoot. Contents land on the turn it completes.
    func searchSite() {
        guard searchableHere != nil, activeRun?.activeEncounter == nil else { return }
        guard let attempt = beginWorldFieldAttempt(.searchSite) else { return }
        var events: [WorldRules.Event] = []
        mutate("search site", flush: true, scope: .expedition) { state in
            events = WorldRules.searchSite(in: &state)
        }
        finishTurn(events, attempt: attempt)
    }

    var canSurvey: Bool {
        activeRun?.activeEncounter == nil && !(activeRun?.carriedInstruments.isEmpty ?? true)
    }

    func survey() {
        guard canSurvey else { return }
        guard let attempt = beginWorldFieldAttempt(.survey) else { return }
        var events: [WorldRules.Event] = []
        mutate("survey world", flush: true, scope: .expedition) { state in
            events = WorldRules.survey(in: &state)
        }
        finishTurn(events, attempt: attempt)
    }

    /// Leave through a portal, keeping the whole haul. The good ending.
    func portalHome(reason: String = "You returned through a portal.") {
        guard canPortalHere, activeRun?.activeEncounter == nil else { return }
        returnHomeWithFullHaul(reason: reason, kind: .portal)
    }

    func leaveMalformedOlderWorld() {
        guard canLeaveMalformedOlderWorld else { return }
        returnHomeWithFullHaul(
            reason: "This older world had no traversable way home.", kind: .abandon)
    }

    /// Banks a successful return as one save transaction. Waystones can call this away from a
    /// portal and are consumed inside the same mutation, so a crash cannot leave the stone gone
    /// while the party remains stranded in the world.
    private func returnHomeWithFullHaul(reason: String, kind: RunExitSummary.Kind,
                                        consuming stackID: InstanceID? = nil) {
        mutateIf("return home", flush: true, scope: .expedition) { state in
            guard var run = state.worlds.activeRun else { return false }
            Self.discardUnanchoredIncompleteAnimalTrust(for: run, in: &state)
            let departureState = WorldDepartureState.capture(from: run)
            if let stackID {
                guard let index = run.satchelItems.stacks.firstIndex(where: { $0.id == stackID })
                else { return false }
                _ = run.satchelItems.stacks[index].removing(1)
                if run.satchelItems.stacks[index].isEmpty { run.satchelItems.stacks.remove(at: index) }
            }
            let outcomeID = state.worlds.mintOutcomeID()
            Self.resolveRecoveredTeachingOffer(in: &run, outcomeID: outcomeID, state: &state)
            state.reality.library.attachOutcome(outcomeID,
                                                toWorld: InstanceID(rawValue: run.mapSeed))
            let banked = GameStore.bankHaul(of: run, outcomeID: outcomeID,
                                            into: &state, fraction: 1.0)
            if let index = state.worlds.anchoredRealms.firstIndex(where: { $0.runIndex == run.runIndex }) {
                state.worlds.anchoredRealms[index].world = run.anchoredSnapshot
            }
            if kind == .portal { state.reality.lifetime.runsBankedViaPortal += 1 }
            let automatic = EconomyRules.commitContinuousSettling(rawUnits: banked.rawEssence,
                                                                   outcomeID: outcomeID,
                                                                   in: &state)
            let springYield = GameStore.essenceSpringYield(for: state)
            if state.worlds.lastSpringOutcomeID != outcomeID {
                GameStore.creditEssenceSpring(&state)
                state.worlds.lastSpringOutcomeID = outcomeID
            }
            let subsidy = GameStore.applyDepartureSubsidy(
                in: &state, duringExpeditionExit: true)
            let reviewSummary = GameStore.makeReturnReceipt(
                run: run, outcomeID: outcomeID, kind: kind, reason: reason, fraction: 1,
                banked: banked, departureState: departureState,
                autoRefinedRaw: automatic?.rawSpent ?? 0,
                autoRefinedEssence: automatic?.essenceGained ?? 0,
                springYield: springYield, antiLockSubsidy: subsidy, state: state)
            guard state.worlds.appendExpeditionReview(reviewSummary) else { return false }
            state.worlds.activeRun = nil
            state.worlds.pendingWorldArrivalReceiptID = nil
            TutorialRules.freezeFirstReturnContext(run: run, banked: banked, in: &state)
            TutorialRules.recordExpeditionOutcome(in: &state)
            Self.refreshTradingPost(after: run, outcomeID: outcomeID, in: &state)
            Self.prepareAnchorSettlement(for: outcomeID, in: &state)
            return true
        }
        recentEvents = []
        clearWorldFieldFeedback()
        refreshWorldFieldContext()
    }

    /// Caught by the collapse (or carried out unconscious): keep a fraction, chosen at random.
    func endRunWithPartialHaul(reason: String, kind: RunExitSummary.Kind = .collapse) {
        guard activeRun != nil else { return }
        mutateIf("run ended: \(reason)", flush: true, scope: .expedition) { state in
            guard var run = state.worlds.activeRun else { return false }
            Self.discardUnanchoredIncompleteAnimalTrust(for: run, in: &state)
            let departureState = WorldDepartureState.capture(from: run)
            let outcomeID = state.worlds.mintOutcomeID()
            Self.resolveRecoveredTeachingOffer(in: &run, outcomeID: outcomeID, state: &state)
            state.reality.library.attachOutcome(outcomeID,
                                                toWorld: InstanceID(rawValue: run.mapSeed))
            let fraction = min(1, max(0, run.tuning.collapseRecoveryFraction))
            let banked = GameStore.bankHaul(of: run, outcomeID: outcomeID,
                                            into: &state, fraction: fraction, rng: &run.rng)
            if let index = state.worlds.anchoredRealms.firstIndex(where: { $0.runIndex == run.runIndex }) {
                state.worlds.anchoredRealms[index].world = run.anchoredSnapshot
            }
            if kind == .collapse { state.reality.lifetime.runsLostToCollapse += 1 }
            let automatic = EconomyRules.commitContinuousSettling(rawUnits: banked.rawEssence,
                                                                   outcomeID: outcomeID,
                                                                   in: &state)
            let springYield = GameStore.essenceSpringYield(for: state)
            if state.worlds.lastSpringOutcomeID != outcomeID {
                GameStore.creditEssenceSpring(&state)
                state.worlds.lastSpringOutcomeID = outcomeID
            }
            let subsidy = GameStore.applyDepartureSubsidy(
                in: &state, duringExpeditionExit: true)
            let reviewSummary = GameStore.makeReturnReceipt(
                run: run, outcomeID: outcomeID, kind: kind, reason: reason, fraction: fraction,
                banked: banked, departureState: departureState,
                autoRefinedRaw: automatic?.rawSpent ?? 0,
                autoRefinedEssence: automatic?.essenceGained ?? 0,
                springYield: springYield, antiLockSubsidy: subsidy, state: state)
            guard state.worlds.appendExpeditionReview(reviewSummary) else { return false }
            state.worlds.activeRun = nil
            state.worlds.pendingWorldArrivalReceiptID = nil
            TutorialRules.freezeFirstReturnContext(run: run, banked: banked, in: &state)
            TutorialRules.recordExpeditionOutcome(in: &state)
            Self.refreshTradingPost(after: run, outcomeID: outcomeID, in: &state)
            Self.prepareAnchorSettlement(for: outcomeID, in: &state)
            return true
        }
        recentEvents = []
        clearWorldFieldFeedback()
        refreshWorldFieldContext()
    }

    nonisolated private static func discardUnanchoredIncompleteAnimalTrust(
        for run: WorldRun, in state: inout GameState
    ) {
        guard !state.worlds.anchoredRealms.contains(where: { $0.runIndex == run.runIndex }) else {
            return
        }
        state.reality.animalTrustRecords = state.reality.animalTrustRecords.filter { _, record in
            record.worldSeed != run.mapSeed || record.completed
        }
    }

    nonisolated private static func resolveRecoveredTeachingOffer(
        in run: inout WorldRun, outcomeID: ExpeditionOutcomeID, state: inout GameState
    ) {
        guard var receipt = run.recoveredTeachingExpedition,
              receipt.validates(), receipt.resolvedAtOutcomeID == nil else { return }
        let recovered = Set(state.reality.library.recoveredTeachings.map(\.teachingID))
        state.reality.library.recoveredTeachingOffers = receipt.resultingOfferStates.filter {
            !recovered.contains($0.teachingID)
        }
        receipt.resolvedAtOutcomeID = outcomeID
        run.recoveredTeachingExpedition = receipt
    }

    func dismissRunExitSummary() {
        guard let reviewID = state.worlds.pendingExpeditionReview?.reviewID else { return }
        _ = acknowledgeExpeditionReview(reviewID)
    }

    nonisolated static func sustainObligation(forExistingRealmCount count: Int) -> Int {
        count * Tuning.Anchoring.sustainPerAdditionalRealm
    }

    nonisolated static func prepareAnchorSettlement(for outcomeID: ExpeditionOutcomeID,
                                                    in state: inout GameState) {
        recalculateAnchorProduction(in: &state)
        state.worlds.pendingAnchorSettlement = state.worlds.anchoredRealms.contains {
            !$0.isDormant && $0.projectedShortfall > 0
        }
        state.worlds.pendingAnchorSettlementOutcomeID = state.worlds.pendingAnchorSettlement
            ? outcomeID : nil
    }

    enum AnchorSettlementDecision: String, CaseIterable, Sendable {
        case sustain
        case letRest
    }

    func settleAnchoredRealms(decisions: [Int: AnchorSettlementDecision]) -> Bool {
        guard state.worlds.pendingAnchorSettlement else { return false }
        let dueRealms = state.worlds.anchoredRealms
            .filter { !$0.isDormant && $0.projectedShortfall > 0 }
        let dueIDs = Set(dueRealms.map(\.id))
        guard Set(decisions.keys) == dueIDs else { return false }
        let payingIDs = Set(decisions.compactMap { id, decision in
            decision == .sustain ? id : nil
        })
        let due = dueRealms
            .filter { payingIDs.contains($0.id) }
            .reduce(0) { $0 + $1.projectedShortfall }
        guard due <= state.base.essenceCrystalCount else { return false }
        mutate("settle anchored realms", flush: true, scope: .expedition) { state in
            guard state.base.spendEssenceCrystals(due) else { return }
            for index in state.worlds.anchoredRealms.indices {
                guard state.worlds.anchoredRealms[index].projectedShortfall > 0,
                      !state.worlds.anchoredRealms[index].isDormant else { continue }
                if !payingIDs.contains(state.worlds.anchoredRealms[index].id) {
                    state.worlds.anchoredRealms[index].isDormant = true
                    state.worlds.anchoredRealms[index].assignedCompanions = []
                }
            }
            Self.recalculateAnchorProduction(in: &state)
            state.worlds.pendingAnchorSettlement = false
            state.worlds.pendingAnchorSettlementOutcomeID = nil
        }
        return true
    }

    func reactivateAnchoredRealm(_ id: Int) -> Bool {
        guard let realm = state.worlds.anchoredRealms.first(where: { $0.id == id && $0.isDormant }) else {
            return false
        }
        let cost = max(Tuning.Anchoring.minimumReactivationCost, realm.projectedShortfall)
        guard state.base.essenceCrystalCount >= cost else { return false }
        mutate("reactivate anchored realm", flush: true, scope: .expedition) { state in
            guard let index = state.worlds.anchoredRealms.firstIndex(where: { $0.id == id }) else { return }
            guard state.base.spendEssenceCrystals(cost) else { return }
            state.worlds.anchoredRealms[index].isDormant = false
        }
        return true
    }

    func assignCompanion(_ companion: Int, toAnchoredRealm id: Int) -> Bool {
        guard let memberID = state.base.persistentID(forRosterIndex: companion),
              state.worlds.anchoredRealms.contains(where: { $0.id == id && !$0.isDormant }) else {
            return false
        }
        mutate("assign companion to anchored realm", flush: true, scope: .expedition) { state in
            state.base.activeParty.removeAll { $0 == memberID }
            for index in state.worlds.anchoredRealms.indices {
                state.worlds.anchoredRealms[index].assignedCompanions.removeAll { $0 == memberID }
            }
            guard let target = state.worlds.anchoredRealms.firstIndex(where: { $0.id == id }) else { return }
            state.worlds.anchoredRealms[target].assignedCompanions.append(memberID)
            Self.recalculateAnchorProduction(in: &state)
        }
        return true
    }

    func unassignCompanion(_ companion: Int, fromAnchoredRealm id: Int) {
        guard let memberID = state.base.persistentID(forRosterIndex: companion) else { return }
        mutate("return companion from anchored realm", flush: true, scope: .expedition) { state in
            guard let target = state.worlds.anchoredRealms.firstIndex(where: { $0.id == id }) else { return }
            state.worlds.anchoredRealms[target].assignedCompanions.removeAll { $0 == memberID }
            Self.recalculateAnchorProduction(in: &state)
        }
    }

    nonisolated static func recalculateAnchorProduction(in state: inout GameState) {
        RosterPlacementRules.recalculateRealmProduction(in: &state)
    }

    // MARK: - Turn bookkeeping

    /// Applies the consequences a turn's events imply, and hands the rest to the UI.
    private func finishTurn(_ events: [WorldRules.Event], attempt: WorldFieldAttempt) {
        // Capture the complete rules array before the legacy suffix retained for current callers.
        submitWorldFieldEvents(events, for: attempt)
        recentEvents = Array(events.suffix(GameStore.eventLimit))
        refreshWorldFieldContext()

        if events.contains(.encounterBegan) {
            clearWorldFieldFeedback()
        }

        // **Only the floor going out from under you ends a run.** The meter emptying is the world
        // beginning to come apart — you can keep working, and reaching a portal before the
        // crumbling reaches you is the decision the collapse exists to create.
        if events.contains(.floorGaveWay) {
            endRunWithPartialHaul(reason: "You stepped on a block as it crumbled away beneath you.",
                                  kind: .collapse)
        } else if let ejection = events.first(where: { if case .ejected = $0 { true } else { false } }),
                  case .ejected(let reason) = ejection {
            endRunWithPartialHaul(reason: reason, kind: .defeat)
        }
    }

    /// Banking respects the layer split: motes are Reality, everything else is Base.
    ///
    /// With a fraction below 1 the item loss is rolled off the run's own RNG, so a kill during the
    /// collapse resumes to the same outcome rather than re-rolling in the player's favour.
    struct BankedHaul: Equatable, Sendable {
        var resources: [RunExitGain]
        var items: [RunExitGain]
        var lostResources: [RunExitGain]
        var lostItems: [RunExitGain]
        var recoveredLines: [RunExitSummary.ReceiptLine] = []
        var lostLines: [RunExitSummary.ReceiptLine] = []
        var keptWorldPages: [WorldPageInstance] = []
        var lostWorldPages: [WorldPageInstance] = []
        var unidentifiedItemIDs: [ItemID]
        var returnedRawEssence: Bool
        var rawEssence: Int = 0
    }

    nonisolated static func makeReturnReceipt(
        run: WorldRun, outcomeID: ExpeditionOutcomeID, kind: RunExitSummary.Kind,
        reason: String, fraction: Double, banked: BankedHaul,
        departureState: WorldDepartureState? = nil,
        autoRefinedRaw: Int, autoRefinedEssence: Int, springYield: Int,
        antiLockSubsidy: Int = 0, state: GameState
    ) -> RunExitSummary {
        RunExitSummary(
            runIndex: run.runIndex, outcomeID: outcomeID, kind: kind, reason: reason,
            departureState: departureState,
            turnsTaken: run.turnsTaken, haulKeptFraction: fraction,
            resources: banked.resources, items: banked.items,
            lostResources: banked.lostResources, lostItems: banked.lostItems,
            recoveredLines: banked.recoveredLines, lostLines: banked.lostLines,
            keptWorldPages: banked.keptWorldPages, lostWorldPages: banked.lostWorldPages,
            progress: progressGained(in: run, state: state),
            pages: pagesFound(in: run, state: state),
            writings: writingsFound(in: run, state: state),
            recruitedTravellers: travellersRecruited(in: run, state: state),
            experienceBreakdown: run.experienceBreakdown,
            creatureMaterialRewardReceipts: run.creatureMaterialRewardReceipts,
            essenceEconomy: .init(
                rawCollected: banked.rawEssence,
                refinedEquivalent: EconomyRules.refine(
                    rawUnits: max(0, banked.rawEssence - autoRefinedRaw), in: state),
                rawAutoRefined: autoRefinedRaw,
                automaticallyRefinedEssence: autoRefinedEssence,
                bindCostPaid: run.book.essencePaid, springYield: springYield,
                antiLockSubsidy: antiLockSubsidy,
                netRunway: EconomyRules.spendableEssence(in: state)))
    }

    nonisolated private static func receiptLines(
        for stack: ItemStack, outcomeID: ExpeditionOutcomeID, side: String,
        recoveredDestination: RunExitSummary.ReceiptLine.RecoveredItemDestination? = nil
    ) -> [RunExitSummary.ReceiptLine] {
        if !stack.materials.isEmpty {
            return stack.materials.enumerated().map { index, sample in
                .materialSample(.init(
                    lineID: "\(outcomeID.rawValue)-\(side)-\(stack.id.rawValue)-\(index)",
                    sourceStackID: stack.id,
                    catalogID: stack.catalogID, sample: sample, identified: stack.identified,
                    fallbackName: stack.displayName, fallbackIcon: stack.icon,
                    recoveredDestination: recoveredDestination))
            }
        }
        let frozen = RunExitSummary.ReceiptLine.Item(
            lineID: "\(outcomeID.rawValue)-\(side)-\(stack.id.rawValue)",
            instanceID: stack.id, snapshot: stack, quantity: stack.count,
            fallbackName: stack.displayName, fallbackIcon: stack.icon,
            recoveredDestination: recoveredDestination)
        let isUnique = stack.gearProfile != nil || stack.distilledCore != nil
            || stack.upgradeLevel != 0 || stack.wildGrowth != 0
            || stack.isFavorite || stack.isLocked
        return [isUnique ? .uniqueItem(frozen) : .stackableItem(frozen)]
    }

    @discardableResult
    nonisolated static func bankHaul(of run: WorldRun,
                                     outcomeID: ExpeditionOutcomeID,
                                     into state: inout GameState,
                                     fraction: Double,
                                     rng: inout SeededRNG) -> BankedHaul {
        let keptResources = run.satchel.retainedForFailure(fraction: fraction,
                                                           outcomeID: outcomeID)
        let resourceGains = keptResources.nonZero.map { id, amount in
            let definition = ContentCatalog.shared.resource(id)
            return RunExitGain(name: definition?.name ?? id.rawValue,
                               icon: definition?.icon ?? "cube", count: amount)
        }
        let lostResourceGains = run.satchel.nonZero.compactMap { id, amount -> RunExitGain? in
            let lost = amount - keptResources[id]
            guard lost > 0 else { return nil }
            let definition = ContentCatalog.shared.resource(id)
            return RunExitGain(name: definition?.name ?? id.rawValue,
                               icon: definition?.icon ?? "cube", count: lost)
        }
        let recoveredResourceLines = keptResources.nonZero.map { id, amount in
            let definition = ContentCatalog.shared.resource(id)
            return RunExitSummary.ReceiptLine.resource(.init(
                lineID: "\(outcomeID.rawValue)-recovered-\(id.rawValue)",
                id: id, quantity: amount, fallbackName: definition?.name ?? id.rawValue,
                fallbackIcon: definition?.icon ?? "cube"))
        }
        let lostResourceLines = run.satchel.nonZero.compactMap { id, amount -> RunExitSummary.ReceiptLine? in
            let lost = amount - keptResources[id]
            guard lost > 0 else { return nil }
            let definition = ContentCatalog.shared.resource(id)
            return .resource(.init(lineID: "\(outcomeID.rawValue)-lost-\(id.rawValue)",
                                   id: id, quantity: lost,
                                   fallbackName: definition?.name ?? id.rawValue,
                                   fallbackIcon: definition?.icon ?? "cube"))
        }
        for (id, amount) in keptResources.nonZero {
            if ContentCatalog.shared.resource(id)?.isRealityCurrency == true {
                state.reality.motes += amount
            } else {
                state.base.resources.add(amount, of: id)
            }
        }
        let materialPartition = partitionCraftMaterialsForFailure(
            world: run.worldMaterialReserve, creature: run.creatureMaterialReserve,
            fraction: fraction, outcomeID: outcomeID)
        func materialGains(_ units: [CraftMaterialHoldingV1]) -> [RunExitGain] {
            Dictionary(grouping: units, by: { $0.sample.kind })
                .map { kind, units in
                    RunExitGain(name: units.count == 1 ? kind.displayName
                                                       : kind.pluralName.capitalisedSentence,
                                icon: kind.icon, count: units.count)
                }
                .sorted { $0.name < $1.name }
        }
        func materialLines(_ units: [CraftMaterialHoldingV1], side: String)
            -> [RunExitSummary.ReceiptLine] {
            units.sorted { $0.id < $1.id }.map { unit in
                .materialSample(.init(
                    lineID: "\(outcomeID.rawValue)-\(side)-\(unit.id.rawValue)",
                    sourceStackID: nil, reserveUnitID: unit.id,
                    catalogID: Items.material, sample: unit.sample, identified: true,
                    fallbackName: unit.sample.displayName, fallbackIcon: unit.sample.kind.icon,
                    recoveredDestination: side == "recovered" ? .stored : nil))
            }
        }
        for var unit in materialPartition.keptWorld.units {
            unit.protectedReturn = false
            _ = state.base.worldMaterialReserve.add(unit)
        }
        for var unit in materialPartition.keptCreature.units {
            unit.protectedReturn = false
            _ = state.base.creatureMaterialReserve.add(unit)
        }
        var guaranteed = Inventory(slots: run.satchelItems.slots)
        var exposed = Inventory(slots: run.satchelItems.slots)
        for stack in run.satchelItems.stacks {
            let parts = stack.partitionedForReturn()
            if let safe = parts.protected { _ = guaranteed.add(safe) }
            if let risk = parts.atRisk { _ = exposed.add(risk) }
        }
        let protectedPages = run.carriedWorldPages.filter { $0.definition.disposition.isProtected }
        let exposedPages = run.carriedWorldPages.filter { !$0.definition.disposition.isProtected }
        func pageUnitKey(_ page: WorldPageInstance) -> String {
            "world-page:\(page.definition.id.rawValue):\(page.id.rawValue)"
        }
        let exposedPartition = exposed.partitionedForFailure(
            fraction: fraction, outcomeID: outcomeID,
            additionalUnitKeys: exposedPages.map(pageUnitKey))
        let retainedRisk = exposedPartition.kept
        let keptPages = protectedPages + exposedPages.filter {
            exposedPartition.keptAdditionalUnitKeys.contains(pageUnitKey($0))
        }
        let lostPages = exposedPages.filter {
            !exposedPartition.keptAdditionalUnitKeys.contains(pageUnitKey($0))
        }
        var kept = guaranteed
        for stack in retainedRisk.stacks { _ = kept.add(stack) }
        let itemGains = kept.stacks.compactMap { stack -> RunExitGain? in
            guard stack.count > 0 else { return nil }
            return RunExitGain(name: stack.displayName,
                               icon: ContentCatalog.shared.item(stack.catalogID)?.icon ?? "shippingbox",
                               count: stack.count)
        }
        let lostStacks = exposedPartition.lost.stacks
        let lostItemGains = lostStacks.map {
            RunExitGain(name: $0.displayName, icon: $0.icon, count: $0.count)
        }
        let lostItemLines = lostStacks.filter { $0.count > 0 }.flatMap {
            receiptLines(for: $0, outcomeID: outcomeID, side: "lost")
        }
        var recoveredItemLines: [RunExitSummary.ReceiptLine] = []
        for var stack in kept.stacks {
            let frozenStack = stack
            stack.protectedReturnCount = 0
            let destination: RunExitSummary.ReceiptLine.RecoveredItemDestination
            if state.base.inventory.add(stack) {
                destination = .stored
            } else {
                // Full Storehouse. It waits rather than evaporating — see `BaseState.spillover`.
                state.base.spillover.append(stack)
                destination = .waitingToSort
            }
            recoveredItemLines += receiptLines(
                for: frozenStack, outcomeID: outcomeID, side: "recovered",
                recoveredDestination: destination)
        }
        let isFirstBankForOutcome = outcomeID.rawValue > 0
            && !state.worlds.worldPageBankedOutcomeIDs.contains(outcomeID)
        if isFirstBankForOutcome {
            var newlyBankedRandom = false
            for page in keptPages.sorted(by: { $0.id.rawValue < $1.id.rawValue }) {
                guard WorldPageCatalog.definition(page.definition.id) == page.definition,
                      !state.base.collectedWorldPages.contains(where: { $0.id == page.id })
                else { continue }
                state.base.collectedWorldPages.append(page)
                if page.definition.disposition.isRandom { newlyBankedRandom = true }
            }
            if newlyBankedRandom {
                state.worlds.randomWorldPageDrought = 0
            } else if run.runIndex >= 2 {
                state.worlds.randomWorldPageDrought += 1
            }
            state.worlds.worldPageBankedOutcomeIDs.insert(outcomeID)
        }
        let keptMaterialUnits = materialPartition.keptWorld.units + materialPartition.keptCreature.units
        let lostMaterialUnits = materialPartition.lostWorld.units + materialPartition.lostCreature.units
        return BankedHaul(resources: resourceGains + materialGains(keptMaterialUnits),
                          items: itemGains,
                          lostResources: lostResourceGains + materialGains(lostMaterialUnits),
                          lostItems: lostItemGains,
                          recoveredLines: recoveredResourceLines + recoveredItemLines
                            + materialLines(keptMaterialUnits, side: "recovered"),
                          lostLines: lostResourceLines + lostItemLines
                            + materialLines(lostMaterialUnits, side: "lost"),
                          keptWorldPages: keptPages,
                          lostWorldPages: lostPages,
                          unidentifiedItemIDs: retainedRisk.stacks.filter { !$0.identified }.map(\.catalogID),
                          returnedRawEssence: keptResources[Resources.essenceRaw] > 0,
                          rawEssence: keptResources[Resources.essenceRaw])
    }

    @discardableResult
    nonisolated static func bankHaul(of run: WorldRun, outcomeID: ExpeditionOutcomeID = 0,
                                     into state: inout GameState, fraction: Double) -> BankedHaul {
        var unused = run.rng
        return bankHaul(of: run, outcomeID: outcomeID, into: &state,
                        fraction: fraction, rng: &unused)
    }

    /// Compatibility seam for rule fixtures that exercise banking without minting an expedition
    /// outcome. Production return paths always pass the real minted OutcomeID above.
    @discardableResult
    nonisolated static func bankHaul(of run: WorldRun, into state: inout GameState,
                                     fraction: Double, rng: inout SeededRNG) -> BankedHaul {
        bankHaul(of: run, outcomeID: 0, into: &state, fraction: fraction, rng: &rng)
    }

    nonisolated static func progressGained(in run: WorldRun, state: GameState) -> [RunProgressGain] {
        run.partyProgressAtStart.map { start in
            let current = state.base.character(start.member)
            return RunProgressGain(member: start.member, name: start.name,
                                   experience: max(0, current.experience - start.experience),
                                   levels: max(0, current.level - start.level),
                                   finalLevel: current.level)
        }
    }

    nonisolated static func pagesFound(in run: WorldRun, state: GameState) -> [DiaryPageID] {
        state.reality.library.foundPages.filter { !run.foundPagesAtStart.contains($0) }
    }

    nonisolated static func writingsFound(
        in run: WorldRun, state: GameState
    ) -> [RunExitSummary.RecoveredWriting] {
        state.reality.library.foundWritings
            .filter { !run.foundWritingsAtStart.contains($0.id) }
            .map { writing in
                let kind: RunExitSummary.RecoveredWriting.Kind = switch writing.family {
                case .fieldNote: .fieldNote
                case .routeMark: .routeMark
                case .siteFragment: .siteFragment
                case .workingScrap: .workingScrap
                }
                let title: String = switch writing.family {
                case .fieldNote: "Field note"
                case .routeMark: "Route sketch"
                case .siteFragment: "Site fragment"
                case .workingScrap: "Working scrap"
                }
                return .init(id: writing.id.rawValue, kind: kind, title: title,
                             prose: writing.prose)
            }
    }

    nonisolated static func travellersRecruited(in run: WorldRun, state: GameState) -> [TravellerID] {
        state.reality.library.foundTravellers
            .subtracting(run.foundTravellersAtStart)
            .sorted { $0.rawValue < $1.rawValue }
    }
}
