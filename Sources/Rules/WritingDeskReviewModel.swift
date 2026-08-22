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
    var glyphID: String
    var displayName: String
    var accessibilityName: String
    var isReadable: Bool
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
    var pageThumbnail: Page
    var visibleMarks: [WritingDeskVisibleMark]
    var unreadMarkCount: Int
    var knownRequests: [String]
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
                glyphID: mark.glyphID,
                displayName: readable ? entries.map(\.displayName).joined(separator: " + ") : "??",
                accessibilityName: readable
                    ? entries.map(\.accessibilityName).joined(separator: ", ")
                    : "Unknown mark",
                isReadable: readable)
        }
        let unreadCount = visibleMarks.filter { !$0.isReadable }.count
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
            pageThumbnail: source.page,
            visibleMarks: visibleMarks,
            unreadMarkCount: unreadCount,
            knownRequests: visibleMarks.filter(\.isReadable).map(\.displayName),
            openSubjects: openSubjects,
            uncertaintyReason: uncertainty,
            stabilityRange: stabilityRange,
            collapseDisclosure: collapseDisclosure,
            sightDisclosure: unreadCount > 0 ? unreadForecast
                : "Sight remains open until the world is bound.",
            dangerDisclosure: unreadCount > 0 ? unreadForecast
                : "Danger remains within the page's disclosed range.",
            ecologyDisclosure: projection.canDescribeLife
                ? "Readable Vitality writing shapes what may live here."
                : "Life remains open to the world.",
            costQuote: source.cost,
            fieldKitSummary: bindAvailability.refusalMessage ?? "Field Kit ready.",
            bindAvailability: bindAvailability)
    }

    private static func canonicalHash<T: Encodable>(_ value: T) -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        guard let data = try? encoder.encode(value) else { return nil }
        return SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }
}

extension GameStore {
    /// Authoritative no-mutation review projection. Availability comes from the existing exact
    /// departure quote path, while the factory owns disclosure and never exposes BookProjection.
    func writingDeskReviewModel(selectedWorldPageID: InstanceID? = nil,
                                bornAnchored: Bool = false) -> WritingDeskReviewModel? {
        let availability = selectedWorldPageID.map {
            bindAvailability(worldPageInstanceID: $0, bornAnchored: bornAnchored)
        } ?? bindAvailability(bornAnchored: bornAnchored)
        return WritingDeskReviewModelFactory.make(
            state: state, selectedWorldPageID: selectedWorldPageID,
            bornAnchored: bornAnchored, bindAvailability: availability,
            tuning: DebugTuningProfile.active)
    }
}
