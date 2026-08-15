import Foundation

extension WorldRules {
    struct TileInspection: Equatable, Sendable {
        var heading: String
        var details: [String]
        var text: String { ([heading] + details).joined(separator: " · ") }
    }

    /// Read-only adjacent inspection. This deliberately accepts the run by value and returns prose;
    /// unlike `step`, it cannot reveal, wake, collect, move, spend Stability or advance a turn.
    static func inspect(_ point: GridPoint, in run: WorldRun,
                        base: BaseState? = nil) -> TileInspection {
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
            let total = turns == 1 ? "1 turn to enter" : "\(turns) turns to enter"
            let extra = max(0, turns - 1)
            details.append(extra == 0 ? total : "\(total) · \(extra) extra")
        }
        if tile.isCracking { details.append("cracks warn that it may crumble") }

        if let plant = run.plant(at: point) {
            details.append(floraAppearanceLabel(plant.traits))
            let harm = FloraRules.harm(of: plant.traits,
                                       severity: run.tuning.floraHazardSeverityMultiplier)
            if plant.traits.isDefended {
                details.append(floraEntryWarning(plant.traits.defenceType))
            } else if harm.isSomething {
                details.append("Entering may be harmful")
            }
            if base?.station(Stations.wayfarersTable).isUnlocked == true {
                details.append(floraFieldNote(for: plant, in: run))
            }
        }

        if let enemy = run.enemies.first(where: { $0.position == point && isVisible($0, in: run) }) {
            if !enemy.isSessile { details.append("\(run.name(of: enemy)) is there") }
        } else if let content = visibleContent(tile.content, in: run) {
            details.append(content)
        }
        return TileInspection(heading: tile.ground.displayName.capitalized, details: details)
    }

    static func floraEntryWarning(_ defence: DefenceType) -> String {
        switch defence {
        case .physical: "Entering will hurt the party"
        case .chemical: "Entering carries a lingering hazard"
        case .active: "Entering will start an encounter"
        }
    }

    static func floraAppearanceLabel(_ traits: FloraTraits) -> String {
        guard traits.isDefended else { return "Visible growth" }
        return switch traits.defenceType {
        case .physical: "Thorn growth"
        case .chemical: "Visible growth"
        case .active: "Coiled growth"
        }
    }

    static func floraFieldNote(for plant: Flora, in run: WorldRun) -> String {
        let name = run.floraNames[plant.id]?.name ?? plant.displayName
        let family: String = if !plant.traits.isDefended {
            "unguarded"
        } else {
            switch plant.traits.defenceType {
            case .physical: "barbed"
            case .chemical: "chemical"
            case .active: "active"
            }
        }
        let resource = FloraRules.yield(of: plant.traits)
        let yieldName = ContentCatalog.shared.resource(resource)?.name ?? resource.rawValue.capitalized
        return "Sela's field note · \(name) · \(family) · yields \(yieldName)"
    }

    private static func visibleContent(_ content: TileContent, in run: WorldRun) -> String? {
        switch content {
        case .empty: nil
        case .node(let node):
            "resource node: \(ContentCatalog.shared.resource(node.resource)?.name ?? "unknown material")"
        case .wildDrop(let resource, _):
            "loose \(ContentCatalog.shared.resource(resource)?.name.lowercased() ?? "resource")"
        case .item(let stack):
            "known find: \(ContentCatalog.shared.item(stack.catalogID)?.name ?? "item")"
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
