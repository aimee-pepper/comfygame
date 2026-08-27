import Foundation

struct SeamlightGuidanceReceiptV1: Codable, Equatable, Sendable {
    static let currentVersion = 1
    var version: Int
    var sourceItemID: ItemID
    var sourceItemInstanceID: InstanceID
    var activatedOnTurn: Int

    func validates(for runTurns: Int) -> Bool {
        version == Self.currentVersion && sourceItemID == Items.seamlight
            && activatedOnTurn >= 0 && activatedOnTurn <= runTurns
    }
}

enum SeamlightUseRefusal: Error, Equatable, Sendable {
    case alreadyActive, noReachablePortal, encounterActive, itemUnavailable, noActiveExpedition
}

struct SeamlightUseQuoteV1: Equatable, Sendable {
    var runIndex: Int
    var sourceItemInstanceID: InstanceID
    var evaluatedAtTurn: Int
}

enum SeamlightUseResult: Equatable, Sendable {
    case activated(SeamlightGuidanceReceiptV1, events: [WorldRules.Event])
    case refused(SeamlightUseRefusal)
}

enum SeamlightDistanceBand: String, Codable, Sendable { case far, near }
enum CardinalDirection: String, Codable, Sendable { case north, east, south, west }
enum SeamlightGuidanceProjection: Equatable, Sendable {
    case directional(CardinalDirection, SeamlightDistanceBand)
    case onPortal
}

enum SeamlightRules {
    static func playerCopy(for refusal: SeamlightUseRefusal) -> String {
        switch refusal {
        case .alreadyActive: "A Seamlight is already guiding this expedition."
        case .noReachablePortal: "No portal seam answers the light."
        case .encounterActive: "Finish the encounter first."
        case .itemUnavailable: "That Seamlight is no longer in the Field Kit."
        case .noActiveExpedition: "There is no active world to guide."
        }
    }

    static func evaluate(sourceItemInstanceID: InstanceID, in state: GameState)
        -> Result<SeamlightUseQuoteV1, SeamlightUseRefusal> {
        guard let run = state.worlds.activeRun else { return .failure(.noActiveExpedition) }
        guard run.activeEncounter == nil else { return .failure(.encounterActive) }
        guard run.seamlightGuidance == nil else { return .failure(.alreadyActive) }
        guard validStack(sourceItemInstanceID, in: run) else { return .failure(.itemUnavailable) }
        guard route(in: run) != nil else { return .failure(.noReachablePortal) }
        return .success(.init(runIndex: run.runIndex,
                              sourceItemInstanceID: sourceItemInstanceID,
                              evaluatedAtTurn: run.turnsTaken))
    }

    static func commit(_ quote: SeamlightUseQuoteV1, in state: inout GameState)
        -> SeamlightUseResult {
        var candidate = state
        guard let run = candidate.worlds.activeRun else { return .refused(.noActiveExpedition) }
        guard run.runIndex == quote.runIndex, run.turnsTaken == quote.evaluatedAtTurn else {
            return .refused(.itemUnavailable)
        }
        switch evaluate(sourceItemInstanceID: quote.sourceItemInstanceID, in: candidate) {
        case .failure(let refusal): return .refused(refusal)
        case .success: break
        }
        guard var updated = candidate.worlds.activeRun,
              let index = updated.satchelItems.stacks.firstIndex(where: {
                  $0.id == quote.sourceItemInstanceID
              }) else { return .refused(.itemUnavailable) }
        let receipt = SeamlightGuidanceReceiptV1(
            version: 1, sourceItemID: Items.seamlight,
            sourceItemInstanceID: quote.sourceItemInstanceID,
            activatedOnTurn: updated.turnsTaken)
        _ = updated.satchelItems.stacks[index].removing(1)
        if updated.satchelItems.stacks[index].isEmpty {
            updated.satchelItems.stacks.remove(at: index)
        }
        updated.seamlightGuidance = receipt
        candidate.worlds.activeRun = updated
        var events: [WorldRules.Event] = [.seamlightActivated]
        events.append(contentsOf: WorldRules.advanceTurn(in: &candidate))
        state = candidate
        return .activated(receipt, events: events)
    }

    static func projection(in run: WorldRun) -> SeamlightGuidanceProjection? {
        guard run.seamlightGuidance?.validates(for: run.turnsTaken) == true,
              let points = route(in: run) else { return nil }
        guard points.count > 1 else { return .onPortal }
        let from = points[0], to = points[1]
        let direction: CardinalDirection
        if to.y < from.y { direction = .north }
        else if to.x > from.x { direction = .east }
        else if to.y > from.y { direction = .south }
        else { direction = .west }
        return .directional(direction, points.count == 2 ? .near : .far)
    }

    static func route(in run: WorldRun) -> [GridPoint]? {
        let start = run.playerPosition
        guard run.map.contains(start) else { return nil }
        var queue = [start]
        var cursor = 0
        var parent: [GridPoint: GridPoint] = [:]
        var seen: Set<GridPoint> = [start]
        while cursor < queue.count {
            let point = queue[cursor]; cursor += 1
            if eligiblePortal(point, in: run.map) {
                var path = [point]
                var current = point
                while let previous = parent[current] { path.append(previous); current = previous }
                return path.reversed()
            }
            let next = run.map.neighbours(of: point)
                .filter { WorldRules.canEnter($0, in: run.map) && !seen.contains($0) }
                .sorted { run.map.index(of: $0) < run.map.index(of: $1) }
            for neighbor in next { seen.insert(neighbor); parent[neighbor] = point; queue.append(neighbor) }
        }
        return nil
    }

    private static func eligiblePortal(_ point: GridPoint, in map: WorldMap) -> Bool {
        map.contains(point) && !map[point].isCrumbled && map[point].content.isPortal
            && WorldRules.canEnter(point, in: map)
    }

    private static func validStack(_ id: InstanceID, in run: WorldRun) -> Bool {
        guard let stack = run.satchelItems.stacks.first(where: { $0.id == id }),
              stack.count > 0, stack.identified, stack.catalogID == Items.seamlight,
              let item = ContentCatalog.shared.item(stack.catalogID) else { return false }
        return item.consumable?.effect == .seamlightGuidance
    }
}
