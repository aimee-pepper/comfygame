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
enum MaterialFamilyID: String, Codable, CaseIterable, Equatable, Hashable, Sendable {
    // Canonical ordinary world construction stock.
    case rubble, clay, ore, copper, adamant, obsidian, resin, silver, gold, quartz
    // From covering
    case plate, quill, pelt, down, hide, chitin, feather, fin, scale, oil, shell, horn, venom
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
        case .plate, .quill, .pelt, .down, .hide, .chitin, .feather, .fin, .scale,
             .oil, .shell, .horn, .venom, .fang, .tusk, .claw, .bone, .ichor:
            true
        case .rubble, .clay, .ore, .copper, .adamant, .obsidian, .resin, .silver, .gold,
             .quartz, .timber, .fibre, .pulp, .toxin, .reagent:
            false
        }
    }

    var displayName: String { rawValue.capitalisedSentence }

    /// What a binful of them is called. English, not a bolted-on "s" — *down* and *ichor* don't
    /// take one, and a bin labelled "Downs" reads as a mistake.
    var pluralName: String {
        switch self {
        case .down, .ichor, .timber, .fibre, .pulp, .chitin, .oil: rawValue
        case .toxin, .reagent, .venom: rawValue + "s"
        default: rawValue + "s"
        }
    }

    /// **[PLACEHOLDER]** — session 11's glyph guidance applies to these too.
    var icon: String {
        switch self {
        case .plate, .chitin, .scale, .shell: "shield.lefthalf.filled"
        case .quill, .feather: "line.diagonal"
        case .pelt, .down, .hide: "square.stack.3d.down.right"
        case .fang, .claw: "triangle"
        case .tusk, .horn, .bone: "oval"
        case .ichor, .oil, .venom, .toxin, .reagent, .resin: "drop"
        case .fin: "water.waves"
        case .timber: "rectangle.portrait"
        case .fibre: "scribble"
        case .pulp: "circle.dotted"
        case .rubble, .clay, .ore, .copper, .adamant, .obsidian, .silver, .gold, .quartz:
            "diamond.fill"
        }
    }
}

extension MaterialFamilyID {
    init(_ family: CreatureMaterialFamilyID) {
        self = MaterialFamilyID(rawValue: family.rawValue)!
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
        guard Set(c.allKeys) == Set(CodingKeys.allCases) else { throw CocoaError(.coderInvalidValue) }
        hardness = try c.decode(Double.self, forKey: .hardness)
        density = try c.decode(Double.self, forKey: .density)
        insulation = try c.decode(Double.self, forKey: .insulation)
        flexibility = try c.decode(Double.self, forKey: .flexibility)
        lustre = try c.decode(Double.self, forKey: .lustre)
        reactivity = try c.decode(Double.self, forKey: .reactivity)
        guard values.allSatisfy({ $0.isFinite && (0...100).contains($0) }) else {
            throw CocoaError(.coderInvalidValue)
        }
    }

    /// The property this material is really about — what a player would name it by.
    var dominant: (name: String, value: Double) {
        let all = [("hard", hardness), ("dense", density), ("warm", insulation),
                   ("supple", flexibility), ("lustrous", lustre), ("volatile", reactivity)]
        let best = all.max { $0.1 < $1.1 } ?? ("plain", 0)
        return (best.0, best.1)
    }

    var values: [Double] { [hardness, density, insulation, flexibility, lustre, reactivity] }

    private enum CodingKeys: String, CodingKey, CaseIterable {
        case hardness, density, insulation, flexibility, lustre, reactivity
    }
}

enum CraftMaterialDomain: String, Codable, CaseIterable, Hashable, Sendable {
    case world, creature

    static func forFamily(_ family: MaterialFamilyID) -> Self {
        switch family {
        case .rubble, .clay, .ore, .copper, .adamant, .obsidian, .resin, .silver, .gold,
             .quartz, .timber, .fibre, .pulp, .toxin, .reagent: .world
        default: .creature
        }
    }
}

enum CraftMaterialUnitFactory {
    static func merchant(kind: MaterialFamilyID, properties: MaterialProperties) -> CraftMaterialUnitV1 {
        .init(stableUnitID: .init(rawValue: "merchant-prototype-\(kind.rawValue)"),
              domain: .forFamily(kind), familyID: kind, qualityBand: .standard,
              properties: properties,
              sourceReceipt: .legacy(originalKind: kind, frozenSource: "Vance's supplier",
                                     qualifier: nil, migrationLocation: "trading-stock",
                                     originalIdentity: nil))
    }
}

enum CraftMaterialQualityBand: Int, Codable, CaseIterable, Comparable, Sendable {
    case rough = 0, standard, fine, superior, exceptional, peerless

    static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }

    init(legacyGrade: Double) throws {
        guard legacyGrade.isFinite, (0...100).contains(legacyGrade) else {
            throw CocoaError(.coderInvalidValue)
        }
        self = switch legacyGrade {
        case ..<25: .rough
        case 25..<55: .standard
        case 55..<75: .fine
        case 75..<90: .superior
        case 90..<98: .exceptional
        default: .peerless
        }
    }

    var displayName: String {
        switch self {
        case .rough: "Rough"
        case .standard: "Standard"
        case .fine: "Fine"
        case .superior: "Superior"
        case .exceptional: "Exceptional"
        case .peerless: "Peerless"
        }
    }
}

enum CraftMaterialSourceReceiptV1: Codable, Equatable, Sendable {
    struct Legacy: Codable, Equatable, Sendable {
        var originalKind: MaterialFamilyID
        var frozenSource: String
        var qualifier: String?
        var migrationLocation: String
        var originalIdentity: String

        init(originalKind: MaterialFamilyID, frozenSource: String, qualifier: String?,
             migrationLocation: String, originalIdentity: String) {
            self.originalKind = originalKind
            self.frozenSource = frozenSource
            self.qualifier = qualifier
            self.migrationLocation = migrationLocation
            self.originalIdentity = originalIdentity
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            let keys = Set(c.allKeys)
            guard keys.isSubset(of: Set(CodingKeys.allCases)),
                  keys.isSuperset(of: [.originalKind, .frozenSource, .migrationLocation,
                                       .originalIdentity]) else {
                throw CocoaError(.coderInvalidValue)
            }
            originalKind = try c.decode(MaterialFamilyID.self, forKey: .originalKind)
            frozenSource = try c.decode(String.self, forKey: .frozenSource)
            qualifier = try c.decodeIfPresent(String.self, forKey: .qualifier)
            migrationLocation = try c.decode(String.self, forKey: .migrationLocation)
            originalIdentity = try c.decode(String.self, forKey: .originalIdentity)
            guard !frozenSource.isEmpty, !migrationLocation.isEmpty, !originalIdentity.isEmpty else {
                throw CocoaError(.coderInvalidValue)
            }
        }

        private enum CodingKeys: String, CodingKey, CaseIterable {
            case originalKind, frozenSource, qualifier, migrationLocation, originalIdentity
        }
    }
    struct CreatureReward: Codable, Equatable, Sendable {
        var sourceReceiptID: String
        var encounterID: InstanceID
        var foeID: InstanceID
        var speciesID: InstanceID

        init(sourceReceiptID: String, encounterID: InstanceID, foeID: InstanceID,
             speciesID: InstanceID) {
            self.sourceReceiptID = sourceReceiptID
            self.encounterID = encounterID
            self.foeID = foeID
            self.speciesID = speciesID
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            guard Set(c.allKeys) == Set(CodingKeys.allCases) else { throw CocoaError(.coderInvalidValue) }
            sourceReceiptID = try c.decode(String.self, forKey: .sourceReceiptID)
            encounterID = try c.decode(InstanceID.self, forKey: .encounterID)
            foeID = try c.decode(InstanceID.self, forKey: .foeID)
            speciesID = try c.decode(InstanceID.self, forKey: .speciesID)
            guard !sourceReceiptID.isEmpty else { throw CocoaError(.coderInvalidValue) }
        }

        private enum CodingKeys: String, CodingKey, CaseIterable {
            case sourceReceiptID, encounterID, foeID, speciesID
        }
    }
    struct WorldHarvest: Codable, Equatable, Sendable {
        var receiptID: String

        init(receiptID: String) { self.receiptID = receiptID }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            guard Set(c.allKeys) == Set(CodingKeys.allCases) else { throw CocoaError(.coderInvalidValue) }
            receiptID = try c.decode(String.self, forKey: .receiptID)
            guard !receiptID.isEmpty else { throw CocoaError(.coderInvalidValue) }
        }

        private enum CodingKeys: String, CodingKey, CaseIterable { case receiptID }
    }
    case legacy(Legacy)
    case creatureReward(CreatureReward)
    case worldHarvest(WorldHarvest)

    static func legacy(originalKind: MaterialFamilyID, frozenSource: String, qualifier: String?,
                       migrationLocation: String, originalIdentity: String?) -> Self {
        .legacy(.init(originalKind: originalKind, frozenSource: frozenSource,
                      qualifier: qualifier, migrationLocation: migrationLocation,
                      originalIdentity: originalIdentity ?? "unknown"))
    }

    static func creatureReward(sourceReceiptID: String, encounterID: InstanceID,
                               foeID: InstanceID, speciesID: InstanceID) -> Self {
        .creatureReward(.init(sourceReceiptID: sourceReceiptID, encounterID: encounterID,
                              foeID: foeID, speciesID: speciesID))
    }

    static func worldHarvest(receiptID: String) -> Self {
        .worldHarvest(.init(receiptID: receiptID))
    }

    var sourceText: String {
        switch self {
        case .legacy(let receipt): receipt.frozenSource
        case .creatureReward(let receipt): receipt.sourceReceiptID
        case .worldHarvest(let receipt): receipt.receiptID
        }
    }

    var qualifier: String? {
        if case .legacy(let receipt) = self { receipt.qualifier } else { nil }
    }
}

/// One immutable property-bearing crafting unit. Quality is a closed six-band value; no
/// continuous grade survives schema 7.
struct CraftMaterialUnitV1: Codable, Equatable, Sendable {
    static let schemaVersion = 1
    var schemaVersion: Int = Self.schemaVersion
    var stableUnitID: CraftMaterialUnitID
    var domain: CraftMaterialDomain
    var familyID: MaterialFamilyID
    var qualityBand: CraftMaterialQualityBand
    var properties: MaterialProperties
    var sourceReceipt: CraftMaterialSourceReceiptV1

    init(schemaVersion: Int = 1, stableUnitID: CraftMaterialUnitID,
         domain: CraftMaterialDomain, familyID: MaterialFamilyID,
         qualityBand: CraftMaterialQualityBand, properties: MaterialProperties,
         sourceReceipt: CraftMaterialSourceReceiptV1) {
        self.schemaVersion = schemaVersion
        self.stableUnitID = stableUnitID
        self.domain = domain
        self.familyID = familyID
        self.qualityBand = qualityBand
        self.properties = properties
        self.sourceReceipt = sourceReceipt
    }

    init(stableUnitID: CraftMaterialUnitID, domain: CraftMaterialDomain,
         familyID: MaterialFamilyID, qualityBand: CraftMaterialQualityBand,
         properties: MaterialProperties, sourceReceipt: CraftMaterialSourceReceiptV1) {
        self.stableUnitID = stableUnitID
        self.domain = domain
        self.familyID = familyID
        self.qualityBand = qualityBand
        self.properties = properties
        self.sourceReceipt = sourceReceipt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        guard Set(c.allKeys) == Set(CodingKeys.allCases) else { throw CocoaError(.coderInvalidValue) }
        schemaVersion = try c.decode(Int.self, forKey: .schemaVersion)
        stableUnitID = try c.decode(CraftMaterialUnitID.self, forKey: .stableUnitID)
        domain = try c.decode(CraftMaterialDomain.self, forKey: .domain)
        familyID = try c.decode(MaterialFamilyID.self, forKey: .familyID)
        qualityBand = try c.decode(CraftMaterialQualityBand.self, forKey: .qualityBand)
        properties = try c.decode(MaterialProperties.self, forKey: .properties)
        sourceReceipt = try c.decode(CraftMaterialSourceReceiptV1.self, forKey: .sourceReceipt)
        guard schemaVersion == Self.schemaVersion, !stableUnitID.rawValue.isEmpty,
              properties.values.allSatisfy({ $0.isFinite && (0...100).contains($0) }) else {
            throw CocoaError(.coderInvalidValue)
        }
    }

    var kind: MaterialFamilyID { familyID }
    var source: String { sourceReceipt.sourceText }
    var qualifier: String? { sourceReceipt.qualifier }

    var displayName: String {
        [qualityBand == .standard ? nil : qualityBand.displayName.lowercased(),
         qualifier, familyID.rawValue]
            .compactMap { $0 }
            .joined(separator: " ")
            .capitalisedSentence
    }

    var rarity: Rarity {
        switch qualityBand {
        case .rough, .standard: .common
        case .fine: .uncommon
        case .superior: .rare
        case .exceptional, .peerless: .mythic
        }
    }

    func withStableID(_ id: CraftMaterialUnitID) -> Self {
        var copy = self
        copy.stableUnitID = id
        return copy
    }

    private enum CodingKeys: String, CodingKey, CaseIterable {
        case schemaVersion, stableUnitID, domain, familyID, qualityBand, properties, sourceReceipt
    }
}

/// Stable identity for one exact property-bearing sample held outside slot-limited item storage.
struct CraftMaterialUnitID: RawRepresentable, Codable, Equatable, Hashable, Comparable, Sendable {
    var rawValue: String
    init(rawValue: String) { self.rawValue = rawValue }
    static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}

/// One physical material sample. `protectedReturn` records a unit carried out from Home rather
/// than found during the current expedition; failure-return rules must never discard it.
struct CraftMaterialHoldingV1: Codable, Equatable, Identifiable, Sendable {
    var unit: CraftMaterialUnitV1
    var protectedReturn: Bool = false
    var id: CraftMaterialUnitID { unit.stableUnitID }
    var sample: CraftMaterialUnitV1 { unit }

    init(unit: CraftMaterialUnitV1, protectedReturn: Bool = false) {
        self.unit = unit
        self.protectedReturn = protectedReturn
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        guard Set(c.allKeys) == Set(CodingKeys.allCases) else { throw CocoaError(.coderInvalidValue) }
        unit = try c.decode(CraftMaterialUnitV1.self, forKey: .unit)
        protectedReturn = try c.decode(Bool.self, forKey: .protectedReturn)
    }

    private enum CodingKeys: String, CodingKey, CaseIterable { case unit, protectedReturn }
}

/// Frozen selection passed from presentation/recipe quoting to the atomic commit boundary.
/// Consumers never retain an array index: reorder and unrelated reserve changes remain safe.
struct CraftMaterialSelection: Codable, Equatable, Sendable {
    var unitID: CraftMaterialUnitID
    var unit: CraftMaterialUnitV1
    var sample: CraftMaterialUnitV1 { unit }
}

protocol CraftMaterialReserveDomain {
    static var domain: CraftMaterialDomain { get }
}
enum WorldReserveDomain: CraftMaterialReserveDomain { static let domain = CraftMaterialDomain.world }
enum CreatureReserveDomain: CraftMaterialReserveDomain { static let domain = CraftMaterialDomain.creature }

typealias WorldMaterialReserve = CraftMaterialReserve<WorldReserveDomain>
typealias CreatureMaterialReserve = CraftMaterialReserve<CreatureReserveDomain>

struct CombinedCraftMaterialFailurePartition: Equatable, Sendable {
    var keptWorld: WorldMaterialReserve
    var lostWorld: WorldMaterialReserve
    var keptCreature: CreatureMaterialReserve
    var lostCreature: CreatureMaterialReserve
}

func partitionCraftMaterialsForFailure(world: WorldMaterialReserve,
                                       creature: CreatureMaterialReserve,
                                       fraction: Double,
                                       outcomeID: ExpeditionOutcomeID) -> CombinedCraftMaterialFailurePartition {
    let all = world.units + creature.units
    let protected = all.filter(\.protectedReturn)
    let exposed = all.filter { !$0.protectedReturn }
    let bounded = min(1, max(0, fraction))
    let budget = bounded > 0 ? min(exposed.count, Int(ceil(Double(exposed.count) * bounded))) : 0
    func stableHash(_ text: String) -> UInt64 {
        var hash: UInt64 = 0xcbf29ce484222325
        for byte in text.utf8 { hash ^= UInt64(byte); hash = hash &* 0x100000001b3 }
        return hash
    }
    let ordered = exposed.sorted {
        let lhs = stableHash("\(outcomeID.rawValue):material:\($0.id.rawValue)")
        let rhs = stableHash("\(outcomeID.rawValue):material:\($1.id.rawValue)")
        return lhs != rhs ? lhs < rhs : $0.id < $1.id
    }
    let kept = protected + Array(ordered.prefix(budget))
    let lost = Array(ordered.dropFirst(budget))
    return .init(
        keptWorld: .init(units: kept.filter { $0.unit.domain == .world }),
        lostWorld: .init(units: lost.filter { $0.unit.domain == .world }),
        keptCreature: .init(units: kept.filter { $0.unit.domain == .creature }),
        lostCreature: .init(units: lost.filter { $0.unit.domain == .creature }))
}

/// Slot-free exact holdings. The generic marker is compile-time ownership and decode-time
/// validation: a holding can never silently cross the world/creature boundary.
struct CraftMaterialReserve<Domain: CraftMaterialReserveDomain>: Codable, Equatable, Sendable {
    struct FailurePartition: Equatable, Sendable {
        var kept: CraftMaterialReserve<Domain>
        var lost: CraftMaterialReserve<Domain>
    }
    private(set) var units: [CraftMaterialHoldingV1] = []

    init(units: [CraftMaterialHoldingV1] = []) {
        self.units = units
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        guard Set(c.allKeys) == [.holdings] else { throw CocoaError(.coderInvalidValue) }
        let decoded = try c.decode([CraftMaterialHoldingV1].self, forKey: .holdings)
        guard Set(decoded.map(\.id)).count == decoded.count,
              decoded.allSatisfy({ $0.unit.domain == Domain.domain }) else {
            throw CocoaError(.coderInvalidValue)
        }
        units = decoded
    }

    func encode(to encoder: Encoder) throws {
        guard Set(units.map(\.id)).count == units.count,
              units.allSatisfy({ $0.unit.domain == Domain.domain }) else {
            throw CocoaError(.coderInvalidValue)
        }
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(units, forKey: .holdings)
    }

    private enum CodingKeys: String, CodingKey { case holdings }

    var isEmpty: Bool { units.isEmpty }
    var count: Int { units.count }

    func units(of kind: MaterialFamilyID) -> [CraftMaterialHoldingV1] {
        units.filter { $0.sample.kind == kind }
    }

    func selections(where accepts: (CraftMaterialUnitV1) -> Bool = { _ in true })
        -> [CraftMaterialSelection] {
        units.filter { accepts($0.sample) }
            .sorted { $0.id < $1.id }
            .map { CraftMaterialSelection(unitID: $0.id, unit: $0.unit) }
    }

    mutating func add(_ unit: CraftMaterialHoldingV1) {
        guard unit.unit.domain == Domain.domain,
              !units.contains(where: { $0.id == unit.id }) else { return }
        units.append(unit)
    }

    @discardableResult
    mutating func addExact(_ newUnits: [CraftMaterialHoldingV1]) -> Bool {
        let ids = newUnits.map(\.id)
        guard Set(ids).count == ids.count,
              newUnits.allSatisfy({ $0.unit.domain == Domain.domain }),
              Set(units.map(\.id)).isDisjoint(with: ids) else { return false }
        units.append(contentsOf: newUnits)
        return true
    }

    /// Adds a harvested group while consuming only the caller's one historical stack identity.
    /// Unit identities derive from that identity plus exact content and ordinal, so quantity does
    /// not introduce extra gameplay RNG draws.
    mutating func addHarvested(_ sample: CraftMaterialUnitV1, count: Int,
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
            var exact = sample
            exact.stableUnitID = candidate
            add(.init(unit: exact, protectedReturn: protectedReturn))
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
        return .init(kept: Self(units: protected + Array(ordered.prefix(budget))),
                     lost: Self(units: Array(ordered.dropFirst(budget))))
    }

    /// Revalidates every exact ID and frozen sample before removing anything. Duplicate IDs,
    /// stale quotes and changed samples all refuse without partial consumption.
    mutating func consume(_ selections: [CraftMaterialSelection]) -> [CraftMaterialUnitV1]? {
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

    private static func harvestID(sourceReceipt: String, dropOrdinal: Int, unitOrdinal: Int,
                                  sample: CraftMaterialUnitV1) -> CraftMaterialUnitID {
        let content = canonicalContent(of: sample)
        let hash = stableHash("harvest|\(sourceReceipt)|\(dropOrdinal)|\(unitOrdinal)|\(content)")
        return .init(rawValue: "harvest-\(String(hash, radix: 16))")
    }

    private static func canonicalContent(of sample: CraftMaterialUnitV1) -> String {
        let p = sample.properties
        return [sample.domain.rawValue, sample.kind.rawValue,
                String(sample.qualityBand.rawValue),
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
