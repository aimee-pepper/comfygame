import SwiftUI

/// Deterministic phone layout for a research DAG. Prerequisites, never price or display name,
/// establish rank; stable IDs break presentation ties.
struct ResearchGraphLayout {
    struct Placement: Identifiable {
        let node: ResearchNodeDef
        let rank: Int
        let row: Int
        let column: Int
        let columnsInRow: Int
        var id: ResearchNodeID { node.id }
    }

    let placements: [Placement]
    let rows: Int

    init(nodes: [ResearchNodeDef]) {
        let byID = Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, $0) })
        var cache: [ResearchNodeID: Int] = [:]

        func rank(_ id: ResearchNodeID, visiting: Set<ResearchNodeID> = []) -> Int {
            if let cached = cache[id] { return cached }
            guard let node = byID[id], !visiting.contains(id) else { return 0 }
            let localParents = node.requires.filter { byID[$0] != nil }
            let value = localParents.isEmpty ? 0
                : 1 + (localParents.map { rank($0, visiting: visiting.union([id])) }.max() ?? 0)
            cache[id] = value
            return value
        }

        for node in nodes { _ = rank(node.id) }
        var result: [Placement] = []
        var visualRow = 0
        let ranks = Dictionary(grouping: nodes) { cache[$0.id] ?? 0 }
        for rankValue in ranks.keys.sorted() {
            let ranked = (ranks[rankValue] ?? []).sorted { $0.id.rawValue < $1.id.rawValue }
            for start in stride(from: 0, to: ranked.count, by: 3) {
                let group = Array(ranked[start..<min(start + 3, ranked.count)])
                for (column, node) in group.enumerated() {
                    result.append(Placement(node: node, rank: rankValue, row: visualRow,
                                            column: column, columnsInRow: group.count))
                }
                visualRow += 1
            }
        }
        placements = result
        rows = visualRow
    }
}

struct ResearchBranchScreen: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let branch: ResearchBranchDef
    @State private var selectedNode: ResearchNodeDef?

    private var nodes: [ResearchNodeDef] { ContentCatalog.shared.nodes(in: branch.id) }
    private var layout: ResearchGraphLayout { ResearchGraphLayout(nodes: nodes) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(branch.blurb)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                if dynamicTypeSize.isAccessibilitySize {
                    accessibleRanks
                } else {
                    ResearchGraph(layout: layout, selectedNode: $selectedNode)
                        .environmentObject(store)
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(branch.name)
        .navigationBarTitleDisplayMode(.inline)
        .popover(item: $selectedNode, attachmentAnchor: .rect(.bounds), arrowEdge: .top) { node in
            ResearchNodeDetail(node: node)
                .environmentObject(store)
                .presentationCompactAdaptation(dynamicTypeSize.isAccessibilitySize ? .sheet : .popover)
        }
    }

    private var accessibleRanks: some View {
        let grouped = Dictionary(grouping: layout.placements) { $0.rank }
        return LazyVStack(alignment: .leading, spacing: 14) {
            ForEach(grouped.keys.sorted(), id: \.self) { rank in
                Text("Rank \(rank + 1)")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                ForEach((grouped[rank] ?? []).sorted { $0.node.id.rawValue < $1.node.id.rawValue }) { placement in
                    Button { selectedNode = placement.node } label: {
                        ResearchAccessibleNode(node: placement.node)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct ResearchGraph: View {
    @EnvironmentObject private var store: GameStore
    let layout: ResearchGraphLayout
    @Binding var selectedNode: ResearchNodeDef?

    private let rowHeight: CGFloat = 94
    private let nodeSize: CGFloat = 64

    var body: some View {
        GeometryReader { proxy in
            let points = Dictionary(uniqueKeysWithValues: layout.placements.map {
                ($0.node.id, point(for: $0, width: proxy.size.width))
            })
            ZStack(alignment: .topLeading) {
                Canvas { context, _ in
                    for placement in layout.placements {
                        guard let child = points[placement.node.id] else { continue }
                        for parentID in placement.node.requires {
                            guard let parent = points[parentID] else { continue }
                            var path = Path()
                            path.move(to: CGPoint(x: parent.x, y: parent.y + nodeSize / 2))
                            path.addLine(to: CGPoint(x: child.x, y: child.y - nodeSize / 2))
                            let satisfied = store.state.base.completedResearch.contains(parentID)
                            context.stroke(path,
                                           with: .color(satisfied ? Color.accentColor : Color.secondary.opacity(0.45)),
                                           style: StrokeStyle(lineWidth: satisfied ? 2 : 1.5,
                                                              dash: satisfied ? [] : [4, 3]))
                        }
                    }
                }
                ForEach(layout.placements) { placement in
                    let center = points[placement.node.id]!
                    Button { selectedNode = placement.node } label: {
                        ResearchNodeTile(node: placement.node,
                                         selected: selectedNode?.id == placement.node.id)
                    }
                    .buttonStyle(.plain)
                    .frame(width: nodeSize, height: nodeSize)
                    .position(center)
                }
            }
        }
        .frame(height: max(120, CGFloat(layout.rows) * rowHeight))
        .accessibilityElement(children: .contain)
    }

    private func point(for placement: ResearchGraphLayout.Placement, width: CGFloat) -> CGPoint {
        let spacing = width / CGFloat(placement.columnsInRow)
        return CGPoint(x: spacing * (CGFloat(placement.column) + 0.5),
                       y: CGFloat(placement.row) * rowHeight + nodeSize / 2 + 8)
    }
}

private struct ResearchNodeTile: View {
    @EnvironmentObject private var store: GameStore
    let node: ResearchNodeDef
    let selected: Bool

    private var completed: Bool { store.isComplete(node) }
    private var supplied: Bool { store.isSuppliedByKeeper(node) }
    private var available: Bool { store.isAvailable(node) }
    private var shortfall: [String] { store.shortfall(for: node) }

    var body: some View {
        VStack(spacing: 3) {
            Image(systemName: completed ? "checkmark" : supplied ? "person.fill" : node.icon)
                .font(.body.weight(.semibold))
            Text(node.name)
                .font(.system(size: 9, weight: .semibold))
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(completed ? Color.white : Color.primary)
        .frame(width: 58, height: 58)
        .background(completed ? Color.green.opacity(0.8) : Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(borderColor, style: StrokeStyle(lineWidth: selected ? 4 : 2,
                                                               dash: available || completed ? [] : [4, 3]))
        }
        .overlay(alignment: .topTrailing) {
            if available && !shortfall.isEmpty && !completed && !supplied {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .offset(x: 4, y: -4)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityLabel(node.name)
        .accessibilityValue(stateLabel)
        .accessibilityHint(prerequisiteLabel)
    }

    private var borderColor: Color {
        if selected { return .accentColor }
        if completed { return .green }
        if supplied { return .teal }
        if available && shortfall.isEmpty { return .accentColor }
        if available { return .orange }
        return .secondary
    }

    private var stateLabel: String {
        if completed { return "Completed" }
        if supplied { return "Supplied by keeper" }
        if available && shortfall.isEmpty { return "Available" }
        if available { return "Available, missing stock" }
        return "Locked"
    }

    private var prerequisiteLabel: String {
        let names = node.requires.compactMap { ContentCatalog.shared.researchNode($0)?.name }
        return names.isEmpty ? "No node prerequisite" : "Requires \(names.joined(separator: " and "))"
    }
}

private struct ResearchAccessibleNode: View {
    @EnvironmentObject private var store: GameStore
    let node: ResearchNodeDef

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(node.name).font(.headline)
                Spacer()
                Text(stateLabel).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            }
            Text(prerequisiteLabel).font(.callout).foregroundStyle(.secondary)
            let grant = ResearchWording.grantText(for: node)
            if !grant.isEmpty { Text(grant).font(.callout) }
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
        .contentShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens research detail")
    }

    private var stateLabel: String {
        if store.isComplete(node) { return "Completed" }
        if store.isSuppliedByKeeper(node) { return "Supplied" }
        if store.isAvailable(node) && store.shortfall(for: node).isEmpty { return "Available" }
        if store.isAvailable(node) { return "Missing stock" }
        return "Locked"
    }
    private var prerequisiteLabel: String {
        let names = node.requires.compactMap { ContentCatalog.shared.researchNode($0)?.name }
        return names.isEmpty ? "No node prerequisite." : "Requires \(names.joined(separator: " and "))."
    }
}

private struct ResearchNodeDetail: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss
    let node: ResearchNodeDef

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(node.name).font(.headline)
                    Spacer()
                    Button("Done") { dismiss() }.frame(minHeight: 44)
                }
                if !node.blurb.isEmpty { Text(node.blurb).font(.callout) }
                let grant = ResearchWording.grantText(for: node)
                if !grant.isEmpty { LabeledContent("Grants", value: grant) }
                prerequisites
                LabeledContent("Cost", value: costText)
                let purchase = store.researchPurchasePreview(for: node)
                if !purchase.shortfall.isEmpty {
                    Text("Needs: \(purchase.shortfall.joined(separator: " · "))")
                        .font(.caption).foregroundStyle(.secondary)
                }
                if node.branch == "penmanship" { runway(purchase) }
                if store.isSuppliedByKeeper(node) {
                    Label("Supplied by keeper", systemImage: "person.crop.circle.badge.checkmark")
                        .foregroundStyle(.teal)
                } else if !store.isComplete(node) {
                    Button("Study") {
                        if store.research(purchase, node: node) == .committed { dismiss() }
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .disabled(!store.canResearch(node))
                }
            }
            .padding(16)
        }
        .frame(minWidth: 300, idealWidth: 330, maxWidth: 360, minHeight: 260)
    }

    @ViewBuilder
    private func runway(_ preview: EconomyRules.ResearchPurchasePreview) -> some View {
        let affordability = preview.affordability
        VStack(alignment: .leading, spacing: 5) {
            LabeledContent("Essence available now", value: "\(affordability.essenceAvailableNow)")
            if affordability.includesRefining {
                LabeledContent("Essence after refining", value: "\(affordability.essenceAfterRefining)")
            }
            LabeledContent(affordability.afterActionLabel,
                           value: "\(affordability.essenceAfterAction)")
            if let basisLabel = affordability.basisLabel,
               let basisCost = affordability.basisCost,
               let count = affordability.formattedWorldCount {
                LabeledContent(basisLabel,
                               value: basisCost.formatted(.number.precision(.fractionLength(0...1))))
                LabeledContent(affordability.worldCountLabel, value: count)
            } else {
                Text(affordability.noBasisCopy)
            }
            if let warning = affordability.warningCopy {
                Label(warning, systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
            }
        }
        .font(.caption.monospacedDigit())
        .foregroundStyle(.secondary)
    }

    private var prerequisites: some View {
        let parents = node.requires.compactMap { ContentCatalog.shared.researchNode($0) }
        return VStack(alignment: .leading, spacing: 5) {
            Text("Prerequisites").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            if parents.isEmpty { Text("No node prerequisite.") }
            ForEach(parents) { parent in
                Label(parent.name,
                      systemImage: store.isComplete(parent) || store.isSuppliedByKeeper(parent)
                      ? "checkmark.circle.fill" : "circle.dashed")
            }
        }
    }

    private var costText: String {
        let paid = store.paidCost(for: node)
        var parts: [String] = []
        if paid.essence > 0 { parts.append("\(paid.essence) essence") }
        for (id, amount) in paid.resources.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
            parts.append("\(amount) \(ContentCatalog.shared.resource(id)?.name.lowercased() ?? id.rawValue)")
        }
        return parts.isEmpty ? "Free" : parts.joined(separator: " · ")
    }
}

enum ResearchWording {
    static func grantText(for node: ResearchNodeDef) -> String {
        node.grants.compactMap { grant -> String? in
            switch grant.kind {
            case .gambitComponent:
                guard let id = grant.id,
                      let component = ContentCatalog.shared.gambitComponent(GambitComponentID(rawValue: id))
                else { return nil }
                return "Learn “\(component.name)”"
            case .symbol:
                guard let id = grant.id, let symbol = ContentCatalog.shared.symbol(SymbolID(rawValue: id)) else { return nil }
                return "Learn the \(symbol.name) symbol"
            case .focus:
                guard let id = grant.id, let focus = ContentCatalog.shared.pressureSource(PressureSourceID(rawValue: id)) else { return nil }
                return "Learn to write \(focus.name)"
            case .instrument:
                guard let id = grant.id, let target = ContentCatalog.shared.pressureTarget(PressureTargetID(rawValue: id)) else { return nil }
                return "Measure \(target.name.lowercased()) in numbers"
            case .capability:
                guard let id = grant.id else { return nil }
                return "Unlock \(id.replacingOccurrences(of: "_", with: " "))"
            case .effect:
                return grant.effect.map(describe)
            }
        }.joined(separator: " · ")
    }

    static func describe(_ effect: ResearchGrant.Effect) -> String {
        switch effect {
        case .storehouseTier: "+\(Tuning.Economy.inventorySlotsPerStorehouseTier) storehouse slots"
        case .satchelTier: "+\(Tuning.Economy.satchelSlotsPerTier) satchel slots"
        case .gambitSlot: "+1 rule slot"
        case .essenceSpringTier: "a deeper spring"
        case .automateSelf: "your own rules, followed without you"
        case .chaining: "more than one main focus per subject"
        case .finerHand: "a finer instrument — the same runes, in less room"
        case .scriptoriumTier: "a better Scriptorium, and what it lets Isolde teach next"
        case .analysisTier: "another tier of the page lens — you can read more off a page before you spend it"
        case .stationTier: "a deeper specialist capability at this station"
        case .companionWeapon: "+\(Tuning.Encounter.attackPerWeaponTier) companion attack"
        case .companionArmor: "+\(Tuning.Encounter.defencePerArmorTier) companion defence"
        }
    }
}
