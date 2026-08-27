import XCTest
@testable import Bookbinder

final class StationStaffingTests: XCTestCase {
    private func stateWithHalloway(level: Int = 1) throws -> (GameState, Int, StationDef) {
        var state = GameState.newGame()
        XCTAssertTrue(state.base.seat("halloway"))
        let index = try XCTUnwrap(state.base.roster.firstIndex { $0.traveller == "halloway" })
        state.base.roster[index].character.level = level
        let memberID = try XCTUnwrap(state.base.persistentID(forRosterIndex: index))
        state.base.activeParty.removeAll { $0 == memberID }
        let station = try XCTUnwrap(ContentCatalog.shared.station(Stations.blacksmith))
        return (state, index, station)
    }

    func testEffectiveTierUsesMaxNeverSumAndCapsAtStationMaximum() throws {
        var (state, index, station) = try stateWithHalloway(level: 24)
        state.base.stations[station.id] = StationState(isUnlocked: true, tier: 1)
        XCTAssertEqual(StationStaffingRules.keeperEarnedTier(for: station, in: state), 3)
        XCTAssertEqual(StationStaffingRules.effectiveTier(for: station, in: state), station.maxTier)
        state.base.roster[index].character.level = 1
        XCTAssertEqual(StationStaffingRules.effectiveTier(for: station, in: state), 1)
    }

    func testOnlyCorrectOwnerAtHomeDiscountsAndRoundsUp() throws {
        var (state, _, station) = try stateWithHalloway(level: 1)
        XCTAssertEqual(StationStaffingRules.homeDiscountRate(for: station, in: state), 0.10,
                       accuracy: 0.000_001)
        XCTAssertEqual(StationStaffingRules.discounted(12, at: station, in: state), 11)
        XCTAssertEqual(StationStaffingRules.discounted(1, at: station, in: state), 1)
        let firepit = try XCTUnwrap(ContentCatalog.shared.station(Stations.firepit))
        XCTAssertEqual(StationStaffingRules.homeDiscountRate(for: firepit, in: state), 0)

        XCTAssertTrue(state.base.seat("mara"))
        XCTAssertEqual(StationStaffingRules.homeDiscountRate(for: station, in: state), 0.10,
                       "A non-owner at Home must not alter the owner's discount")
    }

    func testKeeperTierAndDiscountSurviveSaveLoadWithoutDuplicatingPurchasedTier() throws {
        var (state, _, station) = try stateWithHalloway(level: 12)
        state.base.stations[station.id] = StationState(isUnlocked: true, tier: 1)
        let beforeTier = StationStaffingRules.effectiveTier(for: station, in: state)
        let beforeDiscount = StationStaffingRules.homeDiscountRate(for: station, in: state)
        let data = try JSONEncoder().encode(state)
        let restored = try JSONDecoder().decode(GameState.self, from: data)
        XCTAssertEqual(StationStaffingRules.effectiveTier(for: station, in: restored), beforeTier)
        XCTAssertEqual(StationStaffingRules.effectiveTier(for: station, in: restored),
                       max(1, StationStaffingRules.keeperEarnedTier(for: station, in: restored)))
        XCTAssertEqual(StationStaffingRules.homeDiscountRate(for: station, in: restored),
                       beforeDiscount, accuracy: 0.000_001)
    }

    func testDiscountAppliesToOrdinaryResourceQuantitiesWithPositiveMinimum() throws {
        let (state, _, station) = try stateWithHalloway(level: 1)
        XCTAssertEqual(StationStaffingRules.discounted(6, at: station, in: state), 6)
        XCTAssertEqual(StationStaffingRules.discounted(10, at: station, in: state), 9)
        XCTAssertEqual(StationStaffingRules.discounted(1, at: station, in: state), 1)
    }

    func testTanneryContentIsOwnedByCorrinWithAuthoredBuildCost() throws {
        let station = try XCTUnwrap(ContentCatalog.shared.station(Stations.tannery))
        XCTAssertEqual(station.builtBy, "corrin")
        XCTAssertEqual(station.route, "tannery")
        XCTAssertEqual(station.buildCost?.essence, 80)
        XCTAssertEqual(station.buildCost?.resources["timber"], 12)
        XCTAssertEqual(station.buildCost?.resources["fiber"], 20)
        XCTAssertEqual(station.buildCost?.resources["salt"], 8)
    }

    func testBowyerContentHasFenLifecycleAndExactBuildCost() throws {
        let station = try XCTUnwrap(ContentCatalog.shared.station(Stations.bowyer))
        XCTAssertEqual(station.builtBy, "fen")
        XCTAssertEqual(station.route, "bowyer")
        XCTAssertEqual(station.maxTier, 2)
        XCTAssertEqual(station.buildCost?.essence, 110)
        XCTAssertEqual(station.buildCost?.resources["timber"], 24)
        XCTAssertEqual(station.buildCost?.resources["fiber"], 18)
        XCTAssertEqual(station.buildCost?.resources["resin"], 8)
    }

    func testStationOwnedResearchDiscountsEssenceAndEveryOrdinaryResource() throws {
        var state = GameState.newGame()
        XCTAssertTrue(state.base.seat("corrin"))
        let index = try XCTUnwrap(state.base.roster.firstIndex { $0.traveller == "corrin" })
        let memberID = try XCTUnwrap(state.base.persistentID(forRosterIndex: index))
        state.base.activeParty.removeAll { $0 == memberID }
        state.base.stations[Stations.tannery] = StationState(isUnlocked: true, tier: 0)
        let node = try XCTUnwrap(ContentCatalog.shared.researchNode("tannery_wear_tier_two"))
        let paid = EconomyRules.paidCost(for: node, in: state)
        XCTAssertEqual(paid.essence, 26)
        XCTAssertEqual(paid.resources["fiber"], 9)
        XCTAssertEqual(paid.resources["salt"], 4)
    }

    @MainActor func testBuildingTanneryImmediatelyGrantsWearButNotPaidProgression() throws {
        let store = GameStore(io: .temporary(name: "tannery-build-\(UUID().uuidString)"))
        let station = try XCTUnwrap(ContentCatalog.shared.station(Stations.tannery))
        store.mutate("prepare Corrin build") { state in
            state.reality.library.foundTravellers.insert("corrin")
            state.base.essence = station.buildCost?.essence ?? 0
            for (id, amount) in station.buildCost?.resources ?? [:] {
                state.base.resources.add(amount, of: id)
            }
        }
        XCTAssertTrue(store.build(station))
        XCTAssertTrue(store.state.base.completedResearch.contains(
            PhysicalGearCraftingRules.tanneryWearRoot))
        XCTAssertTrue(store.state.base.hasCapability(
            PhysicalGearCraftingRules.tanneryWearCapability))
        XCTAssertFalse(store.state.base.completedResearch.contains(
            PhysicalGearCraftingRules.tanneryWearTierTwo))
        XCTAssertFalse(store.state.base.completedResearch.contains("tannery_carry_root"))
        XCTAssertFalse(store.state.base.completedResearch.contains("tannery_keep_root"))
        XCTAssertFalse(store.state.base.hasCapability("tannery_tier_two"))
        XCTAssertFalse(store.state.base.hasCapability("tannery_carry"))
        XCTAssertFalse(store.state.base.hasCapability("tannery_keep"))
    }

    func testAlreadyBuiltTanneryInfersFreeWearRootOnLoad() throws {
        var state = GameState.newGame()
        state.base.stations[Stations.tannery] = StationState(isUnlocked: true, tier: 0)
        state.base.completedResearch.remove(PhysicalGearCraftingRules.tanneryWearRoot)
        let restored = try JSONDecoder().decode(GameState.self, from: JSONEncoder().encode(state))
        XCTAssertTrue(restored.base.completedResearch.contains(
            PhysicalGearCraftingRules.tanneryWearRoot))
        XCTAssertTrue(restored.base.hasCapability(
            PhysicalGearCraftingRules.tanneryWearCapability))
    }

    @MainActor func testFailedTanneryBuildGrantsNeitherCompletionNorCapability() throws {
        let store = GameStore(io: .temporary(name: "tannery-atomic-\(UUID().uuidString)"))
        let station = try XCTUnwrap(ContentCatalog.shared.station(Stations.tannery))
        store.mutate("find Corrin without stock") {
            $0.reality.library.foundTravellers.insert("corrin")
            $0.base.essence = 0
        }
        XCTAssertFalse(store.build(station))
        XCTAssertFalse(store.state.base.completedResearch.contains(
            PhysicalGearCraftingRules.tanneryWearRoot))
        XCTAssertFalse(store.state.base.hasCapability(
            PhysicalGearCraftingRules.tanneryWearCapability))
    }

    func testPartyAndRealmAssignmentsRemoveHomeDiscountImmediately() throws {
        var (state, index, station) = try stateWithHalloway(level: 20)
        let memberID = try XCTUnwrap(state.base.persistentID(forRosterIndex: index))
        XCTAssertGreaterThan(StationStaffingRules.homeDiscountRate(for: station, in: state), 0)
        state.base.activeParty.append(memberID)
        XCTAssertEqual(StationStaffingRules.homeDiscountRate(for: station, in: state), 0)
        state.base.activeParty.removeAll { $0 == memberID }

        let generated = Worldgen.generate(book: BoundBook(symbols: [:], randomlyFilled: [], essencePaid: 0),
                                          seed: 42)
        let run = WorldRun(runIndex: 1, book: BoundBook(symbols: [:], randomlyFilled: [], essencePaid: 0),
                           mapSeed: 42, rng: SeededRNG(seed: 42), map: generated.map,
                           playerPosition: generated.start)
        state.worlds.anchoredRealms = [AnchoredRealm(runIndex: 1, name: "Test", route: .craftedFrame,
                                                     sustainObligation: 0,
                                                     assignedCompanions: [memberID], world: run)]
        XCTAssertEqual(StationStaffingRules.homeDiscountRate(for: station, in: state), 0)
    }

    func testCraftPreviewAndDebitUseSameDiscountedEssence() throws {
        var (state, _, _) = try stateWithHalloway(level: 1)
        state.base.stations[Stations.blacksmith] = StationState(isUnlocked: true, tier: 0)
        state.base.essence = 11
        let samples = [
            CraftMaterialUnitV1(kind: .bone,
                           properties: MaterialProperties(hardness: 40), grade: 30, source: "one"),
            CraftMaterialUnitV1(kind: .fibre,
                           properties: MaterialProperties(flexibility: 35), grade: 30, source: "two")
        ]
        state.base.inventory.add(ItemStack(id: InstanceID(rawValue: 90), catalogID: Items.material,
                                           materials: samples))
        let preview = try XCTUnwrap(PhysicalGearCraftingRules.preview(
            PhysicalGearCraftingRules.pointedBlade, in: state))
        XCTAssertEqual(preview.rawEssence, 12)
        XCTAssertEqual(preview.essence, 11)
        guard case .ready = PhysicalGearCraftingRules.readiness(
            PhysicalGearCraftingRules.pointedBlade, in: state) else { return XCTFail("discount ignored") }
        XCTAssertNotNil(PhysicalGearCraftingRules.craft(preview, in: &state))
        XCTAssertEqual(state.base.essence, 0)
    }

    @MainActor func testEarnedTierSatisfiesResearchGateAndSkipsRedundantPaidRung() throws {
        let store = GameStore(io: .temporary(name: "earned-tier-\(UUID().uuidString)"))
        store.mutate("prepare Fen") { state in
            XCTAssertTrue(state.base.seat("fen"))
            let index = state.base.roster.firstIndex { $0.traveller == "fen" }!
            state.base.roster[index].character.level = 8
            let memberID = state.base.persistentID(forRosterIndex: index)!
            state.base.activeParty.removeAll { $0 == memberID }
            state.base.stations[Stations.bowyer] = StationState(isUnlocked: true, tier: 0)
            state.base.essence = 1_000
            state.base.resources.add(100, of: "timber")
            state.base.resources.add(100, of: "fiber")
            state.base.resources.add(100, of: "resin")
        }
        let tierOne = try XCTUnwrap(ContentCatalog.shared.researchNode("bowyer_broaden"))
        let tierTwo = try XCTUnwrap(ContentCatalog.shared.researchNode("bowyer_masterwork"))
        XCTAssertTrue(EconomyRules.prerequisiteSatisfied(tierOne.id, in: store.state))
        XCTAssertTrue(store.isSuppliedByKeeper(tierOne))
        XCTAssertTrue(store.isAvailable(tierTwo))
        let branch = try XCTUnwrap(ContentCatalog.shared.researchBranch(tierOne.branch))
        XCTAssertEqual(store.progress(in: branch).done, 1)
        let before = store.state.base.essence
        let paid = EconomyRules.paidCost(for: tierTwo, in: store.state)
        XCTAssertTrue(store.research(tierTwo))
        XCTAssertEqual(store.state.base.essence, before - paid.essence)
        XCTAssertFalse(store.state.base.completedResearch.contains(tierOne.id))
        XCTAssertEqual(store.state.base.station(Stations.bowyer).tier, 2)
    }
}
