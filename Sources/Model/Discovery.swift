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
    var creatures: [CreatureID: DiscoveryRecord] = [:]
    var resources: [ResourceID: DiscoveryRecord] = [:]
    /// Sites you've stood in. A site you've never met is silhouetted in the preview, same rule as
    /// creatures — you can be told a world *can* hold something without being told what.
    var sites: [SiteID: DiscoveryRecord] = [:]

    init(creatures: [CreatureID: DiscoveryRecord] = [:],
         resources: [ResourceID: DiscoveryRecord] = [:],
         sites: [SiteID: DiscoveryRecord] = [:]) {
        self.creatures = creatures
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
        resources = try container.decodeIfPresent([ResourceID: DiscoveryRecord].self, forKey: .resources) ?? [:]
        sites = try container.decodeIfPresent([SiteID: DiscoveryRecord].self, forKey: .sites) ?? [:]
    }

    // MARK: Queries (drive the silhouette/revealed UI)

    func hasEncountered(creature id: CreatureID) -> Bool { creatures[id]?.timesEncountered ?? 0 > 0 }
    func hasEncountered(resource id: ResourceID) -> Bool { resources[id]?.timesEncountered ?? 0 > 0 }

    var encounteredCreatureCount: Int { creatures.values.count(where: { $0.timesEncountered > 0 }) }
    var encounteredResourceCount: Int { resources.values.count(where: { $0.timesEncountered > 0 }) }

    // MARK: Mutations
    //
    // `runIndex` — not a date — stamps first sighting, so the log stays wall-clock-free (pillar 2).

    mutating func recordCreature(_ id: CreatureID, runIndex: Int) {
        creatures[id, default: DiscoveryRecord()].record(runIndex: runIndex)
    }

    mutating func recordSite(_ id: SiteID, runIndex: Int) {
        sites[id, default: DiscoveryRecord()].record(runIndex: runIndex)
    }

    mutating func recordResource(_ id: ResourceID, runIndex: Int) {
        resources[id, default: DiscoveryRecord()].record(runIndex: runIndex)
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
