import Foundation

extension WorldRules {
    struct TileInspection: Equatable, Sendable {
        var heading: String
        var details: [String]
        var text: String { ([heading] + details).joined(separator: " · ") }
    }

    /// Read-only adjacent inspection. This deliberately accepts the run by value and returns prose;
    /// unlike `step`, it cannot reveal, wake, collect, move, spend Stability or advance a turn.
    static func inspect(_ point: GridPoint, in run: WorldRun) -> TileInspection {
        guard run.map.contains(point) else {
            return TileInspection(heading: "World boundary", details: ["There is no tile there."])
        }
        let tile = run.map[point]
        guard tile.isRevealed else {
            return TileInspection(heading: "Unclear", details: ["You cannot make out that tile."])
        }

        var details: [String] = []
        if !tile.isPassable {
            details.append(tile.isCrumbled ? "nothing remains to stand on" : "impassable")
        } else {
            let turns = movementCost(tile.ground, slowGroundExtraTurns: run.tuning.slowGroundExtraTurns)
            details.append(turns == 1 ? "1 turn to enter" : "\(turns) turns to enter")
        }
        if tile.isCracking { details.append("cracks warn that it may crumble") }

        if let plant = run.plant(at: point) {
            let name = run.floraNames[plant.id]?.name ?? plant.displayName
            let harm = FloraRules.harm(of: plant.traits,
                                       severity: run.tuning.floraHazardSeverityMultiplier)
            if plant.traits.isDefended {
                switch plant.traits.defenceType {
                case .physical: details.append("\(name) has barbs that will hurt the party")
                case .chemical: details.append("\(name) is toxic and will linger")
                case .active: details.append("\(name) reacts when approached")
                }
            } else {
                if harm.isSomething { details.append("\(name) is known to be harmful") }
                else { details.append(name) }
            }
        }

        if let enemy = run.enemies.first(where: { $0.position == point && isVisible($0, in: run) }) {
            details.append("\(run.name(of: enemy)) is there")
        } else if let content = visibleContent(tile.content, in: run) {
            details.append(content)
        }
        return TileInspection(heading: tile.ground.displayName.capitalized, details: details)
    }

    private static func visibleContent(_ content: TileContent, in run: WorldRun) -> String? {
        switch content {
        case .empty: nil
        case .node(let node):
            "resource node: \(ContentCatalog.shared.resource(node.resource)?.name ?? "unknown material")"
        case .wildDrop(let resource, _):
            "loose \(ContentCatalog.shared.resource(resource)?.name.lowercased() ?? "resource")"
        case .hazard: "the ground is hazardous"
        case .portal: "portal"
        case .lockedCache: "locked cache"
        case .site(let id):
            run.sites.first(where: { $0.id == id }).flatMap { ContentCatalog.shared.site($0.siteID)?.name }
                .map { "site: \($0)" } ?? "site"
        case .diaryPage, .foundWriting: "writing"
        case .traveller(let id):
            ContentCatalog.shared.traveller(id).map { "traveller: \($0.name)" } ?? "traveller"
        }
    }
}
