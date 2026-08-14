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
    case recycler
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

    /// Routes whose destinations are authored by `stations.json`. Non-station navigation remains
    /// compiled-only and must not be mistaken for an orphaned catalogue destination.
    var isStationRoute: Bool {
        switch self {
        case .writingDesk, .storehouse, .workshop, .party, .essenceSpring, .constellation,
             .library, .bestiary, .blacksmith, .tradingPost, .recycler, .tannery, .bowyer,
             .armoury, .weaponsmith, .scriptorium, .surveyPost, .apothecary, .reliquary,
             .wayfarersTable, .anchorage, .distillery, .channelworks, .firepit:
            true
        case .base, .worldHistory, .world, .encounter, .settings, .harness:
            false
        }
    }
}
