import SwiftUI

#if DEBUG
/// Native topology and legal-route proof. Ownership is local fixture state: this screen never reads
/// or writes CharacterState while production still uses the complete legacy consumer path.
struct CombatGraphRouteExplorer: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var treeID: CombatTreeID?
    @State private var selectedNodeID: CombatNodeID?
    @State private var route = CombatGraphRouteState()

    private let catalogue = ContentCatalog.shared.combatGraph
    private var tree: CombatGraphTreeDef {
        catalogue.trees.first { $0.id == treeID } ?? catalogue.trees[0]
    }
    private var layout: CombatGraphLayout { CombatGraphLayout(tree: tree) }
    private var selectedNode: CombatGraphNodeDef? { selectedNodeID.flatMap(catalogue.node) }
    private var pointsRemaining: Int { route.pointsRemaining }

    var body: some View {
        VStack(spacing: 0) {
            fixtureHeader
            treePicker
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        connectorKey
                        if dynamicTypeSize.isAccessibilitySize { semanticGraph }
                        else { graphCanvas }
                        if let selectedNode { detail(selectedNode) }
                    }
                    .padding(12)
                }
                .onChange(of: selectedNodeID) { _, id in
                    guard let id else { return }
                    withAnimation(.easeInOut(duration: 0.22)) {
                        proxy.scrollTo(id, anchor: .bottom)
                    }
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("V2 route explorer")
        .navigationBarTitleDisplayMode(.inline)
        .preference(key: DebugBugReporterSuppressedPreferenceKey.self, value: true)
        .onChange(of: tree.id) { _, id in
            if selectedNode.flatMap({ catalogue.tree(containing: $0.id) })?.id != id { selectedNodeID = nil }
        }
    }

    private var fixtureHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("DEBUG fixture · no campaign mutation").font(.caption.weight(.semibold))
                Text("\(route.owned.count) owned · \(pointsRemaining) points ready")
                    .font(.caption2).foregroundStyle(.secondary)
            }
            Spacer()
            Picker("Point budget", selection: Binding(
                get: { route.pointBudget },
                set: { value in route.selectPointBudget(value); selectedNodeID = nil })) {
                ForEach([8, 17, 25], id: \.self) { Text("\($0)").tag($0) }
            }
            .pickerStyle(.segmented).frame(width: 124)
            Button("Reset") { route.reset(); selectedNodeID = nil }
                .buttonStyle(.bordered).controlSize(.small)
        }
        .padding(.horizontal, 12).padding(.vertical, 8).background(.bar)
    }

    private var treePicker: some View {
        Picker("Combat tree", selection: Binding(get: { tree.id }, set: { treeID = $0 })) {
            ForEach(catalogue.trees) { Text($0.name).tag($0.id) }
        }
        .pickerStyle(.segmented).padding(.horizontal, 12).padding(.top, 6)
    }

    private var connectorKey: some View {
        HStack(spacing: 14) {
            HStack(spacing: 5) {
                Rectangle().frame(width: 24, height: 2)
                Text("own discipline")
            }
            HStack(spacing: 5) {
                HStack(spacing: 3) {
                    Rectangle().frame(width: 7, height: 2)
                    Rectangle().frame(width: 7, height: 2)
                }
                Text("hybrid alternative")
            }
        }
        .font(.caption2).foregroundStyle(.secondary)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Solid line own discipline. Dashed line authored hybrid alternative.")
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
                        context.stroke(path, with: .color(Color.secondary.opacity(edge.isHybrid ? 0.52 : 0.78)),
                                       style: StrokeStyle(lineWidth: edge.isHybrid ? 1.5 : 2,
                                                          dash: edge.isHybrid ? [5, 4] : []))
                    }
                }
                ForEach(layout.placements) { placement in
                    let point = points[placement.id]!
                    Button { selectedNodeID = placement.id } label: {
                        nodeTile(placement.node)
                    }
                    .buttonStyle(.plain).frame(width: 44, height: 44).position(point)
                }
            }
        }
        .frame(height: CombatGraphLayout.canvasHeight)
        .accessibilityElement(children: .contain)
    }

    private var semanticGraph: some View {
        LazyVStack(alignment: .leading, spacing: 12) {
            ForEach(1...5, id: \.self) { depth in
                Text("Depth \(depth) of 5").font(.headline).accessibilityAddTraits(.isHeader)
                ForEach(layout.orderedByDepth.filter { $0.node.depth == depth }) { placement in
                    Button { selectedNodeID = placement.id } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(placement.node.name).font(.headline)
                                Spacer(); Text(state(of: placement.node).rawValue).font(.caption.weight(.semibold))
                            }
                            Text("\(placement.discipline.name) · \(roleName(placement.node.role))")
                                .font(.caption).foregroundStyle(.secondary)
                            Text(placement.node.effectCopy).font(.callout)
                            Text(parentText(placement.node)).font(.caption).foregroundStyle(.secondary)
                        }
                        .padding(12).frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
                        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain).accessibilityElement(children: .combine)
                    .accessibilityHint("Opens exact node detail")
                }
            }
        }
    }

    private func nodeTile(_ node: CombatGraphNodeDef) -> some View {
        let state = state(of: node)
        let selected = selectedNodeID == node.id
        let frame = CombatGraphNodeFrame(isCapstone: node.role == .capstone)
        let color = borderColor(state, selected: selected)
        return ZStack {
            frame
            .fill(state == .owned ? Color.green.opacity(0.82) : Color(.secondarySystemGroupedBackground))
            .overlay {
                frame.stroke(color, style: StrokeStyle(lineWidth: selected ? 4 : 2,
                                                        dash: state == .blocked ? [4, 3] : []))
            }
            Image(systemName: state == .owned ? "checkmark" : "circle.fill")
                .font(.caption.weight(.bold)).foregroundStyle(state == .owned ? Color.white : color)
            if node.techniqueID != nil {
                Image(systemName: "sparkles").font(.system(size: 9)).foregroundStyle(.orange)
                    .offset(x: 17, y: -17).accessibilityHidden(true)
            }
        }
        .frame(width: 44, height: 44).contentShape(Rectangle())
        .accessibilityLabel(node.name)
        .accessibilityValue("\(state.rawValue), \(roleName(node.role))")
        .accessibilityHint("Selects exact Effect and prerequisite detail")
    }

    private func detail(_ node: CombatGraphNodeDef) -> some View {
        let discipline = catalogue.discipline(containing: node.id)
        let nodeState = state(of: node)
        let legal = nodeState == .available && pointsRemaining > 0
        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(node.name).font(.headline); Spacer()
                Text(nodeState.rawValue).font(.caption.weight(.semibold))
                    .foregroundStyle(borderColor(nodeState, selected: false))
            }
            Text("\(discipline?.name ?? "Unknown") · \(roleName(node.role))")
                .font(.caption).foregroundStyle(.secondary)
            if node.techniqueID != nil { Label("Active technique", systemImage: "sparkles") }
            Text(node.effectCopy).font(.callout).fixedSize(horizontal: false, vertical: true)
            Text(parentText(node)).font(.caption).foregroundStyle(.secondary)
            if node.role == .capstone { Text(capstoneGateText).font(.caption).foregroundStyle(.secondary) }
            if nodeState != .owned {
                Button("Learn \(node.name)") { if legal { _ = route.purchase(node, catalogue: catalogue) } }
                    .buttonStyle(.borderedProminent).frame(maxWidth: .infinity, minHeight: 44)
                    .disabled(!legal)
            }
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
        .id(node.id)
    }

    private func state(of node: CombatGraphNodeDef) -> CombatGraphNodeState {
        if route.owned.contains(node.id) { return .owned }
        return route.canPurchase(node, catalogue: catalogue) ? .available : .blocked
    }

    private func parentText(_ node: CombatGraphNodeDef) -> String {
        let names = node.ordinaryParentAlternatives.compactMap { catalogue.node($0)?.name }
        return names.isEmpty ? "No node prerequisite" : "Requires " + names.joined(separator: " OR ")
    }

    private var capstoneGateText: String {
        "Gate · own root, fundamental, development and mastery · 5 in this discipline including capstone · 7 connected prior nodes · earliest point 8"
    }

    private func roleName(_ role: CombatGraphRole) -> String {
        switch role {
        case .root: "Root"
        case .fundamentalA, .fundamentalB: "Fundamental"
        case .developmentA, .developmentB: "Development"
        case .masteryA, .masteryB: "Mastery"
        case .capstone: "Capstone"
        }
    }

    private func borderColor(_ state: CombatGraphNodeState, selected: Bool) -> Color {
        if selected { return .accentColor }
        switch state {
        case .owned: return Color.green
        case .available: return Color.accentColor
        case .blocked: return Color.secondary
        }
    }
}

private struct CombatGraphNodeFrame: Shape {
    let isCapstone: Bool

    func path(in rect: CGRect) -> Path {
        if isCapstone {
            var path = Path()
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
            path.closeSubpath()
            return path
        }
        return Path(roundedRect: rect, cornerRadius: 10)
    }
}
#endif
