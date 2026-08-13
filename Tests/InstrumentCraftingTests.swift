import XCTest
@testable import Bookbinder

@MainActor
final class InstrumentCraftingTests: XCTestCase {
    func testInstrumentUpgradeUsesAnOrdinaryPhoneTouchTarget() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(
            contentsOf: root.appending(path: "Sources/Screens/StationViews.swift"),
            encoding: .utf8
        )
        let action = try XCTUnwrap(source.range(of: "Button(\"Improve\")"))
        let end = try XCTUnwrap(source.range(of: ".accessibilityIdentifier(\"instrument.improve.",
                                               range: action.lowerBound..<source.endIndex))
        let button = source[action.lowerBound..<end.upperBound]

        XCTAssertTrue(button.contains(".frame(minWidth: 72, minHeight: 44)"))
        XCTAssertFalse(button.contains(".controlSize(.small)"))
    }

    func testRecipesAskForPropertiesRatherThanMaterialNames() {
        var state = GameState.newGame()
        state.reality.instruments.insert("illumination")

        let recipe = InstrumentCraftingRules.recipe(for: "illumination", in: state)

        XCTAssertEqual(recipe?.property, .lustre)
        XCTAssertEqual(recipe?.output, .good)
    }

    func testUpgradeConsumesWeakestQualifyingSamplesAndRaisesPrecision() throws {
        var state = GameState.newGame()
        state.base.essence = 100
        state.reality.instruments.insert("illumination")
        state.base.inventory.stacks = [ItemStack(
            id: InstanceID(rawValue: 700),
            catalogID: Items.material,
            materials: [sample(lustre: 80), sample(lustre: 36), sample(lustre: 42)]
        )]

        XCTAssertTrue(InstrumentCraftingRules.craftUpgrade(for: "illumination", in: &state))
        XCTAssertEqual(state.reality.instrumentPrecision(for: "illumination"), .good)
        XCTAssertEqual(state.base.essence, 80)
        XCTAssertEqual(state.base.inventory.stacks.first?.materials.map(\.properties.lustre), [80])
    }

    func testGoodThenFineAndNoUpgradePastFine() {
        var state = GameState.newGame()
        state.base.essence = 200
        state.reality.instruments.insert("illumination")
        state.base.inventory.stacks = [ItemStack(
            id: InstanceID(rawValue: 701),
            catalogID: Items.material,
            materials: Array(repeating: sample(lustre: 90), count: 5)
        )]

        XCTAssertTrue(InstrumentCraftingRules.craftUpgrade(for: "illumination", in: &state))
        XCTAssertTrue(InstrumentCraftingRules.craftUpgrade(for: "illumination", in: &state))
        XCTAssertEqual(state.reality.instrumentPrecision(for: "illumination"), .fine)
        XCTAssertEqual(InstrumentCraftingRules.readiness(for: "illumination", in: state), .finished)
    }

    func testOldOwnedInstrumentDefaultsToCrude() throws {
        var reality = RealityState.newGame()
        reality.instruments.insert("thermal")
        XCTAssertEqual(reality.instrumentPrecision(for: "thermal"), .crude)
    }

    private func sample(lustre: Double) -> MaterialSample {
        MaterialSample(kind: .chitin,
                       properties: MaterialProperties(lustre: lustre),
                       grade: lustre,
                       source: "test creature")
    }
}
