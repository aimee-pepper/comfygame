import Foundation
import SwiftUI
import OSLog
import CryptoKit

struct WorldFieldContextReceiptV1: Equatable, Sendable {
    enum ContentSummary: Equatable, Sendable {
        case none
        case node(name: String)
        case item(name: String)
        case genericHazard
        case portal
        case lockedCache
        case site(name: String)
        case writing
        case traveller(name: String)
    }

    enum Interaction: String, Equatable, Sendable {
        case none, harvest, searchSite, enterPortal, openCache, takePage, survey, useAnchor, placeAnchor
    }

    enum InteractionState: Equatable, Sendable {
        case available
        case unavailable(reason: String)
    }

    let worldRunID: String
    let position: GridPoint
    let groundID: GroundType
    let groundName: String
    let elevation: Int
    let surfaceDeposits: SurfaceDeposits
    let stabilitySurfaceState: String
    let floraStableID: InstanceID?
    let floraDisplayName: String?
    let contentSummary: ContentSummary
    let interaction: Interaction
    let interactionState: InteractionState
    let inputStateHash: String

    static func make(from state: GameState) -> Self? {
        guard let run = state.worlds.activeRun, run.map.contains(run.playerPosition) else { return nil }
        let tile = run.map[run.playerPosition]
        let content: ContentSummary
        let interaction: Interaction
        let interactionState: InteractionState
        let encounterBlocksInteraction = run.activeEncounter != nil
        let offeredPages = run.offeredWorldPages.filter {
            $0.fieldProvenance?.position == run.playerPosition
        }
        if offeredPages.count == 1, offeredPages.first != nil {
            content = .writing
            interaction = .takePage
            interactionState = encounterBlocksInteraction
                ? .unavailable(reason: "Finish the encounter first.")
                : .available
        } else { switch tile.content {
        case .empty:
            content = .none
            let frame = run.satchelItems.stacks.first { $0.catalogID == Items.anchorFrame && $0.count > 0 }
            let canPlace = !encounterBlocksInteraction && frame != nil
                && state.base.station(Stations.anchorage).isUnlocked
                && !state.worlds.anchoredRealms.contains { $0.runIndex == run.runIndex }
                && !tile.isCrumbled
            if canPlace {
                interaction = .placeAnchor
                interactionState = .available
            } else if !run.carriedInstruments.isEmpty && !encounterBlocksInteraction {
                interaction = .survey
                interactionState = .available
            } else {
                interaction = .none
                interactionState = .unavailable(reason: encounterBlocksInteraction
                    ? "Finish the encounter first." : "Nothing to use here.")
            }
        case .node(let node):
            content = .node(name: ContentCatalog.shared.resource(node.resource)?.name ?? "Unknown resource")
            interaction = .harvest
            interactionState = encounterBlocksInteraction ? .unavailable(reason: "Finish the encounter first.")
                : node.isExhausted ? .unavailable(reason: "This resource is depleted.") : .available
        case .wildDrop(let resource, _):
            content = .item(name: ContentCatalog.shared.resource(resource)?.name ?? "Unknown resource")
            interaction = .none
            interactionState = .unavailable(reason: "Step here to collect it.")
        case .item(let item):
            content = .item(name: item.displayName)
            interaction = .none
            interactionState = .unavailable(reason: "Step here to collect it.")
        case .hazard:
            content = .genericHazard
            interaction = .none
            interactionState = .unavailable(reason: "This ground is dangerous.")
        case .portal:
            content = .portal
            interaction = .enterPortal
            interactionState = encounterBlocksInteraction
                ? .unavailable(reason: "Finish the encounter first.") : .available
        case .lockedCache:
            content = .lockedCache
            interaction = .openCache
            let hasKey = state.base.inventory.stacks.contains {
                $0.identified && ContentCatalog.shared.item($0.catalogID)?.kind == .key
            }
            interactionState = encounterBlocksInteraction ? .unavailable(reason: "Finish the encounter first.")
                : hasKey ? .available : .unavailable(reason: "A key is required.")
        case .site(let id):
            let site = run.sites.first { $0.id == id }
            content = .site(name: site?.definition?.name ?? "Unknown site")
            let isNaturalAnchor = site?.definition?.providesNaturalAnchor == true
            interaction = isNaturalAnchor ? .useAnchor : .searchSite
            let guarded = run.enemies.contains { $0.position == run.playerPosition }
            let premium = GameStore.bornAnchoredPremium(forBookCost: run.book.essencePaid)
            let anchorCost = max(Tuning.Anchoring.naturalAnchorMinimumCost,
                (premium + Tuning.Anchoring.naturalAnchorPremiumDivisor - 1)
                    / Tuning.Anchoring.naturalAnchorPremiumDivisor)
            if encounterBlocksInteraction || guarded {
                interactionState = .unavailable(reason: "Not while something is standing over you.")
            } else if isNaturalAnchor && !state.base.station(Stations.anchorage).isUnlocked {
                interactionState = .unavailable(reason: "Unlock the Anchorage first.")
            } else if isNaturalAnchor && state.base.essence < anchorCost {
                interactionState = .unavailable(reason: "You need \(anchorCost) essence.")
            } else if isNaturalAnchor && state.worlds.anchoredRealms.contains(where: { $0.runIndex == run.runIndex }) {
                interactionState = .unavailable(reason: "This world is already anchored.")
            } else if !isNaturalAnchor && site?.isLooted == true {
                interactionState = .unavailable(reason: "Nothing remains here.")
            } else {
                interactionState = .available
            }
        case .diaryPage, .foundWriting:
            content = .writing
            interaction = .takePage
            interactionState = encounterBlocksInteraction
                ? .unavailable(reason: "Finish the encounter first.") : .available
        case .traveller(let id):
            content = .traveller(name: ContentCatalog.shared.traveller(id)?.name ?? "Unknown traveller")
            interaction = .none
            interactionState = .unavailable(reason: "Speak with this traveller.")
        }}
        let floraName = tile.flora.flatMap { run.floraNames[$0]?.name }
        let payload = Self.canonicalFields([
            "world=\(run.runIndex):\(run.mapSeed)", "x=\(run.playerPosition.x)",
            "y=\(run.playerPosition.y)", "ground=\(tile.ground.rawValue)",
            "elevation=\(tile.elevation)", "snow=\(tile.surfaceDeposits.snow)",
            "settledAsh=\(tile.surfaceDeposits.settledAsh)", "cracking=\(tile.isCracking)",
            "floraID=\(tile.flora?.description ?? "none")", "floraName=\(floraName ?? "none")",
            "content=\(canonicalContent(content, tile: tile, offeredPage: offeredPages.first))",
            "interaction=\(interaction.rawValue)",
            "state=\(canonicalInteractionState(interactionState))",
        ])
        return Self(
            worldRunID: "\(run.runIndex):\(run.mapSeed)", position: run.playerPosition,
            groundID: tile.ground, groundName: tile.ground.displayName.capitalized,
            elevation: tile.elevation, surfaceDeposits: tile.surfaceDeposits,
            stabilitySurfaceState: tile.isCracking ? "cracking" : "ordinary",
            floraStableID: tile.flora, floraDisplayName: floraName,
            contentSummary: content, interaction: interaction,
            interactionState: interactionState, inputStateHash: Self.sha256(payload))
    }

    private static func sha256(_ value: String) -> String {
        SHA256.hash(data: Data(value.utf8)).map { String(format: "%02x", $0) }.joined()
    }

    private static func canonicalFields(_ fields: [String]) -> String {
        fields.map { "\($0.utf8.count):\($0)" }.joined()
    }

    private static func canonicalContent(_ summary: ContentSummary, tile: Tile,
                                         offeredPage: WorldPageInstance?) -> String {
        func fields(_ values: [String]) -> String { canonicalFields(values) }
        switch summary {
        case .none: return fields(["none"])
        case .node(let name):
            let id = if case .node(let node) = tile.content { node.resource.rawValue } else { "unknown" }
            return fields(["node", id, name])
        case .item(let name):
            let id: String = switch tile.content {
            case .item(let item): item.catalogID.rawValue
            case .wildDrop(let resource, _): resource.rawValue
            default: "unknown"
            }
            return fields(["item", id, name])
        case .genericHazard: return fields(["genericHazard"])
        case .portal: return fields(["portal"])
        case .lockedCache: return fields(["lockedCache"])
        case .site(let name):
            let id = if case .site(let siteID) = tile.content { siteID.description } else { "unknown" }
            return fields(["site", id, name])
        case .writing:
            let id: String = if let offeredPage { offeredPage.id.description } else {
                switch tile.content {
                case .diaryPage(let page): page.rawValue
                case .foundWriting(let writing): writing.rawValue
                default: "unknown"
                }
            }
            return fields(["writing", id])
        case .traveller(let name):
            let id = if case .traveller(let travellerID) = tile.content {
                travellerID.rawValue
            } else { "unknown" }
            return fields(["traveller", id, name])
        }
    }

    private static func canonicalInteractionState(_ state: InteractionState) -> String {
        switch state {
        case .available: canonicalFields(["available"])
        case .unavailable(let reason): canonicalFields(["unavailable", reason])
        }
    }
}

struct WorldFieldEventBatchV1: Equatable {
    enum SourceAction: String, Equatable, Sendable {
        case step, travel, harvest, searchSite, interact, useItem, survey, otherWorldAction
    }

    let batchID: String
    let worldRunID: String
    let attemptID: UInt64
    let sourceAction: SourceAction
    let turnBefore: Int
    let turnAfter: Int
    let orderedEvents: [WorldRules.Event]
    let orderedNarrations: [String]
    let createdAtMonotonicTime: UInt64
}

enum WorldFieldNarration {
    static func text(for event: WorldRules.Event) -> String? {
        return switch event {
        case .moved, .encounterBegan: nil
        case .enteredSlowGround(let ground): "Crossing \(ground) took an extra turn."
        case .blocked(let why): why
        case .pickedUp(let resource, let amount):
            "Picked up \(amount) \(ContentCatalog.shared.resource(resource)?.name.lowercased() ?? "something")."
        case .harvested(let resource, let amount, let exhausted):
            "Harvested \(amount) \(ContentCatalog.shared.resource(resource)?.name.lowercased() ?? "something")."
                + (exhausted ? " This deposit is depleted." : "")
        case .foundPortal: "A way out."
        case .foundCache: "A cache, locked. The key is somewhere else."
        case .cacheOpened(let what): "The lock gives. \(what)"
        case .readPage(let id):
            ContentCatalog.shared.diaryPage(id).map { "A page, in somebody's hand. \"\($0.prose)\"" }
                ?? "A page from someone's diary."
        case .readFoundWriting(_, let prose): "A weathered field note. \"\(prose)\""
        case .foundTraveller(let id):
            ContentCatalog.shared.traveller(id).map { "\($0.name) is coming with you." }
                ?? "They're coming with you."
        case .usedItem(let what, let member):
            "\(what). \(member == .binder ? "You feel" : "They feel") better."
        case .surveyed(let readings):
            "Surveyed: " + readings.map { "\($0.name) \($0.text)" }.joined(separator: ", ") + "."
        case .metTraveller(let id):
            ContentCatalog.shared.traveller(id).map { "\($0.name), \($0.calling). \($0.blurb)" }
                ?? "Someone is here."
        case .nightfall: "The light goes. You can see less of this than you could."
        case .daybreak: "It comes back around. You can see again."
        case .foundSite(let site):
            ContentCatalog.shared.site(site).map { "\($0.name). \($0.blurb)" } ?? "Something built."
        case .searchedSite(_, let remaining):
            "Searching. \(remaining) more turn\(remaining == 1 ? "" : "s")."
        case .siteOpened(let site):
            "You've had everything \(ContentCatalog.shared.site(site)?.name.lowercased() ?? "it") has."
        case .learnedSymbol(let symbol):
            "You can write \(ContentCatalog.shared.symbol(symbol)?.name ?? "something new") now."
        case .learnedFocus(let focus):
            "A word you didn't have: \(ContentCatalog.shared.pressureSource(focus)?.name ?? "something new")."
        case .learnedGambit(let component):
            "A gambit phrase you didn't have: \(ContentCatalog.shared.gambitComponent(component)?.name ?? "something new")."
        case .learnedPattern(let pattern): SchematicPresentation.learnedEvent(pattern: pattern)
        case .learnedSchematic(let schematic): SchematicPresentation.learnedEvent(schematic: schematic)
        case .gainedEssence(let amount): "\(amount) essence, banked."
        case .pickedUpItem(let what): "\(what) You can't tell what it is."
        case .satchelFull(let what): "No room in your satchel — \(what.lowercased()) is waiting on you."
        case .hazardHit(let damage): "The ground turns on you — \(damage) damage."
        case .scratchedByGrowth(let name, let damage, let lingers):
            lingers ? "You push through the \(name). \(damage) damage, and it's still working."
                : "The \(name) tears at you — \(damage) damage."
        case .poisonWorking(let damage): "Whatever that was is still in you — \(damage) damage."
        case .enemySighted(let name): "A \(name) has noticed you."
        case .enemyAlerted(let name): "A \(name) pauses, alert to your movement."
        case .crossedThreshold(let band):
            switch band {
            case .stable: nil
            case .hazardous: "The edges are starting to go."
            case .crumbling: "The world is crumbling inward."
            case .collapsed: "The world is coming apart. Get to a portal while there's floor."
            }
        case .tilesCrumbled(let count): count > 0 ? "\(count) tiles gone." : nil
        case .lostToCrumbling(let count):
            count == 1 ? "Something you hadn't taken went with it."
                : "\(count) things you hadn't taken went with it."
        case .collapsed: "The world is coming apart. Get to a portal."
        case .floorGaveWay: "The ground goes out from under you."
        case .ejected(let reason): reason
        }
    }
}

/// The single owner of game state, and the only thing that writes the save.
///
/// The interruptibility pillar in one rule: **every state change goes through `mutate`**, and
/// `mutate` always schedules a write. No view or system may hold its own copy of game state or
/// poke at the save file. If you find yourself wanting to mutate without saving, the answer is a
/// `mutate` call, not a back door.
///
/// Write policy:
///  - Ordinary mutations debounce by `Tuning.saveDebounceMilliseconds` (≤100ms, per the brief) so
///    a rapid tap sequence doesn't write ten times.
///  - Commitment points (`flush: true`) and any scene-phase change write synchronously, before
///    iOS can suspend us. That's what makes "force-quit at ANY moment" true rather than
///    "force-quit at most moments".
///  - Writes go through one serial queue, so they land in the order they were made.
@MainActor
final class GameStore: ObservableObject {
    enum MutationScope: Sendable { case ordinary, expedition, arrivalLifecycle }
    enum PreparationError: Error, Equatable {
        case unrecoverableSave(String)
    }
    struct PreparedLaunch: Sendable {
        var state: GameState
        var loadOutcome: String
        var saveFileByteCount: Int?
        var timings: LaunchTimings
    }

    struct LaunchTimings: Equatable, Sendable {
        var loadMilliseconds: Double
        var reconciliationMilliseconds: Double
        var persistenceMilliseconds: Double
        var totalMilliseconds: Double
    }
    enum PreparationStep: Int, CaseIterable, Equatable, Sendable {
        case loadingSave
        case reconcilingCatalogue
        case committingSave
        case complete

        var accessibilityDescription: String {
            switch self {
            case .loadingSave: "Reading campaign"
            case .reconcilingCatalogue: "Checking the Atlas"
            case .committingSave: "Securing campaign"
            case .complete: "Ready"
            }
        }
    }
    @Published private(set) var state: GameState
    @Published private(set) var diagnostics: SaveDiagnostics

    /// What just happened in the world, for the World screen to narrate.
    ///
    /// Deliberately *not* in the save: a resumed run should show you where you are, not replay how
    /// you got there. Losing this to a force-quit costs nothing.
    @Published var recentEvents: [WorldRules.Event] = []
    @Published private(set) var worldFieldContext: WorldFieldContextReceiptV1?
    @Published private(set) var worldFieldEventQueue: [WorldFieldEventBatchV1] = []
    /// Recoverable player-facing failure from the bind preview/receipt commitment boundary.
    /// It is deliberately outside the save: a failed bind changes no campaign fact.
    @Published var bindError: String?

    private let io: any GamePersistenceIO
    private let writeQueue = DispatchQueue(label: "com.aimeepepper.bookbinder.save", qos: .userInitiated)
    private var debounceTask: Task<Void, Never>?
    private var nextWorldFieldAttemptID: UInt64 = 1
    private var seenWorldFieldBatchIDs: Set<String> = []
    private var visibleWorldFieldBatchSince: UInt64?

    var diagnosticCampaignReference: String? { io.diagnosticCampaignReference }

    // MARK: - Construction

    /// Loads synchronously at launch: the app must never render a frame of state it might have
    /// to replace a moment later. The file is a few KB.
    convenience init(io: any GamePersistenceIO) {
        do {
            self.init(io: io, prepared: try Self.prepareLaunch(io: io))
        } catch {
            let state = GameState.newGame()
            self.init(io: io, prepared: PreparedLaunch(
                state: state, loadOutcome: "launch failed: \(error.localizedDescription)",
                saveFileByteCount: io.saveFileByteCount,
                timings: .init(loadMilliseconds: 0, reconciliationMilliseconds: 0,
                               persistenceMilliseconds: 0, totalMilliseconds: 0)
            ))
            diagnostics.lastError = error.localizedDescription
        }
    }

    init(io: any GamePersistenceIO, prepared: PreparedLaunch) {
        self.io = io
        self.state = prepared.state
        self.diagnostics = SaveDiagnostics(
            loadOutcome: prepared.loadOutcome,
            savedMutationCount: prepared.state.meta.mutationCount,
            saveURL: io.saveURL
        )
        self.diagnostics.saveFileByteCount = prepared.saveFileByteCount
        self.worldFieldContext = WorldFieldContextReceiptV1.make(from: prepared.state)
    }

    var currentWorldFieldEventBatch: WorldFieldEventBatchV1? { worldFieldEventQueue.first }

    struct WorldFieldAttempt: Equatable, Sendable {
        let id: UInt64
        let sourceAction: WorldFieldEventBatchV1.SourceAction
        let worldRunID: String
        let turnBefore: Int
    }

    func beginWorldFieldAttempt(_ sourceAction: WorldFieldEventBatchV1.SourceAction) -> WorldFieldAttempt? {
        guard let run = activeRun else { return nil }
        let attempt = WorldFieldAttempt(
            id: nextWorldFieldAttemptID, sourceAction: sourceAction,
            worldRunID: "\(run.runIndex):\(run.mapSeed)", turnBefore: run.turnsTaken)
        nextWorldFieldAttemptID &+= 1
        return attempt
    }

    func submitWorldFieldEvents(_ events: [WorldRules.Event], for attempt: WorldFieldAttempt,
                                now: UInt64 = DispatchTime.now().uptimeNanoseconds) {
        let narrations = events.compactMap(WorldFieldNarration.text)
        guard !narrations.isEmpty else { return }
        let turnAfter = activeRun?.turnsTaken ?? attempt.turnBefore
        let canonicalFields = ([
            "v1", attempt.worldRunID, String(attempt.id), attempt.sourceAction.rawValue,
            String(attempt.turnBefore), String(turnAfter),
        ] + events.map(Self.canonicalWorldFieldEvent))
        let canonical = canonicalFields.map { "\($0.utf8.count):\($0)" }.joined()
        let hash = SHA256.hash(data: Data(canonical.utf8)).map { String(format: "%02x", $0) }.joined()
        let batch = WorldFieldEventBatchV1(
            batchID: "\(attempt.id):\(hash)", worldRunID: attempt.worldRunID,
            attemptID: attempt.id, sourceAction: attempt.sourceAction,
            turnBefore: attempt.turnBefore, turnAfter: turnAfter,
            orderedEvents: events, orderedNarrations: narrations,
            createdAtMonotonicTime: now)
        enqueueWorldFieldBatch(batch, now: now)
    }

    func enqueueWorldFieldBatch(_ batch: WorldFieldEventBatchV1,
                                now: UInt64 = DispatchTime.now().uptimeNanoseconds) {
        guard seenWorldFieldBatchIDs.insert(batch.batchID).inserted else { return }
        let wasEmpty = worldFieldEventQueue.isEmpty
        worldFieldEventQueue.append(batch)
        if wasEmpty { visibleWorldFieldBatchSince = now }
    }

    func dismissWorldFieldFeedback(expectedBatchID: String,
                                   now: UInt64 = DispatchTime.now().uptimeNanoseconds) {
        guard worldFieldEventQueue.first?.batchID == expectedBatchID else { return }
        worldFieldEventQueue.removeFirst()
        visibleWorldFieldBatchSince = worldFieldEventQueue.isEmpty ? nil : now
    }

    func expireWorldFieldFeedback(ifCurrent batchID: String,
                                  now: UInt64 = DispatchTime.now().uptimeNanoseconds) {
        guard currentWorldFieldEventBatch?.batchID == batchID,
              let visibleWorldFieldBatchSince,
              now >= visibleWorldFieldBatchSince + 4_000_000_000 else { return }
        dismissWorldFieldFeedback(expectedBatchID: batchID, now: now)
    }

    func clearWorldFieldFeedback() {
        worldFieldEventQueue.removeAll()
        seenWorldFieldBatchIDs.removeAll()
        visibleWorldFieldBatchSince = nil
    }

    func refreshWorldFieldContext() {
        let refreshed = WorldFieldContextReceiptV1.make(from: state)
        guard refreshed != worldFieldContext else { return }
        worldFieldContext = refreshed
    }

    private static func canonicalWorldFieldEvent(_ event: WorldRules.Event) -> String {
        func encoded(_ fields: [String]) -> String {
            fields.map { "\($0.utf8.count):\($0)" }.joined()
        }
        func tagged(_ tag: String, _ values: String...) -> String {
            encoded([tag] + values)
        }
        return switch event {
        case .moved(let point): tagged("moved", String(point.x), String(point.y))
        case .enteredSlowGround(let ground): tagged("slow", ground)
        case .blocked(let reason): tagged("blocked", reason)
        case .pickedUp(let id, let amount): tagged("pickup", id.rawValue, String(amount))
        case .harvested(let id, let amount, let exhausted):
            tagged("harvest", id.rawValue, String(amount), String(exhausted))
        case .foundPortal: tagged("portal")
        case .foundCache: tagged("cache")
        case .cacheOpened(let copy): tagged("cache-open", copy)
        case .foundSite(let id): tagged("site", id.rawValue)
        case .readPage(let id): tagged("page", id.rawValue)
        case .readFoundWriting(let id, let prose): tagged("writing", id.rawValue, prose)
        case .foundTraveller(let id): tagged("traveller", id.rawValue)
        case .metTraveller(let id): tagged("met", id.rawValue)
        case .usedItem(let name, let member): tagged("use", name, member.id)
        case .surveyed(let readings):
            tagged("survey", readings.map {
                encoded([$0.target.rawValue, $0.name, $0.text])
            }.joined())
        case .searchedSite(let id, let turns): tagged("search", id.rawValue, String(turns))
        case .siteOpened(let id): tagged("site-open", id.rawValue)
        case .learnedSymbol(let id): tagged("symbol", id.rawValue)
        case .learnedFocus(let id): tagged("focus", id.rawValue)
        case .learnedGambit(let id): tagged("gambit", id.rawValue)
        case .learnedPattern(let id): tagged("pattern", id.rawValue)
        case .learnedSchematic(let id): tagged("schematic", id.rawValue)
        case .gainedEssence(let amount): tagged("essence", String(amount))
        case .pickedUpItem(let copy): tagged("item", copy)
        case .satchelFull(let copy): tagged("full", copy)
        case .hazardHit(let damage): tagged("hazard", String(damage))
        case .scratchedByGrowth(let name, let damage, let lingers):
            tagged("flora", name, String(damage), String(lingers))
        case .poisonWorking(let damage): tagged("poison", String(damage))
        case .enemySighted(let name): tagged("sighted", name)
        case .enemyAlerted(let name): tagged("alerted", name)
        case .encounterBegan: tagged("encounter")
        case .crossedThreshold(let band): tagged("threshold", band.rawValue)
        case .nightfall: tagged("nightfall")
        case .daybreak: tagged("daybreak")
        case .tilesCrumbled(let count): tagged("crumbled", String(count))
        case .lostToCrumbling(let count): tagged("lost", String(count))
        case .collapsed: tagged("collapsed")
        case .floorGaveWay: tagged("floor")
        case .ejected(let reason): tagged("ejected", reason)
        }
    }

    /// All disk, decoding, catalogue reconciliation and the launch commitment can run before the
    /// main actor owns a store. The first SwiftUI frame therefore never waits behind file I/O.
    nonisolated static func prepareLaunch(
        io: any GamePersistenceIO,
        progress: @Sendable (PreparationStep) -> Void = { _ in }
    ) throws -> PreparedLaunch {
        let totalStart = DispatchTime.now().uptimeNanoseconds
        let loadStart = totalStart
        progress(.loadingSave)
        let outcome = io.load()
        var state: GameState
        switch outcome {
        case .newGame:
            state = GameState.newGame()
        case .loaded(let loaded), .recoveredFromBackup(let loaded, _):
            state = loaded
        case .unrecoverable(let reason):
            throw PreparationError.unrecoverableSave(reason)
        }
        let loadedAt = DispatchTime.now().uptimeNanoseconds
        progress(.reconcilingCatalogue)

        let loadedState = state
        state.base.seatEveryoneFound(in: state.reality.library)
        state.base.learnEveryStarterWord()
        _ = CombatRules.reconcileExpeditionHealth(in: &state)

        if state.worlds.activeRun == nil {
            let floor = EconomyRules.minimumBindCost(in: state)
            if EconomyRules.spendableEssence(in: state) < floor {
                state.base.essence += max(0, floor - EconomyRules.spendableEssence(in: state))
            }
        }
        let reconciledAt = DispatchTime.now().uptimeNanoseconds
        var persistedAt = reconciledAt

        // A normal launch is read-only. Previously diagnostics-only launch bookkeeping forced an
        // envelope encode, atomic write, and second full decode every time the app opened. Commit
        // only when tolerant decode/reconciliation actually changed campaign facts.
        if state != loadedState {
            state.meta.mutationCount += 1
            state.meta.recordSemanticAction("launch reconciliation")
            state.meta.lastSavedAt = Date()
            progress(.committingSave)
            do {
                let committedData = try SaveCodec.encode(state)
                try io.write(committedData)
                // Publish the same normalized representation a future process will decode.
                // Several tolerant save fields intentionally omit default dictionary entries.
                state = try SaveCodec.decode(committedData)
            }
            catch {
                Logger.persistence.error("Launch commitment failed: \(String(describing: error))")
                throw error
            }
            persistedAt = DispatchTime.now().uptimeNanoseconds
        }
        progress(.complete)
        func milliseconds(_ start: UInt64, _ end: UInt64) -> Double {
            Double(end - start) / 1_000_000
        }
        return PreparedLaunch(
            state: state,
            loadOutcome: outcome.description,
            saveFileByteCount: io.saveFileByteCount,
            timings: .init(loadMilliseconds: milliseconds(loadStart, loadedAt),
                           reconciliationMilliseconds: milliseconds(loadedAt, reconciledAt),
                           persistenceMilliseconds: milliseconds(reconciledAt, persistedAt),
                           totalMilliseconds: milliseconds(totalStart, persistedAt))
        )
    }

    static func live() -> GameStore { GameStore(io: .documents) }

    // MARK: - Mutation

    /// The one way to change game state.
    ///
    /// - Parameters:
    ///   - label: short description, stored in the save. A resumed game can then say what the
    ///     player was last doing — and the kill-test can prove which action survived.
    ///   - flush: `true` for commitment points (binding a book, entering/resolving an encounter,
    ///     banking a haul) where losing even the debounce window would be a real loss.
    func mutate(_ label: String, flush: Bool = false, scope: MutationScope = .ordinary,
                _ body: (inout GameState) -> Void) {
        guard permitsMutationWhileArrivalOwnsRoot(scope) else { return }
        body(&state)
        state.meta.mutationCount += 1
        state.meta.recordSemanticAction(label)
        state.meta.lastSavedAt = Date() // diagnostics only — no gameplay rule may read this

        if flush {
            flushNow()
        } else {
            scheduleSave()
        }
    }

    /// Atomic commitment variant. Rules stage against a value copy and publish it only when every
    /// stale-quote guard succeeds; refusal records no action and schedules no save.
    @discardableResult
    func mutateIf(_ label: String, flush: Bool = false, scope: MutationScope = .ordinary,
                  _ body: (inout GameState) -> Bool) -> Bool {
        guard permitsMutationWhileArrivalOwnsRoot(scope) else { return false }
        var candidate = state
        guard body(&candidate) else { return false }
        state = candidate
        state.meta.mutationCount += 1
        state.meta.recordSemanticAction(label)
        state.meta.lastSavedAt = Date()
        if flush { flushNow() } else { scheduleSave() }
        return true
    }

    /// One centralized gate covers every stale/debug action path while the arrival owns root
    /// presentation. Only the exact idempotent dismissal or orphan reconciliation may mutate.
    private func permitsMutationWhileArrivalOwnsRoot(_ scope: MutationScope) -> Bool {
        guard state.worlds.pendingWorldArrivalReceipt != nil else { return true }
        return scope == .arrivalLifecycle
    }

    /// Cancels any pending debounce and writes now, blocking until the bytes are handed to the
    /// filesystem. Called on every scene-phase change out of `.active`.
    func flushNow() {
        debounceTask?.cancel()
        debounceTask = nil
        performWrite(synchronously: true)
    }

    private func scheduleSave() {
        diagnostics.hasPendingWrite = true
        debounceTask?.cancel()
        debounceTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(Tuning.saveDebounceMilliseconds))
            guard !Task.isCancelled, let self else { return }
            self.performWrite(synchronously: false)
        }
    }

    private func performWrite(synchronously: Bool) {
        let snapshot = state
        let data: Data
        do {
            data = try SaveCodec.encode(snapshot)
        } catch {
            diagnostics.lastError = "encode failed: \(error)"
            Logger.persistence.error("Encode failed: \(String(describing: error))")
            return
        }

        let io = self.io
        if synchronously {
            let result = writeQueue.sync { Result { try io.write(data) } }
            recordWriteResult(result, mutationCount: snapshot.meta.mutationCount)
        } else {
            writeQueue.async { [weak self] in
                let result = Result { try io.write(data) }
                Task { @MainActor [weak self] in
                    self?.recordWriteResult(result, mutationCount: snapshot.meta.mutationCount)
                }
            }
        }
    }

    private func recordWriteResult(_ result: Result<Void, Error>, mutationCount: Int) {
        switch result {
        case .success:
            // Guard against an out-of-order report from a slower earlier write.
            diagnostics.savedMutationCount = max(diagnostics.savedMutationCount, mutationCount)
            diagnostics.writeCount += 1
            diagnostics.lastError = nil
        case .failure(let error):
            diagnostics.lastError = "write failed: \(error)"
            Logger.persistence.error("Write failed: \(String(describing: error))")
        }
        diagnostics.hasPendingWrite = state.meta.mutationCount > diagnostics.savedMutationCount
        diagnostics.saveFileByteCount = io.saveFileByteCount
    }

    // MARK: - Whole-save operations

    /// Wipes everything and starts over. Harness/debug only — there is no player-facing new game
    /// in v0.
    func resetEverything() {
        debounceTask?.cancel()
        io.deleteEverything()
        state = GameState.newGame()
        diagnostics = SaveDiagnostics(loadOutcome: "reset", savedMutationCount: 0, saveURL: io.saveURL)
        mutate("reset save", flush: true) { _ in }
    }

    /// The future "reset base, keep reality" operation, proven possible from milestone 1.
    ///
    /// It exists to keep the three-layer separation honest: if this ever stops compiling as three
    /// lines, the layers have leaked into each other. WHAT triggers it and what the payoff is are
    /// open design questions (open-questions.md Q-C) — this is the mechanism only, not the rule.
    func resetBaseKeepingReality() {
        mutate("reset Village, keep shared progress", flush: true) { state in
            state.base = BaseState.newGame()
            state.worlds = WorldsState.newGame(seeds: &state.worlds.seeds)
        }
    }
}

/// Everything the harness needs to show that persistence is behaving.
struct SaveDiagnostics {
    var loadOutcome: String
    /// `meta.mutationCount` as of the last successful write. When this equals the in-memory
    /// count, the disk is fully caught up.
    var savedMutationCount: Int
    var saveURL: URL
    var saveFileByteCount: Int?
    var hasPendingWrite: Bool = false
    var writeCount: Int = 0
    var lastError: String?
}
