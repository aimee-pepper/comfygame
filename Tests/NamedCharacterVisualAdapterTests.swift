import Foundation
import XCTest
@testable import Bookbinder

final class NamedCharacterVisualAdapterTests: XCTestCase {
    private func manifestData() throws -> Data {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        return try Data(contentsOf: root
            .appendingPathComponent("AssetLab/integration/named-character-placeholders-v1/manifest.json"))
    }

    func testExactStableIdentityResolvesCameoAndEveryMapFacing() throws {
        let adapter = try NamedCharacterVisualAdapter.validated(manifestData: manifestData())

        for travellerID in NativeVisualRuntime.NamedCharacterPlaceholderPack
            .supportedTravellerIDs {
            let cameo = try XCTUnwrap(adapter.cameoAsset(for: travellerID))
            XCTAssertEqual(cameo.width, 16)
            XCTAssertEqual(cameo.height, 16)
            for facing in NativeVisualRuntime.MapFacing.allCases {
                let map = try XCTUnwrap(adapter.mapSpriteAsset(
                    for: travellerID, facing: facing))
                XCTAssertEqual(map.width, 16)
                XCTAssertEqual(map.height, 16)
            }
        }
    }

    func testIdentityAndProfileLookupFailClosedWithoutSubstitution() throws {
        let adapter = try NamedCharacterVisualAdapter.validated(manifestData: manifestData())
        XCTAssertNil(adapter.cameoAsset(for: "generated-person-1"))
        XCTAssertNil(adapter.mapSpriteAsset(for: "generated-person-1", facing: .north))
        XCTAssertNil(adapter.cameoAsset(for: "unknown"))

        let mara: TravellerID = "mara"
        XCTAssertNotEqual(adapter.cameoAsset(for: mara),
                          adapter.mapSpriteAsset(for: mara, facing: .north))
        XCTAssertNotEqual(adapter.mapSpriteAsset(for: mara, facing: .north),
                          adapter.mapSpriteAsset(for: mara, facing: .south))
    }

    func testNollIsPackCoverageOnlyAndFallbackConfigurationReturnsNil() throws {
        let adapter = try NamedCharacterVisualAdapter.validated(manifestData: manifestData())
        XCTAssertNotNil(adapter.cameoAsset(for: "noll"),
                        "The immutable pack covers Noll without changing catalogue state")

        let fallback: any NamedCharacterVisualProviding = NamedCharacterVisualAdapter.fallbackOnly
        XCTAssertNil(fallback.cameoAsset(for: "noll"))
        XCTAssertNil(fallback.mapSpriteAsset(for: "mara", facing: .west))
    }

    func testPartyAndLibraryPassOnlyStableTravellerIdentityToCompactCameo() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let party = try String(contentsOf: root.appending(path: "Sources/Screens/PartyRosterView.swift"),
                               encoding: .utf8)
        let library = try String(contentsOf: root.appending(path: "Sources/Screens/LibraryView.swift"),
                                 encoding: .utf8)
        let identity = try String(contentsOf: root.appending(path: "Sources/Screens/NamedCharacterPixelIdentity.swift"),
                                  encoding: .utf8)

        XCTAssertTrue(party.contains("NamedCharacterPixelIdentity("))
        XCTAssertTrue(party.contains("store.state.base.roster[index].traveller"),
                      "Party identity must come from the persisted named-traveller link")
        XCTAssertTrue(library.contains("travellerID: traveller.id"),
                      "Library People and diary authors must use stable catalogue identity")
        XCTAssertTrue(identity.contains("NamedCharacterVisualAdapter.live()"))
        XCTAssertTrue(identity.contains("Image(systemName: fallbackSystemIcon)"),
                      "Missing/generated identities must retain the visible SF fallback")
        XCTAssertFalse(identity.contains("calling"))
        XCTAssertTrue(party.contains("· Max HP \\(health(slot))"),
                      "Party cards must label the derived maximum as Max HP")
        XCTAssertFalse(party.contains("· HP \\(health(slot))"))
        XCTAssertFalse(party.contains("· Health \\(health(slot))"))
    }

    func testEncounterCompanionsUsePersistedNamedIdentityAndPreserveFallbacks() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let encounter = try String(contentsOf: root.appending(path: "Sources/Screens/EncounterView.swift"),
                                   encoding: .utf8)

        XCTAssertTrue(encounter.contains("NamedCharacterPixelIdentity("))
        XCTAssertTrue(encounter.contains("travellerID: store.state.base.roster[index].traveller"),
                      "Encounter identity must use the exact persisted named-traveller link")
        XCTAssertTrue(encounter.contains("travellerID: nil"),
                      "Binder must remain outside the named-traveller placeholder pack")
        XCTAssertTrue(encounter.contains("fallbackSystemIcon: icon"),
                      "Quill, generated, unknown, and unavailable identities retain their SF fallback")
        XCTAssertFalse(encounter.contains("travellerID: store.state.base.roster[index].calling"))
    }

    func testTravellerMeetingUsesExactMeetingIdentityAndPreservesFallback() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let meeting = try String(contentsOf: root.appending(path: "Sources/Screens/TravellerMeetingView.swift"),
                                 encoding: .utf8)

        XCTAssertTrue(meeting.contains("NamedCharacterPixelIdentity("))
        XCTAssertTrue(meeting.contains("travellerID: traveller.id"),
                      "Meeting identity must resolve from the exact encountered TravellerDef")
        XCTAssertTrue(meeting.contains("fallbackSystemIcon: traveller.icon"),
                      "Validation, missing-asset, and lookup failures retain the authored SF fallback")
        XCTAssertTrue(meeting.contains("Text(traveller.name)"),
                      "The visible authored identity must remain unchanged")
        XCTAssertFalse(meeting.contains("travellerID: traveller.calling"))
    }

    func testFirepitUsesPersistedCompanionIdentityAndPreservesFallback() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let firepit = try String(contentsOf: root.appending(path: "Sources/Screens/FirepitView.swift"),
                                 encoding: .utf8)

        XCTAssertTrue(firepit.contains("NamedCharacterPixelIdentity("))
        XCTAssertTrue(firepit.contains("travellerID: member.traveller"),
                      "Firepit identity must use the persisted roster member's TravellerID")
        XCTAssertTrue(firepit.contains("fallbackSystemIcon: member.icon"),
                      "Quill, generated, unknown, and unavailable identities retain their SF fallback")
        XCTAssertTrue(firepit.contains("Text(member.name)"),
                      "Existing visible companion names must remain unchanged")
        XCTAssertFalse(firepit.contains("travellerID: member.calling"))
    }

    func testFirepitAnnouncesCurrentPlacementStatusInsteadOfHidingIt() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let firepit = try String(contentsOf: root.appending(path: "Sources/Screens/FirepitView.swift"),
                                 encoding: .utf8)

        XCTAssertTrue(firepit.contains(
            ".accessibilityLabel(store.isComing(index) ? \"Coming with you\" : \"At Home\")"
        ))
        XCTAssertFalse(firepit.contains(
            "store.isComing(index) ? \"figure.walk.circle.fill\" : \"house.circle\")\n                    .foregroundStyle(.secondary)\n                    .accessibilityHidden(true)"
        ), "Placement state must not remain visual-only")
    }

    func testWorldHistoryUsesRecordedTravellerIdentityAndPreservesReceiptCopy() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let history = try String(contentsOf: root.appending(path: "Sources/Screens/WorldHistoryView.swift"),
                                 encoding: .utf8)

        XCTAssertTrue(history.contains("ForEach(world.travellersPresent, id: \\.self) { id in"),
                      "History must retain the stable recorded TravellerID at presentation time")
        XCTAssertTrue(history.contains("NamedCharacterPixelIdentity("))
        XCTAssertTrue(history.contains("travellerID: id"))
        XCTAssertTrue(history.contains("fallbackSystemIcon: \"figure.wave\""),
                      "Unknown, missing, and invalid assets retain the existing receipt fallback")
        XCTAssertTrue(history.contains("Text(person.name)"))
        XCTAssertTrue(history.contains("? \"with you\" : \"still there\""),
                      "Character pixels must not alter the saved-world receipt meaning")
    }

    func testEncounterTurnTextUsesExactNonQuillRosterName() {
        XCTAssertEqual(
            EncounterTurnText.format(
                current: .companion(1), encounterFinished: false,
                companionOverride: false, rosterNames: ["Mara", "Noll"]),
            "Noll is acting"
        )
        XCTAssertEqual(
            EncounterTurnText.format(
                current: .companion(1), encounterFinished: false,
                companionOverride: true, rosterNames: ["Mara", "Noll"]),
            "you're directing Noll"
        )
    }

    func testEncounterTurnTextUsesGenericFallbackForInvalidRosterIndex() {
        XCTAssertEqual(
            EncounterTurnText.format(
                current: .companion(9), encounterFinished: false,
                companionOverride: false, rosterNames: ["Mara"]),
            "Companion is acting"
        )
        XCTAssertEqual(
            EncounterTurnText.format(
                current: .companion(-1), encounterFinished: false,
                companionOverride: true, rosterNames: ["Mara"]),
            "you're directing Companion"
        )
    }

    func testBaseFoundationUsesExactBuilderIdentityAndPreservesStationPresentation() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let base = try String(contentsOf: root.appending(path: "Sources/Screens/BaseView.swift"),
                              encoding: .utf8)

        XCTAssertTrue(base.contains("let travellerID = station.builtBy"),
                      "Foundation builder identity must remain the exact stable TravellerID")
        XCTAssertTrue(base.contains("NamedCharacterPixelIdentity("))
        XCTAssertTrue(base.contains("travellerID: travellerID"))
        XCTAssertTrue(base.contains("fallbackSystemIcon: person.icon"),
                      "Unknown, missing, or invalid cameo assets retain the traveller's SF fallback")
        XCTAssertTrue(base.contains("Image(systemName: station.icon)"),
                      "Adding builder identity must not replace the station's own identity")
        XCTAssertTrue(base.contains("Text(\"\\(person.name), \\(person.calling)\")"))
    }

    func testAnchorageWorkerUsesPersistedCompanionIdentityAndPreservesAssignmentCopy() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let stations = try String(contentsOf: root.appending(path: "Sources/Screens/StationViews.swift"),
                                  encoding: .utf8)

        XCTAssertTrue(stations.contains("travellerID: worker.traveller"),
                      "Anchorage worker identity must come from the persisted roster member")
        XCTAssertTrue(stations.contains("fallbackSystemIcon: worker.icon"))
        XCTAssertTrue(stations.contains("Text(worker.name)"))
        XCTAssertTrue(stations.contains("Worldwork \\(worker.worldwork) · +\\(contribution)"),
                      "Character pixels must not alter assignment contribution copy")
        XCTAssertTrue(stations.contains("store.unassignCompanion(index, fromAnchoredRealm: realm.id)"))
    }

    func testEssenceSpringUnlearningUsesExactRosterIdentityButKeepsBinderSeparate() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let stations = try String(contentsOf: root.appending(path: "Sources/Screens/StationViews.swift"),
                                  encoding: .utf8)

        let start = try XCTUnwrap(stations.range(of: "struct EssenceSpringView: View"))
        let end = try XCTUnwrap(stations.range(of: "enum EssenceSpringTab", range: start.upperBound..<stations.endIndex))
        let unlearning = String(stations[start.lowerBound..<end.lowerBound])
        XCTAssertTrue(unlearning.contains("let person = store.state.base.roster[index]"))
        XCTAssertTrue(unlearning.contains("travellerID: person.traveller"))
        XCTAssertTrue(unlearning.contains("fallbackSystemIcon: person.icon"))
        XCTAssertTrue(unlearning.contains("Image(systemName: \"figure.stand\")"),
                      "Binder must remain outside the named-traveller pack")
        XCTAssertTrue(unlearning.contains("store.respec(member)"),
                      "Identity presentation must not change Unlearning behavior")
    }

    func testLibraryPersonDetailUsesExactTravellerCameoWithFallback() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let library = try String(contentsOf: root.appending(path: "Sources/Screens/LibraryView.swift"),
                                 encoding: .utf8)
        let detailStart = try XCTUnwrap(library.range(of: "private struct LibraryTravellerView"))
        let detail = library[detailStart.lowerBound...]

        XCTAssertTrue(detail.contains("NamedCharacterPixelIdentity("))
        XCTAssertTrue(detail.contains("travellerID: traveller.id"),
                      "Person detail must resolve the accepted cameo by stable TravellerID")
        XCTAssertTrue(detail.contains("fallbackSystemIcon: traveller.icon"),
                      "Missing or invalid cameo assets must preserve the prior SF Symbol fallback")
        XCTAssertTrue(detail.contains("LibraryPresentation.placementLabel"),
                      "Identity wiring must preserve the existing discovery-state copy")
    }

    func testBuiltBundleResourceBasenameRemainsHashValidated() throws {
        let source = try String(contentsOf: URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
            .appending(path: "Sources/VisualAdapters/NamedCharacterVisualAdapter.swift"),
                                encoding: .utf8)
        XCTAssertTrue(source.contains("[\"named-character-placeholders-v1\", \"manifest\"]"))
        XCTAssertTrue(source.contains("validated(manifestData: data)"),
                      "Neither bundle resource name may bypass immutable pack validation")
    }

    func testGearAnchoredPaneKeepsEquipVisibleAndComparesAgainstWornPiece() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let gear = try String(contentsOf: root.appending(path: "Sources/Screens/GearView.swift"),
                              encoding: .utf8)
        let party = try String(contentsOf: root.appending(path: "Sources/Screens/PartyRosterView.swift"),
                               encoding: .utf8)
        let detailStart = try XCTUnwrap(gear.range(of: "private struct GearOptionDetailPane"))
        let detail = String(gear[detailStart.lowerBound...])

        XCTAssertTrue(gear.contains("worn: worn"),
                      "The detail must receive the exact currently worn piece")
        XCTAssertTrue(gear.contains("You don't own another piece for this slot yet."),
                      "Empty equipment copy must not pluralize slot names as singular nouns")
        XCTAssertFalse(gear.contains("another \\(slot.displayName.lowercased())"))
        XCTAssertTrue(detail.contains("Text(\"Compared with worn\")"))
        XCTAssertTrue(detail.contains("comparisonRow(\"Worn now\""))
        XCTAssertTrue(party.contains("NavigationLink {"))
        XCTAssertTrue(party.contains("GearView(slot: gearSlot, member: slot)"))
        XCTAssertTrue(gear.contains("AnchoredItemDetailButton(item: option, selection: $selectedOption)"))
        XCTAssertFalse(party.contains(".presentationDetents"))
        XCTAssertFalse(party.contains(".presentationDragIndicator"))
        XCTAssertTrue(detail.contains("comparisonRow(\"This piece\""))
        XCTAssertTrue(detail.contains("ImprovementBadge(delta: delta, slot: slot)"))
        XCTAssertTrue(detail.contains("Button(\"Equip\")"))
        XCTAssertTrue(detail.contains(".frame(maxWidth: .infinity, minHeight: 44)"))

        XCTAssertFalse(detail.contains("ScrollView"),
                       "The item decision must not require a second scroll gesture")
        XCTAssertFalse(detail.contains("List {"),
                       "The item page must not recreate a full-screen settings list")
    }
}
