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

    /// **Pages are a guide, never a gate.** Writing the right world by luck puts them in front of
    /// you just the same.
    func testYouCanFindSomeoneWithoutHavingReadAPage() {
        let store = GameStore(io: .temporary(name: "luck-\(UUID().uuidString)"))
        store.mutate("test: fund") { $0.base.essence = 5000 }
        XCTAssertTrue(store.state.reality.library.foundPages.isEmpty)

        for _ in 0..<40 {
            store.bindAndDepart()
            if !(store.state.worlds.activeRun?.travellersHere.isEmpty ?? true) { return }
            store.mutate("test: next") { $0.worlds.activeRun = nil }
        }
        XCTFail("nobody turned up by chance in forty worlds")
    }

    /// **Arriving is not finding** (Aimee, 6 Aug).
    ///
    /// Binding a world that matches somebody's signature used to write them straight into
    /// `foundTravellers`, so a building appeared at the base for a person the player had never laid
    /// eyes on. Now arriving only tells you they're here — and puts them on a tile.
    func testArrivingPutsThemOnTheMapWithoutFindingThem() {
        let store = GameStore(io: .temporary(name: "arrive-\(UUID().uuidString)"))
        store.mutate("test: fund") { $0.base.essence = 5000 }
        for _ in 0..<40 {
            store.bindAndDepart()
            if let run = store.state.worlds.activeRun, !run.travellersHere.isEmpty {
                for id in run.travellersHere {
                    XCTAssertFalse(store.state.reality.library.foundTravellers.contains(id),
                                   "arriving found somebody the player never met")
                    XCTAssertTrue(store.state.reality.library.knownTravellers.contains(id),
                                  "arrived where somebody is and didn't learn to look for them")
                    // …and they are standing somewhere you could walk to.
                    XCTAssertTrue(run.map.allPoints.contains { run.map[$0].content == .traveller(id) },
                                  "\(id.rawValue) is in this world and on no tile in it")
                }
                return
            }
            store.mutate("test: next") { $0.worlds.activeRun = nil }
        }
        XCTFail("no world in forty held anybody")
    }

    func testWorldTravellerReceiptsExactlyMatchPlacedTravellerTiles() {
        let book = BoundBook(symbols: [:], randomlyFilled: [], essencePaid: 0)
        for seed in UInt64(1)...100 {
            let world = Worldgen.generate(book: book, seed: seed)
            let tileTravellers = Set(world.map.allPoints.compactMap { point -> TravellerID? in
                guard case .traveller(let id) = world.map[point].content else { return nil }
                return id
            })

            XCTAssertEqual(Set(world.travellers), tileTravellers, "seed \(seed) returned an unplaced traveller")
            XCTAssertEqual(world.diagnostics.travellersPlaced, world.travellers)
        }
    }

    /// **Walking up to them and agreeing is what finds them**, and that's what raises their
    /// building — the whole point of the search loop, and the thing that didn't exist.
    func testRecruitingIsWhatFindsThemAndUnlocksTheirBuilding() {
        let store = GameStore(io: .temporary(name: "recruit-\(UUID().uuidString)"))
        store.mutate("test: fund") { $0.base.essence = 5000 }

        for _ in 0..<40 {
            store.bindAndDepart()
            guard let run = store.state.worlds.activeRun,
                  let id = run.travellersHere.first,
                  let point = run.map.allPoints.first(where: { run.map[$0].content == .traveller(id) })
            else {
                store.mutate("test: next") { $0.worlds.activeRun = nil }
                continue
            }
            // Stand on them. Reaching somebody is a walk; the test takes the short way.
            store.mutate("test: walk over") { $0.worlds.activeRun?.playerPosition = point }
            XCTAssertEqual(store.travellerHere?.id, id, "standing on them and the scene never opened")

            store.recruit(id)
            XCTAssertTrue(store.state.reality.library.foundTravellers.contains(id))
            XCTAssertFalse(store.state.worlds.activeRun?.map[point].content == .traveller(id),
                           "recruited them and they're still standing there")

            // And if anything is theirs to build, it's now a building site.
            if let station = ContentCatalog.shared.stations.first(where: { $0.builtBy == id }) {
                XCTAssertTrue(store.buildableStations.contains { $0.id == station.id },
                              "\(station.name) didn't appear after recruiting \(id.rawValue)")
            }
            return
        }
        XCTFail("no world in forty held anybody")
    }

    /// You can't raise somebody's building before you've met them — the bug Aimee hit: the forge
    /// appeared for a smith she'd never seen.
    func testABuildingNeedsItsPersonFirst() {
        let store = GameStore(io: .temporary(name: "gate-\(UUID().uuidString)"))
        store.mutate("test: fund") { $0.base.essence = 5000 }
        for station in ContentCatalog.shared.stations where station.builtBy != nil {
            XCTAssertFalse(store.buildableStations.contains { $0.id == station.id },
                           "\(station.name) was buildable before anybody was found")
            XCTAssertFalse(store.build(station), "built \(station.name) without its person")
        }
    }

    // MARK: Pages

    func testLibraryPresentationGivesEveryDiaryPageOneDiaryHome() throws {
        let location = try XCTUnwrap(ContentCatalog.shared.diaryPages.first { $0.kind == .locationClue })
        let other = try XCTUnwrap(ContentCatalog.shared.diaryPages.first { $0.kind != .locationClue })
        var library = LibraryState()
        library.foundPages = [location.id, other.id]

        let presented = LibraryPresentation.diaries(in: library)
            .flatMap { LibraryPresentation.pages(by: $0.id, in: library) }

        XCTAssertEqual(Set(presented.map(\.id)), Set(library.foundPages))
        XCTAssertEqual(presented.count, library.foundPages.count,
                       "a diary page appeared in more than one authored diary")
    }

    func testRecoveredPageMakesItsAuthorVisibleWithoutRevealingTheRestOfTheCast() throws {
        let page = try XCTUnwrap(ContentCatalog.shared.diaryPages.last)
        var library = LibraryState()
        library.foundPages = [page.id]

        XCTAssertEqual(LibraryPresentation.diaries(in: library).map(\.id), [page.diary])
    }

    func testCrossDiaryPageIsIndexedByAuthorAndSubjectWithoutDuplicatingRecovery() throws {
        let page = try XCTUnwrap(ContentCatalog.shared.diaryPages.first {
            guard let about = $0.about else { return false }
            return about != $0.diary
        })
        var library = LibraryState()
        library.foundPages = [page.id]

        XCTAssertEqual(LibraryPresentation.pages(by: page.diary, in: library).map(\.id), [page.id])
        XCTAssertEqual(LibraryPresentation.pages(about: try XCTUnwrap(page.about), in: library).map(\.id),
                       [page.id])
        XCTAssertEqual(library.foundPages.count, 1)
    }

    func testDiaryAndPeopleCountsUseDifferentAxes() throws {
        let authoredElsewhere = try XCTUnwrap(ContentCatalog.shared.diaryPages.first {
            $0.about != nil && $0.about != $0.diary
        })
        let authorOnly = try XCTUnwrap(ContentCatalog.shared.diaryPages.first {
            $0.diary == authoredElsewhere.diary && $0.about != authoredElsewhere.about
        })
        var library = LibraryState()
        library.foundPages = [authoredElsewhere.id, authorOnly.id]

        XCTAssertEqual(LibraryPresentation.pages(by: authoredElsewhere.diary, in: library).count, 2)
        XCTAssertEqual(LibraryPresentation.pages(about: try XCTUnwrap(authoredElsewhere.about),
                                                  in: library).map(\.id), [authoredElsewhere.id])
    }

    func testUnknownRecoveredPageRemainsVisibleAsAnOlderRecord() {
        var library = LibraryState()
        library.foundPages = ["retired_page_from_older_catalogue"]

        XCTAssertEqual(LibraryPresentation.olderRecordIDs(in: library), library.foundPages)
        XCTAssertTrue(LibraryPresentation.diaries(in: library).isEmpty)
    }

    func testWorldNoteTilesOnlyExposeRecoveredFamilies() {
        var library = LibraryState()
        library.foundWritings = [
            .init(id: "field", family: .fieldNote, prose: "Observed.", position: .init(x: 0, y: 0)),
            .init(id: "route", family: .routeMark, prose: "East.", position: .init(x: 1, y: 0))
        ]

        XCTAssertEqual(LibraryPresentation.recoveredNoteFamilies(in: library),
                       [.fieldNote, .routeMark])
    }

    func testTravellerProgressionUsesExplicitAuthoredOrder() {
        XCTAssertEqual(ContentCatalog.shared.travellersInAuthoredOrder.map(\.id),
                       ["vance", "noll", "halloway", "mara", "edren", "isolde", "sela",
                        "bryn", "orsa", "talin", "nessa", "corrin", "dagg", "rook",
                        "lys", "bracken", "fen", "wren", "kestrel", "maud", "marrick", "sabine", "grimmond", "oda", "auber", "ashe", "tovin", "perren", "nine"])
        XCTAssertTrue(ContentCatalog.shared.travellersInAuthoredOrder.allSatisfy {
            $0.authoredOrder != nil && $0.campaignPhase != nil
        })
    }

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

    func testEveryLocationPageQuotesItsSignatureVerbatim() throws {
        // The diary is the player's evidence, so its wording must not drift away from the
        // condition passage ultimately shown on the hint page.
        for traveller in ContentCatalog.shared.travellers {
            for index in traveller.signature.indices {
                let page = try XCTUnwrap(ContentCatalog.shared.diaryPages.first {
                    $0.kind == .locationClue && $0.about == traveller.id && $0.clueIndex == index
                })
                XCTAssertEqual(page.prose, traveller.signature[index].passage,
                               "\(traveller.id.rawValue) clue \(index) tells two different stories")
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

    func testExhaustedDiaryPoolFallsBackToPersistedReachableWorldWriting() throws {
        var library = LibraryState()
        library.foundPages = ContentCatalog.shared.diaryPages.map(\.id)
        let generated = Worldgen.generate(
            book: BoundBook(symbols: [:], randomlyFilled: [], essencePaid: 0),
            seed: 20_260_809, library: library)

        XCTAssertTrue(generated.pages.isEmpty)
        let writing = try XCTUnwrap(generated.writings.first)
        XCTAssertEqual(generated.map[writing.position].content, .foundWriting(writing.id))
        XCTAssertGreaterThan(WorldRules.path(from: generated.start, to: writing.position,
                                             in: generated.map).count, 2)

        let data = try SaveCodec.makeEncoder().encode(generated.writings)
        XCTAssertEqual(try SaveCodec.makeDecoder().decode([FoundWritingRecord].self, from: data),
                       generated.writings, "reload rerolled the writing's prose or host")
    }

    func testEveryWorldGetsOneOrTwoDistinctReachableWritings() {
        let book = BoundBook(symbols: [:], randomlyFilled: [], essencePaid: 0)
        for seed in UInt64(1)...40 {
            let generated = Worldgen.generate(book: book, seed: seed)
            let positions = generated.map.allPoints.filter { point in
                switch generated.map[point].content {
                case .diaryPage, .foundWriting: true
                default: false
                }
            }
            XCTAssertTrue((1...2).contains(positions.count), "seed \(seed) broke the writing promise")
            XCTAssertEqual(Set(positions).count, positions.count)
            XCTAssertTrue(positions.allSatisfy {
                WorldRules.path(from: generated.start, to: $0, in: generated.map).count > 2
            }, "seed \(seed) placed writing outside the eligible exploration band")
        }
    }

    func testGuaranteedWritingUsesConfiguredDiaryOtherMix() {
        var tuning = DebugTuningProfile.defaults
        tuning.additionalPageChance = 0
        let book = BoundBook(symbols: [:], randomlyFilled: [], essencePaid: 0)
        let diaryWorlds = (UInt64(1)...100).reduce(into: 0) { count, seed in
            if !Worldgen.generate(book: book, seed: seed, tuning: tuning).pages.isEmpty { count += 1 }
        }
        XCTAssertTrue((55...85).contains(diaryWorlds),
                      "70/30 selection drifted to \(diaryWorlds)% diary")
    }

    func testDiaryMixCanForceEitherSideWithoutBreakingTheGuarantee() {
        let book = BoundBook(symbols: [:], randomlyFilled: [], essencePaid: 0)
        var allDiary = DebugTuningProfile.defaults
        allDiary.additionalPageChance = 0
        allDiary.diaryWritingShare = 1
        var allOther = allDiary
        allOther.diaryWritingShare = 0

        for seed in UInt64(1)...20 {
            let diary = Worldgen.generate(book: book, seed: seed, tuning: allDiary)
            XCTAssertEqual(diary.pages.count, 1)
            XCTAssertTrue(diary.writings.isEmpty)
            let other = Worldgen.generate(book: book, seed: seed, tuning: allOther)
            XCTAssertTrue(other.pages.isEmpty)
            XCTAssertEqual(other.writings.count, 1)
        }
    }

    func testCustomPatienceFloorChangesOnlyTheNominatedPage() {
        let fussy = ContentCatalog.shared.diaryPages.filter { !$0.prefersConditions.isEmpty }
        guard fussy.count >= 2 else { return XCTFail("fixture needs two condition-bound pages") }
        var library = LibraryState()
        library.patiencePage = fussy[0].id
        library.pagesWaiting = [fussy[0].id: 2, fussy[1].id: 2]
        let eligible = LibraryRules.eligiblePages(in: PressureRules.resolve([]), library: library,
                                                  patienceInWorlds: 2).map(\.id)
        XCTAssertTrue(eligible.contains(fussy[0].id))
        XCTAssertFalse(eligible.contains(fussy[1].id))
    }

    func testReadingAFocusPageMakesItsWordPermanentlyWritable() throws {
        let store = GameStore(io: .temporary(name: "read-focus-\(UUID().uuidString)"))
        let page = try XCTUnwrap(ContentCatalog.shared.diaryPages.first { $0.kind == .focus })
        let focus = try XCTUnwrap(page.teachesFocus)
        store.mutate("test: forget focus") { $0.base.ownedSources.remove(focus) }

        store.mutate("test: read focus") { _ = WorldRules.readPage(page.id, in: &$0) }

        XCTAssertTrue(store.state.base.ownedSources.contains(focus))
        XCTAssertTrue(store.state.reality.library.hasFound(page.id))

        let before = store.state.reality.library.foundPages.count
        store.mutate("test: read focus again") { _ = WorldRules.readPage(page.id, in: &$0) }
        XCTAssertEqual(store.state.reality.library.foundPages.count, before)
    }

    func testReadingAGambitPageMakesItsPhrasePermanentlyWritable() throws {
        let store = GameStore(io: .temporary(name: "read-gambit-\(UUID().uuidString)"))
        let page = try XCTUnwrap(ContentCatalog.shared.diaryPages.first { $0.kind == .gambit })
        let component = try XCTUnwrap(page.teachesGambit)
        store.mutate("test: forget gambit phrase") { $0.base.ownedGambitComponents.remove(component) }

        store.mutate("test: read gambit") { _ = WorldRules.readPage(page.id, in: &$0) }

        XCTAssertTrue(store.state.base.ownedGambitComponents.contains(component))
        XCTAssertTrue(store.state.reality.library.hasFound(page.id))
    }

    func testImplementedTravellersOwnTheirApprovedDiaryFocuses() throws {
        let expected: [TravellerID: PressureSourceID] = [
            "mara": "scarp", "edren": "ruin", "halloway": "gold_ore",
            "isolde": "hush", "sela": "pond", "orsa": "hive", "vance": "amber",
            "nessa": "thorn", "corrin": "chitin", "lys": "echo", "bracken": "bone", "fen": "silk", "sabine": "coral", "grimmond": "mercury",
            "tovin": "drift"
        ]
        for (traveller, focus) in expected {
            let page = try XCTUnwrap(ContentCatalog.shared.diaryPages.first {
                $0.diary == traveller && $0.kind == .focus && $0.teachesFocus == focus
            })
            XCTAssertFalse(page.prose.isEmpty)
            XCTAssertEqual(ContentCatalog.shared.pressureSource(focus)?.acquisition, .diary)
        }
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
        impatient.patiencePage = fussy.id
        XCTAssertTrue(LibraryRules.eligiblePages(in: wrongWorld, library: impatient)
            .contains { $0.id == fussy.id },
                      "a page waited past the threshold and still never appeared")
    }

    func testEveryWorldPlacesAtLeastOneWritingWhileAnyRemain() {
        let readings = PressureRules.resolve([])
        for seed in UInt64(1)...100 {
            var rng = SeededRNG(seed: seed)
            XCTAssertFalse(LibraryRules.placePages(in: readings, library: LibraryState(), rng: &rng).isEmpty,
                           "seed \(seed) generated a world with no writing")
        }
    }

    func testOnlyTheNominatedPageGetsThePatienceFallback() {
        let fussy = ContentCatalog.shared.diaryPages.filter { !$0.prefersConditions.isEmpty }
        guard fussy.count >= 2 else { return XCTFail("fixture needs two condition-bound pages") }
        var library = LibraryState()
        library.patiencePage = fussy[0].id
        library.pagesWaiting = [fussy[0].id: Tuning.Library.patienceInWorlds,
                                fussy[1].id: Tuning.Library.patienceInWorlds]
        let eligible = LibraryRules.eligiblePages(in: PressureRules.resolve([]), library: library).map(\.id)
        XCTAssertTrue(eligible.contains(fussy[0].id))
        XCTAssertFalse(eligible.contains(fussy[1].id))
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

    // MARK: The history of what you wrote

    /// **A wrong deduction has to leave evidence.** Aimee read Mara's clue correctly, wrote a
    /// *giant* sun, and got a dim world — with no way to learn why (6 Aug). The history is the
    /// delayed answer key: what you wrote, what it became, and crucially **which targets you never
    /// wrote at all**, which is the answer to "what rolled over me".
    func testEveryWorldYouEnterIsRecordedWithWhatYouWroteAndWhatItBecame() throws {
        let store = GameStore(io: .temporary(name: "history-\(UUID().uuidString)"))
        store.mutate("test: fund") { $0.base.essence = 500 }
        store.write("plains")
        store.bindAndDepart()

        let recorded = try XCTUnwrap(store.state.reality.library.visitedWorlds.last)
        XCTAssertFalse(recorded.descriptionSentence.isEmpty, "recorded a world with nothing to read")
        XCTAssertFalse(recorded.readings.isEmpty, "recorded a world with no readings")

        // The half a player can't see at the time: some targets they wrote, some the world chose.
        let rolled = recorded.readings.values.filter { !$0.wasWritten }
        XCTAssertFalse(rolled.isEmpty,
                       "nothing is marked as rolled, so the history can't answer 'what got me'")
    }

    /// A modifier that changed nothing is in the record, because that's a mistake in the *writing*
    /// and you shouldn't need an instrument to be told a word you wrote did nothing.
    ///
    /// **Written with Phase, not Scale.** Scale on a sun works now — a vast sun is a bright one
    /// (Aimee, 6 Aug) — so the only genuinely narrow modifiers left are the ones that are narrow on
    /// purpose. Phase says what form water takes and says nothing at all about light, which is
    /// exactly the case the warning still exists for.
    func testTheHistoryRemembersAWordThatSaidNothing() throws {
        let store = GameStore(io: .temporary(name: "inert-\(UUID().uuidString)"))
        store.mutate("test: fund") { $0.base.essence = 500 }
        store.mutate("test: a vast sun") { state in
            var page = Page()
            page.runes = [
                PlacedRune(id: InstanceID(rawValue: 1), content: .target("illumination"),
                           hand: .crude, origin: PageCell(column: 0, row: 0), shapeID: "crude_block"),
                PlacedRune(id: InstanceID(rawValue: 2), content: .source("sun"),
                           hand: .crude, origin: PageCell(column: 2, row: 0), shapeID: "crude_block"),
                PlacedRune(id: InstanceID(rawValue: 3), content: .qualifier("frozen"),
                           hand: .crude, origin: PageCell(column: 0, row: 2), shapeID: "crude_block"),
            ]
            page.links = [MarkLink(InstanceID(rawValue: 1), InstanceID(rawValue: 2)),
                          MarkLink(InstanceID(rawValue: 2), InstanceID(rawValue: 3))]
            state.base.page = page
        }

        // The page itself says so, before you ever bind it.
        let inert = PageRules.inertQualifiers(on: store.state.base.page)
        XCTAssertEqual(inert.first?.qualifier.id, "frozen")
        XCTAssertEqual(inert.first?.target.id, "illumination")

        store.bindAndDepart()
        let recorded = try XCTUnwrap(store.state.reality.library.visitedWorlds.last)
        XCTAssertFalse(recorded.inertModifiers.isEmpty,
                       "wrote a word that did nothing and the record doesn't mention it")
        XCTAssertTrue(recorded.written.contains { $0.contains("Sun") },
                      "the chain you wrote isn't in the record")
        XCTAssertTrue(recorded.focusAttributions.contains { $0.contains("Sun → Illumination") })
        XCTAssertTrue(recorded.focusAttributions.contains { $0.contains("Sun → Thermal") && $0.contains("secondary") },
                      "tier 3 cannot reveal the sun's implicit warmth")
        XCTAssertEqual(Set(recorded.focusEffects.map(\.targetID)), ["illumination", "thermal"])
    }

    /// Kept worlds survive the cap; unkept ones age out. The list is curated rather than infinite.
    func testKeptWorldsSurviveAClearOut() {
        var library = LibraryState()
        func world(_ index: Int, kept: Bool) -> VisitedWorld {
            VisitedWorld(id: InstanceID(rawValue: UInt64(index)), seed: UInt64(index),
                         runIndex: index, descriptionSentence: "", written: [], inertModifiers: [],
                         readings: [:], travellersPresent: [], isKept: kept)
        }
        library.record(world: world(1, kept: true))
        for index in 2...(Tuning.Library.worldsRemembered + 20) {
            library.record(world: world(index, kept: false))
        }
        XCTAssertLessThanOrEqual(library.visitedWorlds.count, Tuning.Library.worldsRemembered)
        XCTAssertTrue(library.visitedWorlds.contains { $0.id == InstanceID(rawValue: 1) },
                      "a kept world was dropped, which is the one thing keeping it prevents")
    }

    // MARK: The Calligrapher — a required gate needs a guaranteed road

    /// **The invariant that would have caught the deadlock.**
    ///
    /// My charcoal test measured *footprints* — whether her signature fits the page you start with.
    /// It does. What it never asked was whether the starting **vocabulary** can express the
    /// conditions at all, and it couldn't: she wanted `atmosphere ≤ 45`, atmosphere's baseline is
    /// 50, and **every starter symbol that touches air raises it**. The only route was to leave it
    /// unwritten and hope — a coin flip, not a deduction — while the clue pointed straight at the
    /// thing that made it worse (`code-audit-13.md`).
    ///
    /// So: for every **required** character, some combination of *starting symbols* must satisfy
    /// every one of their conditions. Fit is not reachability.
    func testEveryRequiredCharacterIsReachableWithTheStartingVocabulary() {
        let starters = ContentCatalog.shared.symbols.filter { $0.acquisition == .starter }
        let required = ContentCatalog.shared.travellers.filter(\.isRequired)
        XCTAssertFalse(required.isEmpty, "nobody is marked required, so this test proves nothing")

        for traveller in required {
            var found = false
            outer: for a in starters {
                for b in starters {
                    for intensity in [Intensity.moderate, .great, .overwhelming] {
                        var sigils: [Sigil] = []
                        var next: UInt64 = 1
                        for symbol in (a.id == b.id ? [a] : [a, b]) {
                            for component in symbol.expandsTo {
                                sigils.append(Sigil(id: InstanceID(rawValue: next),
                                                    source: component.source,
                                                    target: component.target,
                                                    intensity: intensity))
                                next += 1
                            }
                        }
                        if traveller.isFound(in: PressureRules.resolve(sigils)) {
                            found = true
                            break outer
                        }
                    }
                }
            }
            XCTAssertTrue(found,
                          "\(traveller.name) is required and no two starting symbols can reach them")
        }
    }

    /// …and reachable **reliably**, not on a lucky roll. Every unwritten subject is rolled from the
    /// seed, and a rolled occluder is exactly what ate Mara's sunlight — so a required character's
    /// conditions have to survive whatever the world decides for itself.
    func testARequiredCharacterSurvivesWhateverTheWorldRolls() {
        let starters = ContentCatalog.shared.symbols.filter { $0.acquisition == .starter }
        for traveller in ContentCatalog.shared.travellers.filter(\.isRequired) {
            var worstCase = 0, tried = 0
            for a in starters {
                for b in starters where a.id != b.id {
                    var sigils: [Sigil] = []
                    var next: UInt64 = 1
                    for symbol in [a, b] {
                        for component in symbol.expandsTo {
                            sigils.append(Sigil(id: InstanceID(rawValue: next),
                                                source: component.source, target: component.target,
                                                intensity: .great))
                            next += 1
                        }
                    }
                    guard traveller.isFound(in: PressureRules.resolve(sigils)) else { continue }
                    tried += 1
                    // Twenty different rolls of everything they didn't write.
                    let held = (1...20).count { seed in
                        traveller.isFound(in: PressureRules.resolve(sigils,
                                                                    fillingUnwrittenWith: UInt64(seed) &* 7919))
                    }
                    worstCase = max(worstCase, held)
                }
            }
            XCTAssertGreaterThan(tried, 0, "\(traveller.name): no pair of starters reaches them at all")
            XCTAssertGreaterThanOrEqual(worstCase, 18,
                "\(traveller.name) can be written for and still missed \(20 - worstCase) times in 20 — "
                + "a required gate must not be a coin flip")
        }
    }

    /// Perren deliberately asks for several forces to oppose one another. That interpretive hunt
    /// may be difficult, but the authored route must still buy enough actual turns to reach the
    /// person it places; per-condition reachability alone cannot prove that.
    func testPerrensAuthoredOpposedWorldIsSurvivable() throws {
        let statements: [(PressureSourceID, PressureTargetID)] = [
            ("sun", "illumination"), ("void", "illumination"),
            ("sun", "thermal"), ("ice", "thermal"),
            ("bloom", "vitality"), ("miasma", "vitality"),
            ("ruin", "relief"), ("chasm", "relief"), ("scarp", "relief"),
            ("granite", "relief"),
            ("ruin", "substrate"), ("sand", "substrate"),
            ("mist", "atmosphere"), ("orrery", "cycle"),
            ("sea", "hydrology"), ("salt", "hydrology")
        ]
        let sigils = statements.enumerated().map { index, statement in
            Sigil(id: InstanceID(rawValue: UInt64(index + 1)), source: statement.0,
                  target: statement.1, intensity: .great)
        }
        let perren = try XCTUnwrap(ContentCatalog.shared.traveller("perren"))
        let readings = PressureRules.resolve(sigils)
        let openness = readings["relief"].aspect("openness")
        for clue in perren.signature {
            XCTAssertTrue(clue.condition.holds(in: readings),
                          "fixture misses \(clue.condition.displayText); openness is \(openness)")
        }
        XCTAssertTrue(perren.isFound(in: readings), "the documented deliberate route does not find Perren")

        let book = BoundBook(written: [], composition: sigils, essencePaid: 0)
        let turns = BookRules.turnsAvailable(for: book)
        XCTAssertGreaterThanOrEqual(turns, 10,
            "Perren's opposed arrival buys only \(turns) turns; the clue is writable but not safely reachable")
    }

    /// **The hands are behind the Calligrapher, deliberately** (Aimee, 6 Aug: *"the player MUST
    /// meet the calligrapher to progress. it's core to the game"*), and that makes her the one
    /// character who can deadlock a save if her own trail is unreachable.
    ///
    /// So: her signature has to be **writable in the hand you start with**. A required character
    /// behind a signature you'd need the pencil to reach is a circle.
    func testTheCalligraphersOwnWorldIsWritableInCharcoal() throws {
        let isolde = try XCTUnwrap(ContentCatalog.shared.traveller("isolde"))

        // A cluster is a target plus a source, and in charcoal each of those is a big footprint.
        // Measured off the actual shapes rather than a constant, so re-authoring them re-checks it.
        let smallestCrude = ContentCatalog.shared.runeShapes(in: .crude)
            .map(\.offsets.count).min() ?? 6
        let needed = isolde.signature.count * 2 * smallestCrude
        XCTAssertLessThanOrEqual(needed, Page().capacity,
                                 "Isolde is required and her world can't be written in charcoal — "
                                 + "needs \(needed) cells of \(Page().capacity)")

        // And her trail exists, in more than one diary, so an unlucky page distribution can't
        // hide the one character the game insists you meet.
        let aboutHer = ContentCatalog.shared.diaryPages.filter { $0.about == "isolde" }
        XCTAssertGreaterThan(aboutHer.count, isolde.signature.count,
                             "no spare page names Isolde — one bad roll could hide her for good")
        XCTAssertGreaterThan(Set(aboutHer.map(\.diary)).count, 1,
                             "every page naming Isolde is in her own diary")
    }

    /// Nothing in Penmanship is reachable before you've met her — the stated exception to Q40's
    /// "first rungs are free" rule.
    func testNoHandCanBeLearnedBeforeTheScriptoriumIsBuilt() {
        let store = GameStore(io: .temporary(name: "hands-\(UUID().uuidString)"))
        store.mutate("test: rich") { state in
            state.base.essence = 100_000
            for resource in ContentCatalog.shared.resources {
                state.base.resources.add(9_999, of: resource.id)
            }
        }
        for node in ContentCatalog.shared.nodes(in: "penmanship") {
            XCTAssertFalse(store.canResearch(node),
                           "\(node.name) is buyable without the Calligrapher")
            XCTAssertTrue(store.missingPrerequisites(for: node).contains { $0.contains("Isolde") },
                          "\(node.name) is blocked and doesn't say it's Isolde you need")
        }
    }

    /// **Chaining before the fountain pen** — the branch is a line, not a fork.
    func testTheBranchIsALineWithChainingBeforeTheFinestHand() throws {
        let fountain = try XCTUnwrap(ContentCatalog.shared.researchNode("pen_fountain"))
        XCTAssertTrue(fountain.requires.contains("pen_chaining"),
                      "the fountain pen can be reached without ever learning to join two things")
        let chaining = try XCTUnwrap(ContentCatalog.shared.researchNode("pen_chaining"))
        XCTAssertFalse(chaining.requires.contains("pen_fountain"))
        XCTAssertGreaterThan(EconomyRules.depthOf(fountain), EconomyRules.depthOf(chaining))
    }

    /// …and the last one wants the building upgraded, which is the job `maxTier` never had.
    func testTheFinestHandNeedsTheScriptoriumUpgraded() throws {
        let store = GameStore(io: .temporary(name: "tier-\(UUID().uuidString)"))
        store.mutate("test: built, un-upgraded, and rich") { state in
            state.base.essence = 100_000
            for resource in ContentCatalog.shared.resources {
                state.base.resources.add(9_999, of: resource.id)
            }
            state.base.stations[Stations.scriptorium] = StationState(isUnlocked: true, tier: 0)
            // The whole line up to it — chaining comes before the fountain pen (Aimee, 6 Aug):
            // learning to join two statements is the grammar lesson, writing small enough for it
            // to matter is the one after.
            state.base.completedResearch.formUnion(["pen_pencil", "pen_desk", "pen_chaining"])
        }
        let fountain = try XCTUnwrap(ContentCatalog.shared.researchNode("pen_fountain"))
        XCTAssertFalse(store.canResearch(fountain), "the finest hand ignored the building's tier")

        store.mutate("test: upgrade it") { state in
            state.base.stations[Stations.scriptorium] = StationState(isUnlocked: true, tier: 2)
        }
        XCTAssertTrue(store.canResearch(fountain), "upgraded the Scriptorium and still can't learn it")
    }

    /// The hands are the biggest capability jump in the game and cost less than a storehouse tier
    /// (Aimee, 6 Aug: *"WAY too cheap"*). Each one should now want a world you went and wrote.
    func testEachHandCostsARareMaterialFromAParticularKindOfWorld() throws {
        let staples: Set<ResourceID> = ["ore", "fiber", "rubble", "clay", "essence_raw"]
        for node in ContentCatalog.shared.nodes(in: "penmanship") {
            XCTAssertGreaterThan(node.cost.essence, Tuning.Economy.startingEssence * 2,
                                 "\(node.name) is pocket change")
            XCTAssertFalse(node.cost.resources.isEmpty, "\(node.name) asks for no materials at all")
            XCTAssertTrue(node.cost.resources.keys.contains { !staples.contains($0) },
                          "\(node.name) is buyable out of what an ordinary world already pays")
        }
    }

    /// What a brand-new player can actually reach, per subject, using only starting symbols.
    func testReportWhatTheStartingKitCanReach() {
        let starters = ContentCatalog.shared.symbols.filter { $0.acquisition == .starter }
        var lows: [PressureTargetID: Double] = [:], highs: [PressureTargetID: Double] = [:]
        var floorLows: [PressureTargetID: Double] = [:], floorHighs: [PressureTargetID: Double] = [:]

        // Every one, every pair, at every intensity a modifier can reach.
        for a in starters {
            for b in starters {
                for intensity in [Intensity.moderate, .great, .overwhelming] {
                    var sigils: [Sigil] = []
                    var next: UInt64 = 1
                    for symbol in (a.id == b.id ? [a] : [a, b]) {
                        for component in symbol.expandsTo {
                            sigils.append(Sigil(id: InstanceID(rawValue: next),
                                                source: component.source, target: component.target,
                                                intensity: intensity))
                            next += 1
                        }
                    }
                    let readings = PressureRules.resolve(sigils)
                    for reading in readings.inOrder {
                        lows[reading.target] = min(lows[reading.target] ?? 999, reading.peak)
                        highs[reading.target] = max(highs[reading.target] ?? -999, reading.peak)
                        floorLows[reading.target] = min(floorLows[reading.target] ?? 999, reading.floor)
                        floorHighs[reading.target] = max(floorHighs[reading.target] ?? -999, reading.floor)
                    }
                }
            }
        }
        print("WHAT THE STARTING KIT CAN REACH (peak range | floor range)")
        for target in ContentCatalog.shared.pressureTargetsInOrder {
            print(String(format: "  %-14s peak %3.0f–%3.0f   floor %3.0f–%3.0f",
                         (target.name as NSString).utf8String!,
                         lows[target.id] ?? 0, highs[target.id] ?? 0,
                         floorLows[target.id] ?? 0, floorHighs[target.id] ?? 0))
        }
    }

    // MARK: Recruiting has to deliver somebody

    /// **The payoff of the whole search loop.**
    ///
    /// Recruiting used to be two writes to the Library and nothing else — no roster, no gear, no
    /// presence. Aimee found somebody, lost a run, and had *"no idea what happened to her"*
    /// (6 Aug). She was never lost: `foundTravellers` lives in Reality and nothing takes it. There
    /// was simply nothing to show for it, which feels identical to losing her.
    func testRecruitingPutsThemInYourParty() throws {
        let store = GameStore(io: .temporary(name: "join-\(UUID().uuidString)"))
        store.mutate("test: fund") { $0.base.essence = 5000 }
        XCTAssertEqual(store.state.base.roster.count, 1, "somebody is at the fire before you found them")

        for _ in 0..<40 {
            store.bindAndDepart()
            guard let run = store.state.worlds.activeRun,
                  let id = run.travellersHere.first,
                  let point = run.map.allPoints.first(where: { run.map[$0].content == .traveller(id) })
            else {
                store.mutate("test: next") { $0.worlds.activeRun = nil }
                continue
            }
            store.mutate("test: walk over") { $0.worlds.activeRun?.playerPosition = point }
            store.recruit(id)

            let joined = try XCTUnwrap(store.state.base.roster.first { $0.traveller == id },
                                       "recruited somebody and they didn't join the party")
            XCTAssertEqual(joined.name, ContentCatalog.shared.traveller(id)?.name)
            XCTAssertFalse(joined.calling.isEmpty, "they joined without being anybody in particular")
            XCTAssertFalse(joined.gambits.isEmpty, "they joined with no idea what to do in a fight")

            // And you can take them **as well as** Quill — a party, not a swap.
            let index = try XCTUnwrap(store.state.base.roster.firstIndex { $0.traveller == id })
            store.setComing(index, true)
            XCTAssertTrue(store.state.base.activeParty.contains(index),
                          "recruited them, took them, and they still aren't coming")
            XCTAssertTrue(store.state.base.activeParty.contains(0),
                          "taking somebody new pushed Quill out — that's a swap, not a party")
            XCTAssertEqual(store.state.base.partyMembers.count, 3, "you and two others")
            return
        }
        XCTFail("no world in forty held anybody")
    }

    /// A collapse can't take them. They're in the Base layer, and the Library entry is in Reality.
    func testAPersonSurvivesACollapse() throws {
        let store = GameStore(io: .temporary(name: "survive-\(UUID().uuidString)"))
        store.mutate("test: somebody is with you") { state in
            var joined = CompanionState()
            joined.name = "Halloway"
            joined.traveller = "halloway"
            state.base.roster.append(joined)
            state.reality.library.foundTravellers.insert("halloway")
        }
        store.write("plains")
        store.mutate("test: fund") { $0.base.essence = 500 }
        store.bindAndDepart()
        store.endRunWithPartialHaul(reason: "test: the floor took you")

        XCTAssertTrue(store.state.base.roster.contains { $0.traveller == "halloway" },
                      "a collapse took somebody out of the party")
    }

    func testLibraryPersonStatusUsesCurrentPlacementNotRecruitmentAlone() throws {
        var state = GameState.newGame()
        var mara = CompanionState()
        mara.name = "Mara"
        mara.traveller = "mara"
        state.base.roster.append(mara)
        let index = state.base.roster.count - 1
        state.reality.library.foundTravellers.insert("mara")
        let definition = try XCTUnwrap(ContentCatalog.shared.traveller("mara"))

        XCTAssertEqual(LibraryPresentation.placementLabel(for: definition, in: state), "At Home")
        state.base.activeParty.append(index)
        XCTAssertEqual(LibraryPresentation.placementLabel(for: definition, in: state), "With you")

        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let historySource = try String(contentsOf: root.appendingPathComponent(
            "Sources/Screens/WorldHistoryView.swift"), encoding: .utf8)
        XCTAssertTrue(historySource.contains(
            "LibraryPresentation.placementLabel(for: person, in: store.state)"
        ))
        XCTAssertFalse(historySource.contains("? \"with you\" : \"still there\""))
    }

    func testRunRecapListsOnlyPagesFoundThisTrip() throws {
        let store = GameStore(io: .temporary(name: "recap-pages-\(UUID().uuidString)"))
        let pages = ContentCatalog.shared.diaryPages
        let old = try XCTUnwrap(pages.first)
        let fresh = try XCTUnwrap(pages.dropFirst().first)
        store.mutate("already known") { $0.reality.library.foundPages = [old.id] }
        store.mutate("fund") { $0.base.essence = 500 }
        XCTAssertTrue(store.bindAndDepart())
        store.mutate("read in this world") { _ = WorldRules.readPage(fresh.id, in: &$0) }

        store.endRunWithPartialHaul(reason: "test")

        XCTAssertEqual(store.state.worlds.lastExit?.pages, [fresh.id])
        XCTAssertTrue(store.state.reality.library.hasFound(fresh.id),
                      "collapse removed permanent page knowledge")
    }

    func testRunRecapIncludesOtherWritingAndNewlyRecruitedPeople() throws {
        let store = GameStore(io: .temporary(name: "recap-kept-\(UUID().uuidString)"))
        store.mutate("fund") { $0.base.essence = 500 }
        XCTAssertTrue(store.bindAndDepart())
        let writing = FoundWritingRecord(id: "recap-field-note", family: .fieldNote,
                                         prose: "The warm stones hold water.",
                                         position: GridPoint(x: 0, y: 0))
        store.mutate("recover permanent discoveries") { state in
            state.reality.library.foundWritings.append(writing)
            state.reality.library.foundTravellers.insert("halloway")
        }

        store.endRunWithPartialHaul(reason: "test")

        XCTAssertEqual(store.state.worlds.lastExit?.writings.map(\.id), ["recap-field-note"])
        XCTAssertEqual(store.state.worlds.lastExit?.writings.first?.prose,
                       "The warm stones hold water.")
        XCTAssertEqual(store.state.worlds.lastExit?.recruitedTravellers, ["halloway"])
    }

    func testPortalRecapIncludesPermanentDiscoveriesToo() throws {
        let store = GameStore(io: .temporary(name: "recap-portal-kept-\(UUID().uuidString)"))
        store.mutate("fund") { $0.base.essence = 500 }
        XCTAssertTrue(store.bindAndDepart())
        store.mutate("recover permanent discoveries") { state in
            state.reality.library.foundWritings.append(.init(
                id: "recap-route-mark", family: .routeMark, prose: "Three stones east.",
                position: GridPoint(x: 0, y: 0)))
            state.reality.library.foundTravellers.insert("mara")
        }

        XCTAssertTrue(store.canPortalHere)
        store.portalHome()

        XCTAssertEqual(store.state.worlds.lastExit?.writings.map(\.id), ["recap-route-mark"])
        XCTAssertEqual(store.state.worlds.lastExit?.recruitedTravellers, ["mara"])
    }

    /// Five is the expedition party including the Binder, not the number of people who may live at Home.
    func testTheActivePartyHoldsFiveWhileTheRosterKeepsGrowing() {
        let store = GameStore(io: .temporary(name: "five-\(UUID().uuidString)"))
        store.mutate("test: fill it") { state in
            while state.base.roster.count < Tuning.Party.maximumSize + 3 {
                state.base.roster.append(CompanionState())
            }
            state.base.activeParty = Array(0..<(Tuning.Party.maximumSize - 1))
        }
        XCTAssertEqual(store.state.base.partyMembers.count, Tuning.Party.maximumSize)
        XCTAssertFalse(store.state.base.canTakeAnother)
        XCTAssertTrue(store.state.base.canRecruit)
    }

    // MARK: The fire has to hold everybody you found

    /// **Aimee's save, reproduced.** 7 Aug: *"I have FOUND TRAVELERS. that is NOT the issue. the
    /// FOUND travelers not appearing at the firepit is the issue."*
    ///
    /// The roster is newer than the search loop, so anyone recruited before it existed went into
    /// `library.foundTravellers` and nowhere else — and worldgen refuses to place a traveller who
    /// has already been found, so there was no way to meet them again either. Found, gone, and no
    /// route back.
    @MainActor
    func testAnOldSaveFullOfFoundTravellersSeatsThemAtTheFire() throws {
        let io = SaveFileIO.temporary(name: "stranded-\(UUID().uuidString)")
        let everyone = ContentCatalog.shared.travellers.prefix(3).map(\.id)

        // A save from before the roster existed: found in the Library, nobody at the fire but Quill.
        do {
            let store = GameStore(io: io)
            store.mutate("test: an old save", flush: true) { state in
                state.reality.library.foundTravellers = Set(everyone)
                state.reality.library.knownTravellers = Set(everyone)
                state.base.roster = [CompanionState()]
            }
            XCTAssertEqual(store.state.base.roster.count, 1, "fixture didn't take")
        }

        // Launching the game is what puts it right.
        let reopened = GameStore(io: io)
        for id in everyone {
            let seated = reopened.state.base.roster.first { $0.traveller == id }
            XCTAssertNotNil(seated, "\(id.rawValue) was found and has nowhere to be")
            XCTAssertEqual(seated?.name, ContentCatalog.shared.traveller(id)?.name)
            XCTAssertFalse(seated?.calling.isEmpty ?? true, "seated without being anybody in particular")
            XCTAssertFalse(seated?.gambits.isEmpty ?? true, "seated with no idea what to do in a fight")
        }
        XCTAssertEqual(reopened.state.base.roster.count, 1 + everyone.count)

        // And the Firepit shows them as people you can take, not as one person you already have.
        let waiting = reopened.state.base.roster.enumerated()
            .filter { $0.offset != reopened.state.base.activeCompanion }
        XCTAssertEqual(waiting.count, everyone.count,
                       "the fire is still empty with \(everyone.count) people found")
    }

    /// Idempotent: launching twice must not seat anybody twice.
    @MainActor
    func testSeatingEveryoneFoundDoesNotDuplicateThem() {
        let io = SaveFileIO.temporary(name: "reseat-\(UUID().uuidString)")
        let id = ContentCatalog.shared.travellers[0].id
        do {
            let store = GameStore(io: io)
            store.mutate("test: found one", flush: true) {
                $0.reality.library.foundTravellers = [id]
            }
        }
        _ = GameStore(io: io)
        let third = GameStore(io: io)
        XCTAssertEqual(third.state.base.roster.count { $0.traveller == id }, 1,
                       "three launches seated the same person more than once")
    }

    func testEveryNamedTravellerCanJoinBeyondFiveTotalResidents() {
        var base = BaseState()
        let travellers = Array(ContentCatalog.shared.travellersInAuthoredOrder.prefix(7))

        for traveller in travellers { XCTAssertTrue(base.seat(traveller.id)) }

        XCTAssertEqual(base.roster.count, travellers.count + 1, "Quill plus every named recruit")
        XCTAssertTrue(base.canRecruit)
    }
}
