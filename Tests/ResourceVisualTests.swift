import CryptoKit
import XCTest
@testable import Bookbinder

@MainActor
final class ResourceVisualTests: XCTestCase {
    private func sha(_ bytes: [UInt8]) -> String {
        SHA256.hash(data: Data(bytes)).map { String(format: "%02x", $0) }.joined()
    }

    func testResourceBodiesAndSheenMatchFrozenV06Vectors() {
        let vectors: [(ResourceID, String, [String])] = [
            ("ore", "58e9a10175aaf6be5ae765a321ae8b881aa41610f401db8c3de8a508c4097549",
             ["5151826892cbd7996cb581080068571b25749c9037b72178d40056e24df8e1b9",
              "d86d38ae5318233d50c628b4492ff99ad492bf83778d5338146916ea64b6dead"]),
            ("fiber", "afbcd81951626e8d5f1224b72a0fe1d383ad74b4de5272728fe45509ecc5b6c0",
             ["c4f0566017591b35869fc5f3fb9eaf07118d54ca59c4cf0384d001e7ce946dc6",
              "ec06836ba6a6cb12228a243ee787ad11c3549c0adfcdeb2a9d12dabdc6ba0e33"]),
            ("mercury", "e09e33c43a46bf74f2907e4b4f0723a2a598d0e9473b2ae75e90f5f1711940a6",
             ["cd83e1f078a7caf5c0d6b7a5da05f8562fe9a5cbd4ab3e9e4d3db418f5bdbbff",
              "20a19f234a2844c4f146fb1840118a412ca99b5d5703d39925c76970f3a0f933"]),
            ("rift_glass", "5452c20876c54a7ac6f26c5739b4363a1fc2e227a632bbc0a098517db05d13ef",
             ["68595c36f1ebaab74be65366d9bf23878eed294f54b2d3af5e8ca33379769626",
              "d0e81929a0e445dda3917f9ebacd3d25c63ade081221d6a5eac6f9d643b6b240"]),
            ("essence_raw", "41afa2d95a5ead684f5488c158b5dbe4fa83727839ada5253a4e12ba1ea5f14a",
             ["8501963a64b00daa8ed4b3a1a9249e3278bda6d28f70dbc8087beade1e247438",
              "4e25d1a55fd9c108f982fa3463a7a9b023ce7b2b7b7edd015851b1a5bd0f03e7"])
        ]
        for (id, body, frames) in vectors {
            XCTAssertEqual(sha(MapAssetTestSupport.resourcePixels(id)), body, id.rawValue)
            XCTAssertEqual(sha(MapAssetTestSupport.resourcePixels(id, frame: 0)), frames[0], id.rawValue)
            XCTAssertEqual(sha(MapAssetTestSupport.resourcePixels(id, frame: 1)), frames[1], id.rawValue)
        }
    }

    func testResourceSheenUsesFrozenPublicPhaseAndQuietTicks() {
        let phase = MapAssetTestSupport.resourceSheenPhase(
            mapSeed: 0, runIndex: 1, point: GridPoint(x: 4, y: 7))
        XCTAssertEqual(phase, 2_969_120_438)
        XCTAssertEqual((0..<8).map { MapAssetTestSupport.resourceSheenFrame(phase: phase, tick: $0) },
                       [nil, nil, nil, nil, 0, 1, 2, 3])
        XCTAssertEqual(MapAssetTestSupport.resourceSheenPhase(
            mapSeed: .max, runIndex: 22, point: GridPoint(x: -3, y: 91)), 3_224_285_105)
    }

    func testMoteHasNoWorldBodyAndAllResourceFamiliesHaveDistinctBodies() {
        XCTAssertTrue(MapAssetTestSupport.resourcePixels("mote").allSatisfy { $0 == 0 })
        let ids = ContentCatalog.shared.resources.map(\.id).filter { $0 != "mote" }
        let hashes = ids.map { sha(MapAssetTestSupport.resourcePixels($0)) }
        XCTAssertEqual(Set(hashes).count, ids.count)
    }

    func testEveryResourceHasAnInventoryIdentityIncludingMote() {
        let ids = ContentCatalog.shared.resources.map(\.id)
        XCTAssertEqual(ids.count, 23)
        let pixels = ids.map { MapAssetTestSupport.inventoryResourcePixels($0) }
        XCTAssertTrue(pixels.allSatisfy { !$0.allSatisfy { $0 == 0 } })
        XCTAssertEqual(Set(pixels.map(sha)).count, ids.count)
        XCTAssertTrue(MapAssetTestSupport.resourcePixels("mote").allSatisfy { $0 == 0 },
                      "Mote remains inventory-only")
    }
}
