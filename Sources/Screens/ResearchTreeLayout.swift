import SwiftUI

/// Laying a research branch out as an actual tree.
///
/// The prerequisites have always been in the data and were never drawn — which made the trees
/// collapsible lists with hidden dependencies, "a shop with extra steps"
/// (decisions-session-12 §2). The branching structure *is* the point: you should be able to see
/// what leads where, and plan a route.
///
/// Nodes are placed in **tiers by depth** — a node sits one row below its deepest prerequisite —
/// and edges are drawn from each node up to every prerequisite it names.
struct ResearchTreeLayout {
    struct Placement: Identifiable {
        var node: ResearchNodeDef
        /// Rows from the top. A node's depth is one past its deepest requirement.
        var depth: Int
        /// Position within its row.
        var column: Int
        var id: ResearchNodeID { node.id }
    }

    var placements: [Placement]
    var rowCount: Int
    var columnCount: Int

    /// Edges as (from, to) node ids — child first, so drawing reads "this needs that".
    var edges: [(child: ResearchNodeID, parent: ResearchNodeID)]

    init(nodes: [ResearchNodeDef]) {
        let byID = Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, $0) })

        // Depth by longest path to a root, so a node always sits below everything it needs.
        var depths: [ResearchNodeID: Int] = [:]
        func depth(of id: ResearchNodeID, seen: Set<ResearchNodeID> = []) -> Int {
            if let known = depths[id] { return known }
            guard let node = byID[id], !seen.contains(id) else { return 0 }
            let within = node.requires.filter { byID[$0] != nil }
            let result = within.isEmpty ? 0
                : (within.map { depth(of: $0, seen: seen.union([id])) }.max() ?? 0) + 1
            depths[id] = result
            return result
        }

        var rows: [Int: [ResearchNodeDef]] = [:]
        for node in nodes.sorted(by: { $0.id.rawValue < $1.id.rawValue }) {
            rows[depth(of: node.id), default: []].append(node)
        }

        placements = rows.flatMap { depth, nodes in
            nodes.enumerated().map { Placement(node: $1, depth: depth, column: $0) }
        }
        rowCount = (rows.keys.max() ?? 0) + 1
        columnCount = max(1, rows.values.map(\.count).max() ?? 1)
        edges = nodes.flatMap { node in
            node.requires.filter { byID[$0] != nil }.map { (child: node.id, parent: $0) }
        }
    }

    func placement(of id: ResearchNodeID) -> Placement? {
        placements.first { $0.node.id == id }
    }
}

/// A branch drawn as a tree: nodes in tiers, edges to what they need.
struct ResearchTreeView: View {
    @EnvironmentObject private var store: GameStore
    let branch: ResearchBranchDef
    let onSelect: (ResearchNodeDef) -> Void

    private var layout: ResearchTreeLayout {
        ResearchTreeLayout(nodes: ContentCatalog.shared.nodes(in: branch.id))
    }

    private let nodeWidth: CGFloat = 116
    private let nodeHeight: CGFloat = 56
    private let gapX: CGFloat = 14
    private let gapY: CGFloat = 34

    var body: some View {
        let layout = self.layout
        let width = CGFloat(layout.columnCount) * (nodeWidth + gapX) - gapX
        let height = CGFloat(layout.rowCount) * (nodeHeight + gapY) - gapY

        // Wide branches scroll sideways rather than being squashed — a tree you can't read the
        // shape of is the thing this replaced.
        ScrollView(.horizontal, showsIndicators: false) {
            ZStack(alignment: .topLeading) {
                Canvas { context, _ in
                    for edge in layout.edges {
                        guard let child = layout.placement(of: edge.child),
                              let parent = layout.placement(of: edge.parent) else { continue }
                        var path = Path()
                        let from = anchor(parent, bottom: true)
                        let to = anchor(child, bottom: false)
                        path.move(to: from)
                        // A gentle S rather than a straight line, so crossing edges stay tellable
                        // apart when a node has two prerequisites.
                        path.addCurve(to: to,
                                      control1: CGPoint(x: from.x, y: from.y + gapY * 0.6),
                                      control2: CGPoint(x: to.x, y: to.y - gapY * 0.6))
                        context.stroke(path, with: .color(.secondary.opacity(0.45)),
                                       style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                    }
                }
                .frame(width: width, height: height)

                ForEach(layout.placements) { placement in
                    ResearchNodeChip(node: placement.node)
                        .frame(width: nodeWidth, height: nodeHeight)
                        .position(centre(placement))
                        .onTapGesture { onSelect(placement.node) }
                }
            }
            .frame(width: width, height: height)
            .padding(.vertical, 4)
        }
    }

    private func centre(_ placement: ResearchTreeLayout.Placement) -> CGPoint {
        CGPoint(x: CGFloat(placement.column) * (nodeWidth + gapX) + nodeWidth / 2,
                y: CGFloat(placement.depth) * (nodeHeight + gapY) + nodeHeight / 2)
    }

    private func anchor(_ placement: ResearchTreeLayout.Placement, bottom: Bool) -> CGPoint {
        let middle = centre(placement)
        return CGPoint(x: middle.x, y: middle.y + (bottom ? nodeHeight / 2 : -nodeHeight / 2))
    }
}

/// One node in the tree. Small enough that a branch fits on a phone, legible enough to plan with.
private struct ResearchNodeChip: View {
    @EnvironmentObject private var store: GameStore
    let node: ResearchNodeDef

    var body: some View {
        let isDone = store.isComplete(node)
        let isAvailable = store.isAvailable(node)
        let tint: Color = isDone ? .green : (isAvailable ? .accentColor : .secondary)

        VStack(spacing: 3) {
            Image(systemName: isDone ? "checkmark.circle.fill" : node.icon)
                .font(.callout)
                .foregroundStyle(tint)
            Text(node.name)
                .font(.caption2.weight(.medium))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
                .foregroundStyle(isAvailable || isDone ? Color.primary : Color.secondary)
        }
        .padding(4)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.secondarySystemGroupedBackground))
                .overlay(RoundedRectangle(cornerRadius: 10)
                    .stroke(tint.opacity(isDone || isAvailable ? 0.8 : 0.3),
                            lineWidth: isAvailable && !isDone ? 2 : 1))
        )
        .opacity(isDone || isAvailable ? 1 : 0.6)
        .contentShape(RoundedRectangle(cornerRadius: 10))
    }
}
