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
    @State private var selectedOption: GameStore.WearableGearOption?

    private var worn: EquippedPiece? { store.worn(slot, by: member) }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Worn now").font(.headline)
                    if let worn, let definition = worn.definition {
                        tile(piece: worn, definition: definition, delta: nil, count: 1,
                             location: "Worn", enabled: true)
                    } else {
                        Text("Nothing worn.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .frame(minHeight: 44)
                    }
                    Text("Your \(slot.displayName.lowercased())").font(.headline)
                    let options = candidates
                    if options.isEmpty {
                        Text("You don't own another \(slot.displayName.lowercased()) yet. Sites hold better pieces — ruins especially.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(minHeight: 44)
                    }
                    SixAcrossItemGrid(data: options, id: \.id) { option in
                        Button { selectedOption = option } label: {
                            ItemIconTile(icon: option.piece.definition?.icon ?? "questionmark",
                                         rarity: option.piece.definition?.rarity ?? .common,
                                         quantity: option.count, identified: true,
                                         location: gridLocation(of: option),
                                         accessibilityName: option.piece.displayName,
                                         isEnabled: option.canEquipAtHome)
                        }
                        .buttonStyle(.plain)
                    }

                    if worn != nil {
                        Button("Take it off", role: .destructive) {
                            store.unequip(slot, from: member)
                            dismiss()
                        }
                        .frame(minHeight: 44)
                        .buttonStyle(.bordered)
                    }
                }
                .padding()
            }
            .navigationTitle(slot.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(item: $selectedOption) { option in
                GearOptionDetailSheet(
                    option: option, slot: slot, location: location(of: option),
                    delta: store.gearDelta(wearing: option.piece, for: member),
                    equip: {
                        guard store.equip(option, on: member) else { return false }
                        selectedOption = nil
                        dismiss()
                        return true
                    })
            }
        }
    }

    /// **Every distinct piece on the shelf, best first, with how many of it you have.**
    ///
    /// Bins are per (piece, upgrade level), so four identical guards are one row saying ×4 and a
    /// reforged one is its own row — which is exactly what makes "give the best to me and the
    /// second best to Quill" a choice you can make (Aimee, 6 Aug). Nothing is filtered out for
    /// being worn by somebody else: if you have four, you can wear four.
    private var candidates: [GameStore.WearableGearOption] {
        store.wearableOptions(in: slot, excluding: member)
            .sorted { $0.piece.effectivePower > $1.piece.effectivePower }
    }

    private func location(of option: GameStore.WearableGearOption) -> String {
        switch option.source {
        case .stored: "Stored"
        case .overflow: "Waiting to sort"
        case .worn(let owner): "Worn by \(store.name(of: owner))"
        case .carried: "Carried in world"
        }
    }

    private func gridLocation(of option: GameStore.WearableGearOption) -> ItemGridLocation {
        switch option.source {
        case .stored: .stored
        case .overflow: .waiting
        case .worn: .worn
        case .carried: .carried
        }
    }

    private func tile(piece: EquippedPiece, definition: ItemDef?, delta: Int?, count: Int,
                      location: String, enabled: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Image(systemName: definition?.icon ?? "questionmark")
                    .font(.title2)
                    .foregroundStyle(definition?.rarity.tint ?? .secondary)
                Spacer()
                Text(location)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(enabled ? Color.secondary : Color.orange)
            }
            VStack(alignment: .leading, spacing: 3) {
                // Rarity reads as the colour of the name — the ladder from the design brief.
                HStack(spacing: 6) {
                    Text(piece.displayName)
                        .font(.callout.weight(.medium))
                        .foregroundStyle(definition?.rarity.tint ?? .primary)
                    // How many of this exact piece you hold, so "the best one to me, the next to
                    // Quill" is a decision you can see rather than guess at.
                    if count > 1 {
                        Text("×\(count)").font(.caption2.monospacedDigit()).foregroundStyle(.secondary)
                    }
                }
                Text(definition.flatMap(damageLine) ?? definition?.blurb ?? "Unknown equipment")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            if let delta {
                ImprovementBadge(delta: delta, slot: slot)
            } else {
                Text("worn").font(.caption2).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 112, alignment: .topLeading)
        .padding(12)
        .background(.secondary.opacity(0.10), in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(.secondary.opacity(0.18)))
        .contentShape(RoundedRectangle(cornerRadius: 14))
        .opacity(enabled ? 1 : 0.72)
    }

    /// A weapon's corner and reach, because that's the matchup read — a blurb won't tell you
    /// whether this is any use against the plated thing you keep meeting.
    private func damageLine(_ definition: ItemDef) -> String? {
        guard let gear = definition.gear, let damage = gear.damage else { return nil }
        let reach = gear.reach == .close ? "" : " · \(gear.reach.rawValue) reach"
        return "\(damage.rawValue)\(reach)"
    }
}

private struct GearOptionDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let option: GameStore.WearableGearOption
    let slot: GearSlot
    let location: String
    let delta: Int
    let equip: () -> Bool

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 16) {
                        ItemIconTile(icon: option.piece.definition?.icon ?? "questionmark",
                                     rarity: option.piece.definition?.rarity ?? .common,
                                     quantity: option.count, identified: true,
                                     location: gridLocation,
                                     accessibilityName: option.piece.displayName)
                            .frame(width: 58, height: 58)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(option.piece.displayName).font(.headline)
                            Text(location).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                Section("Equipment") {
                    LabeledContent("Location", value: location)
                    LabeledContent("Quantity", value: "\(option.count)")
                    LabeledContent("Power", value: String(format: "%.1f", option.piece.effectivePower))
                    if let profile = option.piece.gearProfile {
                        LabeledContent("Tier", value: "\(profile.constructionTier)")
                        LabeledContent("Reforge", value: "\(profile.reforgeRank) of 3")
                        if let provenance = profile.displayProvenance {
                            LabeledContent("Provenance", value: provenance)
                        }
                    }
                    ImprovementBadge(delta: delta, slot: slot)
                }
                Section {
                    Button("Equip") { _ = equip() }
                        .disabled(!option.canEquipAtHome)
                    if !option.canEquipAtHome {
                        Text("Carried gear can be changed after you return home.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle(option.piece.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } }
            }
        }
    }

    private var gridLocation: ItemGridLocation {
        switch option.source {
        case .stored: .stored
        case .overflow: .waiting
        case .worn: .worn
        case .carried: .carried
        }
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
