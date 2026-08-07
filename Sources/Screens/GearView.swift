import SwiftUI

/// Choosing what to wear, and being told whether it's better.
///
/// Gear is **found, never researched** (decisions-session-12), so this is a picker over what you've
/// hauled home — and the thing it most has to answer is the question you actually have standing in
/// front of it: *is this an improvement?* A tier number doesn't answer that unless you already know
/// the formula, so every option states the difference it would make in the units the fight uses.
struct GearView: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss
    let slot: GearSlot
    let member: PartySlot

    private var worn: EquippedPiece? { store.worn(slot, by: member) }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if let worn, let definition = worn.definition {
                        row(stack: nil, definition: definition, name: worn.displayName,
                            delta: nil, count: 1)
                    } else {
                        Text("Nothing worn.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .frame(minHeight: 44)
                    }
                } header: {
                    Text("Worn")
                }

                Section {
                    let options = candidates
                    if options.isEmpty {
                        Text("Nothing else to wear. Sites hold the better pieces — ruins especially.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(minHeight: 44)
                    }
                    ForEach(options, id: \.stack.id) { option in
                        Button {
                            store.equip(option.stack, on: member)
                            dismiss()
                        } label: {
                            row(stack: option.stack, definition: option.definition,
                                name: option.stack.displayName,
                                delta: store.gearDelta(wearing: option.stack, for: member),
                                count: option.stack.count)
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("In the storehouse")
                }

                if worn != nil {
                    Section {
                        Button("Take it off", role: .destructive) {
                            store.unequip(slot, from: member)
                            dismiss()
                        }
                        .frame(minHeight: 44)
                    }
                }
            }
            .navigationTitle(slot.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    /// **Every distinct piece on the shelf, best first, with how many of it you have.**
    ///
    /// Bins are per (piece, upgrade level), so four identical guards are one row saying ×4 and a
    /// reforged one is its own row — which is exactly what makes "give the best to me and the
    /// second best to Quill" a choice you can make (Aimee, 6 Aug). Nothing is filtered out for
    /// being worn by somebody else: if you have four, you can wear four.
    private var candidates: [(stack: ItemStack, definition: ItemDef)] {
        store.wearable(in: slot)
            .compactMap { stack in
                ContentCatalog.shared.item(stack.catalogID).map { (stack, $0) }
            }
            .sorted { $0.stack.effectiveTier > $1.stack.effectiveTier }
    }

    private func row(stack: ItemStack?, definition: ItemDef, name: String,
                     delta: Int?, count: Int) -> some View {
        HStack(spacing: 10) {
            Image(systemName: definition.icon)
                .foregroundStyle(definition.rarity.tint)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 1) {
                // Rarity reads as the colour of the name — the ladder from the design brief.
                HStack(spacing: 6) {
                    Text(name)
                        .font(.callout.weight(.medium))
                        .foregroundStyle(definition.rarity.tint)
                    // How many of this exact piece you hold, so "the best one to me, the next to
                    // Quill" is a decision you can see rather than guess at.
                    if count > 1 {
                        Text("×\(count)").font(.caption2.monospacedDigit()).foregroundStyle(.secondary)
                    }
                }
                Text(damageLine(definition) ?? definition.blurb)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer(minLength: 6)
            if let delta {
                ImprovementBadge(delta: delta, slot: slot)
            } else {
                Text("worn").font(.caption2).foregroundStyle(.secondary)
            }
        }
        .frame(minHeight: 44)
        .contentShape(Rectangle())
    }

    /// A weapon's corner and reach, because that's the matchup read — a blurb won't tell you
    /// whether this is any use against the plated thing you keep meeting.
    private func damageLine(_ definition: ItemDef) -> String? {
        guard let gear = definition.gear, let damage = gear.damage else { return nil }
        let reach = gear.reach == .close ? "" : " · \(gear.reach.rawValue) reach"
        return "\(damage.rawValue)\(reach)"
    }
}

/// Says, in one chip, whether putting this on is a good idea.
struct ImprovementBadge: View {
    let delta: Int
    let slot: GearSlot

    private var unit: String { slot == .weapon ? "damage" : "protection" }

    var body: some View {
        if delta > 0 {
            label("+\(delta) \(unit)", .green)
        } else if delta < 0 {
            label("\(delta) \(unit)", .red)
        } else {
            label("no change", .secondary)
        }
    }

    private func label(_ text: String, _ tint: Color) -> some View {
        Text(text)
            .font(.caption2.weight(.medium))
            .foregroundStyle(tint)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(tint.opacity(0.14), in: Capsule())
    }
}
