import XCTest
@testable import Bookbinder

final class GearMigrationTests: XCTestCase {
    private func legacyState(equippedValue: Any) throws -> GameState {
        let encoded = try SaveCodec.encode(.newGame())
        var root = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        var base = try XCTUnwrap(root["base"] as? [String: Any])
        base["binderEquipped"] = ["weapon": equippedValue]
        root["base"] = base
        return try SaveCodec.decode(JSONSerialization.data(withJSONObject: root))
    }

    func testBareEquippedLegacyPieceReceivesUniqueNonzeroID() throws {
        let state = try legacyState(equippedValue: "blade_keen")
        let profile = try XCTUnwrap(state.base.binderEquipped[.weapon]?.gearProfile)
        XCTAssertNotEqual(profile.stableInstanceID.rawValue, 0)
    }

    func testLegacyStackedGearExpandsIntoUniqueInstancesWithoutLoss() throws {
        let encoded = try SaveCodec.encode(.newGame())
        var root = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        var base = try XCTUnwrap(root["base"] as? [String: Any])
        var inventory = try XCTUnwrap(base["inventory"] as? [String: Any])
        inventory["stacks"] = [[
            "id": ["rawValue": 70], "catalogID": "blade_keen", "count": 3,
            "upgradeLevel": 2
        ]]
        base["inventory"] = inventory
        root["base"] = base

        let state = try SaveCodec.decode(JSONSerialization.data(withJSONObject: root))
        let pieces = state.base.inventory.stacks.filter { $0.catalogID == "blade_keen" }
        XCTAssertEqual(pieces.count, 3)
        XCTAssertEqual(pieces.reduce(0) { $0 + $1.count }, 3)
        XCTAssertEqual(Set(pieces.compactMap { $0.gearProfile?.stableInstanceID }).count, 3)
        XCTAssertTrue(pieces.allSatisfy { $0.effectivePower == 4 })
    }

    func testStoredAndEquippedRoundTripsPreserveStableID() throws {
        var state = GameState.newGame()
        state.base.inventory.add(ItemStack(id: InstanceID(rawValue: 731), catalogID: "blade_keen"))
        let equippedStack = try XCTUnwrap(state.base.inventory.stacks.first)
        state.base.inventory.stacks.removeAll()
        state.base.binderEquipped[.weapon] = EquippedPiece(equippedStack)

        let equippedID = try XCTUnwrap(state.base.binderEquipped[.weapon]?.gearProfile?.stableInstanceID)
        let decoded = try SaveCodec.decode(SaveCodec.encode(state))
        XCTAssertEqual(decoded.base.binderEquipped[.weapon]?.gearProfile?.stableInstanceID, equippedID)

        var storedState = GameState.newGame()
        let stored = ItemStack(id: InstanceID(rawValue: 812), catalogID: "guard_padded")
        storedState.base.inventory.add(stored)
        let storedDecoded = try SaveCodec.decode(SaveCodec.encode(storedState))
        XCTAssertEqual(storedDecoded.base.inventory.stacks.first?.gearProfile?.stableInstanceID,
                       InstanceID(rawValue: 812))
    }

    @MainActor
    func testRepeatedEquipUnequipPreservesStableID() throws {
        let io = SaveFileIO.temporary(name: "gear-identity-\(UUID().uuidString)")
        defer { io.deleteEverything() }
        let store = GameStore(io: io)
        store.mutate("add gear") {
            $0.base.inventory.add(ItemStack(id: InstanceID(rawValue: 901), catalogID: "blade_keen"))
        }

        for _ in 0..<3 {
            let stack = try XCTUnwrap(store.state.base.inventory.stacks.first { $0.catalogID == "blade_keen" })
            store.equip(stack, on: PartyMember.binder)
            XCTAssertEqual(store.worn(.weapon, by: PartyMember.binder)?.gearProfile?.stableInstanceID,
                           InstanceID(rawValue: 901))
            store.unequip(.weapon, from: PartyMember.binder)
            XCTAssertEqual(store.state.base.inventory.stacks.first { $0.catalogID == "blade_keen" }?
                .gearProfile?.stableInstanceID, InstanceID(rawValue: 901))
        }
    }

    func testProfilePreventsLegacyUpgradeFromBeingAddedTwice() throws {
        var stack = ItemStack(id: InstanceID(rawValue: 44), catalogID: "blade_keen")
        stack.upgradeLevel = 5
        let baseline = try XCTUnwrap(stack.gearProfile?.effectivePower)
        XCTAssertEqual(stack.effectivePower, baseline, accuracy: 0.000_001)

        let decoded = try JSONDecoder().decode(ItemStack.self, from: JSONEncoder().encode(stack))
        XCTAssertEqual(decoded.effectivePower, baseline, accuracy: 0.000_001)
    }

    func testLegacyUpgradeMigrationIsLosslessAcrossCatalogueTiers() throws {
        for id in ["blade_chipped", "blade_keen", "the_long_grievance"] as [ItemID] {
            let catalogueTier = try XCTUnwrap(ContentCatalog.shared.item(id)?.gear?.tier)
            for oldUpgrade in 0...5 {
                let object: [String: Any] = [
                    "id": ["rawValue": 100 + oldUpgrade],
                    "catalogID": id.rawValue,
                    "count": 1,
                    "upgradeLevel": oldUpgrade
                ]
                let stack = try JSONDecoder().decode(ItemStack.self,
                    from: JSONSerialization.data(withJSONObject: object))
                let legacyPower = catalogueTier + oldUpgrade
                XCTAssertEqual(stack.gearProfile?.constructionTier, min(4, max(1, legacyPower)))
                XCTAssertEqual(stack.gearProfile?.legacyPowerCredit, max(0, legacyPower - 4))
                XCTAssertEqual(stack.effectivePower, Double(legacyPower), accuracy: 0.000_001)
                XCTAssertNil(stack.gearProfile?.displayProvenance,
                             "migration invented provenance for old gear")
            }
        }
    }

    func testRankOneContributesPointTwoBeforeFinalRounding() throws {
        var weapon = ItemStack(id: InstanceID(rawValue: 51), catalogID: "blade_keen")
        weapon.gearProfile?.reforgeRank = 1
        XCTAssertEqual(weapon.effectivePower,
                       Double(weapon.constructionTier) + 0.2, accuracy: 0.000_001)

        var state = GameState.newGame()
        var armor = ItemStack(id: InstanceID(rawValue: 52), catalogID: "guard_padded")
        armor.gearProfile?.reforgeRank = 1
        var head = ItemStack(id: InstanceID(rawValue: 53), catalogID: "padded_cap")
        head.gearProfile?.reforgeRank = 1
        state.base.binderEquipped[.armor] = EquippedPiece(armor)
        state.base.binderEquipped[.head] = EquippedPiece(head)
        let combined = try XCTUnwrap(state.base.binderEquipped[.armor]?.effectivePower)
            + (try XCTUnwrap(state.base.binderEquipped[.head]?.effectivePower))
        XCTAssertEqual(combined,
                       Double(armor.constructionTier + head.constructionTier) + 0.4,
                       accuracy: 0.000_001)
    }
}
