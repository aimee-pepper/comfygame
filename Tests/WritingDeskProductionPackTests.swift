import Foundation
import XCTest
@testable import Bookbinder

final class WritingDeskProductionPackTests: XCTestCase {
    private var packRoot: URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("AssetLab/integration/writing-desk-production-pack-v1")
    }

    private func mark(key: String, hand: Hand, shape: String, cells: [PageCell],
                      kind: WritingDeskVisibleMark.AuthoredKind = .compound) -> WritingDeskVisibleMark {
        .init(rendererAssetKey: key,
              visualRoute: key.hasPrefix("personal-compound-") ? .personalCompoundCompatibility : .authored(kind),
              id: .init(rawValue: 1), hand: hand,
              origin: .init(column: 0, row: 0), shapeID: shape, cells: cells,
              inkRecipe: nil, displayName: "visible", accessibilityName: "visible", isReadable: true)
    }

    func testConstructionDoesNoIOAndOpenReadsOnlyManifest() throws {
        final class Reads: @unchecked Sendable { var urls: [URL] = [] }
        let reads = Reads()
        let pack = WritingDeskProductionPack(rootURL: packRoot) { url in
            reads.urls.append(url); return try Data(contentsOf: url)
        }
        XCTAssertTrue(reads.urls.isEmpty)
        try pack.open()
        XCTAssertEqual(reads.urls.map(\.lastPathComponent), ["manifest.json"])
    }

    func testRetainedAcceptedHashesCannotAuthorizeTamperedLookup() throws {
        let original = try String(contentsOf: packRoot.appendingPathComponent("manifest.json"),
                                  encoding: .utf8)
        let tampered = original.replacingOccurrences(of: "\"refined_dot\"", with: "\"forged_dot\"",
                                                       options: [], range: original.startIndex..<original.endIndex)
        let pack = WritingDeskProductionPack(rootURL: packRoot) { url in
            if url.lastPathComponent == "manifest.json" { return Data(tampered.utf8) }
            return try Data(contentsOf: url)
        }
        XCTAssertThrowsError(try pack.open()) {
            XCTAssertEqual($0 as? WritingDeskProductionPack.PackError, .invalidManifest)
        }
    }

    func testAuthoredMarksResolveExactlyAndPersonalCompoundsUseOnlyCompatibilityRoute() throws {
        let pack = WritingDeskProductionPack(rootURL: packRoot)
        XCTAssertEqual(try pack.route(for: mark(key: "archipelago", hand: .refined,
                                                shape: "refined_dot",
                                                cells: [.init(column: 0, row: 0)])),
                       .authored(key: "mark/compound/archipelago/fountain"))
        XCTAssertEqual(try pack.route(for: mark(key: "personal-compound-12", hand: .plain,
                                                shape: "anything",
                                                cells: [.init(column: 0, row: 0)])),
                       .compatibilityPersonalCompound)
        XCTAssertThrowsError(try pack.route(for: mark(key: "missing-authored", hand: .refined,
                                                       shape: "refined_dot",
                                                       cells: [.init(column: 0, row: 0)])))
        var forged = mark(key: "personal-compound-12", hand: .plain, shape: "anything",
                          cells: [.init(column: 0, row: 0)])
        forged.visualRoute = .authored(.compound)
        XCTAssertThrowsError(try pack.route(for: forged))
    }

    func testMarkFootprintNormalizesAbsoluteCellsAndRotationFailsClosed() throws {
        let pack = WritingDeskProductionPack(rootURL: packRoot)
        var translated = mark(key: "archipelago", hand: .refined, shape: "refined_dot",
                              cells: [.init(column: 4, row: 3)])
        translated.origin = .init(column: 4, row: 3)
        XCTAssertEqual(try pack.route(for: translated),
                       .authored(key: "mark/compound/archipelago/fountain"))
        translated.shapeID = "refined_dot@90"
        XCTAssertThrowsError(try pack.route(for: translated)) { error in
            XCTAssertEqual(error as? WritingDeskProductionPack.PackError,
                           .rotatedAuthoredShapeRequiresPack("refined_dot@90"))
        }
    }

    func testOnlyFiveToolInkCombinationsAreLegal() throws {
        let pack = WritingDeskProductionPack(rootURL: packRoot)
        XCTAssertEqual(try pack.toolStrip(hand: .crude, usesMixedInk: false),
                       "tool-strip/charcoal/ash")
        XCTAssertThrowsError(try pack.toolStrip(hand: .crude, usesMixedInk: true))
        XCTAssertEqual(try pack.toolStrip(hand: .plain, usesMixedInk: true),
                       "tool-strip/brush/mixed")
    }

    func testCardinalLinkUsesReadingOrderAndCoarsestHand() throws {
        let pack = WritingDeskProductionPack(rootURL: packRoot)
        let first = mark(key: "archipelago", hand: .refined, shape: "x", cells: [
            .init(column: 0, row: 0), .init(column: 1, row: 0), .init(column: 0, row: 1),
        ])
        let second = mark(key: "archipelago", hand: .crude, shape: "x", cells: [
            .init(column: 2, row: 0), .init(column: 1, row: 1),
        ])
        let placement = try pack.link(between: first, and: second)
        XCTAssertEqual(placement.key, "link/charcoal/horizontal")
        XCTAssertEqual(placement.orientation, .horizontal)
        XCTAssertEqual(placement.width, 28); XCTAssertEqual(placement.height, 5)
        XCTAssertEqual(placement.asset.width, 28); XCTAssertEqual(placement.asset.height, 5)
        XCTAssertThrowsError(try pack.link(
            between: mark(key: "a", hand: .plain, shape: "x", cells: [.init(column: 0, row: 0)]),
            and: mark(key: "b", hand: .plain, shape: "x", cells: [.init(column: 2, row: 2)])))
    }

    func testAssetReadIsHashCheckedAndCached() throws {
        let manifest = try JSONSerialization.jsonObject(
            with: Data(contentsOf: packRoot.appendingPathComponent("manifest.json"))) as! [String: Any]
        let row = (manifest["assets"] as! [[String: Any]])[0]
        let hash = row["sha256"] as! String
        final class Reads: @unchecked Sendable { var counts: [String: Int] = [:] }
        let reads = Reads()
        let pack = WritingDeskProductionPack(rootURL: packRoot) { url in
            reads.counts[url.path, default: 0] += 1; return try Data(contentsOf: url)
        }
        XCTAssertFalse(try pack.assetData(sha256: hash).isEmpty)
        XCTAssertFalse(try pack.assetData(sha256: hash).isEmpty)
        XCTAssertEqual(reads.counts[packRoot.appendingPathComponent("assets/\(hash).png").path], 1)
    }

    func testTintReplacesOnlyTintOwnedPixelsAndAshIsByteExact() throws {
        let base: [UInt8] = [10, 20, 30, 255, 40, 50, 60, 255]
        let mask: [UInt8] = [0, 0, 0, 255, 0, 0, 0, 0]
        XCTAssertEqual(try WritingDeskProductionPack.resolveTint(
            baseRGBA: base, tintMaskRGBA: mask, inkRGBA: nil), base)
        XCTAssertEqual(try WritingDeskProductionPack.resolveTint(
            baseRGBA: base, tintMaskRGBA: mask, inkRGBA: [1, 2, 3, 255]),
                       [1, 2, 3, 255, 40, 50, 60, 255])
    }

    func testTypedAdaptersResolveEveryRuntimeSurface() throws {
        let pack = WritingDeskProductionPack(rootURL: packRoot)
        let mark = try pack.markAssets(for: "mark/compound/archipelago/fountain")
        XCTAssertEqual(mark.rgba.width, 27); XCTAssertEqual(mark.tintMask.width, 27)
        XCTAssertEqual(try pack.overlayAsset(shapeID: "refined_dot", state: "selected").width, 27)
        XCTAssertEqual(try pack.vocabularyAsset(kind: "compound", id: "archipelago",
                                                 hand: .refined, state: "unknown").width, 52)
        XCTAssertEqual(try pack.cardAsset(kind: "collected", state: "ordinary").width, 82)
        XCTAssertEqual(try pack.toolStripAssets(hand: .plain, usesMixedInk: true).rgba.width, 172)
        let blank = try pack.blankPageSpec()
        XCTAssertEqual(blank.writingArea, .init(x: 5, y: 5, width: 162, height: 162))
        XCTAssertEqual(blank.socketSize, .init(width: 27, height: 27))
        XCTAssertEqual(try pack.unreadMarkerAsset().width, 9)
        XCTAssertEqual(try pack.toolAsset(hand: .crude).width, 20)
        let card = try pack.cardSpec(kind: "collected", state: "ordinary")
        XCTAssertEqual(card.thumbnailSocket, .init(x: 6, y: 7, width: 62, height: 62))
        XCTAssertEqual(card.sourceSize, .init(width: 172, height: 172))
        XCTAssertEqual(card.destinationSize, .init(width: 62, height: 62))
        XCTAssertEqual(try pack.popoverBody(rows: 3).rows, 3)
        XCTAssertEqual(try pack.popoverPointer(variant: "aboveLeft").width, 5)
        let strip = try pack.toolStripSpec(hand: .plain, usesMixedInk: true)
        XCTAssertEqual(strip.runtimeTextReserve, .init(x: 22, y: 2, width: 105, height: 18))
        XCTAssertEqual(strip.inkWellSocket, .init(x: 129, y: 2, width: 40, height: 18))
        XCTAssertThrowsError(try pack.overlayAsset(shapeID: "missing", state: "selected"))
        XCTAssertThrowsError(try pack.vocabularyAsset(kind: "compound", id: "missing",
                                                       hand: .plain, state: "known"))
    }

    func testManifestExhaustivelyAccountsForEveryProductionAsset() throws {
        let data = try Data(contentsOf: packRoot.appendingPathComponent("manifest.json"))
        let manifest = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let rows = manifest["assets"] as! [[String: Any]]
        XCTAssertEqual(rows.count, 2_146)
        XCTAssertEqual(Set(rows.compactMap { $0["sha256"] as? String }).count, 2_146)
        let disk = try FileManager.default.contentsOfDirectory(
            at: packRoot.appendingPathComponent("assets"), includingPropertiesForKeys: nil)
        XCTAssertEqual(Set(disk.map(\.lastPathComponent)),
                       Set(rows.compactMap { ($0["file"] as? String).map(URL.init(fileURLWithPath:))?.lastPathComponent }))
    }
}
