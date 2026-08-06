import SwiftUI

/// The battle screen: party left, foes right, action bar in the thumb zone.
///
/// **No gambit editing here** — a locked decision. You can hand the companion's next turn to
/// yourself, but you cannot rewrite its rules mid-fight; that happens on the Party screen, between
/// fights, where it's a considered decision rather than a panic button.
struct EncounterView: View {
    @EnvironmentObject private var store: GameStore
    @State private var targetingAction: TargetingMode?

    private var run: WorldRun? { store.state.worlds.activeRun }
    private var encounter: EncounterState? { store.activeEncounter }

    private enum TargetingMode: Equatable { case attack, damageSkill, item(InstanceID) }

    var body: some View {
        VStack(spacing: 0) {
            if let run, let encounter {
                header(encounter)
                combatants(run, encounter)
                // Log sits directly under the fight it describes; the slack goes below it, so the
                // action bar still lands in the thumb zone without stranding the text mid-screen.
                battleLog(encounter)
                Spacer(minLength: 0)
                if let outcome = encounter.outcome {
                    outcomeBar(outcome)
                } else {
                    actionBar(run, encounter)
                }
            }
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: Header

    private func header(_ encounter: EncounterState) -> some View {
        HStack {
            Text("Round \(encounter.roundNumber)")
                .font(.headline.monospacedDigit())
            Spacer()
            Text(turnText(encounter))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.bar)
    }

    private func turnText(_ encounter: EncounterState) -> String {
        if encounter.outcome != nil { return "" }
        switch encounter.current {
        case .binder: return "your move"
        case .companion: return encounter.isCompanionOverridden ? "you're directing Quill" : "Quill is acting"
        case .foe: return "…"
        }
    }

    // MARK: Combatants

    private func combatants(_ run: WorldRun, _ encounter: EncounterState) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 10) {
                PartyCard(actor: .binder,
                          name: "You",
                          icon: "figure.stand",
                          health: CombatRules.health(of: .binder, in: run),
                          isActing: encounter.current == .binder && encounter.outcome == nil,
                          badge: nil)

                PartyCard(actor: .companion,
                          name: store.state.base.companion.name,
                          icon: "person.fill",
                          health: CombatRules.health(of: .companion, in: run),
                          isActing: encounter.current == .companion && encounter.outcome == nil,
                          badge: encounter.isCompanionOverridden ? "manual" : "auto")
                    .onTapGesture { store.toggleCompanionOverride() }
                    .overlay(alignment: .bottom) {
                        Text(encounter.isCompanionOverridden ? "tap: back to gambits" : "tap: take over next turn")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .offset(y: 16)
                    }
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: 8) {
                ForEach(encounter.foes) { foe in
                    FoeCard(foe: foe,
                            isActing: encounter.current == .foe(foe.id) && encounter.outcome == nil,
                            isTargetable: targetingAction != nil && foe.isAlive)
                        .onTapGesture { tapFoe(foe) }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 24)
    }

    private func tapFoe(_ foe: FoeState) {
        guard let mode = targetingAction, foe.isAlive else { return }
        switch mode {
        case .attack: store.takeCombatAction(.attack(foe: foe.id))
        case .damageSkill: store.takeCombatAction(.damageSkill(foe: foe.id))
        case .item: break // items target allies, handled in the bar
        }
        targetingAction = nil
    }

    // MARK: Log

    private func battleLog(_ encounter: EncounterState) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(Array(encounter.log.suffix(3).enumerated()), id: \.offset) { index, line in
                Text(line)
                    .font(.caption)
                    .foregroundStyle(index == encounter.log.suffix(3).count - 1 ? .primary : .secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, minHeight: 62, alignment: .bottomLeading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 12)
    }

    // MARK: Action bar

    @ViewBuilder
    private func actionBar(_ run: WorldRun, _ encounter: EncounterState) -> some View {
        VStack(spacing: 8) {
            if let mode = targetingAction {
                HStack {
                    Text(mode == .attack ? "Choose a target." : "Choose a target for \(store.currentSkill?.name ?? "your skill").")
                        .font(.footnote)
                    Spacer()
                    Button("Cancel") { targetingAction = nil }
                        .font(.footnote.weight(.semibold))
                }
                .frame(minHeight: 44)
            } else if store.actingCombatant != nil {
                HStack(spacing: 8) {
                    ActionKey("Attack", icon: "figure.fencing") { beginTargeting(.attack) }
                    ActionKey(store.currentSkill?.name ?? "Skill",
                              icon: store.currentSkill?.icon ?? "sparkles",
                              detail: skillDetail(encounter),
                              isEnabled: store.isSkillReady) { useSkill() }
                }
                HStack(spacing: 8) {
                    ActionKey("Item", icon: "cross.vial",
                              detail: store.usableItems.isEmpty ? "none carried" : "\(store.usableItems.count)",
                              isEnabled: !store.usableItems.isEmpty) { useFirstItem() }
                    ActionKey("Flee", icon: "figure.run",
                              detail: "−\(Int(Tuning.Encounter.fleeStabilityCost)) stability",
                              isDestructive: true) { store.takeCombatAction(.flee) }
                }
            } else {
                Text("…")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 6)
        .background(.bar)
    }

    private func skillDetail(_ encounter: EncounterState) -> String? {
        guard let actor = store.actingCombatant else { return nil }
        let cooldown = CombatRules.skillCooldown(for: actor, in: encounter)
        return cooldown > 0 ? "\(cooldown) round\(cooldown == 1 ? "" : "s")" : nil
    }

    private func beginTargeting(_ mode: TargetingMode) {
        guard let encounter, encounter.livingFoes.count > 1 else {
            // One foe left: no decision to make, so don't make them tap twice.
            if let only = encounter?.livingFoes.first {
                switch mode {
                case .attack: store.takeCombatAction(.attack(foe: only.id))
                case .damageSkill: store.takeCombatAction(.damageSkill(foe: only.id))
                case .item: break
                }
            }
            return
        }
        targetingAction = mode
    }

    private func useSkill() {
        guard let skill = store.currentSkill else { return }
        switch skill.kind {
        case .damage: beginTargeting(.damageSkill)
        case .heal: store.takeCombatAction(.healSkill(ally: weakestAlly()))
        }
    }

    private func useFirstItem() {
        guard let stack = store.usableItems.first else { return }
        store.takeCombatAction(.useItem(stack: stack.id, ally: weakestAlly()))
    }

    /// Healing goes to whoever needs it most — the obvious intent, and one fewer tap.
    private func weakestAlly() -> Combatant {
        guard let run else { return .binder }
        let binder = CombatRules.health(of: .binder, in: run)
        let companion = CombatRules.health(of: .companion, in: run)
        let binderShare = Double(binder.current) / Double(max(1, binder.max))
        let companionShare = Double(companion.current) / Double(max(1, companion.max))
        return binderShare <= companionShare ? .binder : .companion
    }

    // MARK: Outcome

    private func outcomeBar(_ outcome: EncounterOutcome) -> some View {
        VStack(spacing: 6) {
            Text(outcomeText(outcome))
                .font(.headline)
                .foregroundStyle(outcome == .victory ? .green : .orange)
            // **What you won.** Rolled at the moment of victory precisely so this screen could
            // report it — and until now nothing did, so every fight paid out invisibly.
            let spoils = encounter?.spoils ?? []
            if !spoils.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(spoils, id: \.self) { line in
                        Label(line, systemImage: "plus.circle.fill")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.bottom, 2)
            }
            Button {
                store.endEncounterIfFinished()
            } label: {
                Text(outcome == .defeated ? "Be carried home" : "Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 52)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(.bar)
    }

    private func outcomeText(_ outcome: EncounterOutcome) -> String {
        switch outcome {
        case .victory: "Nothing left standing."
        case .fled: "You break away."
        case .defeated: "You can't go on."
        }
    }
}

// MARK: - Cards

private struct PartyCard: View {
    let actor: Combatant
    let name: String
    let icon: String
    let health: (current: Int, max: Int)
    let isActing: Bool
    let badge: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(name).font(.subheadline.weight(.semibold)).lineLimit(1)
                Spacer(minLength: 0)
                if let badge {
                    Text(badge)
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Color(.tertiarySystemFill), in: Capsule())
                }
            }
            HealthBar(current: health.current, max: health.max, tint: .green)
        }
        .padding(10)
        .frame(minHeight: 60)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(isActing ? Color.accentColor : .clear, lineWidth: 2)
        )
        .opacity(health.current > 0 ? 1 : 0.4)
    }
}

private struct FoeCard: View {
    let foe: FoeState
    let isActing: Bool
    let isTargetable: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: foe.stats.icon)
                Text(foe.stats.displayName).font(.subheadline.weight(.semibold)).lineLimit(1)
                Spacer(minLength: 0)
            }
            HealthBar(current: foe.currentHP, max: foe.maxHP, tint: .red)
        }
        .padding(10)
        .frame(minHeight: 60)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(borderColour, lineWidth: isTargetable ? 2.5 : 2)
        )
        .opacity(foe.isAlive ? 1 : 0.35)
    }

    private var borderColour: Color {
        if isTargetable { return .accentColor }
        return isActing ? .red : .clear
    }
}

private struct HealthBar: View {
    let current: Int
    let max: Int
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(.tertiarySystemFill))
                    Capsule().fill(tint)
                        .frame(width: proxy.size.width * Double(current) / Double(Swift.max(1, max)))
                }
            }
            .frame(height: 6)
            Text("\(current) / \(max)")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }
}

private struct ActionKey: View {
    let title: String
    let icon: String
    var detail: String?
    var isEnabled: Bool = true
    var isDestructive: Bool = false
    let action: () -> Void

    init(_ title: String, icon: String, detail: String? = nil,
         isEnabled: Bool = true, isDestructive: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.detail = detail
        self.isEnabled = isEnabled
        self.isDestructive = isDestructive
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: icon).font(.body)
                Text(title).font(.footnote.weight(.medium)).lineLimit(1).minimumScaleFactor(0.7)
                if let detail {
                    Text(detail).font(.caption2).foregroundStyle(.secondary).lineLimit(1).minimumScaleFactor(0.7)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 56) // thumb zone, comfortably over 44pt
        }
        .buttonStyle(.bordered)
        .tint(isDestructive ? .red : .accentColor)
        .disabled(!isEnabled)
    }
}

#Preview {
    EncounterView().environmentObject(GameStore(io: .temporary(name: "preview-encounter")))
}
