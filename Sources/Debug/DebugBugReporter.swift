#if DEBUG
import Foundation
import Security

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
    var roadmapCheckpoint: String? = nil
    var screen: String
    var route: String? = nil
    var campaignReference: String? = nil
    var encounterID: UInt64? = nil
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
    static let supportedSchemaVersion = 1
    var schemaVersion: Int
    var remoteReference: String
    var receivedAt: Date
}

protocol DebugBugReportTransport: Sendable {
    func send(report: DebugBugReport, screenshot: Data?) async throws -> DebugBugReportReceipt
}

struct DebugBugReportHTTPTransport: DebugBugReportTransport {
    enum TransportError: Error, Equatable {
        case invalidResponse
        case rejected(statusCode: Int)
        case invalidReceipt
    }

    typealias Performer = @Sendable (URLRequest) async throws -> (Data, HTTPURLResponse)
    let endpoint: URL
    let credential: String
    let perform: Performer

    init(endpoint: URL, credential: String,
         perform: @escaping Performer = { request in
             let (data, response) = try await URLSession.shared.data(for: request)
             guard let http = response as? HTTPURLResponse else { throw TransportError.invalidResponse }
             return (data, http)
         }) {
        self.endpoint = endpoint
        self.credential = credential
        self.perform = perform
    }

    func send(report: DebugBugReport, screenshot: Data?) async throws -> DebugBugReportReceipt {
        let boundary = "bookbinder-\(report.id.uuidString.lowercased())"
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(credential)", forHTTPHeaderField: "Authorization")
        request.setValue(report.id.uuidString.lowercased(), forHTTPHeaderField: "Idempotency-Key")
        request.httpBody = try Self.multipart(report: report, screenshot: screenshot, boundary: boundary)
        let (data, response) = try await perform(request)
        guard (200..<300).contains(response.statusCode) else {
            throw TransportError.rejected(statusCode: response.statusCode)
        }
        let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
        guard let receipt = try? decoder.decode(DebugBugReportReceipt.self, from: data) else {
            throw TransportError.invalidReceipt
        }
        return receipt
    }

    static func multipart(report: DebugBugReport, screenshot: Data?, boundary: String) throws -> Data {
        let encoder = JSONEncoder(); encoder.dateEncodingStrategy = .iso8601
        let reportData = try encoder.encode(report)
        var body = Data()
        func append(_ string: String) { body.append(Data(string.utf8)) }
        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"report\"; filename=\"report.json\"\r\n")
        append("Content-Type: application/json; charset=utf-8\r\n\r\n")
        body.append(reportData); append("\r\n")
        if let screenshot {
            append("--\(boundary)\r\n")
            append("Content-Disposition: form-data; name=\"screenshot\"; filename=\"screenshot.png\"\r\n")
            append("Content-Type: image/png\r\n\r\n")
            body.append(screenshot); append("\r\n")
        }
        append("--\(boundary)--\r\n")
        return body
    }
}

struct DebugBugReportRelayConfiguration: Sendable {
    static let endpointInfoKey = "DebugBugReportRelayURL"
    static let credentialEnvironmentKey = "BOOKBINDER_BUG_RELAY_CREDENTIAL"
    var endpoint: URL
    var credential: String

    static func live(bundle: Bundle = .main,
                     environment: [String: String] = ProcessInfo.processInfo.environment) -> Self? {
        if let injected = environment[credentialEnvironmentKey], !injected.isEmpty {
            try? DebugBugReportCredentialStore.save(injected)
        }
        guard let rawURL = bundle.object(forInfoDictionaryKey: endpointInfoKey) as? String,
              let endpoint = URL(string: rawURL), endpoint.scheme == "https",
              let credential = DebugBugReportCredentialStore.load(), !credential.isEmpty else {
            return nil
        }
        return Self(endpoint: endpoint, credential: credential)
    }
}

enum DebugBugReportCredentialStore {
    private static let service = "com.aimeepepper.bookbinder.debug-bug-relay"
    private static let account = "installation"

    static func save(_ credential: String) throws {
        let value = Data(credential.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let attributes: [String: Any] = [kSecValueData as String: value]
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            var addition = query
            addition[kSecValueData as String] = value
            let added = SecItemAdd(addition as CFDictionary, nil)
            guard added == errSecSuccess else { throw CredentialError.status(added) }
        } else if status != errSecSuccess {
            throw CredentialError.status(status)
        }
    }

    static func load() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    enum CredentialError: Error { case status(OSStatus) }
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
        let destination = directory.appending(path: "\(id.uuidString).bookbinderbug")
        // Export is derived from the canonical atomic report + optional screenshot. Removing any
        // prior package first means an interrupted state update can leave either a current export
        // or no export, never a stale package that contradicts the visible queue entry.
        try? FileManager.default.removeItem(at: destination)
        let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
        if let data = try? Data(contentsOf: directory.appending(path: "report.json")),
           let report = try? decoder.decode(DebugBugReport.self, from: data) {
            try? JSONEncoder().encode(DebugBugReportExport(
                report: report, screenshot: screenshot(in: directory)))
                .write(to: destination, options: .atomic)
        }
        return destination
    }

    func screenshot(in directory: URL) -> Data? {
        try? Data(contentsOf: directory.appending(path: "screenshot.png"))
    }

    func update(_ report: DebugBugReport, in directory: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        try? FileManager.default.removeItem(at: exportURLPath(for: report.id, in: directory))
        try encoder.encode(report).write(to: directory.appending(path: "report.json"), options: .atomic)
    }

    /// A process can die after persisting `sending` but before receiving a receipt. Never imply
    /// success on relaunch: make those entries explicitly retryable.
    @discardableResult
    func recoverInterruptedSends() -> Int {
        var recovered = 0
        for entry in reports() where entry.report.transportState == .sending {
            var report = entry.report
            report.transportState = .needsAttention
            if (try? update(report, in: entry.directory)) != nil { recovered += 1 }
        }
        return recovered
    }

    func remove(_ id: UUID) throws {
        guard let entry = reports().first(where: { $0.report.id == id }) else { return }
        try FileManager.default.removeItem(at: entry.directory)
    }

    private func exportURLPath(for id: UUID, in directory: URL) -> URL {
        directory.appending(path: "\(id.uuidString).bookbinderbug")
    }
}

actor DebugBugReportSubmissionCoordinator {
    enum SubmissionError: Error { case missingReport(UUID), invalidReceipt }
    let outbox: DebugBugReportOutbox
    let transport: any DebugBugReportTransport

    init(outbox: DebugBugReportOutbox, transport: any DebugBugReportTransport) {
        self.outbox = outbox
        self.transport = transport
    }

    func submit(_ id: UUID) async throws -> DebugBugReportReceipt {
        guard let entry = outbox.reports().first(where: { $0.report.id == id }) else {
            throw SubmissionError.missingReport(id)
        }
        var report = entry.report
        report.transportState = .sending
        report.remoteReference = nil
        try outbox.update(report, in: entry.directory)
        do {
            let receipt = try await transport.send(
                report: report, screenshot: outbox.screenshot(in: entry.directory))
            guard receipt.schemaVersion == DebugBugReportReceipt.supportedSchemaVersion,
                  !receipt.remoteReference.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw SubmissionError.invalidReceipt
            }
            report.transportState = .submitted
            report.remoteReference = receipt.remoteReference
            try outbox.update(report, in: entry.directory)
            return receipt
        } catch {
            report.transportState = .needsAttention
            try? outbox.update(report, in: entry.directory)
            throw error
        }
    }

}

private struct DebugBugReportExport: Codable {
    var report: DebugBugReport
    var screenshot: Data?
}
#endif
