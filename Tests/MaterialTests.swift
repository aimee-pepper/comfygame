import XCTest
@testable import Bookbinder

extension CraftMaterialUnitV1 {
    init(kind: MaterialFamilyID, properties: MaterialProperties, grade: Double,
         source: String, qualifier: String? = nil) {
        self.init(stableUnitID: .init(rawValue: "test-prototype-\(kind.rawValue)-\(source)-\(grade)"),
                  domain: .forFamily(kind), familyID: kind,
                  qualityBand: (try? .init(legacyGrade: grade)) ?? .rough,
                  properties: properties,
                  sourceReceipt: .legacy(originalKind: kind, frozenSource: source,
                                         qualifier: qualifier, migrationLocation: "test-fixture",
                                         originalIdentity: nil))
    }
}

extension CraftMaterialHoldingV1 {
    init(id: CraftMaterialUnitID, sample: CraftMaterialUnitV1, protectedReturn: Bool = false) {
        self.init(unit: sample.withStableID(id), protectedReturn: protectedReturn)
    }
}

extension CraftMaterialSelection {
    init(unitID: CraftMaterialUnitID, sample: CraftMaterialUnitV1) {
        self.init(unitID: unitID, unit: sample)
    }
}

extension WorldMaterialReserve {
    mutating func migrateLegacyStacks(_ stacks: inout [ItemStack], location: String) {
        var retained: [ItemStack] = []
        for stack in stacks {
            guard !stack.materials.isEmpty else { retained.append(stack); continue }
            for (ordinal, sample) in stack.materials.enumerated() where sample.domain == .world {
                let id = CraftMaterialUnitID(rawValue: "\(location):\(stack.id.rawValue):\(ordinal)")
                _ = add(.init(unit: sample.withStableID(id), protectedReturn: false))
            }
        }
        stacks = retained
    }
}

/// What a creature leaves behind (creature-system-spec §8).
///
/// **No authored drop tables** — the parts that composed the creature compose what it leaves.
final class MaterialTests: XCTestCase {
    func testTwoReserveFailureUsesOneCombinedBudgetAndPreservesDomains() {
        func holding(_ id: String, _ family: MaterialFamilyID,
                     protected: Bool = false) -> CraftMaterialHoldingV1 {
            let unit = CraftMaterialUnitV1(kind: family, properties: .init(), grade: 50,
                                           source: "fixture")
                .withStableID(.init(rawValue: id))
            return .init(unit: unit, protectedReturn: protected)
        }
        let world = WorldMaterialReserve(units: [
            holding("world-protected", .timber, protected: true),
            holding("world-a", .fibre), holding("world-b", .pulp)
        ])
        let creature = CreatureMaterialReserve(units: [
            holding("creature-a", .hide), holding("creature-b", .bone)
        ])
        let result = partitionCraftMaterialsForFailure(
            world: world, creature: creature, fraction: 0.5, outcomeID: 991)
        let kept = result.keptWorld.units + result.keptCreature.units
        let lost = result.lostWorld.units + result.lostCreature.units
        XCTAssertEqual(kept.count, 3, "one protected plus ceil(4 exposed × 0.5)")
        XCTAssertEqual(lost.count, 2)
        XCTAssertTrue(kept.contains { $0.id.rawValue == "world-protected" })
        XCTAssertTrue(result.keptWorld.units.allSatisfy { $0.unit.domain == .world })
        XCTAssertTrue(result.keptCreature.units.allSatisfy { $0.unit.domain == .creature })
        XCTAssertEqual(Set((kept + lost).map(\.id)),
                       Set((world.units + creature.units).map(\.id)))
    }

    func testIdenticalMobMaterialsStackInVictoryPresentationWithoutFlatteningSamples() {
        let hide = CraftMaterialUnitV1(kind: .hide, properties: .init(flexibility: 72),
                                  grade: 68, source: "shaggy browser")
        let otherHide = CraftMaterialUnitV1(kind: .hide, properties: .init(flexibility: 31),
                                       grade: 42, source: "smooth browser")
        let stacked = CombatRules.stackedMaterialSpoils([
            (hide, 2), (otherHide, 1), (hide, 3)
        ])

        XCTAssertEqual(stacked.count, 2)
        XCTAssertEqual(stacked[0].sample, hide)
        XCTAssertEqual(stacked[0].count, 5)
        XCTAssertEqual(stacked[1].sample, otherHide)
        XCTAssertEqual(stacked[1].count, 1)
    }

    func testLegacyMaterialVisualRegistryRemainsValidForItsAuthoredFamilies() throws {
        let visualFamilies: [MaterialFamilyID] = [
            .plate, .quill, .pelt, .down, .hide, .chitin, .fang, .tusk, .claw, .bone,
            .ichor, .timber, .fibre, .pulp, .toxin, .reagent,
        ]
        let assets = try visualFamilies.map { kind in
            let asset = try XCTUnwrap(MobGearSpriteV1Registry.mobDropAsset(for: kind), kind.rawValue)
            XCTAssertNoThrow(try NativeVisualRuntime.validate(asset), kind.rawValue)
            return asset
        }
        XCTAssertEqual(Set(assets.map(\.decodedRGBASHA256)).count, visualFamilies.count)
    }

    func testMaterialReserveRoundTripPreservesStableIdentityAndExactSample() throws {
        let sample = CraftMaterialUnitV1(kind: .hide,
            properties: MaterialProperties(hardness: 31, density: 42, insulation: 53,
                                           flexibility: 64, lustre: 75, reactivity: 86),
            grade: 67, source: "shaggy browser", qualifier: "ashen")
        let reserve = CreatureMaterialReserve(units: [
            CraftMaterialHoldingV1(id: .init(rawValue: "sample-1"), sample: sample,
                                protectedReturn: true)
        ])

        let restored = try SaveCodec.makeDecoder().decode(
            CreatureMaterialReserve.self, from: SaveCodec.makeEncoder().encode(reserve))

        XCTAssertEqual(restored, reserve)
        XCTAssertEqual(restored.units.first?.sample, sample.withStableID(.init(rawValue: "sample-1")))
        XCTAssertEqual(restored.units.first?.id.rawValue, "sample-1")
        XCTAssertEqual(restored.units.first?.protectedReturn, true)
    }

    func testReserveSelectionUsesStableIDAndRefusesStaleBatchAtomically() throws {
        let first = CraftMaterialUnitV1(kind: .hide, properties: MaterialProperties(hardness: 20),
                                   grade: 30, source: "first")
        let second = CraftMaterialUnitV1(kind: .bone, properties: MaterialProperties(density: 80),
                                    grade: 70, source: "second")
        var reserve = CreatureMaterialReserve(units: [
            .init(id: .init(rawValue: "z"), sample: second),
            .init(id: .init(rawValue: "a"), sample: first)
        ])
        let selections = reserve.selections()
        XCTAssertEqual(selections.map(\.unitID.rawValue), ["a", "z"])

        var stale = selections[1]
        stale.unit.qualityBand = .rough
        XCTAssertNil(reserve.consume([selections[0], stale]))
        XCTAssertEqual(reserve.count, 2)

        XCTAssertEqual(reserve.consume(selections)?.map(\.stableUnitID),
                       selections.map(\.unitID))
        XCTAssertTrue(reserve.isEmpty)
    }

    func testHarvestReceiptIsStableAcrossReplayAndRelaunch() throws {
        let sample = CraftMaterialUnitV1(kind: .quill,
            properties: MaterialProperties(hardness: 72, flexibility: 31),
            grade: 64, source: "barbed glider", qualifier: "ashen")
        var reserve = WorldMaterialReserve()
        reserve.addHarvested(sample, count: 3, sourceReceipt: "run:8:foe:91", dropOrdinal: 0)
        let first = reserve
        reserve.addHarvested(sample, count: 3, sourceReceipt: "run:8:foe:91", dropOrdinal: 0)
        XCTAssertEqual(reserve, first, "replaying combat conclusion duplicated its harvest")

        let restored = try SaveCodec.makeDecoder().decode(
            WorldMaterialReserve.self, from: SaveCodec.makeEncoder().encode(reserve))
        XCTAssertEqual(restored, first)
        XCTAssertEqual(restored.units.map(\.id), first.units.map(\.id))
    }

    // MARK: Covering decides which material

    func testWhatItWasWearingIsWhatItLeaves() {
        XCTAssertEqual(ButcheryRules.coveringMaterial(of: wearing(hardness: 90, length: 10, coverage: 90)), .plate)
        XCTAssertEqual(ButcheryRules.coveringMaterial(of: wearing(hardness: 90, length: 80, coverage: 60)), .quill)
        XCTAssertEqual(ButcheryRules.coveringMaterial(of: wearing(hardness: 10, length: 80, coverage: 85)), .pelt)
        XCTAssertEqual(ButcheryRules.coveringMaterial(of: wearing(hardness: 10, length: 80, coverage: 25)), .down)
        XCTAssertEqual(ButcheryRules.coveringMaterial(of: wearing(hardness: 10, length: 10, coverage: 60)), .hide)
    }

    /// Layered iridescence is what makes a hard covering chitin rather than plate.
    func testALayeredHardCoveringIsChitinNotPlate() {
        var beetle = wearing(hardness: 90, length: 10, coverage: 90)
        beetle.finish = Finish()
        beetle.finish.schiller = 60
        beetle.finish.shine = 20
        beetle.finish.opacity = 20
        XCTAssertEqual(ButcheryRules.coveringMaterial(of: beetle), .chitin)
    }

    func testTheWeaponCornerDecidesWhatComesOffIt() {
        for (kind, expected) in [(DamageKind.pierce, MaterialFamilyID.fang),
                                 (.crush, .tusk),
                                 (.rend, .claw)] {
            let kinds = ButcheryRules.materials(from: armed(with: kind), named: "x").map(\.kind)
            XCTAssertTrue(kinds.contains(expected), "a \(kind.rawValue) creature left \(kinds)")
        }
    }

    /// Something that carries its own light leaves something that still reacts.
    func testAGlowingCreatureLeavesIchor() {
        var glower = wearing(hardness: 10, length: 10, coverage: 50)
        glower.emanation = Emanation(strength: 80, light: 90, heat: 5, caustic: 5)
        let ichor = ButcheryRules.materials(from: glower, named: "x").first { $0.kind == .ichor }
        XCTAssertNotNil(ichor)
        XCTAssertGreaterThan(ichor?.properties.reactivity ?? 0, 50)
    }

    /// Nothing comes off a thing that had nothing.
    func testABareUnarmedBonelessThingLeavesAlmostNothing() {
        var nothing = CreatureTraits()
        nothing.size = 20
        nothing.covering = Covering(hardness: 0, length: 0, coverage: 0)
        nothing.boneDensity = 0
        XCTAssertTrue(ButcheryRules.materials(from: nothing, named: "x").isEmpty)
    }

    // MARK: Properties are inherited, not authored

    /// A pelt off a cold-world animal genuinely insulates better than one off a temperate animal —
    /// which is the whole reason to write a cold world.
    func testAPeltFromAColdWorldIsWarmerThanOneFromAMildOne() {
        let arctic = wearing(hardness: 5, length: 95, coverage: 95)
        let temperate = wearing(hardness: 5, length: 50, coverage: 60)

        let warm = ButcheryRules.materials(from: arctic, named: "x")[0]
        let mild = ButcheryRules.materials(from: temperate, named: "x")[0]
        XCTAssertGreaterThan(warm.properties.insulation, mild.properties.insulation)
    }

    func testHardMaterialsDontBendAndSoftOnesDo() {
        let plate = ButcheryRules.materials(from: wearing(hardness: 95, length: 5, coverage: 90), named: "x")[0]
        let hide = ButcheryRules.materials(from: wearing(hardness: 5, length: 10, coverage: 90), named: "x")[0]
        XCTAssertGreaterThan(hide.properties.flexibility, plate.properties.flexibility)
        XCTAssertGreaterThan(plate.properties.hardness, hide.properties.hardness)
    }

    // MARK: Quantity and grade

    /// **Quantity scales with size.** A bigger animal is more of everything it was made of.
    func testABiggerAnimalIsWorthMoreOfWhatItWasMadeOf() {
        var small = CreatureTraits(); small.size = 5
        var large = CreatureTraits(); large.size = 95
        var rng = SeededRNG(seed: 7)

        let fromSmall = (0..<40).map { _ in ButcheryRules.quantity(from: small, rng: &rng) }
        let fromLarge = (0..<40).map { _ in ButcheryRules.quantity(from: large, rng: &rng) }
        XCTAssertGreaterThan(mean(fromLarge), mean(fromSmall))
        XCTAssertTrue(fromSmall.allSatisfy { $0 >= 1 }, "a body yielded nothing at all")
    }

    /// **Quality scales with trait extremity** — measured as distance from ordinary, so a strikingly
    /// *bare* creature is as interesting as a heavily armoured one.
    func testQualityFollowsHowRemarkableAnAnimalIsInEitherDirection() {
        let ordinary = ButcheryRules.quality(of: [50, 50], lustre: 0)
        let armoured = ButcheryRules.quality(of: [98, 50], lustre: 0)
        let bare = ButcheryRules.quality(of: [2, 50], lustre: 0)

        XCTAssertLessThan(ordinary, armoured)
        XCTAssertEqual(armoured, bare, accuracy: 0.001,
                       "extremity in one direction counted and the other didn't")
    }

    func testAWorldOfMonstersDropsMonstrousParts() {
        var monster = CreatureTraits()
        monster.size = 98
        monster.covering = Covering(hardness: 98, length: 8, coverage: 96)
        monster.boneDensity = 95
        let plate = ButcheryRules.materials(from: monster, named: "x")[0]
        XCTAssertEqual(plate.kind, .plate)
        XCTAssertGreaterThanOrEqual(plate.qualityBand, .fine)
    }

    /// One unusual number must not carry quality — top bands belong to animals that are
    /// remarkable throughout, or every short-haired thing leaves a treasure.
    func testOneOddNumberDoesntMakeATreasure() {
        let throughout = ButcheryRules.quality(of: [95, 95, 95], lustre: 0)
        let inOnePlace = ButcheryRules.quality(of: [95, 50, 50], lustre: 0)
        XCTAssertGreaterThan(throughout, inOnePlace * 2)
    }

    // MARK: It reaches the player

    func testWinningAFightPutsThePartsInYourSatchel() throws {
        var traits = CreatureTraits()
        traits.size = 45
        traits.covering = Covering(hardness: 10, length: 80, coverage: 85)
        traits.boneDensity = 60
        guard case .frozen(let projection) = CreatureMaterialProjectionRules.freeze(
            traits: traits, habitat: .terrestrial
        ) else { return XCTFail("expected ecology-aware projection") }
        let species = Species(id: .init(rawValue: 1), traits: traits, worldSeed: 1,
                              habitat: .terrestrial, materialProjection: projection)
        let point = GridPoint(x: 0, y: 0)
        var run = WorldRun(runIndex: 1, book: .init(written: [], essencePaid: 0), mapSeed: 1,
                           rng: .init(seed: 2), map: .init(width: 1, height: 1,
                           tiles: [.init(isRevealed: true)], entry: point),
                           playerPosition: point, sourceDangerReceipt: .init(sourceBand: 1))
        run.cast = [species]
        var encounterRNG = SeededRNG(seed: 3)
        run.activeEncounter = CombatRules.makeEncounter(
            id: .init(rawValue: 4),
            foes: [.init(id: .init(rawValue: 5), speciesID: species.id, traits: traits,
                         stats: .init(displayName: "Browser", icon: "ant", maxHP: 1, attack: 1),
                         currentHP: 0)], party: [.binder], rng: &encounterRNG)
        var state = GameState.newGame()
        state.worlds.activeRun = run

        CombatRules.checkOutcome(in: &state)

        let awardedRun = try XCTUnwrap(state.worlds.activeRun)
        XCTAssertEqual(awardedRun.activeEncounter?.outcome, .victory)
        let materials = awardedRun.creatureMaterialReserve.units.map(\.sample)
        XCTAssertTrue(materials.contains { $0.kind == .pelt }, "the fur went nowhere")
        XCTAssertTrue(materials.contains { $0.kind == .bone })
        XCTAssertTrue(try XCTUnwrap(awardedRun.activeEncounter).spoils.contains { $0.lowercased().contains("pelt") },
                      "the victory screen didn't mention what dropped")
    }

    /// A stack written before materials existed must still load.
    func testAnItemStackWithNoMaterialStillLoads() throws {
        let json = """
        {"id": {"rawValue": 3}, "catalogID": "curio_shard", "count": 1, "identified": false}
        """
        let stack = try SaveCodec.makeDecoder().decode(ItemStack.self, from: Data(json.utf8))
        XCTAssertNil(stack.material)
        XCTAssertEqual(stack.count, 1)
    }

    // MARK: Helpers

    private func wearing(hardness: Double, length: Double, coverage: Double) -> CreatureTraits {
        var traits = CreatureTraits()
        traits.size = 50
        traits.covering = Covering(hardness: hardness, length: length, coverage: coverage)
        return traits
    }

    private func armed(with kind: DamageKind) -> CreatureTraits {
        var traits = CreatureTraits()
        traits.size = 50
        traits.armament.mix = switch kind {
        case .pierce: WeaponMix(pierce: 1, crush: 0, rend: 0)
        case .crush: WeaponMix(pierce: 0, crush: 1, rend: 0)
        case .rend: WeaponMix(pierce: 0, crush: 0, rend: 1)
        }
        traits.armament.setTotal(70)
        return traits
    }

    private func mean(_ values: [Int]) -> Double {
        Double(values.reduce(0, +)) / Double(values.count)
    }
}
