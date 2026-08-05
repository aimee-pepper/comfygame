import XCTest
@testable import Bookbinder

/// The search loop (decisions-session-7): travellers at condition signatures, diaries scattered
/// across worlds, and a Library that collects without interpreting.
@MainActor
final class LibraryTests: XCTestCase {

    // MARK: Distance is difficulty of description

    /// A traveller is not "N worlds away" — they are *at a signature*, and what varies is how hard
    /// that signature is to write. So difficulty has to show up as complexity, not as distance.
    func testTravellersVaryInHowHardTheyAreToDescribe() {
        let complexities = ContentCatalog.shared.travellers.map(\.complexity)
        XCTAssertEqual(complexities.min(), 1, "no traveller a starting vocabulary can reach")
        XCTAssertGreaterThan(complexities.max() ?? 0, 2, "nobody is genuinely hard to find")
    }

    func testWritingTheRightWorldFindsThePerson() {
        let mara = ContentCatalog.shared.traveller("mara")!
        let sunny = PressureRules.resolve([
            Sigil(id: InstanceID(rawValue: 1), source: "sun", target: "illumination", intensity: .overwhelming)
        ])
        XCTAssertTrue(mara.isFound(in: sunny))
        XCTAssertTrue(LibraryRules.travellersPresent(in: sunny).contains { $0.id == "mara" })
    }

    func testTheWrongWorldDoesNotFindThem() {
        let mara = ContentCatalog.shared.traveller("mara")!
        let dark = PressureRules.resolve([
            Sigil(id: InstanceID(rawValue: 1), source: "void", target: "illumination", intensity: .overwhelming)
        ])
        XCTAssertFalse(mara.isFound(in: dark))
    }

    /// **Pages are a guide, never a gate.** Writing the right world by luck finds them just the same.
    func testYouCanFindSomeoneWithoutHavingReadAPage() {
        let store = GameStore(io: .temporary(name: "luck-\(UUID().uuidString)"))
        store.mutate("test: fund") { $0.base.essence = 5000 }
        XCTAssertTrue(store.state.reality.library.foundPages.isEmpty)

        for _ in 0..<40 {
            store.bindAndDepart()
            if !store.state.reality.library.foundTravellers.isEmpty { break }
            store.mutate("test: next") { $0.worlds.activeRun = nil }
        }
        XCTAssertFalse(store.state.reality.library.foundTravellers.isEmpty,
                       "nobody was ever found by chance in forty worlds")
    }

    func testArrivingRecordsWhoWasThere() {
        let store = GameStore(io: .temporary(name: "arrive-\(UUID().uuidString)"))
        store.mutate("test: fund") { $0.base.essence = 5000 }
        for _ in 0..<40 {
            store.bindAndDepart()
            if let here = store.state.worlds.activeRun?.travellersHere, !here.isEmpty {
                for id in here {
                    XCTAssertTrue(store.state.reality.library.foundTravellers.contains(id))
                    XCTAssertTrue(store.state.reality.library.knownTravellers.contains(id),
                                  "found someone without knowing to look for them")
                }
                return
            }
            store.mutate("test: next") { $0.worlds.activeRun = nil }
        }
        XCTFail("no world in forty held anybody")
    }

    // MARK: Pages

    func testEveryLocationPieceHasAPageThatNamesIt() {
        // Complexity is difficulty only if the pieces are actually findable.
        for traveller in ContentCatalog.shared.travellers {
            for index in traveller.signature.indices {
                let exists = ContentCatalog.shared.diaryPages.contains {
                    $0.kind == .locationClue && $0.about == traveller.id && $0.clueIndex == index
                }
                XCTAssertTrue(exists, "no page describes piece \(index) of \(traveller.id.rawValue)")
            }
        }
    }

    func testEveryPageComesFromSomebodysDiary() {
        // There is no separate class of found writing — everything is somebody's diary.
        for page in ContentCatalog.shared.diaryPages {
            XCTAssertNotNil(ContentCatalog.shared.traveller(page.diary),
                            "page '\(page.id.rawValue)' has no author")
        }
    }

    func testReadingAPageIsPermanentAndUnlocksExactlyOneThing() {
        let store = GameStore(io: .temporary(name: "read-\(UUID().uuidString)"))
        let page = ContentCatalog.shared.diaryPages.first { $0.kind == .symbol }!
        store.mutate("test: forget") { $0.base.ownedSymbols.remove(page.teaches!) }

        store.mutate("test: read") { state in
            _ = WorldRules.readPage(page.id, in: &state)
        }
        XCTAssertTrue(store.state.reality.library.hasFound(page.id))
        XCTAssertTrue(store.state.base.ownedSymbols.contains(page.teaches!))

        // Reading it twice must not double anything.
        let before = store.state.reality.library.foundPages.count
        store.mutate("test: read again") { state in
            _ = WorldRules.readPage(page.id, in: &state)
        }
        XCTAssertEqual(store.state.reality.library.foundPages.count, before)
    }

    func testAPageAboutSomeoneMakesThemWorthLookingFor() {
        let store = GameStore(io: .temporary(name: "word-\(UUID().uuidString)"))
        let page = ContentCatalog.shared.diaryPages.first { $0.kind == .whereabouts }!
        store.mutate("test: read") { state in _ = WorldRules.readPage(page.id, in: &state) }
        XCTAssertTrue(store.state.reality.library.knownTravellers.contains(page.about!))
    }

    /// Nothing may become permanently unreachable because of how a player happens to write.
    func testAPageThatHasWaitedLongEnoughWillSurfaceAnywhere() {
        let fussy = ContentCatalog.shared.diaryPages.first { !$0.prefersConditions.isEmpty }!
        let wrongWorld = PressureRules.resolve([])   // baseline: matches nothing in particular

        var impatient = LibraryState()
        XCTAssertFalse(LibraryRules.eligiblePages(in: wrongWorld, library: impatient)
            .contains { $0.id == fussy.id },
                       "a fussy page turned up somewhere it had no business being, immediately")

        impatient.pagesWaiting[fussy.id] = Tuning.Library.patienceInWorlds
        XCTAssertTrue(LibraryRules.eligiblePages(in: wrongWorld, library: impatient)
            .contains { $0.id == fussy.id },
                      "a page waited past the threshold and still never appeared")
    }

    func testAPageAlreadyReadNeverSurfacesAgain() {
        var library = LibraryState()
        let page = ContentCatalog.shared.diaryPages[0]
        library.foundPages = [page.id]
        XCTAssertFalse(LibraryRules.eligiblePages(in: PressureRules.resolve([]), library: library)
            .contains { $0.id == page.id })
    }

    func testPagePlacementIsDeterministicInTheSeed() {
        let readings = PressureRules.resolve([])
        var a = SeededRNG(seed: 20_260_805)
        var b = SeededRNG(seed: 20_260_805)
        XCTAssertEqual(LibraryRules.placePages(in: readings, library: LibraryState(), rng: &a),
                       LibraryRules.placePages(in: readings, library: LibraryState(), rng: &b))
    }

    // MARK: The hint page

    func testTheHintPageCollectsButDoesNotInterpret() {
        let edren = ContentCatalog.shared.traveller("edren")!
        var library = LibraryState()
        // One of two pieces read.
        library.foundPages = [DiaryPageID(rawValue: "edren_where_0")]

        let hint = LibraryRules.hintPage(for: edren, library: library)
        XCTAssertEqual(hint.knownCount, 1)
        XCTAssertEqual(hint.missingCount, edren.complexity - 1)
        XCTAssertFalse(hint.isComplete)

        // The piece you have is the traveller's own words, verbatim.
        XCTAssertEqual(hint.passages[0], edren.signature[0].passage)
        // The piece you don't have is a gap, not a description of the gap.
        XCTAssertNil(hint.passages[1])
    }

    /// It shows *how many* are missing, because that tells you whether to keep hunting or gamble.
    /// It must not show what *kind* is missing — that crosses into interpretation.
    func testAPassageNeverNamesASigilATargetOrAValue() {
        let dialWords = ContentCatalog.shared.pressureTargets.flatMap {
            [$0.id.rawValue.lowercased(), $0.name.lowercased()]
        }
        for traveller in ContentCatalog.shared.travellers {
            for clue in traveller.signature {
                let text = clue.passage.lowercased()
                XCTAssertFalse(text.contains(where: \.isNumber),
                               "\(traveller.id.rawValue) names a number: \(clue.passage)")
                for word in dialWords where text.contains(word) {
                    XCTFail("\(traveller.id.rawValue) names the dial '\(word)': \(clue.passage)")
                }
            }
        }
    }

    /// Partial knowledge is playable: knowing some of it means writing what you know and leaving
    /// the rest to chance. That's the first place leaving the page sparse is a real gamble.
    func testPartialKnowledgeIsEnoughToAttempt() {
        let sela = ContentCatalog.shared.traveller("sela")!
        var library = LibraryState()
        library.foundPages = [DiaryPageID(rawValue: "sela_where_0")]
        let hint = LibraryRules.hintPage(for: sela, library: library)
        XCTAssertTrue(hint.canBeAttempted)
        XCTAssertGreaterThan(hint.missingCount, 0)
    }

    func testTheLibraryOnlyListsPeopleYouHaveHeardOf() {
        var library = LibraryState()
        XCTAssertTrue(LibraryRules.hintPages(in: library).isEmpty,
                      "the Library is what you know, not a checklist of what exists")

        library.knownTravellers = ["mara"]
        XCTAssertEqual(LibraryRules.hintPages(in: library).map(\.traveller.id), ["mara"])
    }

    func testTheLibrarySurvivesAForceQuit() throws {
        let io = SaveFileIO.temporary(name: "library-\(UUID().uuidString)")
        defer { io.deleteEverything() }
        let page = ContentCatalog.shared.diaryPages[0]
        do {
            let store = GameStore(io: io)
            store.mutate("test: read", flush: true) { state in
                _ = WorldRules.readPage(page.id, in: &state)
            }
        }
        let resumed = GameStore(io: io)
        XCTAssertTrue(resumed.state.reality.library.hasFound(page.id),
                      "a page already read was lost — knowledge must never be taken back")
    }
}
