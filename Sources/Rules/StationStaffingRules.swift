import Foundation

/// Shared station-local owner benefits. Assignment is derived from the existing three durable
/// places: active party, an anchored realm, or Home. A traveller owns at most one current station,
/// so being at Home unambiguously means being available to that building.
enum StationStaffingRules {
    static func keeperIndex(for station: StationDef, in state: GameState) -> Int? {
        guard let owner = station.builtBy else { return nil }
        return state.base.roster.firstIndex { $0.traveller == owner }
    }

    static func keeperIsHome(for station: StationDef, in state: GameState) -> Bool {
        guard let index = keeperIndex(for: station, in: state),
              let memberID = state.base.persistentID(forRosterIndex: index) else { return false }
        guard !state.base.activeParty.contains(memberID) else { return false }
        return !state.worlds.anchoredRealms.contains { $0.assignedCompanions.contains(memberID) }
    }

    static func keeperEarnedTier(for station: StationDef, in state: GameState) -> Int {
        guard let index = keeperIndex(for: station, in: state),
              state.base.roster.indices.contains(index) else { return 0 }
        let level = state.base.roster[index].character.level
        return station.keeperLevelForTier.filter { level >= $0 }.count
    }

    static func effectiveTier(for station: StationDef, in state: GameState) -> Int {
        min(station.maxTier,
            max(state.base.station(station.id).tier, keeperEarnedTier(for: station, in: state)))
    }

    static func homeDiscountRate(for station: StationDef, in state: GameState) -> Double {
        guard keeperIsHome(for: station, in: state),
              let index = keeperIndex(for: station, in: state) else { return 0 }
        let level = state.base.roster[index].character.level
        return min(station.homeDiscountCap,
                   station.homeDiscountBase
                    + Double(max(0, level - 1)) * station.homeDiscountPerKeeperLevel)
    }

    /// Positive costs round up and never become free. Zero remains zero.
    static func discounted(_ quantity: Int, at station: StationDef, in state: GameState) -> Int {
        guard quantity > 0 else { return 0 }
        let rate = homeDiscountRate(for: station, in: state)
        return max(1, Int((Double(quantity) * (1 - rate)).rounded(.up)))
    }
}
