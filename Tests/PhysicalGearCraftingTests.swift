import XCTest
@testable import Bookbinder

final class PhysicalGearCraftingTests: XCTestCase {
    private func sample(_ kind: MaterialFamilyID, grade: Double, hardness: Double = 0,
                        density: Double = 0, flexibility: Double = 0, insulation: Double = 0,
                        reactivity: Double = 0, source: String) -> CraftMaterialUnitV1 {
        CraftMaterialUnitV1(kind: kind,
                       properties: MaterialProperties(hardness: hardness,
                                                      density: density,
                                                      insulation: insulation,
                                                      flexibility: flexibility,
                                                      reactivity: reactivity),
                       grade: grade, source: source)
    }

    private func bowyerState(tier: Int = 0) -> GameState {
        var state = GameState.newGame()
        state.base.stations[Stations.bowyer] = StationState(isUnlocked: true, tier: tier)
        state.base.essence = 200
        state.base.inventory.add(ItemStack(id: InstanceID(rawValue: 73), catalogID: Items.material,
            materials: [
                sample(.timber, grade: 90, flexibility: 70, source: "spring limb"),
                sample(.fibre, grade: 90, flexibility: 70, source: "woven limb"),
                sample(.fang, grade: 90, hardness: 70, source: "white point"),
                sample(.hide, grade: 90, flexibility: 70, source: "sling cord"),
                sample(.bone, grade: 90, density: 70, source: "sling stone"),
                sample(.claw, grade: 90, hardness: 70, source: "edge one"),
                sample(.chitin, grade: 90, hardness: 70, source: "edge two"),
                sample(.pelt, grade: 90, flexibility: 60, source: "carrier")
            ]))
        state.base.worldMaterialReserve.migrateLegacyStacks(&state.base.inventory.stacks,
                                                       location: "fixture.bowyer")
        return state
    }

    private func readyState() -> GameState {
        var state = GameState.newGame()
        state.base.stations[Stations.blacksmith] = StationState(isUnlocked: true, tier: 0)
        state.base.essence = 200
        state.base.inventory.add(ItemStack(id: InstanceID(rawValue: 10), catalogID: Items.material,
            materials: [
                sample(.fang, grade: 90, hardness: 90, source: "great wolf"),
                sample(.bone, grade: 60, hardness: 40, source: "reed grazer"),
                sample(.hide, grade: 70, flexibility: 70, insulation: 50, source: "moss browser"),
                sample(.fibre, grade: 45, flexibility: 35, reactivity: 20, source: "reed")
            ]))
        state.base.worldMaterialReserve.migrateLegacyStacks(&state.base.inventory.stacks,
                                                       location: "fixture.blacksmith")
        return state
    }

    private func forgedEngineFixture(
        receiptUnits: ([CraftMaterialUnitV1]) -> [CraftMaterialUnitV1]
    ) throws -> (GameState, PhysicalGearCommitEnvelopeV1, ItemStack) {
        var state = GameState.newGame()
        state.base.addEssenceCrystals(20)
        let units = [
            sample(.timber, grade: 50, source: "selected limb")
                .withStableID(.init(rawValue: "engine-selected-a")),
            sample(.fibre, grade: 50, source: "selected string")
                .withStableID(.init(rawValue: "engine-selected-b"))
        ]
        units.forEach { state.base.worldMaterialReserve.add(.init(unit: $0, protectedReturn: false)) }
        let selections = units.map { CraftMaterialSelection(unitID: $0.stableUnitID, unit: $0) }
        let outputID: InstanceID
        guard case .success(let next) = PhysicalGearIdentityAuthority.nextID(in: state) else {
            throw CocoaError(.coderInvalidValue)
        }
        outputID = next
        let recorded = receiptUnits(units)
        let receipt = PhysicalGearReceiptV1(gearInstanceID: outputID, revisions: [
            .init(ordinal: 0,
                  authority: .construction(stationID: Stations.bowyer,
                                           schematicID: "forged-fixture", rulesVersion: 1),
                  components: recorded.enumerated().map {
                      .init(ordinal: $0.offset,
                            role: .authoredSocket($0.offset == 0 ? "limb" : "string"),
                            unit: $0.element)
                  }, resultingQualityBand: .standard, resultingConstructionTier: 1)
        ])
        var output = ItemStack(id: outputID, catalogID: "blade_chipped")
        output.gearProfile?.qualityBand = .standard
        output.gearProfile?.constructionTier = 1
        output.gearProfile?.physicalReceipt = receipt
        output.gearProfile?.foundReceipt = nil
        output.gearProfile?.inscription = nil
        let destination: PhysicalGearConstructionDestinationV1 = state.base.inventory.isFull
            ? .waiting : .storehouse
        var quote = PhysicalGearCommitEnvelopeV1(
            authorityID: "test.physical-engine", authorityRulesVersion: 1,
            operation: .construct(expectedInstanceID: outputID,
                                  expectedDestination: destination),
            selectedComponents: selections, physicalEssenceCrystalDebit: 10,
            expectedReceipt: receipt, stationPayloadSHA256: String(repeating: "a", count: 64),
            quoteSHA256: "")
        quote.quoteSHA256 = try XCTUnwrap(quote.canonicalQuoteSHA256())
        return (state, quote, output)
    }

    func testReceiptEngineRejectsForgedConstructionUnitsOrderAndProvenanceByteAtomically() throws {
        let transforms: [([CraftMaterialUnitV1]) -> [CraftMaterialUnitV1]] = [
            { units in
                units.enumerated().map {
                    $0.element.withStableID(.init(rawValue: "fabricated-\($0.offset)"))
                }
            },
            { Array($0.reversed()) },
            { units in
                var changed = units
                changed[1].sourceReceipt = .legacy(originalKind: .fibre,
                                                   frozenSource: "fabricated provenance",
                                                   qualifier: nil,
                                                   migrationLocation: "forged-fixture",
                                                   originalIdentity: nil)
                return changed
            }
        ]
        for transform in transforms {
            var (state, quote, output) = try forgedEngineFixture(receiptUnits: transform)
            let before = try SaveCodec.makeEncoder().encode(state)
            XCTAssertEqual(PhysicalGearReceiptEngineV1.commitConstruction(
                quote, rederived: quote, output: output, in: &state), .refused(.invalidReceipt))
            XCTAssertEqual(try SaveCodec.makeEncoder().encode(state), before)
        }
    }

    func testPointedBladeDefaultsToWeakestQualifyingDistinctSamples() throws {
        let preview = try XCTUnwrap(PhysicalGearCraftingRules.preview(
            PhysicalGearCraftingRules.pointedBlade, in: readyState()))
        XCTAssertEqual(preview.selections.map(\.sample.source), ["reed grazer", "reed"])
        XCTAssertEqual(Set(preview.selections.map(\.stockKey)).count, 2)
    }

    func testInMemoryLegacyMaterialBinCannotSatisfyPhysicalRecipe() {
        var state = GameState.newGame()
        state.base.stations[Stations.blacksmith] = .init(isUnlocked: true, tier: 0)
        state.base.inventory.add(ItemStack(id: .init(rawValue: 900), catalogID: Items.material,
            materials: [sample(.fang, grade: 90, hardness: 90, source: "legacy"),
                        sample(.hide, grade: 90, flexibility: 90, source: "legacy")]))
        XCTAssertNil(PhysicalGearCraftingRules.preview(
            PhysicalGearCraftingRules.pointedBlade, in: state))
    }

    func testBlacksmithCatalogueHasEightDistinctFoundationalFamilies() {
        let recipes = PhysicalGearCraftingRules.recipes
        XCTAssertEqual(recipes.count, 8)
        XCTAssertEqual(Set(recipes.map(\.id)).count, 8)
        XCTAssertTrue(recipes.allSatisfy { $0.station == Stations.blacksmith && $0.stationCap == 2 })
        XCTAssertEqual(Set(recipes.map(\.slot)), [.weapon, .offhand, .head, .armor, .tool])
        XCTAssertEqual(Set(recipes.compactMap(\.damage)), [.pierce, .rend, .crush])
        XCTAssertTrue(recipes.flatMap(\.requirements).allSatisfy {
            !$0.floors.isEmpty || !$0.alternativeFloors.isEmpty || $0.allowedKinds != nil
        })
    }

    func testManualSampleReplacementChangesPreviewAndCraftedProvenance() throws {
        var state = readyState()
        let recipe = PhysicalGearCraftingRules.pointedBlade
        let defaults = try XCTUnwrap(PhysicalGearCraftingRules.defaultSelections(for: recipe, in: state))
        let strongerPoint = try XCTUnwrap(
            PhysicalGearCraftingRules.candidates(for: recipe.requirements[0], in: state)
                .first { $0.sample.source == "great wolf" }
        )
        let chosen = defaults.map { $0.requirementID == "hard_point" ? strongerPoint : $0 }
        let preview = try XCTUnwrap(PhysicalGearCraftingRules.preview(recipe, selections: chosen, in: state))
        XCTAssertEqual(preview.selections.map(\.sample.source), ["great wolf", "reed"])
        let output = try XCTUnwrap(PhysicalGearCraftingRules.craft(preview, in: &state))
        XCTAssertEqual(output.gearProfile?.consumedSamples.map(\.source), ["great wolf", "reed"])
    }

    func testTanneryHasThreeAuthoredFamiliesAndAlternativeSoleRequirement() throws {
        let recipes = PhysicalGearCraftingRules.tanneryRecipes
        XCTAssertEqual(recipes.map(\.id), ["supple_coat", "working_gloves", "working_boots"])
        XCTAssertEqual(Set(recipes.map(\.slot)), [.armor, .hands, .feet])
        XCTAssertTrue(recipes.allSatisfy { $0.station == Stations.tannery && $0.stationCap == 2 })

        let sole = try XCTUnwrap(PhysicalGearCraftingRules.workingBoots.requirements.last)
        XCTAssertTrue(PhysicalGearCraftingRules.qualifies(
            sample(.bone, grade: 30, hardness: 31, source: "hard"), for: sole))
        XCTAssertTrue(PhysicalGearCraftingRules.qualifies(
            CraftMaterialUnitV1(kind: .bone, properties: MaterialProperties(density: 31),
                           grade: 30, source: "dense"), for: sole))
        XCTAssertFalse(PhysicalGearCraftingRules.qualifies(
            sample(.bone, grade: 30, hardness: 29, source: "soft"), for: sole))
    }

    func testTanneryCraftFreezesSpecialistAndConsumesChosenSamples() throws {
        var state = GameState.newGame()
        state.base.stations[Stations.tannery] = StationState(isUnlocked: true, tier: 0)
        state.base.completedResearch.insert(PhysicalGearCraftingRules.tanneryWearRoot)
        state.base.capabilities.insert(PhysicalGearCraftingRules.tanneryWearCapability)
        state.base.essence = 100
        state.base.inventory.add(ItemStack(id: InstanceID(rawValue: 71), catalogID: Items.material,
            materials: [
                sample(.hide, grade: 50, flexibility: 50, insulation: 30, source: "hide one"),
                sample(.pelt, grade: 55, flexibility: 45, insulation: 35, source: "pelt two")
            ]))
        state.base.worldMaterialReserve.migrateLegacyStacks(&state.base.inventory.stacks,
                                                       location: "fixture.tannery.craft")
        let preview = try XCTUnwrap(PhysicalGearCraftingRules.preview(
            PhysicalGearCraftingRules.suppleCoat, in: state))
        let output = try XCTUnwrap(PhysicalGearCraftingRules.craft(preview, in: &state))
        XCTAssertEqual(output.gearProfile?.specialistProfile, "tannery")
        XCTAssertEqual(output.gearProfile?.familyID, "supple_coat")
        XCTAssertEqual(output.gearProfile?.consumedSamples.count, 2)
        XCTAssertFalse(state.base.inventory.stacks.contains { $0.id == InstanceID(rawValue: 71) })
    }

    func testTanneryFamiliesRequireWearCapabilityEvenWhenCompletionHistoryExists() {
        var state = GameState.newGame()
        state.base.stations[Stations.tannery] = StationState(isUnlocked: true, tier: 0)
        XCTAssertEqual(PhysicalGearCraftingRules.readiness(
            PhysicalGearCraftingRules.suppleCoat, in: state),
                       .researchLocked(PhysicalGearCraftingRules.tanneryWearRoot))
        state.base.completedResearch.insert(PhysicalGearCraftingRules.tanneryWearRoot)
        XCTAssertEqual(PhysicalGearCraftingRules.readiness(
            PhysicalGearCraftingRules.suppleCoat, in: state),
                       .researchLocked(PhysicalGearCraftingRules.tanneryWearRoot))
        state.base.capabilities.insert(PhysicalGearCraftingRules.tanneryWearCapability)
        XCTAssertNotEqual(PhysicalGearCraftingRules.readiness(
            PhysicalGearCraftingRules.suppleCoat, in: state),
                          .researchLocked(PhysicalGearCraftingRules.tanneryWearRoot))
    }

    func testTanneryTierTwoRequiresTheSecondWearRung() throws {
        var state = GameState.newGame()
        state.base.stations[Stations.tannery] = StationState(isUnlocked: true, tier: 0)
        state.base.completedResearch.insert(PhysicalGearCraftingRules.tanneryWearRoot)
        state.base.capabilities.insert(PhysicalGearCraftingRules.tanneryWearCapability)
        state.base.essence = 100
        state.base.inventory.add(ItemStack(id: InstanceID(rawValue: 72), catalogID: Items.material,
            materials: [
                sample(.hide, grade: 70, flexibility: 70, insulation: 60, source: "one"),
                sample(.pelt, grade: 70, flexibility: 70, insulation: 60, source: "two")
            ]))
        state.base.worldMaterialReserve.migrateLegacyStacks(&state.base.inventory.stacks,
                                                       location: "fixture.tannery.tier")
        XCTAssertEqual(try XCTUnwrap(PhysicalGearCraftingRules.preview(
            PhysicalGearCraftingRules.suppleCoat, in: state)).outputTier, 1)
        state.base.completedResearch.insert(PhysicalGearCraftingRules.tanneryWearTierTwo)
        state.base.capabilities.insert(PhysicalGearCraftingRules.tanneryTierTwoCapability)
        XCTAssertEqual(try XCTUnwrap(PhysicalGearCraftingRules.preview(
            PhysicalGearCraftingRules.suppleCoat, in: state)).outputTier, 2)
    }

    func testBowyerCoversPhysicalTriangleAtFarReach() {
        let recipes = PhysicalGearCraftingRules.bowyerRecipes
        XCTAssertEqual(recipes.map(\.id), ["longbow", "sling", "throwing_set"])
        XCTAssertEqual(Set(recipes.compactMap(\.damage)), [.pierce, .crush, .rend])
        XCTAssertTrue(recipes.allSatisfy {
            $0.station == Stations.bowyer && $0.slot == .weapon && $0.reach == .far
        })
    }

    func testBowyerTierZeroIsUsefulAndTierOneBroadensTheFamilies() {
        var state = bowyerState()
        guard case .ready = PhysicalGearCraftingRules.readiness(
            PhysicalGearCraftingRules.longbow, in: state) else { return XCTFail("longbow not ready") }
        XCTAssertEqual(PhysicalGearCraftingRules.readiness(
            PhysicalGearCraftingRules.sling, in: state), .tierLocked(need: 1))
        state.base.stations[Stations.bowyer]?.tier = 1
        guard case .ready = PhysicalGearCraftingRules.readiness(
            PhysicalGearCraftingRules.sling, in: state) else { return XCTFail("tier 1 stayed inert") }
    }

    func testBowyerTierTwoAlonePermitsTierFour() throws {
        var state = bowyerState(tier: 0)
        XCTAssertEqual(try XCTUnwrap(PhysicalGearCraftingRules.preview(
            PhysicalGearCraftingRules.longbow, in: state)).outputTier, 3)
        state.base.stations[Stations.bowyer]?.tier = 1
        XCTAssertEqual(try XCTUnwrap(PhysicalGearCraftingRules.preview(
            PhysicalGearCraftingRules.longbow, in: state)).outputTier, 3)
        state.base.stations[Stations.bowyer]?.tier = 2
        let preview = try XCTUnwrap(PhysicalGearCraftingRules.preview(
            PhysicalGearCraftingRules.longbow, in: state))
        XCTAssertEqual(preview.outputTier, 4)
        let output = try XCTUnwrap(PhysicalGearCraftingRules.craft(preview, in: &state))
        XCTAssertEqual(output.gearProfile?.constructionTier, 4)
        XCTAssertEqual(output.gearProfile?.reach, .far)
        XCTAssertEqual(output.gearProfile?.damage, .pierce)
        XCTAssertEqual(output.gearProfile?.specialistProfile, "bowyer")
    }

    func testEveryBowyerFamilyAllowsLowGradePreviewButRejectsAStaleCommit() throws {
        for recipe in PhysicalGearCraftingRules.bowyerRecipes {
            var state = bowyerState(tier: 1)
            let original = state.base.worldMaterialReserve.units
            XCTAssertEqual(state.base.worldMaterialReserve.consume(
                state.base.worldMaterialReserve.selections()), original.map(\.sample))
            for var unit in original {
                unit.unit.qualityBand = .rough
                _ = state.base.worldMaterialReserve.add(unit)
            }
            let preview = try XCTUnwrap(PhysicalGearCraftingRules.preview(recipe, in: state), recipe.id)
            XCTAssertEqual(preview.outputTier, 1, recipe.id)
            XCTAssertTrue(preview.isBelowSpecialistHeadline, recipe.id)
            guard case .ready = PhysicalGearCraftingRules.readiness(recipe, in: state) else {
                return XCTFail("\(recipe.id) incorrectly blocked low-tier specialist output")
            }

            let first = try XCTUnwrap(preview.selections.first)
            _ = state.base.worldMaterialReserve.consume([try XCTUnwrap(first.reserveSelection)])
            let afterExternalChange = state
            XCTAssertNil(PhysicalGearCraftingRules.craft(preview, in: &state), recipe.id)
            XCTAssertEqual(state, afterExternalChange, "\(recipe.id) stale preview debited state")
        }
    }

    func testQualityUsesPrimarySeventySecondaryThirtyAndPreservesStationTierCap() throws {
        var state = readyState()
        let recipe = PhysicalGearCraftingRules.pointedBlade
        let selections = [
            try XCTUnwrap(PhysicalGearCraftingRules.candidates(
                for: recipe.requirements[0], in: state).first { $0.sample.source == "great wolf" }),
            try XCTUnwrap(PhysicalGearCraftingRules.candidates(
                for: recipe.requirements[1], in: state).first { $0.sample.source == "moss browser" })
        ]
        let preview = try XCTUnwrap(PhysicalGearCraftingRules.preview(recipe, selections: selections,
                                                                      in: state))
        XCTAssertEqual(preview.qualityBand, .superior)
        XCTAssertEqual(preview.outputTier, 2)
        XCTAssertEqual(preview.essence, 24)
    }

    func testCraftConsumesExactlyPreviewedInputsAndFreezesProvenance() throws {
        var state = readyState()
        let preview = try XCTUnwrap(PhysicalGearCraftingRules.preview(
            PhysicalGearCraftingRules.pointedBlade, in: state))
        let beforeCount = state.base.worldMaterialReserve.count
        let output = try XCTUnwrap(PhysicalGearCraftingRules.craft(preview, in: &state))

        XCTAssertEqual(state.base.essence, 200 - preview.essence)
        XCTAssertEqual(state.base.worldMaterialReserve.count, beforeCount - 2)
        XCTAssertEqual(output.gearProfile?.familyID, "pointed_blade")
        XCTAssertEqual(output.gearProfile?.constructionTier, preview.outputTier)
        XCTAssertEqual(output.gearProfile?.damage, .pierce)
        XCTAssertEqual(output.gearProfile?.reach, .close)
        XCTAssertEqual(output.gearProfile?.consumedSamples, preview.selections.map(\.sample))
        XCTAssertEqual(output.gearProfile?.recipeVersion, 1)
        XCTAssertEqual(output.displayName, "Pointed Blade · reed grazer + reed · Tier 2")
    }

    func testStaleOrDuplicateSelectionCannotConsumeOrCraft() throws {
        var state = readyState()
        let preview = try XCTUnwrap(PhysicalGearCraftingRules.preview(
            PhysicalGearCraftingRules.pointedBlade, in: state))
        _ = state.base.worldMaterialReserve.consume([
            try XCTUnwrap(preview.selections[0].reserveSelection)
        ])
        let essence = state.base.essence
        XCTAssertNil(PhysicalGearCraftingRules.craft(preview, in: &state))
        XCTAssertEqual(state.base.essence, essence)
    }
}
