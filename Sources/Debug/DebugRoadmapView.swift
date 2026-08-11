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

            Section("Current build") {
                LabeledContent("Installed checkpoint", value: board.installedCheckpoint)
                LabeledContent("Essence baseline", value: board.essenceBaseline)
                LabeledContent("Current work", value: board.currentWork)
                Text(board.currentNote)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Section("Roadmap") {
                ForEach(board.items) { item in
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
                Text("Authoritative detail: docs/playability-first-roadmap-current.md")
                    .font(.caption.monospaced())
                    .textSelection(.enabled)
            } footer: {
                Text("Live DEBUG view · updated \(board.updated) from bundled playability-roadmap.json. The app contains no separate hand-maintained status list.")
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

    struct Item: Identifiable, Codable {
        let id: String
        let priority: String
        let title: String
        let status: Status
        let detail: String
        let gate: String
    }

    struct Board: Codable {
        let schemaVersion: Int
        let updated: String
        let installedCheckpoint: String
        let essenceBaseline: String
        let currentWork: String
        let currentNote: String
        let items: [Item]
        let paused: [String]
    }

    static let current: Board = {
        guard let url = Bundle.main.url(forResource: "playability-roadmap", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let board = try? JSONDecoder().decode(Board.self, from: data)
        else { preconditionFailure("Missing or invalid playability-roadmap.json") }
        return board
    }()
}
#endif
