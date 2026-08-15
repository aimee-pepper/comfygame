import Foundation

/// How a fight resolves.
///
/// Turn-based to the bone: nothing advances except by a call from a player action. The party acts
/// in a fixed rotation, then the enemies (PLACEHOLDER — there's no speed stat in v0). Every roll
/// comes off the run's saved RNG, so a force-quit mid-round resumes to the same fight rather than
/// re-rolling in anyone's favour.
enum CombatRules {
    private static let quickenNode: CombatNodeID = "combat.offense.swiftness.quicken"
    private static let blurNode: CombatNodeID = "combat.offense.swiftness.blur"
    private static let overbearNode: CombatNodeID = "combat.offense.force.overbear"
    private static let firstStrikeNode: CombatNodeID = "combat.offense.swiftness.first_strike"

    static func firstStrikeRawBonus(actor: Combatant, encounter: EncounterState) -> Int {
        encounter.debugV2OwnedNodeIDs?[actor]?.contains(firstStrikeNode) == true
            && encounter.firstNormalActionCompleted?.contains(actor) == false ? 4 : 0
    }

    private static func usesPersonalTurnAuthority(_ encounter: EncounterState) -> Bool {
        if encounter.personalTurn != nil { return true }
        let nodes = [quickenNode, blurNode, overbearNode, firstStrikeNode]
        return encounter.debugV2OwnedNodeIDs?.values.contains { owned in
            nodes.contains(where: owned.contains)
        } == true
    }

    /// Tests, DEBUG comparisons, and tolerant resumed saves can attach the frozen v2 ownership
    /// authority after an encounter was originally constructed. Materialize its empty typed
    /// ledgers together; otherwise producers write through nil optionals while consumers believe
    /// the encounter is modern.
    private static func adoptV2ReceiptLedgers(in encounter: inout EncounterState) {
        guard encounter.debugV2OwnedNodeIDs != nil else { return }
        if encounter.wardReceipts == nil { encounter.wardReceipts = [:] }
        if encounter.snuffReceipts == nil { encounter.snuffReceipts = [:] }
        if encounter.interposeReceipts == nil { encounter.interposeReceipts = [] }
        if encounter.drawOffReceipts == nil { encounter.drawOffReceipts = [:] }
        if encounter.unyieldingSpent == nil { encounter.unyieldingSpent = [] }
        if encounter.braceReceipts == nil { encounter.braceReceipts = [:] }
        if encounter.breakingBlowScheduledSpent == nil { encounter.breakingBlowScheduledSpent = [] }
        if encounter.breakingBlowOpeningSpent == nil { encounter.breakingBlowOpeningSpent = [] }
        if encounter.blurSpent == nil { encounter.blurSpent = [] }
        if encounter.firstNormalActionCompleted == nil { encounter.firstNormalActionCompleted = [] }
        if encounter.rankAtPreviousCompletedAction == nil {
            encounter.rankAtPreviousCompletedAction = encounter.partyRanks
        }
    }

    // MARK: Starting a fight

    /// **Turn order comes off initiative** (creature-system-spec §7), not off a fixed party-first
    /// rotation. Sleek, small and lightly armoured goes before you; a huge armoured thing goes after.
    /// Anything with far reach strikes first regardless — length beats speed at the moment of
    /// contact.
    ///
    /// The order is resolved once and stored, so a foe dying mid-round can't shift whose turn it is.
    /// - Parameter party: everybody who walked out with you. **All of them get a place in the
    ///   order** — this is where a party of five becomes real, and it used to be a hardcoded two.
    static func makeEncounter(id: InstanceID, foes: [FoeState], party: [Combatant] = [.binder, .companion(0)],
                              names: [Int: String] = [:],
                              apexActionSlots: [InstanceID: Int] = [:],
                              ordinaryPressureSlots: Int = 0,
                              initiallyUnrecordedSpecies: Set<String> = [],
                              debugV2BinderAttack: EncounterState.DebugV2BinderAttackReceipt? = nil,
                              debugV2Initiative: EncounterState.DebugV2InitiativeReceipt? = nil,
                              debugV2Armour: EncounterState.DebugV2ArmourReceipt? = nil,
                              debugV2Evasion: EncounterState.DebugV2EvasionReceipt? = nil,
                              debugV2Resistance: EncounterState.DebugV2ResistanceReceipt? = nil,
                              ghostEvasionAvailable: Set<Combatant>? = nil,
                              debugV2OwnedNodeIDs: [Combatant: Set<CombatNodeID>]? = nil,
                              partyRanks: [Combatant: Rank] = [:],
                              rng: inout SeededRNG) -> EncounterState {
        var ranked: [(actor: Combatant, initiative: Int, first: Bool)] = party.map { member in
            let frozen = debugV2Initiative?.entry(for: member)
            return (member, frozen?.total ?? (member == .binder ? Tuning.Encounter.binderInitiative
                                                                : Tuning.Encounter.companionInitiative),
                    frozen?.strikesFirst ?? false)
        }
        for foe in foes {
            let slow = foe.stats.damageKind == .crush ? Tuning.Encounter.crushInitiativePenalty : 0
            let actor = Combatant.foe(foe.id)
            let frozen = debugV2Initiative?.entry(for: actor)
            ranked.append((actor, frozen?.total ?? foe.stats.initiative - slow,
                            frozen?.strikesFirst ?? foe.stats.strikesFirst))
        }
        // Ties broken off the run's own stream rather than by declaration order, so two identical
        // animals don't always act in the order they happened to be placed.
        let jittered = ranked.map { ($0, rng.int(in: 0...99)) }
        let order = jittered
            .sorted {
                if $0.0.first != $1.0.first { return $0.0.first }
                if $0.0.initiative != $1.0.initiative { return $0.0.initiative > $1.0.initiative }
                return $0.1 > $1.1
            }
            .map(\.0.actor)

        var slots = order.map { EncounterState.TurnSlot(actor: $0) }
        for (foeID, count) in apexActionSlots.sorted(by: { $0.key.rawValue < $1.key.rawValue }) where count > 1 {
            guard var previous = slots.firstIndex(where: { $0.actor == .foe(foeID) }) else { continue }
            for ordinal in 2...min(3, count) {
                // Place each lighter action after another actor whenever the remaining initiative
                // order permits it. Re-resolve from the last insertion: using the original primary
                // index for every insertion can accidentally bunch slots 2 and 3 together.
                let intervening = slots.indices.first { $0 > previous && slots[$0].actor != .foe(foeID) }
                let index = intervening.map { $0 + 1 } ?? slots.endIndex
                slots.insert(.init(actor: .foe(foeID), kind: .apexFollowUp(ordinal),
                                   strengthMultiplier: 0.60, suppressesAfflictions: true), at: index)
                previous = index
            }
        }
        let ordinaryFoeOrder = order.compactMap(\.foeID).filter { foeID in
            foes.contains { $0.id == foeID && !$0.isApex }
        }
        if !ordinaryFoeOrder.isEmpty, ordinaryPressureSlots > 0 {
            for ordinal in 1...ordinaryPressureSlots {
                let foeID = ordinaryFoeOrder[(ordinal - 1) % ordinaryFoeOrder.count]
                let previous = slots.lastIndex(where: { $0.actor == .foe(foeID) }) ?? 0
                let intervening = slots.indices.first { $0 > previous && slots[$0].actor != .foe(foeID) }
                let index = intervening.map { $0 + 1 } ?? slots.endIndex
                slots.insert(.init(actor: .foe(foeID), kind: .ordinaryPressureFollowUp(ordinal),
                                   strengthMultiplier: 0.55, suppressesAfflictions: true), at: index)
            }
        }
        var opening = [foes.count == 1 ? "A \(foes[0].stats.displayName) notices you."
                                       : "They close in around you."]
        if let relentless = apexActionSlots.values.max(), relentless > 1 {
            opening.append("Relentless — \(relentless) actions; follow-ups lighter.")
        }
        if ordinaryPressureSlots > 0 {
            opening.append("Pressed — \(ordinaryPressureSlots) lighter follow-up\(ordinaryPressureSlots == 1 ? "" : "s").")
        }
        var finalizedInitiative = debugV2Initiative
        if var receipt = finalizedInitiative {
            for index in receipt.entries.indices {
                receipt.entries[index].finalPosition = order.firstIndex(
                    of: receipt.entries[index].actor).map { $0 + 1 }
            }
            finalizedInitiative = receipt
        }
        var result = EncounterState(
            id: id,
            foes: foes,
            partyNames: names,
            order: order,
            turnSlots: slots,
            initiallyUnrecordedSpecies: initiallyUnrecordedSpecies,
            debugV2BinderAttack: debugV2BinderAttack,
            debugV2Initiative: finalizedInitiative,
            debugV2Armour: debugV2Armour,
            debugV2Evasion: debugV2Evasion,
            debugV2Resistance: debugV2Resistance,
            ghostEvasionAvailable: ghostEvasionAvailable,
            debugV2OwnedNodeIDs: debugV2OwnedNodeIDs,
            partyRanks: partyRanks,
            log: opening
        )
        if let evasion = debugV2Evasion {
            result.feintActive = []
            result.untouchableStates = Dictionary(uniqueKeysWithValues: evasion.entries.compactMap {
                $0.ownsUntouchable == true ? ($0.actor, .init()) : nil
            })
        }
        return result
    }

    // MARK: Party numbers

    /// **What each of them is wearing.** The Binder has its own slots (Aimee, 5 Aug) — it's half
    /// the party, and an attack that was a `Tuning` constant meant the damage-type matchup never
    /// reached the player's own turns, which is the whole point of giving weapons a type.
    static func equipped(_ slot: GearSlot, for actor: Combatant, in state: GameState) -> EquippedPiece? {
        switch actor {
        case .binder: state.base.binderEquipped[slot]
        case .companion(let index): state.base.worn(slot, by: .member(index))
        case .foe: nil
        }
    }

    /// **What somebody is, on top of what they're holding** (session 17 §1).
    ///
    /// Might for crush, Finesse for pierce and rend — so a character and their weapon want to
    /// agree, and a high-Might character carrying a piercing blade is wasting half of what they
    /// are. That's a real equipping decision rather than "wear the highest tier".
    static func stats(of actor: Combatant, in state: GameState) -> CharacterStats? {
        switch actor {
        case .binder: state.base.binderCharacter.stats
        case .companion(let index): state.base.character(.member(index)).stats
        case .foe: nil
        }
    }

    static func rank(of actor: Combatant, in state: GameState) -> Rank {
        switch actor {
        case .binder: state.base.binderCharacter.rank
        case .companion(let index): state.base.character(.member(index)).rank
        case .foe: .front
        }
    }

    static func rank(of actor: Combatant, in encounter: EncounterState,
                     fallback state: GameState) -> Rank {
        if let saved = encounter.partyRanks[actor] { return saved }
        if let frozen = encounter.debugV2Armour?.entry(for: actor)?.entryRank { return frozen }
        if encounter.debugV2Armour != nil { return .front }
        return rank(of: actor, in: state)
    }

    static func binderAttack(in state: GameState) -> Int {
        let power = equipped(.weapon, for: .binder, in: state)?.effectivePower ?? 0
        let total = Double(Tuning.Encounter.binderAttack
            + CharacterRules.damageBonus(state.base.binderCharacter.stats,
                                         with: damageKind(for: .binder, in: state)))
            + power * Double(Tuning.Encounter.attackPerWeaponTier)
        return Int(total.rounded())
    }

    /// **What this one is swinging.** Each party member's own weapon decides the matchup, so
    /// carrying a piercing blade while Quill carries a rending one is a real answer to a world that
    /// grew both plated and furred things.
    static func damageKind(for actor: Combatant, in state: GameState) -> DamageKind? {
        equipped(.weapon, for: actor, in: state)?.frozenDamage
    }

    static func reach(for actor: Combatant, in state: GameState) -> Reach {
        equipped(.weapon, for: actor, in: state)?.frozenReach ?? .close
    }

    /// Whether this foe can include a party member in any attack it can currently perform. Foes
    /// have one derived hostile action today: single delivery respects the front line, while area
    /// and multi delivery, emanation, and first-strike reach can cross it.
    static func canReach(_ target: Combatant, foe: FoeState,
                         in state: GameState, run: WorldRun) -> Bool {
        let standing = party(of: state).filter { isAlive($0, in: run) }
        guard standing.contains(target) else { return false }
        let encounter = run.activeEncounter
        func currentRank(_ actor: Combatant) -> Rank {
            encounter.map { rank(of: actor, in: $0, fallback: state) } ?? rank(of: actor, in: state)
        }
        if currentRank(target) == .front { return true }
        if standing.allSatisfy({ currentRank($0) == .back }) { return true }
        if foe.stats.delivery != .single { return true }
        return foe.stats.strikesFirst || foe.stats.element != nil
    }

    /// **The rule this hand is breaking**, on the eight wild-only weapons and nowhere else
    /// (`apex-encounters.md` §4). Nil on everything you can make.
    static func wildRule(for actor: Combatant, in state: GameState) -> WildRule? {
        equipped(.weapon, for: actor, in: state)?.gear?.breaks
    }

    static func wardedHaftMultiplier(against kind: DamageKind, for actor: Combatant,
                                     in state: GameState) -> Double {
        let weapon = equipped(.weapon, for: actor, in: state)
        return weapon?.gear?.breaks == .wardWhileHeld && weapon?.gear?.wardsAgainst == kind
            ? 1 - Tuning.Apex.wardedHaftReduction : 1
    }

    /// **How well a damage type does against what a creature is wearing** (combat-depth-spec §1).
    ///
    /// | | hard covering | thick soft covering |
    /// |---|---|---|
    /// | **pierce** | strong — finds the gaps | weak — passes through without doing much |
    /// | **crush** | strong — force doesn't care about plate | weak — absorbed by padding |
    /// | **rend** | weak — can't get purchase | strong — tears |
    ///
    /// This is the change that closes the loop: kill a piercing creature, butcher its fang, carry a
    /// piercing weapon, and it's good against the armoured things and wasteful against the soft
    /// ones. **You read it off the covering word the encounter already prints.**
    /// **A two-natured blade picks whichever hurts more** — the one thing no material can do,
    /// because nothing has two dominant armaments (`apex-encounters.md` §4).
    static func effectiveness(of kind: DamageKind, against covering: Covering,
                              breaking rule: WildRule?) -> Double {
        CombatDamageRules.effectiveness(of: kind, against: covering, breaking: rule)
    }

    static func effectiveness(of kind: DamageKind, against covering: Covering) -> Double {
        CombatDamageRules.effectiveness(of: kind, against: covering)
    }

    static func companionAttack(_ index: Int, in state: GameState) -> Int {
        let member = PartyMember.member(index)
        let power = state.base.worn(.weapon, by: member)?.effectivePower ?? 0
        let total = Double(Tuning.Encounter.companionBaseAttack
            + CharacterRules.damageBonus(state.base.character(member).stats,
                                         with: damageKind(for: .companion(index), in: state)))
            + power * Double(Tuning.Encounter.attackPerWeaponTier)
        return Int(total.rounded())
    }

    /// Armour softens what lands on the party. Never below a floor — armour shouldn't make a fight
    /// unloseable, just survivable.
    ///
    /// `armourIgnored` is what a piercing attack goes straight through, which is the whole reason
    /// the weapon triangle exists: the same armour is worth more against some things than others.
    /// **What a piece is made of, beyond its tier** (Q36's addition, audit #9: *"for insulation and
    /// reactivity, don't wait for new slots — give them secondary effects on existing gear"*).
    ///
    /// Four of the six material properties had a job: hardness, flexibility, density and lustre
    /// each decide what the Blacksmith asks for. Insulation and reactivity had none at all outside
    /// that one bar, so a warm pelt and a volatile ichor were worth nothing to wear.
    ///
    /// Now they are: **insulation on what you wear turns aside heat**, and **reactivity on what you
    /// swing carries a status into the wound.** Which ties gear to the world it came from — a cold
    /// world is one you dress for.
    static func insulation(of actor: Combatant, in state: GameState) -> Double {
        GearSlot.allCases
            .filter(\.isProtective)
            .compactMap { equipped($0, for: actor, in: state)?.frozenInsulation }
            .reduce(0, +) / Tuning.Pressure.scaleMaximum
    }

    /// What the weapon in somebody's hand is volatile enough to leave behind.
    static func coating(of actor: Combatant, in state: GameState) -> StatusKind? {
        guard let weapon = equipped(.weapon, for: actor, in: state),
              weapon.frozenReactivity >= Tuning.Encounter.coatingReactivity
        else { return nil }
        return .poison
    }

    /// The one final-target miss resolver for otherwise legal single-target direct foe attacks.
    /// Guaranteed receipts consume before probability and therefore consume no RNG.
    static func resolvePartyMiss(_ actor: Combatant, in state: GameState, run: inout WorldRun,
                                 encounter: inout EncounterState) -> Bool {
        normalizeV2EvasionState(&encounter)
        if encounter.ghostEvasionAvailable == nil {
            // One-time adoption for tolerant mid-fight saves. A modern empty set is deliberately
            // distinct and must never remint a consumed Ghost on relaunch.
            encounter.ghostEvasionAvailable = Set(encounter.order.filter { candidate in
                guard candidate.foeID == nil else { return false }
                return loadout(of: candidate, in: state).firstAttackAlwaysMisses
            })
        }
        let frozen = encounter.debugV2Evasion?.entry(for: actor)
        let character: Double
        let components: [EncounterState.DebugV2EvasionReceipt.Component]
        if encounter.debugV2Evasion != nil {
            // An incomplete/corrupt v2 receipt fails closed instead of mixing in mutable Base data.
            character = frozen?.characterEvasion ?? 0
            var active = frozen?.components ?? []
            if frozen?.ownsFeint == true, encounter.feintActive?.contains(actor) == true {
                active.append(.init(nodeID: CombatDerivedStatsRules.Node.feint, amount: 0.10))
            }
            if frozen?.ownsUntouchable == true,
               let points = encounter.untouchableStates?[actor]?.percentagePoints, points > 0 {
                active.append(.init(nodeID: CombatDerivedStatsRules.Node.untouchable,
                                    amount: Double(points) / 100))
            }
            components = active
        } else {
            character = stats(of: actor, in: state).map(CharacterRules.evasion) ?? 0
            let legacy = loadout(of: actor, in: state).evasion
            components = legacy > 0
                ? [.init(nodeID: CombatDerivedStatsRules.Node.footwork, amount: legacy)] : []
        }
        let chance = min(0.85, max(0, character + components.reduce(0) { $0 + $1.amount }))
        func record(_ resolution: EncounterState.EvasionAttempt.Resolution,
                    roll: Double?, missed: Bool) {
            encounter.evasionAttempts.append(.init(actor: actor, characterEvasion: character,
                                                    components: components, finalChance: chance,
                                                    roll: roll, resolution: resolution,
                                                    missed: missed))
            if encounter.evasionAttempts.count > 24 {
                encounter.evasionAttempts.removeFirst(encounter.evasionAttempts.count - 24)
            }
        }
        if (encounter.dodging[actor] ?? 0) > 0 {
            encounter.dodging.removeValue(forKey: actor)
            record(.sidestep, roll: nil, missed: true)
            return true
        }
        if encounter.ghostEvasionAvailable?.contains(actor) == true {
            encounter.ghostEvasionAvailable?.remove(actor)
            record(.ghost, roll: nil, missed: true)
            return true
        }
        let roll = run.rng.double(in: 0...1)
        let missed = roll < chance
        record(missed ? .probabilityMiss : .probabilityHit, roll: roll, missed: missed)
        return missed
    }

    /// One-time adoption for the atomic Feint/Untouchable receipt revision. Receipts that predate
    /// these ownership bits derive no owners; a modern explicit empty collection stays spent/empty.
    private static func normalizeV2EvasionState(_ encounter: inout EncounterState) {
        guard let receipt = encounter.debugV2Evasion else { return }
        if encounter.feintActive == nil { encounter.feintActive = [] }
        if encounter.untouchableStates == nil {
            encounter.untouchableStates = Dictionary(uniqueKeysWithValues: receipt.entries.compactMap {
                $0.ownsUntouchable == true ? ($0.actor, .init()) : nil
            })
        }
    }

    private static func recordUntouchableTarget(_ actor: Combatant, isForcedOpening: Bool,
                                                 encounter: inout EncounterState) {
        guard encounter.debugV2Evasion?.entry(for: actor)?.ownsUntouchable == true,
              encounter.untouchableStates != nil else { return }
        // Opening attacks can reset an existing stack when they land, but their misses are not an
        // ordinary-round achievement and therefore never enter the growth counters.
        guard !isForcedOpening else { return }
        encounter.untouchableStates?[actor, default: .init()].targetedDirectCount += 1
    }

    private static func recordUntouchableLanding(_ actor: Combatant, isForcedOpening: Bool,
                                                  encounter: inout EncounterState) {
        guard encounter.debugV2Evasion?.entry(for: actor)?.ownsUntouchable == true,
              encounter.untouchableStates != nil else { return }
        if !isForcedOpening {
            encounter.untouchableStates?[actor, default: .init()].landedDirectCount += 1
        }
        encounter.untouchableStates?[actor]?.percentagePoints = 0
    }

    static func damageTaken(_ raw: Int, by actor: Combatant, in state: GameState,
                            armourIgnored: Double = 0) -> Int {
        legacyDamageTaken(raw, by: actor, in: state, rank: rank(of: actor, in: state),
                          armourIgnored: armourIgnored)
    }

    private static func legacyDamageTaken(_ raw: Int, by actor: Combatant, in state: GameState,
                                          rank: Rank, armourIgnored: Double) -> Int {
        // **Iron Skin, and Immovable.** The capstone is the one thing in the game that makes armour
        // work against a piercing blow, which is what "armour is armour, whatever it is against"
        // has to mean if it is worth eight points.
        let tree = loadout(of: actor, in: state)
        let ignored = tree.armourAppliesToEverything ? 0 : armourIgnored
        // **Everything protective counts**, not just the body piece — a helm and boots are armour
        // too, and only the companion's chest plate used to be read at all.
        let power = GearSlot.allCases
            .filter(\.isProtective)
            .reduce(0.0) { total, slot in
                guard let piece = equipped(slot, for: actor, in: state) else { return total }
                return total + (piece.gearProfile?.protectivePower ?? piece.effectivePower)
            }
        // **Fortitude decides what that armour is worth to you** (session 17 §1). The same plate
        // does more for a sturdy character than a slight one, which is what stops Fortitude being a
        // second health bar.
        let sturdiness = stats(of: actor, in: state).map(CharacterRules.armourMultiplier) ?? 1
        let armour = power * Double(Tuning.Encounter.defencePerArmorTier) * sturdiness
            + Double(tree.armour)
        let effective = Int((armour * (1 - ignored)).rounded())

        // **Standing at the back is worth something**, and only against something in reach
        // (session 17 §4).
        var incoming = Double(raw)
        if rank == .back { incoming *= 1 - Tuning.Encounter.backRankProtection }
        return max(Tuning.Encounter.minimumDamage, Int(incoming.rounded()) - effective)
    }

    static func debugArmourReceipt(enabled: Bool, party: [Combatant], in state: GameState,
                                   binderNodeIDs: Set<CombatNodeID>,
                                   companionNodeIDs: [Int: Set<CombatNodeID>])
        -> EncounterState.DebugV2ArmourReceipt? {
        guard enabled else { return nil }
        let supported: Set<CombatNodeID> = [CombatDerivedStatsRules.Node.ironSkin,
                                            CombatDerivedStatsRules.Node.bulwark,
                                            CombatDerivedStatsRules.Node.shieldwall,
                                            CombatDerivedStatsRules.Node.immovable]
        let entries = party.map { actor -> EncounterState.DebugV2ArmourReceipt.Entry in
            let power = GearSlot.allCases.filter(\.isProtective).reduce(0.0) { total, slot in
                guard let piece = equipped(slot, for: actor, in: state) else { return total }
                return total + (piece.gearProfile?.protectivePower ?? piece.effectivePower)
            }
            let sturdiness = stats(of: actor, in: state).map(CharacterRules.armourMultiplier) ?? 1
            let selected: Set<CombatNodeID>
            switch actor {
            case .binder: selected = binderNodeIDs
            case .companion(let index): selected = companionNodeIDs[index] ?? []
            case .foe: selected = []
            }
            return .init(actor: actor, equipmentProtectivePower: power,
                         sturdiness: sturdiness, ownedNodeIDs: selected.intersection(supported),
                         entryRank: rank(of: actor, in: state))
        }
        return .init(entries: entries)
    }

    static func v2IncomingDamage(_ raw: Int, by actor: Combatant, in state: GameState,
                                 run: WorldRun, encounter: EncounterState,
                                 armourIgnored: Double = 0)
        -> CombatDerivedStatsRules.IncomingDamageResult? {
        guard let receipt = encounter.debugV2Armour else { return nil }
        let participants = receipt.entries.map(\.actor)
        var ranks: [Combatant: Rank] = [:]
        for actor in participants where ranks[actor] == nil {
            ranks[actor] = rank(of: actor, in: encounter, fallback: state)
        }
        let conscious = Set(participants.filter { isAlive($0, in: run) })
        return CombatDerivedStatsRules.incomingDamage(raw: raw, receiver: actor,
                                                       receipt: receipt, ranks: ranks,
                                                       conscious: conscious,
                                                       armourIgnored: armourIgnored)
    }

    static func v2EmanationArmourDamage(_ raw: Int, by actor: Combatant, in state: GameState,
                                        run: WorldRun, encounter: EncounterState)
        -> CombatDerivedStatsRules.IncomingDamageResult? {
        guard let receipt = encounter.debugV2Armour,
              receipt.entry(for: actor)?.ownedNodeIDs.contains(
                CombatDerivedStatsRules.Node.immovable) == true else { return nil }
        let participants = receipt.entries.map(\.actor)
        let ranks = Dictionary(uniqueKeysWithValues: participants.map {
            ($0, rank(of: $0, in: encounter, fallback: state))
        })
        let conscious = Set(participants.filter { isAlive($0, in: run) })
        return CombatDerivedStatsRules.emanationArmourDamage(
            raw: raw, receiver: actor, receipt: receipt, ranks: ranks, conscious: conscious)
    }

    static func damageTaken(_ raw: Int, by actor: Combatant, in state: GameState,
                            run: WorldRun, encounter: EncounterState,
                            armourIgnored: Double = 0) -> Int {
        v2IncomingDamage(raw, by: actor, in: state, run: run, encounter: encounter,
                         armourIgnored: armourIgnored)?.finalDamage
            ?? legacyDamageTaken(raw, by: actor, in: state,
                                 rank: rank(of: actor, in: encounter, fallback: state),
                                 armourIgnored: armourIgnored)
    }

    // MARK: Skills

    /// **Everything this member can do**, in catalogue order.
    ///
    /// One each was the whole player side of combat while foes had trait-derived armour, damage
    /// character, reach and retaliation (`resources-skills-spec.md` §2, audit #9's second priority).
    /// **What somebody can do, from where they spent** (`docs/combat-trees-full.md`).
    ///
    /// It used to read `SkillDef.Owner` — *the Binder's skills, or the companion's* — which was a
    /// fossil of a party that was exactly two people with fixed lists. Skills come from branches
    /// now, so a smith who spent in Shadow can Conceal and a soldier who didn't, can't.
    ///
    /// Identity techniques remain separate from graph ownership: Binder carries Unbind/Sight,
    /// Quill carries Mend/Read, and Ashe carries Ground. `SkillDef.owner` and Rout are legacy input.
    static func skills(for actor: Combatant, in state: GameState) -> [SkillDef] {
        var owned = CombatActionOwnershipRules.availableSkillIDs(for: actor, in: state)
        if let modern = state.worlds.activeRun?.activeEncounter?.debugV2OwnedNodeIDs {
            owned.subtract(["steady", "snuff", "interpose", "draw_off", "quicken",
                            "overbear", "first_strike"])
            if modern[actor]?.contains(CombatDerivedStatsRules.Node.quench) == true {
                owned.insert("quench")
            }
            if modern[actor]?.contains(CombatDerivedStatsRules.Node.snuff) == true {
                owned.insert("snuff")
            }
            if modern[actor]?.contains(CombatDerivedStatsRules.Node.interpose) == true {
                owned.insert("interpose")
            }
            if modern[actor]?.contains(CombatDerivedStatsRules.Node.drawOff) == true {
                owned.insert("draw_off")
            }
            if modern[actor]?.contains(quickenNode) == true { owned.insert("quicken") }
            if modern[actor]?.contains(overbearNode) == true { owned.insert("overbear") }
            if modern[actor]?.contains(firstStrikeNode) == true { owned.insert("first_strike") }
        }
        return ContentCatalog.shared.skills.filter { owned.contains($0.id) }
    }

    private static func modernQuenchSkill(for actor: Combatant,
                                           encounter: EncounterState) -> SkillDef? {
        guard encounter.debugV2OwnedNodeIDs?[actor]?.contains(
            CombatDerivedStatsRules.Node.quench) == true else { return nil }
        return ContentCatalog.shared.skill("quench")
    }

    /// The first skill of a kind this member could use *right now*. Nil if they haven't got one or
    /// it's still cooling.
    static func ready(_ kind: SkillDef.Kind, for actor: Combatant,
                      in encounter: EncounterState, state: GameState) -> SkillDef? {
        skills(for: actor, in: state).first {
            $0.kind == kind && isReady($0, for: actor, in: encounter)
        }
    }

    /// What a gambit means by "use a skill" now that there are twelve.
    ///
    /// Heal a hurt ally if anything is hurt and a heal is up; otherwise the strongest ready thing
    /// that isn't a heal. Deliberately simple — the player's own rule list is where nuance belongs,
    /// and inventing a hidden priority order here would fight it.
    static func bestReadySkill(for actor: Combatant, in encounter: EncounterState,
                               state: GameState) -> SkillDef? {
        guard let run = state.worlds.activeRun else { return nil }
        let hurt = party(of: state).contains {
            let hp = health(of: $0, in: run)
            return hp.current > 0 && hp.current < hp.max
        }
        if hurt, let heal = ready(.heal, for: actor, in: encounter, state: state) { return heal }
        if encounter.debugV2OwnedNodeIDs?[actor]?.contains(CombatDerivedStatsRules.Node.ward) == true,
           let ward = ContentCatalog.shared.skill("ward"), isReady(ward, for: actor, in: encounter),
           recommendedWardHarm(in: encounter) != nil {
            return ward
        }
        if let quench = modernQuenchSkill(for: actor, encounter: encounter),
           isReady(quench, for: actor, in: encounter),
           party(of: state).contains(where: {
               isAlive($0, in: run) && !quenchEligibleAfflictions(on: $0, in: encounter).isEmpty
           }) {
            return quench
        }
        return skills(for: actor, in: state)
            .filter { $0.kind != .heal && $0.kind != .rout }
            .filter { isReady($0, for: actor, in: encounter) }
            .max { $0.power < $1.power }
    }

    /// Cooldowns are keyed per skill, because twelve sharing one timer means picking the best and
    /// never seeing the other eleven.
    static func cooldownKey(_ skill: SkillDef, for actor: Combatant) -> String {
        "\(actor.storageKey)|\(skill.id.rawValue)"
    }

    static func cooldown(of skill: SkillDef, for actor: Combatant,
                         in encounter: EncounterState) -> Int {
        if let counted = encounter.cooldowns[cooldownKey(skill, for: actor)] { return counted }
        if skill.id == "quench",
           let legacy = encounter.cooldowns["\(actor.storageKey)|steady"] { return legacy }
        // **Only** a save written before per-skill timers existed falls back to the single number,
        // and only while nothing has been used since. Reading the legacy field the moment any key
        // is missing would put every unused skill on the cooldown of the one you just spent.
        guard encounter.cooldowns.isEmpty else { return 0 }
        switch actor {
        case .binder: return encounter.binderSkillCooldown
        case .companion: return encounter.companionSkillCooldown
        case .foe: return 0
        }
    }

    static func isReady(_ skill: SkillDef, for actor: Combatant, in encounter: EncounterState) -> Bool {
        guard cooldown(of: skill, for: actor, in: encounter) == 0 else { return false }
        if usesPersonalTurnAuthority(encounter) {
            if skill.kind == .quicken {
                guard encounter.personalTurn?.owner == actor,
                      encounter.personalTurn?.setupAvailable == true,
                      encounter.personalTurn?.normalCreditsRemaining == 1,
                      encounter.personalTurn?.expansionSource == nil else { return false }
            }
            if skill.kind == .preempt {
                guard encounter.firstNormalActionCompleted?.contains(actor) == false else { return false }
            }
        }
        if skill.kind == .ambush {
            guard !encounter.completedFirstActions.contains(actor),
                  !encounter.openingAttackConsumed.contains(actor)
            else { return false }
            switch encounter.opening?.resolved {
            case .creatureAmbush: return false
            case .scripted(_, _, let allowsPartyOpeningAttack): return allowsPartyOpeningAttack
            case .partyApproach, .mutualContact: return true
            case nil: return false
            }
        }
        return true
    }

    /// Exact consequence shown before the ordinary retreat commits.
    static func withdrawalStabilityCost(for actor: Combatant, in state: GameState) -> Double {
        canVanishWithdraw(actor, in: state) ? 0 : Tuning.Encounter.fleeStabilityCost
    }

    private static func canVanishWithdraw(_ actor: Combatant, in state: GameState) -> Bool {
        guard let run = state.worlds.activeRun else { return false }
        return loadout(of: actor, in: state).freeFlee && !run.vanishWithdrawSpent
    }

    /// Frozen v2 bonus for the two explicitly typed weapon techniques in this first slice.
    /// Unbind and other legacy `.damage` skills are intentionally not weapon hits.
    private static func debugV2WeaponTechniqueBonus(for actor: Combatant, kind: DamageKind,
                                                     encounter: EncounterState) -> Int {
        guard actor == .binder, let receipt = encounter.debugV2BinderAttack else { return 0 }
        return receipt.preMatchupBonus(for: kind).total
    }

    /// **Every skill's effect.**
    ///
    /// The design rule the whole set is built on (`resources-skills-spec.md` §2): *every skill
    /// answers a specific kind of creature.* If it's good against everything it's just a bigger
    /// attack. So each of these reads something the creature system already computes — its
    /// covering, its armour, what it gives off — and is worth reaching for exactly when that
    /// reading is bad news.
    @discardableResult
    private static func use(_ skill: SkillDef, by actor: Combatant,
                            on foeID: InstanceID?, ally: Combatant?,
                            run: inout WorldRun, encounter: inout EncounterState,
                            weaponKind: DamageKind?, stats: CharacterStats?,
                            standingBack: Bool, reach: Reach,
                            state: inout GameState) -> Bool? {
        let foe = foeID.flatMap { id in encounter.foes.first { $0.id == id && $0.isAlive } }
        let committedDirectAttack = isDirectAttack(skill.kind) && foe != nil
        // **Wit is what a skill is worth in your hands** (session 17 §1) — potency here, and the
        // cooldown at the bottom of this function.
        let power = stats.map { CharacterRules.skillPower(skill.power, $0) } ?? skill.power
        let rankNow: Rank = standingBack ? .back : .front

        switch skill.kind {
        case .damage:
            guard let foe else { return nil }
            strike(foe.id, damage: power, by: actor, kind: skill.damage ?? weaponKind,
                   run: &run, encounter: &encounter, verb: skill.name,
                   standingBack: standingBack, reachOfActor: reach)

        case .heal:
            let target = ally ?? actor
            let amount = roll(around: power, run: &run)
            heal(target, by: amount, run: &run, encounter: &encounter, source: skill.name, healer: actor)

        case .armourIgnoring:
            // **Pry.** Goes under the plate entirely, and hits for very little. The answer to a
            // bulwark whose armour is eating four fifths of every honest swing.
            guard let foe else { return nil }
            guard let profile = targetedWeaponTechniqueProfile(skill, actor: actor, foe: foe,
                                                                encounter: encounter, state: state) else { return nil }
            strike(foe.id, damage: profile.power, by: actor, kind: profile.kind,
                   run: &run, encounter: &encounter, verb: skill.name, ignoresArmour: true,
                   standingBack: standingBack, reachOfActor: reach,
                   coating: coating(of: actor, in: state),
                   breaking: wildRule(for: actor, in: state),
                   innateStatus: equipped(.weapon, for: actor, in: state)?.gear?.statusKind,
                   allowsConditionalDirectHit: true)

        case .overbear:
            // **Overbear.** All your weight behind it, and you're out of position afterwards.
            guard let foe else { return nil }
            strike(foe.id, damage: power + debugV2WeaponTechniqueBonus(for: actor, kind: .crush,
                                                                       encounter: encounter),
                   by: actor, kind: .crush,
                   run: &run, encounter: &encounter, verb: skill.name,
                   standingBack: standingBack, reachOfActor: reach, allowsStagger: true,
                   allowsConditionalDirectHit: true)
            encounter.skippedTurns[actor, default: 0] += 1
            encounter.note("You're off balance.")

        case .bleed:
            // **Flense.** Scales with how much covering there is to open — nothing on a plated
            // thing, a great deal on something shaggy. The mirror of the creature system's own rend.
            guard let foe else { return nil }
            let purchase = (foe.traits?.covering.insulation ?? 0) / Tuning.Pressure.scaleMaximum
            let perRound = flenseTickDamage(power: skill.power,
                                            covering: foe.traits?.covering ?? Covering())
            _ = applyAffliction(.bleed, to: .foe(foe.id), source: actor,
                                provenance: .direct, damage: perRound, ticks: skill.rounds,
                                targetIsStanding: foe.isAlive, encounter: &encounter)
            encounter.note(purchase < Tuning.Encounter.thinCovering
                           ? "\(skill.name): there's nothing here to open."
                           : "\(skill.name). \(foe.stats.displayName) is bleeding.")

        case .reveal:
            // **Sight.** The covering word is what the whole damage triangle is read off, and
            // without this you only learn it by taking a bad trade first.
            guard let foe else { return nil }
            encounter.revealed.insert(foe.id)
            remember(foe, in: &state.reality.discovery, runIndex: run.runIndex)
            let covering = foe.coveringWord ?? "nothing much"
            // **Knowledge as equipment** (`crafting-spec.md` PART TWO). Sight fits no combat branch
            // and was never meant to: what it tells you scales with how well you can *read*, so a
            // low tier says "plated" and a high one gives you the numbers behind it. That is the
            // payoff for the analysis axis reaching outside the writing desk.
            var line = "\(foe.stats.displayName): \(covering), and it \(foe.stats.damageKind.verb)."
            if state.reality.analysisTier >= Tuning.Analysis.targetsTier {
                line += " \(foe.currentHP) of \(foe.stats.maxHP) health, \(foe.stats.armour) armour."
            }
            if state.reality.analysisTier >= Tuning.Analysis.sigilAttributionTier {
                line += " It strikes for about \(foe.stats.attack)."
            }
            encounter.note(line)

        case .ward:
            // **Ward.** Against one of six things, which is the point — you have to know what's
            // coming, and Sight is how you find out. A ward against "elemental" in general would be
            // the good-against-everything shape the whole skill set is built to avoid.
            // Modern v2 Ward is a typed `CombatAction.ward`; an unquoted skill action must not
            // infer a hidden harm. Legacy encounters retain their saved duration-shaped behavior.
            guard encounter.wardReceipts == nil else { return nil }
            let against = skill.damage.map(Harm.blow) ?? mostCommonIncoming(in: encounter)
            encounter.wards[actor] = WardState(against: against, rounds: skill.rounds)
            encounter.note("\(skill.name): set against \(against.displayName).")

        case .taunt:
            // **Draw Off.** The only way to take a hit meant for somebody else.
            guard let foe else { return nil }
            if encounter.drawOffReceipts != nil {
                guard encounter.debugV2OwnedNodeIDs?[actor]?.contains(
                    CombatDerivedStatsRules.Node.drawOff) == true,
                      foe.isAlive, encounter.revealed.contains(foe.id)
                else { return nil }
                encounter.drawOffReceipts?[foe.id] = .init(owner: actor,
                    activationRound: encounter.roundNumber,
                    expiresBeforeRound: encounter.roundNumber + 2)
                encounter.concealed[actor] = nil
            } else {
                encounter.taunts[foe.id] = skill.rounds
            }
            encounter.note("\(foe.stats.displayName) turns on you.")

        case .snuff:
            // **Snuff.** Puts out whatever it was giving off — which is what was doing damage every
            // round whether you touched it or not.
            guard let foe else { return nil }
            if encounter.snuffReceipts != nil {
                guard encounter.debugV2OwnedNodeIDs?[actor]?.contains(
                    CombatDerivedStatsRules.Node.snuff) == true,
                      encounter.revealed.contains(foe.id), foe.isAlive,
                      foe.stats.element != nil,
                      (encounter.snuffReceipts?[foe.id]?.remainingScheduledTurns ?? 0) < 2
                else { return nil }
                encounter.snuffReceipts?[foe.id] = .init(remainingScheduledTurns: 2,
                                                          suppressedRound: nil)
            } else {
                encounter.snuffed.insert(foe.id)
            }
            encounter.note("\(foe.stats.displayName) goes dark.")

        case .quicken:
            if !usesPersonalTurnAuthority(encounter) {
                encounter.extraTurns[actor, default: 0] += 1
                encounter.skippedTurns[actor, default: 0] += 1
                encounter.note("\(skill.name).")
                break
            }
            guard encounter.personalTurn?.owner == actor,
                  encounter.personalTurn?.setupAvailable == true,
                  encounter.personalTurn?.normalCreditsRemaining == 1,
                  encounter.personalTurn?.expansionSource == nil else { return nil }
            encounter.personalTurn?.setupAvailable = false
            encounter.personalTurn?.normalCreditsRemaining = 2
            encounter.personalTurn?.expansionSource = .quicken
            encounter.skippedTurns[actor, default: 0] += 1
            encounter.note("\(skill.name): two actions now, one turn owed.")

        case .cleanse:
            // Legacy `steady` is the decode route for Quench. It may remove one eligible
            // Burn/Poison/Dazzle only when that choice is unambiguous; Bleed remains treatment.
            // Exact v2 Quench uses `CombatAction.quench`; never let the decode-only `steady`
            // technique select a modern row or spend a modern turn implicitly.
            guard encounter.debugV2OwnedNodeIDs == nil else { return nil }
            let target = ally ?? actor
            adoptLegacyAfflictions(in: &encounter)
            let eligible = afflictions(on: target, in: encounter).filter {
                AfflictionDefinition.definition($0.kind).cures.contains(.quench)
            }
            guard eligible.count == 1, let chosen = eligible.first else { return nil }
            encounter.afflictions?.removeAll { $0.applicationReceipt == chosen.applicationReceipt }
            encounter.note("\(skill.name): the \(chosen.kind.rawValue) stops.")

        case .rout:
            // **Rout.** Leaving without the world noticing — the answer to a fight you shouldn't
            // have started, and the reason fleeing stops being a pure penalty.
            encounter.note("You break away clean.")
            encounter.outcome = .fled

        case .reposition:
            // **Fall Back.** The last of the twelve, and it was waiting on ranks rather than on
            // anything else (`resources-skills-spec.md` §2). Swapping where you stand *without*
            // spending the turn is the whole point — otherwise you'd just take the hit.
            let swapped: Rank = rankNow == .front ? .back : .front
            if actor.isParty { encounter.partyRanks[actor] = swapped }
            if usesPersonalTurnAuthority(encounter) {
                encounter.personalTurn?.setupAvailable = false
            } else {
                encounter.extraTurns[actor, default: 0] += 1
            }
            encounter.note(swapped == .back ? "You give ground." : "You step up.")

        case .read:
            // **Read.** A bestiary entry without a kill, which makes collecting a thing you can do
            // *instead* of killing rather than only by killing.
            guard let foe else { return nil }
            encounter.revealed.insert(foe.id)
            remember(foe, in: &state.reality.discovery, runIndex: run.runIndex)
            encounter.note("You take \(foe.stats.displayName) in properly. You'll know it again.")

        // MARK: The ten the combat trees teach

        case .sunder:
            // **Shatter.** The one thing that changes what a foe *is* for the rest of the fight.
            guard let foe, let index = encounter.foes.firstIndex(where: { $0.id == foe.id }) else { return nil }
            let taken = min(encounter.foes[index].stats.armour, max(1, power))
            encounter.foes[index].stats.armour -= taken
            encounter.note("\(skill.name). \(foe.stats.displayName) is \(taken) less protected than it was.")

        case .execute:
            // **Finish.** Large, and only against something already nearly gone — so it rewards
            // having done the work rather than replacing it.
            guard let foe else { return nil }
            guard let profile = targetedWeaponTechniqueProfile(skill, actor: actor, foe: foe,
                                                                encounter: encounter, state: state) else { return nil }
            strike(foe.id, damage: profile.power, by: actor, kind: profile.kind,
                   run: &run, encounter: &encounter, verb: skill.name,
                   standingBack: standingBack, reachOfActor: reach,
                   coating: coating(of: actor, in: state),
                   breaking: wildRule(for: actor, in: state),
                   innateStatus: equipped(.weapon, for: actor, in: state)?.gear?.statusKind,
                   allowsConditionalDirectHit: true)

        case .preempt:
            if !usesPersonalTurnAuthority(encounter) {
                encounter.extraTurns[actor, default: 0] += 1
                encounter.note("\(skill.name): you move before they do.")
                break
            }
            guard let foe,
                  encounter.firstNormalActionCompleted?.contains(actor) == false else { return nil }
            let bonus = firstStrikeRawBonus(actor: actor, encounter: encounter)
            guard bonus > 0 else { return nil }
            strike(foe.id, damage: baseAttack(of: actor, in: state) + bonus, by: actor,
                   kind: weaponKind, run: &run, encounter: &encounter, verb: skill.name,
                   standingBack: standingBack, reachOfActor: reach,
                   coating: coating(of: actor, in: state),
                   breaking: wildRule(for: actor, in: state),
                   innateStatus: equipped(.weapon, for: actor, in: state)?.gear?.statusKind,
                   allowsStagger: true, allowsConditionalDirectHit: true,
                   allowsRetaliation: false)

        case .ambush:
            // A conditional zero-turn direct attack. The extra-turn debt keeps the ordinary
            // schedule on this actor after `perform` hands on; the receipt survives relaunch.
            guard let foe, !encounter.openingAttackConsumed.contains(actor) else { return nil }
            encounter.openingAttackConsumed.insert(actor)
            if !usesPersonalTurnAuthority(encounter) {
                encounter.extraTurns[actor, default: 0] += 1
            }
            strike(foe.id, damage: power, by: actor, kind: skill.damage ?? weaponKind,
                   run: &run, encounter: &encounter, verb: skill.name,
                   standingBack: standingBack, reachOfActor: reach, allowsStagger: true,
                   allowsConditionalDirectHit: true, directAttackWindow: .opening)

        case .brace:
            if encounter.debugV2OwnedNodeIDs != nil {
                guard owns(CombatDerivedStatsRules.Node.brace, actor: actor,
                           encounter: encounter) else { return nil }
                encounter.braceReceipts?[actor] = .init(owner: actor)
            } else {
                encounter.braced[actor] = skill.rounds
            }
            encounter.note("\(skill.name): you set yourself.")

        case .dodge:
            encounter.dodging[actor] = skill.rounds
            encounter.note("\(skill.name): the next one finds nothing.")

        case .conceal:
            encounter.concealed[actor] = skill.rounds
            encounter.note("\(skill.name): they lose sight of you.")

        case .intercept:
            if encounter.interposeReceipts != nil {
                guard encounter.debugV2OwnedNodeIDs?[actor]?.contains(
                    CombatDerivedStatsRules.Node.interpose) == true else { return nil }
                encounter.interposeReceipts?.removeAll { $0.owner == actor }
                encounter.interposeReceipts?.append(.init(
                    owner: actor, activationSequence: encounter.nextInterposeActivationSequence))
                encounter.nextInterposeActivationSequence &+= 1
            } else {
                encounter.interposing[actor] = skill.rounds
            }
            encounter.note("\(skill.name): you step in front.")

        case .ground:
            encounter.grounding[actor] = skill.rounds
            encounter.note("\(skill.name): Ashe prepares to receive what escapes its housing.")

        case .envenom:
            encounter.envenomed[actor] = skill.rounds + Tuning.TreeSkills.envenomExtraRounds
            encounter.note("\(skill.name): coated, and it will last a while.")

        case .elemental:
            // **Emanation Strike.** The answer to a warded foe: emanated harm delivered by a blade.
            guard let foe else { return nil }
            let result = strike(foe.id, damage: power, by: actor, kind: skill.damage ?? weaponKind,
                                run: &run, encounter: &encounter, verb: skill.name,
                                standingBack: standingBack, reachOfActor: reach,
                                defersCarriedDamage: true, isEmanation: true)
            // Conduction copies the authored payload, not whatever survived the primary target's
            // Stonebark/refresh rules. The secondary independently gets its own protection check.
            let authoredPayload = AfflictionInstance(
                kind: .burn, target: .foe(foe.id), source: actor, provenance: .direct,
                damage: max(1, power / 4), ticksRemaining: skill.rounds + 1,
                applicationReceipt: 0)
            if let landed = result.landed {
                _ = applyAffliction(.burn, to: .foe(foe.id), source: actor,
                                    provenance: .direct, damage: authoredPayload.damage,
                                    ticks: authoredPayload.ticksRemaining,
                                    targetIsStanding: encounter.foes.first {
                                        $0.id == foe.id
                                    }?.isAlive == true,
                                    encounter: &encounter)
                resolveCarriedDamage(from: landed, primaryAffliction: authoredPayload,
                                     run: &run, encounter: &encounter)
            }
        }

        let cooling = stats.map { CharacterRules.cooldown(skill.cooldownRounds, $0) } ?? skill.cooldownRounds
        encounter.cooldowns[cooldownKey(skill, for: actor)] = cooling
        setCooldown(cooling, for: actor, in: &encounter)
        return committedDirectAttack
    }

    /// A bestiary entry without a kill — which is what makes Read a real alternative to killing
    /// rather than a convenience.
    private static func remember(_ foe: FoeState, in discovery: inout DiscoveryLog, runIndex: Int) {
        discovery.recordSpecies(foe.identityKey, runIndex: runIndex)
        if foe.isApex { discovery.recordApex(foe.id, species: foe.identityKey, runIndex: runIndex) }
        if let traits = foe.traits {
            discovery.recordSpecimen(traits, of: foe.identityKey, runIndex: runIndex)
        }
    }

    /// What most of what's still standing brings, so a Ward with nothing stated guards the likeliest
    /// thing rather than nothing. **An emanation wins over a blow** — nothing you wear stops one,
    /// so it's the harm most worth turning aside.
    private static func mostCommonIncoming(in encounter: EncounterState) -> Harm {
        let elements = encounter.livingFoes.compactMap(\.stats.element)
        if let commonest = EmanationKind.allCases.max(by: { a, b in
            elements.count { $0 == a } < elements.count { $0 == b }
        }), elements.contains(commonest) {
            return .emanation(commonest)
        }
        let kinds = encounter.livingFoes.map(\.stats.damageKind)
        return .blow(DamageKind.allCases.max { a, b in
            kinds.count { $0 == a } < kinds.count { $0 == b }
        } ?? .pierce)
    }

    static func disclosedWardHarms(in encounter: EncounterState) -> Set<Harm> {
        Set(encounter.livingFoes.compactMap { foe -> Harm? in
            guard encounter.revealed.contains(foe.id) else { return nil }
            return foe.stats.element.map(Harm.emanation) ?? .blow(foe.stats.damageKind)
        })
    }

    static func recommendedWardHarm(in encounter: EncounterState) -> Harm? {
        let harms = disclosedWardHarms(in: encounter)
        guard !harms.isEmpty else { return nil }
        let stable = DamageKind.allCases.map(Harm.blow) + EmanationKind.allCases.map(Harm.emanation)
        return stable.max { lhs, rhs in
            let left = encounter.livingFoes.count { foe in
                encounter.revealed.contains(foe.id)
                    && (foe.stats.element.map(Harm.emanation) ?? .blow(foe.stats.damageKind)) == lhs
            }
            let right = encounter.livingFoes.count { foe in
                encounter.revealed.contains(foe.id)
                    && (foe.stats.element.map(Harm.emanation) ?? .blow(foe.stats.damageKind)) == rhs
            }
            return left < right
        }.flatMap { harms.contains($0) ? $0 : nil }
    }

    // MARK: Harm that outlives the blow

    enum AfflictionApplicationOutcome: Equatable {
        case prevented, noChange, added(AfflictionInstance)
        case damageStrengthened(AfflictionInstance)
        case durationStrengthened(AfflictionInstance)
        case bothStrengthened(AfflictionInstance)

        var appliedInstance: AfflictionInstance? {
            switch self {
            case .added(let row), .damageStrengthened(let row),
                 .durationStrengthened(let row), .bothStrengthened(let row): row
            case .prevented, .noChange: nil
            }
        }
    }

    private static func owns(_ node: CombatNodeID, actor: Combatant?,
                             encounter: EncounterState) -> Bool {
        guard let actor else { return false }
        return encounter.debugV2OwnedNodeIDs?[actor]?.contains(node) == true
    }

    /// One-time adoption boundary. Nil is the only legacy marker; modern empty stays empty.
    static func adoptLegacyAfflictions(in encounter: inout EncounterState) {
        encounter.adoptLegacyAfflictionsIfNeeded()
    }

    @discardableResult
    static func applyAffliction(_ kind: AfflictionID, to target: Combatant,
                                source: Combatant?, provenance: AfflictionProvenance,
                                contributingProvenances: Set<AfflictionProvenance>? = nil,
                                damage: Int, ticks: Int, endless: Bool = false,
                                targetIsStanding: Bool,
                                bypassGuard: Bool = false,
                                encounter: inout EncounterState) -> AfflictionApplicationOutcome {
        adoptLegacyAfflictions(in: &encounter)
        guard targetIsStanding else { return .noChange }
        let definition = AfflictionDefinition.definition(kind)
        let proposedDamage = definition.allowsSeverityOverride ? max(0, damage) : definition.defaultDamage
        let eligibleVirulence = [.direct, .coating].contains(provenance)
            && owns(CombatDerivedStatsRules.Node.virulence, actor: source, encounter: encounter)
        let authoredTicks = (definition.allowsDurationOverride ? max(0, ticks) : definition.defaultTicks)
            + (eligibleVirulence && !endless ? 2 : 0)
        // Constitution's later consumer transforms this prospective value here, before refresh.
        // Keeping the named boundary prevents Virulence being retroactively added to an old row.
        let proposedTicks = CombatDerivedStatsRules.constitutionTicks(
            authored: authoredTicks, endless: endless,
            ownsNode: owns(CombatDerivedStatsRules.Node.constitution,
                           actor: target, encounter: encounter))
        let index = encounter.afflictions?.firstIndex { $0.target == target && $0.kind == kind }
        let old = index.flatMap { encounter.afflictions?[$0] }
        let changes = old == nil
            || proposedDamage > (old?.damage ?? 0)
            || endless && old?.endless != true
            || (!endless && old?.endless != true && proposedTicks > (old?.ticksRemaining ?? 0))
        guard changes else { return .noChange }
        if !bypassGuard, definition.stonebarkEligible,
           consumeStatusGuard(on: target, encounter: &encounter) {
            return .prevented
        }

        let higherDamage = proposedDamage > (old?.damage ?? -1)
        let receipt = encounter.nextAfflictionReceipt
        encounter.nextAfflictionReceipt &+= 1
        var merged = AfflictionInstance(
            kind: kind, target: target,
            source: higherDamage ? source : old?.source,
            provenance: higherDamage ? provenance : (old?.provenance ?? provenance),
            damage: max(old?.damage ?? 0, proposedDamage),
            ticksRemaining: max(old?.ticksRemaining ?? 0, proposedTicks),
            endless: old?.endless == true || endless,
            applicationReceipt: receipt
        )
        merged.provenances.formUnion(old?.provenances ?? [])
        merged.provenances.formUnion(contributingProvenances ?? [provenance])
        if let index { encounter.afflictions?[index] = merged }
        else { encounter.afflictions?.append(merged) }
        let outcome: AfflictionApplicationOutcome
        if let old {
            let damageChanged = merged.damage > old.damage || (merged.endless && !old.endless)
            let durationChanged = merged.ticksRemaining > old.ticksRemaining
            outcome = switch (damageChanged, durationChanged) {
            case (true, true): .bothStrengthened(merged)
            case (true, false): .damageStrengthened(merged)
            case (false, true): .durationStrengthened(merged)
            case (false, false): .noChange
            }
        } else {
            outcome = .added(merged)
        }

        // Blight copies the prospective authored Poison, never the older merged row. Copied
        // provenance makes this recursive call ineligible for both Virulence and another Blight.
        if kind == .poison, [.direct, .coating].contains(provenance),
           owns(CombatDerivedStatsRules.Node.blight, actor: source, encounter: encounter),
           outcome.appliedInstance != nil,
           case .foe(let primaryID) = target, let source {
            let secondary = encounter.foes
                .filter { $0.id != primaryID && $0.isAlive && encounter.revealed.contains($0.id) }
                .sorted { $0.id.rawValue < $1.id.rawValue }
                .first
            if let secondary {
                _ = applyAffliction(.poison, to: .foe(secondary.id), source: source,
                                    provenance: .copied,
                                    damage: max(1, (proposedDamage + 1) / 2),
                                    ticks: max(1, (authoredTicks + 1) / 2),
                                    targetIsStanding: true, encounter: &encounter)
            }
        }
        return outcome
    }

    static func foeArmourBreakdown(_ foe: FoeState, encounter: EncounterState,
                                   ignoredFraction: Double = 0)
        -> CombatDerivedStatsRules.FoeArmourBreakdown {
        CombatDerivedStatsRules.foeArmour(base: foe.stats.armour,
            erosion: encounter.foeArmourErosion[foe.id] ?? 0,
            ignoredFraction: ignoredFraction)
    }

    private static func consumeStatusGuard(on target: Combatant,
                                           encounter: inout EncounterState) -> Bool {
        guard (encounter.statusGuards[target] ?? 0) > 0 else { return false }
        encounter.statusGuards[target, default: 0] -= 1
        if encounter.statusGuards[target] == 0 { encounter.statusGuards[target] = nil }
        encounter.note("The Stonebark holds; the affliction does not take.")
        return true
    }

    static func has(_ kind: StatusKind, _ actor: Combatant, in encounter: EncounterState) -> Bool {
        encounter.afflictions?.contains { $0.target == actor && $0.kind == kind.afflictionID }
            ?? (encounter.statuses[actor] ?? []).contains { $0.kind == kind }
    }

    static func afflictions(on target: Combatant,
                            in encounter: EncounterState) -> [AfflictionInstance] {
        var normalized = encounter
        adoptLegacyAfflictions(in: &normalized)
        return (normalized.afflictions ?? []).filter { $0.target == target }.sorted {
            AfflictionDefinition.definition($0.kind).order
                < AfflictionDefinition.definition($1.kind).order
        }
    }

    static func eligibleAfflictions(for effect: ConsumableDef.Effect, on target: Combatant,
                                    in encounter: EncounterState) -> [AfflictionInstance] {
        let family: AfflictionCureFamily? = switch effect {
        case .clearPoison: .clearing
        case .clearElemental: .quenching
        case .clearAnyStatus: .broad
        default: nil
        }
        guard let family else { return [] }
        return afflictions(on: target, in: encounter).filter {
            AfflictionDefinition.definition($0.kind).cures.contains(family)
        }
    }

    /// Rules-owned cure commit. Group cures remove their entire authored family; Broad removes the
    /// sole eligible kind or the exact player-selected kind and rejects stale/ambiguous input.
    @discardableResult
    static func cureAfflictions(for effect: ConsumableDef.Effect, on target: Combatant,
                                selectedReceipt: UInt64?,
                                encounter: inout EncounterState) -> Bool {
        adoptLegacyAfflictions(in: &encounter)
        let eligible = eligibleAfflictions(for: effect, on: target, in: encounter)
        guard !eligible.isEmpty else { return false }
        if effect == .clearAnyStatus {
            let chosen: AfflictionInstance?
            if let selectedReceipt {
                chosen = eligible.first { $0.applicationReceipt == selectedReceipt }
            }
            else { chosen = eligible.count == 1 ? eligible[0] : nil }
            guard let chosen else { return false }
            encounter.afflictions?.removeAll {
                $0.target == target && $0.applicationReceipt == chosen.applicationReceipt
            }
        } else {
            let kinds = Set(eligible.map(\.kind))
            encounter.afflictions?.removeAll { $0.target == target && kinds.contains($0.kind) }
        }
        return true
    }

    @discardableResult
    static func quenchAffliction(on target: Combatant, selectedReceipt: UInt64,
                                 encounter: inout EncounterState) -> Bool {
        adoptLegacyAfflictions(in: &encounter)
        guard let chosen = afflictions(on: target, in: encounter).first(where: {
            $0.applicationReceipt == selectedReceipt
                && AfflictionDefinition.definition($0.kind).cures.contains(.quench)
        }) else { return false }
        encounter.afflictions?.removeAll { $0.applicationReceipt == chosen.applicationReceipt }
        return true
    }

    static func quenchEligibleAfflictions(on target: Combatant,
                                           in encounter: EncounterState) -> [AfflictionInstance] {
        afflictions(on: target, in: encounter).filter {
            AfflictionDefinition.definition($0.kind).cures.contains(.quench)
        }
    }

    /// **What somebody can take**, which is Fortitude on top of the base (session 17 §1).
    ///
    /// **This is also where the party is put right.** A run begins at these values and health is
    /// run-scoped, so coming home restores everybody — the run is the unit of risk and the base is
    /// where things are mended (Aimee, 6 Aug). Deliberately one place: staged recovery, a healer to
    /// pay, or resting at the tavern are all a change here rather than a hunt.
    static func maximumHealth(of actor: Combatant, in state: GameState) -> Int {
        switch actor {
        case .binder:
            CharacterRules.maximumHealth(state.base.binderCharacter, base: Tuning.Encounter.binderMaxHP)
                + loadout(of: actor, in: state).maxHP
        case .companion(let index):
            CharacterRules.maximumHealth(state.base.character(.member(index)),
                                         base: state.base.roster.indices.contains(index)
                                             ? state.base.roster[index].maxHP
                                             : Tuning.Encounter.companionMaxHP)
                + loadout(of: actor, in: state).maxHP
        case .foe:
            0
        }
    }

    static func expeditionHealthCaps(in state: GameState,
                                     tuning: DebugTuningProfile) -> [RunHealthCapEntry] {
        state.base.partyMembers.map { member in
            let actor = member.combatant
            let graph = ContentCatalog.shared.combatGraph
            let opening = CombatGraphRules.implementedOpeningNodeIDs(in: graph)
            var selected = (state.base.character(member).ownedCombatNodeIDs ?? [])
                .intersection(opening)
            if tuning.debugCombatV2BinderAttackEnabled {
                switch member {
                case .binder: selected.formUnion(tuning.debugCombatV2BinderNodeIDs)
                case .member(let index):
                    selected.formUnion(tuning.debugCombatV2CompanionNodeIDs[index] ?? [])
                }
            }
            let explicitV2 = tuning.debugCombatV2BinderAttackEnabled || !selected.isEmpty
            let ordinary: Int
            switch actor {
            case .binder:
                ordinary = CharacterRules.maximumHealth(state.base.binderCharacter,
                                                         base: Tuning.Encounter.binderMaxHP)
                    + (explicitV2 ? 0 : loadout(of: actor, in: state).maxHP)
            case .companion(let index):
                ordinary = CharacterRules.maximumHealth(
                    state.base.character(.member(index)),
                    base: state.base.roster.indices.contains(index)
                        ? state.base.roster[index].maxHP : Tuning.Encounter.companionMaxHP)
                    + (explicitV2 ? 0 : loadout(of: actor, in: state).maxHP)
            case .foe:
                ordinary = 1
            }
            let components: [RunHealthCapEntry.Component] = explicitV2
                && selected.contains(CombatDerivedStatsRules.Node.thickHide)
                ? [.init(nodeID: CombatDerivedStatsRules.Node.thickHide, amount: 6)] : []
            return RunHealthCapEntry(member: member, ordinaryMaximum: ordinary,
                                     components: components)
        }
    }

    @discardableResult
    static func reconcileExpeditionHealth(in state: inout GameState) -> Bool {
        guard var run = state.worlds.activeRun else { return false }
        var changed = false
        if run.healthCaps == nil {
            let proposed = Dictionary(uniqueKeysWithValues:
                expeditionHealthCaps(in: state, tuning: run.tuning).map { ($0.member, $0) })
            run.healthCaps = state.base.partyMembers.map { member -> RunHealthCapEntry in
                let current: Int
                switch member {
                case .binder: current = run.binderHP
                case .member(let index): current = run.companionHP[index] ?? 0
                }
                let draft = proposed[member] ?? RunHealthCapEntry(
                    member: member,
                    ordinaryMaximum: maximumHealth(of: member.combatant, in: state),
                    components: [])
                let componentTotal = draft.components.reduce(0) { $0 + $1.amount }
                // Preserve an already-saved current value. A historical Legacy run has no
                // component; a run whose frozen DEBUG-v2 tuning explicitly owned Thick Hide keeps
                // that provenance without receiving HP during adoption.
                let ordinary = max(draft.ordinaryMaximum, current - componentTotal)
                return RunHealthCapEntry(member: member, ordinaryMaximum: ordinary,
                                         components: draft.components)
            }
            changed = true
        }
        if let binderCap = run.healthCap(for: .binder), run.binderHP > binderCap.maximum {
            run.binderHP = binderCap.maximum
            changed = true
        }
        for (index, current) in run.companionHP {
            guard let cap = run.healthCap(for: .member(index)), current > cap.maximum else { continue }
            run.companionHP[index] = cap.maximum
            changed = true
        }
        guard changed else { return false }
        state.worlds.activeRun = run
        return true
    }

    static func health(of actor: Combatant, in run: WorldRun) -> (current: Int, max: Int) {
        if run.healthCaps != nil, actor.isParty {
            let member: PartyMember
            switch actor {
            case .binder: member = .binder
            case .companion(let index): member = .member(index)
            case .foe: preconditionFailure("foes do not have expedition health caps")
            }
            guard let cap = run.healthCap(for: member) else { return (0, 1) }
            switch actor {
            case .binder: return (min(run.binderHP, cap.maximum), cap.maximum)
            case .companion(let index):
                return (min(run.companionHP[index] ?? cap.maximum, cap.maximum), cap.maximum)
            case .foe: break
            }
        }
        switch actor {
        case .binder: return (run.binderHP, Tuning.Encounter.binderMaxHP)
        case .companion(let index):
            return (run.companionHP[index] ?? Tuning.Encounter.companionMaxHP,
                    Tuning.Encounter.companionMaxHP)
        case .foe(let id):
            return run.activeEncounter?.foes.first { $0.id == id }
                .map { ($0.currentHP, $0.maxHP) } ?? (0, 1)
        }
    }

    static func isAlive(_ actor: Combatant, in run: WorldRun) -> Bool {
        health(of: actor, in: run).current > 0
    }

    /// **Out of the fight, not out of the game** (session 17 §6). Nobody dies here — a companion at
    /// zero has passed out, takes no more turns, and is on their feet again at the base.
    static func hasPassedOut(_ actor: Combatant, in run: WorldRun) -> Bool {
        actor.isParty && health(of: actor, in: run).current <= 0
    }

    // MARK: Resolving one action

    /// Applies an action and hands the turn on. The only way an encounter advances.
    static func perform(_ action: CombatAction, by actor: Combatant, in state: inout GameState) {
        guard var run = state.worlds.activeRun, var encounter = run.activeEncounter, encounter.outcome == nil
        else { return }
        guard encounter.current == actor, isAlive(actor, in: run) else { return }
        adoptV2ReceiptLedgers(in: &encounter)
        normalizeV2EvasionState(&encounter)
        normalizePersonalTurn(&encounter, actor: actor)
        if case .skill(let id, _, _) = action {
            guard let skill = ContentCatalog.shared.skill(id),
                  owns(skill, actor: actor, encounter: encounter, state: state),
                  isReady(skill, for: actor, in: encounter)
            else {
                // Saved palette selections and old Rout actions remain decodable, but an action
                // the actor no longer owns cannot spend a turn during one-way migration.
                return
            }
        }
        if case .ward(let harm) = action {
            guard encounter.debugV2OwnedNodeIDs?[actor]?.contains(CombatDerivedStatsRules.Node.ward) == true,
                  let skill = ContentCatalog.shared.skill("ward"),
                  isReady(skill, for: actor, in: encounter),
                  disclosedWardHarms(in: encounter).contains(harm)
            else { return }
        }
        if case .quench(let ally, let receipt) = action {
            guard let skill = modernQuenchSkill(for: actor, encounter: encounter),
                  isReady(skill, for: actor, in: encounter), ally.isParty,
                  isAlive(ally, in: run),
                  quenchEligibleAfflictions(on: ally, in: encounter).contains(where: {
                      $0.applicationReceipt == receipt
                  }) else { return }
        }
        if action == .blur {
            guard encounter.debugV2OwnedNodeIDs?[actor]?.contains(blurNode) == true,
                  encounter.personalTurn?.owner == actor,
                  encounter.personalTurn?.setupAvailable == true,
                  encounter.personalTurn?.normalCreditsRemaining == 1,
                  encounter.personalTurn?.expansionSource == nil,
                  encounter.blurSpent?.contains(actor) == false else { return }
        }

        let actionCost = combatActionCost(action)
        if usesPersonalTurnAuthority(encounter), encounter.personalTurn?.owner == actor {
            if actionCost == .normal {
                guard (encounter.personalTurn?.normalCreditsRemaining ?? 0) > 0 else { return }
            } else if isPersonalSetup(action) {
                guard encounter.personalTurn?.setupAvailable == true,
                      encounter.personalTurn?.normalCreditsRemaining == 1,
                      encounter.personalTurn?.expansionSource == nil else { return }
            }
        }
        let feintWasActive = encounter.feintActive?.contains(actor) == true
        var outcome: CommittedActionOutcome = .rejected

        switch action {
        case .attack(let foeID):
            if strike(foeID, damage: baseAttack(of: actor, in: state), by: actor,
                   kind: damageKind(for: actor, in: state), run: &run, encounter: &encounter,
                   standingBack: rank(of: actor, in: encounter, fallback: state) == .back,
                   reachOfActor: reach(for: actor, in: state),
                   coating: coating(of: actor, in: state),
                   breaking: wildRule(for: actor, in: state),
                   innateStatus: equipped(.weapon, for: actor, in: state)?.gear?.statusKind,
                   allowsStagger: true, allowsConditionalDirectHit: true).committed {
                outcome = .committed(cost: actionCost, completedDirectAttack: true)
            }

        case .skill(let id, let foeID, let allyID):
            if let skill = ContentCatalog.shared.skill(id), owns(skill, actor: actor, encounter: encounter,
                                                                 state: state),
               isReady(skill, for: actor, in: encounter) {
                if let direct = use(skill, by: actor, on: foeID, ally: allyID,
                    run: &run, encounter: &encounter,
                    weaponKind: damageKind(for: actor, in: state),
                    stats: stats(of: actor, in: state),
                    standingBack: rank(of: actor, in: encounter, fallback: state) == .back,
                    reach: reach(for: actor, in: state), state: &state) {
                    outcome = .committed(cost: actionCost, completedDirectAttack: direct)
                }
            }

        case .ward(let harm):
            guard let skill = ContentCatalog.shared.skill("ward"), encounter.wardReceipts != nil else { break }
            encounter.wardReceipts?[actor] = .init(harm: harm, activationRound: encounter.roundNumber,
                                                    expiresBeforeRound: encounter.roundNumber + 2)
            let cooling = stats(of: actor, in: state)
                .map { CharacterRules.cooldown(skill.cooldownRounds, $0) } ?? skill.cooldownRounds
            encounter.cooldowns[cooldownKey(skill, for: actor)] = cooling
            setCooldown(cooling, for: actor, in: &encounter)
            encounter.note("Ward: set against \(harm.displayName) through round \(encounter.roundNumber + 1).")
            outcome = .committed(cost: .normal, completedDirectAttack: false)

        case .quench(let ally, let receipt):
            guard let skill = modernQuenchSkill(for: actor, encounter: encounter),
                  quenchAffliction(on: ally, selectedReceipt: receipt, encounter: &encounter)
            else { break }
            let cooling = stats(of: actor, in: state)
                .map { CharacterRules.cooldown(skill.cooldownRounds, $0) } ?? skill.cooldownRounds
            let key = cooldownKey(skill, for: actor)
            let legacyKey = "\(actor.storageKey)|steady"
            encounter.cooldowns[key] = max(cooling, encounter.cooldowns[legacyKey] ?? 0)
            encounter.cooldowns[legacyKey] = nil
            setCooldown(cooling, for: actor, in: &encounter)
            encounter.note("Quench: the selected affliction stops on \(actorName(ally, encounter: encounter)).")
            outcome = .committed(cost: .normal, completedDirectAttack: false)

        case .blur:
            encounter.personalTurn?.setupAvailable = false
            encounter.personalTurn?.normalCreditsRemaining = 2
            encounter.personalTurn?.expansionSource = .blur
            encounter.blurSpent?.insert(actor)
            encounter.note("Blur: two actions now.")
            outcome = .committed(cost: .zero, completedDirectAttack: false)

        case .damageSkill(let foeID):
            // The gambit vocabulary's "damage skill" — whichever damaging one is up.
            if let skill = skills(for: actor, in: state).first(where: {
                $0.power > 0 && $0.kind != .heal && isReady($0, for: actor, in: encounter)
            }) {
                if let direct = use(skill, by: actor, on: foeID, ally: nil,
                    run: &run, encounter: &encounter,
                    weaponKind: damageKind(for: actor, in: state),
                    stats: stats(of: actor, in: state),
                    standingBack: rank(of: actor, in: encounter, fallback: state) == .back,
                    reach: reach(for: actor, in: state), state: &state) {
                    outcome = .committed(cost: .normal, completedDirectAttack: direct)
                }
            }

        case .healSkill(let ally):
            if let skill = ready(.heal, for: actor, in: encounter, state: state) {
                if let direct = use(skill, by: actor, on: nil, ally: ally, run: &run, encounter: &encounter,
                    weaponKind: damageKind(for: actor, in: state),
                    stats: stats(of: actor, in: state),
                    standingBack: rank(of: actor, in: encounter, fallback: state) == .back,
                    reach: reach(for: actor, in: state), state: &state) {
                    outcome = .committed(cost: .normal, completedDirectAttack: direct)
                }
            }

        case .useItem(let stackID, let ally, let afflictionReceipt):
            if useItem(stackID, on: ally, afflictionReceipt: afflictionReceipt,
                       run: &run, encounter: &encounter) {
                outcome = .committed(cost: .normal, completedDirectAttack: false)
            }

        case .flee:
            // Always succeeds — it costs the run, not a dice roll. Vanish pays for one Withdraw
            // per expedition; the receipt prevents a later encounter in the same world reusing it.
            if canVanishWithdraw(actor, in: state) {
                run.vanishWithdrawSpent = true
                encounter.note("The party withdraws without disturbing the world.")
            } else {
                run.stability = max(0, run.stability - Tuning.Encounter.fleeStabilityCost)
                encounter.note("The party withdraws. The world notices.")
            }
            encounter.outcome = .fled
            outcome = .committed(cost: .normal, completedDirectAttack: false)
        }

        guard case .committed(let committedCost, let completedDirectAttack) = outcome else { return }

        // Ambush is a separate opening opportunity, not the actor's first normal-cost action.
        // Choosing anything else closes that opportunity even when the chosen setup action costs
        // no ordinary turn (for example Quicken or Fall Back).
        let completedAmbush: Bool = if case .skill(let id, _, _) = action {
            ContentCatalog.shared.skill(id)?.kind == .ambush
        } else { false }
        if !completedAmbush { encounter.openingAttackConsumed.insert(actor) }

        // Feint lasts through the consequences of the next normal-cost action. Expire the receipt
        // that existed at action start, then let a direct action arm/refresh the next one.
        if committedCost == .normal, feintWasActive { encounter.feintActive?.remove(actor) }
        if completedDirectAttack,
           encounter.debugV2Evasion?.entry(for: actor)?.ownsFeint == true,
           encounter.feintActive != nil {
            encounter.feintActive?.insert(actor)
        }
        if committedCost == .normal,
           encounter.rankAtPreviousCompletedAction != nil,
           let rank = encounter.partyRanks[actor] {
            encounter.rankAtPreviousCompletedAction?[actor] = rank
        }
        if committedCost == .normal { encounter.firstNormalActionCompleted?.insert(actor) }

        // The FF12 rule: an override covers that turn and then hands control back.
        if actor.rosterIndex != nil { encounter.isCompanionOverridden = false }
        // Recovery knowledge describes exactly the first completed action after the debt cleared.
        encounter.recoveryComplete.remove(actor)

        run.activeEncounter = encounter
        state.worlds.activeRun = run
        if encounter.outcome == nil {
            advanceTurn(in: &state, completedAction: committedCost == .normal)
        }
        checkOutcome(in: &state)
    }

    private static func isDirectAttack(_ kind: SkillDef.Kind) -> Bool {
        switch kind {
        case .damage, .armourIgnoring, .overbear, .execute, .ambush, .elemental: true
        default: false
        }
    }

    private static func owns(_ skill: SkillDef, actor: Combatant,
                             encounter: EncounterState, state: GameState) -> Bool {
        if skill.kind == .intercept, let frozen = encounter.debugV2OwnedNodeIDs {
            return frozen[actor]?.contains(CombatDerivedStatsRules.Node.interpose) == true
        }
        if skill.kind == .taunt, let frozen = encounter.debugV2OwnedNodeIDs {
            return frozen[actor]?.contains(CombatDerivedStatsRules.Node.drawOff) == true
        }
        if skill.kind == .snuff, let frozen = encounter.debugV2OwnedNodeIDs {
            return frozen[actor]?.contains(CombatDerivedStatsRules.Node.snuff) == true
        }
        if skill.id == "flense", let frozen = encounter.debugV2OwnedNodeIDs {
            return frozen[actor]?.contains(CombatDerivedStatsRules.Node.flense) == true
        }
        return skills(for: actor, in: state).contains(skill)
    }

    static func isSnuffed(_ foeID: InstanceID, in encounter: EncounterState) -> Bool {
        if let receipts = encounter.snuffReceipts {
            return receipts[foeID]?.suppressedRound == encounter.roundNumber
        }
        return encounter.snuffed.contains(foeID)
    }

    static func flenseTickDamage(power: Int = 9, covering: Covering) -> Int {
        let purchase = covering.insulation / Tuning.Pressure.scaleMaximum
        return max(1, Int((Double(power) * purchase).rounded()))
    }

    struct FlensePreview: Equatable, Sendable {
        var tickDamage: ClosedRange<Int>
        var ticks: Int
        var isExact: Bool
    }

    static func debugV2FlensePreview(actor: Combatant, foe: FoeState,
                                     in state: GameState) -> FlensePreview? {
        guard let encounter = state.worlds.activeRun?.activeEncounter,
              let skill = ContentCatalog.shared.skill("flense"),
              owns(skill, actor: actor, encounter: encounter, state: state), foe.isAlive
        else { return nil }
        guard encounter.revealed.contains(foe.id) else {
            return .init(tickDamage: 1...skill.power, ticks: skill.rounds, isExact: false)
        }
        let exact = flenseTickDamage(power: skill.power, covering: foe.traits?.covering ?? Covering())
        return .init(tickDamage: exact...exact, ticks: skill.rounds, isExact: true)
    }

    private enum CombatActionCost { case zero, normal }

    private enum CommittedActionOutcome {
        case rejected
        case committed(cost: CombatActionCost, completedDirectAttack: Bool)
    }

    enum DirectAttackWindow {
        case scheduled
        case opening
    }

    struct BreakingBlowEffect: Equatable, Sendable {
        var ignoresArmour: Bool
        var automaticStaggerAvailable: Bool
    }

    enum KillingStrokeOutcome: Equatable, Sendable {
        case none
        case defeat
        case apexDamage(Int)
    }

    struct KillingStrokePreview: Equatable, Sendable {
        var lower: KillingStrokeOutcome
        var upper: KillingStrokeOutcome
    }

    private static let killingStrokeNodeID = CombatNodeID(
        rawValue: "combat.offense.precision.killing_stroke"
    )
    private static let secondWindNodeID = CombatNodeID(
        rawValue: "combat.offense.swiftness.second_wind"
    )
    private static let rallyNodeID = CombatNodeID(
        rawValue: "combat.defense.protection.rally"
    )
    private static let cascadeNodeID = CombatNodeID(
        rawValue: "combat.offense.swiftness.cascade"
    )
    private static let flurryNodeID = CombatNodeID(
        rawValue: "combat.offense.swiftness.flurry"
    )
    private static let conductionNodeID = CombatNodeID(
        rawValue: "combat.craft.emanation.conduction"
    )

    /// The one authority shared by preview and commit. `primaryDamage` is the final positive HP
    /// loss from the eligible direct hit, after critical, armour and the global minimum.
    static func killingStrokeOutcome(actor: Combatant, primaryDamage: Int, foe: FoeState,
                                     allowsDirectHit: Bool,
                                     encounter: EncounterState) -> KillingStrokeOutcome {
        guard allowsDirectHit, primaryDamage > 0, foe.isAlive,
              encounter.debugV2OwnedNodeIDs?[actor]?.contains(killingStrokeNodeID) == true else {
            return .none
        }
        let remaining = max(0, foe.currentHP - primaryDamage)
        guard remaining > 0,
              remaining * 100 <= max(1, foe.stats.maxHP) * 15 else { return .none }
        return foe.isApex ? .apexDamage(4) : .defeat
    }

    static func killingStrokePreview(actor: Combatant, damage: CombatDamageRules.Preview,
                                     foe: FoeState,
                                     encounter: EncounterState) -> KillingStrokePreview {
        .init(lower: killingStrokeOutcome(actor: actor, primaryDamage: damage.lower.finalDamage,
                                          foe: foe, allowsDirectHit: true, encounter: encounter),
              upper: killingStrokeOutcome(actor: actor, primaryDamage: damage.upper.finalDamage,
                                          foe: foe, allowsDirectHit: true, encounter: encounter))
    }

    static func debugV2KillingStrokeAttackPreview(foe: FoeState,
                                                   in state: GameState) -> KillingStrokePreview? {
        guard let encounter = state.worlds.activeRun?.activeEncounter,
              let damage = debugV2DirectAttackPreview(foe: foe, in: state) else { return nil }
        return killingStrokePreview(actor: .binder, damage: damage, foe: foe, encounter: encounter)
    }

    static func debugV2KillingStrokeTechniquePreview(skillID: SkillID, actor: Combatant,
                                                      foe: FoeState,
                                                      in state: GameState) -> KillingStrokePreview? {
        guard let encounter = state.worlds.activeRun?.activeEncounter,
              let preview = debugV2DirectTechniquePreview(skillID: skillID, actor: actor,
                                                           foe: foe, in: state) else { return nil }
        return killingStrokePreview(actor: actor, damage: preview.damage, foe: foe,
                                    encounter: encounter)
    }

    @discardableResult
    static func applyFoeDamage(foeID: InstanceID, amount: Int, sourceActor: Combatant?,
                               provenance: EncounterState.FoeDamageProvenance,
                               sourceNodeID: CombatNodeID? = nil,
                               run: inout WorldRun,
                               encounter: inout EncounterState) -> EncounterState.DefeatTransition? {
        guard amount > 0,
              let index = encounter.foes.firstIndex(where: { $0.id == foeID }),
              encounter.foes[index].isAlive else { return nil }
        let before = encounter.foes[index].currentHP
        encounter.foes[index].currentHP = max(0, before - amount)
        guard before > 0, encounter.foes[index].currentHP == 0 else { return nil }
        guard provenance != .environment, sourceActor?.isParty == true else { return nil }
        let transition = EncounterState.DefeatTransition(
            receipt: encounter.nextDefeatTransitionReceipt, foeID: foeID,
            sourceActor: sourceActor, provenance: provenance, damage: amount,
            sourceNodeID: sourceNodeID)
        encounter.nextDefeatTransitionReceipt &+= 1
        encounter.defeatTransitions.append(transition)
        if encounter.defeatTransitions.count > 24 {
            encounter.defeatTransitions.removeFirst(encounter.defeatTransitions.count - 24)
        }
        resolveDefeatConsequences(transition, run: &run, encounter: &encounter)
        return transition
    }

    private static func resolveDefeatConsequences(_ transition: EncounterState.DefeatTransition,
                                                   run: inout WorldRun,
                                                   encounter: inout EncounterState) {
        guard let owner = transition.sourceActor, owner.isParty,
              let owned = encounter.debugV2OwnedNodeIDs?[owner] else { return }
        let ownerIsConscious = isAlive(owner, in: run)
        if owned.contains(secondWindNodeID), ownerIsConscious {
            heal(owner, by: 3, run: &run, encounter: &encounter,
                 source: "Second Wind", healer: owner)
        }
        if owned.contains(rallyNodeID), ownerIsConscious {
            var seen = Set<Combatant>()
            let party = encounter.turnSlots.map(\.actor).filter { $0.isParty && seen.insert($0).inserted }
            for ally in party where ally != owner && isAlive(ally, in: run) {
                heal(ally, by: 2, run: &run, encounter: &encounter,
                     source: "Rally", healer: owner)
            }
        }
        if owned.contains(cascadeNodeID) {
            applyCascade(to: owner, encounter: &encounter)
        }
    }

    private static func applyCascade(to owner: Combatant, encounter: inout EncounterState) {
        let old = min(3, max(0, encounter.cascadeStacks[owner] ?? 0))
        guard old < 3 else { return }
        encounter.cascadeStacks[owner] = old + 1
        if let entryIndex = encounter.debugV2Initiative?.entries.firstIndex(where: { $0.actor == owner }) {
            var entry = encounter.debugV2Initiative!.entries[entryIndex]
            if let component = entry.components.firstIndex(where: { $0.nodeID == cascadeNodeID }) {
                entry.components[component].amount = (old + 1) * 3
            } else {
                entry.components.append(.init(nodeID: cascadeNodeID, amount: 3))
                entry.components.sort { $0.nodeID.rawValue < $1.nodeID.rawValue }
            }
            entry.total = entry.baseline + entry.components.reduce(0) { $0 + $1.amount }
            encounter.debugV2Initiative!.entries[entryIndex] = entry
        }

        guard let ownerIndex = encounter.turnSlots.indices.first(where: {
            $0 > encounter.turnIndex && encounter.turnSlots[$0].actor == owner
                && encounter.turnSlots[$0].kind == .primary
        }), let ownerTotal = encounter.debugV2Initiative?.entry(for: owner)?.total else {
            encounter.note("Cascade · \(old + 1) of 3.")
            return
        }
        let destination = encounter.turnSlots.indices.first(where: { index in
            guard index > encounter.turnIndex, index < ownerIndex,
                  encounter.turnSlots[index].kind == .primary,
                  let total = encounter.debugV2Initiative?.entry(
                    for: encounter.turnSlots[index].actor)?.total else { return false }
            return ownerTotal > total
        })
        if let destination {
            let slot = encounter.turnSlots.remove(at: ownerIndex)
            encounter.turnSlots.insert(slot, at: destination)
            encounter.order = encounter.turnSlots.map(\.actor).reduce(into: []) { result, actor in
                if !result.contains(actor) { result.append(actor) }
            }
            if let indices = encounter.debugV2Initiative?.entries.indices {
                for index in indices {
                    let actor = encounter.debugV2Initiative!.entries[index].actor
                    encounter.debugV2Initiative!.entries[index].finalPosition = encounter.order.firstIndex(of: actor)
                        .map { $0 + 1 }
                }
            }
            encounter.note("Cascade · \(old + 1) of 3 · you move earlier.")
        } else {
            encounter.note("Cascade · \(old + 1) of 3.")
        }
    }

    /// Cascade changes only the relative order of primary actor slots. Follow-up slots keep their
    /// authored positions and payloads, so gaining tempo can never gather an apex/pressure burst.
    private static func applyCascadeOrderForNewRound(_ encounter: inout EncounterState) {
        guard let receipt = encounter.debugV2Initiative else { return }
        let primaryIndices = encounter.turnSlots.indices.filter {
            encounter.turnSlots[$0].kind == .primary
        }
        let sortedActors = primaryIndices.map { encounter.turnSlots[$0].actor }.sorted { lhs, rhs in
            let left = receipt.entry(for: lhs)
            let right = receipt.entry(for: rhs)
            if left?.strikesFirst != right?.strikesFirst { return left?.strikesFirst == true }
            if left?.total != right?.total { return (left?.total ?? Int.min) > (right?.total ?? Int.min) }
            return lhs.storageKey < rhs.storageKey
        }
        for (index, actor) in zip(primaryIndices, sortedActors) {
            encounter.turnSlots[index].actor = actor
        }
        encounter.order = encounter.turnSlots.map(\.actor).reduce(into: []) { result, actor in
            if !result.contains(actor) { result.append(actor) }
        }
    }

    static func breakingBlowEffect(actor: Combatant, kind: DamageKind?,
                                   allowsDirectWeapon: Bool = true,
                                   window: DirectAttackWindow = .scheduled,
                                   encounter: EncounterState) -> BreakingBlowEffect {
        let owns = allowsDirectWeapon && kind == .crush
            && encounter.debugV2OwnedNodeIDs?[actor]?.contains(
                CombatDerivedStatsRules.Node.breakingBlow) == true
        let spent = switch window {
        case .scheduled: encounter.breakingBlowScheduledSpent?.contains(actor) == true
        case .opening: encounter.breakingBlowOpeningSpent?.contains(actor) == true
        }
        return .init(ignoresArmour: owns, automaticStaggerAvailable: owns && !spent)
    }

    /// One authority for turn cost. Extra-turn implementation details must not decide whether a
    /// temporary receipt survives an action.
    private static func combatActionCost(_ action: CombatAction) -> CombatActionCost {
        if action == .blur { return .zero }
        guard case .skill(let id, _, _) = action,
              let kind = ContentCatalog.shared.skill(id)?.kind else { return .normal }
        return switch kind {
        case .ambush, .quicken, .reposition: .zero
        default: .normal
        }
    }

    private static func isPersonalSetup(_ action: CombatAction) -> Bool {
        if action == .blur { return true }
        guard case .skill(let id, _, _) = action,
              let kind = ContentCatalog.shared.skill(id)?.kind else { return false }
        return kind == .quicken || kind == .reposition
    }

    private static func normalizePersonalTurn(_ encounter: inout EncounterState,
                                              actor: Combatant) {
        guard usesPersonalTurnAuthority(encounter) else { return }
        guard encounter.personalTurn?.owner != actor else { return }
        let legacyExtra = max(0, encounter.extraTurns.removeValue(forKey: actor) ?? 0)
        encounter.personalTurn = .init(owner: actor, setupAvailable: true,
                                       normalCreditsRemaining: 1 + legacyExtra,
                                       expansionSource: legacyExtra > 0 ? .legacy : nil)
    }

    private static func baseAttack(of actor: Combatant, in state: GameState) -> Int {
        switch actor {
        case .binder:
            let frozen = state.worlds.activeRun?.activeEncounter?.debugV2BinderAttack
            return binderAttack(in: state)
                + (frozen?.preMatchupBonus(for: frozen?.ordinaryWeaponKind).total ?? 0)
        case .companion(let index): return companionAttack(index, in: state)
        case .foe(let id):
            return state.worlds.activeRun?.activeEncounter?.foes.first { $0.id == id }?.stats.attack ?? 1
        }
    }

    private static func conditionalDirectHitComponents(actor: Combatant, foe: FoeState,
                                                        encounter: EncounterState) -> [EncounterState.DirectHitComponent] {
        guard let ownership = encounter.debugV2OwnedNodeIDs,
              let previousRanks = encounter.rankAtPreviousCompletedAction else { return [] }
        let currentRank = encounter.partyRanks[actor]
        return CombatDerivedStatsRules.conditionalDirectHitComponents(
            ownedNodeIDs: ownership[actor] ?? [],
            snapshot: .init(targetArmour: foeArmourBreakdown(foe, encounter: encounter).beforeIgnore,
                            coveringDensity: foe.traits?.covering.coverage,
                            actorHeldRank: currentRank != nil && currentRank == previousRanks[actor],
                            targetHasAffliction: !afflictions(on: .foe(foe.id), in: encounter).isEmpty)
        )
    }

    struct DirectTechniquePreview: Equatable, Sendable {
        var skillID: SkillID
        var kind: DamageKind
        var branchPower: Int
        var preMatchupPower: Int
        var ignoresArmour: Bool
        var damage: CombatDamageRules.Preview
        var criticalDamage: CombatDamageRules.Preview?
    }

    private static func targetedWeaponTechniqueProfile(
        _ skill: SkillDef, actor: Combatant, foe: FoeState,
        encounter: EncounterState, state: GameState
    ) -> (power: Int, branchPower: Int, kind: DamageKind, ignoresArmour: Bool)? {
        let kind: DamageKind
        let branchPower: Int
        switch skill.kind {
        case .armourIgnoring:
            kind = .pierce
            branchPower = skill.power
        case .execute:
            kind = skill.damage ?? .pierce
            let authored = skill.power
            branchPower = foe.currentHP * 100 <= max(1, foe.stats.maxHP) * 35 ? authored : authored / 3
        default:
            return nil
        }
        let root = debugV2WeaponTechniqueBonus(for: actor, kind: kind, encounter: encounter)
        return (branchPower + root, branchPower, kind, skill.kind == .armourIgnoring)
    }

    static func debugV2DirectTechniquePreview(skillID: SkillID, actor: Combatant,
                                               foe: FoeState, in state: GameState) -> DirectTechniquePreview? {
        guard let encounter = state.worlds.activeRun?.activeEncounter,
              let skill = ContentCatalog.shared.skill(skillID),
              skills(for: actor, in: state).contains(skill),
              let profile = targetedWeaponTechniqueProfile(skill, actor: actor, foe: foe,
                                                            encounter: encounter, state: state)
        else { return nil }
        let conditional = conditionalDirectHitComponents(actor: actor, foe: foe,
                                                         encounter: encounter).reduce(0) { $0 + $1.amount }
        let power = profile.power + conditional
        let spread = max(1, Int((Double(power) * Tuning.Encounter.damageVariance).rounded()))
        let range = max(Tuning.Encounter.minimumDamage, power - spread)...max(Tuning.Encounter.minimumDamage,
                                                                               power + spread)
        let breakingBlow = breakingBlowEffect(actor: actor, kind: profile.kind,
                                              encounter: encounter)
        let context = CombatDamageRules.Context(damageKind: profile.kind,
            covering: foe.traits?.covering ?? Covering(),
            wildRule: wildRule(for: actor, in: state),
            standingBack: rank(of: actor, in: encounter, fallback: state) == .back,
            reach: reach(for: actor, in: state),
            armour: foeArmourBreakdown(foe, encounter: encounter).beforeIgnore,
            ignoresArmour: profile.ignoresArmour || breakingBlow.ignoresArmour)
        let ownsSteadyHand = encounter.debugV2OwnedNodeIDs?[actor]?.contains(
            CombatDerivedStatsRules.Node.steadyHand) == true
        return .init(skillID: skillID, kind: profile.kind, branchPower: profile.branchPower,
                     preMatchupPower: power,
                     ignoresArmour: profile.ignoresArmour || breakingBlow.ignoresArmour,
                     damage: CombatDamageRules.preview(rolledPower: range, in: context),
                     criticalDamage: ownsSteadyHand ? CombatDamageRules.preview(
                        rolledPower: range,
                        in: .init(damageKind: context.damageKind, covering: context.covering,
                                  wildRule: context.wildRule, standingBack: context.standingBack,
                                  reach: context.reach, armour: context.armour,
                                  ignoresArmour: context.ignoresArmour, isCritical: true)) : nil)
    }

    struct DirectAttackCriticalPreview: Equatable, Sendable {
        var ordinary: CombatDamageRules.Preview
        var critical: CombatDamageRules.Preview?
    }

    static func debugV2DirectAttackCriticalPreview(foe: FoeState, in state: GameState,
                                                    standingBack: Bool = false) -> DirectAttackCriticalPreview? {
        guard let ordinary = debugV2DirectAttackPreview(foe: foe, in: state, standingBack: standingBack),
              let encounter = state.worlds.activeRun?.activeEncounter else { return nil }
        guard encounter.debugV2OwnedNodeIDs?[.binder]?.contains(CombatDerivedStatsRules.Node.steadyHand) == true
        else { return .init(ordinary: ordinary, critical: nil) }
        let breakingBlow = breakingBlowEffect(
            actor: .binder,
            kind: encounter.debugV2BinderAttack?.ordinaryWeaponKind,
            encounter: encounter
        )
        let context = CombatDamageRules.Context(
            damageKind: encounter.debugV2BinderAttack?.ordinaryWeaponKind,
            covering: foe.traits?.covering ?? Covering(),
            wildRule: wildRule(for: .binder, in: state), standingBack: standingBack,
            reach: reach(for: .binder, in: state),
            armour: foeArmourBreakdown(foe, encounter: encounter).beforeIgnore,
            ignoresArmour: breakingBlow.ignoresArmour, isCritical: true)
        return .init(ordinary: ordinary,
                     critical: CombatDamageRules.preview(
                        rolledPower: ordinary.lower.rolledPower...ordinary.upper.rolledPower, in: context))
    }

    static func steadyHandCritical(roll: Double, ownsNode: Bool) -> Bool {
        ownsNode && roll < 0.12
    }

    static func debugV2DirectAttackPreview(foe: FoeState, in state: GameState,
                                           standingBack: Bool = false,
                                           personalRawBonus: Int = 0) -> CombatDamageRules.Preview? {
        guard let receipt = state.worlds.activeRun?.activeEncounter?.debugV2BinderAttack else { return nil }
        guard let encounter = state.worlds.activeRun?.activeEncounter else { return nil }
        let conditional = conditionalDirectHitComponents(actor: .binder, foe: foe,
                                                         encounter: encounter).reduce(0) { $0 + $1.amount }
        let power = binderAttack(in: state)
            + receipt.preMatchupBonus(for: receipt.ordinaryWeaponKind).total
            + conditional
            + personalRawBonus
        let spread = max(1, Int((Double(power) * Tuning.Encounter.damageVariance).rounded()))
        let range = max(Tuning.Encounter.minimumDamage, power - spread)...max(Tuning.Encounter.minimumDamage,
                                                                               power + spread)
        let breakingBlow = breakingBlowEffect(actor: .binder, kind: receipt.ordinaryWeaponKind,
                                              encounter: encounter)
        return CombatDamageRules.preview(rolledPower: range,
            in: .init(damageKind: receipt.ordinaryWeaponKind,
                      covering: foe.traits?.covering ?? Covering(),
                      wildRule: wildRule(for: .binder, in: state),
                      standingBack: standingBack,
                      reach: reach(for: .binder, in: state),
                      armour: foeArmourBreakdown(foe, encounter: encounter).beforeIgnore,
                      ignoresArmour: breakingBlow.ignoresArmour))
    }

    private struct LandedDirectHit {
        var actor: Combatant
        var primaryFoeID: InstanceID
        var actualLoss: Int
        var isEmanation: Bool
    }

    private struct StrikeResult {
        var committed: Bool
        var landed: LandedDirectHit?
    }

    private static func resolveCarriedDamage(from hit: LandedDirectHit,
                                             primaryAffliction: AfflictionInstance?,
                                             run: inout WorldRun,
                                             encounter: inout EncounterState) {
        guard hit.actualLoss > 0, let owned = encounter.debugV2OwnedNodeIDs?[hit.actor] else { return }
        let usesConduction = hit.isEmanation && owned.contains(conductionNodeID)
        let sourceNode = usesConduction ? conductionNodeID : flurryNodeID
        guard usesConduction || owned.contains(flurryNodeID) else { return }

        let secondaryIndex = encounter.foes.indices.first { index in
            let candidate = encounter.foes[index]
            guard candidate.id != hit.primaryFoeID, candidate.isAlive else { return false }
            if usesConduction { return encounter.revealed.contains(candidate.id) }
            // Current foe targeting has no per-foe formation rank: every other living participant
            // is legal once the actor could make this same direct attack. Keep this query explicit
            // so later typed foe ranks can narrow it without changing Flurry arithmetic.
            return true
        }
        guard let secondaryIndex else { return }
        let fraction = usesConduction ? 0.5 : 0.4
        let damage = carriedDamageAmount(actualLoss: hit.actualLoss, fraction: fraction)
        let secondaryID = encounter.foes[secondaryIndex].id
        _ = applyFoeDamage(foeID: secondaryID, amount: damage, sourceActor: hit.actor,
                           provenance: .carried, sourceNodeID: sourceNode,
                           run: &run, encounter: &encounter)

        var copiedReceipt: UInt64?
        if usesConduction, let primaryAffliction,
           [.burn, .poison, .dazzle].contains(primaryAffliction.kind) {
            let copiedTicks = max(1, (primaryAffliction.ticksRemaining + 1) / 2)
            let outcome = applyAffliction(
                primaryAffliction.kind, to: .foe(secondaryID), source: hit.actor,
                provenance: .copied, contributingProvenances: [.copied],
                damage: primaryAffliction.damage, ticks: copiedTicks,
                targetIsStanding: encounter.foes[secondaryIndex].isAlive,
                encounter: &encounter)
            switch outcome {
            case .added(let instance), .damageStrengthened(let instance),
                 .durationStrengthened(let instance), .bothStrengthened(let instance):
                copiedReceipt = instance.applicationReceipt
            case .prevented, .noChange:
                break
            }
        }
        let event = EncounterState.CarriedDamageEvent(
            receipt: encounter.nextCarriedDamageReceipt, sourceActor: hit.actor,
            sourceNodeID: sourceNode, primaryFoeID: hit.primaryFoeID,
            secondaryFoeID: secondaryID, primaryActualLoss: hit.actualLoss,
            damage: damage, copiedAfflictionReceipt: copiedReceipt)
        encounter.nextCarriedDamageReceipt &+= 1
        encounter.carriedDamageEvents.append(event)
        if encounter.carriedDamageEvents.count > 24 {
            encounter.carriedDamageEvents.removeFirst(encounter.carriedDamageEvents.count - 24)
        }
        encounter.note("\(sourceNode == conductionNodeID ? "Conduction" : "Flurry") carries \(damage) into \(encounter.foes[secondaryIndex].stats.displayName).")
    }

    static func carriedDamageAmount(actualLoss: Int, fraction: Double) -> Int {
        guard actualLoss > 0 else { return 0 }
        return max(1, Int(floor(Double(actualLoss) * fraction)))
    }

    @discardableResult
    private static func strike(_ foeID: InstanceID,
                               damage: Int,
                               by actor: Combatant,
                               kind: DamageKind?,
                               run: inout WorldRun,
                               encounter: inout EncounterState,
                               verb: String? = nil,
                               ignoresArmour: Bool = false,
                               standingBack: Bool = false,
                               reachOfActor: Reach = .close,
                               coating: StatusKind? = nil,
                               /// The rule the attacker's weapon breaks, where it breaks one. Passed
                               /// in rather than looked up, because `strike` has no `state` — the
                               /// same reason `coating` is.
                               breaking: WildRule? = nil,
                               innateStatus: String? = nil,
                               allowsStagger: Bool = false,
                               allowsConditionalDirectHit: Bool = false,
                               directAttackWindow: DirectAttackWindow = .scheduled,
                               defersCarriedDamage: Bool = false,
                               isEmanation: Bool = false,
                               allowsRetaliation: Bool = true) -> StrikeResult {
        guard let index = encounter.foes.firstIndex(where: { $0.id == foeID }), encounter.foes[index].isAlive
        else { return .init(committed: false, landed: nil) }

        let foe = encounter.foes[index]
        let name = foe.stats.displayName
        let who = actorName(actor, encounter: encounter)

        // **Dazzled, you swing at where it was.** A light emanation now costs you your accuracy
        // rather than only a point of health (Q42).
        let dazzled = has(.dazzle, actor, in: encounter) ? Tuning.Encounter.dazzleMissChance : 0
        if dazzled > 0, run.rng.chance(dazzled) {
            encounter.note("\(who) \(actor == .binder ? "swing" : "swings") at where \(name) was.")
            return .init(committed: true, landed: nil)
        }

        // **Sleek and small is hard to hit.** A miss is the price of chasing something built to run.
        if run.rng.chance(foe.stats.evasion) {
            encounter.note("\(who) \(actor == .binder ? "swing" : "swings") at \(name) and find\(actor == .binder ? "" : "s") nothing there.")
            return .init(committed: true, landed: nil)
        }

        // **The matchup.** What you're swinging against what it's wearing, then armour on what's
        // left — and a piercing weapon goes through a share of that armour rather than all of it.
        let conditional = allowsConditionalDirectHit
            ? conditionalDirectHitComponents(actor: actor, foe: foe, encounter: encounter)
            : []
        let rolledPower = roll(around: damage + conditional.reduce(0) { $0 + $1.amount }, run: &run)
        let ownsSteadyHand = allowsConditionalDirectHit
            && encounter.debugV2OwnedNodeIDs?[actor]?.contains(CombatDerivedStatsRules.Node.steadyHand) == true
        let critical = ownsSteadyHand && steadyHandCritical(roll: run.rng.double(in: 0...1), ownsNode: true)
        let breakingBlow = breakingBlowEffect(actor: actor, kind: kind,
                                              allowsDirectWeapon: allowsConditionalDirectHit,
                                              window: directAttackWindow, encounter: encounter)
        let resolved = CombatDamageRules.resolve(
            rolledPower: rolledPower,
            in: .init(damageKind: kind,
                      covering: foe.traits?.covering ?? Covering(),
                      wildRule: breaking,
                      standingBack: standingBack,
                      reach: reachOfActor,
                      armour: foeArmourBreakdown(foe, encounter: encounter).beforeIgnore,
                      ignoresArmour: ignoresArmour || breakingBlow.ignoresArmour, isCritical: critical)
        )
        let raw = resolved.rawDamage
        let amount = resolved.finalDamage
        let hpBefore = encounter.foes[index].currentHP
        _ = applyFoeDamage(foeID: foeID, amount: amount, sourceActor: actor,
                           provenance: .direct, run: &run, encounter: &encounter)
        let landedHit = LandedDirectHit(actor: actor, primaryFoeID: foeID,
                                        actualLoss: hpBefore - encounter.foes[index].currentHP,
                                        isEmanation: isEmanation)
        if critical { encounter.note("Critical — Steady Hand.") }
        switch killingStrokeOutcome(actor: actor, primaryDamage: amount, foe: foe,
                                    allowsDirectHit: allowsConditionalDirectHit,
                                    encounter: encounter) {
        case .none:
            break
        case .defeat:
            _ = applyFoeDamage(foeID: foeID, amount: encounter.foes[index].currentHP,
                               sourceActor: actor, provenance: .killingStroke,
                               sourceNodeID: killingStrokeNodeID,
                               run: &run, encounter: &encounter)
            encounter.note("Killing Stroke — the fight goes out of \(name).")
        case .apexDamage(let additional):
            _ = applyFoeDamage(foeID: foeID, amount: additional, sourceActor: actor,
                               provenance: .killingStroke, sourceNodeID: killingStrokeNodeID,
                               run: &run, encounter: &encounter)
            encounter.note("Killing Stroke — \(name) takes \(additional) more.")
        }
        if !encounter.foes[index].isAlive { encounter.pendingStaggers[foeID] = nil }

        let soaked = raw - amount
        // "You hits" — the log addresses the Binder in the second person, so the verb has to agree.
        let hits = actor == .binder ? "hit" : "hits"
        let note = verb.map { "\(who) — \($0) — \(hits) \(name) for \(amount)." }
            ?? "\(who) \(hits) \(name) for \(amount)."
        encounter.note(soaked > 1 ? note + " Its \(armourWord(for: foe)) takes the rest." : note)

        var didAutomaticBreakingBlowStagger = false
        if breakingBlow.automaticStaggerAvailable {
                switch directAttackWindow {
                case .scheduled: encounter.breakingBlowScheduledSpent?.insert(actor)
                case .opening: encounter.breakingBlowOpeningSpent?.insert(actor)
                }
                if encounter.foes[index].isAlive {
                    attemptStagger(foeID: foeID, actor: actor, automatic: true,
                                   run: &run, encounter: &encounter,
                                   sourceNodeID: CombatDerivedStatsRules.Node.breakingBlow)
                    didAutomaticBreakingBlowStagger = true
                }
        }

        if allowsStagger, kind == .crush, encounter.foes[index].isAlive,
           !didAutomaticBreakingBlowStagger {
            attemptStagger(foeID: foeID, actor: actor, automatic: false,
                           run: &run, encounter: &encounter)
        }

        // **Throughstroke.** It carries the damage that actually landed through the selected foe,
        // rather than rolling a second attack or inventing enemy ranks for one weapon.
        if breaking == .bothRanks,
           let second = encounter.foes.indices.first(where: { $0 != index && encounter.foes[$0].isAlive }) {
            let carried = max(Tuning.Encounter.minimumDamage, amount / 2)
            let secondName = encounter.foes[second].stats.displayName
            _ = applyFoeDamage(foeID: encounter.foes[second].id, amount: carried,
                               sourceActor: actor, provenance: .carried,
                               run: &run, encounter: &encounter)
            encounter.note("The point keeps going into \(secondName) for \(carried).")
            if !encounter.foes[second].isAlive {
                encounter.note("\(secondName.capitalisedSentence) goes down.")
            }
        }

        // One successful weapon strike spends its prepared coating even if the damage defeats the
        // target. If the target remains standing, merge every same-kind contributor before the one
        // Stonebark/max-refresh transaction; different kinds use registry order.
        let prepared = encounter.preparedCoatings.removeValue(forKey: actor)
        if encounter.foes[index].isAlive {
            typealias Payload = (kind: AfflictionID, damage: Int, ticks: Int,
                                 endless: Bool, provenance: AfflictionProvenance)
            var payloads: [Payload] = []
            if let coating {
                payloads.append((.bleed, Tuning.Encounter.statusDamage[coating.rawValue] ?? 2,
                                 Tuning.Encounter.statusRounds[coating.rawValue] ?? 3,
                                 false, .direct))
                encounter.note("Whatever that blade is made of is in the wound now.")
            }
            if let prepared {
                let payload: Payload = switch prepared {
                case .bleed:
                    (.bleed, Tuning.Encounter.statusDamage["bleed"] ?? 2,
                     Tuning.Encounter.bleedRounds, false, .coating)
                case .poison:
                    (.poison, Tuning.Encounter.statusDamage["poison"] ?? 2,
                     Tuning.Encounter.statusRounds["poison"] ?? 3, false, .coating)
                case .burn:
                    (.burn, Tuning.Encounter.statusDamage["burn"] ?? 4,
                     Tuning.Encounter.statusRounds["burn"] ?? 2, false, .coating)
                case .dazzle:
                    (.dazzle, 0, Tuning.Encounter.statusRounds["dazzle"] ?? 2,
                     false, .coating)
                }
                payloads.append(payload)
                encounter.note("The \(prepared.rawValue) coating leaves the weapon in the wound.")
            }
            if kind == .rend {
                payloads.append((.bleed, Tuning.Encounter.bleedDamage,
                                 Tuning.Encounter.bleedRounds,
                                 breaking == .endlessBleed, .direct))
            }
            if breaking == .innateStatus, let named = innateStatus {
                payloads.append((.bleed, Tuning.Encounter.statusDamage[named] ?? 3,
                                 Tuning.Encounter.statusRounds[named] ?? 3,
                                 false, .direct))
                encounter.note("The barbs stay in the wound.")
            }
            for kind in AfflictionID.allCases {
                let contributors = payloads.filter { $0.kind == kind }
                guard !contributors.isEmpty else { continue }
                let strongest = contributors.max { $0.damage < $1.damage }!
                _ = applyAffliction(kind, to: .foe(foe.id), source: actor,
                                    provenance: strongest.provenance,
                                    contributingProvenances: Set(contributors.map(\.provenance)),
                                    damage: contributors.map(\.damage).max() ?? 0,
                                    ticks: contributors.map(\.ticks).max() ?? 0,
                                    endless: contributors.contains(where: \.endless),
                                    targetIsStanding: true, encounter: &encounter)
            }
        }

        // **Attacking out of cover, and staying in it.** Nothing else in Shadow allows this.
        if breaking == .quietStrike, (encounter.concealed[actor] ?? 0) > 0 {
            encounter.concealed[actor, default: 0] += 1
        }

        // **Warning colours are honest.** Hitting something that advertises costs you — and if it
        // was advertising *venom*, it costs you for a while (Q42).
        if allowsRetaliation, foe.stats.retaliation > 0, encounter.foes[index].isAlive {
            hurt(actor, by: foe.stats.retaliation, run: &run, encounter: &encounter)
            encounter.note("\(name.capitalisedSentence) is not safe to touch — \(foe.stats.retaliation) back.")
            if foe.traits?.isToxic == true {
                _ = applyAffliction(.poison, to: actor, source: .foe(foe.id),
                                    provenance: .retaliation,
                                    damage: Tuning.Encounter.statusDamage["poison"] ?? 0,
                                    ticks: Tuning.Encounter.statusRounds["poison"] ?? 3,
                                    targetIsStanding: isAlive(actor, in: run),
                                    encounter: &encounter)
                encounter.note("It's in you now.")
            }
        }
        if !encounter.foes[index].isAlive { encounter.note("\(name.capitalisedSentence) goes down.") }
        if !defersCarriedDamage {
            resolveCarriedDamage(from: landedHit, primaryAffliction: nil,
                                 run: &run, encounter: &encounter)
        }
        return .init(committed: true, landed: landedHit)
    }

    private static func armourWord(for foe: FoeState) -> String {
        guard let traits = foe.traits else { return "hide" }
        if traits.covering.hardness > 70 { return traits.finish.schiller > 30 ? "shell" : "plate" }
        if traits.covering.length > 55 { return "pelt" }
        return "hide"
    }

    /// Damage onto one of the party, wherever it comes from.
    private static func hurt(_ target: Combatant,
                             by amount: Int,
                             braceApplies: Bool = false,
                             run: inout WorldRun,
                             encounter: inout EncounterState) {
        let before = health(of: target, in: run)
        let ownsEndurance = owns(CombatDerivedStatsRules.Node.endurance,
                                 actor: target, encounter: encounter)
        let reduced = CombatDerivedStatsRules.survivalDamage(
            amount, currentHP: before.current, maximumHP: before.max,
            eventMinimum: Tuning.Encounter.minimumDamage, ownsEndurance: ownsEndurance,
            braceApplies: braceApplies)
        let ownsUnyielding = owns(CombatDerivedStatsRules.Node.unyielding,
                                  actor: target, encounter: encounter)
        let canSpendUnyielding = target.isParty && before.current > 0
            && before.current - reduced <= 0 && ownsUnyielding
            && encounter.unyieldingSpent?.contains(target) == false
        let finalHP = canSpendUnyielding ? 1 : max(0, before.current - reduced)
        switch target {
        case .binder: run.binderHP = finalHP
        case .companion(let index):
            run.companionHP[index] = finalHP
        case .foe(let id):
            _ = applyFoeDamage(foeID: id, amount: reduced, sourceActor: nil,
                               provenance: .environment, run: &run, encounter: &encounter)
        }
        if reduced < amount {
            let source = braceApplies && ownsEndurance ? "Brace and Endurance"
                : (braceApplies ? "Brace" : "Endurance")
            encounter.note("\(source) reduces the harm from \(amount) to \(reduced).")
        }
        if canSpendUnyielding {
            encounter.unyieldingSpent?.insert(target)
            encounter.note("Unyielding leaves \(actorName(target, encounter: encounter).lowercased()) at 1 health.")
        }
    }

    private static func heal(_ ally: Combatant,
                             by amount: Int,
                             run: inout WorldRun,
                             encounter: inout EncounterState,
                             source: String,
                             healer: Combatant) {
        let ceiling = health(of: ally, in: run).max
        switch ally {
        case .binder: run.binderHP = min(ceiling, run.binderHP + amount)
        case .companion(let index):
            run.companionHP[index] = min(ceiling,
                                         (run.companionHP[index] ?? ceiling) + amount)
        case .foe: return
        }
        encounter.note("\(actorName(healer, encounter: encounter)) — \(source) — restores \(amount) to \(actorName(ally, encounter: encounter)).")
    }

    @discardableResult
    private static func useItem(_ stackID: InstanceID,
                                on ally: Combatant,
                                afflictionReceipt: UInt64?,
                                run: inout WorldRun,
                                encounter: inout EncounterState) -> Bool {
        guard let index = run.satchelItems.stacks.firstIndex(where: { $0.id == stackID }),
              let item = ContentCatalog.shared.item(run.satchelItems.stacks[index].catalogID),
              item.kind == .consumable
        else { return false }

        guard let effect = item.consumable else { return false }
        adoptLegacyAfflictions(in: &encounter)
        switch effect.effect {
        case .heal:
            heal(ally, by: effect.potency, run: &run, encounter: &encounter,
                 source: item.name, healer: ally)
        case .clearPoison:
            guard cureAfflictions(for: effect.effect, on: ally,
                                  selectedReceipt: afflictionReceipt,
                                  encounter: &encounter) else { return false }
            encounter.note("\(item.name) clears the wound and the poison.")
        case .clearElemental:
            guard cureAfflictions(for: effect.effect, on: ally,
                                  selectedReceipt: afflictionReceipt,
                                  encounter: &encounter) else { return false }
            encounter.note("\(item.name) quenches what was clinging to \(actorName(ally, encounter: encounter)).")
        case .clearAnyStatus:
            guard cureAfflictions(for: effect.effect, on: ally,
                                  selectedReceipt: afflictionReceipt,
                                  encounter: &encounter) else { return false }
            encounter.note("\(item.name) draws one affliction out.")
        case .preventStatus:
            encounter.statusGuards[ally] = max(1, effect.potency)
            encounter.note("\(item.name) will turn aside the next affliction.")
        case .coatPoison, .coatBurn, .coatBleed, .coatDazzle:
            let coating: PreparedCoating = switch effect.effect {
            case .coatPoison: .poison
            case .coatBurn: .burn
            case .coatBleed: .bleed
            case .coatDazzle: .dazzle
            default: .poison
            }
            encounter.preparedCoatings[ally] = coating
            encounter.note("\(item.name) is ready on \(actorName(ally, encounter: encounter))'s weapon.")
        case .restoreStability, .returnHome, .lightWorld, .farsight, .identifyCurio, .lureCreature:
            return false
        }
        // Through the bin rather than by poking `count`, so a stack that also carries samples
        // can't have its count drift away from what's actually in it.
        _ = run.satchelItems.stacks[index].removing(1)
        if run.satchelItems.stacks[index].isEmpty {
            run.satchelItems.stacks.remove(at: index)
        }
        return true
    }

    private static func setCooldown(_ rounds: Int, for actor: Combatant, in encounter: inout EncounterState) {
        switch actor {
        case .binder: encounter.binderSkillCooldown = rounds
        case .companion: encounter.companionSkillCooldown = rounds
        case .foe: break
        }
    }

    /// Damage and healing wobble a little so fights aren't arithmetic. Off the run's saved RNG.
    private static func roll(around power: Int, run: inout WorldRun) -> Int {
        let spread = max(1, Int((Double(power) * Tuning.Encounter.damageVariance).rounded()))
        return max(Tuning.Encounter.minimumDamage, power + run.rng.int(in: -spread...spread))
    }

    static func actorName(_ actor: Combatant, encounter: EncounterState) -> String {
        switch actor {
        case .binder: "You"
        case .companion(let index): encounter.partyNames[index] ?? "Your companion"
        case .foe(let id): encounter.foes.first { $0.id == id }?.stats.displayName ?? "Something"
        }
    }

    /// **What somebody's spent points are worth**, in the fight. One lookup so a node's effect
    /// reaches combat rather than only the tree screen.
    static func loadout(of actor: Combatant, in state: GameState) -> CombatTreeRules.Loadout {
        guard actor.isParty else { return CombatTreeRules.Loadout() }
        return CombatTreeRules.loadout(for: state.base.character(actor.member))
    }

    /// Everybody who came, as combatants. The one place that answers "who is the party".
    static func party(of state: GameState) -> [Combatant] {
        state.base.partyMembers.map(\.combatant)
    }

    static func guardianFilteredTargets(_ targets: [Combatant], isSingleTargetDirect: Bool,
                                        run: WorldRun, encounter: EncounterState,
                                        state: GameState) -> [Combatant] {
        guard isSingleTargetDirect, encounter.debugV2OwnedNodeIDs != nil else { return targets }
        let front = targets.filter {
            rank(of: $0, in: encounter, fallback: state) == .front && isAlive($0, in: run)
        }
        guard !front.isEmpty,
              front.contains(where: { actor in
                  isAlive(actor, in: run)
                      && encounter.debugV2OwnedNodeIDs?[actor]?.contains(
                          CombatDerivedStatsRules.Node.guardian) == true
              }) else { return targets }
        return front
    }

    struct CoverAllocation: Equatable, Sendable {
        var owner: Combatant
        var targetDamage: Int
        var coverDamage: Int
    }

    static func coverAllocation(finalDamage: Int, target: Combatant, wasInterposed: Bool,
                                run: WorldRun, encounter: EncounterState,
                                state: GameState) -> CoverAllocation? {
        guard finalDamage > 0, !wasInterposed,
              rank(of: target, in: encounter, fallback: state) == .back,
              encounter.debugV2OwnedNodeIDs != nil else { return nil }
        let owner = party(of: state).filter {
            $0 != target && isAlive($0, in: run)
                && rank(of: $0, in: encounter, fallback: state) == .front
                && encounter.debugV2OwnedNodeIDs?[$0]?.contains(
                    CombatDerivedStatsRules.Node.cover) == true
        }.sorted { $0.storageKey < $1.storageKey }.first
        guard let owner else { return nil }
        let cover = Int((Double(finalDamage) * 0.30).rounded(.down))
        guard cover > 0 else { return nil }
        return .init(owner: owner, targetDamage: finalDamage - cover, coverDamage: cover)
    }

    // MARK: Turn order

    /// Moves to the next living combatant, ticking the round over when the rotation wraps.
    static func advanceTurn(in state: inout GameState, completedAction: Bool = true) {
        guard var run = state.worlds.activeRun, var encounter = run.activeEncounter else { return }

        let acting = encounter.current
        if completedAction { encounter.completedFirstActions.insert(acting) }
        if usesPersonalTurnAuthority(encounter) {
            normalizePersonalTurn(&encounter, actor: acting)
            if !completedAction {
                run.activeEncounter = encounter
                state.worlds.activeRun = run
                return
            }
            encounter.personalTurn?.normalCreditsRemaining -= 1
            if (encounter.personalTurn?.normalCreditsRemaining ?? 0) > 0,
               isAlive(acting, in: run), encounter.outcome == nil {
                encounter.note("Again, before it can answer.")
                run.activeEncounter = encounter
                state.worlds.activeRun = run
                return
            }
            encounter.personalTurn = nil
        } else if let owed = encounter.extraTurns[acting], owed > 0 {
            encounter.extraTurns[acting] = owed - 1
            run.activeEncounter = encounter
            state.worlds.activeRun = run
            return
        }
        var roundTurned = false
        let scheduleCount = max(1, encounter.turnSlots.isEmpty ? encounter.order.count : encounter.turnSlots.count)
        for step in 1...scheduleCount {
            let next = (encounter.turnIndex + step) % scheduleCount
            if next <= encounter.turnIndex {
                startNewRound(&encounter, run: run)
                roundTurned = true
            }
            encounter.turnIndex = next
            let who = encounter.turnSlots.isEmpty ? encounter.order[next] : encounter.turnSlots[next].actor
            guard isAlive(who, in: withEncounter(encounter, on: run)) else { continue }
            // …and a turn borrowed is a turn skipped. Overbear and Quicken both pay here.
            if let owing = encounter.skippedTurns[who], owing > 0 {
                encounter.skippedTurns[who] = owing - 1
                if owing == 1 { encounter.recoveryComplete.insert(who) }
                encounter.note("\(actorName(who, encounter: encounter)) is still recovering.")
                continue
            }
            if usesPersonalTurnAuthority(encounter) {
                encounter.personalTurn = .init(owner: who)
            }
            // A newly reached scheduled personal turn mints one Breaking Blow opportunity. Extra
            // action credits return above without clearing this receipt and therefore share it.
            encounter.breakingBlowScheduledSpent?.remove(who)
            break
        }

        run.activeEncounter = encounter
        state.worlds.activeRun = run
        if roundTurned { bleed(in: &state) }
    }

    private static func withEncounter(_ encounter: EncounterState, on run: WorldRun) -> WorldRun {
        var copy = run
        copy.activeEncounter = encounter
        return copy
    }

    static func startNewRound(_ encounter: inout EncounterState, run: WorldRun) {
        normalizeV2EvasionState(&encounter)
        if var states = encounter.untouchableStates {
            for actor in states.keys {
                guard var state = states[actor] else { continue }
                if state.targetedDirectCount > 0, state.landedDirectCount == 0 {
                    state.percentagePoints = min(20, state.percentagePoints + 5)
                }
                state.targetedDirectCount = 0
                state.landedDirectCount = 0
                states[actor] = state
            }
            encounter.untouchableStates = states
        }
        encounter.roundNumber += 1
        if encounter.drawOffReceipts != nil {
            encounter.drawOffReceipts = encounter.drawOffReceipts?.filter {
                $0.value.expiresBeforeRound > encounter.roundNumber
            }
        }
        if encounter.wardReceipts != nil {
            encounter.wardReceipts = encounter.wardReceipts?.filter {
                $0.value.expiresBeforeRound > encounter.roundNumber
            }
        }
        applyCascadeOrderForNewRound(&encounter)
        applyPendingStaggers(for: encounter.roundNumber, run: run, encounter: &encounter)
        encounter.apexTargetsThisRound.removeAll()
        encounter.binderSkillCooldown = max(0, encounter.binderSkillCooldown - 1)
        encounter.companionSkillCooldown = max(0, encounter.companionSkillCooldown - 1)
        // Every skill's own timer, and every effect with a clock on it. Rounds, never seconds.
        for (key, value) in encounter.cooldowns { encounter.cooldowns[key] = max(0, value - 1) }
        for (who, ward) in encounter.wards {
            if ward.rounds <= 1 { encounter.wards[who] = nil }
            else { encounter.wards[who]?.rounds = ward.rounds - 1 }
        }
        for (foe, rounds) in encounter.taunts {
            if rounds <= 1 { encounter.taunts[foe] = nil } else { encounter.taunts[foe] = rounds - 1 }
        }
        // The five the trees leave on somebody. **A clock that never ticks is a permanent effect**,
        // which is what Brace and Conceal would silently have become.
        tick(&encounter.braced); tick(&encounter.concealed)
        tick(&encounter.interposing); tick(&encounter.grounding); tick(&encounter.envenomed)
    }

    static func staggerSucceeds(roll: Double, automatic: Bool) -> Bool {
        automatic || roll < 0.30
    }

    /// Stagger and Breaking Blow share one typed producer. Breaking Blow supplies the automatic
    /// result only after its exact-owner personal-window receipt authorizes a landed Crush hit.
    static func attemptStagger(foeID: InstanceID, actor: Combatant, automatic: Bool,
                               run: inout WorldRun,
                               encounter: inout EncounterState,
                               sourceNodeID: CombatNodeID = CombatDerivedStatsRules.Node.stagger) {
        let ownsStagger = encounter.debugV2OwnedNodeIDs?[actor]?
            .contains(CombatDerivedStatsRules.Node.stagger) == true
        let validProducer = automatic
            ? sourceNodeID == CombatDerivedStatsRules.Node.breakingBlow
            : sourceNodeID == CombatDerivedStatsRules.Node.stagger && ownsStagger
        guard validProducer,
              let foe = encounter.foes.first(where: { $0.id == foeID && $0.isAlive })
        else { return }
        let roll: Double? = automatic ? nil : run.rng.double(in: 0...1)
        let succeeded = automatic || staggerSucceeds(roll: roll ?? 0, automatic: automatic)
        let applyingRound = encounter.roundNumber + 1
        let merged = encounter.pendingStaggers[foeID] != nil
        encounter.staggerAttempts.append(.init(actor: actor, foeID: foeID, roll: roll,
                                                succeeded: succeeded, automatic: automatic,
                                                applyingRound: succeeded ? applyingRound : nil,
                                                merged: succeeded && merged))
        if encounter.staggerAttempts.count > 24 {
            encounter.staggerAttempts.removeFirst(encounter.staggerAttempts.count - 24)
        }
        guard succeeded else { return }
        if var pending = encounter.pendingStaggers[foeID] {
            pending.sourceActors.insert(actor)
            pending.sourceNodeIDs.insert(sourceNodeID)
            pending.automatic = pending.automatic || automatic
            encounter.pendingStaggers[foeID] = pending
        } else {
            encounter.pendingStaggers[foeID] = .init(
                foeID: foeID, applyingRound: applyingRound, sourceActors: [actor],
                sourceNodeIDs: [sourceNodeID], automatic: automatic)
            encounter.note("\(foe.stats.displayName) loses footing · later in round \(applyingRound).")
        }
    }

    static func applyPendingStaggers(for round: Int, run: WorldRun,
                                     encounter: inout EncounterState) {
        let applicable = encounter.pendingStaggers.values.filter { $0.applyingRound == round }
        let sorted = applicable.sorted { lhs, rhs in
            let left = encounter.turnSlots.firstIndex { $0.actor == .foe(lhs.foeID) } ?? -1
            let right = encounter.turnSlots.firstIndex { $0.actor == .foe(rhs.foeID) } ?? -1
            if left != right { return left > right }
            return lhs.foeID.rawValue < rhs.foeID.rawValue
        }
        for pending in sorted {
            defer { encounter.pendingStaggers[pending.foeID] = nil }
            guard encounter.foes.contains(where: { $0.id == pending.foeID && $0.isAlive }) else { continue }
            let actor = Combatant.foe(pending.foeID)
            let name = encounter.foes.first { $0.id == pending.foeID }?.stats.displayName ?? "The foe"
            var moved = false
            let ownedIndices = encounter.turnSlots.indices.filter {
                encounter.turnSlots[$0].actor == actor
            }.sorted(by: >)
            for index in ownedIndices {
                guard let next = encounter.turnSlots.indices.first(where: {
                    $0 > index && encounter.turnSlots[$0].actor != actor
                        && isAlive(encounter.turnSlots[$0].actor,
                                          in: withEncounter(encounter, on: run))
                }) else { continue }
                let slot = encounter.turnSlots.remove(at: index)
                encounter.turnSlots.insert(slot, at: next)
                moved = true
            }
            guard moved else {
                encounter.note("\(name) has no later opening.")
                continue
            }
            encounter.order = encounter.turnSlots.map(\.actor).reduce(into: [Combatant]()) { result, candidate in
                if !result.contains(candidate) { result.append(candidate) }
            }
            encounter.note("\(name) falls one place later.")
        }
    }

    private static func tick(_ clock: inout [Combatant: Int]) {
        for (who, rounds) in clock {
            if rounds <= 1 { clock[who] = nil } else { clock[who] = rounds - 1 }
        }
    }

    /// Wounds that keep costing you, ticked once per round. Run from `advanceTurn` where the round
    /// actually turns over, so a force-quit between rounds can't skip or double a tick.
    private static func bleed(in state: inout GameState) {
        guard var run = state.worlds.activeRun, var encounter = run.activeEncounter else { return }
        tickAfflictions(run: &run, encounter: &encounter)

        run.activeEncounter = encounter
        state.worlds.activeRun = run
    }

    /// One persisted round-boundary consequence. Applications never call this directly, so a
    /// three-tick payload always means three future boundaries and relaunch preserves the count.
    static func tickAfflictions(run: inout WorldRun, encounter: inout EncounterState) {
        adoptLegacyAfflictions(in: &encounter)
        encounter.corrodeReceipts = encounter.corrodeReceipts.filter {
            $0.round >= encounter.roundNumber - 1
        }
        let snapshot = encounter.afflictions ?? []
        var remaining: [AfflictionInstance] = []
        for var affliction in snapshot.sorted(by: {
            if $0.target.storageKey != $1.target.storageKey {
                return $0.target.storageKey < $1.target.storageKey
            }
            return AfflictionDefinition.definition($0.kind).order
                < AfflictionDefinition.definition($1.kind).order
        }) {
            guard isAlive(affliction.target, in: withEncounter(encounter, on: run)) else { continue }
            if affliction.damage > 0 {
                if case .foe(let foeID) = affliction.target {
                    _ = applyFoeDamage(foeID: foeID, amount: affliction.damage,
                                       sourceActor: affliction.source,
                                       provenance: .affliction,
                                       run: &run, encounter: &encounter)
                } else {
                    hurt(affliction.target, by: affliction.damage, run: &run, encounter: &encounter)
                }
                encounter.note("\(actorName(affliction.target, encounter: encounter)) "
                               + "\(affliction.kind.legacyVerb) — \(affliction.damage).")
            }
            guard isAlive(affliction.target, in: withEncounter(encounter, on: run)) else { continue }
            if affliction.kind == .poison, case .foe(let targetID) = affliction.target,
               owns(CombatDerivedStatsRules.Node.corrode,
                    actor: affliction.source, encounter: encounter),
               let source = affliction.source {
                let receipt = EncounterState.CorrodeReceipt(source: source, target: targetID,
                                                             round: encounter.roundNumber)
                if encounter.corrodeReceipts.insert(receipt).inserted,
                   let foe = encounter.foes.first(where: { $0.id == targetID }) {
                    let current = encounter.foeArmourErosion[targetID] ?? 0
                    encounter.foeArmourErosion[targetID] = min(max(0, foe.stats.armour), current + 1)
                    encounter.note("Corrode wears \(foe.stats.displayName)'s armour down by 1.")
                }
            }
            if affliction.endless {
                remaining.append(affliction)
            } else if affliction.ticksRemaining > 1 {
                affliction.ticksRemaining -= 1
                remaining.append(affliction)
            }
        }
        encounter.afflictions = remaining
    }

    /// Whether the current actor is waiting on the player rather than acting for itself.
    static func needsPlayerInput(_ state: GameState) -> Bool {
        guard let encounter = state.worlds.activeRun?.activeEncounter, encounter.outcome == nil else { return false }
        if encounter.opening?.pendingFoeActions.isEmpty == false { return false }
        switch encounter.current {
        case .binder:
            // Manual until you've bought the right to automate yourself, and still manual if you
            // bought it and set no rules — an empty list shouldn't mean "stand there".
            return !state.base.hasAutomateSelfUnlock || state.base.binderGambits.isEmpty
        case .companion: return encounter.isCompanionOverridden
        case .foe: return false
        }
    }

    /// Runs everything that acts for itself — foes, and the companion via its gambits — until the
    /// player is on the clock again or the fight is over.
    ///
    /// Bounded rather than `while true`: a rule that somehow declines to act must not hang the app.
    static func runAutomaticTurns(in state: inout GameState) {
        var guardCount = 0
        while !needsPlayerInput(state),
              state.worlds.activeRun?.activeEncounter?.outcome == nil,
              guardCount < Tuning.Encounter.maxAutomaticTurnsPerInput {
            guardCount += 1
            guard var encounter = state.worlds.activeRun?.activeEncounter else { return }
            if let foeID = encounter.opening?.pendingFoeActions.first {
                encounter.opening?.pendingFoeActions.removeFirst()
                state.worlds.activeRun?.activeEncounter = encounter
                performFoeTurn(.foe(foeID), slot: .init(actor: .foe(foeID)),
                               advancesOrdinarySchedule: false, in: &state)
                continue
            }
            let actor = encounter.current

            switch actor {
            case .foe:
                performFoeTurn(actor, slot: encounter.currentTurnSlot, in: &state)
            case .companion, .binder:
                performAutomatedTurn(actor, in: &state)
            }
        }
    }

    /// Foes attack whoever is standing, in the manner their traits decided. PLACEHOLDER target
    /// selection — the design's automation interest is on the player's side of the fight.
    ///
    /// **How it hits you is what it is** (creature-system-spec §7): pierce goes through armour,
    /// crush lands heavier, rend leaves a wound that keeps costing you, and something that carries
    /// its own heat or venom isn't stopped by armour at all.
    private static func performFoeTurn(_ actor: Combatant, slot: EncounterState.TurnSlot,
                                       advancesOrdinarySchedule: Bool = true,
                                       in state: inout GameState) {
        guard var run = state.worlds.activeRun, var encounter = run.activeEncounter,
              let foeID = actor.foeID, let foe = encounter.foes.first(where: { $0.id == foeID })
        else { return }
        adoptV2ReceiptLedgers(in: &encounter)

        if advancesOrdinarySchedule, slot.kind == .primary,
           var receipt = encounter.snuffReceipts?[foeID], receipt.remainingScheduledTurns > 0 {
            receipt.suppressedRound = encounter.roundNumber
            encounter.snuffReceipts?[foeID] = receipt
        }

        let standing: [Combatant] = party(of: state).filter { isAlive($0, in: run) }
        let visibleTargets = standing.filter { (encounter.concealed[$0] ?? 0) <= 0 }
        // Concealment redirects attention while another legal target exists; an entirely concealed
        // party does not make the encounter unable to act.
        let targetable = visibleTargets.isEmpty ? standing : visibleTargets

        // **The front rank takes the melee** (session 17 §4). Targeting was uniform, so standing at
        // the back was pure upside — less damage, no more risk of being chosen — which is half a
        // rank system. Something with far reach ignores the line entirely, which is what reach is
        // *for*, and if everybody is at the back there's nobody to hide behind.
        let front = targetable.filter { rank(of: $0, in: encounter, fallback: state) == .front }
        let reachesPast = foe.stats.strikesFirst
            || (foe.stats.element != nil && !isSnuffed(foeID, in: encounter))
        let reachLegal = (reachesPast || front.isEmpty) ? targetable : front
        let isSingleTargetIntent: Bool = switch slot.kind {
        case .primary: foe.stats.delivery == .single
        case .apexFollowUp, .ordinaryPressureFollowUp: true
        }
        let reachable = guardianFilteredTargets(reachLegal,
            isSingleTargetDirect: isSingleTargetIntent, run: run, encounter: encounter, state: state)

        // **Draw Off.** Something you've taunted comes for you and doesn't get a choice — the only
        // way in the game to take a hit meant for somebody else.
        let forcedOwner: Combatant? = if let modern = encounter.drawOffReceipts {
            modern[foeID].flatMap { receipt in
                isAlive(receipt.owner, in: run)
                    && reachable.contains(receipt.owner) ? receipt.owner : nil
            }
        } else {
            (encounter.taunts[foeID] ?? 0) > 0 && isAlive(.binder, in: run)
                && reachable.contains(.binder) ? .binder : nil
        }
        let unused = reachable.filter { !(encounter.apexTargetsThisRound[foeID] ?? []).contains($0) }
        guard let primary = forcedOwner ?? run.rng.pick(unused.isEmpty ? reachable : unused) else {
            run.activeEncounter = encounter
            state.worlds.activeRun = run
            checkOutcome(in: &state)
            return
        }
        if case .ordinaryPressureFollowUp(let ordinal) = slot.kind {
            encounter.note("Lighter follow-up \(ordinal) — \(foe.stats.displayName.capitalisedSentence).")
        }

        // Delivery decides how many of you it reaches, and at what cost to each blow.
        let isFollowUp: Bool = switch slot.kind {
        case .primary: false
        case .apexFollowUp, .ordinaryPressureFollowUp: true
        }
        let delivery: ([Combatant], Double)
        if isFollowUp {
            delivery = ([primary], slot.strengthMultiplier)
        } else {
            delivery = switch foe.stats.delivery {
            case .single: ([primary], 1)
            case .multi: (targetable, Tuning.Encounter.multiDeliveryShare)
            case .area: (targetable, Tuning.Encounter.areaDeliveryShare)
            }
        }
        let (targets, share) = delivery

        for originalTarget in targets {
            let hasLighterFollowUp = encounter.turnSlots.contains {
                $0.actor == .foe(foeID) && $0.kind != .primary
            }
            if (foe.isApex || hasLighterFollowUp),
               !(encounter.apexTargetsThisRound[foeID] ?? []).contains(originalTarget) {
                encounter.apexTargetsThisRound[foeID, default: []].append(originalTarget)
            }
            var target = originalTarget
            var wasInterposed = false
            var grounded = false
            if foe.stats.element != nil, !isSnuffed(foeID, in: encounter),
               let ashe = standing.first(where: { member in
                   member.rosterIndex.flatMap {
                       state.base.roster.indices.contains($0) ? state.base.roster[$0].traveller : nil
                   } == TravellerID(rawValue: "ashe")
               }), originalTarget != ashe, (encounter.grounding[ashe] ?? 0) > 0 {
                encounter.grounding.removeValue(forKey: ashe)
                target = ashe
                grounded = true
                encounter.note("Ground: Ashe receives the emanation meant for \(actorName(originalTarget, encounter: encounter).lowercased()).")
            }
            let redirectable = isFollowUp || foe.stats.delivery == .single
            if redirectable, let receipts = encounter.interposeReceipts {
                let intendedTarget = target
                let candidates = receipts.filter {
                    $0.owner != intendedTarget && isAlive($0.owner, in: run)
                }.sorted {
                    if $0.activationSequence != $1.activationSequence {
                        return $0.activationSequence < $1.activationSequence
                    }
                    return $0.owner.storageKey < $1.owner.storageKey
                }
                if let chosen = candidates.first {
                    target = chosen.owner
                    wasInterposed = true
                    grounded = false
                    encounter.interposeReceipts?.removeAll {
                        $0.owner == chosen.owner && $0.activationSequence == chosen.activationSequence
                    }
                    encounter.concealed[chosen.owner] = nil
                    encounter.note("\(actorName(chosen.owner, encounter: encounter)) interposes.")
                }
            }
            // **Not where the blow landed** (session 17 §1). Finesse on the party's side, the
            // mirror of the evasion creatures have had since they were generated.
            let isSingleTargetDirect = isFollowUp || foe.stats.delivery == .single
            if isSingleTargetDirect {
                recordUntouchableTarget(target, isForcedOpening: !advancesOrdinarySchedule,
                                        encounter: &encounter)
                if resolvePartyMiss(target, in: state, run: &run, encounter: &encounter) {
                    encounter.note("\(foe.stats.displayName.capitalisedSentence) finds nothing where \(actorName(target, encounter: encounter).lowercased()) was.")
                    continue
                }
                recordUntouchableLanding(target, isForcedOpening: !advancesOrdinarySchedule,
                                          encounter: &encounter)
            }
            var raw = Double(roll(around: foe.stats.attack, run: &run)) * share
            if grounded { raw *= 0.5 }
            if foe.stats.damageKind == .crush { raw *= 1 + Tuning.Encounter.crushDamageBonus }

            // **Ward.** Turns aside one harm, so you have to know what's coming — which is what
            // Sight is for. Guessing wrong costs you the round you spent setting it.
            let incoming: Harm = (isSnuffed(foeID, in: encounter) ? nil : foe.stats.element)
                .map(Harm.emanation) ?? .blow(foe.stats.damageKind)
            let wardMultiplier: Double
            if let modern = encounter.wardReceipts {
                let receipt = modern[target]
                wardMultiplier = receipt?.harm == incoming
                    && (receipt?.expiresBeforeRound ?? 0) > encounter.roundNumber
                    ? 1 - Tuning.Encounter.wardReduction : 1
            } else {
                wardMultiplier = encounter.wards[target]?.harm == incoming
                    ? 1 - Tuning.Encounter.wardReduction : 1
            }
            // The Haft is a modest continuous ward against one authored blow type. Applied after
            // the skill ward so the two stack multiplicatively rather than replacing each other.

            let amount: Int
            // **Snuff** puts out whatever it was giving off, and with it the damage nothing you
            // wear could stop.
            if let element = foe.stats.element, !isSnuffed(foeID, in: encounter) {
                let wornMultiplier = element == .heat
                    ? 1 - min(Tuning.Encounter.maximumInsulation,
                              insulation(of: target, in: state) * Tuning.Encounter.insulationPerPoint)
                    : 1
                if let receipt = encounter.debugV2Resistance {
                    let reduced = CombatDerivedStatsRules.emanationDamage(
                        raw: raw, element: element, receiver: target, receipt: receipt,
                        wornInsulationMultiplier: wornMultiplier,
                        wardMultiplier: wardMultiplier)
                    amount = v2EmanationArmourDamage(
                        reduced.roundedDamage, by: target, in: state, run: run,
                        encounter: encounter)?.finalDamage ?? reduced.finalDamage
                } else {
                    // Preserve the frozen legacy arithmetic for encounters without a v2 receipt.
                    amount = max(Tuning.Encounter.minimumDamage,
                                 Int((raw * wornMultiplier * wardMultiplier).rounded()))
                }
            } else {
                raw *= wardMultiplier
                if case .blow(let kind) = incoming {
                    raw *= wardedHaftMultiplier(against: kind, for: target, in: state)
                }
                let immovable = encounter.debugV2Armour?.entry(for: target)?
                    .ownedNodeIDs.contains(CombatDerivedStatsRules.Node.immovable) == true
                let ignored = foe.stats.damageKind == .pierce && !immovable
                    ? Tuning.Encounter.pierceArmourIgnored : 0
                amount = damageTaken(Int(raw.rounded()), by: target, in: state, run: run,
                                     encounter: encounter, armourIgnored: ignored)
            }
            let wasStanding = isAlive(target, in: run)
            var braceApplies = false
            if isSingleTargetDirect || (!isFollowUp && [.multi, .area].contains(foe.stats.delivery)),
               var receipt = encounter.braceReceipts?[target] {
                if receipt.hostileActor == nil {
                    receipt.hostileActor = actor
                    receipt.round = encounter.roundNumber
                    receipt.slotIndex = encounter.turnIndex
                }
                if receipt.hostileActor == actor, receipt.round == encounter.roundNumber,
                   receipt.slotIndex == encounter.turnIndex {
                    receipt.triggered = true
                    encounter.braceReceipts?[target] = receipt
                    braceApplies = true
                }
            }
            if let allocation = coverAllocation(finalDamage: amount, target: target,
                wasInterposed: wasInterposed, run: run, encounter: encounter, state: state) {
                hurt(target, by: allocation.targetDamage, braceApplies: braceApplies,
                     run: &run, encounter: &encounter)
                hurt(allocation.owner, by: allocation.coverDamage,
                     run: &run, encounter: &encounter)
                encounter.note("\(actorName(allocation.owner, encounter: encounter)) covers \(allocation.coverDamage).")
            } else {
                hurt(target, by: amount, braceApplies: braceApplies,
                     run: &run, encounter: &encounter)
            }
            if wasStanding, !isAlive(target, in: run), target.rosterIndex != nil {
                encounter.note("\(actorName(target, encounter: encounter)) goes down. They'll be all right at home.")
            }

            let verb = (isSnuffed(foeID, in: encounter) ? nil : foe.stats.element)
                .map(elementalVerb) ?? foe.stats.damageKind.verb
            // "You" is a pronoun mid-sentence and "Quill" is a name, so only one of them lowers.
            let whom = target == .binder
                ? actorName(target, encounter: encounter).lowercased()
                : actorName(target, encounter: encounter)
            encounter.note("\(foe.stats.displayName.capitalisedSentence) \(verb) \(whom) for \(amount).")

            // Rend's wound outlives the blow.
            if foe.stats.damageKind == .rend, !slot.suppressesAfflictions {
                let outcome = applyAffliction(.bleed, to: target, source: .foe(foeID),
                                              provenance: .direct,
                                              damage: Tuning.Encounter.bleedDamage,
                                              ticks: Tuning.Encounter.bleedRounds,
                                              targetIsStanding: isAlive(target, in: run),
                                              encounter: &encounter)
                if outcome != .prevented && outcome != .noChange {
                    encounter.note("The wound won't close.")
                }
            }

            // **And so does what it gives off** (Q42). Emanation was generated, named in the
            // description, and did nothing beyond one armour-ignoring hit. Snuff puts a stop to it.
            if let element = foe.stats.element, !isSnuffed(foeID, in: encounter), !slot.suppressesAfflictions {
                let status = StatusKind.from(element)
                let outcome = applyAffliction(status.afflictionID, to: target,
                                              source: .foe(foeID), provenance: .direct,
                                              damage: Tuning.Encounter.statusDamage[status.rawValue] ?? 0,
                                              ticks: Tuning.Encounter.statusRounds[status.rawValue] ?? 2,
                                              targetIsStanding: isAlive(target, in: run),
                                              encounter: &encounter)
                if outcome != .prevented && outcome != .noChange {
                    encounter.note(status == .dazzle
                                   ? "The after-image sits in your eyes."
                                   : "It's still \(status == .burn ? "burning" : "spreading").")
                }
            }
        }

        // Consume only after the whole hostile slot so every direct event from the same authored
        // multi/area slot receives the one armed reduction. A miss or other target leaves it armed.
        if encounter.braceReceipts != nil {
            encounter.braceReceipts = encounter.braceReceipts?.filter { _, receipt in
                !(receipt.triggered && receipt.hostileActor == actor
                  && receipt.round == encounter.roundNumber
                  && receipt.slotIndex == encounter.turnIndex)
            }
        }

        if advancesOrdinarySchedule, var receipt = encounter.snuffReceipts?[foeID],
           receipt.suppressedRound == encounter.roundNumber {
            let hasLaterOwnedSlot = encounter.turnSlots.indices.contains { index in
                index > encounter.turnIndex && encounter.turnSlots[index].actor == actor
            }
            if !hasLaterOwnedSlot {
                receipt.remainingScheduledTurns -= 1
                receipt.suppressedRound = nil
                encounter.snuffReceipts?[foeID] = receipt.remainingScheduledTurns > 0 ? receipt : nil
            }
        }
        if encounter.foes.first(where: { $0.id == foeID })?.isAlive != true {
            encounter.snuffReceipts?[foeID] = nil
        }

        run.activeEncounter = encounter
        state.worlds.activeRun = run
        if advancesOrdinarySchedule { advanceTurn(in: &state) }
        checkOutcome(in: &state)
    }

    private static func elementalVerb(_ element: EmanationKind) -> String {
        switch element {
        case .light: "sears"
        case .heat: "scorches"
        case .caustic: "burns"
        }
    }

    private static func performAutomatedTurn(_ actor: Combatant, in state: inout GameState) {
        guard let run = state.worlds.activeRun, let encounter = run.activeEncounter else { return }

        if let decision = GambitEngine.decide(for: actor, in: state) {
            state.worlds.activeRun?.activeEncounter?.note(
                "\(actorName(actor, encounter: encounter)): \(decision.rule.displayText)"
            )
            perform(decision.action, by: actor, in: &state)
        } else {
            // No rule matched, or every matching rule wanted something unavailable. Standing there
            // is the honest outcome — it's what makes rule ORDER matter, and it's visible.
            state.worlds.activeRun?.activeEncounter?.note("\(actorName(actor, encounter: encounter)) waits — no rule fits.")
            advanceTurn(in: &state)
        }
    }

    // MARK: Ending

    static func checkOutcome(in state: inout GameState) {
        guard var run = state.worlds.activeRun, var encounter = run.activeEncounter, encounter.outcome == nil
        else { return }

        if encounter.isResolved {
            encounter.outcome = .victory
            encounter.note("Nothing left standing.")
            awardSpoils(run: &run, encounter: &encounter, state: &state)
            awardExperience(for: encounter.foes, run: &run, encounter: &encounter, state: &state)
            let grown = growLivingHooks(in: &state)
            encounter.spoils.append(contentsOf: grown)
        } else if run.binderHP <= 0 {
            // **Nobody dies, and the Binder going down ends the run** (session 17 §6): *"companions
            // can never die. They pass out and are revived back in town. If the Binder passes out,
            // it's treated exactly like a world collapsing."*
            //
            // This used to require **both** of you to be down, which meant a Binder at zero kept
            // walking around a world on Quill's legs. The Binder is the one holding the book.
            encounter.outcome = .defeated
            encounter.note("You go down. Somebody gets you home.")
        }
        run.activeEncounter = encounter
        state.worlds.activeRun = run
    }

    /// One growth credit per won encounter, regardless of hits or killing blows. Growth belongs to
    /// the equipped instance and is distinct from Blacksmith upgrades.
    private static func growLivingHooks(in state: inout GameState) -> [String] {
        var lines: [String] = []
        func grow(_ piece: inout EquippedPiece?) {
            guard piece?.gear?.breaks == .growingGrade,
                  let current = piece?.wildGrowth,
                  current < Tuning.Apex.livingHookGrowthCap else { return }
            piece?.wildGrowth = current + 1
            if let name = piece?.displayName { lines.append("\(name) grew after the fight") }
        }
        grow(&state.base.binderEquipped[.weapon])
        for index in state.base.activeParty where state.base.roster.indices.contains(index) {
            grow(&state.base.roster[index].equipped[.weapon])
        }
        return lines
    }

    /// **What the fight was worth**, scaled by what you beat rather than flat — picking on
    /// something far below you stops paying (session 17 §2).
    ///
    /// Both of them get it. A companion who levelled only when you did wouldn't be a character,
    /// and one who levelled separately would drift out of the party.
    private static func awardExperience(for foes: [FoeState], run: inout WorldRun,
                                        encounter: inout EncounterState,
                                        state: inout GameState) {
        let partyLevel = state.base.partyMembers.map { state.base.character($0).level }.max() ?? 1
        let earned = foes.reduce(0) {
            $0 + CharacterRules.experience(forDefeating: $1, partyLevel: partyLevel)
        }
        guard earned > 0 else { return }

        var gained: [String] = []
        for member in state.base.partyMembers {
            var levels = 0
            state.base.withCharacter(member) { levels = CharacterRules.award(earned, to: &$0) }
            if levels > 0 {
                let name: String
                if let index = member.rosterIndex, state.base.roster.indices.contains(index) {
                    name = "\(state.base.roster[index].name) is"
                } else {
                    name = "You are"
                }
                gained.append("\(name) level \(state.base.character(member).level).")
            }
        }
        run.experienceBreakdown.combat += earned
        encounter.note("\(earned) experience.")
        for line in gained { encounter.note(line) }
    }

    /// Rolls what the fight paid out, straight into the satchel, and records it in plain words.
    ///
    /// Two halves. **Resources** come off the *world's own* yield table, so what you win reflects
    /// where you are — an ore-rich world pays in ore. **Materials** come off the creature itself
    /// (creature-system-spec §8): the parts that composed it compose what it leaves, so a world that
    /// grows monstrous armoured things drops monstrous plates.
    private static func awardSpoils(run: inout WorldRun, encounter: inout EncounterState, state: inout GameState) {
        var gained = ResourcePool()
        var found: [String] = []

        for foe in encounter.foes {
            // How much a kill is worth follows what the world spent making it, rather than an
            // authored tier — a world that grows monstrous things pays out for monstrous things.
            let tier = foe.traits.map(CreatureIdentity.tier(of:))
                ?? foe.creatureID.flatMap { ContentCatalog.shared.creature($0)?.tier }
                ?? 1
            let amount = tier * run.rng.int(in: Tuning.Encounter.lootPerTierRange)
            // **What a world pays comes off its readings, not off a symbol's table.** The
            // book-level table gives every resource the same flat weight, so with a real catalogue
            // it would drop adamant off a barren world as readily as rubble — describing a world it
            // did not generate (`audit-what-pressures-actually-do.md` §4.1). Node placement has read
            // the pressures since that audit; kill drops hadn't caught up.
            let paid = BookRules.yieldTable(from: BookRules.readings(for: run.book, seed: run.mapSeed))
            if let resource = run.rng.pickWeighted(paid) {
                run.satchel.add(amount, of: resource)
                gained.add(amount, of: resource)
                state.reality.discovery.recordResource(resource, runIndex: run.runIndex)
            }
            if let traits = foe.traits {
                found.append(contentsOf: butcher(traits, named: foe.stats.displayName,
                                                 qualifier: foe.qualifier, foeID: foe.id,
                                                 run: &run))
            }
            // **Gear drops too** (Aimee, 5 Aug). Sites were the only source, so a run that fought
            // its way across a world and found no ruin came home with nothing to wear — and now
            // that weapons carry a damage type, what you're carrying is the decision a fight is
            // supposed to reward.
            if run.rng.chance(Tuning.Economy.gearDropChance * Double(tier)) {
                let gear = ContentCatalog.shared.items
                    .filter { $0.kind == .gear && ($0.gear?.tier ?? 0) <= tier + 1 }
                    .map(\.id).sorted { $0.rawValue < $1.rawValue }
                if let piece = run.rng.pick(gear) {
                    let name = ContentCatalog.shared.item(piece)?.name ?? "Something worn"
                    let stack = ItemStack(id: InstanceID(rawValue: run.rng.next()), catalogID: piece)
                    if run.satchelItems.add(stack) {
                        found.append(name)
                    } else {
                        run.offeredItems.append(stack)
                        found.append("\(name) — no room; waiting on you")
                    }
                }
            }

            // **What an apex leaves, and what luck occasionally leaves instead** (`apex-encounters.md`
            // §4–5). The apex is the *reliable* path and the lottery is the surprise: a player who
            // never fights one still occasionally finds something they cannot make, and that is a
            // better memory than a guaranteed drop precisely because it wasn't earned.
            let hunted = foe.isApex
            if hunted || run.rng.chance(Tuning.Apex.ordinaryCreatureChance) {
                let readings = BookRules.readings(for: run.book, seed: run.mapSeed)
                if let id = ApexRules.weapon(for: readings, rng: &run.rng) {
                    let name = ContentCatalog.shared.item(id)?.name ?? "Something you couldn't make"
                    let stack = ItemStack(id: InstanceID(rawValue: run.rng.next()), catalogID: id)
                    if run.satchelItems.add(stack) {
                        found.append(name)
                    } else {
                        run.offeredItems.append(stack)
                        found.append("\(name) — no room; waiting on you")
                    }
                }
            }

            // Curios drop unidentified — this is where keys enter the world, one identify and one
            // long walk before they open anything.
            if run.rng.chance(Tuning.Economy.curioDropChance) {
                let curios = ContentCatalog.shared.items.filter { $0.kind == .curio }
                    .map(\.id).sorted { $0.rawValue < $1.rawValue }
                if let curio = run.rng.pick(curios) {
                    let name = ContentCatalog.shared.item(curio)?.unidentifiedName ?? "Something odd"
                    let stack = ItemStack(id: InstanceID(rawValue: run.rng.next()),
                                          catalogID: curio, count: 1, identified: false)
                    // A full satchel neither swallows the loot nor discards it — it hands you
                    // the choice. Held on the run until you make it, so a force-quit mid-decision
                    // resumes with the decision still open.
                    if run.satchelItems.add(stack) {
                        found.append(name)
                    } else {
                        run.offeredItems.append(stack)
                        found.append("\(name) — no room; waiting on you")
                    }
                }
            }
        }

        encounter.spoils = gained.nonZero.map { entry in
            "\(entry.amount) \(ContentCatalog.shared.resource(entry.id)?.name.lowercased() ?? entry.id.rawValue)"
        } + found
    }

    /// Cuts a body into exact property-bearing reserve units. Material never consumes a satchel
    /// slot or enters the loot-swap queue; source identity is the saved run + defeated combatant.
    private static func butcher(_ traits: CreatureTraits, named name: String,
                                qualifier: String?, foeID: InstanceID,
                                run: inout WorldRun) -> [String] {
        var lines: [String] = []
        let count = ButcheryRules.quantity(from: traits, rng: &run.rng)

        for (dropOrdinal, sample) in ButcheryRules.materials(
            from: traits, named: name, qualifier: qualifier
        ).enumerated() {
            run.materialReserve.addHarvested(
                sample, count: count,
                sourceReceipt: "run:\(run.runIndex):foe:\(foeID.rawValue)",
                dropOrdinal: dropOrdinal)
            lines.append(count > 1 ? "\(sample.displayName) ×\(count)" : sample.displayName)
        }
        return lines
    }

    /// Closes out a finished fight: bestiary, and taking the defeated off the grid.
    ///
    /// Defeated foes must leave the map — a foe shares its id with the `WorldEnemy` that spawned
    /// it, and leaving it standing on the player's tile would re-trigger the same fight forever.
    @discardableResult
    static func conclude(in state: inout GameState) -> [WorldRules.Event] {
        guard var run = state.worlds.activeRun,
              let encounter = run.activeEncounter,
              let outcome = encounter.outcome
        else { return [] }

        let events: [WorldRules.Event] = []

        switch outcome {
        case .victory:
            let defeated = Set(encounter.foes.map(\.id))
            run.enemies.removeAll { defeated.contains($0.id) }
            state.reality.lifetime.encountersWon += 1
            // Spoils were already rolled and banked into the satchel at the moment of victory, so
            // the victory screen could show them. Nothing left to do but clear the board.

        case .fled:
            state.reality.lifetime.encountersFled += 1
            // Retreat to where you came from, and hold off bumps for a turn — otherwise the foe
            // you just fled walks straight back into you and "flee" means nothing.
            if let previous = run.previousPosition, WorldRules.canEnter(previous, in: run.map),
               !run.enemies.contains(where: { $0.position == previous }) {
                run.playerPosition = previous
            }
            run.encounterGraceTurns = Tuning.Encounter.fleeGraceTurns

        case .defeated:
            break // the run ends; the caller banks a partial haul
        }

        run.activeEncounter = nil
        state.worlds.activeRun = run
        return events
    }
}
