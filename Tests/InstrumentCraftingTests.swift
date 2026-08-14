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
        addSamples([sample(lustre: 80), sample(lustre: 36), sample(lustre: 42)], to: &state)

        XCTAssertTrue(InstrumentCraftingRules.craftUpgrade(for: "illumination", in: &state))
        XCTAssertEqual(state.reality.instrumentPrecision(for: "illumination"), .good)
        XCTAssertEqual(state.base.essence, 80)
        XCTAssertEqual(state.base.materialReserve.units.map(\.sample.properties.lustre), [80])
    }

    func testGoodThenFineAndNoUpgradePastFine() {
        var state = GameState.newGame()
        state.base.essence = 200
        state.reality.instruments.insert("illumination")
        addSamples(Array(repeating: sample(lustre: 90), count: 5), to: &state)

        XCTAssertTrue(InstrumentCraftingRules.craftUpgrade(for: "illumination", in: &state))
        XCTAssertTrue(InstrumentCraftingRules.craftUpgrade(for: "illumination", in: &state))
        XCTAssertEqual(state.reality.instrumentPrecision(for: "illumination"), .fine)
        XCTAssertEqual(InstrumentCraftingRules.readiness(for: "illumination", in: state), .finished)
    }

    func testInventoryMaterialBinsDoNotFundInstrumentCrafting() {
        var state = GameState.newGame()
        state.base.essence = 100
        state.reality.instruments.insert("illumination")
        state.base.inventory.stacks = [ItemStack(
            id: InstanceID(rawValue: 700), catalogID: Items.material,
            materials: [sample(lustre: 80), sample(lustre: 80)]
        )]
        let before = state

        XCTAssertFalse(InstrumentCraftingRules.craftUpgrade(for: "illumination", in: &state))
        XCTAssertEqual(state, before)
    }

    func testReserveConsumeRejectsAStaleInstrumentQuoteWithoutPartialMutation() throws {
        var state = GameState.newGame()
        state.reality.instruments.insert("illumination")
        addSamples([sample(lustre: 36), sample(lustre: 42), sample(lustre: 80)], to: &state)
        let recipe = try XCTUnwrap(InstrumentCraftingRules.recipe(for: "illumination", in: state))
        let quote = Array(InstrumentCraftingRules.candidates(for: recipe, in: state).prefix(2))
            .map(\.selection)
        _ = state.base.materialReserve.consume([quote[0]])
        let before = state.base.materialReserve

        XCTAssertNil(state.base.materialReserve.consume(quote))
        XCTAssertEqual(state.base.materialReserve, before)
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

    private func addSamples(_ samples: [MaterialSample], to state: inout GameState) {
        for (index, sample) in samples.enumerated() {
            state.base.materialReserve.add(MaterialReserveUnit(
                id: MaterialReserveUnitID(rawValue: "instrument-\(index)"), sample: sample
            ))
        }
    }
}
