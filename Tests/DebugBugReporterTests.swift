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

        let horizontal = DebugBugReporterPlacementPolicy.horizontalRange(
            width: 368, safeLeading: 0, safeTrailing: 0)
        XCTAssertEqual(horizontal.lowerBound, 28, accuracy: 0.01)
        XCTAssertEqual(horizontal.upperBound, 340, accuracy: 0.01)
        XCTAssertGreaterThan(horizontal.upperBound - horizontal.lowerBound, 300,
                             "The floating reporter must traverse the full ordinary-phone width")
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

    func testReportEncodesBundledRoadmapClaimWithoutInventingInstalledCheckpoint() throws {
        var report = DebugBugReport(id: UUID(), createdAt: Date(), whatHappened: "x", expected: "",
            includesScreenshot: false, screenshotWidth: nil, screenshotHeight: nil, screenshotScale: nil,
            appVersion: "1", build: "1", screen: "base", saveSchemaVersion: 1,
            mutationCount: 0, lastAction: "new",
            runIndex: nil, mapSeed: nil, playerX: nil, playerY: nil, stability: nil, outcomeID: nil)
        report.bundledRoadmapClaim = DebugRoadmap.current.bundledCheckpointClaim

        let encoded = try JSONEncoder().encode(report)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        XCTAssertEqual(object["bundledRoadmapClaim"] as? String,
                       DebugRoadmap.current.bundledCheckpointClaim)
        XCTAssertNil(object["roadmapCheckpoint"],
                     "new reports must not serialize a planning claim under installed provenance")
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
        object.removeValue(forKey: "bundledRoadmapClaim")
        object.removeValue(forKey: "roadmapCheckpoint")
        object.removeValue(forKey: "debugTuningSnapshot")
        object.removeValue(forKey: "encounterScalingEvidence")
        let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(DebugBugReport.self,
                                         from: JSONSerialization.data(withJSONObject: object))
        XCTAssertNil(decoded.bundledRoadmapClaim)
        XCTAssertNil(decoded.legacyRoadmapCheckpointClaim)
        XCTAssertNil(decoded.debugTuningSnapshot)
        XCTAssertNil(decoded.encounterScalingEvidence)
    }

    func testLegacyRoadmapCheckpointDecodesOnlyAsHistoricalClaim() throws {
        let report = DebugBugReport(id: UUID(), createdAt: Date(timeIntervalSince1970: 1),
            whatHappened: "older report", expected: "", includesScreenshot: false,
            screenshotWidth: nil, screenshotHeight: nil, screenshotScale: nil,
            appVersion: "1", build: "1", screen: "base", saveSchemaVersion: 1,
            mutationCount: 0, lastAction: "new", runIndex: nil, mapSeed: nil,
            playerX: nil, playerY: nil, stability: nil, outcomeID: nil)
        let encoder = JSONEncoder(); encoder.dateEncodingStrategy = .iso8601
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: encoder.encode(report)) as? [String: Any])
        object["roadmapCheckpoint"] = "historical bundled claim"
        object.removeValue(forKey: "bundledRoadmapClaim")
        let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(DebugBugReport.self,
                                         from: JSONSerialization.data(withJSONObject: object))
        XCTAssertEqual(decoded.legacyRoadmapCheckpointClaim, "historical bundled claim")
        XCTAssertNil(decoded.bundledRoadmapClaim,
                     "legacy naming must not be silently promoted to installed provenance")
    }

    @MainActor
    func testReportCopiesFrozenScalingReceiptAndCurrentEncounterStateWithoutMutation() throws {
        let store = GameStore(io: .temporary(name: "bug-scaling-\(UUID().uuidString)"))
        store.write("plains")
        store.bindAndDepart()
        store.mutate("stage scaling evidence") { state in
            state.base.binderCharacter.level = 4
            guard var run = state.worlds.activeRun else { return }
            run.tuning.encounterScalingProfile = .recommended
            run.tuning.encounterScalingProfileSchemaVersion = 2
            let enemy = WorldEnemy(id: InstanceID(rawValue: 4_401), creatureID: "paper_moth",
                                   position: run.playerPosition, isAwake: true)
            run.enemies = [enemy]
            state.worlds.activeRun = run
            WorldRules.beginEncounter(triggeredBy: enemy, runsAutomaticTurns: false, in: &state)
        }
        let before = store.state
        let evidence = try XCTUnwrap(DebugEncounterScalingEvidence.capture(from: store.state))

        XCTAssertEqual(store.state, before, "Capturing DEBUG evidence must be read-only")
        XCTAssertEqual(evidence.scalingPreview, store.activeEncounter?.scalingPreview)
        XCTAssertEqual(evidence.scalingPreview.triggerFoeID, InstanceID(rawValue: 4_401))
        XCTAssertEqual(evidence.scalingPreview.scalingProfile, "recommended")
        XCTAssertEqual(evidence.scalingPreview.scalingProfileSchemaVersion, 2)
        XCTAssertNotNil(evidence.scalingPreview.worldLevel)
        XCTAssertEqual(evidence.party.first { $0.actor == .binder }?.level, 4)
        XCTAssertEqual(evidence.party.first { $0.actor == .binder }?.powerContribution, 1)
        XCTAssertEqual(evidence.foes.first?.currentHP, store.activeEncounter?.foes.first?.currentHP)
        XCTAssertEqual(evidence.turnSlots, store.activeEncounter?.turnSlots)
        XCTAssertEqual(evidence.currentTurnSlot, store.activeEncounter?.currentTurnSlot)

        var report = fixtureReport()
        report.encounterScalingEvidence = evidence
        let decoded = try JSONDecoder().decode(DebugBugReport.self,
                                                from: JSONEncoder().encode(report))
        XCTAssertEqual(decoded.encounterScalingEvidence, evidence)
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

    func testSaveOnPhoneAndDoneNeverCallTransport() async throws {
        let root = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let outbox = DebugBugReportOutbox(root: root)
        let transport = RecordingBugTransport()
        let workflow = DebugBugReportWorkflow(outbox: outbox, transport: transport)
        let report = fixtureReport()

        _ = try workflow.saveOnThisPhone(report, screenshot: nil)
        workflow.done()

        XCTAssertEqual(outbox.reports().first?.report.transportState, .unsent)
        let transportCalls = await transport.callCount()
        XCTAssertEqual(transportCalls, 0)
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

private actor RecordingBugTransport: DebugBugReportTransport {
    private var calls = 0
    func send(report: DebugBugReport, screenshot: Data?) async throws -> DebugBugReportReceipt {
        calls += 1
        return DebugBugReportReceipt(schemaVersion: 1, remoteReference: "unexpected",
                                     receivedAt: Date())
    }
    func callCount() -> Int { calls }
}

private actor RequestRecorder {
    var request: URLRequest?
    func record(_ request: URLRequest) { self.request = request }
    func captured() -> URLRequest? { request }
}
#endif
