import XCTest
@testable import Bookbinder

final class TutorialTests: XCTestCase {
    private func makeRun(index: Int = 1) -> WorldRun {
        let book = BoundBook(symbols: [:], randomlyFilled: [], essencePaid: 0)
        let generated = Worldgen.generate(book: book, seed: 991)
        return WorldRun(runIndex: index, book: book, mapSeed: 991, rng: SeededRNG(seed: 991),
                        map: generated.map, playerPosition: generated.start)
    }

    private var emptyBanked: GameStore.BankedHaul {
        .init(resources: [], items: [], lostResources: [], lostItems: [],
              unidentifiedItemIDs: [], returnedRawEssence: false)
    }
    func testNewGameStartsWithVersionedUnseenLessons() {
        let state = GameState.newGame()
        XCTAssertEqual(state.tutorial.version, 1)
        XCTAssertEqual(state.tutorial[.writingPageRequest].status, .unseen)
    }

    func testDeferredLessonKeepsItsFirstEligibilityAndCanCompleteByFact() {
        var tutorial = TutorialState()
        tutorial.becameEligible(.worldNavigation, runIndex: 3)
        tutorial.deferLesson(.worldNavigation)
        tutorial.becameEligible(.worldNavigation, runIndex: 4)
        tutorial.complete(.worldNavigation, fact: "first_movement")

        XCTAssertEqual(tutorial[.worldNavigation].firstEligibleRunIndex, 3)
        XCTAssertEqual(tutorial[.worldNavigation].status, .completed)
        XCTAssertEqual(tutorial[.worldNavigation].completedByFact, "first_movement")
    }

    func testOldProgressAutoFilesCompletedLessonsWithoutMakingOthersVisible() throws {
        var old = GameState.newGame()
        old.worlds.runIndex = 2
        old.worlds.lastExit = RunExitSummary(runIndex: 2, kind: .portal, reason: "home",
                                             turnsTaken: 4, haulKeptFraction: 1,
                                             resources: [], items: [], lostResources: [],
                                             lostItems: [], progress: [], pages: [])
        let encoded = try SaveCodec.makeEncoder().encode(old)
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        object.removeValue(forKey: "tutorial")
        let legacyData = try JSONSerialization.data(withJSONObject: object)
        let decoded = try SaveCodec.makeDecoder().decode(GameState.self, from: legacyData)

        XCTAssertEqual(decoded.tutorial[.writingPageRequest].status, .completed)
        XCTAssertEqual(decoded.tutorial[.writingPreview].status, .completed)
        XCTAssertEqual(decoded.tutorial[.worldReturn].status, .completed)
        XCTAssertEqual(decoded.tutorial[.worldInteraction].status, .unseen)
    }

    func testEveryContextualCardHasAUniqueLessonID() {
        XCTAssertEqual(Set(TutorialRules.definitions.map(\.id)).count,
                       TutorialRules.definitions.count)
    }

    func testEveryExpeditionOutcomeCompletesReturnImmediately() {
        for kind in [RunExitSummary.Kind.portal, .waystone, .defeat, .collapse, .abandon] {
            var state = GameState.newGame()
            state.worlds.lastExit = RunExitSummary(runIndex: 1, kind: kind, reason: "done",
                                                   turnsTaken: 1, haulKeptFraction: 0.5)
            TutorialRules.recordExpeditionOutcome(in: &state)
            XCTAssertEqual(state.tutorial[.worldReturn].status, .completed, kind.rawValue)
        }
    }

    func testUnknownFutureLessonIDsSurviveRoundTrip() throws {
        var state = GameState.newGame()
        state.tutorial.lessons["future.lesson.v9"] = TutorialLessonProgress(status: .deferred)
        let data = try SaveCodec.makeEncoder().encode(state)
        let decoded = try SaveCodec.makeDecoder().decode(GameState.self, from: data)
        XCTAssertEqual(decoded.tutorial.lessons["future.lesson.v9"]?.status, .deferred)
    }

    func testFirstReturnFreezesDeterministicAuthoredPageAndNeverRecalculates() throws {
        var base = GameState.newGame()
        let pages: [DiaryPageID] = ["mara_where_1", "mara_where_0"]
        base.reality.library.foundPages = pages
        var first = base
        var second = base
        let run = makeRun()
        TutorialRules.freezeFirstReturnContext(run: run, banked: emptyBanked, in: &first)
        TutorialRules.freezeFirstReturnContext(run: run, banked: emptyBanked, in: &second)
        XCTAssertEqual(first.tutorial.firstReturnContext, second.tutorial.firstReturnContext)
        XCTAssertEqual(first.tutorial.firstReturnContext?.writingID, "mara_where_0")
        first.reality.library.foundPages.removeAll()
        TutorialRules.freezeFirstReturnContext(run: makeRun(index: 2), banked: emptyBanked, in: &first)
        XCTAssertEqual(first.tutorial.firstReturnContext?.runIndex, 1)
    }

    func testFirstReturnPriorityWritingThenUnidentifiedThenRawThenTraveller() {
        var state = GameState.newGame()
        state.reality.library.foundTravellers.insert("mara")
        state.reality.library.foundWritings = [
            FoundWritingRecord(id: "note-2", family: .fieldNote, prose: "True.", position: GridPoint(x: 0, y: 0))
        ]
        TutorialRules.freezeFirstReturnContext(run: makeRun(), banked: emptyBanked, in: &state)
        XCTAssertEqual(state.tutorial.firstReturnContext?.route, .library)

        var unidentified = GameState.newGame()
        let banked = GameStore.BankedHaul(resources: [], items: [], lostResources: [], lostItems: [],
                                          unidentifiedItemIDs: ["curio_unknown"], returnedRawEssence: true)
        TutorialRules.freezeFirstReturnContext(run: makeRun(), banked: banked, in: &unidentified)
        XCTAssertEqual(unidentified.tutorial.firstReturnContext?.route, .storehouse)
    }

    func testFirstReturnCoversRawTravellerOrdinaryAndLostUnknownBranches() {
        var raw = GameState.newGame()
        raw.base.essence = 0
        let rawBanked = GameStore.BankedHaul(resources: [], items: [], lostResources: [], lostItems: [],
                                             unidentifiedItemIDs: [], returnedRawEssence: true)
        TutorialRules.freezeFirstReturnContext(run: makeRun(), banked: rawBanked, in: &raw)
        XCTAssertEqual(raw.tutorial.firstReturnContext?.route, .essenceSpring)

        var traveller = GameState.newGame()
        traveller.reality.library.foundTravellers.insert("mara")
        TutorialRules.freezeFirstReturnContext(run: makeRun(), banked: emptyBanked, in: &traveller)
        XCTAssertEqual(traveller.tutorial.firstReturnContext?.route, .firepit)

        var ordinary = GameState.newGame()
        TutorialRules.freezeFirstReturnContext(run: makeRun(), banked: emptyBanked, in: &ordinary)
        XCTAssertEqual(ordinary.tutorial.firstReturnContext?.route, .writingDesk)

        var lostUnknown = GameState.newGame()
        let lost = GameStore.BankedHaul(resources: [], items: [], lostResources: [],
                                        lostItems: [RunExitGain(name: "Unknown object", icon: "questionmark", count: 1)],
                                        unidentifiedItemIDs: [], returnedRawEssence: false)
        TutorialRules.freezeFirstReturnContext(run: makeRun(), banked: lost, in: &lostUnknown)
        XCTAssertNotEqual(lostUnknown.tutorial.firstReturnContext?.route, .storehouse)
    }

    func testDeferredFirstReturnRouteDoesNotChangeWhenLaterStateMutates() {
        var state = GameState.newGame()
        state.reality.library.foundWritings = [
            FoundWritingRecord(id: "frozen", family: .fieldNote, prose: "First.", position: GridPoint(x: 0, y: 0))
        ]
        TutorialRules.freezeFirstReturnContext(run: makeRun(), banked: emptyBanked, in: &state)
        let frozen = state.tutorial.firstReturnContext
        state.tutorial.deferLesson(.baseFirstResultRoute)
        state.reality.library.foundWritings.removeAll()
        state.reality.library.foundTravellers.insert("mara")
        TutorialRules.freezeFirstReturnContext(run: makeRun(index: 2), banked: emptyBanked, in: &state)
        XCTAssertEqual(state.tutorial.firstReturnContext, frozen)
        XCTAssertEqual(state.tutorial[.baseFirstResultRoute].status, .deferred)
    }

    func testFirstReturnPreservesFoundWritingCollectionOrder() {
        var state = GameState.newGame()
        state.reality.library.foundWritings = [
            FoundWritingRecord(id: "note-z", family: .fieldNote, prose: "First.", position: GridPoint(x: 0, y: 0)),
            FoundWritingRecord(id: "note-a", family: .fieldNote, prose: "Second.", position: GridPoint(x: 1, y: 0))
        ]
        TutorialRules.freezeFirstReturnContext(run: makeRun(), banked: emptyBanked, in: &state)
        XCTAssertEqual(state.tutorial.firstReturnContext?.writingID, "note-z")
    }

    func testLibraryCopyIsTypeAwareAndMissingRecordDoesNotPretend() {
        for (family, reason, phrase) in [
            (FoundWritingRecord.Family.fieldNote, FirstReturnTutorialContext.Reason.fieldNote, "truthful relation"),
            (.routeMark, .routeMark, "short path"),
            (.siteFragment, .siteFragment, "does not reveal what the site contains"),
            (.workingScrap, .workingScrap, "knowledge, not the item")
        ] {
            var state = GameState.newGame()
            state.reality.library.foundWritings = [
                FoundWritingRecord(id: "selected", family: family, prose: "Words.", position: GridPoint(x: 0, y: 0))
            ]
            let context = FirstReturnTutorialContext(runIndex: 1, route: .library,
                                                     reason: reason, writingID: "selected")
            XCTAssertTrue(TutorialRules.libraryCopy(context, in: state)?.contains(phrase) == true)
        }
        let missing = FirstReturnTutorialContext(runIndex: 1, route: .library,
                                                 reason: .fieldNote, writingID: "missing")
        XCTAssertNil(TutorialRules.libraryCopy(missing, in: .newGame()))
    }

    @MainActor func testOpeningLibraryRouteDoesNotCompleteWritingUntilRecordDisplays() {
        let store = GameStore(io: .temporary(name: "tutorial-library-\(UUID().uuidString)"))
        store.mutate("context") { state in
            state.reality.library.foundWritings = [
                FoundWritingRecord(id: "selected", family: .fieldNote, prose: "Words.", position: GridPoint(x: 0, y: 0))
            ]
            state.tutorial.firstReturnContext = .init(runIndex: 1, route: .library,
                                                      reason: .fieldNote, writingID: "selected")
        }
        store.openedFirstReturnDestination(.library)
        XCTAssertEqual(store.state.tutorial[.baseFirstResultRoute].status, .completed)
        XCTAssertNotEqual(store.state.tutorial[.libraryFirstWriting].status, .completed)
        store.displayedFirstReturnWriting()
        XCTAssertEqual(store.state.tutorial[.libraryFirstWriting].status, .completed)
    }

    func testUnknownFutureFirstReturnRouteAndReasonRoundTripRaw() throws {
        var state = GameState.newGame()
        let data = try JSONEncoder().encode(state)
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        var tutorial = (object["tutorial"] as? [String: Any]) ?? [:]
        tutorial["firstReturnContext"] = ["runIndex": 1, "route": "observatory",
                                           "reason": "starChart", "writingID": "future"]
        object["tutorial"] = tutorial
        let decoded = try JSONDecoder().decode(GameState.self,
            from: JSONSerialization.data(withJSONObject: object))
        XCTAssertEqual(decoded.tutorial.firstReturnContext?.route, .writingDesk)
        XCTAssertEqual(decoded.tutorial.firstReturnContext?.reason, .ordinaryReturn)
        let encodedAgain = try JSONEncoder().encode(decoded)
        let roundTrip = try XCTUnwrap(JSONSerialization.jsonObject(with: encodedAgain) as? [String: Any])
        let raw = try XCTUnwrap((roundTrip["tutorial"] as? [String: Any])?["firstReturnContext"] as? [String: Any])
        XCTAssertEqual(raw["route"] as? String, "observatory")
        XCTAssertEqual(raw["reason"] as? String, "starChart")
    }

    func testSemanticComparisonCountsSubjectsNotGeometryOrIdentity() {
        let original = ["Illumination ← Sun", "Thermal ← great Magma"]
        XCTAssertEqual(TutorialRules.semanticChangeCount(from: original, to: original), 0)
        XCTAssertEqual(TutorialRules.semanticChangeCount(from: original,
                                                         to: ["Illumination ← Moon", "Thermal ← great Magma"]), 1)
        XCTAssertEqual(TutorialRules.semanticChangeCount(from: original,
                                                         to: ["Illumination ← Moon", "Atmosphere ← Wind"]), 3)
    }

    func testComparisonPairFreezesNextRecordAndSurvivesRoundTrip() throws {
        var state = GameState.newGame()
        let origin = history(id: 11, run: 1, requests: ["Illumination ← Sun"])
        let partner = history(id: 12, run: 2, requests: ["Illumination ← Moon"])
        state.reality.library.visitedWorlds = [origin, partner]
        state.tutorial.pendingComparisonOriginID = origin.id
        state.tutorial.pendingComparisonIsOneChange = true
        TutorialRules.pairNewWorld(partner, in: &state)
        XCTAssertEqual(state.tutorial.comparisonPair,
                       TutorialComparisonPair(originID: origin.id, partnerID: partner.id,
                                              isOneChangeExercise: true))
        let decoded = try SaveCodec.makeDecoder().decode(GameState.self,
            from: SaveCodec.makeEncoder().encode(state))
        XCTAssertEqual(decoded.tutorial.comparisonPair, state.tutorial.comparisonPair)
    }

    func testComparisonPairClearsWhenEitherRecordIsPruned() {
        var state = GameState.newGame()
        let origin = history(id: 21, run: 1, requests: [])
        let partner = history(id: 22, run: 2, requests: [])
        state.reality.library.visitedWorlds = [partner]
        state.tutorial.comparisonPair = .init(originID: origin.id, partnerID: partner.id,
                                              isOneChangeExercise: false)
        TutorialRules.reconcileComparisonPair(in: &state)
        XCTAssertNil(state.tutorial.comparisonPair)
        XCTAssertNotEqual(state.tutorial[.historyCompareWorlds].status, .completed)
    }

    func testActualBoundRecordReclassifiesOrCancelsPreviewClaim() {
        let origin = history(id: 31, run: 1,
                             requests: ["Illumination ← Sun", "Thermal ← Magma"])
        var multi = GameState.newGame()
        multi.reality.library.visitedWorlds = [origin]
        multi.tutorial.pendingComparisonOriginID = origin.id
        multi.tutorial.pendingComparisonIsOneChange = true
        let changedTwice = history(id: 32, run: 2,
                                   requests: ["Illumination ← Moon", "Atmosphere ← Wind"])
        multi.reality.library.visitedWorlds.append(changedTwice)
        TutorialRules.pairNewWorld(changedTwice, in: &multi)
        XCTAssertEqual(multi.tutorial.comparisonPair?.isOneChangeExercise, false)

        var reverted = GameState.newGame()
        reverted.reality.library.visitedWorlds = [origin]
        reverted.tutorial.pendingComparisonOriginID = origin.id
        reverted.tutorial.pendingComparisonIsOneChange = true
        let unchanged = history(id: 33, run: 2, requests: origin.semanticRequests)
        reverted.reality.library.visitedWorlds.append(unchanged)
        TutorialRules.pairNewWorld(unchanged, in: &reverted)
        XCTAssertNil(reverted.tutorial.comparisonPair)
        XCTAssertNil(reverted.tutorial.pendingComparisonOriginID)
    }

    func testComparisonLabelsAddedRemovedChangedAndUnchangedWithoutColour() {
        let earlier = history(id: 41, run: 1,
            requests: ["Illumination ← Sun", "Thermal ← Magma", "Relief ← Plain"])
        let later = history(id: 42, run: 2,
            requests: ["Illumination ← Moon", "Atmosphere ← Wind", "Relief ← Plain"])
        let earlyKinds = Dictionary(uniqueKeysWithValues:
            WorldComparisonSheet.labelledChanges(for: earlier, against: later, isLater: false)
                .map { ($0.key, $0.kind) })
        let laterKinds = Dictionary(uniqueKeysWithValues:
            WorldComparisonSheet.labelledChanges(for: later, against: earlier, isLater: true)
                .map { ($0.key, $0.kind) })
        XCTAssertEqual(earlyKinds["Thermal"], "Removed")
        XCTAssertEqual(laterKinds["Atmosphere"], "Added")
        XCTAssertEqual(earlyKinds["Illumination"], "Changed")
        XCTAssertEqual(laterKinds["Illumination"], "Changed")
        XCTAssertEqual(laterKinds["Relief"], "Unchanged")
        let earlyLines = Dictionary(uniqueKeysWithValues:
            WorldComparisonSheet.labelledChanges(for: earlier, against: later, isLater: false)
                .map { ($0.key, $0.line) })
        XCTAssertEqual(earlyLines["Atmosphere"], "Not written")
    }

    private func history(id: UInt64, run: Int, requests: [String]) -> VisitedWorld {
        VisitedWorld(id: InstanceID(rawValue: id), seed: id, runIndex: run,
                     descriptionSentence: "A world.", written: requests,
                     inertModifiers: [], readings: [:], travellersPresent: [],
                     semanticRequests: requests)
    }
}
