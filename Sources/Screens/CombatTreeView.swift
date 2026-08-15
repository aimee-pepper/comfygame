import SwiftUI

/// The authored combat graph in ordinary play. One tree fills the phone width; stable node IDs,
/// not branch position, own selection and purchase.
struct CombatTreeView: View {
    @EnvironmentObject private var store: GameStore
    let member: PartyMember
    @State private var treeID: CombatTreeID?
    @State private var selectedNodeID: CombatNodeID?
    @State private var refusal: String?

    private let catalogue = ContentCatalog.shared.combatGraph
    private var character: CharacterState { store.character(of: member) }
    private var owned: Set<CombatNodeID> {
        CombatGraphRules.ownedNodes(for: character, catalogue: catalogue)
    }
    private var points: Int {
        CombatGraphRules.unspentPoints(for: character, catalogue: catalogue)
    }
    private var tree: CombatGraphTreeDef {
        catalogue.trees.first { $0.id == treeID } ?? catalogue.trees[0]
    }
    private var layout: CombatGraphLayout { CombatGraphLayout(tree: tree) }
    private var selectedNode: CombatGraphNodeDef? { selectedNodeID.flatMap(catalogue.node) }

    var body: some View {
        VStack(spacing: 0) {
            header
            Picker("Combat tree", selection: Binding(get: { tree.id }, set: { treeID = $0 })) {
                ForEach(catalogue.trees) { Text($0.name).tag($0.id) }
            }
            .pickerStyle(.segmented).padding(.horizontal, 12).padding(.top, 6)
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        connectorKey
                        graphCanvas
                        if let selectedNode { detail(selectedNode) }
                    }
                    .padding(12)
                }
                .onChange(of: selectedNodeID) { _, id in
                    guard let id else { return }
                    withAnimation(.easeInOut(duration: 0.2)) { proxy.scrollTo(id, anchor: .bottom) }
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Training")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: tree.id) { _, _ in selectedNodeID = nil; refusal = nil }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text(store.name(of: member)).font(.callout.weight(.semibold))
                Text("Level \(character.level) · \(owned.count) learned")
                    .font(.caption2).foregroundStyle(.secondary)
            }
            Spacer()
            Text(points == 1 ? "1 point" : "\(points) points")
                .font(.caption.weight(.semibold)).foregroundStyle(points > 0 ? Color.accentColor : .secondary)
        }
        .padding(.horizontal, 16).padding(.vertical, 8).background(.bar)
    }

    private var connectorKey: some View {
        HStack(spacing: 14) {
            Label("own discipline", systemImage: "minus")
            Label("hybrid alternative", systemImage: "ellipsis")
        }
        .font(.caption2).foregroundStyle(.secondary)
        .accessibilityElement(children: .combine)
    }

    private var graphCanvas: some View {
        GeometryReader { proxy in
            let points = Dictionary(uniqueKeysWithValues: layout.placements.map {
                ($0.id, layout.point(for: $0, width: proxy.size.width))
            })
            ZStack(alignment: .topLeading) {
                Canvas { context, _ in
                    for edge in layout.edges {
                        guard let parent = points[edge.parent], let child = points[edge.child] else { continue }
                        var path = Path(); path.move(to: parent); path.addLine(to: child)
                        context.stroke(path, with: .color(.secondary.opacity(edge.isHybrid ? 0.5 : 0.78)),
                                       style: StrokeStyle(lineWidth: edge.isHybrid ? 1.5 : 2,
                                                          dash: edge.isHybrid ? [5, 4] : []))
                    }
                }
                ForEach(layout.placements) { placement in
                    Button { selectedNodeID = placement.id; refusal = nil } label: {
                        nodeTile(placement.node)
                    }
                    .buttonStyle(.plain).frame(width: 44, height: 44).position(points[placement.id]!)
                }
            }
        }
        .frame(height: CombatGraphLayout.canvasHeight)
        .accessibilityElement(children: .contain)
    }

    private func nodeTile(_ node: CombatGraphNodeDef) -> some View {
        let state = state(of: node)
        let selected = selectedNodeID == node.id
        let frame = ProductionCombatGraphNodeFrame(isCapstone: node.role == .capstone)
        let colour: Color = selected ? .accentColor : state == .owned ? .green
            : state == .available ? .accentColor : .secondary
        return ZStack {
            frame.fill(state == .owned ? Color.green.opacity(0.82)
                       : Color(.secondarySystemGroupedBackground))
                .overlay { frame.stroke(colour, style: StrokeStyle(lineWidth: selected ? 4 : 2,
                                                                    dash: state == .blocked ? [4, 3] : [])) }
            Image(systemName: state == .owned ? "checkmark" : "circle.fill")
                .font(.caption.bold()).foregroundStyle(state == .owned ? .white : colour)
        }
        .frame(width: 44, height: 44).contentShape(Rectangle())
        .accessibilityLabel(node.name).accessibilityValue(state.rawValue)
    }

    private func detail(_ node: CombatGraphNodeDef) -> some View {
        let state = state(of: node)
        return VStack(alignment: .leading, spacing: 8) {
            HStack { Text(node.name).font(.headline); Spacer(); Text(state.rawValue).font(.caption.bold()) }
            Text(node.effectCopy).font(.callout)
            Text(parentText(node)).font(.caption).foregroundStyle(.secondary)
            if node.depth > CombatGraphRules.openingMaximumDepth {
                Text(CombatGraphRules.PurchaseRefusal.unavailable.rawValue)
                    .font(.caption).foregroundStyle(.secondary)
            } else if state != .owned {
                Button("Learn \(node.name)") { purchase(node) }
                    .buttonStyle(.borderedProminent).frame(maxWidth: .infinity, minHeight: 44)
                    .disabled(state != .available)
            }
            if let refusal { Text(refusal).font(.caption).foregroundStyle(.secondary) }
        }
        .padding(12).background(Color(.secondarySystemGroupedBackground),
                                in: RoundedRectangle(cornerRadius: 12)).id(node.id)
    }

    private func state(of node: CombatGraphNodeDef) -> CombatGraphNodeState {
        if owned.contains(node.id) { return .owned }
        guard node.depth <= CombatGraphRules.openingMaximumDepth else { return .blocked }
        if case .success = store.previewCombatNodePurchase(node.id, for: member) { return .available }
        return .blocked
    }

    private func purchase(_ node: CombatGraphNodeDef) {
        switch store.previewCombatNodePurchase(node.id, for: member) {
        case .failure(let reason): refusal = reason.rawValue
        case .success(let quote):
            switch store.purchaseCombatNode(quote, for: member) {
            case .committed: refusal = nil
            case .refused(let reason): refusal = reason.rawValue
            }
        }
    }

    private func parentText(_ node: CombatGraphNodeDef) -> String {
        let names = node.ordinaryParentAlternatives.compactMap { catalogue.node($0)?.name }
        return names.isEmpty ? "No node prerequisite" : "Requires " + names.joined(separator: " OR ")
    }
}

private struct ProductionCombatGraphNodeFrame: Shape {
    let isCapstone: Bool
    func path(in rect: CGRect) -> Path {
        guard isCapstone else { return Path(roundedRect: rect, cornerRadius: 10) }
        var path = Path(); path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY)); path.closeSubpath(); return path
    }
}
