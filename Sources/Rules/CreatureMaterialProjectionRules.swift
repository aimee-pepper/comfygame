import Foundation

enum CreatureMaterialFamilyID: String, Codable, CaseIterable, Sendable {
    case hide, pelt, down, feather, fin, bone, scale, quill
    case fang, claw, oil, plate, chitin, shell, tusk, horn, venom, ichor
}

enum CreatureMaterialCapabilityID: String, Codable, CaseIterable, Sendable {
    case coveringCoverage = "covering.coverage"
    case derivedFlexibility = "derived.flexibility"
    case derivedInsulation = "derived.insulation"
    case derivedAppendageExtent = "derived.appendageExtent"
    case derivedFinishLustre = "derived.finishLustre"
    case boneDensity
    case size
    case coveringHardness = "covering.hardness"
    case coveringLength = "covering.length"
    case armamentPierce = "armament.pierce"
    case armamentRend = "armament.rend"
    case derivedArmourValue = "derived.armourValue"
    case finishSchiller = "finish.schiller"
    case armamentCrush = "armament.crush"
    case derivedToxinPotency = "derived.toxinPotency"
    case colorationPatterning = "coloration.patterning"
    case emanationStrength = "emanation.strength"
}

struct CreatureMaterialCapabilitySnapshotV1: Codable, Equatable, Sendable {
    var id: CreatureMaterialCapabilityID
    var value: Double

    init(id: CreatureMaterialCapabilityID, value: Double) { self.id = id; self.value = value }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CreatureProjectionCodingKey.self)
        try requireExactKeys(c, ["id", "value"])
        id = try c.decode(CreatureMaterialCapabilityID.self, forKey: .init("id"))
        value = try c.decode(Double.self, forKey: .init("value"))
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CreatureProjectionCodingKey.self)
        try c.encode(id, forKey: .init("id")); try c.encode(value, forKey: .init("value"))
    }
}

struct CreatureMaterialProjectionEntryV1: Codable, Equatable, Sendable {
    var family: CreatureMaterialFamilyID
    var capabilityA: CreatureMaterialCapabilitySnapshotV1
    var capabilityB: CreatureMaterialCapabilitySnapshotV1
    var partExpression: Int
    var quantityPerDefeatedSpecimen: Int

    init(family: CreatureMaterialFamilyID,
         capabilityA: CreatureMaterialCapabilitySnapshotV1,
         capabilityB: CreatureMaterialCapabilitySnapshotV1,
         partExpression: Int, quantityPerDefeatedSpecimen: Int) {
        self.family = family; self.capabilityA = capabilityA; self.capabilityB = capabilityB
        self.partExpression = partExpression
        self.quantityPerDefeatedSpecimen = quantityPerDefeatedSpecimen
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CreatureProjectionCodingKey.self)
        try requireExactKeys(c, ["family", "capabilityA", "capabilityB", "partExpression",
                                 "quantityPerDefeatedSpecimen"])
        family = try c.decode(CreatureMaterialFamilyID.self, forKey: .init("family"))
        capabilityA = try c.decode(CreatureMaterialCapabilitySnapshotV1.self,
                                   forKey: .init("capabilityA"))
        capabilityB = try c.decode(CreatureMaterialCapabilitySnapshotV1.self,
                                   forKey: .init("capabilityB"))
        partExpression = try c.decode(Int.self, forKey: .init("partExpression"))
        quantityPerDefeatedSpecimen = try c.decode(Int.self,
                                                   forKey: .init("quantityPerDefeatedSpecimen"))
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CreatureProjectionCodingKey.self)
        try c.encode(family, forKey: .init("family"))
        try c.encode(capabilityA, forKey: .init("capabilityA"))
        try c.encode(capabilityB, forKey: .init("capabilityB"))
        try c.encode(partExpression, forKey: .init("partExpression"))
        try c.encode(quantityPerDefeatedSpecimen, forKey: .init("quantityPerDefeatedSpecimen"))
    }
}

struct CreatureMaterialProjectionReceiptV1: Codable, Equatable, Sendable {
    static let currentSchemaVersion = 1
    static let currentAuthorityID = "creature-material-projection-v1"

    var schemaVersion: Int = Self.currentSchemaVersion
    var authorityID: String = Self.currentAuthorityID
    var entries: [CreatureMaterialProjectionEntryV1]

    init(entries: [CreatureMaterialProjectionEntryV1]) {
        self.entries = entries
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CreatureProjectionCodingKey.self)
        try requireExactKeys(container, ["schemaVersion", "authorityID", "entries"])
        schemaVersion = try container.decode(Int.self, forKey: .init("schemaVersion"))
        authorityID = try container.decode(String.self, forKey: .init("authorityID"))
        entries = try container.decode([CreatureMaterialProjectionEntryV1].self,
                                       forKey: .init("entries"))
        try CreatureMaterialProjectionRules.validate(self)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CreatureProjectionCodingKey.self)
        try c.encode(schemaVersion, forKey: .init("schemaVersion"))
        try c.encode(authorityID, forKey: .init("authorityID"))
        try c.encode(entries, forKey: .init("entries"))
    }
}

private struct CreatureProjectionCodingKey: CodingKey, Hashable {
    var stringValue: String
    var intValue: Int? { nil }
    init(_ string: String) { stringValue = string }
    init?(stringValue: String) { self.stringValue = stringValue }
    init?(intValue: Int) { return nil }
}

private func requireExactKeys(_ container: KeyedDecodingContainer<CreatureProjectionCodingKey>,
                              _ expected: Set<String>) throws {
    guard Set(container.allKeys.map(\.stringValue)) == expected else {
        throw CocoaError(.coderInvalidValue)
    }
}

enum CreatureMaterialProjectionValidationError: Error, Equatable {
    case unsupportedSchema, unsupportedAuthority, unknownFamily, unknownCapability
    case duplicateFamily, invalidOrder, wrongCapabilityPair, nonFiniteCapability
    case outOfRangeCapability, inconsistentPartExpression, invalidQuantity
    case projectionWithoutHabitat
}

enum CreatureMaterialProjectionBuildResult: Equatable, Sendable {
    case frozen(CreatureMaterialProjectionReceiptV1)
    case legacyUnsupported
}

enum CreatureMaterialProjectionRules {
    private static let order: [CreatureMaterialFamilyID] = [
        .hide, .pelt, .scale, .plate, .chitin, .shell, .quill, .feather,
        .down, .fin, .fang, .claw, .tusk, .horn, .bone, .venom, .oil, .ichor,
    ]

    static let capabilityPairs: [CreatureMaterialFamilyID: (CreatureMaterialCapabilityID,
                                                               CreatureMaterialCapabilityID)] = [
        .hide: (.coveringCoverage, .derivedFlexibility),
        .pelt: (.derivedInsulation, .coveringCoverage),
        .down: (.derivedInsulation, .derivedFlexibility),
        .feather: (.derivedAppendageExtent, .derivedFinishLustre),
        .fin: (.derivedAppendageExtent, .derivedFlexibility),
        .bone: (.boneDensity, .size),
        .scale: (.coveringHardness, .coveringCoverage),
        .quill: (.coveringHardness, .coveringLength),
        .fang: (.armamentPierce, .boneDensity),
        .claw: (.armamentRend, .boneDensity),
        .oil: (.derivedInsulation, .size),
        .plate: (.coveringHardness, .derivedArmourValue),
        .chitin: (.coveringHardness, .finishSchiller),
        .shell: (.coveringHardness, .derivedArmourValue),
        .tusk: (.armamentCrush, .boneDensity),
        .horn: (.armamentCrush, .boneDensity),
        .venom: (.derivedToxinPotency, .colorationPatterning),
        .ichor: (.emanationStrength, .derivedFinishLustre),
    ]

    static func freeze(traits: CreatureTraits,
                       habitat: CreatureHabitat?) -> CreatureMaterialProjectionBuildResult {
        guard let habitat else { return .legacyUnsupported }
        let values = Values(traits: traits)
        var families: [CreatureMaterialFamilyID] = []
        let primary = primaryFamily(traits: traits, habitat: habitat, values: values)
        if let primary { families.append(primary) }
        if primary == .feather && values.insulation >= 25 { families.append(.down) }
        if traits.appendages.type == .finned && traits.appendages.count > 0 { families.append(.fin) }
        if values.armamentTotal >= 30 {
            switch values.dominantArmament {
            case .pierce: families.append(.fang)
            case .rend: families.append(.claw)
            case .crush: families.append(traits.cranialFeature == .horns ? .horn : .tusk)
            }
        }
        if values.boneDensity >= 20 && traits.bodyPlan != .amorphous { families.append(.bone) }
        if traits.isToxic && values.toxinPotency > 0 { families.append(.venom) }
        if habitat == .aquatic && values.insulation >= 45 { families.append(.oil) }
        if values.emanationStrength >= 25 { families.append(.ichor) }

        let entries = families.map { family -> CreatureMaterialProjectionEntryV1 in
            let pair = capabilityPairs[family]!
            let a = CreatureMaterialCapabilitySnapshotV1(id: pair.0, value: values[pair.0])
            let b = CreatureMaterialCapabilitySnapshotV1(id: pair.1, value: values[pair.1])
            return CreatureMaterialProjectionEntryV1(
                family: family, capabilityA: a, capabilityB: b,
                partExpression: roundHalfUp((a.value + b.value) / 2),
                quantityPerDefeatedSpecimen: quantity(family, values: values))
        }
        return .frozen(CreatureMaterialProjectionReceiptV1(entries: entries))
    }

    static func validate(_ receipt: CreatureMaterialProjectionReceiptV1) throws {
        guard receipt.schemaVersion == CreatureMaterialProjectionReceiptV1.currentSchemaVersion else {
            throw CreatureMaterialProjectionValidationError.unsupportedSchema
        }
        guard receipt.authorityID == CreatureMaterialProjectionReceiptV1.currentAuthorityID else {
            throw CreatureMaterialProjectionValidationError.unsupportedAuthority
        }
        var previous = -1
        var seen = Set<CreatureMaterialFamilyID>()
        for entry in receipt.entries {
            guard seen.insert(entry.family).inserted else {
                throw CreatureMaterialProjectionValidationError.duplicateFamily
            }
            guard let index = order.firstIndex(of: entry.family), index > previous else {
                throw CreatureMaterialProjectionValidationError.invalidOrder
            }
            previous = index
            guard let pair = capabilityPairs[entry.family],
                  entry.capabilityA.id == pair.0, entry.capabilityB.id == pair.1 else {
                throw CreatureMaterialProjectionValidationError.wrongCapabilityPair
            }
            for value in [entry.capabilityA.value, entry.capabilityB.value] {
                guard value.isFinite else {
                    throw CreatureMaterialProjectionValidationError.nonFiniteCapability
                }
                guard (0...100).contains(value) else {
                    throw CreatureMaterialProjectionValidationError.outOfRangeCapability
                }
            }
            guard entry.partExpression == roundHalfUp(
                (entry.capabilityA.value + entry.capabilityB.value) / 2) else {
                throw CreatureMaterialProjectionValidationError.inconsistentPartExpression
            }
            guard allowedQuantity(for: entry.family).contains(entry.quantityPerDefeatedSpecimen) else {
                throw CreatureMaterialProjectionValidationError.invalidQuantity
            }
        }
    }

    private static func primaryFamily(traits: CreatureTraits, habitat: CreatureHabitat,
                                      values: Values) -> CreatureMaterialFamilyID? {
        if traits.appendages.type == .feathered && traits.appendages.count > 0 { return .feather }
        if (habitat == .aquatic || traits.bodyPlan == .piscine), values.coverage >= 15 {
            return values.hardness >= 25 ? .scale : .hide
        }
        if traits.bodyPlan == .segmented && values.coverage >= 15 && values.hardness >= 55 { return .chitin }
        if traits.bodyPlan == .radial && values.coverage >= 15 && values.hardness >= 55 { return .shell }
        if values.coverage >= 15 && values.hardness >= 55 && values.length >= 45 { return .quill }
        if values.coverage >= 15 && values.hardness >= 70 { return .plate }
        if values.coverage >= 15 && values.hardness >= 35 { return .scale }
        if values.coverage >= 50 && values.length >= 45 { return .pelt }
        if values.coverage >= 15 { return .hide }
        return nil
    }

    private static func quantity(_ family: CreatureMaterialFamilyID, values: Values) -> Int {
        switch family {
        case .hide, .pelt, .down, .scale, .plate, .chitin, .shell, .quill:
            values.sizeBand
        case .feather, .fin: values.appendageQuantity
        case .fang, .claw, .tusk, .horn: values.armamentTotal >= 65 ? 2 : 1
        case .bone: min(3, max(1, 1 + Int(floor(values.size / 34))))
        case .oil: values.insulation >= 70 ? 2 : 1
        case .venom: values.toxinPotency >= 70 ? 2 : 1
        case .ichor: values.emanationStrength >= 70 ? 2 : 1
        }
    }

    private static func allowedQuantity(for family: CreatureMaterialFamilyID) -> ClosedRange<Int> {
        switch family {
        case .hide, .pelt, .down, .feather, .fin, .scale, .plate, .chitin, .shell, .quill: 1...4
        case .bone: 1...3
        case .fang, .claw, .oil, .tusk, .horn, .venom, .ichor: 1...2
        }
    }

    private static func roundHalfUp(_ value: Double) -> Int { Int(floor(value + 0.5)) }
    private static func clamp(_ value: Double) -> Double { min(100, max(0, value)) }

    private struct Values {
        let size, hardness, length, coverage, boneDensity: Double
        let armamentPierce, armamentCrush, armamentRend, armamentTotal: Double
        let insulation, flexibility, appendageExtent, finishLustre, armourValue: Double
        let finishSchiller, colorationPatterning, toxinPotency, emanationStrength: Double
        let sizeBand, appendageQuantity: Int

        var dominantArmament: DamageKind {
            if armamentPierce >= armamentCrush && armamentPierce >= armamentRend {
                return .pierce
            }
            if armamentCrush >= armamentRend { return .crush }
            return .rend
        }

        init(traits: CreatureTraits) {
            size = clamp(traits.size)
            hardness = clamp(traits.covering.hardness)
            length = clamp(traits.covering.length)
            coverage = clamp(traits.covering.coverage)
            boneDensity = clamp(traits.boneDensity)
            armamentPierce = clamp(traits.armament.pierce)
            armamentCrush = clamp(traits.armament.crush)
            armamentRend = clamp(traits.armament.rend)
            armamentTotal = armamentPierce + armamentCrush + armamentRend
            insulation = clamp(length * coverage / 100)
            flexibility = clamp((100 - hardness) * (0.5 + length / 200))
            appendageExtent = clamp(Double(traits.appendages.count) / 8 * 100)
            finishLustre = clamp(clamp(traits.finish.shine) + clamp(traits.finish.schiller))
            armourValue = clamp(hardness * coverage / 100)
            finishSchiller = clamp(traits.finish.schiller)
            colorationPatterning = clamp(traits.coloration.patterning)
            toxinPotency = traits.isToxic
                ? clamp(Double(roundHalfUp(0.70 * colorationPatterning + 0.30 * clamp(traits.ornament)))) : 0
            emanationStrength = clamp(traits.emanation?.strength ?? 0)
            sizeBand = min(4, max(1, 1 + Int(floor(size / 25))))
            let appendageBand = min(4, max(1, Int(ceil(Double(max(0, traits.appendages.count)) / 2))))
            appendageQuantity = min(4, max(1, roundHalfUp(
                0.5 * Double(sizeBand) + 0.5 * Double(appendageBand))))
        }

        subscript(id: CreatureMaterialCapabilityID) -> Double {
            switch id {
            case .coveringCoverage: coverage
            case .derivedFlexibility: flexibility
            case .derivedInsulation: insulation
            case .derivedAppendageExtent: appendageExtent
            case .derivedFinishLustre: finishLustre
            case .boneDensity: boneDensity
            case .size: size
            case .coveringHardness: hardness
            case .coveringLength: length
            case .armamentPierce: armamentPierce
            case .armamentRend: armamentRend
            case .derivedArmourValue: armourValue
            case .finishSchiller: finishSchiller
            case .armamentCrush: armamentCrush
            case .derivedToxinPotency: toxinPotency
            case .colorationPatterning: colorationPatterning
            case .emanationStrength: emanationStrength
            }
        }
    }
}
