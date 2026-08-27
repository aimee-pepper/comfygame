import XCTest
@testable import Bookbinder

final class ArmouryTests: XCTestCase {
    private func preparedState(reforge: Int = 0, legacy: Int = 0, essence: Int = 200,
                               tier: Int = 1, grade: Double = 70) throws -> GameState {
        var state = GameState.newGame()
        state.base.stations[Stations.armoury] = StationState(isUnlocked: true, tier: tier)
        state.base.essence = essence
        var gear = ItemStack(id: InstanceID(rawValue: 700), catalogID: "guard_padded")
        gear.gearProfile?.reforgeRank = reforge
        gear.gearProfile?.legacyPowerCredit = legacy
        state.base.inventory.add(gear)
        let samples = [
            CraftMaterialUnitV1(kind: .plate, properties: .init(hardness: 80, density: 70, insulation: 75, flexibility: 60, reactivity: 20), grade: grade, source: "a"),
            CraftMaterialUnitV1(kind: .bone, properties: .init(hardness: 75, density: 65, insulation: 70, flexibility: 60, reactivity: 40), grade: grade, source: "b"),
            CraftMaterialUnitV1(kind: .hide, properties: .init(hardness: 60, density: 60, insulation: 70, flexibility: 65, reactivity: 60), grade: grade, source: "c"),
            CraftMaterialUnitV1(kind: .timber, properties: .init(hardness: 70, density: 60, insulation: 60, flexibility: 60, reactivity: 80), grade: grade, source: "d")
        ]
        for (ordinal, sample) in samples.enumerated() {
            state.base.worldMaterialReserve.add(CraftMaterialHoldingV1(
                id: CraftMaterialUnitID(rawValue: "armoury-fixture-\(ordinal)"),
                sample: sample))
        }
        return state
    }

    func testTierProfileAndConstructionCapMatrix() throws {
        let tierZero = try preparedState(tier: 0)
        let target0 = try XCTUnwrap(ArmouryRules.targets(in: tierZero).first)
        XCTAssertTrue(ArmouryRules.isAvailable(ArmouryRules.rigid, for: target0, in: tierZero))
        XCTAssertFalse(ArmouryRules.isAvailable(ArmouryRules.balanced, for: target0, in: tierZero))

        let tierOne = try preparedState(tier: 1, grade: 90)
        let target1 = try XCTUnwrap(ArmouryRules.targets(in: tierOne).first)
        XCTAssertTrue(ArmouryRules.isAvailable(ArmouryRules.balanced, for: target1, in: tierOne))
        let capped = try XCTUnwrap(ArmouryRules.preview(ArmouryRules.rigid, target: target1, in: tierOne))
        XCTAssertEqual(capped.outputTier, 3)
        XCTAssertEqual(capped.qualityBand, .superior)

        let tierTwo = try preparedState(tier: 2, grade: 90)
        let target2 = try XCTUnwrap(ArmouryRules.targets(in: tierTwo).first)
        XCTAssertEqual(ArmouryRules.preview(ArmouryRules.rigid, target: target2, in: tierTwo)?.outputTier, 4)
        let low = try preparedState(tier: 2, grade: 30)
        let lowTarget = try XCTUnwrap(ArmouryRules.targets(in: low).first)
        XCTAssertTrue(try XCTUnwrap(ArmouryRules.preview(ArmouryRules.rigid, target: lowTarget, in: low)).isBelowSpecialistHeadline)
    }

    func testProfileOffsetsAveragesReceiptAndDisplayIdentitySurviveRebuild() throws {
        var state = try preparedState()
        let index = try XCTUnwrap(state.base.inventory.stacks.firstIndex { $0.id.rawValue == 700 })
        state.base.inventory.stacks[index].gearProfile?.displayProvenance = "Aimee's road coat"
        state.base.inventory.stacks[index].gearProfile?.consumedSamples = [
            CraftMaterialUnitV1(kind: .pelt, properties: .init(), grade: 10, source: "old craft")
        ]
        let target = try XCTUnwrap(ArmouryRules.targets(in: state).first)
        let beforeProvenance = target.gearProfile?.displayProvenance
        let stableID = target.gearProfile?.stableInstanceID
        let preview = try XCTUnwrap(ArmouryRules.preview(ArmouryRules.balanced, target: target, in: state))
        XCTAssertEqual(preview.rebuiltPhysical, 2.5, accuracy: 0.000_001)
        XCTAssertEqual(preview.insulation, 68.75, accuracy: 0.000_001)
        XCTAssertEqual(preview.reactivity, 50, accuracy: 0.000_001)
        XCTAssertTrue(ArmouryRules.rebuild(preview, in: &state))
        let rebuilt = try XCTUnwrap(state.base.inventory.stacks.first { $0.id.rawValue == 700 })
        XCTAssertEqual(rebuilt.gearProfile?.displayProvenance, beforeProvenance)
        XCTAssertTrue(rebuilt.displayName.hasPrefix("Aimee's road coat"))
        XCTAssertEqual(rebuilt.gearProfile?.stableInstanceID, stableID)
        XCTAssertEqual(rebuilt.gearProfile?.consumedSamples.count, 5)
        XCTAssertTrue(state.base.worldMaterialReserve.isEmpty)
        XCTAssertTrue(state.base.inventory.stacks.flatMap(\.materials).isEmpty)
        let roundTrip = try JSONDecoder().decode(GameState.self, from: JSONEncoder().encode(state))
        XCTAssertEqual(roundTrip.base.inventory.stacks.first { $0.id.rawValue == 700 }?.gearProfile,
                       rebuilt.gearProfile)
    }

    func testInsulatedCannotUseOffhandAndUniqueOrWeaponTargetsAreExcluded() throws {
        var state = try preparedState()
        let index = try XCTUnwrap(state.base.inventory.stacks.firstIndex { $0.id.rawValue == 700 })
        state.base.inventory.stacks[index].gearProfile?.slot = .offhand
        let offhand = try XCTUnwrap(ArmouryRules.targets(in: state).first)
        XCTAssertFalse(ArmouryRules.isAvailable(ArmouryRules.insulated, for: offhand, in: state))
        state.base.inventory.stacks[index].gearProfile?.authoredUniqueRuleID = "story"
        XCTAssertTrue(ArmouryRules.targets(in: state, includeLegacy: true).isEmpty)
        var weapon = ItemStack(id: InstanceID(rawValue: 702), catalogID: "blade_rusted")
        weapon.gearProfile?.slot = .weapon
        state.base.inventory.add(weapon)
        XCTAssertFalse(ArmouryRules.targets(in: state, includeLegacy: true).contains { $0.id == "stored-702" })
    }

    func testWornBinderAndTravellerKeepOwnerSlotAndIdentity() throws {
        for travellerWorn in [false, true] {
            var state = try preparedState()
            let stack = try XCTUnwrap(state.base.inventory.stacks.first { $0.id.rawValue == 700 })
            state.base.inventory.stacks.removeAll { $0.id.rawValue == 700 }
            let piece = EquippedPiece(stack)
            if travellerWorn {
                XCTAssertTrue(state.base.seat("mara"))
                let member = try XCTUnwrap(state.base.roster.firstIndex { $0.traveller == "mara" })
                state.base.roster[member].equipped[.armor] = piece
            } else {
                state.base.binderEquipped[.armor] = piece
            }
            let target = try XCTUnwrap(ArmouryRules.targets(in: state).first)
            let id = target.gearProfile?.stableInstanceID
            let preview = try XCTUnwrap(ArmouryRules.preview(ArmouryRules.rigid, target: target, in: state))
            XCTAssertTrue(ArmouryRules.rebuild(preview, in: &state))
            let rebuilt: EquippedPiece? = travellerWorn
                ? state.base.roster.first { $0.traveller == "mara" }?.equipped[.armor]
                : state.base.binderEquipped[.armor]
            XCTAssertEqual(rebuilt?.gearProfile?.stableInstanceID, id)
            XCTAssertEqual(rebuilt?.gearProfile?.slot, .armor)
            let restored = try JSONDecoder().decode(GameState.self, from: JSONEncoder().encode(state))
            XCTAssertEqual(ArmouryRules.targets(in: restored).first?.gearProfile?.stableInstanceID, id)
        }
    }

    func testProtectiveOffsetsRemainFractionalUntilCombinedBoundary() throws {
        var state = try preparedState(tier: 1)
        let target = try XCTUnwrap(ArmouryRules.targets(in: state).first)
        let rigid = try XCTUnwrap(ArmouryRules.preview(ArmouryRules.rigid, target: target, in: state))
        let balanced = try XCTUnwrap(ArmouryRules.preview(ArmouryRules.balanced, target: target, in: state))
        let insulated = try XCTUnwrap(ArmouryRules.preview(ArmouryRules.insulated, target: target, in: state))
        XCTAssertEqual(rigid.rebuiltPhysical, 3.0, accuracy: 0.000_001)
        XCTAssertEqual(balanced.rebuiltPhysical, 2.5, accuracy: 0.000_001)
        XCTAssertEqual(insulated.rebuiltPhysical, 2.0, accuracy: 0.000_001)
        XCTAssertEqual(Int((rigid.rebuiltPhysical + balanced.rebuiltPhysical + insulated.rebuiltPhysical).rounded()), 8)
    }

    func testArmouryLifecycleIsImmediatelyRigidUseful() throws {
        let station = try XCTUnwrap(ContentCatalog.shared.station(Stations.armoury))
        XCTAssertEqual(station.builtBy, "bracken")
        XCTAssertEqual(station.maxTier, 2)
        let state = try preparedState(tier: 0)
        let target = try XCTUnwrap(ArmouryRules.targets(in: state).first)
        XCTAssertTrue(ArmouryRules.isAvailable(ArmouryRules.rigid, for: target, in: state))
        XCTAssertFalse(ArmouryRules.isAvailable(ArmouryRules.balanced, for: target, in: state))
        let restored = try JSONDecoder().decode(GameState.self, from: JSONEncoder().encode(state))
        XCTAssertTrue(ArmouryRules.isAvailable(ArmouryRules.rigid, for: target, in: restored))
    }

    func testOrdinaryReforgeIsVisibleAndRebuildableWithoutLegacyPermission() throws {
        var state = try preparedState(reforge: 1)
        let target = try XCTUnwrap(ArmouryRules.targets(in: state).first)
        XCTAssertTrue(target.hasReforgeWork)
        XCTAssertFalse(target.hasLegacyCredit)
        let preview = try XCTUnwrap(ArmouryRules.preview(ArmouryRules.rigid, target: target, in: state))
        XCTAssertFalse(preview.destroysLegacyWork)
        XCTAssertTrue(ArmouryRules.rebuild(preview, in: &state))
        XCTAssertEqual(state.base.inventory.stacks.first { $0.id.rawValue == 700 }?.gearProfile?.reforgeRank, 0)
    }

    func testLegacyCreditIsHiddenAndRequiresExplicitPermission() throws {
        var state = try preparedState(reforge: 1, legacy: 2)
        XCTAssertFalse(ArmouryRules.targets(in: state).contains { $0.id == "stored-700" })
        let target = try XCTUnwrap(ArmouryRules.targets(in: state, includeLegacy: true).first { $0.id == "stored-700" })
        XCTAssertTrue(target.hasLegacyCredit)
        let preview = try XCTUnwrap(ArmouryRules.preview(ArmouryRules.rigid, target: target,
                                                         includeLegacy: true, in: state))
        XCTAssertTrue(preview.destroysLegacyWork)
        let before = state
        XCTAssertFalse(ArmouryRules.rebuild(preview, in: &state))
        XCTAssertEqual(state, before)
        XCTAssertTrue(ArmouryRules.rebuild(preview, allowLegacyLoss: true, in: &state))
        XCTAssertEqual(state.base.inventory.stacks.first { $0.id.rawValue == 700 }?.gearProfile?.legacyPowerCredit, 0)
    }

    func testInsufficientEssenceAndStalePreviewAreAtomicFailures() throws {
        var poor = try preparedState(essence: 0)
        let target = try XCTUnwrap(ArmouryRules.targets(in: poor).first)
        let preview = try XCTUnwrap(ArmouryRules.preview(ArmouryRules.rigid, target: target, in: poor))
        let before = poor
        XCTAssertFalse(ArmouryRules.rebuild(preview, in: &poor))
        XCTAssertEqual(poor, before)

        var stale = try preparedState()
        let staleTarget = try XCTUnwrap(ArmouryRules.targets(in: stale).first)
        let stalePreview = try XCTUnwrap(ArmouryRules.preview(ArmouryRules.rigid, target: staleTarget, in: stale))
        let removed = try XCTUnwrap(stale.base.worldMaterialReserve.selections().first)
        XCTAssertNotNil(stale.base.worldMaterialReserve.consume([removed]))
        let changed = stale
        XCTAssertFalse(ArmouryRules.rebuild(stalePreview, in: &stale))
        XCTAssertEqual(stale, changed)
    }

    @MainActor func testStoreReportsStaleCommitFailure() throws {
        let store = GameStore(io: .temporary(name: "armoury-stale-\(UUID().uuidString)"))
        let prepared = try preparedState()
        store.mutate("prepare") { $0 = prepared }
        let target = try XCTUnwrap(ArmouryRules.targets(in: store.state).first)
        let preview = try XCTUnwrap(ArmouryRules.preview(ArmouryRules.rigid, target: target, in: store.state))
        store.mutate("stale") {
            guard let removed = $0.base.worldMaterialReserve.selections().first else { return }
            _ = $0.base.worldMaterialReserve.consume([removed])
        }
        XCTAssertFalse(store.rebuildArmoury(preview, allowLegacyLoss: false))
    }

    func testLegacyInventoryMaterialBinCannotEnterArmouryPreviewOrCommit() throws {
        var state = try preparedState()
        let reserveSelections = state.base.worldMaterialReserve.selections()
        XCTAssertEqual(state.base.worldMaterialReserve.consume(reserveSelections),
                       reserveSelections.map(\.sample))
        let samples = reserveSelections.map(\.sample)
        state.base.inventory.add(ItemStack(id: InstanceID(rawValue: 701),
                                           catalogID: Items.material,
                                           materials: samples))
        let target = try XCTUnwrap(ArmouryRules.targets(in: state).first)

        XCTAssertNil(ArmouryRules.preview(ArmouryRules.rigid, target: target, in: state))
        XCTAssertTrue(ArmouryRules.candidates(
            for: ArmouryRules.rigid.requirements[0], in: state).isEmpty)
    }

    func testReserveReorderingDoesNotInvalidateStableArmourySelections() throws {
        var state = try preparedState()
        let target = try XCTUnwrap(ArmouryRules.targets(in: state).first)
        let preview = try XCTUnwrap(
            ArmouryRules.preview(ArmouryRules.rigid, target: target, in: state))
        state.base.worldMaterialReserve = WorldMaterialReserve(
            units: Array(state.base.worldMaterialReserve.units.reversed()))

        XCTAssertTrue(ArmouryRules.rebuild(preview, in: &state))
        XCTAssertTrue(state.base.worldMaterialReserve.isEmpty)
        XCTAssertEqual(state.base.inventory.stacks.count, 1)
    }
}
