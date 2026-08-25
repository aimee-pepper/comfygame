import SwiftUI
import UIKit
import XCTest
@testable import Bookbinder

final class TravellerWorldPacingTests: XCTestCase {
    private let catalog = ContentCatalog.shared

    @MainActor
    private func mountedMeeting(_ traveller: TravellerDef, store: GameStore,
                                conversation: TravellerMeetingConversation = .init())
        -> (controller: UIHostingController<AnyView>, window: UIWindow) {
        let controller = UIHostingController(rootView: AnyView(
            TravellerMeetingView(traveller: traveller, initialConversation: conversation)
                .environmentObject(store)
                .environment(\.colorScheme, .light)
                .frame(width: 368, height: 800)))
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 368, height: 800))
        window.rootViewController = controller
        window.makeKeyAndVisible()
        controller.view.frame = CGRect(x: 0, y: 0, width: 368, height: 800)
        controller.view.setNeedsLayout()
        controller.view.layoutIfNeeded()
        settle(0.05)
        controller.view.layoutIfNeeded()
        return (controller, window)
    }

    @MainActor
    private func renderedPNG(_ controller: UIViewController) throws -> Data {
        let renderer = UIGraphicsImageRenderer(size: controller.view.bounds.size)
        return try XCTUnwrap(renderer.image { context in
            controller.view.layer.render(in: context.cgContext)
        }.pngData())
    }

    @MainActor
    private func settle(_ interval: TimeInterval = 0.4) {
        RunLoop.main.run(until: Date().addingTimeInterval(interval))
    }

    func testMeetingTransitionsContainNoLoadingOrImplicitReflowOwner() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(
            contentsOf: root.appending(path: "Sources/Screens/TravellerMeetingView.swift"),
            encoding: .utf8)
        XCTAssertFalse(source.contains("withAnimation"))
        for forbidden in ["ProgressView", "AsyncImage", "redacted(", "shimmer", "placeholder"] {
            XCTAssertFalse(source.contains(forbidden), "meeting introduced loading owner \(forbidden)")
        }
    }

    @MainActor
    func testMountedQuestionAndDeclineTransitionsAreImmediateStableAndInert() throws {
        let traveller = try traveller("isolde")
        let meeting = try XCTUnwrap(traveller.meeting)

        let askStore = GameStore(io: .temporary(name: "meeting-ask-\(UUID().uuidString)"))
        let askBytes = try SaveCodec.makeEncoder().encode(askStore.state)
        let askTurn = askStore.state.worlds.activeRun?.turnsTaken
        let exchange = try XCTUnwrap(meeting.questions.first)
        let baselineAsk = mountedMeeting(traveller, store: askStore)
        var asked = TravellerMeetingConversation()
        asked.ask(exchange.id)
        let askedMount = mountedMeeting(traveller, store: askStore, conversation: asked)
        let askController = askedMount.controller
        let immediateAskReceipt = try renderedPNG(askController)
        XCTAssertNotEqual(immediateAskReceipt, try renderedPNG(baselineAsk.controller),
                          "the exact asked exchange did not change the mounted production view")
        settle()
        askController.view.layoutIfNeeded()
        XCTAssertEqual(try renderedPNG(askController), immediateAskReceipt,
                       "question/reply content continued moving like a loading transition")
        XCTAssertEqual(try SaveCodec.makeEncoder().encode(askStore.state), askBytes)
        XCTAssertEqual(askStore.state.worlds.activeRun?.turnsTaken, askTurn)

        let declineStore = GameStore(io: .temporary(name: "meeting-decline-\(UUID().uuidString)"))
        let declineBytes = try SaveCodec.makeEncoder().encode(declineStore.state)
        var declined = TravellerMeetingConversation()
        declined.decline()
        let baselineDecline = mountedMeeting(traveller, store: declineStore)
        let declinedMount = mountedMeeting(traveller, store: declineStore,
                                           conversation: declined)
        let declineController = declinedMount.controller
        let immediateDeclineReceipt = try renderedPNG(declineController)
        XCTAssertNotEqual(immediateDeclineReceipt, try renderedPNG(baselineDecline.controller),
                          "declined terminal copy did not change the mounted production view")
        settle()
        declineController.view.layoutIfNeeded()
        XCTAssertEqual(try renderedPNG(declineController), immediateDeclineReceipt,
                       "terminal dialogue continued moving after decline")
        XCTAssertEqual(try SaveCodec.makeEncoder().encode(declineStore.state), declineBytes)
        XCTAssertNil(declineStore.state.worlds.activeRun)
    }

    @MainActor
    func testMountedAcceptTransitionIsImmediateAndKeepsRecruitmentOwnedByRules() throws {
        let traveller = try traveller("isolde")
        let store = GameStore(io: .temporary(name: "meeting-accept-\(UUID().uuidString)"))
        store.mutate("prepare meeting accept") {
            $0.base.essence = 5_000
            $0.worlds.seeds = SeedSequence(rootSeed: 1)
        }
        XCTAssertTrue(store.bindAndDepart(), store.bindError ?? "world not prepared")
        let point = try XCTUnwrap(store.state.worlds.activeRun?.playerPosition)
        let turn = store.state.worlds.activeRun?.turnsTaken
        var recruitedState = store.state
        let beforeRoster = recruitedState.base.roster.count
        var recruitEvents: [WorldRules.Event] = []
        guard var run = recruitedState.worlds.activeRun else {
            return XCTFail("world not prepared")
        }
        run.map[point].content = .traveller(traveller.id)
        run.travellersHere = [traveller.id]
        recruitedState.worlds.activeRun = run
        recruitEvents = WorldRules.recruit(traveller.id, in: &recruitedState)
        XCTAssertFalse(recruitEvents.contains { if case .blocked = $0 { true } else { false } })
        var accepted = TravellerMeetingConversation()
        accepted.accept()
        let acceptedMount = mountedMeeting(traveller, store: store, conversation: accepted)
        let controller = acceptedMount.controller
        XCTAssertTrue(recruitedState.reality.library.foundTravellers.contains(traveller.id))
        XCTAssertEqual(recruitedState.base.roster.count, beforeRoster + 1)
        XCTAssertEqual(recruitedState.worlds.activeRun?.turnsTaken, turn)
        let immediateReceipt = try renderedPNG(controller)
        settle()
        controller.view.layoutIfNeeded()
        XCTAssertEqual(try renderedPNG(controller), immediateReceipt,
                       "accepted copy and decision content continued moving after recruitment")
    }

    func testMeetingKeepsAuthoredOfferOutOfOversizedActionLabel() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let source = try String(
            contentsOf: root.appending(path: "Sources/Screens/TravellerMeetingView.swift"),
            encoding: .utf8
        )
        XCTAssertTrue(source.contains("PersistentActionBar("))
        XCTAssertTrue(source.contains("Text(\"Invite them\")"))
        XCTAssertTrue(source.contains("Button(\"Not now\")"))
        XCTAssertTrue(source.contains("return meeting?.offer ?? \"Come back with me.\""))
    }

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
        XCTAssertEqual(catalog.travellers.count, 29)
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

    func testRemovedAuthoredTargetRerollsAndOnlyCountsWhenSameSeedFillFails() throws {
        let mara = try traveller("mara")
        let authored = [Sigil(id: InstanceID(rawValue: 1), source: "sun",
                              target: "illumination", intensity: .overwhelming)]
        var sameSeedStillMatches: UInt64?
        var sameSeedFails: UInt64?

        for seed in UInt64(1)...2_000
            where sameSeedStillMatches == nil || sameSeedFails == nil {
            let pair = Worldgen.travellerCausalityReadings(authoredSigils: authored, seed: seed)
            guard mara.isFound(in: pair.actual) else { continue }
            let causal = LibraryRules.causalConditionIndices(
                for: mara, actual: pair.actual,
                withoutAuthoredPressure: pair.withoutAuthoredPressure)
            if mara.isFound(in: pair.withoutAuthoredPressure) {
                sameSeedStillMatches = sameSeedStillMatches ?? seed
                XCTAssertTrue(causal.isEmpty,
                              "ordinary same-seed fill already satisfied Mara at seed \(seed)")
            } else {
                sameSeedFails = sameSeedFails ?? seed
                XCTAssertEqual(causal, [0],
                               "Mara depended on the authored illumination at seed \(seed)")
            }
        }

        XCTAssertNotNil(sameSeedStillMatches, "fixture corpus needs a same-seed accidental match")
        XCTAssertNotNil(sameSeedFails, "fixture corpus needs a genuinely authored match")
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
