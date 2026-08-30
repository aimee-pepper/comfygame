import CryptoKit
import XCTest
@testable import Bookbinder

final class StartingTownHomeSceneTests: XCTestCase {
    @MainActor
    func testPhoneAdmissionTouchDownIsInertAndTenReleasesInvokeOnce() async throws {
        let admission = PhoneControlAdmissionV1()
        var state = GameState.newGame()
        let before = try SaveCodec.encode(state)
        let essenceBefore = state.base.essence
        admission.touchDown()
        XCTAssertEqual(admission.state, .touchDown)
        XCTAssertEqual(try SaveCodec.encode(state), before)

        var invocations = 0
        var admitted = 0
        var busy = 0
        for _ in 0..<10 {
            switch admission.release({
                invocations += 1
                state.base.essence += 1
                return .success(.committed)
            }) {
            case .success: admitted += 1
            case .failure(.busy): busy += 1
            case .failure: XCTFail("unexpected refusal")
            }
        }
        await Task.yield()
        XCTAssertEqual(admitted, 1)
        XCTAssertEqual(busy, 9)
        XCTAssertEqual(invocations, 1)
        XCTAssertEqual(state.base.essence, essenceBefore + 1)
        guard case .completed(_, .committed) = admission.state else {
            return XCTFail("authoritative completion must own feedback")
        }
    }

    func testHomeDestinationQuoteStalesWithoutMutatingCampaign() throws {
        var state = GameState.newGame()
        let quote = try XCTUnwrap(HomeDestinationRulesV1.quote(.route(.settings), in: state))
        let before = try SaveCodec.encode(state)
        state.meta.mutationCount += 1
        XCTAssertNotEqual(HomeDestinationRulesV1.quote(.route(.settings), in: state), quote)
        state.meta.mutationCount -= 1
        XCTAssertEqual(try SaveCodec.encode(state), before)
        state.worlds.activeRun = WorldRun(
            runIndex: 1, book: .init(written: [], essencePaid: 0), mapSeed: 1,
            rng: .init(seed: 1),
            map: .init(width: 1, height: 1, tiles: [.init()], entry: .init(x: 0, y: 0)),
            playerPosition: .init(x: 0, y: 0))
        XCTAssertNil(HomeDestinationRulesV1.quote(.route(.settings), in: state))
    }

    @MainActor
    func testRetainedHomeSelectionQuoteAndRapidDuplicateAreInert() async {
        let admission = PhoneControlAdmissionV1()
        let quote = HomeSectionSelectionQuoteV1(
            displayedSection: .home, desiredSection: .make,
            availableSections: StationHomeSection.allCases)
        var displayed = StationHomeSection.home
        var commits = 0
        admission.touchDown(controlID: "village.tab.make")
        XCTAssertNoThrow(try admission.release(controlID: "village.tab.make") {
            guard HomeSectionSelectionQuoteV1(
                displayedSection: displayed, desiredSection: .make,
                availableSections: StationHomeSection.allCases) == quote
            else { return .failure(.stale) }
            displayed = .make
            commits += 1
            return .success(.committed)
        }.get())
        XCTAssertEqual(admission.release(controlID: "village.tab.make") {
            commits += 1
            return .success(.committed)
        }, .failure(.busy))
        await Task.yield()
        XCTAssertEqual(displayed, .make)
        XCTAssertEqual(commits, 1)

        let stale = PhoneControlAdmissionV1()
        displayed = .study
        stale.touchDown(controlID: "village.tab.make")
        XCTAssertNoThrow(try stale.release(controlID: "village.tab.make") {
            guard HomeSectionSelectionQuoteV1(
                displayedSection: displayed, desiredSection: .make,
                availableSections: StationHomeSection.allCases) == quote
            else { return .failure(.stale) }
            displayed = .make
            return .success(.committed)
        }.get())
        await Task.yield()
        XCTAssertEqual(displayed, .study)
        guard case .refused(_, .stale) = stale.state else {
            return XCTFail("retained district quote must refuse after presentation drift")
        }
    }

    func testHomePageQuoteBindsDisplayedPageAndCount() {
        let quote = HomeTownPageSelectionQuoteV1(
            section: .make, displayedPage: 0, desiredPage: 1, pageCount: 2)
        XCTAssertNotEqual(quote, .init(section: .make, displayedPage: 1,
                                      desiredPage: 1, pageCount: 2))
        XCTAssertNotEqual(quote, .init(section: .make, displayedPage: 0,
                                      desiredPage: 1, pageCount: 3))
    }
    func testSourceArtworkStillMatchesTheAuthoredIdentityHash() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let source = root.appending(path:
            "Sources/Content/TownVisuals/town-starting-v1.png")
        let digest = try SHA256.hash(data: Data(contentsOf: source))
            .map { String(format: "%02x", $0) }.joined()
        XCTAssertEqual(digest, StartingTownHomeRules.authoredAssetSHA256)

        let display = root.appending(path:
            "AssetLab/integration/starting-town-home-v1/town-starting-home-v1-phone-v2.png")
        let displayDigest = try SHA256.hash(data: Data(contentsOf: display))
            .map { String(format: "%02x", $0) }.joined()
        XCTAssertEqual(displayDigest, StartingTownHomeRules.displayAssetSHA256)
    }

    @MainActor
    func testProcessedBundlePNGStillResolvesTheHomeScene() throws {
        let scene = try XCTUnwrap(StartingTownHomeResource.scene())
        XCTAssertEqual(scene.definition.sha256, StartingTownHomeRules.authoredAssetSHA256)
        XCTAssertEqual(scene.image.cgImage?.width, Int(StartingTownHomeRules.displayPixelSize.width))
        XCTAssertEqual(scene.image.cgImage?.height, Int(StartingTownHomeRules.displayPixelSize.height))
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
        XCTAssertEqual(scene.pixelWidth, 1408)
        XCTAssertEqual(scene.pixelHeight, 3048)
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

    func testFullPageHomeUsesTheSameCenteredAspectFillCropAsOtherVillagePanes() {
        let container = CGSize(width: 344, height: 500)
        let rect = StartingTownHomeRules.renderedImageRect(
            imageSize: CGSize(width: 1408, height: 3048), in: container)
        let scale = max(container.width / 1408, container.height / 3048)
        XCTAssertEqual(rect.width, 1408 * scale, accuracy: 0.001)
        XCTAssertEqual(rect.height, 3048 * scale, accuracy: 0.001)
        XCTAssertEqual(rect.midX, container.width / 2, accuracy: 0.001)
        XCTAssertEqual(rect.midY, container.height / 2, accuracy: 0.001)
        XCTAssertTrue(rect.contains(CGRect(origin: .zero, size: container)))
        XCTAssertEqual(rect, BaseBoardRules.townAspectFillFrame(
            imageSize: CGSize(width: 1408, height: 3048), containerSize: container))
    }

    func testOrdinaryPhoneHotspotsRemainMeaningfulAndFullyInsideTheViewport() throws {
        let container = CGSize(width: 344, height: 500)
        let imageRect = StartingTownHomeRules.renderedImageRect(
            imageSize: CGSize(width: 1408, height: 3048), in: container)
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
        XCTAssertTrue(body.contains("districtPager(containerSize: geometry.size)"))
        XCTAssertTrue(body.contains(".frame(maxWidth: .infinity, maxHeight: .infinity)"))
        XCTAssertFalse(body.contains("if selectedSection == .home"))
        XCTAssertFalse(body.contains("ScrollView"))
        XCTAssertFalse(body.contains(".padding(12)"))
    }

    func testMalformedMetadataFailsClosed() throws {
        let asset = try assetURL()
        let malformed = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString).appendingPathExtension("json")
        try Data(#"{"schemaVersion":1,"assetName":"town-starting-v1","hotspots":[]}"#.utf8)
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
        XCTAssertFalse(scene.contains(".scaledToFit()"))
        XCTAssertFalse(scene.contains(".scaledToFill()"))
        XCTAssertTrue(scene.contains(".frame(width: geometry.size.width, height: geometry.size.height)"))
        XCTAssertTrue(scene.contains(".frame(width: imageRect.width, height: imageRect.height)"))
        XCTAssertTrue(scene.contains("StartingTownHomeRules.hotspotRect("))
        XCTAssertTrue(scene.contains("Button {"))
        XCTAssertTrue(scene.contains(".zIndex(1)"))
        XCTAssertTrue(scene.contains("openedRoute(route, destinationQuotes[route])"))
        XCTAssertTrue(scene.contains(".clipped()"))
        XCTAssertFalse(scene.contains("clipShape(RoundedRectangle"))
        XCTAssertFalse(scene.contains("overlay(RoundedRectangle"))

        let sign = String(source[end.lowerBound...])
        XCTAssertTrue(sign.contains("PixelUITheme.edgeDark"))
        XCTAssertTrue(sign.contains("PixelUITheme.neutralHighlight"))
        XCTAssertFalse(sign.contains("Color(red:"))
        XCTAssertFalse(sign.contains(".shadow("),
                       "Hotspot depth must not duplicate or soften the label text")
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
