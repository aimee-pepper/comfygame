import Foundation

/// Reforging: making the piece you already carry better, instead of waiting for a better one to drop.
///
/// `materials-crafting-spec.md` §7 asks for **upgrading over replacing** — "a piece you like can
/// grow" — which is the answer to the loot treadmill, and the reason hoarding pays. §5 sets how the
/// asking works: **a recipe names properties, not item names.** So the smith never wants "3 ore".
/// It wants *three pieces of stock hard enough*, and a plate off a monstrous bulwark qualifies
/// exactly as well as ore does, which is what makes a hoard kept for its own sake turn out to be
/// worth something later.
///
/// Nothing here rolls dice: what a reforge costs and what it gives are both stated before you agree
/// to it, so a force-quit halfway through the decision loses nothing.
enum SmithRules {

    // MARK: What the smith asks for

    /// **The property the smith judges this slot by.**
    ///
    /// Every slot leans on a different one, so the material you'd throw away for a blade is the one
    /// you need for boots. That's what stops a hoard collapsing into "keep the hard things, discard
    /// the rest", and it gives all six properties a job.
    static func workingProperty(for slot: GearSlot) -> MaterialProperty {
        switch slot {
        case .weapon, .offhand, .head, .armor: .hardness
        case .hands, .feet: .flexibility
        case .tool: .density
        case .keepsake: .lustre
        }
    }

    /// One reforge's price, stated in full.
    struct Requirement: Equatable, Sendable {
        var property: MaterialProperty
        /// Every sample handed over must reach this.
        var minimum: Double
        var count: Int
        var essence: Int
        /// The level this buys. `piece.upgradeLevel + 1`.
        var level: Int

        var summary: String {
            "\(count) × \(property.stockWord) \(Int(minimum))+"
        }
    }

    /// Every physical piece has the same three within-tier ranks. Construction tier remains the
    /// specialist hierarchy; reforging can improve a piece but can never promote it across that
    /// boundary.
    static func maximumLevel(for definition: ItemDef) -> Int {
        Tuning.Smith.maximumReforgeRank
    }

    /// What the next step up costs. Nil when the piece is finished, or isn't gear at all.
    ///
    /// Both the threshold and the essence climb with the level, so the first reforging is something
    /// you do with whatever you came home with and the fourth is something you go looking for.
    ///
    /// Keyed on **what a piece is and how far it's been pushed**, not on an `ItemStack`, because
    /// the thing you most want reforged is usually the thing you're wearing — and a worn piece has
    /// no stack.
    static func requirement(for catalogID: ItemID, at upgradeLevel: Int) -> Requirement? {
        guard let definition = ContentCatalog.shared.item(catalogID),
              let gear = definition.gear
        else { return nil }
        let level = upgradeLevel + 1
        guard level <= maximumLevel(for: definition) else { return nil }
        let t = Tuning.Smith.self
        return Requirement(
            property: workingProperty(for: gear.slot),
            minimum: min(t.maximumThreshold,
                         t.baseThreshold + Double(level - 1) * t.thresholdPerLevel),
            count: t.samplesBase + (level - 1) * t.samplesPerLevel,
            essence: t.essenceBase + (level - 1) * t.essencePerLevel,
            level: level
        )
    }

    // MARK: Finding the stock

    /// One sample on the shelf that would satisfy a requirement, and where it lives.
    struct Candidate: Equatable, Sendable {
        var binID: InstanceID
        var index: Int
        var sample: MaterialSample
        var value: Double
    }

    /// **Everything in the storehouse hard enough (or supple enough, or…) to do the job**, worst
    /// qualifying first.
    ///
    /// Worst-first is deliberate: a reforging that silently ate your finest plate because it
    /// happened to be in the same bin would make you afraid to use the smith at all. It spends what
    /// clears the bar and leaves the rest of the hoard alone.
    static func candidates(for requirement: Requirement, in state: GameState) -> [Candidate] {
        var found: [Candidate] = []
        for bin in state.base.inventory.stacks {
            for (index, sample) in bin.materials.enumerated() {
                let value = sample.properties[requirement.property]
                guard value >= requirement.minimum else { continue }
                found.append(Candidate(binID: bin.id, index: index, sample: sample, value: value))
            }
        }
        return found.sorted { ($0.value, $0.sample.grade) < ($1.value, $1.sample.grade) }
    }

    /// Whether a reforging can go ahead right now, and if not, what's short.
    enum Readiness: Equatable, Sendable {
        case ready
        case finished
        case needsMaterials(have: Int, need: Int)
        case needsEssence(have: Int, need: Int)

        var isReady: Bool { self == .ready }
    }

    static func readiness(for catalogID: ItemID, at upgradeLevel: Int,
                          in state: GameState) -> Readiness {
        guard let requirement = requirement(for: catalogID, at: upgradeLevel) else { return .finished }
        let stock = candidates(for: requirement, in: state)
        guard stock.count >= requirement.count else {
            return .needsMaterials(have: stock.count, need: requirement.count)
        }
        guard state.base.essence >= requirement.essence else {
            return .needsEssence(have: state.base.essence, need: requirement.essence)
        }
        return .ready
    }

    // MARK: Doing it

    /// Pays a requirement: the stock leaves the bins, the essence leaves the purse.
    ///
    /// Split out from the two reforge paths because a worn piece and a stored one cost the same
    /// thing — only what happens to the piece afterwards differs.
    @discardableResult
    private static func pay(_ requirement: Requirement, in state: inout GameState) -> Bool {
        let spending = Array(candidates(for: requirement, in: state).prefix(requirement.count))
        guard spending.count == requirement.count, state.base.essence >= requirement.essence
        else { return false }

        // Remove the chosen samples highest-index-first within each bin, so earlier removals can't
        // shift the indices of later ones.
        let byBin = Dictionary(grouping: spending, by: \.binID)
        for (binID, taken) in byBin {
            guard let binIndex = state.base.inventory.stacks.firstIndex(where: { $0.id == binID })
            else { continue }
            for candidate in taken.sorted(by: { $0.index > $1.index }) {
                state.base.inventory.stacks[binIndex].materials.remove(at: candidate.index)
            }
            state.base.inventory.stacks[binIndex].count =
                state.base.inventory.stacks[binIndex].materials.count
        }
        state.base.inventory.stacks.removeAll { $0.materials.isEmpty && $0.count <= 0 }

        state.base.essence -= requirement.essence
        return true
    }

    /// Reforge something on the shelf.
    ///
    /// Takes **one instance** out of its bin and returns the reforged one rather than mutating in
    /// place: a reforged piece has a different `binKey` — it is genuinely a different object from
    /// its unreforged twin — and the other three in the bin haven't been touched.
    @discardableResult
    static func reforge(stored stack: ItemStack, in state: inout GameState) -> ItemStack? {
        let rank = stack.gearProfile?.reforgeRank ?? stack.upgradeLevel
        guard case .ready = readiness(for: stack.catalogID, at: rank, in: state),
              let requirement = requirement(for: stack.catalogID, at: rank),
              let index = state.base.inventory.stacks.firstIndex(where: { $0.id == stack.id })
        else { return nil }

        // The piece comes off the shelf FIRST, so it can't be spent as stock for its own reforging.
        guard var taken = state.base.inventory.stacks[index].removing(1) else { return nil }
        if state.base.inventory.stacks[index].isEmpty {
            state.base.inventory.stacks.remove(at: index)
        }
        guard pay(requirement, in: &state) else {
            // Couldn't pay after all — put it back exactly as it was.
            state.base.store(taken)
            return nil
        }
        taken.gearProfile?.reforgeRank += 1
        taken.upgradeLevel = taken.gearProfile?.reforgeRank ?? (taken.upgradeLevel + 1)
        // A reforged piece is its own bin, so it may need a slot the storehouse hasn't got. It
        // goes to the waiting pile rather than nowhere.
        state.base.store(taken)
        return taken
    }

    /// Reforge something somebody is wearing.
    ///
    /// **Without taking it off**, which matters more than it sounds: the piece you most want
    /// improved is the one you're carrying, and making you unequip it first would be a chore
    /// standing between you and the thing the building is for.
    @discardableResult
    static func reforge(worn slot: GearSlot, on member: PartyMember,
                        in state: inout GameState) -> Bool {
        guard let piece = state.base.worn(slot, by: member) else { return false }
        let rank = piece.gearProfile?.reforgeRank ?? piece.upgradeLevel
        guard case .ready = readiness(for: piece.catalogID, at: rank, in: state),
              let requirement = requirement(for: piece.catalogID, at: rank),
              pay(requirement, in: &state)
        else { return false }

        switch member {
        case .binder:
            guard var reforged = state.base.binderEquipped[slot] else { return false }
            reforged.gearProfile?.reforgeRank += 1
            reforged.upgradeLevel = reforged.gearProfile?.reforgeRank ?? (piece.upgradeLevel + 1)
            state.base.binderEquipped[slot] = reforged
        case .member(let index):
            guard state.base.roster.indices.contains(index) else { return false }
            guard var reforged = state.base.roster[index].equipped[slot] else { return false }
            reforged.gearProfile?.reforgeRank += 1
            reforged.upgradeLevel = reforged.gearProfile?.reforgeRank ?? (piece.upgradeLevel + 1)
            state.base.roster[index].equipped[slot] = reforged
        }
        return true
    }
}

/// Something the smith could work on: a piece on the shelf, or one somebody is wearing.
///
/// Worn pieces are listed too, and reforged in place. The piece you most want improved is nearly
/// always the one you're carrying, and making you take it off first would be a chore standing
/// between you and the only thing the building does.
enum ReforgeTarget: Identifiable, Equatable, Sendable {
    case stored(ItemStack)
    case worn(slot: GearSlot, member: PartyMember, piece: EquippedPiece)

    var id: String {
        switch self {
        case .stored(let stack): "stored-\(stack.id.rawValue)"
        case .worn(let slot, let member, _): "worn-\(member.id)-\(slot.rawValue)"
        }
    }

    var catalogID: ItemID {
        switch self {
        case .stored(let stack): stack.catalogID
        case .worn(_, _, let piece): piece.catalogID
        }
    }

    var upgradeLevel: Int {
        switch self {
        case .stored(let stack): stack.gearProfile?.reforgeRank ?? stack.upgradeLevel
        case .worn(_, _, let piece): piece.gearProfile?.reforgeRank ?? piece.upgradeLevel
        }
    }

    var definition: ItemDef? { ContentCatalog.shared.item(catalogID) }
    var effectivePower: Double {
        switch self {
        case .stored(let stack): stack.effectivePower
        case .worn(_, _, let piece): piece.effectivePower
        }
    }
    var effectiveTier: Int { Int(effectivePower.rounded()) }
    var constructionTier: Int {
        switch self {
        case .stored(let stack): stack.constructionTier
        case .worn(_, _, let piece): piece.constructionTier
        }
    }
    var rarity: Rarity { definition?.rarity ?? .common }
    var icon: String { definition?.icon ?? "questionmark" }

    var displayName: String {
        let base = definition?.name ?? catalogID.rawValue
        let suffix = upgradeLevel > 0 ? " · Reforged \(upgradeLevel)/3" : ""
        return "\(base) · Tier \(constructionTier)\(suffix)"
    }

    /// How many of this exact piece are in the bin — nothing, for a worn one.
    var count: Int {
        switch self {
        case .stored(let stack): stack.count
        case .worn: 1
        }
    }

    /// Who's wearing it, for the row's second line.
    var wearer: String? {
        switch self {
        case .stored: nil
        case .worn(let slot, let member, _): "\(member.displayName) · \(slot.displayName)"
        }
    }
}

/// The six properties, as something you can name and ask for — recipes read one by name (§5), and
/// the smith says which one it's judging by, so "why won't this pelt do" always has an answer.
enum MaterialProperty: String, CaseIterable, Codable, Sendable {
    case hardness, density, insulation, flexibility, lustre, reactivity

    var displayName: String { rawValue.capitalisedSentence }

    /// What the smith calls stock of this kind when it's asking for some.
    var stockWord: String {
        switch self {
        case .hardness: "hard stock"
        case .density: "dense stock"
        case .insulation: "warm stock"
        case .flexibility: "supple stock"
        case .lustre: "lustrous stock"
        case .reactivity: "volatile stock"
        }
    }

    var icon: String {
        switch self {
        case .hardness: "diamond"
        case .density: "circle.fill"
        case .insulation: "flame"
        case .flexibility: "wave.3.right"
        case .lustre: "sparkle"
        case .reactivity: "bolt"
        }
    }
}

extension MaterialProperties {
    subscript(property: MaterialProperty) -> Double {
        get {
            switch property {
            case .hardness: hardness
            case .density: density
            case .insulation: insulation
            case .flexibility: flexibility
            case .lustre: lustre
            case .reactivity: reactivity
            }
        }
        set {
            switch property {
            case .hardness: hardness = newValue
            case .density: density = newValue
            case .insulation: insulation = newValue
            case .flexibility: flexibility = newValue
            case .lustre: lustre = newValue
            case .reactivity: reactivity = newValue
            }
        }
    }
}

/// Tovin's carried certainty route. Six different samples are assigned to six property slots;
/// one exceptional sample can never satisfy two rows of the recipe.
enum AnchorFrameRules {
    struct Need: Equatable, Sendable {
        var property: MaterialProperty
        var minimum: Double
    }

    struct GroupedNeed: Identifiable, Equatable, Sendable {
        var property: MaterialProperty
        var minimum: Double
        var count: Int
        var id: String { "\(property.rawValue):\(minimum)" }
    }

    static let essenceCost = 60
    static let needs: [Need] = [
        Need(property: .hardness, minimum: 65), Need(property: .hardness, minimum: 65),
        Need(property: .density, minimum: 65), Need(property: .density, minimum: 65),
        Need(property: .flexibility, minimum: 55), Need(property: .reactivity, minimum: 65),
    ]

    static var groupedNeeds: [GroupedNeed] {
        needs.reduce(into: []) { groups, need in
            if let index = groups.firstIndex(where: {
                $0.property == need.property && $0.minimum == need.minimum
            }) {
                groups[index].count += 1
            } else {
                groups.append(GroupedNeed(property: need.property, minimum: need.minimum, count: 1))
            }
        }
    }

    static func selectedSamples(in state: GameState) -> [SmithRules.Candidate]? {
        let slots = needs.enumerated().sorted { lhs, rhs in
            candidates(for: lhs.element, in: state).count < candidates(for: rhs.element, in: state).count
        }
        func assign(_ position: Int, used: Set<String>, chosen: [SmithRules.Candidate])
            -> [SmithRules.Candidate]? {
            guard position < slots.count else { return chosen }
            for candidate in candidates(for: slots[position].element, in: state) {
                let key = "\(candidate.binID.rawValue):\(candidate.index)"
                guard !used.contains(key) else { continue }
                if let result = assign(position + 1, used: used.union([key]), chosen: chosen + [candidate]) {
                    return result
                }
            }
            return nil
        }
        return assign(0, used: [], chosen: [])
    }

    private static func candidates(for need: Need, in state: GameState) -> [SmithRules.Candidate] {
        SmithRules.candidates(for: .init(property: need.property, minimum: need.minimum,
                                         count: 1, essence: 0, level: 0), in: state)
    }

    static func canCraft(in state: GameState) -> Bool {
        state.base.station(Stations.anchorage).isUnlocked
            && state.base.essence >= essenceCost
            && selectedSamples(in: state) != nil
    }

    static func shortfall(in state: GameState) -> [String] {
        var missing: [String] = []
        for group in Dictionary(grouping: needs, by: { "\($0.property.rawValue):\($0.minimum)" }).values {
            guard let need = group.first else { continue }
            let have = candidates(for: need, in: state).count
            if have < group.count {
                missing.append("\(group.count - have) × \(need.property.stockWord) \(Int(need.minimum))+")
            }
        }
        if selectedSamples(in: state) == nil && missing.isEmpty {
            missing.append("six distinct qualifying samples")
        }
        if state.base.essence < essenceCost { missing.append("\(essenceCost - state.base.essence) essence") }
        return missing.sorted()
    }

    static func craft(in state: inout GameState) -> Bool {
        guard canCraft(in: state), let spending = selectedSamples(in: state) else { return false }
        for (binID, candidates) in Dictionary(grouping: spending, by: \.binID) {
            guard let bin = state.base.inventory.stacks.firstIndex(where: { $0.id == binID }) else { return false }
            for candidate in candidates.sorted(by: { $0.index > $1.index }) {
                state.base.inventory.stacks[bin].materials.remove(at: candidate.index)
            }
            state.base.inventory.stacks[bin].count = state.base.inventory.stacks[bin].materials.count
        }
        state.base.inventory.stacks.removeAll { $0.count == 0 }
        state.base.essence -= essenceCost
        state.base.store(ItemStack(id: InstanceID(rawValue: state.base.nextItemID()),
                                   catalogID: Items.anchorFrame))
        return true
    }
}
