import SwiftUI

/// The Blacksmith: where the piece you already carry gets better.
///
/// The screen has one job, and it's a question the player arrives with: *what should I put my
/// materials into?* So it lists everything reforgeable — worn and stored, both party members — and
/// each row says the price and whether you can pay it, without you having to open anything.
struct BlacksmithView: View {
    @EnvironmentObject private var store: GameStore
    @State private var chosen: ReforgeTarget?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    CurrencyChip(icon: "drop.fill", label: "Essence",
                                 value: "\(store.state.base.essence)", tint: .teal)
                    CurrencyChip(icon: "shippingbox", label: "Stock",
                                 value: "\(store.materialSampleCount)")
                }

                StationCard(title: "At the anvil", icon: "hammer.fill") {
                    Text("Reforging asks for stock with the right quality in it, never for a named thing. A monstrous plate does a blade as much good as ore does — what matters is how hard it is.")
                        .font(.caption).foregroundStyle(.secondary)
                }

                if store.reforgeable.isEmpty {
                    StationCard(title: "Nothing to work on", icon: "questionmark") {
                        EmptyNote("Bring back something to wear, and something hard to work it with.")
                    }
                } else {
                    StationCard(title: "Gear", icon: "shield.lefthalf.filled") {
                        ForEach(store.reforgeable) { target in
                            ReforgeRow(target: target) { chosen = target }
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Blacksmith")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $chosen) { target in
            ReforgeSheet(target: target).environmentObject(store)
        }
    }
}

/// One piece and what the next step up would cost.
private struct ReforgeRow: View {
    @EnvironmentObject private var store: GameStore
    let target: ReforgeTarget
    let tap: () -> Void

    var body: some View {
        let requirement = SmithRules.requirement(for: target.catalogID, at: target.upgradeLevel)
        let readiness = store.readiness(of: target)

        Button(action: tap) {
            HStack(spacing: 10) {
                Image(systemName: target.icon)
                    .foregroundStyle(target.rarity.tint)
                    .frame(width: 22)
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 6) {
                        Text(target.displayName)
                            .font(.callout.weight(.medium))
                            .foregroundStyle(target.rarity.tint)
                        if target.count > 1 {
                            Text("×\(target.count)")
                                .font(.caption2.monospacedDigit()).foregroundStyle(.secondary)
                        }
                        // Worn pieces are reforged in place, so it has to be obvious which one of
                        // the two identical blades on this screen is the one you're carrying.
                        if let wearer = target.wearer {
                            Text(wearer)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Color(.tertiarySystemFill), in: Capsule())
                        }
                    }
                    if let requirement {
                        Text("\(requirement.summary) · \(requirement.essence) essence")
                            .font(.caption2).foregroundStyle(.secondary)
                    } else {
                        Text("As far as it goes.")
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 6)
                ReadinessChip(readiness: readiness)
                if requirement != nil {
                    Image(systemName: "chevron.right")
                        .font(.caption2).foregroundStyle(.tertiary)
                }
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(requirement == nil)
    }
}

/// Says in one chip whether you can pay, and if not, exactly what's short — the difference between
/// a greyed-out button and knowing to go and find two more hard things.
private struct ReadinessChip: View {
    let readiness: SmithRules.Readiness

    var body: some View {
        switch readiness {
        case .ready:
            chip("+1 tier", .green)
        case .finished:
            chip("finished", .secondary)
        case .needsMaterials(let have, let need):
            chip("\(have)/\(need) stock", .orange)
        case .needsEssence(let have, let need):
            chip("\(have)/\(need) essence", .orange)
        }
    }

    private func chip(_ text: String, _ tint: Color) -> some View {
        Text(text)
            .font(.caption2.weight(.medium))
            .foregroundStyle(tint)
            .padding(.horizontal, 7).padding(.vertical, 3)
            .background(tint.opacity(0.14), in: Capsule())
    }
}

/// The confirmation: what it costs, **which samples it would take**, and what you get.
///
/// Naming the exact samples matters — the smith spends the worst thing that clears the bar, and
/// seeing that written down is what makes it safe to keep your best pelt in the same bin.
private struct ReforgeSheet: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss
    let target: ReforgeTarget

    var body: some View {
        NavigationStack {
            List {
                if let requirement = SmithRules.requirement(for: target.catalogID,
                                                            at: target.upgradeLevel) {
                    let spending = Array(
                        SmithRules.candidates(for: requirement, in: store.state)
                            .prefix(requirement.count)
                    )

                    Section {
                        LabeledRow(icon: target.icon, label: target.displayName,
                                   value: "tier \(target.effectiveTier)", tint: target.rarity.tint)
                        LabeledRow(icon: "arrow.up.circle", label: "Becomes",
                                   value: "tier \(target.effectiveTier + 1)")
                        if let wearer = target.wearer {
                            LabeledRow(icon: "person.fill", label: "Worn by", value: wearer)
                        }
                    } header: {
                        Text("Reforging")
                    } footer: {
                        Text(effectText)
                    }

                    Section {
                        LabeledRow(icon: requirement.property.icon,
                                   label: "\(requirement.property.displayName) of at least",
                                   value: "\(Int(requirement.minimum))")
                        LabeledRow(icon: "drop.fill", label: "Essence",
                                   value: "\(requirement.essence)")
                    } header: {
                        Text("Asks for")
                    }

                    Section {
                        if spending.isEmpty {
                            EmptyNote("Nothing you're holding is \(requirement.property.stockWord) enough.")
                                .frame(minHeight: 44)
                        }
                        ForEach(Array(spending.enumerated()), id: \.offset) { _, candidate in
                            HStack(spacing: 10) {
                                Image(systemName: candidate.sample.kind.icon)
                                    .font(.footnote).frame(width: 20)
                                    .foregroundStyle(candidate.sample.rarity.tint)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(candidate.sample.displayName)
                                        .font(.callout)
                                        .foregroundStyle(candidate.sample.rarity.tint)
                                    if !candidate.sample.source.isEmpty {
                                        Text("off a \(candidate.sample.source)")
                                            .font(.caption2).foregroundStyle(.secondary)
                                    }
                                }
                                Spacer(minLength: 8)
                                Text("\(Int(candidate.value))")
                                    .font(.callout.monospacedDigit()).foregroundStyle(.secondary)
                            }
                            .frame(minHeight: 44)
                        }
                    } header: {
                        Text("Would take \(spending.count) of \(requirement.count)")
                    } footer: {
                        Text("The worst stock that clears the bar goes in first. Your best is left where it is.")
                    }

                    Section {
                        Button {
                            store.reforge(target)
                            dismiss()
                        } label: {
                            Text("Reforge")
                                .frame(maxWidth: .infinity, minHeight: 44)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!store.readiness(of: target).isReady)
                    }
                }
            }
            .navigationTitle("The anvil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
        }
    }

    /// What the extra tier is actually worth in the fight, in the fight's own units — the same
    /// promise the gear picker makes.
    private var effectText: String {
        guard let slot = target.definition?.gear?.slot else { return "" }
        let step = slot == .weapon
            ? Tuning.Encounter.attackPerWeaponTier
            : Tuning.Encounter.defencePerArmorTier
        let unit = slot == .weapon ? "damage" : "protection"
        return "+\(step) \(unit). This exact piece keeps it — reforging is per object, not per kind."
    }
}
