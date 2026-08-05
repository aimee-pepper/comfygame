import Foundation

/// Which sites a world can host, and where they end up standing.
///
/// Separate from the pressure model on purpose (`docs/sites-system.md`): pressures shift
/// distributions, sites are discrete objects placed when conditions are met. Keeping the two apart
/// is what lets hand-authored content — a diary page, a rune, a named landmark — live inside a
/// procedural world without either half having to compromise.
///
/// Pure functions over (readings, map, rng), like `BookRules`. The preview and the generator call
/// the same eligibility test, so what the Writing Desk promises is what the world contains.
enum SiteRules {

    /// Every site whose conditions the world satisfies, most likely first.
    ///
    /// This is also what the preview reads, which is why it takes readings rather than a map: you
    /// can be told what *kind* of place you're writing toward before you commit to it.
    static func eligible(in readings: PressureReadings,
                         contradictions: [ContradictionDef] = []) -> [SiteDef] {
        ContentCatalog.shared.sites
            .filter { $0.isEligible(in: readings, contradictions: contradictions) }
            .sorted { ($0.weight, $1.id.rawValue) > ($1.weight, $0.id.rawValue) }
    }

    /// Choose and place the sites for one world.
    ///
    /// Draws without replacement against each site's cap, honouring exclusions, and stops at the
    /// per-world ceiling. A site that can't be legally placed is dropped rather than shoved
    /// somewhere invalid — a Crystal Cavern on the entry tile is worse than no cavern.
    static func place(in map: WorldMap,
                      readings: PressureReadings,
                      contradictions: [ContradictionDef] = [],
                      avoiding occupied: Set<GridPoint>,
                      rng: inout SeededRNG) -> [PlacedSite] {
        var candidates = eligible(in: readings, contradictions: contradictions)
        guard !candidates.isEmpty else { return [] }

        var placed: [PlacedSite] = []
        var taken = occupied
        var counts: [SiteID: Int] = [:]
        var excluded: Set<SiteID> = []

        let ceiling = rng.int(in: Tuning.Sites.perWorldCountRange)
        while placed.count < ceiling {
            let pool = candidates
                .filter { !excluded.contains($0.id) && (counts[$0.id] ?? 0) < $0.maximumPerWorld }
                .map { (value: $0, weight: $0.weight) }
            guard let site = rng.pickWeighted(pool) else { break }

            guard let point = position(for: site, in: map, avoiding: taken, rng: &rng) else {
                // Nowhere legal for it in this world; take it out of the running entirely rather
                // than spinning on it.
                candidates.removeAll { $0.id == site.id }
                continue
            }

            placed.append(PlacedSite(id: InstanceID(rawValue: rng.next()),
                                     siteID: site.id,
                                     position: point,
                                     searchTurnsRemaining: site.contents.searchTurns))
            taken.insert(point)
            counts[site.id, default: 0] += 1
            excluded.formUnion(site.excludes)
            // Exclusion is symmetric, so anything naming this site is out too.
            excluded.formUnion(candidates.filter { $0.excludes.contains(site.id) }.map(\.id))
        }
        return placed
    }

    /// A legal tile for a site, or nil if this world has none.
    private static func position(for site: SiteDef,
                                 in map: WorldMap,
                                 avoiding taken: Set<GridPoint>,
                                 rng: inout SeededRNG) -> GridPoint? {
        let free = map.allPoints.filter { point in
            !taken.contains(point) && map[point].content == .empty && !map[point].isCrumbled
        }
        var legal = free.filter { point in
            switch site.placement.rule {
            case .anywhere: true
            case .edge: map.ring(of: point) == 0
            case .interior: map.ring(of: point) > 0
            }
        }
        let distant = legal.filter {
            $0.chebyshevDistance(to: map.entry) >= site.placement.minimumDistanceFromEntry
        }
        // Distance is a preference, not a guarantee — a small map can make it unsatisfiable, and
        // dropping the site entirely would be a worse answer than placing it a little close.
        if !distant.isEmpty { legal = distant }
        return rng.pick(legal.sorted { ($0.y, $0.x) < ($1.y, $1.x) })
    }

    // MARK: Instability

    /// What the sites a world contains do to its Stability headline.
    ///
    /// This is the greed rule applied at the site layer: writing toward treasure destabilises,
    /// exactly as writing toward rich substrate does. Charged on what the world *actually got*, so
    /// it stays self-balancing as the catalog grows.
    static func stabilityDelta(of sites: [PlacedSite]) -> Int {
        sites.reduce(0) { $0 + ($1.definition?.stabilityDelta ?? 0) }
    }
}
