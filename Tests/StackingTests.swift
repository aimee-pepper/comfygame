import XCTest
@testable import Bookbinder

final class DistilleryRequirementAuthorityTests: XCTestCase {
    func testCatalystOptionsAreDerivedFromTheAttunementRequirement() {
        for attunement in CoreAttunement.allCases {
            let expected = DistilleryRules.requirement(for: attunement).catalysts
            XCTAssertEqual(DistilleryRules.catalystOptions(for: attunement).map(\.0),
                           expected.map(\.resource))
            XCTAssertEqual(DistilleryRules.catalystOptions(for: attunement).map(\.1),
                           expected.map(\.amount))
        }
    }

    func testHeatCandidateThresholdUsesTheSharedRequirement() {
        let requirement = DistilleryRules.requirement(for: .heat)
        let accepted = MaterialSample(kind: .bone,
            properties: MaterialProperties(insulation: 25, reactivity: 60),
            grade: 50, source: "test")
        let tooCold = MaterialSample(kind: .bone,
            properties: MaterialProperties(insulation: 24, reactivity: 60),
            grade: 50, source: "test")
        XCTAssertTrue(requirement.accepts(accepted))
        XCTAssertFalse(requirement.accepts(tooCold))
    }

    func testCausticKindAndLightPropertyThresholdsUseSharedRequirements() {
        let reactiveReagent = MaterialSample(kind: .reagent,
            properties: MaterialProperties(reactivity: 60), grade: 50, source: "test")
        let reactiveBone = MaterialSample(kind: .bone,
            properties: MaterialProperties(reactivity: 60), grade: 50, source: "test")
        XCTAssertTrue(DistilleryRules.requirement(for: .caustic).accepts(reactiveReagent))
        XCTAssertFalse(DistilleryRules.requirement(for: .caustic).accepts(reactiveBone))

        let luminous = MaterialSample(kind: .quill,
            properties: MaterialProperties(hardness: 30, lustre: 60), grade: 50, source: "test")
        let tooSoft = MaterialSample(kind: .quill,
            properties: MaterialProperties(hardness: 29, lustre: 60), grade: 50, source: "test")
        XCTAssertTrue(DistilleryRules.requirement(for: .light).accepts(luminous))
        XCTAssertFalse(DistilleryRules.requirement(for: .light).accepts(tooSoft))
    }

    func testAttunementReadinessNamesTheExactMissingInput() throws {
        var state = GameState.newGame()
        state.base.stations[Stations.distillery] = StationState(isUnlocked: true, tier: 0)
        state.base.essence = 0
        let sample = MaterialSample(kind: .reagent,
            properties: MaterialProperties(insulation: 30, reactivity: 80),
            grade: 70, source: "ashen bloom")
        state.base.inventory.add(ItemStack(id: InstanceID(rawValue: 1), catalogID: Items.material,
                                           material: sample))
        let candidate = try XCTUnwrap(DistilleryRules.candidates(for: .heat, in: state).first)

        XCTAssertEqual(DistilleryRules.readiness(.heat, candidate: candidate,
                                                  catalyst: Resources.sulfur, in: state),
                       .needsEssence(have: 0, need: DistilleryRules.attuneEssence))

        state.base.essence = DistilleryRules.attuneEssence
        XCTAssertEqual(DistilleryRules.readiness(.heat, candidate: candidate,
                                                  catalyst: Resources.sulfur, in: state),
                       .needsCatalyst(resource: Resources.sulfur, have: 0, need: 2))

        state.base.resources.add(2, of: Resources.sulfur)
        XCTAssertEqual(DistilleryRules.readiness(.heat, candidate: candidate,
                                                  catalyst: Resources.sulfur, in: state),
                       .needsBlankCrystal)

        state.base.inventory.add(ItemStack(id: InstanceID(rawValue: 2),
                                           catalogID: Items.essenceCrystal,
                                           distilledCore: DistilledCore(attunement: nil, potency: 0)))
        XCTAssertEqual(DistilleryRules.readiness(.heat, candidate: candidate,
                                                  catalyst: Resources.sulfur, in: state), .ready)
        XCTAssertTrue(DistilleryRules.canAttune(.heat, candidate: candidate,
                                                catalyst: Resources.sulfur, in: state))
    }

    func testCrystallisationReadinessNamesTheExactMissingInput() {
        var state = GameState.newGame()
        XCTAssertEqual(DistilleryRules.crystallisationReadiness(in: state), .stationLocked)

        state.base.stations[Stations.distillery] = StationState(isUnlocked: true, tier: 0)
        state.base.essence = 0
        XCTAssertEqual(DistilleryRules.crystallisationReadiness(in: state),
                       .needsEssence(have: 0, need: DistilleryRules.blankEssence))

        state.base.essence = DistilleryRules.blankEssence
        XCTAssertEqual(DistilleryRules.crystallisationReadiness(in: state),
                       .needsQuartz(have: 0, need: DistilleryRules.blankQuartz))

        state.base.resources.add(DistilleryRules.blankQuartz, of: Resources.quartz)
        XCTAssertEqual(DistilleryRules.crystallisationReadiness(in: state), .ready)
        XCTAssertTrue(DistilleryRules.canCrystallise(in: state))
    }
}

/// Items stack, and materials bin by kind (decisions-session-16 §1).
final class StackingTests: XCTestCase {

    func testStorehouseWaitingItemRequiresExactDestructiveConfirmation() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(
            contentsOf: root.appending(path: "Sources/Screens/StationViews.swift"),
            encoding: .utf8
        )

        XCTAssertTrue(source.contains("Throw away \\(displaySpilled.displayName)?"))
        XCTAssertTrue(source.contains("This permanently removes the item from the waiting pile."))
        XCTAssertTrue(source.contains("Button(\"Keep it waiting\", role: .cancel)"))
        XCTAssertFalse(source.contains("Button(role: .destructive, action: discard)"))
    }

    func testDistilledCoresStackOnlyWhenDisplayProvenanceMatches() {
        var inventory = Inventory(slots: 8)
        let first = DistilledCore(attunement: .heat, potency: 70, sampleKind: "reagent",
                                  sampleSource: "ashen bloom", catalystID: Resources.sulfur,
                                  catalystCount: 2)
        let otherOrigin = DistilledCore(attunement: .heat, potency: 70, sampleKind: "reagent",
                                        sampleSource: "red fungus", catalystID: Resources.sulfur,
                                        catalystCount: 2)
        inventory.add(ItemStack(id: InstanceID(rawValue: 1), catalogID: Items.heatCore, distilledCore: first))
        inventory.add(ItemStack(id: InstanceID(rawValue: 2), catalogID: Items.heatCore, distilledCore: first))
        inventory.add(ItemStack(id: InstanceID(rawValue: 3), catalogID: Items.heatCore, distilledCore: otherOrigin))
        XCTAssertEqual(inventory.stacks.count, 2)
        XCTAssertEqual(inventory.stacks.first?.count, 2)
    }

    func testDistilleryCoreProvenanceSurvivesSave() throws {
        let core = DistilledCore(attunement: .light, potency: 86, sampleKind: "chitin",
                                sampleSource: "glassback", sampleQualifier: "lustrous",
                                catalystID: Resources.silver, catalystCount: 2)
        let stack = ItemStack(id: InstanceID(rawValue: 9), catalogID: Items.lightCore,
                              distilledCore: core)
        let data = try SaveCodec.makeEncoder().encode(stack)
        XCTAssertEqual(try SaveCodec.makeDecoder().decode(ItemStack.self, from: data), stack)
    }

    func testAttuningConsumesExactInputsAndRecordsSelectedSample() throws {
        var state = GameState.newGame()
        state.base.stations[Stations.distillery] = StationState(isUnlocked: true, tier: 0)
        state.base.essence = 100
        state.base.resources.add(2, of: Resources.sulfur)
        state.base.inventory.add(ItemStack(id: InstanceID(rawValue: 1), catalogID: Items.essenceCrystal,
                                           distilledCore: DistilledCore(attunement: nil, potency: 0)))
        state.base.inventory.add(ItemStack(id: InstanceID(rawValue: 2), catalogID: Items.material,
                                           material: MaterialSample(kind: .reagent,
                                               properties: MaterialProperties(insulation: 30, reactivity: 80),
                                               grade: 70, source: "ashen bloom")))
        let candidate = try XCTUnwrap(DistilleryRules.candidates(for: .heat, in: state).first)
        XCTAssertTrue(DistilleryRules.attune(.heat, candidate: candidate,
                                             catalyst: Resources.sulfur, in: &state))
        XCTAssertEqual(state.base.essence, 85)
        XCTAssertEqual(state.base.resources[Resources.sulfur], 0)
        let core = try XCTUnwrap(state.base.inventory.stacks.first { $0.catalogID == Items.heatCore }?.distilledCore)
        XCTAssertEqual(core.potency, 73)
        XCTAssertEqual(core.sampleSource, "ashen bloom")
    }

    func testFullStorehouseRefusesAttunementAtomically() throws {
        var state = GameState.newGame()
        state.base.stations[Stations.distillery] = StationState(isUnlocked: true, tier: 0)
        state.base.essence = 100
        state.base.resources.add(2, of: Resources.sulfur)
        state.base.inventory = Inventory(slots: 2)
        state.base.inventory.add(ItemStack(id: InstanceID(rawValue: 1), catalogID: Items.essenceCrystal,
                                           count: 2, distilledCore: DistilledCore(attunement: nil, potency: 0)))
        let qualifying = MaterialSample(kind: .reagent,
            properties: MaterialProperties(insulation: 30, reactivity: 80), grade: 70, source: "a")
        let spare = MaterialSample(kind: .reagent, properties: MaterialProperties(), grade: 10, source: "b")
        state.base.inventory.add(ItemStack(id: InstanceID(rawValue: 2), catalogID: Items.material,
                                           identified: true, materials: [qualifying, spare]))
        let before = state
        let candidate = try XCTUnwrap(DistilleryRules.candidates(for: .heat, in: state).first)
        XCTAssertFalse(DistilleryRules.attune(.heat, candidate: candidate,
                                              catalyst: Resources.sulfur, in: &state))
        XCTAssertEqual(state, before)
    }

    @MainActor func testBuildingChannelworksRestoresOdasFixtureExactlyOnce() throws {
        let store = GameStore(io: .temporary(name: "channelworks-\(UUID().uuidString)"))
        let station = try XCTUnwrap(ContentCatalog.shared.station(Stations.channelworks))
        store.mutate("prepare Oda build") { state in
            state.reality.library.foundTravellers.insert("oda")
            state.base.essence = 1_000
            for (id, amount) in station.buildCost?.resources ?? [:] { state.base.resources.add(amount, of: id) }
        }
        XCTAssertTrue(store.build(station))
        let fixtures = store.state.base.inventory.stacks.filter { $0.catalogID == Items.conduitFixture }
        XCTAssertEqual(fixtures.reduce(0) { $0 + $1.count }, 1)
        XCTAssertEqual(fixtures.first?.distilledCore?.recipeVersion, 0)
        XCTAssertTrue(store.state.base.odaFixtureRestored)
        XCTAssertFalse(store.build(station))
        XCTAssertEqual(store.state.base.inventory.stacks.filter { $0.catalogID == Items.conduitFixture }
            .reduce(0) { $0 + $1.count }, 1)
    }

    func testUnlockedLegacyChannelworksAdoptsOrGrantsOneRestorationReceipt() throws {
        var adopting = GameState.newGame()
        adopting.base.stations[Stations.channelworks] = StationState(isUnlocked: true, tier: 0)
        let authored = DistilledCore(attunement: .heat, potency: 40,
            sampleKind: "authored fixture", sampleSource: "Oda's damaged conduit",
            sampleQualifier: "intact, non-recoverable core", catalystID: nil, catalystCount: 0,
            recipeVersion: 0, stationID: Stations.channelworks)
        adopting.base.store(ItemStack(id: InstanceID(rawValue: 800),
                                     catalogID: Items.conduitFixture, distilledCore: authored))

        let adopted = try SaveCodec.decode(SaveCodec.encode(adopting))
        XCTAssertTrue(adopted.base.odaFixtureRestored)
        XCTAssertEqual(restorationCount(in: adopted), 1)
        XCTAssertEqual(restorationCount(in: try SaveCodec.decode(SaveCodec.encode(adopted))), 1)

        var granting = GameState.newGame()
        granting.base.stations[Stations.channelworks] = StationState(isUnlocked: true, tier: 0)
        let granted = try SaveCodec.decode(SaveCodec.encode(granting))
        XCTAssertTrue(granted.base.odaFixtureRestored)
        XCTAssertEqual(restorationCount(in: granted), 1)
    }

    func testRestorationReceiptPreventsReplacementAfterFixtureLeavesStorage() throws {
        var state = GameState.newGame()
        state.base.stations[Stations.channelworks] = StationState(isUnlocked: true, tier: 0)
        state.base.odaFixtureRestored = true

        let restored = try SaveCodec.decode(SaveCodec.encode(state))
        XCTAssertTrue(restored.base.odaFixtureRestored)
        XCTAssertEqual(restorationCount(in: restored), 0)
    }

    private func restorationCount(in state: GameState) -> Int {
        (state.base.inventory.stacks + state.base.spillover).filter {
            $0.catalogID == Items.conduitFixture
                && $0.distilledCore?.recipeVersion == 0
                && $0.distilledCore?.sampleSource == "Oda's damaged conduit"
        }.reduce(0) { $0 + $1.count }
    }

    // MARK: The bug

    /// **`count` existed from the start and nothing ever incremented it.** Every pickup made a new
    /// stack in a new slot, so two identical curios ate two of your eight.
    func testTwoOfTheSameThingShareOneSlot() {
        var inventory = Inventory(slots: 8)
        XCTAssertTrue(inventory.add(curio("curio_a")))
        XCTAssertTrue(inventory.add(curio("curio_a")))

        XCTAssertEqual(inventory.stacks.count, 1, "identical items still took a slot each")
        XCTAssertEqual(inventory.stacks[0].count, 2)
    }

    func testDifferentThingsStillTakeDifferentSlots() {
        var inventory = Inventory(slots: 8)
        inventory.add(curio("curio_a"))
        inventory.add(curio("curio_b"))
        XCTAssertEqual(inventory.stacks.count, 2)
    }

    /// Identifying one tells you nothing about the other, so it can't share its bin.
    func testAnIdentifiedThingDoesntShareABinWithAnUnidentifiedOne() {
        var inventory = Inventory(slots: 8)
        inventory.add(ItemStack(id: InstanceID(rawValue: 1), catalogID: "curio_a", identified: false))
        inventory.add(ItemStack(id: InstanceID(rawValue: 2), catalogID: "curio_a", identified: true))
        XCTAssertEqual(inventory.stacks.count, 2)
    }

    // MARK: Materials bin by kind

    /// **All hides go in the hide bin**, whatever their grade or whichever animal they came off.
    /// A world with six species produces a dozen variants; slot pressure has to be proportional to
    /// *kinds*, not to variants.
    func testEveryHideSharesOneSlotHoweverDifferentTheyAre() {
        var inventory = Inventory(slots: 8)
        inventory.add(material(.hide, grade: 20, source: "pale groper"))
        inventory.add(material(.hide, grade: 80, source: "shaggy browser"))
        inventory.add(material(.hide, grade: 55, source: "sable grazer"))

        XCTAssertEqual(inventory.stacks.count, 1, "three hides took three slots")
        XCTAssertEqual(inventory.stacks[0].count, 3)
    }

    /// …and **nothing is lost by it**. Every sample keeps its own grade, name and source.
    func testBinningLosesNothingAboutAnyOfThem() throws {
        var inventory = Inventory(slots: 8)
        inventory.add(material(.hide, grade: 20, source: "pale groper"))
        inventory.add(material(.hide, grade: 80, source: "shaggy browser"))

        let bin = try XCTUnwrap(inventory.stacks.first)
        XCTAssertEqual(Set(bin.materials.map(\.source)), ["pale groper", "shaggy browser"])
        XCTAssertEqual(bin.finest?.grade, 80)
        XCTAssertEqual(bin.finest?.source, "shaggy browser")
    }

    func testDifferentMaterialKindsGetDifferentSlots() {
        var inventory = Inventory(slots: 8)
        inventory.add(material(.hide, grade: 40, source: "x"))
        inventory.add(material(.bone, grade: 40, source: "x"))
        inventory.add(material(.fang, grade: 40, source: "x"))
        XCTAssertEqual(inventory.stacks.count, 3)
    }

    /// A bin is named for its kind and says what the best thing in it is — "12 hides" tells you how
    /// much room it takes and nothing about whether it was worth the trip.
    func testABinSaysWhatKindItIsAndHowGoodItsBestIs() {
        var inventory = Inventory(slots: 8)
        inventory.add(material(.hide, grade: 20, source: "x"))
        inventory.add(material(.hide, grade: 80, source: "y"))

        XCTAssertEqual(inventory.stacks[0].displayName, "Hides")
        XCTAssertTrue(inventory.stacks[0].detail.contains("superb"), inventory.stacks[0].detail)
        XCTAssertTrue(inventory.stacks[0].detail.contains("×2"), inventory.stacks[0].detail)
    }

    // MARK: A full hold still takes more of what it already has

    /// The point of binning: a full storehouse can still accept another hide, because the hide bin
    /// is already there. Only a *new kind* needs a slot.
    func testAFullHoldStillTakesMoreOfWhatItAlreadyHolds() {
        var inventory = Inventory(slots: 1)
        XCTAssertTrue(inventory.add(material(.hide, grade: 30, source: "x")))
        XCTAssertTrue(inventory.isFull)

        XCTAssertTrue(inventory.add(material(.hide, grade: 90, source: "y")),
                      "a full hold refused another of something it was already holding")
        XCTAssertFalse(inventory.add(material(.bone, grade: 30, source: "x")),
                       "a full hold accepted a kind it had no room for")
        XCTAssertEqual(inventory.stacks[0].count, 2)
    }

    // MARK: Taking things back out

    /// Losses come off the bottom — what a collapse or a trade costs you is what you'd miss least.
    func testTakingFromABinTakesTheWorstFirst() throws {
        var bin = ItemStack(id: InstanceID(rawValue: 1), catalogID: Items.material,
                            materials: [sample(.hide, grade: 10, source: "a"),
                                        sample(.hide, grade: 90, source: "b"),
                                        sample(.hide, grade: 50, source: "c")])
        let taken = try XCTUnwrap(bin.removing(1))
        XCTAssertEqual(taken.materials.first?.grade, 10)
        XCTAssertEqual(bin.count, 2)
        XCTAssertEqual(bin.finest?.grade, 90)
    }

    /// **A collapse costs half of what you're carrying, not half your slots.** Once a slot can hold
    /// a dozen hides, dropping half the *slots* takes all twelve or none.
    func testACollapseCostsThingsRatherThanSlots() {
        var rng = SeededRNG(seed: 4)
        var inventory = Inventory(slots: 8)
        for grade in stride(from: 10.0, through: 100.0, by: 10) {
            inventory.add(material(.hide, grade: grade, source: "x"))
        }
        XCTAssertEqual(inventory.stacks.count, 1)

        let kept = inventory.randomlyKeeping(fraction: 0.5, rng: &rng)
        XCTAssertEqual(kept.stacks.first?.count, 5, "half of ten hides is five hides")
        XCTAssertEqual(kept.stacks.first?.finest?.grade, 100, "the collapse took the best ones")
    }

    // MARK: Persistence

    /// A save written before binning holds a single `material` and a count. It has to load.
    func testASaveFromBeforeBinningStillLoads() throws {
        let json = """
        {"id": {"rawValue": 3}, "catalogID": "material", "count": 4, "identified": true,
         "material": {"kind": "pelt", "grade": 62, "source": "shaggy browser",
                      "properties": {"insulation": 70}}}
        """
        let stack = try SaveCodec.makeDecoder().decode(ItemStack.self, from: Data(json.utf8))
        XCTAssertEqual(stack.count, 4)
        XCTAssertEqual(stack.materials.count, 4, "four pelts became one")
        XCTAssertEqual(stack.materials.first?.kind, .pelt)
    }

    func testABinRoundTripsThroughASave() throws {
        var inventory = Inventory(slots: 8)
        inventory.add(material(.pelt, grade: 30, source: "a"))
        inventory.add(material(.pelt, grade: 70, source: "b"))

        let data = try SaveCodec.makeEncoder().encode(inventory)
        XCTAssertEqual(try SaveCodec.makeDecoder().decode(Inventory.self, from: data), inventory)
    }

    // MARK: It reaches the player

    /// The satchel uses the same rule in-world — otherwise carrying is still miserable and the fix
    /// only helps at home.
    @MainActor
    func testTheSatchelBinsTooSoCarryingIsntMiserable() throws {
        let store = GameStore(io: .temporary(name: "stack-\(UUID().uuidString)"))
        store.write("plains")
        store.bindAndDepart()
        store.mutate("haul several of the same thing") { state in
            guard var run = state.worlds.activeRun else { return }
            run.satchelItems = Inventory(slots: 2)
            for grade in [20.0, 55, 90] {
                _ = run.satchelItems.add(self.material(.hide, grade: grade, source: "x"))
            }
            state.worlds.activeRun = run
        }
        let satchel = try XCTUnwrap(store.state.worlds.activeRun?.satchelItems)
        XCTAssertEqual(satchel.stacks.count, 1)
        XCTAssertEqual(satchel.stacks[0].count, 3)
    }


    // MARK: The hold expands far enough to be worth hoarding in (session 16 §2)

    /// **Three tiers capped storage at twenty slots forever**, which fights the hoarding pillar —
    /// "expand until you can hoard whatever you want mid-game" can't happen in three steps.
    @MainActor
    func testStorageExpandsFarBeyondThreeTiers() {
        let hold = ContentCatalog.shared.nodes(in: "hold")
        let shelving = hold.filter { node in
            node.grants.contains { $0.effect == .storehouseTier }
        }
        XCTAssertGreaterThanOrEqual(shelving.count, 8,
                                    "the storehouse ladder is still short enough to max in an hour")

        let station = ContentCatalog.shared.station(Stations.storehouse)
        XCTAssertGreaterThanOrEqual(station?.maxTier ?? 0, shelving.count,
                                    "the ladder has more rungs than the station will accept")
    }

    /// It gets **steeply** expensive, so storage stays worth investing in across the whole game
    /// rather than being finished early.
    @MainActor
    func testEachRungOfTheLadderCostsMoreThanTheLast() {
        for effect in [ResearchGrant.Effect.storehouseTier, .satchelTier] {
            let rungs = ContentCatalog.shared.nodes(in: "hold")
                .filter { node in node.grants.contains { $0.effect == effect } }
                .sorted { $0.cost.essence < $1.cost.essence }
            XCTAssertGreaterThan(rungs.count, 2)
            for (earlier, later) in zip(rungs, rungs.dropFirst()) {
                XCTAssertGreaterThan(later.cost.essence, earlier.cost.essence,
                                     "\(later.id.rawValue) costs no more than \(earlier.id.rawValue)")
            }
            // The last rung should be a real investment, not a rounding error above the first.
            XCTAssertGreaterThan(rungs.last!.cost.essence, rungs.first!.cost.essence * 8)
        }
    }

    /// Every rung has to be reachable — a ladder with a missing prerequisite is a ladder you can
    /// see the top of and never climb.
    @MainActor
    func testEveryRungOfTheLadderIsReachable() {
        let hold = ContentCatalog.shared.nodes(in: "hold")
        let ids = Set(hold.map(\.id))
        for node in hold {
            for requirement in node.requires {
                let crossStationCapability = ContentCatalog.shared.researchNode(requirement)?
                    .grants.contains { $0.kind == .capability } == true
                XCTAssertTrue(ids.contains(requirement) || crossStationCapability,
                              "\(node.id.rawValue) needs \(requirement.rawValue), which is neither in the branch nor an explicit station capability")
            }
        }
    }

    // MARK: Helpers

    private func curio(_ id: String) -> ItemStack {
        ItemStack(id: InstanceID(rawValue: UInt64.random(in: 1...9_999_999)),
                  catalogID: ItemID(rawValue: id))
    }

    private func sample(_ kind: MaterialKind, grade: Double, source: String) -> MaterialSample {
        MaterialSample(kind: kind, properties: MaterialProperties(hardness: 40),
                       grade: grade, source: source)
    }

    private func material(_ kind: MaterialKind, grade: Double, source: String) -> ItemStack {
        ItemStack(id: InstanceID(rawValue: UInt64.random(in: 1...9_999_999)),
                  catalogID: Items.material,
                  materials: [sample(kind, grade: grade, source: source)])
    }
}
