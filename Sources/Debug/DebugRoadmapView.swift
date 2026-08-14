#if DEBUG
import SwiftUI

struct DebugToolsView: View {
    enum Tab: Hashable { case roadmap, balancing, textAtlas }
    @State private var tab: Tab = .roadmap

    var body: some View {
        TabView(selection: $tab) {
            DebugRoadmapView()
                .tabItem { Label("Roadmap", systemImage: "map") }
                .tag(Tab.roadmap)

            BalancingView()
                .tabItem { Label("Balancing", systemImage: "slider.horizontal.3") }
                .tag(Tab.balancing)

            AuthoredTextAtlasView()
                .tabItem { Label("Text Atlas", systemImage: "text.book.closed.fill") }
                .tag(Tab.textAtlas)
        }
        .navigationTitle(tab.title)
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("debug-tools")
    }
}

private extension DebugToolsView.Tab {
    var title: String {
        switch self {
        case .roadmap: "Roadmap"
        case .balancing: "Balancing"
        case .textAtlas: "Text Atlas"
        }
    }
}

struct DebugRoadmapView: View {
    private let board = DebugRoadmap.current

    var body: some View {
        List {
            Section {
                Label("Aimee is the sole tester for this phase.", systemImage: "person.fill")
                Text("Playable-loop blockers stay ahead of feature breadth. We check in after each installed phone checkpoint.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Playability first")
            }

            Section("Bundled planning snapshot") {
                LabeledContent("Essence baseline", value: board.essenceBaseline)
                LabeledContent("Current work", value: board.currentWork)
                Text(board.currentNote)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            ForEach(board.campaignBands) { band in
                Section {
                    ForEach(board.items(in: band)) { item in
                        RoadmapItemRow(item: item)
                    }
                } header: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(band.title)
                        Text(band.reach)
                            .font(.caption)
                            .textCase(nil)
                    }
                }
            }

            Section("Closed foundations") {
                ForEach(board.items.filter { $0.status == .complete }) { item in
                    RoadmapItemRow(item: item)
                }
            }

            Section("Paused until blockers pass") {
                ForEach(board.paused, id: \.self) { item in
                    Label(item, systemImage: "pause.circle")
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Text("Authoritative detail: docs/player-progression-implementation-roadmap-current.md")
                    .font(.caption.monospaced())
                    .textSelection(.enabled)
            } footer: {
                Text("Bundled planning snapshot · updated \(board.updated). This is authored roadmap data, not a measurement of the installed commit, build, tests, or device state.")
            }
        }
        .accessibilityIdentifier("debug-roadmap")
    }
}

private struct RoadmapItemRow: View {
    let item: DebugRoadmap.Item

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(item.priority)
                    .font(.caption.bold().monospaced())
                    .foregroundStyle(item.status.tint)
                Text(item.title)
                    .font(.headline)
                Spacer(minLength: 4)
                Label(item.status.label, systemImage: item.status.icon)
                    .font(.caption.bold())
                    .foregroundStyle(item.status.tint)
                    .labelStyle(.titleAndIcon)
            }
            Text(item.detail)
                .font(.callout)
                .foregroundStyle(.secondary)
            Text("Gate: \(item.gate)")
                .font(.caption)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("debug-roadmap.\(item.id)")
    }
}

enum DebugRoadmap {
    enum Status: String, Codable, Equatable {
        case complete, readyToTest, inProgress, next, queued, pending, paused

        var label: String {
            switch self {
            case .complete: "Complete"
            case .readyToTest: "Test now"
            case .inProgress: "In progress"
            case .next: "Next"
            case .queued: "Queued"
            case .pending: "Pending"
            case .paused: "Paused"
            }
        }

        var icon: String {
            switch self {
            case .complete: "checkmark.circle.fill"
            case .readyToTest: "play.circle.fill"
            case .inProgress: "hammer.circle.fill"
            case .next: "arrow.right.circle.fill"
            case .queued: "clock"
            case .pending: "wrench.and.screwdriver"
            case .paused: "pause.circle"
            }
        }

        var tint: Color {
            switch self {
            case .complete: .green
            case .readyToTest: .green
            case .inProgress: .blue
            case .next: .blue
            case .queued: .secondary
            case .pending: .orange
            case .paused: .secondary
            }
        }
    }

    enum Workstream: String, Codable, CaseIterable, Equatable {
        case engineering, design, asset, acceptance

        var label: String { rawValue.capitalized }
    }

    struct Item: Identifiable, Codable {
        let id: String
        let priority: String
        let title: String
        let status: Status
        let workstream: Workstream
        let isPrimary: Bool
        let detail: String
        let gate: String

        private enum CodingKeys: String, CodingKey {
            case id, priority, title, status, workstream, isPrimary, detail, gate
        }

        init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            id = try values.decode(String.self, forKey: .id)
            priority = try values.decode(String.self, forKey: .priority)
            title = try values.decode(String.self, forKey: .title)
            status = try values.decode(Status.self, forKey: .status)
            workstream = try values.decodeIfPresent(Workstream.self, forKey: .workstream)
                ?? Board.legacyWorkstream(for: id, status: status)
            isPrimary = try values.decodeIfPresent(Bool.self, forKey: .isPrimary)
                ?? (status == .inProgress)
            detail = try values.decode(String.self, forKey: .detail)
            gate = try values.decode(String.self, forKey: .gate)
        }
    }

    struct CampaignBand: Identifiable, Codable {
        let id: String
        let title: String
        let reach: String
        let itemIDs: [String]
    }

    struct Board: Codable {
        let schemaVersion: Int
        let updated: String
        let essenceBaseline: String
        let campaignBands: [CampaignBand]
        let items: [Item]
        let paused: [String]

        private enum CodingKeys: String, CodingKey {
            case schemaVersion, updated, essenceBaseline, campaignBands, items, paused
        }

        init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            schemaVersion = try values.decode(Int.self, forKey: .schemaVersion)
            updated = try values.decode(String.self, forKey: .updated)
            essenceBaseline = try values.decode(String.self, forKey: .essenceBaseline)
            campaignBands = try values.decodeIfPresent([CampaignBand].self, forKey: .campaignBands) ?? []
            items = try values.decode([Item].self, forKey: .items)
            paused = try values.decode([String].self, forKey: .paused)
        }

        var currentItems: [Item] {
            let active = Workstream.allCases.compactMap { workstream in
                items.first { $0.workstream == workstream && $0.isPrimary && $0.status == .inProgress }
                    ?? items.first { $0.workstream == workstream && $0.isPrimary && $0.status == .readyToTest }
            }
            if !active.isEmpty { return active }
            return items.filter { [.readyToTest, .next, .queued].contains($0.status) }
                .sorted(by: Self.fallbackOrder)
                .prefix(1).map { $0 }
        }

        var currentWork: String {
            currentItems.map { "\($0.workstream.label): \($0.status.label) · \($0.title)" }
                .joined(separator: "\n")
        }

        var currentNote: String { currentItems.map(\.detail).joined(separator: "\n\n") }

        /// Compatibility for the bug-report snapshot. This is deliberately derived from authored
        /// roadmap data and makes no claim about the commit or binary installed on a device.
        var bundledCheckpointClaim: String { "Bundled roadmap updated \(updated)" }

        func items(in band: CampaignBand) -> [Item] {
            let byID = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })
            return band.itemIDs.compactMap { byID[$0] }
        }

        func validationErrors() -> [String] {
            var errors: [String] = []
            for workstream in Workstream.allCases {
                let primaries = items.filter {
                    $0.workstream == workstream && $0.isPrimary
                }
                if primaries.count > 1 {
                    errors.append("Multiple \(workstream.rawValue) primaries: "
                                  + primaries.map(\.id).sorted().joined(separator: ", "))
                }
            }
            for item in items where item.isPrimary && [.complete, .paused].contains(item.status) {
                errors.append("Inactive primary: \(item.id)")
            }
            if schemaVersion >= 3 {
                let knownIDs = Set(items.map(\.id))
                let expectedIDs = Set(items.filter { $0.status != .complete }.map(\.id))
                let bandIDs = campaignBands.flatMap(\.itemIDs)
                let referencedIDs = Set(bandIDs)
                let unknownIDs = referencedIDs.subtracting(knownIDs).sorted()
                let missingIDs = expectedIDs.subtracting(referencedIDs).sorted()
                let duplicateIDs = Dictionary(grouping: bandIDs, by: { $0 })
                    .filter { $0.value.count > 1 }.keys.sorted()
                if campaignBands.isEmpty { errors.append("No campaign bands") }
                if !unknownIDs.isEmpty { errors.append("Unknown band items: " + unknownIDs.joined(separator: ", ")) }
                if !missingIDs.isEmpty { errors.append("Unbanded active items: " + missingIDs.joined(separator: ", ")) }
                if !duplicateIDs.isEmpty { errors.append("Duplicate band items: " + duplicateIDs.joined(separator: ", ")) }
            }
            return errors
        }

        static func legacyWorkstream(for id: String, status: Status) -> Workstream {
            if id == "combat-tree-v2" || status == .inProgress { return .engineering }
            if id == "item-character-identities" { return .asset }
            if status == .queued || status == .next || status == .pending { return .design }
            return .acceptance
        }

        private static func fallbackOrder(_ lhs: Item, _ rhs: Item) -> Bool {
            let rank = ["P0": 0, "P1": 1, "P2": 2, "P3": 3]
            let left = rank[lhs.priority] ?? 4
            let right = rank[rhs.priority] ?? 4
            return left == right ? lhs.id < rhs.id : left < right
        }
    }

    static let current: Board = {
        guard let url = Bundle.main.url(forResource: "playability-roadmap", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let board = try? JSONDecoder().decode(Board.self, from: data),
              board.validationErrors().isEmpty
        else { preconditionFailure("Missing or invalid playability-roadmap.json") }
        return board
    }()
}
#endif
