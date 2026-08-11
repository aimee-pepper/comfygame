#if DEBUG
import XCTest
@testable import Bookbinder

final class DebugBugReporterTests: XCTestCase {
    func testBaseReporterPlacementAvoidsPurseTabsAndDepartureBands() {
        let base = DebugBugReporterPlacementPolicy.verticalRange(
            height: 800, safeTop: 59, safeBottom: 34, isBase: true)
        let ordinary = DebugBugReporterPlacementPolicy.verticalRange(
            height: 800, safeTop: 59, safeBottom: 34, isBase: false)
        let station = DebugBugReporterPlacementPolicy.verticalRange(
            height: 800, safeTop: 59, safeBottom: 34, isBase: false,
            reservesTopChrome: true)

        XCTAssertEqual(base.lowerBound, 520, accuracy: 0.01)
        XCTAssertEqual(base.upperBound, 624, accuracy: 0.01)
        XCTAssertEqual(ordinary.lowerBound, 87, accuracy: 0.01)
        XCTAssertEqual(ordinary.upperBound, 738, accuracy: 0.01)
        XCTAssertEqual(station.lowerBound, 384, accuracy: 0.01)
        XCTAssertEqual(station.upperBound, 624, accuracy: 0.01)
    }

    func testOutboxAtomicallyPersistsUnicodeReportAndScreenshot() throws {
        let root = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let id = UUID()
        let report = DebugBugReport(id: id, createdAt: Date(timeIntervalSince1970: 1),
            whatHappened: "Mercury shimmered — then vanished 🌙", expected: "It should remain.",
            includesScreenshot: true, screenshotWidth: 1179, screenshotHeight: 2556,
            screenshotScale: 3, appVersion: "1", build: "2", screen: "world",
            saveSchemaVersion: 3, mutationCount: 4, lastAction: "move", runIndex: 5,
            mapSeed: 6, playerX: 7, playerY: 8, stability: 9, outcomeID: nil)
        let destination = try DebugBugReportOutbox(root: root).save(report, screenshot: Data([1,2,3]))
        let data = try Data(contentsOf: destination.appending(path: "report.json"))
        let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
        XCTAssertEqual(try decoder.decode(DebugBugReport.self, from: data), report)
        XCTAssertEqual(try Data(contentsOf: destination.appending(path: "screenshot.png")), Data([1,2,3]))
        let export = DebugBugReportOutbox(root: root).exportURL(for: report, in: destination)
        XCTAssertTrue(FileManager.default.fileExists(atPath: export.path))
        let exportObject = try XCTUnwrap(
            JSONSerialization.jsonObject(with: Data(contentsOf: export)) as? [String: Any]
        )
        XCTAssertNotNil(exportObject["report"] as? [String: Any])
        XCTAssertEqual(exportObject["screenshot"] as? String, Data([1,2,3]).base64EncodedString())
        XCTAssertEqual(DebugBugReportOutbox(root: root).reports().map(\.report), [report])
    }

    func testSameReportIDCannotCreateTwoQueueEntries() throws {
        let root = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let report = DebugBugReport(id: UUID(), createdAt: Date(), whatHappened: "x", expected: "",
            includesScreenshot: false, screenshotWidth: nil, screenshotHeight: nil, screenshotScale: nil,
            appVersion: "1", build: "1", screen: "base", saveSchemaVersion: 1,
            mutationCount: 0, lastAction: "new", runIndex: nil, mapSeed: nil,
            playerX: nil, playerY: nil, stability: nil, outcomeID: nil)
        let outbox = DebugBugReportOutbox(root: root)
        _ = try outbox.save(report, screenshot: nil)
        XCTAssertThrowsError(try outbox.save(report, screenshot: nil))
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: nil).filter { !$0.lastPathComponent.hasPrefix(".") }.count, 1)
    }

    func testReportCapturesTheActivelyBundledRoadmapCheckpoint() {
        var report = DebugBugReport(id: UUID(), createdAt: Date(), whatHappened: "x", expected: "",
            includesScreenshot: false, screenshotWidth: nil, screenshotHeight: nil, screenshotScale: nil,
            appVersion: "1", build: "1", screen: "base", saveSchemaVersion: 1,
            mutationCount: 0, lastAction: "new",
            runIndex: nil, mapSeed: nil, playerX: nil, playerY: nil, stability: nil, outcomeID: nil)
        report.roadmapCheckpoint = DebugRoadmap.current.installedCheckpoint
        XCTAssertEqual(report.roadmapCheckpoint, DebugRoadmap.current.installedCheckpoint)
    }

    func testOlderSavedReportWithoutRoadmapCheckpointStillDecodes() throws {
        let report = DebugBugReport(id: UUID(), createdAt: Date(timeIntervalSince1970: 1),
            whatHappened: "older report", expected: "", includesScreenshot: false,
            screenshotWidth: nil, screenshotHeight: nil, screenshotScale: nil,
            appVersion: "1", build: "1", screen: "base", saveSchemaVersion: 1,
            mutationCount: 0, lastAction: "new", runIndex: nil, mapSeed: nil,
            playerX: nil, playerY: nil, stability: nil, outcomeID: nil)
        let encoder = JSONEncoder(); encoder.dateEncodingStrategy = .iso8601
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: encoder.encode(report)) as? [String: Any])
        object.removeValue(forKey: "roadmapCheckpoint")
        object.removeValue(forKey: "debugTuningSnapshot")
        let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(DebugBugReport.self,
                                         from: JSONSerialization.data(withJSONObject: object))
        XCTAssertNil(decoded.roadmapCheckpoint)
        XCTAssertNil(decoded.debugTuningSnapshot)
    }

    func testReportPreservesReproducibleDebugTuningSnapshot() throws {
        var report = fixtureReport()
        report.debugTuningSnapshot = "{\"encounterScalingProfile\":\"recommended\",\"rawEssenceProfile\":\"recommended\"}"
        let encoder = JSONEncoder(); encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601

        let decoded = try decoder.decode(DebugBugReport.self, from: encoder.encode(report))

        XCTAssertEqual(decoded.debugTuningSnapshot, report.debugTuningSnapshot)
    }

    func testReportPreservesBoundedSemanticActionTrail() throws {
        var report = fixtureReport()
        report.semanticActionTrail = ["move north", "look east", "collect quartz"]
        let encoder = JSONEncoder(); encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601

        let decoded = try decoder.decode(DebugBugReport.self, from: encoder.encode(report))

        XCTAssertEqual(decoded.semanticActionTrail, report.semanticActionTrail)
    }

    func testDistinctReportsUseIndependentAtomicStagingDirectories() async throws {
        let root = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let outbox = DebugBugReportOutbox(root: root)
        try await withThrowingTaskGroup(of: Void.self) { group in
            for index in 0..<8 {
                group.addTask {
                    let report = DebugBugReport(id: UUID(), createdAt: Date(),
                        whatHappened: "report \(index)", expected: "", includesScreenshot: true,
                        screenshotWidth: 1, screenshotHeight: 1, screenshotScale: 1,
                        appVersion: "1", build: "1", screen: "world", saveSchemaVersion: 1,
                        mutationCount: index, lastAction: "test", runIndex: nil, mapSeed: nil,
                        playerX: nil, playerY: nil, stability: nil, outcomeID: nil)
                    _ = try outbox.save(report, screenshot: Data([UInt8(index)]))
                }
            }
            try await group.waitForAll()
        }
        XCTAssertEqual(outbox.reports().count, 8)
    }

    func testInterruptedSendRecoversToNeedsAttention() throws {
        let root = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let outbox = DebugBugReportOutbox(root: root)
        var report = fixtureReport()
        report.transportState = .sending
        _ = try outbox.save(report, screenshot: nil)

        XCTAssertEqual(outbox.recoverInterruptedSends(), 1)
        XCTAssertEqual(outbox.reports().first?.report.transportState, .needsAttention)
        XCTAssertEqual(outbox.recoverInterruptedSends(), 0)
    }

    func testSubmissionRequiresReceiptBeforeMarkingSubmitted() async throws {
        let root = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let outbox = DebugBugReportOutbox(root: root)
        let report = fixtureReport()
        _ = try outbox.save(report, screenshot: Data([7, 8]))
        let coordinator = DebugBugReportSubmissionCoordinator(
            outbox: outbox,
            transport: StubBugTransport(result: .success(DebugBugReportReceipt(
                schemaVersion: 1, remoteReference: "triage-42", receivedAt: Date()))))

        let receipt = try await coordinator.submit(report.id)
        XCTAssertEqual(receipt.remoteReference, "triage-42")
        XCTAssertEqual(outbox.reports().first?.report.transportState, .submitted)
        XCTAssertEqual(outbox.reports().first?.report.remoteReference, "triage-42")
    }

    func testSubmissionFailureRemainsDurableAndRetryable() async throws {
        let root = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let outbox = DebugBugReportOutbox(root: root)
        let report = fixtureReport()
        _ = try outbox.save(report, screenshot: nil)
        let coordinator = DebugBugReportSubmissionCoordinator(
            outbox: outbox, transport: StubBugTransport(result: .failure(StubFailure.offline)))

        do { _ = try await coordinator.submit(report.id); XCTFail("Expected transport failure") }
        catch { XCTAssertEqual(error as? StubFailure, .offline) }
        XCTAssertEqual(outbox.reports().first?.report.transportState, .needsAttention)
        XCTAssertNil(outbox.reports().first?.report.remoteReference)
    }

    func testUnsupportedReceiptCannotMarkReportSubmitted() async throws {
        let root = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let outbox = DebugBugReportOutbox(root: root)
        let report = fixtureReport()
        _ = try outbox.save(report, screenshot: nil)
        let coordinator = DebugBugReportSubmissionCoordinator(
            outbox: outbox,
            transport: StubBugTransport(result: .success(DebugBugReportReceipt(
                schemaVersion: 99, remoteReference: "untrusted", receivedAt: Date()))))

        do { _ = try await coordinator.submit(report.id); XCTFail("Expected invalid receipt") }
        catch { }
        XCTAssertEqual(outbox.reports().first?.report.transportState, .needsAttention)
        XCTAssertNil(outbox.reports().first?.report.remoteReference)
    }

    func testExportRegeneratesFromCanonicalReportAfterStateChange() throws {
        let root = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let outbox = DebugBugReportOutbox(root: root)
        var report = fixtureReport()
        report.includesScreenshot = true
        report.screenshotWidth = 1
        report.screenshotHeight = 1
        report.screenshotScale = 1
        let directory = try outbox.save(report, screenshot: Data([3]))
        report.transportState = .needsAttention
        try outbox.update(report, in: directory)

        let export = outbox.exportURL(for: report, in: directory)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(
            with: Data(contentsOf: export)) as? [String: Any])
        let encodedReport = try XCTUnwrap(object["report"] as? [String: Any])
        XCTAssertEqual(encodedReport["transportState"] as? String, "needsAttention")
        XCTAssertEqual(object["screenshot"] as? String, Data([3]).base64EncodedString())
    }

    func testHTTPTransportUsesMultipartIdempotencyAndRequiresTwoXX() async throws {
        let report = fixtureReport()
        let recorder = RequestRecorder()
        let receipt = DebugBugReportReceipt(schemaVersion: 1, remoteReference: "queue-9",
                                            receivedAt: Date(timeIntervalSince1970: 1))
        let encoder = JSONEncoder(); encoder.dateEncodingStrategy = .iso8601
        let responseData = try encoder.encode(receipt)
        let endpoint = try XCTUnwrap(URL(string: "https://bugs.example.test/v1/reports"))
        let transport = DebugBugReportHTTPTransport(
            endpoint: endpoint, credential: "installation-secret") { request in
                await recorder.record(request)
                return (responseData, HTTPURLResponse(
                    url: endpoint, statusCode: 201, httpVersion: nil, headerFields: nil)!)
            }

        let returned = try await transport.send(report: report, screenshot: Data([0x89, 0x50]))
        XCTAssertEqual(returned, receipt)
        let recorded = await recorder.captured()
        let request = try XCTUnwrap(recorded)
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Idempotency-Key"),
                       report.id.uuidString.lowercased())
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"),
                       "Bearer installation-secret")
        let body = try XCTUnwrap(request.httpBody)
        let text = String(decoding: body, as: UTF8.self)
        XCTAssertTrue(text.contains("name=\"report\""))
        XCTAssertTrue(text.contains("name=\"screenshot\""))
        XCTAssertNotNil(body.range(of: Data([0x89, 0x50])))
    }

    func testHTTPTransportRejectsNonTwoXXWithoutReceipt() async throws {
        let endpoint = try XCTUnwrap(URL(string: "https://bugs.example.test/v1/reports"))
        let transport = DebugBugReportHTTPTransport(endpoint: endpoint, credential: "secret") { _ in
            (Data(), HTTPURLResponse(url: endpoint, statusCode: 503,
                                     httpVersion: nil, headerFields: nil)!)
        }
        do { _ = try await transport.send(report: fixtureReport(), screenshot: nil); XCTFail("Expected rejection") }
        catch { XCTAssertEqual(error as? DebugBugReportHTTPTransport.TransportError,
                               .rejected(statusCode: 503)) }
    }

    private func fixtureReport() -> DebugBugReport {
        DebugBugReport(
            id: UUID(), createdAt: Date(), whatHappened: "Unicode 🐞 café", expected: "Worked",
            includesScreenshot: false, screenshotWidth: nil, screenshotHeight: nil,
            screenshotScale: nil, appVersion: "1", build: "1", screen: "base",
            saveSchemaVersion: 1, mutationCount: 2, lastAction: "look")
    }
}

private enum StubFailure: Error { case offline }

private enum StubTransportResult: Sendable {
    case success(DebugBugReportReceipt)
    case failure(StubFailure)
}

private struct StubBugTransport: DebugBugReportTransport {
    let result: StubTransportResult
    func send(report: DebugBugReport, screenshot: Data?) async throws -> DebugBugReportReceipt {
        switch result {
        case .success(let receipt): receipt
        case .failure(let error): throw error
        }
    }
}

private actor RequestRecorder {
    var request: URLRequest?
    func record(_ request: URLRequest) { self.request = request }
    func captured() -> URLRequest? { request }
}
#endif
