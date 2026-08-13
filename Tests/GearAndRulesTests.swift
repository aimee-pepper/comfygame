import XCTest
@testable import Bookbinder

/// Session 12: gear is found rather than researched, and rules are edited in place.
@MainActor
final class GearAndRulesTests: XCTestCase {

    func testFirepitReturnReportsStalePlacementInsteadOfSilentlyDoingNothing() {
        let store = GameStore(io: .temporary(name: "firepit-return-\(UUID().uuidString)"))
        store.mutate("prepare active companion") { state in
            state.base.roster = [CompanionState()]
            state.base.activeParty = [0]
        }

        XCTAssertEqual(store.setComingHome(0), .committed)
        guard case .refused(let message) = store.setComingHome(0) else {
            return XCTFail("A stale return was reported as committed")
        }
        XCTAssertTrue(message.contains("placement changed"))
        XCTAssertEqual(store.placement(of: 0), .home)
    }

    func testFirepitConfirmationDismissesOnlyAfterCommittedQuote() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(contentsOf: root.appending(path: "Sources/Screens/FirepitView.swift"),
                                encoding: .utf8)
        let detailStart = try XCTUnwrap(source.range(of: "private struct PartyTransferConfirmationSheet"))
        let detail = source[detailStart.lowerBound...]

        XCTAssertTrue(source.contains(".sheet(item: $pendingTransfer)"))
        XCTAssertTrue(detail.contains("case .committed: dismiss()"))
        XCTAssertTrue(detail.contains("case .refused(let message): refusal = message"))
        XCTAssertFalse(source.contains("_ = store.setComing(index, false"))
    }

    func testFirepitShowsCurrentCommunityWithoutAnUnavailableFutureTavernCard() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(contentsOf: root.appending(path: "Sources/Screens/FirepitView.swift"),
                                encoding: .utf8)

        XCTAssertTrue(source.contains("Coming with you"))
        XCTAssertTrue(source.contains("At Home"))
        XCTAssertTrue(source.contains("The fire is full — five is as many as you can keep."))
        XCTAssertFalse(source.contains("A tavern would bring other people's travellers through"))
    }

    func testPartyStorageSummaryNamesCapacitiesRatherThanClaimingItemCounts() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(contentsOf: root.appending(path: "Sources/Screens/PartyRosterView.swift"),
                                encoding: .utf8)

        XCTAssertTrue(source.contains("satchelCapacity) capacity"))
        XCTAssertTrue(source.contains("inventory.slots) Storehouse bins"))
        XCTAssertFalse(source.contains("satchelCapacity) carried"))
        XCTAssertFalse(source.contains("inventory.slots) stored"))
    }

    // MARK: Gear comes from the world, not from study

    func testNoResearchNodeModifiesAPartyMember() {
        // "Modifying party members through a research node is not how this works and never was."
        for node in ContentCatalog.shared.researchNodes {
            for grant in node.grants {
                XCTAssertNotEqual(grant.effect, .companionWeapon,
                                  "\(node.id.rawValue) still upgrades a weapon through research")
                XCTAssertNotEqual(grant.effect, .companionArmor,
                                  "\(node.id.rawValue) still upgrades armor through research")
            }
        }
        XCTAssertNil(ContentCatalog.shared.researchBranch("forge"), "the Forge branch is still here")
    }

    func testTiersComeEntirelyFromWhatIsWorn() {
        let store = GameStore(io: .temporary(name: "gear-\(UUID().uuidString)"))
        XCTAssertEqual(store.state.base.companion.weaponTier, 0)

        let blade = ItemStack(id: InstanceID(rawValue: 1), catalogID: "blade_keen")
        store.mutate("test: haul it home") { $0.base.inventory.add(blade) }
        store.equip(blade, on: PartyMember.member(0))

        let tier = ContentCatalog.shared.item("blade_keen")?.gear?.tier
        XCTAssertEqual(store.state.base.companion.weaponTier, tier)

        store.unequip(.weapon, from: PartyMember.member(0))
        XCTAssertEqual(store.state.base.companion.weaponTier, 0, "taking it off left the tier behind")
    }

    func testWearingSomethingActuallyHitsHarder() {
        let store = GameStore(io: .temporary(name: "gear-\(UUID().uuidString)"))
        let bare = CombatRules.companionAttack(0, in: store.state)

        let blade = ItemStack(id: InstanceID(rawValue: 1), catalogID: "blade_binders")
        store.mutate("test: haul it home") { $0.base.inventory.add(blade) }
        store.equip(blade, on: PartyMember.member(0))

        XCTAssertGreaterThan(CombatRules.companionAttack(0, in: store.state), bare)
    }

    func testSitesCarryGearAndRuinsCarryTheBest() {
        let catalog = ContentCatalog.shared
        func bestTier(_ site: SiteDef) -> Int {
            site.contents.items.compactMap { catalog.item($0)?.gear?.tier }.max() ?? 0
        }
        let ruins = catalog.sites.filter { $0.category == .oldRuin }
        let ordinary = catalog.sites.filter { $0.category == .landmark }

        XCTAssertGreaterThan(ruins.map(bestTier).max() ?? 0, ordinary.map(bestTier).max() ?? 0,
                             "ruins should hold the notably better gear")
        XCTAssertTrue(catalog.sites.contains { !$0.contents.items.isEmpty },
                      "no site carries anything wearable at all")
    }

    /// A site's items were catalogued and validated but never actually handed over.
    func testSearchingASiteHandsOverItsItems() throws {
        let store = GameStore(io: .temporary(name: "loot-\(UUID().uuidString)"))
        store.mutate("test: know everything") { state in
            state.base.ownedSymbols = Set(ContentCatalog.shared.symbols.map(\.id))
            state.base.essence = 5000
        }
        store.write("plains")

        for _ in 0..<60 {
            store.bindAndDepart()
            if let run = store.state.worlds.activeRun,
               let site = run.sites.first(where: { !($0.definition?.contents.items.isEmpty ?? true) }) {
                store.mutate("test: stand on it") { state in
                    state.worlds.activeRun?.playerPosition = site.position
                    state.worlds.activeRun?.enemies.removeAll()
                    state.worlds.activeRun?.stability = Tuning.World.startingStability
                }
                for _ in 0..<(site.definition?.contents.searchTurns ?? 1) { store.searchSite() }

                let carried = store.state.worlds.activeRun?.satchelItems.stacks.map(\.catalogID) ?? []
                let offered = store.state.worlds.activeRun?.offeredItems.map(\.catalogID) ?? []
                for item in site.definition!.contents.items {
                    XCTAssertTrue(carried.contains(item) || offered.contains(item),
                                  "\(site.siteID.rawValue) never handed over \(item.rawValue)")
                }
                return
            }
            store.mutate("test: next") { $0.worlds.activeRun = nil }
        }
        throw XCTSkip("no world in sixty held a site with anything in it")
    }

    // MARK: Rules are edited in place, and can be switched off

    func testASegmentCanBeChangedWithoutRebuildingTheRule() throws {
        let store = GameStore(io: .temporary(name: "rules-\(UUID().uuidString)"))
        guard let rule = store.gambits(for: .companion(0)).first else { return XCTFail("no starting rules") }
        guard let other = store.ownedComponents(.action).first(where: { $0.id != rule.action })
        else { throw XCTSkip("only one action known") }

        store.setGambitPart(rule.id, kind: .action, to: other.id)
        let updated = store.gambits(for: .companion(0)).first
        XCTAssertEqual(updated?.action, other.id)
        XCTAssertEqual(updated?.id, rule.id, "editing a part replaced the whole rule")
        XCTAssertEqual(updated?.subject, rule.subject, "editing one part changed another")
    }

    func testAConditionCanBeClearedBackToUnconditional() {
        let store = GameStore(io: .temporary(name: "rules-\(UUID().uuidString)"))
        guard let rule = store.gambits(for: .companion(0)).first(where: { $0.hasCondition })
        else { return XCTFail("no conditional starting rule") }

        store.setGambitPart(rule.id, kind: .property, to: nil)
        XCTAssertFalse(store.gambits(for: .companion(0)).first { $0.id == rule.id }?.hasCondition ?? true)
    }

    func testSwitchingARuleOffKeepsItButStopsItFiring() {
        let store = GameStore(io: .temporary(name: "rules-\(UUID().uuidString)"))
        guard let rule = store.gambits(for: .companion(0)).first else { return XCTFail("no rules") }
        let countBefore = store.gambits(for: .companion(0)).count

        store.setGambitEnabled(rule.id, false)
        let after = store.gambits(for: .companion(0))
        XCTAssertEqual(after.count, countBefore, "switching off deleted the rule")
        XCTAssertEqual(after.first?.id, rule.id, "switching off moved the rule")
        XCTAssertFalse(after.first?.isEnabled ?? true)
    }

    func testADisabledRuleNeverFires() {
        let store = GameStore(io: .temporary(name: "rules-\(UUID().uuidString)"))
        store.mutate("test: fund") { $0.base.essence = 500 }
        store.bindAndDepart()
        guard var state = Optional(store.state), state.worlds.activeRun != nil else {
            return XCTFail("couldn't depart")
        }
        guard let rule = store.gambits(for: .companion(0)).first else { return XCTFail("no rules") }

        // With it on, it's a candidate; with it off, it isn't.
        state.base.companion.gambits = [rule]
        let live = GambitEngine.rules(for: .companion(0), in: state).filter(\.isEnabled)
        XCTAssertEqual(live.count, 1)

        state.base.companion.gambits[0].isEnabled = false
        XCTAssertTrue(GambitEngine.rules(for: .companion(0), in: state).filter(\.isEnabled).isEmpty)
    }

    func testARuleSurvivesAForceQuitWithItsSwitchPosition() throws {
        let io = SaveFileIO.temporary(name: "rules-\(UUID().uuidString)")
        defer { io.deleteEverything() }
        var ruleID: InstanceID?
        do {
            let store = GameStore(io: io)
            guard let rule = store.gambits(for: .companion(0)).first else { return XCTFail("no rules") }
            ruleID = rule.id
            store.setGambitEnabled(rule.id, false)
            store.flushNow()
        }
        let resumed = GameStore(io: io)
        XCTAssertEqual(resumed.gambits(for: .companion(0)).first { $0.id == ruleID }?.isEnabled, false)
    }

    // MARK: Is it an improvement?

    /// The question the player actually has is "is this better?", and a tier number only answers it
    /// if you already know the formula. The badge answers it in the units the fight uses.
    func testTheDeltaIsStatedInFightUnitsNotTiers() throws {
        let store = GameStore(io: .temporary(name: "delta-\(UUID().uuidString)"))
        let chipped = try XCTUnwrap(ContentCatalog.shared.item("blade_chipped"))
        let binders = try XCTUnwrap(ContentCatalog.shared.item("blade_binders"))

        // Nothing worn: the delta is the whole of what it gives.
        XCTAssertEqual(store.gearDelta(wearing: chipped, for: PartyMember.member(0)),
                       (chipped.gear?.tier ?? 0) * Tuning.Encounter.attackPerWeaponTier)

        store.mutate("test: haul it home") { $0.base.inventory.add(
            ItemStack(id: InstanceID(rawValue: 1), catalogID: chipped.id)) }
        store.equip(ItemStack(id: InstanceID(rawValue: 1), catalogID: chipped.id), on: PartyMember.member(0))

        // Against something worn, it's the difference — and it matches what combat will actually do.
        let promised = store.gearDelta(wearing: binders, for: PartyMember.member(0))
        let before = CombatRules.companionAttack(0, in: store.state)
        store.mutate("test: haul the better one home") { $0.base.inventory.add(
            ItemStack(id: InstanceID(rawValue: 2), catalogID: binders.id)) }
        store.equip(ItemStack(id: InstanceID(rawValue: 2), catalogID: binders.id), on: PartyMember.member(0))

        XCTAssertEqual(CombatRules.companionAttack(0, in: store.state) - before, promised,
                       "the badge promised a number the fight didn't deliver")
    }

    func testAWorsePieceReadsAsWorse() throws {
        let store = GameStore(io: .temporary(name: "delta-\(UUID().uuidString)"))
        let good = try XCTUnwrap(ContentCatalog.shared.item("guard_vault"))
        let poor = try XCTUnwrap(ContentCatalog.shared.item("guard_padded"))
        store.mutate("test: haul it home") { $0.base.inventory.add(
            ItemStack(id: InstanceID(rawValue: 1), catalogID: good.id)) }
        store.equip(ItemStack(id: InstanceID(rawValue: 1), catalogID: good.id), on: PartyMember.member(0))
        XCTAssertLessThan(store.gearDelta(wearing: poor, for: PartyMember.member(0)), 0)
    }

    func testTheUpgradeNudgeOnlyFiresWhenSomethingIsActuallyBetter() throws {
        let store = GameStore(io: .temporary(name: "nudge-\(UUID().uuidString)"))
        XCTAssertFalse(store.hasUpgradeAvailable(for: .weapon, member: PartyMember.member(0)), "nudged with an empty storehouse")

        let best = try XCTUnwrap(ContentCatalog.shared.item("blade_binders"))
        store.mutate("test: haul it home") { $0.base.inventory.add(
            ItemStack(id: InstanceID(rawValue: 1), catalogID: best.id)) }
        XCTAssertTrue(store.hasUpgradeAvailable(for: .weapon, member: PartyMember.member(0)))

        store.equip(ItemStack(id: InstanceID(rawValue: 1), catalogID: best.id), on: PartyMember.member(0))
        XCTAssertFalse(store.hasUpgradeAvailable(for: .weapon, member: PartyMember.member(0)),
                       "still nudging about the thing already worn")
    }

    func testUpgradeNudgeDoesNotAdvertiseGearWornBySomebodyElse() throws {
        let store = GameStore(io: .temporary(name: "nudge-worn-\(UUID().uuidString)"))
        let better = try XCTUnwrap(ContentCatalog.shared.item("blade_binders"))
        store.mutate("test: add companion and better blade") { state in
            var companion = CompanionState()
            companion.name = "Mara"
            state.base.roster.append(companion)
            state.base.inventory.add(ItemStack(id: InstanceID(rawValue: 41), catalogID: better.id))
        }

        XCTAssertTrue(store.hasUpgradeAvailable(for: .weapon, slot: .binder))
        store.equip(ItemStack(id: InstanceID(rawValue: 41), catalogID: better.id), on: .member(0))

        XCTAssertFalse(store.hasUpgradeAvailable(for: .weapon, slot: .binder),
                       "somebody else's worn blade is not an available shelf upgrade")
        XCTAssertTrue(store.wearableOptions(in: .weapon, excluding: .binder).contains {
            $0.source == .worn(.member(0))
        }, "the picker should still permit an explicit transfer")
    }

    /// Equipment round-trips as a readable object, not the alternating array Swift defaults to for
    /// a dictionary whose key isn't a coding key.
    func testEquipmentRoundTripsThroughASaveAsAnObject() throws {
        let store = GameStore(io: .temporary(name: "equip-\(UUID().uuidString)"))
        store.mutate("test: wear it") { $0.base.companion.equipped[.weapon] = "blade_keen" }

        let data = try SaveCodec.encode(store.state)
        let text = try XCTUnwrap(String(data: data, encoding: .utf8))
        XCTAssertTrue(text.contains("\"weapon\" : \"blade_keen\"")
                      || text.contains("\"weapon\": \"blade_keen\""),
                      "equipment didn't encode as a readable object")

        let reloaded = try SaveCodec.decode(data)
        XCTAssertEqual(reloaded.base.companion.equipped[.weapon]?.catalogID, "blade_keen")
        XCTAssertNotEqual(reloaded.base.companion.equipped[.weapon]?
            .gearProfile?.stableInstanceID.rawValue, 0)
    }

    /// **A rebalance has to reach saves that already exist.**
    ///
    /// `Inventory.slots` is stored, so a save written when the storehouse held eight kept holding
    /// eight forever and raising the number in `Tuning` did nothing for anybody who had already
    /// played — which is precisely the person the change was for.
    func testAnOlderSaveGetsTheStorehouseItShouldHave() throws {
        var old = GameState.newGame()
        old.base.inventory.slots = 8
        old.base.inventory.stacks = [ItemStack(id: InstanceID(rawValue: 1), catalogID: "blade_keen")]

        let reloaded = try SaveCodec.decode(try SaveCodec.encode(old))
        XCTAssertEqual(reloaded.base.inventory.slots, Tuning.Economy.startingInventorySlots)
        XCTAssertEqual(reloaded.base.inventory.stacks.count, 1, "resizing the shelf emptied it")
    }

    func testAStationAddedAfterASaveWasWrittenStillAppears() throws {
        // The Library was invisible on any save written before it existed, because a station missing
        // from the save's dictionary defaulted to locked rather than to what the catalog says.
        var state = GameState.newGame()
        state.base.stations = [:]
        for station in ContentCatalog.shared.stations where station.unlockedAtStart {
            XCTAssertTrue(state.base.station(station.id).isUnlocked,
                          "\(station.id.rawValue) would be invisible on an older save")
        }
    }

    // MARK: - Both of them carry their own (Aimee, 5 Aug)

    /// The Binder's attack was a `Tuning` constant while Quill had a sword, so **the damage-type
    /// matchup never reached the player's own turns** — which is the whole point of giving weapons
    /// a type at all.
    @MainActor
    func testTheBindersOwnWeaponReachesItsOwnAttack() throws {
        let store = GameStore(io: .temporary(name: "binder-gear-\(UUID().uuidString)"))
        let before = CombatRules.binderAttack(in: store.state)

        let blade = try XCTUnwrap(ContentCatalog.shared.item("blade_binders"))
        store.mutate("haul it home") { $0.base.inventory.add(
            ItemStack(id: InstanceID(rawValue: 1), catalogID: blade.id)) }
        store.equip(ItemStack(id: InstanceID(rawValue: 1), catalogID: blade.id), on: PartyMember.binder)

        XCTAssertGreaterThan(CombatRules.binderAttack(in: store.state), before)
        XCTAssertEqual(CombatRules.damageKind(for: .binder, in: store.state), blade.gear?.damage)
    }

    /// They can carry different weapons, which is the answer to a world that grew both plated and
    /// furred things.
    @MainActor
    func testTheTwoOfThemCanCarryDifferentWeapons() {
        let store = GameStore(io: .temporary(name: "two-\(UUID().uuidString)"))
        store.mutate("haul two home") { state in
            state.base.inventory.add(ItemStack(id: InstanceID(rawValue: 1), catalogID: "blade_keen"))
            state.base.inventory.add(ItemStack(id: InstanceID(rawValue: 2), catalogID: "blade_chipped"))
        }
        store.equip(ItemStack(id: InstanceID(rawValue: 1), catalogID: "blade_keen"), on: PartyMember.binder)
        store.equip(ItemStack(id: InstanceID(rawValue: 2), catalogID: "blade_chipped"), on: PartyMember.member(0))

        XCTAssertEqual(CombatRules.damageKind(for: .binder, in: store.state), .pierce)
        XCTAssertEqual(CombatRules.damageKind(for: .companion(0), in: store.state), .rend)
    }

    /// **If you have four, you can wear four.** Physical gear is four durable instances rather
    /// than a quantity bin, because each piece can acquire its own provenance and reforge history.
    ///
    /// Aimee, 6 Aug: *"in storage it shows I have 4 padded guards and two chipped blades but when I
    /// go to equip my character with those items it unequips them from my companion."* Equipping
    /// used to claim a piece by catalogue id, so a storehouse holding four of a thing could still
    /// only dress one person. Equipping now takes **an instance out of the bin**.
    @MainActor
    func testAFullBinCanDressBothOfThem() throws {
        let store = GameStore(io: .temporary(name: "bin-\(UUID().uuidString)"))
        store.mutate("haul four home") { state in
            for id in 1...4 {
                state.base.inventory.add(ItemStack(id: InstanceID(rawValue: UInt64(id)),
                                                   catalogID: "guard_padded"))
            }
        }

        let bin = try XCTUnwrap(store.state.base.inventory.stacks.first)
        store.equip(bin, on: PartyMember.binder)
        let after = try XCTUnwrap(store.state.base.inventory.stacks.first)
        store.equip(after, on: PartyMember.member(0))

        XCTAssertEqual(store.worn(.armor, by: PartyMember.binder)?.catalogID, "guard_padded")
        XCTAssertEqual(store.worn(.armor, by: PartyMember.member(0))?.catalogID, "guard_padded",
                       "dressing one of them stripped the other")
        XCTAssertEqual(store.state.base.inventory.stacks.filter { $0.catalogID == "guard_padded" }.count, 2,
                       "the two they are wearing didn't come out of the bin")
    }

    /// **And if you only have one, you can only wear one.** The bin is the truth either way — a
    /// single blade can't be handed to Quill while you're still holding it.
    @MainActor
    func testOneOfAThingOnlyDressesOneOfThem() {
        let store = GameStore(io: .temporary(name: "one-\(UUID().uuidString)"))
        let stack = ItemStack(id: InstanceID(rawValue: 1), catalogID: "blade_keen")
        store.mutate("haul it home") { $0.base.inventory.add(stack) }

        store.equip(stack, on: PartyMember.binder)
        XCTAssertEqual(store.worn(.weapon, by: PartyMember.binder)?.catalogID, "blade_keen")

        store.equip(stack, on: PartyMember.member(0))
        XCTAssertNil(store.worn(.weapon, by: PartyMember.member(0)), "dressed them from an empty shelf")
        XCTAssertEqual(store.worn(.weapon, by: PartyMember.binder)?.catalogID, "blade_keen",
                       "the sword was taken off the person actually holding it")
    }

    /// Taking something off puts it back where it came from, rather than evaporating it.
    @MainActor
    func testTakingSomethingOffPutsItBackOnTheShelf() {
        let store = GameStore(io: .temporary(name: "off-\(UUID().uuidString)"))
        let stack = ItemStack(id: InstanceID(rawValue: 1), catalogID: "blade_keen")
        store.mutate("haul it home") { $0.base.inventory.add(stack) }

        store.equip(stack, on: PartyMember.binder)
        XCTAssertTrue(store.state.base.inventory.stacks.isEmpty)

        store.unequip(.weapon, from: PartyMember.binder)
        XCTAssertEqual(store.state.base.inventory.stacks.first?.catalogID, "blade_keen")
        XCTAssertNil(store.worn(.weapon, by: PartyMember.binder))
    }

    /// The Binder stood in whatever a world threw at it wearing nothing at all.
    @MainActor
    func testTheBindersArmourActuallyProtectsIt() {
        let store = GameStore(io: .temporary(name: "armour-\(UUID().uuidString)"))
        let before = CombatRules.damageTaken(10, by: .binder, in: store.state)

        let guardPiece = ItemStack(id: InstanceID(rawValue: 1), catalogID: "guard_vault")
        store.mutate("haul it home") { $0.base.inventory.add(guardPiece) }
        store.equip(guardPiece, on: PartyMember.binder)

        XCTAssertLessThan(CombatRules.damageTaken(10, by: .binder, in: store.state), before)
    }


    /// **Everybody you took is on the Party screen**, or there is no way to give them gear.
    ///
    /// Aimee, 7 Aug: *"I added people to the party at the firepit but they're not showing up on the
    /// party page so I can't give them gear."* `partySlots` filtered on `activeCompanion`, which is
    /// only the *first* of the party — written before a party could hold more than one person, and
    /// it quietly outlived that. Nothing asserted on it, so nothing caught it.
    @MainActor
    func testEverybodyYouTookIsOnThePartyScreen() {
        let store = GameStore(io: .temporary(name: "slots-\(UUID().uuidString)"))
        store.mutate("test: a fire with people at it") { state in
            var b = CompanionState(); b.name = "Bramwell"
            var c = CompanionState(); c.name = "Corvin"
            state.base.roster = [CompanionState(), b, c]
            state.base.activeParty = [0]
        }
        XCTAssertEqual(store.partySlots.count, 2, "you and Quill")

        store.setComing(1, true)
        store.setComing(2, true)

        XCTAssertEqual(store.partySlots, [.binder, .member(0), .member(1), .member(2)],
                       "took three and the screen shows \(store.partySlots.count - 1)")
        // And each of them is a real page: a name, a sheet, and gear slots that answer.
        for slot in store.partySlots {
            XCTAssertFalse(store.name(of: slot).isEmpty, "a blank row on the Party screen")
            XCTAssertGreaterThan(store.character(of: slot).level, 0)
            for gearSlot in GearSlot.allCases {
                _ = store.worn(gearSlot, by: slot)   // must not trap on anybody in the party
            }
        }
    }

    /// Leaving somebody takes them off it again.
    @MainActor
    func testLeavingSomebodyTakesThemOffThePartyScreen() {
        let store = GameStore(io: .temporary(name: "unslot-\(UUID().uuidString)"))
        store.mutate("test: two of them") { state in
            state.base.roster = [CompanionState(), CompanionState()]
            state.base.activeParty = [0, 1]
        }
        XCTAssertEqual(store.partySlots.count, 3)
        store.setComing(1, false)
        XCTAssertEqual(store.partySlots, [.binder, .member(0)])
    }

    func testEquipmentPickerUsesFrozenSlotAndIncludesOverflow() throws {
        let store = GameStore(io: .temporary(name: "owned-gear-\(UUID().uuidString)"))
        var frozen = ItemStack(id: InstanceID(rawValue: 901), catalogID: "blade_keen")
        frozen.gearProfile?.slot = .armor // Simulates an authored/migrated instance surviving a catalogue change.
        store.mutate("test: overflow frozen piece") { $0.base.spillover = [frozen] }

        XCTAssertFalse(store.wearableOptions(in: .weapon).contains { $0.piece.gearProfile?.stableInstanceID == frozen.gearProfile?.stableInstanceID })
        let option = try XCTUnwrap(store.wearableOptions(in: .armor).first)
        XCTAssertEqual(option.source, .overflow(frozen.id))

        store.equip(option, on: .binder)
        XCTAssertEqual(store.worn(.armor, by: .binder)?.gearProfile?.stableInstanceID,
                       frozen.gearProfile?.stableInstanceID)
        XCTAssertTrue(store.state.base.spillover.isEmpty)
    }

    func testPickerCanSwapExactPiecesBetweenPeopleWithoutLosingEither() throws {
        let store = GameStore(io: .temporary(name: "swap-gear-\(UUID().uuidString)"))
        var first = ItemStack(id: InstanceID(rawValue: 911), catalogID: "blade_keen")
        var second = ItemStack(id: InstanceID(rawValue: 912), catalogID: "blade_chipped")
        first.gearProfile?.reforgeRank = 2
        second.wildGrowth = 1
        store.mutate("test: dress both") { state in
            state.base.binderEquipped[.weapon] = EquippedPiece(first)
            state.base.roster[0].equipped[.weapon] = EquippedPiece(second)
        }

        let offered = try XCTUnwrap(store.wearableOptions(in: .weapon, excluding: .binder)
            .first { $0.source == .worn(.member(0)) })
        store.equip(offered, on: .binder)

        XCTAssertEqual(store.worn(.weapon, by: .binder)?.gearProfile?.stableInstanceID,
                       second.gearProfile?.stableInstanceID)
        XCTAssertEqual(store.worn(.weapon, by: .member(0))?.gearProfile?.stableInstanceID,
                       first.gearProfile?.stableInstanceID)
        XCTAssertEqual(store.worn(.weapon, by: .member(0))?.gearProfile?.reforgeRank, 2)
        XCTAssertEqual(store.worn(.weapon, by: .binder)?.wildGrowth, 1)
    }

    func testCarriedGearIsVisibleButCannotTeleportHome() throws {
        let store = GameStore(io: .temporary(name: "carried-gear-\(UUID().uuidString)"))
        let carried = ItemStack(id: InstanceID(rawValue: 921), catalogID: "guard_padded")
        store.mutate("test: fund") { $0.base.essence = 500 }
        store.write("plains")
        store.bindAndDepart()
        store.mutate("test: active haul") { state in
            _ = state.worlds.activeRun?.satchelItems.add(carried)
        }
        let option = try XCTUnwrap(store.wearableOptions(in: .armor).first { $0.source == .carried(carried.id) })
        XCTAssertFalse(option.canEquipAtHome)
        store.equip(option, on: .binder)
        XCTAssertNil(store.worn(.armor, by: .binder))
        XCTAssertTrue(store.state.worlds.activeRun?.satchelItems.stacks.contains { $0.id == carried.id } == true)
    }

    func testAStaleWornTileCannotMoveItsReplacement() throws {
        let store = GameStore(io: .temporary(name: "stale-worn-\(UUID().uuidString)"))
        let first = ItemStack(id: InstanceID(rawValue: 931), catalogID: "blade_keen")
        let replacement = ItemStack(id: InstanceID(rawValue: 932), catalogID: "blade_chipped")
        store.mutate("test: first worn") { $0.base.roster[0].equipped[.weapon] = EquippedPiece(first) }
        let stale = try XCTUnwrap(store.wearableOptions(in: .weapon, excluding: .binder)
            .first { $0.source == .worn(.member(0)) })
        store.mutate("test: replaced elsewhere") { $0.base.roster[0].equipped[.weapon] = EquippedPiece(replacement) }

        XCTAssertFalse(store.equip(stale, on: .binder))
        XCTAssertNil(store.worn(.weapon, by: .binder))
        XCTAssertEqual(store.worn(.weapon, by: .member(0))?.gearProfile?.stableInstanceID,
                       replacement.gearProfile?.stableInstanceID)
    }

    func testInvalidTargetDoesNotRemoveTheSource() throws {
        let store = GameStore(io: .temporary(name: "invalid-target-\(UUID().uuidString)"))
        let piece = ItemStack(id: InstanceID(rawValue: 941), catalogID: "blade_keen")
        store.mutate("test: stored") { _ = $0.base.inventory.add(piece) }
        let option = try XCTUnwrap(store.wearableOptions(in: .weapon).first)

        XCTAssertFalse(store.equip(option, on: .member(999)))
        XCTAssertTrue(store.state.base.inventory.stacks.contains { $0.id == piece.id })
    }

    func testOverflowEquipKeepsReplacedExactPieceWhenStorehouseIsFull() throws {
        let store = GameStore(io: .temporary(name: "full-overflow-\(UUID().uuidString)"))
        var previous = ItemStack(id: InstanceID(rawValue: 951), catalogID: "guard_vault")
        previous.gearProfile?.reforgeRank = 3
        let incoming = ItemStack(id: InstanceID(rawValue: 952), catalogID: "guard_padded")
        store.mutate("test: full store and overflow") { state in
            state.base.binderEquipped[.armor] = EquippedPiece(previous)
            state.base.inventory = Inventory(slots: 1, stacks: [
                ItemStack(id: InstanceID(rawValue: 953), catalogID: "curio_glass_eye")
            ])
            state.base.spillover = [incoming]
        }
        let option = try XCTUnwrap(store.wearableOptions(in: .armor, excluding: .binder)
            .first { $0.source == .overflow(incoming.id) })

        XCTAssertTrue(store.equip(option, on: .binder))
        XCTAssertEqual(store.worn(.armor, by: .binder)?.gearProfile?.stableInstanceID,
                       incoming.gearProfile?.stableInstanceID)
        let returned = try XCTUnwrap(store.state.base.spillover.first {
            $0.gearProfile?.stableInstanceID == previous.gearProfile?.stableInstanceID
        })
        XCTAssertEqual(returned.gearProfile, previous.gearProfile)
        XCTAssertEqual(returned.gearProfile?.reforgeRank, 3)
    }
}
