import SwiftUI

/// Laying a research branch out as a **vertical outline**.
///
/// It was a node graph that scrolled sideways, which is the wrong shape for a phone twice over: you
/// had to scroll horizontally to read a tree, and nodes were ordered by *id* within their row rather
/// than under the thing they follow from — so Satchel Reinforced sat two columns away from Satchel
/// Stitching with Deepen The Spring between them, and the edges crossed over each other.
///
/// An outline fixes both by construction. A node is written directly beneath the thing it needs,
/// indented one step; siblings are adjacent; **edges cannot cross, because there are no edges** —
/// the indentation is the edge. It reads top to bottom, which is the direction a phone scrolls.
///
/// A node that needs *two* things sits under one of them and names the other, so the second
/// dependency stays visible rather than being silently dropped.
struct ResearchOutline {
    struct Row: Identifiable {
        var node: ResearchNodeDef
        /// Steps in from the left. Zero for a node that needs nothing.
        var indent: Int
        /// Requirements this row does **not** sit beneath — the second parent of a diamond.
        var alsoNeeds: [ResearchNodeDef]
        var hasChildren: Bool
        /// True for the last sibling at its level, so the connector can stop rather than run on.
        var isLastSibling: Bool
        var id: ResearchNodeID { node.id }
    }

    var rows: [Row]

    init(nodes: [ResearchNodeDef]) {
        let byID = Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, $0) })

        // Depth by longest path to a root, so a node is always written below everything it needs.
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
        for node in nodes { _ = depth(of: node.id) }

        /// The one requirement a node is written beneath: its deepest, so the outline follows the
        /// longest chain and a diamond closes rather than repeating.
        func primaryParent(of node: ResearchNodeDef) -> ResearchNodeID? {
            node.requires
                .filter { byID[$0] != nil }
                .max { lhs, rhs in
                    (depths[lhs] ?? 0, rhs.rawValue) < (depths[rhs] ?? 0, lhs.rawValue)
                }
        }

        var children: [ResearchNodeID: [ResearchNodeDef]] = [:]
        var roots: [ResearchNodeDef] = []
        for node in nodes {
            if let parent = primaryParent(of: node) {
                children[parent, default: []].append(node)
            } else {
                roots.append(node)
            }
        }

        /// Cheapest first, then by name — so a branch reads as a course of study rather than as
        /// whatever order the file happened to be in.
        func ordered(_ group: [ResearchNodeDef]) -> [ResearchNodeDef] {
            group.sorted {
                ($0.cost.essence, $0.name) < ($1.cost.essence, $1.name)
            }
        }

        var rows: [Row] = []
        func emit(_ node: ResearchNodeDef, indent: Int, isLast: Bool) {
            let kids = ordered(children[node.id] ?? [])
            let primary = primaryParent(of: node)
            rows.append(Row(node: node,
                            indent: indent,
                            alsoNeeds: node.requires
                                .filter { $0 != primary }
                                .compactMap { byID[$0] },
                            hasChildren: !kids.isEmpty,
                            isLastSibling: isLast))
            for (index, child) in kids.enumerated() {
                emit(child, indent: indent + 1, isLast: index == kids.count - 1)
            }
        }
        let orderedRoots = ordered(roots)
        for (index, root) in orderedRoots.enumerated() {
            emit(root, indent: 0, isLast: index == orderedRoots.count - 1)
        }
        self.rows = rows
    }
}

/// A branch, in full, on its own screen.
///
/// **Navigated into and out of** rather than expanded in place: a branch is a subject you sit down
/// with, and four of them unfolding inside a scrolling card gave every one of them a fifth of the
/// screen to draw a tree in.
struct ResearchBranchScreen: View {
    @EnvironmentObject private var store: GameStore
    let branch: ResearchBranchDef
    @State private var collapsed: Set<ResearchNodeID> = []

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 4) {
                Text(branch.blurb)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 6)

                ForEach(visibleRows) { row in
                    ResearchOutlineRow(row: row,
                                       isCollapsed: collapsed.contains(row.node.id),
                                       toggle: { toggle(row.node.id) })
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(branch.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    /// Everything except what's tucked away under a collapsed parent.
    private var visibleRows: [ResearchOutline.Row] {
        let rows = ResearchOutline(nodes: ContentCatalog.shared.nodes(in: branch.id)).rows
        var result: [ResearchOutline.Row] = []
        var hiddenDeeperThan: Int?
        for row in rows {
            if let limit = hiddenDeeperThan {
                if row.indent > limit { continue }
                hiddenDeeperThan = nil
            }
            result.append(row)
            if collapsed.contains(row.node.id) { hiddenDeeperThan = row.indent }
        }
        return result
    }

    private func toggle(_ id: ResearchNodeID) {
        withAnimation(.snappy) {
            if collapsed.contains(id) { collapsed.remove(id) } else { collapsed.insert(id) }
        }
    }
}

/// One line of the outline: what it is, what it costs, and the button to study it.
///
/// Self-contained on purpose — there is no sheet to open. Everything you need to decide whether to
/// buy this is on the row, which is what makes the outline plannable by scrolling it.
private struct ResearchOutlineRow: View {
    @EnvironmentObject private var store: GameStore
    let row: ResearchOutline.Row
    let isCollapsed: Bool
    let toggle: () -> Void

    private let indentWidth: CGFloat = 18

    var body: some View {
        let node = row.node
        let isDone = store.isComplete(node)
        let isAvailable = store.isAvailable(node)
        let missing = store.shortfall(for: node)

        HStack(alignment: .top, spacing: 0) {
            // The indentation *is* the edge. A short elbow makes the parent unambiguous.
            ForEach(0..<row.indent, id: \.self) { step in
                Rectangle()
                    .fill(Color.secondary.opacity(step == row.indent - 1 ? 0 : 0.25))
                    .frame(width: 1)
                    .frame(maxHeight: .infinity)
                    .frame(width: indentWidth)
            }
            if row.indent > 0 {
                ElbowConnector(isLast: row.isLastSibling)
                    .stroke(Color.secondary.opacity(0.4), lineWidth: 1.5)
                    .frame(width: 12)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: isDone ? "checkmark.circle.fill" : (isAvailable ? node.icon : "lock.fill"))
                        .font(.footnote)
                        .frame(width: 18)
                        .foregroundStyle(isDone ? Color.green : (isAvailable ? Color.accentColor : Color.secondary))

                    VStack(alignment: .leading, spacing: 1) {
                        Text(node.name)
                            .font(.subheadline.weight(.medium))
                        if !grantText.isEmpty {
                            Text(grantText)
                                .font(.caption2)
                                .foregroundStyle(isAvailable || isDone ? Color.accentColor : Color.secondary)
                                .lineLimit(2)
                        }
                        if !row.alsoNeeds.isEmpty {
                            Text("also needs \(row.alsoNeeds.map(\.name).joined(separator: ", "))")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer(minLength: 4)

                    if row.hasChildren {
                        Button(action: toggle) {
                            Image(systemName: isCollapsed ? "chevron.right" : "chevron.down")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .frame(width: 44, height: 44)
                        }
                        .buttonStyle(.plain)
                    }
                }

                if !isDone {
                    if isAvailable && missing.isEmpty {
                        Button { store.research(node) } label: {
                            HStack(spacing: 6) {
                                Text(costText).font(.caption.monospacedDigit())
                                Spacer(minLength: 4)
                                Text("Study").font(.caption.weight(.semibold))
                            }
                            .frame(minHeight: 34)
                            .padding(.horizontal, 8)
                        }
                        .buttonStyle(.borderedProminent)
                    } else {
                        // **Not a disabled button.** A disabled bordered button is drawn at about a
                        // third contrast, so everything you were saving up for was unreadable —
                        // which is exactly the part of a tree you spend the most time reading. What
                        // you can't have yet is priced in full-contrast text; only the *status* is
                        // dimmed, and the lock icon already carries the state.
                        HStack(spacing: 6) {
                            Text(costText)
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.primary)
                            Spacer(minLength: 4)
                            Text(statusText(isAvailable: isAvailable, missing: missing))
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(isAvailable ? Color.orange : Color.secondary)
                        }
                        .frame(minHeight: 34)
                        .padding(.horizontal, 8)
                        .frame(maxWidth: .infinity)
                        .background(Color(.tertiarySystemGroupedBackground),
                                    in: RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isAvailable && !isDone ? Color.accentColor.opacity(0.5) : Color.clear,
                            lineWidth: 1.5)
            )
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private func statusText(isAvailable: Bool, missing: [String]) -> String {
        isAvailable ? "Need \(missing.joined(separator: ", "))" : "Locked"
    }

    private var grantText: String {
        row.node.grants.compactMap { grant -> String? in
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
            case .focus:
                guard let id = grant.id,
                      let focus = ContentCatalog.shared.pressureSource(PressureSourceID(rawValue: id))
                else { return nil }
                return "learn to write \(focus.name)"
            case .effect:
                return grant.effect.map(ResearchWording.describe)
            }
        }.joined(separator: " · ")
    }

    private var costText: String {
        var parts: [String] = []
        if row.node.cost.essence > 0 { parts.append("\(row.node.cost.essence) essence") }
        for (id, amount) in row.node.cost.resources.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
            parts.append("\(amount) \(ContentCatalog.shared.resource(id)?.name.lowercased() ?? id.rawValue)")
        }
        return parts.isEmpty ? "free" : parts.joined(separator: " · ")
    }
}

/// The short line from a parent's rule into its child's row.
private struct ElbowConnector: Shape {
    let isLast: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let midY = rect.minY + 20
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: midY))
        // A middle sibling's rule carries on down to the next one.
        if !isLast {
            path.move(to: CGPoint(x: rect.minX, y: midY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        }
        return path
    }
}

/// Plain words for what a node actually gives you. Shared so the outline and anything else that
/// lists grants say the same thing.
enum ResearchWording {
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
        case .analysisTier: "an instrument — you can read more off a world before you write it"
        case .companionWeapon: "+\(Tuning.Encounter.attackPerWeaponTier) companion attack"
        case .companionArmor: "+\(Tuning.Encounter.defencePerArmorTier) companion defence"
        }
    }
}
