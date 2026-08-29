import Foundation

/// Bracken rebuilds one existing protective instance in place. The preview freezes both the base
/// and exact stock locations so a stale confirmation can never spend around changed state.
enum ArmouryRules {
    typealias Requirement = PhysicalGearCraftingRules.SampleRequirement
    typealias Floor = PhysicalGearCraftingRules.PropertyFloor
    typealias Selection = PhysicalGearCraftingRules.Selection

    struct Profile: Identifiable, Equatable, Sendable {
        var id: String
        var name: String
        var minimumEffectiveTier: Int
        var allowedSlots: Set<GearSlot>
        var physicalOffset: Double
        var requirements: [Requirement]
        var primaryRequirementIDs: Set<String>
    }

    enum Target: Identifiable, Equatable, Sendable {
        case stored(ItemStack)
        case worn(slot: GearSlot, member: PartyMember, piece: EquippedPiece)

        var id: String {
            switch self {
            case .stored(let stack): "stored-\(stack.id.rawValue)"
            case .worn(let slot, let member, _): "worn-\(member.id)-\(slot.rawValue)"
            }
        }
        var catalogID: ItemID {
            switch self { case .stored(let value): value.catalogID; case .worn(_, _, let value): value.catalogID }
        }
        var gearProfile: GearInstanceProfile? {
            switch self { case .stored(let value): value.gearProfile; case .worn(_, _, let value): value.gearProfile }
        }
        var slot: GearSlot? { gearProfile?.slot }
        var displayName: String {
            switch self {
            case .stored(let value): value.displayName
            case .worn(_, _, let value): value.displayName
            }
        }
        var legacyPowerCredit: Int { gearProfile?.legacyPowerCredit ?? 0 }
        var legacyEffectivePowerCredit: Int { gearProfile?.legacyEffectivePowerCredit ?? 0 }
        var reforgeRank: Int { gearProfile?.reforgeRank ?? 0 }
        var hasLegacyCredit: Bool {
            legacyPowerCredit > 0 || legacyEffectivePowerCredit > 0
        }
        var hasReforgeWork: Bool { reforgeRank > 0 }
        var isLegacyMasterwork: Bool { hasLegacyCredit }
    }

    struct Preview: Equatable, Sendable {
        var target: Target
        var profile: Profile
        var selections: [Selection]
        var qualityBand: CraftMaterialQualityBand
        var outputTier: Int
        var rawEssence: Int
        var essence: Int
        var insulation: Double
        var reactivity: Double
        var currentPhysical: Double
        var rebuiltPhysical: Double
        var currentInsulation: Double

        var isBelowSpecialistHeadline: Bool { outputTier < 3 }
        var destroysLegacyWork: Bool { target.hasLegacyCredit }
    }

    static let protectiveSlots: Set<GearSlot> = [.offhand, .head, .armor, .hands, .feet]

    static let rigid = Profile(
        id: "armoury_rigid_shell", name: "Rigid shell", minimumEffectiveTier: 0,
        allowedSlots: protectiveSlots, physicalOffset: 0.5,
        requirements: [
            requirement("body.0", [.ore, .copper, .adamant, .bone, .scale, .plate,
                                    .chitin, .shell, .quill]),
            requirement("body.1", [.ore, .copper, .adamant, .bone, .scale, .plate,
                                    .chitin, .shell, .quill]),
            requirement("binding.0", [.fibre, .resin, .copper, .silver, .gold, .hide, .fin])
        ], primaryRequirementIDs: ["body.0", "body.1"])
    static let insulated = Profile(
        id: "armoury_insulated_layer", name: "Insulated layer", minimumEffectiveTier: 1,
        allowedSlots: [.head, .armor, .hands, .feet], physicalOffset: -0.5,
        requirements: [
            requirement("lining.0", [.fibre, .hide, .pelt, .down, .feather, .fin]),
            requirement("lining.1", [.fibre, .hide, .pelt, .down, .feather, .fin]),
            requirement("outer.0", [.ore, .copper, .adamant, .timber, .bone, .hide,
                                     .scale, .plate, .chitin, .shell])
        ], primaryRequirementIDs: ["lining.0", "lining.1"])
    static let balanced = Profile(
        id: "armoury_balanced_laminate", name: "Balanced laminate", minimumEffectiveTier: 1,
        allowedSlots: protectiveSlots, physicalOffset: 0,
        requirements: [
            requirement("body.0", [.ore, .copper, .adamant, .timber, .bone, .hide,
                                    .scale, .plate, .chitin, .shell]),
            requirement("lining.0", [.fibre, .hide, .pelt, .down, .feather, .fin]),
            requirement("binding.0", [.fibre, .resin, .copper, .silver, .gold, .hide, .fin]),
            requirement("fitting.0", [.copper, .silver, .gold, .quartz, .adamant,
                                       .bone, .horn, .quill])
        ], primaryRequirementIDs: ["body.0", "lining.0"])
    static let profiles = [rigid, insulated, balanced]

    private static func requirement(_ id: String, _ families: Set<MaterialFamilyID>)
        -> Requirement {
        Requirement(id: id, allowedKinds: families,
                    allowedIdentities: Set(families.map {
                        .init(domain: .forFamily($0), family: $0)
                    }), floors: [])
    }

    static func effectiveTier(in state: GameState) -> Int {
        guard let station = ContentCatalog.shared.station(Stations.armoury) else { return 0 }
        return StationStaffingRules.effectiveTier(for: station, in: state)
    }

    static func targets(in state: GameState, includeLegacy: Bool = false) -> [Target] {
        let stored = state.base.inventory.stacks.compactMap { stack -> Target? in
            let target = Target.stored(stack)
            return eligible(target, includeLegacy: includeLegacy) ? target : nil
        }
        var worn: [Target] = []
        for (slot, piece) in state.base.binderEquipped {
            let target = Target.worn(slot: slot, member: .binder, piece: piece)
            if eligible(target, includeLegacy: includeLegacy) { worn.append(target) }
        }
        for index in state.base.roster.indices {
            for (slot, piece) in state.base.roster[index].equipped {
                guard let id = state.base.persistentID(forRosterIndex: index) else { continue }
                let target = Target.worn(slot: slot, member: .member(id), piece: piece)
                if eligible(target, includeLegacy: includeLegacy) { worn.append(target) }
            }
        }
        return (stored + worn).sorted { $0.id < $1.id }
    }

    static func eligible(_ target: Target, includeLegacy: Bool) -> Bool {
        guard let profile = target.gearProfile, protectiveSlots.contains(profile.slot),
              profile.authoredUniqueRuleID == nil,
              target.catalogID != Items.conduitFixture,
              let definition = ContentCatalog.shared.item(target.catalogID),
              definition.gear?.breaks == nil,
              definition.gearCatalogueDisposition?.classification != .wildApexOnly,
              definition.gearCatalogueDisposition?.foundReceipt?.mode != .fixedSpecial
        else { return false }
        return includeLegacy || !target.isLegacyMasterwork
    }

    static func isAvailable(_ profile: Profile, for target: Target, in state: GameState) -> Bool {
        state.base.station(Stations.armoury).isUnlocked
            && effectiveTier(in: state) >= profile.minimumEffectiveTier
            && target.slot.map(profile.allowedSlots.contains) == true
    }

    static func defaultSelections(for profile: Profile, in state: GameState) -> [Selection]? {
        var used: Set<String> = []
        var result: [Selection] = []
        for requirement in profile.requirements {
            guard let candidate = candidates(for: requirement, in: state)
                .first(where: { !used.contains($0.stockKey) }) else { return nil }
            used.insert(candidate.stockKey)
            result.append(candidate)
        }
        return result
    }

    static func candidates(for requirement: Requirement, in state: GameState) -> [Selection] {
        state.base.craftMaterialSelections {
            PhysicalGearCraftingRules.qualifies($0, for: requirement)
        }.map { quote in
            Selection(requirementID: requirement.id, binID: .init(rawValue: 0), sampleIndex: 0,
                      sample: quote.sample, reserveSelection: quote)
        }.sorted { lhs, rhs in
            let scoringFloors = requirement.floors + requirement.alternativeFloors
            let left = scoringFloors.map { lhs.sample.properties[$0.property] }.reduce(0, +)
            let right = scoringFloors.map { rhs.sample.properties[$0.property] }.reduce(0, +)
            return (left, lhs.sample.qualityBand.rawValue, lhs.stockKey)
                < (right, rhs.sample.qualityBand.rawValue, rhs.stockKey)
        }
    }

    static func preview(_ profile: Profile, target: Target, selections: [Selection]? = nil,
                        includeLegacy: Bool = false, in state: GameState) -> Preview? {
        guard eligible(target, includeLegacy: includeLegacy),
              isAvailable(profile, for: target, in: state), currentTarget(matching: target, in: state) != nil
        else { return nil }
        let chosen = selections ?? defaultSelections(for: profile, in: state)
        guard let chosen, chosen.allSatisfy({ $0.reserveSelection != nil }),
              PhysicalGearCraftingRules.preview(selectionRecipe(profile), selections: chosen, in: state) != nil
        else { return nil }
        let primaryRanks = chosen.filter { profile.primaryRequirementIDs.contains($0.requirementID) }
            .map { $0.sample.qualityBand.rawValue }
        let secondaryRanks = chosen.filter { !profile.primaryRequirementIDs.contains($0.requirementID) }
            .map { $0.sample.qualityBand.rawValue }
        guard !primaryRanks.isEmpty else { return nil }
        let primary = Double(primaryRanks.reduce(0, +)) / Double(primaryRanks.count)
        let secondary = secondaryRanks.isEmpty
            ? primary
            : Double(secondaryRanks.reduce(0, +)) / Double(secondaryRanks.count)
        let qualityRank = Int((0.7 * primary + 0.3 * secondary).rounded())
        let qualityBand = CraftMaterialQualityBand(rawValue: qualityRank) ?? .rough
        let output = qualityRank
        let station = ContentCatalog.shared.station(Stations.armoury)!
        let raw = PhysicalGearCraftingRules.essenceCost(for: max(1, output))
        let paid = StationStaffingRules.discounted(raw, at: station, in: state)
        let insulation = chosen.map(\.sample.properties.insulation).reduce(0, +) / Double(chosen.count)
        let reactivity = chosen.map(\.sample.properties.reactivity).reduce(0, +) / Double(chosen.count)
        return Preview(target: target, profile: profile, selections: chosen, qualityBand: qualityBand,
                       outputTier: output, rawEssence: raw, essence: paid,
                       insulation: insulation, reactivity: reactivity,
                       currentPhysical: target.gearProfile?.protectivePower ?? 0,
                       rebuiltPhysical: max(0, Double(qualityRank) + profile.physicalOffset),
                       currentInsulation: target.gearProfile?.insulation ?? 0)
    }

    @discardableResult
    static func rebuild(_ preview: Preview, allowLegacyLoss: Bool = false,
                        in state: inout GameState) -> Bool {
        guard let current = currentTarget(matching: preview.target, in: state),
              current == preview.target,
              let fresh = self.preview(preview.profile, target: current,
                                       selections: preview.selections,
                                       includeLegacy: allowLegacyLoss, in: state),
              fresh == preview, (!preview.destroysLegacyWork || allowLegacyLoss),
              state.base.essenceCrystalCount >= preview.essence else { return false }

        guard state.base.physicalGearOwnershipRevision < UInt64.max else { return false }
        var candidate = state
        var rebuilt = current.gearProfile!
        rebuilt.constructionTier = preview.outputTier
        rebuilt.qualityBand = preview.qualityBand
        rebuilt.reforgeRank = 0
        rebuilt.legacyPowerCredit = 0
        rebuilt.legacyEffectivePowerCredit = 0
        rebuilt.specialistProfile = preview.profile.id
        rebuilt.insulation = preview.insulation
        rebuilt.reactivity = preview.reactivity
        let prior = rebuilt.physicalReceipt?.revisions ?? []
        let revision = PhysicalGearWorkRevisionV1(
            ordinal: prior.count,
            authority: .rebuild(stationID: Stations.armoury,
                                profileID: preview.profile.id, rulesVersion: 1),
            components: preview.selections.enumerated().map {
                .init(ordinal: $0.offset, role: .authoredSocket($0.element.requirementID),
                      unit: $0.element.sample)
            }, resultingQualityBand: rebuilt.qualityBand,
            resultingConstructionTier: rebuilt.constructionTier)
        rebuilt.physicalReceipt = .init(gearInstanceID: rebuilt.stableInstanceID,
                                        revisions: prior + [revision])
        rebuilt.freezeGameplayFacts(protectivePowerOffset: preview.profile.physicalOffset)

        guard PhysicalGearCraftingRules.consume(preview.selections, in: &candidate),
              candidate.base.spendEssenceCrystals(preview.essence),
              rebuilt.physicalReceipt?.validates(profile: rebuilt) == true else { return false }
        apply(rebuilt, to: current, in: &candidate)
        candidate.base.physicalGearOwnershipRevision += 1
        guard candidate.validatesPhysicalGearReceipts() else { return false }
        state = candidate
        return true
    }

    private static func selectionRecipe(_ profile: Profile) -> PhysicalGearCraftingRules.Recipe {
        PhysicalGearCraftingRules.Recipe(id: profile.id, displayName: profile.name,
            catalogFallback: "guard_padded", station: Stations.armoury, stationCap: 4,
            specialistHeadlineTier: 3, slot: .armor, damage: nil, reach: .close,
            requirements: profile.requirements,
            primaryRequirementIDs: profile.primaryRequirementIDs)
    }

    private static func currentTarget(matching target: Target, in state: GameState) -> Target? {
        switch target {
        case .stored(let stack):
            return state.base.inventory.stacks.first { $0.id == stack.id }.map(Target.stored)
        case .worn(let slot, let member, _):
            return state.base.worn(slot, by: member).map { .worn(slot: slot, member: member, piece: $0) }
        }
    }

    private static func apply(_ profile: GearInstanceProfile, to target: Target, in state: inout GameState) {
        switch target {
        case .stored(let old):
            guard let index = state.base.inventory.stacks.firstIndex(where: { $0.id == old.id }) else { return }
            state.base.inventory.stacks[index].gearProfile = profile
            state.base.inventory.stacks[index].upgradeLevel = 0
        case .worn(let slot, let member, _):
            switch member {
            case .binder:
                state.base.binderEquipped[slot]?.gearProfile = profile
                state.base.binderEquipped[slot]?.upgradeLevel = 0
            case .member(let id):
                guard let index = state.base.rosterIndex(for: id) else { return }
                state.base.roster[index].equipped[slot]?.gearProfile = profile
                state.base.roster[index].equipped[slot]?.upgradeLevel = 0
            }
        }
    }
}
