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
            CraftMaterialUnitV1(kind: .ore, properties: .init(hardness: 80), grade: grade, source: "ore body"),
            CraftMaterialUnitV1(kind: .copper, properties: .init(hardness: 75), grade: grade, source: "copper body"),
            CraftMaterialUnitV1(kind: .fibre, properties: .init(insulation: 70, flexibility: 70), grade: grade, source: "fiber lining"),
            CraftMaterialUnitV1(kind: .resin, properties: .init(flexibility: 60), grade: grade, source: "resin binding"),
            CraftMaterialUnitV1(kind: .quartz, properties: .init(lustre: 70), grade: grade, source: "quartz fitting"),
            CraftMaterialUnitV1(kind: .hide, properties: .init(insulation: 75, flexibility: 70), grade: grade, source: "hide lining"),
            CraftMaterialUnitV1(kind: .pelt, properties: .init(insulation: 80, flexibility: 70), grade: grade, source: "pelt lining"),
            CraftMaterialUnitV1(kind: .plate, properties: .init(hardness: 80), grade: grade, source: "plate body")
        ].enumerated().map {
            $0.element.withStableID(.init(rawValue: "armoury-fixture-\($0.offset)"))
        }
        for sample in samples {
            let holding = CraftMaterialHoldingV1(unit: sample, protectedReturn: false)
            if sample.domain == .world { state.base.worldMaterialReserve.add(holding) }
            else { state.base.creatureMaterialReserve.add(holding) }
        }
        return state
    }

    func testTierProfileAndUncappedQualityMatrix() throws {
        let tierZero = try preparedState(tier: 0)
        let target0 = try XCTUnwrap(ArmouryRules.targets(in: tierZero).first)
        XCTAssertTrue(ArmouryRules.isAvailable(ArmouryRules.rigid, for: target0, in: tierZero))
        XCTAssertFalse(ArmouryRules.isAvailable(ArmouryRules.balanced, for: target0, in: tierZero))

        let tierOne = try preparedState(tier: 1, grade: 90)
        let target1 = try XCTUnwrap(ArmouryRules.targets(in: tierOne).first)
        XCTAssertTrue(ArmouryRules.isAvailable(ArmouryRules.balanced, for: target1, in: tierOne))
        let uncapped = try XCTUnwrap(ArmouryRules.preview(ArmouryRules.rigid, target: target1, in: tierOne))
        XCTAssertEqual(uncapped.outputTier, 5)
        XCTAssertEqual(uncapped.qualityBand, .peerless)

        let tierTwo = try preparedState(tier: 2, grade: 90)
        let target2 = try XCTUnwrap(ArmouryRules.targets(in: tierTwo).first)
        XCTAssertEqual(ArmouryRules.preview(ArmouryRules.rigid, target: target2, in: tierTwo)?.outputTier, 5)
        let low = try preparedState(tier: 2, grade: 30)
        let lowTarget = try XCTUnwrap(ArmouryRules.targets(in: low).first)
        XCTAssertTrue(try XCTUnwrap(ArmouryRules.preview(ArmouryRules.rigid, target: lowTarget, in: low)).isBelowSpecialistHeadline)
    }

    func testRebuildFreezesPeerlessQualityAndTierThroughRelaunchAndReceipt() throws {
        var state = try preparedState(tier: 1, grade: 100)
        let target = try XCTUnwrap(ArmouryRules.targets(in: state).first)
        let preview = try XCTUnwrap(ArmouryRules.preview(ArmouryRules.rigid,
                                                        target: target, in: state))
        XCTAssertEqual(preview.qualityBand, .peerless)
        XCTAssertEqual(preview.outputTier, 5)
        XCTAssertTrue(ArmouryRules.rebuild(preview, in: &state))
        let rebuilt = try XCTUnwrap(state.base.inventory.stacks.first { $0.id.rawValue == 700 })
        XCTAssertEqual(rebuilt.gearProfile?.qualityBand, .peerless)
        XCTAssertEqual(rebuilt.gearProfile?.constructionTier, 5)
        XCTAssertEqual(rebuilt.gearProfile?.physicalReceipt?.revisions.last?.resultingQualityBand,
                       .peerless)
        XCTAssertEqual(rebuilt.gearProfile?.physicalReceipt?.revisions.last?.resultingConstructionTier,
                       5)
        let decoded = try SaveCodec.makeDecoder().decode(
            GameState.self, from: SaveCodec.makeEncoder().encode(state))
        let relaunched = try XCTUnwrap(decoded.base.inventory.stacks.first { $0.id.rawValue == 700 })
        XCTAssertEqual(relaunched.gearProfile, rebuilt.gearProfile)
        XCTAssertEqual(relaunched.gearProfile?.physicalReceipt?.flattenedUnits,
                       rebuilt.gearProfile?.physicalReceipt?.flattenedUnits)
        let recycler = try XCTUnwrap(RecyclerRules.preview(
            location: .stored, stackID: relaunched.id, serviceTier: 1, in: decoded.base))
        XCTAssertEqual(recycler.route, .constructionReceipt)
        XCTAssertEqual(recycler.returnedSamples,
                       Array(rebuilt.gearProfile!.physicalReceipt!.flattenedUnits.prefix(1)))
    }

    func testProfileOffsetsAveragesReceiptAndDisplayIdentitySurviveRebuild() throws {
        var state = try preparedState()
        let index = try XCTUnwrap(state.base.inventory.stacks.firstIndex { $0.id.rawValue == 700 })
        state.base.inventory.stacks[index].gearProfile?.displayProvenance = "Aimee's road coat"
        let inscription = EquipmentInscriptionReceiptV1(
            version: 1, definitionID: "future_starlace", sourceItemID: "future_source",
            rulesVersion: 7, inkRecipe: nil)
        state.base.inventory.stacks[index].gearProfile?.inscription = inscription
        state.base.inventory.stacks[index].isFavorite = true
        state.base.inventory.stacks[index].isLocked = true
        state.base.inventory.stacks[index].gearProfile?.consumedSamples = [
            CraftMaterialUnitV1(kind: .pelt, properties: .init(), grade: 10, source: "old craft")
        ]
        let target = try XCTUnwrap(ArmouryRules.targets(in: state).first)
        let beforeProvenance = target.gearProfile?.displayProvenance
        let stableID = target.gearProfile?.stableInstanceID
        let preview = try XCTUnwrap(ArmouryRules.preview(ArmouryRules.balanced, target: target, in: state))
        XCTAssertEqual(preview.rebuiltPhysical, 3, accuracy: 0.000_001)
        XCTAssertTrue(ArmouryRules.rebuild(preview, in: &state))
        let rebuilt = try XCTUnwrap(state.base.inventory.stacks.first { $0.id.rawValue == 700 })
        XCTAssertEqual(rebuilt.gearProfile?.displayProvenance, beforeProvenance)
        XCTAssertEqual(rebuilt.gearProfile?.inscription, inscription)
        XCTAssertTrue(rebuilt.isFavorite)
        XCTAssertTrue(rebuilt.isLocked)
        XCTAssertTrue(rebuilt.displayName.hasPrefix("Aimee's road coat"))
        XCTAssertEqual(rebuilt.gearProfile?.stableInstanceID, stableID)
        XCTAssertEqual(rebuilt.gearProfile?.consumedSamples.count, 5)
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

    func testCanonicalProfilesSocketsOffsetsAndCrossDomainRefusals() {
        XCTAssertEqual(ArmouryRules.profiles.map(\.id),
                       ["armoury_rigid_shell", "armoury_insulated_layer",
                        "armoury_balanced_laminate"])
        XCTAssertEqual(ArmouryRules.profiles.map(\.physicalOffset), [0.5, -0.5, 0])
        XCTAssertEqual(ArmouryRules.rigid.requirements.map(\.id),
                       ["body.0", "body.1", "binding.0"])
        XCTAssertEqual(ArmouryRules.insulated.requirements.map(\.id),
                       ["lining.0", "lining.1", "outer.0"])
        XCTAssertEqual(ArmouryRules.balanced.requirements.map(\.id),
                       ["body.0", "lining.0", "binding.0", "fitting.0"])

        var creatureOre = CraftMaterialUnitV1(kind: .ore, properties: .init(), grade: 50,
                                               source: "forged creature ore")
        creatureOre.domain = .creature
        XCTAssertFalse(PhysicalGearCraftingRules.qualifies(
            creatureOre, for: ArmouryRules.rigid.requirements[0]))
        var worldHide = CraftMaterialUnitV1(kind: .hide, properties: .init(), grade: 50,
                                            source: "forged world hide")
        worldHide.domain = .world
        XCTAssertFalse(PhysicalGearCraftingRules.qualifies(
            worldHide, for: ArmouryRules.insulated.requirements[0]))
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
        XCTAssertEqual(rigid.rebuiltPhysical, 3.5, accuracy: 0.000_001)
        XCTAssertEqual(balanced.rebuiltPhysical, 3, accuracy: 0.000_001)
        XCTAssertEqual(insulated.rebuiltPhysical, 2.5, accuracy: 0.000_001)
        XCTAssertEqual(Int((rigid.rebuiltPhysical + balanced.rebuiltPhysical + insulated.rebuiltPhysical).rounded()), 9)
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
        let world = state.base.worldMaterialReserve.selections()
        let creature = state.base.creatureMaterialReserve.selections()
        XCTAssertEqual(state.base.worldMaterialReserve.consume(world), world.map(\.sample))
        XCTAssertEqual(state.base.creatureMaterialReserve.consume(creature), creature.map(\.sample))
        let samples = (world + creature).map(\.sample)
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
        XCTAssertEqual(state.base.inventory.stacks.count, 1)
    }
}
