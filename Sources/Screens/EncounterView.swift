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
    @State private var isChoosingItem = false
    @State private var isConfirmingWithdraw = false
    @State private var isShowingDebugV2Order = false

    private var run: WorldRun? { store.state.worlds.activeRun }
    private var encounter: EncounterState? { store.activeEncounter }
    private var withdrawalCost: Int {
        guard let actor = store.actingCombatant else { return Int(Tuning.Encounter.fleeStabilityCost) }
        return Int(CombatRules.withdrawalStabilityCost(for: actor, in: store.state))
    }

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
                        .sheet(isPresented: $isChoosingItem) {
                            CombatItemSheet(onCommit: use).environmentObject(store)
                        }
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .confirmationDialog("Withdraw from this fight?", isPresented: $isConfirmingWithdraw,
                            titleVisibility: .visible) {
            Button(withdrawalCost == 0 ? "Withdraw without losing Stability"
                                      : "Withdraw for \(withdrawalCost) Stability",
                   role: .destructive) {
                store.takeCombatAction(.flee)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(withdrawalCost == 0
                 ? "The party leaves this encounter and remains in the world. Vanish prevents this Stability loss."
                 : "The party leaves this encounter, remains in the world, and loses \(withdrawalCost) Stability.")
        }
#if DEBUG
        .sheet(isPresented: $isShowingDebugV2Order) {
            if let encounter, let receipt = encounter.debugV2Initiative {
                NavigationStack {
                    List {
                        Section("Final order") {
                            ForEach(receipt.entries.sorted { ($0.finalPosition ?? .max) < ($1.finalPosition ?? .max) },
                                    id: \.actor) { entry in
                                VStack(alignment: .leading, spacing: 5) {
                                    Text("\(entry.finalPosition ?? 0). \(CombatRules.actorName(entry.actor, encounter: encounter))")
                                        .font(.headline)
                                    Text("Baseline \(entry.baseline) · total \(entry.total)")
                                        .font(.subheadline.monospacedDigit())
                                    ForEach(entry.components, id: \.nodeID) { component in
                                        Text("+\(component.amount) · \(debugInitiativeNodeName(component.nodeID)) [\(component.nodeID.rawValue)]")
                                            .font(.caption.monospacedDigit())
                                    }
                                    if entry.strikesFirst {
                                        Text("Contact priority places this actor before ordinary initiative totals.")
                                            .font(.caption).foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                        if let evasion = encounter.debugV2Evasion {
                            Section("Final-target miss inputs") {
                                ForEach(evasion.entries, id: \.actor) { entry in
                                    let footwork = entry.components.first {
                                        $0.nodeID == CombatDerivedStatsRules.Node.footwork
                                    }?.amount ?? 0
                                    let feint = encounter.feintActive?.contains(entry.actor) == true
                                    let untouchable = encounter.untouchableStates?[entry.actor]
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("\(CombatRules.actorName(entry.actor, encounter: encounter)) · base \(Int(entry.characterEvasion * 100))%\(footwork > 0 ? " + Footwork 6%" : "")")
                                        if entry.ownsFeint == true {
                                            Text("Feint · \(feint ? "+10% active" : "inactive")")
                                        }
                                        if entry.ownsUntouchable == true {
                                            Text("Untouchable · +\(untouchable?.percentagePoints ?? 0)% · targeted \(untouchable?.targetedDirectCount ?? 0) · landed \(untouchable?.landedDirectCount ?? 0)")
                                        }
                                    }
                                    .font(.caption.monospacedDigit())
                                }
                                ForEach(Array(encounter.evasionAttempts.suffix(8).enumerated()), id: \.offset) { _, attempt in
                                    Text("\(CombatRules.actorName(attempt.actor, encounter: encounter)) · \(attempt.resolution.rawValue) · \(Int(attempt.finalChance * 100))%\(attempt.roll.map { " · roll \(String(format: "%.3f", $0))" } ?? " · no RNG")")
                                        .font(.caption2.monospacedDigit())
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .navigationTitle("V2 final order")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar { Button("Done") { isShowingDebugV2Order = false } }
                }
            }
        }
#endif
    }

    // MARK: Header

    private func header(_ encounter: EncounterState) -> some View {
        HStack {
            Text("Round \(encounter.roundNumber)")
                .font(.headline.monospacedDigit())
            Spacer()
#if DEBUG
            if let receipt = encounter.debugV2Initiative {
                Button("V2 order · \(receipt.entries.count) actors") {
                    isShowingDebugV2Order = true
                }
                    .font(.caption.weight(.semibold))
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .accessibilityIdentifier("encounter.debug-v2-initiative-order")
            }
#endif
            Text(turnText(encounter))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.bar)
    }

#if DEBUG
    private func debugInitiativeNodeName(_ id: CombatNodeID) -> String {
        switch id {
        case CombatDerivedStatsRules.Node.quickStep: "Quick Step"
        case CombatDerivedStatsRules.Node.lightFrame: "Light Frame"
        default: id.rawValue
        }
    }
#endif

    private func turnText(_ encounter: EncounterState) -> String {
        EncounterTurnText.format(
            current: encounter.current,
            encounterFinished: encounter.outcome != nil,
            companionOverride: encounter.isCompanionOverridden,
            rosterNames: store.state.base.roster.map(\.name)
        )
    }

    // MARK: Combatants

    private func combatants(_ run: WorldRun, _ encounter: EncounterState) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 10) {
                PartyCard(actor: .binder,
                          name: "You",
                          icon: "figure.stand",
                          travellerID: nil,
                          health: CombatRules.health(of: .binder, in: run),
                          isActing: encounter.current == .binder && encounter.outcome == nil,
                          badge: nil)

                // **Everybody who came.** One hardcoded card was the last place the party of two
                // survived — the fight itself already knows how to run five.
                ForEach(store.state.base.activeParty, id: \.self) { index in
                    if store.state.base.roster.indices.contains(index) {
                        PartyCard(actor: .companion(index),
                                  name: store.state.base.roster[index].name,
                                  icon: store.state.base.roster[index].icon,
                                  travellerID: store.state.base.roster[index].traveller,
                                  health: CombatRules.health(of: .companion(index), in: run),
                                  isActing: encounter.current == .companion(index) && encounter.outcome == nil,
                                  badge: encounter.isCompanionOverridden ? "manual" : "auto")
                            .onTapGesture { store.toggleCompanionOverride() }
                    }
                }
                Group { EmptyView() }
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
                    VStack(spacing: 3) {
                        FoeCard(foe: foe,
                                isActing: encounter.current == .foe(foe.id) && encounter.outcome == nil,
                                isTargetable: targetingAction != nil && foe.isAlive)
                            .onTapGesture { tapFoe(foe) }
#if DEBUG
                        if encounter.current == .binder, encounter.outcome == nil, foe.isAlive,
                           encounter.debugV2BinderAttack != nil {
                            debugV2TargetPreview(foe, encounter: encounter)
                        }
#endif
                    }
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
            if isChoosingSkill, let actor = store.actingCombatant {
                CombatTechniquePalette(
                    skills: store.actorSkills,
                    actor: actor,
                    encounter: encounter,
                    state: store.state,
                    onUse: use,
                    onClose: { isChoosingSkill = false }
                )
            } else if store.actingCombatant != nil {
                HStack(spacing: 8) {
                    ActionKey("Attack", icon: "figure.fencing") { attackPressed() }
                    ActionKey("Techniques", icon: "sparkles",
                              detail: skillDetail(encounter),
                              isEnabled: !store.actorSkills.isEmpty) { isChoosingSkill = true }
                }
                HStack(spacing: 8) {
                    ActionKey("Item", icon: "cross.vial",
                              detail: store.usableItems.isEmpty ? "none carried" : "\(store.usableItems.count)",
                              isEnabled: !store.usableItems.isEmpty) {
                        stopTargeting()
                        isChoosingItem = true
                    }
                    ActionKey("Withdraw", icon: "figure.run",
                              detail: withdrawalCost == 0 ? "no stability lost"
                                                          : "−\(withdrawalCost) stability",
                              isDestructive: true) {
                        stopTargeting()
                        isConfirmingWithdraw = true
                    }
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

#if DEBUG
    @ViewBuilder
    private func debugV2TargetPreview(_ foe: FoeState, encounter: EncounterState) -> some View {
        if encounter.revealed.contains(foe.id),
           let preview = CombatRules.debugV2DirectAttackPreview(foe: foe, in: store.state),
           let receipt = encounter.debugV2BinderAttack {
            let contributors = receipt.preMatchupBonus(for: receipt.ordinaryWeaponKind).components.map { component in
                let name: String = switch component.nodeID {
                case CombatDerivedStatsRules.Node.heavyHand: "Heavy Hand"
                case CombatDerivedStatsRules.Node.keenEye: "Keen Eye"
                default: component.nodeID.rawValue
                }
                return "\(name) [\(component.nodeID.rawValue)] +\(component.amount)"
            }.joined(separator: " · ")
            Text("V2 \(preview.lower.finalDamage)–\(preview.upper.finalDamage) · \(contributors.isEmpty ? "no node bonus" : contributors)")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        } else {
            Text("V2 damage preview needs Sight")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
#endif

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

    private func use(_ quote: CombatItemUseQuote) -> CombatItemUseCommitResult {
        store.commitCombatItemUse(quote)
    }

    /// Healing goes to whoever needs it most — the obvious intent, and one fewer tap. Across the
    /// whole party now, rather than a comparison between the only two people who could be hurt.
    private func weakestAlly() -> Combatant {
        guard let run else { return .binder }
        func share(_ who: Combatant) -> Double {
            let health = CombatRules.health(of: who, in: run)
            return Double(health.current) / Double(max(1, health.max))
        }
        return CombatRules.party(of: store.state)
            .filter { CombatRules.isAlive($0, in: run) }
            .min { share($0) < share($1) } ?? .binder
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
        case .fled: "The party withdrew."
        case .defeated: "You can't go on."
        }
    }
}

enum EncounterTurnText {
    static func format(
        current: Combatant,
        encounterFinished: Bool,
        companionOverride: Bool,
        rosterNames: [String]
    ) -> String {
        guard !encounterFinished else { return "" }
        switch current {
        case .binder:
            return "your move"
        case .companion(let index):
            let name = rosterNames.indices.contains(index) ? rosterNames[index] : "Companion"
            return companionOverride ? "you're directing \(name)" : "\(name) is acting"
        case .foe:
            return "…"
        }
    }
}

// MARK: - Cards

private struct PartyCard: View {
    let actor: Combatant
    let name: String
    let icon: String
    let travellerID: TravellerID?
    let health: (current: Int, max: Int)
    let isActing: Bool
    let badge: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                NamedCharacterPixelIdentity(
                    travellerID: travellerID,
                    fallbackSystemIcon: icon,
                    fallbackColor: .primary
                )
                .frame(width: 24, height: 24)
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
                CreaturePixelIdentity(traits: foe.traits, fallbackSystemIcon: foe.stats.icon)
                    .frame(width: 28, height: 28)
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


/// The compact in-place technique palette. It replaces only the ordinary action keys, leaving the
/// encounter stage and current actor visible. A first tap owns selection/detail; the explicit Use
/// action preserves the existing combat commit/target flow.
private struct CombatTechniquePalette: View {
    let skills: [SkillDef]
    let actor: Combatant
    let encounter: EncounterState
    let state: GameState
    let onUse: (SkillDef) -> Void
    let onClose: () -> Void
    @State private var selectedSkillID: SkillID?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 4)

    private var selectedSkill: SkillDef? {
        skills.first { $0.id == selectedSkillID }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Techniques").font(.headline)
                Spacer(minLength: 8)
                Button("Close", action: onClose)
                    .font(.footnote.weight(.semibold))
                    .frame(minHeight: 44)
            }

            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(skills) { skill in
                    let presentation = CombatSkillRowPresentation.make(
                        skill: skill, actor: actor, encounter: encounter, state: state
                    )
                    let cooling = presentation.remainingCooldown > 0
                    Button {
                        selectedSkillID = skill.id
                    } label: {
                        VStack(spacing: 3) {
                            Image(systemName: skill.icon)
                                .font(.body)
                            Text(skill.name)
                                .font(.caption2.weight(.semibold))
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                            Text(cooling ? "\(presentation.remainingCooldown) rounds" : "Ready")
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 64)
                        .padding(.horizontal, 2)
                        .background(Color(.secondarySystemGroupedBackground),
                                    in: RoundedRectangle(cornerRadius: 10))
                        .overlay {
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(selectedSkillID == skill.id ? Color.accentColor : .clear,
                                        lineWidth: 2)
                        }
                    }
                    .buttonStyle(.plain)
                    .opacity(cooling ? 0.55 : 1)
                }
            }

            if let skill = selectedSkill {
                let presentation = CombatSkillRowPresentation.make(
                    skill: skill, actor: actor, encounter: encounter, state: state
                )
                HStack(alignment: .center, spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(skill.name).font(.callout.weight(.semibold))
                        Text(skill.answers.isEmpty ? skill.blurb : skill.answers)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                        Text(presentation.accessibilityValue)
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 4)
                    Button("Use") { onUse(skill) }
                        .buttonStyle(.borderedProminent)
                        .frame(minHeight: 44)
                        .disabled(presentation.remainingCooldown > 0)
                }
                .padding(10)
                .background(Color(.tertiarySystemGroupedBackground),
                            in: RoundedRectangle(cornerRadius: 10))
            } else {
                Text("Select a technique to review its effect and readiness.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

/// Truth boundary for the skill row. The displayed potency and minted cooldown use the same
/// actor-stat derivations as `CombatRules.use`; the remaining cooldown is the encounter's saved
/// per-actor, per-skill receipt.
struct CombatSkillRowPresentation: Equatable, Sendable {
    static let footerText = "Potency and cooldown reflect the acting character. “Ready in” is the saved cooldown remaining now."

    var potency: Int?
    var cooldownDuration: Int
    var remainingCooldown: Int

    var cooldownText: String {
        remainingCooldown > 0
            ? "Ready in \(remainingCooldown) round\(remainingCooldown == 1 ? "" : "s")"
            : "Ready · \(cooldownDuration)-round cooldown"
    }

    var accessibilityValue: String {
        (potency.map { "Potency \($0). " } ?? "") + cooldownText
    }

    static func make(skill: SkillDef, actor: Combatant, encounter: EncounterState,
                     state: GameState) -> CombatSkillRowPresentation {
        let stats = CombatRules.stats(of: actor, in: state)
        return CombatSkillRowPresentation(
            potency: skill.power > 0
                ? (stats.map { CharacterRules.skillPower(skill.power, $0) } ?? skill.power)
                : nil,
            cooldownDuration: stats.map { CharacterRules.cooldown(skill.cooldownRounds, $0) }
                ?? skill.cooldownRounds,
            remainingCooldown: CombatRules.cooldown(of: skill, for: actor, in: encounter)
        )
    }
}

/// Combat items are a deliberate choice of both remedy and recipient. Auto-using the first stack
/// made status cures effectively inaccessible whenever a salve sorted ahead of them.
private struct CombatItemSheet: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss
    let onCommit: (CombatItemUseQuote) -> CombatItemUseCommitResult
    @State private var refusalMessage: String?
    @State private var selectedStackID: InstanceID?

    private var livingParty: [Combatant] {
        guard let run = store.activeRun else { return [] }
        return CombatRules.party(of: store.state).filter { CombatRules.isAlive($0, in: run) }
    }

    private var selectedStack: ItemStack? {
        store.usableItems.first { $0.id == selectedStackID }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Choose a remedy")
                        .font(.headline)

                    SixAcrossItemGrid(data: store.usableItems, id: \.id) { stack in
                        if let item = ContentCatalog.shared.item(stack.catalogID) {
                            Button {
                                selectedStackID = stack.id
                            } label: {
                                ItemIconTile(
                                    icon: item.icon,
                                    catalogueID: stack.catalogID,
                                    rarity: item.rarity,
                                    quantity: stack.count,
                                    identified: stack.identified,
                                    location: .carried,
                                    accessibilityName: item.name,
                                    isSelected: selectedStackID == stack.id
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    if let stack = selectedStack,
                       let item = ContentCatalog.shared.item(stack.catalogID) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(stack.count > 1 ? "\(item.name) ×\(stack.count)" : item.name)
                                .font(.headline)
                            Text(itemEffect(item))
                                .font(.caption)
                                .foregroundStyle(.secondary)

                        }
                        .padding(12)
                        .background(Color(.secondarySystemGroupedBackground),
                                    in: RoundedRectangle(cornerRadius: 12))
                    } else {
                        Text("Select a remedy to choose who uses it.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(16)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) { selectedRemedyActionBar }
            .navigationTitle("Carried remedies")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Back") { dismiss() } }
            }
            .alert("Item not used", isPresented: Binding(
                get: { refusalMessage != nil },
                set: { if !$0 { refusalMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(refusalMessage ?? "The current fight state no longer permits that action.")
            }
            .confirmationDialog("Choose an affliction", isPresented: Binding(
                get: { pendingSelection != nil },
                set: { if !$0 { pendingSelection = nil } }
            ), titleVisibility: .visible) {
                if let pendingSelection {
                    ForEach(pendingSelection.afflictions, id: \.applicationReceipt) { affliction in
                        Button(AfflictionDefinition.definition(affliction.kind).displayName) {
                            commit(pendingSelection.stack, on: pendingSelection.ally,
                                   selecting: affliction.applicationReceipt)
                        }
                    }
                    Button("Cancel", role: .cancel) { self.pendingSelection = nil }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    @ViewBuilder private var selectedRemedyActionBar: some View {
        if let stack = selectedStack,
           let item = ContentCatalog.shared.item(stack.catalogID) {
            PersistentActionBar(message: itemEffect(item)) {
                HStack(spacing: 10) {
                    Text(stack.count > 1 ? "\(item.name) ×\(stack.count)" : item.name)
                        .font(.callout.weight(.semibold))
                        .lineLimit(1)
                    Spacer(minLength: 4)
                    Menu {
                        ForEach(livingParty, id: \.self) { ally in
                            Button(name(of: ally)) { beginUse(stack, on: ally) }
                        }
                    } label: {
                        Label("Use on…", systemImage: "person.crop.circle.badge.checkmark")
                            .frame(minHeight: 44)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(livingParty.isEmpty)
                }
            }
        }
    }

    private struct PendingSelection {
        let stack: ItemStack
        let ally: Combatant
        let afflictions: [AfflictionInstance]
    }

    @State private var pendingSelection: PendingSelection?

    private func beginUse(_ stack: ItemStack, on ally: Combatant) {
        switch store.combatItemUseEvaluation(stack: stack, on: ally) {
        case .ready(let quote):
            finish(onCommit(quote))
        case .refused(.selectionRequired(let afflictions)):
            pendingSelection = .init(stack: stack, ally: ally, afflictions: afflictions)
        case .refused(let refusal):
            refusalMessage = refusal.message
        }
    }

    private func commit(_ stack: ItemStack, on ally: Combatant, selecting receipt: UInt64) {
        pendingSelection = nil
        switch store.combatItemUseEvaluation(stack: stack, on: ally, selecting: receipt) {
        case .ready(let quote): finish(onCommit(quote))
        case .refused(let refusal): refusalMessage = refusal.message
        }
    }

    private func finish(_ result: CombatItemUseCommitResult) {
        switch result {
        case .committed: dismiss()
        case .refused(let refusal): refusalMessage = refusal.message
        }
    }

    private func name(of actor: Combatant) -> String {
        switch actor {
        case .binder: return "You"
        case .companion(let index):
            return store.state.base.roster.indices.contains(index)
                ? store.state.base.roster[index].name : "Companion"
        case .foe: return "Foe"
        }
    }

    private func itemEffect(_ item: ItemDef) -> String {
        guard let consumable = item.consumable else { return "Consumable." }
        switch consumable.effect {
        case .heal: return "Restores \(consumable.potency) health."
        case .clearPoison: return "Clears poison and bleeding."
        case .clearElemental: return "Clears burning and dazzle."
        case .clearAnyStatus: return "Clears one affliction."
        case .restoreStability: return "Restores world stability outside combat."
        case .returnHome: return "Returns the party home outside combat."
        case .lightWorld: return "Expands vision outside combat."
        case .farsight: return "Reveals a distant site outside combat."
        case .preventStatus: return "Prevents the next affliction, including bleeding."
        case .coatPoison: return "Poisons the next foe this party member strikes."
        case .coatBurn: return "Burns the next foe this party member strikes."
        case .coatBleed: return "Makes the next strike leave a bleeding wound."
        case .coatDazzle: return "Dazzles the next foe this party member strikes."
        case .identifyCurio: return "Identifies a curio outside combat."
        case .lureCreature: return "Draws a roaming creature outside combat."
        case .maskScent: return "Masks the party's scent outside combat."
        }
    }
}
