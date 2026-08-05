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

        let bare = DescriptionRules.describe(page: [
            Sigil(id: InstanceID(rawValue: 1), source: "sun", target: "illumination", intensity: .faint)
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
    func testTheDeskDescribesTheWorldItIsAboutToMake() {
        let store = GameStore(io: .temporary(name: "describe-\(UUID().uuidString)"))
        store.setSymbol("frostbound", in: "biome")
        let promised = store.bookProjection.worldDescription

        store.mutate("test: fund") { $0.base.essence = 500 }
        store.bindAndDepart()

        guard let run = store.state.worlds.activeRun else { return XCTFail("couldn't depart") }
        let actual = DescriptionRules.describe(
            BookRules.readings(for: run.book, seed: run.mapSeed),
            contradictions: ContradictionRules.fired(in: BookRules.sigils(for: run.book))
        )
        XCTAssertEqual(promised.clauses.map(\.id), actual.clauses.map(\.id),
                       "the desk promised a different world than it made")
    }
}
