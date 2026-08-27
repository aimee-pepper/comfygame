import XCTest
@testable import Bookbinder

final class GearMigrationTests: XCTestCase {
    func testGearCatalogueDispositionHasExactClosedPartitionAndRoutes() throws {
        let gear = ContentCatalog.shared.items.filter { $0.kind == .gear }
        XCTAssertEqual(gear.count, 75)
        let grouped = Dictionary(grouping: gear) { $0.gearCatalogueDisposition?.classification }
        XCTAssertEqual(grouped[.some(.ordinaryFound)]?.count, 44)
        XCTAssertEqual(grouped[.some(.wildApexOnly)]?.count, 8)
        XCTAssertEqual(grouped[.some(.componentAuthoredFound)]?.count, 12)
        XCTAssertEqual(grouped[.some(.decodeOnly)]?.count, 11)
        XCTAssertEqual(gear.compactMap { $0.gearCatalogueDisposition?.foundReceipt }.count, 12)

        for item in gear {
            let classID = try XCTUnwrap(item.gearCatalogueDisposition?.classification)
            switch classID {
            case .decodeOnly:
                XCTAssertEqual(GearCatalogueDispositionRules.evaluate(item.id, route: .territoryFind),
                               .ineligible(.decodeOnly))
            case .wildApexOnly:
                guard case .eligible = GearCatalogueDispositionRules.evaluate(item.id, route: .apexReward)
                else { return XCTFail("apex route refused \(item.id)") }
                XCTAssertEqual(GearCatalogueDispositionRules.evaluate(item.id, route: .territoryFind),
                               .ineligible(.apexOnly))
            case .ordinaryFound:
                guard case .eligible = GearCatalogueDispositionRules.evaluate(item.id, route: .territoryFind)
                else { return XCTFail("ordinary route refused \(item.id)") }
            case .componentAuthoredFound:
                XCTAssertNotNil(item.gearCatalogueDisposition?.foundReceipt)
            }
        }
    }

    func testAllAuthoredFoundReceiptsHaveExactFrozenOrderedFields() throws {
        let expected: [ItemID: String] = [
            "rubble_sling": "schematic|sling|-|-|1|cord:world:fiber:1,projectile:world:rubble:1,pouch:creature:hide:1",
            "ironwork_blade": "schematic|cutting_blade|-|-|2|edge:world:ore:2,grip:creature:hide:2",
            "copper_buckler": "schematic|shield|-|-|2|face:world:copper:2,brace:world:timber:2,binding:world:fiber:2",
            "silvered_helm": "schematic|armoury_balanced_laminate|-|head|3|body:world:ore:3,lining:creature:hide:3,binding:world:fiber:3,fitting:world:silver:3",
            "golden_keepsake": "fixedFound|-|worked-gold-keepsake|-|3|fitting:world:gold:3",
            "quartz_point": "schematic|long_spear|-|-|2|point:world:quartz:2,haft:world:timber:2,binding:world:fiber:2",
            "obsidian_edge": "schematic|weaponsmith_fitted_edge|-|-|3|edge:world:obsidian:3,grip:creature:hide:3,fitting:creature:bone:3",
            "adamant_cuirass": "schematic|rigid_guard|-|-|4|body-1:world:adamant:4,body-2:world:adamant:4,binding:world:fiber:4",
            "woven_sling": "schematic|sling|-|-|1|cord:world:fiber:1,projectile:world:clay:1,pouch:world:fiber:1",
            "timber_longbow": "schematic|longbow|-|-|1|limb-1:world:timber:1,limb-2:world:timber:1,string:world:fiber:1",
            "resinbound_boots": "schematic|working_boots|-|-|1|upper:creature:hide:1,sole:world:timber:1,binding:world:resin:1",
            "riftglass_rapier": "fixedSpecial|-|riftglass-rapier|-|4|special-core:world:rift_glass:4",
        ]
        XCTAssertEqual(Set(expected.keys), Set(ContentCatalog.shared.items.compactMap {
            $0.gearCatalogueDisposition?.foundReceipt == nil ? nil : $0.id
        }))
        for (id, frozen) in expected {
            let receipt = try XCTUnwrap(ContentCatalog.shared.item(id)?.gearCatalogueDisposition?.foundReceipt)
            let components = receipt.components.map {
                "\($0.socket):\($0.domain.rawValue):\($0.familyID):\($0.qualityBand.rawValue)"
            }.joined(separator: ",")
            let actual = [receipt.mode.rawValue, receipt.schematicID?.rawValue ?? "-",
                          receipt.fixedIdentity ?? "-", receipt.outputSlot?.rawValue ?? "-",
                          String(receipt.qualityBand.rawValue), components].joined(separator: "|")
            XCTAssertEqual(actual, frozen, id.rawValue)
        }
    }

    func testTenThousandRouteEvaluationsNeverLeakRetiredApexOrSpecialGear() {
        let ids = ContentCatalog.shared.items.map(\.id).sorted { $0.rawValue < $1.rawValue }
        for index in 0..<10_000 {
            let route = GearAcquisitionRoute.allCases[index % GearAcquisitionRoute.allCases.count]
            let id = ids[(index &* 7_919) % ids.count]
            guard case .eligible(let creation) = GearCatalogueDispositionRules.evaluate(id, route: route)
            else { continue }
            let classification = ContentCatalog.shared.item(creation.catalogID)?.gearCatalogueDisposition?.classification
            XCTAssertNotEqual(classification, .decodeOnly)
            if classification == .wildApexOnly { XCTAssertEqual(route, .apexReward) }
            XCTAssertNotEqual(creation.catalogID, "riftglass_rapier")
        }
    }

    func testAuthoredFoundInstancesFreezeBandAndReceipt() throws {
        let found = ItemStack(id: .init(rawValue: 991), catalogID: "silvered_helm")
        XCTAssertEqual(found.gearProfile?.version, 2)
        XCTAssertEqual(found.gearProfile?.qualityBand, .superior)
        XCTAssertEqual(found.gearProfile?.foundReceipt,
                       ContentCatalog.shared.item("silvered_helm")?.gearCatalogueDisposition?.foundReceipt)
        let decoded = try SaveCodec.decode(SaveCodec.encode({
            var state = GameState.newGame()
            state.base.inventory.add(found)
            return state
        }()))
        XCTAssertEqual(decoded.base.inventory.stacks.first(where: { $0.id.rawValue == 991 })?.gearProfile,
                       found.gearProfile)
    }

    func testCurrentSchemaGearProfileOmissionAndNullFailClosed() throws {
        var state = GameState.newGame()
        state.base.inventory.add(ItemStack(id: .init(rawValue: 992), catalogID: "blade_keen"))
        let encoded = try SaveCodec.encode(state)
        for replacement: Any? in [nil, NSNull()] {
            var root = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
            var base = try XCTUnwrap(root["base"] as? [String: Any])
            var inventory = try XCTUnwrap(base["inventory"] as? [String: Any])
            var stacks = try XCTUnwrap(inventory["stacks"] as? [[String: Any]])
            if let replacement { stacks[0]["gearProfile"] = replacement }
            else { stacks[0].removeValue(forKey: "gearProfile") }
            inventory["stacks"] = stacks
            base["inventory"] = inventory
            root["base"] = base
            XCTAssertThrowsError(try SaveCodec.decode(JSONSerialization.data(withJSONObject: root)))
        }
    }

    func testCurrentSchemaFoundReceiptMalformedFutureExtraAndMismatchFailClosed() throws {
        var state = GameState.newGame()
        state.base.inventory.add(ItemStack(id: .init(rawValue: 994), catalogID: "silvered_helm"))
        let encoded = try SaveCodec.encode(state)
        let mutations: [(String, (inout [String: Any]) -> Void)] = [
            ("future version", { $0["version"] = 2 }),
            ("missing explicit nullable key", { $0.removeValue(forKey: "fixedIdentity") }),
            ("mode-inapplicable key is nonnull", { $0["fixedIdentity"] = "invented" }),
            ("extra receipt key", { $0["unexpected"] = true }),
            ("extra component key", { receipt in
                var components = receipt["components"] as! [[String: Any]]
                components[0]["unexpected"] = true
                receipt["components"] = components
            }),
            ("wrong family", { receipt in
                var components = receipt["components"] as! [[String: Any]]
                components[0]["familyID"] = "gold"
                receipt["components"] = components
            }),
            ("wrong order", { receipt in
                var components = receipt["components"] as! [[String: Any]]
                components.swapAt(0, 1)
                receipt["components"] = components
            }),
        ]
        for (label, mutate) in mutations {
            var root = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
            var base = try XCTUnwrap(root["base"] as? [String: Any])
            var inventory = try XCTUnwrap(base["inventory"] as? [String: Any])
            var stacks = try XCTUnwrap(inventory["stacks"] as? [[String: Any]])
            var profile = try XCTUnwrap(stacks[0]["gearProfile"] as? [String: Any])
            var receipt = try XCTUnwrap(profile["foundReceipt"] as? [String: Any])
            mutate(&receipt)
            profile["foundReceipt"] = receipt
            stacks[0]["gearProfile"] = profile
            inventory["stacks"] = stacks
            base["inventory"] = inventory
            root["base"] = base
            XCTAssertThrowsError(try SaveCodec.decode(JSONSerialization.data(withJSONObject: root)), label)
        }
    }

    func testSchemaSevenMigrationRejectsNonIntegralNullAndPartialGearProvenance() throws {
        var state = GameState.newGame()
        state.base.inventory.add(ItemStack(id: .init(rawValue: 995), catalogID: "blade_keen"))
        let current = try SaveCodec.encode(state)
        let mutations: [(String, (inout [String: Any]) -> Void)] = [
            ("fractional version", { $0["version"] = 1.5 }),
            ("boolean tier", { $0["constructionTier"] = true }),
            ("null credit", { $0["legacyPowerCredit"] = NSNull() }),
            ("fractional reforge", { $0["reforgeRank"] = 1.25 }),
            ("recipe without units", { profile in
                profile["recipeVersion"] = 1
                profile["consumedSamples"] = []
            }),
            ("units without recipe", { profile in
                profile.removeValue(forKey: "recipeVersion")
                profile["consumedSamples"] = [["partial": true]]
            }),
        ]
        for (label, mutate) in mutations {
            var root = try XCTUnwrap(JSONSerialization.jsonObject(with: current) as? [String: Any])
            root["schemaVersion"] = 7
            var base = try XCTUnwrap(root["base"] as? [String: Any])
            var inventory = try XCTUnwrap(base["inventory"] as? [String: Any])
            var stacks = try XCTUnwrap(inventory["stacks"] as? [[String: Any]])
            var profile = try XCTUnwrap(stacks[0]["gearProfile"] as? [String: Any])
            profile["version"] = 1
            profile.removeValue(forKey: "qualityBand")
            profile.removeValue(forKey: "legacyEffectivePowerCredit")
            profile.removeValue(forKey: "foundReceipt")
            mutate(&profile)
            stacks[0]["gearProfile"] = profile
            inventory["stacks"] = stacks
            base["inventory"] = inventory
            root["base"] = base
            let bytes = try JSONSerialization.data(withJSONObject: root, options: [.sortedKeys])
            XCTAssertThrowsError(try SaveCodec.decode(bytes), label)
        }
    }

    func testSharedGearPresentationUsesSixBandIdentityInsteadOfLegacyRarityOrTier() throws {
        let stack = ItemStack(id: .init(rawValue: 996), catalogID: "silvered_helm")
        XCTAssertTrue(stack.displayName.contains("Superior"))
        XCTAssertFalse(stack.displayName.contains("Tier"))
        XCTAssertEqual(GearPresentationCopy.catalogueQuality("silvered_helm"), "Superior")
        XCTAssertEqual(GearPresentationCopy.catalogueQuality("blade_chipped"), "Standard")
        XCTAssertNil(GearPresentationCopy.catalogueQuality("salve_lesser"))
    }

    func testMigrationPreservesConstructionReceiptPrecedenceForCatalogueAuthoredID() throws {
        var state = GameState.newGame()
        var constructed = ItemStack(id: .init(rawValue: 993), catalogID: "silvered_helm")
        constructed.gearProfile?.foundReceipt = nil
        constructed.gearProfile?.recipeVersion = 1
        constructed.gearProfile?.consumedSamples = [.init(
            stableUnitID: .init(rawValue: "constructed-hide"), domain: .creature, familyID: .hide,
            qualityBand: .superior, properties: .init(),
            sourceReceipt: .legacy(originalKind: .hide, frozenSource: "constructed",
                qualifier: nil, migrationLocation: "fixture", originalIdentity: "constructed-hide"))]
        state.base.inventory.add(constructed)
        var root = try XCTUnwrap(JSONSerialization.jsonObject(with: SaveCodec.encode(state)) as? [String: Any])
        root["schemaVersion"] = 7
        var base = try XCTUnwrap(root["base"] as? [String: Any])
        var inventory = try XCTUnwrap(base["inventory"] as? [String: Any])
        var stacks = try XCTUnwrap(inventory["stacks"] as? [[String: Any]])
        var profile = try XCTUnwrap(stacks[0]["gearProfile"] as? [String: Any])
        profile["version"] = 1
        profile.removeValue(forKey: "qualityBand")
        profile.removeValue(forKey: "legacyEffectivePowerCredit")
        profile.removeValue(forKey: "foundReceipt")
        stacks[0]["gearProfile"] = profile
        inventory["stacks"] = stacks
        base["inventory"] = inventory
        root["base"] = base

        let migrated = try SaveCodec.decode(JSONSerialization.data(withJSONObject: root))
        let result = try XCTUnwrap(migrated.base.inventory.stacks.first?.gearProfile)
        XCTAssertTrue(result.hasImmutableConstructionReceipt)
        XCTAssertNil(result.foundReceipt)
        XCTAssertEqual(result.qualityBand.rawValue, result.constructionTier)
    }

    private func legacyState(equippedValue: Any) throws -> GameState {
        let encoded = try SaveCodec.encode(.newGame())
        var root = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        root["schemaVersion"] = 7
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
        root["schemaVersion"] = 7
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
                let encoded = try SaveCodec.encode(.newGame())
                var root = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
                root["schemaVersion"] = 7
                var base = try XCTUnwrap(root["base"] as? [String: Any])
                var inventory = try XCTUnwrap(base["inventory"] as? [String: Any])
                inventory["stacks"] = [object]
                base["inventory"] = inventory
                root["base"] = base
                let state = try SaveCodec.decode(JSONSerialization.data(withJSONObject: root))
                let stack = try XCTUnwrap(state.base.inventory.stacks.first)
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
