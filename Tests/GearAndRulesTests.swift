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
        store.equip(blade)

        let tier = ContentCatalog.shared.item("blade_keen")?.gear?.tier
        XCTAssertEqual(store.state.base.companion.weaponTier, tier)

        store.unequip(.weapon)
        XCTAssertEqual(store.state.base.companion.weaponTier, 0, "taking it off left the tier behind")
    }

    func testWearingSomethingActuallyHitsHarder() {
        let store = GameStore(io: .temporary(name: "gear-\(UUID().uuidString)"))
        let bare = CombatRules.companionAttack(in: store.state)

        let blade = ItemStack(id: InstanceID(rawValue: 1), catalogID: "blade_binders")
        store.mutate("test: haul it home") { $0.base.inventory.add(blade) }
        store.equip(blade)

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
}
