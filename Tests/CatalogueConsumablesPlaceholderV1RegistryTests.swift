import Foundation
import XCTest
@testable import Bookbinder

final class CatalogueConsumablesPlaceholderV1RegistryTests: XCTestCase {
    private let expectedIdentifiedIDs: Set<String> = [
        "salve_lesser", "salve", "salve_greater", "draught_clearing",
        "draught_quenching", "antidote_broad", "stonebark_tonic", "venom",
        "firebrand", "briar_oil", "flashsalt", "solvent", "lure", "stillwater",
        "waystone", "torch", "farsight_draught",
    ]

    func testFrozenManifestMetadataAndExactLiveCataloguePartition() throws {
        let registry = CatalogueConsumablesPlaceholderV1Registry()
        XCTAssertEqual(registry.manifestSHA256,
                       "70a6d7c6c71f93c9c8488969439aed051e35a47a3579d3c219d556c160fee4a9")
        XCTAssertEqual(CatalogueConsumablesPlaceholderV1Registry.manifestFileSHA256,
                       "162179701e16b2406ad1ffff7a4c0e8514bc19e862adf17c5ccc290aaae5c19f")
        XCTAssertEqual(registry.pipelineVersion,
                       "catalogue-consumables-functional-placeholder-1.0.0")
        XCTAssertEqual(registry.canvasWidth, 32)
        XCTAssertEqual(registry.canvasHeight, 32)
        XCTAssertEqual(Set(registry.assets.map(\.key.catalogueID)), expectedIdentifiedIDs)
        XCTAssertEqual(Set(CatalogueConsumablesPlaceholderV1Registry
            .assetCanonicalCommandSHA256ByID.keys), expectedIdentifiedIDs)
        XCTAssertEqual(registry.assets.count, 17)
        XCTAssertEqual(registry.explicitlyUnsupportedIDs.count, 61)

        let liveIDs = Set(ContentCatalog.shared.items.map(\.id.rawValue))
        XCTAssertEqual(liveIDs.count, 78)
        XCTAssertNoThrow(try NativeVisualRuntime.Pack(
            registry: registry,
            requiredCatalogueIDs: liveIDs
        ))
    }

    func testEveryFrozenCommandAndDecodedHashValidates() throws {
        let registry = CatalogueConsumablesPlaceholderV1Registry()
        for entry in registry.assets {
            XCTAssertTrue(entry.key.identified)
            XCTAssertNoThrow(try NativeVisualRuntime.validate(entry.asset), entry.key.catalogueID)
        }

        let entriesByID = Dictionary(uniqueKeysWithValues: registry.assets.map {
            ($0.key.catalogueID, $0.asset)
        })
        let manifestEvidence = expectedIdentifiedIDs.sorted().map { id in
            let canonicalCommandHash = CatalogueConsumablesPlaceholderV1Registry
                .assetCanonicalCommandSHA256ByID[id]!
            return "\(id)|\(canonicalCommandHash)|\(entriesByID[id]!.decodedRGBASHA256)\n"
        }.joined()
        XCTAssertEqual(
            NativeVisualRuntime.sha256(Data(manifestEvidence.utf8)),
            "a2b36eed3a7ce4473c005790db10900550b73469a167f2286ad8e7f92cc45703"
        )
    }

    func testLiveAdapterUsesExactIdentifiedVariantAndNeverBorrowsFallbacks() throws {
        let adapter = CatalogueItemVisualAdapter.live()
        for rawID in expectedIdentifiedIDs {
            let id = ItemID(rawValue: rawID)
            XCTAssertNotNil(adapter.asset(for: id, identified: true), rawID)
            XCTAssertNil(adapter.asset(for: id, identified: false), rawID)
        }
        XCTAssertNil(adapter.asset(for: "cache_key", identified: true))
        XCTAssertNil(adapter.asset(for: "future_unknown_item", identified: true))
    }

    func testRemainingConsumableSurfacesPassStableCatalogueIdentityToSharedRenderer() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let apothecary = try String(contentsOf: root.appending(path: "Sources/Screens/ApothecaryView.swift"),
                                     encoding: .utf8)
        let encounter = try String(contentsOf: root.appending(path: "Sources/Screens/EncounterView.swift"),
                                   encoding: .utf8)
        let world = try String(contentsOf: root.appending(path: "Sources/Screens/WorldView.swift"),
                               encoding: .utf8)

        XCTAssertTrue(apothecary.contains("CatalogueItemPixelIdentity("))
        XCTAssertTrue(apothecary.contains("itemID: recipe.output"),
                      "Apothecary recipes must resolve by exact output catalogue identity")
        XCTAssertTrue(encounter.contains("catalogueID: stack.catalogID"),
                      "Combat remedy tiles must preserve the carried stack catalogue identity")
        XCTAssertTrue(encounter.contains("identified: stack.identified"),
                      "Combat remedy tiles must preserve disclosure state")

        let fieldKitStart = try XCTUnwrap(world.range(of: "private struct FieldKitSheet"))
        let fieldKit = world[fieldKitStart.lowerBound...]
        XCTAssertTrue(fieldKit.contains("CatalogueItemPixelIdentity("))
        XCTAssertTrue(fieldKit.contains("itemID: stack.catalogID"),
                      "Field Kit must preserve the carried stack catalogue identity")
        XCTAssertTrue(fieldKit.contains("identified: stack.identified"),
                      "Field Kit presentation must preserve disclosure state")
        XCTAssertFalse(fieldKit.contains("LabeledRow(icon: ContentCatalog.shared.item(stack.catalogID)?.icon"),
                       "A carried item body must not bypass the shared catalogue renderer")
    }
}
