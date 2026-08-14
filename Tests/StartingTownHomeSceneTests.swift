import XCTest
@testable import Bookbinder

final class StartingTownHomeSceneTests: XCTestCase {
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

    func testSceneFitsOrdinaryPhoneOrFallsBackToGrid() {
        let ordinary = StartingTownHomeRules.sceneHeight(containerSize: CGSize(width: 368, height: 732))
        XCTAssertEqual(ordinary ?? 0, CGFloat(344) * CGFloat(1402) / CGFloat(1122), accuracy: 0.01)
        XCTAssertNil(StartingTownHomeRules.sceneHeight(containerSize: CGSize(width: 320, height: 420)))
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
        XCTAssertTrue(scene.contains(".scaledToFit()"))
        XCTAssertTrue(scene.contains("NavigationLink(value: route)"))
        XCTAssertTrue(scene.contains(".zIndex(1)"))
        XCTAssertTrue(scene.contains("openedRoute(route)"))
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
