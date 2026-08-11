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
}
#endif
