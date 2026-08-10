import XCTest
@testable import Bookbinder

/// The world-description panel — the only place the pressure model becomes visible to the player,
/// and the surface a Library hint page is matched against.
final class DescriptionTests: XCTestCase {

    // MARK: The rule that makes it a deduction surface

    /// > Descriptive, never a condition list, never naming sigil values.
    ///
    /// The rule is about **values** — a clause reading "Illumination 12" would turn matching into
    /// arithmetic, and the diary page in the player's hand doesn't talk that way. Naming things
    /// that are *in* the world is fine and usually better prose: "frozen over", "hard stone",
    /// "geysers breathe out of the ground" all leak nothing.
    func testNoClauseNamesAValue() {
        for clause in ContentCatalog.shared.descriptionClauses {
            XCTAssertFalse(clause.text.contains(where: \.isNumber),
                           "'\(clause.id)' names a number: \(clause.text)")
        }
    }

    /// The system's own vocabulary stays out of the prose — "Illumination", "Hydrology", "Vitality"
    /// are names for dials, not for what a place is like.
    ///
    /// **This one is a judgement call, not the spec.** §6 only forbids values. But a hint page is
    /// written by a person describing where they are, and nobody says "the vitality was low."
    func testNoClauseUsesTheSystemsOwnWordForADial() {
        let dialWords = ContentCatalog.shared.pressureTargets.flatMap {
            [$0.id.rawValue.lowercased(), $0.name.lowercased()]
        }
        for clause in ContentCatalog.shared.descriptionClauses {
            let text = clause.text.lowercased()
            for word in dialWords where text.contains(word) {
                XCTFail("'\(clause.id)' calls a dial by its name ('\(word)'): \(clause.text)")
            }
        }
    }

    func testEveryClauseReadsAsASentence() {
        for clause in ContentCatalog.shared.descriptionClauses {
            XCTAssertTrue(clause.text.last.map { ".!?".contains($0) } ?? false,
                          "'\(clause.id)' doesn't end a sentence: \(clause.text)")
            XCTAssertTrue(clause.text.first?.isUppercase ?? false,
                          "'\(clause.id)' doesn't start one: \(clause.text)")
        }
    }

    // MARK: Every world says something

    func testEveryWorldGetsADescription() {
        for seed in UInt64(1)...200 {
            let description = DescriptionRules.describe(page: [], seed: seed)
            XCTAssertGreaterThanOrEqual(description.clauses.count, 3,
                                        "seed \(seed) produced a world with almost nothing to say")
            XCTAssertFalse(description.sentence.isEmpty)
        }
    }

    /// Ordering follows the pressure targets, not clause strength — so the sentence reads the same
    /// way every time and a player learns where to look. A description that shuffled by strength
    /// would be much harder to compare against a hint page.
    func testClauseOrderFollowsTheTargetsEveryTime() {
        let order = DescriptionRules.groupOrder
        for seed in UInt64(1)...80 {
            let groups = DescriptionRules.describe(page: [], seed: seed).clauses.map(\.group)
            let positions = groups.compactMap { order.firstIndex(of: $0) }
            XCTAssertEqual(positions, positions.sorted(), "seed \(seed) described a world out of order")
        }
    }

    /// A description says as much as there is to say — bounded by one clause per subject, not by a
    /// length limit (Aimee, 5 Aug). What it must not do is say something *duller* than it could.
    func testTheMostTellingClauseWinsWithinASubject() {
        // Frozen over and gently broken are both true of a glacier world. Within Hydrology, the
        // frozenness has to beat the generic "water enough" fallback.
        let page = [
            Sigil(id: InstanceID(rawValue: 1), source: "glacier", target: "hydrology", intensity: .overwhelming),
            Sigil(id: InstanceID(rawValue: 2), source: "ice", target: "thermal", intensity: .overwhelming)
        ]
        let description = DescriptionRules.describe(page: page)
        XCTAssertTrue(description.clauses.contains { $0.id == "frozen_over" })
        XCTAssertFalse(description.clauses.contains { $0.id == "water_enough" },
                       "the fallback beat the clause that actually said something")
    }

    func testOneClausePerGroupAtMost() {
        for seed in UInt64(1)...80 {
            let groups = DescriptionRules.describe(page: [], seed: seed).clauses.map(\.group)
            XCTAssertEqual(Set(groups).count, groups.count, "seed \(seed) said two things about one subject")
        }
    }

    // MARK: It describes the world it was given

    func testAFrozenWorldSaysSo() {
        let page = [
            Sigil(id: InstanceID(rawValue: 1), source: "glacier", target: "hydrology", intensity: .overwhelming),
            Sigil(id: InstanceID(rawValue: 2), source: "ice", target: "thermal", intensity: .overwhelming)
        ]
        let description = DescriptionRules.describe(page: page)
        XCTAssertTrue(description.clauses.contains { $0.id == "frozen_over" },
                      "a glacier world didn't read as frozen: \(description.sentence)")
    }

    func testALightlessWorldSaysSo() {
        let page = [Sigil(id: InstanceID(rawValue: 1), source: "void", target: "illumination", intensity: .overwhelming)]
        let description = DescriptionRules.describe(page: page)
        XCTAssertTrue(description.clauses.contains { $0.id == "lightless" },
                      "a void world didn't read as dark: \(description.sentence)")
    }

    // MARK: Polarity drives the underline

    func testRichSeamsReadAsDestabilisingAndBarrenGroundAsCalm() throws {
        let greedy = DescriptionRules.describe(page: [
            Sigil(id: InstanceID(rawValue: 1), source: "gold", target: "substrate", intensity: .overwhelming)
        ])
        let seams = try XCTUnwrap(greedy.clauses.first { $0.group == "substrate" })
        XCTAssertEqual(seams.polarity, .destabilising, "writing toward treasure should read as a risk")

        // **Barren ground has to be written now**, not merely left unmentioned. Ground you say
        // nothing about is ordinary ground, so it reads neutral; ground you deliberately strip is
        // the stabilising choice, and Silt is the word for it (7 Aug).
        let bare = DescriptionRules.describe(page: [
            Sigil(id: InstanceID(rawValue: 1), source: "silt", target: "substrate", intensity: .great)
        ])
        let ground = try XCTUnwrap(bare.clauses.first { $0.group == "substrate" })
        XCTAssertEqual(ground.polarity, .stabilising)
    }

    // MARK: Attribution is earned, not given

    /// Session 8, and a correction to how this shipped: opacity is the *joy*. Working out what your
    /// own writing did to a world is the game, so the panel starts out describing and nothing more.
    func testANewPlayerIsToldSomethingIsWrongButNotWhat() {
        let page = [Sigil(id: InstanceID(rawValue: 1), source: "sun", target: "illumination",
                          intensity: .great, negatedTargets: ["thermal"])]
        let description = DescriptionRules.describe(page: page)   // starting tier

        XCTAssertFalse(description.contradictions.isEmpty, "the contradiction still happened")
        XCTAssertTrue(description.namedContradictions.isEmpty, "it was named far too early")
        XCTAssertTrue(description.hasUnreadableWrongness, "the player got no signal at all")
        XCTAssertFalse(description.showsAttribution, "red/green underlining is tier 4")
    }

    func testAContradictionIsNamedOnceYouCanReadThatFar() {
        let page = [Sigil(id: InstanceID(rawValue: 1), source: "sun", target: "illumination",
                          intensity: .great, negatedTargets: ["thermal"])]
        let description = DescriptionRules.describe(page: page,
                                                    analysisTier: Tuning.Analysis.attributionTier)
        XCTAssertEqual(description.namedContradictions.map(\.name), ["A sun that does not warm"])
        XCTAssertTrue(description.showsAttribution)
        XCTAssertFalse(description.hasUnreadableWrongness)
        // Still its own line, never folded into the prose.
        XCTAssertFalse(description.sentence.contains("does not warm"))
    }

    func testTierFourPolarityComesFromPageArithmeticNotAuthoredProse() {
        let greedy = [Sigil(id: InstanceID(rawValue: 1), source: "gold", target: "substrate",
                            intensity: .overwhelming)]
        let description = DescriptionRules.describe(page: greedy,
                                                     analysisTier: Tuning.Analysis.attributionTier)
        XCTAssertEqual(description.derivedPolarity["substrate"], .destabilising)

        let calm = [Sigil(id: InstanceID(rawValue: 2), source: "void", target: "illumination",
                          intensity: .overwhelming)]
        let calmDescription = DescriptionRules.describe(page: calm,
                                                         analysisTier: Tuning.Analysis.attributionTier)
        XCTAssertEqual(calmDescription.derivedPolarity["illumination"], .stabilising)
    }

    /// The half that must work from the very first book: description is what a clue gets matched
    /// against, so it can't be gated behind anything.
    func testDescriptionItselfNeverDependsOnTheAnalysisTier() {
        let page = [
            Sigil(id: InstanceID(rawValue: 1), source: "glacier", target: "hydrology", intensity: .overwhelming),
            Sigil(id: InstanceID(rawValue: 2), source: "ice", target: "thermal", intensity: .overwhelming)
        ]
        let novice = DescriptionRules.describe(page: page, analysisTier: Tuning.Analysis.startingTier)
        let adept = DescriptionRules.describe(page: page, analysisTier: Tuning.Analysis.livingTier)
        XCTAssertEqual(novice.clauses.map(\.id), adept.clauses.map(\.id))
        XCTAssertEqual(novice.sentence, adept.sentence)
    }

    @MainActor
    func testTheDeskShowsWhatThePlayerCanActuallyRead() {
        let store = GameStore(io: .temporary(name: "analysis-\(UUID().uuidString)"))
        XCTAssertEqual(store.state.reality.analysisTier, Tuning.Analysis.startingTier)
        XCTAssertFalse(store.bookProjection.worldDescription.showsAttribution)

        store.mutate("test: better instruments") { $0.reality.analysisTier = Tuning.Analysis.attributionTier }
        XCTAssertTrue(store.bookProjection.worldDescription.showsAttribution)
    }

    func testAnHonestWorldNamesNoContradictions() {
        let page = [
            Sigil(id: InstanceID(rawValue: 1), source: "sun", target: "illumination", intensity: .overwhelming),
            Sigil(id: InstanceID(rawValue: 2), source: "glacier", target: "hydrology", intensity: .overwhelming)
        ]
        let description = DescriptionRules.describe(page: page,
                                                    analysisTier: Tuning.Analysis.attributionTier)
        XCTAssertTrue(description.contradictions.isEmpty)
        XCTAssertFalse(description.hasUnreadableWrongness, "an honest world must not feel wrong")
    }

    // MARK: The desk shows the same world the bind produces

    @MainActor
    func testTheDeskDescribesWhatYouWroteAndNothingElse() {
        let store = GameStore(io: .temporary(name: "describe-\(UUID().uuidString)"))
        store.write("frostbound")
        let promised = store.bookProjection.worldDescription

        store.mutate("test: fund") { $0.base.essence = 500 }
        store.bindAndDepart()
        guard let run = store.state.worlds.activeRun else { return XCTFail("couldn't depart") }

        // What the desk said must be exactly the description of what was *written*: resolved
        // without the unwritten targets filled in, and speaking only about targets the page
        // actually touches.
        let sigils = BookRules.sigils(for: run.book)
        let written = DescriptionRules.describe(
            PressureRules.resolve(sigils),
            contradictions: ContradictionRules.fired(in: sigils),
            about: DescriptionRules.targetsTouched(by: sigils)
        )
        XCTAssertEqual(promised.clauses.map(\.id), written.clauses.map(\.id),
                       "the desk described something other than what was on the page")
    }

    /// The locked rule the desk was breaking: a slot left to chance is a **surprise**, so the
    /// preview must not describe what the world rolled for itself before it's been paid for.
    @MainActor
    func testTheDeskNeverSpoilsWhatTheWorldRolls() {
        let store = GameStore(io: .temporary(name: "spoil-\(UUID().uuidString)"))
        store.write("frostbound")
        store.mutate("test: fund") { $0.base.essence = 500 }

        let promised = store.bookProjection.worldDescription
        store.bindAndDepart()
        guard let run = store.state.worlds.activeRun else { return XCTFail("couldn't depart") }

        // The world the player actually gets, unwritten targets and all.
        let rolled = DescriptionRules.describe(BookRules.readings(for: run.book, seed: run.mapSeed))
        let spoiled = Set(promised.clauses.map(\.group))
            .subtracting(["hydrology", "thermal"])   // what Frostbound genuinely says
        XCTAssertTrue(spoiled.isEmpty,
                      "the desk described \(spoiled), which the player never wrote")
        XCTAssertGreaterThan(rolled.clauses.count, promised.clauses.count,
                             "the world should hold more than the page said")
    }

    // MARK: The description rule — absolute (decisions-session-11 §1)

    /// The leak in its purest form: a description appearing before a single rune is placed.
    @MainActor
    func testABlankPageHasNoDescriptionAtAll() {
        let store = GameStore(io: .temporary(name: "blank-\(UUID().uuidString)"))
        let description = store.bookProjection.worldDescription

        XCTAssertTrue(description.clauses.isEmpty,
                      "a blank page described a world: \(description.sentence)")
        XCTAssertTrue(description.isEmpty, "the panel would still be on screen")
    }

    /// Place three runes and the description speaks to those three, silent on everything else.
    @MainActor
    func testTheDescriptionSpeaksOnlyToWhatIsOnThePage() {
        let store = GameStore(io: .temporary(name: "spoken-\(UUID().uuidString)"))
        store.mutate("test: know everything") {
            $0.base.ownedSymbols = Set(ContentCatalog.shared.symbols.map(\.id))
        }
        store.write("frostbound")

        let spoken = Set(store.bookProjection.worldDescription.clauses.map(\.group))
        let allowed = Set(DescriptionRules
            .targetsTouched(by: BookRules.sigils(for: BookRules.resolveBook(page: store.state.base.page)))
            .map(\.rawValue))
        XCTAssertFalse(spoken.isEmpty, "writing something produced no description")
        XCTAssertTrue(spoken.isSubset(of: allowed),
                      "described \(spoken.subtracting(allowed)), which nothing on the page touches")
    }

    /// Adding a rune may only ever add to what's described.
    @MainActor
    func testWritingMoreRevealsMoreAndNeverLess() {
        let store = GameStore(io: .temporary(name: "growing-\(UUID().uuidString)"))
        store.mutate("test: know everything") {
            $0.base.ownedSymbols = Set(ContentCatalog.shared.symbols.map(\.id))
        }
        var spokenBefore = Set<String>()
        for symbol in ContentCatalog.shared.symbols where store.write(symbol.id) {
            let spoken = Set(store.bookProjection.worldDescription.clauses.map(\.group))
            XCTAssertTrue(spokenBefore.isSubset(of: spoken),
                          "writing \(symbol.id.rawValue) took a subject away from the description")
            spokenBefore = spoken
        }
        XCTAssertGreaterThan(spokenBefore.count, 1)
    }

    /// The stability number must not require knowing what rolled — **and it must not pretend to
    /// know either** (Aimee, 6 Aug).
    ///
    /// It's a band now, because every unwritten subject is rolled at bind and a rolled focus
    /// carries its own delta, greed and contradictions. What you wrote sits inside the band; the
    /// band says nothing about *which* thing might roll, so the no-leaking rule still holds.
    @MainActor
    func testStabilityBracketsWhatThePageAloneSays() {
        let store = GameStore(io: .temporary(name: "stab-\(UUID().uuidString)"))
        store.mutate("test: know everything") {
            $0.base.ownedSymbols = Set(ContentCatalog.shared.symbols.map(\.id))
        }
        store.write("rich_ore")
        let shown = store.bookProjection.stabilityScore
        let fromPage = BookRules.stabilityScore(delta: BookRules.stabilityDelta(ofSymbolAlone: "rich_ore"))
        XCTAssertTrue(shown.contains(fromPage),
                      "what the page says isn't inside the band the panel shows")
        XCTAssertFalse(shown.isPoint,
                       "seven subjects unwritten and stability is shown as a certainty")
    }

    /// **Visiting unseals it.** A world you've been to has no secrets.
    @MainActor
    func testAVisitedWorldMayBeDescribedInFull() {
        let store = GameStore(io: .temporary(name: "visited-\(UUID().uuidString)"))
        store.mutate("test: know everything") { state in
            state.base.ownedSymbols = Set(ContentCatalog.shared.symbols.map(\.id))
            state.base.essence = 500
        }
        store.write("frostbound")

        let sealed = store.bookProjection.worldDescription
        let seed = store.state.worlds.seeds.peekNextSeed()

        store.mutate("test: having been there") { $0.reality.visitedWorldSeeds.insert(seed) }
        let unsealed = store.bookProjection.worldDescription

        XCTAssertGreaterThan(unsealed.clauses.count, sealed.clauses.count,
                             "a world already visited should hold nothing back")
    }

    @MainActor
    func testDepartingRecordsTheWorldAsVisited() {
        let store = GameStore(io: .temporary(name: "record-\(UUID().uuidString)"))
        store.mutate("test: fund") { $0.base.essence = 500 }
        let seed = store.state.worlds.seeds.peekNextSeed()
        store.bindAndDepart()
        XCTAssertTrue(store.state.reality.visitedWorldSeeds.contains(seed))
        XCTAssertEqual(store.state.worlds.activeRun?.mapSeed, seed,
                       "the world recorded as visited isn't the one that was entered")
    }
}
