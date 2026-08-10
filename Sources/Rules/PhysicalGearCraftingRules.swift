import Foundation

/// Deterministic property-driven construction shared by all physical specialist stations.
///
/// The first live fixture is Halloway's Pointed Blade. The types deliberately already express the
/// full 21-family contract: requirements may constrain kinds and multiple properties, preview owns
/// exact sample choice, and the crafted instance freezes both its inputs and combat shape.
enum PhysicalGearCraftingRules {
    struct PropertyFloor: Equatable, Sendable {
        var property: MaterialProperty
        var minimum: Double
    }

    struct SampleRequirement: Identifiable, Equatable, Sendable {
        var id: String
        var allowedKinds: Set<MaterialKind>?
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
        var sample: MaterialSample

        var stockKey: String { "\(binID.rawValue):\(sampleIndex)" }
    }

    struct Preview: Equatable, Sendable {
        var recipe: Recipe
        var selections: [Selection]
        var craftGrade: Double
        var naturalTier: Int
        var outputTier: Int
        var constructionCap: Int
        var rawEssence: Int
        var essence: Int
        var homeDiscountRate: Double
        var insulation: Double
        var reactivity: Double

        var wastesGradeAboveCap: Bool { naturalTier > constructionCap }
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
        station: Stations.bowyer, stationCap: 4, specialistHeadlineTier: 3,
        slot: .weapon, damage: .pierce, reach: .far,
        requirements: [
            SampleRequirement(id: "flexible_limb_1", allowedKinds: [.timber, .quill, .fibre],
                              floors: [PropertyFloor(property: .flexibility, minimum: 60)]),
            SampleRequirement(id: "flexible_limb_2", allowedKinds: [.timber, .quill, .fibre],
                              floors: [PropertyFloor(property: .flexibility, minimum: 60)]),
            SampleRequirement(id: "hard_point", allowedKinds: [.fang, .quill, .bone, .tusk],
                              floors: [PropertyFloor(property: .hardness, minimum: 50)])
        ])

    static let sling = Recipe(
        id: "sling", displayName: "Sling", catalogFallback: "field_maul",
        station: Stations.bowyer, stationCap: 4, minimumEffectiveTier: 1, specialistHeadlineTier: 3,
        slot: .weapon, damage: .crush, reach: .far,
        requirements: [
            SampleRequirement(id: "flexible_cord", allowedKinds: nil,
                              floors: [PropertyFloor(property: .flexibility, minimum: 60)]),
            SampleRequirement(id: "dense_projectile", allowedKinds: nil,
                              floors: [PropertyFloor(property: .density, minimum: 60)])
        ])

    static let throwingSet = Recipe(
        id: "throwing_set", displayName: "Throwing Set", catalogFallback: "blade_chipped",
        station: Stations.bowyer, stationCap: 4, minimumEffectiveTier: 1, specialistHeadlineTier: 3,
        slot: .weapon, damage: .rend, reach: .far,
        requirements: [
            SampleRequirement(id: "hard_edge_1", allowedKinds: [.claw, .quill, .chitin],
                              floors: [PropertyFloor(property: .hardness, minimum: 55)]),
            SampleRequirement(id: "hard_edge_2", allowedKinds: [.claw, .quill, .chitin],
                              floors: [PropertyFloor(property: .hardness, minimum: 55)]),
            SampleRequirement(id: "flexible_carrier", allowedKinds: nil,
                              floors: [PropertyFloor(property: .flexibility, minimum: 45)])
        ])

    static let bowyerRecipes: [Recipe] = [longbow, sling, throwingSet]
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
    static let maudFittingPattern = "maud_fitting_pattern"

    static func requiredResearch(for recipe: Recipe) -> ResearchNodeID? {
        if recipe.station == Stations.tannery { return tanneryWearRoot }
        if recipe.station == Stations.weaponsmith { return weaponsmithPointRoot }
        return nil
    }

    static func isUnlocked(_ recipe: Recipe, in state: GameState) -> Bool {
        if let required = requiredResearch(for: recipe),
           !state.base.completedResearch.contains(required) { return false }
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
            return state.base.completedResearch.contains(tanneryWearTierTwo)
                ? recipe.stationCap : min(1, recipe.stationCap)
        }
        if recipe.station == Stations.bowyer {
            return min(effectiveTier(for: recipe, in: state) >= 2 ? 4 : 3, recipe.stationCap)
        }
        if recipe.station == Stations.weaponsmith {
            return min(effectiveTier(for: recipe, in: state) >= 2 ? 4 : 3, recipe.stationCap)
        }
        return recipe.stationCap
    }

    static func naturalTier(for grade: Double) -> Int {
        switch grade {
        case ..<40: 1
        case ..<65: 2
        case ..<85: 3
        default: 4
        }
    }

    static func essenceCost(for tier: Int) -> Int {
        [1: 12, 2: 24, 3: 48, 4: 80][tier] ?? 80
    }

    static func qualifies(_ sample: MaterialSample, for requirement: SampleRequirement) -> Bool {
        if let kinds = requirement.allowedKinds, !kinds.contains(sample.kind) { return false }
        guard requirement.floors.allSatisfy({ sample.properties[$0.property] >= $0.minimum })
        else { return false }
        return requirement.alternativeFloors.isEmpty
            || requirement.alternativeFloors.contains { sample.properties[$0.property] >= $0.minimum }
    }

    static func candidates(for requirement: SampleRequirement, in state: GameState) -> [Selection] {
        state.base.inventory.stacks.flatMap { bin in
            bin.materials.enumerated().compactMap { index, sample in
                guard qualifies(sample, for: requirement) else { return nil }
                return Selection(requirementID: requirement.id, binID: bin.id,
                                 sampleIndex: index, sample: sample)
            }
        }.sorted { lhs, rhs in
            let scoringFloors = requirement.floors + requirement.alternativeFloors
            let left = scoringFloors.map { lhs.sample.properties[$0.property] }.reduce(0, +)
            let right = scoringFloors.map { rhs.sample.properties[$0.property] }.reduce(0, +)
            return (left, lhs.sample.grade, lhs.binID.rawValue, lhs.sampleIndex)
                < (right, rhs.sample.grade, rhs.binID.rawValue, rhs.sampleIndex)
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
                  state.base.inventory.stacks.contains(where: { bin in
                      bin.id == selection.binID && bin.materials.indices.contains(selection.sampleIndex)
                          && bin.materials[selection.sampleIndex] == selection.sample
                  }) else { return nil }
        }
        let unique = Set(chosen.map(\.stockKey))
        guard unique.count == chosen.count else { return nil }
        let grades = chosen.map(\.sample.grade)
        let grade = 0.6 * (grades.min() ?? 0)
            + 0.4 * (grades.reduce(0, +) / Double(grades.count))
        let natural = naturalTier(for: grade)
        let output = min(natural, constructionCap(for: recipe, in: state))
        let averageInsulation = chosen.map(\.sample.properties.insulation).reduce(0, +) / Double(chosen.count)
        let averageReactivity = chosen.map(\.sample.properties.reactivity).reduce(0, +) / Double(chosen.count)
        let rawEssence = essenceCost(for: output)
        let station = ContentCatalog.shared.station(recipe.station)
        let paidEssence = station.map { StationStaffingRules.discounted(rawEssence, at: $0, in: state) }
            ?? rawEssence
        let discount = station.map { StationStaffingRules.homeDiscountRate(for: $0, in: state) } ?? 0
        return Preview(recipe: recipe, selections: chosen, craftGrade: grade,
                       naturalTier: natural, outputTier: output, constructionCap: constructionCap(for: recipe, in: state), rawEssence: rawEssence,
                       essence: paidEssence, homeDiscountRate: discount,
                       insulation: averageInsulation, reactivity: averageReactivity)
    }

    static func readiness(_ recipe: Recipe, in state: GameState) -> Readiness {
        guard state.base.station(recipe.station).isUnlocked else { return .stationLocked }
        if let required = requiredResearch(for: recipe),
           !state.base.completedResearch.contains(required) {
            return .researchLocked(required)
        }
        let tier = effectiveTier(for: recipe, in: state)
        guard tier >= recipe.minimumEffectiveTier else {
            return .tierLocked(need: recipe.minimumEffectiveTier)
        }
        guard let preview = preview(recipe, in: state) else {
            let missing = recipe.requirements.filter { requirement in
                !state.base.inventory.stacks.contains { bin in
                    bin.materials.contains { qualifies($0, for: requirement) }
                }
            }.map(\.id)
            return .needsSamples(requirementIDs: missing)
        }
        guard state.base.essence >= preview.essence else {
            return .needsEssence(have: state.base.essence, need: preview.essence)
        }
        return .ready(preview)
    }

    @discardableResult
    static func craft(_ preview: Preview, in state: inout GameState) -> ItemStack? {
        guard state.base.station(preview.recipe.station).isUnlocked,
              isUnlocked(preview.recipe, in: state),
              let fresh = self.preview(preview.recipe, selections: preview.selections, in: state),
              fresh == preview, state.base.essence >= preview.essence else { return nil }

        for (binID, selections) in Dictionary(grouping: preview.selections, by: \.binID) {
            guard let bin = state.base.inventory.stacks.firstIndex(where: { $0.id == binID })
            else { return nil }
            for selection in selections.sorted(by: { $0.sampleIndex > $1.sampleIndex }) {
                state.base.inventory.stacks[bin].materials.remove(at: selection.sampleIndex)
            }
            state.base.inventory.stacks[bin].count = state.base.inventory.stacks[bin].materials.count
        }
        state.base.inventory.stacks.removeAll { $0.count == 0 }
        state.base.essence -= preview.essence

        let id = InstanceID(rawValue: state.base.nextItemID())
        var output = ItemStack(id: id, catalogID: preview.recipe.catalogFallback)
        output.gearProfile?.familyID = preview.recipe.id
        output.gearProfile?.constructionTier = preview.outputTier
        output.gearProfile?.slot = preview.recipe.slot
        output.gearProfile?.damage = preview.recipe.damage
        output.gearProfile?.reach = preview.recipe.reach
        output.gearProfile?.insulation = preview.insulation
        output.gearProfile?.reactivity = preview.reactivity
        output.gearProfile?.consumedSamples = preview.selections.map(\.sample)
        output.gearProfile?.recipeVersion = 1
        output.gearProfile?.specialistProfile = preview.recipe.station.rawValue
        let origin = preview.selections.map(\.sample.source).filter { !$0.isEmpty }
        output.gearProfile?.displayProvenance = origin.isEmpty
            ? preview.recipe.displayName
            : "\(preview.recipe.displayName) · \(origin.joined(separator: " + "))"
        state.base.store(output)
        return output
    }
}
