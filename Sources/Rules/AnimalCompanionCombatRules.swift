import Foundation

enum AnimalPartyRefusalV1: String, Codable, Equatable, Sendable, Error {
    case missingAnimal, notAtMenagerie, expeditionActive, partyFull, staleQuote, malformedRecord

    var copy: String {
        switch self {
        case .missingAnimal: "That animal is no longer available."
        case .notAtMenagerie: "That animal is not resting at the Menagerie."
        case .expeditionActive: "Change the travelling party at Home."
        case .partyFull: "The travelling party is full."
        case .staleQuote: "That animal’s posting changed. Review the party and try again."
        case .malformedRecord: "That animal’s companion record cannot be used."
        }
    }
}

struct AnimalPartyQuoteV1: Equatable, Sendable {
    enum Change: Equatable, Sendable { case add, remove }
    var animalID: TamedAnimalID
    var change: Change
    var expected: TamedAnimalCompanionStateV1
    var expectedActiveParty: [PersistentPartyMemberID]
}

enum AnimalPartyCommitResultV1: Equatable, Sendable {
    case committed
    case refused(AnimalPartyRefusalV1)
}

enum AnimalCombatRefusalV1: String, Codable, Equatable, Sendable, Error {
    case wrongOwner, passedOut, actionUnavailable, targetUnavailable, illegalRankStep
    case staleQuote, humanOnlyCapability

    var copy: String {
        switch self {
        case .wrongOwner, .actionUnavailable: "That action is no longer available."
        case .passedOut: "That animal has passed out."
        case .targetUnavailable: "That target is no longer available."
        case .illegalRankStep: "That rank move is no longer available."
        case .staleQuote: "The fight changed. Review the action and try again."
        case .humanOnlyCapability: "Animals do not use human equipment or combat trees."
        }
    }
}

enum AnimalCombatCommandV1: Equatable, Sendable {
    case instinctiveAttack(foe: InstanceID)
    case interpose(ally: Combatant)
    case harrier(foe: InstanceID, destinationRank: Rank)
    case slipAway(destinationRank: Rank)
    case warningDisplay
    case commit(foe: InstanceID)
}

struct AnimalCombatQuoteV1: Equatable, Sendable {
    var version = 1
    var owner: Combatant
    var command: AnimalCombatCommandV1
    var expectedEncounter: EncounterState
}

enum AnimalCombatCommitResultV1: Equatable, Sendable {
    case committed
    case refused(AnimalCombatRefusalV1)
}

enum AnimalCompanionCombatRules {
    static let instinctiveActionID = "animal.instinctive_attack"

    static func dominantTechnique(for traits: CreatureTraits) -> AnimalDominantTechniqueV1 {
        switch traits.defence {
        case .armour: .interpose
        case .speed: .harrier
        case .crypsis: .slipAway
        case .aposematism: .warningDisplay
        case nil: .commit
        }
    }

    static func resolvedLevel(for enemy: WorldEnemy, in run: WorldRun, binderLevel: Int) -> Int {
        let greed = Double(BookRules.greedDelta(for: BookRules.sigils(for: run.book)))
        return min(Tuning.Character.maximumLevel, max(1, CharacterRules.foeLevel(
            partyLevel: binderLevel, stability: run.stability, greed: greed)))
    }

    static func originReceipt(animal: RealityState.TamedAnimalV1, displayName: String,
                              icon: String, level: Int,
                              provenance: AnimalCombatSourceProvenanceV1) -> AnimalCombatOriginReceiptV1? {
        guard let id = TamedAnimalID(animal: animal), !displayName.isEmpty,
              (1...Tuning.Character.maximumLevel).contains(level) else { return nil }
        return .init(animalID: id, frozenDisplayName: displayName,
                     levelOneStats: CombatStats.derived(from: animal.traits,
                                                        name: displayName, icon: icon),
                     reach: animal.traits.armament.reach, startingLevel: level,
                     startingExperience: CharacterRules.experienceForLevel(level),
                     dominantTechnique: dominantTechnique(for: animal.traits),
                     sourceProvenance: provenance)
    }

    static func scaledStats(_ state: TamedAnimalCompanionStateV1) -> CombatStats {
        var stats = state.originReceipt.levelOneStats
        stats.maxHP = CharacterRules.scaled(stats.maxHP, toLevel: state.level)
        stats.attack = CharacterRules.scaled(stats.attack, toLevel: state.level)
        stats.armour = CharacterRules.scaled(stats.armour, toLevel: state.level)
        return stats
    }

    static func evaluatePartyChange(_ animalID: TamedAnimalID, in state: GameState)
        -> Result<AnimalPartyQuoteV1, AnimalPartyRefusalV1> {
        guard state.worlds.activeRun == nil else { return .failure(.expeditionActive) }
        guard let animal = state.reality.tamedAnimals[animalID.rawValue],
              let companion = state.base.tamedAnimalCompanions[animalID] else {
            return .failure(.missingAnimal)
        }
        guard companion.validates(animal: animal) else { return .failure(.malformedRecord) }
        let memberID = PersistentPartyMemberID.animal(animalID.rawValue)
        if companion.posting == .activeParty {
            guard state.base.activeParty.contains(memberID) else { return .failure(.malformedRecord) }
            return .success(.init(animalID: animalID, change: .remove, expected: companion,
                                  expectedActiveParty: state.base.activeParty))
        }
        guard companion.posting == .menagerie else { return .failure(.notAtMenagerie) }
        guard state.base.canTakeAnother else { return .failure(.partyFull) }
        return .success(.init(animalID: animalID, change: .add, expected: companion,
                              expectedActiveParty: state.base.activeParty))
    }

    static func commitPartyChange(_ quote: AnimalPartyQuoteV1, in state: inout GameState)
        -> AnimalPartyCommitResultV1 {
        guard case .success(let current) = evaluatePartyChange(quote.animalID, in: state),
              current == quote else { return .refused(.staleQuote) }
        var candidate = state
        let memberID = PersistentPartyMemberID.animal(quote.animalID.rawValue)
        switch quote.change {
        case .add:
            candidate.base.tamedAnimalCompanions[quote.animalID]?.posting = .activeParty
            candidate.base.activeParty.append(memberID)
        case .remove:
            candidate.base.tamedAnimalCompanions[quote.animalID]?.posting = .menagerie
            candidate.base.activeParty.removeAll { $0 == memberID }
        }
        guard candidate.validatesAnimalCompanionCombat() else { return .refused(.malformedRecord) }
        state = candidate
        return .committed
    }

    static func returnTravellingAnimals(runIndex: Int, in state: inout GameState) {
        for id in state.base.tamedAnimalCompanions.keys.sorted() {
            guard state.base.tamedAnimalCompanions[id]?.posting == .travelling(runIndex: runIndex)
            else { continue }
            state.base.tamedAnimalCompanions[id]?.posting = .menagerie
        }
    }

    static func evaluate(_ command: AnimalCombatCommandV1, owner: Combatant,
                         in state: GameState) -> Result<AnimalCombatQuoteV1, AnimalCombatRefusalV1> {
        guard let run = state.worlds.activeRun, let encounter = run.activeEncounter,
              encounter.current == owner else { return .failure(.wrongOwner) }
        guard CombatRules.isAlive(owner, in: run) else { return .failure(.passedOut) }
        guard let participant = encounter.animalParticipants?[owner],
              participant.availableActionIDs.contains(instinctiveActionID) else {
            return .failure(.humanOnlyCapability)
        }
        let technique = participant.dominantTechnique
        func targetIsLive(_ id: InstanceID) -> Bool {
            encounter.foes.contains { $0.id == id && $0.isAlive }
                && encounter.revealed.contains(id)
        }
        switch command {
        case .instinctiveAttack(let foe):
            guard targetIsLive(foe) else { return .failure(.targetUnavailable) }
        case .interpose(let ally):
            guard technique == .interpose else { return .failure(.actionUnavailable) }
            guard ally != owner, ally.isParty, CombatRules.isAlive(ally, in: run),
                  encounter.partyRanks[ally] != nil else { return .failure(.targetUnavailable) }
        case .harrier(let foe, let destination):
            guard technique == .harrier else { return .failure(.actionUnavailable) }
            guard encounter.partyRanks[owner] != destination else {
                return .failure(.illegalRankStep)
            }
            guard targetIsLive(foe) else { return .failure(.targetUnavailable) }
        case .commit(let foe):
            guard technique == .commit else { return .failure(.actionUnavailable) }
            guard targetIsLive(foe) else { return .failure(.targetUnavailable) }
        case .slipAway(let destination):
            guard technique == .slipAway else { return .failure(.actionUnavailable) }
            guard encounter.partyRanks[owner] != destination else {
                return .failure(.illegalRankStep)
            }
        case .warningDisplay:
            guard technique == .warningDisplay else { return .failure(.actionUnavailable) }
        }
        return .success(.init(owner: owner, command: command, expectedEncounter: encounter))
    }

    static func commit(_ quote: AnimalCombatQuoteV1, in state: inout GameState)
        -> AnimalCombatCommitResultV1 {
        guard quote.version == 1,
              state.worlds.activeRun?.activeEncounter == quote.expectedEncounter else {
            return .refused(.staleQuote)
        }
        guard case .success(let current) = evaluate(quote.command, owner: quote.owner, in: state),
              current == quote else { return .refused(.staleQuote) }
        var candidate = state
        switch quote.command {
        case .instinctiveAttack(let foe):
            CombatRules.perform(.attack(foe: foe), by: quote.owner, in: &candidate)
        case .harrier(let foe, let destination):
            CombatRules.perform(.attack(foe: foe), by: quote.owner, in: &candidate)
            candidate.worlds.activeRun?.activeEncounter?.partyRanks[quote.owner] = destination
        case .commit(let foe):
            guard let receipt = candidate.worlds.activeRun?.activeEncounter?
                .animalParticipants?[quote.owner] else { return .refused(.staleQuote) }
            var boosted = receipt
            boosted.scaledStats.attack = max(1, Int((Double(receipt.scaledStats.attack)
                * receipt.commitStrengthMultiplier).rounded()))
            candidate.worlds.activeRun?.activeEncounter?
                .animalParticipants?[quote.owner] = boosted
            CombatRules.perform(.attack(foe: foe), by: quote.owner, in: &candidate)
            candidate.worlds.activeRun?.activeEncounter?
                .animalParticipants?[quote.owner] = receipt
            candidate.worlds.activeRun?.activeEncounter?.skippedTurns[quote.owner, default: 0] += 1
        case .interpose:
            guard var encounter = candidate.worlds.activeRun?.activeEncounter else {
                return .refused(.staleQuote)
            }
            encounter.interposeReceipts = encounter.interposeReceipts ?? []
            encounter.interposeReceipts?.removeAll { $0.owner == quote.owner }
            encounter.interposeReceipts?.append(.init(
                owner: quote.owner, activationSequence: encounter.nextInterposeActivationSequence))
            encounter.nextInterposeActivationSequence += 1
            let name = quote.owner.persistentPartyMemberID
                .flatMap { encounter.partyNames[$0] } ?? "Animal"
            encounter.note("\(name) interposes.")
            candidate.worlds.activeRun?.activeEncounter = encounter
            CombatRules.advanceTurn(in: &candidate)
        case .slipAway(let destination):
            candidate.worlds.activeRun?.activeEncounter?.partyRanks[quote.owner] = destination
            candidate.worlds.activeRun?.activeEncounter?.animalSlipAwayOwners?.insert(quote.owner)
            CombatRules.advanceTurn(in: &candidate)
        case .warningDisplay:
            candidate.worlds.activeRun?.activeEncounter?.animalWarningDisplayOwners?.insert(quote.owner)
            CombatRules.advanceTurn(in: &candidate)
        }
        guard candidate != state, candidate.validatesAnimalCompanionCombat() else {
            return .refused(.staleQuote)
        }
        state = candidate
        return .committed
    }
}

extension GameState {
    func validatesAnimalCompanionCombat() -> Bool {
        guard reality.tamedAnimals.count == base.tamedAnimalCompanions.count else { return false }
        for (rawID, animal) in reality.tamedAnimals {
            let id = TamedAnimalID(rawValue: rawID)
            guard let companion = base.tamedAnimalCompanions[id], companion.validates(animal: animal)
            else { return false }
            let memberID = PersistentPartyMemberID.animal(rawID)
            let occurrences = base.activeParty.filter { $0 == memberID }.count
            switch companion.posting {
            case .activeParty: if occurrences != 1 { return false }
            case .menagerie, .travelling: if occurrences != 0 { return false }
            }
        }
        guard base.activeParty.allSatisfy({
            !$0.rawValue.hasPrefix("animal:") || base.animalCompanion(for: $0)?.posting == .activeParty
        }) else { return false }
        for companion in base.tamedAnimalCompanions.values {
            if case .travelling(let runIndex) = companion.posting,
               worlds.activeRun?.runIndex != runIndex { return false }
        }
        let runs = [worlds.activeRun].compactMap { $0 } + worlds.anchoredRealms.map(\.world)
        for run in runs {
            guard let encounter = run.activeEncounter else { continue }
            let animalActors = Set(encounter.order.filter {
                guard case .companion(let id) = $0 else { return false }
                return id.rawValue.hasPrefix("animal:")
            })
            let receipts = encounter.animalParticipants ?? [:]
            guard Set(receipts.keys) == animalActors else { return false }
            if !animalActors.isEmpty,
               (encounter.animalSlipAwayOwners == nil
                || encounter.animalWarningDisplayOwners == nil) { return false }
            guard encounter.animalSlipAwayOwners?.allSatisfy(animalActors.contains) ?? true,
                  encounter.animalWarningDisplayOwners?.allSatisfy(animalActors.contains) ?? true
            else { return false }
            for (actor, receipt) in receipts {
                guard case .companion(let memberID) = actor,
                      memberID == receipt.memberID,
                      let companion = base.tamedAnimalCompanions[receipt.animalID],
                      receipt.validates(companion: companion) else { return false }
            }
            if let override = encounter.manualOverrideOwner,
               case .companion(let id) = override, id.rawValue.hasPrefix("animal:"),
               !animalActors.contains(override) { return false }
        }
        return true
    }
}
