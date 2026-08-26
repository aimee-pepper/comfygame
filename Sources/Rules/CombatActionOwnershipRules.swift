import Foundation

/// One authority for why a party member can perform a named combat technique.
///
/// Legacy `SkillDef.owner` values describe the old two-person catalogue and are decode-only. New
/// runtime ownership comes from identity or the exact stable graph nodes a character owns.
enum CombatActionOwnershipRules {
    static let binderInnate: Set<SkillID> = ["unbind", "sight"]
    static let quillInnate: Set<SkillID> = ["mend", "read"]
    static let asheInnate: Set<SkillID> = ["ground"]
    static let retiredDecodeOnly: Set<SkillID> = ["rout"]

    static func innateSkillIDs(for actor: Combatant, in state: GameState) -> Set<SkillID> {
        switch actor {
        case .binder:
            return binderInnate
        case .companion(let id):
            guard let index = state.base.rosterIndex(for: id) else { return [] }
            // Quill is the documented, always-present roster member at index zero. Do not infer
            // Quill from `traveller == nil`: generated people share that representation today.
            var result = id == .founderQuill ? quillInnate : []
            if state.base.roster[index].traveller == TravellerID(rawValue: "ashe") {
                result.formUnion(asheInnate)
            }
            return result
        case .foe:
            return []
        }
    }

    static func availableSkillIDs(for actor: Combatant, in state: GameState) -> Set<SkillID> {
        guard actor.isParty else { return [] }
        let graph = CombatTreeRules.loadout(for: state.base.character(actor.member)).skills
        return innateSkillIDs(for: actor, in: state)
            .union(graph)
            .subtracting(retiredDecodeOnly)
    }
}
