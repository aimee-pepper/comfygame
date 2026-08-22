import XCTest
@testable import Bookbinder

final class MakerStationPresentationTests: XCTestCase {
    func testGearPresentationCopyUsesNaturalStockCountsAndOlderSaveCopy() {
        XCTAssertEqual(GearPresentationCopy.piecesOfStock(0), "0 pieces of stock")
        XCTAssertEqual(GearPresentationCopy.piecesOfStock(1), "1 piece of stock")
        XCTAssertEqual(GearPresentationCopy.piecesOfStock(4), "4 pieces of stock")
        XCTAssertEqual(GearPresentationCopy.moreQualifyingPiecesOfStock(1),
                       "1 more qualifying piece of stock")
        XCTAssertEqual(GearPresentationCopy.moreQualifyingPiecesOfStock(3),
                       "3 more qualifying pieces of stock")
        XCTAssertEqual(GearPresentationCopy.olderSaveArtUnavailable,
                       "From an older save. Detailed item art is unavailable.")
        XCTAssertEqual(GearPresentationCopy.physicalProtection(offset: 0), "full physical protection")
        XCTAssertEqual(GearPresentationCopy.physicalProtection(offset: -0.5), "0.5 less physical protection")
        XCTAssertEqual(GearPresentationCopy.physicalProtection(offset: -1), "1 less physical protection")
        XCTAssertEqual(GearPresentationCopy.physicalProtection(offset: 0.5), "0.5 more physical protection")
        XCTAssertEqual(GearPresentationCopy.rarity(.common), "Common")
        XCTAssertEqual(GearPresentationCopy.rarity(.uncommon), "Uncommon")
        XCTAssertEqual(GearPresentationCopy.rarity(.rare), "Rare")
        XCTAssertEqual(GearPresentationCopy.rarity(.mythic), "Mythic")
        XCTAssertEqual(GearPresentationCopy.damage(.rend), "Rend")
        XCTAssertEqual(GearPresentationCopy.damage(.pierce), "Pierce")
        XCTAssertEqual(GearPresentationCopy.reach(.close), "Close")
        XCTAssertEqual(GearPresentationCopy.reach(.mid), "Mid")
        XCTAssertEqual(GearPresentationCopy.reach(.far), "Far")
    }

    func testStepFivePlayerCopyAvoidsImplementationTermsOnScopedSurfaces() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        let paths = [
            "Sources/App/RootView.swift", "Sources/Screens/BlacksmithView.swift",
            "Sources/Screens/RecyclerView.swift", "Sources/Screens/TradingPostView.swift",
            "Sources/Screens/AuthoredTextAtlasView.swift", "Sources/Screens/WorldView.swift",
            "Sources/Rules/RecyclerRules.swift"
        ]
        let visibleStringPattern = try NSRegularExpression(pattern: #"\"(?:[^\"\\]|\\.)*\""#)
        let strings = try paths.flatMap { path -> [String] in
            let source = try String(contentsOf: root.appending(path: path), encoding: .utf8)
            let range = NSRange(source.startIndex..., in: source)
            return visibleStringPattern.matches(in: source, range: range).compactMap {
                Range($0.range, in: source).map { String(source[$0]).lowercased() }
            }
        }.joined(separator: "\n")
        for retired in ["receipt detail", "legacy receipt", "legacy masterwork",
                        "construction profile", "authored salvage profile", "provenance",
                        "workshop pattern", "a rune"] {
            XCTAssertFalse(strings.contains(retired), "retired player copy: \(retired)")
        }
        let blacksmith = try String(contentsOf: root.appending(path: "Sources/Screens/BlacksmithView.swift"), encoding: .utf8)
        let blacksmithStrings = visibleStringPattern.matches(
            in: blacksmith, range: NSRange(blacksmith.startIndex..., in: blacksmith)
        ).compactMap { Range($0.range, in: blacksmith).map { String(blacksmith[$0]) } }
        XCTAssertFalse(blacksmithStrings.contains {
            let playerCopy = $0.replacingOccurrences(of: #"\\\([^)]*\)"#, with: "", options: .regularExpression)
            return playerCopy.range(of: #"\bsamples?\b"#, options: .regularExpression) != nil
        })
    }

    func testReturnDetailsLeadWithCanonicalNameAndHideRawKeys() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(contentsOf: root.appending(path: "Sources/App/RootView.swift"), encoding: .utf8)
        let start = try XCTUnwrap(source.range(of: "private func receiptDetail("))
        let end = try XCTUnwrap(source.range(of: "private func receiptDetailOverlay("))
        let detail = String(source[start.lowerBound..<end.lowerBound])
        XCTAssertTrue(detail.contains("Text(line.compatibilityGain.name)"))
        XCTAssertTrue(detail.contains("GearPresentationCopy.olderSaveArtUnavailable"))
        XCTAssertFalse(detail.contains("resource.id.rawValue"))
        XCTAssertFalse(detail.contains("item.snapshot.catalogID.rawValue"))
        XCTAssertFalse(detail.contains("LabeledContent(\"Identity\""))
        XCTAssertTrue(source.contains("Text(\"DETAILS\")"))
    }

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
        XCTAssertEqual(CompoundRunebookPresentation.sigilCount(receipt), "2 Sigils in this Compound")
        XCTAssertTrue(CompoundRunebookPresentation.accessibilityLabel(receipt).hasPrefix(
            "2 Sigils in this Compound. Illumination:"))
        XCTAssertTrue(CompoundRunebookPresentation.footprint(receipt, hand: .crude)
            .contains("spelled out"))
        XCTAssertEqual(CompoundRunebookPresentation.message(.ineligible(.nestedCompound)),
                       "A Compound cannot contain another Compound.")
        XCTAssertEqual(CompoundRunebookPresentation.message(.insufficientResources),
                       "Formalization needs more Essence or pulp.")
    }

    func testCompoundSigilCountUsesFrozenVocabularyNotSemanticAtomMultiplicity() throws {
        let source = try XCTUnwrap(ContentCatalog.shared.pressureSources.first).id
        var atom = CompoundSemanticAtom(Sigil(id: .init(rawValue: 1), source: source,
                                               target: "illumination"))
        func receipt(_ vocabulary: [LexemeIdentity]) -> ProvenStatementReceipt {
            ProvenStatementReceipt(fingerprint: "fixture", target: "illumination", atoms: [atom],
                                   vocabulary: vocabulary,
                                   vocabularySchemaVersion: ProvenStatementReceipt.currentVocabularySchemaVersion,
                                   firstBoundRunIndex: 1)
        }
        XCTAssertEqual(CompoundRunebookPresentation.sigilCount(receipt([])), "0 Sigils in this Compound")
        XCTAssertEqual(CompoundRunebookPresentation.sigilCount(receipt([.target("illumination")])),
                       "1 Sigil in this Compound")
        let basic = receipt([.target("illumination"), .source(source)])
        XCTAssertEqual(atom.count, 1)
        XCTAssertEqual(CompoundRunebookPresentation.sigilCount(basic), "2 Sigils in this Compound")
        XCTAssertEqual(CompoundRunebookPresentation.sigilCount(
            receipt([.target("illumination"), .source(source), .qualifier("great")])),
            "3 Sigils in this Compound")
        atom.count = 17
        let multiplied = receipt([.target("illumination"), .source(source)])
        XCTAssertNotEqual(multiplied.atoms, basic.atoms)
        XCTAssertEqual(CompoundRunebookPresentation.sigilCount(multiplied),
                       CompoundRunebookPresentation.sigilCount(basic))
    }

    func testCompoundEligibilityIssuesHaveExactPlayerCopyWithoutChangingRawCompatibility() {
        let expected: [(PageRules.CompoundEligibilityIssue, String)] = [
            (.incomplete, "A Compound needs one complete Subject-and-Focus statement."),
            (.multipleTargets, "A Compound can have exactly one Subject."),
            (.tooFewAtoms, "A Compound needs at least two Sigils."),
            (.tooManyAtoms, "A Compound can contain at most five Sigils."),
            (.nestedCompound, "A Compound cannot contain another Compound."),
            (.unknownAtom, "Every Sigil must be known before this statement can be formalized.")
        ]
        for (issue, copy) in expected {
            XCTAssertEqual(CompoundRunebookPresentation.message(.ineligible(issue)), copy)
            XCTAssertFalse(issue.rawValue.isEmpty)
        }
        XCTAssertEqual(PageRules.CompoundEligibilityIssue.tooFewAtoms.rawValue,
                       "A compound needs at least two atomic Sigils.")
    }

    func testCompoundAssemblyVisibleStringsDoNotExposeAtomTerminologyAndCountCanWrap() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(contentsOf: root.appending(path: "Sources/Screens/StationViews.swift"), encoding: .utf8)
        let pattern = try NSRegularExpression(pattern: #"\"(?:[^\"\\]|\\.)*\""#)
        let strings = pattern.matches(in: source, range: NSRange(source.startIndex..., in: source))
            .compactMap { Range($0.range, in: source).map { String(source[$0]) } }
        XCTAssertFalse(strings.contains { value in
            let playerCopy = value.replacingOccurrences(of: #"\\\([^)]*\)"#, with: "", options: .regularExpression)
            return playerCopy.range(of: #"\batom(?:ic|s)?\b"#, options: [.regularExpression, .caseInsensitive]) != nil
        })
        XCTAssertTrue(source.contains("CompoundRunebookPresentation.sigilCount(receipt)"))
        XCTAssertTrue(source.contains(".fixedSize(horizontal: false, vertical: true)"))
        XCTAssertTrue(source.contains(".accessibilityLabel(CompoundRunebookPresentation.accessibilityLabel(receipt))"))
        XCTAssertFalse(source.contains("Text(\"\\(receipt.atoms.count) atoms\")"))
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
        XCTAssertTrue(source.contains("GearPresentationCopy.piecesOfStock(recipe.requirements.count)"))
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
        XCTAssertTrue(armoury.contains("No eligible ordinary protective pieces. Include gear from older saves to see compatible pieces."))
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
