import XCTest
@testable import Bookbinder

/// What a creature leaves behind (creature-system-spec §8).
///
/// **No authored drop tables** — the parts that composed the creature compose what it leaves.
final class MaterialTests: XCTestCase {

    func testEveryHarvestedMaterialKindHasAValidatedDistinctInventoryIdentity() throws {
        let assets = try MaterialKind.allCases.map { kind in
            let asset = try XCTUnwrap(MobGearSpriteV1Registry.mobDropAsset(for: kind), kind.rawValue)
            XCTAssertNoThrow(try NativeVisualRuntime.validate(asset), kind.rawValue)
            return asset
        }
        XCTAssertEqual(Set(assets.map(\.decodedRGBASHA256)).count, MaterialKind.allCases.count)
    }

    func testMaterialReserveRoundTripPreservesStableIdentityAndExactSample() throws {
        let sample = MaterialSample(kind: .hide,
            properties: MaterialProperties(hardness: 31, density: 42, insulation: 53,
                                           flexibility: 64, lustre: 75, reactivity: 86),
            grade: 67, source: "shaggy browser", qualifier: "ashen")
        let reserve = MaterialReserve(units: [
            MaterialReserveUnit(id: .init(rawValue: "sample-1"), sample: sample,
                                protectedReturn: true)
        ])

        let restored = try SaveCodec.makeDecoder().decode(
            MaterialReserve.self, from: SaveCodec.makeEncoder().encode(reserve))

        XCTAssertEqual(restored, reserve)
        XCTAssertEqual(restored.units.first?.sample, sample)
        XCTAssertEqual(restored.units.first?.id.rawValue, "sample-1")
        XCTAssertEqual(restored.units.first?.protectedReturn, true)
    }

    func testReserveSelectionUsesStableIDAndRefusesStaleBatchAtomically() throws {
        let first = MaterialSample(kind: .hide, properties: MaterialProperties(hardness: 20),
                                   grade: 30, source: "first")
        let second = MaterialSample(kind: .bone, properties: MaterialProperties(density: 80),
                                    grade: 70, source: "second")
        var reserve = MaterialReserve(units: [
            .init(id: .init(rawValue: "z"), sample: second),
            .init(id: .init(rawValue: "a"), sample: first)
        ])
        let selections = reserve.selections()
        XCTAssertEqual(selections.map(\.unitID.rawValue), ["a", "z"])

        var stale = selections[1]
        stale.sample.grade = 1
        XCTAssertNil(reserve.consume([selections[0], stale]))
        XCTAssertEqual(reserve.count, 2)

        XCTAssertEqual(reserve.consume(selections), [first, second])
        XCTAssertTrue(reserve.isEmpty)
    }

    func testHarvestReceiptIsStableAcrossReplayAndRelaunch() throws {
        let sample = MaterialSample(kind: .quill,
            properties: MaterialProperties(hardness: 72, flexibility: 31),
            grade: 64, source: "barbed glider", qualifier: "ashen")
        var reserve = MaterialReserve()
        reserve.addHarvested(sample, count: 3, sourceReceipt: "run:8:foe:91", dropOrdinal: 0)
        let first = reserve
        reserve.addHarvested(sample, count: 3, sourceReceipt: "run:8:foe:91", dropOrdinal: 0)
        XCTAssertEqual(reserve, first, "replaying combat conclusion duplicated its harvest")

        let restored = try SaveCodec.makeDecoder().decode(
            MaterialReserve.self, from: SaveCodec.makeEncoder().encode(reserve))
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
        for (kind, expected) in [(DamageKind.pierce, MaterialKind.fang),
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

    /// **Grade scales with trait extremity** — measured as distance from ordinary, so a strikingly
    /// *bare* creature is as interesting as a heavily armoured one.
    func testGradeFollowsHowRemarkableAnAnimalIsInEitherDirection() {
        let ordinary = ButcheryRules.grade(of: [50, 50], lustre: 0)
        let armoured = ButcheryRules.grade(of: [98, 50], lustre: 0)
        let bare = ButcheryRules.grade(of: [2, 50], lustre: 0)

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
        XCTAssertGreaterThan(plate.grade, 70)
        XCTAssertGreaterThanOrEqual(plate.rarity, .rare)
    }

    /// One unusual number must not carry a grade — top grades belong to animals that are
    /// remarkable throughout, or every short-haired thing leaves a treasure.
    func testOneOddNumberDoesntMakeATreasure() {
        let throughout = ButcheryRules.grade(of: [95, 95, 95], lustre: 0)
        let inOnePlace = ButcheryRules.grade(of: [95, 50, 50], lustre: 0)
        XCTAssertGreaterThan(throughout, inOnePlace * 2)
    }

    // MARK: It reaches the player

    @MainActor
    func testWinningAFightPutsThePartsInYourSatchel() throws {
        let store = GameStore(io: .temporary(name: "loot-\(UUID().uuidString)"))
        store.write("plains")
        store.bindAndDepart()
        store.mutate("stage a fight against something worth skinning") { state in
            guard var run = state.worlds.activeRun else { return }
            var traits = CreatureTraits()
            traits.size = 45
            traits.covering = Covering(hardness: 10, length: 80, coverage: 85)   // a pelt
            traits.boneDensity = 60
            let species = Species(id: InstanceID(rawValue: 1), traits: traits, worldSeed: 1)
            run.cast = [species]
            run.enemies = [WorldEnemy(id: InstanceID(rawValue: 1), speciesID: species.id,
                                      traits: traits, position: run.playerPosition, isAwake: true)]
            state.worlds.activeRun = run
            WorldRules.beginEncounter(triggeredBy: run.enemies[0], in: &state)
        }

        var guardCount = 0
        while store.activeEncounter?.outcome == nil, guardCount < 40 {
            guardCount += 1
            guard let foe = store.activeEncounter?.foes.first(where: \.isAlive) else { break }
            store.takeCombatAction(.attack(foe: foe.id))
        }
        XCTAssertEqual(store.activeEncounter?.outcome, .victory)

        let run = try XCTUnwrap(store.state.worlds.activeRun)
        let materials = run.materialReserve.units.map(\.sample)
        XCTAssertTrue(materials.contains { $0.kind == .pelt }, "the fur went nowhere")
        XCTAssertTrue(materials.contains { $0.kind == .bone })
        XCTAssertTrue(try XCTUnwrap(store.activeEncounter).spoils.contains { $0.lowercased().contains("pelt") },
                      "the victory screen didn't mention what dropped")
    }

    func testAMaterialStackRoundTripsThroughASave() throws {
        var traits = CreatureTraits()
        traits.covering = Covering(hardness: 80, length: 10, coverage: 80)
        let sample = ButcheryRules.materials(from: traits, named: "large armoured walker")[0]
        let stack = ItemStack(id: InstanceID(rawValue: 9), catalogID: Items.material,
                              count: 3, material: sample)

        let data = try SaveCodec.makeEncoder().encode(stack)
        let restored = try SaveCodec.makeDecoder().decode(ItemStack.self, from: data)
        XCTAssertEqual(restored, stack)
        XCTAssertEqual(restored.material?.source, "large armoured walker")
        XCTAssertFalse(restored.displayName.isEmpty)
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
