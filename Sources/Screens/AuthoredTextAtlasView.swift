#if DEBUG
import CryptoKit
import SwiftUI
import UIKit
import UniformTypeIdentifiers

enum AuthoredTextAtlas {
    enum UnitKind: String, Codable, CaseIterable {
        case meeting, diary
        var displayName: String { self == .meeting ? "Meeting" : "Diary" }
    }

    struct Unit: Identifiable, Equatable {
        let id: String
        let traveller: TravellerID
        let kind: UnitKind
        let label: String
        let text: String
        let detail: String?

        var textHash: String {
            SHA256.hash(data: Data(text.utf8)).map { String(format: "%02x", $0) }.joined()
        }

        var teachingKind: String? {
            guard kind == .diary, let detail else { return nil }
            for value in ["focus", "gambit", "pattern", "research", "site"] where detail.contains("\(value) ") { return value.capitalized }
            return nil
        }

        var validationIssues: [String] {
            var issues: [String] = []
            if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { issues.append("Empty prose") }
            if text.contains("TODO") || text.contains("TBD") { issues.append("Placeholder token") }
            if text.filter({ $0 == "*" }).count % 2 != 0 { issues.append("Malformed emphasis") }
            return issues
        }
    }

    struct TravellerEntry: Identifiable {
        let traveller: TravellerDef
        let units: [Unit]
        var id: TravellerID { traveller.id }
        var meetingState: String { traveller.meeting == nil ? "Missing" : "Live" }
    }

    /// The generated source and release catalogue share these exact authored meeting IDs.
    static var generatedMeetingIDs: Set<TravellerID> {
        Set(AuthoredMeetingCorpus.meetings.map { TravellerID(rawValue: $0.travellerID) })
    }

    static func inventory(catalogue: ContentCatalog = .shared) -> [TravellerEntry] {
        catalogue.travellers
            .sorted {
                ($0.authoredOrder ?? .max, $0.name) < ($1.authoredOrder ?? .max, $1.name)
            }
            .map { traveller in
                var units: [Unit] = []
                if let meeting = traveller.meeting {
                    let prefix = "meeting.\(traveller.id.rawValue)"
                    units.append(Unit(id: "\(prefix).opening", traveller: traveller.id,
                                      kind: .meeting, label: "Opening", text: meeting.opening, detail: nil))
                    for exchange in meeting.questions {
                        units.append(Unit(id: "\(prefix).exchange.\(exchange.id).ask", traveller: traveller.id,
                                          kind: .meeting, label: "You may ask", text: exchange.ask,
                                          detail: exchange.id))
                        units.append(Unit(id: "\(prefix).exchange.\(exchange.id).reply", traveller: traveller.id,
                                          kind: .meeting, label: "Reply", text: exchange.reply,
                                          detail: exchange.id))
                    }
                    units += [
                        Unit(id: "\(prefix).offer", traveller: traveller.id, kind: .meeting,
                             label: "Offer", text: meeting.offer, detail: nil),
                        Unit(id: "\(prefix).accepted", traveller: traveller.id, kind: .meeting,
                             label: "Accepted", text: meeting.accepted, detail: nil),
                        Unit(id: "\(prefix).declined", traveller: traveller.id, kind: .meeting,
                             label: "Declined", text: meeting.declined, detail: nil)
                    ]
                }
                for (index, page) in catalogue.diary(of: traveller.id).enumerated() {
                    var metadata = [page.kind.displayName, "packet \(index + 1)"]
                    if let about = page.about { metadata.append("about \(about.rawValue)") }
                    if let clue = page.clueIndex { metadata.append("clue \(clue)") }
                    if let focus = page.teachesFocus { metadata.append("focus \(focus.rawValue)") }
                    if let gambit = page.teachesGambit { metadata.append("gambit \(gambit.rawValue)") }
                    if let pattern = page.teachesPattern { metadata.append("pattern \(pattern)") }
                    if let research = page.researchNode { metadata.append("research \(research.rawValue)") }
                    if let site = page.site { metadata.append("site \(site.rawValue)") }
                    if traveller.id == "noll" { metadata.append("Provisional · needs Aimee review") }
                    units.append(Unit(id: "page.\(page.id.rawValue).prose", traveller: traveller.id,
                                      kind: .diary, label: "Page \(index + 1) · \(page.kind.displayName)",
                                      text: page.prose, detail: metadata.joined(separator: " · ")))
                }
                if traveller.id == "noll" {
                    units.append(Unit(id: "held.page.noll_field_separation_kit.prose", traveller: traveller.id,
                                      kind: .diary, label: "Held page · Pattern",
                                      text: "A travelling kit should open one object and then be spent. If the tool survives every separation, the thing being consumed is somewhere you have chosen not to record.",
                                      detail: "Provisional · DEBUG review only · not findable · no live Field Separation Kit reward"))
                }
                return TravellerEntry(traveller: traveller, units: units)
            }
    }
}

@MainActor
final class AuthoredTextReviewStore: ObservableObject {
    enum Status: String, Codable, CaseIterable { case unreviewed, good, needsRevision }
    struct Entry: Codable, Equatable {
        var status: Status
        var note: String?
        var reviewedTextHash: String
        var reviewedAt: Date
    }
    struct File: Codable { var schemaVersion = 1; var entries: [String: Entry] = [:] }
    struct Conflict: Identifiable, Equatable {
        let id: String
        let local: Entry
        let imported: Entry
    }

    @Published private(set) var file: File
    @Published private(set) var conflicts: [Conflict] = []
    @Published private(set) var migrationWarnings: [String] = []
    private let defaults: UserDefaults
    private let key = "debug.authoredTextReview.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
        if let data = defaults.data(forKey: key), let decoded = try? decoder.decode(File.self, from: data) {
            file = decoded
        } else { file = File() }
        migrateCorrectedMeetingAliases()
    }

    func status(for unit: AuthoredTextAtlas.Unit) -> Status {
        guard let entry = file.entries[unit.id], entry.reviewedTextHash == unit.textHash else { return .unreviewed }
        return entry.status
    }

    func isStale(_ unit: AuthoredTextAtlas.Unit) -> Bool {
        guard let entry = file.entries[unit.id] else { return false }
        return entry.reviewedTextHash != unit.textHash
    }

    func note(for unit: AuthoredTextAtlas.Unit) -> String { file.entries[unit.id]?.note ?? "" }

    func review(_ unit: AuthoredTextAtlas.Unit, as status: Status, note: String? = nil) {
        if status == .unreviewed && (note ?? "").isEmpty { file.entries.removeValue(forKey: unit.id) }
        else {
            file.entries[unit.id] = Entry(status: status, note: note?.nilIfBlank,
                                          reviewedTextHash: unit.textHash, reviewedAt: Date())
        }
        persist()
    }

    func updateNote(_ note: String, for unit: AuthoredTextAtlas.Unit) {
        let status = status(for: unit)
        review(unit, as: status, note: note)
    }

    func jsonReport(unitIDs: Set<String>? = nil) -> String {
        let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]; encoder.dateEncodingStrategy = .iso8601
        let report = unitIDs.map { allowed in File(entries: file.entries.filter { allowed.contains($0.key) }) } ?? file
        return String(data: (try? encoder.encode(report)) ?? Data(), encoding: .utf8) ?? "{}"
    }

    func importReport(_ data: Data) throws {
        let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
        let imported = try decoder.decode(File.self, from: data)
        guard imported.schemaVersion == file.schemaVersion else {
            throw CocoaError(.fileReadCorruptFile, userInfo: [NSLocalizedDescriptionKey: "Unsupported review schema \(imported.schemaVersion)"])
        }
        var newConflicts: [Conflict] = []
        for (id, incoming) in imported.entries {
            guard let local = file.entries[id] else { file.entries[id] = incoming; continue }
            if local == incoming { continue }
            if local.reviewedTextHash == incoming.reviewedTextHash {
                if incoming.reviewedAt > local.reviewedAt { file.entries[id] = incoming }
            } else {
                newConflicts.append(Conflict(id: id, local: local, imported: incoming))
            }
        }
        conflicts = newConflicts.sorted { $0.id < $1.id }
        persist()
    }

    /// Sela and Halloway's prose was always attached to the right traveller, but six exchange IDs
    /// carried the other person's prefix. Move DEBUG review decisions only when their exact prose
    /// hash proves identity; an edited/mismatched record stays under its old key and is reported.
    private func migrateCorrectedMeetingAliases() {
        let aliases = [
            ("sela", "halloway.destination", "sela.destination"),
            ("sela", "halloway.tired", "sela.tired"),
            ("sela", "halloway.wayfinding", "sela.wayfinding"),
            ("halloway", "sela.kept_fire", "halloway.kept_fire"),
            ("halloway", "sela.making", "halloway.making"),
            ("halloway", "sela.needs", "halloway.needs")
        ]
        let units = Dictionary(uniqueKeysWithValues: AuthoredTextAtlas.inventory().flatMap(\.units).map { ($0.id, $0) })
        var changed = false
        for (traveller, oldExchange, newExchange) in aliases {
            for suffix in ["ask", "reply"] {
                let oldID = "meeting.\(traveller).exchange.\(oldExchange).\(suffix)"
                let newID = "meeting.\(traveller).exchange.\(newExchange).\(suffix)"
                guard let old = file.entries[oldID], let unit = units[newID] else { continue }
                guard old.reviewedTextHash == unit.textHash else {
                    migrationWarnings.append("Review alias not applied: \(oldID) → \(newID) (text changed)")
                    continue
                }
                if file.entries[newID] == nil { file.entries[newID] = old }
                file.entries.removeValue(forKey: oldID)
                changed = true
            }
        }
        if changed { persist() }
    }

    func markdownReport(inventory: [AuthoredTextAtlas.TravellerEntry]) -> String {
        var lines = ["# Bookbinder authored-text review", ""]
        for entry in inventory {
            let reviewed = entry.units.filter { status(for: $0) != .unreviewed || isStale($0) }
            guard !reviewed.isEmpty else { continue }
            lines += ["## \(entry.traveller.name)", ""]
            for unit in reviewed {
                let state = isStale(unit) ? "stale" : status(for: unit).rawValue
                lines.append("- `\(unit.id)` — **\(state)**\(note(for: unit).isEmpty ? "" : ": \(note(for: unit))")")
            }
            lines.append("")
        }
        return lines.joined(separator: "\n")
    }

    private func persist() {
        let encoder = JSONEncoder(); encoder.dateEncodingStrategy = .iso8601
        defaults.set(try? encoder.encode(file), forKey: key)
    }
}

private extension String { var nilIfBlank: String? { trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : self } }

struct AuthoredTextAtlasView: View {
    private enum ReviewFilter: String, CaseIterable { case all, unreviewed, good, needsRevision, stale, missing }
    @StateObject private var reviews = AuthoredTextReviewStore()
    @State private var search = ""
    @State private var kind: AuthoredTextAtlas.UnitKind?
    @State private var phase: TravellerDef.CampaignPhase?
    @State private var reviewFilter: ReviewFilter = .all
    @State private var teachingKind: String?
    @State private var validationOnly = false
    @State private var importing = false
    @State private var importError: String?
    private let inventory = AuthoredTextAtlas.inventory()

    var body: some View {
        List {
            Section {
                Picker("Text kind", selection: $kind) {
                    Text("All text").tag(AuthoredTextAtlas.UnitKind?.none)
                    ForEach(AuthoredTextAtlas.UnitKind.allCases, id: \.self) { Text($0.displayName).tag(Optional($0)) }
                }
                Picker("Campaign phase", selection: $phase) {
                    Text("All phases").tag(TravellerDef.CampaignPhase?.none)
                    ForEach(TravellerDef.CampaignPhase.allCases, id: \.self) { Text($0.rawValue).tag(Optional($0)) }
                }
                Picker("Review status", selection: $reviewFilter) {
                    ForEach(ReviewFilter.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0) }
                }
                Picker("Teaching kind", selection: $teachingKind) {
                    Text("All teachings").tag(String?.none)
                    ForEach(["Focus", "Gambit", "Pattern", "Research", "Site"], id: \.self) { Text($0).tag(Optional($0)) }
                }
                Toggle("Validation issues only", isOn: $validationOnly)
            }
            Section("Travellers · \(inventory.count) · pages \(inventory.flatMap(\.units).filter { $0.kind == .diary }.count)") {
                ForEach(filtered) { entry in
                    NavigationLink {
                        AuthoredTextTravellerView(entry: entry, reviews: reviews)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack { Text(entry.traveller.name).font(.headline); Spacer(); Text(entry.meetingState).font(.caption) }
                            Text("\(entry.traveller.calling) · \(entry.traveller.campaignPhase?.rawValue ?? "unphased") · order \(entry.traveller.authoredOrder.map(String.init) ?? "—")")
                                .font(.caption).foregroundStyle(.secondary)
                            Text(summary(entry)).font(.caption2).foregroundStyle(.secondary)
                        }.padding(.vertical, 4)
                    }
                }
            }
            Section("Export") {
                ShareLink(item: reviews.jsonReport(unitIDs: Set(filtered.flatMap(\.units).map(\.id)))) { Label("Share filtered JSON report", systemImage: "square.and.arrow.up") }
                ShareLink(item: reviews.markdownReport(inventory: filtered)) { Label("Share filtered Markdown report", systemImage: "doc.plaintext") }
                Button { UIPasteboard.general.string = reviews.markdownReport(inventory: filtered) } label: {
                    Label("Copy Markdown report", systemImage: "doc.on.doc")
                }
                Button { importing = true } label: { Label("Import JSON report", systemImage: "square.and.arrow.down") }
                if !reviews.conflicts.isEmpty {
                    DisclosureGroup("Import conflicts · \(reviews.conflicts.count)") {
                        ForEach(reviews.conflicts) { conflict in
                            Text("\(conflict.id): local review retained; imported review targets different text.")
                                .font(.caption).foregroundStyle(.orange)
                        }
                    }
                }
                if !reviews.migrationWarnings.isEmpty {
                    DisclosureGroup("Review migration warnings · \(reviews.migrationWarnings.count)") {
                        ForEach(reviews.migrationWarnings, id: \.self) { warning in
                            Text(warning).font(.caption.monospaced()).foregroundStyle(.orange)
                        }
                    }
                }
                if let importError { Text(importError).font(.caption).foregroundStyle(.red) }
            }
        }
        .searchable(text: $search, prompt: "Names, prose, IDs, notes")
        .navigationTitle("Text Atlas")
        .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
            do {
                let url = try result.get()
                let scoped = url.startAccessingSecurityScopedResource()
                defer { if scoped { url.stopAccessingSecurityScopedResource() } }
                try reviews.importReport(Data(contentsOf: url))
                importError = nil
            } catch { importError = error.localizedDescription }
        }
    }

    private var filtered: [AuthoredTextAtlas.TravellerEntry] {
        inventory.compactMap { entry in
            guard phase == nil || entry.traveller.campaignPhase == phase else { return nil }
            var units = kind.map { selected in entry.units.filter { $0.kind == selected } } ?? entry.units
            if let teachingKind { units = units.filter { $0.teachingKind == teachingKind } }
            if validationOnly { units = units.filter { !$0.validationIssues.isEmpty } }
            switch reviewFilter {
            case .all: break
            case .missing:
                guard entry.traveller.meeting == nil else { return nil }
            case .stale: units = units.filter(reviews.isStale)
            case .unreviewed: units = units.filter { reviews.status(for: $0) == .unreviewed && !reviews.isStale($0) }
            case .good: units = units.filter { reviews.status(for: $0) == .good }
            case .needsRevision: units = units.filter { reviews.status(for: $0) == .needsRevision }
            }
            guard !units.isEmpty || reviewFilter == .missing else { return nil }
            if !search.isEmpty {
                let needle = search.localizedLowercase
                let travellerMatches = entry.traveller.name.localizedLowercase.contains(needle)
                    || entry.traveller.id.rawValue.localizedLowercase.contains(needle)
                if !travellerMatches {
                    units = units.filter { $0.id.localizedLowercase.contains(needle) || $0.text.localizedLowercase.contains(needle)
                        || reviews.note(for: $0).localizedLowercase.contains(needle) }
                    guard !units.isEmpty else { return nil }
                }
            }
            return AuthoredTextAtlas.TravellerEntry(traveller: entry.traveller, units: units)
        }
    }

    private func summary(_ entry: AuthoredTextAtlas.TravellerEntry) -> String {
        let good = entry.units.filter { reviews.status(for: $0) == .good }.count
        let revise = entry.units.filter { reviews.status(for: $0) == .needsRevision }.count
        let stale = entry.units.filter(reviews.isStale).count
        let unreviewed = entry.units.count - good - revise
        return "Good \(good) · Revise \(revise) · Unreviewed \(unreviewed) · Stale \(stale)"
    }
}

private struct AuthoredTextTravellerView: View {
    let entry: AuthoredTextAtlas.TravellerEntry
    @ObservedObject var reviews: AuthoredTextReviewStore
    @State private var lastJumpID: String?

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                Text("\(entry.traveller.calling) · \(entry.traveller.campaignPhase?.rawValue ?? "unphased") · authored order \(entry.traveller.authoredOrder.map(String.init) ?? "—")")
                    .font(.subheadline).foregroundStyle(.secondary)
                if entry.traveller.meeting == nil {
                    ContentUnavailableView("Meeting missing",
                                           systemImage: "person.crop.circle.badge.questionmark",
                                           description: Text("No live meeting object exists."))
                }
                if let live = entry.traveller.meeting {
                    AtlasMeetingPreview(title: "Live meeting preview", opening: live.opening,
                                        exchanges: live.questions.map { .init(id: $0.id, ask: $0.ask, reply: $0.reply) },
                                        offer: live.offer, accepted: live.accepted, declined: live.declined)
                }
                    ForEach(entry.units) { unit in ReviewUnitCard(unit: unit, reviews: reviews).id(unit.id) }
                }.padding(16)
            }
            .safeAreaInset(edge: .bottom) {
                HStack {
                    Button("Next unreviewed") { jump(to: nextUnit(matching: { reviews.status(for: $0) == .unreviewed }), proxy: proxy) }
                    Spacer()
                    Button("Next revision") { jump(to: nextUnit(matching: { reviews.status(for: $0) == .needsRevision }), proxy: proxy) }
                }
                .font(.caption.weight(.semibold)).padding(.horizontal, 16).padding(.vertical, 8).background(.bar)
            }
        }
        .navigationTitle(entry.traveller.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func nextUnit(matching predicate: (AuthoredTextAtlas.Unit) -> Bool) -> AuthoredTextAtlas.Unit? {
        let candidates = entry.units.filter(predicate)
        guard !candidates.isEmpty else { return nil }
        guard let lastJumpID, let index = candidates.firstIndex(where: { $0.id == lastJumpID }) else { return candidates.first }
        return candidates[(index + 1) % candidates.count]
    }

    private func jump(to unit: AuthoredTextAtlas.Unit?, proxy: ScrollViewProxy) {
        guard let unit else { return }
        lastJumpID = unit.id
        withAnimation { proxy.scrollTo(unit.id, anchor: .top) }
    }
}

private struct AtlasMeetingPreview: View {
    struct Exchange: Identifiable { let id: String; let ask: String; let reply: String }
    let title: String
    let opening: String
    let exchanges: [Exchange]
    let offer: String
    let accepted: String
    let declined: String
    @State private var conversation = TravellerMeetingConversation()

    var body: some View {
        DisclosureGroup(title) {
            VStack(alignment: .leading, spacing: 10) {
                AuthoredDialogueLine(text: opening)
                ForEach(conversation.orderedExchangeIDs, id: \.self) { id in
                    if let exchange = exchanges.first(where: { $0.id == id }) {
                        AuthoredDialogueLine(text: exchange.ask, isPlayer: true)
                        AuthoredDialogueLine(text: exchange.reply)
                    }
                }
                if let terminal = conversation.terminal {
                    AuthoredDialogueLine(text: terminal == .accepted ? accepted : declined)
                } else {
                    ForEach(exchanges.filter { !conversation.orderedExchangeIDs.contains($0.id) }) { exchange in
                        Button(exchange.ask) { conversation.ask(exchange.id) }
                            .buttonStyle(.bordered)
                            .frame(minHeight: 44)
                            .accessibilityHint("Appends this question and its matching reply to the transcript")
                    }
                    HStack {
                        Button(offer) { conversation.accept() }.buttonStyle(.borderedProminent)
                        Button("Leave") { conversation.decline() }.buttonStyle(.bordered)
                    }
                }
                Button("Reset preview") { conversation = TravellerMeetingConversation() }
                    .font(.caption)
            }.padding(.top, 8)
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }
}

private struct ReviewUnitCard: View {
    let unit: AuthoredTextAtlas.Unit
    @ObservedObject var reviews: AuthoredTextReviewStore
    @State private var note = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading) {
                    Text(unit.label).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                    Text(unit.id).font(.caption2.monospaced()).foregroundStyle(.tertiary)
                }
                Spacer()
                if reviews.isStale(unit) { Text("STALE").font(.caption2.bold()).foregroundStyle(.orange) }
            }
            if unit.kind == .diary,
               let pageID = unit.id.split(separator: ".").dropFirst().first.map(String.init),
               let page = ContentCatalog.shared.diaryPage(DiaryPageID(rawValue: pageID)) {
                DiaryPageProseCard(page: page)
                    .padding(12)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
            } else {
                Text(AuthoredTextRendering.attributed(unit.text)).font(unit.label == "You may ask" ? .callout.italic() : .callout)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
            }
            if let detail = unit.detail {
                DisclosureGroup("Developer context") { Text(detail).font(.caption.monospaced()).textSelection(.enabled) }
            }
            Picker("Review status for \(unit.label)", selection: Binding(
                get: { reviews.status(for: unit) },
                set: { reviews.review(unit, as: $0, note: note) })) {
                    Text("Unreviewed").tag(AuthoredTextReviewStore.Status.unreviewed)
                    Text("Good").tag(AuthoredTextReviewStore.Status.good)
                    Text("Needs revision").tag(AuthoredTextReviewStore.Status.needsRevision)
                }.pickerStyle(.segmented)
            TextField("Optional review note", text: $note, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .onSubmit { reviews.updateNote(note, for: unit) }
            Button("Save note") { reviews.updateNote(note, for: unit) }
                .buttonStyle(.bordered)
                .disabled(note == reviews.note(for: unit))
        }
        .padding(12)
        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
        .onAppear { note = reviews.note(for: unit) }
        .onDisappear {
            if note != reviews.note(for: unit) { reviews.updateNote(note, for: unit) }
        }
    }
}
#endif
