import Foundation

enum TutorialLessonID: String, Codable, CaseIterable, Sendable {
    case writingPageRequest = "writing.page_request.v1"
    case writingPageSpace = "writing.page_space.v1"
    case writingPreview = "writing.preview.v1"
    case writingBind = "writing.bind.v1"
    case worldNavigation = "world.navigation.v1"
    case worldStability = "world.stability.v1"
    case worldInteraction = "world.interaction.v1"
    case worldReturn = "world.return.v1"
    case returnPersistenceBoundary = "return.persistence_boundary.v1"
    case baseFirstResultRoute = "base.first_result_route.v1"
    case libraryFirstWriting = "library.first_writing.v1"
    case writingCompareRequest = "writing.compare_request.v1"
    case historyCompareWorlds = "history.compare_worlds.v1"
}

enum TutorialLessonStatus: String, Codable, Sendable {
    case unseen, deferred, completed
}

struct TutorialLessonProgress: Codable, Equatable, Sendable {
    var status: TutorialLessonStatus = .unseen
    var firstEligibleRunIndex: Int?
    var completedByFact: String?
}

struct TutorialState: Codable, Equatable, Sendable {
    var version: Int = 1
    /// Raw stable IDs preserve unknown future lessons across tolerant decoding.
    var lessons: [String: TutorialLessonProgress] = [:]
    var durableFacts: Set<String> = []
    var firstReturnContext: FirstReturnTutorialContext?
    var pendingComparisonOriginID: InstanceID?
    var pendingComparisonIsOneChange: Bool = false
    var comparisonPair: TutorialComparisonPair?

    init(version: Int = 1, lessons: [String: TutorialLessonProgress] = [:],
         durableFacts: Set<String> = [], firstReturnContext: FirstReturnTutorialContext? = nil,
         pendingComparisonOriginID: InstanceID? = nil,
         pendingComparisonIsOneChange: Bool = false,
         comparisonPair: TutorialComparisonPair? = nil) {
        self.version = version
        self.lessons = lessons
        self.durableFacts = durableFacts
        self.firstReturnContext = firstReturnContext
        self.pendingComparisonOriginID = pendingComparisonOriginID
        self.pendingComparisonIsOneChange = pendingComparisonIsOneChange
        self.comparisonPair = comparisonPair
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = try container.decodeIfPresent(Int.self, forKey: .version) ?? 1
        lessons = try container.decodeIfPresent([String: TutorialLessonProgress].self,
                                                 forKey: .lessons) ?? [:]
        durableFacts = try container.decodeIfPresent(Set<String>.self, forKey: .durableFacts) ?? []
        firstReturnContext = try container.decodeIfPresent(FirstReturnTutorialContext.self,
                                                            forKey: .firstReturnContext)
        pendingComparisonOriginID = try container.decodeIfPresent(InstanceID.self, forKey: .pendingComparisonOriginID)
        pendingComparisonIsOneChange = try container.decodeIfPresent(Bool.self, forKey: .pendingComparisonIsOneChange) ?? false
        comparisonPair = try container.decodeIfPresent(TutorialComparisonPair.self, forKey: .comparisonPair)
    }

    subscript(_ id: TutorialLessonID) -> TutorialLessonProgress {
        get { lessons[id.rawValue] ?? TutorialLessonProgress() }
        set { lessons[id.rawValue] = newValue }
    }

    mutating func becameEligible(_ id: TutorialLessonID, runIndex: Int) {
        var progress = self[id]
        if progress.firstEligibleRunIndex == nil { progress.firstEligibleRunIndex = runIndex }
        self[id] = progress
    }

    mutating func deferLesson(_ id: TutorialLessonID) {
        var progress = self[id]
        guard progress.status != .completed else { return }
        progress.status = .deferred
        self[id] = progress
    }

    mutating func complete(_ id: TutorialLessonID, fact: String) {
        durableFacts.insert(fact)
        var progress = self[id]
        progress.status = .completed
        progress.completedByFact = fact
        self[id] = progress
    }

    mutating func reconcile(with state: GameState) {
        let inferred: [(TutorialLessonID, String, Bool)] = [
            (.writingPageRequest, "first_bind", state.worlds.runIndex > 0),
            (.writingPageSpace, "mark_placed", !state.base.page.runes.isEmpty),
            (.writingPreview, "world_pane_opened", state.worlds.runIndex > 0),
            (.writingBind, "first_run_created", state.worlds.runIndex > 0),
            (.worldNavigation, "first_movement", (state.worlds.activeRun?.turnsTaken ?? 0) > 0 || state.worlds.lastExit != nil),
            (.worldStability, "post_turn_meter_seen", (state.worlds.activeRun?.turnsTaken ?? 0) > 0 || state.worlds.lastExit != nil),
            (.worldReturn, "first_expedition_outcome", state.worlds.lastExit != nil)
        ]
        for (id, fact, exists) in inferred where exists { complete(id, fact: fact) }
    }
}

struct TutorialComparisonPair: Codable, Equatable, Sendable {
    var originID: InstanceID
    var partnerID: InstanceID
    var isOneChangeExercise: Bool
}

struct FirstReturnTutorialContext: Codable, Equatable, Sendable {
    enum Route: String, Codable, Sendable {
        case library, storehouse, workshop, essenceSpring, firepit, writingDesk
    }
    enum Reason: String, Codable, Sendable {
        case diaryPage, fieldNote, routeMark, siteFragment, workingScrap
        case unidentifiedObject, rawEssence, traveller, ordinaryReturn
    }
    var runIndex: Int
    var route: Route
    var reason: Reason
    var writingID: String?
    var rawRoute: String? = nil
    var rawReason: String? = nil

    private enum CodingKeys: String, CodingKey { case runIndex, route, reason, writingID }

    init(runIndex: Int, route: Route, reason: Reason, writingID: String?,
         rawRoute: String? = nil, rawReason: String? = nil) {
        self.runIndex = runIndex
        self.route = route
        self.reason = reason
        self.writingID = writingID
        self.rawRoute = rawRoute
        self.rawReason = rawReason
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        runIndex = try c.decodeIfPresent(Int.self, forKey: .runIndex) ?? 0
        let routeValue = try c.decodeIfPresent(String.self, forKey: .route) ?? Route.writingDesk.rawValue
        route = Route(rawValue: routeValue) ?? .writingDesk
        rawRoute = Route(rawValue: routeValue) == nil ? routeValue : nil
        let reasonValue = try c.decodeIfPresent(String.self, forKey: .reason) ?? Reason.ordinaryReturn.rawValue
        reason = Reason(rawValue: reasonValue) ?? .ordinaryReturn
        rawReason = Reason(rawValue: reasonValue) == nil ? reasonValue : nil
        writingID = try c.decodeIfPresent(String.self, forKey: .writingID)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(runIndex, forKey: .runIndex)
        try c.encode(rawRoute ?? route.rawValue, forKey: .route)
        try c.encode(rawReason ?? reason.rawValue, forKey: .reason)
        try c.encodeIfPresent(writingID, forKey: .writingID)
    }
}
