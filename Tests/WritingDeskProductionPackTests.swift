import Foundation
import XCTest
@testable import Bookbinder

final class WritingDeskProductionPackTests: XCTestCase {
    private var packRoot: URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("AssetLab/integration/writing-desk-production-pack-v1/runtime")
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
                       .authored(key: "mark/compound/archipelago/fountain/0"))
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

    func testMarkFootprintNormalizesAbsoluteCellsAndAllQuarterTurnsResolve() throws {
        let pack = WritingDeskProductionPack(rootURL: packRoot)
        var translated = mark(key: "archipelago", hand: .refined, shape: "refined_dot",
                              cells: [.init(column: 4, row: 3)])
        translated.origin = .init(column: 4, row: 3)
        XCTAssertEqual(try pack.route(for: translated),
                       .authored(key: "mark/compound/archipelago/fountain/0"))
        for (angle, cells) in [(90, [PageCell(column: 0, row: 0)]),
                               (180, [PageCell(column: 0, row: 0)]),
                               (270, [PageCell(column: 0, row: 0)])] {
            translated.shapeID = "refined_dot@\(angle)"; translated.cells = cells
            translated.origin = .init(column: 0, row: 0)
            XCTAssertEqual(try pack.route(for: translated),
                           .authored(key: "mark/compound/archipelago/fountain/\(angle)"))
        }
        for invalid in ["refined_dot@45", "refined_dot@", "refined_dot@90@180"] {
            translated.shapeID = invalid
            XCTAssertThrowsError(try pack.route(for: translated))
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
        let mark = try pack.markAssets(for: "mark/compound/archipelago/fountain/90")
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
        XCTAssertEqual(rows.count, 4_459)
        XCTAssertEqual(Set(rows.compactMap { $0["sha256"] as? String }).count, 4_459)
        let disk = try FileManager.default.contentsOfDirectory(
            at: packRoot.appendingPathComponent("assets"), includingPropertiesForKeys: nil)
        XCTAssertEqual(Set(disk.map(\.lastPathComponent)),
                       Set(rows.compactMap { ($0["file"] as? String).map(URL.init(fileURLWithPath:))?.lastPathComponent }))
    }

    func testEveryAuthoredRotationAndOverlayRoutesExactly() throws {
        let data = try Data(contentsOf: packRoot.appendingPathComponent("manifest.json"))
        let manifest = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let lookups = manifest["lookups"] as! [String: Any]
        let rows = lookups["marks"] as! [String: [String: Any]]
        let pack = WritingDeskProductionPack(rootURL: packRoot)
        XCTAssertEqual(rows.count, 1_296)
        for (key, row) in rows {
            let kind = WritingDeskVisibleMark.AuthoredKind(rawValue: row["kind"] as! String)!
            let hand: Hand = switch row["hand"] as! String {
            case "charcoal": .crude; case "brush": .plain; default: .refined
            }
            let origin = PageCell(column: 3, row: 4)
            let cells = (row["cells"] as! [[Int]]).map {
                PageCell(column: $0[0] + origin.column, row: $0[1] + origin.row)
            }
            let visible = WritingDeskVisibleMark(
                rendererAssetKey: row["id"] as! String, visualRoute: .authored(kind),
                id: .init(rawValue: 1), hand: hand, origin: origin,
                shapeID: row["shapeID"] as! String, cells: cells, inkRecipe: nil,
                displayName: "visible", accessibilityName: "visible", isReadable: true)
            XCTAssertEqual(try pack.route(for: visible), .authored(key: key))
            _ = try pack.markAssets(for: key)
        }
        let overlays = lookups["overlays"] as! [String: [String: Any]]
        XCTAssertEqual(overlays.count, 312)
        for row in overlays.values {
            _ = try pack.overlayAsset(shapeID: row["shapeID"] as! String,
                                      state: row["state"] as! String)
        }
    }

    func testBundleBoundaryIsOneRuntimeFolderAndExcludesEvidence() throws {
        let project = try String(contentsOf: packRoot
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Bookbinder.xcodeproj/project.pbxproj"), encoding: .utf8)
        XCTAssertEqual(project.components(separatedBy: "WritingDeskProductionPack-v1 in Resources").count - 1, 2)
        XCTAssertTrue(project.contains("lastKnownFileType = folder"))
        XCTAssertFalse(project.contains("writing-desk-production-pack-v1/evidence"))
    }

    func testBuiltProductContainsExactRuntimeSubdirectoryAndNoEvidence() throws {
        let root = Bundle.main.bundleURL.appendingPathComponent("runtime", isDirectory: true)
        XCTAssertTrue(FileManager.default.fileExists(atPath: root.appendingPathComponent("manifest.json").path))
        let pack = try WritingDeskProductionPack.bundled(in: .main)
        try pack.open()
        let contents = try FileManager.default.subpathsOfDirectory(atPath: Bundle.main.bundlePath)
        XCTAssertEqual(contents.filter { $0 == "runtime/manifest.json" }.count, 1)
        XCTAssertFalse(contents.contains { $0.lowercased().contains("evidence") })
        XCTAssertFalse(contents.contains { $0.contains("contact-sheet") })
    }

    func testBundledLocatorUsesExactPhysicalProductPathNotResourceIndex() throws {
        let source = try String(contentsOf: packRoot.deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Sources/VisualRuntime/WritingDeskProductionPack.swift"),
                                encoding: .utf8)
        XCTAssertTrue(source.contains("bundle.bundleURL.appendingPathComponent(\"runtime\""))
        XCTAssertTrue(source.contains("root.appendingPathComponent(\"manifest.json\""))
        XCTAssertFalse(source.contains("url(forResource: \"manifest\""))
    }
}
