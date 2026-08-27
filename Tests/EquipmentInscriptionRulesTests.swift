import XCTest
import SwiftUI
import UIKit
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

    func testInactiveHomeRosterWornGearIsSelectableAndErasableButNeverContributes() throws {
        var state = eligibleState()
        state.base.activeParty = []
        let receipt = EquipmentInscriptionReceiptV1(version: 1, definitionID: "seamward",
                                                     sourceItemID: Items.seamlight,
                                                     rulesVersion: 1, inkRecipe: nil)
        let worn = try XCTUnwrap(state.base.inventory.stacks.first { $0.id.rawValue == 40 })
        state.base.inventory.remove(worn.id)
        state.base.roster[0].equipped[.armor] = EquippedPiece(worn)

        XCTAssertEqual(EquipmentInscriptionRules.eligibleGear(in: state.base).map(\.0),
                       [.worn(.member(.founderQuill))])
        let quote = try EquipmentInscriptionRules.evaluate(
            gearStableInstanceID: .init(rawValue: 40), inkChoice: .ash, in: state).get()
        XCTAssertEqual(quote.location, .worn(.member(.founderQuill)))
        XCTAssertEqual(EquipmentInscriptionRules.commit(quote, in: &state), .committed(receipt))
        XCTAssertEqual(EquipmentInscriptionRules.inscribedGear(in: state.base).map(\.0),
                       [.worn(.member(.founderQuill))])
        XCTAssertNil(EquipmentInscriptionRules.expeditionReceipt(from: state.base),
                     "a Home wearer must remain absent from expedition contributors")
        XCTAssertTrue(EquipmentInscriptionRules.erase(.init(rawValue: 40), expected: receipt,
                                                       in: &state))
        XCTAssertNil(state.base.roster[0].equipped[.armor]?.gearProfile?.inscription)
    }

    func testUnknownStructurallyValidInscriptionRoundTripsVisibleAndInert() throws {
        var state = eligibleState()
        let unknown = EquipmentInscriptionReceiptV1(version: 1,
                                                     definitionID: "future_starlace",
                                                     sourceItemID: "future_source",
                                                     rulesVersion: 7, inkRecipe: nil)
        state.base.inventory.stacks[0].gearProfile?.inscription = unknown
        let before = try SaveCodec.encode(state)
        let decoded = try SaveCodec.decode(before)
        XCTAssertEqual(decoded, state)
        let canonical = try SaveCodec.encode(decoded)
        XCTAssertEqual(try SaveCodec.decode(canonical), decoded)
        let visible = EquipmentInscriptionRules.inscribedGear(in: decoded.base)
        XCTAssertEqual(visible.first?.1.inscription, unknown)
        XCTAssertFalse(try XCTUnwrap(visible.first?.1.inscription).isActiveSeamward)
        XCTAssertNil(EquipmentInscriptionRules.expeditionReceipt(from: decoded.base))
        XCTAssertEqual(decoded.base.essenceCrystalCount, state.base.essenceCrystalCount)
        XCTAssertEqual(decoded.base.inventory.stacks, state.base.inventory.stacks)
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

    func testWornPreparedInkInstallationAndStoreErasureAreExact() throws {
        var state = eligibleState(gearID: 40)
        let worn = try XCTUnwrap(state.base.inventory.stacks.first { $0.id.rawValue == 40 })
        state.base.inventory.remove(.init(rawValue: 40))
        state.base.binderEquipped[.armor] = EquippedPiece(worn)
        let ink = InkRecipe(cyan: 15, magenta: 25, yellow: 35, depth: 45)
        state.base.preparedInkVials = [.init(id: 7, recipe: ink, remainingApplications: 1)]
        let quote = try EquipmentInscriptionRules.evaluate(
            gearStableInstanceID: .init(rawValue: 40), inkChoice: .prepared(ink), in: state).get()
        XCTAssertEqual(quote.location, .worn(.binder))
        XCTAssertEqual(quote.preparedVialID, 7)
        guard case .committed(let receipt) = EquipmentInscriptionRules.commit(quote, in: &state) else {
            return XCTFail("expected worn inscription")
        }
        XCTAssertEqual(state.base.binderEquipped[.armor]?.gearProfile?.inscription, receipt)
        XCTAssertTrue(state.base.preparedInkVials.isEmpty)
        XCTAssertTrue(EquipmentInscriptionRules.erase(.init(rawValue: 40), expected: receipt, in: &state))
        XCTAssertNil(state.base.binderEquipped[.armor]?.gearProfile?.inscription)
    }

    func testGuidanceRetargetsReachesPortalAndNeverDisclosesMap() throws {
        var run = makeWorldRun()
        run.seamwardExpedition = .init(contributors: [
            .init(member: .binder, gearStableInstanceID: .init(rawValue: 70), slot: .armor,
                  definitionID: "seamward", rulesVersion: 1, inkRecipe: nil)
        ], activatedOnTurn: 0)
        let disclosure = run.map.tiles.map(\.isRevealed)
        XCTAssertEqual(SeamwardRules.projection(in: run), .directional(.east, .far))
        run.playerPosition = .init(x: 1, y: 0)
        XCTAssertEqual(SeamwardRules.projection(in: run), .directional(.east, .near))
        run.playerPosition = .init(x: 2, y: 0)
        XCTAssertEqual(SeamwardRules.projection(in: run), .onPortal)
        XCTAssertEqual(run.map.tiles.map(\.isRevealed), disclosure)
    }

    func testMalformedAndFutureInscriptionReceiptsFailDecode() throws {
        let receipt = EquipmentInscriptionReceiptV1(version: 1, definitionID: "seamward",
                                                     sourceItemID: Items.seamlight,
                                                     rulesVersion: 1, inkRecipe: nil)
        var object = try XCTUnwrap(JSONSerialization.jsonObject(
            with: SaveCodec.makeEncoder().encode(receipt)) as? [String: Any])
        object["version"] = 2
        XCTAssertThrowsError(try SaveCodec.makeDecoder().decode(
            EquipmentInscriptionReceiptV1.self,
            from: JSONSerialization.data(withJSONObject: object)))

        var state = GameState.newGame()
        var run = makeWorldRun()
        run.seamwardExpedition = .init(contributors: [
            .init(member: .binder, gearStableInstanceID: .init(rawValue: 70), slot: .armor,
                  definitionID: "seamward", rulesVersion: 1, inkRecipe: nil)
        ])
        state.worlds.activeRun = run
        var root = try XCTUnwrap(JSONSerialization.jsonObject(
            with: SaveCodec.makeEncoder().encode(state)) as? [String: Any])
        var worlds = try XCTUnwrap(root["worlds"] as? [String: Any])
        var active = try XCTUnwrap(worlds["activeRun"] as? [String: Any])
        var expedition = try XCTUnwrap(active["seamwardExpedition"] as? [String: Any])
        expedition["version"] = 2
        active["seamwardExpedition"] = expedition; worlds["activeRun"] = active; root["worlds"] = worlds
        XCTAssertThrowsError(try SaveCodec.decode(JSONSerialization.data(withJSONObject: root)))
        expedition["version"] = 1
        expedition["activatedOnTurn"] = 99
        active["seamwardExpedition"] = expedition; worlds["activeRun"] = active; root["worlds"] = worlds
        XCTAssertThrowsError(try SaveCodec.decode(JSONSerialization.data(withJSONObject: root)))
    }

    func testInscriptionSnapshotSurvivesStorageOverflowEquipReforgeAndRelaunch() throws {
        var state = eligibleState()
        let quote = try EquipmentInscriptionRules.evaluate(
            gearStableInstanceID: .init(rawValue: 40), inkChoice: .ash, in: state).get()
        guard case .committed(let receipt) = EquipmentInscriptionRules.commit(quote, in: &state) else {
            return XCTFail("expected inscription")
        }
        let encoded = try SaveCodec.encode(state)
        state = try SaveCodec.decode(encoded)
        XCTAssertEqual(state.base.inventory.stacks.first(where: { $0.id.rawValue == 40 })?
            .gearProfile?.inscription, receipt)
        let stack = try XCTUnwrap(state.base.inventory.stacks.first { $0.id.rawValue == 40 })
        state.base.inventory.remove(.init(rawValue: 40))
        state.base.spillover.append(stack)
        XCTAssertEqual(state.base.spillover.first?.gearProfile?.inscription, receipt)
        let overflow = try XCTUnwrap(state.base.spillover.first)
        state.base.spillover.removeAll()
        state.base.binderEquipped[.armor] = EquippedPiece(overflow)
        XCTAssertEqual(state.base.binderEquipped[.armor]?.gearProfile?.inscription, receipt)
        _ = SmithRules.reforge(worn: .armor, on: .binder, in: &state)
        XCTAssertEqual(state.base.binderEquipped[.armor]?.gearProfile?.inscription, receipt)
    }

    func testTradingAndRecyclerDestructivePreviewsFreezeTheInscribedSnapshot() throws {
        var state = eligibleState()
        let quote = try EquipmentInscriptionRules.evaluate(
            gearStableInstanceID: .init(rawValue: 40), inkChoice: .ash, in: state).get()
        guard case .committed(let receipt) = EquipmentInscriptionRules.commit(quote, in: &state) else {
            return XCTFail("expected inscription")
        }
        let sale = try XCTUnwrap(TradingPostRules.previewSale(
            resources: [:],
            items: [.init(location: .stored, stackID: .init(rawValue: 40), quantity: 1)],
            in: state.base))
        XCTAssertEqual(sale.items.first?.snapshot.gearProfile?.inscription, receipt)
        let recycler = try XCTUnwrap(RecyclerRules.preview(
            location: .stored, stackID: .init(rawValue: 40), serviceTier: 1, in: state.base))
        XCTAssertEqual(recycler.snapshot.gearProfile?.inscription, receipt)
    }

    @MainActor
    func testMountedWorldShowsDirectionalRetargetAndOnPortalWithoutDisclosure() throws {
        let store = GameStore(io: .temporary(name: "seamward-mounted-\(UUID().uuidString)"))
        var run = makeWorldRun()
        run.seamwardExpedition = .init(contributors: [
            .init(member: .binder, gearStableInstanceID: .init(rawValue: 70), slot: .armor,
                  definitionID: "seamward", rulesVersion: 1, inkRecipe: nil)
        ], activatedOnTurn: 0)
        let disclosure = run.map.tiles.map(\.isRevealed)
        store.mutate("mounted seamward") { state in
            state.worlds.activeRun = run
            for lesson in TutorialLessonID.allCases {
                state.tutorial.complete(lesson, fact: "seamward_fixture")
            }
        }

        func capture(_ name: String) -> Data {
            let controller = UIHostingController(rootView:
                WorldView().environmentObject(store).frame(width: 368, height: 800))
            let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 368, height: 800))
            window.rootViewController = controller; window.makeKeyAndVisible()
            controller.view.frame = window.bounds; controller.view.layoutIfNeeded()
            RunLoop.main.run(until: Date().addingTimeInterval(0.08))
            let image = UIGraphicsImageRenderer(size: window.bounds.size).image { _ in
                controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
            }
            let attachment = XCTAttachment(image: image)
            attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
            window.isHidden = true
            return image.pngData() ?? Data()
        }

        let far = capture("seamward-world-east-far-368x800")
        store.mutate("retarget seamward") { $0.worlds.activeRun?.playerPosition = .init(x: 1, y: 0) }
        let near = capture("seamward-world-east-near-368x800")
        store.mutate("stand on seam") { $0.worlds.activeRun?.playerPosition = .init(x: 2, y: 0) }
        let portal = capture("seamward-world-on-portal-368x800")
        XCTAssertFalse(far.isEmpty); XCTAssertNotEqual(far, near); XCTAssertNotEqual(near, portal)
        XCTAssertEqual(store.state.worlds.activeRun?.map.tiles.map(\.isRevealed), disclosure)
    }
}
