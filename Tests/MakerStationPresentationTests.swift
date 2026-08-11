import XCTest
@testable import Bookbinder

final class MakerStationPresentationTests: XCTestCase {
    func testBlacksmithRecipeGridReflowsBeforeTextShrinks() {
        XCTAssertEqual(MakerStationPresentationRules.recipeColumns(isAccessibilitySize: false), 3)
        XCTAssertEqual(MakerStationPresentationRules.recipeColumns(isAccessibilitySize: true), 2)
    }

    func testLandingReadinessCopyComesFromRulesPreview() throws {
        var state = GameState.newGame()
        state.base.stations[Stations.blacksmith] = StationState(isUnlocked: true, tier: 0)
        state.base.essence = 100
        let materials = ItemStack(
            id: InstanceID(rawValue: 901), catalogID: Items.material,
            identified: true,
            materials: [
                sample(.fang, hardness: 60, source: "point"),
                sample(.fibre, flexibility: 60, source: "grip")
            ])
        XCTAssertTrue(state.base.inventory.add(materials))

        let readiness = PhysicalGearCraftingRules.readiness(
            PhysicalGearCraftingRules.pointedBlade, in: state)
        guard case .ready(let preview) = readiness else { return XCTFail("expected ready") }
        XCTAssertEqual(MakerStationPresentationRules.readinessLabel(readiness),
                       "Ready · Tier \(preview.outputTier)")
    }

    func testCandidateAssessmentExplainsWrongKindAndLowProperty() throws {
        let requirement = PhysicalGearCraftingRules.pointedBlade.requirements[0]
        XCTAssertEqual(PhysicalGearCraftingRules.rejectionReason(
            for: sample(.hide, hardness: 100, source: "wrong kind"), requirement: requirement),
            "Needs Bone, Fang, Quill.")
        XCTAssertEqual(PhysicalGearCraftingRules.rejectionReason(
            for: sample(.fang, hardness: 10, source: "soft point"), requirement: requirement),
            "Hardness 10 of 35 required.")
        XCTAssertNil(PhysicalGearCraftingRules.rejectionReason(
            for: sample(.fang, hardness: 35, source: "enough"), requirement: requirement))
    }

    func testOverflowGearCanBeReforgedAtomicallyWithoutLosingItsIdentity() throws {
        var state = GameState.newGame()
        state.base.essence = 999
        state.base.inventory.slots = 1
        let gear = ItemStack(id: InstanceID(rawValue: 902), catalogID: "blade_chipped")
        let requirement = try XCTUnwrap(SmithRules.requirement(for: gear.catalogID, at: 0))
        let stock = (0..<requirement.count).map { index in
            sample(.plate, hardness: requirement.minimum + 5, source: "stock \(index)")
        }
        XCTAssertTrue(state.base.inventory.add(ItemStack(
            id: InstanceID(rawValue: 903), catalogID: Items.material,
            identified: true, materials: stock)))
        state.base.spillover = [gear]

        let result = try XCTUnwrap(SmithRules.reforge(overflow: gear, in: &state))
        XCTAssertEqual(result.id, gear.id)
        XCTAssertEqual(result.gearProfile?.reforgeRank, 1)
        let returned = state.base.spillover.first { $0.id == gear.id }
            ?? state.base.inventory.stacks.first { $0.id == gear.id }
        XCTAssertEqual(returned?.gearProfile?.stableInstanceID, gear.gearProfile?.stableInstanceID)
        XCTAssertEqual(returned?.gearProfile?.reforgeRank, 1)
        XCTAssertEqual(state.base.essence, 999 - requirement.essence)
    }

    func testStaleOverflowTargetRejectsWithoutPayment() {
        var state = GameState.newGame()
        state.base.essence = 999
        let gear = ItemStack(id: InstanceID(rawValue: 904), catalogID: "blade_chipped")
        let before = state
        XCTAssertNil(SmithRules.reforge(overflow: gear, in: &state))
        XCTAssertEqual(state, before)
    }

    private func sample(_ kind: MaterialKind, hardness: Double = 0,
                        flexibility: Double = 0, source: String) -> MaterialSample {
        MaterialSample(kind: kind,
                       properties: MaterialProperties(hardness: hardness,
                                                      flexibility: flexibility),
                       grade: 50, source: source)
    }
}
