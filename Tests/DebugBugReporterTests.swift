#if DEBUG
import XCTest
@testable import Bookbinder

final class DebugBugReporterTests: XCTestCase {
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
        let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(DebugBugReport.self,
                                         from: JSONSerialization.data(withJSONObject: object))
        XCTAssertNil(decoded.roadmapCheckpoint)
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
}
#endif
