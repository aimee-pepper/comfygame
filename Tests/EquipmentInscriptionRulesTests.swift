import XCTest
@testable import Bookbinder

final class EquipmentInscriptionRulesTests: XCTestCase {
    private func eligibleState(gearID: UInt64 = 40, slotItem: ItemID = "guard_padded") -> GameState {
        var state = GameState.newGame()
        state.base.stations[Stations.scriptorium] = .init(isUnlocked: true, tier: 0)
        state.base.ownedHands.insert(.plain)
        state.base.capabilities.insert("inkMixing")
        state.base.setEssenceCrystalCount(30)
        _ = state.base.inventory.add(.init(id: .init(rawValue: gearID), catalogID: slotItem))
        _ = state.base.inventory.add(.init(id: .init(rawValue: 50), catalogID: Items.seamlight))
        return state
    }

    private func makeWorldRun(portal: Bool = true) -> WorldRun {
        var tiles = Array(repeating: Tile(ground: .soil, isRevealed: false), count: 9)
        if portal { tiles[2].content = .portal(isEntry: true) }
        var run = WorldRun(runIndex: 1,
                        book: .init(symbols: [:], randomlyFilled: [], essencePaid: 0),
                        mapSeed: 1, rng: .init(seed: 1),
                        map: .init(width: 3, height: 3, tiles: tiles, entry: .init(x: 2, y: 0)),
                        playerPosition: .init(x: 0, y: 0))
        run.stability = 0
        return run
    }

    func testDefinitionEntitlementSlotsAndAtomicAshCommit() throws {
        var state = eligibleState()
        let beforeID = try XCTUnwrap(state.base.inventory.stacks.first { $0.id.rawValue == 40 }?.gearProfile?.stableInstanceID)
        let quote = try EquipmentInscriptionRules.evaluate(
            gearStableInstanceID: beforeID, inkChoice: .ash, in: state).get()
        XCTAssertEqual(EquipmentInscriptionRules.commit(quote, in: &state),
                       .committed(.init(version: 1, definitionID: "seamward",
                                        sourceItemID: Items.seamlight, rulesVersion: 1, inkRecipe: nil)))
        let profile = try XCTUnwrap(state.base.inventory.stacks.first { $0.id.rawValue == 40 }?.gearProfile)
        XCTAssertEqual(profile.stableInstanceID, beforeID)
        XCTAssertEqual(profile.inscription?.definitionID, "seamward")
        XCTAssertEqual(state.base.essenceCrystalCount, 20)
        XCTAssertNil(state.base.inventory.stacks.first { $0.id.rawValue == 50 })

        let invalid = eligibleState(gearID: 41, slotItem: "blade_chipped")
        XCTAssertEqual(EquipmentInscriptionRules.evaluate(
            gearStableInstanceID: .init(rawValue: 41), inkChoice: .ash, in: invalid),
                       .failure(.ineligibleSlot))
    }

    func testPreparedInkUsesExactLowestVialAndStaleIsAtomic() throws {
        var state = eligibleState()
        let ink = InkRecipe(cyan: 20, magenta: 30, yellow: 40, depth: 10)
        state.base.preparedInkVials = [.init(id: 9, recipe: ink, remainingApplications: 2),
                                      .init(id: 3, recipe: ink, remainingApplications: 1)]
        let quote = try EquipmentInscriptionRules.evaluate(
            gearStableInstanceID: .init(rawValue: 40), inkChoice: .prepared(ink), in: state).get()
        XCTAssertEqual(quote.preparedVialID, 3)
        state.base.preparedInkVials.removeAll { $0.id == 3 }
        let before = try SaveCodec.encode(state)
        XCTAssertEqual(EquipmentInscriptionRules.commit(quote, in: &state), .refused(.inkUnavailable))
        XCTAssertEqual(try SaveCodec.encode(state), before)
    }

    func testContributorOrderPartyOwnershipAndNonstacking() throws {
        var state = eligibleState()
        let receipt = EquipmentInscriptionReceiptV1(version: 1, definitionID: "seamward",
                                                     sourceItemID: Items.seamlight,
                                                     rulesVersion: 1, inkRecipe: nil)
        var binder = ItemStack(id: .init(rawValue: 70), catalogID: "guard_padded")
        binder.gearProfile?.inscription = receipt
        state.base.binderEquipped[.armor] = EquippedPiece(binder)
        var quill = ItemStack(id: .init(rawValue: 71), catalogID: "pressed_leaf")
        quill.gearProfile?.inscription = receipt
        state.base.roster[0].equipped[.keepsake] = EquippedPiece(quill)
        let frozen = try XCTUnwrap(EquipmentInscriptionRules.expeditionReceipt(from: state.base))
        XCTAssertEqual(frozen.contributors.map(\.gearStableInstanceID), [.init(rawValue: 70), .init(rawValue: 71)])
        XCTAssertEqual(frozen.contributors.map(\.member), [.binder, .member(.founderQuill)])
        XCTAssertTrue(frozen.hasActiveContributor)
    }

    func testCollapseActivatesWithoutExtraTurnAndGuidancePersists() throws {
        var state = GameState.newGame()
        var active = makeWorldRun()
        active.seamwardExpedition = .init(contributors: [
            .init(member: .binder, gearStableInstanceID: .init(rawValue: 70), slot: .armor,
                  definitionID: "seamward", rulesVersion: 1, inkRecipe: nil)
        ])
        state.worlds.activeRun = active
        let events = WorldRules.advanceTurn(in: &state)
        XCTAssertEqual(state.worlds.activeRun?.turnsTaken, 1)
        XCTAssertEqual(state.worlds.activeRun?.seamwardExpedition?.activatedOnTurn, 1)
        XCTAssertNotNil(SeamwardRules.projection(in: try XCTUnwrap(state.worlds.activeRun)))
        let decoded = try SaveCodec.decode(SaveCodec.encode(state))
        XCTAssertEqual(decoded.worlds.activeRun?.seamwardExpedition,
                       state.worlds.activeRun?.seamwardExpedition)
        XCTAssertTrue(events.contains(.collapsed))
        XCTAssertNil(state.worlds.activeRun?.anchoredSnapshot.seamwardExpedition)
    }

    func testNoRouteEventEmitsOnceAndErasureRefundsNothing() throws {
        var state = eligibleState()
        let quote = try EquipmentInscriptionRules.evaluate(
            gearStableInstanceID: .init(rawValue: 40), inkChoice: .ash, in: state).get()
        _ = EquipmentInscriptionRules.commit(quote, in: &state)
        let crystals = state.base.essenceCrystalCount
        let installed = try XCTUnwrap(state.base.inventory.stacks.first { $0.id.rawValue == 40 }?.gearProfile?.inscription)
        XCTAssertTrue(EquipmentInscriptionRules.erase(.init(rawValue: 40), expected: installed, in: &state))
        XCTAssertEqual(state.base.essenceCrystalCount, crystals)
        XCTAssertNil(state.base.inventory.stacks.first { $0.id.rawValue == 40 }?.gearProfile?.inscription)

        var noRoute = makeWorldRun(portal: false)
        noRoute.seamwardExpedition = .init(contributors: [
            .init(member: .binder, gearStableInstanceID: .init(rawValue: 70), slot: .armor,
                  definitionID: "seamward", rulesVersion: 1, inkRecipe: nil)
        ])
        state.worlds.activeRun = noRoute
        let first = WorldRules.advanceTurn(in: &state)
        let second = WorldRules.advanceTurn(in: &state)
        XCTAssertTrue(first.contains(.seamwardFoundNoSeam))
        XCTAssertFalse(second.contains(.seamwardFoundNoSeam))
    }
}
