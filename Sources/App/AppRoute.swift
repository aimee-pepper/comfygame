import Foundation

/// Every screen the app can show.
///
/// Base stations are data (`Content/Data/stations.json`) and carry a `route` string that must
/// match one of these cases — `RoutingTests` proves that, so adding a station without a screen
/// fails the suite instead of dead-ending at runtime.
enum AppRoute: String, Codable, Hashable, CaseIterable, Sendable {
    case base
    case writingDesk
    case storehouse
    case workshop
    case party
    case essenceSpring
    case constellation
    case library
    case blacksmith
    case world
    case encounter
    case settings
    /// The milestone-1 persistence harness. Reachable from the Base screen while in development.
    case harness
}
