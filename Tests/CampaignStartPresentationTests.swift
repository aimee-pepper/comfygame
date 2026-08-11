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
        XCTAssertEqual(CampaignStartPresentation.deletionTitle(for: campaign),
                       "Delete “Aimee’s no-rune test” · \(campaign.bookplateLabel)?")
    }

    func testStableIDNotDisplayNameDistinguishesCampaigns() {
        let first = slot(name: "Test", date: 10, health: .valid)
        let second = slot(name: "Test", date: 20, health: .valid)
        XCTAssertNotEqual(first.id, second.id)
        XCTAssertEqual(CampaignStartPresentation(slots: [first, second]).slots.count, 2)
    }

    func testAccessibilityTextForcesSingleColumnCards() {
        XCTAssertFalse(CampaignStartLayoutPolicy.usesSingleColumn(dynamicTypeSize: .xxxLarge))
        XCTAssertTrue(CampaignStartLayoutPolicy.usesSingleColumn(dynamicTypeSize: .accessibility1))
        XCTAssertTrue(CampaignStartLayoutPolicy.usesSingleColumn(dynamicTypeSize: .accessibility5))
        XCTAssertEqual(CampaignStartLayoutPolicy.compactCardMinimumWidth, 156)
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
        XCTAssertTrue(corrupt.name.hasPrefix("Damaged campaign · Bookplate "))
        XCTAssertFalse(corrupt.hasKnownMetadata)
        XCTAssertNil(corrupt.debugVersion)
        XCTAssertTrue(future.name.hasPrefix("Campaign · Bookplate "))
        XCTAssertFalse(future.name.contains("Damaged"))
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
