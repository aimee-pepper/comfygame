import SwiftUI

/// The battle screen: party left, foes right, action bar in the thumb zone.
///
/// **No gambit editing here** — a locked decision. You can hand the companion's next turn to
/// yourself, but you cannot rewrite its rules mid-fight; that happens on the Party screen, between
/// fights, where it's a considered decision rather than a panic button.
struct EncounterView: View {
    @EnvironmentObject private var store: GameStore
    @State private var targetingAction: TargetingMode?
    /// The skill you've chosen and are now picking a target for. Nil while attacking.
    @State private var pendingSkill: SkillDef?
    /// The skill list, open. Twelve of them won't fit on a key.
    @State private var isChoosingSkill = false

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
                        .sheet(isPresented: $isChoosingSkill) {
                            SkillSheet(onUse: use).environmentObject(store)
                        }
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
        case .damageSkill:
            if let pendingSkill {
                store.takeCombatAction(.skill(pendingSkill.id, foe: foe.id))
            } else {
                store.takeCombatAction(.damageSkill(foe: foe.id))
            }
        case .item: break // items target allies, handled in the bar
        }
        targetingAction = nil
        pendingSkill = nil
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
            if targetingAction != nil {
                // **The keys stay put while you're choosing**, so pressing Attack a second time is
                // literally the same button in the same place rather than a new affordance to find.
                HStack {
                    Text(secondTapPrompt)
                        .font(.footnote)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 8)
                    Button("Cancel") { stopTargeting() }
                        .font(.footnote.weight(.semibold))
                }
                .frame(minHeight: 32)
            }
            if store.actingCombatant != nil {
                HStack(spacing: 8) {
                    ActionKey("Attack", icon: "figure.fencing") { attackPressed() }
                    // **Twelve skills don't fit on a key.** Opens the list, which is also where
                    // each one says what it's *for* — the spec's rule that a skill names the
                    // problem it solves is worth nothing if the UI doesn't print it.
                    ActionKey("Skills", icon: "sparkles",
                              detail: skillDetail(encounter),
                              isEnabled: store.hasAnyReadySkill) { isChoosingSkill = true }
                }
                HStack(spacing: 8) {
                    ActionKey("Item", icon: "cross.vial",
                              detail: store.usableItems.isEmpty ? "none carried" : "\(store.usableItems.count)",
                              isEnabled: !store.usableItems.isEmpty) { stopTargeting(); useFirstItem() }
                    ActionKey("Flee", icon: "figure.run",
                              detail: "−\(Int(Tuning.Encounter.fleeStabilityCost)) stability",
                              isDestructive: true) { stopTargeting(); store.takeCombatAction(.flee) }
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

    /// How many are actually usable this turn — the number you'd want before opening the list.
    private func skillDetail(_ encounter: EncounterState) -> String? {
        let ready = store.readySkills.count
        let total = store.actorSkills.count
        guard total > 0 else { return "none" }
        return ready == 0 ? "all cooling" : "\(ready) of \(total)"
    }

    private func stopTargeting() { targetingAction = nil; pendingSkill = nil }

    /// What the second tap will do, said before it's pressed rather than after.
    private var secondTapPrompt: String {
        if let pendingSkill {
            return "Choose a target — or tap Attack to use \(pendingSkill.name) on the first."
        }
        return store.wouldActOnOwnRules
            ? "Choose a target — or tap Attack again to follow your own rules."
            : "Choose a target — or tap Attack again to take the first."
    }

    /// **First press picks a target; second press stops asking.**
    private func attackPressed() {
        guard targetingAction != nil else { return beginTargeting(.attack) }
        if let action = store.defaultCombatAction(pendingSkill: pendingSkill?.id) {
            store.takeCombatAction(action)
        }
        targetingAction = nil
        pendingSkill = nil
    }

    private func beginTargeting(_ mode: TargetingMode) {
        guard let encounter, encounter.livingFoes.count > 1 else {
            // One foe left: no decision to make, so don't make them tap twice.
            if let only = encounter?.livingFoes.first {
                switch mode {
                case .attack: store.takeCombatAction(.attack(foe: only.id))
                case .damageSkill:
                    if let pendingSkill {
                        store.takeCombatAction(.skill(pendingSkill.id, foe: only.id))
                    } else {
                        store.takeCombatAction(.damageSkill(foe: only.id))
                    }
                    pendingSkill = nil
                case .item: break
                }
            }
            return
        }
        targetingAction = mode
    }

    /// Chosen from the list. Anything needing a foe goes into targeting; anything else fires now.
    private func use(_ skill: SkillDef) {
        isChoosingSkill = false
        if skill.needsFoe {
            pendingSkill = skill
            beginTargeting(.damageSkill)
        } else if skill.needsAlly {
            store.takeCombatAction(.skill(skill.id, ally: weakestAlly()))
        } else {
            store.takeCombatAction(.skill(skill.id))
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
            // **What it's wearing.** Your weapon's damage type is worth more or less against it,
            // and this is the read that makes choosing one a decision rather than a guess.
            if let covering = foe.coveringWord {
                Text(covering)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
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


/// The skill list.
///
/// **Every row says what it's for.** `resources-skills-spec.md` §2 rules that a skill which is good
/// against everything is just a bigger attack — so each one names the kind of creature it answers,
/// and the list prints that rather than making you infer it from a power number.
private struct SkillSheet: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss
    let onUse: (SkillDef) -> Void

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(store.actorSkills) { skill in
                        let cooling = store.cooldown(of: skill)
                        Button {
                            onUse(skill)
                            dismiss()
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: skill.icon)
                                    .foregroundStyle(cooling > 0 ? Color.secondary : .accentColor)
                                    .frame(width: 24)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(skill.name).font(.callout.weight(.medium))
                                    // The problem it solves, which is the whole reason to have it.
                                    Text(skill.answers.isEmpty ? skill.blurb : skill.answers)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                Spacer(minLength: 6)
                                if cooling > 0 {
                                    Text("\(cooling)")
                                        .font(.caption.monospacedDigit())
                                        .foregroundStyle(.secondary)
                                        .padding(.horizontal, 8).padding(.vertical, 3)
                                        .background(Color(.tertiarySystemFill), in: Capsule())
                                } else if skill.power > 0 {
                                    Text("\(skill.power)")
                                        .font(.caption.monospacedDigit())
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .frame(minHeight: 44)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .disabled(cooling > 0)
                        .opacity(cooling > 0 ? 0.5 : 1)
                    }
                } footer: {
                    Text("A number on the right is what it costs you in rounds before you can use it again.")
                }
            }
            .navigationTitle("Skills")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Back") { dismiss() } }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
