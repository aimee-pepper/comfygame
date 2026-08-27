import CryptoKit
import Foundation

/// The one source currently under review at the Writing Desk.
///
/// A collected source is deliberately fail-closed: if its exact instance or canonical definition
/// changes, the factory returns `nil` instead of silently reviewing the draft.
enum WritingDeskSourceKey: Equatable, Sendable {
    case draft(pageRevisionID: String)
    case collected(instanceID: InstanceID,
                   definitionID: WorldPageDefinitionID,
                   canonicalDefinitionHash: String)
}

struct WritingDeskVisibleMark: Equatable, Sendable {
    enum AuthoredKind: String, Equatable, Sendable { case target, source, qualifier, compound }
    enum VisualRoute: Equatable, Sendable {
        case authored(AuthoredKind)
        case personalCompoundCompatibility
    }
    /// Opaque visual lookup only. Never legal for copy, ordering or accessibility.
    var rendererAssetKey: String
    var visualRoute: VisualRoute
    var id: InstanceID
    var hand: Hand
    var origin: PageCell
    var shapeID: String
    var cells: [PageCell]
    var inkRecipe: InkRecipe?
    var displayName: String
    var accessibilityName: String
    var isReadable: Bool
}

struct WritingDeskVisibleLink: Equatable, Sendable {
    var firstMarkID: InstanceID
    var secondMarkID: InstanceID
}

/// Physical page receipt with no canonical semantic content.
struct WritingDeskVisiblePage: Equatable, Sendable {
    var width: Int
    var height: Int
    var marks: [WritingDeskVisibleMark]
    var links: [WritingDeskVisibleLink]
}

struct WritingDeskKnownRequest: Equatable, Sendable {
    struct Focus: Equatable, Sendable {
        var name: String
        var qualifiers: [String]
    }
    var subject: String
    var focuses: [Focus]
}

/// Pure, disclosure-safe input for every Writing Desk pane.
///
/// This is intentionally not `BookProjection`. Canonical page facts may be used by simulation,
/// but only values copied into this type are legal for player strings, icons, sorting and
/// accessibility.
struct WritingDeskReviewModel: Equatable, Sendable {
    enum SourceKind: Equatable, Sendable { case draft, collected }
    enum CollapseUpperBound: Equatable, Sendable { case turns(Int), indefinite }
    enum CollapseDisclosure: Equatable, Sendable {
        case range(lower: Int, upper: CollapseUpperBound)

        var copy: String {
            switch self {
            case let .range(lower, .turns(upper)) where lower == upper:
                "Collapse may begin after about \(lower) turns."
            case let .range(lower, .turns(upper)):
                "Collapse may begin after about \(lower)–\(upper) turns."
            case let .range(lower, .indefinite):
                "Collapse may begin after about \(lower) turns, or the world may hold indefinitely."
            }
        }
    }

    var sourceKey: WritingDeskSourceKey
    var sourceKind: SourceKind
    var title: String
    var pageThumbnail: WritingDeskVisiblePage
    var visibleMarks: [WritingDeskVisibleMark]
    var unreadMarkCount: Int
    var knownRequests: [WritingDeskKnownRequest]
    var silentMarkCount: Int
    var openSubjects: [String]?
    var uncertaintyReason: String
    var stabilityRange: ClosedRange<Int>
    var collapseDisclosure: CollapseDisclosure
    var sightDisclosure: String
    var dangerDisclosure: String
    var ecologyDisclosure: String
    var costQuote: Int
    var fieldKitSummary: String
    var bindAvailability: BindAvailability

    var visibleMarkCount: Int { visibleMarks.count }
}

/// Closed player-facing causal summary for the Writing Desk's review pane.
///
/// Keeping this projection beside the redacted review model prevents the SwiftUI surface from
/// reaching back into `BookProjection` for a more precise (and potentially undisclosed) answer.
struct WritingDeskCausalPresentation: Equatable, Sendable {
    struct Request: Equatable, Sendable {
        var subject: String
        var detail: String
    }

    var sourceTitle: String
    var sourceKind: WritingDeskReviewModel.SourceKind
    var sourceState: String
    var requests: [Request]
    var placedMarkState: String?
    var unreadMarkState: String?
    var uncertainty: String
    var stability: String
    var collapse: String
    var sight: String
    var danger: String
    var ecology: String
    var preparation: [String]

    static func make(from review: WritingDeskReviewModel) -> Self {
        let sourceState = switch review.sourceKind {
        case .draft: "Current page · \(review.visibleMarkCount) placed marks"
        case .collected: "Collected World Page · consumed only when departure succeeds"
        }
        let requests = review.knownRequests.map { request in
            Request(
                subject: request.subject,
                detail: request.focuses.map { focus in
                    focus.qualifiers.isEmpty
                        ? focus.name
                        : "\(focus.name); \(focus.qualifiers.joined(separator: ", "))"
                }.joined(separator: " · "))
        }
        let stability = review.stabilityRange.lowerBound == review.stabilityRange.upperBound
            ? "Stability \(review.stabilityRange.lowerBound)"
            : "Stability \(review.stabilityRange.lowerBound)–\(review.stabilityRange.upperBound)"
        return Self(
            sourceTitle: review.title,
            sourceKind: review.sourceKind,
            sourceState: sourceState,
            requests: requests,
            placedMarkState: review.silentMarkCount == 0 ? nil
                : "\(review.silentMarkCount) placed marks are not connected into a request.",
            unreadMarkState: review.unreadMarkCount == 0 ? nil
                : "\(review.unreadMarkCount) marks remain unread.",
            uncertainty: review.uncertaintyReason,
            stability: stability,
            collapse: review.collapseDisclosure.copy,
            sight: review.sightDisclosure,
            danger: review.dangerDisclosure,
            ecology: review.ecologyDisclosure,
            preparation: [review.fieldKitSummary])
    }
}

enum WritingDeskReviewModelFactory {
    /// Builds one redacted model. `selectedWorldPageID != nil` never falls back to the draft.
    static func make(state: GameState,
                     selectedWorldPageID: InstanceID? = nil,
                     bornAnchored: Bool = false,
                     bindAvailability: BindAvailability,
                     tuning: DebugTuningProfile = .defaults) -> WritingDeskReviewModel? {
        let source: (key: WritingDeskSourceKey, kind: WritingDeskReviewModel.SourceKind,
                     title: String, page: Page, seed: UInt64, cost: Int)
        if let selectedWorldPageID {
            let matches = state.base.collectedWorldPages.filter { $0.id == selectedWorldPageID }
            guard matches.count == 1, let instance = matches.first,
                  let canonical = WorldPageCatalog.definition(instance.definition.id),
                  canonical == instance.definition,
                  let hash = canonicalHash(canonical) else { return nil }
            source = (
                .collected(instanceID: instance.id,
                           definitionID: instance.definition.id,
                           canonicalDefinitionHash: hash),
                .collected,
                instance.inspected ? instance.definition.title : "Unknown page",
                instance.definition.page,
                instance.definition.seed,
                instance.definition.worldPageCost
            )
        } else {
            guard let revision = canonicalHash(state.base.page) else { return nil }
            source = (.draft(pageRevisionID: revision), .draft, "Current page",
                      state.base.page, state.worlds.seeds.peekNextSeed(),
                      BookRules.resolveBook(page: state.base.page).essencePaid)
        }

        let dictionary = Dictionary(uniqueKeysWithValues:
            LibraryRules.dictionaryEntries(reality: state.reality, base: state.base)
                .map { ($0.identity, $0) })
        let visibleMarks = source.page.runes.map { mark in
            let identities = mark.content.encounteredLexemes.sorted {
                if $0.categoryOrder != $1.categoryOrder {
                    return $0.categoryOrder < $1.categoryOrder
                }
                return $0.glyphID < $1.glyphID
            }
            let entries = identities.compactMap { dictionary[$0] }
            let readable = entries.count == identities.count && entries.allSatisfy(\.isKnown)
            return WritingDeskVisibleMark(
                rendererAssetKey: mark.glyphID,
                visualRoute: visualRoute(for: mark),
                id: mark.id,
                hand: mark.hand,
                origin: mark.origin,
                shapeID: mark.shapeID,
                cells: mark.cells,
                inkRecipe: mark.inkRecipe,
                displayName: readable ? entries.map(\.displayName).joined(separator: " + ") : "??",
                accessibilityName: readable
                    ? entries.map(\.accessibilityName).joined(separator: ", ")
                    : "Unknown Sigil",
                isReadable: readable)
        }
        let unreadCount = visibleMarks.filter { !$0.isReadable }.count
        let requestProjection = redactedRequests(
            page: source.page, visibleMarks: visibleMarks, dictionary: dictionary)
        let projection = BookProjection.project(
            page: source.page, seed: source.seed,
            analysisTier: state.reality.analysisTier,
            measuring: state.reality.calibratedSubjects,
            precision: state.reality.observations.mapValues(\.bestPrecision),
            tuning: tuning, revealRolled: false)
        let openSubjects: [String]? = unreadCount == 0 ? projection.unwrittenSubjects.map {
            ContentCatalog.shared.pressureTarget($0)?.name ?? $0.rawValue
        } : nil
        let uncertainty: String
        if unreadCount > 0 {
            uncertainty = "Some of this page is still unread. The world may answer it in ways you cannot interpret yet."
        } else if source.page.runes.isEmpty {
            uncertainty = "Nothing is written yet. Every subject is left to the world."
        } else if let openSubjects, openSubjects.isEmpty {
            uncertainty = "Every subject is written."
        } else {
            uncertainty = "\(openSubjects?.count ?? 0) subjects are left to the world: \(openSubjects?.joined(separator: ", ") ?? "")."
        }

        let stabilityRange = unreadCount > 0 ? 0...100 : projection.stabilityScore
        let collapseDisclosure: WritingDeskReviewModel.CollapseDisclosure
        if unreadCount > 0 {
            collapseDisclosure = .range(
                lower: BookRules.turnsAvailable(stabilityScore: 0), upper: .indefinite)
        } else {
            let upper: WritingDeskReviewModel.CollapseUpperBound =
                projection.turnsUntilCollapse.upperBound >= Tuning.World.indefiniteTurns
                ? .indefinite : .turns(projection.turnsUntilCollapse.upperBound)
            collapseDisclosure = .range(lower: projection.turnsUntilCollapse.lowerBound,
                                         upper: upper)
        }
        let unreadForecast = "Some of this page is unread; sight and danger remain open."

        return WritingDeskReviewModel(
            sourceKey: source.key,
            sourceKind: source.kind,
            title: source.title,
            pageThumbnail: WritingDeskVisiblePage(
                width: source.page.width,
                height: source.page.height,
                marks: visibleMarks,
                links: source.page.links.sorted {
                    $0.a.rawValue != $1.a.rawValue
                        ? $0.a.rawValue < $1.a.rawValue : $0.b.rawValue < $1.b.rawValue
                }.map { .init(firstMarkID: $0.a, secondMarkID: $0.b) }),
            visibleMarks: visibleMarks,
            unreadMarkCount: unreadCount,
            knownRequests: requestProjection.requests,
            silentMarkCount: requestProjection.silentMarkCount,
            openSubjects: openSubjects,
            uncertaintyReason: uncertainty,
            stabilityRange: stabilityRange,
            collapseDisclosure: collapseDisclosure,
            sightDisclosure: unreadCount > 0 ? unreadForecast
                : "Sight remains open until the world is bound.",
            dangerDisclosure: unreadCount > 0 ? unreadForecast
                : "Danger remains within the page's disclosed range.",
            ecologyDisclosure: unreadCount > 0
                ? "Some of this page is unread; life remains open."
                : projection.canDescribeLife
                ? "Readable Vitality writing shapes what may live here."
                : "Life remains open to the world.",
            costQuote: source.cost,
            fieldKitSummary: bindAvailability.refusalMessage ?? "Field Kit ready.",
            bindAvailability: bindAvailability)
    }

    private static func visualRoute(for mark: PlacedRune) -> WritingDeskVisibleMark.VisualRoute {
        if mark.personalCompound != nil { return .personalCompoundCompatibility }
        return switch mark.content {
        case .target: .authored(.target)
        case .source, .rune: .authored(.source)
        case .qualifier: .authored(.qualifier)
        case .compound: .authored(.compound)
        }
    }

    static func canonicalHash<T: Encodable>(_ value: T) -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        guard let data = try? encoder.encode(value) else { return nil }
        return SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    private static func redactedRequests(
        page: Page,
        visibleMarks: [WritingDeskVisibleMark],
        dictionary: [LexemeIdentity: LibraryRules.DictionaryEntry]
    ) -> (requests: [WritingDeskKnownRequest], silentMarkCount: Int) {
        let visibleByID = Dictionary(uniqueKeysWithValues: visibleMarks.map { ($0.id, $0) })
        var visited: Set<InstanceID> = []
        var represented: Set<InstanceID> = []
        var requests: [WritingDeskKnownRequest] = []

        func knownName(_ identity: LexemeIdentity) -> String? {
            guard let entry = dictionary[identity], entry.isKnown else { return nil }
            return entry.name
        }

        // Page insertion order is the authored reading order. Cluster membership comes only from
        // physical links; no canonical chain/effect projection is exposed here.
        for first in page.runes where !visited.contains(first.id) {
            let cluster = PageRules.cluster(containing: first.id, on: page)
            cluster.forEach { visited.insert($0.id) }
            guard cluster.allSatisfy({ visibleByID[$0.id]?.isReadable == true }) else { continue }

            if cluster.count == 1, let mark = cluster.first {
                switch mark.content {
                case .rune(let sigil):
                    guard let subject = knownName(.target(sigil.target)),
                          let focus = knownName(.source(sigil.source)) else { continue }
                    requests.append(.init(subject: subject,
                                          focuses: [.init(name: focus, qualifiers: [])]))
                    represented.insert(mark.id)
                    continue
                case .compound(let id):
                    guard let name = knownName(.compound(id)) else { continue }
                    requests.append(.init(subject: name, focuses: []))
                    represented.insert(mark.id)
                    continue
                default: break
                }
            }

            guard let targetMark = cluster.first(where: { $0.targetID != nil }),
                  let targetID = targetMark.targetID,
                  let subject = knownName(.target(targetID)) else { continue }
            let sourceMarks = cluster.filter { $0.sourceID != nil }
            guard !sourceMarks.isEmpty else { continue }
            var focuses: [WritingDeskKnownRequest.Focus] = []
            for sourceMark in sourceMarks {
                guard let sourceID = sourceMark.sourceID,
                      let name = knownName(.source(sourceID)) else { focuses = []; break }
                let qualifierMarks = page.links.compactMap { $0.other(than: sourceMark.id) }
                    .compactMap { id in cluster.first { $0.id == id && $0.qualifierID != nil } }
                let qualifierNames = qualifierMarks.compactMap(\.qualifierID)
                    .compactMap { knownName(.qualifier($0)) }
                focuses.append(.init(name: name, qualifiers: qualifierNames))
                represented.insert(sourceMark.id)
                qualifierMarks.forEach { represented.insert($0.id) }
            }
            guard focuses.count == sourceMarks.count else { continue }
            requests.append(.init(subject: subject, focuses: focuses))
            represented.insert(targetMark.id)
        }
        let silent = page.runes.filter {
            visibleByID[$0.id]?.isReadable == true && !represented.contains($0.id)
        }.count
        return (requests, silent)
    }
}

struct WritingDeskPreparedInkApplication: Equatable, Sendable {
    var vialID: UInt64
    var recipe: InkRecipe
    var before: Int
    var spend: Int
    var after: Int
}

struct WritingDeskAnchorageReceipt: Equatable, Sendable {
    var bornAnchored: Bool
    var isUnlocked: Bool
    var stationTier: Int
    var premium: Int
}

private struct WritingDeskFieldKitRevision: Encodable {
    var entries: [FieldKitPreparationEntry]
    var capacity: Int
    var needsReview: Bool
    var sourceInventory: Inventory
}

/// The complete staged authority shown by the fixed Bind bar and revalidated by commit.
struct WritingDeskBindQuote: Equatable, Sendable {
    static let currentVersion = "writing-bind-quote-v1"

    var quoteVersion: String
    var sourceKey: WritingDeskSourceKey
    var frozenPageHash: String
    var reservedCampaignSeed: UInt64
    var generationSeed: UInt64
    var pageCost: Int
    var availableEssence: Int
    var essenceAfter: Int
    var anchorageReceipt: WritingDeskAnchorageReceipt
    var preparedInkReceipt: [WritingDeskPreparedInkApplication]
    var fieldKitLoadoutHash: String
    var fieldKitReceipt: FieldKitDepartureEvaluation
    var availability: BindAvailability

    var totalCost: Int { pageCost + anchorageReceipt.premium }
}

enum WritingDeskBindQuoteFactory {
    @MainActor
    static func make(state: GameState, selectedWorldPageID: InstanceID? = nil,
                     bornAnchored: Bool = false) -> WritingDeskBindQuote? {
        let page: Page
        let pageCost: Int
        let generationSeed: UInt64
        let sourceKey: WritingDeskSourceKey
        if let selectedWorldPageID {
            let matches = state.base.collectedWorldPages.filter { $0.id == selectedWorldPageID }
            guard matches.count == 1, let instance = matches.first,
                  let canonical = WorldPageCatalog.definition(instance.definition.id),
                  canonical == instance.definition,
                  let hash = WritingDeskReviewModelFactory.canonicalHash(canonical) else { return nil }
            page = instance.definition.page
            pageCost = instance.definition.worldPageCost
            generationSeed = instance.definition.seed
            sourceKey = .collected(instanceID: instance.id,
                                   definitionID: instance.definition.id,
                                   canonicalDefinitionHash: hash)
        } else {
            page = state.base.page
            pageCost = BookRules.resolveBook(page: page).essencePaid
            generationSeed = state.worlds.seeds.peekNextSeed()
            guard let revision = WritingDeskReviewModelFactory.canonicalHash(page) else { return nil }
            sourceKey = .draft(pageRevisionID: revision)
        }
        let fieldKit = GameStore.fieldKitDepartureQuote(in: state)
        let anchorPremium = bornAnchored
            ? GameStore.bornAnchoredPremium(forBookCost: pageCost) : 0
        let total = pageCost + anchorPremium
        let availability: BindAvailability
        if state.worlds.activeRun != nil {
            availability = .activeExpedition
        } else if case .refused(let reason) = fieldKit {
            availability = .fieldKit(reason)
        } else if bornAnchored && !state.base.station(Stations.anchorage).isUnlocked {
            availability = .anchorageLocked
        } else if state.base.essenceCrystalCount < total {
            availability = .insufficientEssence(available: state.base.essenceCrystalCount, required: total)
        } else if let reason = GameStore.inkDepartureRefusal(page: page, in: state.base) {
            availability = .unavailable(reason)
        } else {
            availability = .ready(totalCost: total)
        }

        let requirements = GameStore.inkRequirements(on: page)
        var inkReceipt: [WritingDeskPreparedInkApplication] = []
        for recipe in requirements.keys.sorted(by: inkRecipeOrder) {
            var remaining = requirements[recipe] ?? 0
            for vial in state.base.preparedInkVials
                .filter({ $0.recipe == recipe }).sorted(by: { $0.id < $1.id }) where remaining > 0 {
                let spend = min(remaining, vial.remainingApplications)
                inkReceipt.append(.init(vialID: vial.id, recipe: recipe,
                                        before: vial.remainingApplications,
                                        spend: spend,
                                        after: vial.remainingApplications - spend))
                remaining -= spend
            }
        }
        let station = state.base.station(Stations.anchorage)
        let loadoutHash = WritingDeskReviewModelFactory.canonicalHash(
            WritingDeskFieldKitRevision(
                entries: GameStore.canonicalFieldKitEntries(state.base.preparationLoadout ?? []),
                capacity: state.base.satchelCapacity,
                needsReview: state.base.preparationLoadoutNeedsReview,
                sourceInventory: state.base.inventory)) ?? ""
        guard let frozenPageHash = WritingDeskReviewModelFactory.canonicalHash(page) else { return nil }
        return .init(quoteVersion: WritingDeskBindQuote.currentVersion,
                     sourceKey: sourceKey,
                     frozenPageHash: frozenPageHash,
                     reservedCampaignSeed: state.worlds.seeds.peekNextSeed(),
                     generationSeed: generationSeed,
                     pageCost: pageCost,
                     availableEssence: state.base.essenceCrystalCount,
                     essenceAfter: state.base.essenceCrystalCount - total,
                     anchorageReceipt: .init(bornAnchored: bornAnchored,
                                             isUnlocked: station.isUnlocked,
                                             stationTier: station.tier,
                                             premium: anchorPremium),
                     preparedInkReceipt: inkReceipt,
                     fieldKitLoadoutHash: loadoutHash,
                     fieldKitReceipt: fieldKit,
                     availability: availability)
    }

    private static func inkRecipeOrder(_ lhs: InkRecipe, _ rhs: InkRecipe) -> Bool {
        let left = [lhs.cyan, lhs.magenta, lhs.yellow, lhs.depth]
        let right = [rhs.cyan, rhs.magenta, rhs.yellow, rhs.depth]
        return left == right
            ? lhs.conversionVersion < rhs.conversionVersion
            : left.lexicographicallyPrecedes(right)
    }
}

extension GameStore {
    /// Authoritative no-mutation review projection. The strict departure quote validates the
    /// exact source first; its availability then owns both the review and the fixed Bind rail.
    func writingDeskReviewModel(selectedWorldPageID: InstanceID? = nil,
                                bornAnchored: Bool = false) -> WritingDeskReviewModel? {
        guard let quote = writingDeskBindQuote(
            selectedWorldPageID: selectedWorldPageID, bornAnchored: bornAnchored),
              let review = WritingDeskReviewModelFactory.make(
            state: writingDeskState, selectedWorldPageID: selectedWorldPageID,
            bornAnchored: bornAnchored, bindAvailability: quote.availability,
            tuning: DebugTuningProfile.active),
              review.sourceKey == quote.sourceKey else { return nil }
        return review
    }

    func writingDeskBindQuote(selectedWorldPageID: InstanceID? = nil,
                              bornAnchored: Bool = false) -> WritingDeskBindQuote? {
        WritingDeskBindQuoteFactory.make(
            state: writingDeskState, selectedWorldPageID: selectedWorldPageID,
            bornAnchored: bornAnchored)
    }
}
