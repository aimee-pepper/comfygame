import XCTest
@testable import Bookbinder

/// Contradiction is a **catalogue, never a formula** (`docs/contradiction-danger-spec.md` §1).
///
/// The first test here is the one the spec asks for by name, and it's the whole safety mechanism:
/// if opposition itself were penalised, players would learn to avoid the interesting combinations,
/// which is the opposite of what the writing system exists for.
final class ContradictionTests: XCTestCase {

    // MARK: The invariant

    /// > No world composed only of non-negated, catalogue-clean sigils ever accrues contradiction
    /// > instability, regardless of how opposed its pressures are.
    func testHonestWorldsNeverContradict() {
        // Deliberately violent opposition on every dual-valued target. Nature is full of this:
        // a sunny snowy world is real — sun producing heat, glacier sinking it, an equilibrium.
        let opposed: [[String]] = [
            ["sun", "void"],
            ["magma", "glacier"],
            ["sun", "glacier", "magma", "ice", "snow"],
            ["wildfire", "sea"],
            ["aurora", "miasma", "crystal", "ash"]
        ]

        for sources in opposed {
            let page = sources.enumerated().map { index, source in
                Sigil(id: InstanceID(rawValue: UInt64(index)),
                      source: PressureSourceID(rawValue: source),
                      target: primaryTarget(of: source),
                      intensity: .overwhelming)
            }
            let readings = PressureRules.resolve(page)
            let fired = ContradictionRules.fired(in: page, readings: readings)

            // Sanity: these really are opposed, so the test isn't passing vacuously.
            XCTAssertGreaterThan(readings.totalOpposed, 0,
                                 "\(sources) didn't actually oppose anything")
            XCTAssertTrue(fired.isEmpty, """
                \(sources.joined(separator: " + ")) fired \(fired.map(\.id.rawValue)) — \
                honest worldbuilding was punished for being opposed
                """)
            XCTAssertEqual(ContradictionRules.totalPenalty(for: fired), 0)
        }
    }

    func testAnEmptyPageContradictsNothing() {
        XCTAssertTrue(ContradictionRules.fired(in: []).isEmpty)
    }

    /// **Negation can never happen by accident** — the spec's central safety claim for the category
    /// it expects most contradiction to live in. You had to write a Negate rune, and chance never
    /// writes one.
    func testChanceNeverProducesANegationContradiction() {
        for seed in UInt64(1)...200 {
            let rolled = PressureRules.rollUnwritten(after: [], seed: seed)
            let negations = ContradictionRules.fired(in: rolled).filter { $0.kind == .negation }
            XCTAssertTrue(negations.isEmpty,
                          "chance wrote a negation, which it has no rune for — seed \(seed)")
        }
    }

    /// **Assertions can.** A chance-filled slot can roll growing things into a world another
    /// chance-filled slot made dark, and that is a real contradiction — the world was asserted to
    /// be something it can't be, regardless of who did the asserting.
    ///
    /// Pinned as *observed behaviour*, not as a ruling: `contradiction-danger-spec.md` §7.2 asks
    /// whether chance-fills should participate at all, and leans yes on the grounds that the risk
    /// is acceptable gameplay. If that lands the other way, this test is the one to change.
    func testChanceCanProduceAnAssertionContradiction() {
        let contradicted = (UInt64(1)...200).filter { seed in
            !ContradictionRules.fired(in: PressureRules.rollUnwritten(after: [], seed: seed)).isEmpty
        }
        XCTAssertFalse(contradicted.isEmpty, "no chance-filled world contradicted — has §7.2 changed?")
        // It should stay uncommon: a gamble, not a tax.
        XCTAssertLessThan(contradicted.count, 100,
                          "most chance-filled worlds contradict, which makes it a tax on leaving slots open")
    }

    // MARK: Negation — the deliberate, visible category

    func testASunThatDoesNotWarmIsNamed() {
        let page = [Sigil(id: InstanceID(rawValue: 1),
                          source: "sun", target: "illumination",
                          intensity: .great, negatedTargets: ["thermal"])]
        let fired = ContradictionRules.fired(in: page)
        XCTAssertEqual(fired.map(\.id.rawValue), ["sun_that_does_not_warm"])
        XCTAssertEqual(fired.first?.name, "A sun that does not warm")
        XCTAssertGreaterThan(ContradictionRules.totalPenalty(for: fired), 0)
    }

    func testTheSameSunWithoutTheNegationIsFine() {
        let page = [Sigil(id: InstanceID(rawValue: 1),
                          source: "sun", target: "illumination", intensity: .overwhelming)]
        XCTAssertTrue(ContradictionRules.fired(in: page).isEmpty)
    }

    func testNegatingSomethingTheSourceNeverDidDoesNotFire() {
        // Sun doesn't touch Substrate, so denying it is a no-op rather than a contradiction.
        let page = [Sigil(id: InstanceID(rawValue: 1),
                          source: "sun", target: "illumination",
                          intensity: .great, negatedTargets: ["substrate"])]
        XCTAssertTrue(ContradictionRules.fired(in: page).isEmpty)
    }

    // MARK: Assertions — enumerated only, and only on what was written

    func testGreenInTheDarkFiresOnlyWhenBothHalvesAreWritten() {
        let darkAndGrowing = [
            Sigil(id: InstanceID(rawValue: 1), source: "root", target: "vitality", intensity: .great),
            Sigil(id: InstanceID(rawValue: 2), source: "void", target: "illumination", intensity: .overwhelming)
        ]
        XCTAssertTrue(ContradictionRules.fired(in: darkAndGrowing).contains { $0.id == "green_in_the_dark" })

        // Same darkness, nothing asserted to grow in it.
        let justDark = [darkAndGrowing[1]]
        XCTAssertFalse(ContradictionRules.fired(in: justDark).contains { $0.id == "green_in_the_dark" })

        // Same growth, in the light.
        let lit = [
            darkAndGrowing[0],
            Sigil(id: InstanceID(rawValue: 3), source: "sun", target: "illumination", intensity: .great)
        ]
        XCTAssertFalse(ContradictionRules.fired(in: lit).contains { $0.id == "green_in_the_dark" })
    }

    func testFungalGrowthInTheDarkIsNotAContradiction() {
        // The fungal exemption is the *interesting* case — it must not be punished.
        let page = [
            Sigil(id: InstanceID(rawValue: 1), source: "fungus", target: "vitality", intensity: .great),
            Sigil(id: InstanceID(rawValue: 2), source: "void", target: "illumination", intensity: .overwhelming)
        ]
        XCTAssertTrue(ContradictionRules.fired(in: page).isEmpty)
    }

    // MARK: Stacking

    func testEscalationIsZeroForOneAndRisesFromTwo() {
        XCTAssertEqual(ContradictionRules.escalation(count: 0), 0)
        XCTAssertEqual(ContradictionRules.escalation(count: 1), 0)
        XCTAssertGreaterThan(ContradictionRules.escalation(count: 2), 0)
        XCTAssertGreaterThan(ContradictionRules.escalation(count: 3),
                             ContradictionRules.escalation(count: 2))
    }

    func testTheEscalationTermIsReportedSeparately() {
        // §3: hidden superlinearity is the failure mode, so the preview must be able to show it.
        let page = [
            Sigil(id: InstanceID(rawValue: 1), source: "sun", target: "illumination",
                  intensity: .great, negatedTargets: ["thermal"]),
            Sigil(id: InstanceID(rawValue: 2), source: "rain", target: "hydrology",
                  intensity: .great, negatedTargets: ["hydrology"])
        ]
        let fired = ContradictionRules.fired(in: page)
        XCTAssertEqual(fired.count, 2)

        let parts = ContradictionRules.penalty(for: fired)
        XCTAssertEqual(parts.base, fired.reduce(0) { $0 + $1.instability })
        XCTAssertGreaterThan(parts.escalation, 0)
        XCTAssertEqual(ContradictionRules.totalPenalty(for: fired), parts.base + parts.escalation)
    }

    // MARK: Hazard sites

    func testATearNeedsANamedContradictionNotOpposedForce() throws {
        let tear = try XCTUnwrap(ContentCatalog.shared.site("the_tear"))

        // Violently opposed, entirely honest. Must not tear.
        let honest = [
            Sigil(id: InstanceID(rawValue: 1), source: "magma", target: "thermal", intensity: .overwhelming),
            Sigil(id: InstanceID(rawValue: 2), source: "glacier", target: "hydrology", intensity: .overwhelming)
        ]
        let honestReadings = PressureRules.resolve(honest)
        XCTAssertGreaterThan(honestReadings.totalOpposed, 0)
        XCTAssertFalse(tear.isEligible(in: honestReadings,
                                       contradictions: ContradictionRules.fired(in: honest, readings: honestReadings)))

        // One named contradiction, and the world tears.
        let denied = [Sigil(id: InstanceID(rawValue: 1), source: "sun", target: "illumination",
                            intensity: .great, negatedTargets: ["thermal"])]
        let deniedReadings = PressureRules.resolve(denied)
        XCTAssertTrue(tear.isEligible(in: deniedReadings,
                                      contradictions: ContradictionRules.fired(in: denied, readings: deniedReadings)))
    }

    // MARK: Helpers

    /// The target a source most obviously binds to, for building test pages.
    private func primaryTarget(of source: String) -> PressureTargetID {
        ContentCatalog.shared.pressureSource(PressureSourceID(rawValue: source))?
            .contributions.first?.target ?? "illumination"
    }
}
