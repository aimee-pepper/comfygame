import XCTest
@testable import Bookbinder

/// Content is data, so content mistakes are data mistakes — these tests are the spellchecker.
/// Adding a symbol/creature/station to JSON and getting an ID wrong should fail here, loudly,
/// rather than silently spawning nothing in a world.
final class ContentTests: XCTestCase {
    func testPenmanshipIsBrushRootedWithThreeIndependentTierOnePractices() throws {
        let catalog = ContentCatalog.shared
        let brush = try XCTUnwrap(catalog.researchNode("pen_brush"))
        XCTAssertTrue(brush.requires.isEmpty)
        XCTAssertNil(catalog.researchNode("pen_pencil"))

        let siblings = ["pen_ink_mixing", "pen_compounds", "pen_chaining"]
            .compactMap(catalog.researchNode)
        XCTAssertEqual(siblings.count, 3)
        for node in siblings {
            XCTAssertEqual(node.requires, ["pen_brush"])
            XCTAssertEqual(node.needsStationTier, 1)
        }
        XCTAssertEqual(Set(siblings.flatMap(\.requires)), ["pen_brush"])

        let fountain = try XCTUnwrap(catalog.researchNode("pen_fountain"))
        XCTAssertEqual(fountain.requires, ["pen_chaining"])
        XCTAssertEqual(fountain.needsStationTier, 2)
    }

    func testCurrentResearchAndDiaryCopyContainsNoPlayerFacingPencil() {
        for node in ContentCatalog.shared.researchNodes {
            XCTAssertFalse("\(node.name) \(node.blurb)".localizedCaseInsensitiveContains("pencil"),
                           "legacy tool copy remains on \(node.id)")
        }
        for page in ContentCatalog.shared.diaryPages {
            XCTAssertFalse(page.prose.localizedCaseInsensitiveContains("pencil"),
                           "legacy tool copy remains on \(page.id)")
        }
    }

    func testSettingsDestinationsShareOneNavigationCardGrammar() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(contentsOf: root.appendingPathComponent(
            "Sources/Screens/SettingsView.swift"), encoding: .utf8)

        XCTAssertTrue(source.contains("private struct SettingsDestinationRow: View"))
        XCTAssertEqual(source.components(separatedBy: "SettingsDestinationRow(").count - 1, 4)
        XCTAssertTrue(source.contains("Image(systemName: \"chevron.right\")"))
        XCTAssertFalse(source.contains("rectangle.portrait.and.arrow.right"))
        XCTAssertTrue(source.contains(".frame(minHeight: 44)"))
    }

    func testBundledPlayerFacingCatalogueCopyContainsNoPlaceholderMarkers() throws {
        let projectRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let dataDirectory = projectRoot.appending(path: "Sources/Content/Data")
        let files = try FileManager.default.contentsOfDirectory(
            at: dataDirectory,
            includingPropertiesForKeys: nil
        ).filter { $0.pathExtension == "json" }

        for file in files {
            let object = try JSONSerialization.jsonObject(with: Data(contentsOf: file))
            assertPlayerFacingCopyHasNoPlaceholderMarker(object, path: file.lastPathComponent)
        }
    }

    private func assertPlayerFacingCopyHasNoPlaceholderMarker(_ value: Any, path: String) {
        if let dictionary = value as? [String: Any] {
            for (key, child) in dictionary {
                let childPath = "\(path).\(key)"
                if ["name", "blurb", "description", "title", "subtitle"].contains(key),
                   let text = child as? String {
                    XCTAssertFalse(text.localizedCaseInsensitiveContains("placeholder"),
                                   "Player-facing copy at \(childPath) exposes placeholder status")
                }
                assertPlayerFacingCopyHasNoPlaceholderMarker(child, path: childPath)
            }
        } else if let array = value as? [Any] {
            for (index, child) in array.enumerated() {
                assertPlayerFacingCopyHasNoPlaceholderMarker(child, path: "\(path)[\(index)]")
            }
        }
    }
    func testEveryPlaceholderCatalogueHasFieldDispositionMetadata() throws {
        try ContentCatalog.validateBundledAuthorityMetadata()
        XCTAssertEqual(ContentCatalog.provisionalAuthorityFileNames.count, 17)

        let metadata = ContentCatalog.AuthorityMetadata(
            schemaVersion: 1,
            defaultDisposition: .settled,
            numericValues: .playtestTuning,
            playerFacingCopy: .provisionalCopy
        )
        XCTAssertEqual(metadata.disposition(forFieldNamed: "id", value: "venom"), .settled)
        XCTAssertEqual(metadata.disposition(forFieldNamed: "potency", value: 2), .playtestTuning)
        XCTAssertEqual(metadata.disposition(forFieldNamed: "enabled", value: true), .settled)
        XCTAssertEqual(metadata.disposition(forFieldNamed: "blurb", value: "copy"), .provisionalCopy)
    }

    func testLiveCatalogueCopyDoesNotLeakPlaceholderLanguageToPlayers() {
        XCTAssertFalse(ContentCatalog.shared.items.contains {
            $0.name.localizedCaseInsensitiveContains("placeholder") ||
            $0.blurb.localizedCaseInsensitiveContains("placeholder")
        })
    }

    func testCatalogLoadsAndValidates() throws {
        let catalog = try ContentCatalog.load()
        XCTAssertNoThrow(try catalog.validate())
    }

    func testMeetingConversationPreservesTapOrderAndFreezesAtDecision() {
        var first = TravellerMeetingConversation()
        first.ask("isolde.charcoal_hand")
        first.ask("isolde.blank_board")
        first.ask("isolde.teacher")
        XCTAssertEqual(first.orderedExchangeIDs,
                       ["isolde.charcoal_hand", "isolde.blank_board", "isolde.teacher"])
        first.ask("isolde.blank_board")
        XCTAssertEqual(first.orderedExchangeIDs.count, 3, "an exchange appeared twice")
        first.accept()
        first.ask("later")
        first.decline()
        XCTAssertEqual(first.terminal, .accepted)
        XCTAssertFalse(first.orderedExchangeIDs.contains("later"))

        var second = TravellerMeetingConversation()
        second.ask("isolde.teacher")
        second.ask("isolde.charcoal_hand")
        second.decline()
        XCTAssertEqual(second.orderedExchangeIDs, ["isolde.teacher", "isolde.charcoal_hand"])
        XCTAssertEqual(second.terminal, .declined)
    }

    func testMeetingExchangeIdentitySurvivesCopyRevision() throws {
        let before = try JSONDecoder().decode(TravellerMeeting.Exchange.self, from: Data(
            #"{"id":"isolde.teacher","ask":"You taught this?","reply":"Forty years."}"#.utf8))
        let after = try JSONDecoder().decode(TravellerMeeting.Exchange.self, from: Data(
            #"{"id":"isolde.teacher","ask":"Were you a teacher?","reply":"For forty years."}"#.utf8))
        XCTAssertEqual(before.id, after.id)
        XCTAssertNotEqual(before.ask, after.ask)
    }

    func testReleaseCataloguePromotesOneMeetingForEveryTraveller() throws {
        let catalogue = try ContentCatalog.load()
        XCTAssertEqual(catalogue.travellers.count, 29)
        XCTAssertTrue(catalogue.travellers.allSatisfy { $0.meeting != nil })
        XCTAssertTrue(catalogue.travellers.allSatisfy { traveller in
            guard let meeting = traveller.meeting else { return false }
            return meeting.questions.count == 3
                && meeting.questions.allSatisfy { $0.id.hasPrefix("\(traveller.id.rawValue).") }
        })
    }

#if DEBUG
    func testAuthoredTextAtlasReviewsTheSameLiveMeetingCorpus() throws {
        let inventory = AuthoredTextAtlas.inventory()
        let catalogue = ContentCatalog.shared
        let catalogueIDs = Set(catalogue.travellers.map(\.id))
        let generatedIDs = Set(AuthoredMeetingCorpus.meetings.map { TravellerID(rawValue: $0.travellerID) })
        XCTAssertEqual(AuthoredTextAtlas.generatedMeetingIDs, generatedIDs)

        XCTAssertEqual(catalogue.travellers.count, 29)
        XCTAssertEqual(catalogue.diaryPages.count, 238,
                       "Noll has five findable pages; the held Field Separation Kit page is DEBUG-only")
        XCTAssertEqual(catalogue.travellers.filter { $0.meeting != nil }.count, 29)
        XCTAssertEqual(AuthoredMeetingCorpus.meetings.count, 23,
                       "21 formerly missing meetings plus Noll and Auber replacements")
        XCTAssertNil(AuthoredMeetingCorpus.decodingError)
        XCTAssertEqual(generatedIDs.subtracting(catalogueIDs), [])
        XCTAssertEqual(Set(inventory.map(\.id)), catalogueIDs)
        XCTAssertEqual(inventory.flatMap(\.units).filter { $0.kind == .diary }.count,
                       catalogue.diaryPages.count + 1,
                       "the held Field Separation Kit page is reviewable but not findable")
        XCTAssertEqual(Set(inventory.flatMap(\.units).map(\.id)).count, inventory.flatMap(\.units).count)
        XCTAssertTrue(inventory.allSatisfy { $0.meetingState == "Live" })
        XCTAssertTrue(AuthoredMeetingCorpus.meetings.allSatisfy { $0.exchanges.count == 3 })
        XCTAssertTrue(AuthoredMeetingCorpus.meetings.allSatisfy { $0.offerSpeaker == .player })

        for authored in AuthoredMeetingCorpus.meetings {
            let live = try XCTUnwrap(catalogue.traveller(TravellerID(rawValue: authored.travellerID))?.meeting)
            XCTAssertEqual(live.opening, authored.opening)
            XCTAssertEqual(live.questions.map(\.id), authored.exchanges.map(\.id))
            XCTAssertEqual(live.questions.map(\.ask), authored.exchanges.map(\.ask))
            XCTAssertEqual(live.questions.map(\.reply), authored.exchanges.map(\.reply))
            XCTAssertEqual(live.offer, authored.offer)
            XCTAssertEqual(live.accepted, authored.accepted)
            XCTAssertEqual(live.declined, authored.declined)
        }
        XCTAssertEqual(AuthoredMeetingCorpus.meeting(for: "bryn")?.exchanges.first?.id, "bryn.held_route")
        let emphasized = AuthoredTextRendering.attributed("What happens *after*?")
        XCTAssertEqual(String(emphasized.characters), "What happens after?",
                       "Live authored meetings must use the same Markdown-aware rendering path")
    }

    func testDecision279ExactIsoldeRepliesAndSabineClueIdentity() throws {
        let isolde = try XCTUnwrap(ContentCatalog.shared.traveller("isolde")?.meeting)
        XCTAssertEqual(isolde.questions.map(\.id),
                       ["isolde.blank_board", "isolde.teacher", "isolde.charcoal_hand"])
        XCTAssertEqual(isolde.questions.map(\.reply), [
            "\u{201c}The board is for resistance, not ink.\u{201d} She draws the line again, slower. \u{201c}If the hand cannot keep its course here, giving it charcoal only records the mistake.\u{201d}",
            "\u{201c}For forty years. Mostly to people who wanted to write faster.\u{201d} A short laugh. \u{201c}They had to learn smaller first. Smaller takes longer.\u{201d}",
            "She looks at you for the first time. \u{201c}Then every mark has had to carry too much.\u{201d} She sets the board down. \u{201c}Show me your hands.\u{201d}"
        ])

        let clues = ContentCatalog.shared.diary(of: "sabine")
            .filter { $0.kind == .locationClue }
            .sorted { ($0.clueIndex ?? .max) < ($1.clueIndex ?? .max) }
        XCTAssertEqual(clues.map { $0.id.rawValue }, (0...6).map { "sabine_where_\($0)" })
        XCTAssertEqual(clues.map(\.clueIndex), Array(0...6).map(Optional.some))
        XCTAssertEqual(clues.map(\.about), Array(repeating: TravellerID(rawValue: "sabine"), count: 7).map(Optional.some))
        XCTAssertEqual(clues.map(\.prose), [
            "Bite the new shoots down at dusk and they stand above the old cut by morning. This place can answer feeding without pretending nothing was taken.",
            "Every shelter is occupied, and fresh tracks stop at the entrances before turning away. More creatures live here than one keeper could gather.",
            "Small grazers crowd the new growth. Larger tracks circle them, and scavengers follow what the hunt leaves behind. Feed one creature here and three others change their route.",
            "The same hollows are pressed flat each night while nearby ground goes untouched. Return often enough and absence becomes part of the pattern.",
            "Hoofprints, paws and dragging tails reach the water by different banks. No creature has to pass another's shelter to drink.",
            "There is open ground enough to approach and cover near enough to refuse. I could work here without making nearness the only safe choice.",
            "The same calls begin at the same interval, and the same paths fill soon after. They can learn when I return; that does not mean they must come."
        ])
        let sabine = try XCTUnwrap(ContentCatalog.shared.traveller("sabine"))
        XCTAssertEqual(sabine.signature.map(\.passage), clues.map(\.prose),
                       "Location disclosure and recovered diary clues must tell one exact story")
    }

    @MainActor func testAuthoredTextReviewBecomesStaleAndRoundTripsUnicode() throws {
        let suite = "atlas-review-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = AuthoredTextReviewStore(defaults: defaults)
        let original = AuthoredTextAtlas.Unit(id: "meeting.isolde.opening", traveller: "isolde",
                                               kind: .meeting, label: "Opening",
                                               text: "A board — and a hand.", detail: nil)
        store.review(original, as: .needsRevision, note: "Keep the em dash — and café.")
        XCTAssertEqual(store.status(for: original), .needsRevision)
        XCTAssertFalse(store.isStale(original))
        let changed = AuthoredTextAtlas.Unit(id: original.id, traveller: original.traveller,
                                              kind: original.kind, label: original.label,
                                              text: original.text + " Changed.", detail: nil)
        XCTAssertTrue(store.isStale(changed))
        XCTAssertEqual(store.status(for: changed), .unreviewed)
        let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(AuthoredTextReviewStore.File.self,
                                         from: Data(store.jsonReport().utf8))
        XCTAssertEqual(decoded.entries[original.id]?.note, "Keep the em dash — and café.")
    }

    @MainActor func testAuthoredTextReviewImportMergesNewerMatchingTextAndSurfacesConflict() throws {
        let suite = "atlas-import-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = AuthoredTextReviewStore(defaults: defaults)
        let unit = AuthoredTextAtlas.Unit(id: "meeting.nessa.exchange.nessa.time.ask", traveller: "nessa",
                                          kind: .meeting, label: "Question", text: "What happens *after*?", detail: nil)
        store.review(unit, as: .good, note: "local")
        let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
        let encoder = JSONEncoder(); encoder.dateEncodingStrategy = .iso8601
        var imported = try decoder.decode(AuthoredTextReviewStore.File.self, from: Data(store.jsonReport().utf8))
        imported.entries[unit.id]?.status = .needsRevision
        imported.entries[unit.id]?.note = "newer café"
        imported.entries[unit.id]?.reviewedAt = Date().addingTimeInterval(60)
        try store.importReport(encoder.encode(imported))
        XCTAssertEqual(store.status(for: unit), .needsRevision)
        XCTAssertEqual(store.note(for: unit), "newer café")

        imported.entries[unit.id]?.reviewedTextHash = "different-copy"
        try store.importReport(encoder.encode(imported))
        XCTAssertEqual(store.conflicts.map(\.id), [unit.id])
        XCTAssertEqual(store.note(for: unit), "newer café", "A conflict must not silently replace local work")
    }

    @MainActor func testCorrectedMeetingReviewAliasesRequireExactTextHash() throws {
        let unit = try XCTUnwrap(AuthoredTextAtlas.inventory().first { $0.id == "sela" }?.units.first {
            $0.id == "meeting.sela.exchange.sela.destination.ask"
        })
        let oldID = "meeting.sela.exchange.halloway.destination.ask"
        let suite = "atlas-alias-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let encoder = JSONEncoder(); encoder.dateEncodingStrategy = .iso8601
        let entry = AuthoredTextReviewStore.Entry(status: .good, note: "preserve",
                                                   reviewedTextHash: unit.textHash, reviewedAt: Date())
        defaults.set(try encoder.encode(AuthoredTextReviewStore.File(entries: [oldID: entry])),
                     forKey: "debug.authoredTextReview.v1")
        let migrated = AuthoredTextReviewStore(defaults: defaults)
        XCTAssertEqual(migrated.status(for: unit), .good)
        XCTAssertTrue(migrated.migrationWarnings.isEmpty)

        defaults.set(try encoder.encode(AuthoredTextReviewStore.File(entries: [oldID:
            .init(status: .needsRevision, note: nil, reviewedTextHash: "changed", reviewedAt: Date())])),
                     forKey: "debug.authoredTextReview.v1")
        let mismatched = AuthoredTextReviewStore(defaults: defaults)
        XCTAssertEqual(mismatched.status(for: unit), .unreviewed)
        XCTAssertEqual(mismatched.migrationWarnings.count, 1)
    }
#endif

    func testStarterCollectionMatchesTheBrief() {
        // The brief names eleven (Q2). "Ore" is a twelfth, added on Aimee's instruction that the
        // bounty slot needs a neutral middle rung — see questions-for-design Q15.
        let expected: Set<SymbolID> = [
            "plains", "caverns", "archipelago",
            "verdant", "ashen", "frostbound",
            "sparse_ore", "common_ore", "rich_ore", "teeming_life",
            "dim_sky", "gilded_veins",
        ]
        XCTAssertEqual(Set(ContentCatalog.shared.starterSymbolIDs), expected)
    }

    /// The rule that makes the bounty slot a decision instead of a toll: below the baseline calms a
    /// world, the baseline costs nothing, above it destabilises.
    func testTheBountyLadderRunsBelowAtAndAboveTheBaseline() throws {
        let sparse = try XCTUnwrap(ContentCatalog.shared.symbol("sparse_ore"))
        let ordinary = try XCTUnwrap(ContentCatalog.shared.symbol("common_ore"))
        let rich = try XCTUnwrap(ContentCatalog.shared.symbol("rich_ore"))

        // **Measured, not printed** (Q44). These used to be hand-typed on the symbols, which meant
        // the ladder was true by assertion; it is now true only if the three expansions really do sit
        // below, at and above an ordinary amount of rock.
        XCTAssertGreaterThan(BookRules.stabilityDelta(ofSymbolAlone: sparse.id), 0,
                             "Asking for less than there is calms a world")
        // Within a few points rather than exactly nil: every focus deviates from ordinary by
        // *something*, so a measured meter has no way to spell an exact zero. Ore you can dig is
        // slightly more rock than a world ordinarily carries, and it should read as costing nothing.
        XCTAssertEqual(BookRules.stabilityDelta(ofSymbolAlone: ordinary.id), 0, accuracy: 4,
                       "Asking for what's already there costs nothing")
        XCTAssertLessThan(BookRules.stabilityDelta(ofSymbolAlone: rich.id), 0,
                          "Asking for more than there is, is greed")

        // …and the yields have to follow the same ladder, or the names are lying.
        let sparseOre = sparse.yieldModifiers[Resources.ore] ?? 1
        let ordinaryOre = ordinary.yieldModifiers[Resources.ore] ?? 1
        let richOre = rich.yieldModifiers[Resources.ore] ?? 1
        XCTAssertLessThan(sparseOre, ordinaryOre)
        XCTAssertLessThan(ordinaryOre, richOre)
    }

    /// **You must be able to write something on the first turn.**
    ///
    /// This used to assert one starter symbol per *slot*, and slots are gone (`fossil-audit.md` §4).
    /// The claim underneath it survives and is stronger: a new game has to arrive with enough
    /// vocabulary to say something, or the writing desk opens onto nothing.
    func testANewGameCanWriteSomething() {
        XCTAssertFalse(ContentCatalog.shared.starterSymbolIDs.isEmpty,
                       "a new game has no symbols and the desk opens onto nothing")
        XCTAssertFalse(ContentCatalog.shared.starterSourceIDs.isEmpty,
                       "a new game has no words for the page")
    }

    /// Sight belongs to the creature, so later ones can notice you from further off.
    func testEveryCreatureCanSee() {
        for creature in ContentCatalog.shared.creatures {
            XCTAssertGreaterThan(creature.sightRadius, 0, "'\(creature.id)' would never notice you")
        }
    }

    func testThreeCreatureTypesShip() {
        XCTAssertEqual(ContentCatalog.shared.creatures.count, 3, "v0 ships exactly three enemy types")
    }

    /// You start able to say a little, and everything else is learned. Every starter component
    /// has to exist, or a new game begins with rules it can't read.
    func testStarterComponentsAllExist() {
        for id in GambitStarter.components {
            XCTAssertNotNil(ContentCatalog.shared.gambitComponent(id), "Unknown starter component '\(id)'")
        }
        for rule in GambitStarter.rules {
            XCTAssertTrue(rule.isWritable(with: Set(GambitStarter.components)),
                          "A starter rule uses something a new player doesn't have")
        }
    }

    /// Every kind of component needs at least one instance or the grammar has a hole in it.
    func testTheGrammarIsComplete() {
        for kind in GambitComponentDef.Kind.allCases {
            XCTAssertFalse(ContentCatalog.shared.components(kind).isEmpty,
                           "No '\(kind.rawValue)' components exist")
        }
    }

    /// All research is gated behind a themed branch — there is no flat shopping list.
    func testEveryBranchHasReachableWork() {
        for branch in ContentCatalog.shared.branchesInOrder {
            let nodes = ContentCatalog.shared.nodes(in: branch.id)
            XCTAssertFalse(nodes.isEmpty, "Branch '\(branch.id)' has no nodes")
            XCTAssertTrue(nodes.contains { $0.requires.isEmpty },
                          "Branch '\(branch.id)' has no entry point — every node is behind another")
        }
    }

    /// A prerequisite cycle would make part of the tree permanently unreachable, and it wouldn't
    /// be obvious from reading the JSON.
    func testTheResearchTreeHasNoCycles() {
        var resolved = Set<ResearchNodeID>()
        var progressed = true
        while progressed {
            progressed = false
            for node in ContentCatalog.shared.researchNodes where !resolved.contains(node.id) {
                if node.requires.allSatisfy({ resolved.contains($0) }) {
                    resolved.insert(node.id)
                    progressed = true
                }
            }
        }
        let unreachable = ContentCatalog.shared.researchNodes.filter { !resolved.contains($0.id) }
        XCTAssertTrue(unreachable.isEmpty,
                      "Unreachable research: \(unreachable.map(\.id.rawValue).joined(separator: ", "))")
    }

    func testCuriosIdentifyIntoAConsumableAndAKey() {
        let curios = ContentCatalog.shared.items.filter { $0.kind == .curio }
        XCTAssertEqual(curios.count, 2, "v0 ships two unidentified curio types")

        let outcomes = curios.compactMap { $0.identifiesInto }.compactMap { ContentCatalog.shared.item($0)?.kind }
        XCTAssertTrue(outcomes.contains(.consumable), "One curio must identify into a consumable")
        XCTAssertTrue(outcomes.contains(.key), "One curio must identify into a key (the locked-cache payoff)")
    }

    /// Catalogue and compiled station destinations must remain a complete two-way bridge.
    func testStationRoutesResolveToRealScreens() {
        let authored = Set(ContentCatalog.shared.stations.map(\.route))
        let compiled = Set(AppRoute.allCases.filter(\.isStationRoute).map(\.rawValue))
        let missing = authored.subtracting(compiled).sorted()
        let orphaned = compiled.subtracting(authored).sorted()

        XCTAssertEqual(missing, [], "Station catalogue routes missing compiled screens: \(missing)")
        XCTAssertEqual(orphaned, [], "Compiled station screens missing catalogue routes: \(orphaned)")
    }

    func testStationsCoverTheSixV0Screens() {
        let ids = Set(ContentCatalog.shared.stations.map(\.id))
        for required in [Stations.writingDesk, Stations.storehouse, Stations.workshop,
                         Stations.party, Stations.essenceSpring, Stations.constellation] {
            XCTAssertTrue(ids.contains(required), "Missing station '\(required)'")
        }
    }

    /// **One node, and it does something** — which is better than three where two didn't.
    ///
    /// The Fifth Mark granted a book slot for books that stopped having slots when the page grid
    /// replaced them, and the Kept Spring pays out after a reset the game can't perform. Both cut
    /// (`fossil-audit.md`). The count isn't the property worth asserting; `EconomyTests` asserts
    /// the one that is — that every node's effect is read by something.
    func testTheConstellationHasSomethingToBuy() {
        XCTAssertFalse(ContentCatalog.shared.constellationNodes.isEmpty,
                       "nothing left to spend motes on")
        for node in ContentCatalog.shared.constellationNodes {
            XCTAssertEqual(node.moteCostPerRank.count, node.maxRank, "Node '\(node.id)' needs a cost per rank")
        }
    }

    /// A new game must be internally consistent with whatever the catalogs currently say.
    func testNewGameIsBuiltFromTheCatalog() {
        let state = GameState.newGame()
        XCTAssertEqual(state.base.ownedSymbols.count, ContentCatalog.shared.starterSymbolIDs.count)
        XCTAssertEqual(state.base.stations.count, ContentCatalog.shared.stations.count)
        XCTAssertEqual(state.base.companion.gambits.count, GambitStarter.rules.count)
        for id in state.base.ownedSymbols {
            XCTAssertNotNil(ContentCatalog.shared.symbol(id), "New game grants unknown symbol '\(id)'")
        }
    }

    /// Tier counts upgrades purchased, so a fresh Storehouse (tier 0) grants no bonus slots.
    ///
    /// The brief's literal eight is superseded — **way more slots, and far more upgrades** (Aimee,
    /// 5 Aug), because three tiers of four capped the hold at twenty forever and that fights the
    /// hoarding pillar outright. What's pinned here is the shape, not a number that moves.
    func testInventoryStartsWorkableAndGrowsPerStorehouseTier() {
        var base = BaseState.newGame()
        let starting = base.inventory.slots
        XCTAssertEqual(starting, Tuning.Economy.startingInventorySlots)
        XCTAssertGreaterThanOrEqual(starting, 8, "a fresh hold should never be smaller than the brief's")

        base.stations[Stations.storehouse] = StationState(isUnlocked: true, tier: 2)
        base.syncInventoryCapacity()
        XCTAssertEqual(base.inventory.slots,
                       starting + 2 * Tuning.Economy.inventorySlotsPerStorehouseTier)
    }

    /// **The hold has to end up big enough to hoard in.** A ladder that tops out at twenty slots is
    /// a ladder you finish in an hour and never think about again.
    @MainActor
    func testAFullyUpgradedHoldIsWorthHoardingIn() {
        let rungs = ContentCatalog.shared.nodes(in: "hold").count { node in
            node.grants.contains { $0.effect == .storehouseTier }
        }
        let full = Tuning.Economy.startingInventorySlots
            + rungs * Tuning.Economy.inventorySlotsPerStorehouseTier
        XCTAssertGreaterThan(full, 60, "a fully-studied storehouse still only holds \(full)")
    }

    func testStationMaxTiersAreReachable() {
        for station in ContentCatalog.shared.stations {
            XCTAssertLessThanOrEqual(station.startingTier, station.maxTier,
                                     "Station '\(station.id)' starts above its max tier")
        }
    }

    func testValidationCatchesADanglingReference() throws {
        let catalog = try ContentCatalog.load()
        var broken = catalog.symbols
        broken[0].yieldModifiers = ["not_a_real_resource": 2.0]
        let sabotaged = ContentCatalog(
            symbols: broken,
            creatures: catalog.creatures,
            resources: catalog.resources,
            items: catalog.items,
            skills: catalog.skills,
            pressureTargets: catalog.pressureTargets,
            pressureSources: catalog.pressureSources,
            researchBranches: catalog.researchBranches,
            researchNodes: catalog.researchNodes,
            gambitComponents: catalog.gambitComponents,
            stations: catalog.stations,
            constellationNodes: catalog.constellationNodes,
            sites: catalog.sites,
            contradictions: catalog.contradictions,
            descriptionClauses: catalog.descriptionClauses,
            combatTrees: catalog.combatTrees,
            combatGraph: catalog.combatGraph,
            runeShapes: catalog.runeShapes,
            qualifiers: catalog.qualifiers,
            travellers: catalog.travellers,
            diaryPages: catalog.diaryPages
        )
        XCTAssertThrowsError(try sabotaged.validate())
    }
}
