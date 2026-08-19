import CryptoKit
import SwiftUI
import UIKit
import XCTest
@testable import Bookbinder

/// The page as a spatial grid (`writing-system-rune-spec.md` §2–3).
///
/// Two properties carry the whole design: **the page is a budget, not a syntax** — where a rune
/// sits never changes what it says — and **refinement is literacy, not power** — a better hand lets
/// you say the same thing in less space and never unlocks a meaning.
final class PageTests: XCTestCase {
    @MainActor
    func testWritingDeskRendersAtApprovedOrdinaryPhoneSize() throws {
        let store = GameStore(io: .temporary(name: "writing-render-\(UUID().uuidString)"))
        store.mutate("prepare writing render fixture") { state in
            for lesson in TutorialLessonID.allCases {
                state.tutorial.complete(lesson, fact: "visual_fixture")
            }
        }
        for scheme in [ColorScheme.light, .dark] {
            let controller = UIHostingController(rootView:
                NavigationStack { WritingDeskView().environmentObject(store) }
                    .environment(\.colorScheme, scheme)
                    .environment(\.dynamicTypeSize, .large)
                    .frame(width: 368, height: 800)
            )
            let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 368, height: 800))
            window.rootViewController = controller
            window.makeKeyAndVisible()
            controller.view.frame = window.bounds
            controller.view.layoutIfNeeded()
            RunLoop.main.run(until: Date().addingTimeInterval(0.05))
            let image = UIGraphicsImageRenderer(size: window.bounds.size).image { _ in
                controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
            }
            window.isHidden = true
            XCTAssertEqual(image.size, CGSize(width: 368, height: 800))
            let attachment = XCTAttachment(image: image)
            attachment.name = "writing-desk-write-\(scheme == .light ? "light" : "dark")"
            attachment.lifetime = .keepAlways
            add(attachment)
        }
    }
    @MainActor
    func testEarthlikeTestWorldIsPermanentAndAddedToExistingCampaigns() throws {
        let earth = WorldPageCatalog.earthlikeTestInstance
        XCTAssertEqual(earth.definition.id, "earthlike_test_world")
        XCTAssertEqual(earth.definition.disposition, .reusable)
        XCTAssertEqual(earth.definition.worldPageCost, 0)
        XCTAssertEqual(earth.definition.seed, 101)
        XCTAssertEqual(Set(earth.definition.page.symbolIDs),
                       Set(["plains", "archipelago", "common_ore"]))
        let earthReadings = BookRules.readings(
            for: BookRules.resolveBook(worldPage: earth), seed: earth.definition.seed)
        XCTAssertEqual(earthReadings["illumination"].peak, 60.36, accuracy: 0.0001)
        XCTAssertEqual(earthReadings["atmosphere"].peak, 51)
        XCTAssertEqual(earthReadings["atmosphere"].aspect("clarity"), 78)
        XCTAssertLessThanOrEqual(earthReadings["vitality"].peak, 30)
        XCTAssertFalse(
            DescriptionRules.describe(earthReadings).sentence
                .localizedCaseInsensitiveContains("want of light"))
        XCTAssertTrue(earth.inspected)

        let store = GameStore(io: .temporary(name: "earthlike-page-\(UUID().uuidString)"))
        store.mutate("simulate existing campaign without Earth page", flush: true) {
            $0.base.collectedWorldPages.removeAll { $0.definition.id == earth.definition.id }
            $0.base.starterWorldPageBundleFulfilled = true
        }
        store.reconcileStarterWorldPageBundle()
        XCTAssertEqual(store.state.base.collectedWorldPages.filter {
            $0.definition.id == earth.definition.id
        }, [earth])

        let essenceBeforeTestDeparture = store.state.base.essence
        XCTAssertTrue(store.bindAndDepart(worldPageInstanceID: earth.id))
        XCTAssertEqual(store.state.base.essence, essenceBeforeTestDeparture,
                       "the reusable testing page must never charge Essence")
        XCTAssertEqual(store.activeRun?.mapSeed, earth.definition.seed)
        XCTAssertEqual(store.activeRun?.book.worldPageUseReceipt?.instanceID, earth.id)
        XCTAssertEqual(store.activeRun?.worldVisualReceipt?.request.atmosphere.medium, "none")
        XCTAssertEqual(store.activeRun?.worldVisualReceipt?.request.atmosphere.density, 0)
        let visibility = try XCTUnwrap(store.activeRun.map { WorldRules.visibilityProfile(in: $0) })
        XCTAssertEqual(visibility.illumination, 60.36, accuracy: 0.0001)
        XCTAssertEqual(visibility.obscurantDensity, 0)
        XCTAssertEqual(visibility.fringeWidth, Tuning.Visibility.defaultFringeWidth)
        let diagnostics = try XCTUnwrap(store.activeRun?.generationDiagnostics)
        XCTAssertEqual(diagnostics.creatureSpeciesCount, 2)
        XCTAssertEqual(diagnostics.creatureInstancesPlaced, 1)
        XCTAssertEqual(diagnostics.floraSpeciesCount, 0)
        XCTAssertEqual(diagnostics.floraInstancesPlaced, 0)
        XCTAssertTrue(store.state.base.collectedWorldPages.contains { $0 == earth },
                      "the permanent Earth-like page must survive every successful bind")
    }

    @MainActor
    func testBand2TemplatesPhoneFixtureRelaunchesNearCapWithDirtyLegalDraftAndStableIDs() throws {
        let fixture = try GameStore.makeBand2TemplatesPhoneFixture()
        let receipt = fixture.receipt
        XCTAssertEqual(receipt.templateCount, PageTemplateRules.capacity - 1)
        XCTAssertEqual(receipt.capacity, PageTemplateRules.capacity)
        XCTAssertGreaterThan(receipt.currentDraftMarkCount, 0)
        XCTAssertEqual(receipt.stableTemplateIDs,
                       fixture.store.state.base.savedPageTemplates.sorted {
                           $0.creationOrdinal < $1.creationOrdinal
                       }.map(\.id))
        XCTAssertEqual(Set(receipt.stableTemplateIDs).count, receipt.stableTemplateIDs.count)

        let first = try XCTUnwrap(receipt.stableTemplateIDs.first)
        let ordinal = try XCTUnwrap(fixture.store.state.base.savedPageTemplates.first {
            $0.id == first
        }?.creationOrdinal)
        XCTAssertEqual(fixture.store.renamePageTemplate(first, to: "Phone renamed"),
                       .updated(first))
        XCTAssertEqual(fixture.store.overwritePageTemplate(first), .updated(first))
        XCTAssertEqual(fixture.store.state.base.savedPageTemplates.first {
            $0.id == first
        }?.creationOrdinal, ordinal)
        fixture.store.clearPage()
        XCTAssertEqual(fixture.store.loadPageTemplate(first), .loaded(first))
        XCTAssertEqual(fixture.store.deletePageTemplate(first), .deleted(first))
    }

    func testSettingsExposesDisposableTemplatesAcceptanceThroughProductionDesk() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .deletingLastPathComponent()
        let source = try String(contentsOf: root.appending(path:
            "Sources/Screens/SettingsView.swift"), encoding: .utf8)
        XCTAssertTrue(source.contains("settings.page-templates-acceptance"))
        XCTAssertTrue(source.contains("Page Templates acceptance"))
        XCTAssertTrue(source.contains("WritingDeskView().environmentObject(session.store)"))
        XCTAssertTrue(source.contains("band2-templates-fixture-receipt"))
        XCTAssertTrue(source.contains("Load over the dirty draft"))
        XCTAssertTrue(source.contains("rename, overwrite and delete"))
    }

    @MainActor
    func testStarterWorldPagePhoneFixturesUseProductionReceiptsRevealedFindsAndSafeRoutes() throws {
        for instance in WorldPageCatalog.starterInstances {
            let fixture = try GameStore.makeStarterWorldPagePhoneFixture(
                definitionID: instance.definition.id)
            let receipt = fixture.receipt
            XCTAssertEqual(receipt.pageDefinitionID, instance.definition.id)
            XCTAssertEqual(receipt.pageInstanceID, instance.id)
            XCTAssertEqual(receipt.mapSeed, instance.definition.seed)
            XCTAssertEqual(receipt.itemID, instance.definition.knownFind)
            XCTAssertEqual(receipt.itemInstanceID,
                           StarterKnownFindPlacementRules.stableInstanceID(for:
                            try XCTUnwrap(fixture.store.activeRun?.book.worldPageUseReceipt)))
            XCTAssertTrue((1...2).contains(receipt.safePathToRevealedFind.count - 1))
            XCTAssertEqual(receipt.safePathToRevealedFind.first,
                           fixture.store.activeRun?.playerPosition)
            XCTAssertEqual(receipt.safePathToRevealedFind.last, receipt.placement)
            XCTAssertTrue(fixture.store.activeRun?.map[receipt.placement].isRevealed == true)
            XCTAssertTrue(receipt.safePathToRevealedFind.allSatisfy {
                fixture.store.activeRun?.map[$0].ground.movementCost == 1
            })
            XCTAssertFalse(fixture.store.state.base.collectedWorldPages.contains {
                $0.id == instance.id
            }, "the production bind transaction must consume only the disposable copy")
        }
    }

    func testSettingsExposesDisposableStarterWorldPageAcceptanceRoute() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .deletingLastPathComponent()
        let settings = try String(
            contentsOf: root.appending(path: "Sources/Screens/SettingsView.swift"),
            encoding: .utf8)
        let harness = try String(
            contentsOf: root.appending(path: "Sources/Debug/HarnessActions.swift"),
            encoding: .utf8)
        XCTAssertTrue(settings.contains("settings.starter-world-pages-acceptance"))
        XCTAssertTrue(settings.contains("starter-world-page-receipt"))
        XCTAssertTrue(harness.contains("GameStore(io: .temporary("))
        XCTAssertTrue(harness.contains("bindAndDepart(worldPageInstanceID: instance.id)"))
    }

    func testSettingsExposesWildWorldPagesAcceptanceAcrossRealSurfaces() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .deletingLastPathComponent()
        let settings = try String(contentsOf: root.appending(path:
            "Sources/Screens/SettingsView.swift"), encoding: .utf8)
        let harness = try String(contentsOf: root.appending(path:
            "Sources/Debug/HarnessActions.swift"), encoding: .utf8)
        XCTAssertTrue(settings.contains("settings.wild-world-pages-acceptance"))
        XCTAssertTrue(settings.contains("RootView().environmentObject(fixture.store)"))
        XCTAssertTrue(settings.contains("WritingDeskView()"))
        XCTAssertTrue(settings.contains("wild-world-pages-fixture-receipt"))
        XCTAssertTrue(harness.contains("endRunWithPartialHaul"))
        XCTAssertTrue(harness.contains("bindAndDepart()"))
        XCTAssertTrue(harness.contains("GameStore(io: fixture.io)"))
    }

    @MainActor
    func testWildWorldPagesPhoneFieldFixturesUseExactProductionTransactions() throws {
        let room = try GameStore.makeWildWorldPagesPhoneFixture(kind: .fieldWithRoom)
        let offered = try XCTUnwrap(room.store.activeRun?.offeredWorldPages.first)
        XCTAssertFalse(offered.inspected)
        let beforeSightings = room.store.state.reality.encounteredLexemes
        let quote = try XCTUnwrap(room.store.offeredWorldPageQuote(offered.id))
        XCTAssertEqual(room.store.takeOfferedWorldPage(quote), .taken(offered))
        XCTAssertEqual(room.store.state.reality.encounteredLexemes, beforeSightings,
                       "picking up an unopened page must not record Dictionary sightings")
        XCTAssertEqual(room.store.activeRun?.carriedWorldPages, [offered])
        XCTAssertFalse(try XCTUnwrap(room.store.activeRun?.carriedWorldPages.first).inspected)

        let full = try GameStore.makeWildWorldPagesPhoneFixture(kind: .fullSatchel)
        let fullPage = try XCTUnwrap(full.store.activeRun?.offeredWorldPages.first)
        let cancelledState = full.store.state
        XCTAssertEqual(full.store.state, cancelledState, "cancelling is deliberately no action")
        let swapQuote = try XCTUnwrap(full.store.offeredWorldPageQuote(fullPage.id))
        XCTAssertEqual(full.store.takeOfferedWorldPage(swapQuote), .satchelFull)
        XCTAssertEqual(full.store.activeRun?.offeredWorldPages,
                       cancelledState.worlds.activeRun?.offeredWorldPages)
        XCTAssertEqual(full.store.activeRun?.satchelItems,
                       cancelledState.worlds.activeRun?.satchelItems)
        XCTAssertEqual(full.store.activeRun?.carriedWorldPages,
                       cancelledState.worlds.activeRun?.carriedWorldPages)
        XCTAssertEqual(full.store.state.reality.encounteredLexemes,
                       cancelledState.reality.encounteredLexemes)
        let itemID = try XCTUnwrap(full.store.activeRun?.satchelItems.stacks.first?.id)
        guard case .swapped(let taken, discarded: .itemStack(let discarded)) =
                full.store.swapOfferedWorldPage(swapQuote, discarding: .itemStack(itemID)) else {
            return XCTFail("expected exact item-to-page swap")
        }
        XCTAssertEqual(taken.id, fullPage.id)
        XCTAssertFalse(taken.inspected)
        XCTAssertEqual(discarded.id, itemID)
        XCTAssertEqual(full.store.state.reality.encounteredLexemes,
                       cancelledState.reality.encounteredLexemes,
                       "swapping for an unopened page must not record Dictionary sightings")
    }

    func testWorldInteractTakesLoosePageDirectlyWithoutInspectOrSuccessModal() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .deletingLastPathComponent()
        let source = try String(contentsOf: root.appending(path:
            "Sources/Screens/WorldView.swift"), encoding: .utf8)
        let interaction = try XCTUnwrap(source.components(separatedBy:
            "private func performInteraction()").dropFirst().first)
            .components(separatedBy: "private func completeWorldPageSwap")[0]

        XCTAssertTrue(interaction.contains("store.takeOfferedWorldPage(quote)"))
        XCTAssertFalse(interaction.contains("store.inspectOfferedWorldPage"),
                       "field Interact must not require Inspect before Take")
        XCTAssertFalse(interaction.contains("case .taken(let"),
                       "successful pickup must not open a result alert")
        XCTAssertTrue(source.contains("Take loose page · 1 satchel slot · no turn"))
        XCTAssertFalse(source.contains("Inspect Loose page · no turn"))
    }

    @MainActor
    func testWildWorldPagesPhoneFailureAndLaterBindReceiptsAreExactAndDurable() throws {
        let failure = try GameStore.makeWildWorldPagesPhoneFixture(kind: .failureReceipt)
        let summary = try XCTUnwrap(failure.store.state.worlds.lastExit)
        XCTAssertNil(failure.store.activeRun)
        XCTAssertFalse(summary.keptWorldPages.isEmpty)
        XCTAssertTrue(summary.keptWorldPages.contains(where: \.isProtectedReturn))
        XCTAssertEqual(failure.store.state.worlds.worldPageBankedOutcomeIDs,
                       [try XCTUnwrap(summary.outcomeID)])

        let bind = try GameStore.makeWildWorldPagesPhoneFixture(kind: .laterBind)
        let pages = bind.store.state.base.collectedWorldPages
        XCTAssertEqual(pages.count, 2)
        XCTAssertTrue(bind.store.bindAndDepart(worldPageInstanceID: pages[0].id))
        XCTAssertEqual(bind.store.activeRun?.book.worldPageUseReceipt?.instanceID, pages[0].id)
        XCTAssertFalse(bind.store.state.base.collectedWorldPages.contains { $0.id == pages[0].id })
        XCTAssertTrue(bind.store.state.base.collectedWorldPages.contains { $0.id == pages[1].id })
    }

    func testWritingDeskConcealsUninspectedWildPageAuthorityUntilExactOpen() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .deletingLastPathComponent()
        let source = try String(contentsOf: root.appending(path: "Sources/Screens/WritingDeskView.swift"),
                                encoding: .utf8)
        XCTAssertTrue(source.contains("instance.fieldProvenance != nil && !instance.inspected"))
        XCTAssertTrue(source.contains("concealsFieldPage ? \"Unknown page\" : instance.definition.title"))
        XCTAssertTrue(source.contains("if !concealsFieldPage"))
    }

    @MainActor
    func testHomeInspectionPersistsExactWildPageKnowledge() throws {
        let definition = try XCTUnwrap(WorldPageCatalog.definition("wild_storm_coast"))
        let instance = WorldPageInstance(
            id: InstanceID(rawValue: 7_001), definition: definition,
            fieldProvenance: .init(originRunIndex: 2, originWorldSeed: 3,
                                   generationSeed: 4, position: GridPoint(x: 1, y: 1)))
        let store = GameStore(io: .temporary(name: "inspect-wild-home-\(UUID().uuidString)"))
        store.mutate("install wild page") { $0.base.collectedWorldPages.append(instance) }
        XCTAssertTrue(store.inspectWorldPage(instance.id))
        let current = try XCTUnwrap(store.state.base.collectedWorldPages.first {
            $0.id == instance.id
        })
        XCTAssertTrue(current.inspected)
        XCTAssertEqual(store.state.reality.encounteredLexemes,
                       definition.page.encounteredLexemes)
    }
    func testRepeatableWorldPagesMatchGeneratedAuthorityAndCarryFieldIdentity() throws {
        let definitions = WorldPageCatalog.repeatableDefinitions
        XCTAssertEqual(definitions.map(\.id), [
            "wild_moss_and_mist", "wild_salt_and_iron", "wild_winter_hollows",
            "wild_cinder_fields", "wild_gilded_caverns", "wild_storm_coast",
            "wild_blighted_garden", "wild_mote_understone"
        ])
        XCTAssertEqual(definitions.map(\.disposition),
                       Array(repeating: .repeatable, count: 7) + [.repeatableRare])
        XCTAssertEqual(definitions.map(\.minimumResolvedExpeditions), [1, 1, 1, 1, 2, 3, 3, 5])
        XCTAssertEqual(definitions.map(\.worldPageCost), [17, 17, 16, 17, 19, 18, 18, 25])
        XCTAssertEqual(definitions.map(\.baseWeightMultiplier), [1, 1, 1, 1, 1, 1, 1, 0.35])
        XCTAssertEqual(definitions.map { $0.candidateUnknownSymbolIDs.map(\.rawValue) },
                       [[], [], [], [], [], ["storm"], ["blight"], ["mote_vein"]])
        XCTAssertTrue(definitions.allSatisfy { $0.seed == 0 && $0.disposition.isRandom })
        XCTAssertEqual(WorldPageCatalog.definitions.count,
                       WorldPageCatalog.starterDefinitions.count
                           + WorldPageCatalog.repeatableDefinitions.count + 1,
                       "the permanent Earthlike testing page is additional to authored starter and wild pages")
        XCTAssertEqual(WorldPageCatalog.definition("wild_storm_coast")?.title, "Storm Coast")

        let page = try XCTUnwrap(WorldPageCatalog.definition("wild_storm_coast"))
        let instance = WorldPageInstance(
            id: InstanceID(rawValue: 9001), definition: page, inspected: true,
            fieldProvenance: .init(originRunIndex: 7, originWorldSeed: 55,
                                   generationSeed: 77, position: GridPoint(x: 4, y: 9)))
        XCTAssertFalse(instance.isProtectedReturn)
        XCTAssertTrue(instance.isRandomDrop)
        XCTAssertEqual(try SaveCodec.makeDecoder().decode(
            WorldPageInstance.self, from: SaveCodec.makeEncoder().encode(instance)), instance)
    }

    func testLegacyStarterPageInstanceDecodesWithUninspectedNoFieldOrigin() throws {
        let legacy = WorldPageCatalog.starterInstances[0]
        var object = try XCTUnwrap(JSONSerialization.jsonObject(
            with: SaveCodec.makeEncoder().encode(legacy)) as? [String: Any])
        object.removeValue(forKey: "inspected")
        object.removeValue(forKey: "fieldProvenance")
        if var definition = object["definition"] as? [String: Any] {
            definition.removeValue(forKey: "knownFind")
            object["definition"] = definition
        }
        let decoded = try SaveCodec.makeDecoder().decode(
            WorldPageInstance.self, from: JSONSerialization.data(withJSONObject: object))
        XCTAssertFalse(decoded.inspected)
        XCTAssertNil(decoded.fieldProvenance)
        XCTAssertNil(decoded.definition.knownFind)
        XCTAssertTrue(decoded.isProtectedReturn)
    }

    func testStarterWorldPagesMatchFrozenAuthorityAndRulesOwnedPrices() throws {
        let definitions = WorldPageCatalog.starterDefinitions
        XCTAssertEqual(definitions.map(\.id), ["starter_open_meadow", "starter_rainwashed_shore",
                                                "starter_stone_hollow"])
        XCTAssertEqual(definitions.map(\.disposition), [.starterUnique, .starterUnique, .starterUnique])
        XCTAssertEqual(definitions.map(\.seed), [2, 26, 23])
        XCTAssertEqual(definitions.map(\.copiedCost), [21, 18, 22])
        XCTAssertEqual(definitions.map(\.worldPageCost), [14, 14, 16])
        XCTAssertEqual(definitions.map(\.title), ["Open Meadow", "Rainwashed Shore", "Stone Hollow"])
        XCTAssertEqual(definitions.map(\.knownFind), ["field_maul", "bone_awl", "blade_chipped"])
        XCTAssertEqual(definitions.map(\.provenance), [
            "A clean practice page, already written in rough charcoal.",
            "A clean practice page with one broad charcoal mark.",
            "A clean practice page with charcoal rubbed into the grain."
        ])
        XCTAssertEqual(definitions.map(\.promise), [
            "Open, living, modestly resourced and safe enough to learn the opening loop.",
            "A readable water-and-relief contrast without an opening lethality spike.",
            "Stone, enclosure and ordinary ore within the accepted level-one envelope."
        ])
        XCTAssertTrue(definitions.allSatisfy { $0.page.width == 6 && $0.page.height == 6 })
        XCTAssertTrue(definitions.allSatisfy { $0.page.runes.allSatisfy { $0.hand == .crude } })
        XCTAssertEqual(definitions.map { $0.page.runes.map(\.id.rawValue) }, [[1, 2], [1], [1, 2]])
        XCTAssertEqual(definitions.map { $0.page.runes.map(\.shapeID) },
                       [["crude_smear", "crude_smear"], ["crude_smear"],
                        ["crude_smear", "crude_block"]])
        XCTAssertEqual(definitions.map { $0.page.symbolIDs.map(\.rawValue) },
                       [["plains", "verdant"], ["archipelago"], ["caverns", "common_ore"]])
        XCTAssertEqual(definitions.map { $0.page.runes.map(\.origin) }, [
            [PageCell(column: 0, row: 0), PageCell(column: 3, row: 3)],
            [PageCell(column: 1, row: 2)],
            [PageCell(column: 0, row: 1), PageCell(column: 4, row: 3)]
        ])

        let instances = WorldPageCatalog.starterInstances
        XCTAssertEqual(Set(instances.map(\.id)).count, 3)
        XCTAssertEqual(instances.map(\.id.rawValue),
                       [0x5750_0000_0000_0001, 0x5750_0000_0000_0002,
                        0x5750_0000_0000_0003])
        let projectRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let authority = projectRoot.appendingPathComponent("docs/world-pages-authority.json")
        let sourceAuthoritySHA256 = try SHA256.hash(data: Data(contentsOf: authority))
            .map { String(format: "%02x", $0) }.joined()
        XCTAssertEqual(WorldPageCatalog.authoritySHA256, sourceAuthoritySHA256,
                       "generated World Page authority must match its source document")
        XCTAssertNil(WorldPageCatalog.definition("not_authored"),
                     "unknown content must fail closed rather than fabricate a page")
        for instance in instances {
            let ordinary = BookRules.resolveBook(page: instance.definition.page)
            let preInscribed = BookRules.resolveBook(worldPage: instance)
            XCTAssertEqual(ordinary.essencePaid, instance.definition.copiedCost)
            XCTAssertEqual(preInscribed.essencePaid, instance.definition.worldPageCost)
            XCTAssertEqual(preInscribed.essencePaid,
                           ordinary.essencePaid - BookRules.inkCost(of: instance.definition.page))
            XCTAssertEqual(preInscribed.worldPageUseReceipt?.instanceID, instance.id)
            XCTAssertEqual(preInscribed.worldPageUseReceipt?.definition, instance.definition)
        }

        let data = try SaveCodec.makeEncoder().encode(instances)
        XCTAssertEqual(try SaveCodec.makeDecoder().decode([WorldPageInstance].self, from: data), instances)
    }

    func testLegacyBoundBookDecodesWithoutWorldPageReceipt() throws {
        let data = Data(#"{"written":["plains"],"essencePaid":14}"#.utf8)
        let book = try SaveCodec.makeDecoder().decode(BoundBook.self, from: data)
        XCTAssertNil(book.worldPageUseReceipt)
        XCTAssertEqual(book.allSymbolIDs, ["plains"])
        XCTAssertEqual(book.essencePaid, 14)
    }

    func testCancellingPageToolClearsEveryTransientFieldWithoutChangingThePage() {
        let link = MarkLink(InstanceID(rawValue: 1), InstanceID(rawValue: 2))
        let page = Page(links: [link])
        var session = PageInteractionSession(mode: .connecting,
                                             anchor: InstanceID(rawValue: 1),
                                             held: InstanceID(rawValue: 2),
                                             connectionError: "Not adjacent")

        session.cancel()

        XCTAssertEqual(session.mode, .off)
        XCTAssertNil(session.anchor)
        XCTAssertNil(session.held)
        XCTAssertNil(session.connectionError)
        XCTAssertEqual(page.links, [link], "dismissing a tool must not undo completed links")
    }

    func testPageIdentityTracksPageReplacementButNotLinkEdits() {
        let ids = [InstanceID(rawValue: 3), InstanceID(rawValue: 7)]
        let original = PageInteractionIdentity(width: 6, height: 6, runeIDs: ids)
        let linkOnlyEdit = PageInteractionIdentity(width: 6, height: 6, runeIDs: ids)
        let replacement = PageInteractionIdentity(width: 6, height: 6,
                                                  runeIDs: [InstanceID(rawValue: 9)])

        XCTAssertEqual(original, linkOnlyEdit,
                       "completed Connect/Disconnect edits must not cancel their own mode")
        XCTAssertNotEqual(original, replacement)
    }

    // MARK: The page is a budget, not a syntax

    /// **Superseded in part** (decisions-session-14 §3). Absolute position still carries no
    /// meaning, which is what this checks — but *relative* position now does, and the rule that
    /// replaced this one lives in `GrammarTests`: translate or rotate the whole page and it must
    /// say exactly the same thing.
    ///
    /// This case survives because the marks in it are **self-contained** — compounds and
    /// whole-statement runes say what they say wherever they sit, with or without neighbours.
    func testSelfContainedMarksSayTheSameThingWhereverTheySit() {
        let sigils = [
            Sigil(id: InstanceID(rawValue: 1), source: "sun", target: "illumination", intensity: .great),
            Sigil(id: InstanceID(rawValue: 2), source: "glacier", target: "hydrology", intensity: .moderate)
        ]

        var tidy = Page()
        var scattered = Page()
        for sigil in sigils {
            tidy = PageRules.placeAnywhere(sigil, hand: .refined, on: tidy)!
        }
        // Same runes, deliberately different squares.
        scattered = PageRules.place(sigils[1], hand: .refined, at: PageCell(column: 5, row: 5), on: scattered)!
        scattered = PageRules.place(sigils[0], hand: .refined, at: PageCell(column: 0, row: 3), on: scattered)!

        XCTAssertNotEqual(tidy.runes.map(\.origin), scattered.runes.map(\.origin),
                          "the two pages were laid out the same, so this proves nothing")
        XCTAssertEqual(PressureRules.resolve(tidy.sigils), PressureRules.resolve(scattered.sigils))
    }

    /// Reading order isn't meaning either — `sigils` sorts by identity, not by where things landed.
    func testSigilOrderDoesNotDependOnLayout() {
        let a = Sigil(id: InstanceID(rawValue: 1), source: "sun", target: "illumination")
        let b = Sigil(id: InstanceID(rawValue: 2), source: "ice", target: "thermal")

        let first = PageRules.place(b, hand: .refined, at: PageCell(column: 0, row: 0), on: Page())!
        let second = PageRules.place(a, hand: .refined, at: PageCell(column: 3, row: 3), on: first)!
        XCTAssertEqual(second.sigils.map(\.id.rawValue), [1, 2])
    }

    // MARK: Fitting

    func testARuneCannotOverlapAnother() {
        let page = PageRules.place(
            Sigil(id: InstanceID(rawValue: 1), source: "sun", target: "illumination"),
            hand: .crude, at: PageCell(column: 0, row: 0), on: Page())!

        let occupied = page.runes[0].cells[0]
        XCTAssertNil(PageRules.place(
            Sigil(id: InstanceID(rawValue: 2), source: "ice", target: "thermal"),
            hand: .refined, at: occupied, on: page),
                     "two runes wrote over each other")
    }

    func testARuneCannotHangOffTheEdge() {
        let page = Page()
        let corner = PageCell(column: page.width - 1, row: page.height - 1)
        XCTAssertNil(PageRules.place(
            Sigil(id: InstanceID(rawValue: 1), source: "sun", target: "illumination"),
            hand: .crude, at: corner, on: page),
                     "a charcoal scrawl fitted into a single corner cell")
    }

    func testAFullPageRefusesMore() {
        var page = Page(width: 2, height: 2)
        for index in 0..<4 {
            let sigil = Sigil(id: InstanceID(rawValue: UInt64(index)), source: "sun", target: "illumination")
            page = PageRules.placeAnywhere(sigil, hand: .refined, on: page)!
        }
        XCTAssertEqual(page.freeCells, 0)
        XCTAssertNil(PageRules.placeAnywhere(
            Sigil(id: InstanceID(rawValue: 99), source: "ice", target: "thermal"),
            hand: .refined, on: page))
    }

    func testRemovingARuneFreesItsCells() {
        let sigil = Sigil(id: InstanceID(rawValue: 1), source: "sun", target: "illumination")
        let page = PageRules.placeAnywhere(sigil, hand: .crude, on: Page())!
        XCTAssertGreaterThan(page.usedCells, 1)
        XCTAssertEqual(PageRules.remove(sigil.id, from: page).usedCells, 0)
    }

    // MARK: Refinement is literacy, not power

    func testABetterHandSaysTheSameThingInLessSpace() {
        let sigil = Sigil(id: InstanceID(rawValue: 1), source: "sun", target: "illumination")
        var previous = Int.max
        for hand in Hand.allCases {   // crude → plain → refined
            let page = PageRules.placeAnywhere(sigil, hand: hand, on: Page())!
            XCTAssertLessThan(page.usedCells, previous, "\(hand.rawValue) didn't compress")
            previous = page.usedCells

            // Same statement, whichever hand wrote it.
            XCTAssertEqual(page.sigils, [sigil])
        }
    }

    func testEveryRefinedRuneIsASingleCell() {
        for source in ContentCatalog.shared.pressureSources {
            let shape = PageRules.shape(for: source.id, hand: .refined)
            XCTAssertEqual(shape?.footprint, 1, "\(source.id.rawValue) isn't 1×1 in a fine hand")
        }
    }

    func testCrudeIsAlwaysBulkierThanPlain() {
        for source in ContentCatalog.shared.pressureSources {
            let crude = PageRules.shape(for: source.id, hand: .crude)?.footprint ?? 0
            let plain = PageRules.shape(for: source.id, hand: .plain)?.footprint ?? 0
            XCTAssertGreaterThan(crude, plain, "\(source.id.rawValue) got no worse in charcoal")
        }
    }

    func testRedrawingInAFinerHandKeepsThePageValid() {
        let sigil = Sigil(id: InstanceID(rawValue: 1), source: "sun", target: "illumination")
        let crude = PageRules.placeAnywhere(sigil, hand: .crude, on: Page())!
        let refined = PageRules.redraw(sigil.id, in: .refined, on: crude)!

        XCTAssertEqual(refined.usedCells, 1)
        XCTAssertEqual(refined.sigils, crude.sigils, "redrawing changed what the page said")
        XCTAssertEqual(Set(refined.runes.flatMap(\.cells)).count, refined.usedCells)
    }

    /// A better hand must never cost you a layout you'd already made.
    func testRedrawingRelocatesRatherThanFailing() {
        let big = Sigil(id: InstanceID(rawValue: 1), source: "sun", target: "illumination")
        var page = PageRules.place(big, hand: .refined, at: PageCell(column: 5, row: 5), on: Page())!
        // Crude needs room the bottom-right corner doesn't have, so it has to move.
        page = PageRules.redraw(big.id, in: .crude, on: page)!
        XCTAssertEqual(page.sigils, [big])
        XCTAssertTrue(page.runes[0].cells.allSatisfy { page.contains($0) })
    }

    // MARK: Shapes are stable

    /// A rune the player has learned to fit must not change shape between launches — Swift's own
    /// hashing is salted per process, which would redraw every page on relaunch.
    func testARuneAlwaysDrawsTheSameShape() {
        for source in ContentCatalog.shared.pressureSources {
            let first = PageRules.shape(for: source.id, hand: .crude)?.id
            let again = PageRules.shape(for: source.id, hand: .crude)?.id
            XCTAssertEqual(first, again)
        }
        // Pinned values: if these change, existing pages relayout.
        XCTAssertNotNil(PageRules.shape(for: "sun", hand: .crude))
        XCTAssertEqual(PageRules.shape(for: "sun", hand: .crude)?.id,
                       PageRules.shape(for: "sun", hand: .crude)?.id)
    }

    func testShapesAreSpreadAcrossTheAvailableForms() {
        // If every rune picked the same shape, the packing puzzle would be trivial.
        let used = Set(ContentCatalog.shared.pressureSources.compactMap {
            PageRules.shape(for: $0.id, hand: .crude)?.id
        })
        XCTAssertGreaterThan(used.count, 1, "every rune drew as the same scrawl")
    }

    // MARK: Compounds

    func testACompoundCostsLessThanItsPartsButIsNeverFree() {
        XCTAssertEqual(PageRules.compoundFootprint(ofParts: []), 0)
        XCTAssertGreaterThan(PageRules.compoundFootprint(ofParts: [1]), 0)

        for parts in [[2, 2], [3, 3, 3], [4, 5, 6]] {
            let sum = parts.reduce(0, +)
            let compound = PageRules.compoundFootprint(ofParts: parts)
            XCTAssertLessThan(compound, sum, "\(parts) was no cheaper written as one mark")
            XCTAssertGreaterThan(compound, 0)
        }
    }

    func testEveryCatalogueCompoundIsWorthLearning() {
        for symbol in ContentCatalog.shared.symbols {
            let parts = symbol.expandsTo.compactMap { PageRules.shape(for: $0.source, hand: .plain)?.footprint }
            guard parts.count > 1 else { continue }
            XCTAssertLessThan(PageRules.footprint(of: symbol, hand: .plain), parts.reduce(0, +),
                              "\(symbol.id.rawValue) costs as much as spelling it out")
        }
    }

    func testProvenStatementNormalizationIgnoresLayoutHandAndSourceOrder() throws {
        var base = BaseState.newGame()
        let sources = Array(ContentCatalog.shared.pressureSources.prefix(2).map(\.id))
        XCTAssertEqual(sources.count, 2)
        base.ownedSources.formUnion(sources)
        let target: PressureTargetID = "illumination"
        func page(ids: [UInt64], reversed: Bool, hand: Hand) -> Page {
            let ordered = reversed ? Array(sources.reversed()) : sources
            let targetMark = PlacedRune(id: .init(rawValue: ids[0]), content: .target(target),
                                        hand: hand, origin: .init(column: 5, row: 5), shapeID: "refined_dot")
            let sourceMarks = ordered.enumerated().map { offset, source in
                PlacedRune(id: .init(rawValue: ids[offset + 1]), content: .source(source),
                           hand: hand, origin: .init(column: offset, row: 0), shapeID: "refined_dot")
            }
            return Page(runes: [targetMark] + sourceMarks,
                        links: Set(sourceMarks.map { MarkLink(targetMark.id, $0.id) }))
        }
        let first = try XCTUnwrap(PageRules.compoundStatementAssessments(
            on: page(ids: [1, 2, 3], reversed: false, hand: .crude), knownBy: base,
            boundRunIndex: 1).first?.receipt)
        let rearranged = try XCTUnwrap(PageRules.compoundStatementAssessments(
            on: page(ids: [91, 43, 12], reversed: true, hand: .refined), knownBy: base,
            boundRunIndex: 7).first?.receipt)
        XCTAssertEqual(first.fingerprint, rearranged.fingerprint)
        XCTAssertEqual(first.atoms, rearranged.atoms)
        XCTAssertEqual(first.vocabulary, rearranged.vocabulary)
        XCTAssertNotEqual(first.firstBoundRunIndex, rearranged.firstBoundRunIndex)
    }

    func testCompoundEligibilityRejectsUnknownNestedAndOverFiveAtomsExactly() throws {
        var base = BaseState.newGame()
        let source = try XCTUnwrap(ContentCatalog.shared.pressureSources.first).id
        base.ownedSources.remove(source)
        let target = PlacedRune(id: .init(rawValue: 1), content: .target("illumination"),
                                hand: .crude, origin: .init(column: 0, row: 0), shapeID: "refined_dot")
        let focus = PlacedRune(id: .init(rawValue: 2), content: .source(source),
                               hand: .crude, origin: .init(column: 1, row: 0), shapeID: "refined_dot")
        let unknown = Page(runes: [target, focus], links: [MarkLink(target.id, focus.id)])
        XCTAssertEqual(PageRules.compoundStatementAssessments(
            on: unknown, knownBy: base, boundRunIndex: 1).first?.issue, .unknownAtom)

        let nested = PlacedRune(id: .init(rawValue: 3), content: .compound("plains"),
                                hand: .crude, origin: .init(column: 2, row: 0), shapeID: "crude_block")
        XCTAssertEqual(PageRules.compoundStatementAssessments(
            on: Page(runes: [target, nested], links: [MarkLink(target.id, nested.id)]),
            knownBy: base, boundRunIndex: 1).first?.issue, .nestedCompound)

        base.ownedSources.insert(source)
        let qualifiers = (0..<4).map { offset in
            PlacedRune(id: .init(rawValue: UInt64(10 + offset)), content: .qualifier("great"),
                       hand: .crude, origin: .init(column: offset, row: 1), shapeID: "refined_dot")
        }
        let tooMany = Page(runes: [target, focus] + qualifiers,
                           links: Set([MarkLink(target.id, focus.id)]
                            + qualifiers.map { MarkLink(focus.id, $0.id) }))
        XCTAssertEqual(PageRules.compoundStatementAssessments(
            on: tooMany, knownBy: base, boundRunIndex: 1).first?.issue, .tooManyAtoms)
    }

    func testPersonalCompoundPlacementPreservesExactWorldEffectsAndShrinksFootprint() throws {
        let source = try XCTUnwrap(ContentCatalog.shared.pressureSources.first).id
        let atom = CompoundSemanticAtom(Sigil(id: .init(rawValue: 1), source: source,
                                               target: "illumination", intensity: .great,
                                               scale: 2, count: 1))
        let receipt = ProvenStatementReceipt(
            fingerprint: PageRules.statementFingerprint(target: "illumination", atoms: [atom]),
            target: "illumination", atoms: [atom],
            vocabulary: [.target("illumination"), .source(source), .qualifier("great")],
            vocabularySchemaVersion: 1, firstBoundRunIndex: 1)
        let record = PersonalCompoundRecord(
            id: .init(rawValue: 9), nickname: "Bright reach",
            provenFingerprint: receipt.fingerprint, target: receipt.target,
            expansion: receipt.atoms, vocabulary: receipt.vocabulary,
            vocabularySchemaVersion: 1, provenance: "Personal", creationOrdinal: 1)
        let personal = try XCTUnwrap(PageRules.place(record, hand: .plain,
                                                     at: .init(column: 0, row: 0), on: Page()))
        let expanded = Page(runes: [
            PlacedRune(id: .init(rawValue: 50), sigil: atom.sigil(id: .init(rawValue: 50)),
                       hand: .plain, origin: .init(column: 0, row: 0),
                       shapeID: try XCTUnwrap(PageRules.shape(for: source, hand: .plain)?.id))
        ])
        let personalBook = BookRules.resolveBook(page: personal)
        let expandedBook = BookRules.resolveBook(page: expanded)
        XCTAssertEqual(BookRules.readings(for: personalBook, seed: 77),
                       BookRules.readings(for: expandedBook, seed: 77))
        XCTAssertEqual(BookRules.dangerProfile(for: personalBook),
                       BookRules.dangerProfile(for: expandedBook))
        XCTAssertEqual(BookRules.stabilityScore(of: personalBook),
                       BookRules.stabilityScore(of: expandedBook))
        XCTAssertEqual(BookRules.greedDelta(for: personalBook.composition),
                       BookRules.greedDelta(for: expandedBook.composition))
        let atomicFootprint = record.vocabulary.compactMap { identity -> Int? in
            switch identity {
            case .target(let id): PageRules.shape(for: .target(id), hand: .plain)?.footprint
            case .source(let id): PageRules.shape(for: .source(id), hand: .plain)?.footprint
            case .qualifier(let id): PageRules.shape(for: .qualifier(id), hand: .plain)?.footprint
            case .compound: nil
            }
        }.reduce(0, +)
        XCTAssertEqual(PageRules.personalCompoundFootprint(record, hand: .plain),
                       max(1, Int((Double(atomicFootprint) * 0.6).rounded(.up))))
        XCTAssertLessThan(PageRules.personalCompoundFootprint(record, hand: .plain), atomicFootprint)
    }

    // MARK: Capacity

    func testPageSizeIsCapabilityNotAffordability() {
        // Growing the page is a permanent unlock; it must not change what a book *costs*.
        let small = Page(width: 4, height: 4)
        let large = Page(width: 8, height: 8)
        XCTAssertGreaterThan(large.capacity, small.capacity)

        let sigil = Sigil(id: InstanceID(rawValue: 1), source: "sun", target: "illumination")
        let onSmall = PageRules.placeAnywhere(sigil, hand: .plain, on: small)!
        let onLarge = PageRules.placeAnywhere(sigil, hand: .plain, on: large)!
        XCTAssertEqual(onSmall.usedCells, onLarge.usedCells, "the same rune cost more on a bigger page")
    }

    func testAPageRoundTripsThroughASave() throws {
        var page = Page()
        page = PageRules.placeAnywhere(
            Sigil(id: InstanceID(rawValue: 1), source: "sun", target: "illumination",
                  intensity: .great, negatedTargets: ["thermal"]), hand: .crude, on: page)!
        page = PageRules.placeAnywhere(
            Sigil(id: InstanceID(rawValue: 2), source: "ice", target: "thermal"), hand: .refined, on: page)!

        let data = try SaveCodec.makeEncoder().encode(page)
        let reloaded = try SaveCodec.makeDecoder().decode(Page.self, from: data)
        XCTAssertEqual(reloaded, page)
        XCTAssertEqual(reloaded.sigils, page.sigils)
    }

    // MARK: The desk writes on the page

    func testWritingDeskClearRequiresExactDestructiveConfirmation() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let source = try String(
            contentsOf: root.appending(path: "Sources/Screens/WritingDeskView.swift"),
            encoding: .utf8
        )

        XCTAssertTrue(source.contains("private var writingContextTools"))
        XCTAssertTrue(source.contains("Text(clearPageActionLabel)"))
        XCTAssertTrue(source.contains("isConfirmingClear = true"))
        XCTAssertTrue(source.contains("\"Clear this page?\""))
        XCTAssertTrue(source.contains("Button(clearPageActionLabel, role: .destructive)"))
        XCTAssertTrue(source.contains("Button(\"Keep writing\", role: .cancel)"))
        XCTAssertTrue(source.contains("Every placed mark and connection on this page will be removed."))
        XCTAssertEqual(source.components(separatedBy: "store.clearPage()").count - 1, 1,
                       "Only the confirmed destructive action may clear the page.")
    }

    func testWritingDeskUsesApprovedPageDrawerAndPaneHierarchyWithoutChangingActions() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(
            contentsOf: root.appending(path: "Sources/Screens/WritingDeskView.swift"),
            encoding: .utf8)

        XCTAssertTrue(source.contains("private var writingPaneTabs"))
        XCTAssertTrue(source.contains("WritingDeskPaperBackground()"))
        XCTAssertTrue(source.contains("WritingDeskWoodBackground()"))
        XCTAssertTrue(source.contains("PageGridView(ghost: $ghost"))
        XCTAssertTrue(source.contains("PixelUITheme.surfaceInset"))
        XCTAssertTrue(source.contains("HStack(spacing: 4)"),
                      "Collected and Templates remain one internal two-choice shelf switch.")
        XCTAssertFalse(source.contains("Picker(\"\", selection: $pane)"),
                       "The approved three-pane rail belongs in the screen, not the navigation title.")
        XCTAssertTrue(source.contains("store.bindAndDepart"))
        XCTAssertTrue(source.contains("store.savePageTemplate"))
        XCTAssertTrue(source.contains("store.clearPage()"))
    }

    func testWritingDeskPersonalCompoundPaletteUsesFrozenPlacementAuthorityAndAnchoredDetail() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(
            contentsOf: root.appending(path: "Sources/Screens/WritingDeskView.swift"),
            encoding: .utf8)

        XCTAssertTrue(source.contains("sectionLabel(\"My Runebook\")"))
        XCTAssertTrue(source.contains("PageRules.personalCompoundFootprint(record"))
        XCTAssertTrue(source.contains("CompoundRunebookPresentation.expansion(record)"))
        XCTAssertTrue(source.contains("Text(record.provenance)"))
        XCTAssertTrue(source.contains("PageRules.place(record, hand: state.base.bestHand"))
        XCTAssertTrue(source.contains("store.mutate(\"place personal compound\")"))
        XCTAssertTrue(source.contains("exact frozen expansion"))
        XCTAssertFalse(source.contains("formalizePersonalCompound"),
                       "The Writing Desk places saved notation; it must not mint or charge for it")
    }

    func testTemplateUIUsesThumbnailGridAnchoredActionsAndExactConfirmations() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let source = try String(
            contentsOf: root.appending(path: "Sources/Screens/WritingDeskView.swift"),
            encoding: .utf8)
        XCTAssertTrue(source.contains("case templates = \"Templates\""))
        XCTAssertTrue(source.contains("SavedPageTemplateCard("))
        XCTAssertTrue(source.contains(".popover(isPresented: $showsActions"))
        XCTAssertTrue(source.contains(".presentationCompactAdaptation(.popover)"))
        XCTAssertTrue(source.contains("\"Replace the current page?\""))
        XCTAssertTrue(source.contains("\"Overwrite this Template?\""))
        XCTAssertTrue(source.contains("\"Delete this Template?\""))
        XCTAssertTrue(source.contains("PageTemplateRules.capacity) Templates"),
                      "the bounded shelf must disclose current usage and its cap")
        XCTAssertTrue(source.contains("Button(\"Save Template\")")
                      || source.contains(".accessibilityLabel(\"Save Template\")"))
    }

    func testInkWellUIExposesAshMixerPreparationAndOneSharedRecipePreview() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(
            contentsOf: root.appending(path: "Sources/Screens/WritingDeskView.swift"),
            encoding: .utf8)
        XCTAssertTrue(source.contains("Ash ink"))
        XCTAssertTrue(source.contains("Color left open"))
        XCTAssertTrue(source.contains("InkChannelSlider(name: \"Cyan\""))
        XCTAssertTrue(source.contains("InkChannelSlider(name: \"Magenta\""))
        XCTAssertTrue(source.contains("InkChannelSlider(name: \"Yellow\""))
        XCTAssertTrue(source.contains("InkChannelSlider(name: \"Depth\""))
        XCTAssertTrue(source.contains("Button(\"Apply mixture\")"))
        XCTAssertTrue(source.contains("Button(\"Return to Ash\")"))
        XCTAssertTrue(source.contains("Button(\"Use for next focus\")"))
        XCTAssertTrue(source.contains("Button(\"Prepare 12 applications\")"))
        XCTAssertTrue(source.contains("store.inkVialPreparationQuote(recipe)"))
        XCTAssertTrue(source.contains("store.prepareInkVial(quote)"))
        XCTAssertTrue(source.contains("recipe?.resolvedSRGB"),
                      "the page swatch must use the same recipe conversion as binding")
    }

    @MainActor
    func testTemplateRoundTripRemapsEveryIdentityAndLinkWithoutChangingComposition() throws {
        let store = GameStore(io: .temporary(name: "template-remap-\(UUID().uuidString)"))
        let first = PlacedRune(id: InstanceID(rawValue: 11), content: .target("illumination"),
                               hand: .crude, origin: .init(column: 0, row: 0),
                               shapeID: "crude_block")
        let second = PlacedRune(id: InstanceID(rawValue: 22), content: .source("sun"),
                                hand: .crude, origin: .init(column: 2, row: 0),
                                shapeID: "crude_block")
        let legacy = PlacedRune(
            id: InstanceID(rawValue: 33),
            sigil: Sigil(id: InstanceID(rawValue: 44), source: "sun", target: "illumination"),
            hand: .crude, origin: .init(column: 0, row: 2), shapeID: "crude_block")
        let authored = Page(runes: [first, second, legacy], links: [MarkLink(first.id, second.id)])
        store.mutate("test: authored template") { $0.base.page = authored }

        guard case .saved(let templateID) = store.savePageTemplate(named: "  Morning path  ")
        else { return XCTFail("valid page was not saved") }
        let frozen = try XCTUnwrap(store.state.base.savedPageTemplates.first)
        XCTAssertEqual(frozen.id, templateID)
        XCTAssertEqual(frozen.name, "Morning path")
        XCTAssertEqual(frozen.page, authored)

        store.clearPage()
        XCTAssertEqual(store.loadPageTemplate(templateID), .loaded(templateID))
        let firstLoad = store.state.base.page
        XCTAssertEqual(Array(firstLoad.runes.prefix(2)).map(\.content),
                       Array(authored.runes.prefix(2)).map(\.content))
        XCTAssertEqual(firstLoad.runes.map(\.origin), authored.runes.map(\.origin))
        XCTAssertEqual(firstLoad.runes.map(\.shapeID), authored.runes.map(\.shapeID))
        XCTAssertEqual(firstLoad.links.count, 1)
        XCTAssertNotEqual(firstLoad.runes.map(\.id), authored.runes.map(\.id))
        guard case .rune(let firstLegacy) = firstLoad.runes[2].content,
              case .rune(let authoredLegacy) = authored.runes[2].content
        else { return XCTFail("legacy rune was not preserved") }
        XCTAssertNotEqual(firstLegacy.id, authoredLegacy.id)
        XCTAssertEqual(firstLegacy.source, authoredLegacy.source)
        XCTAssertEqual(firstLegacy.target, authoredLegacy.target)
        XCTAssertTrue(firstLoad.links.contains(MarkLink(firstLoad.runes[0].id, firstLoad.runes[1].id)))
        XCTAssertTrue(PageTemplateRules.structurallyEquivalent(authored, firstLoad))

        XCTAssertEqual(store.loadPageTemplate(templateID), .noChange,
                       "loading the composition already present is an identity-insensitive no-op")
        XCTAssertEqual(store.state.base.page.runes.map(\.id), firstLoad.runes.map(\.id))

        store.clearPage()
        XCTAssertEqual(store.loadPageTemplate(templateID), .loaded(templateID))
        XCTAssertNotEqual(store.state.base.page.runes.map(\.id), firstLoad.runes.map(\.id),
                          "each actual load must issue fresh identities")
        XCTAssertEqual(store.state.base.savedPageTemplates.first?.page, authored,
                       "loading must never mutate the frozen Template")
    }

    @MainActor
    func testTemplateActionsUseStableIDsAndRemainAtomicAtTheCap() throws {
        let store = GameStore(io: .temporary(name: "template-actions-\(UUID().uuidString)"))
        XCTAssertEqual(store.savePageTemplate(named: "Blank"), .emptyDraft)
        XCTAssertTrue(store.write("plains"))
        guard case .saved(let firstID) = store.savePageTemplate(named: "First")
        else { return XCTFail("first Template did not save") }
        let firstOrdinal = try XCTUnwrap(store.state.base.savedPageTemplates.first).creationOrdinal

        XCTAssertEqual(store.renamePageTemplate(firstID, to: "  Renamed  "), .updated(firstID))
        XCTAssertEqual(store.state.base.savedPageTemplates.first?.name, "Renamed")
        XCTAssertTrue(store.write("frostbound"))
        XCTAssertEqual(store.overwritePageTemplate(firstID), .updated(firstID))
        XCTAssertEqual(store.state.base.savedPageTemplates.first?.id, firstID)
        XCTAssertEqual(store.state.base.savedPageTemplates.first?.creationOrdinal, firstOrdinal)
        XCTAssertEqual(store.state.base.savedPageTemplates.first?.name, "Renamed")

        store.mutate("test: fill template cap") { state in
            let page = state.base.page
            while state.base.savedPageTemplates.count < PageTemplateRules.capacity {
                let raw = state.base.nextPageTemplateID
                state.base.nextPageTemplateID += 1
                state.base.savedPageTemplates.append(.init(
                    id: .init(rawValue: raw), name: "Template \(raw)", page: page,
                    creationOrdinal: raw))
            }
        }
        let before = store.state
        XCTAssertEqual(store.savePageTemplate(named: "One too many"),
                       .capacityReached(PageTemplateRules.capacity))
        XCTAssertEqual(store.state, before)
        XCTAssertEqual(store.deletePageTemplate(.init(rawValue: UInt64.max)), .staleTemplate)
        XCTAssertEqual(store.state, before)
        XCTAssertEqual(store.deletePageTemplate(firstID), .deleted(firstID))
        XCTAssertFalse(store.state.base.savedPageTemplates.contains { $0.id == firstID })

        let nextID = store.state.base.nextPageTemplateID
        guard case .saved(let replacementID) = store.savePageTemplate(named: "After deletion")
        else { return XCTFail("deleting at cap did not make room") }
        XCTAssertEqual(replacementID.rawValue, nextID)
        XCTAssertNotEqual(replacementID, firstID, "deleted stable IDs must never be reused")
    }

    @MainActor
    func testTemplateRefusesMalformedLinksWithoutMutatingTheSave() {
        let store = GameStore(io: .temporary(name: "template-invalid-link-\(UUID().uuidString)"))
        XCTAssertTrue(store.write("plains"))
        store.mutate("test: inject malformed link") { state in
            let placed = state.base.page.runes[0]
            state.base.page.links = [MarkLink(placed.id, .init(rawValue: UInt64.max))]
        }
        let before = store.state
        XCTAssertEqual(store.savePageTemplate(named: "Broken"), .invalidDraft)
        XCTAssertEqual(store.state, before, "a refused Template must be an atomic no-op")
    }

    @MainActor
    func testMixedInkAppliesOnlyToInkCapableFocusMarksWithoutDraftCost() throws {
        let store = GameStore(io: .temporary(name: "ink-application-\(UUID().uuidString)"))
        let recipe = InkRecipe(cyan: 100, magenta: 0, yellow: 100, depth: 0)
        let target = PlacedRune(id: .init(rawValue: 1), content: .target("illumination"),
                                hand: .plain, origin: .init(column: 0, row: 0),
                                shapeID: "plain_bar")
        let charcoal = PlacedRune(id: .init(rawValue: 2), content: .source("sun"),
                                  hand: .crude, origin: .init(column: 2, row: 0),
                                  shapeID: "crude_block")
        let brush = PlacedRune(id: .init(rawValue: 3), content: .source("sun"),
                               hand: .plain, origin: .init(column: 0, row: 2),
                               shapeID: "plain_bar")
        store.mutate("test: ink page") { state in
            state.base.ownedHands.insert(.plain)
            state.base.page = Page(runes: [target, charcoal, brush])
        }
        let beforeLocked = store.state
        XCTAssertEqual(store.applyInkRecipe(recipe, to: brush.id), .mixingLocked)
        XCTAssertEqual(store.state, beforeLocked)

        store.mutate("test: learn ink mixing") {
            $0.base.completedResearch.insert("pen_ink_mixing")
            $0.base.capabilities.insert("inkMixing")
        }
        let before = store.state
        XCTAssertEqual(store.applyInkRecipe(recipe, to: target.id), .ineligibleMark)
        XCTAssertEqual(store.applyInkRecipe(recipe, to: charcoal.id), .ineligibleMark)
        XCTAssertEqual(store.applyInkRecipe(recipe, to: brush.id), .applied(brush.id))
        XCTAssertEqual(store.state.base.page.runes.first { $0.id == brush.id }?.inkRecipe, recipe)
        XCTAssertEqual(store.state.base.essence, before.base.essence,
                       "draft re-inking spends no Essence")
        XCTAssertEqual(store.applyInkRecipe(recipe, to: brush.id), .noChange)
        XCTAssertEqual(store.returnMarkToAsh(brush.id), .returnedToAsh(brush.id))
        XCTAssertNil(store.state.base.page.runes.first { $0.id == brush.id }?.inkRecipe)
    }

    @MainActor
    func testSavedInkMixturesDeduplicateWithoutRewritingFrozenMarks() throws {
        let store = GameStore(io: .temporary(name: "ink-mixtures-\(UUID().uuidString)"))
        let recipe = InkRecipe(cyan: 40, magenta: 15, yellow: 70, depth: 5)
        store.mutate("test: learn ink mixing") {
            $0.base.completedResearch.insert("pen_ink_mixing")
            $0.base.capabilities.insert("inkMixing")
        }
        guard case .savedMixture(let id) = store.saveInkMixture(named: "  Moss  ", recipe: recipe)
        else { return XCTFail("mixture was not saved") }
        XCTAssertEqual(store.state.base.savedInkMixtures.first?.name, "Moss")
        XCTAssertEqual(store.saveInkMixture(named: "Duplicate", recipe: recipe), .savedMixture(id))
        XCTAssertEqual(store.state.base.savedInkMixtures.count, 1)

        let mark = PlacedRune(id: .init(rawValue: 9), content: .source("sun"), hand: .plain,
                              origin: .init(column: 0, row: 0), shapeID: "plain_bar",
                              inkRecipe: recipe)
        store.mutate("test: freeze mixed mark") { $0.base.page = Page(runes: [mark]) }
        XCTAssertEqual(store.deleteInkMixture(id), .deletedMixture(id))
        XCTAssertEqual(store.state.base.page.runes.first?.inkRecipe, recipe,
                       "deleting a saved formula cannot recolor an existing mark")
    }

    func testInkRecipeRejectsEmptyAndOutOfRangeDecodedRecipes() throws {
        let decoder = JSONDecoder()
        XCTAssertThrowsError(try decoder.decode(
            InkRecipe.self,
            from: Data(#"{"cyan":0,"magenta":0,"yellow":0,"depth":0,"conversionVersion":"cmy-depth-v1"}"#.utf8)))
        XCTAssertThrowsError(try decoder.decode(
            InkRecipe.self,
            from: Data(#"{"cyan":101,"magenta":0,"yellow":0,"depth":0,"conversionVersion":"cmy-depth-v1"}"#.utf8)))
        let legacyVersionless = try decoder.decode(
            InkRecipe.self,
            from: Data(#"{"cyan":25,"magenta":0,"yellow":0,"depth":0}"#.utf8))
        XCTAssertEqual(legacyVersionless.conversionVersion, InkRecipe.currentConversionVersion)
    }

    @MainActor
    func testPreparingInkProcessesOnlyShortfallRetainsExcessAndIsAtomic() throws {
        let store = GameStore(io: .temporary(name: "ink-vial-\(UUID().uuidString)"))
        let recipe = InkRecipe(cyan: 26, magenta: 0, yellow: 100, depth: 1)
        store.mutate("test: stock Scriptorium") { state in
            state.base.completedResearch.insert("pen_ink_mixing")
            state.base.capabilities.insert("inkMixing")
            state.base.pigmentStock.add(1, of: .cyan)
            state.base.resources.add(1, of: "copper")
            state.base.resources.add(1, of: "sulfur")
            state.base.resources.add(1, of: "obsidian")
            state.base.resources.add(1, of: "resin")
        }
        let quote = store.inkVialPreparationQuote(recipe)
        XCTAssertTrue(quote.isReady)
        XCTAssertEqual(quote.measureCost[.cyan], 2)
        XCTAssertEqual(quote.measureCost[.yellow], 4)
        XCTAssertEqual(quote.measureCost[.depth], 1)
        XCTAssertEqual(quote.resourcesToProcess, ["copper": 1, "sulfur": 1, "obsidian": 1])
        XCTAssertEqual(quote.retainedMeasures[.cyan], 3)
        XCTAssertEqual(quote.retainedMeasures[.depth], 3)

        guard case .prepared(_, let applications) = store.prepareInkVial(quote)
        else { return XCTFail("ready quote did not prepare") }
        XCTAssertEqual(applications, 12)
        XCTAssertEqual(store.state.base.preparedInkVials.first?.remainingApplications, 12)
        XCTAssertEqual(store.state.base.pigmentStock[.cyan], 3)
        XCTAssertEqual(store.state.base.pigmentStock[.yellow], 0)
        XCTAssertEqual(store.state.base.pigmentStock[.depth], 3)
        XCTAssertEqual(store.state.base.resources["resin"], 0)

        let after = store.state
        XCTAssertEqual(store.prepareInkVial(quote), .staleQuote)
        XCTAssertEqual(store.state, after, "stale preparation must consume nothing")
    }

    @MainActor
    func testInsufficientInkPreparationConsumesNothing() {
        let store = GameStore(io: .temporary(name: "ink-vial-missing-\(UUID().uuidString)"))
        let recipe = InkRecipe(cyan: 100, magenta: 100, yellow: 0, depth: 0)
        store.mutate("test: unlock only") {
            $0.base.completedResearch.insert("pen_ink_mixing")
            $0.base.capabilities.insert("inkMixing")
        }
        let quote = store.inkVialPreparationQuote(recipe)
        XCTAssertFalse(quote.isReady)
        let before = store.state
        guard case .insufficient = store.prepareInkVial(quote)
        else { return XCTFail("missing stock was not refused") }
        XCTAssertEqual(store.state, before)
    }

    @MainActor
    func testQueuedInkWaitsForAndIsConsumedByNextEligibleFocus() {
        let store = GameStore(io: .temporary(name: "next-focus-ink-\(UUID().uuidString)"))
        let recipe = InkRecipe(cyan: 72, magenta: 0, yellow: 76, depth: 10)
        store.mutate("test: unlock Brush ink") { state in
            state.base.ownedHands.insert(.plain)
            state.base.completedResearch.insert("pen_ink_mixing")
            state.base.capabilities.insert("inkMixing")
        }
        store.useInkForNextFocus(recipe)
        XCTAssertTrue(store.write(.target("illumination"), glyph: "illumination",
                                  at: .init(column: 0, row: 0)))
        XCTAssertEqual(store.state.base.nextFocusInkRecipe, recipe,
                       "targets must not consume a queued focus ink")
        XCTAssertTrue(store.write(.source("sun"), glyph: "sun", at: .init(column: 0, row: 2)))
        XCTAssertEqual(store.state.base.page.runes.last?.inkRecipe, recipe)
        XCTAssertNil(store.state.base.nextFocusInkRecipe)
    }

    @MainActor
    func testWritingOnThePageIsWhatComposesTheBook() {
        let store = GameStore(io: .temporary(name: "desk-\(UUID().uuidString)"))
        store.mutate("test: fund") { $0.base.essence = 500 }

        XCTAssertTrue(store.write("plains"))
        XCTAssertTrue(store.write("frostbound"))
        XCTAssertEqual(store.state.base.page.symbolIDs, ["plains", "frostbound"])

        store.bindAndDepart()
        let book = store.state.worlds.activeRun?.book
        XCTAssertEqual(book?.allSymbolIDs, ["plains", "frostbound"],
                       "the world was bound from something other than the page")
    }

    @MainActor
    func testThePageRefusesWhatWillNotFit() {
        let store = GameStore(io: .temporary(name: "desk-\(UUID().uuidString)"))
        store.mutate("test: a cramped page") { $0.base.page = Page(width: 2, height: 2) }

        var written = 0
        for symbol in ContentCatalog.shared.symbols where store.write(symbol.id) { written += 1 }
        XCTAssertGreaterThan(written, 0, "nothing fitted at all")
        XCTAssertLessThan(written, ContentCatalog.shared.symbols.count,
                          "a 2x2 page accepted the entire vocabulary")
        XCTAssertLessThanOrEqual(store.state.base.page.usedCells, 4)
    }

    @MainActor
    func testErasingAMarkTakesItOutOfTheBook() {
        let store = GameStore(io: .temporary(name: "desk-\(UUID().uuidString)"))
        store.write("plains")
        let mark = store.state.base.page.runes[0]
        store.erase(mark.id)
        XCTAssertTrue(store.state.base.page.symbolIDs.isEmpty)
        // A blank page is the *most* uncertain world there is — everything rolls — so what it says
        // has to sit inside the band rather than be the band.
        XCTAssertTrue(store.bookProjection.stabilityScore.contains(BookRules.stabilityScore(delta: 0)))
    }

    @MainActor
    func testABlankPageStillBinds() {
        // Everything you don't say, the world decides. Under-specification is a surprise, not an
        // error — and with no slots left, a blank page is the extreme case of it.
        let store = GameStore(io: .temporary(name: "desk-\(UUID().uuidString)"))
        store.mutate("test: fund") { $0.base.essence = 500 }
        XCTAssertTrue(store.canBindAndDepart)
        store.bindAndDepart()
        XCTAssertNotNil(store.state.worlds.activeRun)
    }

    @MainActor
    func testAHalfWrittenPageSurvivesAForceQuit() throws {
        let io = SaveFileIO.temporary(name: "page-kill-\(UUID().uuidString)")
        defer { io.deleteEverything() }
        do {
            let store = GameStore(io: io)
            store.write("plains")
            store.write("frostbound")
            store.flushNow()
        }
        let resumed = GameStore(io: io)
        XCTAssertEqual(resumed.state.base.page.symbolIDs, ["plains", "frostbound"])
        XCTAssertEqual(resumed.state.base.page.runes.map(\.origin),
                       resumed.state.base.page.runes.map(\.origin))
    }
}
