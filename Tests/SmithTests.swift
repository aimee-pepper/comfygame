import XCTest
@testable import Bookbinder

/// The Blacksmith: reforging what you already carry, and the building it happens in.
///
/// Two things are being defended here. **The economics** — that a reforging costs what it says,
/// spends the stock you'd miss least, and can't be repeated forever on a common piece. And **the
/// promise the screen makes** — that the tier it says you'll get is the number the fight delivers.
final class SmithTests: XCTestCase {

    // MARK: Helpers

    @MainActor
    private func store(named name: String = #function) -> GameStore {
        GameStore(io: .temporary(name: "smith-\(name)-\(UUID().uuidString)"))
    }

    private func sample(_ kind: MaterialFamilyID = .plate, hardness: Double,
                        grade: Double = 50, source: String = "bulwark") -> CraftMaterialUnitV1 {
        CraftMaterialUnitV1(kind: kind, properties: MaterialProperties(hardness: hardness),
                       grade: grade, source: source)
    }

    func testDirectLegacyMaterialBinCannotFundSmithAndRefusalIsByteEquivalent() throws {
        var state = GameState.newGame()
        let exact = sample(hardness: 70)
        let gear = ItemStack(id: .init(rawValue: 82), catalogID: "blade_chipped")
        state.base.inventory = Inventory(slots: 2, stacks: [gear,
            ItemStack(id: .init(rawValue: 81), catalogID: Items.material, materials: [exact])])
        state.base.essence = 500
        let encodedBefore = try SaveCodec.makeEncoder().encode(state)

        XCTAssertTrue(SmithRules.candidates(
            for: try XCTUnwrap(SmithRules.requirement(for: gear.catalogID, at: 0)),
            in: state).isEmpty)
        XCTAssertNil(SmithRules.reforge(stored: gear, in: &state))
        XCTAssertEqual(try SaveCodec.makeEncoder().encode(state), encodedBefore)
    }

    func testDecodedLegacyMaterialBinMigratesBeforeSmithCanUseIt() throws {
        var legacy = GameState.newGame()
        let exact = sample(hardness: 70, source: "legacy bin")
        legacy.base.inventory = Inventory(slots: 2, stacks: [
            ItemStack(id: .init(rawValue: 81), catalogID: Items.material, materials: [exact])
        ])

        let restored = try SaveCodec.makeDecoder().decode(
            GameState.self, from: SaveCodec.makeEncoder().encode(legacy))
        let requirement = SmithRules.Requirement(property: .hardness, minimum: 60,
                                                 count: 1, essence: 0, level: 0)

        XCTAssertTrue(restored.base.inventory.stacks.flatMap(\.materials).isEmpty)
        XCTAssertEqual(restored.base.worldMaterialReserve.selections().map(\.sample), [exact])
        XCTAssertEqual(SmithRules.candidates(for: requirement, in: restored).count, 1)
    }

    func testSmithCandidatesQuoteAndConsumeExactReserveUnit() throws {
        var state = GameState.newGame()
        let exact = sample(hardness: 70, source: "reserve source")
        state.base.worldMaterialReserve.add(.init(id: .init(rawValue: "reserve-smith-1"), sample: exact))
        let requirement = SmithRules.Requirement(property: .hardness, minimum: 60,
                                                 count: 1, essence: 0, level: 0)
        let candidate = try XCTUnwrap(SmithRules.candidates(for: requirement, in: state).first)
        XCTAssertEqual(candidate.reserveSelection.unitID.rawValue, "reserve-smith-1")

        XCTAssertTrue(SmithRules.consume([candidate], in: &state))
        XCTAssertTrue(state.base.worldMaterialReserve.isEmpty)
    }

    /// A storehouse with `count` pieces of hard stock and plenty of essence.
    @MainActor
    private func stocked(_ store: GameStore, hardness: Double = 90, count: Int = 8,
                         essence: Int = 500) {
        store.mutate("test: stock the shelf") { state in
            state.base.essence = essence
            for ordinal in 0..<count {
                state.base.worldMaterialReserve.add(CraftMaterialHoldingV1(
                    id: CraftMaterialUnitID(rawValue: "smith-fixture-\(ordinal)"),
                    sample: self.sample(hardness: hardness)))
            }
        }
    }

    // MARK: What it costs

    /// **Recipes ask for properties, never for item names** (materials-crafting-spec §5). A plate
    /// off a monstrous animal does a blade as much good as ore does — which is the whole reason a
    /// hoard kept for its own sake turns out to be worth something later.
    func testTheSmithAsksForAPropertyNotAThing() throws {
        let requirement = try XCTUnwrap(SmithRules.requirement(for: "blade_keen", at: 0))
        XCTAssertEqual(requirement.property, .hardness)
        XCTAssertGreaterThan(requirement.count, 0)
        XCTAssertGreaterThan(requirement.minimum, 0)
    }

    /// Every slot leans on a different property, so the material you'd throw away for a blade is
    /// the one you need for boots. Nothing in the hoard is universally junk.
    func testDifferentSlotsWantDifferentStock() {
        let wanted = Set(GearSlot.allCases.map { SmithRules.workingProperty(for: $0) })
        XCTAssertGreaterThanOrEqual(wanted.count, 4,
                                    "every slot wants the same thing, so half the hoard is junk")
    }

    /// It gets harder as it goes, or the fourth reforging is the same errand as the first.
    func testItGetsDearerEachTime() throws {
        let first = try XCTUnwrap(SmithRules.requirement(for: "the_long_grievance", at: 0))
        let third = try XCTUnwrap(SmithRules.requirement(for: "the_long_grievance", at: 2))
        XCTAssertGreaterThan(third.minimum, first.minimum)
        XCTAssertGreaterThan(third.count, first.count)
        XCTAssertGreaterThan(third.essence, first.essence)
    }

    /// Reforging is an equal three-rank within-tier track. Rarity and construction tier describe
    /// what was built; neither lets smith work promote an item into another specialist's tier.
    func testEveryPhysicalPieceHasTheSameThreeRankReforgeTrack() {
        let common = SmithRules.maximumLevel(for: ContentCatalog.shared.item("blade_chipped")!)
        let mythic = SmithRules.maximumLevel(for: ContentCatalog.shared.item("the_long_grievance")!)
        XCTAssertEqual(common, 3)
        XCTAssertEqual(mythic, 3)
        XCTAssertEqual(common, SmithRules.maximumReforgeLevel)
        XCTAssertNil(SmithRules.requirement(for: "blade_chipped", at: common),
                     "a finished piece was still offering another reforging")
    }

    // MARK: Doing it

    @MainActor
    func testReforgingRaisesRankWithoutChangingConstructionTier() throws {
        let store = store()
        stocked(store)
        store.mutate("test: carry it") { state in
            state.base.inventory.add(ItemStack(id: InstanceID(rawValue: 1), catalogID: "blade_keen"))
        }
        let stack = try XCTUnwrap(store.state.base.inventory.stacks.first { $0.catalogID == "blade_keen" })
        store.equip(stack, on: PartyMember.binder)

        let beforePower = try XCTUnwrap(store.worn(.weapon, by: PartyMember.binder)?.effectivePower)
        let beforeTier = try XCTUnwrap(store.worn(.weapon, by: PartyMember.binder)?.constructionTier)
        let target = try XCTUnwrap(store.reforgeable.first { $0.catalogID == "blade_keen" })
        XCTAssertTrue(store.readiness(of: target).isReady)
        store.reforge(target)

        XCTAssertEqual(store.worn(.weapon, by: PartyMember.binder)?.upgradeLevel, 1)
        let afterPower = try XCTUnwrap(store.worn(.weapon, by: PartyMember.binder)?.effectivePower)
        XCTAssertEqual(afterPower, beforePower + 0.2, accuracy: 0.000_001)
        XCTAssertEqual(store.worn(.weapon, by: PartyMember.binder)?.constructionTier, beforeTier,
                       "reforging crossed a construction-tier boundary")
    }

    /// A worn piece is reforged **in place**. The thing you most want improved is the one you're
    /// carrying, and making you take it off first would be a chore standing between you and the
    /// only thing the building does.
    @MainActor
    func testAWornPieceIsReforgedWithoutTakingItOff() throws {
        let store = store()
        stocked(store)
        store.mutate("test: carry it") { state in
            state.base.inventory.add(ItemStack(id: InstanceID(rawValue: 1), catalogID: "guard_padded"))
        }
        let stack = try XCTUnwrap(store.state.base.inventory.stacks.first { $0.catalogID == "guard_padded" })
        store.equip(stack, on: PartyMember.member(0))

        let target = try XCTUnwrap(store.reforgeable.first { $0.catalogID == "guard_padded" })
        store.reforge(target)

        XCTAssertEqual(store.worn(.armor, by: PartyMember.member(0))?.upgradeLevel, 1)
        XCTAssertNil(store.state.base.inventory.stacks.first { $0.catalogID == "guard_padded" },
                     "reforging a worn piece put a second one on the shelf")
    }

    /// **It spends what you'd miss least.** A reforging that silently ate your finest plate because
    /// it happened to share a bin would make you afraid to use the building at all.
    @MainActor
    func testItSpendsTheWorstStockThatClearsTheBar() throws {
        let store = store()
        store.mutate("test: one treasure among the tat") { state in
            state.base.essence = 500
            let samples = [self.sample(hardness: 99, grade: 99, source: "monstrous bulwark"),
                           self.sample(hardness: 40, grade: 20),
                           self.sample(hardness: 41, grade: 21),
                           self.sample(hardness: 42, grade: 22)]
            for (ordinal, sample) in samples.enumerated() {
                state.base.worldMaterialReserve.add(CraftMaterialHoldingV1(
                    id: CraftMaterialUnitID(rawValue: "smith-quality-\(ordinal)"),
                    sample: sample))
            }
            state.base.inventory.add(ItemStack(id: InstanceID(rawValue: 1), catalogID: "blade_chipped"))
        }
        let target = try XCTUnwrap(store.reforgeable.first { $0.catalogID == "blade_chipped" })
        store.reforge(target)

        let left = store.state.base.worldMaterialReserve.selections().map(\.sample)
        XCTAssertTrue(left.contains { $0.qualityBand == .peerless }, "the smith ate the best thing in the bin")
        XCTAssertEqual(left.count, 2)
    }

    /// Nothing happens on credit.
    @MainActor
    func testItRefusesWhenYouAreShort() throws {
        let store = store()
        store.mutate("test: nothing to work with") { state in
            state.base.essence = 500
            state.base.inventory.add(ItemStack(id: InstanceID(rawValue: 1), catalogID: "blade_chipped"))
        }
        let target = try XCTUnwrap(store.reforgeable.first)
        guard case .needsMaterials = store.readiness(of: target) else {
            return XCTFail("said it was ready with an empty shelf")
        }
        store.reforge(target)
        XCTAssertEqual(store.state.base.inventory.stacks.first?.upgradeLevel, 0)
    }

    /// Soft stock doesn't make a blade. The bar is the point of having a bar.
    @MainActor
    func testStockThatIsTooSoftDoesNotCount() throws {
        let store = store()
        stocked(store, hardness: 5)
        store.mutate("test: carry it") { state in
            state.base.inventory.add(ItemStack(id: InstanceID(rawValue: 1), catalogID: "blade_chipped"))
        }
        let target = try XCTUnwrap(store.reforgeable.first { $0.catalogID == "blade_chipped" })
        guard case .needsMaterials(let have, _) = store.readiness(of: target) else {
            return XCTFail("soft stock passed for hard")
        }
        XCTAssertEqual(have, 0)
    }

    // MARK: The piece is an object, not a kind

    /// **Reforging is per instance** (materials-crafting-spec §7). The whole point of upgrading
    /// over replacing is that *this* blade, the one you've carried, is the one that grows — so it
    /// can't go back in the bin with its unreforged twins.
    @MainActor
    func testAReforgedPieceDoesNotMergeWithItsUnreforgedTwins() throws {
        let store = store()
        stocked(store)
        store.mutate("test: three the same") { state in
            for id in 1...3 {
                state.base.inventory.add(ItemStack(id: InstanceID(rawValue: UInt64(id)),
                                                   catalogID: "guard_padded"))
            }
        }
        let target = try XCTUnwrap(store.reforgeable.first { $0.catalogID == "guard_padded" })
        store.reforge(target)

        let bins = store.state.base.inventory.stacks.filter { $0.catalogID == "guard_padded" }
        XCTAssertEqual(bins.count, 3, "physical gear instances merged and lost their own histories")
        XCTAssertEqual(bins.first { $0.upgradeLevel == 1 }?.count, 1)
        XCTAssertEqual(bins.filter { $0.upgradeLevel == 0 }.reduce(0) { $0 + $1.count }, 2)
    }

    /// The work survives a force-quit — pillar 2, and the piece is worthless if it doesn't.
    @MainActor
    func testTheWorkSurvivesAForceQuit() throws {
        let io = SaveFileIO.temporary(name: "smith-resume-\(UUID().uuidString)")
        let store = GameStore(io: io)
        stocked(store)
        store.mutate("test: carry it") { state in
            state.base.inventory.add(ItemStack(id: InstanceID(rawValue: 1), catalogID: "blade_keen"))
        }
        let stack = try XCTUnwrap(store.state.base.inventory.stacks.first { $0.catalogID == "blade_keen" })
        store.equip(stack, on: PartyMember.binder)
        // `reforge` already writes through (flush: true) — a force-quit at the anvil is the case.
        store.reforge(try XCTUnwrap(store.reforgeable.first { $0.catalogID == "blade_keen" }))

        let resumed = GameStore(io: io)
        XCTAssertEqual(resumed.worn(.weapon, by: PartyMember.binder)?.upgradeLevel, 1)
        XCTAssertEqual(resumed.worn(.weapon, by: PartyMember.binder)?.displayName,
                       "Keen Blade · Tier 2 · Reforged 1/\(SmithRules.maximumReforgeLevel)")
    }

    func testPlayerFacingReforgeNamesUseRulesOwnedMaximum() throws {
        var stack = ItemStack(id: InstanceID(rawValue: 219), catalogID: "blade_keen")
        stack.gearProfile?.reforgeRank = 1
        let expected = "Reforged 1/\(SmithRules.maximumReforgeLevel)"

        XCTAssertTrue(stack.displayName.contains(expected))
        XCTAssertTrue(ReforgeTarget.stored(stack).displayName.contains(expected))
        XCTAssertFalse(stack.displayName.contains("Reforged 1/3")
                       && SmithRules.maximumReforgeLevel != 3,
                       "Presentation must follow tuning rather than a frozen denominator")
    }

    /// Once loaded, even an untouched equipped piece writes its durable instance profile. Bare IDs
    /// remain accepted as a legacy input, but cannot preserve identity on their own.
    @MainActor
    func testAnUntouchedPieceStillSavesAsABareID() throws {
        let store = store()
        store.mutate("test: wear it") { $0.base.companion.equipped[.weapon] = "blade_keen" }
        let migrated = try SaveCodec.decode(SaveCodec.encode(store.state))
        let text = try XCTUnwrap(String(data: try SaveCodec.encode(migrated), encoding: .utf8))
        XCTAssertTrue(text.contains("\"gearProfile\""),
                      "an equipped piece omitted its durable instance profile")
    }

    // MARK: The building

    /// **You don't buy a forge — you find a smith** (Aimee, 6 Aug). Which hangs the crafting
    /// buildings off the search loop that already exists rather than off a shopping list.
    @MainActor
    func testTheForgeIsLockedUntilYouHaveMetTheSmith() throws {
        let store = store()
        XCTAssertFalse(store.state.base.station(Stations.blacksmith).isUnlocked)
        XCTAssertTrue(store.buildableStations.isEmpty, "offered a forge without a smith")

        let smith = try XCTUnwrap(ContentCatalog.shared.station(Stations.blacksmith)?.builtBy)
        store.mutate("test: meet them") { $0.reality.library.foundTravellers.insert(smith) }

        XCTAssertEqual(store.buildableStations.map(\.id), [Stations.blacksmith])
        XCTAssertFalse(store.state.base.station(Stations.blacksmith).isUnlocked,
                       "meeting them built it for free")
    }

    @MainActor
    func testBuildingItCostsWhatItSays() throws {
        let store = store()
        let station = try XCTUnwrap(ContentCatalog.shared.station(Stations.blacksmith))
        let cost = try XCTUnwrap(station.buildCost)
        store.mutate("test: meet them") {
            $0.reality.library.foundTravellers.insert(station.builtBy!)
        }

        XCTAssertFalse(store.build(station), "built it while short")
        XCTAssertFalse(store.shortfall(for: station).isEmpty)

        store.mutate("test: haul it home") { state in
            state.base.essence = cost.essence
            for (id, amount) in cost.resources { state.base.resources.add(amount, of: id) }
        }
        XCTAssertTrue(store.build(station))
        XCTAssertTrue(store.state.base.station(Stations.blacksmith).isUnlocked)
        XCTAssertEqual(store.state.base.essence, 0, "the forge was free after all")
        XCTAssertTrue(store.buildableStations.isEmpty, "still offering a forge that stands there")
    }

    /// The smith is findable the same way everybody else is: by writing the world they're in.
    func testTheSmithIsFindableByWritingTheRightWorld() throws {
        let smith = try XCTUnwrap(ContentCatalog.shared.traveller("halloway"))
        XCTAssertFalse(smith.signature.isEmpty, "a traveller nobody can reach")
        for index in smith.signature.indices {
            XCTAssertTrue(
                ContentCatalog.shared.diaryPages.contains {
                    $0.about == smith.id && $0.clueIndex == index
                },
                "no page names piece \(index) of the smith's whereabouts")
        }
    }
}
