import Foundation

/// What a creature leaves behind.
///
/// **No authored drop tables** (creature-system-spec §8): the parts that composed the creature
/// compose what it leaves. A world that grows monstrous armoured things drops monstrous plates —
/// which is the reason to write such a world, and it can't be true of a table someone typed out.
///
/// A material is a *kind* plus the properties it inherited from the animal it came off, so two
/// plates are not interchangeable. That's the whole economy of this: what you can make depends on
/// where you've been.
enum MaterialKind: String, Codable, CaseIterable, Equatable, Hashable, Sendable {
    // From covering
    case plate, quill, pelt, down, hide, chitin
    // From armament
    case fang, tusk, claw
    // From the skeleton
    case bone
    // From whatever it was doing instead of being ordinary
    case ichor

    // Flora, for when `flora-system-spec.md` lands. Declared now so the material economy has one
    // vocabulary rather than two.
    case timber, fibre, pulp, toxin, reagent

    /// Closed provenance boundary used by animal-only preparations. A resource's display source
    /// and property values never get to imply that it came from an animal.
    var isAnimalWorldResource: Bool {
        switch self {
        case .plate, .quill, .pelt, .down, .hide, .chitin, .fang, .tusk, .claw, .bone, .ichor:
            true
        case .timber, .fibre, .pulp, .toxin, .reagent:
            false
        }
    }

    var displayName: String { rawValue.capitalisedSentence }

    /// What a binful of them is called. English, not a bolted-on "s" — *down* and *ichor* don't
    /// take one, and a bin labelled "Downs" reads as a mistake.
    var pluralName: String {
        switch self {
        case .down, .ichor, .timber, .fibre, .pulp, .chitin: rawValue
        case .toxin, .reagent: rawValue + "s"
        default: rawValue + "s"
        }
    }

    /// **[PLACEHOLDER]** — session 11's glyph guidance applies to these too.
    var icon: String {
        switch self {
        case .plate, .chitin: "shield.lefthalf.filled"
        case .quill: "line.diagonal"
        case .pelt, .down, .hide: "square.stack.3d.down.right"
        case .fang, .claw: "triangle"
        case .tusk, .bone: "oval"
        case .ichor, .toxin, .reagent: "drop"
        case .timber: "rectangle.portrait"
        case .fibre: "scribble"
        case .pulp: "circle.dotted"
        }
    }
}

/// What a material is good for. Inherited from the traits that produced it, so a pelt off a
/// cold-world animal genuinely insulates better than one off a temperate animal.
struct MaterialProperties: Codable, Equatable, Sendable {
    var hardness: Double = 0
    var density: Double = 0
    var insulation: Double = 0
    var flexibility: Double = 0
    var lustre: Double = 0
    var reactivity: Double = 0

    init(hardness: Double = 0, density: Double = 0, insulation: Double = 0,
         flexibility: Double = 0, lustre: Double = 0, reactivity: Double = 0) {
        self.hardness = hardness
        self.density = density
        self.insulation = insulation
        self.flexibility = flexibility
        self.lustre = lustre
        self.reactivity = reactivity
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        hardness = try c.decodeIfPresent(Double.self, forKey: .hardness) ?? 0
        density = try c.decodeIfPresent(Double.self, forKey: .density) ?? 0
        insulation = try c.decodeIfPresent(Double.self, forKey: .insulation) ?? 0
        flexibility = try c.decodeIfPresent(Double.self, forKey: .flexibility) ?? 0
        lustre = try c.decodeIfPresent(Double.self, forKey: .lustre) ?? 0
        reactivity = try c.decodeIfPresent(Double.self, forKey: .reactivity) ?? 0
    }

    /// The property this material is really about — what a player would name it by.
    var dominant: (name: String, value: Double) {
        let all = [("hard", hardness), ("dense", density), ("warm", insulation),
                   ("supple", flexibility), ("lustrous", lustre), ("volatile", reactivity)]
        let best = all.max { $0.1 < $1.1 } ?? ("plain", 0)
        return (best.0, best.1)
    }
}

/// One drop: a kind, what it inherited, and how good an example of itself it is.
struct MaterialSample: Codable, Equatable, Sendable {
    var kind: MaterialKind
    var properties: MaterialProperties
    /// 0–100. **Grade scales with trait extremity** — an ordinary animal gives ordinary parts.
    var grade: Double
    /// Which animal it came off, so the storehouse can say where a thing is from.
    var source: String
    /// **Inherited from the source, not recomputed** (name-generation-spec §5). A pelt off a
    /// *shaggy browser* is a *shaggy pelt* — that inheritance is what makes loot read as coming
    /// from somewhere, and what makes you remember where when a recipe asks for it later.
    var qualifier: String?

    init(kind: MaterialKind, properties: MaterialProperties, grade: Double,
         source: String, qualifier: String? = nil) {
        self.kind = kind
        self.properties = properties
        self.grade = grade
        self.source = source
        self.qualifier = qualifier
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        kind = try c.decodeIfPresent(MaterialKind.self, forKey: .kind) ?? .hide
        properties = try c.decodeIfPresent(MaterialProperties.self, forKey: .properties)
            ?? MaterialProperties()
        grade = try c.decodeIfPresent(Double.self, forKey: .grade) ?? 0
        source = try c.decodeIfPresent(String.self, forKey: .source) ?? ""
        qualifier = try c.decodeIfPresent(String.self, forKey: .qualifier)
    }

    /// `[grade] [qualifier] [kind]` — *fine ashen pelt*, *monstrous ironbound plate*.
    var displayName: String {
        [gradeWord, qualifier, kind.rawValue]
            .compactMap { $0 }
            .joined(separator: " ")
            .capitalisedSentence
    }

    /// **[PLACEHOLDER]** vocabulary, per name-generation-spec §5.
    var gradeWord: String? {
        switch grade {
        case ..<25: "crude"
        case 25..<55: nil          // plain needs no word
        case 55..<75: "fine"
        case 75..<90: "superb"
        default: "monstrous"
        }
    }

    var rarity: Rarity {
        switch grade {
        case ..<40: .common
        case 40..<65: .uncommon
        case 65..<85: .rare
        default: .mythic
        }
    }
}

/// Stable identity for one exact property-bearing sample held outside slot-limited item storage.
struct MaterialReserveUnitID: RawRepresentable, Codable, Equatable, Hashable, Comparable, Sendable {
    var rawValue: String
    init(rawValue: String) { self.rawValue = rawValue }
    static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}

/// One physical material sample. `protectedReturn` records a unit carried out from Home rather
/// than found during the current expedition; failure-return rules must never discard it.
struct MaterialReserveUnit: Codable, Equatable, Identifiable, Sendable {
    var id: MaterialReserveUnitID
    var sample: MaterialSample
    var protectedReturn: Bool = false
}

/// Frozen selection passed from presentation/recipe quoting to the atomic commit boundary.
/// Consumers never retain an array index: reorder and unrelated reserve changes remain safe.
struct MaterialReserveSelection: Codable, Equatable, Sendable {
    var unitID: MaterialReserveUnitID
    var sample: MaterialSample
}

/// Harvested materials are bulk reserves, not Storehouse or satchel slots. Exact samples remain separate
/// so grade, inherited properties and source provenance are never averaged away.
struct MaterialReserve: Codable, Equatable, Sendable {
    struct FailurePartition: Equatable, Sendable {
        var kept: MaterialReserve
        var lost: MaterialReserve
    }
    private(set) var units: [MaterialReserveUnit] = []

    init(units: [MaterialReserveUnit] = []) {
        self.units = units
    }

    var isEmpty: Bool { units.isEmpty }
    var count: Int { units.count }

    func units(of kind: MaterialKind) -> [MaterialReserveUnit] {
        units.filter { $0.sample.kind == kind }
    }

    func selections(where accepts: (MaterialSample) -> Bool = { _ in true })
        -> [MaterialReserveSelection] {
        units.filter { accepts($0.sample) }
            .sorted { $0.id < $1.id }
            .map { MaterialReserveSelection(unitID: $0.id, sample: $0.sample) }
    }

    mutating func add(_ unit: MaterialReserveUnit) {
        guard !units.contains(where: { $0.id == unit.id }) else { return }
        units.append(unit)
    }

    /// Adds a harvested group while consuming only the caller's one historical stack identity.
    /// Unit identities derive from that identity plus exact content and ordinal, so quantity does
    /// not introduce extra gameplay RNG draws.
    mutating func addHarvested(_ sample: MaterialSample, count: Int,
                               sourceReceipt: String, dropOrdinal: Int,
                               protectedReturn: Bool = false) {
        guard count > 0 else { return }
        for ordinal in 0..<count {
            let base = Self.harvestID(sourceReceipt: sourceReceipt, dropOrdinal: dropOrdinal,
                                      unitOrdinal: ordinal, sample: sample)
            var candidate = base
            var collision = 2
            if let existing = units.first(where: { $0.id == candidate }),
               existing.sample == sample && existing.protectedReturn == protectedReturn {
                continue
            }
            while units.contains(where: { $0.id == candidate }) {
                candidate = .init(rawValue: "\(base.rawValue)-\(collision)")
                collision += 1
            }
            add(.init(id: candidate, sample: sample, protectedReturn: protectedReturn))
        }
    }

    /// Protected carried units return exactly. Exposed samples share one discrete outcome budget,
    /// selected by stable unit identity and never by current array order.
    func partitionedForFailure(fraction: Double,
                               outcomeID: ExpeditionOutcomeID) -> FailurePartition {
        let fraction = min(1, max(0, fraction))
        let protected = units.filter(\.protectedReturn)
        let exposed = units.filter { !$0.protectedReturn }
        let budget = fraction > 0
            ? min(exposed.count, Int(ceil(Double(exposed.count) * fraction))) : 0
        let ordered = exposed.sorted {
            let lhs = Self.stableHash("\(outcomeID.rawValue):material:\($0.id.rawValue)")
            let rhs = Self.stableHash("\(outcomeID.rawValue):material:\($1.id.rawValue)")
            return lhs != rhs ? lhs < rhs : $0.id < $1.id
        }
        return .init(kept: MaterialReserve(units: protected + Array(ordered.prefix(budget))),
                     lost: MaterialReserve(units: Array(ordered.dropFirst(budget))))
    }

    /// Revalidates every exact ID and frozen sample before removing anything. Duplicate IDs,
    /// stale quotes and changed samples all refuse without partial consumption.
    mutating func consume(_ selections: [MaterialReserveSelection]) -> [MaterialSample]? {
        guard Set(selections.map(\.unitID)).count == selections.count else { return nil }
        var indices: [Int] = []
        for selection in selections {
            guard let index = units.firstIndex(where: {
                $0.id == selection.unitID && $0.sample == selection.sample
            }) else { return nil }
            indices.append(index)
        }
        let samples = indices.map { units[$0].sample }
        for index in indices.sorted(by: >) { units.remove(at: index) }
        return samples
    }

    /// Losslessly adopts eligible material samples from a legacy item container. IDs are derived
    /// from the frozen container location, old stack identity, ordinal and complete sample content.
    mutating func migrateLegacyStacks(_ stacks: inout [ItemStack], location: String) {
        for stackIndex in stacks.indices.reversed() {
            let stack = stacks[stackIndex]
            guard stack.catalogID == Items.material, !stack.materials.isEmpty else { continue }
            for (ordinal, sample) in stack.materials.enumerated() {
                let base = Self.legacyID(location: location, stackID: stack.id,
                                         ordinal: ordinal, sample: sample)
                var candidate = base
                var collision = 2
                while let existing = units.first(where: { $0.id == candidate }),
                      existing.sample != sample || existing.protectedReturn != (ordinal < stack.protectedReturnCount) {
                    candidate = MaterialReserveUnitID(rawValue: "\(base.rawValue)-\(collision)")
                    collision += 1
                }
                add(MaterialReserveUnit(id: candidate, sample: sample,
                                        protectedReturn: ordinal < stack.protectedReturnCount))
            }
            stacks.remove(at: stackIndex)
        }
    }

    private static func legacyID(location: String, stackID: InstanceID, ordinal: Int,
                                 sample: MaterialSample) -> MaterialReserveUnitID {
        let p = sample.properties
        let content = [sample.kind.rawValue,
                       String(sample.grade.bitPattern, radix: 16),
                       String(p.hardness.bitPattern, radix: 16),
                       String(p.density.bitPattern, radix: 16),
                       String(p.insulation.bitPattern, radix: 16),
                       String(p.flexibility.bitPattern, radix: 16),
                       String(p.lustre.bitPattern, radix: 16),
                       String(p.reactivity.bitPattern, radix: 16),
                       sample.source, sample.qualifier ?? ""].joined(separator: "|")
        let hash = stableHash("\(location)|\(stackID.rawValue)|\(ordinal)|\(content)")
        return MaterialReserveUnitID(rawValue: "legacy-\(String(hash, radix: 16))")
    }

    private static func harvestID(sourceReceipt: String, dropOrdinal: Int, unitOrdinal: Int,
                                  sample: MaterialSample) -> MaterialReserveUnitID {
        let content = canonicalContent(of: sample)
        let hash = stableHash("harvest|\(sourceReceipt)|\(dropOrdinal)|\(unitOrdinal)|\(content)")
        return .init(rawValue: "harvest-\(String(hash, radix: 16))")
    }

    private static func canonicalContent(of sample: MaterialSample) -> String {
        let p = sample.properties
        return [sample.kind.rawValue,
                String(sample.grade.bitPattern, radix: 16),
                String(p.hardness.bitPattern, radix: 16),
                String(p.density.bitPattern, radix: 16),
                String(p.insulation.bitPattern, radix: 16),
                String(p.flexibility.bitPattern, radix: 16),
                String(p.lustre.bitPattern, radix: 16),
                String(p.reactivity.bitPattern, radix: 16),
                sample.source, sample.qualifier ?? ""].joined(separator: "|")
    }

    private static func stableHash(_ text: String) -> UInt64 {
        var hash: UInt64 = 0xcbf29ce484222325
        for byte in text.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x100000001b3
        }
        return hash
    }
}
