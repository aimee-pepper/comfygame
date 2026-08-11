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
    case bestiary
    case blacksmith
    case tradingPost
    case tannery
    case bowyer
    case armoury
    case weaponsmith
    case worldHistory
    case scriptorium
    case surveyPost
    case apothecary
    case reliquary
    case wayfarersTable
    case anchorage
    case distillery
    case channelworks
    case firepit
    case world
    case encounter
    case settings
    /// The milestone-1 persistence harness. Reachable from the Base screen while in development.
    case harness
}
