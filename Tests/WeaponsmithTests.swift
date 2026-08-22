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
        state.base.essence = 1_000
        if pattern { state.reality.library.knownPatterns.insert(PhysicalGearCraftingRules.maudFittingPattern) }
        let samples = [
            MaterialSample(kind: .plate, properties: .init(hardness: 80, density: 80, flexibility: 60, lustre: 60, reactivity: 60), grade: grade, source: "head"),
            MaterialSample(kind: .bone, properties: .init(hardness: 75, density: 75, flexibility: 65, lustre: 55, reactivity: 55), grade: grade, source: "haft"),
            MaterialSample(kind: .timber, properties: .init(hardness: 70, density: 70, flexibility: 65, lustre: 50, reactivity: 50), grade: grade, source: "binding"),
            MaterialSample(kind: .hide, properties: .init(hardness: 70, density: 70, flexibility: 65, lustre: 50, reactivity: 50), grade: grade, source: "spare")
        ]
        state.base.inventory.add(ItemStack(id: InstanceID(rawValue: 800), catalogID: Items.material,
                                           materials: samples))
        return state
    }

    func testTierMatrixKindsReachLeanAndCaps() throws {
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
            XCTAssertEqual(preview.outputTier, 3)
            XCTAssertTrue(preview.wastesGradeAboveCap)
        }
        let two = state(tier: 2, grade: 90)
        XCTAssertEqual(PhysicalGearCraftingRules.preview(PhysicalGearCraftingRules.fittedPoint,
                                                         in: two)?.outputTier, 4)
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

    func testAllPolearmKindsAreMidAndHeadPropertyMatchesChoice() throws {
        let state = state(pattern: true)
        for kind in DamageKind.allCases {
            let recipe = PhysicalGearCraftingRules.fittedPolearm(damage: kind)
            XCTAssertEqual(recipe.damage, kind)
            XCTAssertEqual(recipe.reach, .mid)
            XCTAssertEqual(recipe.intendedLean, kind == .crush ? "Might" : "Finesse")
            let head = try XCTUnwrap(recipe.requirements.first)
            XCTAssertEqual(head.floors.first?.property, kind == .crush ? .density : .hardness)
            XCTAssertNotNil(PhysicalGearCraftingRules.preview(recipe, in: state))

            var crafting = self.state(pattern: true)
            let preview = try XCTUnwrap(PhysicalGearCraftingRules.preview(recipe, in: crafting))
            let output = try XCTUnwrap(PhysicalGearCraftingRules.craft(preview, in: &crafting))
            XCTAssertEqual(output.gearProfile?.damage, kind)
            XCTAssertEqual(output.gearProfile?.reach, .mid)
        }
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
        state.base.activeParty.removeAll { $0 == index }
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
        let beforeCount = state.base.inventory.stacks.first { $0.id.rawValue == 800 }!.count
        let output = try XCTUnwrap(PhysicalGearCraftingRules.craft(preview, in: &state))
        XCTAssertEqual(output.gearProfile?.familyID, recipe.id)
        XCTAssertEqual(output.gearProfile?.damage, .rend)
        XCTAssertEqual(output.gearProfile?.reach, .close)
        XCTAssertEqual(output.gearProfile?.reforgeRank, 0)
        XCTAssertEqual(output.gearProfile?.consumedSamples, preview.selections.map(\.sample))
        XCTAssertEqual(state.base.inventory.stacks.first { $0.id.rawValue == 800 }?.count,
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
        XCTAssertEqual(store.state.base.essence, 0)

        var old = GameState.newGame()
        old.base.stations[Stations.weaponsmith] = StationState(isUnlocked: true, tier: 0)
        old.base.completedResearch.remove(PhysicalGearCraftingRules.weaponsmithPointRoot)
        let restored = try JSONDecoder().decode(GameState.self, from: JSONEncoder().encode(old))
        XCTAssertTrue(restored.base.completedResearch.contains(PhysicalGearCraftingRules.weaponsmithPointRoot))
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
        XCTAssertEqual(store.state.base.inventory.stacks.first { $0.id.rawValue == 800 }?.count, 4)
    }
}
