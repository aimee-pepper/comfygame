import SwiftUI

/// **Where you spend, which is what a class is.**
///
/// Nine branches shared by everybody (`docs/combat-trees-full.md`). Nobody is handed a role: a
/// rogue is Swiftness, Evasion and Shadow, and a knight is Force, Fortitude and Kindling, and the
/// game never says either word until you've finished three.
///
/// One tree at a time on a phone, because three columns of eight nodes is not a portrait layout.
struct CombatTreeView: View {
    @EnvironmentObject private var store: GameStore
    let member: PartyMember
    @State private var tree: CombatTreeID?

    private var character: CharacterState { store.character(of: member) }
    private var unspent: Int { CombatTreeRules.unspentPoints(character) }

    private var openTree: CombatTreeDef? {
        ContentCatalog.shared.combatTrees.first { $0.id == tree } ?? ContentCatalog.shared.combatTrees.first
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            treePicker
            ScrollView {
                VStack(spacing: 12) {
                    if let openTree {
                        ForEach(openTree.branches) { branch in
                            branchCard(branch)
                        }
                    }
                }
                .padding(16)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Training")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 1) {
                Text(store.name(of: member)).font(.callout.weight(.semibold))
                Text(CombatTreeRules.className(for: character)
                     ?? "Level \(character.level) · nothing decided yet")
                    .font(.caption2).foregroundStyle(.secondary)
            }
            Spacer(minLength: 6)
            Text(unspent == 1 ? "1 point" : "\(unspent) points")
                .font(.caption.weight(.semibold))
                .foregroundStyle(unspent > 0 ? Color.accentColor : .secondary)
                .padding(.horizontal, 9).padding(.vertical, 4)
                .background((unspent > 0 ? Color.accentColor : Color.secondary).opacity(0.14),
                            in: Capsule())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.bar)
    }

    private var treePicker: some View {
        Picker("", selection: Binding(
            get: { openTree?.id ?? ContentCatalog.shared.combatTrees[0].id },
            set: { tree = $0 })) {
            ForEach(ContentCatalog.shared.combatTrees) { Text($0.name).tag($0.id) }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 12)
        .padding(.top, 6)
    }

    private func branchCard(_ branch: CombatBranchDef) -> some View {
        let depth = CombatTreeRules.depth(of: branch.id, in: character)
        let canBuy = CombatTreeRules.canBuyNext(in: branch, for: character)
        return StationCard(title: "\(branch.name) — \(depth) of \(branch.nodes.count)",
                           icon: branch.icon) {
            Text(branch.blurb)
                .font(.caption2).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(Array(branch.nodes.enumerated()), id: \.offset) { item in
                nodeRow(item.element, bought: item.offset < depth, isNext: item.offset == depth)
            }

            if canBuy {
                Button {
                    store.spendPoint(in: branch.id, for: member)
                } label: {
                    Text("Learn \(branch.nodes[depth].name)")
                        .font(.caption.weight(.semibold))
                        .frame(maxWidth: .infinity).frame(minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
            } else if depth == branch.nodes.count {
                Text("Finished.").font(.caption2).foregroundStyle(.green)
            } else if unspent == 0 {
                Text("Nothing left to spend.").font(.caption2).foregroundStyle(.tertiary)
            }
        }
    }

    /// Bought nodes read plainly; the next one is offered; everything past it is dimmed but
    /// **visible** — you should be able to see what committing to a branch would eventually get you,
    /// because that is the decision.
    private func nodeRow(_ node: CombatNodeDef, bought: Bool, isNext: Bool) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: bought ? "checkmark.circle.fill"
                                     : (isNext ? "circle" : "circle.dotted"))
                .font(.caption)
                .foregroundStyle(bought ? Color.green : (isNext ? Color.accentColor : Color.tertiaryLabel))
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 5) {
                    Text(node.name).font(.caption.weight(bought || isNext ? .medium : .regular))
                    if node.grantsSkill != nil {
                        Image(systemName: "sparkles").font(.system(size: 8)).foregroundStyle(.orange)
                    }
                    if node.index == 8 {
                        Text("capstone").font(.system(size: 8).weight(.semibold))
                            .foregroundStyle(.purple)
                    }
                }
                Text(node.blurb)
                    .font(.system(size: 10)).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .opacity(bought || isNext ? 1 : 0.45)
        .frame(minHeight: 30)
    }
}

private extension ShapeStyle where Self == Color {
    static var tertiaryLabel: Color { Color(.tertiaryLabel) }
}
