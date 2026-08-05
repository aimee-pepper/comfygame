import SwiftUI

/// The Workshop's research tree.
///
/// **Everything buyable in the game lives here**, gated behind a themed branch and its
/// prerequisites — there is no flat shopping list anywhere. A branch is a subject you're getting
/// better at; its nodes are the steps, and locked ones stay visible because seeing what you can't
/// have yet is most of what makes a tree feel like a tree.
struct ResearchTree: View {
    @EnvironmentObject private var store: GameStore

    var body: some View {
        VStack(spacing: 16) {
            ForEach(ContentCatalog.shared.branchesInOrder) { branch in
                ResearchBranchCard(branch: branch)
            }
        }
    }
}

private struct ResearchBranchCard: View {
    @EnvironmentObject private var store: GameStore
    let branch: ResearchBranchDef
    /// Collapsed by default (Aimee, 5 Aug). Four branches expanded at once is a wall of rows, and
    /// the point of a branch is that it's a *subject* you choose to look into — the headline plus
    /// its progress count is what you should be reading first.
    ///
    /// Interim shape. These are meant to become real trees — a laid-out DAG with visible
    /// prerequisite edges, reached from different buildings in the village rather than all from the
    /// Workshop. See BACKLOG "Research as actual trees".
    @State private var isExpanded = false
    @State private var selected: ResearchNodeDef?

    var body: some View {
        let progress = store.progress(in: branch)

        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation(.snappy) { isExpanded.toggle() }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: branch.icon).font(.title3).frame(width: 26).foregroundStyle(.tint)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(branch.name).font(.headline)
                        Text(branch.blurb).font(.caption).foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 8)
                    Text("\(progress.done)/\(progress.total)")
                        .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.semibold)).foregroundStyle(.tertiary)
                }
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                // **An actual tree.** Prerequisites have always been in the data; drawing them is
                // what makes a branch something you can plan a route through rather than a shop
                // with extra steps (decisions-session-12 §2). Tapping a node opens what it costs.
                ResearchTreeView(branch: branch) { selected = $0 }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .sheet(item: $selected) { node in
            NavigationStack {
                ScrollView { ResearchNodeRow(node: node).padding(16) }
                    .navigationTitle(node.name)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") { selected = nil }
                        }
                    }
            }
            .presentationDetents([.medium])
            .environmentObject(store)
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }

    private var orderedNodes: [ResearchNodeDef] {
        // Ranked outside the sort closure, which can't reach main-actor state.
        let ranked = ContentCatalog.shared.nodes(in: branch.id).map { node -> (node: ResearchNodeDef, rank: Int) in
            if store.isComplete(node) { return (node, 0) }
            return (node, store.isAvailable(node) ? 1 : 2)
        }
        return ranked
            .sorted { $0.rank == $1.rank ? $0.node.cost.essence < $1.node.cost.essence : $0.rank < $1.rank }
            .map(\.node)
    }
}

private struct ResearchNodeRow: View {
    @EnvironmentObject private var store: GameStore
    let node: ResearchNodeDef

    var body: some View {
        let isDone = store.isComplete(node)
        let isAvailable = store.isAvailable(node)
        let blockedBy = store.missingPrerequisites(for: node)
        let missing = store.shortfall(for: node)

        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 10) {
                Image(systemName: isDone ? "checkmark.circle.fill" : (isAvailable ? node.icon : "lock"))
                    .frame(width: 22)
                    .foregroundStyle(isDone ? Color.green : (isAvailable ? Color.accentColor : Color.secondary))
                VStack(alignment: .leading, spacing: 1) {
                    Text(node.name).font(.callout.weight(.medium))
                    Text(node.blurb).font(.caption).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    if !grantText.isEmpty {
                        Text(grantText).font(.caption2).foregroundStyle(.tint)
                    }
                }
                Spacer(minLength: 0)
            }

            if isDone {
                EmptyView()
            } else if !blockedBy.isEmpty {
                Text("Needs \(blockedBy.joined(separator: ", ")) first.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                Button {
                    store.research(node)
                } label: {
                    HStack {
                        Text(costText).font(.footnote.monospacedDigit())
                        Spacer()
                        Text(missing.isEmpty ? "Study" : "Need \(missing.joined(separator: ", "))")
                            .font(.footnote.weight(.semibold))
                    }
                    .frame(minHeight: 44)
                    .padding(.horizontal, 10)
                }
                .buttonStyle(.bordered)
                .tint(missing.isEmpty ? .accentColor : .secondary)
                .disabled(!missing.isEmpty)
            }
        }
        .padding(.vertical, 3)
        .opacity(isDone ? 0.6 : 1)
    }

    /// What you actually get — the reason to care about the row.
    private var grantText: String {
        node.grants.compactMap { grant -> String? in
            switch grant.kind {
            case .gambitComponent:
                guard let id = grant.id,
                      let component = ContentCatalog.shared.gambitComponent(GambitComponentID(rawValue: id))
                else { return nil }
                return "learn “\(component.name)”"
            case .symbol:
                guard let id = grant.id,
                      let symbol = ContentCatalog.shared.symbol(SymbolID(rawValue: id)) else { return nil }
                return "learn the \(symbol.name) symbol"
            case .effect:
                return grant.effect.map(describe)
            }
        }.joined(separator: " · ")
    }

    private func describe(_ effect: ResearchGrant.Effect) -> String {
        switch effect {
        case .storehouseTier: "+\(Tuning.Economy.inventorySlotsPerStorehouseTier) storehouse slots"
        case .satchelTier: "+\(Tuning.Economy.satchelSlotsPerTier) satchel slots"
        case .gambitSlot: "+1 rule slot"
        case .essenceSpringTier: "a deeper spring"
        case .automateSelf: "your own rules, followed without you"
        case .chaining: "more than one primary per subject"
        case .finerHand: "a finer instrument — the same runes, in less room"
        case .companionWeapon: "+\(Tuning.Encounter.attackPerWeaponTier) companion attack"
        case .companionArmor: "+\(Tuning.Encounter.defencePerArmorTier) companion defence"
        }
    }

    private var costText: String {
        var parts: [String] = []
        if node.cost.essence > 0 { parts.append("\(node.cost.essence) essence") }
        for (id, amount) in node.cost.resources.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
            parts.append("\(amount) \(ContentCatalog.shared.resource(id)?.name.lowercased() ?? id.rawValue)")
        }
        return parts.joined(separator: " · ")
    }
}
