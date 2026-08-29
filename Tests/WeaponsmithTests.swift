import XCTest
@testable import Bookbinder

final class WeaponsmithTests: XCTestCase {
    func testTypedPatternKnowledgeRemainsTheExactCraftingGate() throws {
        var without = state(tier: 4, pattern: false)
        var with = without
        with.reality.library.knownPatterns.insert("maud_fitting_pattern")

        XCTAssertFalse(PhysicalGearCraftingRules.isUnlocked(
            PhysicalGearCraftingRules.fittedPolearm(damage: .pierce), in: without))
        XCTAssertTrue(PhysicalGearCraftingRules.isUnlocked(
            PhysicalGearCraftingRules.fittedPolearm(damage: .pierce), in: with))
        without.reality.library.knownPatterns.insert("retired_pattern")
        XCTAssertFalse(PhysicalGearCraftingRules.isUnlocked(
            PhysicalGearCraftingRules.fittedPolearm(damage: .pierce), in: without),
            "an unknown retained legacy ID became a live pattern grant")
    }

    func testTypedDiaryPayloadStillEmitsStableStringEvent() throws {
        let page = try XCTUnwrap(ContentCatalog.shared.diaryPage("maud_fitting_pattern"))
        XCTAssertEqual(page.teachesPattern, WorkshopPatternID(rawValue: "maud_fitting_pattern"))
        var state = GameState.newGame()

        XCTAssertTrue(WorldRules.readPage(page.id, in: &state)
            .contains(.learnedPattern(WorkshopPatternID(rawValue: "maud_fitting_pattern"))))
        XCTAssertTrue(state.reality.library.knownPatterns.contains(
            WorkshopPatternID(rawValue: "maud_fitting_pattern")))
    }

    func testWeaponsmithPatternAuthorityIsTyped() {
        let pattern: WorkshopPatternID = PhysicalGearCraftingRules.maudFittingPattern
        XCTAssertEqual(pattern.rawValue, "maud_fitting_pattern")
        XCTAssertEqual(WorkshopPatternRegistry.displayName(pattern), "Fitted Polearm Schematic")
        XCTAssertNil(WorkshopPatternRegistry.displayName("unknown_pattern"))
        XCTAssertEqual(DiaryPageDef.Kind.pattern.displayName, "A Schematic")
        XCTAssertEqual(DiaryPageDef.Kind.schematic.displayName, "A Schematic")
        XCTAssertEqual(DiaryPageDef.Kind.symbol.displayName, "A Sigil")
        XCTAssertEqual(SchematicPresentation.learnedEvent(pattern: pattern),
                       "A Schematic you didn't have: Fitted Polearm Schematic.")
        XCTAssertEqual(SchematicPresentation.learnedEvent(pattern: "unknown_pattern"),
                       "A Schematic you didn't have.")
        XCTAssertEqual(SchematicPresentation.learnedEvent(schematic: "unknown_schematic"),
                       "A Schematic you didn't have.")
    }

#if DEBUG
    func testAuthoredAtlasClassifiesBothWireKindsAsSchematicAndKeepsInternalIDSecondary() throws {
        let units = AuthoredTextAtlas.inventory().flatMap(\.units)
        let pattern = try XCTUnwrap(units.first { $0.id.contains("maud_fitting_pattern") })
        let schematic = try XCTUnwrap(units.first { $0.id.contains("oda_emanation_housing") })
        XCTAssertEqual(pattern.teachingKind, "Schematic")
        XCTAssertEqual(schematic.teachingKind, "Schematic")
        XCTAssertTrue(try XCTUnwrap(pattern.detail).contains(
            "Schematic: Fitted Polearm Schematic · Internal ID: maud_fitting_pattern"))
        XCTAssertTrue(try XCTUnwrap(schematic.detail).contains("Schematic:"))
        XCTAssertTrue(try XCTUnwrap(schematic.detail).contains("Internal ID: emanation_housing"))
    }
#endif
    private func state(tier: Int = 0, grade: Double = 70, pattern: Bool = false) -> GameState {
        var state = GameState.newGame()
        state.base.stations[Stations.weaponsmith] = StationState(isUnlocked: true, tier: tier)
        state.base.completedResearch.insert(PhysicalGearCraftingRules.weaponsmithPointRoot)
        state.base.capabilities.insert(PhysicalGearCraftingRules.weaponsmithPointCapability)
        state.base.essence = 1_000
        if pattern { state.reality.library.knownPatterns.insert(PhysicalGearCraftingRules.maudFittingPattern) }
        let samples: [CraftMaterialUnitV1] = [
            CraftMaterialUnitV1(kind: .ore, properties: .init(hardness: 80), grade: grade, source: "point"),
            CraftMaterialUnitV1(kind: .obsidian, properties: .init(hardness: 80), grade: grade, source: "edge"),
            CraftMaterialUnitV1(kind: .rubble, properties: .init(density: 80), grade: grade, source: "maul"),
            CraftMaterialUnitV1(kind: .timber, properties: .init(flexibility: 60), grade: grade, source: "haft"),
            CraftMaterialUnitV1(kind: .fibre, properties: .init(flexibility: 60), grade: grade, source: "binding"),
            CraftMaterialUnitV1(kind: .copper, properties: .init(lustre: 60), grade: grade, source: "fitting"),
            CraftMaterialUnitV1(kind: .hide, properties: .init(flexibility: 60), grade: grade, source: "grip")
        ].enumerated().map {
            $0.element.withStableID(.init(rawValue: "weaponsmith-fixture-\($0.offset)"))
        }
        for unit in samples {
            let holding = CraftMaterialHoldingV1(unit: unit, protectedReturn: false)
            if unit.domain == .world { state.base.worldMaterialReserve.add(holding) }
            else { state.base.creatureMaterialReserve.add(holding) }
        }
        return state
    }

    func testTierMatrixKindsReachLeanAndUncappedQuality() throws {
        let zero = state(tier: 0)
        XCTAssertNotNil(PhysicalGearCraftingRules.preview(PhysicalGearCraftingRules.fittedPoint, in: zero))
        XCTAssertNil(PhysicalGearCraftingRules.preview(PhysicalGearCraftingRules.fittedEdge, in: zero))
        XCTAssertNil(PhysicalGearCraftingRules.preview(PhysicalGearCraftingRules.fittedMaul, in: zero))

        let one = state(tier: 1, grade: 90)
        let fixed = [PhysicalGearCraftingRules.fittedPoint,
                     PhysicalGearCraftingRules.fittedEdge,
                     PhysicalGearCraftingRules.fittedMaul]
        XCTAssertEqual(fixed.map(\.damage), [.pierce, .rend, .crush])
        XCTAssertEqual(fixed.map(\.reach), [.close, .close, .close])
        XCTAssertEqual(fixed.map(\.intendedLean), ["Finesse", "Finesse", "Might"])
        for recipe in fixed {
            let preview = try XCTUnwrap(PhysicalGearCraftingRules.preview(recipe, in: one))
            XCTAssertEqual(preview.outputTier, 5)
            XCTAssertEqual(preview.qualityBand, .peerless)
            XCTAssertEqual(preview.rawEssence, 80)
        }
        let two = state(tier: 2, grade: 90)
        XCTAssertEqual(PhysicalGearCraftingRules.preview(PhysicalGearCraftingRules.fittedPoint,
                                                         in: two)?.outputTier, 5)
        let low = state(tier: 2, grade: 30)
        XCTAssertTrue(try XCTUnwrap(PhysicalGearCraftingRules.preview(
            PhysicalGearCraftingRules.fittedPoint, in: low)).isBelowSpecialistHeadline)
    }

    func testDiaryPatternPersistsBeforeBuildAndGatesPolearm() throws {
        var state = GameState.newGame()
        XCTAssertFalse(state.reality.library.knownPatterns.contains(PhysicalGearCraftingRules.maudFittingPattern))
        let events = WorldRules.readPage("maud_fitting_pattern", in: &state)
        XCTAssertTrue(events.contains(.learnedPattern(PhysicalGearCraftingRules.maudFittingPattern)))
        XCTAssertTrue(state.reality.library.knownPatterns.contains(PhysicalGearCraftingRules.maudFittingPattern))
        let restored = try JSONDecoder().decode(GameState.self, from: JSONEncoder().encode(state))
        XCTAssertTrue(restored.reality.library.knownPatterns.contains(PhysicalGearCraftingRules.maudFittingPattern))
        XCTAssertNil(PhysicalGearCraftingRules.preview(
            PhysicalGearCraftingRules.fittedPolearm(damage: .pierce), in: restored))

        var built = self.state(pattern: false)
        XCTAssertNil(PhysicalGearCraftingRules.preview(
            PhysicalGearCraftingRules.fittedPolearm(damage: .pierce), in: built))
        built.reality.library.knownPatterns.insert(PhysicalGearCraftingRules.maudFittingPattern)
        XCTAssertNotNil(PhysicalGearCraftingRules.preview(
            PhysicalGearCraftingRules.fittedPolearm(damage: .pierce), in: built))
    }

    func testAllPolearmKindsAreMidAndHeadFamiliesMatchChoice() throws {
        let state = state(pattern: true)
        for kind in DamageKind.allCases {
            let recipe = PhysicalGearCraftingRules.fittedPolearm(damage: kind)
            XCTAssertEqual(recipe.damage, kind)
            XCTAssertEqual(recipe.reach, .mid)
            XCTAssertEqual(recipe.intendedLean, kind == .crush ? "Might" : "Finesse")
            let head = try XCTUnwrap(recipe.requirements.first)
            XCTAssertTrue(head.floors.isEmpty)
            XCTAssertTrue(try XCTUnwrap(head.allowedIdentities).contains(
                .init(domain: .world,
                      family: kind == .crush ? .rubble : kind == .rend ? .obsidian : .ore)))
            XCTAssertNotNil(PhysicalGearCraftingRules.preview(recipe, in: state))

            var crafting = self.state(pattern: true)
            let preview = try XCTUnwrap(PhysicalGearCraftingRules.preview(recipe, in: crafting))
            let output = try XCTUnwrap(PhysicalGearCraftingRules.craft(preview, in: &crafting))
            XCTAssertEqual(output.gearProfile?.damage, kind)
            XCTAssertEqual(output.gearProfile?.reach, .mid)
            XCTAssertEqual(output.gearProfile?.gameplayFacts?.powerOffset, 0.5)
            XCTAssertEqual(output.effectivePower, Double(preview.qualityBand.rawValue) + 0.5)
        }
    }

    func testCanonicalSocketsRejectCrossDomainLookalikes() {
        let point = PhysicalGearCraftingRules.fittedPoint.requirements[0]
        var creatureOre = CraftMaterialUnitV1(kind: .ore, properties: .init(), grade: 50,
                                               source: "forged creature ore")
        creatureOre.domain = .creature
        XCTAssertFalse(PhysicalGearCraftingRules.qualifies(creatureOre, for: point))

        let fitting = PhysicalGearCraftingRules.fittedPoint.requirements[2]
        var worldHorn = CraftMaterialUnitV1(kind: .horn, properties: .init(), grade: 50,
                                            source: "forged world horn")
        worldHorn.domain = .world
        XCTAssertFalse(PhysicalGearCraftingRules.qualifies(worldHorn, for: fitting))
    }

    func testCanonicalSocketOrderAndClosedFamilyTables() {
        let point = PhysicalGearCraftingRules.fittedPoint
        XCTAssertEqual(point.requirements.map(\.id), ["point.0", "grip.0", "fitting.0"])
        XCTAssertEqual(point.primaryRequirementIDs, ["point.0"])
        XCTAssertEqual(point.requirements[0].allowedKinds,
                       [.ore, .adamant, .obsidian, .quartz, .fang, .quill, .bone, .tusk, .horn])
        XCTAssertEqual(point.requirements[1].allowedKinds,
                       [.fibre, .timber, .copper, .silver, .gold,
                        .hide, .pelt, .fin, .bone, .horn])
        XCTAssertEqual(point.requirements[2].allowedKinds,
                       [.copper, .silver, .gold, .quartz, .adamant, .bone, .horn, .quill])

        let edge = PhysicalGearCraftingRules.fittedEdge
        XCTAssertEqual(edge.requirements.map(\.id), ["edge.0", "grip.0", "fitting.0"])
        XCTAssertEqual(edge.primaryRequirementIDs, ["edge.0"])
        XCTAssertEqual(edge.requirements[0].allowedKinds,
                       [.ore, .adamant, .obsidian, .claw, .chitin, .quill, .bone, .shell])

        let maul = PhysicalGearCraftingRules.fittedMaul
        XCTAssertEqual(maul.requirements.map(\.id), ["head.0", "brace.0", "grip.0"])
        XCTAssertEqual(maul.primaryRequirementIDs, ["head.0", "brace.0"])
        XCTAssertEqual(maul.requirements[0].allowedKinds,
                       [.rubble, .ore, .copper, .adamant, .bone, .tusk, .horn, .plate, .shell])
        XCTAssertEqual(maul.requirements[1].allowedKinds,
                       [.timber, .ore, .adamant, .bone, .horn])

        let polearm = PhysicalGearCraftingRules.fittedPolearm(damage: .pierce)
        XCTAssertEqual(polearm.requirements.map(\.id), ["head.0", "haft.0", "binding.0"])
        XCTAssertEqual(polearm.primaryRequirementIDs, ["head.0", "haft.0"])
        XCTAssertEqual(polearm.requirements[2].allowedKinds,
                       [.fibre, .resin, .copper, .silver, .gold, .hide, .fin])
    }

    func testRoughAndPeerlessUseUncappedQualityPriceAndHalfPointOffset() throws {
        for (grade, band, price) in [(10.0, CraftMaterialQualityBand.rough, 12),
                                     (90.0, .peerless, 80)] {
            var crafting = state(grade: grade)
            let preview = try XCTUnwrap(PhysicalGearCraftingRules.preview(
                PhysicalGearCraftingRules.fittedPoint, in: crafting))
            XCTAssertEqual(preview.qualityBand, band)
            XCTAssertEqual(preview.outputTier, band.rawValue)
            XCTAssertEqual(preview.rawEssence, price)
            let output = try XCTUnwrap(PhysicalGearCraftingRules.craft(preview, in: &crafting))
            XCTAssertEqual(output.gearProfile?.qualityBand, band)
            XCTAssertEqual(output.effectivePower, Double(band.rawValue) + 0.5)

            let restored = try SaveCodec.decode(SaveCodec.encode(crafting))
            let restoredOutput = try XCTUnwrap(restored.base.inventory.stacks.first {
                $0.id == output.id
            })
            XCTAssertEqual(restoredOutput.gearProfile?.physicalReceipt,
                           output.gearProfile?.physicalReceipt)
            XCTAssertEqual(restoredOutput.effectivePower, output.effectivePower)
        }
    }

    func testIdentityExhaustionRefusesBeforePreviewOrMutation() {
        var exhausted = state()
        var terminal = ItemStack(id: .init(rawValue: UInt64.max), catalogID: "blade_chipped")
        terminal.gearProfile?.stableInstanceID = terminal.id
        exhausted.base.inventory.stacks.append(terminal)
        let before = exhausted
        XCTAssertNil(PhysicalGearCraftingRules.preview(
            PhysicalGearCraftingRules.fittedPoint, in: exhausted))
        XCTAssertEqual(exhausted, before)
    }

    func testAuthoredStationAndTierRungEconomy() throws {
        let station = try XCTUnwrap(ContentCatalog.shared.station(Stations.weaponsmith))
        XCTAssertEqual(station.builtBy, "maud")
        XCTAssertEqual(station.maxTier, 2)
        XCTAssertEqual(station.buildCost?.essence, 150)
        XCTAssertEqual(station.buildCost?.resources["ore"], 32)
        XCTAssertEqual(station.buildCost?.resources["copper"], 12)
        XCTAssertEqual(station.buildCost?.resources["gold"], 4)
        let broaden = try XCTUnwrap(ContentCatalog.shared.researchNode("weaponsmith_broaden"))
        XCTAssertEqual(broaden.cost.essence, 75)
        XCTAssertEqual(broaden.cost.resources["ore"], 16)
        XCTAssertEqual(broaden.cost.resources["copper"], 6)
        XCTAssertEqual(broaden.cost.resources["gold"], 2)
        XCTAssertEqual(broaden.grants.first?.tier, 1)
        let masterwork = try XCTUnwrap(ContentCatalog.shared.researchNode("weaponsmith_masterwork"))
        XCTAssertEqual(masterwork.cost.essence, 150)
        XCTAssertEqual(masterwork.cost.resources["ore"], 28)
        XCTAssertEqual(masterwork.cost.resources["copper"], 10)
        XCTAssertEqual(masterwork.cost.resources["gold"], 4)
        XCTAssertEqual(masterwork.grants.first?.tier, 2)
    }

    func testMaudAtHomeDiscountsPreviewAndExactDebit() throws {
        var state = state(tier: 0)
        XCTAssertTrue(state.base.seat("maud"))
        let index = try XCTUnwrap(state.base.roster.firstIndex { $0.traveller == "maud" })
        let memberID = try XCTUnwrap(state.base.persistentID(forRosterIndex: index))
        state.base.activeParty.removeAll { $0 == memberID }
        let preview = try XCTUnwrap(PhysicalGearCraftingRules.preview(
            PhysicalGearCraftingRules.fittedPoint, in: state))
        XCTAssertLessThan(preview.essence, preview.rawEssence)
        let before = state.base.essence
        XCTAssertNotNil(PhysicalGearCraftingRules.craft(preview, in: &state))
        XCTAssertEqual(state.base.essence, before - preview.essence)
    }

    func testCraftConsumesExactSamplesOnceAndFreezesReceiptWithoutFitState() throws {
        var state = state(tier: 1)
        let recipe = PhysicalGearCraftingRules.fittedEdge
        let preview = try XCTUnwrap(PhysicalGearCraftingRules.preview(recipe, in: state))
        let beforeCount = state.base.worldMaterialReserve.count
            + state.base.creatureMaterialReserve.count
        let output = try XCTUnwrap(PhysicalGearCraftingRules.craft(preview, in: &state))
        XCTAssertEqual(output.gearProfile?.familyID, recipe.id)
        XCTAssertEqual(output.gearProfile?.damage, .rend)
        XCTAssertEqual(output.gearProfile?.reach, .close)
        XCTAssertEqual(output.gearProfile?.reforgeRank, 0)
        XCTAssertEqual(output.gearProfile?.consumedSamples, preview.selections.map(\.sample))
        XCTAssertEqual(output.gearProfile?.physicalReceipt?.revisions.first?.components.map(\.unit),
                       preview.selections.map(\.sample))
        XCTAssertEqual(output.gearProfile?.gameplayFacts?.powerOffset, 0.5)
        XCTAssertEqual(state.base.worldMaterialReserve.count
                       + state.base.creatureMaterialReserve.count,
                       beforeCount - recipe.requirements.count)
        let after = state
        XCTAssertNil(PhysicalGearCraftingRules.craft(preview, in: &state))
        XCTAssertEqual(state, after)
    }

    @MainActor func testBuildAndOldSaveBothReceivePointRootWithoutExtraCharge() throws {
        let store = GameStore(io: .temporary(name: "weaponsmith-build-\(UUID().uuidString)"))
        let station = try XCTUnwrap(ContentCatalog.shared.station(Stations.weaponsmith))
        store.mutate("prepare Maud build") { state in
            state.reality.library.foundTravellers.insert("maud")
            state.base.essence = station.buildCost!.essence
            for (id, amount) in station.buildCost!.resources { state.base.resources.add(amount, of: id) }
        }
        XCTAssertTrue(store.build(station))
        XCTAssertTrue(store.state.base.completedResearch.contains(PhysicalGearCraftingRules.weaponsmithPointRoot))
        XCTAssertTrue(store.state.base.hasCapability(PhysicalGearCraftingRules.weaponsmithPointCapability))
        XCTAssertEqual(store.state.base.essence, 0)

        var old = GameState.newGame()
        old.base.stations[Stations.weaponsmith] = StationState(isUnlocked: true, tier: 0)
        old.base.completedResearch.remove(PhysicalGearCraftingRules.weaponsmithPointRoot)
        let restored = try JSONDecoder().decode(GameState.self, from: JSONEncoder().encode(old))
        XCTAssertTrue(restored.base.completedResearch.contains(PhysicalGearCraftingRules.weaponsmithPointRoot))
        XCTAssertTrue(restored.base.hasCapability(PhysicalGearCraftingRules.weaponsmithPointCapability))
    }

    func testCapabilityNotCompletionIsTheLiveWeaponsmithEntitlement() {
        var historyOnly = state()
        historyOnly.base.capabilities.remove(PhysicalGearCraftingRules.weaponsmithPointCapability)
        XCTAssertFalse(PhysicalGearCraftingRules.isUnlocked(
            PhysicalGearCraftingRules.fittedPoint, in: historyOnly))

        var entitlementOnly = state()
        entitlementOnly.base.completedResearch.remove(PhysicalGearCraftingRules.weaponsmithPointRoot)
        XCTAssertTrue(PhysicalGearCraftingRules.isUnlocked(
            PhysicalGearCraftingRules.fittedPoint, in: entitlementOnly))
    }

    @MainActor func testStoreReturnsFailureForStalePatternOrSampleCommit() throws {
        let store = GameStore(io: .temporary(name: "weaponsmith-stale-\(UUID().uuidString)"))
        store.mutate("prepare") { $0 = self.state(pattern: true) }
        let recipe = PhysicalGearCraftingRules.fittedPolearm(damage: .crush)
        let preview = try XCTUnwrap(PhysicalGearCraftingRules.preview(recipe, in: store.state))
        store.mutate("forget pattern") {
            $0.reality.library.knownPatterns.remove(PhysicalGearCraftingRules.maudFittingPattern)
        }
        XCTAssertFalse(store.craftPhysicalGear(preview))
        XCTAssertEqual(store.state.base.essence, 1_000)
        XCTAssertEqual(store.state.base.worldMaterialReserve.count
                       + store.state.base.creatureMaterialReserve.count, 7)
    }
}
