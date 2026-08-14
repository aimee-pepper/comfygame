import CryptoKit
import XCTest
@testable import Bookbinder

final class StartingTownHomeSceneTests: XCTestCase {
    func testSourceArtworkStillMatchesTheAuthoredIdentityHash() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let source = root.appending(path:
            "AssetLab/integration/starting-town-home-v1/town-starting-home-v1.png")
        let digest = try SHA256.hash(data: Data(contentsOf: source))
            .map { String(format: "%02x", $0) }.joined()
        XCTAssertEqual(digest, StartingTownHomeRules.authoredAssetSHA256)
    }

    @MainActor
    func testProcessedBundlePNGStillResolvesTheHomeScene() throws {
        let scene = try XCTUnwrap(StartingTownHomeResource.scene())
        XCTAssertEqual(scene.definition.sha256, StartingTownHomeRules.authoredAssetSHA256)
        XCTAssertEqual(scene.image.cgImage?.width, scene.definition.pixelWidth)
        XCTAssertEqual(scene.image.cgImage?.height, scene.definition.pixelHeight)
    }

    func testManifestOwnsExactBandOneHomeDestinations() throws {
        let scene = try loadedScene()
        XCTAssertEqual(scene.hotspots.map(\.id),
                       ["writingDesk", "workshop", "storehouse", "essenceSpring", "firepit"])
        XCTAssertEqual(scene.hotspots.compactMap(\.appRoute),
                       [.writingDesk, .workshop, .storehouse, .essenceSpring, .firepit])
        XCTAssertFalse(scene.hotspots.contains { $0.appRoute == .party || $0.appRoute == .library })
        XCTAssertTrue(scene.hotspots.allSatisfy {
            (0...1).contains($0.point.x) && (0...1).contains($0.point.y) &&
            $0.size.width > 0 && $0.size.width <= 1 &&
            $0.size.height > 0 && $0.size.height <= 1
        })
        XCTAssertEqual(scene.pixelWidth, 1122)
        XCTAssertEqual(scene.pixelHeight, 1402)
    }

    func testHotspotsNeverCompeteForTheSameOrdinaryPhoneTap() throws {
        let hotspots = try loadedScene().hotspots
        let sceneSize = CGSize(width: 344, height: 430)
        let hitRects = hotspots.map { hotspot in
            let width = max(54, sceneSize.width * hotspot.size.width)
            let height = max(44, sceneSize.height * hotspot.size.height)
            return CGRect(x: sceneSize.width * hotspot.point.x - width / 2,
                          y: sceneSize.height * hotspot.point.y - height / 2,
                          width: width, height: height)
        }

        for first in hotspots.indices {
            for second in hotspots.indices where second > first {
                XCTAssertTrue(hitRects[first].intersection(hitRects[second]).isNull,
                              "\(hotspots[first].label) and \(hotspots[second].label) overlap")
            }
        }
    }

    func testAspectFillOwnsTheFullUsableViewportAndKeepsCoordinatesInImageSpace() {
        let container = CGSize(width: 344, height: 500)
        let rect = StartingTownHomeRules.renderedImageRect(
            imageSize: CGSize(width: 1122, height: 1402), in: container)
        XCTAssertEqual(rect.height, container.height, accuracy: 0.01)
        XCTAssertGreaterThanOrEqual(rect.width, container.width)
        XCTAssertEqual(rect.midX, container.width / 2, accuracy: 0.01)
        XCTAssertEqual(rect.midY, container.height / 2, accuracy: 0.01)
    }

    func testOrdinaryPhoneHotspotsRemainMeaningfulAndFullyInsideTheViewport() throws {
        let container = CGSize(width: 344, height: 500)
        let imageRect = StartingTownHomeRules.renderedImageRect(
            imageSize: CGSize(width: 1122, height: 1402), in: container)
        let viewport = CGRect(origin: .zero, size: container)
        for hotspot in try loadedScene().hotspots {
            let authored = CGRect(
                x: imageRect.minX + imageRect.width * hotspot.x,
                y: imageRect.minY + imageRect.height * hotspot.y,
                width: imageRect.width * hotspot.width,
                height: imageRect.height * hotspot.height)
            let hit = StartingTownHomeRules.hotspotRect(
                hotspot, imageRect: imageRect, containerSize: container)
            XCTAssertGreaterThanOrEqual(hit.width, 44, hotspot.label)
            XCTAssertGreaterThanOrEqual(hit.height, 44, hotspot.label)
            XCTAssertTrue(viewport.contains(hit), "\(hotspot.label) is clipped")
            XCTAssertFalse(hit.intersection(authored).isNull, "\(hotspot.label) lost its landmark")
        }
    }

    func testEveryDistrictSceneOwnsTheSameRemainingViewportWithoutScrolling() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(contentsOf: root.appending(path: "Sources/Screens/BaseView.swift"),
                                encoding: .utf8)
        let bodyStart = try XCTUnwrap(source.range(of: "var body: some View"))
        let purse = try XCTUnwrap(source.range(of: "// MARK: Purse", range: bodyStart.upperBound..<source.endIndex))
        let body = String(source[bodyStart.lowerBound..<purse.lowerBound])
        XCTAssertTrue(body.contains("stationBoard(containerSize: geometry.size)\n                    .frame(maxWidth: .infinity, maxHeight: .infinity)"))
        XCTAssertFalse(body.contains("if selectedSection == .home"))
        XCTAssertFalse(body.contains("ScrollView"))
        XCTAssertFalse(body.contains(".padding(12)"))
    }

    func testMalformedMetadataFailsClosed() throws {
        let asset = try assetURL()
        let malformed = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString).appendingPathExtension("json")
        try Data(#"{"schemaVersion":1,"assetName":"town-starting-home-v1","hotspots":[]}"#.utf8)
            .write(to: malformed)
        defer { try? FileManager.default.removeItem(at: malformed) }
        XCTAssertNil(StartingTownHomeRules.load(manifestURL: malformed, assetURL: asset))
    }

    func testArtworkCannotInterceptDestinationLinks() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(contentsOf: root.appending(path: "Sources/Screens/StartingTownHomeScene.swift"),
                                encoding: .utf8)
        let start = try XCTUnwrap(source.range(of: "struct StartingTownHomeScene"))
        let end = try XCTUnwrap(source.range(of: "private struct TownHotspotSign",
                                             range: start.upperBound..<source.endIndex))
        let scene = String(source[start.lowerBound..<end.lowerBound])

        XCTAssertTrue(scene.contains(".allowsHitTesting(false)"))
        XCTAssertTrue(scene.contains(".scaledToFill()"))
        XCTAssertTrue(scene.contains("StartingTownHomeRules.hotspotRect("))
        XCTAssertTrue(scene.contains("NavigationLink(value: route)"))
        XCTAssertTrue(scene.contains(".zIndex(1)"))
        XCTAssertTrue(scene.contains("openedRoute(route)"))
        XCTAssertTrue(scene.contains(".clipped()"))
        XCTAssertFalse(scene.contains("clipShape(RoundedRectangle"))
        XCTAssertFalse(scene.contains("overlay(RoundedRectangle"))
    }

    private func loadedScene() throws -> StartingTownHomeRules.Scene {
        let manifest = try XCTUnwrap(Bundle.main.url(forResource: StartingTownHomeRules.manifestName,
                                                      withExtension: "json"))
        return try XCTUnwrap(StartingTownHomeRules.load(manifestURL: manifest, assetURL: assetURL()))
    }

    private func assetURL() throws -> URL {
        try XCTUnwrap(Bundle.main.url(forResource: StartingTownHomeRules.assetName, withExtension: "png"))
    }
}
