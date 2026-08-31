import Foundation
import SwiftUI
import OSLog
import CryptoKit

struct PersistedCommitPresentationTokenV1: Equatable, Hashable, Sendable {
    let rawValue: UUID
}

enum PersistedCommitRefusalV1: Equatable, Sendable {
    case mutationUnavailable, candidateRefused, invalidCandidate
    case persistence(PersistenceCommitRefusalV1)
}

enum PersistedCommitResultV1<Value> {
    case committedNow(Value, PersistedCommitPresentationTokenV1)
    case recoveredDurable(PersistenceCommitReceiptV1)
    case alreadyCommitted(PersistenceCommitReceiptV1)
    case refused(PersistedCommitRefusalV1)
}

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
        let extractionTarget = ResourceExtractionRules.selectedDisclosedNode(in: state)
        let offeredPages = run.offeredWorldPages.filter {
            $0.fieldProvenance?.position == run.playerPosition
        }
        if offeredPages.count == 1, offeredPages.first != nil {
            content = .writing
            interaction = .takePage
            interactionState = encounterBlocksInteraction
                ? .unavailable(reason: "Finish the encounter first.")
                : .available
        } else if let (_, node) = extractionTarget {
            content = .node(name: ContentCatalog.shared.resource(node.resource)?.name ?? "Unknown resource")
            interaction = .harvest
            switch ResourceExtractionRules.evaluate(in: state) {
            case .available:
                interactionState = .available
            case .refused(let refusal):
                interactionState = .unavailable(reason: ResourceExtractionRules.playerCopy(
                    for: refusal,
                    resourceName: ContentCatalog.shared.resource(node.resource)?.name))
            }
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
            } else if !run.carriedInstruments.isEmpty {
                interaction = .survey
                switch WorldRules.evaluateFieldSurvey(in: state) {
                case .available:
                    interactionState = .available
                case .refused(let refusal):
                    interactionState = .unavailable(
                        reason: WorldRules.fieldSurveyPlayerCopy(for: refusal))
                }
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
            let premium = GameStore.bornAnchoredPremium(forBookCost: run.book.essencePaid)
            let anchorCost = max(Tuning.Anchoring.naturalAnchorMinimumCost,
                (premium + Tuning.Anchoring.naturalAnchorPremiumDivisor - 1)
                    / Tuning.Anchoring.naturalAnchorPremiumDivisor)
            if !isNaturalAnchor {
                switch WorldRules.evaluateSiteSearch(in: state) {
                case .available:
                    interactionState = .available
                case .refused(let refusal):
                    interactionState = .unavailable(
                        reason: WorldRules.siteSearchPlayerCopy(for: refusal))
                }
            } else if encounterBlocksInteraction || run.enemies.contains(where: {
                $0.position == run.playerPosition
            }) {
                interactionState = .unavailable(reason: "Not while something is standing over you.")
            } else if !state.base.station(Stations.anchorage).isUnlocked {
                interactionState = .unavailable(reason: "Unlock the Anchorage first.")
            } else if state.base.essenceCrystalCount < anchorCost {
                interactionState = .unavailable(reason: "You need \(anchorCost) essence.")
            } else if state.worlds.anchoredRealms.contains(where: { $0.runIndex == run.runIndex }) {
                interactionState = .unavailable(reason: "This world is already anchored.")
            } else {
                interactionState = .available
            }
        case .diaryPage, .foundWriting, .recoveredTeaching:
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
            "survey=\(surveyInputHash(in: state, interaction: interaction))",
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

    private static func surveyInputHash(in state: GameState, interaction: Interaction) -> String {
        guard interaction == .survey,
              case .available(let quote) = WorldRules.evaluateFieldSurvey(in: state) else {
            return "none"
        }
        return quote.inputStateHash
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
                case .recoveredTeaching: "recovered-teaching"
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

    enum Disposition: Equatable, Sendable {
        case committed
        case blocked(String)
        case refused(String)
        case busy

        var isCommitted: Bool {
            if case .committed = self { return true }
            return false
        }
    }

    let batchID: String
    let sessionEpoch: UInt64
    let worldRunID: String
    let attemptID: UInt64
    let sourceAction: SourceAction
    let sourcePoint: GridPoint
    let turnBefore: Int
    let turnAfter: Int
    let beforeContext: WorldFieldContextReceiptV1
    let afterContext: WorldFieldContextReceiptV1?
    let disposition: Disposition
    let orderedEvents: [WorldRules.Event]
    let orderedNarrations: [String]
    let createdAtMonotonicTime: UInt64
    let deadlineMonotonicTime: UInt64
}

struct WorldMiningFeedbackGroupV1: Equatable {
    struct Subject: Equatable { let resourceID: ResourceID; let amount: Int }
    let batchID: String
    let worldRunID: String
    let sourcePoint: GridPoint
    let subjects: [Subject]
    let startedAtMonotonicTime: UInt64
}

struct WorldTravellerSpeechSessionIDV1: Equatable, Hashable, Sendable {
    let rawValue: UInt64
}

struct WorldTravellerSpeechPresentationIDV1: Equatable, Hashable, Sendable {
    let sessionID: WorldTravellerSpeechSessionIDV1
    let ordinal: Int
}

struct WorldTravellerSpeechBubbleV1: Equatable, Identifiable, Sendable {
    let presentationID: WorldTravellerSpeechPresentationIDV1
    let travellerID: TravellerID
    let worldRunID: String
    let point: GridPoint
    let text: String
    let visibleSinceMonotonicTime: UInt64?
    let deadlineMonotonicTime: UInt64?

    var id: WorldTravellerSpeechPresentationIDV1 { presentationID }

    func promoted(at now: UInt64) -> Self {
        Self(
            presentationID: presentationID, travellerID: travellerID,
            worldRunID: worldRunID, point: point, text: text,
            visibleSinceMonotonicTime: now,
            deadlineMonotonicTime: now &+ GameStore.worldTravellerSpeechLifetimeNanoseconds)
    }
}

enum TravellerAdjacentSpeechV1Registry {
    static let textByTravellerID: [String: String] = [
        "ashe": "“That is permission for this moment, from that direction.”",
        "auber": "“This is the interesting half. Nobody asks to taste this one.”",
        "bracken": "“The wearer was less fortunate.”",
        "bryn": "“I'm keeping this one open until they're clear.”",
        "corrin": "“The shoulder that has to meet it eight hundred times is less theoretical.”",
        "dagg": "“Because I moved the slab.”",
        "edren": "\"Mind where you tread. There's a floor about eight inches down and I've nearly got the edge of it.\"",
        "fen": "“It stretched. Fine for a sling, poor for a bow.”",
        "grimmond": "“It'll still crush you.”",
        "halloway": "\"Don't crowd it. It's shy.\"",
        "isolde": "\"Don't speak for a moment. I'm nearly at the bottom.\"",
        "kestrel": "“That is not yet the animal.”",
        "lys": "“Only the account of how one became the other.”",
        "mara": "\"Don't move. You're the first fixed point I've had in a long while.\"",
        "marrick": "“The sixth couldn't reach their place. We kept calling that a successful formation.”",
        "maud": "“That is the first measurement the metal could not give me.”",
        "nessa": "“Different instructions. The old labels nearly made that expensive.”",
        "nine": "“So is the revision.”",
        "noll": "“I haven't finished checking why it failed.”",
        "oda": "“Approach corridor held. Marker four did not. Please stand exactly where you are while I determine which result matters.”",
        "orsa": "“I repaired it, but I don't trust its opinion of taller guests.”",
        "perren": "“So is the decision about which relationship the repetition is allowed to prove.”",
        "rook": "“It could not know what the line meant. That failure is mine.”",
        "sabine": "“Sorry. The twigs are doing excellent work, but they are terrible at introductions.”",
        "sela": "\"Oh, good. Company. Keep up.\"",
        "talin": "“The gap closes before I can recover.”",
        "tovin": "\"You wrote this. I can tell by the light — it's got somebody's opinion in it.\"",
        "vance": "“Good start. Not much of a sales pitch.”",
        "wren": "“They can't. So we're using their route first.”",
    ]
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
        case .recoveredTeaching(_, let title): "Recovered teaching: \(title)."
        case .foundTraveller(let id):
            ContentCatalog.shared.traveller(id).map { "\($0.name) is coming with you." }
                ?? "They're coming with you."
        case .usedItem(let what, let member):
            "\(what). \(member == .binder ? "You feel" : "They feel") better."
        case .seamlightActivated: "The Seamlight leans toward a portal seam."
        case .seamwardFoundNoSeam: "The Seamward finds no answering seam."
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
        case .animalAttended(let name): "You attend to the \(name)."
        case .animalTrustProgress(let name, let current, let required):
            "The \(name) keeps watching. \(current) of \(required) patient turns."
        case .animalTrustCompleted(let name): "The \(name) chooses to approach."
        case .animalJoined(let name): "The \(name) chooses to travel with you."
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
    @Published private(set) var worldMiningFeedbackPresentations: [WorldMiningFeedbackGroupV1] = []
    @Published private(set) var worldTravellerSpeech: WorldTravellerSpeechBubbleV1?
    @Published private(set) var worldTravellerSpeechQueue: [WorldTravellerSpeechBubbleV1] = []
    /// Recoverable player-facing failure from the bind preview/receipt commitment boundary.
    /// It is deliberately outside the save: a failed bind changes no campaign fact.
    @Published var bindError: String?
    /// The unfinished page on the currently mounted Writing Desk. Deliberately transient: an
    /// ordinary visit starts blank and a relaunch cannot silently restore an abandoned draft.
    @Published private(set) var writingDeskDraft: Page?
#if DEBUG
    /// Test-only interruption at the exact staged-quote/atomic-commit boundary.
    var writingDeskBeforeCommitForTesting: (() -> Void)?
    var expeditionReviewBeforeCommitForTesting: (() -> Void)?
#endif

    private let io: any GamePersistenceIO
    private let writeQueue = DispatchQueue(label: "com.aimeepepper.bookbinder.save", qos: .userInitiated)
    private var debounceTask: Task<Void, Never>?
    private var nextPersistenceWriteGeneration: UInt64 = 1
    private var minimumAcceptedWriteGeneration: UInt64 = 0
    private var completedPersistedAttempts: [UUID: PersistenceCommitReceiptV1] = [:]
    private var persistenceClosing = false
    private var nextWorldFieldAttemptID: UInt64 = 1
    private var worldFieldSessionEpoch: UInt64 = 1
    private var seenWorldFieldBatchIDs: Set<String> = []
    private var seenWorldMiningBatchIDs: Set<String> = []
    private var travellerSpeechWorldRunID: String?
    private var nextTravellerSpeechSessionID: UInt64 = 1
    private var currentTravellerSpeechSessionID: WorldTravellerSpeechSessionIDV1?
    private var shownTravellerSpeechIDs: Set<TravellerID> = []
    var expeditionReviewAcknowledgementInFlight = false

    var diagnosticCampaignReference: String? { io.diagnosticCampaignReference }

    /// The page the mounted Writing Desk presents. Before SwiftUI delivers `onAppear`, this must
    /// already be blank so a legacy persisted page can never flash during the first frame.
    var writingDeskPage: Page {
        writingDeskDraft ?? Page(width: state.base.page.width, height: state.base.page.height)
    }

    /// Rule calls outside a mounted Writing Desk retain their established persisted-page owner.
    /// Once a session exists, the same calls edit the transient page shown by the screen.
    var writingDeskActionPage: Page { writingDeskDraft ?? state.base.page }

    var writingDeskState: GameState {
        guard let writingDeskDraft else { return state }
        var value = state
        value.base.page = writingDeskDraft
        return value
    }

    func beginWritingDeskSession() {
        bindError = nil
        // SwiftUI may redeliver appearance while the same routed Desk remains mounted (for
        // example as its tutorial/overlay tree changes). Only the matching end call starts a new
        // visit; another appearance must not reconstruct a draft that already owns placed marks.
        guard writingDeskDraft == nil else { return }
        writingDeskDraft = Page(width: state.base.page.width, height: state.base.page.height)
    }

    func endWritingDeskSession() {
        writingDeskDraft = nil
        bindError = nil
    }

    func replaceWritingDeskDraft(_ page: Page, label: String = "edit Writing Desk page",
                                 flush: Bool = false) {
        if writingDeskDraft != nil {
            writingDeskDraft = page
        } else {
            mutate(label, flush: flush) { $0.base.page = page }
        }
    }

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
    var currentWorldFieldEventVisibleSince: UInt64? {
        currentWorldFieldEventBatch?.createdAtMonotonicTime
    }

    struct WorldFieldAttempt: Equatable, Sendable {
        let sessionEpoch: UInt64
        let attemptID: UInt64
        let sourceAction: WorldFieldEventBatchV1.SourceAction
        let beforeContext: WorldFieldContextReceiptV1
        let worldRunID: String
        let sourcePoint: GridPoint
        let turnBefore: Int
        let observedTravellerSpeechSessionID: WorldTravellerSpeechSessionIDV1?

        var id: UInt64 { attemptID }
    }

    func beginWorldFieldAttempt(_ sourceAction: WorldFieldEventBatchV1.SourceAction) -> WorldFieldAttempt? {
        guard let run = activeRun,
              let beforeContext = WorldFieldContextReceiptV1.make(from: state) else { return nil }
        let attempt = WorldFieldAttempt(
            sessionEpoch: worldFieldSessionEpoch, attemptID: nextWorldFieldAttemptID,
            sourceAction: sourceAction, beforeContext: beforeContext,
            worldRunID: "\(run.runIndex):\(run.mapSeed)", sourcePoint: run.playerPosition,
            turnBefore: run.turnsTaken,
            observedTravellerSpeechSessionID: currentTravellerSpeechSessionID)
        nextWorldFieldAttemptID &+= 1
        return attempt
    }

    /// Cancels transient speech only once the rules-owned action has actually committed.
    /// Refused/no-op attempts must not consume a bubble that has already entered the shown set.
    func acceptWorldFieldAttempt(_ attempt: WorldFieldAttempt) {
        guard attempt.sessionEpoch == worldFieldSessionEpoch, let run = activeRun,
              "\(run.runIndex):\(run.mapSeed)" == attempt.worldRunID else { return }
        clearWorldTravellerSpeechPresentation(
            expectedSessionID: attempt.observedTravellerSpeechSessionID)
    }

    func submitWorldFieldEvents(_ events: [WorldRules.Event], for attempt: WorldFieldAttempt,
                                disposition: WorldFieldEventBatchV1.Disposition,
                                now: UInt64 = DispatchTime.now().uptimeNanoseconds) {
        guard attempt.sessionEpoch == worldFieldSessionEpoch,
              let run = activeRun,
              "\(run.runIndex):\(run.mapSeed)" == attempt.worldRunID else { return }
        guard disposition != .busy else { return }
        let afterContext = WorldFieldContextReceiptV1.make(from: state)
        if !disposition.isCommitted {
            guard afterContext == attempt.beforeContext else { return }
        } else {
            guard run.turnsTaken != attempt.turnBefore || afterContext != attempt.beforeContext
            else { return }
        }
        if disposition.isCommitted {
            acceptWorldFieldAttempt(attempt)
        }
        let narrations = events.compactMap(WorldFieldNarration.text)
        guard !narrations.isEmpty else { return }
        let turnAfter = run.turnsTaken
        let canonicalFields = ([
            "v2", String(attempt.sessionEpoch), attempt.worldRunID, String(attempt.id),
            attempt.sourceAction.rawValue, String(attempt.sourcePoint.x), String(attempt.sourcePoint.y),
            String(attempt.turnBefore), String(turnAfter), attempt.beforeContext.inputStateHash,
            afterContext?.inputStateHash ?? "none", Self.canonicalDisposition(disposition),
        ] + events.map(Self.canonicalWorldFieldEvent))
        let canonical = canonicalFields.map { "\($0.utf8.count):\($0)" }.joined()
        let hash = SHA256.hash(data: Data(canonical.utf8)).map { String(format: "%02x", $0) }.joined()
        let batch = WorldFieldEventBatchV1(
            batchID: "\(attempt.sessionEpoch):\(attempt.id):\(hash)",
            sessionEpoch: attempt.sessionEpoch, worldRunID: attempt.worldRunID,
            attemptID: attempt.id, sourceAction: attempt.sourceAction,
            sourcePoint: attempt.sourcePoint,
            turnBefore: attempt.turnBefore, turnAfter: turnAfter,
            beforeContext: attempt.beforeContext, afterContext: afterContext,
            disposition: disposition,
            orderedEvents: events, orderedNarrations: narrations,
            createdAtMonotonicTime: now,
            deadlineMonotonicTime: now &+ WorldFieldFeedbackLayout.eventLifetimeNanoseconds)
        enqueueWorldFieldBatch(batch, now: now)
    }

    func enqueueWorldFieldBatch(_ batch: WorldFieldEventBatchV1,
                                now: UInt64 = DispatchTime.now().uptimeNanoseconds) {
        guard batch.sessionEpoch == worldFieldSessionEpoch,
              activeRun.map({ "\($0.runIndex):\($0.mapSeed)" }) == batch.worldRunID,
              now < batch.deadlineMonotonicTime else { return }
        guard seenWorldFieldBatchIDs.insert(batch.batchID).inserted else { return }
        // A newly committed interaction owns the visible socket immediately. A preempted receipt
        // is retired instead of resurfacing with a newly reset lifetime.
        worldFieldEventQueue.removeAll(keepingCapacity: true)
        worldFieldEventQueue.append(batch)
        claimWorldMiningFeedback(for: batch, now: now)
    }

    func claimWorldMiningFeedback(for batch: WorldFieldEventBatchV1,
        now: UInt64 = DispatchTime.now().uptimeNanoseconds) {
        guard batch.sourceAction == .harvest, batch.disposition.isCommitted,
              let run = activeRun, batch.worldRunID == "\(run.runIndex):\(run.mapSeed)",
              seenWorldMiningBatchIDs.insert(batch.batchID).inserted else { return }
        var order: [ResourceID] = []; var totals: [ResourceID: Int] = [:]
        for event in batch.orderedEvents {
            guard case .harvested(let id, let amount, _) = event, amount > 0 else { continue }
            if totals[id] == nil { order.append(id) }
            totals[id, default: 0] += amount
        }
        let subjects = order.compactMap { id -> WorldMiningFeedbackGroupV1.Subject? in
            guard let amount = totals[id],
                  ResourceSpriteV1Registry.asset(for: id, profile: .field) != nil else { return nil }
            return .init(resourceID: id, amount: amount)
        }
        // Aimee's restored local-rise authority has no approved multi-kind spatial composition.
        // Preserve the complete committed reward/narration, but fail the optional animation closed.
        guard subjects.count == 1 else { return }
        let group = WorldMiningFeedbackGroupV1(
            batchID: batch.batchID, worldRunID: batch.worldRunID,
            sourcePoint: batch.sourcePoint, subjects: subjects,
            startedAtMonotonicTime: now)
        worldMiningFeedbackPresentations.append(group)
    }

    func finishWorldMiningFeedback(expectedBatchID: String) {
        worldMiningFeedbackPresentations.removeAll { $0.batchID == expectedBatchID }
    }

    func dismissWorldFieldFeedback(expectedBatchID: String,
                                   now: UInt64 = DispatchTime.now().uptimeNanoseconds) {
        guard worldFieldEventQueue.first?.batchID == expectedBatchID else { return }
        worldFieldEventQueue.removeFirst()
    }

    func expireWorldFieldFeedback(ifCurrent batchID: String,
                                  now: UInt64 = DispatchTime.now().uptimeNanoseconds) {
        guard currentWorldFieldEventBatch?.batchID == batchID,
              let deadline = currentWorldFieldEventBatch?.deadlineMonotonicTime,
              now >= deadline else { return }
        dismissWorldFieldFeedback(expectedBatchID: batchID, now: now)
    }

    func remainingWorldFieldFeedbackLifetime(
        for batchID: String,
        now: UInt64 = DispatchTime.now().uptimeNanoseconds
    ) -> UInt64? {
        guard let batch = currentWorldFieldEventBatch, batch.batchID == batchID else { return nil }
        return now < batch.deadlineMonotonicTime ? batch.deadlineMonotonicTime - now : 0
    }

    func clearWorldFieldFeedback() {
        worldFieldSessionEpoch &+= 1
        worldFieldEventQueue.removeAll()
        seenWorldFieldBatchIDs.removeAll()
        worldMiningFeedbackPresentations.removeAll()
        seenWorldMiningBatchIDs.removeAll()
        clearWorldTravellerSpeechSession()
    }

    nonisolated static let worldTravellerSpeechLifetimeNanoseconds: UInt64 = 5_140_000_000

    var worldTravellerSpeechSessionID: WorldTravellerSpeechSessionIDV1? {
        currentTravellerSpeechSessionID
    }

    func clearWorldTravellerSpeechPresentation(
        expectedSessionID: WorldTravellerSpeechSessionIDV1?
    ) {
        guard let expectedSessionID,
              currentTravellerSpeechSessionID == expectedSessionID else { return }
        worldTravellerSpeech = nil
        worldTravellerSpeechQueue.removeAll()
        currentTravellerSpeechSessionID = nil
    }

    func clearWorldTravellerSpeechSession() {
        worldTravellerSpeech = nil
        worldTravellerSpeechQueue.removeAll()
        currentTravellerSpeechSessionID = nil
        travellerSpeechWorldRunID = nil
        shownTravellerSpeechIDs.removeAll()
    }

    func remainingWorldTravellerSpeechLifetime(
        for presentationID: WorldTravellerSpeechPresentationIDV1,
        now: UInt64 = DispatchTime.now().uptimeNanoseconds
    ) -> UInt64? {
        guard let speech = worldTravellerSpeech,
              speech.presentationID == presentationID,
              let deadline = speech.deadlineMonotonicTime else { return nil }
        return now < deadline ? deadline - now : 0
    }

    func expireWorldTravellerSpeech(
        ifCurrent presentationID: WorldTravellerSpeechPresentationIDV1,
        now: UInt64 = DispatchTime.now().uptimeNanoseconds
    ) {
        guard let speech = worldTravellerSpeech,
              speech.presentationID == presentationID,
              let deadline = speech.deadlineMonotonicTime,
              now >= deadline else { return }
        promoteNextWorldTravellerSpeech(now: now)
    }

    private func promoteNextWorldTravellerSpeech(now: UInt64) {
        guard !worldTravellerSpeechQueue.isEmpty else {
            worldTravellerSpeech = nil
            currentTravellerSpeechSessionID = nil
            return
        }
        let next = worldTravellerSpeechQueue.removeFirst().promoted(at: now)
        worldTravellerSpeech = next
        shownTravellerSpeechIDs.insert(next.travellerID)
    }

    func presentTravellerSpeechAfterMovement(
        committedFinalPosition: GridPoint,
        from attempt: WorldFieldAttempt,
        now: UInt64 = DispatchTime.now().uptimeNanoseconds
    ) {
        guard attempt.sessionEpoch == worldFieldSessionEpoch,
              let run = activeRun, run.activeEncounter == nil,
              "\(run.runIndex):\(run.mapSeed)" == attempt.worldRunID,
              run.playerPosition == committedFinalPosition,
              committedFinalPosition != attempt.sourcePoint,
              attempt.sourceAction == .travel
                || (attempt.sourceAction == .step
                    && committedFinalPosition.manhattanDistance(to: attempt.sourcePoint) == 1)
        else { return }
        guard currentTravellerSpeechSessionID == nil else { return }
        let worldRunID = attempt.worldRunID
        if travellerSpeechWorldRunID != worldRunID {
            clearWorldTravellerSpeechSession()
            travellerSpeechWorldRunID = worldRunID
        }
        let directions = [(0, -1), (1, 0), (0, 1), (-1, 0)]
        let previouslyAdjacent = Set(directions.compactMap { direction -> TravellerID? in
            let point = GridPoint(x: attempt.sourcePoint.x + direction.0,
                                  y: attempt.sourcePoint.y + direction.1)
            guard run.map.contains(point), case .traveller(let id) = run.map[point].content else {
                return nil
            }
            return id
        })
        let alreadyPresented = Set(
            ([worldTravellerSpeech].compactMap { $0 } + worldTravellerSpeechQueue)
                .map(\.travellerID))
        let sessionID = WorldTravellerSpeechSessionIDV1(
            rawValue: nextTravellerSpeechSessionID)
        var admitted: [WorldTravellerSpeechBubbleV1] = []
        for direction in directions {
            let point = GridPoint(x: committedFinalPosition.x + direction.0,
                                  y: committedFinalPosition.y + direction.1)
            guard run.map.contains(point), run.map[point].isRevealed,
                  !run.map[point].isCrumbled,
                  WorldRules.visibility(of: point, from: committedFinalPosition, in: run.map,
                                        profile: WorldRules.visibilityProfile(
                                            in: run, party: WorldRules.sightBonus(in: state))) == .full,
                  case .traveller(let id) = run.map[point].content,
                  !previouslyAdjacent.contains(id), !shownTravellerSpeechIDs.contains(id),
                  !alreadyPresented.contains(id),
                  let text = TravellerAdjacentSpeechV1Registry.textByTravellerID[id.rawValue]
            else { continue }
            admitted.append(.init(
                presentationID: .init(sessionID: sessionID, ordinal: admitted.count),
                travellerID: id, worldRunID: worldRunID, point: point, text: text,
                visibleSinceMonotonicTime: nil, deadlineMonotonicTime: nil))
        }
        guard !admitted.isEmpty else { return }
        nextTravellerSpeechSessionID &+= 1
        currentTravellerSpeechSessionID = sessionID
        worldTravellerSpeech = admitted.removeFirst().promoted(at: now)
        shownTravellerSpeechIDs.insert(worldTravellerSpeech!.travellerID)
        worldTravellerSpeechQueue.append(contentsOf: admitted)
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
        case .recoveredTeaching(let id, let title): tagged("teaching", id.rawValue, title)
        case .foundTraveller(let id): tagged("traveller", id.rawValue)
        case .metTraveller(let id): tagged("met", id.rawValue)
        case .usedItem(let name, let member): tagged("use", name, member.id)
        case .seamlightActivated: tagged("seamlight-activated")
        case .seamwardFoundNoSeam: tagged("seamward-no-answering-seam")
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
        case .animalAttended(let name): tagged("animal-attended", name)
        case .animalTrustProgress(let name, let current, let required):
            tagged("animal-trust-progress", name, String(current), String(required))
        case .animalTrustCompleted(let name): tagged("animal-trust-completed", name)
        case .animalJoined(let name): tagged("animal-joined", name)
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

    private static func canonicalDisposition(_ disposition: WorldFieldEventBatchV1.Disposition)
        -> String {
        switch disposition {
        case .committed: "committed"
        case .blocked(let reason): "blocked:\(reason.utf8.count):\(reason)"
        case .refused(let reason): "refused:\(reason.utf8.count):\(reason)"
        case .busy: "busy"
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
                state.base.addEssenceCrystals(max(0, floor - EconomyRules.spendableEssence(in: state)))
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
        EconomyRules.normalizeRecognizedCurios(in: &state)
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
        EconomyRules.normalizeRecognizedCurios(in: &candidate)
        state = candidate
        state.meta.mutationCount += 1
        state.meta.recordSemanticAction(label)
        state.meta.lastSavedAt = Date()
        if flush { flushNow() } else { scheduleSave() }
        return true
    }

    func commitPersistedIf<Value>(
        _ label: String, attemptID: UUID, stagedAt: Date,
        scope: MutationScope = .ordinary,
        _ body: (inout GameState) -> Value?
    ) -> PersistedCommitResultV1<Value> {
        if let receipt = completedPersistedAttempts[attemptID] {
            return .alreadyCommitted(receipt)
        }
        guard permitsMutationWhileArrivalOwnsRoot(scope) else {
            return .refused(.mutationUnavailable)
        }
        var candidate = state
        guard let value = body(&candidate) else { return .refused(.candidateRefused) }
        EconomyRules.normalizeRecognizedCurios(in: &candidate)
        candidate.meta.mutationCount += 1
        candidate.meta.recordSemanticAction(label)
        candidate.meta.lastSavedAt = stagedAt

        let candidateData: Data
        let normalized: GameState
        do {
            let stagedData = try SaveCodec.encode(candidate)
            normalized = try SaveCodec.decode(stagedData)
            candidateData = try SaveCodec.encode(normalized)
            guard try SaveCodec.decode(candidateData) == normalized else {
                return .refused(.invalidCandidate)
            }
        } catch { return .refused(.invalidCandidate) }

        let hadPendingWrite = diagnostics.hasPendingWrite
        let diagnosticsBefore = diagnostics
        debounceTask?.cancel()
        debounceTask = nil
        writeQueue.sync {}
        let generation = nextPersistenceWriteGeneration
        nextPersistenceWriteGeneration &+= 1
        minimumAcceptedWriteGeneration = generation

        let authority: PersistenceAuthorityV1
        do { authority = try io.persistenceAuthority() }
        catch {
            diagnostics = diagnosticsBefore
            if hadPendingWrite { scheduleSave() }
            return .refused(.persistence(.corruptAuthority))
        }
        let result = writeQueue.sync {
            io.compareAndSwap(expected: authority, candidate: candidateData)
        }
        switch result {
        case .committed(let receipt):
            state = normalized
            completedPersistedAttempts[attemptID] = receipt
            recordAuthoritativeCommit(receipt, generation: generation)
            return .committedNow(value, .init(rawValue: UUID()))
        case .recoveredDurable(let receipt):
            state = normalized
            completedPersistedAttempts[attemptID] = receipt
            recordAuthoritativeCommit(receipt, generation: generation)
            return .recoveredDurable(receipt)
        case .alreadyCommitted(let receipt):
            if normalized != state {
                state = normalized
                completedPersistedAttempts[attemptID] = receipt
                recordAuthoritativeCommit(receipt, generation: generation)
                return .recoveredDurable(receipt)
            }
            completedPersistedAttempts[attemptID] = receipt
            diagnostics = diagnosticsBefore
            if hadPendingWrite { scheduleSave() }
            return .alreadyCommitted(receipt)
        case .refused(let refusal):
            diagnostics = diagnosticsBefore
            if hadPendingWrite { scheduleSave() }
            return .refused(.persistence(refusal))
        }
    }

    /// Synchronously closes every gameplay mutation seam after the durable campaign write and
    /// before coordinator lease retirement can suspend.
    func beginPersistenceClosing() {
        persistenceClosing = true
        debounceTask?.cancel()
        debounceTask = nil
        diagnostics.hasPendingWrite = false
    }

    private func recordAuthoritativeCommit(_ receipt: PersistenceCommitReceiptV1,
                                           generation: UInt64) {
        guard generation >= minimumAcceptedWriteGeneration else { return }
        diagnostics.savedMutationCount = state.meta.mutationCount
        diagnostics.writeCount += 1
        diagnostics.lastError = nil
        diagnostics.hasPendingWrite = false
        diagnostics.saveFileByteCount = receipt.envelopeByteCount ?? receipt.payloadByteCount
    }

    /// One centralized gate covers every stale/debug action path while the arrival owns root
    /// presentation. Only the exact idempotent dismissal or orphan reconciliation may mutate.
    private func permitsMutationWhileArrivalOwnsRoot(_ scope: MutationScope) -> Bool {
        guard !persistenceClosing else { return false }
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
        let generation = nextPersistenceWriteGeneration
        nextPersistenceWriteGeneration &+= 1
        if synchronously {
            let result = writeQueue.sync { Result { try io.write(data) } }
            recordWriteResult(result, mutationCount: snapshot.meta.mutationCount,
                              generation: generation)
        } else {
            writeQueue.async { [weak self] in
                let result = Result { try io.write(data) }
                Task { @MainActor [weak self] in
                    self?.recordWriteResult(result, mutationCount: snapshot.meta.mutationCount,
                                            generation: generation)
                }
            }
        }
    }

    private func recordWriteResult(_ result: Result<Void, Error>, mutationCount: Int,
                                   generation: UInt64) {
        guard generation >= minimumAcceptedWriteGeneration else { return }
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
