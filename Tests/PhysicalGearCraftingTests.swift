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
        let units = [
            sample(.timber, grade: 90, flexibility: 70, source: "spring limb"),
            sample(.timber, grade: 90, flexibility: 70, source: "second limb"),
            sample(.fibre, grade: 90, flexibility: 70, source: "woven string"),
            sample(.rubble, grade: 90, density: 70, source: "sling stone"),
            sample(.ore, grade: 90, hardness: 70, source: "edge one"),
            sample(.adamant, grade: 90, hardness: 70, source: "edge two"),
            sample(.hide, grade: 90, flexibility: 70, source: "sling cord"),
            sample(.pelt, grade: 90, flexibility: 60, source: "sling pouch"),
            sample(.fin, grade: 90, flexibility: 60, source: "carrier")
        ].enumerated().map {
            $0.element.withStableID(.init(rawValue: "bowyer-fixture-\($0.offset)"))
        }
        for unit in units {
            let holding = CraftMaterialHoldingV1(unit: unit, protectedReturn: false)
            if unit.domain == .world { state.base.worldMaterialReserve.add(holding) }
            else { state.base.creatureMaterialReserve.add(holding) }
        }
        return state
    }

    private func tanneryState(grade: Double = 90) -> GameState {
        var state = GameState.newGame()
        state.base.stations[Stations.tannery] = StationState(isUnlocked: true, tier: 0)
        state.base.completedResearch.insert(PhysicalGearCraftingRules.tanneryWearRoot)
        state.base.capabilities.insert(PhysicalGearCraftingRules.tanneryWearCapability)
        state.base.essence = 200
        let units = [
            sample(.fibre, grade: grade, flexibility: 70, source: "outer fiber"),
            sample(.timber, grade: grade, density: 70, source: "sole timber"),
            sample(.resin, grade: grade, source: "binding resin"),
            sample(.hide, grade: grade, flexibility: 70, insulation: 60, source: "body hide"),
            sample(.pelt, grade: grade, flexibility: 70, insulation: 60, source: "lining pelt"),
            sample(.bone, grade: grade, hardness: 70, source: "facing bone"),
            sample(.scale, grade: grade, hardness: 70, source: "spare scale")
        ].enumerated().map {
            $0.element.withStableID(.init(rawValue: "tannery-fixture-\($0.offset)"))
        }
        for unit in units {
            let holding = CraftMaterialHoldingV1(unit: unit, protectedReturn: false)
            if unit.domain == .world { state.base.worldMaterialReserve.add(holding) }
            else { state.base.creatureMaterialReserve.add(holding) }
        }
        return state
    }

    private func readyState() -> GameState {
        var state = GameState.newGame()
        state.base.stations[Stations.blacksmith] = StationState(isUnlocked: true, tier: 0)
        state.reality.library.knownSchematics.insert("pointed_blade")
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
        XCTAssertEqual(PhysicalGearCraftingRules.blacksmithLiveRecipes.map(\.id), ["pointed_blade"])
        XCTAssertTrue(recipes.allSatisfy { $0.station == Stations.blacksmith })
        XCTAssertEqual(Set(recipes.map(\.slot)), [.weapon, .offhand, .head, .armor, .tool])
        XCTAssertEqual(Set(recipes.compactMap(\.damage)), [.pierce, .rend, .crush])
        XCTAssertTrue(recipes.flatMap(\.requirements).allSatisfy {
            !$0.floors.isEmpty || !$0.alternativeFloors.isEmpty || $0.allowedKinds != nil
        })
    }

    func testOnlyPointedBladeIsLiveAndRequiresDurableKnowledge() {
        var state = readyState()
        XCTAssertTrue(PhysicalGearCraftingRules.isUnlocked(
            PhysicalGearCraftingRules.pointedBlade, in: state))
        for recipe in PhysicalGearCraftingRules.recipes.dropFirst() {
            XCTAssertFalse(PhysicalGearCraftingRules.isUnlocked(recipe, in: state), recipe.id)
            XCTAssertNil(PhysicalGearCraftingRules.preview(recipe, in: state), recipe.id)
        }
        state.reality.library.knownSchematics.remove("pointed_blade")
        XCTAssertFalse(PhysicalGearCraftingRules.isUnlocked(
            PhysicalGearCraftingRules.pointedBlade, in: state))
    }

    func testPointedBladeSocketsAreDomainQualifiedAndPropertyFloorFree() {
        let recipe = PhysicalGearCraftingRules.pointedBlade
        XCTAssertEqual(recipe.requirements.map(\.id), ["point.0", "grip.0"])
        XCTAssertEqual(recipe.primaryRequirementIDs, ["point.0"])
        XCTAssertTrue(recipe.requirements.allSatisfy { $0.floors.isEmpty })
        XCTAssertEqual(recipe.requirements[0].allowedKinds,
                       [.ore, .adamant, .obsidian, .quartz,
                        .fang, .quill, .bone, .tusk, .horn])
        XCTAssertEqual(recipe.requirements[1].allowedKinds,
                       [.fibre, .timber, .copper, .silver, .gold,
                        .hide, .pelt, .fin, .bone, .horn])
        var creatureOre = sample(.ore, grade: 50, source: "creature ore")
        creatureOre.domain = .creature
        XCTAssertFalse(PhysicalGearCraftingRules.qualifies(
            creatureOre, for: recipe.requirements[0]))
        var worldHorn = sample(.horn, grade: 50, source: "world horn")
        worldHorn.domain = .world
        XCTAssertFalse(PhysicalGearCraftingRules.qualifies(
            worldHorn, for: recipe.requirements[0]))
    }

    @MainActor func testBlacksmithBuildGrantsPointedBladeKnowledgeAtomically() throws {
        let store = GameStore(io: .temporary(name: "pointed-build-\(UUID().uuidString)"))
        let station = try XCTUnwrap(ContentCatalog.shared.station(Stations.blacksmith))
        store.mutate("prepare Halloway") { state in
            state.reality.library.foundTravellers.insert("halloway")
            state.base.essence = station.buildCost!.essence
            for (id, amount) in station.buildCost!.resources {
                state.base.resources.add(amount, of: id)
            }
        }
        XCTAssertFalse(store.state.reality.library.knownSchematics.contains("pointed_blade"))
        XCTAssertTrue(store.build(station))
        XCTAssertTrue(store.state.reality.library.knownSchematics.contains("pointed_blade"))
        let restored = try SaveCodec.decode(SaveCodec.encode(store.state))
        XCTAssertTrue(restored.reality.library.knownSchematics.contains("pointed_blade"))
    }

    func testManualSampleReplacementChangesPreviewAndCraftedProvenance() throws {
        var state = readyState()
        let recipe = PhysicalGearCraftingRules.pointedBlade
        let defaults = try XCTUnwrap(PhysicalGearCraftingRules.defaultSelections(for: recipe, in: state))
        let strongerPoint = try XCTUnwrap(
            PhysicalGearCraftingRules.candidates(for: recipe.requirements[0], in: state)
                .first { $0.sample.source == "great wolf" }
        )
        let chosen = defaults.map { $0.requirementID == "point.0" ? strongerPoint : $0 }
        let preview = try XCTUnwrap(PhysicalGearCraftingRules.preview(recipe, selections: chosen, in: state))
        XCTAssertEqual(preview.selections.map(\.sample.source), ["great wolf", "reed"])
        let output = try XCTUnwrap(PhysicalGearCraftingRules.craft(preview, in: &state))
        XCTAssertEqual(output.gearProfile?.consumedSamples.map(\.source), ["great wolf", "reed"])
    }

    func testTanneryHasThreeCanonicalDomainQualifiedWearForms() throws {
        let recipes = PhysicalGearCraftingRules.tanneryRecipes
        XCTAssertEqual(recipes.map(\.id), ["supple_coat", "working_gloves", "working_boots"])
        XCTAssertEqual(Set(recipes.map(\.slot)), [.armor, .hands, .feet])
        XCTAssertTrue(recipes.allSatisfy { $0.station == Stations.tannery && $0.stationCap == 5 })
        XCTAssertEqual(PhysicalGearCraftingRules.suppleCoat.requirements.map(\.id),
                       ["outer.0", "lining.0"])
        XCTAssertEqual(PhysicalGearCraftingRules.workingGloves.requirements.map(\.id),
                       ["hand.0", "facing.0"])
        XCTAssertEqual(PhysicalGearCraftingRules.workingBoots.requirements.map(\.id),
                       ["upper.0", "sole.0", "binding.0"])
        XCTAssertEqual(PhysicalGearCraftingRules.workingBoots.primaryRequirementIDs,
                       ["upper.0", "sole.0"])

        let sole = PhysicalGearCraftingRules.workingBoots.requirements[1]
        var creatureTimber = sample(.timber, grade: 30, source: "forged creature timber")
        creatureTimber.domain = .creature
        XCTAssertFalse(PhysicalGearCraftingRules.qualifies(creatureTimber, for: sole))
        let body = PhysicalGearCraftingRules.suppleCoat.requirements[0]
        var worldHide = sample(.hide, grade: 30, source: "forged world hide")
        worldHide.domain = .world
        XCTAssertFalse(PhysicalGearCraftingRules.qualifies(worldHide, for: body))
        XCTAssertFalse(PhysicalGearCraftingRules.qualifies(
            sample(.down, grade: 30, source: "lining only"), for: body))
    }

    func testTanneryCraftFreezesSpecialistAndConsumesChosenSamples() throws {
        for recipe in PhysicalGearCraftingRules.tanneryRecipes {
            var state = tanneryState()
            let preview = try XCTUnwrap(PhysicalGearCraftingRules.preview(recipe, in: state))
            let selected = preview.selections.map(\.sample)
            let output = try XCTUnwrap(PhysicalGearCraftingRules.craft(preview, in: &state))
            XCTAssertEqual(output.gearProfile?.specialistProfile, "tannery")
            XCTAssertEqual(output.gearProfile?.familyID, recipe.id)
            XCTAssertEqual(output.gearProfile?.qualityBand, .peerless)
            XCTAssertEqual(output.gearProfile?.gameplayFacts?.powerOffset, 0)
            XCTAssertEqual(output.gearProfile?.physicalReceipt?.flattenedUnits, selected)
            XCTAssertEqual(output.gearProfile?.physicalReceipt?.revisions.first?.components.map(\.role),
                           recipe.requirements.map { .authoredSocket($0.id) })
            let restored = try SaveCodec.decode(SaveCodec.encode(state))
            XCTAssertEqual(restored.base.inventory.stacks.first { $0.id == output.id }, output)
        }
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

    func testTanneryTierTwoEntitlementIsInertAndNeverCapsQuality() throws {
        var state = tanneryState()
        let before = try XCTUnwrap(PhysicalGearCraftingRules.preview(
            PhysicalGearCraftingRules.suppleCoat, in: state))
        XCTAssertEqual(before.outputTier, 5)
        XCTAssertEqual(before.rawEssence, 80)
        state.base.completedResearch.insert(PhysicalGearCraftingRules.tanneryWearTierTwo)
        state.base.capabilities.insert(PhysicalGearCraftingRules.tanneryTierTwoCapability)
        let after = try XCTUnwrap(PhysicalGearCraftingRules.preview(
            PhysicalGearCraftingRules.suppleCoat, in: state))
        XCTAssertEqual(after.outputTier, before.outputTier)
        XCTAssertEqual(after.qualityBand, before.qualityBand)
        XCTAssertEqual(after.rawEssence, before.rawEssence)
    }

    func testWorkingBootsAveragesTwoPrimaryUnitsBeforeSeventyThirtyWeighting() throws {
        var state = tanneryState()
        let world = state.base.worldMaterialReserve.units
        let creature = state.base.creatureMaterialReserve.units
        XCTAssertNotNil(state.base.worldMaterialReserve.consume(
            state.base.worldMaterialReserve.selections()))
        XCTAssertNotNil(state.base.creatureMaterialReserve.consume(
            state.base.creatureMaterialReserve.selections()))
        for var holding in world + creature {
            switch holding.unit.source {
            case "body hide", "binding resin": holding.unit.qualityBand = .peerless
            case "sole timber": holding.unit.qualityBand = .standard
            default: holding.unit.qualityBand = .rough
            }
            if holding.unit.domain == .world { state.base.worldMaterialReserve.add(holding) }
            else { state.base.creatureMaterialReserve.add(holding) }
        }
        let recipe = PhysicalGearCraftingRules.workingBoots
        let chosenSources = ["body hide", "sole timber", "binding resin"]
        let selections = try recipe.requirements.enumerated().map { index, requirement in
            try XCTUnwrap(PhysicalGearCraftingRules.candidates(for: requirement, in: state)
                .first { $0.sample.source == chosenSources[index] })
        }
        let preview = try XCTUnwrap(PhysicalGearCraftingRules.preview(
            recipe, selections: selections, in: state))
        XCTAssertEqual(preview.qualityBand, .exceptional)
        XCTAssertEqual(preview.outputTier, 4)
        XCTAssertEqual(preview.rawEssence, 80)
    }

    func testTanneryReceiptDrivesRecyclerOrderAndOriginalDomains() throws {
        var state = tanneryState()
        let preview = try XCTUnwrap(PhysicalGearCraftingRules.preview(
            PhysicalGearCraftingRules.workingBoots, in: state))
        let selected = preview.selections.map(\.sample)
        let output = try XCTUnwrap(PhysicalGearCraftingRules.craft(preview, in: &state))
        let recycle = try XCTUnwrap(RecyclerRules.preview(
            location: .stored, stackID: output.id, serviceTier: 3, in: state.base))
        XCTAssertEqual(recycle.route, .constructionReceipt)
        XCTAssertEqual(recycle.recoveryCapacity, 2)
        XCTAssertEqual(recycle.returnedSamples, Array(selected.prefix(2)))
        XCTAssertEqual(recycle.returnedSamples.map(\.stableUnitID),
                       selected.prefix(2).map(\.stableUnitID))
        XCTAssertEqual(recycle.returnedSamples.map(\.domain),
                       selected.prefix(2).map(\.domain))
    }

    func testEveryTanneryFormRejectsStaleExactUnitWithoutMutation() throws {
        for recipe in PhysicalGearCraftingRules.tanneryRecipes {
            var state = tanneryState()
            let preview = try XCTUnwrap(PhysicalGearCraftingRules.preview(recipe, in: state))
            let first = try XCTUnwrap(preview.selections.first?.reserveSelection)
            XCTAssertNotNil(state.base.consumeCraftMaterials([first]))
            let afterExternalChange = state
            XCTAssertNil(PhysicalGearCraftingRules.craft(preview, in: &state))
            XCTAssertEqual(state, afterExternalChange)
        }
    }

    func testBowyerCoversPhysicalTriangleAtFarReach() {
        let recipes = PhysicalGearCraftingRules.bowyerRecipes
        XCTAssertEqual(recipes.map(\.id), ["longbow", "sling", "throwing_set"])
        XCTAssertEqual(Set(recipes.compactMap(\.damage)), [.pierce, .crush, .rend])
        XCTAssertTrue(recipes.allSatisfy {
            $0.station == Stations.bowyer && $0.slot == .weapon && $0.reach == .far
        })
    }

    func testBowyerCanonicalSocketsAndClosedFamilies() {
        let longbow = PhysicalGearCraftingRules.longbow
        XCTAssertEqual(longbow.requirements.map(\.id), ["limb.0", "limb.1", "string.0"])
        XCTAssertEqual(longbow.requirements[0].allowedKinds, [.timber, .horn, .quill, .bone])
        XCTAssertEqual(longbow.requirements[1].allowedKinds, longbow.requirements[0].allowedKinds)
        XCTAssertEqual(longbow.requirements[2].allowedKinds, [.fibre, .hide, .fin])
        XCTAssertEqual(longbow.primaryRequirementIDs, ["limb.0", "limb.1"])

        let sling = PhysicalGearCraftingRules.sling
        XCTAssertEqual(sling.requirements.map(\.id), ["cord.0", "projectile.0", "pouch.0"])
        XCTAssertEqual(sling.requirements[0].allowedKinds, [.fibre, .hide, .fin])
        XCTAssertEqual(sling.requirements[1].allowedKinds,
                       [.rubble, .clay, .ore, .copper, .adamant, .bone, .tusk, .horn, .shell])
        XCTAssertEqual(sling.requirements[2].allowedKinds, [.fibre, .hide, .pelt])
        XCTAssertEqual(sling.primaryRequirementIDs, ["cord.0", "projectile.0"])

        let throwing = PhysicalGearCraftingRules.throwingSet
        XCTAssertEqual(throwing.requirements.map(\.id), ["edge.0", "edge.1", "carrier.0"])
        XCTAssertEqual(throwing.requirements[0].allowedKinds,
                       [.ore, .adamant, .obsidian, .claw, .chitin, .quill, .bone, .shell])
        XCTAssertEqual(throwing.requirements[1].allowedKinds,
                       throwing.requirements[0].allowedKinds)
        XCTAssertEqual(throwing.requirements[2].allowedKinds, [.fibre, .hide, .pelt, .fin])
        XCTAssertEqual(throwing.primaryRequirementIDs, ["edge.0", "edge.1"])
    }

    func testBowyerSocketsRejectCrossDomainLookalikes() {
        let limb = PhysicalGearCraftingRules.longbow.requirements[0]
        var forgedHorn = sample(.horn, grade: 50, source: "forged world horn")
        forgedHorn.domain = .world
        XCTAssertFalse(PhysicalGearCraftingRules.qualifies(forgedHorn, for: limb))

        let projectile = PhysicalGearCraftingRules.sling.requirements[1]
        var forgedOre = sample(.ore, grade: 50, source: "forged creature ore")
        forgedOre.domain = .creature
        XCTAssertFalse(PhysicalGearCraftingRules.qualifies(forgedOre, for: projectile))
        XCTAssertTrue(PhysicalGearCraftingRules.qualifies(
            sample(.ore, grade: 50, source: "ordinary ore"), for: projectile))
    }

    func testEveryBowyerSchematicPreviewsCommitsAndFreezesExactReceipt() throws {
        for recipe in PhysicalGearCraftingRules.bowyerRecipes {
            var state = bowyerState(tier: 1)
            let preview = try XCTUnwrap(PhysicalGearCraftingRules.preview(recipe, in: state), recipe.id)
            XCTAssertEqual(preview.selections.count, recipe.requirements.count, recipe.id)
            XCTAssertTrue(preview.selections.contains { $0.sample.domain == .world }, recipe.id)
            let selected = preview.selections.map(\.sample)
            let output = try XCTUnwrap(PhysicalGearCraftingRules.craft(preview, in: &state), recipe.id)
            let revision = try XCTUnwrap(output.gearProfile?.physicalReceipt?.revisions.first)
            XCTAssertEqual(revision.authority,
                           .construction(stationID: Stations.bowyer,
                                         schematicID: recipe.id, rulesVersion: 1))
            XCTAssertEqual(revision.components.map(\.role),
                           recipe.requirements.map { .authoredSocket($0.id) })
            XCTAssertEqual(revision.components.map(\.unit), selected)
            XCTAssertEqual(revision.resultingQualityBand, preview.qualityBand)
            XCTAssertEqual(revision.resultingConstructionTier, preview.outputTier)
            XCTAssertTrue(state.validatesPhysicalGearReceipts())
        }
    }

    func testPointedBladeUsesItsOwnUncappedQualityAndCost() throws {
        var state = readyState()
        let preview = try XCTUnwrap(PhysicalGearCraftingRules.preview(
            PhysicalGearCraftingRules.pointedBlade, in: state))
        XCTAssertEqual(preview.outputTier, preview.qualityBand.rawValue)
        XCTAssertEqual(preview.rawEssence,
                       PhysicalGearCraftingRules.essenceCost(for: max(1, preview.outputTier)))
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

    func testBowyerQualityIsUncappedAndTierDoesNotInflateIt() throws {
        var state = bowyerState(tier: 0)
        XCTAssertEqual(try XCTUnwrap(PhysicalGearCraftingRules.preview(
            PhysicalGearCraftingRules.longbow, in: state)).qualityBand, .peerless)
        state.base.stations[Stations.bowyer]?.tier = 1
        XCTAssertEqual(try XCTUnwrap(PhysicalGearCraftingRules.preview(
            PhysicalGearCraftingRules.longbow, in: state)).outputTier, 5)
        state.base.stations[Stations.bowyer]?.tier = 2
        let preview = try XCTUnwrap(PhysicalGearCraftingRules.preview(
            PhysicalGearCraftingRules.longbow, in: state))
        XCTAssertEqual(preview.outputTier, 5)
        XCTAssertEqual(preview.rawEssence, 80)
        let output = try XCTUnwrap(PhysicalGearCraftingRules.craft(preview, in: &state))
        XCTAssertEqual(output.gearProfile?.qualityBand, .peerless)
        XCTAssertEqual(output.gearProfile?.constructionTier, 5)
        XCTAssertEqual(output.gearProfile?.reach, .far)
        XCTAssertEqual(output.gearProfile?.damage, .pierce)
        XCTAssertEqual(output.gearProfile?.specialistProfile, "bowyer")
    }

    func testEveryBowyerFamilyAllowsLowGradePreviewButRejectsAStaleCommit() throws {
        for recipe in PhysicalGearCraftingRules.bowyerRecipes {
            var state = bowyerState(tier: 1)
            let originalWorld = state.base.worldMaterialReserve.units
            let originalCreature = state.base.creatureMaterialReserve.units
            XCTAssertEqual(state.base.worldMaterialReserve.consume(
                state.base.worldMaterialReserve.selections()), originalWorld.map(\.sample))
            XCTAssertEqual(state.base.creatureMaterialReserve.consume(
                state.base.creatureMaterialReserve.selections()), originalCreature.map(\.sample))
            for var unit in originalWorld {
                unit.unit.qualityBand = .rough
                state.base.worldMaterialReserve.add(unit)
            }
            for var unit in originalCreature {
                unit.unit.qualityBand = .rough
                state.base.creatureMaterialReserve.add(unit)
            }
            let preview = try XCTUnwrap(PhysicalGearCraftingRules.preview(recipe, in: state), recipe.id)
            XCTAssertEqual(preview.outputTier, 0, recipe.id)
            XCTAssertEqual(preview.rawEssence, 12, recipe.id)
            XCTAssertTrue(preview.isBelowSpecialistHeadline, recipe.id)
            guard case .ready = PhysicalGearCraftingRules.readiness(recipe, in: state) else {
                return XCTFail("\(recipe.id) incorrectly blocked low-tier specialist output")
            }

            let first = try XCTUnwrap(preview.selections.first)
            XCTAssertNotNil(state.base.consumeCraftMaterials(
                [try XCTUnwrap(first.reserveSelection)]), recipe.id)
            let afterExternalChange = state
            XCTAssertNil(PhysicalGearCraftingRules.craft(preview, in: &state), recipe.id)
            XCTAssertEqual(state, afterExternalChange, "\(recipe.id) stale preview debited state")
        }
    }

    func testPointedBladeQualityUsesPrimarySeventySecondaryThirtyWithoutCap() throws {
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
        XCTAssertEqual(preview.outputTier, 3)
        XCTAssertEqual(preview.rawEssence, 48)
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
        XCTAssertTrue(output.displayName.hasPrefix("Pointed Blade · reed grazer + reed"))
        XCTAssertNil(output.gearProfile?.inscription)
        XCTAssertEqual(output.gearProfile?.reforgeRank, 0)
        XCTAssertEqual(output.gearProfile?.legacyPowerCredit, 0)
        let recycler = try XCTUnwrap(RecyclerRules.preview(
            location: .stored, stackID: output.id, serviceTier: 3, in: state.base))
        XCTAssertEqual(recycler.returnedSamples,
                       Array(preview.selections.map(\.sample).prefix(1)))
    }

    func testPointedBladeFreezesCanonicalAdamantPeltEffectsThroughRelaunchAndConsumers() throws {
        var state = GameState.newGame()
        state.base.stations[Stations.blacksmith] = .init(isUnlocked: true, tier: 0)
        state.reality.library.knownSchematics.insert("pointed_blade")
        state.base.essence = 100
        var adamant = sample(.adamant, grade: 90, source: "peerless adamant")
        adamant.qualityBand = .peerless
        adamant = adamant.withStableID(.init(rawValue: "pointed-adamant"))
        var pelt = sample(.pelt, grade: 50, insulation: 70, source: "fine pelt")
        pelt.qualityBand = .fine
        pelt = pelt.withStableID(.init(rawValue: "pointed-pelt"))
        state.base.worldMaterialReserve.add(.init(unit: adamant, protectedReturn: false))
        state.base.creatureMaterialReserve.add(.init(unit: pelt, protectedReturn: false))

        let preview = try XCTUnwrap(PhysicalGearCraftingRules.preview(
            PhysicalGearCraftingRules.pointedBlade, in: state))
        XCTAssertEqual(preview.qualityBand, .exceptional)
        XCTAssertEqual(preview.materialPowerOffset, 0.75)
        XCTAssertEqual(preview.materialInitiativeModifier, -1)
        XCTAssertEqual(preview.materialHeatWard, 10)
        XCTAssertEqual(preview.appliedContributionIDs, ["forceful", "heavy", "insulated"])

        let output = try XCTUnwrap(PhysicalGearCraftingRules.craft(preview, in: &state))
        let facts = try XCTUnwrap(output.gearProfile?.gameplayFacts)
        XCTAssertEqual(output.effectivePower, 4.75)
        XCTAssertEqual(facts.powerOffset, 0.75)
        XCTAssertEqual(facts.initiativeModifier, -1)
        XCTAssertEqual(facts.heatWard, 10)
        XCTAssertEqual(facts.appliedContributionIDs, preview.appliedContributionIDs)

        let tradingPrice = max(4, Int(floor(4 * output.effectivePower)))
        XCTAssertEqual(tradingPrice, 19)
        let recycler = try XCTUnwrap(RecyclerRules.preview(
            location: .stored, stackID: output.id, serviceTier: 3, in: state.base))
        XCTAssertEqual(recycler.snapshot.gearProfile?.gameplayFacts, facts)
        XCTAssertEqual(recycler.returnedSamples, [adamant])

        let restored = try SaveCodec.decode(SaveCodec.encode(state))
        let relaunched = try XCTUnwrap(restored.base.inventory.stacks.first { $0.id == output.id })
        XCTAssertEqual(relaunched.gearProfile?.gameplayFacts, facts)
        XCTAssertEqual(relaunched.gearProfile?.physicalReceipt,
                       output.gearProfile?.physicalReceipt)
        XCTAssertEqual(relaunched.effectivePower, 4.75)
    }

    func testPointedBladeControlAndStrongestOnceMaterialEffects() {
        func selection(_ requirement: String, _ unit: CraftMaterialUnitV1, _ id: UInt64)
            -> PhysicalGearCraftingRules.Selection {
            .init(requirementID: requirement, binID: .init(rawValue: id), sampleIndex: 0,
                  sample: unit.withStableID(.init(rawValue: "effect-\(id)")))
        }
        var fang = sample(.fang, grade: 30, source: "standard fang")
        fang.qualityBand = .standard
        var hide = sample(.hide, grade: 30, source: "standard hide")
        hide.qualityBand = .standard
        let control = PhysicalGearCraftingRules.materialEffects(
            for: PhysicalGearCraftingRules.pointedBlade,
            selections: [selection("point.0", fang, 1), selection("grip.0", hide, 2)])
        XCTAssertEqual(control.powerOffset, 0.25)
        XCTAssertEqual(control.initiativeModifier, 0)
        XCTAssertEqual(control.heatWard, 0)
        XCTAssertEqual(control.contributionIDs, ["keen"])

        var adamant = sample(.adamant, grade: 90, source: "one")
        adamant.qualityBand = .peerless
        let duplicate = PhysicalGearCraftingRules.materialEffects(
            for: PhysicalGearCraftingRules.pointedBlade,
            selections: [selection("point.0", adamant, 3),
                         selection("point.0", adamant, 4)])
        XCTAssertEqual(duplicate.powerOffset, 0.75)
        XCTAssertEqual(duplicate.initiativeModifier, -1)
        XCTAssertEqual(duplicate.contributionIDs, ["forceful", "heavy"])
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
