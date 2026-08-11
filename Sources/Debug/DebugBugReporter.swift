#if DEBUG
import Foundation

struct DebugBugReport: Codable, Equatable, Identifiable, Sendable {
    static let schemaVersion = 1
    enum TransportState: String, Codable, Sendable { case unsent, sending, submitted, needsAttention }

    var id: UUID
    var schemaVersion: Int = Self.schemaVersion
    var createdAt: Date
    var whatHappened: String
    var expected: String
    var includesScreenshot: Bool
    var screenshotWidth: Int?
    var screenshotHeight: Int?
    var screenshotScale: Double?
    var appVersion: String
    var build: String
    var screen: String
    var saveSchemaVersion: Int
    var mutationCount: Int
    var lastAction: String
    var runIndex: Int?
    var mapSeed: UInt64?
    var playerX: Int?
    var playerY: Int?
    var stability: Int?
    var outcomeID: UInt64?
    var transportState: TransportState = .unsent
    var remoteReference: String?
}

struct DebugBugReportReceipt: Codable, Equatable, Sendable {
    var schemaVersion: Int
    var remoteReference: String
    var receivedAt: Date
}

protocol DebugBugReportTransport: Sendable {
    func send(report: DebugBugReport, screenshot: Data?) async throws -> DebugBugReportReceipt
}

struct DebugBugReportOutbox: Sendable {
    enum SaveError: Error { case duplicateID }
    let root: URL

    static var live: Self {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return Self(root: documents.appending(path: "DebugBugReports", directoryHint: .isDirectory))
    }

    func save(_ report: DebugBugReport, screenshot: Data?) throws -> URL {
        let fm = FileManager.default
        try fm.createDirectory(at: root, withIntermediateDirectories: true)
        let destination = root.appending(path: report.id.uuidString, directoryHint: .isDirectory)
        guard !fm.fileExists(atPath: destination.path) else { throw SaveError.duplicateID }
        let staging = root.appending(path: ".\(report.id.uuidString).staging", directoryHint: .isDirectory)
        try? fm.removeItem(at: staging)
        do {
            try fm.createDirectory(at: staging, withIntermediateDirectories: true)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            try encoder.encode(report).write(to: staging.appending(path: "report.json"), options: .atomic)
            if report.includesScreenshot, let screenshot {
                try screenshot.write(to: staging.appending(path: "screenshot.png"), options: .atomic)
            }
            try JSONEncoder().encode(DebugBugReportExport(report: report, screenshot: screenshot))
                .write(to: staging.appending(path: "\(report.id.uuidString).bookbinderbug"), options: .atomic)
            try fm.moveItem(at: staging, to: destination)
            return destination
        } catch {
            try? fm.removeItem(at: staging)
            throw error
        }
    }

    func reports() -> [(report: DebugBugReport, directory: URL)] {
        let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
        let directories = (try? FileManager.default.contentsOfDirectory(
            at: root, includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles])) ?? []
        return directories.compactMap { directory in
            guard let data = try? Data(contentsOf: directory.appending(path: "report.json")),
                  let report = try? decoder.decode(DebugBugReport.self, from: data) else { return nil }
            return (report, directory)
        }.sorted { $0.report.createdAt > $1.report.createdAt }
    }

    func exportURL(for report: DebugBugReport, in directory: URL) -> URL {
        exportURL(for: report.id, in: directory)
    }

    func exportURL(for id: UUID, in directory: URL) -> URL {
        directory.appending(path: "\(id.uuidString).bookbinderbug")
    }
}

private struct DebugBugReportExport: Codable {
    var report: DebugBugReport
    var screenshot: Data?
}
#endif
