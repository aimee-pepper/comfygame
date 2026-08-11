import XCTest
@testable import Bookbinder

final class TravellerWorldPacingTests: XCTestCase {
    private let catalog = ContentCatalog.shared

    func testFreshMaraAndBrynMatchPlacesMaraOnly() throws {
        let mara = try traveller("mara")
        let bryn = try traveller("bryn")

        let selection = LibraryRules.selectTravellerForNewWorld(
            from: [bryn, mara], library: LibraryState(), blindDiscoveryWindow: 3)
        XCTAssertEqual(selection.selected, "mara")
        XCTAssertEqual(selection.eligible, ["mara"])
        XCTAssertEqual(selection.exclusions.first(where: { $0.traveller == "bryn" })?.reason,
                       .phaseLocked)
    }

    func testExactLocationClueCannotBeatEarlierStoryBand() throws {
        let mara = try traveller("mara")
        let bryn = try traveller("bryn")
        let clue = try XCTUnwrap(catalog.diaryPages.first {
            $0.kind == .locationClue && $0.about == TravellerID(rawValue: "bryn")
        })
        var after = LibraryState()
        after.foundPages = [clue.id]
        let selected = LibraryRules.selectTravellerForNewWorld(
            from: [mara, bryn], library: after, blindDiscoveryWindow: 3)
        XCTAssertEqual(selected.selected, "mara")
        XCTAssertEqual(selected.exclusions.first(where: { $0.traveller == "bryn" })?.reason,
                       .laterStoryBand)
    }

    func testSameBandRecoveredAndCausalEvidenceBreaksTieOnlyOncePerCondition() throws {
        let isolde = try traveller("isolde")
        let bryn = try traveller("bryn")
        let clue = try XCTUnwrap(catalog.diaryPages.first {
            $0.kind == .locationClue && $0.about == bryn.id && $0.clueIndex == 0
        })
        var library = LibraryState()
        library.foundPages = [clue.id]
        library.foundTravellers = ["vance", "halloway", "mara"]
        let selection = LibraryRules.selectTravellerForNewWorld(
            from: [isolde, bryn], library: library, blindDiscoveryWindow: 3,
            causalConditionIndices: [bryn.id: [0]], clueWeight: 1, authoredWeight: 2)
        XCTAssertEqual(selection.selected, bryn.id)
        XCTAssertEqual(selection.evidence[bryn.id]?.recoveredClues, 1)
        XCTAssertEqual(selection.evidence[bryn.id]?.causallyAuthoredConditions, 1)
        XCTAssertEqual(selection.evidence[bryn.id]?.causallyAuthoredKnownConditions, 1)
        XCTAssertEqual(selection.evidence[bryn.id]?.evidenceScore, 3)
    }

    func testBlindFrontierUsesAuthoredOrderNotCampaignPhase() throws {
        let sela = try traveller("sela")
        let bryn = try traveller("bryn")
        var library = LibraryState()
        library.foundTravellers = ["vance", "halloway", "mara", "edren"]
        XCTAssertEqual(LibraryRules.selectTravellerForNewWorld(
            from: [bryn, sela], library: library, blindDiscoveryWindow: 3).selected, "sela")

        library.foundTravellers.insert("sela")
        XCTAssertEqual(LibraryRules.selectTravellerForNewWorld(
            from: [bryn], library: library, blindDiscoveryWindow: 3).selected, "bryn")
    }

    func testWindowIsClampedAndSelectionIsStableUnderCandidateShuffle() throws {
        let matches = try [traveller("mara"), traveller("bryn"), traveller("orsa")]
        var library = LibraryState()
        library.foundTravellers = ["vance", "halloway", "edren"]
        let narrow = LibraryRules.selectTravellerForNewWorld(
            from: matches, library: library, blindDiscoveryWindow: 1)
        let wide = LibraryRules.selectTravellerForNewWorld(
            from: Array(matches.reversed()), library: library, blindDiscoveryWindow: 6)
        XCTAssertEqual(narrow.selected, "mara")
        XCTAssertEqual(wide.selected, "mara")
        XCTAssertEqual(wide.eligible, ["mara", "bryn", "orsa"])
    }

    func testArrivalConfidenceUsesOneBoundedRollFormulaAndSavedProtection() {
        XCTAssertEqual(LibraryRules.travellerArrivalChance(
            causallyAuthoredConditions: 0, totalConditions: 4, priorNearMisses: 0), 0.25)
        XCTAssertEqual(LibraryRules.travellerArrivalChance(
            causallyAuthoredConditions: 2, totalConditions: 4, priorNearMisses: 0), 0.625)
        XCTAssertEqual(LibraryRules.travellerArrivalChance(
            causallyAuthoredConditions: 4, totalConditions: 4, priorNearMisses: 0), 1)
        XCTAssertEqual(LibraryRules.travellerArrivalChance(
            causallyAuthoredConditions: 0, totalConditions: 4, priorNearMisses: 1), 0.5)
        XCTAssertEqual(LibraryRules.travellerArrivalChance(
            causallyAuthoredConditions: 0, totalConditions: 4, priorNearMisses: 2), 1)
        XCTAssertEqual(LibraryRules.travellerArrivalChance(
            causallyAuthoredConditions: 2, totalConditions: 4, priorNearMisses: 0, floor: 0.4), 0.7)
    }

    func testNearMissSaveIsTolerantAndOnlyConfidenceFailureMutatesIt() throws {
        let old = try JSONDecoder().decode(LibraryState.self, from: Data("{}".utf8))
        XCTAssertTrue(old.travellerArrivalNearMisses.isEmpty)

        var library = LibraryState()
        var receipt = TravellerArrivalReceipt(
            selectedTraveller: "mara", storyArrivalBand: 1, authoredOrder: 4,
            totalConditions: 1, recoveredLocationClues: 0, causallyAuthoredConditions: 0,
            causallyAuthoredKnownConditions: 0, accidentalSatisfiedConditions: 1,
            evidenceScore: 0, priorNearMisses: 0, arrivalChance: 0.25,
            arrivalRoll: 0.8, outcome: .confidenceFailed)
        library.applyTravellerArrival(receipt)
        XCTAssertEqual(library.travellerArrivalNearMisses["mara"], 1)
        receipt.outcome = .placementFailed
        library.applyTravellerArrival(receipt)
        XCTAssertEqual(library.travellerArrivalNearMisses["mara"], 1)
        receipt.outcome = .placed
        library.applyTravellerArrival(receipt)
        XCTAssertNil(library.travellerArrivalNearMisses["mara"])

        let roundTrip = try JSONDecoder().decode(LibraryState.self,
            from: JSONEncoder().encode(library))
        XCTAssertEqual(roundTrip, library)
    }

    func testAllLiveTravellersHaveExactNonnegativeStoryBands() {
        XCTAssertEqual(catalog.travellers.count, 28)
        XCTAssertTrue(catalog.travellers.allSatisfy { ($0.storyArrivalBand ?? -1) >= 0 })
        XCTAssertEqual(catalog.traveller("vance")?.storyArrivalBand, 0)
        XCTAssertEqual(catalog.traveller("mara")?.storyArrivalBand, 1)
        XCTAssertEqual(catalog.traveller("bryn")?.storyArrivalBand, 2)
        XCTAssertEqual(catalog.traveller("nine")?.storyArrivalBand, 7)
    }

    func testGenerationFreezesArrivalReceiptAcrossRelaunchEquivalentCalls() {
        let blank = BoundBook(symbols: [:], randomlyFilled: [], essencePaid: 0)
        let library = LibraryState()
        for seed in UInt64(1)...30 {
            let first = Worldgen.generate(book: blank, seed: seed, library: library)
            let second = Worldgen.generate(book: blank, seed: seed, library: library)
            XCTAssertEqual(first.diagnostics.travellerArrival,
                           second.diagnostics.travellerArrival, "seed \(seed)")
            XCTAssertEqual(first.travellers, second.travellers, "seed \(seed)")
        }
    }

    func testCausalConditionRequiresActualHoldAndCounterfactualFailure() throws {
        let mara = try traveller("mara")
        let authored = PressureRules.resolve([
            Sigil(id: InstanceID(rawValue: 1), source: "sun", target: "illumination",
                  intensity: .overwhelming)
        ])
        let dark = PressureRules.resolve([
            Sigil(id: InstanceID(rawValue: 2), source: "void", target: "illumination",
                  intensity: .overwhelming)
        ])
        XCTAssertEqual(LibraryRules.causalConditionIndices(
            for: mara, actual: authored, withoutAuthoredPressure: dark), [0])
        XCTAssertTrue(LibraryRules.causalConditionIndices(
            for: mara, actual: dark, withoutAuthoredPressure: dark).isEmpty)
    }

    func testPageBucketsAverageRatherThanRewardingPageCount() throws {
        let page = try XCTUnwrap(catalog.diaryPages.first)
        let readings = PressureRules.resolve([])
        let one = LibraryRules.pageSelectionBuckets([page], readings: readings)
        let ten = LibraryRules.pageSelectionBuckets(Array(repeating: page, count: 10), readings: readings)
        XCTAssertEqual(one.map(\.weight), ten.map(\.weight))
    }

    func testLocationCluesBucketBySubjectAndOtherPagesByDiary() throws {
        let location = try XCTUnwrap(catalog.diaryPages.first {
            $0.kind == .locationClue && $0.about != nil && $0.about != $0.diary
        })
        let other = try XCTUnwrap(catalog.diaryPages.first {
            $0.kind != .locationClue && $0.diary == location.diary
        })
        let buckets = LibraryRules.pageSelectionBuckets([location, other],
                                                         readings: PressureRules.resolve([]))
        XCTAssertEqual(Set(buckets.map(\.key)),
                       ["location:\(location.about!.rawValue)", "diary:\(location.diary.rawValue)"])
    }

    func testAtHomeContextRaisesBucketAverageWithoutChangingItsGrammar() throws {
        var found: (DiaryPageDef, PressureReadings)?
        for seed in UInt64(1)...500 where found == nil {
            let readings = PressureRules.resolve([], fillingUnwrittenWith: seed)
            if let page = catalog.diaryPages.first(where: {
                !$0.prefersConditions.isEmpty
                    && $0.prefersConditions.allSatisfy { $0.holds(in: readings) }
            }) {
                found = (page, readings)
            }
        }
        let (page, readings) = try XCTUnwrap(found)
        let bucket = try XCTUnwrap(LibraryRules.pageSelectionBuckets([page], readings: readings).first)
        XCTAssertEqual(bucket.weight, Tuning.Library.atHomeWeight)
    }

    func testPatienceNomineeStillBypassesBucketLottery() throws {
        let page = try XCTUnwrap(catalog.diaryPages.first { !$0.prefersConditions.isEmpty })
        var library = LibraryState()
        library.patiencePage = page.id
        library.pagesWaiting = [page.id: 0]
        let threshold = 0
        var rng = SeededRNG(seed: 44)
        let placed = LibraryRules.placePages(in: PressureRules.resolve([]), library: library,
                                             additionalPageChance: 0,
                                             patienceInWorlds: threshold, rng: &rng)
        XCTAssertEqual(placed.first, page.id)
    }

    func testPageBucketSelectionIsStableUnderCatalogueShuffleAndRelaunchSeed() {
        let readings = PressureRules.resolve([], fillingUnwrittenWith: 91)
        let pages = Array(catalog.diaryPages.prefix(30))
        XCTAssertEqual(LibraryRules.pageSelectionBuckets(pages, readings: readings),
                       LibraryRules.pageSelectionBuckets(Array(pages.reversed()), readings: readings))
        var firstRNG = SeededRNG(seed: 808)
        var secondRNG = SeededRNG(seed: 808)
        XCTAssertEqual(LibraryRules.placePages(in: readings, library: LibraryState(), rng: &firstRNG),
                       LibraryRules.placePages(in: readings, library: LibraryState(), rng: &secondRNG))
    }

    func testGeneratedWorldNeverPlacesMoreThanOneNewTraveller() {
        let blank = BoundBook(symbols: [:], randomlyFilled: [], essencePaid: 0)
        for seed in UInt64(1)...100 {
            XCTAssertLessThanOrEqual(Worldgen.generate(book: blank, seed: seed).travellers.count, 1,
                                     "seed \(seed)")
        }
    }

    private func traveller(_ id: TravellerID) throws -> TravellerDef {
        try XCTUnwrap(catalog.traveller(id))
    }
}
