import XCTest
@testable import Bookbinder

/// Spending: refining, upgrades, identification, the key→cache payoff, and Constellation nodes.
@MainActor
final class EconomyTests: XCTestCase {

    func testWritingDeskReviewRedactsUnknownHalfOfLegacyRuneBeforeAnyStringsExist() throws {
        let store = GameStore(io: .temporary(name: "desk-redaction-\(UUID().uuidString)"))
        let source: PressureSourceID = "sun"
        let legacy = PlacedRune(
            id: .init(rawValue: 991),
            sigil: Sigil(id: .init(rawValue: 992), source: source, target: "illumination"),
            hand: .plain, origin: .init(column: 0, row: 0), shapeID: "refined_dot")
        store.mutate("install partially known legacy mark") { state in
            state.base.ownedSources.remove(source)
            state.base.page = Page(runes: [legacy])
            state.reality.encounteredLexemes.formUnion(legacy.content.encounteredLexemes)
        }

        let review = try XCTUnwrap(store.writingDeskReviewModel())

        XCTAssertEqual(review.visibleMarkCount, 1)
        XCTAssertEqual(review.unreadMarkCount, 1)
        XCTAssertEqual(review.visibleMarks[0].displayName, "??")
        XCTAssertEqual(review.visibleMarks[0].accessibilityName, "Unknown mark")
        XCTAssertEqual(review.pageThumbnail.marks[0].id, legacy.id)
        XCTAssertEqual(review.pageThumbnail.marks[0].cells, legacy.cells)
        XCTAssertTrue(review.knownRequests.isEmpty,
                      "a known target must not disclose the unknown source half")
        XCTAssertNil(review.openSubjects)
        XCTAssertEqual(review.stabilityRange, 0...100)
        XCTAssertEqual(review.sightDisclosure, review.dangerDisclosure)
        XCTAssertFalse(review.uncertaintyReason.localizedCaseInsensitiveContains("sun"))
        let playerFacing = [review.visibleMarks[0].displayName,
                            review.visibleMarks[0].accessibilityName,
                            review.uncertaintyReason,
                            review.sightDisclosure,
                            review.dangerDisclosure,
                            review.ecologyDisclosure].joined(separator: " ")
        XCTAssertFalse(playerFacing.localizedCaseInsensitiveContains("sun"),
                       "the opaque rendererAssetKey is never a string/accessibility source")
    }

    func testUnreadCollectedPagesUseSameBroadForecastDespiteDifferentHiddenSemantics() throws {
        let store = GameStore(io: .temporary(name: "desk-unread-pages-\(UUID().uuidString)"))
        let pages = Array(store.state.base.collectedWorldPages.prefix(2))
        XCTAssertEqual(pages.count, 2)
        XCTAssertNotEqual(pages[0].definition.page, pages[1].definition.page)
        XCTAssertEqual(pages[0].definition.worldPageCost, pages[1].definition.worldPageCost)
        store.mutate("conceal collected semantics") { state in
            state.base.ownedSources = []
            state.base.ownedSymbols = []
            state.reality.encounteredLexemes = []
        }

        let first = try XCTUnwrap(store.writingDeskReviewModel(
            selectedWorldPageID: pages[0].id))
        let second = try XCTUnwrap(store.writingDeskReviewModel(
            selectedWorldPageID: pages[1].id))

        XCTAssertGreaterThan(first.unreadMarkCount, 0)
        XCTAssertGreaterThan(second.unreadMarkCount, 0)
        XCTAssertEqual(first.stabilityRange, 0...100)
        XCTAssertEqual(second.stabilityRange, 0...100)
        XCTAssertEqual(first.collapseDisclosure, second.collapseDisclosure)
        XCTAssertEqual(first.collapseDisclosure.copy, second.collapseDisclosure.copy)
        XCTAssertEqual(first.sightDisclosure, second.sightDisclosure)
        XCTAssertEqual(first.dangerDisclosure, second.dangerDisclosure)
        XCTAssertEqual(first.ecologyDisclosure, second.ecologyDisclosure)
        XCTAssertNil(first.openSubjects)
        XCTAssertNil(second.openSubjects)
    }

    func testUnreadVitalityAndNonVitalityMeaningsCannotChangeAnyForecastCopy() throws {
        func review(target: PressureTargetID) throws -> WritingDeskReviewModel {
            let store = GameStore(io: .temporary(name: "desk-hidden-\(target.rawValue)-\(UUID().uuidString)"))
            let mark = PlacedRune(
                id: .init(rawValue: 700),
                sigil: Sigil(id: .init(rawValue: 701), source: "sun", target: target),
                hand: .plain, origin: .init(column: 0, row: 0), shapeID: "refined_dot")
            store.mutate("install unread legacy meaning") { state in
                state.base.ownedSources.remove("sun")
                state.base.page = Page(runes: [mark])
                state.reality.encounteredLexemes.formUnion(mark.content.encounteredLexemes)
            }
            return try XCTUnwrap(store.writingDeskReviewModel())
        }

        let vitality = try review(target: "vitality")
        let illumination = try review(target: "illumination")
        XCTAssertEqual(vitality.ecologyDisclosure, illumination.ecologyDisclosure)
        XCTAssertEqual(vitality.sightDisclosure, illumination.sightDisclosure)
        XCTAssertEqual(vitality.dangerDisclosure, illumination.dangerDisclosure)
        XCTAssertEqual(vitality.uncertaintyReason, illumination.uncertaintyReason)
        XCTAssertEqual(vitality.openSubjects, illumination.openSubjects)
        XCTAssertEqual(vitality.stabilityRange, illumination.stabilityRange)
        XCTAssertEqual(vitality.collapseDisclosure, illumination.collapseDisclosure)
    }

    func testCollectedReviewNeverFallsBackToDraftWhenCanonicalSnapshotChanges() throws {
        let store = GameStore(io: .temporary(name: "desk-stale-source-\(UUID().uuidString)"))
        let page = try XCTUnwrap(store.state.base.collectedWorldPages.first)
        store.mutate("stale collected definition") {
            $0.base.collectedWorldPages[0].definition.seed &+= 1
        }

        XCTAssertNil(store.writingDeskReviewModel(selectedWorldPageID: page.id))
        XCTAssertNotNil(store.writingDeskReviewModel(),
                        "the draft remains available only when explicitly selected")
    }

    func testWritingDeskBindQuoteFreezesSourceSeedCostInkAndFieldKit() throws {
        let store = GameStore(io: .temporary(name: "desk-bind-quote-\(UUID().uuidString)"))
        store.mutate("make quote available") { state in
            state.base.essence = 100
            state.base.preparationLoadout = []
            state.base.preparationLoadoutNeedsReview = false
        }
        let original = try XCTUnwrap(store.writingDeskBindQuote())
        XCTAssertEqual(original.sourceKey,
                       store.writingDeskReviewModel()?.sourceKey)
        XCTAssertEqual(original.reservedCampaignSeed,
                       store.state.worlds.seeds.peekNextSeed())
        XCTAssertEqual(original.totalCost, original.pageCost)
        XCTAssertEqual(original.availableEssence, 100)
        XCTAssertEqual(original.essenceAfter, 100 - original.totalCost)
        XCTAssertEqual(original.fieldKitReceipt, .allowed(.init(
            packed: Inventory(slots: store.state.base.satchelCapacity),
            remainingInventory: store.state.base.inventory,
            shortages: [])))

        store.mutate("make staged quote stale") { state in
            _ = state.worlds.seeds.nextSeed()
        }
        let changed = try XCTUnwrap(store.writingDeskBindQuote())
        XCTAssertNotEqual(changed, original)
        XCTAssertNotEqual(changed.reservedCampaignSeed, original.reservedCampaignSeed)
    }

    func testWritingDeskBindQuoteStalesOnStillSufficientWalletChange() throws {
        let store = GameStore(io: .temporary(name: "desk-wallet-stale-\(UUID().uuidString)"))
        store.mutate("prepare exact wallet quote") { state in
            state.base.essence = 100
            state.base.preparationLoadout = []
            state.base.preparationLoadoutNeedsReview = false
        }
        var interfered = false
        let committed = store.bindAndDepart(openColorResolver: { scope, sigil, seed in
            if !interfered {
                store.mutate("change wallet without making bind unaffordable") {
                    $0.base.essence = 99
                }
                interfered = true
            }
            return try WorldGrade2BindAdapter.openColor(
                scope: scope, selectedSigilID: sigil.id, mapSeed: seed)
        })
        XCTAssertTrue(interfered)
        XCTAssertFalse(committed)
        XCTAssertEqual(store.state.base.essence, 99)
        XCTAssertNil(store.state.worlds.activeRun)
    }

    func testInkReceiptOrdersEqualChannelsByConversionVersionThenStableVialID() throws {
        let old = InkRecipe(cyan: 25, magenta: 25, yellow: 25, depth: 25,
                            conversionVersion: "a-version")
        let new = InkRecipe(cyan: 25, magenta: 25, yellow: 25, depth: 25,
                            conversionVersion: "z-version")
        func quote(reversed: Bool) throws -> WritingDeskBindQuote {
            let store = GameStore(io: .temporary(name: "desk-ink-order-\(UUID().uuidString)"))
            let first = PlacedRune(id: .init(rawValue: 1), content: .source("sun"), hand: .plain,
                                   origin: .init(column: 0, row: 0), shapeID: "refined_dot",
                                   inkRecipe: old)
            let second = PlacedRune(id: .init(rawValue: 2), content: .source("sun"), hand: .plain,
                                    origin: .init(column: 1, row: 0), shapeID: "refined_dot",
                                    inkRecipe: new)
            let vials = [PreparedInkVial(id: 20, recipe: old, remainingApplications: 2),
                         PreparedInkVial(id: 10, recipe: new, remainingApplications: 2)]
            store.mutate("prepare versioned ink quote") { state in
                state.base.essence = 100
                state.base.page = Page(runes: [first, second])
                state.base.preparedInkVials = reversed ? Array(vials.reversed()) : vials
                state.base.preparationLoadout = []
                state.base.preparationLoadoutNeedsReview = false
            }
            return try XCTUnwrap(store.writingDeskBindQuote())
        }
        let forward = try quote(reversed: false)
        let reversed = try quote(reversed: true)
        XCTAssertEqual(forward.preparedInkReceipt, reversed.preparedInkReceipt)
        XCTAssertEqual(forward.preparedInkReceipt.map(\.recipe.conversionVersion),
                       ["a-version", "z-version"])
    }

    func testRedactedRequestsRequireReadableConnectedStatementsAndPreservePageOrder() throws {
        let store = GameStore(io: .temporary(name: "desk-requests-\(UUID().uuidString)"))
        let illumination = PlacedRune(id: .init(rawValue: 40), content: .target("illumination"),
                                      hand: .plain, origin: .init(column: 0, row: 0), shapeID: "refined_dot")
        let sun = PlacedRune(id: .init(rawValue: 41), content: .source("sun"),
                             hand: .plain, origin: .init(column: 1, row: 0), shapeID: "refined_dot")
        let vitality = PlacedRune(id: .init(rawValue: 10), content: .target("vitality"),
                                  hand: .plain, origin: .init(column: 0, row: 2), shapeID: "refined_dot")
        let bloom = PlacedRune(id: .init(rawValue: 11), content: .source("bloom"),
                               hand: .plain, origin: .init(column: 1, row: 2), shapeID: "refined_dot")
        store.mutate("install two ordered requests") { state in
            state.base.ownedSources.formUnion(["sun", "bloom"])
            // Insertion order intentionally disagrees with target/name and stable-ID order.
            state.base.page = Page(
                runes: [illumination, sun, vitality, bloom],
                links: [MarkLink(illumination.id, sun.id), MarkLink(vitality.id, bloom.id)])
        }
        let joined = try XCTUnwrap(store.writingDeskReviewModel())
        XCTAssertEqual(joined.knownRequests.map(\.subject), ["Illumination", "Vitality"])
        XCTAssertEqual(joined.knownRequests.map { $0.focuses.map(\.name) }, [["Sun"], ["Bloom"]])
        XCTAssertEqual(joined.silentMarkCount, 0)

        store.mutate("disconnect every mark") { $0.base.page.links = [] }
        let disconnected = try XCTUnwrap(store.writingDeskReviewModel())
        XCTAssertTrue(disconnected.knownRequests.isEmpty)
        XCTAssertEqual(disconnected.silentMarkCount, 4)
    }

    func testUnreadClusterMemberSuppressesRelationWithoutCallingReadableMarksRequests() throws {
        let store = GameStore(io: .temporary(name: "desk-unread-cluster-\(UUID().uuidString)"))
        let target = PlacedRune(id: .init(rawValue: 1), content: .target("illumination"),
                                hand: .plain, origin: .init(column: 0, row: 0), shapeID: "refined_dot")
        let source = PlacedRune(id: .init(rawValue: 2), content: .source("sun"),
                                hand: .plain, origin: .init(column: 1, row: 0), shapeID: "refined_dot")
        store.mutate("install partly unread cluster") { state in
            state.base.ownedSources.remove("sun")
            state.base.page = Page(runes: [target, source], links: [MarkLink(target.id, source.id)])
            state.reality.encounteredLexemes.insert(.source("sun"))
        }
        let review = try XCTUnwrap(store.writingDeskReviewModel())
        XCTAssertTrue(review.knownRequests.isEmpty)
        XCTAssertEqual(review.unreadMarkCount, 1)
        XCTAssertEqual(review.silentMarkCount, 1)
        XCTAssertFalse(review.uncertaintyReason.localizedCaseInsensitiveContains("illumination"))
    }

    func testMalformedExtraTargetAndMisattachedQualifierRemainSilent() throws {
        let store = GameStore(io: .temporary(name: "desk-malformed-request-\(UUID().uuidString)"))
        let target = PlacedRune(id: .init(rawValue: 1), content: .target("illumination"),
                                hand: .plain, origin: .init(column: 0, row: 0), shapeID: "refined_dot")
        let source = PlacedRune(id: .init(rawValue: 2), content: .source("sun"),
                                hand: .plain, origin: .init(column: 1, row: 0), shapeID: "refined_dot")
        let extraTarget = PlacedRune(id: .init(rawValue: 3), content: .target("vitality"),
                                     hand: .plain, origin: .init(column: 2, row: 0), shapeID: "refined_dot")
        let wrongQualifier = PlacedRune(id: .init(rawValue: 4), content: .qualifier("great"),
                                        hand: .plain, origin: .init(column: 0, row: 1), shapeID: "refined_dot")
        store.mutate("install malformed connected cluster") { state in
            state.base.ownedSources.insert("sun")
            state.base.page = Page(
                runes: [target, source, extraTarget, wrongQualifier],
                links: [MarkLink(target.id, source.id),
                        MarkLink(source.id, extraTarget.id),
                        MarkLink(target.id, wrongQualifier.id)])
        }
        let review = try XCTUnwrap(store.writingDeskReviewModel())
        XCTAssertEqual(review.knownRequests.count, 1)
        XCTAssertEqual(review.knownRequests[0].subject, "Illumination")
        XCTAssertEqual(review.knownRequests[0].focuses[0].qualifiers, [])
        XCTAssertEqual(review.silentMarkCount, 2,
                       "the unused target and target-attached qualifier remain visible as inert")
    }

    func testWritingDeskWritePaneReturnsToDraftWithoutConsumingCollectedSelection() {
        let selected = WorldPageCatalog.starterInstances[0].id
        XCTAssertNil(WritingDeskSourceRules.selectedPage(afterEnteringWrite: true,
                                                         current: selected))
        XCTAssertEqual(WritingDeskSourceRules.selectedPage(afterEnteringWrite: false,
                                                           current: selected), selected)
        XCTAssertEqual(GameState.newGame().base.collectedWorldPages.count, 3,
                       "Changing the active source is not a physical-page mutation")
    }

    func testNewCampaignOwnsExactlyThreeStarterWorldPagesAndLegacyAdoptionIsOneTime() throws {
        let fresh = GameState.newGame()
        XCTAssertTrue(fresh.base.starterWorldPageBundleFulfilled)
        XCTAssertEqual(fresh.base.collectedWorldPages, WorldPageCatalog.starterInstances)

        var object = try XCTUnwrap(JSONSerialization.jsonObject(
            with: SaveCodec.makeEncoder().encode(fresh)) as? [String: Any])
        var base = try XCTUnwrap(object["base"] as? [String: Any])
        base.removeValue(forKey: "collectedWorldPages")
        base.removeValue(forKey: "starterWorldPageBundleFulfilled")
        object["base"] = base
        let legacy = try SaveCodec.makeDecoder().decode(
            GameState.self, from: JSONSerialization.data(withJSONObject: object))
        XCTAssertTrue(legacy.base.collectedWorldPages.isEmpty)
        XCTAssertFalse(legacy.base.starterWorldPageBundleFulfilled)
        let store = GameStore(io: .temporary(name: "starter-adopt-\(UUID().uuidString)"))
        store.mutate("load legacy starter state") { $0 = legacy }
        store.reconcileStarterWorldPageBundle()
        XCTAssertEqual(store.state.base.collectedWorldPages, WorldPageCatalog.starterInstances)
        XCTAssertTrue(store.state.base.starterWorldPageBundleFulfilled)
        let adopted = store.state
        store.reconcileStarterWorldPageBundle()
        XCTAssertEqual(store.state, adopted)

        let data = try SaveCodec.makeEncoder().encode(store.state)
        let reloaded = try SaveCodec.makeDecoder().decode(GameState.self, from: data)
        XCTAssertEqual(reloaded.base.collectedWorldPages, WorldPageCatalog.starterInstances)
        XCTAssertTrue(reloaded.base.starterWorldPageBundleFulfilled)
    }

    func testProgressedLegacyCampaignNeverReceivesStarterWorldPages() {
        var progressed = GameState.newGame()
        progressed.base.collectedWorldPages = []
        progressed.base.starterWorldPageBundleFulfilled = false
        progressed.worlds.runIndex = 1
        progressed.reality.lifetime.runsStarted = 1
        let store = GameStore(io: .temporary(name: "starter-progressed-\(UUID().uuidString)"))
        store.mutate("load progressed starter state") { $0 = progressed }

        store.reconcileStarterWorldPageBundle()

        XCTAssertTrue(store.state.base.starterWorldPageBundleFulfilled)
        XCTAssertTrue(store.state.base.collectedWorldPages.isEmpty)
    }

    func testEachStarterWorldPageUsesExactPriceSeedAndFrozenHistoryWhileAdvancingCampaignSeed() throws {
        for instance in WorldPageCatalog.starterInstances {
            let store = GameStore(io: .temporary(
                name: "starter-bind-\(instance.id.rawValue)-\(UUID().uuidString)"))
            store.mutate("fund starter bind") { $0.base.essence = 100 }
            let campaignSeed = store.state.worlds.seeds.peekNextSeed()
            var expectedSequence = store.state.worlds.seeds
            XCTAssertEqual(expectedSequence.nextSeed(), campaignSeed)
            let expectedCost = instance.definition.worldPageCost

            XCTAssertEqual(store.worldPageProjection(instance.id)?.cost, expectedCost)
            XCTAssertTrue(store.bindAndDepart(worldPageInstanceID: instance.id))

            let run = try XCTUnwrap(store.state.worlds.activeRun)
            XCTAssertEqual(run.mapSeed, instance.definition.seed)
            XCTAssertEqual(run.book.essencePaid, expectedCost)
            XCTAssertEqual(run.book.worldPageUseReceipt?.definition, instance.definition)
            XCTAssertEqual(store.state.base.essence, 100 - expectedCost)
            XCTAssertFalse(store.state.base.collectedWorldPages.contains { $0.id == instance.id })
            XCTAssertEqual(store.state.worlds.seeds.peekNextSeed(), expectedSequence.peekNextSeed(),
                           "The next drafted world must follow exactly one reserved campaign seed")
            let history = try XCTUnwrap(store.state.reality.library.visitedWorlds.last)
            XCTAssertEqual(history.seed, instance.definition.seed)
            XCTAssertEqual(history.bindEssencePaid, expectedCost)
            XCTAssertEqual(history.worldPageUseReceipt, run.book.worldPageUseReceipt)
        }
    }

    func testDuplicateWorldPageIdentityRefusesWithoutAnyMutation() throws {
        let store = GameStore(io: .temporary(name: "starter-duplicate-\(UUID().uuidString)"))
        let instance = try XCTUnwrap(store.state.base.collectedWorldPages.first)
        store.mutate("duplicate physical identity") { $0.base.collectedWorldPages.append(instance) }
        let before = store.state

        XCTAssertFalse(store.bindAndDepart(worldPageInstanceID: instance.id))
        XCTAssertEqual(store.state, before)
    }

    func testTamperedEmbeddedWorldPageDefinitionRefusesWithoutAnyMutation() throws {
        let store = GameStore(io: .temporary(name: "starter-tamper-\(UUID().uuidString)"))
        let instance = try XCTUnwrap(store.state.base.collectedWorldPages.first)
        store.mutate("tamper frozen page authority") { state in
            state.base.collectedWorldPages[0].definition.seed &+= 1
        }
        let before = store.state

        XCTAssertFalse(store.bindAndDepart(worldPageInstanceID: instance.id))
        XCTAssertEqual(store.state, before)
    }

    func testWorldPageAdapterFailureConsumesNoPageSeedOrEssence() throws {
        enum Expected: Error { case failure }
        let store = GameStore(io: .temporary(name: "starter-adapter-\(UUID().uuidString)"))
        let instance = try XCTUnwrap(store.state.base.collectedWorldPages.first)
        let before = store.state

        XCTAssertFalse(store.bindAndDepart(worldPageInstanceID: instance.id,
                                           openColorResolver: { _, _, _ in throw Expected.failure }))
        XCTAssertEqual(store.state, before)
    }

    func testWorldPageCommitRevalidatesStagedAuthorityWithoutPartialBindMutation() throws {
        enum Sabotage: CaseIterable { case essence, seed, page, anchorage }

        for sabotage in Sabotage.allCases {
            let store = GameStore(io: .temporary(name: "starter-stale-\(sabotage)-\(UUID().uuidString)"))
            let instance = try XCTUnwrap(store.state.base.collectedWorldPages.first)
            store.mutate("prepare stale bind") { state in
                state.base.essence = 10_000
                if sabotage == .anchorage {
                    state.base.stations[Stations.anchorage] = StationState(isUnlocked: true, tier: 1)
                }
            }
            var sabotaged = false
            var expectedAfterSabotage: GameState?
            let committed = store.bindAndDepart(
                worldPageInstanceID: instance.id, bornAnchored: sabotage == .anchorage,
                openColorResolver: { scope, sigil, seed in
                    if !sabotaged {
                        store.mutate("invalidate staged bind") { state in
                            switch sabotage {
                            case .essence: state.base.essence = 0
                            case .seed: _ = state.worlds.seeds.nextSeed()
                            case .page: state.base.collectedWorldPages[0].definition.seed &+= 1
                            case .anchorage:
                                state.base.stations[Stations.anchorage] = StationState(isUnlocked: false, tier: 0)
                            }
                        }
                        expectedAfterSabotage = store.state
                        sabotaged = true
                    }
                    return try WorldGrade2BindAdapter.openColor(
                        scope: scope, selectedSigilID: sigil.id, mapSeed: seed)
                })

            XCTAssertTrue(sabotaged, "Fixture must cross the preparation/commit seam")
            XCTAssertFalse(committed)
            XCTAssertEqual(store.state, expectedAfterSabotage,
                           "\(sabotage) must preserve the exact post-interference state")
            XCTAssertNil(store.state.worlds.activeRun)
            XCTAssertTrue(store.state.reality.library.visitedWorlds.isEmpty)
        }
    }
    func testWritingPaletteUsesThreeReadableColumnsOnAnOrdinaryPhone() {
        XCTAssertEqual(WritingDeskLayout.paletteChipMinimumWidth, 104)
        XCTAssertEqual(WritingDeskLayout.paletteColumnCount(containerWidth: 344), 3)
        XCTAssertEqual(WritingDeskLayout.paletteColumnCount(containerWidth: 320), 2)
        let ordinary = WritingDeskLayout.writePaneMetrics(containerWidth: 368, containerHeight: 600)
        XCTAssertEqual(ordinary.pageOuterSide, 344)
        XCTAssertEqual(ordinary.cellSide, 54)
        XCTAssertEqual(ordinary.pageInset, 10)
        XCTAssertEqual(ordinary.paletteColumns, 3)
        XCTAssertEqual(CGFloat(ordinary.paletteColumns) * 104
                       + CGFloat(ordinary.paletteColumns - 1) * 8, 328)
        XCTAssertEqual(ordinary.cellSide * 6 + ordinary.pageInset * 2, ordinary.pageOuterSide)
        let fallback = WritingDeskLayout.writePaneMetrics(containerWidth: 320, containerHeight: 600)
        XCTAssertEqual(fallback.pageOuterSide, 296)
        XCTAssertEqual(fallback.cellSide, 46.5)
        XCTAssertEqual(fallback.pageInset, 8.5)
        XCTAssertEqual(fallback.paletteColumns, 2)
        XCTAssertEqual(CGFloat(fallback.paletteColumns) * 104
                       + CGFloat(fallback.paletteColumns - 1) * 8, 216)
        XCTAssertEqual(fallback.cellSide * 6 + fallback.pageInset * 2, fallback.pageOuterSide)
        let threeX = WritingDeskLayout.writePaneMetrics(
            containerWidth: 320, containerHeight: 600, displayScale: 3)
        XCTAssertEqual((threeX.cellSide * 3).rounded(), threeX.cellSide * 3)
    }

    func testGambitEditorUsesPlayerInstructionsInsteadOfSchemaPlaceholders() {
        XCTAssertEqual(GambitEditorPresentation.placeholder(for: .subject), "Choose who")
        XCTAssertEqual(GambitEditorPresentation.placeholder(for: .property), "Stat")
        XCTAssertEqual(GambitEditorPresentation.placeholder(for: .comparator), "Test")
        XCTAssertEqual(GambitEditorPresentation.placeholder(for: .threshold), "Value")
        XCTAssertEqual(GambitEditorPresentation.placeholder(for: .action), "Action")
    }

    func testGambitEditorDistinguishesActiveSlotsFromWrittenIdleRules() {
        XCTAssertEqual(GambitEditorPresentation.slotSummary(written: 1, slots: 2), "1/2 active")
        XCTAssertEqual(GambitEditorPresentation.slotSummary(written: 2, slots: 2), "2/2 active")
        XCTAssertEqual(GambitEditorPresentation.slotSummary(written: 3, slots: 2), "2 active · 3 written")
        XCTAssertEqual(GambitEditorPresentation.addRuleLabel(written: 1, slots: 2), "Write a rule")
        XCTAssertEqual(GambitEditorPresentation.addRuleLabel(written: 2, slots: 2), "Write an idle rule")
        XCTAssertEqual(GambitEditorPresentation.addRuleLabel(written: 3, slots: 2), "Write an idle rule")
    }

    func testIdentificationShortfallNamesTheExactMissingEssence() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(contentsOf: root.appendingPathComponent(
            "Sources/Screens/SpendingViews.swift"), encoding: .utf8)

        XCTAssertTrue(source.contains("Needs \\(identifyEssenceShortfall) more essence to identify."))
        XCTAssertTrue(source.contains(
            "max(0, Tuning.Economy.identifyCostEssence - store.state.base.essence)"
        ))
        XCTAssertFalse(source.contains("Not enough essence to identify anything."))
    }

    func testSettingsDistinguishesPushDestinationsFromCampaignReturn() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(contentsOf: root.appendingPathComponent(
            "Sources/Screens/SettingsView.swift"), encoding: .utf8)

        XCTAssertTrue(source.contains("var directionIcon = \"chevron.right\""))
        XCTAssertTrue(source.contains("subtitle: \"Return to the campaign chooser\","))
        XCTAssertTrue(source.contains("directionIcon: \"rectangle.portrait.and.arrow.right\""))
        XCTAssertFalse(source.contains("directionIcon: \"chevron.backward\""))
        XCTAssertTrue(source.contains("Image(systemName: directionIcon)"))
    }

    func testAnchorageNamesTheTravellerReturnDestination() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(contentsOf: root.appendingPathComponent(
            "Sources/Screens/StationViews.swift"), encoding: .utf8)

        XCTAssertTrue(source.contains("Button(\"Return Home\")"))
        XCTAssertTrue(source.contains("store.unassignCompanion(index, fromAnchoredRealm: realm.id)"))
        XCTAssertFalse(source.contains("Button(\"Return\") { store.unassignCompanion"))
    }

    func testLootDecisionConfirmsTheExactItemBeforeLeavingItBehind() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(
            contentsOf: root.appending(path: "Sources/Screens/LootDecisionView.swift"),
            encoding: .utf8
        )

        XCTAssertTrue(source.contains("Leave \\(offered.displayName) behind?"))
        XCTAssertTrue(source.contains("You cannot recover it after leaving this decision."))
        XCTAssertTrue(source.contains("Button(\"Leave \\(offered.displayName)\", role: .destructive)"))
        XCTAssertFalse(source.contains("Button(role: .destructive) {\n                    store.leaveOffered(offered)"))
    }


    /// The simplest legal rule, for tests that just need the Binder to do *something*.
    private static let attackAnything = GambitRule(id: InstanceID(rawValue: 99),
                                                   subject: "subject_foe_any",
                                                   action: "act_attack")

    private func richStore() -> GameStore {
        let store = GameStore(io: .temporary(name: "economy-\(UUID().uuidString)"))
        store.mutate("stock up for testing") { state in
            state.base.essence = 500
            state.base.resources.add(200, of: Resources.ore)
            state.base.resources.add(200, of: Resources.fiber)
            state.reality.motes = 50
        }
        return store
    }

    private func node(_ id: ResearchNodeID) throws -> ResearchNodeDef {
        try XCTUnwrap(ContentCatalog.shared.researchNode(id))
    }

    /// Complete a node and everything it depends on, so a test can start from a given point in the
    /// tree without hand-listing the path.
    private func researchThrough(_ id: ResearchNodeID, in store: GameStore) throws {
        let target = try node(id)
        for required in target.requires { try researchThrough(required, in: store) }
        XCTAssertTrue(store.research(target), "Couldn't research \(id)")
    }

    // MARK: Refining

    /// Before this existed, ore and fibre had nowhere to go and raw essence did nothing. Refining
    /// is the join between harvesting and spending.
    func testRefiningTurnsRawEssenceIntoEssence() {
        let store = GameStore(io: .temporary(name: "refine-\(UUID().uuidString)"))
        store.mutate("haul") { $0.base.resources.add(6, of: Resources.essenceRaw) }
        let before = store.state.base.essence

        store.refineAllEssence()

        XCTAssertEqual(store.state.base.resources[Resources.essenceRaw], 0)
        XCTAssertEqual(store.state.base.essence, before + 6 * Tuning.Economy.essencePerRawEssence)
    }

    func testRefiningNothingDoesNothing() {
        let store = GameStore(io: .temporary(name: "refine-none-\(UUID().uuidString)"))
        let before = store.state.base.essence
        XCTAssertFalse(store.refineEssence(rawUnits: 5), "You can't refine what you don't have")
        XCTAssertEqual(store.state.base.essence, before)
    }

    // MARK: Research

    func testPenmanshipPreviewUsesRecentAuthoredMedianAndShowsLowRunway() throws {
        var state = GameState.newGame()
        state.base.essence = 45
        state.base.resources.add(5, of: Resources.essenceRaw)
        state.reality.library.visitedWorlds = [8, 10, 12].enumerated().map { offset, paid in
            VisitedWorld(id: InstanceID(rawValue: UInt64(offset + 1)), seed: UInt64(offset + 1),
                         runIndex: offset, descriptionSentence: "", written: ["Light ← Sun"],
                         inertModifiers: [], readings: [:], travellersPresent: [],
                         bindEssencePaid: paid)
        }
        let brush = try node("pen_brush")
        let preview = EconomyRules.researchPurchasePreview(for: brush, in: state)

        let expectedNow = 45 + EconomyRules.refine(rawUnits: 5, in: state)
        XCTAssertEqual(preview.spendableEssenceNow, expectedNow)
        XCTAssertEqual(preview.spendableEssenceAfter, expectedNow - brush.cost.essence)
        XCTAssertEqual(preview.authoredBindCost, 10)
        XCTAssertEqual(preview.bindCostBasis, .recentMedian)
        XCTAssertEqual(preview.authoredBindsRemaining,
                       Double(expectedNow - brush.cost.essence) / 10)
        XCTAssertTrue(preview.isLowWritingRunway)
    }

    func testPenmanshipPreviewFallsBackToCurrentAuthoredDraftNotBlankMinimum() throws {
        var state = GameState.newGame()
        let target = PlacedRune(id: InstanceID(rawValue: 1), content: .target("illumination"),
                                hand: .crude, origin: .init(column: 0, row: 0),
                                shapeID: "crude_block")
        let source = PlacedRune(id: InstanceID(rawValue: 2), content: .source("sun"),
                                hand: .crude, origin: .init(column: 2, row: 0),
                                shapeID: "crude_block")
        state.base.page = Page(runes: [target, source], links: [MarkLink(target.id, source.id)])
        let brush = try node("pen_brush")
        let preview = EconomyRules.researchPurchasePreview(for: brush, in: state)

        XCTAssertEqual(preview.bindCostBasis, .currentAuthoredPreview)
        XCTAssertEqual(preview.authoredBindCost,
                       Double(BookRules.resolveBook(page: state.base.page).essencePaid))

        state.base.page = Page()
        let blank = EconomyRules.researchPurchasePreview(for: brush, in: state)
        XCTAssertNil(blank.authoredBindCost,
                     "the ten-Essence emergency minimum is not an ordinary authored baseline")
        XCTAssertNil(blank.authoredBindsRemaining)
    }

    func testPenmanshipQuoteHasExactShortfallAndStaleCommitLosesNothing() throws {
        let store = GameStore(io: .temporary(name: "penmanship-runway-\(UUID().uuidString)"))
        store.mutate("prepare brush") { state in
            state.base.stations[Stations.scriptorium] = StationState(isUnlocked: true, tier: 0)
            state.base.essence = 45
            state.base.resources.add(2, of: "copper")
            state.base.resources.add(5, of: Resources.fiber)
            state.base.resources.add(4, of: Resources.timber)
        }
        let brush = try node("pen_brush")
        let missing = store.researchPurchasePreview(for: brush)
        XCTAssertEqual(missing.shortfall, ["1 fibre"])

        store.mutate("finish stock") { $0.base.resources.add(1, of: Resources.fiber) }
        let quote = store.researchPurchasePreview(for: brush)
        XCTAssertTrue(quote.shortfall.isEmpty)
        store.mutate("background stock change") { $0.base.resources.spend(1, of: "copper") }
        let beforeRefusal = store.state
        XCTAssertEqual(store.research(quote, node: brush), .refused(.stalePreview))
        XCTAssertEqual(store.state, beforeRefusal)

        store.mutate("restore exact stock") { $0.base.resources.add(1, of: "copper") }
        let fresh = store.researchPurchasePreview(for: brush)
        XCTAssertEqual(store.research(fresh, node: brush), .committed)
        XCTAssertEqual(store.state.base.essence, 0)
        XCTAssertEqual(store.state.base.resources["copper"], 0)
        XCTAssertEqual(store.state.base.resources[Resources.fiber], 0)
        XCTAssertEqual(store.state.base.resources[Resources.timber], 0)
        XCTAssertTrue(store.state.base.completedResearch.contains(brush.id))
    }

    func testIsoldeBrushPurchaseNamesItsPartsAndKeepsThePreviewedNextBindRunway() throws {
        let store = GameStore(io: .temporary(name: "isolde-brush-runway-\(UUID().uuidString)"))
        let brush = try node("pen_brush")
        XCTAssertTrue(brush.blurb.localizedCaseInsensitiveContains("ferrule"))
        XCTAssertTrue(brush.blurb.localizedCaseInsensitiveContains("bristles"))
        XCTAssertTrue(brush.blurb.localizedCaseInsensitiveContains("handle"))

        store.mutate("force Isolde phase with one authored bind reserved") { state in
            state.reality.library.foundTravellers.insert("isolde")
            state.base.stations[Stations.scriptorium] = StationState(isUnlocked: true, tier: 0)
            state.base.page = Page(runes: [
                PlacedRune(id: InstanceID(rawValue: 1), content: .target("illumination"), hand: .crude,
                           origin: .init(column: 0, row: 0), shapeID: "crude_block"),
                PlacedRune(id: InstanceID(rawValue: 2), content: .source("sun"), hand: .crude,
                           origin: .init(column: 2, row: 0), shapeID: "crude_block")
            ], links: [MarkLink(InstanceID(rawValue: 1), InstanceID(rawValue: 2))])
            let nextBind = BookRules.resolveBook(page: state.base.page).essencePaid
            state.base.essence = brush.cost.essence + nextBind
            for (resource, amount) in brush.cost.resources {
                state.base.resources.add(amount, of: resource)
            }
        }

        let preview = store.researchPurchasePreview(for: brush)
        let nextBind = try XCTUnwrap(preview.authoredBindCost)
        XCTAssertGreaterThanOrEqual(Double(preview.spendableEssenceAfter), nextBind)
        XCTAssertEqual(store.research(preview, node: brush), .committed)
        XCTAssertGreaterThanOrEqual(Double(store.state.base.essence), nextBind)
    }

    func testCompoundAssemblyResearchRevalidatesExactPurchaseAndUnlocksProvider() throws {
        let store = GameStore(io: .temporary(name: "compound-research-\(UUID().uuidString)"))
        let compound = try node("pen_compounds")

        store.mutate("fund compound research") { state in
            state.base.stations[Stations.scriptorium] = StationState(isUnlocked: true, tier: 1)
            state.base.essence = compound.cost.essence
            for (resource, amount) in compound.cost.resources {
                state.base.resources.add(amount, of: resource)
            }
        }
        XCTAssertFalse(store.isAvailable(compound), "Brush remains the authored prerequisite")
        XCTAssertFalse(store.missingPrerequisites(for: compound).isEmpty)

        store.mutate("learn prerequisite") { $0.base.completedResearch.insert("pen_brush") }
        XCTAssertTrue(store.isAvailable(compound))
        XCTAssertTrue(store.canResearch(compound))
        let stale = store.researchPurchasePreview(for: compound)
        store.mutate("background resource mutation") {
            $0.base.resources.spend(1, of: Resources.pulp)
        }
        let beforeRefusal = store.state
        XCTAssertEqual(store.research(stale, node: compound), .refused(.stalePreview))
        XCTAssertEqual(store.state, beforeRefusal)
        XCTAssertFalse(store.state.base.completedResearch.contains(compound.id))

        store.mutate("restore exact stock") { $0.base.resources.add(1, of: Resources.pulp) }
        let fresh = store.researchPurchasePreview(for: compound)
        XCTAssertEqual(fresh.cost, compound.cost)
        XCTAssertEqual(store.research(fresh, node: compound), .committed)
        XCTAssertEqual(store.state.base.essence, 0)
        for resource in compound.cost.resources.keys {
            XCTAssertEqual(store.state.base.resources[resource], 0)
        }
        XCTAssertTrue(store.state.base.completedResearch.contains(compound.id))
        XCTAssertTrue(store.state.base.capabilities.contains("compoundAssembly"))
        XCTAssertNotEqual(
            store.previewCompoundFormalization(fingerprint: "not-yet-proven", nickname: "Test"),
            .refused(.locked),
            "Completed research is the provider's durable Compound Assembly capability"
        )
    }

    func testResearchingANodeSpendsBothCurrenciesAndGrantsItsEffect() throws {
        let store = richStore()
        let shelving = try node("shelving_one")
        let essenceBefore = store.state.base.essence
        let oreBefore = store.state.base.resources[Resources.ore]
        let slotsBefore = store.state.base.inventory.slots

        XCTAssertTrue(store.research(shelving))

        XCTAssertEqual(store.state.base.essence, essenceBefore - shelving.cost.essence)
        XCTAssertEqual(store.state.base.resources[Resources.ore],
                       oreBefore - (shelving.cost.resources[Resources.ore] ?? 0))
        XCTAssertTrue(store.isComplete(shelving))
        XCTAssertEqual(store.state.base.inventory.slots,
                       slotsBefore + Tuning.Economy.inventorySlotsPerStorehouseTier,
                       "Capacity has to follow the tier, not drift from it")
    }

    /// The whole point of a tree rather than a list: you can't buy the end before the beginning.
    func testANodeIsLockedUntilItsPrerequisitesAreDone() throws {
        let store = richStore()
        let deeper = try node("shelving_two")

        XCTAssertFalse(store.isAvailable(deeper))
        XCTAssertFalse(store.research(deeper))
        XCTAssertFalse(store.missingPrerequisites(for: deeper).isEmpty,
                       "The UI has to be able to say what's blocking")

        try researchThrough("shelving_one", in: store)
        XCTAssertTrue(store.isAvailable(deeper))
        XCTAssertTrue(store.research(deeper))
    }

    func testAdvancedCapacityRequiresTheMatchingTanneryCapability() throws {
        let store = richStore()
        store.mutate("build tannery and finish early capacity") { state in
            state.base.stations[Stations.tannery] = StationState(isUnlocked: true, tier: 0)
            state.base.completedResearch.formUnion([
                "shelving_one", "shelving_two", "shelving_three",
                "satchel_one", "satchel_two"
            ])
        }
        let shelving = try node("shelving_four")
        let satchel = try node("satchel_three")
        XCTAssertFalse(store.isAvailable(shelving))
        XCTAssertFalse(store.isAvailable(satchel))
        XCTAssertTrue(store.research(try node("tannery_keep_root")))
        XCTAssertTrue(store.isAvailable(shelving))
        XCTAssertTrue(store.research(try node("tannery_carry_root")))
        XCTAssertTrue(store.isAvailable(satchel))
    }

    func testLegacyPurchasedCapacityRemainsCompleteWithoutNewTanneryPrerequisite() throws {
        let store = richStore()
        store.mutate("legacy capacity") { state in
            state.base.completedResearch.insert("satchel_three")
            state.base.satchelTier = 3
        }
        let node = try node("satchel_three")
        XCTAssertTrue(store.isComplete(node))
        XCTAssertEqual(store.state.base.satchelTier, 3)
        XCTAssertFalse(store.isAvailable(node))
    }

    func testBowyerResearchRaisesStoredStationTierOncePerRung() throws {
        let store = richStore()
        store.mutate("build and stock bowyer") { state in
            state.base.stations[Stations.bowyer] = StationState(isUnlocked: true, tier: 0)
            state.base.resources.add(100, of: "timber")
            state.base.resources.add(100, of: "resin")
        }
        XCTAssertTrue(store.research(try node("bowyer_broaden")))
        XCTAssertEqual(store.state.base.station(Stations.bowyer).tier, 1)
        XCTAssertFalse(store.research(try node("bowyer_broaden")))
        XCTAssertEqual(store.state.base.station(Stations.bowyer).tier, 1)
        XCTAssertTrue(store.research(try node("bowyer_masterwork")))
        XCTAssertEqual(store.state.base.station(Stations.bowyer).tier, 2)
    }

    func testANodeIsOnlyEverResearchedOnce() throws {
        let store = richStore()
        let node = try node("reason_about_self")
        XCTAssertTrue(store.research(node))
        XCTAssertFalse(store.isAvailable(node))
        XCTAssertFalse(store.research(node))
    }

    func testCannotResearchWhatYouCannotAfford() throws {
        let store = GameStore(io: .temporary(name: "poor-\(UUID().uuidString)"))
        store.mutate("broke") { $0.base.essence = 0 }
        let shelving = try node("shelving_one")

        XCTAssertFalse(store.canResearch(shelving))
        XCTAssertFalse(store.research(shelving))
        XCTAssertFalse(store.shortfall(for: shelving).isEmpty)
        XCTAssertFalse(store.isComplete(shelving))
    }

    /// Research grants *components*, not finished rules. Learning one threshold widens everything
    /// you can already say — that's why it's a grammar and not a shop.
    func testResearchGrantsComponentsThatWidenTheGrammar() throws {
        let store = richStore()
        XCTAssertFalse(store.state.base.ownedGambitComponents.contains("thr_30"))

        try researchThrough("notice_thirty", in: store)

        XCTAssertTrue(store.state.base.ownedGambitComponents.contains("thr_30"))
        XCTAssertTrue(store.ownedComponents(.threshold).contains { $0.id == "thr_30" },
                      "The new word is immediately available to the rule builder")
    }

    func testResearchCanGrantASymbol() throws {
        let store = richStore()
        XCTAssertFalse(store.state.base.ownedSymbols.contains("verdigris_bloom"))
        try researchThrough("study_growth", in: store)
        XCTAssertTrue(store.state.base.ownedSymbols.contains("verdigris_bloom"))
    }

    func testResearchingASlotWidensTheRuleList() throws {
        let store = richStore()
        let before = store.activeGambitSlots(for: .binder)
        try researchThrough("longer_instruction", in: store)
        XCTAssertEqual(store.activeGambitSlots(for: .binder), before + 1)
    }

    /// Two sources of slots, in two layers — and only one survives a reset. That's the whole point
    /// of having both.
    func testResearchedSlotsAreLostInAResetAndConstellationSlotsAreNot() throws {
        let store = richStore()
        try researchThrough("longer_instruction", in: store)
        let node = try XCTUnwrap(ContentCatalog.shared.constellationNode(ConstellationNodes.extraGambitSlot))
        store.buy(node)
        XCTAssertEqual(store.activeGambitSlots(for: .binder), Tuning.Encounter.startingGambitSlots + 2)

        store.resetBaseKeepingReality()

        XCTAssertEqual(store.activeGambitSlots(for: .binder), Tuning.Encounter.startingGambitSlots + 1,
                       "The researched slot goes, the Constellation slot stays")
    }

    /// A reset should hand back the whole tree, not leave you owning its fruits.
    func testResettingTheBaseClearsResearch() throws {
        let store = richStore()
        try researchThrough("shelving_one", in: store)
        XCTAssertFalse(store.state.base.completedResearch.isEmpty)

        store.resetBaseKeepingReality()
        XCTAssertTrue(store.state.base.completedResearch.isEmpty)
        XCTAssertEqual(store.state.base.inventory.slots, Tuning.Economy.startingInventorySlots)
    }

    // MARK: Identifying

    func testIdentifyingACurioRevealsWhatItIs() throws {
        let store = richStore()
        let curio = try XCTUnwrap(ContentCatalog.shared.items.first { $0.kind == .curio })
        let stack = ItemStack(id: InstanceID(rawValue: 1), catalogID: curio.id, count: 1, identified: false)
        store.mutate("found something") { $0.base.inventory.add(stack) }

        let essenceBefore = store.state.base.essence
        let revealed: ItemDef
        switch store.identify(stack) {
        case .committed(let item): revealed = item
        case .refused(let message): return XCTFail(message)
        }

        XCTAssertEqual(store.state.base.essence, essenceBefore - Tuning.Economy.identifyCostEssence)
        XCTAssertEqual(revealed.id, curio.identifiesInto)
        XCTAssertTrue(store.unidentifiedStacks.isEmpty)
        XCTAssertEqual(store.state.base.inventory.stacks.first?.catalogID, curio.identifiesInto)
    }

    func testIdentifyingIsRefusedWithoutTheFee() throws {
        let store = GameStore(io: .temporary(name: "identify-poor-\(UUID().uuidString)"))
        let curio = try XCTUnwrap(ContentCatalog.shared.items.first { $0.kind == .curio })
        let stack = ItemStack(id: InstanceID(rawValue: 1), catalogID: curio.id, count: 1, identified: false)
        store.mutate("found something, spent everything") { state in
            state.base.inventory.add(stack)
            state.base.essence = 0
        }

        XCTAssertEqual(store.identify(stack), .refused("Not enough Essence to identify this item."))
        XCTAssertEqual(store.unidentifiedStacks.count, 1)
    }

    func testIdentifyingAStaleStackSnapshotIsRefusedWithoutTheFee() throws {
        let store = richStore()
        let curio = try XCTUnwrap(ContentCatalog.shared.items.first { $0.kind == .curio })
        let quoted = ItemStack(id: InstanceID(rawValue: 11), catalogID: curio.id,
                               count: 1, identified: false)
        store.mutate("found more of the same curio") { state in
            state.base.inventory.add(quoted)
            state.base.inventory.add(ItemStack(id: InstanceID(rawValue: 12), catalogID: curio.id,
                                               count: 1, identified: false))
        }
        let before = store.state

        XCTAssertEqual(
            store.identify(quoted),
            .refused("The unidentified item changed. Review the Storehouse and try again.")
        )
        XCTAssertEqual(store.state, before)
    }

    func testIdentifyingNeedsRoomForASplitStackBeforeCharging() throws {
        let store = richStore()
        let curio = try XCTUnwrap(ContentCatalog.shared.items.first { $0.kind == .curio })
        let stack = ItemStack(id: InstanceID(rawValue: 13), catalogID: curio.id,
                              count: 2, identified: false)
        store.mutate("full unidentified bin") { state in
            state.base.inventory = Inventory(slots: 1, stacks: [stack])
        }
        let before = store.state

        XCTAssertEqual(
            store.identify(stack),
            .refused("The Storehouse needs room for the identified item.")
        )
        XCTAssertEqual(store.state, before)
    }

    // MARK: The delayed payoff

    /// The moment the whole itemization spine exists for: a key found in one world, carried home,
    /// identified, and spent on a lock standing in a different world entirely.
    func testAKeyFromOneWorldOpensACacheInAnother() throws {
        let store = richStore()

        // World A: a curio drops. Identify it at home — and it's a key.
        let knot = try XCTUnwrap(ContentCatalog.shared.items.first {
            $0.kind == .curio && ContentCatalog.shared.item($0.identifiesInto ?? "")?.kind == .key
        })
        let stack = ItemStack(id: InstanceID(rawValue: 7), catalogID: knot.id, count: 1, identified: false)
        store.mutate("hauled home from world A") { $0.base.inventory.add(stack) }
        let key: ItemDef
        switch store.identify(stack) {
        case .committed(let item): key = item
        case .refused(let message): return XCTFail(message)
        }
        XCTAssertEqual(key.kind, .key)

        // World B: stand on a cache.
        store.write("plains")
        store.bindAndDepart()
        store.mutate("stand on a cache") { state in
            guard var run = state.worlds.activeRun else { return }
            run.map[run.playerPosition].content = .lockedCache
            state.worlds.activeRun = run
        }

        XCTAssertTrue(store.isOnLockedCache)
        XCTAssertNotNil(store.carriedCacheKey, "The key came from a different world entirely")

        let symbolsBefore = store.state.base.ownedSymbols.count
        let sourcesBefore = store.state.base.ownedSources.count
        let componentsBefore = store.state.base.ownedGambitComponents.count
        let motesBefore = store.state.reality.motes
        let reward = try XCTUnwrap(store.openCacheHere())

        XCTAssertNil(store.carriedCacheKey, "The key is spent")
        XCTAssertFalse(store.isOnLockedCache, "The cache is opened, not reopenable")

        // Guaranteed Rare+: a word, a symbol, a new rule, or motes. Never nothing.
        switch reward {
        case .focus: XCTAssertEqual(store.state.base.ownedSources.count, sourcesBefore + 1)
        case .symbol: XCTAssertEqual(store.state.base.ownedSymbols.count, symbolsBefore + 1)
        case .gambitComponent: XCTAssertEqual(store.state.base.ownedGambitComponents.count, componentsBefore + 1)
        case .motes(let amount):
            XCTAssertGreaterThan(amount, 0)
            XCTAssertEqual(store.state.reality.motes, motesBefore + amount)
        }
    }

    func testACacheWithoutAKeyStaysShut() throws {
        let store = richStore()
        store.write("plains")
        store.bindAndDepart()
        store.mutate("stand on a cache") { state in
            guard var run = state.worlds.activeRun else { return }
            run.map[run.playerPosition].content = .lockedCache
            state.worlds.activeRun = run
        }

        XCTAssertNil(store.carriedCacheKey)
        XCTAssertNil(store.openCacheHere())
        XCTAssertTrue(store.isOnLockedCache, "It's still there, still shut")
    }

    /// A cache is never a dud — it falls back to motes when there's nothing new left to give.
    func testACacheAlwaysPaysSomething() {
        var state = GameState.newGame()
        state.base.ownedSymbols = Set(ContentCatalog.shared.symbols.map(\.id))
        state.base.ownedSources = Set(ContentCatalog.shared.pressureSources.map(\.id))
        state.base.ownedGambitComponents = Set(ContentCatalog.shared.gambitComponents.map(\.id))
        var rng = SeededRNG(seed: 4242)

        for _ in 0..<20 {
            let reward = EconomyRules.rollCacheReward(in: state, rng: &rng)
            guard case .motes(let amount) = reward else {
                return XCTFail("With everything owned, the only thing left to give is motes")
            }
            XCTAssertGreaterThan(amount, 0)
        }
    }

    // MARK: The satchel decision

    func testGambitWriteActionPrecedesThePotentiallyLongPriorityList() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(
            contentsOf: root.appending(path: "Sources/Screens/GambitEditorView.swift"),
            encoding: .utf8
        )

        let action = try XCTUnwrap(source.range(of: "GambitEditorPresentation.addRuleLabel"))
        let priorityList = try XCTUnwrap(source.range(of: "List {"))
        XCTAssertLessThan(action.lowerBound, priorityList.lowerBound)
        XCTAssertEqual(source.components(separatedBy: "GambitEditorPresentation.addRuleLabel").count - 1, 1)
        XCTAssertTrue(source.contains("if !store.canEditGambits"))
        XCTAssertTrue(source.contains("Rules can be changed at Home between expeditions."))
        XCTAssertTrue(source.contains("if store.addBlankGambit(for: owner)"))
        XCTAssertTrue(source.contains("Rule not written"))
        XCTAssertTrue(source.contains("No owned subject and action are available for a new rule."))
    }

    func testRuleBuilderReportsAStaleWriteFailure() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(
            contentsOf: root.appending(path: "Sources/Screens/RuleBuilderView.swift"),
            encoding: .utf8
        )

        XCTAssertTrue(source.contains("if store.addGambit(preview, for: owner)"))
        XCTAssertTrue(source.contains("Rule not added"))
        XCTAssertTrue(source.contains("Rule writing or one of the selected parts is no longer available."))
        XCTAssertTrue(source.contains("addFailure = nil\n                            dismiss()"))
    }

    func testGambitSwipeDeletionConfirmsStableRuleIdentityBeforeMutation() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(
            contentsOf: root.appending(path: "Sources/Screens/GambitEditorView.swift"),
            encoding: .utf8
        )

        XCTAssertTrue(source.contains("pendingDeletionID = rule.id"))
        XCTAssertTrue(source.contains("firstIndex(where: { $0.id == pendingDeletionID })"))
        XCTAssertTrue(source.contains("Button(\"Cancel\", role: .cancel)"))
        XCTAssertTrue(source.contains("Button(\"Delete rule\", role: .destructive)"))
        XCTAssertTrue(source.contains("pendingDeletion?.rule.displayText"))
        XCTAssertEqual(source.components(separatedBy: "store.removeGambit(at:").count - 1, 1,
                       "a rule should be removed only by the confirmed stable-ID path")
        XCTAssertTrue(source.contains("Button(\"Any — no condition\")"))
        XCTAssertFalse(source.contains("Button(\"Any — no condition\", role: .destructive)"),
                       "a valid optional-condition choice should not be styled as destructive")
    }

    func testLootSwapKeepsTheExactDecisionActionOutsideScrollableItemFacts() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let source = try String(
            contentsOf: root.appending(path: "Sources/Screens/LootDecisionView.swift"),
            encoding: .utf8
        )

        XCTAssertTrue(source.contains(".safeAreaInset(edge: .bottom)"))
        XCTAssertTrue(source.contains("Drop this and take \\(offered.displayName)"))
        XCTAssertTrue(source.contains("swapSummary(carried, role: \"Drop\", location: .carried)"))
        XCTAssertTrue(source.contains("swapSummary(offered, role: \"Take\", location: .offered)"))
        XCTAssertTrue(source.contains("Image(systemName: \"arrow.right\")"))
        XCTAssertTrue(source.contains(".frame(maxWidth: .infinity, minHeight: 44)"))
        XCTAssertTrue(source.contains("case .refused(let message):\n                        refusal = message"))
    }

    func testLootSwapShowsKnownFactsForBothSidesOfTheDecision() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let source = try String(
            contentsOf: root.appending(path: "Sources/Screens/LootDecisionView.swift"),
            encoding: .utf8
        )

        XCTAssertTrue(source.contains("Section(\"Known facts\")"))
        XCTAssertTrue(source.contains("knownFacts(carried, role: \"Drop\", location: .carried)"))
        XCTAssertTrue(source.contains("knownFacts(offered, role: \"Take\", location: .offered)"))
        XCTAssertTrue(source.contains("Text(\"\\(location.displayName) · \\(stack.count)\")"))
        XCTAssertTrue(source.contains("ContentCatalog.shared.item(stack.catalogID)?.blurb"))
        XCTAssertFalse(source.contains("LabeledContent(\"Quantity\", value: \"\\(carried.count)\")"),
                       "The facts panel must not describe only the item being dropped.")
    }

    /// A full satchel must hand the player a choice, not make one for them. Silently dropping the
    /// loot, or silently discarding what you were carrying, both empty out the reason the satchel is
    /// smaller than home storage in the first place.
    func testLootThatDoesNotFitBecomesADecision() throws {
        let store = richStore()
        store.write("plains")
        store.bindAndDepart()

        let curio = try XCTUnwrap(ContentCatalog.shared.items.first { $0.kind == .curio })
        store.mutate("fill the satchel and offer one more") { state in
            guard var run = state.worlds.activeRun else { return }
            run.satchelItems = Inventory(slots: 1, stacks: [
                ItemStack(id: InstanceID(rawValue: 1), catalogID: curio.id, count: 1, identified: false)
            ])
            run.offeredItems = [ItemStack(id: InstanceID(rawValue: 2), catalogID: curio.id,
                                          count: 1, identified: false)]
            state.worlds.activeRun = run
        }

        XCTAssertEqual(store.pendingLoot.count, 1, "The decision is pending, not resolved")

        let offered = try XCTUnwrap(store.pendingLoot.first)
        let carried = try XCTUnwrap(store.state.worlds.activeRun?.satchelItems.stacks.first)
        guard case .allowed(let quote) = store.lootSwapQuote(offered: offered, dropping: carried) else {
            return XCTFail("A valid exact swap did not quote")
        }
        XCTAssertEqual(store.takeOffered(quote), .committed)

        let run = try XCTUnwrap(store.state.worlds.activeRun)
        XCTAssertTrue(run.offeredItems.isEmpty)
        XCTAssertEqual(run.satchelItems.stacks.map(\.id), [offered.id], "You swapped, not stacked")
    }

    func testStaleLootSwapQuoteRefusesWithoutDeletingEitherItem() throws {
        let store = richStore()
        store.write("plains")
        store.bindAndDepart()
        let curio = try XCTUnwrap(ContentCatalog.shared.items.first { $0.kind == .curio })
        let carried = ItemStack(id: InstanceID(rawValue: 11), catalogID: curio.id)
        let offered = ItemStack(id: InstanceID(rawValue: 12), catalogID: curio.id)
        store.mutate("prepare quoted swap") { state in
            state.worlds.activeRun?.satchelItems = Inventory(slots: 1, stacks: [carried])
            state.worlds.activeRun?.offeredItems = [offered]
        }
        guard case .allowed(let quote) = store.lootSwapQuote(offered: offered, dropping: carried) else {
            return XCTFail("The initial swap did not quote")
        }
        store.mutate("change carried stack behind sheet") { state in
            state.worlds.activeRun?.satchelItems.stacks[0].count = 2
        }

        guard case .refused = store.takeOffered(quote) else {
            return XCTFail("A stale exact quote committed")
        }
        XCTAssertEqual(store.pendingLoot, [offered])
        XCTAssertEqual(store.state.worlds.activeRun?.satchelItems.stacks.first?.count, 2)
    }

    func testLootSwapQuoteRefusesWhenRemovalWouldStillLeaveNoCapacity() throws {
        let store = richStore()
        store.write("plains")
        store.bindAndDepart()
        let curio = try XCTUnwrap(ContentCatalog.shared.items.first { $0.kind == .curio })
        let carried = ItemStack(id: InstanceID(rawValue: 21), catalogID: curio.id)
        let offered = ItemStack(id: InstanceID(rawValue: 22), catalogID: curio.id)
        store.mutate("prepare impossible zero-slot swap") { state in
            state.worlds.activeRun?.satchelItems = Inventory(slots: 0, stacks: [carried])
            state.worlds.activeRun?.offeredItems = [offered]
        }

        guard case .refused = store.lootSwapQuote(offered: offered, dropping: carried) else {
            return XCTFail("A swap whose add would fail was quoted as allowed")
        }
        XCTAssertEqual(store.pendingLoot, [offered])
        XCTAssertEqual(store.state.worlds.activeRun?.satchelItems.stacks, [carried])
    }

    func testCapacityMutationAfterLootQuoteRefusesWithNoLoss() throws {
        let store = richStore()
        store.write("plains")
        store.bindAndDepart()
        let curio = try XCTUnwrap(ContentCatalog.shared.items.first { $0.kind == .curio })
        let carried = ItemStack(id: InstanceID(rawValue: 31), catalogID: curio.id)
        let offered = ItemStack(id: InstanceID(rawValue: 32), catalogID: curio.id)
        store.mutate("prepare capacity quote") { state in
            state.worlds.activeRun?.satchelItems = Inventory(slots: 1, stacks: [carried])
            state.worlds.activeRun?.offeredItems = [offered]
        }
        guard case .allowed(let quote) = store.lootSwapQuote(offered: offered, dropping: carried) else {
            return XCTFail("The initial capacity-safe swap did not quote")
        }
        store.mutate("remove capacity behind open detail") { state in
            state.worlds.activeRun?.satchelItems.slots = 0
        }

        guard case .refused = store.takeOffered(quote) else {
            return XCTFail("A quote committed after its add capacity disappeared")
        }
        let run = try XCTUnwrap(store.state.worlds.activeRun)
        XCTAssertEqual(run.offeredItems, [offered], "refusal must preserve offered loot")
        XCTAssertEqual(run.satchelItems.stacks, [carried], "refusal must preserve carried loot")
        XCTAssertEqual(run.offeredItems.count + run.satchelItems.stacks.count, 2,
                       "a failed atomic swap must neither lose nor duplicate an item")
    }

    func testLootCanBeLeftBehind() throws {
        let store = richStore()
        store.write("plains")
        store.bindAndDepart()
        let curio = try XCTUnwrap(ContentCatalog.shared.items.first { $0.kind == .curio })
        store.mutate("offer something") { state in
            state.worlds.activeRun?.offeredItems = [
                ItemStack(id: InstanceID(rawValue: 3), catalogID: curio.id, count: 1, identified: false)
            ]
        }

        store.leaveOffered(try XCTUnwrap(store.pendingLoot.first))
        XCTAssertTrue(store.pendingLoot.isEmpty)
        XCTAssertTrue(store.state.worlds.activeRun?.satchelItems.stacks.isEmpty ?? false)
    }

    /// A decision you're in the middle of has to survive a force-quit like anything else.
    func testAPendingLootDecisionSurvivesRelaunch() throws {
        let io = SaveFileIO.temporary(name: "offer-\(UUID().uuidString)")
        defer { io.deleteEverything() }

        let first = GameStore(io: io)
        first.write("plains")
        first.bindAndDepart()
        let curio = try XCTUnwrap(ContentCatalog.shared.items.first { $0.kind == .curio })
        first.mutate("offer something", flush: true) { state in
            state.worlds.activeRun?.offeredItems = [
                ItemStack(id: InstanceID(rawValue: 4), catalogID: curio.id, count: 1, identified: false)
            ]
        }

        let second = GameStore(io: io)
        XCTAssertEqual(second.pendingLoot.count, 1, "The choice is still open on relaunch")
    }

    // MARK: Never stranded

    /// The failstate Aimee hit on device: essence only enters the game by coming home from a
    /// world, so spending your last on a book and returning empty-handed left you at the desk with
    /// nothing to write and no way to earn any. The game was simply over, silently.
    func testTheBaseNeverStrandsYou() {
        let store = GameStore(io: .temporary(name: "stranded-\(UUID().uuidString)"))
        store.mutate("spend everything") { state in
            state.base.essence = 0
            state.base.resources = ResourcePool()
        }

        store.ensureDepartureIsPossible()

        XCTAssertTrue(store.canBindAndDepart, "There must always be a way back out into a world")
        XCTAssertGreaterThanOrEqual(store.state.base.essence,
                                    EconomyRules.minimumBindCost(in: store.state))
    }

    /// Raw essence you could still refine counts — the Spring shouldn't hand out charity to
    /// somebody who simply hasn't walked to the Workshop yet.
    func testTheSpringDoesNotPayForWhatYouAlreadyHave() {
        let store = GameStore(io: .temporary(name: "hasraw-\(UUID().uuidString)"))
        store.mutate("plenty of raw, no refined") { state in
            state.base.essence = 0
            state.base.resources = ResourcePool()
            state.base.resources.add(50, of: Resources.essenceRaw)
        }

        store.ensureDepartureIsPossible()

        XCTAssertEqual(store.state.base.essence, 0, "You can refine your way out of this yourself")
        XCTAssertTrue(store.needsToRefine, "…and the game has to say so")
    }

    /// A stranded save left by an earlier build recovers itself rather than needing a wipe.
    func testAStrandedSaveRecoversOnLaunch() throws {
        let io = SaveFileIO.temporary(name: "recover-\(UUID().uuidString)")
        defer { io.deleteEverything() }

        let first = GameStore(io: io)
        first.mutate("strand it", flush: true) { state in
            state.base.essence = 0
            state.base.resources = ResourcePool()
        }

        let second = GameStore(io: io)
        XCTAssertTrue(second.canBindAndDepart, "Reopening the app has to get you unstuck")
    }

    /// Coming home broke still leaves you able to leave again.
    func testReturningWithNothingStillLetsYouDepartAgain() {
        let store = GameStore(io: .temporary(name: "broke-return-\(UUID().uuidString)"))
        store.write("plains")
        store.bindAndDepart()
        store.mutate("spend it all while away") { $0.base.essence = 0 }

        store.portalHome()

        // The guarantee is that *something* is always writable, not that your current draft is.
        // A fancier book than you can afford is a legible problem with a stated fix; nothing at
        // all to write is a dead end.
        store.clearPage()
        XCTAssertTrue(store.canBindAndDepart, "There must always be a cheapest book you can write")
    }

    // MARK: Constellation

    func testBuyingAConstellationNodeSpendsMotesAndSticks() throws {
        let store = richStore()
        let node = try XCTUnwrap(ContentCatalog.shared.constellationNodes.first)
        let cost = try XCTUnwrap(store.moteCost(of: node))
        let before = store.state.reality.motes

        XCTAssertTrue(store.buy(node))
        XCTAssertEqual(store.state.reality.motes, before - cost)
        XCTAssertEqual(store.state.reality.rank(of: node.id), 1)

        store.resetBaseKeepingReality()
        XCTAssertEqual(store.state.reality.rank(of: node.id), 1, "The Reality layer never gives it back")
    }

    func testConstellationNodesCannotBeBoughtPastTheirMaxRank() throws {
        let store = richStore()
        let node = try XCTUnwrap(ContentCatalog.shared.constellationNodes.first)
        for _ in 0..<(node.maxRank + 2) { store.buy(node) }
        XCTAssertEqual(store.state.reality.rank(of: node.id), node.maxRank)
        XCTAssertNil(store.moteCost(of: node))
    }

    // MARK: Automate self

    /// The unlock has to actually do something: your own rules, followed without you.
    func testAutomateSelfHandsTheBinderOverToItsOwnRules() throws {
        let store = richStore()
        try researchThrough("automate_self", in: store)
        XCTAssertTrue(store.state.base.hasAutomateSelfUnlock)

        store.mutate("write your own hand") { $0.base.binderGambits = [Self.attackAnything] }
        store.write("plains")
        store.bindAndDepart()
        store.mutate("stage a fight") { state in
            guard var run = state.worlds.activeRun else { return }
            run.enemies = [WorldEnemy(id: InstanceID(rawValue: 1), creatureID: "ink_hound",
                                      position: run.playerPosition, isAwake: true)]
            state.worlds.activeRun = run
            WorldRules.beginEncounter(triggeredBy: run.enemies[0], in: &state)
        }

        // The fight now opens on its own — automatic turns start with the encounter rather than
        // waiting for a tap — so the proof is that the Binder acted without being asked.
        let encounter = try XCTUnwrap(store.activeEncounter)
        XCTAssertTrue(encounter.log.contains { $0.hasPrefix("You:") },
                      "The Binder now has rules of its own to follow, and nobody tapped anything")
        XCTAssertFalse(CombatRules.needsPlayerInput(store.state),
                       "…and the fight no longer waits on you")
    }

    func testWithoutTheUnlockTheBinderIsAlwaysManual() throws {
        let store = richStore()
        store.mutate("rules written but not unlocked") { $0.base.binderGambits = [Self.attackAnything] }
        store.write("plains")
        store.bindAndDepart()
        store.mutate("stage a fight") { state in
            guard var run = state.worlds.activeRun else { return }
            run.enemies = [WorldEnemy(id: InstanceID(rawValue: 1), creatureID: "ink_hound",
                                      position: run.playerPosition, isAwake: true)]
            state.worlds.activeRun = run
            WorldRules.beginEncounter(triggeredBy: run.enemies[0], in: &state)
        }

        XCTAssertNil(GambitEngine.decide(for: .binder, in: store.state))
        XCTAssertTrue(CombatRules.needsPlayerInput(store.state), "Automating yourself is earned")
    }

    /// **Nothing may grant a value nothing reads** (`fossil-audit.md` §6).
    ///
    /// The Fifth Mark sold *"+1 symbol slot in every book you bind"* for three motes. Books stopped
    /// having symbol slots when the page grid replaced them — and `bonusBookSlots` was never read
    /// by anything even before that. It was dead on arrival and survived the system it belonged to.
    ///
    /// This is the cheap guard the audit asked for: a Constellation node whose effect nothing
    /// consumes is a fossil by definition, and the research tree already has the equivalent check.
    func testEveryConstellationNodeActuallyDoesSomething() throws {
        let sources = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()      // Tests/
            .deletingLastPathComponent()      // repo root
            .appendingPathComponent("Sources")
        var code = ""
        if let walker = FileManager.default.enumerator(at: sources,
                                                       includingPropertiesForKeys: nil) {
            for case let file as URL in walker where file.pathExtension == "swift" {
                code += (try? String(contentsOf: file, encoding: .utf8)) ?? ""
            }
        }
        XCTAssertFalse(code.isEmpty, "couldn't read the source to check against")

        // **The check is on what a node grants, not on the node.** Every node is mentioned
        // somewhere — its own constant, the catalogue, the screen that draws it. What tells you
        // it's a fossil is that the *value* it produces is read by nobody.
        //
        // `RealityState` exposes one accessor per purchasable effect; each has to be consumed
        // outside the file that declares it, or the purchase buys nothing.
        let realityFile = sources.appendingPathComponent("Model/RealityState.swift")
        let reality = (try? String(contentsOf: realityFile, encoding: .utf8)) ?? ""
        let accessors = reality
            .components(separatedBy: "\n")
            .filter { $0.contains("rank(of: ConstellationNodes") }
            .compactMap { line -> String? in
                guard let name = line.components(separatedBy: "var ").last?
                    .components(separatedBy: ":").first else { return nil }
                return name.trimmingCharacters(in: .whitespaces)
            }
        XCTAssertFalse(accessors.isEmpty, "no constellation effects found to check")

        let elsewhere = code.replacingOccurrences(of: reality, with: "")
        for accessor in accessors {
            XCTAssertTrue(elsewhere.contains(accessor),
                          "\(accessor) is bought with motes and read by nothing — a fossil")
        }
    }

    // MARK: Every progression axis has a door

    /// **The fault `clause-audit.md` F2 found**, expressed so it can't come back: all five analysis
    /// tiers were implemented, tiers 3 and 4 did real work, and `analysisTier` was written by a save
    /// decoder and the debug harness and by nothing a player could reach. Finished work nobody could
    /// see.
    @MainActor
    func testAnalysisCanActuallyBeRaisedInPlay() throws {
        let store = GameStore(io: .temporary(name: "analysis-\(UUID().uuidString)"))
        XCTAssertEqual(store.state.reality.analysisTier, Tuning.Analysis.startingTier)

        let instruments = ContentCatalog.shared.researchNodes.filter {
            $0.grants.contains { $0.effect == .analysisTier }
        }
        XCTAssertFalse(instruments.isEmpty, "nothing in the game raises how well you can read a world")

        var state = store.state
        for node in instruments { EconomyRules.apply(node.grants[0], in: &state) }
        XCTAssertEqual(state.reality.analysisTier, Tuning.Analysis.livingTier,
                       "the instruments don't reach the top tier, so two of them are still unreachable")
    }

    /// And the tiers that do the most work have to be among the ones you can get to.
    @MainActor
    func testTheTiersThatDoWorkAreReachable() {
        let reachable = ContentCatalog.shared.researchNodes
            .filter { $0.grants.contains { $0.effect == .analysisTier } }.count
            + Tuning.Analysis.startingTier
        XCTAssertGreaterThanOrEqual(reachable, Tuning.Analysis.attributionTier,
                                    "the red/green attribution tier is still finished work nobody can see")
    }

    /// **Knowledge is never taken back.** Analysis lives in Reality, like visited seeds and the
    /// Library, so a future base reset can't cost you an instrument you ground yourself.
    @MainActor
    func testAnInstrumentSurvivesABaseReset() {
        let store = GameStore(io: .temporary(name: "analysis-reset-\(UUID().uuidString)"))
        store.mutate("test: an instrument") { $0.reality.analysisTier = Tuning.Analysis.attributionTier }
        store.resetBaseKeepingReality()
        XCTAssertEqual(store.state.reality.analysisTier, Tuning.Analysis.attributionTier,
                       "a base reset took back something that was learned")
    }
}
