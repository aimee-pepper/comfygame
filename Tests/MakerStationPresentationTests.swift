import XCTest
@testable import Bookbinder

final class MakerStationPresentationTests: XCTestCase {
    func testScriptoriumExposesOnlyRealHandsInksRunebookCapabilitiesAndFrozenTransactions() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(contentsOf: root.appending(path: "Sources/Screens/StationViews.swift"),
                                encoding: .utf8)

        XCTAssertTrue(source.contains("case hands = \"Hands\""))
        XCTAssertTrue(source.contains("case inks = \"Inks\""))
        XCTAssertTrue(source.contains("case runebook = \"Runebook\""))
        XCTAssertTrue(source.contains("completedResearch.contains(\"pen_ink_mixing\")"))
        XCTAssertTrue(source.contains("completedResearch.contains(\"pen_compounds\")"))
        XCTAssertTrue(source.contains("previewCompoundFormalization(fingerprint:"))
        XCTAssertTrue(source.contains("store.formalizeCompound(quote)"))
        XCTAssertTrue(source.contains("store.previewCompoundRename(record.id"))
        XCTAssertTrue(source.contains("store.renameCompound(quote)"))
        XCTAssertTrue(source.contains("store.previewCompoundDeletion(record.id)"))
        XCTAssertTrue(source.contains("store.deleteCompound(quote)"))
        XCTAssertTrue(source.contains("Array(repeating: GridItem(.flexible(), spacing: 6), count: 3)"))
        XCTAssertFalse(source.contains("selectedAtoms"), "Runebook must formalize proven receipts, not arbitrary atoms")
    }

    func testCompoundRunebookPresentationDisclosesReadingFootprintAndExactRefusal() throws {
        let source = try XCTUnwrap(ContentCatalog.shared.pressureSources.first).id
        let atom = CompoundSemanticAtom(Sigil(id: .init(rawValue: 1), source: source,
                                               target: "illumination"))
        let receipt = ProvenStatementReceipt(
            fingerprint: PageRules.statementFingerprint(target: "illumination", atoms: [atom]),
            target: "illumination", atoms: [atom],
            vocabulary: [.target("illumination"), .source(source)],
            vocabularySchemaVersion: ProvenStatementReceipt.currentVocabularySchemaVersion,
            firstBoundRunIndex: 1)

        XCTAssertTrue(CompoundRunebookPresentation.reading(receipt).contains("Illumination"))
        XCTAssertTrue(CompoundRunebookPresentation.reading(receipt).contains("Moderate"))
        XCTAssertTrue(CompoundRunebookPresentation.footprint(receipt, hand: .crude)
            .contains("spelled out"))
        XCTAssertEqual(CompoundRunebookPresentation.message(.ineligible(.nestedCompound)),
                       PageRules.CompoundEligibilityIssue.nestedCompound.rawValue)
        XCTAssertEqual(CompoundRunebookPresentation.message(.insufficientResources),
                       "Formalization needs more Essence or pulp.")
    }

    func testStationResourceNamesUseCatalogueAndNeverExposeUnknownIDs() throws {
        let clay = try XCTUnwrap(ContentCatalog.shared.resource("clay"))
        XCTAssertEqual(StationCataloguePresentation.resourceName(clay.id), clay.name)
        let unknown: ResourceID = "internal_missing_station_resource"
        let fallback = StationCataloguePresentation.resourceName(unknown)
        XCTAssertEqual(fallback, "Unknown resource")
        XCTAssertFalse(fallback.contains(unknown.rawValue))
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(contentsOf: root.appending(path: "Sources/Screens/StationViews.swift"), encoding: .utf8)
        XCTAssertFalse(source.contains("option.resource.rawValue.capitalisedSentence"))
        XCTAssertFalse(source.contains("resource(resource)?.name ?? resource.rawValue"))
        XCTAssertFalse(source.contains("definition?.name ?? entry.id.rawValue"))
        XCTAssertTrue(source.contains("Text(\"From \\(sample.source)\")"))
        XCTAssertFalse(source.contains("Text(\"off a \\(sample.source)\")"))
    }

    func testConstructionRowsDescribeRequirementsRatherThanClaimingASelection() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(contentsOf: root.appending(path: "Sources/Screens/BlacksmithView.swift"), encoding: .utf8)
        XCTAssertTrue(source.contains("Needs \\(recipe.requirements.count) samples"))
        XCTAssertFalse(source.contains("\\(recipe.requirements.count) selected samples"))
    }

    func testReforgeUsesTheSamePowerTermAsEquipmentDetails() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(contentsOf: root.appending(path: "Sources/Screens/BlacksmithView.swift"), encoding: .utf8)
        XCTAssertTrue(source.contains("chip(\"+0.2 power\", .green)"))
        XCTAssertTrue(source.contains("String(format: \"power %.1f\", target.effectivePower + 0.2)"))
        XCTAssertTrue(source.contains("+0.2 power toward final"))
        XCTAssertFalse(source.contains("+0.2 rating"))
        XCTAssertFalse(source.contains("gear rating toward final"))
    }

    func testArmouryUsesCompactProfileAndExactSampleGrids() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(
            contentsOf: root.appending(path: "Sources/Screens/BlacksmithView.swift"),
            encoding: .utf8
        )
        let armoury = try XCTUnwrap(source.range(of: "private struct ArmouryTargetSheet"))
        let picker = try XCTUnwrap(source.range(of: "private struct SamplePicker"))
        let armourySource = String(source[armoury.lowerBound..<picker.lowerBound])
        let pickerSource = String(source[picker.lowerBound...])

        XCTAssertTrue(armourySource.contains("LazyVGrid(columns: profileColumns"))
        XCTAssertTrue(armourySource.contains("count: 3"))
        XCTAssertFalse(armourySource.contains("Section(\"Rebuild as\")"))
        XCTAssertTrue(pickerSource.contains("SixAcrossItemGrid(data: available"))
        XCTAssertTrue(pickerSource.contains("AnchoredItemDetailButton"))
        XCTAssertTrue(pickerSource.contains("ArmourySampleDetail"))
    }

    func testArmouryProtectivePiecesUseTheSharedPhysicalItemTray() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(
            contentsOf: root.appending(path: "Sources/Screens/BlacksmithView.swift"),
            encoding: .utf8
        )
        let armouryStart = try XCTUnwrap(source.range(of: "struct ArmouryView"))
        let armouryEnd = try XCTUnwrap(source.range(of: "struct WeaponsmithView"))
        let armoury = String(source[armouryStart.lowerBound..<armouryEnd.lowerBound])

        XCTAssertTrue(armoury.contains("SixAcrossItemGrid(data: targets, id: \\.id)"))
        XCTAssertTrue(armoury.contains("catalogueID: target.catalogID"))
        XCTAssertTrue(armoury.contains("identified: targetIsIdentified(target)"))
        XCTAssertTrue(armoury.contains("location: targetLocation(target)"))
        XCTAssertTrue(armoury.contains("case .stored: .stored"))
        XCTAssertTrue(armoury.contains("case .worn: .worn"))
        XCTAssertTrue(armoury.contains("case .stored(let stack): stack.identified"))
        XCTAssertTrue(armoury.contains(".presentationDetents([.medium, .large])"))
        XCTAssertTrue(armoury.contains(".presentationDragIndicator(.visible)"))
        XCTAssertTrue(armoury.contains("if targets.isEmpty"))
        XCTAssertTrue(armoury.contains("No eligible protective pieces are stored or worn."))
        XCTAssertTrue(armoury.contains("No eligible ordinary protective pieces. Show legacy masterworks to include them."))
        XCTAssertFalse(armoury.contains("Image(systemName: \"chevron.right\")"))
    }
    func testPlayerFacingReforgeLabelsUseRulesOwnedMaximum() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let paths = [
            "Sources/Screens/GearView.swift",
            "Sources/Screens/TradingPostView.swift",
            "Sources/Screens/StationViews.swift",
            "Sources/Rules/SmithRules.swift",
            "Sources/Model/Inventory.swift"
        ]
        let sources = try paths.map {
            try String(contentsOf: root.appending(path: $0), encoding: .utf8)
        }

        XCTAssertFalse(sources.contains { $0.contains("Reforged \\(upgradeLevel)/3") })
        XCTAssertFalse(sources.contains { $0.contains("Reforged \\(profile.reforgeRank)/3") })
        XCTAssertTrue(sources[0].contains("SmithRules.maximumReforgeLevel"))
        XCTAssertTrue(sources[1].contains("SmithRules.maximumReforgeLevel"))
        XCTAssertTrue(sources[2].contains("SmithRules.maximumReforgeLevel"))
        XCTAssertTrue(sources[3].contains("SmithRules.maximumReforgeLevel"))
        XCTAssertTrue(sources[4].contains("Tuning.Smith.maximumReforgeRank"))
    }

    func testBlacksmithRecipeGridReflowsBeforeTextShrinks() {
        XCTAssertEqual(MakerStationPresentationRules.recipeColumns(isAccessibilitySize: false), 3)
        XCTAssertEqual(MakerStationPresentationRules.recipeColumns(isAccessibilitySize: true), 2)
    }

    func testTradingPostKeepsTradeActionOutsideScrollableDetails() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(
            contentsOf: root.appending(path: "Sources/Screens/TradingPostView.swift"),
            encoding: .utf8
        )

        XCTAssertTrue(source.contains(".safeAreaInset(edge: .bottom, spacing: 0) { tradeActionBar }"))
        XCTAssertTrue(source.contains("Text(actionTitle).frame(maxWidth: .infinity)"))
        XCTAssertFalse(source.contains("Section {\n                    Button(actionTitle)"))
    }

    func testBlacksmithKeepsConstructAndReforgeActionsOutsideScrollableDetails() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(
            contentsOf: root.appending(path: "Sources/Screens/BlacksmithView.swift"),
            encoding: .utf8
        )

        XCTAssertTrue(source.contains("if let preview { constructionActionBar(preview) }"))
        XCTAssertTrue(source.contains("Text(\"Construct · \\(preview.essence) essence\").frame(maxWidth: .infinity)"))
        XCTAssertTrue(source.contains("reforgeActionBar"))
        XCTAssertTrue(source.contains("Text(\"Reforge\").frame(maxWidth: .infinity)"))
        XCTAssertTrue(source.contains("reforgeActionFootnote(readiness)"))
        XCTAssertTrue(source.contains("Needs \\(missing) more qualifying stock"))
        XCTAssertTrue(source.contains("Needs \\(max(0, need - have)) more essence."))
        XCTAssertTrue(source.contains("if let preview { rebuildActionBar(preview) }"))
        XCTAssertTrue(source.contains("Text(\"Rebuild · \\(preview.essence) essence\").frame(maxWidth: .infinity)"))
    }

    func testBlacksmithRecipesUseTheirExactSharedCatalogueIdentity() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(
            contentsOf: root.appending(path: "Sources/Screens/BlacksmithView.swift"),
            encoding: .utf8
        )

        let recipeTile = try XCTUnwrap(source.range(of: "private struct MakerRecipeTile"))
        let armouryTarget = try XCTUnwrap(source.range(of: "private struct ArmouryTargetSheet"))
        let recipeSurfaces = String(source[recipeTile.lowerBound..<armouryTarget.lowerBound])

        XCTAssertEqual(recipeSurfaces.components(separatedBy: "CatalogueItemPixelIdentity(").count - 1, 2)
        XCTAssertEqual(recipeSurfaces.components(separatedBy: "itemID: recipe.catalogFallback").count - 1, 2)
        XCTAssertEqual(recipeSurfaces.components(separatedBy: "identified: true").count - 1, 2)
    }

    func testLandingReadinessCopyComesFromRulesPreview() throws {
        var state = GameState.newGame()
        state.base.stations[Stations.blacksmith] = StationState(isUnlocked: true, tier: 0)
        state.base.essence = 100
        state.base.materialReserve.add(.init(
            id: .init(rawValue: "landing-point"),
            sample: sample(.fang, hardness: 60, source: "point")
        ))
        state.base.materialReserve.add(.init(
            id: .init(rawValue: "landing-grip"),
            sample: sample(.fibre, flexibility: 60, source: "grip")
        ))

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
        for (index, sample) in stock.enumerated() {
            state.base.materialReserve.add(.init(
                id: .init(rawValue: "overflow-reforge-\(index)"), sample: sample
            ))
        }
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

    func testEssenceSpringNamesAndConfirmsUnlearningBeforeMutation() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(contentsOf: root.appendingPathComponent(
            "Sources/Screens/StationViews.swift"), encoding: .utf8)
        let spring = try XCTUnwrap(source.range(of: "struct EssenceSpringView: View"))
        let tabs = try XCTUnwrap(source.range(of: "enum EssenceSpringTab", range: spring.lowerBound..<source.endIndex))
        let view = String(source[spring.lowerBound..<tabs.lowerBound])

        XCTAssertTrue(view.contains("Button(cost == 0 ? \"Nothing to unlearn\" : \"Unlearn · \\(cost)\")"))
        XCTAssertTrue(view.contains("pendingUnlearning = member"))
        XCTAssertTrue(view.contains("Button(\"Cancel\", role: .cancel)"))
        XCTAssertTrue(view.contains("Button(\"Unlearn\", role: .destructive)"))
        XCTAssertTrue(view.contains("This returns \\(points) learned points and costs \\(cost) essence."))
        XCTAssertEqual(view.components(separatedBy: "store.respec(member)").count - 1, 1,
                       "unlearning should mutate only from the confirmed destructive action")
    }

    private func sample(_ kind: MaterialKind, hardness: Double = 0,
                        flexibility: Double = 0, source: String) -> MaterialSample {
        MaterialSample(kind: kind,
                       properties: MaterialProperties(hardness: hardness,
                                                      flexibility: flexibility),
                       grade: 50, source: source)
    }
}
