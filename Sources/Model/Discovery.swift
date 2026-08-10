import Foundation

/// The encounter-flag registry: what the player has ever seen.
///
/// Required from milestone 1 (design brief, build-order note 7) because the pre-bind preview's
/// silhouette-vs-revealed spawn icons read from it: never encountered → silhouette; encountered
/// → real icon + likelihood + expected ratio.
///
/// It lives in the **Reality** layer — knowledge, like a Pokédex, should be the thing a reset
/// never takes back. PLACEHOLDER: which layer owns the bestiary is not in the decisions log;
/// logged in docs/questions-for-design.md (Q1). If the answer is "base", move the two properties
/// to `BaseState` — nothing else needs to change.
struct DiscoveryLog: Codable, Equatable, Sendable {
    /// Authored creatures. **Legacy** — kept so a save from before worlds grew their own animals
    /// doesn't lose what it had recorded.
    var creatures: [CreatureID: DiscoveryRecord] = [:]
    /// **The bestiary's first tier: identities are entries** (session 15 §1, spec §6). Keyed by the
    /// derived identity, so two similar ambushers from different worlds are one entry.
    var species: [String: DiscoveryRecord] = [:]
    /// **The second tier: specimens.** One record per animal actually met, which is where personal
    /// bests and "the largest you've seen" come from. Capped, because this is the only collection in
    /// the save that grows without bound.
    var specimens: [SpecimenRecord] = []
    /// Apexes remain their derived species, but their exceptional sightings are collected too.
    var apexSightings: [ApexSighting] = []
    var resources: [ResourceID: DiscoveryRecord] = [:]
    /// Sites you've stood in. A site you've never met is silhouetted in the preview, same rule as
    /// creatures — you can be told a world *can* hold something without being told what.
    var sites: [SiteID: DiscoveryRecord] = [:]

    init(creatures: [CreatureID: DiscoveryRecord] = [:],
         species: [String: DiscoveryRecord] = [:],
         specimens: [SpecimenRecord] = [],
         apexSightings: [ApexSighting] = [],
         resources: [ResourceID: DiscoveryRecord] = [:],
         sites: [SiteID: DiscoveryRecord] = [:]) {
        self.creatures = creatures
        self.species = species
        self.specimens = specimens
        self.apexSightings = apexSightings
        self.resources = resources
        self.sites = sites
    }

    /// Tolerant decoding, per the policy in `Migrations.swift`.
    ///
    /// This one has teeth: adding `sites` with synthesised `Codable` quarantined a real save on a
    /// real device, because a save written before the field existed has no `sites` key and
    /// synthesised decoding *throws* rather than defaulting. Every field here decodes optionally,
    /// and every field added here must too.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        creatures = try container.decodeIfPresent([CreatureID: DiscoveryRecord].self, forKey: .creatures) ?? [:]
        species = try container.decodeIfPresent([String: DiscoveryRecord].self, forKey: .species) ?? [:]
        specimens = try container.decodeIfPresent([SpecimenRecord].self, forKey: .specimens) ?? []
        apexSightings = try container.decodeIfPresent([ApexSighting].self,
                                                       forKey: .apexSightings) ?? []
        resources = try container.decodeIfPresent([ResourceID: DiscoveryRecord].self, forKey: .resources) ?? [:]
        sites = try container.decodeIfPresent([SiteID: DiscoveryRecord].self, forKey: .sites) ?? [:]
    }

    // MARK: Queries (drive the silhouette/revealed UI)

    func hasEncountered(creature id: CreatureID) -> Bool { creatures[id]?.timesEncountered ?? 0 > 0 }
    func hasEncountered(resource id: ResourceID) -> Bool { resources[id]?.timesEncountered ?? 0 > 0 }
    func hasEncountered(species key: String) -> Bool { species[key]?.timesEncountered ?? 0 > 0 }

    var encounteredCreatureCount: Int {
        creatures.values.count(where: { $0.timesEncountered > 0 })
            + species.values.count(where: { $0.timesEncountered > 0 })
    }
    var encounteredResourceCount: Int { resources.values.count(where: { $0.timesEncountered > 0 }) }

    /// Every specimen you've recorded of one identity, newest last.
    func specimens(of key: String) -> [SpecimenRecord] { specimens.filter { $0.identityKey == key } }
    func apexSightings(of key: String) -> [ApexSighting] {
        apexSightings.filter { $0.identityKey == key }
    }

    /// Where this animal sits against every other one of its kind you've met, 0–1. The percentile
    /// the bestiary's second tier exists for.
    func percentile(of specimen: SpecimenRecord, by measure: (SpecimenRecord) -> Double) -> Double {
        let peers = specimens(of: specimen.identityKey)
        guard peers.count > 1 else { return 1 }
        let value = measure(specimen)
        let below = peers.count(where: { measure($0) < value })
        return Double(below) / Double(peers.count - 1)
    }

    // MARK: Mutations
    //
    // `runIndex` — not a date — stamps first sighting, so the log stays wall-clock-free (pillar 2).

    mutating func recordCreature(_ id: CreatureID, runIndex: Int) {
        creatures[id, default: DiscoveryRecord()].record(runIndex: runIndex)
    }

    /// A bestiary *entry* — that this kind of animal exists and you've met one.
    mutating func recordSpecies(_ key: String, runIndex: Int) {
        species[key, default: DiscoveryRecord()].record(runIndex: runIndex)
    }

    /// A bestiary *specimen* — this particular animal, kept so the entry can say how this one
    /// compared. Oldest are dropped first: an unbounded list in a save that's rewritten after every
    /// action is a slow leak, and the percentile only needs a population, not a complete history.
    mutating func recordSpecimen(_ traits: CreatureTraits, of key: String, runIndex: Int) {
        specimens.append(SpecimenRecord(identityKey: key, traits: traits, runIndex: runIndex))
        let cap = Tuning.Discovery.specimensKeptPerIdentity * max(1, species.count)
        if specimens.count > cap { specimens.removeFirst(specimens.count - cap) }
    }

    mutating func recordApex(_ id: InstanceID, species key: String, runIndex: Int) {
        guard !apexSightings.contains(where: { $0.id == id && $0.runIndex == runIndex }) else { return }
        apexSightings.append(ApexSighting(id: id, identityKey: key, runIndex: runIndex))
    }

    mutating func recordSite(_ id: SiteID, runIndex: Int) {
        sites[id, default: DiscoveryRecord()].record(runIndex: runIndex)
    }

    mutating func recordResource(_ id: ResourceID, runIndex: Int) {
        resources[id, default: DiscoveryRecord()].record(runIndex: runIndex)
    }
}

struct ApexSighting: Codable, Equatable, Identifiable, Sendable {
    var id: InstanceID
    var identityKey: String
    var runIndex: Int
}

/// One animal you actually met. **The bestiary's second tier** — the entry is what it was, this is
/// which one it was.
struct SpecimenRecord: Codable, Equatable, Sendable {
    var identityKey: String
    var traits: CreatureTraits
    /// Which run you met it in. A run count, never a date (pillar 2).
    var runIndex: Int

    init(identityKey: String, traits: CreatureTraits, runIndex: Int) {
        self.identityKey = identityKey
        self.traits = traits
        self.runIndex = runIndex
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        identityKey = try c.decodeIfPresent(String.self, forKey: .identityKey) ?? "unknown"
        traits = try c.decodeIfPresent(CreatureTraits.self, forKey: .traits) ?? CreatureTraits()
        runIndex = try c.decodeIfPresent(Int.self, forKey: .runIndex) ?? 0
    }
}

struct DiscoveryRecord: Codable, Equatable, Sendable {
    /// The run in which this was first seen. `nil` = never seen (record exists but is empty).
    var firstSeenRunIndex: Int?
    var timesEncountered: Int = 0

    init(firstSeenRunIndex: Int? = nil, timesEncountered: Int = 0) {
        self.firstSeenRunIndex = firstSeenRunIndex
        self.timesEncountered = timesEncountered
    }

    mutating func record(runIndex: Int) {
        if firstSeenRunIndex == nil { firstSeenRunIndex = runIndex }
        timesEncountered += 1
    }
}
