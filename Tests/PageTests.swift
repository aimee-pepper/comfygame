import CryptoKit
import SwiftUI
import UIKit
import XCTest
@testable import Bookbinder

/// The page as a spatial grid (`writing-system-rune-spec.md` §2–3).
///
/// Two properties carry the whole design: **the page is a budget, not a syntax** — where a rune
/// sits never changes what it says — and **refinement is literacy, not power** — a better hand lets
/// you say the same thing in less space and never unlocks a meaning.
final class PageTests: XCTestCase {
    func testNativeWorldArrivalRendererMatchesAllAcceptedCorpusCasesByteForByte() throws {
        struct Corpus: Decodable {
            struct Canvas: Decodable { var width: Int; var height: Int }
            struct ABI: Decodable { var op: String; var fields: [String] }
            struct Pins: Decodable {
                var compositorFile: String
                var compositorSHA256: String; var compositorCommit: String
                var acceptedManifestFile: String
                var acceptedManifestSHA256: String
                var latestReceiptCommit: String
            }
            var identity: String; var integrationReady: Bool; var canvas: Canvas
            var commandABI: ABI; var pins: Pins; var canonicalBodySHA256: String
            var cases: [Case]
        }
        struct Case: Decodable {
            var id: String
            var sceneReceiptVersion: Int
            var inputReceiptSHA256: String
            var inputPayloadSHA256: String
            var commandListSHA256: String
            var renderedRGBA8SHA256: String
            var receipt: WorldArrivalSceneReceipt.Payload
            var arrivalSceneCommands: [WorldArrivalRenderedSceneReceipt.Command]
        }
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        let data = try Data(contentsOf: root.appendingPathComponent(
            "AssetLab/integration/world-arrival-command-corpus-v1/corpus.json"))
        let corpus = try JSONDecoder().decode(Corpus.self, from: data)
        XCTAssertEqual(corpus.identity, "world-arrival-command-corpus-v1")
        XCTAssertFalse(corpus.integrationReady)
        XCTAssertEqual(corpus.canonicalBodySHA256, "d2783de992abb183a9d9372d60af67251b9e43d14830806bcbabc7781a9448fc")
        XCTAssertEqual(corpus.canvas.width, 160); XCTAssertEqual(corpus.canvas.height, 100)
        XCTAssertEqual(corpus.commandABI.op, "rect-v1")
        XCTAssertEqual(corpus.commandABI.fields, ["op","x","y","width","height","rgba","scope","sourceOrder"])
        XCTAssertEqual(corpus.pins.compositorFile, "AssetLab/src/world-arrival-kit.js")
        XCTAssertEqual(corpus.pins.acceptedManifestFile,
                       "AssetLab/artifacts/world-arrival-v0.1/manifest.json")
        XCTAssertEqual(corpus.pins.latestReceiptCommit,
                       "72b840d3e1de2b8c32aebfc0e876d61c69448a92")
        XCTAssertEqual(corpus.pins.compositorSHA256, WorldArrivalRenderedSceneReceipt.visualProgramSHA256)
        XCTAssertEqual(corpus.pins.compositorCommit, WorldArrivalRenderedSceneReceipt.visualProgramCommit)
        XCTAssertEqual(corpus.pins.acceptedManifestSHA256, WorldArrivalRenderedSceneReceipt.acceptedManifestSHA256)
        XCTAssertEqual(corpus.cases.count, 85)
        var maximum = 0
        for fixture in corpus.cases {
            let scene = WorldArrivalSceneReceipt(payload: fixture.receipt)
            XCTAssertEqual(scene.version, fixture.sceneReceiptVersion, fixture.id)
            XCTAssertEqual(scene.canonicalSHA256, fixture.inputReceiptSHA256, fixture.id)
            XCTAssertEqual(WorldArrivalRenderedSceneReceipt.canonicalSHA256(fixture.receipt),
                           fixture.inputPayloadSHA256, fixture.id)
            let rendered = try WorldArrivalNativeRenderer.makeRenderedReceipt(scene: scene)
            XCTAssertEqual(rendered.commands, fixture.arrivalSceneCommands, fixture.id)
            XCTAssertEqual(rendered.commandListSHA256, fixture.commandListSHA256, fixture.id)
            XCTAssertEqual(rendered.renderedRGBA8SHA256, fixture.renderedRGBA8SHA256, fixture.id)
            XCTAssertEqual(rendered.visualProgramSHA256, corpus.pins.compositorSHA256)
            XCTAssertEqual(rendered.visualProgramCommit, corpus.pins.compositorCommit)
            XCTAssertEqual(rendered.acceptedManifestSHA256, corpus.pins.acceptedManifestSHA256)
            maximum = max(maximum, rendered.commands.count)
        }
        XCTAssertEqual(maximum, 1365)
    }

    func testWorldArrivalJavaScriptArithmeticDoesNotWrapAfterHashing() {
        XCTAssertEqual(WorldArrivalNativeRenderer.jsModulo(.max, add: 41, modulus: 134),
                       Int((UInt64(UInt32.max) + 41) % 134))
    }

    func testBlankPageSceneIsValidAndRendersWithoutEntryMarkCommands() throws {
        var payload = try acceptedArrivalPayload("starter_open_meadow")
        payload.sourcePage.marks = []
        let scene = WorldArrivalSceneReceipt(payload: payload)

        XCTAssertTrue(scene.validatesSchema())
        let rendered = try WorldArrivalNativeRenderer.makeRenderedReceipt(scene: scene)
        XCTAssertTrue(rendered.validates())
        XCTAssertFalse(rendered.commands.contains { $0.scope == .entryMark })
    }

    func testWorldArrivalOrdinaryPhoneLayoutAndCrispThumbnailGeometry() {
        XCTAssertEqual(WorldArrivalLayout.metrics(width: 368).sceneWidth, 320)
        XCTAssertEqual(WorldArrivalLayout.metrics(width: 320).sceneWidth, 296)
        let cell = floor(54.0 / 6.0)
        XCTAssertEqual(cell, 9)
        XCTAssertEqual((54 - cell * 6) / 2, 0)
        XCTAssertEqual(WorldArrivalLayout.enterFrame(height: 800), 728...786)
        XCTAssertEqual(RootPresentationRules.surface(
            hasArrival: true, hasEncounter: true, isInRun: true), .arrival)
    }

    @MainActor
    func testWorldDestinationPreparationStartsOnceAndReusesTheSameResult() async {
        let coordinator = WorldDestinationPreparationCoordinator()
        let key = WorldDestinationPreparationCoordinator.Key(
            receiptID: .init(rawValue: "prepared-a"), runIndex: 4, mapSeed: 44)
        var calls = 0
        let first = Task { @MainActor in
            await coordinator.prepare(key: key) {
                calls += 1
                try? await Task.sleep(for: .milliseconds(40))
                return !Task.isCancelled
            }
        }
        await Task.yield()
        let second = Task { @MainActor in
            await coordinator.prepare(key: key) {
                XCTFail("a peer waiter must reuse the one owned preparation")
                return false
            }
        }
        let firstResult = await first.value
        let secondResult = await second.value
        XCTAssertTrue(firstResult)
        XCTAssertTrue(secondResult)
        XCTAssertEqual(calls, 1)
        XCTAssertEqual(coordinator.startedPreparationCount, 1)
        XCTAssertEqual(coordinator.phase, .ready(key))
        let reused = await coordinator.prepare(key: key) {
            XCTFail("a ready destination must not prepare twice")
            return false
        }
        XCTAssertTrue(reused)
        XCTAssertEqual(coordinator.startedPreparationCount, 1)
    }

    @MainActor
    func testWorldDestinationPreparationCancelsStaleDestinationAndIgnoresItsCallback() async {
        let coordinator = WorldDestinationPreparationCoordinator()
        let old = WorldDestinationPreparationCoordinator.Key(
            receiptID: .init(rawValue: "prepared-old"), runIndex: 4, mapSeed: 44)
        let current = WorldDestinationPreparationCoordinator.Key(
            receiptID: .init(rawValue: "prepared-current"), runIndex: 5, mapSeed: 55)
        let stale = Task { @MainActor in
            await coordinator.prepare(key: old) {
                try? await Task.sleep(for: .milliseconds(80))
                return !Task.isCancelled
            }
        }
        await Task.yield()
        let currentResult = await coordinator.prepare(key: current) { true }
        let staleResult = await stale.value
        XCTAssertTrue(currentResult)
        XCTAssertFalse(staleResult)
        XCTAssertEqual(coordinator.phase, .ready(current))
        XCTAssertEqual(coordinator.startedPreparationCount, 2)

        coordinator.cancel(key: old)
        XCTAssertEqual(coordinator.phase, .ready(current),
                       "an obsolete route callback cannot cancel the selected destination")
        coordinator.cancel(key: current)
        XCTAssertEqual(coordinator.phase, .idle)
    }

    @MainActor
    func testWorldDestinationPreparationFailureIsOneShotForTheSelectedDestination() async {
        let coordinator = WorldDestinationPreparationCoordinator()
        let key = WorldDestinationPreparationCoordinator.Key(
            receiptID: .init(rawValue: "prepared-failure"), runIndex: 6, mapSeed: 66)
        var calls = 0

        let failed = await coordinator.prepare(key: key) {
            calls += 1
            return false
        }
        XCTAssertFalse(failed)
        XCTAssertEqual(coordinator.phase, .failed(key))

        let reusedFailure = await coordinator.prepare(key: key) {
            XCTFail("a failed destination must not start an implicit second preparation")
            return true
        }
        XCTAssertFalse(reusedFailure)
        XCTAssertEqual(calls, 1)
        XCTAssertEqual(coordinator.startedPreparationCount, 1)
    }

    @MainActor
    func testMountedWorldSplashPreparesExactDestinationWithoutSaveOrTurnMutation() throws {
        let io = SaveFileIO.temporary(name: "world-preload-mounted-\(UUID().uuidString)")
        let store = GameStore(io: io)
        XCTAssertTrue(store.bindAndDepart(
            worldPageInstanceID: WorldPageCatalog.earthlikeTestInstance.id))
        let receipt = try XCTUnwrap(store.state.worlds.pendingWorldArrivalReceipt)
        let run = try XCTUnwrap(store.activeRun)
        let beforeBytes = try SaveCodec.encode(store.state)
        let beforeTurn = run.turnsTaken
        let beforeMutationCount = store.state.meta.mutationCount
        WorldDestinationPreparationMeasurement.reset()
        WorldMapFirstFrameMeasurement.reset()

        let host = UIHostingController(rootView:
            WorldArrivalView(receipt: receipt)
                .environmentObject(store)
                .frame(width: 368, height: 800))
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 368, height: 800))
        window.rootViewController = host
        window.makeKeyAndVisible()
        host.view.frame = window.bounds
        host.view.layoutIfNeeded()
        let deadline = Date().addingTimeInterval(4)
        while WorldDestinationPreparationMeasurement.readyKeys.isEmpty, Date() < deadline {
            RunLoop.main.run(until: Date().addingTimeInterval(0.01))
        }
        let expectedKey = WorldDestinationPreparationCoordinator.Key(
            receiptID: receipt.id, runIndex: run.runIndex, mapSeed: run.mapSeed)
        XCTAssertEqual(WorldDestinationPreparationMeasurement.startedKeys, [expectedKey])
        XCTAssertEqual(WorldDestinationPreparationMeasurement.readyKeys, [expectedKey])
        let preloadedFrame = try XCTUnwrap(WorldMapFirstFrameMeasurement.preloaded)
        XCTAssertEqual(preloadedFrame.columns, 11)
        XCTAssertEqual(preloadedFrame.rows, 14)
        XCTAssertEqual(store.state.worlds.pendingWorldArrivalReceiptID, receipt.id)
        XCTAssertEqual(store.activeRun?.turnsTaken, beforeTurn)
        XCTAssertEqual(store.state.meta.mutationCount, beforeMutationCount)
        XCTAssertEqual(try SaveCodec.encode(store.state), beforeBytes)

        let firstRequest = WorldDestinationPreloader.request(
            run: run, state: store.state, containerSize: .init(width: 368, height: 800),
            displayScale: 2, presentationTick: TerrainPresentationClock.shared.tick,
            reduceMotion: false)
        let secondRequest = WorldDestinationPreloader.request(
            run: run, state: store.state, containerSize: .init(width: 368, height: 800),
            displayScale: 2, presentationTick: TerrainPresentationClock.shared.tick,
            reduceMotion: false)
        XCTAssertEqual(firstRequest.artRequests.count, secondRequest.artRequests.count)
        XCTAssertEqual(firstRequest.identityKeys, secondRequest.identityKeys)
        XCTAssertFalse(firstRequest.artRequests.isEmpty)

        XCTAssertTrue(store.enterPendingWorld(arrivalReceiptID: receipt.id))
        XCTAssertNil(store.state.worlds.pendingWorldArrivalReceiptID)
        XCTAssertEqual(store.activeRun?.turnsTaken, beforeTurn)
        XCTAssertEqual(store.activeRun?.mapSeed, run.mapSeed)
        XCTAssertEqual(store.activeRun?.map, run.map)
        XCTAssertFalse(store.enterPendingWorld(arrivalReceiptID: receipt.id))

        host.rootView = WorldArrivalView(receipt: receipt)
            .environmentObject(store)
            .frame(width: 368, height: 800)
        let worldHost = UIHostingController(rootView:
            WorldView().environmentObject(store).frame(width: 368, height: 800))
        window.rootViewController = worldHost
        worldHost.view.frame = window.bounds
        worldHost.view.layoutIfNeeded()
        let mapDeadline = Date().addingTimeInterval(2)
        while WorldMapFirstFrameMeasurement.mounted == nil, Date() < mapDeadline {
            RunLoop.main.run(until: Date().addingTimeInterval(0.01))
        }
        XCTAssertEqual(WorldMapFirstFrameMeasurement.mounted, preloadedFrame,
                       "the splash preload must exactly equal the first production MapGrid request")
    }

    @MainActor
    func testWorldDestinationPreparationIsTransientAndDeterministicAcrossRelaunch() throws {
        let io = SaveFileIO.temporary(name: "world-preload-relaunch-\(UUID().uuidString)")
        var store: GameStore? = GameStore(io: io)
        XCTAssertTrue(store?.bindAndDepart(
            worldPageInstanceID: WorldPageCatalog.earthlikeTestInstance.id) == true)
        let before = try XCTUnwrap(store?.activeRun)
        let beforeState = try XCTUnwrap(store?.state)
        let beforeRequest = WorldDestinationPreloader.request(
            run: before, state: beforeState, containerSize: .init(width: 368, height: 800),
            displayScale: 2, presentationTick: 0, reduceMotion: false)
        store = nil

        let relaunched = GameStore(io: io)
        let after = try XCTUnwrap(relaunched.activeRun)
        let afterRequest = WorldDestinationPreloader.request(
            run: after, state: relaunched.state,
            containerSize: .init(width: 368, height: 800), displayScale: 2,
            presentationTick: 0, reduceMotion: false)
        XCTAssertEqual(after, before)
        XCTAssertEqual(relaunched.state.base, beforeState.base)
        XCTAssertEqual(relaunched.state.reality, beforeState.reality)
        XCTAssertEqual(relaunched.state.worlds, beforeState.worlds)
        XCTAssertEqual(relaunched.state.meta.mutationCount, beforeState.meta.mutationCount)
        XCTAssertEqual(relaunched.state.meta.lastAction, beforeState.meta.lastAction)
        XCTAssertEqual(afterRequest.artRequests.count, beforeRequest.artRequests.count)
        XCTAssertEqual(afterRequest.identityKeys, beforeRequest.identityKeys)
        XCTAssertEqual(relaunched.state.worlds.pendingWorldArrivalReceiptID,
                       before.worldArrivalReceipt?.id)
    }

    @MainActor
    func testWorldArrivalRendersOrdinaryPhoneLayoutsInLightAndDark() throws {
        func pixels(_ image: UIImage) throws -> (data: Data, width: Int, height: Int, row: Int) {
            let cg = try XCTUnwrap(image.cgImage)
            let row = cg.width * 4
            var bytes = [UInt8](repeating: 0, count: row * cg.height)
            try bytes.withUnsafeMutableBytes { storage in
                let context = try XCTUnwrap(CGContext(
                    data: storage.baseAddress, width: cg.width, height: cg.height,
                    bitsPerComponent: 8, bytesPerRow: row,
                    space: CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
                context.translateBy(x: 0, y: CGFloat(cg.height))
                context.scaleBy(x: 1, y: -1)
                context.interpolationQuality = .none
                context.draw(cg, in: CGRect(x: 0, y: 0, width: cg.width, height: cg.height))
            }
            return (Data(bytes), cg.width, cg.height, row)
        }
        func largestNonBackgroundBounds(in mounted: UIImage) throws -> CGRect {
            let whole = try pixels(mounted)
            let background = (0..<3).map { whole.data[$0] }
            let limitY = min(620, whole.height)
            var visible = Array(repeating: false, count: whole.width * limitY)
            for y in 0..<limitY {
                for x in 0..<whole.width {
                    let offset = y * whole.row + x * 4
                    visible[y * whole.width + x] = (0..<3).contains {
                        abs(Int(whole.data[offset + $0]) - Int(background[$0])) > 8
                    }
                }
            }
            var visited = Array(repeating: false, count: visible.count)
            var best = CGRect.zero
            for start in visible.indices where visible[start] && !visited[start] {
                var queue = [start]
                visited[start] = true
                var cursor = 0
                var minX = whole.width, maxX = 0, minY = limitY, maxY = 0
                while cursor < queue.count {
                    let current = queue[cursor]; cursor += 1
                    let x = current % whole.width, y = current / whole.width
                    minX = min(minX, x); maxX = max(maxX, x)
                    minY = min(minY, y); maxY = max(maxY, y)
                    for next in [current - (x > 0 ? 1 : 0), current + (x + 1 < whole.width ? 1 : 0),
                                 current - (y > 0 ? whole.width : 0),
                                 current + (y + 1 < limitY ? whole.width : 0)]
                    where next != current && visible[next] && !visited[next] {
                        visited[next] = true
                        queue.append(next)
                    }
                }
                let bounds = CGRect(x: minX, y: minY,
                                    width: maxX - minX + 1, height: maxY - minY + 1)
                if bounds.width * bounds.height > best.width * best.height { best = bounds }
            }
            return best
        }
        func mountedSceneInteriorMatch(mounted: UIImage, scene: UIImage) throws -> Double {
            let whole = try pixels(mounted)
            let source = try pixels(scene)
            var best = 0.0
            for originY in 0...min(440, whole.height - source.height) {
                var matched = 0
                var sampled = 0
                for y in stride(from: 8, to: source.height - 8, by: 8) {
                    for x in stride(from: 8, to: source.width - 8, by: 8) {
                        let lhs = y * source.row + x * 4
                        let rhs = (originY + y) * whole.row + (24 + x) * 4
                        if (0..<3).allSatisfy({
                            abs(Int(source.data[lhs + $0]) - Int(whole.data[rhs + $0])) <= 8
                        }) { matched += 1 }
                        sampled += 1
                    }
                }
                best = max(best, Double(matched) / Double(sampled))
            }
            return best
        }
        func snapshot(_ view: UIView, size: CGSize) -> UIImage {
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1
            format.opaque = true
            return UIGraphicsImageRenderer(size: size, format: format).image { _ in
                view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
            }
        }
        let store = GameStore(io: .temporary(name: "arrival-layout-\(UUID().uuidString)"))
        XCTAssertTrue(store.bindAndDepart(
            worldPageInstanceID: WorldPageCatalog.earthlikeTestInstance.id))
        var receipt = try XCTUnwrap(store.state.worlds.pendingWorldArrivalReceipt)
        receipt.sourcePagePhysicalReceipt.title =
            "The Exceptionally Long Chronicle of the Rain-Washed Archipelago Beyond the Stone Horizon"
        receipt.finalDescription = "Broad stone shelves rise above narrow soil paths and connected pools of shallow water, with deep channels cutting between the largest dry crossings. Your Archipelago Sigil divided the route into separate shelves, while your Verdant Sigil spread dense low growth across the dampest edges and left the higher exposed ground comparatively bare near the entry."
        XCTAssertEqual(receipt.finalDescription.split(whereSeparator: \.isWhitespace).count, 55)
        if let template = receipt.sourcePagePhysicalReceipt.marks.first {
            receipt.sourcePagePhysicalReceipt.marks = (0..<36).map { index in
                var mark = template
                mark.id = .init(rawValue: UInt64(90_000 + index))
                mark.origin = .init(column: index % 6, row: index / 6)
                mark.cells = [mark.origin]
                mark.isReadable = true
                mark.visibleLabel = "Disclosed Sigil \(index + 1)"
                return mark
            }
        }

        for (width, scheme, name) in [
            (CGFloat(368), ColorScheme.dark, "dark-368"),
            (CGFloat(368), ColorScheme.light, "light-368"),
            (CGFloat(320), ColorScheme.dark, "dark-320")
        ] {
            let host = UIHostingController(rootView:
                WorldArrivalView(receipt: receipt)
                    .environmentObject(store)
                    .environment(\.dynamicTypeSize, .large)
                    .environment(\.colorScheme, scheme)
                    .frame(width: width, height: 800))
            let window = UIWindow(frame: CGRect(x: 0, y: 0, width: width, height: 800))
            window.rootViewController = host
            window.makeKeyAndVisible()
            host.view.frame = window.bounds
            host.view.layoutIfNeeded()
            RunLoop.main.run(until: Date().addingTimeInterval(0.05))
            let scrolls = arrivalDescendants(of: host.view).compactMap { $0 as? UIScrollView }
            XCTAssertFalse(scrolls.isEmpty)
            let scroll = try XCTUnwrap(scrolls.max(by: { $0.bounds.width < $1.bounds.width }))
            let scrollFrame = scroll.convert(scroll.bounds, to: host.view)
            XCTAssertGreaterThan(scroll.contentSize.height, scroll.bounds.height,
                "longest legal copy and full disclosed-Sigil list must remain scroll-reachable")
            let image = snapshot(host.view, size: window.bounds.size)
            XCTAssertEqual(image.size, CGSize(width: width, height: 800))
            XCTAssertEqual(scrollFrame.maxY,
                WorldArrivalLayout.enterFrame(height: 800).lowerBound, accuracy: 1,
                "decision content must end exactly adjacent to the fixed Enter World action")
            if width == 368 {
                let splash = try XCTUnwrap(receipt.worldSplashReceiptV3)
                let scene = try XCTUnwrap(WorldArrivalNativeRenderer.placeholderImage(
                    for: splash, size: .init(width: 320, height: 360)))
                XCTAssertEqual(scene.cgImage?.width, 320)
                XCTAssertEqual(scene.cgImage?.height, 360)
                XCTAssertGreaterThan(try mountedSceneInteriorMatch(mounted: image, scene: scene), 0.90,
                    "mounted scene interior must retain the direct renderer's full raster")
                let occupied = try largestNonBackgroundBounds(in: image)
                XCTAssertGreaterThanOrEqual(occupied.width, 310,
                    "mounted scene must not collapse to a narrow theme/width-dependent strip")
                XCTAssertGreaterThanOrEqual(occupied.height, 348,
                    "mounted scene must retain materially full 320x360 occupied raster")
            }
            let attachment = XCTAttachment(image: image)
            attachment.name = "world-arrival-\(name)"
            attachment.lifetime = .keepAlways
            add(attachment)
            let maximumOffset = max(0, scroll.contentSize.height - scroll.bounds.height)
            scroll.setContentOffset(CGPoint(x: 0, y: maximumOffset), animated: false)
            host.view.layoutIfNeeded()
            RunLoop.main.run(until: Date().addingTimeInterval(0.02))
            XCTAssertEqual(scroll.contentOffset.y, maximumOffset, accuracy: 1)
            XCTAssertEqual(scroll.contentSize.height - scroll.contentOffset.y,
                           scroll.bounds.height, accuracy: 1,
                           "the final provenance/Sigil content boundary must be reachable above the action")
            let bottom = snapshot(host.view, size: window.bounds.size)
            XCTAssertNotEqual(try pixels(image).data, try pixels(bottom).data,
                "the complete provenance/Sigil content must be reachable above the fixed action")
            let bottomAttachment = XCTAttachment(image: bottom)
            bottomAttachment.name = "world-arrival-\(name)-provenance"
            bottomAttachment.lifetime = .keepAlways
            add(bottomAttachment)
            window.isHidden = true
        }
    }

    @MainActor private func arrivalDescendants(of view: UIView) -> [UIView] {
        [view] + view.subviews.flatMap(arrivalDescendants)
    }

    func testArrivalSceneSchemaRejectsClosedBoundaryViolations() throws {
        let accepted = try acceptedArrivalPayload("starter_open_meadow")
        func rejects(_ edit: (inout WorldArrivalSceneReceipt.Payload) -> Void,
                     file: StaticString = #filePath, line: UInt = #line) {
            var payload = accepted
            edit(&payload)
            XCTAssertFalse(WorldArrivalSceneReceipt(payload: payload).validatesSchema(),
                           file: file, line: line)
        }
        rejects { $0.dominantGround = .water }
        rejects { $0.waterRelationship = "ocean" }
        rejects { $0.materialDescriptor.resolvedColor = [0, 0, 256] }
        rejects { $0.illumination.band = "unknown" }
        rejects { $0.suspendedAtmosphere.medium = "none"; $0.suspendedAtmosphere.density = "light" }
        rejects { $0.precipitation.medium = "none"; $0.precipitation.intensity = "heavy" }
        rejects { $0.precipitation.motion = "diagonal" }
        rejects { $0.suspendedAtmosphere.motion = "diagonal" }
        rejects { $0.flora[0].coverage = "unknown" }
        rejects { $0.flora[0].habit = "unknown" }
        rejects { $0.flora[0].color = [1, 2] }
        rejects { $0.causalVisualFacts[0].visibleScope = "site" }
        rejects { $0.causalVisualFacts[0].visibleScope = "resource"; $0.causalVisualFacts[0].resultBand = "raw:17" }
        rejects { $0.entryDisclosure = .init(siteProfile: "", status: "entryVisible") }
        rejects { $0.entryDisclosure = .init(siteProfile: "site", status: "hidden") }
        rejects { $0.sourcePage.marks[0].x = 6 }
        rejects { $0.sourcePage.marks[0].cells[0] = [0] }
        rejects { $0.firstMapCropReceipt.cells[0].visibility = "hidden"; $0.firstMapCropReceipt.cells[0].ground = .stone }
        rejects { $0.firstMapCropReceipt.cells[1].x = $0.firstMapCropReceipt.cells[0].x; $0.firstMapCropReceipt.cells[1].y = $0.firstMapCropReceipt.cells[0].y }
        rejects { $0.firstMapCropReceipt.cells[0].x = 9 }
        rejects { $0.firstMapCropReceipt.cells[0].ground = nil }
        rejects { $0.firstMapCropReceipt.cells[0].visibility = "fringe"; $0.firstMapCropReceipt.cells[0].floraStableID = "flora" }
    }

    @MainActor
    func testWritingDeskRendersAtApprovedOrdinaryPhoneSize() throws {
        let store = GameStore(io: .temporary(name: "writing-render-\(UUID().uuidString)"))
        store.mutate("prepare writing render fixture") { state in
            for lesson in TutorialLessonID.allCases {
                state.tutorial.complete(lesson, fact: "visual_fixture")
            }
        }
        for scheme in [ColorScheme.light, .dark] {
            let controller = UIHostingController(rootView:
                NavigationStack { WritingDeskView().environmentObject(store) }
                    .environment(\.colorScheme, scheme)
                    .environment(\.dynamicTypeSize, .large)
                    .frame(width: 368, height: 800)
            )
            let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 368, height: 800))
            window.rootViewController = controller
            window.makeKeyAndVisible()
            controller.view.frame = window.bounds
            controller.view.layoutIfNeeded()
            RunLoop.main.run(until: Date().addingTimeInterval(0.05))
            XCTAssertTrue(store.writingDeskPage.runes.isEmpty)
            let persistedBefore = try SaveCodec.makeEncoder().encode(store.state)
            let marks: [(MarkContent, String, PageCell)] = [
                (.target("illumination"), "illumination", .init(column: 0, row: 0)),
                (.target("thermal"), "thermal", .init(column: 2, row: 0)),
                (.target("hydrology"), "hydrology", .init(column: 0, row: 2)),
                (.target("substrate"), "substrate", .init(column: 2, row: 2)),
            ]
            for count in 0...marks.count {
                if count > 0 {
                    let mark = marks[count - 1]
                    XCTAssertTrue(store.write(mark.0, glyph: mark.1, at: mark.2))
                    RunLoop.main.run(until: Date().addingTimeInterval(0.03))
                    controller.view.layoutIfNeeded()
                }
                XCTAssertEqual(store.writingDeskPage.runes.count, count)
                let image = UIGraphicsImageRenderer(size: window.bounds.size).image { _ in
                    controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
                }
                XCTAssertEqual(image.size, CGSize(width: 368, height: 800))
                let attachment = XCTAttachment(image: image)
                attachment.name = "writing-desk-\(count)-marks-\(scheme == .light ? "light" : "dark")"
                attachment.lifetime = .keepAlways
                add(attachment)
            }
            window.isHidden = true
            XCTAssertEqual(try SaveCodec.makeEncoder().encode(store.state), persistedBefore)
        }
    }

    @MainActor
    func testWritingDeskCausalReviewMountsAtOrdinaryPhoneWithoutMutation() throws {
        let store = GameStore(io: .temporary(name: "writing-causal-mount-\(UUID().uuidString)"))
        store.mutate("prepare causal mount") { state in
            state.base.setEssenceCrystalCount(100)
            for lesson in TutorialLessonID.allCases {
                state.tutorial.complete(lesson, fact: "causal_mount")
            }
        }
        store.reconcileStarterWorldPageBundle()
        let before = try SaveCodec.makeEncoder().encode(store.state)
        for scheme in [ColorScheme.light, .dark] {
            let controller = UIHostingController(rootView:
                WritingDeskView(debugInitialPane: "The world")
                    .environmentObject(store)
                    .environment(\.colorScheme, scheme)
                    .frame(width: 368, height: 800))
            let window = UIWindow(frame: .init(x: 0, y: 0, width: 368, height: 800))
            window.rootViewController = controller
            window.makeKeyAndVisible()
            controller.view.frame = window.bounds
            controller.view.layoutIfNeeded()
            RunLoop.main.run(until: Date().addingTimeInterval(0.1))
            controller.view.layoutIfNeeded()

            XCTAssertEqual(controller.view.bounds.size, CGSize(width: 368, height: 800))
            let image = UIGraphicsImageRenderer(size: window.bounds.size).image { _ in
                controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
            }
            let attachment = XCTAttachment(image: image)
            attachment.name = "writing-causal-review-\(scheme == .light ? "light" : "dark")"
            attachment.lifetime = .keepAlways
            add(attachment)
            window.isHidden = true
        }
        XCTAssertEqual(try SaveCodec.makeEncoder().encode(store.state), before)
    }

    @MainActor
    func testWritingDeskPrimaryFacesPressImmediatelyAndDisabledBindStaysInactive() throws {
        let store = GameStore(io: .temporary(name: "writing-press-\(UUID().uuidString)"))
        store.mutate("prepare writing press fixture") { state in
            for lesson in TutorialLessonID.allCases {
                state.tutorial.complete(lesson, fact: "press_fixture")
            }
            state.base.setEssenceCrystalCount(0)
            state.base.stations[Stations.anchorage] = StationState(isUnlocked: true, tier: 0)
        }
        store.reconcileStarterWorldPageBundle()
        let beforeTurn = store.activeRun?.turnsTaken
        for id in ["writing.pane.Write", "writing.bin.compounds", "writing.bind-depart"] {
            FullFacePressMeasurements.reset()
            let controller = UIHostingController(rootView:
                NavigationStack {
                    (id == "writing.bind-depart"
                     ? WritingDeskView(debugInitialPane: "The world", debugBornAnchored: true)
                     : WritingDeskView()).environmentObject(store)
                }
                    .environment(\.fullFacePressFixtureID, id)
                    .environment(\.dynamicTypeSize, .large)
                    .frame(width: 368, height: 800))
            let window = UIWindow(frame: .init(x: 0, y: 0, width: 368, height: 800))
            window.rootViewController = controller; window.makeKeyAndVisible()
            controller.view.frame = window.bounds; controller.view.layoutIfNeeded()
            RunLoop.main.run(until: Date().addingTimeInterval(0.1))
            let measurement = try XCTUnwrap(FullFacePressMeasurements.values[id], id)
            if id == "writing.bind-depart" {
                XCTAssertFalse(measurement.isEnabled)
                XCTAssertFalse(measurement.isPressed,
                               "a disabled action cannot borrow enabled-looking feedback")
            } else {
                XCTAssertTrue(measurement.isEnabled)
                XCTAssertTrue(measurement.isPressed)
            }
            XCTAssertGreaterThan(measurement.frame.width, 0)
            XCTAssertGreaterThan(measurement.frame.height, 0)
            window.isHidden = true
        }
        XCTAssertEqual(store.activeRun?.turnsTaken, beforeTurn)
    }

    @MainActor
    func testWritingDeskOrdinarySessionIsBlankTransientAndRelaunchSafe() throws {
        let io = SaveFileIO.temporary(name: "writing-transient-\(UUID().uuidString)")
        let store = GameStore(io: io)
        XCTAssertTrue(store.write(.source("sun"), glyph: "sun",
                                  at: .init(column: 0, row: 0)))
        store.flushNow()
        let persistedPage = store.state.base.page
        let persistedBytes = try SaveCodec.makeEncoder().encode(store.state)

        store.beginWritingDeskSession()
        XCTAssertTrue(store.writingDeskPage.runes.isEmpty)
        XCTAssertEqual(try SaveCodec.makeEncoder().encode(store.state), persistedBytes)
        XCTAssertTrue(store.write(.target("thermal"), glyph: "thermal",
                                  at: .init(column: 0, row: 0)))
        XCTAssertEqual(store.writingDeskPage.runes.count, 1)
        XCTAssertEqual(store.state.base.page, persistedPage)
        XCTAssertEqual(try SaveCodec.makeEncoder().encode(store.state), persistedBytes)
        store.endWritingDeskSession()

        let relaunched = GameStore(io: io)
        XCTAssertEqual(relaunched.state.base.page, persistedPage)
        let relaunchedBytes = try SaveCodec.makeEncoder().encode(relaunched.state)
        relaunched.beginWritingDeskSession()
        XCTAssertTrue(relaunched.writingDeskPage.runes.isEmpty)
        XCTAssertEqual(try SaveCodec.makeEncoder().encode(relaunched.state), relaunchedBytes)
    }

    @MainActor
    func testWritingDeskFirstRenderedPageIsBlankBeforeOnAppearOwnsASession() throws {
        func preparedStore(_ name: String, withLegacyPage: Bool) -> GameStore {
            let store = GameStore(io: .temporary(name: name))
            store.mutate("prepare first-frame fixture") { state in
                for lesson in TutorialLessonID.allCases {
                    state.tutorial.complete(lesson, fact: "first_frame_fixture")
                }
            }
            if withLegacyPage { XCTAssertTrue(store.write("plains")) }
            store.reconcileStarterWorldPageBundle()
            return store
        }
        func firstRender(_ store: GameStore) throws -> UIImage {
            let renderer = ImageRenderer(content:
                WritingDeskView()
                    .environmentObject(store)
                    .environment(\.colorScheme, .light)
                    .environment(\.dynamicTypeSize, .large)
                    .frame(width: 368, height: 800))
            renderer.scale = 1
            renderer.proposedSize = ProposedViewSize(width: 368, height: 800)
            return try XCTUnwrap(renderer.uiImage)
        }

        let legacy = preparedStore("writing-first-legacy-\(UUID().uuidString)", withLegacyPage: true)
        let blank = preparedStore("writing-first-blank-\(UUID().uuidString)", withLegacyPage: false)
        XCTAssertNil(legacy.writingDeskDraft, "the pre-appearance proof must precede session setup")
        XCTAssertEqual(legacy.state.base.page.runes.count, 1)
        XCTAssertTrue(legacy.writingDeskPage.runes.isEmpty,
                      "the presentation owner must be blank before the first body evaluation")
        let persistedPageBeforeRender = legacy.state.base.page
        let legacyFirstFrame = try firstRender(legacy)
        let blankFirstFrame = try firstRender(blank)
        XCTAssertEqual(legacy.state.base.page, persistedPageBeforeRender,
                       "mount may own a transient session but must not rewrite the persisted legacy page")
        XCTAssertEqual(legacyFirstFrame.pngData(), blankFirstFrame.pngData(),
                       "a legacy persisted mark must not change any first-render Writing Desk pixel")
    }

    @MainActor
    func testWritingDeskBlankAndEditedDraftsStageReviewAndCommitOneRevision() throws {
        func exercise(_ symbolID: SymbolID?) throws {
            let store = GameStore(io: .temporary(name: "writing-bind-revision-\(UUID().uuidString)"))
            store.mutate("fund transient bind fixture") {
                $0.base.essence = 1_000
                $0.worlds.seeds = SeedSequence(rootSeed: 1)
            }
            store.beginWritingDeskSession()
            if let symbolID { XCTAssertTrue(store.write(symbolID)) }
            let draft = store.writingDeskPage
            let revision = try XCTUnwrap(WritingDeskReviewModelFactory.canonicalHash(draft))
            let quote = try XCTUnwrap(store.writingDeskBindQuote())
            let review = try XCTUnwrap(store.writingDeskReviewModel())
            XCTAssertEqual(quote.sourceKey, .draft(pageRevisionID: revision))
            XCTAssertEqual(review.sourceKey, quote.sourceKey)
            XCTAssertEqual(quote.frozenPageHash, revision)
            XCTAssertEqual(review.visibleMarkCount, draft.runes.count)
            XCTAssertTrue(store.bindAndDepart(), store.bindError ?? "ordinary transient bind refused")
            XCTAssertEqual(store.activeRun?.book.allSymbolIDs, draft.symbolIDs)
            XCTAssertEqual(store.writingDeskPage, draft,
                           "commit must use the frozen draft without rewriting session ownership")
        }
        try exercise(nil)
        try exercise("plains")
    }

    @MainActor
    func testWritingDeskChangedTransientQuoteRefusesWithoutCommitDrift() throws {
        let store = GameStore(io: .temporary(name: "writing-stale-quote-\(UUID().uuidString)"))
        store.mutate("fund stale transient bind") {
            $0.base.essence = 1_000
            $0.worlds.seeds = SeedSequence(rootSeed: 1)
        }
        store.beginWritingDeskSession()
        XCTAssertTrue(store.write("caverns"))
        let staged = try XCTUnwrap(store.writingDeskBindQuote())
        var changedDraft: Page?
        var bytesAfterChange: Data?
        store.writingDeskBeforeCommitForTesting = {
            XCTAssertTrue(store.write("frostbound"))
            changedDraft = store.writingDeskPage
            bytesAfterChange = try! SaveCodec.makeEncoder().encode(store.state)
        }
        let committed = store.bindAndDepart()
        XCTAssertNotNil(changedDraft, "the test hook must cross the staged/commit boundary")
        XCTAssertFalse(committed)
        XCTAssertEqual(store.bindError, "The binding changed before departure. Nothing was spent.")
        XCTAssertNotEqual(store.writingDeskBindQuote(), staged)
        XCTAssertEqual(store.writingDeskPage, changedDraft)
        XCTAssertEqual(try SaveCodec.makeEncoder().encode(store.state), bytesAfterChange,
                       "refusal may not spend Essence/seed/ink, add History, change the persisted page, or emit a turn")
        XCTAssertNil(store.activeRun)
        XCTAssertTrue(store.state.reality.library.visitedWorlds.isEmpty)
    }

    @MainActor
    func testWritingDeskCollectedPageBindIgnoresAndPreservesTransientDraft() throws {
        let selected = try XCTUnwrap(WorldPageCatalog.starterInstances.first)
        let store = GameStore(io: .temporary(name: "writing-collected-owner-\(UUID().uuidString)"))
        store.mutate("prepare collected bind owner") { state in
            state.base.essence = 1_000
            state.worlds.seeds = SeedSequence(rootSeed: 1)
            state.base.collectedWorldPages = [selected]
            state.base.starterWorldPageBundleFulfilled = true
        }
        let persistedPage = store.state.base.page
        store.beginWritingDeskSession()
        XCTAssertTrue(store.write("plains"))
        let transientDraft = store.writingDeskPage
        let quote = try XCTUnwrap(store.writingDeskBindQuote(selectedWorldPageID: selected.id))
        let review = try XCTUnwrap(store.writingDeskReviewModel(selectedWorldPageID: selected.id))
        XCTAssertEqual(quote.sourceKey, review.sourceKey)
        XCTAssertTrue(store.bindAndDepart(worldPageInstanceID: selected.id))
        XCTAssertEqual(store.activeRun?.book.worldPageUseReceipt?.instanceID, selected.id)
        XCTAssertFalse(store.state.base.collectedWorldPages.contains { $0.id == selected.id })
        XCTAssertEqual(store.writingDeskPage, transientDraft)
        XCTAssertEqual(store.state.base.page, persistedPage)
        XCTAssertEqual(store.activeRun?.book.allSymbolIDs,
                       BookRules.resolveBook(worldPage: selected).allSymbolIDs)
    }

    @MainActor
    func testWritingDeskTemplateLoadIsExplicitAndTargetsOnlyCurrentSession() throws {
        let store = GameStore(io: .temporary(name: "writing-template-session-\(UUID().uuidString)"))
        let persistedPage = store.state.base.page
        store.beginWritingDeskSession()
        XCTAssertTrue(store.write(.source("sun"), glyph: "sun",
                                  at: .init(column: 0, row: 0)))
        let saveResult = store.savePageTemplate(named: "Light")
        guard case .saved(let templateID) = saveResult else {
            return XCTFail("expected the real Template save path, got \(saveResult); draft=\(store.writingDeskPage)")
        }
        let templatePage = try XCTUnwrap(
            store.state.base.savedPageTemplates.first { $0.id == templateID }).page
        store.clearPage()
        XCTAssertTrue(store.writingDeskPage.runes.isEmpty)
        XCTAssertEqual(store.loadPageTemplate(templateID), .loaded(templateID))
        XCTAssertTrue(PageTemplateRules.structurallyEquivalent(store.writingDeskPage, templatePage))
        XCTAssertEqual(store.state.base.page, persistedPage)
        store.endWritingDeskSession()
        store.beginWritingDeskSession()
        XCTAssertTrue(store.writingDeskPage.runes.isEmpty,
                      "a previously selected Template must not become the next ordinary visit")
    }
    @MainActor
    func testEarthlikeTestWorldIsPermanentAndAddedToExistingCampaigns() throws {
        let earth = WorldPageCatalog.earthlikeTestInstance
        XCTAssertEqual(earth.definition.id, "earthlike_test_world")
        XCTAssertEqual(earth.definition.disposition, .reusable)
        XCTAssertEqual(earth.definition.worldPageCost, 0)
        XCTAssertEqual(earth.definition.seed, 101)
        XCTAssertEqual(Set(earth.definition.page.symbolIDs),
                       Set(["plains", "archipelago", "common_ore"]))
        let earthReadings = BookRules.readings(
            for: BookRules.resolveBook(worldPage: earth), seed: earth.definition.seed)
        XCTAssertEqual(earthReadings["illumination"].peak, 60.36, accuracy: 0.0001)
        XCTAssertEqual(earthReadings["atmosphere"].peak, 51)
        XCTAssertEqual(earthReadings["atmosphere"].aspect("clarity"), 78)
        XCTAssertLessThanOrEqual(earthReadings["vitality"].peak, 30)
        XCTAssertFalse(
            DescriptionRules.describe(earthReadings).sentence
                .localizedCaseInsensitiveContains("want of light"))
        XCTAssertTrue(earth.inspected)

        let store = GameStore(io: .temporary(name: "earthlike-page-\(UUID().uuidString)"))
        store.mutate("simulate existing campaign without Earth page", flush: true) {
            $0.base.collectedWorldPages.removeAll { $0.definition.id == earth.definition.id }
            $0.base.starterWorldPageBundleFulfilled = true
        }
        store.reconcileStarterWorldPageBundle()
        XCTAssertEqual(store.state.base.collectedWorldPages.filter {
            $0.definition.id == earth.definition.id
        }, [earth])

        let essenceBeforeTestDeparture = store.state.base.essence
        XCTAssertTrue(store.bindAndDepart(worldPageInstanceID: earth.id))
        XCTAssertEqual(store.state.base.essence, essenceBeforeTestDeparture,
                       "the reusable testing page must never charge Essence")
        XCTAssertEqual(store.activeRun?.mapSeed, earth.definition.seed)
        XCTAssertEqual(store.activeRun?.book.worldPageUseReceipt?.instanceID, earth.id)
        XCTAssertEqual(store.activeRun?.worldVisualReceipt?.request.atmosphere.medium, "none")
        XCTAssertEqual(store.activeRun?.worldVisualReceipt?.request.atmosphere.density, 0)
        let visibility = try XCTUnwrap(store.activeRun.map { WorldRules.visibilityProfile(in: $0) })
        XCTAssertEqual(visibility.illumination, 60.36, accuracy: 0.0001)
        XCTAssertEqual(visibility.obscurantDensity, 0)
        XCTAssertEqual(visibility.fringeWidth, Tuning.Visibility.defaultFringeWidth)
        let diagnostics = try XCTUnwrap(store.activeRun?.generationDiagnostics)
        XCTAssertEqual(diagnostics.creatureSpeciesCount, 2)
        XCTAssertEqual(diagnostics.creatureInstancesPlaced, 1)
        XCTAssertEqual(diagnostics.floraSpeciesCount, 0)
        XCTAssertEqual(diagnostics.floraInstancesPlaced, 0)
        XCTAssertTrue(store.state.base.collectedWorldPages.contains { $0 == earth },
                      "the permanent Earth-like page must survive every successful bind")
    }

    @MainActor
    func testNewBindFreezesOneArrivalReceiptAcrossRunAndHistoryAndOwnsPendingRoot() throws {
        let store = GameStore(io: .temporary(name: "arrival-receipt-\(UUID().uuidString)"))
        let earth = WorldPageCatalog.earthlikeTestInstance
        XCTAssertTrue(store.bindAndDepart(worldPageInstanceID: earth.id))

        let runReceipt = try XCTUnwrap(store.activeRun?.worldArrivalReceipt)
        XCTAssertTrue(WorldArrivalPresentationAuthority.isNativePresentationEnabled)
        XCTAssertEqual(store.state.worlds.pendingWorldArrivalReceiptID, runReceipt.id)
        XCTAssertEqual(store.state.worlds.pendingWorldArrivalReceipt, runReceipt)
        XCTAssertTrue(runReceipt.isNativePresentationEligible)
        XCTAssertNotNil(runReceipt.renderedSceneReceipt)
        let splash = try XCTUnwrap(runReceipt.worldSplashReceiptV3)
        XCTAssertTrue(splash.validates())
        XCTAssertEqual(splash.version, WorldSplashReceiptV3.schemaVersion)
        XCTAssertEqual(splash.worldSeed, earth.definition.seed)
        XCTAssertEqual(splash.worldVisualReceiptSHA256,
                       store.activeRun?.worldVisualReceipt?.canonicalReceiptSHA256)
        XCTAssertEqual(splash.terrain.grounds.map(\.ground), GroundType.allCases)
        XCTAssertEqual(splash.terrain.grounds.reduce(0) { $0 + $1.exactCount },
                       splash.terrain.width * splash.terrain.height)
        XCTAssertEqual(splash.terrain.regions.count, 12)
        XCTAssertEqual(splash.flora.species.count,
                       Set(store.activeRun?.map.tiles.compactMap(\.flora) ?? []).count,
                       "every placed flora identity must survive; no prefix-four truncation")
        XCTAssertEqual(splash.flora.species.map(\.placedTileCount).reduce(0, +),
                       store.activeRun?.map.tiles.count { $0.flora != nil })
        XCTAssertNotNil(WorldArrivalNativeRenderer.placeholderImage(for: splash))
        let splashCommands = try XCTUnwrap(WorldArrivalNativeRenderer.splashCommands(for: splash))
        let materialCommand = try XCTUnwrap(splashCommands.first {
            $0.scope == .terrainMass && $0.semanticID == "material-presentation"
        })
        let materialDescriptor = try splash.terrain.materialPresentation.resolvedDescriptor()
        for cell in splash.firstMapCropReceipt.cells where cell.visibility != "hidden" {
            let ground = try XCTUnwrap(cell.ground)
            let packGround = try XCTUnwrap(TerrainProductionPack.Ground(rawValue: ground.rawValue))
            let palette = try TerrainProductionPack.resolvedGroundPalette(
                packGround, descriptor: materialDescriptor)
            let encoded = ground.rawValue + "=" + palette.map {
                "\($0.red),\($0.green),\($0.blue),\($0.alpha)"
            }.joined(separator: "/")
            XCTAssertTrue(materialCommand.values.contains(encoded))
            if let floraID = cell.floraStableID {
                let species = try XCTUnwrap(splash.flora.species.first { $0.stableID == floraID })
                let identityCommand = try XCTUnwrap(splashCommands.first {
                    $0.scope == .floraIdentity && $0.semanticID == floraID
                })
                XCTAssertTrue(identityCommand.values.contains(species.renderIdentity.speciesID))
                XCTAssertEqual(species.renderIdentity.resolvedColor.srgb.count, 3)
            }
        }
        XCTAssertEqual(store.state.reality.library.visitedWorlds.last?.worldArrivalReceipt,
                       runReceipt)
        XCTAssertEqual(runReceipt.generationSeed, earth.definition.seed)
        let scene = try XCTUnwrap(runReceipt.sceneReceipt)
        XCTAssertEqual(scene.version, WorldArrivalSceneReceipt.schemaVersion)
        XCTAssertTrue(scene.validatesCanonicalHash())
        XCTAssertEqual(scene.payload.worldSeed, String(earth.definition.seed))
        XCTAssertFalse(scene.payload.illumination.band.isEmpty)
        XCTAssertFalse(scene.payload.suspendedAtmosphere.density.isEmpty)
        XCTAssertEqual(scene.payload.precipitation.medium, "none")
        XCTAssertEqual(scene.payload.precipitation.intensity, "none")
        let sceneData = try JSONEncoder().encode(scene)
        let sceneObject = try XCTUnwrap(
            JSONSerialization.jsonObject(with: sceneData) as? [String: Any])
        XCTAssertEqual(Set(sceneObject.keys), ["version", "payload", "canonicalSHA256"])
        let payloadObject = try XCTUnwrap(sceneObject["payload"] as? [String: Any])
        XCTAssertEqual(Set(payloadObject.keys), [
            "receiptID", "worldSeed", "sourcePage", "dominantGround", "waterRelationship",
            "materialDescriptor", "illumination", "suspendedAtmosphere", "precipitation",
            "flora", "causalVisualFacts", "entryDisclosure", "description", "firstMapCropReceipt"
        ])
        XCTAssertTrue(payloadObject["entryDisclosure"] is NSNull)
        let suspendedObject = try XCTUnwrap(
            payloadObject["suspendedAtmosphere"] as? [String: Any])
        XCTAssertTrue(suspendedObject["density"] is String,
                      "scene receipt must freeze a band, never expose raw density")
        XCTAssertEqual(runReceipt.sourcePagePhysicalReceipt.marks.count,
                       earth.definition.page.runes.count)
        XCTAssertFalse(String(describing: runReceipt.sourcePagePhysicalReceipt)
            .contains("MarkContent"))
        XCTAssertEqual(runReceipt.finalDescription.filter { ".!?".contains($0) }.count, 2)
        let wordCount = runReceipt.finalDescription.split(whereSeparator: \.isWhitespace).count
        XCTAssertTrue((18...55).contains(wordCount), runReceipt.finalDescription)

        let worldsRoundTrip = try JSONDecoder().decode(
            WorldsState.self, from: JSONEncoder().encode(store.state.worlds))
        XCTAssertEqual(worldsRoundTrip.activeRun?.worldArrivalReceipt, runReceipt)
        XCTAssertEqual(worldsRoundTrip.pendingWorldArrivalReceiptID, runReceipt.id)
        XCTAssertEqual(worldsRoundTrip.pendingWorldArrivalReceipt, runReceipt)
        XCTAssertEqual(worldsRoundTrip.activeRun?.worldArrivalReceipt?.worldSplashReceiptV3, splash)
        let persistedReceipt = try XCTUnwrap(JSONSerialization.jsonObject(
            with: JSONEncoder().encode(runReceipt)) as? [String: Any])
        XCTAssertNil(persistedReceipt["counterfactualPassCount"])
        XCTAssertNil(persistedReceipt["counterfactualElapsedMilliseconds"],
                     "wall-clock diagnostics must never enter frozen receipt bytes")
        var invalidObject = persistedReceipt
        var invalidSplash = try XCTUnwrap(invalidObject["worldSplashReceiptV3"] as? [String: Any])
        invalidSplash["canonicalReceiptSHA256"] = "tampered"
        invalidObject["worldSplashReceiptV3"] = invalidSplash
        let tolerant = try JSONDecoder().decode(WorldArrivalReceipt.self,
            from: JSONSerialization.data(withJSONObject: invalidObject, options: [.sortedKeys]))
        XCTAssertNil(tolerant.worldSplashReceiptV3,
                     "invalid optional v3 presentation data must not quarantine the playable run")

        let positionBeforeEnter = try XCTUnwrap(store.activeRun?.playerPosition)
        let turnBeforeEnter = try XCTUnwrap(store.activeRun?.turnsTaken)
        if let adjacent = store.activeRun?.map.neighbours(of: positionBeforeEnter).first(where: {
            store.activeRun?.map[$0].ground.isPassable == true
        }) {
            store.step(to: adjacent)
            XCTAssertEqual(store.activeRun?.playerPosition, positionBeforeEnter)
            XCTAssertEqual(store.activeRun?.turnsTaken, turnBeforeEnter)
        }
        store.endRunWithPartialHaul(reason: "blocked fixture", kind: .defeat)
        XCTAssertNotNil(store.activeRun, "arrival ownership must block defeat/return mutation")
        XCTAssertEqual(store.state.worlds.pendingWorldArrivalReceiptID, runReceipt.id)
        XCTAssertEqual(store.activeRun?.worldArrivalReceipt, runReceipt)
        XCTAssertEqual(store.state.reality.library.visitedWorlds.last?.worldArrivalReceipt,
                       runReceipt)
        XCTAssertTrue(store.enterPendingWorld(arrivalReceiptID: runReceipt.id))
        XCTAssertNil(store.state.worlds.pendingWorldArrivalReceiptID)
        XCTAssertEqual(store.activeRun?.turnsTaken, turnBeforeEnter)
        XCTAssertEqual(store.activeRun?.playerPosition, positionBeforeEnter)
        XCTAssertEqual(store.activeRun?.worldArrivalReceipt, runReceipt)
        XCTAssertFalse(store.enterPendingWorld(arrivalReceiptID: runReceipt.id),
                       "double dismissal must be a typed no-op")

        let orphan = WorldArrivalReceiptID(rawValue: "orphan")
        store.mutate("stage orphan arrival ID") {
            $0.worlds.pendingWorldArrivalReceiptID = orphan
        }
        XCTAssertTrue(store.reconcileOrphanWorldArrival())
        XCTAssertNil(store.state.worlds.pendingWorldArrivalReceiptID)
    }

    @MainActor
    func testWorldSplashV3MalformedOptionalPayloadsFailClosedWithoutQuarantiningRun() throws {
        let store = GameStore(io: .temporary(name: "splash-v3-fail-closed-\(UUID().uuidString)"))
        XCTAssertTrue(store.bindAndDepart(
            worldPageInstanceID: WorldPageCatalog.earthlikeTestInstance.id))
        let accepted = try XCTUnwrap(store.activeRun?.worldArrivalReceipt)
        let splash = try XCTUnwrap(accepted.worldSplashReceiptV3)

        func decodeWith(_ malformed: WorldSplashReceiptV3,
                        file: StaticString = #filePath, line: UInt = #line) throws {
            var outer = accepted
            outer.worldSplashReceiptV3 = malformed
            let decoded = try JSONDecoder().decode(
                WorldArrivalReceipt.self, from: JSONEncoder().encode(outer))
            XCTAssertNil(decoded.worldSplashReceiptV3, file: file, line: line)
            XCTAssertEqual(decoded.id, accepted.id, file: file, line: line)
            XCTAssertEqual(decoded.finalDescription, accepted.finalDescription, file: file, line: line)
        }

        var duplicateGround = splash
        duplicateGround.terrain.grounds[1].ground = duplicateGround.terrain.grounds[0].ground
        duplicateGround.seal()
        XCTAssertFalse(duplicateGround.validates())
        try decodeWith(duplicateGround)

        var oversizedDimensions = splash
        oversizedDimensions.terrain.width = Int.max
        oversizedDimensions.terrain.height = Int.max
        oversizedDimensions.seal()
        XCTAssertFalse(oversizedDimensions.validates())
        try decodeWith(oversizedDimensions)

        var oversizedCount = splash
        oversizedCount.terrain.grounds[0].exactCount = Int.max
        oversizedCount.seal()
        XCTAssertFalse(oversizedCount.validates())
        try decodeWith(oversizedCount)

        var inconsistentRegionBand = splash
        inconsistentRegionBand.terrain.regions[0].groundShares[0].band =
            inconsistentRegionBand.terrain.regions[0].groundShares[0].band == .dominant
                ? .none : .dominant
        inconsistentRegionBand.seal()
        XCTAssertFalse(inconsistentRegionBand.validates())
        try decodeWith(inconsistentRegionBand)

        if splash.relief.elevatedComponentSizes.count > 1 {
            var unsortedComponents = splash
            unsortedComponents.relief.elevatedComponentSizes.reverse()
            unsortedComponents.seal()
            XCTAssertFalse(unsortedComponents.validates())
            try decodeWith(unsortedComponents)
        }

        var inconsistentEnvironment = splash
        inconsistentEnvironment.environment.precipitationMedium = "none"
        inconsistentEnvironment.environment.precipitationIntensity = "heavy"
        inconsistentEnvironment.seal()
        XCTAssertFalse(inconsistentEnvironment.validates())
        try decodeWith(inconsistentEnvironment)

        var impossibleSouthContacts = splash
        impossibleSouthContacts.relief.southContactCounts[0] = Int.max
        impossibleSouthContacts.seal()
        XCTAssertFalse(impossibleSouthContacts.validates())
        try decodeWith(impossibleSouthContacts)

        var emptyOpportunityID = splash
        emptyOpportunityID.explorationOpportunities.resources = [
            .init(stableID: "", sourceCount: 1, obtainableQuantity: 1, causalMarkIDs: [])
        ]
        emptyOpportunityID.seal()
        XCTAssertFalse(emptyOpportunityID.validates())
        try decodeWith(emptyOpportunityID)

        var zeroOpportunity = splash
        zeroOpportunity.explorationOpportunities.resources = [
            .init(stableID: "silver", sourceCount: 0, obtainableQuantity: 1, causalMarkIDs: [])
        ]
        zeroOpportunity.seal()
        XCTAssertFalse(zeroOpportunity.validates())
        try decodeWith(zeroOpportunity)

        for (kind, stableID) in [("resource", "not_a_catalogue_resource")] {
            var unknown = splash
            let row = WorldSplashReceiptV3.ExplorationOpportunityRow(
                stableID: stableID, sourceCount: 1, obtainableQuantity: 1, causalMarkIDs: [])
            unknown.explorationOpportunities.resources = [row]
            unknown.seal()
            XCTAssertFalse(unknown.validates(), "unknown \(kind) must fail closed")
            try decodeWith(unknown)
        }

        for stableID in ["ore", "essence_raw"] {
            var ineligible = splash
            ineligible.explorationOpportunities.resources = [
                .init(stableID: stableID, sourceCount: 1,
                      obtainableQuantity: 1, causalMarkIDs: [])
            ]
            ineligible.seal()
            XCTAssertFalse(ineligible.validates(), "\(stableID) is not rare/precious")
            try decodeWith(ineligible)
        }

        var crossFamilyOwner = splash
        let wrongOwner = WorldArrivalReceipt.CausalVisualFact(
            candidateMarkID: .init(rawValue: 987_654), semanticKey: "verdant",
            markDisplayName: "Verdant", sourcePageOrder: 0, scope: .resource,
            contributionKind: .increased, resultBand: "present", withoutAuthoredBand: "absent")
        crossFamilyOwner.causalVisualFacts.append(wrongOwner)
        crossFamilyOwner.explorationOpportunities.resources = [
            .init(stableID: "ore", sourceCount: 1, obtainableQuantity: 1,
                  causalMarkIDs: [wrongOwner.candidateMarkID])
        ]
        crossFamilyOwner.seal()
        XCTAssertFalse(crossFamilyOwner.validates(),
                       "a valid resource fact cannot own a family its symbol does not register")
        try decodeWith(crossFamilyOwner)

        var nonIncreasingOwner = splash
        let reducedOre = WorldArrivalReceipt.CausalVisualFact(
            candidateMarkID: .init(rawValue: 987_655), semanticKey: "common_ore",
            markDisplayName: "Ore", sourcePageOrder: 0, scope: .resource,
            contributionKind: .reduced, resultBand: "present", withoutAuthoredBand: "present")
        nonIncreasingOwner.causalVisualFacts.append(reducedOre)
        nonIncreasingOwner.explorationOpportunities.resources = [
            .init(stableID: "ore", sourceCount: 1, obtainableQuantity: 1,
                  causalMarkIDs: [reducedOre.candidateMarkID])
        ]
        nonIncreasingOwner.seal()
        XCTAssertFalse(nonIncreasingOwner.validates(),
                       "ordinary Ore requires a positive same-seed causal quantity delta")
        try decodeWith(nonIncreasingOwner)

        var unsortedOpportunities = splash
        unsortedOpportunities.explorationOpportunities.resources = [
            .init(stableID: "silver", sourceCount: 1, obtainableQuantity: 1, causalMarkIDs: []),
            .init(stableID: "gold", sourceCount: 1, obtainableQuantity: 1, causalMarkIDs: [])
        ]
        unsortedOpportunities.seal()
        XCTAssertFalse(unsortedOpportunities.validates())
        try decodeWith(unsortedOpportunities)

        var overCapacityOpportunities = splash
        let opportunityTileCount = splash.terrain.width * splash.terrain.height
        overCapacityOpportunities.explorationOpportunities.resources =
            ["adamant", "gold", "mercury", "silver"].map {
                .init(stableID: $0, sourceCount: opportunityTileCount,
                      obtainableQuantity: opportunityTileCount
                        * WorldSplashReceiptV3.maximumObtainableQuantityPerSource,
                      causalMarkIDs: [])
            }
        overCapacityOpportunities.seal()
        XCTAssertFalse(overCapacityOpportunities.validates())
        XCTAssertNil(WorldArrivalNativeRenderer.placeholderImage(
            for: overCapacityOpportunities, size: .init(width: 320, height: 360)))
        try decodeWith(overCapacityOpportunities)

        var duplicateCropPoint = splash
        duplicateCropPoint.firstMapCropReceipt.cells[1].point =
            duplicateCropPoint.firstMapCropReceipt.cells[0].point
        duplicateCropPoint.seal()
        XCTAssertFalse(duplicateCropPoint.validates())
        try decodeWith(duplicateCropPoint)

        var hiddenPayload = splash
        hiddenPayload.firstMapCropReceipt.cells[0].visibility = "hidden"
        hiddenPayload.firstMapCropReceipt.cells[0].ground = .stone
        hiddenPayload.firstMapCropReceipt.cells[0].elevation = 0
        hiddenPayload.seal()
        XCTAssertFalse(hiddenPayload.validates())
        try decodeWith(hiddenPayload)

        var fringeFlora = splash
        fringeFlora.firstMapCropReceipt.cells[0].visibility = "fringe"
        fringeFlora.firstMapCropReceipt.cells[0].ground = .stone
        fringeFlora.firstMapCropReceipt.cells[0].elevation = 0
        fringeFlora.firstMapCropReceipt.cells[0].floraStableID = "flora-1"
        fringeFlora.seal()
        XCTAssertFalse(fringeFlora.validates())
        try decodeWith(fringeFlora)

        var unknownFlora = splash
        unknownFlora.firstMapCropReceipt.cells[0].visibility = "full"
        unknownFlora.firstMapCropReceipt.cells[0].ground = .stone
        unknownFlora.firstMapCropReceipt.cells[0].elevation = 0
        unknownFlora.firstMapCropReceipt.cells[0].floraStableID = "flora-18446744073709551615"
        unknownFlora.seal()
        XCTAssertFalse(unknownFlora.validates())
        try decodeWith(unknownFlora)

        var elevationFour = splash
        elevationFour.firstMapCropReceipt.cells[0].visibility = "full"
        elevationFour.firstMapCropReceipt.cells[0].ground = .stone
        elevationFour.firstMapCropReceipt.cells[0].elevation = 4
        elevationFour.firstMapCropReceipt.cells[0].floraStableID = nil
        elevationFour.seal()
        XCTAssertFalse(elevationFour.validates())
        try decodeWith(elevationFour)

        var foreignValid = splash
        foreignValid.receiptID = .init(rawValue: splash.receiptID.rawValue + "-foreign")
        foreignValid.seal()
        XCTAssertTrue(foreignValid.validates())
        try decodeWith(foreignValid)

        var divergentDescription = splash
        divergentDescription.finalDescription += " "
        divergentDescription.seal()
        XCTAssertTrue(divergentDescription.validates())
        try decodeWith(divergentDescription)

        if var mark = splash.entryMark, let first = mark.cells.first {
            mark.cells.append(first)
            var duplicateCell = splash
            duplicateCell.entryMark = mark
            duplicateCell.seal()
            XCTAssertFalse(duplicateCell.validates())
            try decodeWith(duplicateCell)
        }
    }

    func testWorldSplashWaterTopologyUsesAuthoredOwnershipAndFinalConnectedGeometry() throws {
        func map(wet: [GridPoint: GroundType], width: Int = 12, height: Int = 12) -> WorldMap {
            var result = WorldMap(width: width, height: height,
                tiles: Array(repeating: Tile(ground: .soil), count: width * height),
                entry: .init(x: 0, y: 0))
            for (point, ground) in wet { result[point] = Tile(ground: ground) }
            return result
        }
        func regions(_ points: Set<GridPoint>, width: Int = 12, height: Int = 12) -> [Int] {
            (0..<12).map { region in
                let column = region % 4, row = region / 4
                return points.count { point in
                    min(3, point.x * 4 / width) == column && min(2, point.y * 3 / height) == row
                }
            }
        }
        func observation(standing: Set<GridPoint> = [], flowing: Set<GridPoint> = [],
                         frozen: Set<GridPoint> = [], standingBodies: [Int] = [],
                         channels: [Int] = [], frozenBodies: [Int] = [],
                         standingDeep: Int = 0, flowingDeep: Int = 0) -> WorldHydrologyTopologyObservation {
            .init(standingTiles: standing.count, flowingTiles: flowing.count, frozenTiles: frozen.count,
                  standingDeepTiles: standingDeep, flowingDeepTiles: flowingDeep,
                  standingBodySizes: standingBodies, flowingChannelSizes: channels,
                  frozenBodySizes: frozenBodies, standingRegionCounts: regions(standing),
                  flowingRegionCounts: regions(flowing), frozenRegionCounts: regions(frozen))
        }

        let pond = Set([GridPoint(x: 1, y: 1), .init(x: 1, y: 2), .init(x: 2, y: 1), .init(x: 2, y: 2)])
        let lake = Set((7...9).flatMap { y in (7...9).map { GridPoint(x: $0, y: y) } })
        var standingGrounds = Dictionary(uniqueKeysWithValues: pond.union(lake).map { ($0, GroundType.water) })
        let deep = GridPoint(x: 8, y: 8); standingGrounds[deep] = .deepWater
        let mixedStanding = try XCTUnwrap(WorldArrivalReceiptFactory.splashWaterProfile(
            map: map(wet: standingGrounds), observation: observation(
                standing: pond.union(lake), standingBodies: [4, 9], standingDeep: 1)))
        XCTAssertTrue(mixedStanding.topologyFlags.contains(.pool))
        XCTAssertTrue(mixedStanding.topologyFlags.contains(.lake))
        XCTAssertTrue(mixedStanding.topologyFlags.contains(.shelf))
        XCTAssertEqual(mixedStanding.dominantTopology, .standing)

        let channel = Set((2...8).map { GridPoint(x: $0, y: 5) })
        var channelGrounds = Dictionary(uniqueKeysWithValues: channel.map { ($0, GroundType.water) })
        channelGrounds[.init(x: 5, y: 5)] = .deepWater
        let flowing = try XCTUnwrap(WorldArrivalReceiptFactory.splashWaterProfile(
            map: map(wet: channelGrounds), observation: observation(
                flowing: channel, channels: [channel.count], flowingDeep: 1)))
        XCTAssertEqual(flowing.dominantTopology, .flowing)
        XCTAssertTrue(flowing.topologyFlags.contains(.channel))
        XCTAssertFalse(flowing.topologyFlags.contains(.shelf),
                       "flowing depth stays visibly deep without becoming a Standing shelf")

        let ring = Set([GridPoint(x: 4, y: 4), .init(x: 5, y: 4), .init(x: 6, y: 4),
                        .init(x: 4, y: 5), .init(x: 6, y: 5),
                        .init(x: 4, y: 6), .init(x: 5, y: 6), .init(x: 6, y: 6)])
        let frozenIsland = try XCTUnwrap(WorldArrivalReceiptFactory.splashWaterProfile(
            map: map(wet: Dictionary(uniqueKeysWithValues: ring.map { ($0, GroundType.ice) })),
            observation: observation(frozen: ring, frozenBodies: [ring.count])))
        XCTAssertNil(frozenIsland.dominantTopology)
        XCTAssertTrue(frozenIsland.topologyFlags.contains(.island))
        XCTAssertTrue(frozenIsland.topologyFlags.contains(.broken))

        let twoPonds: Set<GridPoint> = [.init(x: 2, y: 2), .init(x: 9, y: 9)]
        let ordinaryPonds = try XCTUnwrap(WorldArrivalReceiptFactory.splashWaterProfile(
            map: map(wet: Dictionary(uniqueKeysWithValues: twoPonds.map { ($0, GroundType.water) })),
            observation: observation(standing: twoPonds, standingBodies: [1, 1])))
        XCTAssertFalse(ordinaryPonds.topologyFlags.contains(.broken),
                       "separate ordinary Standing ponds are not broken water structure")

        let standingMass: Set<GridPoint> = [.init(x: 2, y: 2), .init(x: 3, y: 2),
                                             .init(x: 2, y: 3), .init(x: 3, y: 3)]
        let joinedFlow: Set<GridPoint> = [.init(x: 4, y: 3), .init(x: 5, y: 3), .init(x: 6, y: 3)]
        let joinedWet = Dictionary(uniqueKeysWithValues:
            standingMass.union(joinedFlow).map { ($0, GroundType.water) })
        let standingDominant = try XCTUnwrap(WorldArrivalReceiptFactory.splashWaterProfile(
            map: map(wet: joinedWet), observation: observation(
                standing: standingMass, flowing: joinedFlow,
                standingBodies: [standingMass.count], channels: [joinedFlow.count])))
        XCTAssertEqual(standingDominant.dominantTopology, .standing)
        XCTAssertEqual(standingDominant.finalConnectedBodyCount, 1,
                       "a joined channel/body is one final wet component")

        let tiedFlow: Set<GridPoint> = joinedFlow.union([.init(x: 7, y: 3)])
        let tied = try XCTUnwrap(WorldArrivalReceiptFactory.splashWaterProfile(
            map: map(wet: Dictionary(uniqueKeysWithValues:
                standingMass.union(tiedFlow).map { ($0, GroundType.water) })),
            observation: observation(standing: standingMass, flowing: tiedFlow,
                standingBodies: [standingMass.count], channels: [tiedFlow.count])))
        XCTAssertEqual(tied.dominantTopology, .standing,
                       "Standing wins the exact final-owned-tile tie deterministically")

        let flowingMass = tiedFlow.union([.init(x: 8, y: 3)])
        let flowingDominant = try XCTUnwrap(WorldArrivalReceiptFactory.splashWaterProfile(
            map: map(wet: Dictionary(uniqueKeysWithValues:
                standingMass.union(flowingMass).map { ($0, GroundType.water) })),
            observation: observation(standing: standingMass, flowing: flowingMass,
                standingBodies: [standingMass.count], channels: [flowingMass.count])))
        XCTAssertEqual(flowingDominant.dominantTopology, .flowing)

        let remoteFlow: Set<GridPoint> = [.init(x: 9, y: 8), .init(x: 9, y: 9)]
        let disconnected = try XCTUnwrap(WorldArrivalReceiptFactory.splashWaterProfile(
            map: map(wet: Dictionary(uniqueKeysWithValues:
                standingMass.union(remoteFlow).map { ($0, GroundType.water) })),
            observation: observation(standing: standingMass, flowing: remoteFlow,
                standingBodies: [standingMass.count], channels: [remoteFlow.count])))
        XCTAssertEqual(disconnected.finalConnectedBodyCount, 2,
                       "final disconnected wet components, not authored record count, own the exact receipt")
    }

    @MainActor
    func testWorldSplashPlaceholderIsCanonicalOneXAndRetainsMixedRegionalFacts() throws {
        let store = GameStore(io: .temporary(name: "splash-v3-pixels-\(UUID().uuidString)"))
        XCTAssertTrue(store.bindAndDepart(
            worldPageInstanceID: WorldPageCatalog.earthlikeTestInstance.id))
        let run = try XCTUnwrap(store.activeRun)
        let outer = try XCTUnwrap(run.worldArrivalReceipt)
        let original = try XCTUnwrap(outer.worldSplashReceiptV3)
        let environment = try XCTUnwrap(outer.environmentSummary)
        let visual = try XCTUnwrap(run.worldVisualReceipt)

        // O05/O06 use the real bind-time same-seed causal intervention, not a fabricated fact.
        let oreStore = GameStore(io: .temporary(name: "splash-v3-o05-\(UUID().uuidString)"))
        let stoneHollow = try XCTUnwrap(WorldPageCatalog.starterInstances.first {
            $0.definition.id == WorldPageCatalog.stoneHollowID
        })
        XCTAssertTrue(oreStore.bindAndDepart(worldPageInstanceID: stoneHollow.id))
        let oreRun = try XCTUnwrap(oreStore.activeRun)
        let oreOuter = try XCTUnwrap(oreRun.worldArrivalReceipt)
        let oreSplash = try XCTUnwrap(oreOuter.worldSplashReceiptV3)
        let productionOreFact = oreOuter.causalVisualFacts.first {
            $0.scope == .resource && $0.semanticKey == "common_ore"
                && $0.contributionKind == .increased
        }
        let productionOreRow = oreSplash.explorationOpportunities.resources.first {
            $0.stableID == Resources.ore.rawValue
        }
        let definition = stoneHollow.definition
        let visibleMarks = definition.page.runes.map { mark in
            WritingDeskVisibleMark(rendererAssetKey: mark.glyphID,
                visualRoute: mark.personalCompound == nil ? .authored(.source)
                    : .personalCompoundCompatibility,
                id: mark.id, hand: mark.hand, origin: mark.origin, shapeID: mark.shapeID,
                cells: mark.cells, inkRecipe: mark.inkRecipe, displayName: mark.displayName,
                accessibilityName: mark.displayName, isReadable: true)
        }
        let candidates = WorldArrivalCausalCandidateRules.candidates(
            page: definition.page, visibleMarks: visibleMarks)
        func counterfactual(_ semanticKey: String) throws -> Worldgen.ArrivalCausalSummary {
            let candidate = try XCTUnwrap(candidates.first { $0.semanticKey == semanticKey })
            let removed = try XCTUnwrap(WorldArrivalCausalCandidateRules.removing(
                candidate, from: definition.page))
            var removedBook = BookRules.resolveBook(page: removed)
            removedBook.worldPageUseReceipt = oreRun.book.worldPageUseReceipt
            let intervention = PressureRules.causalIntervention(
                actualAuthored: BookRules.sigils(for: oreRun.book),
                remainingAuthored: BookRules.sigils(for: removedBook), seed: oreRun.mapSeed)
            return Worldgen.arrivalCausalSummary(
                book: removedBook, seed: oreRun.mapSeed,
                terrain: .init(readings: intervention.readings,
                               resolvedSigils: intervention.counterfactualSigils),
                library: oreStore.state.reality.library, tuning: oreRun.tuning,
                isFreshFirstExpedition: true, wildPageSelection: nil,
                wildPageOriginRunIndex: oreRun.runIndex)
        }
        let withoutOre = try counterfactual("common_ore")
        let withoutOreQuantity = WorldArrivalCausalCandidateRules.resourceQuantity(
            Resources.ore, in: withoutOre.map)
        let actualOreQuantity = WorldArrivalCausalCandidateRules.resourceQuantity(
            Resources.ore, in: oreRun.map)
        if actualOreQuantity > withoutOreQuantity {
            let fact = try XCTUnwrap(productionOreFact)
            let row = try XCTUnwrap(productionOreRow)
            XCTAssertTrue(row.causalMarkIDs.contains(fact.candidateMarkID))
            XCTAssertEqual(row.obtainableQuantity, actualOreQuantity)
        } else {
            XCTAssertNil(productionOreFact)
            XCTAssertNil(productionOreRow,
                         "ordinary Ore without positive same-seed causality stays absent")
        }

        let floraStore = GameStore(io: .temporary(name: "splash-v3-o06-\(UUID().uuidString)"))
        let openMeadow = try XCTUnwrap(WorldPageCatalog.starterInstances.first {
            $0.definition.id == WorldPageCatalog.openMeadowID
        })
        XCTAssertTrue(floraStore.bindAndDepart(worldPageInstanceID: openMeadow.id))
        let floraRun = try XCTUnwrap(floraStore.activeRun)
        let floraOuter = try XCTUnwrap(floraRun.worldArrivalReceipt)
        let floraSplash = try XCTUnwrap(floraOuter.worldSplashReceiptV3)
        let productionFloraFact = try XCTUnwrap(floraOuter.causalVisualFacts.first {
            $0.scope == .flora && $0.semanticKey == "verdant"
        })
        XCTAssertEqual(floraSplash.flora.occupiedTileCount,
                       floraRun.map.tiles.count { $0.flora != nil })
        let meadowDefinition = openMeadow.definition
        let meadowCandidate = try XCTUnwrap(WorldArrivalCausalCandidateRules.candidates(
            page: meadowDefinition.page,
            visibleMarks: meadowDefinition.page.runes.map { mark in
                WritingDeskVisibleMark(rendererAssetKey: mark.glyphID,
                    visualRoute: mark.personalCompound == nil ? .authored(.source)
                        : .personalCompoundCompatibility, id: mark.id, hand: mark.hand,
                    origin: mark.origin, shapeID: mark.shapeID, cells: mark.cells,
                    inkRecipe: mark.inkRecipe, displayName: mark.displayName,
                    accessibilityName: mark.displayName, isReadable: true)
            }).first { $0.semanticKey == "verdant" })
        let meadowRemoved = try XCTUnwrap(WorldArrivalCausalCandidateRules.removing(
            meadowCandidate, from: meadowDefinition.page))
        var meadowBook = BookRules.resolveBook(page: meadowRemoved)
        meadowBook.worldPageUseReceipt = floraRun.book.worldPageUseReceipt
        let meadowIntervention = PressureRules.causalIntervention(
            actualAuthored: BookRules.sigils(for: floraRun.book),
            remainingAuthored: BookRules.sigils(for: meadowBook), seed: floraRun.mapSeed)
        let withoutVerdant = Worldgen.arrivalCausalSummary(
            book: meadowBook, seed: floraRun.mapSeed,
            terrain: .init(readings: meadowIntervention.readings,
                           resolvedSigils: meadowIntervention.counterfactualSigils),
            library: floraStore.state.reality.library, tuning: floraRun.tuning,
            isFreshFirstExpedition: true, wildPageSelection: nil,
            wildPageOriginRunIndex: floraRun.runIndex)
        let withoutVerdantCount = withoutVerdant.map.tiles.count { $0.flora != nil }
        if productionFloraFact.contributionKind == .increased {
            XCTAssertGreaterThan(floraSplash.flora.occupiedTileCount, withoutVerdantCount)
        } else if productionFloraFact.contributionKind == .reduced {
            XCTAssertLessThan(floraSplash.flora.occupiedTileCount, withoutVerdantCount)
        } else {
            XCTAssertNotEqual(floraSplash.flora.occupiedTileCount, withoutVerdantCount)
        }
        var withoutFloraCue = floraSplash
        withoutFloraCue.flora = .init(placedIdentityCount: 0, occupiedTileCount: 0,
                                      aggregateCoverage: .none, species: [])
        for index in withoutFloraCue.terrain.regions.indices {
            withoutFloraCue.terrain.regions[index].floraShares = []
        }
        for index in withoutFloraCue.firstMapCropReceipt.cells.indices {
            withoutFloraCue.firstMapCropReceipt.cells[index].floraStableID = nil
        }
        withoutFloraCue.seal()
        XCTAssertTrue(withoutFloraCue.validates())
        let floraScopes: Set<WorldArrivalNativeRenderer.SplashCommand.Scope> = [
            .floraIdentity, .floraDistribution
        ]
        let floraCommands = try XCTUnwrap(WorldArrivalNativeRenderer.splashCommands(for: floraSplash))
        let noFloraCommands = try XCTUnwrap(WorldArrivalNativeRenderer.splashCommands(for: withoutFloraCue))
        XCTAssertEqual(floraCommands.filter { !floraScopes.contains($0.scope) },
                       noFloraCommands.filter { !floraScopes.contains($0.scope) },
                       "O06 the production Verdant delta owns only flora command scopes")
        let withoutVerdantVisual = try WorldGrade2BindAdapter.makeReceipt(
            book: meadowBook, mapSeed: floraRun.mapSeed,
            map: withoutVerdant.map, flora: withoutVerdant.flora)
        let withoutVerdantHydrology = try XCTUnwrap(
            floraRun.generationDiagnostics.hydrologyTopology)
        XCTAssertNotNil(WorldArrivalReceiptFactory.splashWaterProfile(
            map: withoutVerdant.map, observation: withoutVerdantHydrology))
        var withoutVerdantCrop = floraOuter.firstMapCropReceipt
        for index in withoutVerdantCrop.cells.indices {
            let point = withoutVerdantCrop.cells[index].point
            guard withoutVerdantCrop.cells[index].visibility != "hidden" else { continue }
            withoutVerdantCrop.cells[index].ground = withoutVerdant.map[point].ground
            withoutVerdantCrop.cells[index].elevation = withoutVerdant.map[point].elevation
            withoutVerdantCrop.cells[index].floraStableID =
                withoutVerdantCrop.cells[index].visibility == "full"
                ? withoutVerdant.map[point].flora.map { "flora-\($0.rawValue)" } : nil
        }
        let factoryWithoutVerdant = try XCTUnwrap(WorldArrivalReceiptFactory.makeSplashV3(
            receiptID: floraOuter.id, generationSeed: floraRun.mapSeed,
            sourcePage: floraOuter.sourcePagePhysicalReceipt,
            visualReceipt: withoutVerdantVisual, map: withoutVerdant.map,
            flora: withoutVerdant.flora,
            hydrologyTopology: withoutVerdantHydrology,
            environment: try XCTUnwrap(floraOuter.environmentSummary),
            illuminationSourceClass: floraOuter.illumination.sourceClass,
            motionBand: floraSplash.environment.suspendedMotion,
            causalFacts: floraOuter.causalVisualFacts, crop: withoutVerdantCrop,
            description: floraOuter.finalDescription))
        var withoutVerdantSplash = floraSplash
        withoutVerdantSplash.flora = factoryWithoutVerdant.flora
        for region in withoutVerdantSplash.terrain.regions.indices {
            withoutVerdantSplash.terrain.regions[region].floraShares =
                factoryWithoutVerdant.terrain.regions[region].floraShares
        }
        for index in withoutVerdantSplash.firstMapCropReceipt.cells.indices {
            withoutVerdantSplash.firstMapCropReceipt.cells[index].floraStableID =
                factoryWithoutVerdant.firstMapCropReceipt.cells[index].floraStableID
        }
        withoutVerdantSplash.seal()
        XCTAssertTrue(withoutVerdantSplash.validates())
        let withoutVerdantCommands = try XCTUnwrap(
            WorldArrivalNativeRenderer.splashCommands(for: withoutVerdantSplash))
        XCTAssertEqual(floraCommands.filter { !floraScopes.contains($0.scope) },
                       withoutVerdantCommands.filter { !floraScopes.contains($0.scope) })
        if productionFloraFact.contributionKind == .increased {
            let actualPixels = try rgba(try XCTUnwrap(WorldArrivalNativeRenderer.placeholderImage(
                for: floraSplash, size: .init(width: 320, height: 360))))
            let withoutPixels = try rgba(try XCTUnwrap(WorldArrivalNativeRenderer.placeholderImage(
                for: withoutVerdantSplash, size: .init(width: 320, height: 360))))
            let barePixels = try rgba(try XCTUnwrap(WorldArrivalNativeRenderer.placeholderImage(
                for: withoutFloraCue, size: .init(width: 320, height: 360))))
            XCTAssertGreaterThan(changedPixels(actualPixels, barePixels).count,
                                 changedPixels(withoutPixels, barePixels).count,
                                 "real Open Meadow Verdant must own strictly more flora pixels")
        }

        func regionalCounts(_ points: Set<GridPoint>, width: Int, height: Int) -> [Int] {
            (0..<12).map { region in points.count { point in
                min(3, point.x * 4 / width) == region % 4
                    && min(2, point.y * 3 / height) == region / 4
            } }
        }
        func make(_ map: WorldMap, standing: Set<GridPoint>, flowing: Set<GridPoint>,
                  frozen: Set<GridPoint>, standingBodies: [Int], channels: [Int],
                  frozenBodies: [Int], standingDeep: Int, flowingDeep: Int,
                  flora: [Flora] = [], sites: [PlacedSite] = [],
                  causalFacts: [WorldArrivalReceipt.CausalVisualFact]? = nil,
                  causalResourceOwners: [ResourceID: [InstanceID]] = [:]) throws
            -> WorldSplashReceiptV3 {
            let observation = WorldHydrologyTopologyObservation(
                standingTiles: standing.count, flowingTiles: flowing.count, frozenTiles: frozen.count,
                standingDeepTiles: standingDeep, flowingDeepTiles: flowingDeep,
                standingBodySizes: standingBodies, flowingChannelSizes: channels,
                frozenBodySizes: frozenBodies,
                standingRegionCounts: regionalCounts(standing, width: map.width, height: map.height),
                flowingRegionCounts: regionalCounts(flowing, width: map.width, height: map.height),
                frozenRegionCounts: regionalCounts(frozen, width: map.width, height: map.height))
            let usedVisual = flora.isEmpty ? visual : try WorldGrade2BindAdapter.makeReceipt(
                book: run.book, mapSeed: run.mapSeed, map: map, flora: flora)
            let crop = WorldArrivalReceiptFactory.firstCrop(
                map: map, flora: flora,
                profile: WorldRules.visibilityProfile(illumination: 100, baseRadius: 8))
            return try XCTUnwrap(WorldArrivalReceiptFactory.makeSplashV3(
                receiptID: outer.id, generationSeed: outer.generationSeed,
                sourcePage: outer.sourcePagePhysicalReceipt, visualReceipt: usedVisual,
                map: map, flora: flora, sites: sites, hydrologyTopology: observation,
                environment: environment,
                illuminationSourceClass: original.environment.illuminationSourceClass,
                motionBand: original.environment.suspendedMotion,
                causalFacts: causalFacts ?? outer.causalVisualFacts,
                causalResourceOwners: causalResourceOwners, crop: crop,
                description: outer.finalDescription))
        }
        func rgba(_ image: UIImage) throws -> Data {
            let cg = try XCTUnwrap(image.cgImage)
            return try XCTUnwrap(cg.dataProvider?.data) as Data
        }
        func changedPixels(_ lhs: Data, _ rhs: Data) -> Set<Int> {
            precondition(lhs.count == rhs.count)
            return Set(stride(from: 0, to: lhs.count, by: 4).compactMap { offset in
                lhs[offset..<(offset + 4)] == rhs[offset..<(offset + 4)] ? nil : offset / 4
            })
        }
        func containsRGB(_ data: Data, _ rgb: [Int], tolerance: Int = 1) -> Bool {
            guard rgb.count == 3 else { return false }
            func close(_ lhs: Int, _ rhs: Int) -> Bool { abs(lhs - rhs) <= tolerance }
            for offset in stride(from: 0, to: data.count, by: 4) {
                let first = Int(data[offset]), middle = Int(data[offset + 1])
                let third = Int(data[offset + 2])
                if (close(first, rgb[0]) && close(middle, rgb[1]) && close(third, rgb[2]))
                    || (close(first, rgb[2]) && close(middle, rgb[1]) && close(third, rgb[0])) {
                    return true
                }
            }
            return false
        }

        let repeatedA = try XCTUnwrap(WorldArrivalNativeRenderer.placeholderImage(
            for: original, size: .init(width: 320, height: 360)))
        let repeatedB = try XCTUnwrap(WorldArrivalNativeRenderer.placeholderImage(
            for: original, size: .init(width: 320, height: 360)))
        XCTAssertEqual(repeatedA.cgImage?.width, 320)
        XCTAssertEqual(repeatedA.cgImage?.height, 360)
        XCTAssertEqual(try rgba(repeatedA), try rgba(repeatedB))

        var map = WorldMap(width: 12, height: 12,
            tiles: Array(repeating: Tile(ground: .soil), count: 144), entry: .init(x: 0, y: 0))
        // One region deliberately owns dry majority plus shallow, deep and frozen water together.
        let standing: Set<GridPoint> = [.init(x: 0, y: 0), .init(x: 1, y: 0)]
        let flowing: Set<GridPoint> = [.init(x: 2, y: 0)]
        let frozen: Set<GridPoint> = [.init(x: 0, y: 1)]
        map[.init(x: 0, y: 0)] = Tile(ground: .water)
        map[.init(x: 1, y: 0)] = Tile(ground: .deepWater)
        map[.init(x: 2, y: 0)] = Tile(ground: .water)
        map[.init(x: 0, y: 1)] = Tile(ground: .ice)
        map[.init(x: 1, y: 1)] = Tile(ground: .stone)
        let mixed = try make(map, standing: standing, flowing: flowing, frozen: frozen,
                             standingBodies: [2], channels: [1], frozenBodies: [1],
                             standingDeep: 1, flowingDeep: 0)
        let mixedRepeat = try make(map, standing: standing, flowing: flowing, frozen: frozen,
                                   standingBodies: [2], channels: [1], frozenBodies: [1],
                                   standingDeep: 1, flowingDeep: 0)
        XCTAssertEqual(mixed, mixedRepeat, "C02 identical factory inputs must freeze one receipt")
        XCTAssertEqual(WorldArrivalNativeRenderer.splashCommands(for: mixed),
                       WorldArrivalNativeRenderer.splashCommands(for: mixedRepeat))
        let firstRegion = mixed.terrain.regions[0]
        XCTAssertGreaterThan(firstRegion.groundShares.first { $0.id == "soil" }!.exactCount,
                             firstRegion.waterShares.reduce(0) { $0 + $1.exactCount })
        XCTAssertEqual(firstRegion.waterShares.map(\.exactCount), [2, 1, 1])
        XCTAssertEqual(Set(firstRegion.elevationShares.filter { $0.exactCount > 0 }.map(\.id)), ["0"])
        let mixedImage = try XCTUnwrap(WorldArrivalNativeRenderer.placeholderImage(
            for: mixed, size: .init(width: 320, height: 360)))
        let mixedPixels = try rgba(mixedImage)
        let mixedDescriptor = try mixed.terrain.materialPresentation.resolvedDescriptor()
        func paletteRGBs(_ ground: TerrainProductionPack.Ground) throws -> [[Int]] {
            try TerrainProductionPack.resolvedGroundPalette(ground, descriptor: mixedDescriptor)
                .map { [Int($0.red), Int($0.green), Int($0.blue)] }
        }
        XCTAssertTrue(try paletteRGBs(.stone).contains { containsRGB(mixedPixels, $0) },
                      "T01 represented secondary Stone mass must survive in pixels")
        XCTAssertTrue(try paletteRGBs(.water).contains { containsRGB(mixedPixels, $0) },
                      "W03 shallow Water palette ownership must survive in mixed pixels")
        XCTAssertTrue(try paletteRGBs(.deepWater).contains { containsRGB(mixedPixels, $0) },
                      "W03 DeepWater palette ownership must survive in mixed pixels")
        XCTAssertTrue(try paletteRGBs(.ice).contains { containsRGB(mixedPixels, $0) },
                      "W04 frozen Water palette ownership must survive in mixed pixels")
        XCTAssertEqual(try rgba(mixedImage),
                       try rgba(try XCTUnwrap(WorldArrivalNativeRenderer.placeholderImage(
                        for: mixedRepeat, size: .init(width: 320, height: 360)))))
        XCTAssertNotEqual(try rgba(mixedImage), try rgba(repeatedA))

        // W01-W04: the same liquid census retains authored Standing versus Flowing geometry;
        // shallow/deep/frozen remain separately visible rather than collapsing into one fill.
        let allLiquid = standing.union(flowing)
        let allStanding = try make(map, standing: allLiquid, flowing: [], frozen: frozen,
                                   standingBodies: [allLiquid.count], channels: [], frozenBodies: [1],
                                   standingDeep: 1, flowingDeep: 0)
        let allFlowing = try make(map, standing: [], flowing: allLiquid, frozen: frozen,
                                  standingBodies: [], channels: [allLiquid.count], frozenBodies: [1],
                                  standingDeep: 0, flowingDeep: 1)
        let standingCommands = try XCTUnwrap(WorldArrivalNativeRenderer.splashCommands(for: allStanding))
        let flowingCommands = try XCTUnwrap(WorldArrivalNativeRenderer.splashCommands(for: allFlowing))
        XCTAssertNotEqual(standingCommands.filter { $0.scope == .waterStructure },
                          flowingCommands.filter { $0.scope == .waterStructure })
        XCTAssertEqual(standingCommands.filter { $0.scope != .waterStructure },
                       flowingCommands.filter { $0.scope != .waterStructure })
        XCTAssertNotEqual(try rgba(try XCTUnwrap(WorldArrivalNativeRenderer.placeholderImage(
            for: allStanding, size: .init(width: 320, height: 360)))),
                          try rgba(try XCTUnwrap(WorldArrivalNativeRenderer.placeholderImage(
            for: allFlowing, size: .init(width: 320, height: 360)))))
        let waterValues = standingCommands.filter { $0.scope == .waterStructure }.flatMap(\.values)
        XCTAssertTrue(waterValues.contains { $0.contains("shallow=2") })
        XCTAssertTrue(waterValues.contains { $0.contains("deep=1") })
        XCTAssertTrue(waterValues.contains { $0.contains("frozen=1") })

        var thawedMap = map
        thawedMap[.init(x: 0, y: 1)] = Tile(ground: .water)
        let thawedStanding = allLiquid.union([.init(x: 0, y: 1)])
        let thawed = try make(thawedMap, standing: thawedStanding, flowing: [], frozen: [],
                              standingBodies: [thawedStanding.count], channels: [], frozenBodies: [],
                              standingDeep: 1, flowingDeep: 0)
        XCTAssertNotEqual(try rgba(try XCTUnwrap(WorldArrivalNativeRenderer.placeholderImage(
            for: allStanding, size: .init(width: 320, height: 360)))),
                          try rgba(try XCTUnwrap(WorldArrivalNativeRenderer.placeholderImage(
            for: thawed, size: .init(width: 320, height: 360)))),
                          "frozen structure must remain visibly distinct from moving liquid water")

        // D01: generated sites/resources own coordinate-free reasons to explore. Exact identity,
        // yield and position remain excluded, as do traveller/apex facts.
        let emptyOpportunities = try make(map, standing: standing, flowing: flowing, frozen: frozen,
                                          standingBodies: [2], channels: [1], frozenBodies: [1],
                                          standingDeep: 1, flowingDeep: 0)
        var resourceA = map, resourceYield = map, resourceMoved = map
        resourceA[.init(x: 11, y: 11)].content = .wildDrop(
            resource: ResourceID(rawValue: "silver"), amount: 1)
        resourceYield[.init(x: 11, y: 11)].content = .wildDrop(
            resource: ResourceID(rawValue: "silver"), amount: 2)
        resourceMoved[.init(x: 10, y: 11)].content = .wildDrop(
            resource: ResourceID(rawValue: "silver"), amount: 1)
        var resourceOther = map
        resourceOther[.init(x: 11, y: 11)].content = .wildDrop(
            resource: ResourceID(rawValue: "gold"), amount: 1)
        var ordinaryResource = map
        ordinaryResource[.init(x: 11, y: 11)].content = .wildDrop(
            resource: ResourceID(rawValue: "ore"), amount: 1)
        var nontradeableResource = map
        nontradeableResource[.init(x: 11, y: 11)].content = .wildDrop(
            resource: ResourceID(rawValue: "essence_raw"), amount: 1)
        var resourceSources = map
        resourceSources[.init(x: 11, y: 11)].content = .node(.init(
            resource: .init(rawValue: "silver"), remainingHarvests: 2, yieldPerHarvest: 1,
            secondaryResource: .init(rawValue: "gold"), secondaryYieldPerHarvest: 1))
        resourceSources[.init(x: 10, y: 11)].content = .wildDrop(
            resource: .init(rawValue: "silver"), amount: 1)
        var resourceSourcesPermuted = map
        resourceSourcesPermuted[.init(x: 1, y: 10)].content = resourceSources[.init(x: 10, y: 11)].content
        resourceSourcesPermuted[.init(x: 2, y: 10)].content = resourceSources[.init(x: 11, y: 11)].content
        var exhaustedSources = map
        exhaustedSources[.init(x: 11, y: 11)].content = .node(.init(
            resource: .init(rawValue: "silver"), remainingHarvests: 0, yieldPerHarvest: 9,
            secondaryResource: .init(rawValue: "gold"), secondaryYieldPerHarvest: 9))
        exhaustedSources[.init(x: 10, y: 11)].content = .node(.init(
            resource: .init(rawValue: "silver"), remainingHarvests: 2, yieldPerHarvest: 0,
            secondaryResource: .init(rawValue: "gold"), secondaryYieldPerHarvest: 0))
        exhaustedSources[.init(x: 9, y: 11)].content = .wildDrop(
            resource: .init(rawValue: "silver"), amount: 0)
        var siteA = map, siteB = map, siteOther = map, siteMany = map
        siteA[.init(x: 11, y: 11)].content = .site(.init(rawValue: 88_001))
        siteB[.init(x: 10, y: 11)].content = .site(.init(rawValue: 99_002))
        siteOther[.init(x: 11, y: 11)].content = .site(.init(rawValue: 77_003))
        siteMany[.init(x: 2, y: 9)].content = .site(.init(rawValue: 66_004))
        siteMany[.init(x: 9, y: 2)].content = .site(.init(rawValue: 55_005))
        let placedSiteA = PlacedSite(id: .init(rawValue: 88_001),
            siteID: .init(rawValue: "crystal_cavern"), position: .init(x: 11, y: 11),
            searchTurnsRemaining: 3)
        let placedSiteB = PlacedSite(id: .init(rawValue: 99_002),
            siteID: .init(rawValue: "crystal_cavern"), position: .init(x: 10, y: 11),
            searchTurnsRemaining: 3)
        let placedSiteOther = PlacedSite(id: .init(rawValue: 77_003),
            siteID: .init(rawValue: "geyser_basin"), position: .init(x: 11, y: 11),
            searchTurnsRemaining: 2)
        let placedSiteMany = [
            PlacedSite(id: .init(rawValue: 66_004), siteID: .init(rawValue: "geyser_basin"),
                       position: .init(x: 2, y: 9), searchTurnsRemaining: 1),
            PlacedSite(id: .init(rawValue: 55_005), siteID: .init(rawValue: "crystal_cavern"),
                       position: .init(x: 9, y: 2), searchTurnsRemaining: 4)
        ]
        var travellerMap = map
        travellerMap[.init(x: 11, y: 11)].content = .traveller(.init(rawValue: "hidden-person"))
        func opportunityReceipt(_ source: WorldMap, sites: [PlacedSite] = [],
                                causalFacts: [WorldArrivalReceipt.CausalVisualFact]? = nil) throws
            -> WorldSplashReceiptV3 {
            try make(source, standing: standing, flowing: flowing, frozen: frozen,
                     standingBodies: [2], channels: [1], frozenBodies: [1],
                     standingDeep: 1, flowingDeep: 0, sites: sites,
                     causalFacts: causalFacts)
        }
        let resourceReceipt = try opportunityReceipt(resourceA)
        let resourceYieldReceipt = try opportunityReceipt(resourceYield)
        let resourceCoordinate = try opportunityReceipt(resourceMoved)
        let resourceOtherReceipt = try opportunityReceipt(resourceOther)
        let ordinaryResourceReceipt = try opportunityReceipt(ordinaryResource, causalFacts: [])
        let emptyNoncausalOpportunities = try opportunityReceipt(map, causalFacts: [])
        let nontradeableResourceReceipt = try opportunityReceipt(nontradeableResource)
        let resourceSourcesReceipt = try opportunityReceipt(resourceSources)
        let resourceSourcesPermutedReceipt = try opportunityReceipt(resourceSourcesPermuted)
        let exhaustedSourcesReceipt = try opportunityReceipt(exhaustedSources)
        let siteReceipt = try opportunityReceipt(siteA, sites: [placedSiteA])
        let siteIdentityCoordinate = try opportunityReceipt(siteB, sites: [placedSiteB])
        let siteOtherReceipt = try opportunityReceipt(siteOther, sites: [placedSiteOther])
        let siteManyReceipt = try opportunityReceipt(siteMany, sites: placedSiteMany.reversed())
        let richOreFact = WorldArrivalReceipt.CausalVisualFact(
            candidateMarkID: .init(rawValue: 456_789), semanticKey: "rich_ore",
            markDisplayName: "Rich Ore", sourcePageOrder: 0, scope: .resource,
            contributionKind: .increased, resultBand: "present", withoutAuthoredBand: "absent")
        let orePressureReceipt = try make(
            ordinaryResource, standing: standing, flowing: flowing, frozen: frozen,
            standingBodies: [2], channels: [1], frozenBodies: [1],
            standingDeep: 1, flowingDeep: 0, causalFacts: [richOreFact],
            causalResourceOwners: [Resources.ore: [.init(rawValue: 456_789)]])
        var ordinaryResourceMoved = map
        ordinaryResourceMoved[.init(x: 3, y: 8)].content = ordinaryResource[.init(x: 11, y: 11)].content
        let orePressureMovedReceipt = try make(
            ordinaryResourceMoved, standing: standing, flowing: flowing, frozen: frozen,
            standingBodies: [2], channels: [1], frozenBodies: [1],
            standingDeep: 1, flowingDeep: 0, causalFacts: [richOreFact],
            causalResourceOwners: [Resources.ore: [.init(rawValue: 456_789)]])
        let travellerReceipt = try opportunityReceipt(travellerMap)
        XCTAssertEqual(resourceReceipt.explorationOpportunities.resources,
                       [.init(stableID: "silver", sourceCount: 1,
                              obtainableQuantity: 1, causalMarkIDs: [])])
        XCTAssertTrue(siteReceipt.explorationOpportunities.hasGeneratedSiteOpportunity)
        XCTAssertEqual(resourceSourcesReceipt.explorationOpportunities.resources, [
            .init(stableID: "gold", sourceCount: 1, obtainableQuantity: 2, causalMarkIDs: []),
            .init(stableID: "silver", sourceCount: 2, obtainableQuantity: 3, causalMarkIDs: [])
        ], "primary and positive secondary source families aggregate once per tile")
        XCTAssertEqual(resourceSourcesReceipt, resourceSourcesPermutedReceipt,
                       "O03 keyed rows are canonical across placement/input permutation")
        XCTAssertEqual(exhaustedSourcesReceipt, emptyOpportunities,
                       "zero-yield, exhausted and zero-amount sources are not advertised")
        XCTAssertEqual(ordinaryResourceReceipt.explorationOpportunities,
                       emptyNoncausalOpportunities.explorationOpportunities,
                       "ordinary noncausal resources are not Splash opportunities")
        XCTAssertEqual(orePressureReceipt.explorationOpportunities.resources,
                       [.init(stableID: "ore", sourceCount: 1, obtainableQuantity: 1,
                              causalMarkIDs: [.init(rawValue: 456_789)])],
                       "an existing Rich Ore causal receipt owns its actually placed Ore cue")
        XCTAssertEqual(orePressureReceipt, orePressureMovedReceipt,
                       "pressure-owned Ore remains coordinate-free")
        XCTAssertNotEqual(WorldArrivalNativeRenderer.splashCommands(for: orePressureReceipt),
                          WorldArrivalNativeRenderer.splashCommands(for: ordinaryResourceReceipt))
        XCTAssertNotEqual(try rgba(try XCTUnwrap(WorldArrivalNativeRenderer.placeholderImage(
            for: orePressureReceipt, size: .init(width: 320, height: 360)))),
                          try rgba(try XCTUnwrap(WorldArrivalNativeRenderer.placeholderImage(
            for: ordinaryResourceReceipt, size: .init(width: 320, height: 360)))))
        XCTAssertEqual(nontradeableResourceReceipt, emptyOpportunities,
                       "nontradeable is not a rarity synonym")
        XCTAssertNotEqual(resourceReceipt, emptyOpportunities)
        XCTAssertNotEqual(siteReceipt, emptyOpportunities)
        XCTAssertNotEqual(resourceReceipt, resourceYieldReceipt,
                          "O05 exact obtainable quantity remains truthful")
        let resourcePixels = try rgba(try XCTUnwrap(WorldArrivalNativeRenderer.placeholderImage(
            for: resourceReceipt, size: .init(width: 320, height: 360))))
        let resourceYieldPixels = try rgba(try XCTUnwrap(WorldArrivalNativeRenderer.placeholderImage(
            for: resourceYieldReceipt, size: .init(width: 320, height: 360))))
        XCTAssertGreaterThan(changedPixels(resourceYieldPixels,
                                           try rgba(try XCTUnwrap(WorldArrivalNativeRenderer.placeholderImage(
                                            for: emptyOpportunities,
                                            size: .init(width: 320, height: 360))))).count,
                             changedPixels(resourcePixels,
                                           try rgba(try XCTUnwrap(WorldArrivalNativeRenderer.placeholderImage(
                                            for: emptyOpportunities,
                                            size: .init(width: 320, height: 360))))).count)
        let opportunityBaselinePixels = try rgba(try XCTUnwrap(
            WorldArrivalNativeRenderer.placeholderImage(
                for: emptyOpportunities, size: .init(width: 320, height: 360))))
        var priorResourceOwnedPixels = Set<Int>()
        for quantity in 1...WorldSplashReceiptV3.maximumObtainableQuantityPerSource {
            var exact = emptyOpportunities
            exact.explorationOpportunities.resources = [
                .init(stableID: "silver", sourceCount: 1,
                      obtainableQuantity: quantity, causalMarkIDs: [])
            ]
            exact.seal()
            XCTAssertTrue(exact.validates())
            let owned = changedPixels(try rgba(try XCTUnwrap(
                WorldArrivalNativeRenderer.placeholderImage(
                    for: exact, size: .init(width: 320, height: 360)))),
                opportunityBaselinePixels)
            XCTAssertTrue(priorResourceOwnedPixels.isSubset(of: owned))
            XCTAssertGreaterThan(owned.count, priorResourceOwnedPixels.count,
                                 "q→q+1 must add collision-free resource-owned pixels")
            priorResourceOwnedPixels = owned
        }
        var beyondFiveHitCeiling = emptyOpportunities
        beyondFiveHitCeiling.explorationOpportunities.resources = [
            .init(stableID: "silver", sourceCount: 1,
                  obtainableQuantity: WorldSplashReceiptV3.maximumObtainableQuantityPerSource + 1,
                  causalMarkIDs: [])
        ]
        beyondFiveHitCeiling.seal()
        XCTAssertFalse(beyondFiveHitCeiling.validates(), "a 36-unit source must fail closed")
        let opportunityTileCount = emptyOpportunities.terrain.width
            * emptyOpportunities.terrain.height
        let slotCapacity = WorldArrivalNativeRenderer.resourceOpportunitySlotCapacity(
            for: .init(width: 320, height: 360))
        let maximumFullSources = min(
            opportunityTileCount,
            slotCapacity / (WorldSplashReceiptV3.maximumObtainableQuantityPerSource + 1))
        let maximumAggregateQuantity = maximumFullSources
            * WorldSplashReceiptV3.maximumObtainableQuantityPerSource
        let maximumAggregateMarks = maximumFullSources + maximumAggregateQuantity
        XCTAssertEqual(
            slotCapacity,
            WorldSplashReceiptV3.maximumResourceOpportunityMarks)
        XCTAssertGreaterThanOrEqual(slotCapacity, maximumAggregateMarks,
            "the canonical scene must have a collision-free slot for every accepted mark")

        func resourceOwned(sourceCount: Int, quantity: Int) throws -> Set<Int> {
            var exact = emptyOpportunities
            exact.explorationOpportunities.resources = [
                .init(stableID: "silver", sourceCount: sourceCount,
                      obtainableQuantity: quantity, causalMarkIDs: [])
            ]
            exact.seal()
            XCTAssertTrue(exact.validates())
            return changedPixels(try rgba(try XCTUnwrap(
                WorldArrivalNativeRenderer.placeholderImage(
                    for: exact, size: .init(width: 320, height: 360)))),
                opportunityBaselinePixels)
        }
        let fewerSources = try resourceOwned(sourceCount: opportunityTileCount - 1, quantity: 1)
        let moreSources = try resourceOwned(sourceCount: opportunityTileCount, quantity: 1)
        XCTAssertTrue(fewerSources.isSubset(of: moreSources))
        XCTAssertGreaterThan(moreSources.count, fewerSources.count,
                             "n→n+1 sources must add collision-free ownership")
        let nearMaximum = try resourceOwned(sourceCount: maximumFullSources,
                                            quantity: maximumAggregateQuantity - 1)
        let maximum = try resourceOwned(sourceCount: maximumFullSources,
                                        quantity: maximumAggregateQuantity)
        XCTAssertTrue(nearMaximum.isSubset(of: maximum))
        XCTAssertGreaterThan(maximum.count, nearMaximum.count,
                             "q→q+1 at the legal aggregate maximum must remain distinct")
        XCTAssertEqual(resourceReceipt, resourceCoordinate,
                       "O03 relocating the same resource-family aggregate is byte-identical")
        XCTAssertEqual(siteReceipt, siteIdentityCoordinate,
                       "O04 relocating a site is byte-identical")
        XCTAssertEqual(siteReceipt, siteOtherReceipt,
                       "site category and instance identity remain undisclosed")
        XCTAssertEqual(siteReceipt, siteManyReceipt,
                       "one versus many sites and ordering remain byte-identical")
        XCTAssertNotEqual(resourceReceipt, resourceOtherReceipt,
                          "O02 stable resource-family identity must remain truthful")
        XCTAssertEqual(travellerReceipt, emptyOpportunities,
                       "D01 traveller identity remains excluded")
        let emptyCommands = try XCTUnwrap(WorldArrivalNativeRenderer.splashCommands(
            for: emptyOpportunities))
        let resourceCommands = try XCTUnwrap(WorldArrivalNativeRenderer.splashCommands(
            for: resourceReceipt))
        let siteCommands = try XCTUnwrap(WorldArrivalNativeRenderer.splashCommands(
            for: siteReceipt))
        XCTAssertNotEqual(emptyCommands, resourceCommands)
        XCTAssertNotEqual(emptyCommands, siteCommands)
        let nonOpportunity: (WorldArrivalNativeRenderer.SplashCommand) -> Bool = {
            $0.scope != .siteOpportunity && $0.scope != .resourceOpportunity
        }
        XCTAssertEqual(emptyCommands.filter(nonOpportunity),
                       resourceCommands.filter(nonOpportunity),
                       "O02 add/remove resource changes only its opportunity commands")
        XCTAssertEqual(emptyCommands.filter(nonOpportunity),
                       siteCommands.filter(nonOpportunity),
                       "O01 add/remove site changes only its opportunity commands")
        XCTAssertNotEqual(try rgba(try XCTUnwrap(WorldArrivalNativeRenderer.placeholderImage(
            for: emptyOpportunities, size: .init(width: 320, height: 360)))),
                          try rgba(try XCTUnwrap(WorldArrivalNativeRenderer.placeholderImage(
            for: resourceReceipt, size: .init(width: 320, height: 360)))))
        XCTAssertNotEqual(try rgba(try XCTUnwrap(WorldArrivalNativeRenderer.placeholderImage(
            for: emptyOpportunities, size: .init(width: 320, height: 360)))),
                          try rgba(try XCTUnwrap(WorldArrivalNativeRenderer.placeholderImage(
            for: siteReceipt, size: .init(width: 320, height: 360)))))
        XCTAssertNotEqual(try rgba(try XCTUnwrap(WorldArrivalNativeRenderer.placeholderImage(
            for: resourceReceipt, size: .init(width: 320, height: 360)))),
                          try rgba(try XCTUnwrap(WorldArrivalNativeRenderer.placeholderImage(
            for: resourceOtherReceipt, size: .init(width: 320, height: 360)))),
                          "O02 resource identities own deterministic distinct placeholder pixels")
        XCTAssertEqual(try rgba(try XCTUnwrap(WorldArrivalNativeRenderer.placeholderImage(
            for: siteReceipt, size: .init(width: 320, height: 360)))),
                         try rgba(try XCTUnwrap(WorldArrivalNativeRenderer.placeholderImage(
            for: siteManyReceipt, size: .init(width: 320, height: 360)))),
                         "site multiplicity/category/location own one constant visible cue")
        let encodedData = try JSONEncoder().encode(resourceReceipt)
        let encodedObject = try XCTUnwrap(JSONSerialization.jsonObject(with: encodedData)
            as? [String: Any])
        let opportunityObject = try XCTUnwrap(encodedObject["explorationOpportunities"]
            as? [String: Any])
        XCTAssertEqual(Set(opportunityObject.keys), ["hasGeneratedSiteOpportunity", "resources"])
        let encodedSplash = String(decoding: encodedData, as: UTF8.self)
        for forbidden in ["traveller", "apex", "yieldPerHarvest", "remainingHarvests",
                          "resourceID", "siteID", "coordinates"] {
            XCTAssertFalse(encodedSplash.localizedCaseInsensitiveContains(forbidden),
                           "D01 exact/identity runtime scope leaked into the aggregate receipt")
        }

        // C03: corrected prose/title never perturbs the frozen visual command or RGBA stream.
        var correctedCopy = mixed
        correctedCopy.finalDescription = "Corrected two-sentence world description. The scene facts remain unchanged."
        correctedCopy.sourcePagePhysicalReceipt.title += " — corrected"
        correctedCopy.seal()
        XCTAssertTrue(correctedCopy.validates())
        XCTAssertEqual(WorldArrivalNativeRenderer.splashCommands(for: mixed),
                       WorldArrivalNativeRenderer.splashCommands(for: correctedCopy))
        XCTAssertEqual(try rgba(mixedImage),
                       try rgba(try XCTUnwrap(WorldArrivalNativeRenderer.placeholderImage(
            for: correctedCopy, size: .init(width: 320, height: 360)))))

        var reliefMap = map
        reliefMap[.init(x: 1, y: 1)].elevation = 1
        reliefMap[.init(x: 2, y: 1)].elevation = 2
        reliefMap[.init(x: 2, y: 2)].elevation = 3
        let mixedRelief = try make(reliefMap, standing: standing, flowing: flowing, frozen: frozen,
                                   standingBodies: [2], channels: [1], frozenBodies: [1],
                                   standingDeep: 1, flowingDeep: 0)
        XCTAssertEqual(Set(mixedRelief.terrain.regions[0].elevationShares
            .filter { $0.exactCount > 0 }.map(\.id)), ["0", "1", "2", "3"])
        XCTAssertEqual(mixedRelief.relief.maximumElevation, 3)
        XCTAssertEqual(mixedRelief.relief.elevatedComponentSizes, [3])
        XCTAssertEqual(mixedRelief.relief.southContactCounts, [1, 0, 1])
        XCTAssertTrue(mixedRelief.relief.shapeFlags.isEmpty)
        let reliefCommands = try XCTUnwrap(WorldArrivalNativeRenderer.splashCommands(
            for: mixedRelief)).filter { $0.scope == .relief }
        XCTAssertTrue(reliefCommands.contains { $0.semanticID == "shape"
            && $0.values.contains("elevated-components=3") })
        for deferred in ["rolling", "ridge", "basin", "shelf", "enclosed", "broken"] {
            XCTAssertFalse(reliefCommands.flatMap(\.values).contains(deferred))
        }
        for cell in mixedRelief.firstMapCropReceipt.cells where cell.visibility != "hidden" {
            XCTAssertEqual(cell.elevation, reliefMap[cell.point].elevation)
        }
        XCTAssertNotEqual(try rgba(try XCTUnwrap(WorldArrivalNativeRenderer.placeholderImage(
            for: mixedRelief, size: .init(width: 320, height: 360)))), try rgba(mixedImage))

        // F04/F05: density and habit own distribution geometry independently of identity/color.
        var plantTraits = FloraTraits()
        plantTraits.stature = 48
        plantTraits.habit = .clustered
        let plant = Flora(id: InstanceID(rawValue: 7001), traits: plantTraits,
                          worldSeed: run.mapSeed)
        let available = map.allPoints.filter { map[$0].ground != .chasm }
        func floraReceipt(count: Int, habit: Habit) throws -> WorldSplashReceiptV3 {
            var floraMap = map
            for point in floraMap.allPoints { floraMap[point].flora = nil }
            for point in available.prefix(count) { floraMap[point].flora = plant.id }
            var traits = plant.traits
            traits.habit = habit
            let changedPlant = Flora(id: plant.id, traits: traits, worldSeed: plant.worldSeed)
            return try make(floraMap, standing: standing, flowing: flowing, frozen: frozen,
                            standingBodies: [2], channels: [1], frozenBodies: [1],
                            standingDeep: 1, flowingDeep: 0, flora: [changedPlant])
        }
        func floraPermutationReceipt(_ points: [GridPoint]) throws -> WorldSplashReceiptV3 {
            var floraMap = map
            for point in floraMap.allPoints { floraMap[point].flora = nil }
            for point in points { floraMap[point].flora = plant.id }
            return try make(floraMap, standing: standing, flowing: flowing, frozen: frozen,
                            standingBodies: [2], channels: [1], frozenBodies: [1],
                            standingDeep: 1, flowingDeep: 0, flora: [plant])
        }
        let floraCoordinatesA = try floraPermutationReceipt([
            .init(x: 9, y: 9), .init(x: 10, y: 9)
        ])
        let floraCoordinatesB = try floraPermutationReceipt([
            .init(x: 9, y: 10), .init(x: 10, y: 10)
        ])
        XCTAssertEqual(floraCoordinatesA, floraCoordinatesB,
                       "O07 coordinate permutation preserving region/identity/count is undisclosed")
        XCTAssertEqual(WorldArrivalNativeRenderer.splashCommands(for: floraCoordinatesA),
                       WorldArrivalNativeRenderer.splashCommands(for: floraCoordinatesB))
        XCTAssertEqual(try rgba(try XCTUnwrap(WorldArrivalNativeRenderer.placeholderImage(
            for: floraCoordinatesA, size: .init(width: 320, height: 360)))),
                       try rgba(try XCTUnwrap(WorldArrivalNativeRenderer.placeholderImage(
            for: floraCoordinatesB, size: .init(width: 320, height: 360)))))
        let sparse = try floraReceipt(count: 2, habit: .clustered)
        let abundant = try floraReceipt(count: 40, habit: .clustered)
        let spreading = try floraReceipt(count: 40, habit: .spreading)
        var pinkDominant = abundant
        pinkDominant.flora.species[0].renderIdentity.resolvedColor.srgb = [242, 72, 188]
        pinkDominant.seal()
        XCTAssertTrue(pinkDominant.validates())
        XCTAssertEqual(pinkDominant.flora.species[0].coverage, .abundant)
        XCTAssertTrue(pinkDominant.firstMapCropReceipt.cells.contains {
            $0.floraStableID == pinkDominant.flora.species[0].stableID
        }, "F01 high-coverage pink flora must remain present in the disclosed crop")
        let pinkPixels = try rgba(try XCTUnwrap(WorldArrivalNativeRenderer.placeholderImage(
            for: pinkDominant, size: .init(width: 320, height: 360))))
        XCTAssertTrue(containsRGB(pinkPixels, [242, 72, 188], tolerance: 16),
                      "F01 the high-coverage pink identity must own scene pixels")
        func withoutFlora(_ source: WorldSplashReceiptV3) -> WorldSplashReceiptV3 {
            var copy = source
            copy.flora.species = []
            copy.flora.placedIdentityCount = 0
            copy.flora.occupiedTileCount = 0
            copy.flora.aggregateCoverage = .none
            for index in copy.terrain.regions.indices { copy.terrain.regions[index].floraShares = [] }
            for index in copy.firstMapCropReceipt.cells.indices {
                copy.firstMapCropReceipt.cells[index].floraStableID = nil
            }
            copy.seal()
            return copy
        }
        let firstRegionHosts = available.filter {
            $0.x * WorldSplashReceiptV3.regionColumns / map.width == 0
                && $0.y * WorldSplashReceiptV3.regionRows / map.height == 0
        }
        var priorExactFloraPixels = Set<Int>()
        for exactCount in 1...firstRegionHosts.count {
            let exactReceipt = try floraPermutationReceipt(
                Array(firstRegionHosts.prefix(exactCount)))
            let exactPixels = try rgba(try XCTUnwrap(
                WorldArrivalNativeRenderer.placeholderImage(
                    for: exactReceipt, size: .init(width: 320, height: 360))))
            let exactBarePixels = try rgba(try XCTUnwrap(
                WorldArrivalNativeRenderer.placeholderImage(
                    for: withoutFlora(exactReceipt), size: .init(width: 320, height: 360))))
            let owned = changedPixels(exactPixels, exactBarePixels)
            XCTAssertTrue(priorExactFloraPixels.isSubset(of: owned))
            XCTAssertGreaterThan(owned.count, priorExactFloraPixels.count,
                                 "each legal q→q+1 regional flora count must add ownership")
            priorExactFloraPixels = owned
        }
        var pinkSparse = sparse
        pinkSparse.flora.species[0].renderIdentity.resolvedColor.srgb = [242, 72, 188]
        pinkSparse.seal()
        let pinkSparsePixels = try rgba(try XCTUnwrap(WorldArrivalNativeRenderer.placeholderImage(
            for: pinkSparse, size: .init(width: 320, height: 360))))
        let abundantBarePixels = try rgba(try XCTUnwrap(WorldArrivalNativeRenderer.placeholderImage(
            for: withoutFlora(pinkDominant), size: .init(width: 320, height: 360))))
        let sparseBarePixels = try rgba(try XCTUnwrap(WorldArrivalNativeRenderer.placeholderImage(
            for: withoutFlora(pinkSparse), size: .init(width: 320, height: 360))))
        XCTAssertGreaterThan(changedPixels(pinkPixels, abundantBarePixels).count,
                             changedPixels(pinkSparsePixels, sparseBarePixels).count,
                             "F01 abundant identity must own more geometry than sparse identity")
        for region in pinkDominant.terrain.regions where
            region.floraShares.first?.exactCount ?? 0 > 0 {
            let minX = 8 + region.column * 76
            let maxX = region.column == 3 ? 312 : minX + 76
            let minY = 8 + Int(floor(Double(region.row) * 344.0 / 3.0))
            let maxY = region.row == 2 ? 352
                : 8 + Int(ceil(Double(region.row + 1) * 344.0 / 3.0))
            let ownsPink = (minY..<maxY).contains { y in
                (minX..<maxX).contains { x in
                    let offset = (y * 320 + x) * 4
                    let pixel = Data(pinkPixels[offset..<(offset + 4)])
                    return containsRGB(pixel, [242, 72, 188], tolerance: 16)
                }
            }
            XCTAssertTrue(ownsPink, "F01 every nonempty flora region must visibly retain pink ownership")
        }
        let fullPinkCrop = pinkDominant.firstMapCropReceipt.cells.filter {
            $0.visibility == "full" && $0.floraStableID != nil
        }
        XCTAssertFalse(fullPinkCrop.isEmpty)
        XCTAssertTrue(fullPinkCrop.allSatisfy {
            $0.floraStableID == pinkDominant.flora.species[0].stableID
                && pinkDominant.flora.species[0].renderIdentity.resolvedColor.srgb == [242, 72, 188]
        }, "F01 full-visible crop cells retain the same stable identity/color request")
        XCTAssertNotEqual(WorldArrivalNativeRenderer.splashCommands(for: sparse),
                          WorldArrivalNativeRenderer.splashCommands(for: abundant))
        XCTAssertNotEqual(try rgba(try XCTUnwrap(WorldArrivalNativeRenderer.placeholderImage(
            for: sparse, size: .init(width: 320, height: 360)))),
                          try rgba(try XCTUnwrap(WorldArrivalNativeRenderer.placeholderImage(
            for: abundant, size: .init(width: 320, height: 360)))))
        XCTAssertNotEqual(WorldArrivalNativeRenderer.splashCommands(for: abundant),
                          WorldArrivalNativeRenderer.splashCommands(for: spreading))
        XCTAssertNotEqual(try rgba(try XCTUnwrap(WorldArrivalNativeRenderer.placeholderImage(
            for: abundant, size: .init(width: 320, height: 360)))),
                          try rgba(try XCTUnwrap(WorldArrivalNativeRenderer.placeholderImage(
            for: spreading, size: .init(width: 320, height: 360)))))

        // F06: Splash itself has no prefix-four truncation, even though current WorldGrade
        // generation remains correctly limited to four realized species.
        func localBand(_ count: Int, _ total: Int) -> WorldSplashReceiptV3.CoverageBand {
            guard count > 0 else { return .none }
            let ratio = Double(count) / Double(total)
            if ratio < 0.03 { return .trace }
            if ratio < 0.10 { return .sparse }
            if ratio < 0.25 { return .present }
            if ratio < 0.50 { return .abundant }
            return .dominant
        }
        let templateSpecies = try XCTUnwrap(abundant.flora.species.first)
        var six = abundant
        six.flora.species = (0..<6).map { index in
            var species = templateSpecies
            species.stableID = "flora-\(7001 + index)"
            species.renderIdentity.speciesID = species.stableID
            species.renderIdentity.resolvedColor.srgb = [40 + index * 20, 90 + index * 10, 70 + index * 8]
            species.placedTileCount = 1
            species.coverage = localBand(1, six.terrain.nonChasmTileCount)
            species.regionShares = (0..<12).map { region in
                localBand(region == index ? 1 : 0,
                          six.terrain.regions[region].groundShares.reduce(0) { $0 + $1.exactCount })
            }
            return species
        }
        for regionIndex in six.terrain.regions.indices {
            let regionTotal = six.terrain.regions[regionIndex].groundShares
                .reduce(0) { $0 + $1.exactCount }
            six.terrain.regions[regionIndex].floraShares = six.flora.species.enumerated().map {
                speciesIndex, species in
                let exact = speciesIndex == regionIndex ? 1 : 0
                return .init(id: species.stableID, exactCount: exact,
                             band: localBand(exact, regionTotal))
            }
        }
        six.flora.placedIdentityCount = 6
        six.flora.occupiedTileCount = 6
        six.flora.aggregateCoverage = localBand(6, six.terrain.nonChasmTileCount)
        six.seal()
        XCTAssertTrue(six.validates())
        let sixCommands = try XCTUnwrap(WorldArrivalNativeRenderer.splashCommands(for: six))
        XCTAssertEqual(sixCommands.count { $0.scope == .floraIdentity }, 6)
        XCTAssertEqual(sixCommands.count { $0.scope == .floraDistribution }, 6)
        var five = six
        let removed = five.flora.species.removeLast()
        for regionIndex in five.terrain.regions.indices {
            five.terrain.regions[regionIndex].floraShares.removeAll { $0.id == removed.stableID }
        }
        five.flora.placedIdentityCount = 5
        five.flora.occupiedTileCount = 5
        five.flora.aggregateCoverage = localBand(5, five.terrain.nonChasmTileCount)
        five.seal()
        XCTAssertTrue(five.validates())
        let fiveCommands = try XCTUnwrap(WorldArrivalNativeRenderer.splashCommands(for: five))
        XCTAssertNotEqual(sixCommands, fiveCommands)
        let nonFlora: (WorldArrivalNativeRenderer.SplashCommand) -> Bool = {
            $0.scope != .floraIdentity && $0.scope != .floraDistribution
        }
        XCTAssertEqual(sixCommands.filter(nonFlora), fiveCommands.filter(nonFlora),
                       "F02 removal changes only flora-owned commands")
        let retainedIDs = Set(five.flora.species.map(\.stableID))
        XCTAssertEqual(sixCommands.filter { ($0.scope == .floraIdentity
            || $0.scope == .floraDistribution) && retainedIDs.contains($0.semanticID) },
                       fiveCommands.filter { $0.scope == .floraIdentity
            || $0.scope == .floraDistribution },
                       "F02 must preserve every retained species command byte-for-byte")
        XCTAssertNotEqual(try rgba(try XCTUnwrap(WorldArrivalNativeRenderer.placeholderImage(
            for: six, size: .init(width: 320, height: 360)))),
                          try rgba(try XCTUnwrap(WorldArrivalNativeRenderer.placeholderImage(
            for: five, size: .init(width: 320, height: 360)))))

        var recolored = six
        recolored.flora.species[0].renderIdentity.resolvedColor.srgb = [242, 72, 188]
        recolored.seal()
        XCTAssertTrue(recolored.validates())
        let recoloredCommands = try XCTUnwrap(
            WorldArrivalNativeRenderer.splashCommands(for: recolored))
        XCTAssertEqual(sixCommands.filter(nonFlora), recoloredCommands.filter(nonFlora))
        XCTAssertNotEqual(sixCommands.filter { $0.scope == .floraIdentity },
                          recoloredCommands.filter { $0.scope == .floraIdentity })
        XCTAssertEqual(sixCommands.filter { $0.scope == .floraDistribution },
                       recoloredCommands.filter { $0.scope == .floraDistribution },
                       "F03 color-only changes must preserve distribution commands byte-for-byte")
        XCTAssertNotEqual(try rgba(try XCTUnwrap(WorldArrivalNativeRenderer.placeholderImage(
            for: six, size: .init(width: 320, height: 360)))),
                          try rgba(try XCTUnwrap(WorldArrivalNativeRenderer.placeholderImage(
            for: recolored, size: .init(width: 320, height: 360)))))

        var bare = six
        bare.flora.species = []
        bare.flora.placedIdentityCount = 0
        bare.flora.occupiedTileCount = 0
        bare.flora.aggregateCoverage = .none
        for index in bare.terrain.regions.indices { bare.terrain.regions[index].floraShares = [] }
        for index in bare.firstMapCropReceipt.cells.indices {
            bare.firstMapCropReceipt.cells[index].floraStableID = nil
        }
        bare.seal()
        XCTAssertTrue(bare.validates())
        let bareBytes = try rgba(try XCTUnwrap(WorldArrivalNativeRenderer.placeholderImage(
            for: bare, size: .init(width: 320, height: 360))))
        let sixBytes = try rgba(try XCTUnwrap(WorldArrivalNativeRenderer.placeholderImage(
            for: six, size: .init(width: 320, height: 360))))
        let recoloredBytes = try rgba(try XCTUnwrap(WorldArrivalNativeRenderer.placeholderImage(
            for: recolored, size: .init(width: 320, height: 360))))
        XCTAssertEqual(changedPixels(sixBytes, bareBytes), changedPixels(recoloredBytes, bareBytes),
                       "F03 color-only changes must retain the exact flora-owned pixel geometry")

        var reformed = six
        reformed.flora.species[0].renderIdentity.formID =
            (reformed.flora.species[0].renderIdentity.formID + 1) % 4
        reformed.seal()
        XCTAssertTrue(reformed.validates())
        XCTAssertNotEqual(try rgba(try XCTUnwrap(WorldArrivalNativeRenderer.placeholderImage(
            for: six, size: .init(width: 320, height: 360)))),
                          try rgba(try XCTUnwrap(WorldArrivalNativeRenderer.placeholderImage(
            for: reformed, size: .init(width: 320, height: 360)))))

        var permuted = six
        permuted.flora.species.reverse()
        for index in permuted.terrain.regions.indices {
            permuted.terrain.regions[index].floraShares.reverse()
        }
        permuted.seal()
        XCTAssertFalse(permuted.validates(), "persisted species order is canonical, never Set order")

        // F07: source catalogue order is canonicalized before the receipt, commands, and pixels.
        var secondTraits = plant.traits
        secondTraits.stature = min(100, secondTraits.stature + 20)
        let secondPlant = Flora(id: .init(rawValue: 7002), traits: secondTraits,
                                worldSeed: plant.worldSeed)
        var orderedMap = map
        orderedMap[.init(x: 4, y: 4)].flora = plant.id
        orderedMap[.init(x: 5, y: 4)].flora = secondPlant.id
        let forward = try make(orderedMap, standing: standing, flowing: flowing, frozen: frozen,
                               standingBodies: [2], channels: [1], frozenBodies: [1],
                               standingDeep: 1, flowingDeep: 0, flora: [plant, secondPlant])
        let reverse = try make(orderedMap, standing: standing, flowing: flowing, frozen: frozen,
                               standingBodies: [2], channels: [1], frozenBodies: [1],
                               standingDeep: 1, flowingDeep: 0, flora: [secondPlant, plant])
        XCTAssertEqual(forward, reverse)
        XCTAssertEqual(WorldArrivalNativeRenderer.splashCommands(for: forward),
                       WorldArrivalNativeRenderer.splashCommands(for: reverse))
        XCTAssertEqual(try rgba(try XCTUnwrap(WorldArrivalNativeRenderer.placeholderImage(
            for: forward, size: .init(width: 320, height: 360)))),
                       try rgba(try XCTUnwrap(WorldArrivalNativeRenderer.placeholderImage(
            for: reverse, size: .init(width: 320, height: 360)))))
    }

    @MainActor
    func testWorldSplashSemanticDepositPalettesRemainDistinctAndDescriptorOwned() throws {
        func descriptor(hue: Double, atmosphere: WorldGrade2V1.Atmosphere = .init(
            medium: "none", density: 0, paletteFamilyID: "clear"),
            atmosphereColor: WorldGrade2V1.ResolvedColor? = nil) throws
            -> WorldGrade2V1.Descriptor {
            try WorldGrade2V1.resolve(.init(
                material: .init(identity: "mixedMineral", paletteFamilyID: "paleNeutral",
                                transform: .init(hue: hue, saturation: 1, value: 0)),
                atmosphere: atmosphere,
                flora: .init(coveragePercent: 0, paletteRichness: 0, cast: []),
                resolvedColors: .init(atmosphere: atmosphereColor)))
        }
        let neutral = try descriptor(hue: 0)
        let opposed = try descriptor(hue: 28, atmosphere: .init(
            medium: "smoke", density: 55, paletteFamilyID: "neutralSmoke"),
            atmosphereColor: .init(srgb: [130, 76, 166],
                resolutionVersion: "resolved-color-1.0.0", provenance: "bindRandom"))
        let neutralSnow = try TerrainProductionPack.resolvedSurfaceDepositPalette(
            .snow, descriptor: neutral)
        let neutralAsh = try TerrainProductionPack.resolvedSurfaceDepositPalette(
            .settledAsh, descriptor: neutral)
        let opposedSnow = try TerrainProductionPack.resolvedSurfaceDepositPalette(
            .snow, descriptor: opposed)
        let opposedAsh = try TerrainProductionPack.resolvedSurfaceDepositPalette(
            .settledAsh, descriptor: opposed)
        XCTAssertNotEqual(neutralSnow, neutralAsh)
        XCTAssertNotEqual(neutralSnow, opposedSnow)
        XCTAssertNotEqual(neutralAsh, opposedAsh)
        XCTAssertEqual(neutralSnow.count, 5)
        XCTAssertEqual(neutralAsh.count, 5)

        let store = GameStore(io: .temporary(name: "splash-deposit-palette-\(UUID().uuidString)"))
        XCTAssertTrue(store.bindAndDepart(
            worldPageInstanceID: WorldPageCatalog.earthlikeTestInstance.id))
        var neutralReceipt = try XCTUnwrap(
            store.activeRun?.worldArrivalReceipt?.worldSplashReceiptV3)
        func band(_ count: Int, _ total: Int) -> WorldSplashReceiptV3.CoverageBand {
            guard count > 0 else { return .none }
            let ratio = Double(count) / Double(total)
            if ratio < 0.03 { return .trace }
            if ratio < 0.10 { return .sparse }
            if ratio < 0.25 { return .present }
            if ratio < 0.50 { return .abundant }
            return .dominant
        }
        let total = neutralReceipt.terrain.width * neutralReceipt.terrain.height
        neutralReceipt.deposits.snowCount = 1
        neutralReceipt.deposits.settledAshCount = 1
        neutralReceipt.deposits.snowCoverage = band(1, total)
        neutralReceipt.deposits.settledAshCoverage = band(1, total)
        for index in neutralReceipt.terrain.regions.indices {
            neutralReceipt.terrain.regions[index].depositShares[0].exactCount = 0
            neutralReceipt.terrain.regions[index].depositShares[0].band = .none
            neutralReceipt.terrain.regions[index].depositShares[1].exactCount = 0
            neutralReceipt.terrain.regions[index].depositShares[1].band = .none
        }
        let regionTotal = neutralReceipt.terrain.regions[0].groundShares
            .reduce(0) { $0 + $1.exactCount }
        neutralReceipt.terrain.regions[0].depositShares[0].exactCount = 1
        neutralReceipt.terrain.regions[0].depositShares[0].band = band(1, regionTotal)
        neutralReceipt.terrain.regions[0].depositShares[1].exactCount = 1
        neutralReceipt.terrain.regions[0].depositShares[1].band = band(1, regionTotal)
        neutralReceipt.terrain.materialPresentation = try XCTUnwrap(
            WorldSplashReceiptV3.MaterialPresentationDescriptor.make(from: neutral))
        neutralReceipt.seal()
        XCTAssertTrue(neutralReceipt.validates())
        func deposits(_ snow: Int, _ ash: Int) -> WorldSplashReceiptV3 {
            var copy = neutralReceipt
            copy.deposits.snowCount = snow
            copy.deposits.settledAshCount = ash
            copy.deposits.snowCoverage = band(snow, total)
            copy.deposits.settledAshCoverage = band(ash, total)
            for index in copy.terrain.regions.indices {
                copy.terrain.regions[index].depositShares[0].exactCount = index == 0 ? snow : 0
                copy.terrain.regions[index].depositShares[0].band = index == 0 ? band(snow, regionTotal) : .none
                copy.terrain.regions[index].depositShares[1].exactCount = index == 0 ? ash : 0
                copy.terrain.regions[index].depositShares[1].band = index == 0 ? band(ash, regionTotal) : .none
            }
            copy.seal()
            return copy
        }
        let depositVariants = [deposits(0, 0), deposits(1, 0), deposits(0, 1), deposits(1, 1)]
        XCTAssertTrue(depositVariants.allSatisfy { $0.validates() })
        let depositCommands = depositVariants.map {
            WorldArrivalNativeRenderer.splashCommands(for: $0)!
        }
        let withoutDeposits: (WorldArrivalNativeRenderer.SplashCommand) -> Bool = {
            $0.scope != .surfaceDeposit
        }
        XCTAssertTrue(depositCommands.dropFirst().allSatisfy {
            $0.filter(withoutDeposits) == depositCommands[0].filter(withoutDeposits)
        }, "T03 deposit variants may change only deposit-owned commands")
        let depositPixels = try depositVariants.map { receipt -> Data in
            let image = try XCTUnwrap(WorldArrivalNativeRenderer.placeholderImage(
                for: receipt, size: .init(width: 320, height: 360)))
            return try XCTUnwrap(image.cgImage?.dataProvider?.data) as Data
        }
        XCTAssertEqual(Set(depositPixels).count, 4,
                       "T03 none, snow, Ash, and both must all remain visibly distinct")
        var opposedReceipt = neutralReceipt
        opposedReceipt.terrain.materialPresentation = try XCTUnwrap(
            WorldSplashReceiptV3.MaterialPresentationDescriptor.make(from: opposed))
        opposedReceipt.seal()
        XCTAssertTrue(opposedReceipt.validates())
        let neutralCommands = try XCTUnwrap(
            WorldArrivalNativeRenderer.splashCommands(for: neutralReceipt))
        let opposedCommands = try XCTUnwrap(
            WorldArrivalNativeRenderer.splashCommands(for: opposedReceipt))
        XCTAssertNotEqual(neutralCommands, opposedCommands)
        let descriptorIndependent: (WorldArrivalNativeRenderer.SplashCommand) -> Bool = {
            !($0.scope == .terrainMass && $0.semanticID == "material-presentation")
        }
        XCTAssertEqual(neutralCommands.filter(descriptorIndependent),
                       opposedCommands.filter(descriptorIndependent),
                       "T02 descriptor-only recolor preserves exact geometry and role ownership")
        let neutralImage = try XCTUnwrap(WorldArrivalNativeRenderer.placeholderImage(
            for: neutralReceipt, size: .init(width: 320, height: 360)))
        let opposedImage = try XCTUnwrap(WorldArrivalNativeRenderer.placeholderImage(
            for: opposedReceipt, size: .init(width: 320, height: 360)))
        XCTAssertNotEqual(neutralImage.cgImage?.dataProvider?.data as Data?,
                          opposedImage.cgImage?.dataProvider?.data as Data?)
    }

    @MainActor
    func testWorldSplashEnvironmentStatesOwnDistinctCommandsAndPixels() throws {
        let store = GameStore(io: .temporary(name: "splash-environment-\(UUID().uuidString)"))
        XCTAssertTrue(store.bindAndDepart(
            worldPageInstanceID: WorldPageCatalog.earthlikeTestInstance.id))
        let base = try XCTUnwrap(store.activeRun?.worldArrivalReceipt?.worldSplashReceiptV3)
        func variant(_ edit: (inout WorldSplashReceiptV3.EnvironmentProfile) -> Void)
            throws -> WorldSplashReceiptV3 {
            var copy = base
            edit(&copy.environment)
            copy.seal()
            XCTAssertTrue(copy.validates())
            return copy
        }
        func bytes(_ receipt: WorldSplashReceiptV3) throws -> Data {
            let image = try XCTUnwrap(WorldArrivalNativeRenderer.placeholderImage(
                for: receipt, size: .init(width: 320, height: 360)))
            return try XCTUnwrap(image.cgImage?.dataProvider?.data) as Data
        }
        let dimConstant = try variant {
            $0.illuminationBand = "dim"; $0.illuminationSourceClass = "constant"
        }
        let dimCyclic = try variant {
            $0.illuminationBand = "dim"; $0.illuminationSourceClass = "cyclic"
        }
        XCTAssertNotEqual(WorldArrivalNativeRenderer.splashCommands(for: dimConstant),
                          WorldArrivalNativeRenderer.splashCommands(for: dimCyclic))
        XCTAssertNotEqual(try bytes(dimConstant), try bytes(dimCyclic))

        let smokeTrace = try variant {
            $0.suspendedMedium = "smoke"; $0.suspendedDensity = "trace"; $0.suspendedMotion = "calm"
        }
        let mistStrong = try variant {
            $0.suspendedMedium = "mist"; $0.suspendedDensity = "dense"; $0.suspendedMotion = "strong"
        }
        XCTAssertNotEqual(WorldArrivalNativeRenderer.splashCommands(for: smokeTrace),
                          WorldArrivalNativeRenderer.splashCommands(for: mistStrong))
        XCTAssertNotEqual(try bytes(smokeTrace), try bytes(mistStrong))

        let rain = try variant {
            $0.precipitationMedium = "rain"; $0.precipitationIntensity = "heavy"
            $0.precipitationMotion = "moving"
        }
        let snow = try variant {
            $0.precipitationMedium = "snow"; $0.precipitationIntensity = "heavy"
            $0.precipitationMotion = "moving"
        }
        let mixed = try variant {
            $0.precipitationMedium = "mixedRainSnow"; $0.precipitationIntensity = "heavy"
            $0.precipitationMotion = "strong"
        }
        XCTAssertNotEqual(try bytes(rain), try bytes(snow))
        XCTAssertNotEqual(try bytes(snow), try bytes(mixed))
        XCTAssertNotEqual(WorldArrivalNativeRenderer.splashCommands(for: rain),
                          WorldArrivalNativeRenderer.splashCommands(for: snow))

        let noPrecipitation = try variant {
            $0.precipitationMedium = "none"; $0.precipitationIntensity = "none"
            $0.precipitationMotion = "strong"
        }
        let strongSnow = try variant {
            $0.precipitationMedium = "snow"; $0.precipitationIntensity = "heavy"
            $0.precipitationMotion = "strong"
        }
        let noPrecipitationBytes = try bytes(noPrecipitation)
        let strongSnowBytes = try bytes(strongSnow)
        let changed = stride(from: 0, to: strongSnowBytes.count, by: 4).compactMap { offset -> Int? in
            strongSnowBytes[offset..<(offset + 4)] == noPrecipitationBytes[offset..<(offset + 4)]
                ? nil : offset / 4
        }
        XCTAssertFalse(changed.isEmpty)
        XCTAssertTrue(changed.allSatisfy { pixel in
            let x = pixel % 320, y = pixel / 320
            return x >= 8 && x < 312 && y >= 8 && y < 352
        }, "E02 strong precipitation must remain clipped to the framed scene")

        func assertDistinct(_ receipts: [WorldSplashReceiptV3], label: String,
                            file: StaticString = #filePath, line: UInt = #line) throws {
            let commands = receipts.map { WorldArrivalNativeRenderer.splashCommands(for: $0) }
            let commandBytes = try commands.map { try JSONEncoder().encode(try XCTUnwrap($0)) }
            XCTAssertEqual(Set(commandBytes).count, receipts.count,
                           "\(label) commands collapsed", file: file, line: line)
            let images = try receipts.map(bytes)
            XCTAssertEqual(Set(images).count, receipts.count,
                           "\(label) pixels collapsed", file: file, line: line)
        }
        var illuminationStates: [WorldSplashReceiptV3] = []
        for band in ["trueDark", "dim", "ordinary", "bright", "blazing"] {
            for source in ["sourceless", "constant", "cyclic"] {
                illuminationStates.append(try variant {
                    $0.illuminationBand = band; $0.illuminationSourceClass = source
                })
            }
        }
        try assertDistinct(illuminationStates, label: "E01 illumination band/source")

        var suspendedStates: [WorldSplashReceiptV3] = []
        for medium in ["smoke", "airborneAsh", "mist", "miasma"] {
            for density in ["trace", "light", "heavy", "dense"] {
                for motion in ["calm", "moving", "strong"] {
                    suspendedStates.append(try variant {
                        $0.suspendedMedium = medium; $0.suspendedDensity = density
                        $0.suspendedMotion = motion
                    })
                }
            }
        }
        try assertDistinct(suspendedStates, label: "E02 suspended medium/density/motion")

        var precipitationStates: [WorldSplashReceiptV3] = []
        for medium in ["rain", "snow", "mixedRainSnow"] {
            for intensity in ["trace", "light", "heavy"] {
                for motion in ["calm", "moving", "strong"] {
                    precipitationStates.append(try variant {
                        $0.precipitationMedium = medium; $0.precipitationIntensity = intensity
                        $0.precipitationMotion = motion
                    })
                }
            }
        }
        try assertDistinct(precipitationStates, label: "E02 precipitation medium/intensity/motion")
    }

    @MainActor
    func testWorldArrivalPendingLifecycleSurvivesRelaunchAndEnterIsZeroMutation() throws {
        let io = SaveFileIO.temporary(name: "arrival-relaunch-\(UUID().uuidString)")
        var store: GameStore? = GameStore(io: io)
        let page = WorldPageCatalog.earthlikeTestInstance
        XCTAssertTrue(store?.bindAndDepart(worldPageInstanceID: page.id) == true)
        let receipt = try XCTUnwrap(store?.activeRun?.worldArrivalReceipt)
        let runBefore = store?.activeRun
        let historyBefore = store?.state.reality.library.visitedWorlds
        store = nil

        let beforeEnter = GameStore(io: io)
        XCTAssertEqual(beforeEnter.state.worlds.pendingWorldArrivalReceipt, receipt,
                       "a kill/relaunch before Enter must replay the exact frozen receipt")
        XCTAssertEqual(beforeEnter.activeRun, runBefore)
        XCTAssertTrue(beforeEnter.enterPendingWorld(arrivalReceiptID: receipt.id))
        XCTAssertEqual(beforeEnter.activeRun, runBefore)
        XCTAssertEqual(beforeEnter.state.reality.library.visitedWorlds, historyBefore)
        XCTAssertFalse(beforeEnter.enterPendingWorld(arrivalReceiptID: receipt.id))

        let afterEnter = GameStore(io: io)
        XCTAssertNil(afterEnter.state.worlds.pendingWorldArrivalReceiptID,
                     "a kill/relaunch after Enter must not replay arrival")
        XCTAssertEqual(afterEnter.activeRun, runBefore)
        XCTAssertEqual(afterEnter.state.reality.library.visitedWorlds, historyBefore)
    }

    @MainActor
    func testArrivalOrphansFailOpenDurablyAndRunExitClearsOwnership() throws {
        let io = SaveFileIO.temporary(name: "arrival-orphan-\(UUID().uuidString)")
        var store: GameStore? = GameStore(io: io)
        XCTAssertTrue(store?.bindAndDepart(
            worldPageInstanceID: WorldPageCatalog.earthlikeTestInstance.id) == true)
        store?.mutate("stage mismatched arrival", flush: true, scope: .arrivalLifecycle) {
            $0.worlds.pendingWorldArrivalReceiptID = .init(rawValue: "mismatch")
        }
        store = nil
        let firstRelaunch = GameStore(io: io)
        XCTAssertEqual(firstRelaunch.state.worlds.pendingWorldArrivalReceiptID?.rawValue,
                       "mismatch")
        XCTAssertNotNil(firstRelaunch.activeRun, "orphan reconciliation must fail open to map")
        XCTAssertTrue(firstRelaunch.reconcileOrphanWorldArrival())
        let secondRelaunch = GameStore(io: io)
        XCTAssertNil(secondRelaunch.state.worlds.pendingWorldArrivalReceiptID,
                     "orphan clearing must remain durable")

        secondRelaunch.mutate("stage exit orphan", flush: true, scope: .arrivalLifecycle) {
            $0.worlds.pendingWorldArrivalReceiptID = .init(rawValue: "exit-orphan")
        }
        secondRelaunch.endRunWithPartialHaul(reason: "Fixture", kind: .defeat)
        XCTAssertNil(secondRelaunch.activeRun)
        XCTAssertNil(secondRelaunch.state.worlds.pendingWorldArrivalReceiptID)

        let invalidIO = SaveFileIO.temporary(name: "arrival-invalid-\(UUID().uuidString)")
        var invalidStore: GameStore? = GameStore(io: invalidIO)
        XCTAssertTrue(invalidStore?.bindAndDepart(
            worldPageInstanceID: WorldPageCatalog.earthlikeTestInstance.id) == true)
        invalidStore?.mutate("corrupt persisted arrival", flush: true,
                             scope: .arrivalLifecycle) { state in
            state.worlds.activeRun?.worldArrivalReceipt?.sceneReceipt?.canonicalSHA256 = "bad"
        }
        invalidStore = nil
        let invalidRelaunch = GameStore(io: invalidIO)
        XCTAssertNil(invalidRelaunch.state.worlds.pendingWorldArrivalReceipt)
        XCTAssertNotNil(invalidRelaunch.activeRun)
        XCTAssertTrue(invalidRelaunch.reconcileOrphanWorldArrival())
        XCTAssertNil(GameStore(io: invalidIO).state.worlds.pendingWorldArrivalReceiptID)
    }

    @MainActor
    func testStarterBindFactoryFreezesExactAcceptedDescriptionsAndClosedCausalBands() throws {
        let expected = [
            "starter_open_meadow": "Broad sandy ground stretches into the distance. Your Plains Sigil opened the terrain, while your Verdant Sigil spread low growth farther along the few wet and stony edges.",
            "starter_rainwashed_shore": "Stone shelves rise as islands from shallow and deep water. Your Archipelago Sigil divided the route, while only the ground nearest the entry remained clearly visible.",
            "starter_stone_hollow": "Stone closes around narrow paths and wet hollows. Your Caverns Sigil shaped the enclosure, while your Ore Sigil made ore more plentiful."
        ]
        let closed: [WorldArrivalReceipt.CausalVisualFact.Scope: Set<String>] = [
            .ground: Set(GroundType.allCases.map(\.rawValue)),
            .water: ["none", "pools", "channels", "shelves", "islands"],
            .flora: ["none", "sparse", "present", "abundant"],
            .resource: ["absent", "present"],
            .light: ["trueDark", "dim", "ordinary", "bright", "blazing"],
            .atmosphere: Set(["smoke", "airborneAsh", "mist", "miasma"].flatMap { medium in
                ["trace", "light", "heavy", "dense"].map { "\(medium):\($0)" }
            }).union(["none"])
        ]
        for instance in WorldPageCatalog.starterInstances {
            let fixture = try GameStore.makeStarterWorldPagePhoneFixture(
                definitionID: instance.definition.id)
            let receipt = try XCTUnwrap(fixture.store.activeRun?.worldArrivalReceipt)
            XCTAssertEqual(receipt.finalDescription, expected[instance.definition.id.rawValue],
                           instance.definition.id.rawValue)
            let splash = try XCTUnwrap(receipt.worldSplashReceiptV3)
            switch instance.definition.id.rawValue {
            case "starter_open_meadow":
                XCTAssertEqual(splash.terrain.dominantDryGround, .sand)
                XCTAssertEqual(splash.water.shallowCount + splash.water.deepCount, 0)
                XCTAssertEqual(splash.flora.species.map(\.placedTileCount), [22])
                XCTAssertEqual(splash.relief.elevationCounts, [308, 16, 0, 0])
            case "starter_rainwashed_shore":
                XCTAssertEqual(splash.water.shallowCount, 84)
                XCTAssertEqual(splash.water.deepCount, 40)
                XCTAssertEqual(splash.water.topologyFlags.map(\.rawValue),
                               ["standing", "lake", "shelf", "island", "broken"])
                XCTAssertTrue(receipt.finalDescription.contains(
                    "only the ground nearest the entry remained clearly visible"))
                XCTAssertEqual(splash.relief.elevationCounts, [265, 59, 0, 0])
            case "starter_stone_hollow":
                XCTAssertEqual(splash.terrain.dominantDryGround, .stone)
                XCTAssertEqual(splash.relief.elevationCounts, [268, 56, 0, 0])
                XCTAssertEqual(splash.relief.elevatedComponentSizes, [13, 43])
                XCTAssertEqual(splash.relief.southContactCounts, [12, 0, 0])
                let commands = try XCTUnwrap(WorldArrivalNativeRenderer.splashCommands(for: splash))
                let positiveOreOwner = receipt.causalVisualFacts.first {
                    $0.scope == .resource && $0.semanticKey == "common_ore"
                        && $0.contributionKind == .increased
                }
                let oreRow = splash.explorationOpportunities.resources.first {
                    $0.stableID == Resources.ore.rawValue
                }
                if let positiveOreOwner {
                    XCTAssertEqual(oreRow?.causalMarkIDs, [positiveOreOwner.candidateMarkID])
                    XCTAssertTrue(commands.contains {
                        $0.scope == .resourceOpportunity && $0.semanticID == Resources.ore.rawValue
                    }, "positive same-seed Ore causality must own the S03 opportunity")
                } else {
                    XCTAssertNil(oreRow, "ordinary Ore without positive causality stays undisclosed")
                }
            default: XCTFail("unregistered starter matrix row")
            }
            XCTAssertTrue(splash.validates())
            XCTAssertEqual(splash.firstMapCropReceipt, receipt.firstMapCropReceipt)
            XCTAssertNotNil(WorldArrivalNativeRenderer.splashCommands(for: splash))
            XCTAssertNotNil(WorldArrivalNativeRenderer.placeholderImage(
                for: splash, size: .init(width: 320, height: 360)))
            XCTAssertEqual(fixture.store.state.reality.library.visitedWorlds.last?
                .worldArrivalReceipt?.worldSplashReceiptV3, splash)
            for fact in receipt.causalVisualFacts {
                XCTAssertTrue(closed[fact.scope, default: []].contains(fact.resultBand),
                              "open result band \(fact.resultBand)")
                XCTAssertTrue(closed[fact.scope, default: []].contains(fact.withoutAuthoredBand),
                              "open counterfactual band \(fact.withoutAuthoredBand)")
                XCTAssertFalse(fact.resultBand.contains(":" ) && fact.scope != .atmosphere)
                XCTAssertFalse(fact.resultBand.contains(";"))
            }
        }
    }

    func testHiddenArrivalCropCellsSerializeWithoutTerrainPayload() throws {
        let entry = GridPoint(x: 4, y: 4)
        func crop(hiddenGround: GroundType) -> WorldArrivalReceipt.FirstMapCrop {
            var tiles = Array(repeating: Tile(ground: .soil), count: 81)
            tiles[0] = Tile(ground: hiddenGround, flora: .init(rawValue: 999), elevation: 3,
                            isRevealed: false)
            let map = WorldMap(width: 9, height: 9, tiles: tiles, entry: entry)
            return WorldArrivalReceiptFactory.firstCrop(
                map: map, flora: [],
                profile: WorldRules.visibilityProfile(illumination: 0, baseRadius: 1))
        }
        let stone = crop(hiddenGround: .stone).cells.first { $0.point == .init(x: 0, y: 0) }
        let deepWater = crop(hiddenGround: .deepWater).cells.first { $0.point == .init(x: 0, y: 0) }
        let stoneCell = try XCTUnwrap(stone)
        let waterCell = try XCTUnwrap(deepWater)
        XCTAssertEqual(stoneCell, waterCell)
        XCTAssertEqual(stoneCell.visibility, "hidden")
        XCTAssertNil(stoneCell.ground)
        XCTAssertNil(stoneCell.elevation)
        XCTAssertNil(stoneCell.floraStableID)
        XCTAssertEqual(try JSONEncoder().encode(stoneCell),
                       try JSONEncoder().encode(waterCell))

        let data = try JSONEncoder().encode(stoneCell)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(object["visibility"] as? String, "hidden")
        XCTAssertNil(object["ground"])
        XCTAssertNil(object["elevation"])
        XCTAssertNil(object["floraStableID"])
    }

    func testArrivalCropUsesPartyAwareCurrentVisibilityWithoutPersistingFringe() {
        let entry = GridPoint(x: 4, y: 4)
        let tiles = Array(repeating: Tile(ground: .soil, isRevealed: false), count: 81)
        let map = WorldMap(width: 9, height: 9, tiles: tiles, entry: entry)
        let ordinary = WorldArrivalReceiptFactory.firstCrop(
            map: map, flora: [],
            profile: WorldRules.visibilityProfile(illumination: 100, baseRadius: 1))
        let perceptive = WorldArrivalReceiptFactory.firstCrop(
            map: map, flora: [],
            profile: WorldRules.visibilityProfile(illumination: 100, baseRadius: 1, sightBonus: 2))
        XCTAssertGreaterThan(perceptive.cells.count { $0.visibility == "full" },
                             ordinary.cells.count { $0.visibility == "full" })
        XCTAssertGreaterThan(ordinary.cells.count { $0.visibility == "fringe" }, 0)
        XCTAssertTrue(map.tiles.allSatisfy { !$0.isRevealed },
                      "arrival fringe is transient and must not become terrain memory")
    }

    func testSceneV2SerializesVisibilitySpecificCropKeys() throws {
        func keys(_ cell: WorldArrivalSceneReceipt.CropCell) throws -> Set<String> {
            let object = try XCTUnwrap(JSONSerialization.jsonObject(
                with: JSONEncoder().encode(cell)) as? [String: Any])
            return Set(object.keys)
        }
        let full = WorldArrivalSceneReceipt.CropCell(
            x: 1, y: 2, ground: .stone, elevation: 1, floraStableID: nil, visibility: "full")
        let fringe = WorldArrivalSceneReceipt.CropCell(
            x: 2, y: 2, ground: .soil, elevation: 0, floraStableID: nil, visibility: "fringe")
        let remembered = WorldArrivalSceneReceipt.CropCell(
            x: 3, y: 2, ground: .sand, elevation: 2, floraStableID: nil, visibility: "remembered")
        let hidden = WorldArrivalSceneReceipt.CropCell(
            x: 4, y: 2, ground: nil, elevation: nil, floraStableID: nil, visibility: "hidden")
        let disclosed: Set<String> = ["x", "y", "ground", "elevation", "floraStableID", "visibility"]
        XCTAssertEqual(try keys(full), disclosed)
        XCTAssertEqual(try keys(fringe), disclosed)
        XCTAssertEqual(try keys(remembered), disclosed)
        XCTAssertEqual(try keys(hidden), ["x", "y", "visibility"])

        let sanitized = WorldArrivalSceneReceipt.CausalVisualFact(
            markID: "common_ore", visibleScope: "resource", contributionKind: "increased",
            resultBand: "present", withoutAuthoredBand: "present")
        let object = try XCTUnwrap(JSONSerialization.jsonObject(
            with: JSONEncoder().encode(sanitized)) as? [String: Any])
        XCTAssertEqual(Set(object.keys), ["markID", "visibleScope", "contributionKind",
                                          "resultBand", "withoutAuthoredBand"])
    }

    func testDominantArrivalGroundExcludesWetAndUsesFrozenTieOrder() throws {
        let entry = GridPoint(x: 0, y: 0)
        let tied = WorldMap(width: 2, height: 2,
                            tiles: [Tile(ground: .sand), Tile(ground: .stone),
                                    Tile(ground: .water), Tile(ground: .deepWater)], entry: entry)
        XCTAssertEqual(try WorldArrivalReceiptFactory.dominantDryGround(in: tied), .stone)
        let wet = WorldMap(width: 2, height: 1,
                           tiles: [Tile(ground: .water), Tile(ground: .deepWater)], entry: entry)
        XCTAssertThrowsError(try WorldArrivalReceiptFactory.dominantDryGround(in: wet)) {
            XCTAssertEqual($0 as? WorldArrivalReceiptFactory.Error, .noDryGround)
        }
    }

    func testAcceptedStarterArrivalReceiptsProduceExactRulesOwnedDescriptions() throws {
        let expected = [
            "starter_open_meadow": "Broad sandy ground runs between shallow pools. Your Plains Sigil opened the terrain, while your Verdant Sigil spread low growth farther along the few wet and stony edges.",
            "starter_rainwashed_shore": "Stone shelves break a wide run of shallow and deep water. Your Archipelago Sigil divided the route, while only the ground nearest the entry remained clearly visible.",
            "starter_stone_hollow": "Stone closes around narrow paths and wet hollows. Your Caverns Sigil shaped the enclosure, while your Ore Sigil made ore more plentiful."
        ]
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .deletingLastPathComponent()
        let decoder = JSONDecoder()
        for (id, copy) in expected {
            let url = root.appendingPathComponent("AssetLab/fixtures/world-arrival-v1/\(id).json")
            let payload = try decoder.decode(WorldArrivalSceneReceipt.Payload.self,
                                             from: Data(contentsOf: url))
            XCTAssertEqual(try WorldArrivalDescriptionRules.describe(
                arrivalInput(payload, terrain: arrivalTerrain(id))), copy, id)
            if id == "starter_rainwashed_shore" {
                XCTAssertNotEqual(payload.description, copy,
                    "the frozen v0.3 proof predates the later trueDark priority correction")
            } else {
                XCTAssertEqual(payload.description, copy, "accepted Asset receipt drifted from authority")
            }
            let words = copy.split(whereSeparator: \.isWhitespace).count
            XCTAssertTrue((18...55).contains(words), "\(id): \(words) words")
        }
    }

    func testArrivalWaterBandsAreMutuallyExclusiveAtExactBoundaries() throws {
        let payload = try acceptedArrivalPayload("starter_open_meadow")
        func copy(_ wet: Int, _ deep: Int, _ total: Int = 100) throws -> String {
            try WorldArrivalDescriptionRules.describe(
                arrivalInput(payload, terrain: .init(
                    wetTileCount: wet, deepWaterTileCount: deep, nonChasmTileCount: total)))
        }
        XCTAssertTrue(try copy(0, 0).hasPrefix("Broad sandy ground stretches"))
        XCTAssertTrue(try copy(8, 0).hasPrefix("Broad sandy ground runs between shallow pools"))
        XCTAssertTrue(try copy(8, 1).hasPrefix(
            "Broad sandy ground runs between scattered pools of shallow and deep water"))
        XCTAssertTrue(try copy(9, 2).hasPrefix("Broad sandy ground runs around wet hollows"))
        XCTAssertTrue(try copy(35, 8).hasPrefix("Broad sandy ground runs around wet hollows"))
        XCTAssertTrue(try copy(35, 9).hasPrefix(
            "Broad sandy ground runs between shallow and deep water"))
        XCTAssertTrue(try copy(36, 0).hasPrefix("Broad sandy ground forms a few broad islands"))
    }

    func testOnlyRegisteredReshapingMarksOwnStructuralSentence() throws {
        var payload = try acceptedArrivalPayload("starter_open_meadow")
        let fact = WorldArrivalReceipt.CausalVisualFact(
            candidateMarkID: .init(rawValue: 1), semanticKey: "unregistered_shape",
            markDisplayName: "Terraces", sourcePageOrder: 0, scope: .ground,
            contributionKind: .reshaped, resultBand: "broad", withoutAuthoredBand: "broken")
        let copy = try WorldArrivalDescriptionRules.describe(
            .init(dominantDryGround: payload.dominantGround,
                  terrain: .init(wetTileCount: 0, deepWaterTileCount: 0, nonChasmTileCount: 100),
                  environment: arrivalEnvironment(payload), causalFacts: [fact]))
        XCTAssertTrue(copy.hasPrefix("Sandy ground stretches across the visible ground."))
        XCTAssertFalse(copy.hasPrefix("Broad sandy ground"))
    }

    func testOneCausalFactUsesExactPastTenseEnvironmentalFragment() throws {
        var payload = try acceptedArrivalPayload("starter_rainwashed_shore")
        let fact = WorldArrivalReceipt.CausalVisualFact(
            candidateMarkID: .init(rawValue: 1), semanticKey: "archipelago",
            markDisplayName: "Archipelago", sourcePageOrder: 0, scope: .water,
            contributionKind: .reshaped, resultBand: "shelves", withoutAuthoredBand: "broken")
        XCTAssertTrue(try WorldArrivalDescriptionRules.describe(
            .init(dominantDryGround: payload.dominantGround,
                  terrain: arrivalTerrain("starter_rainwashed_shore"),
                  environment: arrivalEnvironment(payload), causalFacts: [fact])).contains(
            "while sparse growth settled on the open stone."))
    }

    func testDesignOwnedFiftyFiveWordSpecimenIsValidationOnly() {
        let specimen = "Broad stone shelves rise above narrow soil paths and connected pools of shallow water, with deep channels cutting between the largest dry crossings. Your Archipelago Sigil divided the route into separate shelves, while your Verdant Sigil spread dense low growth across the dampest edges and left the higher exposed ground comparatively bare near the entry."
        XCTAssertEqual(specimen.split(whereSeparator: \.isWhitespace).count, 55)
        XCTAssertEqual(specimen.filter { ".!?".contains($0) }.count, 2)
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .deletingLastPathComponent()
        let source = try? String(contentsOf: root.appendingPathComponent(
            "Sources/Rules/WorldArrivalDescriptionRules.swift"))
        XCTAssertFalse(source?.contains("Broad stone shelves rise above narrow soil paths") == true,
                       "typography specimen must not become a runtime selector branch")
    }

    func testArrivalEnvironmentalFallbackKeepsPresentTenseAndUsesAggregateFlora() throws {
        var payload = try acceptedArrivalPayload("starter_open_meadow")
        payload.causalVisualFacts = []
        let terrain = WorldArrivalDescriptionRules.TerrainSummary(
            wetTileCount: 0, deepWaterTileCount: 0, nonChasmTileCount: 100)
        func copy(_ environment: WorldArrivalDescriptionRules.EnvironmentSummary) throws -> String {
            try WorldArrivalDescriptionRules.describe(.init(
                dominantDryGround: payload.dominantGround, terrain: terrain,
                environment: environment, causalFacts: []))
        }
        let base = WorldArrivalDescriptionRules.EnvironmentSummary(
            illuminationBand: "ordinary", suspendedMedium: "none", suspendedDensity: "none",
            precipitation: "none", precipitationIntensity: "none",
            floraCoverageBand: "none", floraHabit: "none")
        var condition = base
        condition.suspendedMedium = "smoke"; condition.suspendedDensity = "light"
        XCTAssertTrue(try copy(condition).contains("Thin smoke drifts through the open ground."))
        condition = base; condition.illuminationBand = "dim"
        XCTAssertTrue(try copy(condition).contains("Dim light leaves the farther ground subdued."))
        condition = base; condition.illuminationBand = "bright"
        XCTAssertTrue(try copy(condition).contains("Clear light separates the open surfaces."))
        condition = base; condition.floraCoverageBand = "sparse"; condition.floraHabit = "clustered"
        XCTAssertTrue(try copy(condition).contains("Sparse growth holds to a few open patches."))
        condition = base; condition.floraCoverageBand = "present"; condition.floraHabit = "spreading"
        XCTAssertTrue(try copy(condition).contains("Growth spreads through the open ground."))
        condition = base; condition.floraCoverageBand = "abundant"; condition.floraHabit = "clustered"
        XCTAssertTrue(try copy(condition).contains("Dense growth gathers in broad clusters."))
    }

    func testArrivalPairedFragmentUsesFrozenConditionPriority() throws {
        let payload = try acceptedArrivalPayload("starter_open_meadow")
        let fact = try XCTUnwrap(arrivalFacts(payload).first)
        let base = WorldArrivalDescriptionRules.EnvironmentSummary(
            illuminationBand: "ordinary", suspendedMedium: "none", suspendedDensity: "none",
            precipitation: "none", precipitationIntensity: "none",
            floraCoverageBand: "sparse", floraHabit: "spreading")
        func copy(_ environment: WorldArrivalDescriptionRules.EnvironmentSummary) throws -> String {
            try WorldArrivalDescriptionRules.describe(.init(
                dominantDryGround: payload.dominantGround,
                terrain: arrivalTerrain("starter_open_meadow"),
                environment: environment, causalFacts: [fact]))
        }

        var condition = base
        condition.illuminationBand = "trueDark"
        XCTAssertTrue(try copy(condition).contains(
            "only the ground nearest the entry remained clearly visible"))
        condition.illuminationBand = "blazing"
        XCTAssertTrue(try copy(condition).contains("hard light reached every open surface"))
        condition.illuminationBand = "dim"
        XCTAssertTrue(try copy(condition).contains("sparse growth settled"))
        XCTAssertFalse(try copy(condition).contains("dim light"))
        condition.illuminationBand = "bright"
        XCTAssertTrue(try copy(condition).contains("sparse growth settled"))
        XCTAssertFalse(try copy(condition).contains("clear light"))

        condition = base
        condition.suspendedMedium = "smoke"; condition.suspendedDensity = "light"
        XCTAssertTrue(try copy(condition).contains("thin smoke drifted"))
        condition = base
        condition.precipitation = "rain"; condition.precipitationIntensity = "light"
        XCTAssertTrue(try copy(condition).contains("light rain crossed"))
    }

    func testArrivalCausalCopyUsesFrozenLabelsAndExplicitPageOrder() throws {
        var payload = try acceptedArrivalPayload("starter_open_meadow")
        var facts = Array(arrivalFacts(payload).reversed())
        let copy = try WorldArrivalDescriptionRules.describe(
            .init(dominantDryGround: payload.dominantGround,
                  terrain: arrivalTerrain("starter_open_meadow"),
                  environment: arrivalEnvironment(payload), causalFacts: Array(facts)))
        XCTAssertTrue(copy.contains("Your Plains Sigil opened the terrain, while your Verdant Sigil"))

        facts[0].markDisplayName = nil
        let redacted = try WorldArrivalDescriptionRules.describe(
            .init(dominantDryGround: payload.dominantGround,
                  terrain: arrivalTerrain("starter_open_meadow"),
                  environment: arrivalEnvironment(payload), causalFacts: Array(facts)))
        XCTAssertFalse(redacted.contains("Verdant"), "unknown label must be ineligible, not derived from ID")
        XCTAssertFalse(redacted.contains("verdant"), "stable ID must never leak into player copy")
    }

    func testArrivalGrammarRejectsInvalidEnumsInsteadOfInventingFallbacks() throws {
        var payload = try acceptedArrivalPayload("starter_open_meadow")
        payload.dominantGround = .water
        XCTAssertThrowsError(try WorldArrivalDescriptionRules.describe(
            arrivalInput(payload, terrain: arrivalTerrain("starter_open_meadow")))) {
            XCTAssertEqual($0 as? WorldArrivalDescriptionRules.Error, .unknownGround)
        }
        payload = try acceptedArrivalPayload("starter_open_meadow")
        var incoherent = arrivalEnvironment(payload)
        incoherent.suspendedMedium = "none"
        incoherent.suspendedDensity = "light"
        XCTAssertThrowsError(try WorldArrivalDescriptionRules.describe(
            .init(dominantDryGround: payload.dominantGround,
                  terrain: arrivalTerrain("starter_open_meadow"), environment: incoherent,
                  causalFacts: arrivalFacts(payload)))) {
            XCTAssertEqual($0 as? WorldArrivalDescriptionRules.Error, .malformedEnvironment)
        }
        incoherent = arrivalEnvironment(payload)
        incoherent.floraCoverageBand = "none"
        incoherent.floraHabit = "mixed"
        XCTAssertThrowsError(try WorldArrivalDescriptionRules.describe(
            .init(dominantDryGround: payload.dominantGround,
                  terrain: arrivalTerrain("starter_open_meadow"), environment: incoherent,
                  causalFacts: arrivalFacts(payload)))) {
            XCTAssertEqual($0 as? WorldArrivalDescriptionRules.Error, .malformedEnvironment)
        }
    }

    func testArrivalIlluminationPreservesSourcelessBeforeConstantClassification() {
        let sourceless = PressureReading(
            target: "illumination", peak: 40, floor: 40, opposedMagnitude: 0,
            aspects: [:], forms: [:], tags: ["sourceless"])
        let wide = PressureReading(
            target: "illumination", peak: 90, floor: 20, opposedMagnitude: 0,
            aspects: [:], forms: [:], tags: [])
        let narrow = PressureReading(
            target: "illumination", peak: 40, floor: 20, opposedMagnitude: 0,
            aspects: [:], forms: [:], tags: [])
        let stopped = PressureReading(target: "cycle", peak: Tuning.DayNight.stoppedMaximumPeak,
                                      floor: 0, opposedMagnitude: 0,
                                      aspects: [:], forms: [:], tags: [])
        let moving = PressureReading(target: "cycle", peak: Tuning.DayNight.stoppedMaximumPeak + 1,
                                     floor: 0, opposedMagnitude: 0,
                                     aspects: [:], forms: [:], tags: [])
        XCTAssertEqual(WorldArrivalReceiptFactory.illuminationSourceClass(
            light: sourceless, cycle: moving), "sourceless")
        XCTAssertEqual(WorldArrivalReceiptFactory.illuminationSourceClass(
            light: wide, cycle: moving), "cyclic")
        XCTAssertEqual(WorldArrivalReceiptFactory.illuminationSourceClass(
            light: wide, cycle: stopped), "constant")
        XCTAssertEqual(WorldArrivalReceiptFactory.illuminationSourceClass(
            light: narrow, cycle: moving), "constant")
        XCTAssertEqual(WorldArrivalReceiptFactory.illuminationSourceClass(
            light: narrow, cycle: stopped), "constant")
    }

    func testArrivalCandidatesUseInsertionOrderAndRemoveTheCompleteSpeakingMark() throws {
        let definition = try XCTUnwrap(WorldPageCatalog.definition("starter_stone_hollow"))
        let page = definition.page
        let visible = page.runes.map { mark in
            WritingDeskVisibleMark(rendererAssetKey: mark.glyphID,
                                   visualRoute: mark.personalCompound == nil ? .authored(.source) : .personalCompoundCompatibility,
                                   id: mark.id, hand: mark.hand,
                                   origin: mark.origin, shapeID: mark.shapeID, cells: mark.cells,
                                   inkRecipe: mark.inkRecipe, displayName: mark.displayName,
                                   accessibilityName: mark.displayName, isReadable: true)
        }
        let candidates = WorldArrivalCausalCandidateRules.candidates(
            page: page, visibleMarks: visible)
        XCTAssertEqual(candidates.map(\.sourcePageOrder), candidates.map(\.sourcePageOrder).sorted())
        let ore = try XCTUnwrap(candidates.first { $0.semanticKey == "common_ore" })
        XCTAssertEqual(ore.displayLabel, "Ore")
        XCTAssertEqual(ore.registeredResourceFamilies, ["ore"])
        let removed = try XCTUnwrap(WorldArrivalCausalCandidateRules.removing(ore, from: page))
        XCTAssertFalse(removed.runes.contains { $0.id == ore.markID })
        XCTAssertFalse(removed.links.contains { $0.a == ore.markID || $0.b == ore.markID })
        XCTAssertFalse(removed.symbolIDs.contains("common_ore"))
    }

    func testArrivalResourceFactUsesExactObtainableWorldQuantityAndPresentBands() throws {
        let ore: ResourceID = "ore"
        let actual = WorldMap(width: 3, height: 1, tiles: [
            Tile(content: .node(.init(resource: ore, remainingHarvests: 2, yieldPerHarvest: 3))),
            Tile(content: .wildDrop(resource: ore, amount: 2)),
            Tile(content: .item(.init(id: .init(rawValue: 1), catalogID: Items.material,
                                      count: 99)))
        ], entry: .init(x: 0, y: 0))
        let without = WorldMap(width: 2, height: 1, tiles: [
            Tile(content: .node(.init(resource: ore, remainingHarvests: 1, yieldPerHarvest: 3))),
            Tile(content: .wildDrop(resource: ore, amount: 1))
        ], entry: .init(x: 0, y: 0))
        XCTAssertEqual(WorldArrivalCausalCandidateRules.resourceQuantity(ore, in: actual), 8)
        let candidate = WorldArrivalCausalCandidateRules.Candidate(
            markID: .init(rawValue: 7), semanticKey: "common_ore", displayLabel: "Ore",
            sourcePageOrder: 2, registeredResourceFamilies: [ore])
        let fact = try XCTUnwrap(WorldArrivalCausalCandidateRules.resourceFacts(
            candidate: candidate, actual: actual, withoutCandidate: without).first)
        XCTAssertEqual(fact.scope, .resource)
        XCTAssertEqual(fact.semanticKey, "common_ore")
        XCTAssertEqual(fact.contributionKind, .increased)
        XCTAssertEqual(fact.resultBand, "present")
        XCTAssertEqual(fact.withoutAuthoredBand, "present",
                       "exact quantity, not coarse band change, owns increased causality")

        var payload = try acceptedArrivalPayload("starter_stone_hollow")
        let unregistered = WorldArrivalReceipt.CausalVisualFact(
            candidateMarkID: .init(rawValue: 99), semanticKey: nil,
            markDisplayName: "Mystery deposits", sourcePageOrder: 0, scope: .resource,
            contributionKind: .increased, resultBand: "present", withoutAuthoredBand: "absent")
        XCTAssertThrowsError(try WorldArrivalDescriptionRules.describe(.init(
            dominantDryGround: payload.dominantGround,
            terrain: arrivalTerrain("starter_stone_hollow"),
            environment: arrivalEnvironment(payload), causalFacts: [unregistered]))) {
            XCTAssertEqual($0 as? WorldArrivalDescriptionRules.Error, .unregisteredResource)
        }
    }

    func testArrivalWaterCausalityUsesIndependentShallowAndDeepDeltas() {
        typealias Kind = WorldArrivalReceipt.CausalVisualFact.ContributionKind
        func classify(actualShallow: Int, actualDeep: Int,
                      withoutShallow: Int, withoutDeep: Int) -> Kind? {
            WorldArrivalCausalCandidateRules.waterContribution(
                actual: (actualShallow + actualDeep, actualDeep),
                without: (withoutShallow + withoutDeep, withoutDeep))
        }

        XCTAssertEqual(classify(actualShallow: 20, actualDeep: 5,
                                withoutShallow: 25, withoutDeep: 0), .reshaped,
                       "shallow-only becoming mixed changes composition")
        XCTAssertEqual(classify(actualShallow: 15, actualDeep: 10,
                                withoutShallow: 10, withoutDeep: 15), .reshaped,
                       "equal-total mixed redistribution changes shape")
        XCTAssertEqual(classify(actualShallow: 15, actualDeep: 10,
                                withoutShallow: 12, withoutDeep: 8), .increased)
        XCTAssertEqual(classify(actualShallow: 12, actualDeep: 8,
                                withoutShallow: 15, withoutDeep: 10), .reduced)
        XCTAssertEqual(classify(actualShallow: 10, actualDeep: 10,
                                withoutShallow: 14, withoutDeep: 8), .reshaped,
                       "opposing deltas must not cancel under the old wet+deep sum")
    }

    func testArrivalGrammarTieBreaksMalformedPageOrderByStableMarkIDThenScope() throws {
        let facts: [WorldArrivalReceipt.CausalVisualFact] = [
            .init(candidateMarkID: .init(rawValue: 30), semanticKey: "verdant",
                  markDisplayName: "Verdant", sourcePageOrder: 0, scope: .flora,
                  contributionKind: .increased, resultBand: "present",
                  withoutAuthoredBand: "sparse"),
            .init(candidateMarkID: .init(rawValue: 10), semanticKey: "archipelago",
                  markDisplayName: "Archipelago", sourcePageOrder: 0, scope: .water,
                  contributionKind: .reshaped, resultBand: "shelves",
                  withoutAuthoredBand: "channels"),
            .init(candidateMarkID: .init(rawValue: 20), semanticKey: "plains",
                  markDisplayName: "Plains", sourcePageOrder: 0, scope: .ground,
                  contributionKind: .reshaped, resultBand: "sand",
                  withoutAuthoredBand: "stone")
        ]
        let payload = try acceptedArrivalPayload("starter_rainwashed_shore")
        func copy(_ values: [WorldArrivalReceipt.CausalVisualFact]) throws -> String {
            try WorldArrivalDescriptionRules.describe(.init(
                dominantDryGround: payload.dominantGround,
                terrain: arrivalTerrain("starter_rainwashed_shore"),
                environment: arrivalEnvironment(payload), causalFacts: values))
        }
        let expected = try copy(facts)
        XCTAssertEqual(try copy([facts[2], facts[0], facts[1]]), expected)
        XCTAssertEqual(try copy([facts[1], facts[2], facts[0]]), expected)
        XCTAssertEqual(try copy(Array(facts.reversed())), expected)
    }

    func testCausalInterventionPreservesUnrelatedActualRollsAndUsesEmptyBaselineForNewSilence() throws {
        let authored = [Sigil(id: .init(rawValue: 91), source: "sun",
                              target: "illumination", intensity: .moderate)]
        let intervention = PressureRules.causalIntervention(
            actualAuthored: authored, remainingAuthored: [], seed: 4_242)
        let newlySilent = try XCTUnwrap(ContentCatalog.shared.pressureSource("sun")).targets
        for rolled in intervention.actualRolled where !newlySilent.contains(rolled.target) {
            XCTAssertTrue(intervention.counterfactualSigils.contains(rolled),
                          "unrelated actual roll shifted for \(rolled.target.rawValue)")
        }
        for target in newlySilent {
            XCTAssertTrue(intervention.counterfactualSigils.contains(
                try XCTUnwrap(intervention.baselineByTarget[target])),
                "newly silent target did not receive its full-empty baseline roll")
        }
    }

    private func acceptedArrivalPayload(_ id: String) throws -> WorldArrivalSceneReceipt.Payload {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .deletingLastPathComponent()
        return try JSONDecoder().decode(
            WorldArrivalSceneReceipt.Payload.self,
            from: Data(contentsOf: root.appendingPathComponent(
                "AssetLab/fixtures/world-arrival-v1/\(id).json")))
    }

    private func arrivalFacts(
        _ payload: WorldArrivalSceneReceipt.Payload
    ) -> [WorldArrivalReceipt.CausalVisualFact] {
        let labels = ["plains": "Plains", "verdant": "Verdant", "archipelago": "Archipelago",
                      "caverns": "Caverns", "common_ore": "Ore"]
        return payload.causalVisualFacts.enumerated().compactMap { index, fact in
            guard let contribution = WorldArrivalReceipt.CausalVisualFact.ContributionKind(
                rawValue: fact.contributionKind),
                  let scope = WorldArrivalReceipt.CausalVisualFact.Scope(
                    rawValue: fact.markID == "common_ore" ? "resource" : fact.visibleScope)
            else { return nil }
            return .init(candidateMarkID: .init(rawValue: UInt64(index + 1)),
                         semanticKey: fact.markID, markDisplayName: labels[fact.markID],
                         sourcePageOrder: index, scope: scope, contributionKind: contribution,
                         resultBand: fact.resultBand,
                         withoutAuthoredBand: fact.withoutAuthoredBand)
        }
    }

    private func arrivalInput(
        _ payload: WorldArrivalSceneReceipt.Payload,
        terrain: WorldArrivalDescriptionRules.TerrainSummary
    ) -> WorldArrivalDescriptionRules.Input {
        .init(dominantDryGround: payload.dominantGround, terrain: terrain,
              environment: arrivalEnvironment(payload), causalFacts: arrivalFacts(payload))
    }

    private func arrivalTerrain(_ id: String) -> WorldArrivalDescriptionRules.TerrainSummary {
        switch id {
        case "starter_open_meadow": .init(wetTileCount: 8, deepWaterTileCount: 0,
                                            nonChasmTileCount: 100)
        case "starter_rainwashed_shore": .init(wetTileCount: 30, deepWaterTileCount: 10,
                                                 nonChasmTileCount: 100)
        default: .init(wetTileCount: 20, deepWaterTileCount: 2, nonChasmTileCount: 100)
        }
    }

    private func arrivalEnvironment(
        _ payload: WorldArrivalSceneReceipt.Payload
    ) -> WorldArrivalDescriptionRules.EnvironmentSummary {
        let flora = payload.flora.first
        return .init(illuminationBand: payload.illumination.band,
                     suspendedMedium: payload.suspendedAtmosphere.medium,
                     suspendedDensity: payload.suspendedAtmosphere.density,
                     precipitation: payload.precipitation.medium,
                     precipitationIntensity: payload.precipitation.intensity,
                     floraCoverageBand: flora?.coverage ?? "none",
                     floraHabit: flora?.habit ?? "none")
    }

    func testLegacyAndOrphanArrivalStateDecodeWithoutInventingAReveal() throws {
        var seeds = SeedSequence.newGame()
        let legacy = WorldsState.newGame(seeds: &seeds)
        let decoded = try JSONDecoder().decode(WorldsState.self,
                                               from: JSONEncoder().encode(legacy))
        XCTAssertNil(decoded.pendingWorldArrivalReceiptID)
        XCTAssertNil(decoded.pendingWorldArrivalReceipt)
    }

    @MainActor
    func testBand2TemplatesPhoneFixtureRelaunchesNearCapWithDirtyLegalDraftAndStableIDs() throws {
        let fixture = try GameStore.makeBand2TemplatesPhoneFixture()
        let receipt = fixture.receipt
        XCTAssertEqual(receipt.templateCount, PageTemplateRules.capacity - 1)
        XCTAssertEqual(receipt.capacity, PageTemplateRules.capacity)
        XCTAssertGreaterThan(receipt.currentDraftMarkCount, 0)
        XCTAssertEqual(receipt.stableTemplateIDs,
                       fixture.store.state.base.savedPageTemplates.sorted {
                           $0.creationOrdinal < $1.creationOrdinal
                       }.map(\.id))
        XCTAssertEqual(Set(receipt.stableTemplateIDs).count, receipt.stableTemplateIDs.count)

        let first = try XCTUnwrap(receipt.stableTemplateIDs.first)
        let ordinal = try XCTUnwrap(fixture.store.state.base.savedPageTemplates.first {
            $0.id == first
        }?.creationOrdinal)
        XCTAssertEqual(fixture.store.renamePageTemplate(first, to: "Phone renamed"),
                       .updated(first))
        XCTAssertEqual(fixture.store.overwritePageTemplate(first), .updated(first))
        XCTAssertEqual(fixture.store.state.base.savedPageTemplates.first {
            $0.id == first
        }?.creationOrdinal, ordinal)
        fixture.store.clearPage()
        XCTAssertEqual(fixture.store.loadPageTemplate(first), .loaded(first))
        XCTAssertEqual(fixture.store.deletePageTemplate(first), .deleted(first))
    }

    func testSettingsExposesDisposableTemplatesAcceptanceThroughProductionDesk() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .deletingLastPathComponent()
        let source = try String(contentsOf: root.appending(path:
            "Sources/Screens/SettingsView.swift"), encoding: .utf8)
        XCTAssertTrue(source.contains("settings.page-templates-acceptance"))
        XCTAssertTrue(source.contains("Page Templates acceptance"))
        XCTAssertTrue(source.contains("WritingDeskView().environmentObject(session.store)"))
        XCTAssertTrue(source.contains("band2-templates-fixture-receipt"))
        XCTAssertTrue(source.contains("Load over the dirty draft"))
        XCTAssertTrue(source.contains("rename, overwrite and delete"))
    }

    @MainActor
    func testStarterWorldPagePhoneFixturesUseProductionReceiptsRevealedFindsAndSafeRoutes() throws {
        for instance in WorldPageCatalog.starterInstances {
            let fixture = try GameStore.makeStarterWorldPagePhoneFixture(
                definitionID: instance.definition.id)
            let receipt = fixture.receipt
            XCTAssertEqual(receipt.pageDefinitionID, instance.definition.id)
            XCTAssertEqual(receipt.pageInstanceID, instance.id)
            XCTAssertEqual(receipt.mapSeed, instance.definition.seed)
            XCTAssertEqual(receipt.itemID, instance.definition.knownFind)
            XCTAssertEqual(receipt.itemInstanceID,
                           StarterKnownFindPlacementRules.stableInstanceID(for:
                            try XCTUnwrap(fixture.store.activeRun?.book.worldPageUseReceipt)))
            XCTAssertTrue((1...2).contains(receipt.safePathToRevealedFind.count - 1))
            XCTAssertEqual(receipt.safePathToRevealedFind.first,
                           fixture.store.activeRun?.playerPosition)
            XCTAssertEqual(receipt.safePathToRevealedFind.last, receipt.placement)
            XCTAssertTrue(fixture.store.activeRun?.map[receipt.placement].isRevealed == true)
            XCTAssertTrue(receipt.safePathToRevealedFind.allSatisfy {
                fixture.store.activeRun?.map[$0].ground.movementCost == 1
            })
            XCTAssertFalse(fixture.store.state.base.collectedWorldPages.contains {
                $0.id == instance.id
            }, "the production bind transaction must consume only the disposable copy")
        }
    }

    func testSettingsExposesDisposableStarterWorldPageAcceptanceRoute() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .deletingLastPathComponent()
        let settings = try String(
            contentsOf: root.appending(path: "Sources/Screens/SettingsView.swift"),
            encoding: .utf8)
        let harness = try String(
            contentsOf: root.appending(path: "Sources/Debug/HarnessActions.swift"),
            encoding: .utf8)
        XCTAssertTrue(settings.contains("settings.starter-world-pages-acceptance"))
        XCTAssertTrue(settings.contains("starter-world-page-receipt"))
        XCTAssertTrue(harness.contains("GameStore(io: .temporary("))
        XCTAssertTrue(harness.contains("bindAndDepart(worldPageInstanceID: instance.id)"))
    }

    func testSettingsExposesWildWorldPagesAcceptanceAcrossRealSurfaces() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .deletingLastPathComponent()
        let settings = try String(contentsOf: root.appending(path:
            "Sources/Screens/SettingsView.swift"), encoding: .utf8)
        let harness = try String(contentsOf: root.appending(path:
            "Sources/Debug/HarnessActions.swift"), encoding: .utf8)
        XCTAssertTrue(settings.contains("settings.wild-world-pages-acceptance"))
        XCTAssertTrue(settings.contains("RootView().environmentObject(fixture.store)"))
        XCTAssertTrue(settings.contains("WritingDeskView()"))
        XCTAssertTrue(settings.contains("wild-world-pages-fixture-receipt"))
        XCTAssertTrue(harness.contains("endRunWithPartialHaul"))
        XCTAssertTrue(harness.contains("bindAndDepart()"))
        XCTAssertTrue(harness.contains("GameStore(io: fixture.io)"))
    }

    @MainActor
    func testWildWorldPagesPhoneFieldFixturesUseExactProductionTransactions() throws {
        let room = try GameStore.makeWildWorldPagesPhoneFixture(kind: .fieldWithRoom)
        let offered = try XCTUnwrap(room.store.activeRun?.offeredWorldPages.first)
        XCTAssertFalse(offered.inspected)
        let beforeSightings = room.store.state.reality.encounteredLexemes
        let quote = try XCTUnwrap(room.store.offeredWorldPageQuote(offered.id))
        XCTAssertEqual(room.store.takeOfferedWorldPage(quote), .taken(offered))
        XCTAssertEqual(room.store.state.reality.encounteredLexemes, beforeSightings,
                       "picking up an unopened page must not record Dictionary sightings")
        XCTAssertEqual(room.store.activeRun?.carriedWorldPages, [offered])
        XCTAssertFalse(try XCTUnwrap(room.store.activeRun?.carriedWorldPages.first).inspected)

        let full = try GameStore.makeWildWorldPagesPhoneFixture(kind: .fullSatchel)
        let fullPage = try XCTUnwrap(full.store.activeRun?.offeredWorldPages.first)
        let cancelledState = full.store.state
        XCTAssertEqual(full.store.state, cancelledState, "cancelling is deliberately no action")
        let swapQuote = try XCTUnwrap(full.store.offeredWorldPageQuote(fullPage.id))
        XCTAssertEqual(full.store.takeOfferedWorldPage(swapQuote), .satchelFull)
        XCTAssertEqual(full.store.activeRun?.offeredWorldPages,
                       cancelledState.worlds.activeRun?.offeredWorldPages)
        XCTAssertEqual(full.store.activeRun?.satchelItems,
                       cancelledState.worlds.activeRun?.satchelItems)
        XCTAssertEqual(full.store.activeRun?.carriedWorldPages,
                       cancelledState.worlds.activeRun?.carriedWorldPages)
        XCTAssertEqual(full.store.state.reality.encounteredLexemes,
                       cancelledState.reality.encounteredLexemes)
        let itemID = try XCTUnwrap(full.store.activeRun?.satchelItems.stacks.first?.id)
        guard case .swapped(let taken, discarded: .itemStack(let discarded)) =
                full.store.swapOfferedWorldPage(swapQuote, discarding: .itemStack(itemID)) else {
            return XCTFail("expected exact item-to-page swap")
        }
        XCTAssertEqual(taken.id, fullPage.id)
        XCTAssertFalse(taken.inspected)
        XCTAssertEqual(discarded.id, itemID)
        XCTAssertEqual(full.store.state.reality.encounteredLexemes,
                       cancelledState.reality.encounteredLexemes,
                       "swapping for an unopened page must not record Dictionary sightings")
    }

    func testWorldInteractTakesLoosePageDirectlyWithoutInspectOrSuccessModal() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .deletingLastPathComponent()
        let source = try String(contentsOf: root.appending(path:
            "Sources/Screens/WorldView.swift"), encoding: .utf8)
        let interaction = try XCTUnwrap(source.components(separatedBy:
            "private func performInteraction()").dropFirst().first)
            .components(separatedBy: "private func completeWorldPageSwap")[0]

        XCTAssertTrue(interaction.contains("store.takeOfferedWorldPage(quote)"))
        XCTAssertFalse(interaction.contains("store.inspectOfferedWorldPage"),
                       "field Interact must not require Inspect before Take")
        XCTAssertFalse(interaction.contains("case .taken(let"),
                       "successful pickup must not open a result alert")
        XCTAssertTrue(source.contains("Take loose page · 1 satchel slot · no turn"))
        XCTAssertFalse(source.contains("Inspect Loose page · no turn"))
    }

    @MainActor
    func testWildWorldPagesPhoneFailureAndLaterBindReceiptsAreExactAndDurable() throws {
        let failure = try GameStore.makeWildWorldPagesPhoneFixture(kind: .failureReceipt)
        let summary = try XCTUnwrap(failure.store.state.worlds.lastExit)
        XCTAssertNil(failure.store.activeRun)
        XCTAssertFalse(summary.keptWorldPages.isEmpty)
        XCTAssertTrue(summary.keptWorldPages.contains(where: \.isProtectedReturn))
        XCTAssertEqual(failure.store.state.worlds.worldPageBankedOutcomeIDs,
                       [try XCTUnwrap(summary.outcomeID)])

        let bind = try GameStore.makeWildWorldPagesPhoneFixture(kind: .laterBind)
        let pages = bind.store.state.base.collectedWorldPages
        XCTAssertEqual(pages.count, 2)
        XCTAssertTrue(bind.store.bindAndDepart(worldPageInstanceID: pages[0].id))
        XCTAssertEqual(bind.store.activeRun?.book.worldPageUseReceipt?.instanceID, pages[0].id)
        XCTAssertFalse(bind.store.state.base.collectedWorldPages.contains { $0.id == pages[0].id })
        XCTAssertTrue(bind.store.state.base.collectedWorldPages.contains { $0.id == pages[1].id })
    }

    func testWritingDeskConcealsUninspectedWildPageAuthorityUntilExactOpen() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .deletingLastPathComponent()
        let source = try String(contentsOf: root.appending(path: "Sources/Screens/WritingDeskView.swift"),
                                encoding: .utf8)
        XCTAssertTrue(source.contains("instance.fieldProvenance != nil && !instance.inspected"))
        XCTAssertTrue(source.contains("concealsFieldPage ? \"Unknown page\" : instance.definition.title"))
        XCTAssertTrue(source.contains("if !concealsFieldPage"))
    }

    @MainActor
    func testHomeInspectionPersistsExactWildPageKnowledge() throws {
        let definition = try XCTUnwrap(WorldPageCatalog.definition("wild_storm_coast"))
        let instance = WorldPageInstance(
            id: InstanceID(rawValue: 7_001), definition: definition,
            fieldProvenance: .init(originRunIndex: 2, originWorldSeed: 3,
                                   generationSeed: 4, position: GridPoint(x: 1, y: 1)))
        let store = GameStore(io: .temporary(name: "inspect-wild-home-\(UUID().uuidString)"))
        store.mutate("install wild page") { $0.base.collectedWorldPages.append(instance) }
        XCTAssertTrue(store.inspectWorldPage(instance.id))
        let current = try XCTUnwrap(store.state.base.collectedWorldPages.first {
            $0.id == instance.id
        })
        XCTAssertTrue(current.inspected)
        XCTAssertEqual(store.state.reality.encounteredLexemes,
                       definition.page.encounteredLexemes)
    }
    func testRepeatableWorldPagesMatchGeneratedAuthorityAndCarryFieldIdentity() throws {
        let definitions = WorldPageCatalog.repeatableDefinitions
        XCTAssertEqual(definitions.map(\.id), [
            "wild_moss_and_mist", "wild_salt_and_iron", "wild_winter_hollows",
            "wild_cinder_fields", "wild_gilded_caverns", "wild_storm_coast",
            "wild_blighted_garden", "wild_mote_understone"
        ])
        XCTAssertEqual(definitions.map(\.disposition),
                       Array(repeating: .repeatable, count: 7) + [.repeatableRare])
        XCTAssertEqual(definitions.map(\.minimumResolvedExpeditions), [1, 1, 1, 1, 2, 3, 3, 5])
        XCTAssertEqual(definitions.map(\.worldPageCost), [17, 17, 16, 17, 19, 18, 18, 25])
        XCTAssertEqual(definitions.map(\.baseWeightMultiplier), [1, 1, 1, 1, 1, 1, 1, 0.35])
        XCTAssertEqual(definitions.map { $0.candidateUnknownSymbolIDs.map(\.rawValue) },
                       [[], [], [], [], [], ["storm"], ["blight"], ["mote_vein"]])
        XCTAssertTrue(definitions.allSatisfy { $0.seed == 0 && $0.disposition.isRandom })
        XCTAssertEqual(WorldPageCatalog.definitions.count,
                       WorldPageCatalog.starterDefinitions.count
                           + WorldPageCatalog.repeatableDefinitions.count + 1,
                       "the permanent Earthlike testing page is additional to authored starter and wild pages")
        XCTAssertEqual(WorldPageCatalog.definition("wild_storm_coast")?.title, "Storm Coast")

        let page = try XCTUnwrap(WorldPageCatalog.definition("wild_storm_coast"))
        let instance = WorldPageInstance(
            id: InstanceID(rawValue: 9001), definition: page, inspected: true,
            fieldProvenance: .init(originRunIndex: 7, originWorldSeed: 55,
                                   generationSeed: 77, position: GridPoint(x: 4, y: 9)))
        XCTAssertFalse(instance.isProtectedReturn)
        XCTAssertTrue(instance.isRandomDrop)
        XCTAssertEqual(try SaveCodec.makeDecoder().decode(
            WorldPageInstance.self, from: SaveCodec.makeEncoder().encode(instance)), instance)
    }

    func testLegacyStarterPageInstanceDecodesWithUninspectedNoFieldOrigin() throws {
        let legacy = WorldPageCatalog.starterInstances[0]
        var object = try XCTUnwrap(JSONSerialization.jsonObject(
            with: SaveCodec.makeEncoder().encode(legacy)) as? [String: Any])
        object.removeValue(forKey: "inspected")
        object.removeValue(forKey: "fieldProvenance")
        if var definition = object["definition"] as? [String: Any] {
            definition.removeValue(forKey: "knownFind")
            object["definition"] = definition
        }
        let decoded = try SaveCodec.makeDecoder().decode(
            WorldPageInstance.self, from: JSONSerialization.data(withJSONObject: object))
        XCTAssertFalse(decoded.inspected)
        XCTAssertNil(decoded.fieldProvenance)
        XCTAssertNil(decoded.definition.knownFind)
        XCTAssertTrue(decoded.isProtectedReturn)
    }

    func testStarterWorldPagesMatchFrozenAuthorityAndRulesOwnedPrices() throws {
        let definitions = WorldPageCatalog.starterDefinitions
        XCTAssertEqual(definitions.map(\.id), ["starter_open_meadow", "starter_rainwashed_shore",
                                                "starter_stone_hollow"])
        XCTAssertEqual(definitions.map(\.disposition), [.starterUnique, .starterUnique, .starterUnique])
        XCTAssertEqual(definitions.map(\.seed), [67, 26, 23])
        XCTAssertEqual(definitions.map(\.copiedCost), [21, 18, 22])
        XCTAssertEqual(definitions.map(\.worldPageCost), [14, 14, 16])
        XCTAssertEqual(definitions.map(\.title), ["Open Flats", "Rainwashed Shore", "Stone Hollow"])
        XCTAssertEqual(definitions.map(\.knownFind), ["field_maul", "bone_awl", "blade_chipped"])
        XCTAssertEqual(definitions.map(\.provenance), [
            "A clean practice page, already written in rough charcoal.",
            "A clean practice page with one broad charcoal mark.",
            "A clean practice page with charcoal rubbed into the grain."
        ])
        XCTAssertEqual(definitions.map(\.promise), [
            "Broad passable flats, low growth and shallow water with three ordinary creatures and strong continuation runway.",
            "A readable water-and-relief contrast without an opening lethality spike.",
            "Stone, enclosure and ordinary ore within the accepted level-one envelope."
        ])
        XCTAssertTrue(definitions.allSatisfy { $0.page.width == 6 && $0.page.height == 6 })
        XCTAssertTrue(definitions.allSatisfy { $0.page.runes.allSatisfy { $0.hand == .crude } })
        XCTAssertEqual(definitions.map { $0.page.runes.map(\.id.rawValue) }, [[1, 2], [1], [1, 2]])
        XCTAssertEqual(definitions.map { $0.page.runes.map(\.shapeID) },
                       [["crude_smear", "crude_smear"], ["crude_smear"],
                        ["crude_smear", "crude_block"]])
        XCTAssertEqual(definitions.map { $0.page.symbolIDs.map(\.rawValue) },
                       [["plains", "verdant"], ["archipelago"], ["caverns", "common_ore"]])
        XCTAssertEqual(definitions.map { $0.page.runes.map(\.origin) }, [
            [PageCell(column: 0, row: 0), PageCell(column: 3, row: 3)],
            [PageCell(column: 1, row: 2)],
            [PageCell(column: 0, row: 1), PageCell(column: 4, row: 3)]
        ])

        let instances = WorldPageCatalog.starterInstances
        XCTAssertEqual(Set(instances.map(\.id)).count, 3)
        XCTAssertEqual(instances.map(\.id.rawValue),
                       [0x5750_0000_0000_0001, 0x5750_0000_0000_0002,
                        0x5750_0000_0000_0003])
        let projectRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let authority = projectRoot.appendingPathComponent("docs/world-pages-authority.json")
        let sourceAuthoritySHA256 = try SHA256.hash(data: Data(contentsOf: authority))
            .map { String(format: "%02x", $0) }.joined()
        XCTAssertEqual(WorldPageCatalog.authoritySHA256, sourceAuthoritySHA256,
                       "generated World Page authority must match its source document")
        XCTAssertNil(WorldPageCatalog.definition("not_authored"),
                     "unknown content must fail closed rather than fabricate a page")
        for instance in instances {
            let ordinary = BookRules.resolveBook(page: instance.definition.page)
            let preInscribed = BookRules.resolveBook(worldPage: instance)
            XCTAssertEqual(ordinary.essencePaid, instance.definition.copiedCost)
            XCTAssertEqual(preInscribed.essencePaid, instance.definition.worldPageCost)
            XCTAssertEqual(preInscribed.essencePaid,
                           ordinary.essencePaid - BookRules.inkCost(of: instance.definition.page))
            XCTAssertEqual(preInscribed.worldPageUseReceipt?.instanceID, instance.id)
            XCTAssertEqual(preInscribed.worldPageUseReceipt?.definition, instance.definition)
        }

        let data = try SaveCodec.makeEncoder().encode(instances)
        XCTAssertEqual(try SaveCodec.makeDecoder().decode([WorldPageInstance].self, from: data), instances)
    }

    func testLegacyBoundBookDecodesWithoutWorldPageReceipt() throws {
        let data = Data(#"{"written":["plains"],"essencePaid":14}"#.utf8)
        let book = try SaveCodec.makeDecoder().decode(BoundBook.self, from: data)
        XCTAssertNil(book.worldPageUseReceipt)
        XCTAssertEqual(book.allSymbolIDs, ["plains"])
        XCTAssertEqual(book.essencePaid, 14)
    }

    func testCancellingPageToolClearsEveryTransientFieldWithoutChangingThePage() {
        let link = MarkLink(InstanceID(rawValue: 1), InstanceID(rawValue: 2))
        let page = Page(links: [link])
        var session = PageInteractionSession(mode: .connecting,
                                             anchor: InstanceID(rawValue: 1),
                                             held: InstanceID(rawValue: 2),
                                             connectionError: "Not adjacent")

        session.cancel()

        XCTAssertEqual(session.mode, .off)
        XCTAssertNil(session.anchor)
        XCTAssertNil(session.held)
        XCTAssertNil(session.connectionError)
        XCTAssertEqual(page.links, [link], "dismissing a tool must not undo completed links")
    }

    func testPageIdentityTracksPageReplacementButNotLinkEdits() {
        let ids = [InstanceID(rawValue: 3), InstanceID(rawValue: 7)]
        let original = PageInteractionIdentity(width: 6, height: 6, runeIDs: ids)
        let linkOnlyEdit = PageInteractionIdentity(width: 6, height: 6, runeIDs: ids)
        let replacement = PageInteractionIdentity(width: 6, height: 6,
                                                  runeIDs: [InstanceID(rawValue: 9)])

        XCTAssertEqual(original, linkOnlyEdit,
                       "completed Connect/Disconnect edits must not cancel their own mode")
        XCTAssertNotEqual(original, replacement)
    }

    // MARK: The page is a budget, not a syntax

    /// **Superseded in part** (decisions-session-14 §3). Absolute position still carries no
    /// meaning, which is what this checks — but *relative* position now does, and the rule that
    /// replaced this one lives in `GrammarTests`: translate or rotate the whole page and it must
    /// say exactly the same thing.
    ///
    /// This case survives because the marks in it are **self-contained** — compounds and
    /// whole-statement runes say what they say wherever they sit, with or without neighbours.
    func testSelfContainedMarksSayTheSameThingWhereverTheySit() {
        let sigils = [
            Sigil(id: InstanceID(rawValue: 1), source: "sun", target: "illumination", intensity: .great),
            Sigil(id: InstanceID(rawValue: 2), source: "glacier", target: "hydrology", intensity: .moderate)
        ]

        var tidy = Page()
        var scattered = Page()
        for sigil in sigils {
            tidy = PageRules.placeAnywhere(sigil, hand: .refined, on: tidy)!
        }
        // Same runes, deliberately different squares.
        scattered = PageRules.place(sigils[1], hand: .refined, at: PageCell(column: 5, row: 5), on: scattered)!
        scattered = PageRules.place(sigils[0], hand: .refined, at: PageCell(column: 0, row: 3), on: scattered)!

        XCTAssertNotEqual(tidy.runes.map(\.origin), scattered.runes.map(\.origin),
                          "the two pages were laid out the same, so this proves nothing")
        XCTAssertEqual(PressureRules.resolve(tidy.sigils), PressureRules.resolve(scattered.sigils))
    }

    /// Reading order isn't meaning either — `sigils` sorts by identity, not by where things landed.
    func testSigilOrderDoesNotDependOnLayout() {
        let a = Sigil(id: InstanceID(rawValue: 1), source: "sun", target: "illumination")
        let b = Sigil(id: InstanceID(rawValue: 2), source: "ice", target: "thermal")

        let first = PageRules.place(b, hand: .refined, at: PageCell(column: 0, row: 0), on: Page())!
        let second = PageRules.place(a, hand: .refined, at: PageCell(column: 3, row: 3), on: first)!
        XCTAssertEqual(second.sigils.map(\.id.rawValue), [1, 2])
    }

    // MARK: Fitting

    func testARuneCannotOverlapAnother() {
        let page = PageRules.place(
            Sigil(id: InstanceID(rawValue: 1), source: "sun", target: "illumination"),
            hand: .crude, at: PageCell(column: 0, row: 0), on: Page())!

        let occupied = page.runes[0].cells[0]
        XCTAssertNil(PageRules.place(
            Sigil(id: InstanceID(rawValue: 2), source: "ice", target: "thermal"),
            hand: .refined, at: occupied, on: page),
                     "two runes wrote over each other")
    }

    func testARuneCannotHangOffTheEdge() {
        let page = Page()
        let corner = PageCell(column: page.width - 1, row: page.height - 1)
        XCTAssertNil(PageRules.place(
            Sigil(id: InstanceID(rawValue: 1), source: "sun", target: "illumination"),
            hand: .crude, at: corner, on: page),
                     "a charcoal scrawl fitted into a single corner cell")
    }

    func testAFullPageRefusesMore() {
        var page = Page(width: 2, height: 2)
        for index in 0..<4 {
            let sigil = Sigil(id: InstanceID(rawValue: UInt64(index)), source: "sun", target: "illumination")
            page = PageRules.placeAnywhere(sigil, hand: .refined, on: page)!
        }
        XCTAssertEqual(page.freeCells, 0)
        XCTAssertNil(PageRules.placeAnywhere(
            Sigil(id: InstanceID(rawValue: 99), source: "ice", target: "thermal"),
            hand: .refined, on: page))
    }

    func testRemovingARuneFreesItsCells() {
        let sigil = Sigil(id: InstanceID(rawValue: 1), source: "sun", target: "illumination")
        let page = PageRules.placeAnywhere(sigil, hand: .crude, on: Page())!
        XCTAssertGreaterThan(page.usedCells, 1)
        XCTAssertEqual(PageRules.remove(sigil.id, from: page).usedCells, 0)
    }

    // MARK: Refinement is literacy, not power

    func testABetterHandSaysTheSameThingInLessSpace() {
        let sigil = Sigil(id: InstanceID(rawValue: 1), source: "sun", target: "illumination")
        var previous = Int.max
        for hand in Hand.allCases {   // crude → plain → refined
            let page = PageRules.placeAnywhere(sigil, hand: hand, on: Page())!
            XCTAssertLessThan(page.usedCells, previous, "\(hand.rawValue) didn't compress")
            previous = page.usedCells

            // Same statement, whichever hand wrote it.
            XCTAssertEqual(page.sigils, [sigil])
        }
    }

    func testEveryRefinedRuneIsASingleCell() {
        for source in ContentCatalog.shared.pressureSources {
            let shape = PageRules.shape(for: source.id, hand: .refined)
            XCTAssertEqual(shape?.footprint, 1, "\(source.id.rawValue) isn't 1×1 in a fine hand")
        }
    }

    func testCrudeIsAlwaysBulkierThanPlain() {
        for source in ContentCatalog.shared.pressureSources {
            let crude = PageRules.shape(for: source.id, hand: .crude)?.footprint ?? 0
            let plain = PageRules.shape(for: source.id, hand: .plain)?.footprint ?? 0
            XCTAssertGreaterThan(crude, plain, "\(source.id.rawValue) got no worse in charcoal")
        }
    }

    func testRedrawingInAFinerHandKeepsThePageValid() {
        let sigil = Sigil(id: InstanceID(rawValue: 1), source: "sun", target: "illumination")
        let crude = PageRules.placeAnywhere(sigil, hand: .crude, on: Page())!
        let refined = PageRules.redraw(sigil.id, in: .refined, on: crude)!

        XCTAssertEqual(refined.usedCells, 1)
        XCTAssertEqual(refined.sigils, crude.sigils, "redrawing changed what the page said")
        XCTAssertEqual(Set(refined.runes.flatMap(\.cells)).count, refined.usedCells)
    }

    /// A better hand must never cost you a layout you'd already made.
    func testRedrawingRelocatesRatherThanFailing() {
        let big = Sigil(id: InstanceID(rawValue: 1), source: "sun", target: "illumination")
        var page = PageRules.place(big, hand: .refined, at: PageCell(column: 5, row: 5), on: Page())!
        // Crude needs room the bottom-right corner doesn't have, so it has to move.
        page = PageRules.redraw(big.id, in: .crude, on: page)!
        XCTAssertEqual(page.sigils, [big])
        XCTAssertTrue(page.runes[0].cells.allSatisfy { page.contains($0) })
    }

    // MARK: Shapes are stable

    /// A rune the player has learned to fit must not change shape between launches — Swift's own
    /// hashing is salted per process, which would redraw every page on relaunch.
    func testARuneAlwaysDrawsTheSameShape() {
        for source in ContentCatalog.shared.pressureSources {
            let first = PageRules.shape(for: source.id, hand: .crude)?.id
            let again = PageRules.shape(for: source.id, hand: .crude)?.id
            XCTAssertEqual(first, again)
        }
        // Pinned values: if these change, existing pages relayout.
        XCTAssertNotNil(PageRules.shape(for: "sun", hand: .crude))
        XCTAssertEqual(PageRules.shape(for: "sun", hand: .crude)?.id,
                       PageRules.shape(for: "sun", hand: .crude)?.id)
    }

    func testShapesAreSpreadAcrossTheAvailableForms() {
        // If every rune picked the same shape, the packing puzzle would be trivial.
        let used = Set(ContentCatalog.shared.pressureSources.compactMap {
            PageRules.shape(for: $0.id, hand: .crude)?.id
        })
        XCTAssertGreaterThan(used.count, 1, "every rune drew as the same scrawl")
    }

    // MARK: Compounds

    func testACompoundCostsLessThanItsPartsButIsNeverFree() {
        XCTAssertEqual(PageRules.compoundFootprint(ofParts: []), 0)
        XCTAssertGreaterThan(PageRules.compoundFootprint(ofParts: [1]), 0)

        for parts in [[2, 2], [3, 3, 3], [4, 5, 6]] {
            let sum = parts.reduce(0, +)
            let compound = PageRules.compoundFootprint(ofParts: parts)
            XCTAssertLessThan(compound, sum, "\(parts) was no cheaper written as one mark")
            XCTAssertGreaterThan(compound, 0)
        }
    }

    func testEveryCatalogueCompoundIsWorthLearning() {
        for symbol in ContentCatalog.shared.symbols {
            let parts = symbol.expandsTo.compactMap { PageRules.shape(for: $0.source, hand: .plain)?.footprint }
            guard parts.count > 1 else { continue }
            XCTAssertLessThan(PageRules.footprint(of: symbol, hand: .plain), parts.reduce(0, +),
                              "\(symbol.id.rawValue) costs as much as spelling it out")
        }
    }

    func testProvenStatementNormalizationIgnoresLayoutHandAndSourceOrder() throws {
        var base = BaseState.newGame()
        let sources = Array(ContentCatalog.shared.pressureSources.prefix(2).map(\.id))
        XCTAssertEqual(sources.count, 2)
        base.ownedSources.formUnion(sources)
        let target: PressureTargetID = "illumination"
        func page(ids: [UInt64], reversed: Bool, hand: Hand) -> Page {
            let ordered = reversed ? Array(sources.reversed()) : sources
            let targetMark = PlacedRune(id: .init(rawValue: ids[0]), content: .target(target),
                                        hand: hand, origin: .init(column: 5, row: 5), shapeID: "refined_dot")
            let sourceMarks = ordered.enumerated().map { offset, source in
                PlacedRune(id: .init(rawValue: ids[offset + 1]), content: .source(source),
                           hand: hand, origin: .init(column: offset, row: 0), shapeID: "refined_dot")
            }
            return Page(runes: [targetMark] + sourceMarks,
                        links: Set(sourceMarks.map { MarkLink(targetMark.id, $0.id) }))
        }
        let first = try XCTUnwrap(PageRules.compoundStatementAssessments(
            on: page(ids: [1, 2, 3], reversed: false, hand: .crude), knownBy: base,
            boundRunIndex: 1).first?.receipt)
        let rearranged = try XCTUnwrap(PageRules.compoundStatementAssessments(
            on: page(ids: [91, 43, 12], reversed: true, hand: .refined), knownBy: base,
            boundRunIndex: 7).first?.receipt)
        XCTAssertEqual(first.fingerprint, rearranged.fingerprint)
        XCTAssertEqual(first.atoms, rearranged.atoms)
        XCTAssertEqual(first.vocabulary, rearranged.vocabulary)
        XCTAssertNotEqual(first.firstBoundRunIndex, rearranged.firstBoundRunIndex)
    }

    func testCompoundEligibilityRejectsUnknownNestedAndOverFiveAtomsExactly() throws {
        var base = BaseState.newGame()
        let source = try XCTUnwrap(ContentCatalog.shared.pressureSources.first).id
        base.ownedSources.remove(source)
        let target = PlacedRune(id: .init(rawValue: 1), content: .target("illumination"),
                                hand: .crude, origin: .init(column: 0, row: 0), shapeID: "refined_dot")
        let focus = PlacedRune(id: .init(rawValue: 2), content: .source(source),
                               hand: .crude, origin: .init(column: 1, row: 0), shapeID: "refined_dot")
        let unknown = Page(runes: [target, focus], links: [MarkLink(target.id, focus.id)])
        XCTAssertEqual(PageRules.compoundStatementAssessments(
            on: unknown, knownBy: base, boundRunIndex: 1).first?.issue, .unknownAtom)

        let nested = PlacedRune(id: .init(rawValue: 3), content: .compound("plains"),
                                hand: .crude, origin: .init(column: 2, row: 0), shapeID: "crude_block")
        XCTAssertEqual(PageRules.compoundStatementAssessments(
            on: Page(runes: [target, nested], links: [MarkLink(target.id, nested.id)]),
            knownBy: base, boundRunIndex: 1).first?.issue, .nestedCompound)

        base.ownedSources.insert(source)
        let qualifiers = (0..<4).map { offset in
            PlacedRune(id: .init(rawValue: UInt64(10 + offset)), content: .qualifier("great"),
                       hand: .crude, origin: .init(column: offset, row: 1), shapeID: "refined_dot")
        }
        let tooMany = Page(runes: [target, focus] + qualifiers,
                           links: Set([MarkLink(target.id, focus.id)]
                            + qualifiers.map { MarkLink(focus.id, $0.id) }))
        XCTAssertEqual(PageRules.compoundStatementAssessments(
            on: tooMany, knownBy: base, boundRunIndex: 1).first?.issue, .tooManyAtoms)
    }

    func testPersonalCompoundPlacementPreservesExactWorldEffectsAndShrinksFootprint() throws {
        let source = try XCTUnwrap(ContentCatalog.shared.pressureSources.first).id
        let atom = CompoundSemanticAtom(Sigil(id: .init(rawValue: 1), source: source,
                                               target: "illumination", intensity: .great,
                                               scale: 2, count: 1))
        let receipt = ProvenStatementReceipt(
            fingerprint: PageRules.statementFingerprint(target: "illumination", atoms: [atom]),
            target: "illumination", atoms: [atom],
            vocabulary: [.target("illumination"), .source(source), .qualifier("great")],
            vocabularySchemaVersion: 1, firstBoundRunIndex: 1)
        let record = PersonalCompoundRecord(
            id: .init(rawValue: 9), nickname: "Bright reach",
            provenFingerprint: receipt.fingerprint, target: receipt.target,
            expansion: receipt.atoms, vocabulary: receipt.vocabulary,
            vocabularySchemaVersion: 1, provenance: "Personal", creationOrdinal: 1)
        let personal = try XCTUnwrap(PageRules.place(record, hand: .plain,
                                                     at: .init(column: 0, row: 0), on: Page()))
        let expanded = Page(runes: [
            PlacedRune(id: .init(rawValue: 50), sigil: atom.sigil(id: .init(rawValue: 50)),
                       hand: .plain, origin: .init(column: 0, row: 0),
                       shapeID: try XCTUnwrap(PageRules.shape(for: source, hand: .plain)?.id))
        ])
        let personalBook = BookRules.resolveBook(page: personal)
        let expandedBook = BookRules.resolveBook(page: expanded)
        XCTAssertEqual(BookRules.readings(for: personalBook, seed: 77),
                       BookRules.readings(for: expandedBook, seed: 77))
        XCTAssertEqual(BookRules.dangerProfile(for: personalBook),
                       BookRules.dangerProfile(for: expandedBook))
        XCTAssertEqual(BookRules.stabilityScore(of: personalBook),
                       BookRules.stabilityScore(of: expandedBook))
        XCTAssertEqual(BookRules.greedDelta(for: personalBook.composition),
                       BookRules.greedDelta(for: expandedBook.composition))
        let atomicFootprint = record.vocabulary.compactMap { identity -> Int? in
            switch identity {
            case .target(let id): PageRules.shape(for: .target(id), hand: .plain)?.footprint
            case .source(let id): PageRules.shape(for: .source(id), hand: .plain)?.footprint
            case .qualifier(let id): PageRules.shape(for: .qualifier(id), hand: .plain)?.footprint
            case .compound: nil
            }
        }.reduce(0, +)
        XCTAssertEqual(PageRules.personalCompoundFootprint(record, hand: .plain),
                       max(1, Int((Double(atomicFootprint) * 0.6).rounded(.up))))
        XCTAssertLessThan(PageRules.personalCompoundFootprint(record, hand: .plain), atomicFootprint)
    }

    // MARK: Capacity

    func testPageSizeIsCapabilityNotAffordability() {
        // Growing the page is a permanent unlock; it must not change what a book *costs*.
        let small = Page(width: 4, height: 4)
        let large = Page(width: 8, height: 8)
        XCTAssertGreaterThan(large.capacity, small.capacity)

        let sigil = Sigil(id: InstanceID(rawValue: 1), source: "sun", target: "illumination")
        let onSmall = PageRules.placeAnywhere(sigil, hand: .plain, on: small)!
        let onLarge = PageRules.placeAnywhere(sigil, hand: .plain, on: large)!
        XCTAssertEqual(onSmall.usedCells, onLarge.usedCells, "the same rune cost more on a bigger page")
    }

    func testAPageRoundTripsThroughASave() throws {
        var page = Page()
        page = PageRules.placeAnywhere(
            Sigil(id: InstanceID(rawValue: 1), source: "sun", target: "illumination",
                  intensity: .great, negatedTargets: ["thermal"]), hand: .crude, on: page)!
        page = PageRules.placeAnywhere(
            Sigil(id: InstanceID(rawValue: 2), source: "ice", target: "thermal"), hand: .refined, on: page)!

        let data = try SaveCodec.makeEncoder().encode(page)
        let reloaded = try SaveCodec.makeDecoder().decode(Page.self, from: data)
        XCTAssertEqual(reloaded, page)
        XCTAssertEqual(reloaded.sigils, page.sigils)
    }

    // MARK: The desk writes on the page

    func testWritingDeskClearRequiresExactDestructiveConfirmation() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let source = try String(
            contentsOf: root.appending(path: "Sources/Screens/WritingDeskView.swift"),
            encoding: .utf8
        )

        XCTAssertTrue(source.contains("WritingDeskPageActionsPopover("))
        XCTAssertTrue(source.contains("Button(clearLabel, action: clear)"))
        XCTAssertTrue(source.contains("isConfirmingClear = true"))
        XCTAssertTrue(source.contains("\"Clear this page?\""))
        XCTAssertTrue(source.contains("Button(clearPageActionLabel, role: .destructive)"))
        XCTAssertTrue(source.contains("Button(\"Keep writing\", role: .cancel)"))
        XCTAssertTrue(source.contains("Every placed Sigil and connection on this page will be removed."))
        XCTAssertEqual(source.components(separatedBy: "store.clearPage()").count - 1, 1,
                       "Only the confirmed destructive action may clear the page.")
    }

    func testWritingDeskUsesApprovedPageDrawerAndPaneHierarchyWithoutChangingActions() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(
            contentsOf: root.appending(path: "Sources/Screens/WritingDeskView.swift"),
            encoding: .utf8)

        XCTAssertTrue(source.contains("private var writingPaneTabs"))
        XCTAssertTrue(source.contains("WritingDeskPaperBackground()"))
        XCTAssertTrue(source.contains("WritingDeskWoodBackground()"))
        XCTAssertTrue(source.contains("PageGridView(ghost: $ghost"))
        XCTAssertTrue(source.contains("PixelUITheme.surfaceInset"))
        XCTAssertTrue(source.contains("HStack(spacing: 4)"),
                      "Collected and Templates remain one internal two-choice shelf switch.")
        XCTAssertFalse(source.contains("Picker(\"\", selection: $pane)"),
                       "The approved three-pane rail belongs in the screen, not the navigation title.")
        XCTAssertTrue(source.contains("store.bindAndDepart"))
        XCTAssertTrue(source.contains("WritingDeskCausalPresentation.make(from: review)"))
        XCTAssertTrue(source.contains("causalSection(\"What the page says\")"))
        XCTAssertTrue(source.contains("causalSection(\"What remains open\")"))
        XCTAssertTrue(source.contains("causalSection(\"Risk\")"))
        XCTAssertTrue(source.contains("causalSection(\"Preparation\")"))
        XCTAssertTrue(source.contains("DisclosureGroup(\"Further reading\")"))
        XCTAssertFalse(source.contains("PreviewPanel(projection:"),
                       "The live review pane must not bypass the redacted causal model.")
        XCTAssertTrue(source.contains("store.savePageTemplate"))
        XCTAssertTrue(source.contains("store.clearPage()"))
        XCTAssertFalse(source.contains("private var writingContextTools"))
        XCTAssertFalse(source.contains(".popover(isPresented: $showsPageActions"))
        XCTAssertTrue(source.contains("try WritingDeskProductionPack.bundled()"))
        let grid = try String(
            contentsOf: root.appending(path: "Sources/Screens/PageGridView.swift"), encoding: .utf8)
        XCTAssertTrue(grid.contains("WritingDeskPackMarkArtwork"))
        XCTAssertTrue(grid.contains("WritingDeskPackLinkArtwork"))
    }

    func testWritingDeskVocabularyNamesAndCategoryContrastDoNotDependOnPackArt() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(
            contentsOf: root.appending(path: "Sources/Screens/WritingDeskView.swift"),
            encoding: .utf8)

        XCTAssertTrue(source.contains("WritingDeskNativeVocabularyLabel("))
        XCTAssertTrue(source.contains("title: item.name"),
                      "Canonical candidate identity must remain native text without pack art.")
        XCTAssertTrue(source.contains("Color.clear.frame(width: 38)"),
                      "Native names must stay outside the temporary glyph well.")
        XCTAssertTrue(source.contains("PixelUITheme.surface.opacity(0.94)"),
                      "The reserved text region needs a stable semantic backing.")
        XCTAssertFalse(source.contains("bin == entry ? PixelUITheme.screen"),
                       "The dark screen role is unreadable on the selected dark category.")
        XCTAssertGreaterThanOrEqual(
            PixelUITheme.contrastRatio(PixelUITheme.light.screen, PixelUITheme.light.edgeDark), 4.5)
        XCTAssertGreaterThanOrEqual(
            PixelUITheme.contrastRatio(PixelUITheme.dark.text, PixelUITheme.dark.edgeDark), 4.5)
    }

    @MainActor
    func testMissingVisualPackStillArmsAndPlacesCanonicalWriting() throws {
        let store = GameStore(io: .temporary(name: "writing-fallback-\(UUID().uuidString)"))
        let before = try SaveCodec.makeEncoder().encode(store.state.base.page)
        let candidate = WritingDeskFallbackSelection.arm(
            glyph: "illumination", content: .target("illumination"),
            origin: .init(column: 0, row: 0))

        XCTAssertEqual(candidate.glyph, "illumination")
        XCTAssertEqual(candidate.content, .target("illumination"))
        XCTAssertTrue(store.write(candidate.content, glyph: candidate.glyph, at: candidate.origin))
        XCTAssertEqual(store.state.base.page.runes.count, 1)
        XCTAssertEqual(store.state.base.page.runes[0].displayName, "Illumination")
        XCTAssertNotEqual(try SaveCodec.makeEncoder().encode(store.state.base.page), before)
        XCTAssertEqual(store.state.base.page.runes[0].cells,
                       PageRules.shape(for: candidate.content, hand: store.state.base.bestHand)?
                        .offsets.map { PageCell(column: candidate.origin.column + $0.column,
                                                row: candidate.origin.row + $0.row) })
    }

    func testWritingDeskCancellationClearsGhostAndPageSessionWithoutMutatingPage() {
        let original = Page()
        var ghost: GhostRune? = .init(glyph: "sun", content: .source("sun"),
                                      origin: .init(column: 1, row: 1))
        var token = 4
        var session = PageInteractionSession(mode: .connecting,
                                             anchor: .init(rawValue: 1),
                                             held: .init(rawValue: 2),
                                             connectionError: "still active")

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let encoded = try! encoder.encode(original)
        for trigger in WritingDeskInteractionCancellation.Trigger.allCases {
            ghost = .init(glyph: "sun", content: .source("sun"), origin: .init(column: 1, row: 1))
            session = .init(mode: .connecting, anchor: .init(rawValue: 1),
                            held: .init(rawValue: 2), connectionError: "still active")
            let before = token
            WritingDeskInteractionCancellation.cancel(trigger, ghost: &ghost, dismissalToken: &token)
            session.cancel()
            XCTAssertNil(ghost, "\(trigger)")
            XCTAssertEqual(token, before + 1, "\(trigger)")
            XCTAssertEqual(session, PageInteractionSession(), "\(trigger)")
            XCTAssertEqual(try! encoder.encode(original), encoded, "\(trigger)")
        }
    }

    func testPageGridLoadIdentityChangesWhenRoutePackBecomesAvailable() {
        let page = PageInteractionIdentity(width: 6, height: 6, runeIDs: [])
        XCTAssertNotEqual(PageGridLoadIdentity(page: page, packAvailable: false),
                          PageGridLoadIdentity(page: page, packAvailable: true))
    }

    func testEveryRequiredWriteCancellationTriggerUsesTheOneCancellationFunction() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(contentsOf: root.appending(path: "Sources/Screens/WritingDeskView.swift"),
                                encoding: .utf8)
        for call in ["cancelPageInteraction(.back)", "cancelPageInteraction(.pane)",
                     "cancelPageInteraction(.bin)", "cancelPageInteraction(.handOrInk)",
                     "cancelPageInteraction(.pageActions)", "cancelPageInteraction(.outsidePage)"] {
            XCTAssertTrue(source.contains(call), "missing typed cancellation call \(call)")
        }
    }

    func testWritingDeskPersonalCompoundPaletteUsesFrozenPlacementAuthorityAndAnchoredDetail() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(
            contentsOf: root.appending(path: "Sources/Screens/WritingDeskView.swift"),
            encoding: .utf8)

        XCTAssertTrue(source.contains("sectionLabel(\"My Runebook\")"))
        XCTAssertTrue(source.contains("PageRules.personalCompoundFootprint(record"))
        XCTAssertTrue(source.contains("CompoundRunebookPresentation.expansion(record)"))
        XCTAssertTrue(source.contains("Text(record.provenance)"))
        XCTAssertTrue(source.contains("PageRules.place(record, hand: state.base.bestHand"))
        XCTAssertTrue(source.contains("store.replaceWritingDeskDraft(updated)"))
        XCTAssertTrue(source.contains("Sigils saved at the time"))
        XCTAssertFalse(source.contains("formalizePersonalCompound"),
                       "The Writing Desk places saved notation; it must not mint or charge for it")
    }

    func testTemplateUIUsesThumbnailGridAnchoredActionsAndExactConfirmations() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let source = try String(
            contentsOf: root.appending(path: "Sources/Screens/WritingDeskView.swift"),
            encoding: .utf8)
        XCTAssertTrue(source.contains("case templates = \"Templates\""))
        XCTAssertTrue(source.contains("SavedPageTemplateCard("))
        XCTAssertTrue(source.contains(".popover(isPresented: $showsActions"))
        XCTAssertTrue(source.contains(".presentationCompactAdaptation(.popover)"))
        XCTAssertTrue(source.contains("\"Replace the current page?\""))
        XCTAssertTrue(source.contains("\"Overwrite this Template?\""))
        XCTAssertTrue(source.contains("\"Delete this Template?\""))
        XCTAssertTrue(source.contains("PageTemplateRules.capacity) Templates"),
                      "the bounded shelf must disclose current usage and its cap")
        XCTAssertTrue(source.contains("Button(\"Save Template\", action: save)")
                      || source.contains(".accessibilityLabel(\"Save Template\")"))
    }

    func testInkWellUIExposesAshMixerPreparationAndOneSharedRecipePreview() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(
            contentsOf: root.appending(path: "Sources/Screens/WritingDeskView.swift"),
            encoding: .utf8)
        XCTAssertTrue(source.contains("Ash ink · color open"))
        XCTAssertTrue(source.contains("InkChannelSlider(name: \"Cyan\""))
        XCTAssertTrue(source.contains("InkChannelSlider(name: \"Magenta\""))
        XCTAssertTrue(source.contains("InkChannelSlider(name: \"Yellow\""))
        XCTAssertTrue(source.contains("InkChannelSlider(name: \"Depth\""))
        XCTAssertTrue(source.contains("Button(\"Apply mixture\")"))
        XCTAssertTrue(source.contains("Button(\"Return to Ash\")"))
        XCTAssertTrue(source.contains("Button(\"Use for next focus\")"))
        XCTAssertTrue(source.contains("Button(\"Prepare 12 applications\")"))
        XCTAssertTrue(source.contains("store.inkVialPreparationQuote(recipe)"))
        XCTAssertTrue(source.contains("store.prepareInkVial(quote)"))
        XCTAssertTrue(source.contains("recipe?.resolvedSRGB"),
                      "the page swatch must use the same recipe conversion as binding")
    }

    @MainActor
    func testTemplateRoundTripRemapsEveryIdentityAndLinkWithoutChangingComposition() throws {
        let store = GameStore(io: .temporary(name: "template-remap-\(UUID().uuidString)"))
        let first = PlacedRune(id: InstanceID(rawValue: 11), content: .target("illumination"),
                               hand: .crude, origin: .init(column: 0, row: 0),
                               shapeID: "crude_block")
        let second = PlacedRune(id: InstanceID(rawValue: 22), content: .source("sun"),
                                hand: .crude, origin: .init(column: 2, row: 0),
                                shapeID: "crude_block")
        let legacy = PlacedRune(
            id: InstanceID(rawValue: 33),
            sigil: Sigil(id: InstanceID(rawValue: 44), source: "sun", target: "illumination"),
            hand: .crude, origin: .init(column: 0, row: 2), shapeID: "crude_block")
        let authored = Page(runes: [first, second, legacy], links: [MarkLink(first.id, second.id)])
        store.mutate("test: authored template") { $0.base.page = authored }

        guard case .saved(let templateID) = store.savePageTemplate(named: "  Morning path  ")
        else { return XCTFail("valid page was not saved") }
        let frozen = try XCTUnwrap(store.state.base.savedPageTemplates.first)
        XCTAssertEqual(frozen.id, templateID)
        XCTAssertEqual(frozen.name, "Morning path")
        XCTAssertEqual(frozen.page, authored)

        store.clearPage()
        XCTAssertEqual(store.loadPageTemplate(templateID), .loaded(templateID))
        let firstLoad = store.state.base.page
        XCTAssertEqual(Array(firstLoad.runes.prefix(2)).map(\.content),
                       Array(authored.runes.prefix(2)).map(\.content))
        XCTAssertEqual(firstLoad.runes.map(\.origin), authored.runes.map(\.origin))
        XCTAssertEqual(firstLoad.runes.map(\.shapeID), authored.runes.map(\.shapeID))
        XCTAssertEqual(firstLoad.links.count, 1)
        XCTAssertNotEqual(firstLoad.runes.map(\.id), authored.runes.map(\.id))
        guard case .rune(let firstLegacy) = firstLoad.runes[2].content,
              case .rune(let authoredLegacy) = authored.runes[2].content
        else { return XCTFail("legacy rune was not preserved") }
        XCTAssertNotEqual(firstLegacy.id, authoredLegacy.id)
        XCTAssertEqual(firstLegacy.source, authoredLegacy.source)
        XCTAssertEqual(firstLegacy.target, authoredLegacy.target)
        XCTAssertTrue(firstLoad.links.contains(MarkLink(firstLoad.runes[0].id, firstLoad.runes[1].id)))
        XCTAssertTrue(PageTemplateRules.structurallyEquivalent(authored, firstLoad))

        XCTAssertEqual(store.loadPageTemplate(templateID), .noChange,
                       "loading the composition already present is an identity-insensitive no-op")
        XCTAssertEqual(store.state.base.page.runes.map(\.id), firstLoad.runes.map(\.id))

        store.clearPage()
        XCTAssertEqual(store.loadPageTemplate(templateID), .loaded(templateID))
        XCTAssertNotEqual(store.state.base.page.runes.map(\.id), firstLoad.runes.map(\.id),
                          "each actual load must issue fresh identities")
        XCTAssertEqual(store.state.base.savedPageTemplates.first?.page, authored,
                       "loading must never mutate the frozen Template")
    }

    @MainActor
    func testTemplateActionsUseStableIDsAndRemainAtomicAtTheCap() throws {
        let store = GameStore(io: .temporary(name: "template-actions-\(UUID().uuidString)"))
        XCTAssertEqual(store.savePageTemplate(named: "Blank"), .emptyDraft)
        XCTAssertTrue(store.write("plains"))
        guard case .saved(let firstID) = store.savePageTemplate(named: "First")
        else { return XCTFail("first Template did not save") }
        let firstOrdinal = try XCTUnwrap(store.state.base.savedPageTemplates.first).creationOrdinal

        XCTAssertEqual(store.renamePageTemplate(firstID, to: "  Renamed  "), .updated(firstID))
        XCTAssertEqual(store.state.base.savedPageTemplates.first?.name, "Renamed")
        XCTAssertTrue(store.write("frostbound"))
        XCTAssertEqual(store.overwritePageTemplate(firstID), .updated(firstID))
        XCTAssertEqual(store.state.base.savedPageTemplates.first?.id, firstID)
        XCTAssertEqual(store.state.base.savedPageTemplates.first?.creationOrdinal, firstOrdinal)
        XCTAssertEqual(store.state.base.savedPageTemplates.first?.name, "Renamed")

        store.mutate("test: fill template cap") { state in
            let page = state.base.page
            while state.base.savedPageTemplates.count < PageTemplateRules.capacity {
                let raw = state.base.nextPageTemplateID
                state.base.nextPageTemplateID += 1
                state.base.savedPageTemplates.append(.init(
                    id: .init(rawValue: raw), name: "Template \(raw)", page: page,
                    creationOrdinal: raw))
            }
        }
        let before = store.state
        XCTAssertEqual(store.savePageTemplate(named: "One too many"),
                       .capacityReached(PageTemplateRules.capacity))
        XCTAssertEqual(store.state, before)
        XCTAssertEqual(store.deletePageTemplate(.init(rawValue: UInt64.max)), .staleTemplate)
        XCTAssertEqual(store.state, before)
        XCTAssertEqual(store.deletePageTemplate(firstID), .deleted(firstID))
        XCTAssertFalse(store.state.base.savedPageTemplates.contains { $0.id == firstID })

        let nextID = store.state.base.nextPageTemplateID
        guard case .saved(let replacementID) = store.savePageTemplate(named: "After deletion")
        else { return XCTFail("deleting at cap did not make room") }
        XCTAssertEqual(replacementID.rawValue, nextID)
        XCTAssertNotEqual(replacementID, firstID, "deleted stable IDs must never be reused")
    }

    @MainActor
    func testTemplateRefusesMalformedLinksWithoutMutatingTheSave() {
        let store = GameStore(io: .temporary(name: "template-invalid-link-\(UUID().uuidString)"))
        XCTAssertTrue(store.write("plains"))
        store.mutate("test: inject malformed link") { state in
            let placed = state.base.page.runes[0]
            state.base.page.links = [MarkLink(placed.id, .init(rawValue: UInt64.max))]
        }
        let before = store.state
        XCTAssertEqual(store.savePageTemplate(named: "Broken"), .invalidDraft)
        XCTAssertEqual(store.state, before, "a refused Template must be an atomic no-op")
    }

    @MainActor
    func testMixedInkAppliesOnlyToInkCapableFocusMarksWithoutDraftCost() throws {
        let store = GameStore(io: .temporary(name: "ink-application-\(UUID().uuidString)"))
        let recipe = InkRecipe(cyan: 100, magenta: 0, yellow: 100, depth: 0)
        let target = PlacedRune(id: .init(rawValue: 1), content: .target("illumination"),
                                hand: .plain, origin: .init(column: 0, row: 0),
                                shapeID: "plain_bar")
        let charcoal = PlacedRune(id: .init(rawValue: 2), content: .source("sun"),
                                  hand: .crude, origin: .init(column: 2, row: 0),
                                  shapeID: "crude_block")
        let brush = PlacedRune(id: .init(rawValue: 3), content: .source("sun"),
                               hand: .plain, origin: .init(column: 0, row: 2),
                               shapeID: "plain_bar")
        store.mutate("test: ink page") { state in
            state.base.ownedHands.insert(.plain)
            state.base.page = Page(runes: [target, charcoal, brush])
        }
        let beforeLocked = store.state
        XCTAssertEqual(store.applyInkRecipe(recipe, to: brush.id), .mixingLocked)
        XCTAssertEqual(store.state, beforeLocked)

        store.mutate("test: learn ink mixing") {
            $0.base.completedResearch.insert("pen_ink_mixing")
            $0.base.capabilities.insert("inkMixing")
        }
        let before = store.state
        XCTAssertEqual(store.applyInkRecipe(recipe, to: target.id), .ineligibleMark)
        XCTAssertEqual(store.applyInkRecipe(recipe, to: charcoal.id), .ineligibleMark)
        XCTAssertEqual(store.applyInkRecipe(recipe, to: brush.id), .applied(brush.id))
        XCTAssertEqual(store.state.base.page.runes.first { $0.id == brush.id }?.inkRecipe, recipe)
        XCTAssertEqual(store.state.base.essence, before.base.essence,
                       "draft re-inking spends no Essence")
        XCTAssertEqual(store.applyInkRecipe(recipe, to: brush.id), .noChange)
        XCTAssertEqual(store.returnMarkToAsh(brush.id), .returnedToAsh(brush.id))
        XCTAssertNil(store.state.base.page.runes.first { $0.id == brush.id }?.inkRecipe)
    }

    @MainActor
    func testSavedInkMixturesDeduplicateWithoutRewritingFrozenMarks() throws {
        let store = GameStore(io: .temporary(name: "ink-mixtures-\(UUID().uuidString)"))
        let recipe = InkRecipe(cyan: 40, magenta: 15, yellow: 70, depth: 5)
        store.mutate("test: learn ink mixing") {
            $0.base.completedResearch.insert("pen_ink_mixing")
            $0.base.capabilities.insert("inkMixing")
        }
        guard case .savedMixture(let id) = store.saveInkMixture(named: "  Moss  ", recipe: recipe)
        else { return XCTFail("mixture was not saved") }
        XCTAssertEqual(store.state.base.savedInkMixtures.first?.name, "Moss")
        XCTAssertEqual(store.saveInkMixture(named: "Duplicate", recipe: recipe), .savedMixture(id))
        XCTAssertEqual(store.state.base.savedInkMixtures.count, 1)

        let mark = PlacedRune(id: .init(rawValue: 9), content: .source("sun"), hand: .plain,
                              origin: .init(column: 0, row: 0), shapeID: "plain_bar",
                              inkRecipe: recipe)
        store.mutate("test: freeze mixed mark") { $0.base.page = Page(runes: [mark]) }
        XCTAssertEqual(store.deleteInkMixture(id), .deletedMixture(id))
        XCTAssertEqual(store.state.base.page.runes.first?.inkRecipe, recipe,
                       "deleting a saved formula cannot recolor an existing mark")
    }

    func testInkRecipeRejectsEmptyAndOutOfRangeDecodedRecipes() throws {
        let decoder = JSONDecoder()
        XCTAssertThrowsError(try decoder.decode(
            InkRecipe.self,
            from: Data(#"{"cyan":0,"magenta":0,"yellow":0,"depth":0,"conversionVersion":"cmy-depth-v1"}"#.utf8)))
        XCTAssertThrowsError(try decoder.decode(
            InkRecipe.self,
            from: Data(#"{"cyan":101,"magenta":0,"yellow":0,"depth":0,"conversionVersion":"cmy-depth-v1"}"#.utf8)))
        let legacyVersionless = try decoder.decode(
            InkRecipe.self,
            from: Data(#"{"cyan":25,"magenta":0,"yellow":0,"depth":0}"#.utf8))
        XCTAssertEqual(legacyVersionless.conversionVersion, InkRecipe.currentConversionVersion)
    }

    @MainActor
    func testPreparingInkProcessesOnlyShortfallRetainsExcessAndIsAtomic() throws {
        let store = GameStore(io: .temporary(name: "ink-vial-\(UUID().uuidString)"))
        let recipe = InkRecipe(cyan: 26, magenta: 0, yellow: 100, depth: 1)
        store.mutate("test: stock Scriptorium") { state in
            state.base.completedResearch.insert("pen_ink_mixing")
            state.base.capabilities.insert("inkMixing")
            state.base.pigmentStock.add(1, of: .cyan)
            state.base.resources.add(1, of: "copper")
            state.base.resources.add(1, of: "sulfur")
            state.base.resources.add(1, of: "obsidian")
            state.base.resources.add(1, of: "resin")
        }
        let quote = store.inkVialPreparationQuote(recipe)
        XCTAssertTrue(quote.isReady)
        XCTAssertEqual(quote.measureCost[.cyan], 2)
        XCTAssertEqual(quote.measureCost[.yellow], 4)
        XCTAssertEqual(quote.measureCost[.depth], 1)
        XCTAssertEqual(quote.resourcesToProcess, ["copper": 1, "sulfur": 1, "obsidian": 1])
        XCTAssertEqual(quote.retainedMeasures[.cyan], 3)
        XCTAssertEqual(quote.retainedMeasures[.depth], 3)

        guard case .prepared(_, let applications) = store.prepareInkVial(quote)
        else { return XCTFail("ready quote did not prepare") }
        XCTAssertEqual(applications, 12)
        XCTAssertEqual(store.state.base.preparedInkVials.first?.remainingApplications, 12)
        XCTAssertEqual(store.state.base.pigmentStock[.cyan], 3)
        XCTAssertEqual(store.state.base.pigmentStock[.yellow], 0)
        XCTAssertEqual(store.state.base.pigmentStock[.depth], 3)
        XCTAssertEqual(store.state.base.resources["resin"], 0)

        let after = store.state
        XCTAssertEqual(store.prepareInkVial(quote), .staleQuote)
        XCTAssertEqual(store.state, after, "stale preparation must consume nothing")
    }

    @MainActor
    func testInsufficientInkPreparationConsumesNothing() {
        let store = GameStore(io: .temporary(name: "ink-vial-missing-\(UUID().uuidString)"))
        let recipe = InkRecipe(cyan: 100, magenta: 100, yellow: 0, depth: 0)
        store.mutate("test: unlock only") {
            $0.base.completedResearch.insert("pen_ink_mixing")
            $0.base.capabilities.insert("inkMixing")
        }
        let quote = store.inkVialPreparationQuote(recipe)
        XCTAssertFalse(quote.isReady)
        let before = store.state
        guard case .insufficient = store.prepareInkVial(quote)
        else { return XCTFail("missing stock was not refused") }
        XCTAssertEqual(store.state, before)
    }

    @MainActor
    func testQueuedInkWaitsForAndIsConsumedByNextEligibleFocus() {
        let store = GameStore(io: .temporary(name: "next-focus-ink-\(UUID().uuidString)"))
        let recipe = InkRecipe(cyan: 72, magenta: 0, yellow: 76, depth: 10)
        store.mutate("test: unlock Brush ink") { state in
            state.base.ownedHands.insert(.plain)
            state.base.completedResearch.insert("pen_ink_mixing")
            state.base.capabilities.insert("inkMixing")
        }
        store.useInkForNextFocus(recipe)
        XCTAssertTrue(store.write(.target("illumination"), glyph: "illumination",
                                  at: .init(column: 0, row: 0)))
        XCTAssertEqual(store.state.base.nextFocusInkRecipe, recipe,
                       "targets must not consume a queued focus ink")
        XCTAssertTrue(store.write(.source("sun"), glyph: "sun", at: .init(column: 0, row: 2)))
        XCTAssertEqual(store.state.base.page.runes.last?.inkRecipe, recipe)
        XCTAssertNil(store.state.base.nextFocusInkRecipe)
    }

    @MainActor
    func testWritingOnThePageIsWhatComposesTheBook() {
        let store = GameStore(io: .temporary(name: "desk-\(UUID().uuidString)"))
        store.mutate("test: fund") { $0.base.essence = 500 }

        XCTAssertTrue(store.write("plains"))
        XCTAssertTrue(store.write("frostbound"))
        XCTAssertEqual(store.state.base.page.symbolIDs, ["plains", "frostbound"])

        store.bindAndDepart()
        let book = store.state.worlds.activeRun?.book
        XCTAssertEqual(book?.allSymbolIDs, ["plains", "frostbound"],
                       "the world was bound from something other than the page")
    }

    @MainActor
    func testThePageRefusesWhatWillNotFit() {
        let store = GameStore(io: .temporary(name: "desk-\(UUID().uuidString)"))
        store.mutate("test: a cramped page") { $0.base.page = Page(width: 2, height: 2) }

        var written = 0
        for symbol in ContentCatalog.shared.symbols where store.write(symbol.id) { written += 1 }
        XCTAssertGreaterThan(written, 0, "nothing fitted at all")
        XCTAssertLessThan(written, ContentCatalog.shared.symbols.count,
                          "a 2x2 page accepted the entire vocabulary")
        XCTAssertLessThanOrEqual(store.state.base.page.usedCells, 4)
    }

    @MainActor
    func testErasingAMarkTakesItOutOfTheBook() {
        let store = GameStore(io: .temporary(name: "desk-\(UUID().uuidString)"))
        store.write("plains")
        let mark = store.state.base.page.runes[0]
        store.erase(mark.id)
        XCTAssertTrue(store.state.base.page.symbolIDs.isEmpty)
        // A blank page is the *most* uncertain world there is — everything rolls — so what it says
        // has to sit inside the band rather than be the band.
        XCTAssertTrue(store.bookProjection.stabilityScore.contains(BookRules.stabilityScore(delta: 0)))
    }

    @MainActor
    func testABlankPageStillBinds() {
        // Everything you don't say, the world decides. Under-specification is a surprise, not an
        // error — and with no slots left, a blank page is the extreme case of it.
        let store = GameStore(io: .temporary(name: "desk-\(UUID().uuidString)"))
        store.mutate("test: fund") { $0.base.essence = 500 }
        XCTAssertTrue(store.canBindAndDepart)
        store.bindAndDepart()
        XCTAssertNotNil(store.state.worlds.activeRun)
    }

    @MainActor
    func testAHalfWrittenPageSurvivesAForceQuit() throws {
        let io = SaveFileIO.temporary(name: "page-kill-\(UUID().uuidString)")
        defer { io.deleteEverything() }
        do {
            let store = GameStore(io: io)
            store.write("plains")
            store.write("frostbound")
            store.flushNow()
        }
        let resumed = GameStore(io: io)
        XCTAssertEqual(resumed.state.base.page.symbolIDs, ["plains", "frostbound"])
        XCTAssertEqual(resumed.state.base.page.runes.map(\.origin),
                       resumed.state.base.page.runes.map(\.origin))
    }

    func testCanonicalSigilPlayerCopyIsSharedAndExact() {
        XCTAssertEqual(PlayerSigilCopy.count(0), "0 Sigils")
        XCTAssertEqual(PlayerSigilCopy.count(1), "1 Sigil")
        XCTAssertEqual(PlayerSigilCopy.count(2), "2 Sigils")
    }

    func testCanonicalTerminologyCensusForWorldPreviewWritingAndDictionary() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .deletingLastPathComponent()
        let paths = [
            "Sources/Screens/PreviewPanel.swift",
            "Sources/Screens/WritingDeskView.swift",
            "Sources/Screens/PageGridView.swift",
            "Sources/Screens/LibraryView.swift",
            "Sources/Screens/SettingsView.swift",
            "Sources/Screens/BaseView.swift",
            "Sources/Screens/WorldHistoryView.swift",
            "Sources/Rules/PageRules.swift",
            "Sources/Debug/HarnessActions.swift"
        ]
        let source = try paths.map {
            try String(contentsOf: root.appending(path: $0), encoding: .utf8)
        }.joined(separator: "\n")

        for required in ["World preview", "Danger Sigils", "Clear ", "Unknown Sigil",
                         "Sigil Dictionary", "Sigils saved at the time",
                         "Those Sigils cannot be joined.", "One Sigil speaking",
                         "which of your Sigils did what", "Move the Sigils"] {
            XCTAssertTrue(source.contains(required), required)
        }
        for retired in ["\"Projection\"", "Danger runes", "Unknown mark",
                        "current draft", "exact frozen expansion", "Rune Dictionary",
                        "choose Runes", "Those marks cannot be joined.",
                        "unknown-source", "placed mark must remain frozen"] {
            XCTAssertFalse(source.contains(retired), retired)
        }
    }
}
