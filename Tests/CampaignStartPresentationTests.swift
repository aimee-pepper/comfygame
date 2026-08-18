import SwiftUI
import UIKit
import XCTest
@testable import Bookbinder

final class CampaignStartPresentationTests: XCTestCase {
    func testContinueSelectsMostRecentValidSlotAndIgnoresInvalidSlots() {
        let older = slot(name: "Old", date: 10, health: .valid)
        let newestCorrupt = slot(name: "Broken", date: 30,
                                 health: .corrupt(message: "Could not read this save."))
        let newer = slot(name: "Current", date: 20, health: .valid)

        let presentation = CampaignStartPresentation(slots: [older, newestCorrupt, newer])

        XCTAssertEqual(presentation.continueSlot?.id, newer.id)
        XCTAssertEqual(presentation.slots.map(\.id), [newestCorrupt.id, newer.id, older.id])
    }

    func testEmptyInstallationHasNoContinueCandidate() {
        let presentation = CampaignStartPresentation(slots: [])
        XCTAssertTrue(presentation.isEmpty)
        XCTAssertNil(presentation.continueSlot)
    }

    func testInstallationWithOnlyInvalidSlotsHasNoContinueCandidateButKeepsCards() {
        let corrupt = slot(name: "Recover Me", date: 10,
                           health: .corrupt(message: "Export this campaign for recovery."))
        let future = slot(name: "From Tomorrow", date: 20,
                          health: .futureIncompatible(message: "Update Bookbinder to load this."))

        let presentation = CampaignStartPresentation(slots: [corrupt, future])

        XCTAssertNil(presentation.continueSlot)
        XCTAssertEqual(presentation.slots.count, 2)
        XCTAssertFalse(corrupt.health.canLoad)
        XCTAssertNotNil(future.health.recoveryMessage)
    }

    func testDeleteConfirmationNamesExactCampaign() {
        let campaign = slot(name: "Aimee’s no-rune test", date: 10, health: .valid)
        let title = CampaignStartPresentation.deletionTitle(for: campaign)
        XCTAssertTrue(title.contains("Aimee’s no-rune test"))
        XCTAssertTrue(title.contains("Home"))
        XCTAssertFalse(title.contains(campaign.id.uuidString))
        XCTAssertFalse(title.contains("Bookplate"))
    }

    func testStableIDNotDisplayNameDistinguishesCampaigns() {
        let first = slot(name: "Test", date: 10, health: .valid)
        let second = slot(name: "Test", date: 20, health: .valid)
        XCTAssertNotEqual(first.id, second.id)
        XCTAssertEqual(CampaignStartPresentation(slots: [first, second]).slots.count, 2)
    }

    func testEnabledNewGameOwnsAnAccentOutlineInsteadOfLookingDisabled() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(contentsOf: root.appending(path: "Sources/Screens/CampaignStartView.swift"),
                                encoding: .utf8)
        let start = try XCTUnwrap(source.range(of: "struct CampaignStartPrimaryAction"))
        let end = try XCTUnwrap(source.range(of: "struct CampaignStartActionLabel",
                                             range: start.upperBound..<source.endIndex))
        let action = String(source[start.lowerBound..<end.lowerBound])

        XCTAssertTrue(action.contains("buttonStyle(.plain)"))
        XCTAssertTrue(action.contains("CampaignShelfPalette.pageHighlight"))
        XCTAssertTrue(action.contains("Rectangle()"))
        XCTAssertTrue(action.contains("CampaignShelfPalette.shelf"))
        XCTAssertFalse(action.contains("Capsule()"))
        XCTAssertFalse(action.contains(".disabled("))
    }

    func testOrdinaryPrimaryActionsUseTheWholeAvailableRow() throws {
        XCTAssertEqual(
            CampaignStartLayoutPolicy.ordinaryPrimaryActionColumnCount(hasContinue: false),
            1,
            "A fresh installation's only action must not be stranded in half a row."
        )
        XCTAssertEqual(
            CampaignStartLayoutPolicy.ordinaryPrimaryActionColumnCount(hasContinue: true),
            2,
            "Continue and New Game should share two equal ordinary-phone columns."
        )

        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(contentsOf: root.appending(path: "Sources/Screens/CampaignStartView.swift"),
                                encoding: .utf8)
        XCTAssertTrue(source.contains("LazyVGrid(columns: ordinaryPrimaryActionColumns"))
        XCTAssertFalse(source.contains("HStack(spacing: 10) { primaryActionButtons }"))
    }

    func testAccessibilityTextForcesSingleColumnCards() {
        XCTAssertFalse(CampaignStartLayoutPolicy.usesSingleColumn(dynamicTypeSize: .xxxLarge))
        XCTAssertTrue(CampaignStartLayoutPolicy.usesSingleColumn(dynamicTypeSize: .accessibility1))
        XCTAssertTrue(CampaignStartLayoutPolicy.usesSingleColumn(dynamicTypeSize: .accessibility5))
    }

    func testEightOrdinarySlotsUseACompactTwoByFourShelf() {
        XCTAssertEqual(CampaignStartLayoutPolicy.ordinarySlotColumnCount, 2)
        XCTAssertEqual(CampaignStartLayoutPolicy.ordinarySlotRowCount(slotCount: 0), 0)
        XCTAssertEqual(CampaignStartLayoutPolicy.ordinarySlotRowCount(slotCount: 1), 1)
        XCTAssertEqual(CampaignStartLayoutPolicy.ordinarySlotRowCount(slotCount: 8), 4)
        XCTAssertGreaterThanOrEqual(CampaignStartLayoutPolicy.ordinarySlotCardMinimumHeight, 44)

        let shelfHeight =
            CGFloat(CampaignStartLayoutPolicy.ordinarySlotRowCount(slotCount: 8))
            * CampaignStartLayoutPolicy.ordinarySlotCardMinimumHeight
            + 30 // three ten-point row gutters
        XCTAssertLessThanOrEqual(shelfHeight, 370,
                                 "Eight slots must leave ordinary-phone room for title and actions.")
    }

    func testOrdinaryCampaignSurfaceIsStaticWhileAccessibilityRetainsFallbackScrolling() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(contentsOf: root.appending(path: "Sources/Screens/CampaignStartView.swift"),
                                encoding: .utf8)
        let bodyStart = try XCTUnwrap(source.range(of: "var body: some View {"))
        let titleStart = try XCTUnwrap(source.range(of: "private var title:",
                                                    range: bodyStart.upperBound..<source.endIndex))
        let body = String(source[bodyStart.lowerBound..<titleStart.lowerBound])

        XCTAssertTrue(body.contains("if dynamicTypeSize.isAccessibilitySize"))
        XCTAssertTrue(body.contains("ScrollView { campaignContents(compactSlots: false)"))
        XCTAssertTrue(body.contains("campaignContents(compactSlots: true)"))
        XCTAssertFalse(body.contains("ScrollView { campaignContents(compactSlots: true)"))
    }

    func testCompactSlotUsesTheWholeCardForLoadAndLongPressForDetails() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(contentsOf: root.appending(path: "Sources/Screens/CampaignStartView.swift"),
                                encoding: .utf8)
        let start = try XCTUnwrap(source.range(of: "private var compactBody"))
        let end = try XCTUnwrap(source.range(of: "private var expandedBody", range: start.upperBound..<source.endIndex))
        let compact = String(source[start.lowerBound..<end.lowerBound])

        XCTAssertTrue(compact.contains("Button(action: slot.health.canLoad ? onLoad : onDetails)"))
        XCTAssertTrue(compact.contains(".contentShape(Rectangle())"))
        XCTAssertTrue(compact.contains(".contextMenu"))
        XCTAssertTrue(compact.contains("Button(\"Details\", systemImage: \"info.circle\", action: onDetails)"))
        XCTAssertTrue(compact.contains(".accessibilityAction(named: \"Details\", onDetails)"))
        XCTAssertFalse(compact.contains("Button(\"Load\""))
        XCTAssertFalse(compact.contains(".buttonStyle(.borderedProminent)"))
        XCTAssertTrue(compact.contains("CampaignShelfPalette.cover(for: slot.id)"))
        XCTAssertTrue(compact.contains("Rectangle().stroke(CampaignShelfPalette.shelf"))
    }

    func testCompactSlotRestoresProgressGraphicLevelAndLastPlayedWithoutLoosePadding() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(contentsOf: root.appending(path: "Sources/Screens/CampaignStartView.swift"),
                                encoding: .utf8)
        let start = try XCTUnwrap(source.range(of: "private var compactBody"))
        let end = try XCTUnwrap(source.range(of: "private var expandedBody",
                                             range: start.upperBound..<source.endIndex))
        let compact = String(source[start.lowerBound..<end.lowerBound])

        XCTAssertTrue(compact.contains("CampaignBookplateMotif"))
        XCTAssertTrue(compact.contains("Level \\(slot.binderLevel)"))
        XCTAssertTrue(compact.contains("slot.lastPlayed.formatted(date: .abbreviated, time: .shortened)"))
        XCTAssertTrue(compact.contains(".padding(.horizontal, 7)"))
        XCTAssertTrue(compact.contains(".padding(.vertical, 5)"))
        XCTAssertFalse(compact.contains(".padding(14)"))
        XCTAssertFalse(compact.contains("HStack(spacing: 4) {\n                if slot.health.canLoad"))
    }

    func testCompactBookCardsExposeTheApprovedCampaignTruthWithoutAnActionRail() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(contentsOf: root.appending(path: "Sources/Screens/CampaignStartView.swift"),
                                encoding: .utf8)
        let start = try XCTUnwrap(source.range(of: "private var compactBody"))
        let end = try XCTUnwrap(source.range(of: "private var expandedBody",
                                             range: start.upperBound..<source.endIndex))
        let compact = String(source[start.lowerBound..<end.lowerBound])

        XCTAssertTrue(compact.contains("CampaignSlotStatusBadge(slot: slot)"))
        XCTAssertTrue(compact.contains("CampaignShelfProgress.volumeLabel(for: slot.progressBookCount)"))
        XCTAssertTrue(compact.contains("Text(slot.location)"))
        XCTAssertTrue(compact.contains("slot.lastPlayed.formatted(date: .abbreviated, time: .shortened)"))
        XCTAssertTrue(compact.contains("if let debugVersion = slot.debugVersion"))
        XCTAssertFalse(compact.contains("slot.progression"),
                       "The compact shelf must not squeeze paragraph-length progression prose into a card.")
        XCTAssertTrue(compact.contains(".contextMenu"))
        XCTAssertTrue(compact.contains("Button(\"Details\", systemImage: \"info.circle\""),
                      "Details must remain available through the approved long-press menu.")
        XCTAssertFalse(compact.contains(".buttonStyle(.bordered)"),
                       "The compact card must not grow a permanent Details action rail.")
    }

    func testVolumeLabelsRemainTruthfulForOneAndManyBooks() {
        XCTAssertEqual(CampaignShelfProgress.volumeLabel(for: 1), "1 volume")
        XCTAssertEqual(CampaignShelfProgress.volumeLabel(for: 7), "7 volumes")
    }

    @MainActor
    func testPrimaryCampaignActionsRenderAtEqualSizeNormallyAndAtAccessibilityText() {
        for dynamicTypeSize in [DynamicTypeSize.large, .accessibility3] {
            let continueSize = renderedActionLabelSize(
                title: "Continue", subtitle: "A campaign with a longer name",
                icon: "book.pages.fill",
                dynamicTypeSize: dynamicTypeSize
            )
            let createSize = renderedActionLabelSize(
                title: "New Game", subtitle: "Create a separate campaign",
                icon: "plus.rectangle.on.folder",
                dynamicTypeSize: dynamicTypeSize
            )

            XCTAssertEqual(continueSize.width, createSize.width, accuracy: 0.5)
            XCTAssertEqual(continueSize.height, createSize.height, accuracy: 0.5)
            XCTAssertEqual(continueSize.height,
                           CampaignStartLayoutPolicy.primaryActionLabelHeight(
                               dynamicTypeSize: dynamicTypeSize
                           ), accuracy: 0.5)
        }
    }

    @MainActor
    func testStyledPrimaryCampaignButtonsHaveEqualRenderedBounds() throws {
        for dynamicTypeSize in [DynamicTypeSize.large, .accessibility3] {
            let continueSize = renderedPrimaryActionSize(
                title: "Continue", subtitle: "The deliberately long winter campaign",
                icon: "book.pages.fill", emphasized: true, dynamicTypeSize: dynamicTypeSize)
            let newSize = renderedPrimaryActionSize(
                title: "New Game", subtitle: "Create a separate campaign",
                icon: "plus.rectangle.on.folder", emphasized: false,
                dynamicTypeSize: dynamicTypeSize)
            XCTAssertEqual(continueSize.width, newSize.width, accuracy: 0.5)
            XCTAssertEqual(continueSize.height, newSize.height, accuracy: 0.5)
        }
    }

    @MainActor
    private func renderedActionLabelSize(title: String, subtitle: String, icon: String,
                                         dynamicTypeSize: DynamicTypeSize) -> CGSize {
        let controller = UIHostingController(rootView:
            CampaignStartActionLabel(title: title, subtitle: subtitle,
                                     icon: icon)
                .environment(\.dynamicTypeSize, dynamicTypeSize)
                .frame(width: 164)
        )
        return controller.sizeThatFits(in: CGSize(width: 164, height: 200))
    }

    @MainActor
    private func renderedPrimaryActionSize(title: String, subtitle: String, icon: String,
                                           emphasized: Bool,
                                           dynamicTypeSize: DynamicTypeSize) -> CGSize {
        let controller = UIHostingController(rootView:
            CampaignStartPrimaryAction(title: title, subtitle: subtitle, icon: icon,
                                       emphasized: emphasized, identifier: "fixture", action: {})
                .environment(\.dynamicTypeSize, dynamicTypeSize)
                .frame(width: dynamicTypeSize.isAccessibilitySize ? 361 : 164)
        )
        return controller.sizeThatFits(in: CGSize(width: 361, height: 200))
    }

    func testCampaignShelfAddsBooksAsDurableProgressGrowsAndCapsAtCardWidth() {
        let early = GameState.newGame()
        var progressed = early
        progressed.reality.library.foundTravellers = Set(
            ContentCatalog.shared.travellers.prefix(6).map(\.id)
        )
        progressed.reality.library.foundPages = Array(
            ContentCatalog.shared.diaryPages.prefix(36).map(\.id)
        )
        progressed.base.completedResearch = Set(
            ContentCatalog.shared.researchNodes.prefix(12).map(\.id)
        )

        XCTAssertGreaterThan(CampaignShelfProgress.bookCount(for: progressed),
                             CampaignShelfProgress.bookCount(for: early))
        XCTAssertEqual(CampaignShelfProgress.bookCount(for: progressed),
                       CampaignShelfProgress.maximumBooks)
    }

    func testSlotSummaryUsesPersistedShelfCountAndInvalidSlotInventsNone() {
        var state = GameState.newGame()
        state.reality.library.foundPages = Array(ContentCatalog.shared.diaryPages.prefix(12).map(\.id))
        let id = SaveSlotID()
        let metadata = SaveSlotMetadata.make(id: id, name: "Growing shelf", state: state,
                                             createdAt: .distantPast, lastPlayedAt: .distantFuture)
        let valid = CampaignSlotSummary(descriptor: SaveSlotDescriptor(
            id: id, metadata: metadata, validity: .valid))
        let corrupt = CampaignSlotSummary(descriptor: SaveSlotDescriptor(
            id: SaveSlotID(), metadata: nil, validity: .corrupt(reason: "Unreadable")))

        XCTAssertEqual(valid.progressBookCount, metadata.progressBookCount)
        XCTAssertGreaterThan(valid.progressBookCount, 0)
        XCTAssertEqual(corrupt.progressBookCount, 0)
    }

    func testPersistenceDescriptorMapsFutureAndCorruptSlotsWithoutHidingThem() {
        let futureID = SaveSlotID()
        let future = CampaignSlotSummary(descriptor: SaveSlotDescriptor(
            id: futureID, metadata: nil, validity: .futureIncompatible(schemaVersion: 99)))
        XCTAssertEqual(future.id, futureID.rawValue)
        XCTAssertFalse(future.health.canLoad)
        XCTAssertTrue(future.health.recoveryMessage?.contains("newer") == true)

        let corruptID = SaveSlotID()
        let corrupt = CampaignSlotSummary(descriptor: SaveSlotDescriptor(
            id: corruptID, metadata: nil, validity: .corrupt(reason: "Unreadable envelope")))
        XCTAssertEqual(corrupt.id, corruptID.rawValue)
        XCTAssertEqual(corrupt.health.recoveryMessage, "Unreadable envelope")
        XCTAssertEqual(corrupt.name, "Campaign needing recovery")
        XCTAssertFalse(corrupt.hasKnownMetadata)
        XCTAssertNil(corrupt.debugVersion)
        XCTAssertEqual(future.name, "Campaign from a newer version")
    }

    private func slot(name: String, date: TimeInterval,
                      health: CampaignSlotHealth) -> CampaignSlotSummary {
        CampaignSlotSummary(id: UUID(), name: name,
                            lastPlayed: Date(timeIntervalSince1970: date),
                            binderLevel: 4, location: "Home",
                            progression: "3 travellers · 2 stations",
                            health: health, debugVersion: "build 1 · schema 15")
    }
}
