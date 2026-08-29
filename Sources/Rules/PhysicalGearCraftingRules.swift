import Foundation

/// Deterministic property-driven construction shared by all physical specialist stations.
///
/// The first live fixture is Halloway's Pointed Blade. The types deliberately already express the
/// full 21-family contract: requirements may constrain kinds and multiple properties, preview owns
/// exact sample choice, and the crafted instance freezes both its inputs and combat shape.
enum PhysicalGearCraftingRules {
    struct MaterialIdentity: Hashable, Sendable {
        var domain: CraftMaterialDomain
        var family: MaterialFamilyID
    }

    struct PropertyFloor: Equatable, Sendable {
        var property: MaterialProperty
        var minimum: Double
    }

    struct SampleRequirement: Identifiable, Equatable, Sendable {
        var id: String
        var allowedKinds: Set<MaterialFamilyID>?
        var allowedIdentities: Set<MaterialIdentity>? = nil
        var floors: [PropertyFloor]
        var alternativeFloors: [PropertyFloor] = []
    }

    struct Recipe: Identifiable, Equatable, Sendable {
        var id: String
        var displayName: String
        var catalogFallback: ItemID
        var station: StationID
        var stationCap: Int
        var minimumEffectiveTier: Int = 0
        var specialistHeadlineTier: Int? = nil
        var slot: GearSlot
        var damage: DamageKind?
        var reach: Reach
        var requirements: [SampleRequirement]
        /// Empty preserves the legacy first-primary rule. Canonical schematics name every primary.
        var primaryRequirementIDs: Set<String> = []

        var intendedLean: String? {
            guard slot == .weapon, let damage else { return nil }
            return damage == .crush ? "Might" : "Finesse"
        }
    }

    struct Selection: Identifiable, Equatable, Sendable {
        var id: String { "\(requirementID):\(stockKey)" }
        var requirementID: String
        var binID: InstanceID
        var sampleIndex: Int
        var sample: CraftMaterialUnitV1
        var reserveSelection: CraftMaterialSelection? = nil

        var stockKey: String {
            reserveSelection?.unitID.rawValue ?? "legacy:\(binID.rawValue):\(sampleIndex)"
        }
    }

    struct CandidateAssessment: Identifiable, Equatable, Sendable {
        var id: String { selection.id }
        var selection: Selection
        var rejectionReason: String?
        var isEligible: Bool { rejectionReason == nil }
    }

    struct Preview: Equatable, Sendable {
        var recipe: Recipe
        var selections: [Selection]
        var qualityBand: CraftMaterialQualityBand
        var outputTier: Int
        var rawEssence: Int
        var essence: Int
        var homeDiscountRate: Double
        var insulation: Double
        var reactivity: Double
        var expectedInstanceID: InstanceID
        var destination: PhysicalGearConstructionDestinationV1

        var isBelowSpecialistHeadline: Bool {
            recipe.specialistHeadlineTier.map { outputTier < $0 } ?? false
        }
    }

    enum Readiness: Equatable, Sendable {
        case ready(Preview)
        case stationLocked
        case researchLocked(ResearchNodeID)
        case tierLocked(need: Int)
        case needsSamples(requirementIDs: [String])
        case needsEssence(have: Int, need: Int)
    }

    static let pointedBlade = Recipe(
        id: "pointed_blade", displayName: "Pointed Blade", catalogFallback: "blade_chipped",
        station: Stations.blacksmith, stationCap: 2, slot: .weapon, damage: .pierce,
        reach: .close,
        requirements: [
            SampleRequirement(id: "hard_point", allowedKinds: [.fang, .quill, .bone],
                              floors: [PropertyFloor(property: .hardness, minimum: 35)]),
            SampleRequirement(id: "flexible_grip", allowedKinds: nil,
                              floors: [PropertyFloor(property: .flexibility, minimum: 30)])
        ])

    static let cuttingBlade = Recipe(
        id: "cutting_blade", displayName: "Cutting Blade", catalogFallback: "blade_chipped",
        station: Stations.blacksmith, stationCap: 2, slot: .weapon, damage: .rend, reach: .close,
        requirements: [
            SampleRequirement(id: "hard_edge", allowedKinds: [.claw, .chitin, .quill],
                              floors: [PropertyFloor(property: .hardness, minimum: 35)]),
            SampleRequirement(id: "flexible_grip", allowedKinds: nil,
                              floors: [PropertyFloor(property: .flexibility, minimum: 30)])
        ])

    static let handMaul = Recipe(
        id: "hand_maul", displayName: "Hand Maul", catalogFallback: "field_maul",
        station: Stations.blacksmith, stationCap: 2, slot: .weapon, damage: .crush, reach: .close,
        requirements: [
            SampleRequirement(id: "dense_head", allowedKinds: [.tusk, .bone, .plate],
                              floors: [PropertyFloor(property: .density, minimum: 40)]),
            SampleRequirement(id: "haft", allowedKinds: [.timber, .bone], floors: [])
        ])

    static let longSpear = Recipe(
        id: "long_spear", displayName: "Long Spear", catalogFallback: "long_pick",
        station: Stations.blacksmith, stationCap: 2, slot: .weapon, damage: .pierce, reach: .mid,
        requirements: [
            SampleRequirement(id: "hard_point", allowedKinds: [.fang, .quill, .bone, .tusk],
                              floors: [PropertyFloor(property: .hardness, minimum: 40)]),
            SampleRequirement(id: "dense_haft", allowedKinds: [.timber, .bone],
                              floors: [PropertyFloor(property: .density, minimum: 30)]),
            SampleRequirement(id: "flexible_binding", allowedKinds: nil,
                              floors: [PropertyFloor(property: .flexibility, minimum: 35)])
        ])

    static let shield = Recipe(
        id: "shield", displayName: "Shield", catalogFallback: "split_board",
        station: Stations.blacksmith, stationCap: 2, slot: .offhand, damage: nil, reach: .close,
        requirements: [
            SampleRequirement(id: "hard_face", allowedKinds: nil,
                              floors: [PropertyFloor(property: .hardness, minimum: 40)]),
            SampleRequirement(id: "dense_brace", allowedKinds: nil,
                              floors: [PropertyFloor(property: .density, minimum: 30)]),
            SampleRequirement(id: "flexible_binding", allowedKinds: nil,
                              floors: [PropertyFloor(property: .flexibility, minimum: 30)])
        ])

    static let helm = Recipe(
        id: "helm", displayName: "Helm", catalogFallback: "padded_cap",
        station: Stations.blacksmith, stationCap: 2, slot: .head, damage: nil, reach: .close,
        requirements: [
            SampleRequirement(id: "hard_shell", allowedKinds: [.plate, .chitin, .bone, .quill],
                              floors: [PropertyFloor(property: .hardness, minimum: 35)]),
            SampleRequirement(id: "lining", allowedKinds: nil,
                              floors: [],
                              alternativeFloors: [PropertyFloor(property: .flexibility, minimum: 25),
                                                  PropertyFloor(property: .insulation, minimum: 25)])
        ])

    static let rigidGuard = Recipe(
        id: "rigid_guard", displayName: "Rigid Guard", catalogFallback: "guard_padded",
        station: Stations.blacksmith, stationCap: 2, slot: .armor, damage: nil, reach: .close,
        requirements: [
            SampleRequirement(id: "hard_body_1", allowedKinds: nil,
                              floors: [PropertyFloor(property: .hardness, minimum: 40)]),
            SampleRequirement(id: "hard_body_2", allowedKinds: nil,
                              floors: [PropertyFloor(property: .hardness, minimum: 40)]),
            SampleRequirement(id: "flexible_binding", allowedKinds: nil,
                              floors: [PropertyFloor(property: .flexibility, minimum: 35)])
        ])

    static let fieldPick = Recipe(
        id: "field_pick", displayName: "Field Pick", catalogFallback: "bent_pick",
        station: Stations.blacksmith, stationCap: 2, slot: .tool, damage: nil, reach: .close,
        requirements: [
            SampleRequirement(id: "hard_pick", allowedKinds: nil,
                              floors: [PropertyFloor(property: .hardness, minimum: 45)]),
            SampleRequirement(id: "dense_weight", allowedKinds: nil,
                              floors: [PropertyFloor(property: .density, minimum: 35)]),
            SampleRequirement(id: "haft", allowedKinds: [.timber, .bone], floors: [])
        ])

    static let recipes: [Recipe] = [
        pointedBlade, cuttingBlade, handMaul, longSpear, shield, helm, rigidGuard, fieldPick
    ]

    static let suppleCoat = Recipe(
        id: "supple_coat", displayName: "Supple Coat", catalogFallback: "guard_padded",
        station: Stations.tannery, stationCap: 2, slot: .armor, damage: nil, reach: .close,
        requirements: [
            SampleRequirement(id: "flexible_layer_1", allowedKinds: [.hide, .pelt, .down, .fibre],
                              floors: [PropertyFloor(property: .flexibility, minimum: 40),
                                       PropertyFloor(property: .insulation, minimum: 25)]),
            SampleRequirement(id: "flexible_layer_2", allowedKinds: [.hide, .pelt, .down, .fibre],
                              floors: [PropertyFloor(property: .flexibility, minimum: 40),
                                       PropertyFloor(property: .insulation, minimum: 25)])
        ])

    static let workingGloves = Recipe(
        id: "working_gloves", displayName: "Working Gloves", catalogFallback: "wrapped_hands",
        station: Stations.tannery, stationCap: 2, slot: .hands, damage: nil, reach: .close,
        requirements: [
            SampleRequirement(id: "flexible_hand", allowedKinds: nil,
                              floors: [PropertyFloor(property: .flexibility, minimum: 40)]),
            SampleRequirement(id: "hard_facing", allowedKinds: nil,
                              floors: [PropertyFloor(property: .hardness, minimum: 25)])
        ])

    static let workingBoots = Recipe(
        id: "working_boots", displayName: "Working Boots", catalogFallback: "worn_boots",
        station: Stations.tannery, stationCap: 2, slot: .feet, damage: nil, reach: .close,
        requirements: [
            SampleRequirement(id: "flexible_upper", allowedKinds: nil,
                              floors: [PropertyFloor(property: .flexibility, minimum: 35)]),
            SampleRequirement(id: "dense_or_hard_sole", allowedKinds: nil, floors: [],
                              alternativeFloors: [PropertyFloor(property: .density, minimum: 30),
                                                  PropertyFloor(property: .hardness, minimum: 30)])
        ])

    static let tanneryRecipes: [Recipe] = [suppleCoat, workingGloves, workingBoots]

    static let longbow = Recipe(
        id: "longbow", displayName: "Longbow", catalogFallback: "long_pick",
        station: Stations.bowyer, stationCap: 5, specialistHeadlineTier: 3,
        slot: .weapon, damage: .pierce, reach: .far,
        requirements: [
            bowyerRequirement("limb.0", [.timber, .horn, .quill, .bone]),
            bowyerRequirement("limb.1", [.timber, .horn, .quill, .bone]),
            bowyerRequirement("string.0", [.fibre, .hide, .fin])
        ], primaryRequirementIDs: ["limb.0", "limb.1"])

    static let sling = Recipe(
        id: "sling", displayName: "Sling", catalogFallback: "field_maul",
        station: Stations.bowyer, stationCap: 5, minimumEffectiveTier: 1, specialistHeadlineTier: 3,
        slot: .weapon, damage: .crush, reach: .far,
        requirements: [
            bowyerRequirement("cord.0", [.fibre, .hide, .fin]),
            bowyerRequirement("projectile.0", [.rubble, .clay, .ore, .copper,
                              .adamant, .bone, .tusk, .horn, .shell]),
            bowyerRequirement("pouch.0", [.fibre, .hide, .pelt])
        ], primaryRequirementIDs: ["cord.0", "projectile.0"])

    static let throwingSet = Recipe(
        id: "throwing_set", displayName: "Throwing Set", catalogFallback: "blade_chipped",
        station: Stations.bowyer, stationCap: 5, minimumEffectiveTier: 1, specialistHeadlineTier: 3,
        slot: .weapon, damage: .rend, reach: .far,
        requirements: [
            bowyerRequirement("edge.0", [.ore, .adamant, .obsidian, .claw,
                              .chitin, .quill, .bone, .shell]),
            bowyerRequirement("edge.1", [.ore, .adamant, .obsidian, .claw,
                              .chitin, .quill, .bone, .shell]),
            bowyerRequirement("carrier.0", [.fibre, .hide, .pelt, .fin])
        ], primaryRequirementIDs: ["edge.0", "edge.1"])

    static let bowyerRecipes: [Recipe] = [longbow, sling, throwingSet]

    private static func bowyerRequirement(_ id: String, _ families: Set<MaterialFamilyID>)
        -> SampleRequirement {
        SampleRequirement(id: id, allowedKinds: families,
                          allowedIdentities: Set(families.map {
                              MaterialIdentity(domain: .forFamily($0), family: $0)
                          }), floors: [])
    }
    static let fittedPoint = Recipe(
        id: "weaponsmith_fitted_point", displayName: "Fitted Point", catalogFallback: "blade_chipped",
        station: Stations.weaponsmith, stationCap: 4, specialistHeadlineTier: 3,
        slot: .weapon, damage: .pierce, reach: .close,
        requirements: [
            SampleRequirement(id: "hard_point", allowedKinds: nil,
                              floors: [PropertyFloor(property: .hardness, minimum: 65)]),
            SampleRequirement(id: "flexible_grip", allowedKinds: nil,
                              floors: [PropertyFloor(property: .flexibility, minimum: 55)]),
            SampleRequirement(id: "lustrous_or_dense", allowedKinds: nil, floors: [],
                              alternativeFloors: [PropertyFloor(property: .lustre, minimum: 40),
                                                  PropertyFloor(property: .density, minimum: 40)])
        ])
    static let fittedEdge = Recipe(
        id: "weaponsmith_fitted_edge", displayName: "Fitted Edge", catalogFallback: "blade_chipped",
        station: Stations.weaponsmith, stationCap: 4, minimumEffectiveTier: 1,
        specialistHeadlineTier: 3, slot: .weapon, damage: .rend, reach: .close,
        requirements: [
            SampleRequirement(id: "hard_edge", allowedKinds: nil,
                              floors: [PropertyFloor(property: .hardness, minimum: 65)]),
            SampleRequirement(id: "flexible_grip", allowedKinds: nil,
                              floors: [PropertyFloor(property: .flexibility, minimum: 55)]),
            SampleRequirement(id: "reactive_or_lustrous", allowedKinds: nil, floors: [],
                              alternativeFloors: [PropertyFloor(property: .reactivity, minimum: 40),
                                                  PropertyFloor(property: .lustre, minimum: 40)])
        ])
    static let fittedMaul = Recipe(
        id: "weaponsmith_fitted_maul", displayName: "Fitted Maul", catalogFallback: "field_maul",
        station: Stations.weaponsmith, stationCap: 4, minimumEffectiveTier: 1,
        specialistHeadlineTier: 3, slot: .weapon, damage: .crush, reach: .close,
        requirements: [
            SampleRequirement(id: "dense_head", allowedKinds: nil,
                              floors: [PropertyFloor(property: .density, minimum: 70)]),
            SampleRequirement(id: "hard_face", allowedKinds: nil,
                              floors: [PropertyFloor(property: .hardness, minimum: 55)]),
            SampleRequirement(id: "flexible_grip", allowedKinds: nil,
                              floors: [PropertyFloor(property: .flexibility, minimum: 45)])
        ])

    static func fittedPolearm(damage: DamageKind) -> Recipe {
        let head = damage == .crush
            ? PropertyFloor(property: .density, minimum: 65)
            : PropertyFloor(property: .hardness, minimum: 65)
        return Recipe(id: "weaponsmith_fitted_polearm", displayName: "Fitted Polearm",
            catalogFallback: damage == .crush ? "field_maul" : "long_pick",
            station: Stations.weaponsmith, stationCap: 4, specialistHeadlineTier: 3,
            slot: .weapon, damage: damage, reach: .mid,
            requirements: [
                SampleRequirement(id: "chosen_head", allowedKinds: nil, floors: [head]),
                SampleRequirement(id: "flexible_haft", allowedKinds: [.timber, .bone],
                                  floors: [PropertyFloor(property: .flexibility, minimum: 55)]),
                SampleRequirement(id: "flexible_binding", allowedKinds: nil,
                                  floors: [PropertyFloor(property: .flexibility, minimum: 55)])
            ])
    }

    static let weaponsmithRecipes: [Recipe] = [fittedPoint, fittedEdge, fittedMaul]
    static let allRecipes: [Recipe] = recipes + tanneryRecipes + bowyerRecipes + weaponsmithRecipes
    static let tanneryWearRoot: ResearchNodeID = "tannery_wear_root"
    static let tanneryWearTierTwo: ResearchNodeID = "tannery_wear_tier_two"
    static let weaponsmithPointRoot: ResearchNodeID = "weaponsmith_point_root"
    static let tanneryWearCapability: CapabilityID = "tannery_wear"
    static let tanneryTierTwoCapability: CapabilityID = "tannery_tier_two"
    static let weaponsmithPointCapability: CapabilityID = "weaponsmith_fitted_point"
    static let maudFittingPattern: WorkshopPatternID = "maud_fitting_pattern"

    static func requiredResearch(for recipe: Recipe) -> ResearchNodeID? {
        if recipe.station == Stations.tannery { return tanneryWearRoot }
        if recipe.station == Stations.weaponsmith { return weaponsmithPointRoot }
        return nil
    }

    static func requiredCapability(for recipe: Recipe) -> CapabilityID? {
        if recipe.station == Stations.tannery { return tanneryWearCapability }
        if recipe.station == Stations.weaponsmith { return weaponsmithPointCapability }
        return nil
    }

    static func isUnlocked(_ recipe: Recipe, in state: GameState) -> Bool {
        if let required = requiredCapability(for: recipe),
           !state.base.hasCapability(required) { return false }
        if recipe.id == "weaponsmith_fitted_polearm",
           !state.reality.library.knownPatterns.contains(maudFittingPattern) { return false }
        return effectiveTier(for: recipe, in: state) >= recipe.minimumEffectiveTier
    }

    static func effectiveTier(for recipe: Recipe, in state: GameState) -> Int {
        guard let station = ContentCatalog.shared.station(recipe.station) else {
            return state.base.station(recipe.station).tier
        }
        return StationStaffingRules.effectiveTier(for: station, in: state)
    }

    static func constructionCap(for recipe: Recipe, in state: GameState) -> Int {
        if recipe.station == Stations.tannery {
            return state.base.hasCapability(tanneryTierTwoCapability)
                ? recipe.stationCap : min(1, recipe.stationCap)
        }
        if recipe.station == Stations.bowyer {
            return recipe.stationCap
        }
        if recipe.station == Stations.weaponsmith {
            return min(effectiveTier(for: recipe, in: state) >= 2 ? 4 : 3, recipe.stationCap)
        }
        return recipe.stationCap
    }

    static func essenceCost(for tier: Int) -> Int {
        [1: 12, 2: 24, 3: 48, 4: 80][tier] ?? 80
    }

    static func qualifies(_ sample: CraftMaterialUnitV1, for requirement: SampleRequirement) -> Bool {
        rejectionReason(for: sample, requirement: requirement) == nil
    }

    static func rejectionReason(for sample: CraftMaterialUnitV1,
                                requirement: SampleRequirement) -> String? {
        if let identities = requirement.allowedIdentities,
           !identities.contains(.init(domain: sample.domain, family: sample.familyID)) {
            return "That material does not belong in this part."
        }
        if let kinds = requirement.allowedKinds, !kinds.contains(sample.kind) {
            let allowed = kinds.map(\.displayName).sorted().joined(separator: ", ")
            return "Needs \(allowed)."
        }
        let missing = requirement.floors.filter {
            sample.properties[$0.property] < $0.minimum
        }
        if let floor = missing.first {
            return "\(floor.property.displayName) \(Int(sample.properties[floor.property])) of \(Int(floor.minimum)) required."
        }
        if !requirement.alternativeFloors.isEmpty,
           !requirement.alternativeFloors.contains(where: {
               sample.properties[$0.property] >= $0.minimum
           }) {
            return requirement.alternativeFloors.map {
                "\($0.property.displayName) \(Int($0.minimum))+"
            }.joined(separator: " or ") + " required."
        }
        return nil
    }

    static func assessments(for requirement: SampleRequirement,
                            in state: GameState) -> [CandidateAssessment] {
        let reserve = state.base.craftMaterialSelections().map { quote in
            CandidateAssessment(selection: Selection(requirementID: requirement.id,
                binID: .init(rawValue: 0), sampleIndex: 0, sample: quote.sample,
                reserveSelection: quote),
                rejectionReason: rejectionReason(for: quote.sample, requirement: requirement))
        }
        return reserve
    }

    static func candidates(for requirement: SampleRequirement, in state: GameState) -> [Selection] {
        let reserve = state.base.craftMaterialSelections { qualifies($0, for: requirement) }
            .map { quote in Selection(requirementID: requirement.id,
                binID: .init(rawValue: 0), sampleIndex: 0, sample: quote.sample,
                reserveSelection: quote) }
        return reserve.sorted { lhs, rhs in
            let scoringFloors = requirement.floors + requirement.alternativeFloors
            let left = scoringFloors.map { lhs.sample.properties[$0.property] }.reduce(0, +)
            let right = scoringFloors.map { rhs.sample.properties[$0.property] }.reduce(0, +)
            return (left, lhs.sample.qualityBand.rawValue, lhs.sample.domain.rawValue, lhs.stockKey)
                < (right, rhs.sample.qualityBand.rawValue, rhs.sample.domain.rawValue, rhs.stockKey)
        }
    }

    /// Weakest-qualifying-first default, with a sample used at most once even when it could fill
    /// both jobs. Requirement order is authored and therefore deterministic.
    static func defaultSelections(for recipe: Recipe, in state: GameState) -> [Selection]? {
        var used: Set<String> = []
        var result: [Selection] = []
        for requirement in recipe.requirements {
            let candidate = candidates(for: requirement, in: state)
                .first { !used.contains($0.stockKey) }
            guard let candidate else { return nil }
            used.insert(candidate.stockKey)
            result.append(candidate)
        }
        return result
    }

    static func preview(_ recipe: Recipe, selections: [Selection]? = nil,
                        in state: GameState) -> Preview? {
        guard isUnlocked(recipe, in: state) else { return nil }
        let chosen = selections ?? defaultSelections(for: recipe, in: state)
        guard let chosen, chosen.count == recipe.requirements.count else { return nil }
        for requirement in recipe.requirements {
            guard let selection = chosen.first(where: { $0.requirementID == requirement.id }),
                  qualifies(selection.sample, for: requirement),
                  selectionIsCurrent(selection, in: state) else { return nil }
        }
        let unique = Set(chosen.map(\.stockKey))
        guard unique.count == chosen.count else { return nil }
        let primaryIDs = recipe.primaryRequirementIDs.isEmpty
            ? Set(recipe.requirements.prefix(1).map(\.id)) : recipe.primaryRequirementIDs
        let primaryRanks = chosen.filter { primaryIDs.contains($0.requirementID) }
            .map { $0.sample.qualityBand.rawValue }
        let secondaryRanks = chosen.filter { !primaryIDs.contains($0.requirementID) }
            .map { $0.sample.qualityBand.rawValue }
        guard !primaryRanks.isEmpty else { return nil }
        let primary = Double(primaryRanks.reduce(0, +)) / Double(primaryRanks.count)
        let secondary = secondaryRanks.isEmpty
            ? primary : Double(secondaryRanks.reduce(0, +)) / Double(secondaryRanks.count)
        let qualityRank = Int((0.7 * primary + 0.3 * secondary).rounded())
        let qualityBand = CraftMaterialQualityBand(rawValue: qualityRank) ?? .rough
        let output = recipe.station == Stations.bowyer
            ? qualityRank : min(max(1, qualityRank), constructionCap(for: recipe, in: state))
        let averageInsulation = chosen.map(\.sample.properties.insulation).reduce(0, +) / Double(chosen.count)
        let averageReactivity = chosen.map(\.sample.properties.reactivity).reduce(0, +) / Double(chosen.count)
        let rawEssence = essenceCost(for: recipe.station == Stations.bowyer
            ? max(1, qualityRank) : output)
        let station = ContentCatalog.shared.station(recipe.station)
        let paidEssence = station.map { StationStaffingRules.discounted(rawEssence, at: $0, in: state) }
            ?? rawEssence
        let discount = station.map { StationStaffingRules.homeDiscountRate(for: $0, in: state) } ?? 0
        guard case .success(let expectedID) = PhysicalGearIdentityAuthority.nextID(in: state)
        else { return nil }
        let destination: PhysicalGearConstructionDestinationV1 = state.base.inventory.isFull
            ? .waiting : .storehouse
        return Preview(recipe: recipe, selections: chosen, qualityBand: qualityBand,
                       outputTier: output, rawEssence: rawEssence,
                       essence: paidEssence, homeDiscountRate: discount,
                       insulation: averageInsulation, reactivity: averageReactivity,
                       expectedInstanceID: expectedID, destination: destination)
    }

    static func readiness(_ recipe: Recipe, in state: GameState) -> Readiness {
        guard state.base.station(recipe.station).isUnlocked else { return .stationLocked }
        if let requiredCapability = requiredCapability(for: recipe),
           !state.base.hasCapability(requiredCapability),
           let requiredNode = requiredResearch(for: recipe) {
            return .researchLocked(requiredNode)
        }
        let tier = effectiveTier(for: recipe, in: state)
        guard tier >= recipe.minimumEffectiveTier else {
            return .tierLocked(need: recipe.minimumEffectiveTier)
        }
        guard let preview = preview(recipe, in: state) else {
            let missing = recipe.requirements.filter { requirement in
                candidates(for: requirement, in: state).isEmpty
            }.map(\.id)
            return .needsSamples(requirementIDs: missing)
        }
        guard state.base.essenceCrystalCount >= preview.essence else {
            return .needsEssence(have: state.base.essenceCrystalCount, need: preview.essence)
        }
        return .ready(preview)
    }

    @discardableResult
    static func craft(_ preview: Preview, in state: inout GameState) -> ItemStack? {
        guard state.base.station(preview.recipe.station).isUnlocked,
              isUnlocked(preview.recipe, in: state),
              let fresh = self.preview(preview.recipe, selections: preview.selections, in: state),
              fresh == preview, state.base.essenceCrystalCount >= preview.essence else { return nil }

        guard state.base.physicalGearOwnershipRevision < UInt64.max else { return nil }
        var candidate = state
        guard consume(preview.selections, in: &candidate),
              candidate.base.spendEssenceCrystals(preview.essence),
              case .success(let id) = PhysicalGearIdentityAuthority.nextID(in: state),
              id == preview.expectedInstanceID else { return nil }
        var output = ItemStack(id: id, catalogID: preview.recipe.catalogFallback)
        output.gearProfile?.familyID = preview.recipe.id
        output.gearProfile?.constructionTier = preview.outputTier
        output.gearProfile?.qualityBand = preview.qualityBand
        output.gearProfile?.slot = preview.recipe.slot
        output.gearProfile?.damage = preview.recipe.damage
        output.gearProfile?.reach = preview.recipe.reach
        output.gearProfile?.insulation = preview.insulation
        output.gearProfile?.reactivity = preview.reactivity
        output.gearProfile?.specialistProfile = preview.recipe.station.rawValue
        output.gearProfile?.foundReceipt = nil
        output.gearProfile?.inscription = nil
        output.gearProfile?.physicalReceipt = .init(
            gearInstanceID: id,
            revisions: [.init(
                ordinal: 0,
                authority: .construction(stationID: preview.recipe.station,
                                         schematicID: preview.recipe.id, rulesVersion: 1),
                components: preview.selections.enumerated().map {
                    .init(ordinal: $0.offset,
                          role: .authoredSocket($0.element.requirementID),
                          unit: $0.element.sample)
                }, resultingQualityBand: preview.qualityBand,
                resultingConstructionTier: preview.outputTier)])
        let toolCapability: GearToolCapabilityV1? = preview.recipe.id == fieldPick.id
            ? .init(capabilityID: "extraction", rank: min(4, max(0, preview.outputTier)),
                    authorityID: GearToolCapabilityV1.extractionAuthorityID,
                    authorityVersion: 1)
            : nil
        output.gearProfile?.freezeGameplayFacts(toolCapability: toolCapability)
        let origin = preview.selections.map(\.sample.source).filter { !$0.isEmpty }
        output.gearProfile?.displayProvenance = origin.isEmpty
            ? preview.recipe.displayName
            : "\(preview.recipe.displayName) · \(origin.joined(separator: " + "))"
        guard output.gearProfile?.physicalReceipt?.validates(profile: output.gearProfile!) == true
        else { return nil }
        candidate.base.store(output)
        candidate.base.physicalGearOwnershipRevision += 1
        guard candidate.validatesPhysicalGearReceipts() else { return nil }
        state = candidate
        return output
    }

    static func consume(_ selections: [Selection], in state: inout GameState) -> Bool {
        guard selections.allSatisfy({ selectionIsCurrent($0, in: state) }) else { return false }
        let reserve = selections.compactMap(\.reserveSelection)
        guard reserve.count == selections.count else { return false }
        if !reserve.isEmpty, state.base.consumeCraftMaterials(reserve) == nil { return false }
        return true
    }

    private static func selectionIsCurrent(_ selection: Selection, in state: GameState) -> Bool {
        if let reserve = selection.reserveSelection {
            return state.base.craftMaterialHoldings.contains {
                $0.id == reserve.unitID && $0.sample == reserve.sample
            }
        }
        return false
    }
}
