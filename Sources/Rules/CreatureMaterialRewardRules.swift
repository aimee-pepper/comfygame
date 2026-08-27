import Foundation

private struct CreatureRewardCodingKey: CodingKey, Hashable {
    var stringValue: String
    var intValue: Int? { nil }
    init(_ value: String) { stringValue = value }
    init?(stringValue: String) { self.stringValue = stringValue }
    init?(intValue: Int) { return nil }
}

private func requireCreatureRewardKeys(
    _ container: KeyedDecodingContainer<CreatureRewardCodingKey>, _ expected: Set<String>
) throws {
    guard Set(container.allKeys.map(\.stringValue)) == expected else {
        throw CocoaError(.coderInvalidValue)
    }
}

struct WorldSourceDangerReceiptV1: Codable, Equatable, Sendable {
    static let currentSchemaVersion = 1
    static let currentAuthorityID = "world-source-danger-v1"
    static let inputs = [20, 35, 50, 65, 80, 95]

    var schemaVersion: Int
    var authorityID: String
    var sourceBand: Int
    var qualityInput: Int

    init(sourceBand: Int) {
        let band = min(5, max(0, sourceBand))
        schemaVersion = Self.currentSchemaVersion
        authorityID = Self.currentAuthorityID
        self.sourceBand = band
        qualityInput = Self.inputs[band]
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CreatureRewardCodingKey.self)
        try requireCreatureRewardKeys(c, ["schemaVersion", "authorityID", "sourceBand", "qualityInput"])
        schemaVersion = try c.decode(Int.self, forKey: .init("schemaVersion"))
        authorityID = try c.decode(String.self, forKey: .init("authorityID"))
        sourceBand = try c.decode(Int.self, forKey: .init("sourceBand"))
        qualityInput = try c.decode(Int.self, forKey: .init("qualityInput"))
        try validate()
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CreatureRewardCodingKey.self)
        try c.encode(schemaVersion, forKey: .init("schemaVersion"))
        try c.encode(authorityID, forKey: .init("authorityID"))
        try c.encode(sourceBand, forKey: .init("sourceBand"))
        try c.encode(qualityInput, forKey: .init("qualityInput"))
    }

    func validate() throws {
        guard schemaVersion == Self.currentSchemaVersion,
              authorityID == Self.currentAuthorityID,
              Self.inputs.indices.contains(sourceBand),
              qualityInput == Self.inputs[sourceBand] else { throw CocoaError(.coderInvalidValue) }
    }

    static func freeze(book: BoundBook) -> Self {
        .init(sourceBand: BookRules.enemyTier(of: book) - 1)
    }
}

enum CreatureMaterialQualityBand: String, Codable, CaseIterable, Sendable {
    case rough, standard, fine, superior, exceptional, peerless
}

struct CreatureMaterialRewardEntryV1: Codable, Equatable, Sendable {
    var foeID: InstanceID
    var speciesID: InstanceID
    var family: CreatureMaterialFamilyID
    var partExpression: Int
    var quantity: Int
    var qualityScore: Int
    var qualityBand: CreatureMaterialQualityBand
    var reserveUnitIDs: [MaterialReserveUnitID]
    var sourceReceiptID: String

    init(foeID: InstanceID, speciesID: InstanceID, family: CreatureMaterialFamilyID,
         partExpression: Int, quantity: Int, qualityScore: Int,
         qualityBand: CreatureMaterialQualityBand,
         reserveUnitIDs: [MaterialReserveUnitID], sourceReceiptID: String) {
        self.foeID = foeID; self.speciesID = speciesID; self.family = family
        self.partExpression = partExpression; self.quantity = quantity
        self.qualityScore = qualityScore; self.qualityBand = qualityBand
        self.reserveUnitIDs = reserveUnitIDs; self.sourceReceiptID = sourceReceiptID
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CreatureRewardCodingKey.self)
        try requireCreatureRewardKeys(c, ["foeID", "speciesID", "family", "partExpression",
                                          "quantity", "qualityScore", "qualityBand",
                                          "reserveUnitIDs", "sourceReceiptID"])
        foeID = try c.decode(InstanceID.self, forKey: .init("foeID"))
        speciesID = try c.decode(InstanceID.self, forKey: .init("speciesID"))
        family = try c.decode(CreatureMaterialFamilyID.self, forKey: .init("family"))
        partExpression = try c.decode(Int.self, forKey: .init("partExpression"))
        quantity = try c.decode(Int.self, forKey: .init("quantity"))
        qualityScore = try c.decode(Int.self, forKey: .init("qualityScore"))
        qualityBand = try c.decode(CreatureMaterialQualityBand.self, forKey: .init("qualityBand"))
        reserveUnitIDs = try c.decode([MaterialReserveUnitID].self, forKey: .init("reserveUnitIDs"))
        sourceReceiptID = try c.decode(String.self, forKey: .init("sourceReceiptID"))
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CreatureRewardCodingKey.self)
        try c.encode(foeID, forKey: .init("foeID")); try c.encode(speciesID, forKey: .init("speciesID"))
        try c.encode(family, forKey: .init("family")); try c.encode(partExpression, forKey: .init("partExpression"))
        try c.encode(quantity, forKey: .init("quantity")); try c.encode(qualityScore, forKey: .init("qualityScore"))
        try c.encode(qualityBand, forKey: .init("qualityBand")); try c.encode(reserveUnitIDs, forKey: .init("reserveUnitIDs"))
        try c.encode(sourceReceiptID, forKey: .init("sourceReceiptID"))
    }

    func validate(sourceDanger: WorldSourceDangerReceiptV1) throws {
        guard (0...100).contains(partExpression), quantity > 0,
              reserveUnitIDs.count == quantity, Set(reserveUnitIDs).count == quantity,
              !sourceReceiptID.isEmpty else { throw CocoaError(.coderInvalidValue) }
        let expected = CreatureMaterialRewardRules.qualityScore(
            partExpression: partExpression, sourceQuality: sourceDanger.qualityInput)
        guard qualityScore == expected,
              qualityBand == CreatureMaterialRewardRules.qualityBand(score: expected)
        else { throw CocoaError(.coderInvalidValue) }
    }
}

struct CreatureMaterialRewardReceiptV1: Codable, Equatable, Sendable {
    static let currentSchemaVersion = 1
    static let currentAuthorityID = "creature-material-reward-v1"
    var schemaVersion = Self.currentSchemaVersion
    var authorityID = Self.currentAuthorityID
    var runIndex: Int
    var encounterID: InstanceID
    var sourceDanger: WorldSourceDangerReceiptV1
    var entries: [CreatureMaterialRewardEntryV1]

    init(runIndex: Int, encounterID: InstanceID, sourceDanger: WorldSourceDangerReceiptV1,
         entries: [CreatureMaterialRewardEntryV1]) {
        self.runIndex = runIndex
        self.encounterID = encounterID
        self.sourceDanger = sourceDanger
        self.entries = entries
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CreatureRewardCodingKey.self)
        try requireCreatureRewardKeys(c, ["schemaVersion", "authorityID", "runIndex",
                                          "encounterID", "sourceDanger", "entries"])
        schemaVersion = try c.decode(Int.self, forKey: .init("schemaVersion"))
        authorityID = try c.decode(String.self, forKey: .init("authorityID"))
        runIndex = try c.decode(Int.self, forKey: .init("runIndex"))
        encounterID = try c.decode(InstanceID.self, forKey: .init("encounterID"))
        sourceDanger = try c.decode(WorldSourceDangerReceiptV1.self, forKey: .init("sourceDanger"))
        entries = try c.decode([CreatureMaterialRewardEntryV1].self, forKey: .init("entries"))
        try validate()
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CreatureRewardCodingKey.self)
        try c.encode(schemaVersion, forKey: .init("schemaVersion"))
        try c.encode(authorityID, forKey: .init("authorityID"))
        try c.encode(runIndex, forKey: .init("runIndex"))
        try c.encode(encounterID, forKey: .init("encounterID"))
        try c.encode(sourceDanger, forKey: .init("sourceDanger"))
        try c.encode(entries, forKey: .init("entries"))
    }

    func validate() throws {
        try sourceDanger.validate()
        guard schemaVersion == Self.currentSchemaVersion,
              authorityID == Self.currentAuthorityID, runIndex >= 0 else {
            throw CocoaError(.coderInvalidValue)
        }
        var pairs = Set<String>(), unitIDs = Set<MaterialReserveUnitID>()
        for entry in entries {
            try entry.validate(sourceDanger: sourceDanger)
            guard pairs.insert("\(entry.foeID.rawValue):\(entry.family.rawValue)").inserted,
                  entry.reserveUnitIDs.allSatisfy({ unitIDs.insert($0).inserted }) else {
                throw CocoaError(.coderInvalidValue)
            }
        }
    }
}

enum CreatureMaterialRewardIneligibleCause: String, Codable, Equatable, Sendable {
    case noEligibleSpecimens
}

enum CreatureMaterialRewardResolutionV1: Codable, Equatable, Sendable {
    case pending
    case awarded(CreatureMaterialRewardReceiptV1)
    case ineligible(CreatureMaterialRewardIneligibleCause)
    case legacyResolved

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CreatureRewardCodingKey.self)
        let state = try c.decode(String.self, forKey: .init("state"))
        switch state {
        case "pending":
            try requireCreatureRewardKeys(c, ["state"]); self = .pending
        case "awarded":
            try requireCreatureRewardKeys(c, ["state", "receipt"])
            self = .awarded(try c.decode(CreatureMaterialRewardReceiptV1.self,
                                          forKey: .init("receipt")))
        case "ineligible":
            try requireCreatureRewardKeys(c, ["state", "cause"])
            self = .ineligible(try c.decode(CreatureMaterialRewardIneligibleCause.self,
                                             forKey: .init("cause")))
        case "legacyResolved":
            try requireCreatureRewardKeys(c, ["state"]); self = .legacyResolved
        default: throw CocoaError(.coderInvalidValue)
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CreatureRewardCodingKey.self)
        switch self {
        case .pending: try c.encode("pending", forKey: .init("state"))
        case .awarded(let receipt):
            try c.encode("awarded", forKey: .init("state"))
            try c.encode(receipt, forKey: .init("receipt"))
        case .ineligible(let cause):
            try c.encode("ineligible", forKey: .init("state"))
            try c.encode(cause, forKey: .init("cause"))
        case .legacyResolved: try c.encode("legacyResolved", forKey: .init("state"))
        }
    }
}

enum CreatureMaterialRewardEvaluation: Equatable, Sendable {
    case eligible(CreatureMaterialRewardReceiptV1, [MaterialReserveUnit])
    case noEligibleSpecimens
    case alreadyResolved(CreatureMaterialRewardResolutionV1)
    case staleEncounter, missingSourceDanger, invalidSourceDanger, missingSpeciesID
    case unknownSpecies, duplicateSpeciesIdentity, missingProjection, invalidProjection
    case projectionIdentityMismatch, duplicateFoe, invalidRewardReceipt, reserveIDExhausted
}

enum CreatureMaterialRewardRules {
    static func validatePersisted(run: WorldRun) throws {
        guard !run.creatureMaterialRewardReceipts.isEmpty
                || run.activeEncounter.map({
                    if case .awarded = $0.creatureMaterialRewardResolution { return true }
                    return false
                }) == true else { return }
        guard Set(run.cast.map(\.id)).count == run.cast.count else { throw CocoaError(.coderInvalidValue) }
        var receiptEncounters = Set<InstanceID>()
        for receipt in run.creatureMaterialRewardReceipts {
            try receipt.validate()
            guard receipt.runIndex == run.runIndex,
                  receiptEncounters.insert(receipt.encounterID).inserted else {
                throw CocoaError(.coderInvalidValue)
            }
            for entry in receipt.entries {
                guard let species = run.cast.first(where: { $0.id == entry.speciesID }),
                      let projection = species.materialProjection,
                      let frozen = projection.entries.first(where: { $0.family == entry.family }),
                      frozen.partExpression == entry.partExpression,
                      frozen.quantityPerDefeatedSpecimen == entry.quantity else {
                    throw CocoaError(.coderInvalidValue)
                }
            }
        }
        if let encounter = run.activeEncounter,
           case .awarded(let receipt) = encounter.creatureMaterialRewardResolution {
            guard receipt.encounterID == encounter.id,
                  run.creatureMaterialRewardReceipts.contains(receipt) else {
                throw CocoaError(.coderInvalidValue)
            }
        }
    }

    static func qualityScore(partExpression: Int, sourceQuality: Int) -> Int {
        min(100, max(0, (3 * partExpression + sourceQuality + 2) / 4))
    }

    static func qualityBand(score: Int) -> CreatureMaterialQualityBand {
        switch score {
        case ...24: .rough
        case 25...54: .standard
        case 55...74: .fine
        case 75...89: .superior
        case 90...97: .exceptional
        default: .peerless
        }
    }

    static func evaluate(run: WorldRun, encounter: EncounterState) -> CreatureMaterialRewardEvaluation {
        guard case .pending = encounter.creatureMaterialRewardResolution else {
            return .alreadyResolved(encounter.creatureMaterialRewardResolution)
        }
        guard Set(encounter.foes.map(\.id)).count == encounter.foes.count else { return .duplicateFoe }
        guard Set(run.cast.map(\.id)).count == run.cast.count else { return .duplicateSpeciesIdentity }
        guard let danger = run.sourceDangerReceipt else { return .missingSourceDanger }
        do { try danger.validate() } catch { return .invalidSourceDanger }

        var entries: [CreatureMaterialRewardEntryV1] = []
        var units: [MaterialReserveUnit] = []
        var allocated = Set(run.materialReserve.units.map(\.id))
        for foe in encounter.foes where !foe.isAlive {
            guard let speciesID = foe.speciesID else { continue }
            guard let species = run.cast.first(where: { $0.id == speciesID }) else { return .unknownSpecies }
            guard let projection = species.materialProjection else { continue }
            do { try CreatureMaterialProjectionRules.validate(projection) }
            catch { return .invalidProjection }
            for projected in projection.entries {
                let score = qualityScore(partExpression: projected.partExpression,
                                         sourceQuality: danger.qualityInput)
                let source = "run:\(run.runIndex):encounter:\(encounter.id.rawValue):foe:\(foe.id.rawValue):family:\(projected.family.rawValue)"
                let ids = (0..<projected.quantityPerDefeatedSpecimen).map {
                    MaterialReserveUnitID(rawValue: "creature-material:\(source):\($0)")
                }
                guard ids.allSatisfy({ allocated.insert($0).inserted }) else {
                    return .reserveIDExhausted
                }
                let sample = sample(for: projected, foe: foe, species: species, score: score)
                units += ids.map { .init(id: $0, sample: sample) }
                entries.append(.init(foeID: foe.id, speciesID: speciesID,
                                     family: projected.family,
                                     partExpression: projected.partExpression,
                                     quantity: projected.quantityPerDefeatedSpecimen,
                                     qualityScore: score, qualityBand: qualityBand(score: score),
                                     reserveUnitIDs: ids, sourceReceiptID: source))
            }
        }
        guard !entries.isEmpty else { return .noEligibleSpecimens }
        return .eligible(.init(runIndex: run.runIndex, encounterID: encounter.id,
                               sourceDanger: danger, entries: entries), units)
    }

    private static func sample(for entry: CreatureMaterialProjectionEntryV1, foe: FoeState,
                               species: Species, score: Int) -> MaterialSample {
        let a = entry.capabilityA.value, b = entry.capabilityB.value
        let properties = MaterialProperties(
            hardness: entry.capabilityA.id == .coveringHardness ? a : (entry.capabilityB.id == .coveringHardness ? b : 0),
            density: entry.family == .bone ? a : 0,
            insulation: entry.capabilityA.id == .derivedInsulation ? a : (entry.capabilityB.id == .derivedInsulation ? b : 0),
            flexibility: entry.capabilityA.id == .derivedFlexibility ? a : (entry.capabilityB.id == .derivedFlexibility ? b : 0),
            lustre: entry.capabilityA.id == .derivedFinishLustre ? a : (entry.capabilityB.id == .derivedFinishLustre ? b : 0),
            reactivity: entry.family == .venom || entry.family == .ichor ? max(a, b) : 0)
        return .init(kind: MaterialKind(entry.family), properties: properties, grade: Double(score),
                     source: foe.stats.displayName, qualifier: foe.qualifier)
    }
}
