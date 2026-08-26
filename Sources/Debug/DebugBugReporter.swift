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
    /// The planning claim bundled with this build. This is not observed installed-commit provenance.
    var bundledRoadmapClaim: String? = nil
    /// Decode-only compatibility for reports written before the authority label was corrected.
    /// New reports never populate or encode this key.
    var legacyRoadmapCheckpointClaim: String? = nil
    var screen: String
    var route: String? = nil
    var campaignReference: String? = nil
    var encounterID: UInt64? = nil
    var debugTuningSnapshot: String? = nil
    var saveSchemaVersion: Int
    var mutationCount: Int
    var lastAction: String
    var semanticActionTrail: [String]? = nil
    var runIndex: Int?
    var mapSeed: UInt64?
    var playerX: Int?
    var playerY: Int?
    var stability: Int?
    var outcomeID: UInt64?
    /// Exact saved encounter evidence. Absent outside combat and in reports written before v1.
    var encounterScalingEvidence: DebugEncounterScalingEvidence? = nil
    /// False means DEBUG survival changed defeat handling. The report remains fully usable for
    /// crashes, UI, content, world and economy defects; only combat-balance conclusions are barred.
    var validCombatBalanceEvidence: Bool? = nil
    var transportState: TransportState = .unsent
    var remoteReference: String?

    private enum CodingKeys: String, CodingKey {
        case id, schemaVersion, createdAt, whatHappened, expected, includesScreenshot
        case screenshotWidth, screenshotHeight, screenshotScale, appVersion, build
        case bundledRoadmapClaim
        case legacyRoadmapCheckpointClaim = "roadmapCheckpoint"
        case screen, route, campaignReference, encounterID, debugTuningSnapshot
        case saveSchemaVersion, mutationCount, lastAction, semanticActionTrail
        case runIndex, mapSeed, playerX, playerY, stability, outcomeID
        case encounterScalingEvidence, validCombatBalanceEvidence, transportState, remoteReference
    }
}

struct DebugEncounterScalingEvidence: Codable, Equatable, Sendable {
    static let schemaVersion = 1

    struct PartyMember: Codable, Equatable, Sendable {
        var actor: Combatant
        var stableIdentity: String
        var displayName: String
        var level: Int
        var rank: Rank
        var currentHP: Int
        var rawLevelRatio: Double?
        var powerContribution: Double?
    }

    struct FoeHealth: Codable, Equatable, Sendable {
        var id: InstanceID
        var currentHP: Int
    }

    var schemaVersion = Self.schemaVersion
    var scalingPreview: EncounterScalingRules.Preview
    var party: [PartyMember]
    var foes: [FoeHealth]
    var opening: EncounterState.OpeningResolution?
    var roundNumber: Int
    var turnIndex: Int
    var currentTurnSlot: EncounterState.TurnSlot
    var turnSlots: [EncounterState.TurnSlot]
    var godModeReceipt: EncounterState.DebugGodModeReceipt?

    static func capture(from state: GameState) -> Self? {
        guard let run = state.worlds.activeRun,
              let encounter = run.activeEncounter,
              let preview = encounter.scalingPreview else { return nil }

        let contributions = Dictionary(uniqueKeysWithValues:
            (preview.partyPowerLedger?.contributions ?? []).map { ($0.identity, $0) })
        var seen: Set<Combatant> = []
        let partyActors = encounter.order.filter { $0.isParty && seen.insert($0).inserted }
        let party = partyActors.compactMap { actor -> PartyMember? in
            let identity: String
            let name: String
            let level: Int
            let currentHP: Int
            switch actor {
            case .binder:
                identity = "binder"
                name = "Binder"
                level = state.base.binderCharacter.level
                currentHP = run.binderHP
            case .companion(let id):
                guard let index = state.base.rosterIndex(for: id) else { return nil }
                let companion = state.base.roster[index]
                identity = stableIdentity(for: companion)
                name = encounter.partyNames[id] ?? companion.name
                level = companion.character.level
                currentHP = CombatRules.health(of: actor, in: run).current
            case .foe:
                return nil
            }
            let contribution = contributions[identity]
            return PartyMember(actor: actor, stableIdentity: identity, displayName: name,
                               level: level, rank: CombatRules.rank(of: actor, in: state),
                               currentHP: currentHP,
                               rawLevelRatio: contribution?.rawLevelRatio,
                               powerContribution: contribution?.contribution)
        }.sorted { $0.stableIdentity < $1.stableIdentity }

        return Self(
            scalingPreview: preview,
            party: party,
            foes: encounter.foes.map { FoeHealth(id: $0.id, currentHP: $0.currentHP) }
                .sorted { $0.id.rawValue < $1.id.rawValue },
            opening: encounter.opening,
            roundNumber: encounter.roundNumber,
            turnIndex: encounter.turnIndex,
            currentTurnSlot: encounter.currentTurnSlot,
            turnSlots: encounter.turnSlots,
            godModeReceipt: encounter.debugGodMode
        )
    }

    private static func stableIdentity(for companion: CompanionState) -> String {
        if let traveller = companion.traveller { return "traveller:\(traveller.rawValue)" }
        if companion.name.trimmingCharacters(in: .whitespacesAndNewlines)
            .localizedCaseInsensitiveCompare("Quill") == .orderedSame { return "quill" }
        let name = companion.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let calling = companion.calling.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return "legacy-person:\(name)|\(calling)"
    }
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

/// Keeps local save/dismiss semantics structurally separate from the only action allowed to call a
/// transport. UI labels can therefore be truthful without depending on convention in a button
/// closure.
struct DebugBugReportWorkflow: Sendable {
    let outbox: DebugBugReportOutbox
    private let submission: DebugBugReportSubmissionCoordinator?

    init(outbox: DebugBugReportOutbox, transport: (any DebugBugReportTransport)? = nil) {
        self.outbox = outbox
        self.submission = transport.map {
            DebugBugReportSubmissionCoordinator(outbox: outbox, transport: $0)
        }
    }

    func saveOnThisPhone(_ report: DebugBugReport, screenshot: Data?) throws -> URL {
        try outbox.save(report, screenshot: screenshot)
    }

    func done() {
        // Dismissal only. Intentionally no submission or state transition.
    }

    func submitToTriage(_ id: UUID) async throws -> DebugBugReportReceipt {
        guard let submission else {
            throw DebugBugReportSubmissionCoordinator.SubmissionError.missingReport(id)
        }
        return try await submission.submit(id)
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
