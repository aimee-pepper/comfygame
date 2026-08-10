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
                Text("Essence continuity and early item offloading block feature breadth. We check in after each installed phone checkpoint.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Playability first")
            }

            Section("Current build") {
                LabeledContent("Installed / HEAD", value: board.installedBuild)
                LabeledContent("Current test", value: "Essence continuation")
                Text("Use Recommended Raw Essence with 1× multipliers. Record bind cost, collected raw, refined equivalent, Spring yield, ending Essence, and any anti-lock help.")
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
                Text("Read-only DEBUG mirror · updated 10 Aug 2026. Change the Markdown authority and this mirror together at each check-in.")
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
    enum Status {
        case readyToTest, next, queued, pending, paused

        var label: String {
            switch self {
            case .readyToTest: "Test now"
            case .next: "Next"
            case .queued: "Queued"
            case .pending: "Pending"
            case .paused: "Paused"
            }
        }

        var icon: String {
            switch self {
            case .readyToTest: "play.circle.fill"
            case .next: "arrow.right.circle.fill"
            case .queued: "clock"
            case .pending: "wrench.and.screwdriver"
            case .paused: "pause.circle"
            }
        }

        var tint: Color {
            switch self {
            case .readyToTest: .green
            case .next: .blue
            case .queued: .secondary
            case .pending: .orange
            case .paused: .secondary
            }
        }
    }

    struct Item: Identifiable {
        let id: String
        let priority: String
        let title: String
        let status: Status
        let detail: String
        let gate: String
    }

    struct Board {
        let installedBuild: String
        let items: [Item]
        let paused: [String]
    }

    static let current = Board(
        installedBuild: "a816113",
        items: [
            Item(id: "essence", priority: "B0", title: "Essence continuation",
                 status: .readyToTest,
                 detail: "Recommended 5–7 drops × 2–3 raw is installed. Measure it; do not retune from memory.",
                 gate: "Three ordinary returns now, building toward ten; another ordinary authored bind remains affordable."),
            Item(id: "awareness", priority: "A", title: "Awareness housekeeping",
                 status: .next,
                 detail: "837 tests are green locally. This check-in only installs, commits and pushes that exact slice.",
                 gate: "Installed build identity, phone smoke test, commit and push; no added scope."),
            Item(id: "outcome", priority: "C", title: "Atomic expedition outcome",
                 status: .queued,
                 detail: "One monotonic receipt makes return-driven stock and production idempotent across relaunch and anchored revisits.",
                 gate: "Authorize only after the three-expedition Essence evidence; returns tick once and combat/recap do not."),
            Item(id: "trading-post", priority: "D", title: "Sell-first Trading Post",
                 status: .queued,
                 detail: "Land gold, authored transfer metadata, safe selling and one idempotent stock refresh before traveller integration.",
                 gate: "Sell, cancel and reload without loss, duplication, anti-loop failure or lock bypass."),
            Item(id: "vance", priority: "E", title: "Vance first + 10e Trading Post",
                 status: .queued,
                 detail: "Make Vance the first intended find and sole Trading Post owner without rewriting unreviewed prose.",
                 gate: "Fresh and old-save find/build/sell/runway proof on phone."),
            Item(id: "recycler", priority: "F", title: "Independent Recycler engine",
                 status: .queued,
                 detail: "Recover exact construction receipts or explicit found-gear salvage with no invented provenance.",
                 gate: "Recycle, reject, cancel and reload with exactly one recovery route."),
            Item(id: "noll", priority: "G", title: "Noll second + Halloway third",
                 status: .queued,
                 detail: "After Aimee approves Noll's identity/live copy, migrate to Vance → Noll → Halloway without granting Noll to old saves.",
                 gate: "Fresh campaign reaches circulate → recover → retain/make without recreating the Essence blocker."),
            Item(id: "terrain", priority: "P1", title: "Terrain border correction",
                 status: .pending,
                 detail: "Remove universal grid/dirt ledge; keep only meaningful adjacency edges and inset elevation contours.",
                 gate: "Native phone proof with complete map, mixed heights, route, content, water and chasm."),
            Item(id: "refining", priority: "P1", title: "Spring refining skills",
                 status: .queued,
                 detail: "After baseline telemetry: batch control, a reversible 2→3 rate unlock, and outcome-safe auto-refining.",
                 gate: "Opening 2:1 loop already works; unlock payback and precision cost remain healthy over ten returns."),
            Item(id: "bug-reporter", priority: "P1", title: "In-game bug reporter",
                 status: .queued,
                 detail: "After blockers: floating DEBUG capture, text form, build/context bundle and durable untriaged outbox.",
                 gate: "Screenshot/report survives relaunch and reaches one agreed queue exactly once.")
        ],
        paused: [
            "Broad asset and catalogue expansion",
            "Tutorial content for outside testers",
            "New stations and companion systems",
            "Great Work, Reality reset and Tam",
            "Animation and non-blocking polish"
        ]
    )
}
#endif
