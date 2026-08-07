import XCTest
@testable import Bookbinder

/// Session 12: gear is found rather than researched, and rules are edited in place.
@MainActor
final class GearAndRulesTests: XCTestCase {

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
        store.equip(blade, on: PartyMember.companion)

        let tier = ContentCatalog.shared.item("blade_keen")?.gear?.tier
        XCTAssertEqual(store.state.base.companion.weaponTier, tier)

        store.unequip(.weapon, from: PartyMember.companion)
        XCTAssertEqual(store.state.base.companion.weaponTier, 0, "taking it off left the tier behind")
    }

    func testWearingSomethingActuallyHitsHarder() {
        let store = GameStore(io: .temporary(name: "gear-\(UUID().uuidString)"))
        let bare = CombatRules.companionAttack(in: store.state)

        let blade = ItemStack(id: InstanceID(rawValue: 1), catalogID: "blade_binders")
        store.mutate("test: haul it home") { $0.base.inventory.add(blade) }
        store.equip(blade, on: PartyMember.companion)

        XCTAssertGreaterThan(CombatRules.companionAttack(in: store.state), bare)
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
        store.setSymbol("plains", in: "terrain")

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
        guard let rule = store.gambits(for: .companion).first else { return XCTFail("no starting rules") }
        guard let other = store.ownedComponents(.action).first(where: { $0.id != rule.action })
        else { throw XCTSkip("only one action known") }

        store.setGambitPart(rule.id, kind: .action, to: other.id)
        let updated = store.gambits(for: .companion).first
        XCTAssertEqual(updated?.action, other.id)
        XCTAssertEqual(updated?.id, rule.id, "editing a part replaced the whole rule")
        XCTAssertEqual(updated?.subject, rule.subject, "editing one part changed another")
    }

    func testAConditionCanBeClearedBackToUnconditional() {
        let store = GameStore(io: .temporary(name: "rules-\(UUID().uuidString)"))
        guard let rule = store.gambits(for: .companion).first(where: { $0.hasCondition })
        else { return XCTFail("no conditional starting rule") }

        store.setGambitPart(rule.id, kind: .property, to: nil)
        XCTAssertFalse(store.gambits(for: .companion).first { $0.id == rule.id }?.hasCondition ?? true)
    }

    func testSwitchingARuleOffKeepsItButStopsItFiring() {
        let store = GameStore(io: .temporary(name: "rules-\(UUID().uuidString)"))
        guard let rule = store.gambits(for: .companion).first else { return XCTFail("no rules") }
        let countBefore = store.gambits(for: .companion).count

        store.setGambitEnabled(rule.id, false)
        let after = store.gambits(for: .companion)
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
        guard let rule = store.gambits(for: .companion).first else { return XCTFail("no rules") }

        // With it on, it's a candidate; with it off, it isn't.
        state.base.companion.gambits = [rule]
        let live = GambitEngine.rules(for: .companion, in: state).filter(\.isEnabled)
        XCTAssertEqual(live.count, 1)

        state.base.companion.gambits[0].isEnabled = false
        XCTAssertTrue(GambitEngine.rules(for: .companion, in: state).filter(\.isEnabled).isEmpty)
    }

    func testARuleSurvivesAForceQuitWithItsSwitchPosition() throws {
        let io = SaveFileIO.temporary(name: "rules-\(UUID().uuidString)")
        defer { io.deleteEverything() }
        var ruleID: InstanceID?
        do {
            let store = GameStore(io: io)
            guard let rule = store.gambits(for: .companion).first else { return XCTFail("no rules") }
            ruleID = rule.id
            store.setGambitEnabled(rule.id, false)
            store.flushNow()
        }
        let resumed = GameStore(io: io)
        XCTAssertEqual(resumed.gambits(for: .companion).first { $0.id == ruleID }?.isEnabled, false)
    }

    // MARK: Is it an improvement?

    /// The question the player actually has is "is this better?", and a tier number only answers it
    /// if you already know the formula. The badge answers it in the units the fight uses.
    func testTheDeltaIsStatedInFightUnitsNotTiers() throws {
        let store = GameStore(io: .temporary(name: "delta-\(UUID().uuidString)"))
        let chipped = try XCTUnwrap(ContentCatalog.shared.item("blade_chipped"))
        let binders = try XCTUnwrap(ContentCatalog.shared.item("blade_binders"))

        // Nothing worn: the delta is the whole of what it gives.
        XCTAssertEqual(store.gearDelta(wearing: chipped, for: PartyMember.companion),
                       (chipped.gear?.tier ?? 0) * Tuning.Encounter.attackPerWeaponTier)

        store.mutate("test: haul it home") { $0.base.inventory.add(
            ItemStack(id: InstanceID(rawValue: 1), catalogID: chipped.id)) }
        store.equip(ItemStack(id: InstanceID(rawValue: 1), catalogID: chipped.id), on: PartyMember.companion)

        // Against something worn, it's the difference — and it matches what combat will actually do.
        let promised = store.gearDelta(wearing: binders, for: PartyMember.companion)
        let before = CombatRules.companionAttack(in: store.state)
        store.mutate("test: haul the better one home") { $0.base.inventory.add(
            ItemStack(id: InstanceID(rawValue: 2), catalogID: binders.id)) }
        store.equip(ItemStack(id: InstanceID(rawValue: 2), catalogID: binders.id), on: PartyMember.companion)

        XCTAssertEqual(CombatRules.companionAttack(in: store.state) - before, promised,
                       "the badge promised a number the fight didn't deliver")
    }

    func testAWorsePieceReadsAsWorse() throws {
        let store = GameStore(io: .temporary(name: "delta-\(UUID().uuidString)"))
        let good = try XCTUnwrap(ContentCatalog.shared.item("guard_vault"))
        let poor = try XCTUnwrap(ContentCatalog.shared.item("guard_padded"))
        store.mutate("test: haul it home") { $0.base.inventory.add(
            ItemStack(id: InstanceID(rawValue: 1), catalogID: good.id)) }
        store.equip(ItemStack(id: InstanceID(rawValue: 1), catalogID: good.id), on: PartyMember.companion)
        XCTAssertLessThan(store.gearDelta(wearing: poor, for: PartyMember.companion), 0)
    }

    func testTheUpgradeNudgeOnlyFiresWhenSomethingIsActuallyBetter() throws {
        let store = GameStore(io: .temporary(name: "nudge-\(UUID().uuidString)"))
        XCTAssertFalse(store.hasUpgradeAvailable(for: .weapon, member: PartyMember.companion), "nudged with an empty storehouse")

        let best = try XCTUnwrap(ContentCatalog.shared.item("blade_binders"))
        store.mutate("test: haul it home") { $0.base.inventory.add(
            ItemStack(id: InstanceID(rawValue: 1), catalogID: best.id)) }
        XCTAssertTrue(store.hasUpgradeAvailable(for: .weapon, member: PartyMember.companion))

        store.equip(ItemStack(id: InstanceID(rawValue: 1), catalogID: best.id), on: PartyMember.companion)
        XCTAssertFalse(store.hasUpgradeAvailable(for: .weapon, member: PartyMember.companion),
                       "still nudging about the thing already worn")
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
        XCTAssertEqual(reloaded.base.companion.equipped[.weapon], "blade_keen")
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
        store.equip(ItemStack(id: InstanceID(rawValue: 2), catalogID: "blade_chipped"), on: PartyMember.companion)

        XCTAssertEqual(CombatRules.damageKind(for: .binder, in: store.state), .pierce)
        XCTAssertEqual(CombatRules.damageKind(for: .companion, in: store.state), .rend)
    }

    /// **If you have four, you can wear four.**
    ///
    /// Aimee, 6 Aug: *"in storage it shows I have 4 padded guards and two chipped blades but when I
    /// go to equip my character with those items it unequips them from my companion."* Equipping
    /// used to claim a piece by catalogue id, so a storehouse holding four of a thing could still
    /// only dress one person. Equipping now takes **an instance out of the bin**.
    @MainActor
    func testAFullBinCanDressBothOfThem() throws {
        let store = GameStore(io: .temporary(name: "bin-\(UUID().uuidString)"))
        store.mutate("haul four home") { state in
            state.base.inventory.add(ItemStack(id: InstanceID(rawValue: 1),
                                               catalogID: "guard_padded", count: 4))
        }

        let bin = try XCTUnwrap(store.state.base.inventory.stacks.first)
        store.equip(bin, on: PartyMember.binder)
        let after = try XCTUnwrap(store.state.base.inventory.stacks.first)
        store.equip(after, on: PartyMember.companion)

        XCTAssertEqual(store.worn(.armor, by: PartyMember.binder), "guard_padded")
        XCTAssertEqual(store.worn(.armor, by: PartyMember.companion), "guard_padded",
                       "dressing one of them stripped the other")
        XCTAssertEqual(store.state.base.inventory.stacks.first?.count, 2,
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
        XCTAssertEqual(store.worn(.weapon, by: PartyMember.binder), "blade_keen")

        store.equip(stack, on: PartyMember.companion)
        XCTAssertNil(store.worn(.weapon, by: PartyMember.companion), "dressed them from an empty shelf")
        XCTAssertEqual(store.worn(.weapon, by: PartyMember.binder), "blade_keen",
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

}
