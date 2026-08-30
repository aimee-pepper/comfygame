import Foundation

enum FirstReturnTutorialFactResultV1: Equatable, Sendable {
    case committed
    case alreadyCompleted
    case refused(FirstReturnTutorialFactRefusalV1)
}

enum FirstReturnTutorialFactRefusalV1: Equatable, Sendable {
    case noFrozenContext
    case wrongDestination(expected: AppRoute, actual: AppRoute)
    case recoveredRecordUnavailable
    case staleContext
}

struct TutorialLessonDefinition: Identifiable, Sendable {
    enum Group: String, CaseIterable, Sendable { case writing = "Writing", worlds = "Worlds" }
    let id: TutorialLessonID
    let group: Group
    let title: String
    let body: String
    let anchorLabel: String
}

enum TutorialRules {
    static let definitions: [TutorialLessonDefinition] = [
        .init(id: .writingPageRequest, group: .writing, title: "A page is a request",
              body: "Choose a word and place its Sigil—or leave Subjects unwritten and let the world decide.",
              anchorLabel: "Page grid"),
        .init(id: .writingPageSpace, group: .writing, title: "Sigils take room",
              body: "The number on a word is its footprint; one Page cannot hold every request.",
              anchorLabel: "Palette footprint"),
        .init(id: .writingPreview, group: .writing, title: "Reading the preview",
              body: "Written Subjects are described; unwritten Subjects remain ranges until binding.",
              anchorLabel: "The world pane"),
        .init(id: .writingBind, group: .writing, title: "Binding an expedition",
              body: "Binding spends the shown essence and opens one expedition. The book and everything you learn remain recorded after the trip ends.",
              anchorLabel: "Bind & Depart"),
        .init(id: .worldNavigation, group: .worlds, title: "Moving through a world",
              body: "Tap a reachable space to travel there, or use the arrows one step at a time. Movement spends world turns and stops when something needs you.",
              anchorLabel: "Map and direction arrows"),
        .init(id: .worldStability, group: .worlds, title: "Stability and collapse",
              body: "World actions spend turns. At zero Stability the world starts coming apart; you may still race for a portal while floor remains.",
              anchorLabel: "Stability meter"),
        .init(id: .worldInteraction, group: .worlds, title: "Actions where you stand",
              body: "Standing somewhere useful reveals what you can do here. Each action says whether it spends a turn or consumes something.",
              anchorLabel: "World actions"),
        .init(id: .worldReturn, group: .worlds, title: "Returning home",
              body: "A portal returns the full haul. If defeat or the collapsing floor carries you home, knowledge stays and only part of what you found may be lost.",
              anchorLabel: "Portal home"),
        .init(id: .returnPersistenceBoundary, group: .worlds, title: "What crossed home",
              body: "Recovered resources and objects come home with you. Writing, discoveries, and people stay with you even when part of a haul was lost.",
              anchorLabel: "Expedition recap"),
        .init(id: .baseFirstResultRoute, group: .worlds, title: "Follow what returned",
              body: "Your first result points to one place in the village. The route stays the same if you visit it later.",
              anchorLabel: "Village destination"),
        .init(id: .libraryFirstWriting, group: .worlds, title: "Reading recovered writing",
              body: "The Library keeps recovered words as written. It does not translate traveller passages into checklists.",
              anchorLabel: "Recovered record"),
        .init(id: .writingCompareRequest, group: .writing, title: "Change one request and compare",
              body: "Add, remove or replace one focus under a subject, then inspect The world. Everything left unwritten may still roll differently.",
              anchorLabel: "Page and The world"),
        .init(id: .historyCompareWorlds, group: .writing, title: "Read two records together",
              body: "Changed writing is emphasized; other differences may have come from what neither page controlled.",
              anchorLabel: "World History comparison")
    ]

    static func freezeFirstReturnContext(run: WorldRun, banked: GameStore.BankedHaul,
                                         in state: inout GameState) {
        guard state.tutorial.firstReturnContext == nil else { return }
        let authoredPageOrder = Dictionary(uniqueKeysWithValues:
            ContentCatalog.shared.diaryPages.enumerated().map { ($0.element.id, $0.offset) })
        let newPages = state.reality.library.foundPages
            .filter { !run.foundPagesAtStart.contains($0) }
            .sorted { (authoredPageOrder[$0] ?? .max, $0.rawValue)
                    < (authoredPageOrder[$1] ?? .max, $1.rawValue) }
        let newWritings = state.reality.library.foundWritings.filter {
            !run.foundWritingsAtStart.contains($0.id)
        }
        let newTravellers = state.reality.library.foundTravellers
            .subtracting(run.foundTravellersAtStart)
        let context: FirstReturnTutorialContext
        if let page = newPages.first {
            context = .init(runIndex: run.runIndex, route: .library, reason: .diaryPage,
                            writingID: page.rawValue)
        } else if let writing = newWritings.first {
            let reason: FirstReturnTutorialContext.Reason = switch writing.family {
            case .fieldNote: .fieldNote
            case .routeMark: .routeMark
            case .siteFragment: .siteFragment
            case .workingScrap: .workingScrap
            }
            context = .init(runIndex: run.runIndex, route: .library, reason: reason,
                            writingID: String(writing.id.rawValue))
        } else if let item = banked.unidentifiedItemIDs.first {
            context = .init(runIndex: run.runIndex, route: .storehouse,
                            reason: .unidentifiedObject, writingID: item.rawValue)
        } else if banked.returnedRawEssence
                    && state.base.essenceCrystalCount < EconomyRules.minimumBindCost(in: state) {
            context = .init(runIndex: run.runIndex, route: .essenceSpring,
                            reason: .rawEssence, writingID: nil)
        } else if let traveller = newTravellers.sorted(by: { $0.rawValue < $1.rawValue }).first {
            context = .init(runIndex: run.runIndex, route: .firepit,
                            reason: .traveller, writingID: traveller.rawValue)
        } else {
            context = .init(runIndex: run.runIndex, route: .writingDesk,
                            reason: .ordinaryReturn, writingID: nil)
        }
        state.tutorial.firstReturnContext = context
        state.tutorial.becameEligible(.returnPersistenceBoundary, runIndex: run.runIndex)
    }

    static func destination(for route: FirstReturnTutorialContext.Route) -> AppRoute {
        switch route {
        case .library: .library
        case .storehouse: .storehouse
        case .workshop: .essenceSpring
        case .essenceSpring: .essenceSpring
        case .firepit: .firepit
        case .writingDesk: .writingDesk
        }
    }

    static func routeCopy(_ context: FirstReturnTutorialContext, in state: GameState) -> String {
        switch context.route {
        case .library:
            return libraryCopy(context, in: state)
                ?? "You brought back writing. The Library keeps its words beside everything else you have learned. The selected record is not present in this migrated save."
        case .storehouse: return "Something returned without a known name. The Storehouse is where an object can be identified without guessing at its use."
        case .workshop: return "Raw essence cannot bind a page. Refine what returned at the Essence Spring."
        case .essenceSpring: return "Raw essence cannot bind a page. Refine what returned at the Essence Spring."
        case .firepit: return "Someone new is in the village. The Firepit is where you choose who travels; Party holds their stats, gear, rank and gambits."
        case .writingDesk: return "This journey is now part of World History. Bind again when you want another comparison."
        }
    }

    static func libraryCopy(_ context: FirstReturnTutorialContext, in state: GameState) -> String? {
        guard context.route == .library, let rawID = context.writingID else { return nil }
        if context.reason == .diaryPage {
            let id = DiaryPageID(rawValue: rawID)
            guard state.reality.library.foundPages.contains(id),
                  let page = ContentCatalog.shared.diaryPage(id) else { return nil }
            let author = ContentCatalog.shared.traveller(page.diary)?.name ?? page.diary.rawValue
            if page.kind == .locationClue, let about = page.about,
               let traveller = ContentCatalog.shared.traveller(about) {
                return "Every world holds some kind of writing. This passage describes one part of a world where \(traveller.name) can be found. Compare its words with world descriptions; the Library will not translate it into a checklist."
            }
            return "This page belongs to \(author)'s book. Its heading shows what kind of knowledge it carries; it is not necessarily a location clue."
        }
        guard let writing = state.reality.library.foundWritings.first(where: { $0.id.rawValue == rawID })
        else { return nil }
        return switch writing.family {
        case .fieldNote: "A Field note remembers one truthful relation from the place where it was found. It can help you read worlds, but it is not part of a traveller's location."
        case .routeMark: "A Route sketch preserves one short path from that world. It reveals no destination beyond the sketched ground."
        case .siteFragment: "A Site fragment records words tied to a place you could already see. It does not reveal what the site contains."
        case .workingScrap: "A Working scrap teaches one ordinary recipe. It grants the knowledge, not the item or the materials to make it."
        }
    }

    static func definition(_ id: TutorialLessonID) -> TutorialLessonDefinition? {
        definitions.first { $0.id == id }
    }

    static func recordExpeditionOutcome(in state: inout GameState) {
        state.tutorial.complete(.worldReturn, fact: "first_expedition_outcome")
    }

    static func semanticRequests(on page: Page) -> [String] {
        PageRules.chains(on: page).map { chain in
            "\(chain.target) ← " + chain.parts.map { part in
                (part.qualifiers.map(\.name) + [part.source] + part.negates.sorted().map { "not \($0)" })
                    .joined(separator: " · ")
            }.joined(separator: " + ")
        }.sorted()
    }

    /// Count changed subject requests, independent of mark identity, position, rotation or hand.
    static func semanticChangeCount(from old: [String], to new: [String]) -> Int {
        func keyed(_ lines: [String]) -> [String: String] {
            Dictionary(lines.map { line in
                let subject = line.components(separatedBy: " ← ").first ?? line
                return (subject, line)
            }, uniquingKeysWith: { _, latter in latter })
        }
        let lhs = keyed(old), rhs = keyed(new)
        return Set(lhs.keys).union(rhs.keys).reduce(0) { count, key in
            count + (lhs[key] == rhs[key] ? 0 : 1)
        }
    }

    static func noteComparisonPreview(page: Page, in state: inout GameState) {
        guard state.tutorial.comparisonPair == nil,
              let origin = state.reality.library.visitedWorlds.last else { return }
        state.tutorial.becameEligible(.writingCompareRequest, runIndex: state.worlds.runIndex)
        let count = semanticChangeCount(from: origin.semanticRequests,
                                        to: semanticRequests(on: page))
        guard count > 0 else { return }
        state.tutorial.pendingComparisonOriginID = origin.id
        state.tutorial.pendingComparisonIsOneChange = count == 1
        if count == 1 {
            state.tutorial.complete(.writingCompareRequest, fact: "one_semantic_request_changed")
        }
    }

    static func pairNewWorld(_ partner: VisitedWorld, in state: inout GameState) {
        guard let origin = state.tutorial.pendingComparisonOriginID,
              origin != partner.id,
              let originRecord = state.reality.library.visitedWorlds.first(where: { $0.id == origin }) else { return }
        let actualChangeCount = semanticChangeCount(from: originRecord.semanticRequests,
                                                    to: partner.semanticRequests)
        guard actualChangeCount > 0 else {
            state.tutorial.pendingComparisonOriginID = nil
            state.tutorial.pendingComparisonIsOneChange = false
            return
        }
        state.tutorial.comparisonPair = .init(originID: origin, partnerID: partner.id,
                                              isOneChangeExercise: actualChangeCount == 1)
        state.tutorial.pendingComparisonOriginID = nil
        state.tutorial.pendingComparisonIsOneChange = false
        state.tutorial.becameEligible(.historyCompareWorlds, runIndex: partner.runIndex)
    }

    static func reconcileComparisonPair(in state: inout GameState) {
        guard let pair = state.tutorial.comparisonPair else { return }
        let ids = Set(state.reality.library.visitedWorlds.map(\.id))
        if !ids.contains(pair.originID) || !ids.contains(pair.partnerID) {
            state.tutorial.comparisonPair = nil
        }
    }
}

extension GameStore {
    func expeditionReviewContinueQuote() -> ExpeditionReviewContinueQuoteV1? {
        ExpeditionReviewContinueQuoteV1.make(from: state)
    }

    @discardableResult
    func acknowledgeExpeditionReview(
        quote: ExpeditionReviewContinueQuoteV1
    ) -> ExpeditionReviewContinueResultV1 {
        guard !expeditionReviewAcknowledgementInFlight else { return .busy }
        guard quote.version == ExpeditionReviewContinueQuoteV1.version,
              quote.headOrdinal == 0,
              !quote.headFingerprintSHA256.isEmpty,
              !quote.queueRevisionSHA256.isEmpty else { return .refused(.invalidQuote) }
        if state.worlds.expeditionReviewQueue.acknowledged.contains(quote.head.reviewID) {
            return .alreadyAcknowledged
        }
        guard let currentHead = state.worlds.pendingExpeditionReview else {
            return .stale(.noPresentedReview)
        }
        guard currentHead == quote.head else { return .stale(.changedReview) }
        guard state.tutorial.firstReturnContext == quote.firstReturnContext else {
            return .stale(.changedTutorialContext)
        }
        guard quote.exactlyMatches(state) else { return .stale(.changedReview) }

        expeditionReviewAcknowledgementInFlight = true
        defer { expeditionReviewAcknowledgementInFlight = false }
#if DEBUG
        expeditionReviewBeforeCommitForTesting?()
#endif
        let committed = mutateIf("acknowledge expedition review", flush: true) { state in
            guard quote.exactlyMatches(state),
                  let removed = state.worlds.expeditionReviewQueue.pending.first,
                  removed == quote.head else { return false }
            state.worlds.expeditionReviewQueue.pending.removeFirst()
            state.worlds.expeditionReviewQueue.acknowledged.append(removed.reviewID)
            if state.worlds.expeditionReviewQueue.acknowledged.count
                > ExpeditionReviewQueueV1.acknowledgedLimit {
                state.worlds.expeditionReviewQueue.acknowledged.removeFirst(
                    state.worlds.expeditionReviewQueue.acknowledged.count
                        - ExpeditionReviewQueueV1.acknowledgedLimit)
            }
            if quote.firstReturnContext != nil {
                state.tutorial.complete(.returnPersistenceBoundary,
                                        fact: "first_recap_acknowledged")
                state.tutorial.becameEligible(.baseFirstResultRoute,
                                              runIndex: removed.summary.runIndex)
            }
            return true
        }
        return committed ? .acknowledged : .stale(.changedReview)
    }

    func tutorialEligible(_ id: TutorialLessonID) {
        mutate("tutorial eligible: \(id.rawValue)") { state in
            state.tutorial.becameEligible(id, runIndex: state.worlds.runIndex)
        }
    }

    func deferTutorial(_ id: TutorialLessonID) {
        mutate("tutorial deferred: \(id.rawValue)") { $0.tutorial.deferLesson(id) }
    }

    func completeTutorial(_ id: TutorialLessonID, fact: String) {
        mutate("tutorial completed: \(id.rawValue)") { $0.tutorial.complete(id, fact: fact) }
    }

    func replayTutorial(_ id: TutorialLessonID) {
        mutate("tutorial replay: \(id.rawValue)") { state in
            var progress = state.tutorial[id]
            progress.status = .deferred
            state.tutorial[id] = progress
        }
    }

    @discardableResult
    func acknowledgeExpeditionReview(
        _ reviewID: ExpeditionReviewID
    ) -> ExpeditionReviewAcknowledgementResult {
        if state.worlds.expeditionReviewQueue.acknowledged.contains(reviewID) {
            return .alreadyAcknowledged
        }
        guard let presented = state.worlds.pendingExpeditionReview else {
            return .stale(expected: nil, actual: reviewID)
        }
        guard presented.reviewID == reviewID else {
            if case .outcome(let attempted) = reviewID,
               case .outcome(let expected) = presented.reviewID,
               attempted.rawValue < expected.rawValue,
               !state.worlds.expeditionReviewQueue.pending.contains(where: {
                   $0.reviewID == reviewID
               }) {
                return .alreadyAcknowledged
            }
            return .stale(expected: presented.reviewID, actual: reviewID)
        }
        guard let quote = expeditionReviewContinueQuote() else {
            return .stale(expected: nil, actual: reviewID)
        }
        switch acknowledgeExpeditionReview(quote: quote) {
        case .acknowledged: return .acknowledged
        case .alreadyAcknowledged: return .alreadyAcknowledged
        case .stale, .refused, .busy:
            return .stale(expected: state.worlds.pendingExpeditionReview?.reviewID,
                          actual: reviewID)
        }
    }

    @discardableResult
    func acknowledgeFirstReturnRecap() -> ExpeditionReviewAcknowledgementResult {
        guard let reviewID = state.worlds.pendingExpeditionReview?.reviewID else {
            return .stale(expected: nil, actual: .legacy("missing-review"))
        }
        return acknowledgeExpeditionReview(reviewID)
    }

    @discardableResult
    func openedFirstReturnDestination(_ route: AppRoute) -> FirstReturnTutorialFactResultV1 {
        guard let context = state.tutorial.firstReturnContext else {
            return .refused(.noFrozenContext)
        }
        let expected = TutorialRules.destination(for: context.route)
        guard expected == route else {
            return .refused(.wrongDestination(expected: expected, actual: route))
        }
        guard state.tutorial[.baseFirstResultRoute].status != .completed else {
            return .alreadyCompleted
        }
        let committed = mutateIf("opened first return destination") { state in
            guard state.tutorial.firstReturnContext == context,
                  TutorialRules.destination(for: context.route) == route,
                  state.tutorial[.baseFirstResultRoute].status != .completed else { return false }
            state.tutorial.complete(.baseFirstResultRoute, fact: "first_result_destination_opened")
            return true
        }
        return committed ? .committed : .refused(.staleContext)
    }

    @discardableResult
    func displayedFirstReturnWriting(
        _ renderedContext: FirstReturnTutorialContext
    ) -> FirstReturnTutorialFactResultV1 {
        guard let context = state.tutorial.firstReturnContext else {
            return .refused(.noFrozenContext)
        }
        guard context == renderedContext else { return .refused(.staleContext) }
        guard context.route == .library,
              TutorialRules.libraryCopy(context, in: state) != nil else {
            return .refused(.recoveredRecordUnavailable)
        }
        guard state.tutorial[.libraryFirstWriting].status != .completed else {
            return .alreadyCompleted
        }
        let committed = mutateIf("displayed first return writing") { state in
            guard state.tutorial.firstReturnContext == renderedContext,
                  renderedContext.route == .library,
                  TutorialRules.libraryCopy(renderedContext, in: state) != nil,
                  state.tutorial[.libraryFirstWriting].status != .completed else { return false }
            state.tutorial.complete(.libraryFirstWriting, fact: "first_writing_displayed")
            return true
        }
        return committed ? .committed : .refused(.staleContext)
    }

    func openedComparisonPreview() {
        mutate("opened semantic comparison preview") { state in
            TutorialRules.noteComparisonPreview(page: state.base.page, in: &state)
        }
    }

    func openedWorldComparison() {
        completeTutorial(.historyCompareWorlds, fact: "comparison_opened")
    }
}
