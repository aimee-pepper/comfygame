import SwiftUI

enum GambitEditorPresentation {
    static func slotSummary(written: Int, slots: Int) -> String {
        if written <= slots {
            return "\(written)/\(slots) active"
        }
        return "\(slots) active · \(written) written"
    }

    static func addRuleLabel(written: Int, slots: Int) -> String {
        written >= slots ? "Write an idle rule" : "Write a rule"
    }

    static func placeholder(for kind: GambitComponentDef.Kind) -> String {
        switch kind {
        case .subject: "Choose who"
        case .property: "Stat"
        case .comparator: "Test"
        case .threshold: "Value"
        case .action: "Action"
        }
    }
}

/// The gambit list, in the shape FF12 got right.
///
/// **The whole priority list is visible at once**, numbered, so you read your party's logic top to
/// bottom without opening anything. **One rule is one row.** **Editing happens in place** — every
/// segment of the sentence is tappable and opens a compact picker right there, never a modal sheet
/// you have to leave the list to use. **Reordering is a drag**, because priority is positional and
/// arranging is the main act of authoring. And a rule can be **switched off** without being deleted,
/// so an order can be tested rather than rebuilt.
///
/// Our rules have five parts where FF12 had two dropdowns. That's a content decision, not a UI one,
/// so it still has to read as a single line: `Ally · HP · < · 30% → Mend`. Unset parts show as
/// placeholder chips, so a half-written rule stays readable and you can see what's missing.
///
/// Lives here and nowhere else — gambit editing is out-of-combat only, a locked decision.
struct GambitEditorView: View {
    @EnvironmentObject private var store: GameStore
    let owner: Combatant
    @State private var pendingDeletionID: InstanceID?
    @State private var writeFailure: String?

    private var gambits: [GambitRule] { store.gambits(for: owner) }
    /// **This person's list, this person's length.** Wit governs how long a rule list somebody can
    /// hold, so a sharper companion has more slots than a duller one standing next to them.
    private var slots: Int { store.activeGambitSlots(for: owner) }
    /// **By name.** Every list said "Quill's rules" whoever was holding it — written when there was
    /// one companion and left standing when the roster grew to five.
    private var person: String { store.name(of: owner.member) }
    private var ownerName: String { owner == .binder ? "Your own rules" : "\(person)'s rules" }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label("\(ownerName)", systemImage: "list.number")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Spacer()
                Text(GambitEditorPresentation.slotSummary(written: gambits.count, slots: slots))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            Text("Checked top to bottom. The first rule that fits is the one that fires.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button {
                if store.addBlankGambit(for: owner) {
                    writeFailure = nil
                } else {
                    writeFailure = "No owned subject and action are available for a new rule."
                }
            } label: {
                Label(
                    GambitEditorPresentation.addRuleLabel(written: gambits.count, slots: slots),
                    systemImage: "plus.circle"
                )
                    .font(.caption)
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.bordered)
            .disabled(!store.canEditGambits)

            if !store.canEditGambits {
                Text("Rules can be changed at Home between expeditions.")
                    .font(.caption2)
                    .foregroundStyle(.orange)
            }

            if gambits.isEmpty {
                EmptyNote(owner == .binder
                          ? "No rules written — you'll keep acting for yourself."
                          : "No rules written — \(person) will stand there.")
            } else {
                List {
                    ForEach(Array(gambits.enumerated()), id: \.element.id) { index, rule in
                        GambitRow(index: index, rule: rule, isInSlot: index < slots, owner: owner)
                            .swipeActions(edge: .trailing) {
                                Button("Delete", role: .destructive) {
                                    pendingDeletionID = rule.id
                                }
                            }
                            .listRowInsets(EdgeInsets(top: 2, leading: 0, bottom: 2, trailing: 0))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                    }
                    // No `.onDelete`: with edit mode active it would put a red minus in front of
                    // every rule, crowding out the sentence that is the point of the row. Deleting
                    // is a swipe, which is where a phone user looks for it anyway.
                    .onMove { store.moveGambit(from: $0, to: $1, for: owner) }
                }
                .listStyle(.plain)
                .environment(\.editMode, .constant(.active))
                .frame(height: CGFloat(gambits.count) * 48 + 8)
                .scrollDisabled(true)
                .disabled(!store.canEditGambits)
            }

            if gambits.count > slots {
                Text("Rules past slot \(slots) are written but idle.")
                    .font(.caption2)
                    .foregroundStyle(.orange)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
        .alert(deletionTitle, isPresented: Binding(
            get: { pendingDeletionID != nil },
            set: { if !$0 { pendingDeletionID = nil } }
        )) {
            Button("Cancel", role: .cancel) { pendingDeletionID = nil }
            Button("Delete rule", role: .destructive) { confirmDeletion() }
        } message: {
            Text(deletionMessage)
        }
        .alert("Rule not written", isPresented: Binding(
            get: { writeFailure != nil },
            set: { if !$0 { writeFailure = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(writeFailure ?? "A new rule could not be written.")
        }
    }

    private var pendingDeletion: (index: Int, rule: GambitRule)? {
        guard let pendingDeletionID,
              let index = gambits.firstIndex(where: { $0.id == pendingDeletionID }) else { return nil }
        return (index, gambits[index])
    }

    private var deletionTitle: String {
        guard let pendingDeletion else { return "Delete rule?" }
        return "Delete rule \(pendingDeletion.index + 1)?"
    }

    private var deletionMessage: String {
        pendingDeletion?.rule.displayText ?? "This rule is no longer present."
    }

    private func confirmDeletion() {
        guard let pendingDeletion else { pendingDeletionID = nil; return }
        pendingDeletionID = nil
        store.removeGambit(at: IndexSet(integer: pendingDeletion.index), for: owner)
    }
}

/// One rule, one row: a numbered, tappable sentence.
private struct GambitRow: View {
    @EnvironmentObject private var store: GameStore
    let index: Int
    let rule: GambitRule
    let isInSlot: Bool
    let owner: Combatant

    private var isLive: Bool { isInSlot && rule.isEnabled }

    var body: some View {
        HStack(spacing: 6) {
            Button {
                store.setGambitEnabled(rule.id, !rule.isEnabled, for: owner)
            } label: {
                Text("\(index + 1)")
                    .font(.caption2.monospacedDigit().weight(.bold))
                    .foregroundStyle(rule.isEnabled ? Color.accentColor : Color.secondary)
                    .frame(width: 26, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(rule.isEnabled ? "Rule \(index + 1), on. Tap to switch off."
                                               : "Rule \(index + 1), off. Tap to switch on.")

            // **One rule, one row.** The sentence scrolls sideways rather than wrapping, so every
            // rule is the same height and the list reads as a numbered priority order at a glance —
            // which is the whole reason for looking at it.
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    segment(.subject, current: rule.subject, required: true)
                    if rule.isFoeArmourRule {
                        armourMarkSegment
                    } else {
                        segment(.property, current: rule.property)
                        segment(.comparator, current: rule.comparator)
                        segment(.threshold, current: rule.threshold)
                    }
                    Text("→").font(.caption2).foregroundStyle(.secondary)
                    segment(.action, current: rule.action, required: true)
                }
                .padding(.trailing, 8)
            }
            .opacity(isLive ? 1 : 0.45)
        }
        .frame(height: 44)
    }

    private var armourMarkSegment: some View {
        let options = store.ownedComponents(.threshold).filter {
            FoeArmourGambit.markIDs.contains($0.id)
        }
        let name = rule.threshold.flatMap { FoeArmourGambit.mark(for: $0) }.map(String.init)

        return Menu {
            ForEach(options) { option in
                Button(option.name) {
                    // The specialised grammar fixes property/current armour and comparator/above.
                    // Clear stale generic pieces before setting its one explicit mark.
                    store.setGambitPart(rule.id, kind: .property, to: nil, for: owner)
                    store.setGambitPart(rule.id, kind: .comparator, to: nil, for: owner)
                    store.setGambitPart(rule.id, kind: .threshold, to: option.id, for: owner)
                }
            }
        } label: {
            Text(name.map { "Armour mark \($0)" } ?? "Choose armour mark")
                .font(.caption2.weight(name == nil ? .regular : .medium))
                .foregroundStyle(name == nil ? Color.secondary : Color.primary)
                .lineLimit(1)
                .padding(.horizontal, 7)
                .frame(height: 30)
                .background(name == nil ? Color(.tertiarySystemFill) : Color(.secondarySystemFill),
                            in: Capsule())
        }
        .disabled(options.isEmpty)
    }

    /// One tappable part of the sentence. A `Menu` keeps the list on screen — this is the "editing
    /// in place" requirement, and it's why there's no sheet anywhere in this file.
    private func segment(_ kind: GambitComponentDef.Kind,
                         current: GambitComponentID?,
                         required: Bool = false) -> some View {
        let options = store.ownedComponents(kind)
        let name = current.flatMap { ContentCatalog.shared.gambitComponent($0)?.name }

        return Menu {
            ForEach(options) { option in
                Button(option.name) { store.setGambitPart(rule.id, kind: kind, to: option.id, for: owner) }
            }
            if !required {
                Divider()
                Button("Any — no condition") {
                    store.setGambitPart(rule.id, kind: kind, to: nil, for: owner)
                }
            }
        } label: {
            Text(name ?? GambitEditorPresentation.placeholder(for: kind))
                .font(.caption2.weight(name == nil ? .regular : .medium))
                .foregroundStyle(name == nil ? Color.secondary : Color.primary)
                .lineLimit(1)
                .padding(.horizontal, 7)
                .frame(height: 30)
                .background(name == nil ? Color(.tertiarySystemFill) : Color(.secondarySystemFill),
                            in: Capsule())
        }
        .disabled(options.isEmpty)
    }
}
