import XCTest
@testable import Bookbinder

/// **The vocabulary is a progression** — rune spec principle 2, *"every **discovered** rune stays
/// writable forever"*, whose first word never meant anything: the palette listed the whole catalogue,
/// so a new player had all forty-two focuses on their first page and nothing found out in a world
/// could ever be a word they didn't have.
///
/// These are the three claims that make a locked vocabulary better than an open one rather than
/// worse: you can already say something about everything, everything else is *gettable*, and nothing
/// is ever taken back.
final class VocabularyTests: XCTestCase {

    private var starters: Set<PressureSourceID> { Set(ContentCatalog.shared.starterSourceIDs) }

    // MARK: What you start with, and what you don't

    /// **Not every subject is writable at the start, and that is the design** (Aimee, via
    /// `sigil-vocabulary.md` §4): *"A starting player has coarse words for some subjects and nothing
    /// at all for others… a subject you can't write is a subject that's always rolled, so early
    /// worlds have more chance in them, and every new subject you learn is a piece of the world
    /// moving from luck into your hands."*
    ///
    /// I had asserted the opposite — every subject writable both ways on turn one — which was my own
    /// rule, cut by measurement while filling the subtractive gaps, and it is overruled. What
    /// survives is the half that was never mine: **Cycle in particular should start unwritable**, so
    /// learning to name a world's rhythm is a thing that happens to you.
    func testSomeSubjectsStartUnwritableAndThatIsThePoint() {
        let starters = Set(ContentCatalog.shared.starterSourceIDs)
        let writable = Set(ContentCatalog.shared.pressureTargets.map(\.id).filter { target in
            ContentCatalog.shared.pressureSources.contains { starters.contains($0.id) && $0.canAttach(to: target) }
        })
        XCTAssertFalse(writable.contains("cycle"),
                       "a world's rhythm should be rolled until you learn to name it")
        XCTAssertGreaterThan(writable.count, 4, "…but most of a world has to be sayable on day one")
        XCTAssertLessThan(writable.count, ContentCatalog.shared.pressureTargets.count,
                          "everything is writable at the start, so nothing is ever learned")
    }

    /// **A capability rune must be reliable, not rare** (`sigil-vocabulary.md` §3): *"Missing one
    /// doesn't make the game harder; it makes part of it unavailable. This is exactly what
    /// deadlocked Isolde."*
    ///
    /// So: wherever a subject can be pushed in a direction by only one word, that word must be
    /// bought rather than found. A single point of failure that only turns up in the wild is a
    /// deadlock waiting for an unlucky player.
    func testTheOnlyWordForADirectionIsNeverLeftToLuck() {
        for target in ContentCatalog.shared.pressureTargets {
            for wantsMore in [true, false] {
                let words = ContentCatalog.shared.pressureSources.filter { source in
                    guard source.canAttach(to: target.id) else { return false }
                    let sigil = Sigil(id: InstanceID(rawValue: 1), source: source.id, target: target.id)
                    let peak = PressureRules.resolve([sigil])[target.id].peak
                    return wantsMore ? peak > target.baseline + 1 : peak < target.baseline - 1
                }
                guard words.count == 1, let only = words.first else { continue }
                XCTAssertNotEqual(only.acquisition, .worldDrop,
                    "\(only.id.rawValue) is the ONLY way to write \(target.id.rawValue) "
                    + (wantsMore ? "upward" : "downward") + " and it can only be found by luck")
            }
        }
    }

    /// And every subject has to be sayable in both directions **eventually**, or half of it is
    /// decoration however long you play. This is the fault that started all of it, checked against
    /// the whole vocabulary rather than against the starting slice.
    func testEverySubjectCanEventuallyBeWrittenBothWays() {
        for target in ContentCatalog.shared.pressureTargets {
            var up = false, down = false
            for source in ContentCatalog.shared.pressureSources where source.canAttach(to: target.id) {
                let sigil = Sigil(id: InstanceID(rawValue: 1), source: source.id, target: target.id)
                let peak = PressureRules.resolve([sigil])[target.id].peak
                if peak > target.baseline + 1 { up = true }
                if peak < target.baseline - 1 { down = true }
            }
            XCTAssertTrue(up, "\(target.id.rawValue) can never be asked for MORE of")
            XCTAssertTrue(down, "\(target.id.rawValue) can never be asked for LESS of")
        }
    }

    // MARK: Everything else is gettable

    /// **A word you can never learn is worse than a word you were given.** Every focus has to have
    /// a route: it's a starter, the Workshop sells it, a site teaches it, or a cache can hold it.
    func testEveryFocusCanBeLearned() {
        let taughtByResearch = Set(ContentCatalog.shared.researchNodes
            .flatMap(\.grants)
            .filter { $0.kind == .focus }
            .compactMap { $0.id }
            .map { PressureSourceID(rawValue: $0) })
        let taughtBySites = Set(ContentCatalog.shared.sites.flatMap { $0.contents.teachesFocuses })

        for source in ContentCatalog.shared.pressureSources {
            switch source.acquisition {
            case .starter:
                XCTAssertTrue(starters.contains(source.id))
            case .research:
                XCTAssertTrue(taughtByResearch.contains(source.id),
                              "\(source.id.rawValue) is sold at the Workshop by no node")
            case .worldDrop:
                XCTAssertTrue(taughtBySites.contains(source.id) || canComeFromACache(source.id),
                              "\(source.id.rawValue) is found out there by nothing")
            }
        }
    }

    /// Caches draw from everything not-yet-owned that isn't Workshop-only, so this is a real check
    /// of the filter rather than a restatement of it.
    private func canComeFromACache(_ id: PressureSourceID) -> Bool {
        var state = GameState.newGame()
        state.base.ownedSources = Set(ContentCatalog.shared.pressureSources.map(\.id))
        state.base.ownedSources.remove(id)
        state.base.ownedSymbols = Set(ContentCatalog.shared.symbols.map(\.id))
        state.base.ownedGambitComponents = Set(ContentCatalog.shared.gambitComponents.map(\.id))
        var rng = SeededRNG(seed: 99)
        for _ in 0..<80 {
            if case .focus(let rolled) = EconomyRules.rollCacheReward(in: state, rng: &rng),
               rolled == id { return true }
        }
        return false
    }

    /// Studying it has to actually hand it over.
    @MainActor
    func testBuyingAWordAtTheWorkshopTeachesIt() throws {
        let node = try XCTUnwrap(ContentCatalog.shared.researchNodes
            .first { $0.grants.contains { $0.kind == .focus } })
        let grant = try XCTUnwrap(node.grants.first { $0.kind == .focus })
        let focus = PressureSourceID(rawValue: try XCTUnwrap(grant.id))
        var state = GameState.newGame()
        XCTAssertFalse(state.base.ownedSources.contains(focus), "fixture: it's already known")
        EconomyRules.apply(grant, in: &state)
        XCTAssertTrue(state.base.ownedSources.contains(focus))
    }

    // MARK: Nothing is ever taken back

    /// Which words are starters is content, and it will be re-cut during balancing. A save written
    /// against an older list must not end up unable to say something the game considers basic —
    /// the same reconciliation the roster gets, and for the same reason.
    @MainActor
    func testAnOldSaveGainsAnyWordThatBecameAStarter() {
        let io = SaveFileIO.temporary(name: "vocab-\(UUID().uuidString)")
        do {
            let store = GameStore(io: io)
            store.mutate("test: an older vocabulary", flush: true) { $0.base.ownedSources = [] }
            XCTAssertTrue(store.state.base.ownedSources.isEmpty, "fixture didn't take")
        }
        let reopened = GameStore(io: io)
        XCTAssertEqual(reopened.state.base.ownedSources, starters,
                       "a save from before a word was a starter can't say it")
    }

    /// And the palette shows exactly what you know — no more, and no less.
    @MainActor
    func testThePaletteOffersOnlyWhatYouKnow() {
        let store = GameStore(io: .temporary(name: "palette-\(UUID().uuidString)"))
        let offered = ContentCatalog.shared.pressureSources
            .filter { store.state.base.ownedSources.contains($0.id) }
        XCTAssertEqual(Set(offered.map(\.id)), starters)
        XCTAssertLessThan(offered.count, ContentCatalog.shared.pressureSources.count,
                          "every word in the game is available on turn one, so there is no vocabulary")
    }

    /// **Chance is not limited to what you know.** A subject left unwritten is rolled from the whole
    /// pool — a surprise that could only hand back words you already had would be a shuffle
    /// (the same rule the random slot fill has always been held to).
    func testWhatTheWorldRollsIsNotLimitedToYourVocabulary() {
        var rolled: Set<PressureSourceID> = []
        for seed in UInt64(1)...300 {
            for sigil in PressureRules.rollUnwritten(after: [], seed: seed) { rolled.insert(sigil.source) }
        }
        let beyond = rolled.subtracting(starters)
        XCTAssertFalse(beyond.isEmpty,
                       "the world only ever rolls words the player already has, which is a shuffle")
    }
}
