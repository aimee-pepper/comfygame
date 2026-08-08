import XCTest
@testable import Bookbinder

/// **The instruments** (`crafting-spec.md` PART TWO) — the acquisition path for the analysis axis.
///
/// Five tiers were implemented and `analysisTier` was written only by the debug harness, so tiers 3
/// and 4 were finished work no player could see (`clause-audit.md` F2). The placeholder that closed
/// it was four generic nodes at the Workshop, each +1 tier from a menu. This is the real thing, and
/// the rule that makes it good is the dependency: **field readings are the currency prediction is
/// bought with.**
@MainActor
final class InstrumentTests: XCTestCase {

    // MARK: The content

    /// One instrument per subject, and no subject left unreadable.
    func testThereIsAnInstrumentForEverySubject() {
        var measured: Set<PressureTargetID> = []
        for node in ContentCatalog.shared.researchNodes {
            for grant in node.grants where grant.kind == .instrument {
                measured.insert(PressureTargetID(rawValue: grant.id ?? ""))
            }
        }
        let subjects = Set(ContentCatalog.shared.pressureTargets.map(\.id))
        XCTAssertEqual(measured, subjects,
                       "a subject with no instrument can never be read: \(subjects.subtracting(measured))")
    }

    /// **Mara has a reason to exist.** She was a surveyor who unlocked nothing.
    func testTheInstrumentsAreMarasAndTheLensIsIsoldes() throws {
        let post = try XCTUnwrap(ContentCatalog.shared.station(Stations.surveyPost))
        XCTAssertEqual(post.builtBy, "mara")
        XCTAssertEqual(ContentCatalog.shared.researchBranch("instruments")?.station, Stations.surveyPost)
        XCTAssertEqual(ContentCatalog.shared.researchBranch("lens")?.station, Stations.scriptorium)
        XCTAssertEqual(ContentCatalog.shared.station(Stations.scriptorium)?.builtBy, "isolde")
    }

    /// Every tier of the lens is reachable, and the last one wants most of the kit.
    func testTheLensAsksForMoreOfTheKitEachTime() {
        let tiers = ContentCatalog.shared.researchNodes
            .filter { $0.branch == "lens" }
            .map(\.needsInstruments)
            .sorted()
        XCTAssertEqual(tiers.count, 4, "four tiers of lens, per the spec")
        XCTAssertEqual(tiers, tiers.sorted(), "the lens must get harder, not easier")
        XCTAssertLessThanOrEqual(tiers.last ?? 99, ContentCatalog.shared.pressureTargets.count,
                                 "a tier asking for more instruments than exist is unreachable")
    }

    // MARK: The dependency

    /// **The lens only opens once you have been out and measured.** This is the whole idea: you
    /// cannot buy prediction at home, you earn it in the field.
    func testTheLensIsGatedOnInstrumentsYouOwn() throws {
        let store = richStore()
        let firstTier = try XCTUnwrap(ContentCatalog.shared.researchNode("lens_targets"))
        XCTAssertGreaterThan(firstTier.needsInstruments, 0)

        store.mutate("both buildings up") { state in
            state.base.stations[Stations.scriptorium] = StationState(isUnlocked: true, tier: 2)
            state.base.stations[Stations.surveyPost] = StationState(isUnlocked: true, tier: 1)
        }
        XCTAssertFalse(EconomyRules.isAvailable(firstTier, in: store.state),
                       "the lens opened with nothing measured to grind it against")
        XCTAssertFalse(EconomyRules.missingPrerequisites(firstTier, in: store.state).isEmpty,
                       "a locked row that doesn't say why is indistinguishable from a bug")

        store.mutate("kit acquired") { state in
            state.reality.instruments = Set(ContentCatalog.shared.pressureTargets.prefix(firstTier.needsInstruments).map(\.id))
        }
        XCTAssertTrue(EconomyRules.isAvailable(firstTier, in: store.state))
    }

    /// Buying an instrument records the subject it reads, in Reality, permanently.
    func testBuyingAnInstrumentTeachesYouOneSubject() throws {
        let store = richStore()
        let sunglass = try XCTUnwrap(ContentCatalog.shared.researchNode("sunglass"))
        XCTAssertFalse(store.state.reality.measures("illumination"))

        store.mutate("build it") { EconomyRules.complete(sunglass, in: &$0) }
        XCTAssertTrue(store.state.reality.measures("illumination"))
        XCTAssertFalse(store.state.reality.measures("cycle"), "one instrument, one subject")

        // Reality survives a base reset — a reading is knowledge, and knowledge is never taken back.
        store.resetBaseKeepingReality()
        XCTAssertTrue(store.state.reality.measures("illumination"))
    }

    // MARK: What it buys you

    /// **The lens shows what you measured, and nothing else** — however finely it is ground.
    func testTheLensShowsOnlyWhatYouHaveMeasured() {
        let readings = PressureRules.resolve([])

        let blind = DescriptionRules.describe(readings,
                                              analysisTier: Tuning.Analysis.livingTier,
                                              measuring: [])
        XCTAssertTrue(blind.measured.isEmpty, "a lens with no instruments read something anyway")

        let partial = DescriptionRules.describe(readings,
                                                analysisTier: Tuning.Analysis.targetsTier,
                                                measuring: ["illumination", "thermal"])
        XCTAssertEqual(Set(partial.measured.map(\.target)), ["illumination", "thermal"])
    }

    /// …and an instrument with no lens gives you a reading you can't put on a page. Both halves are
    /// required, which is what makes them feed each other rather than sit side by side.
    func testAnInstrumentWithoutTheLensShowsNothing() {
        let description = DescriptionRules.describe(PressureRules.resolve([]),
                                                    analysisTier: Tuning.Analysis.startingTier,
                                                    measuring: ["illumination"])
        XCTAssertTrue(description.measured.isEmpty)
        XCTAssertFalse(description.showsNumbers)
    }

    /// The two subjects with a day and a night read out both.
    func testTheDualSubjectsReadOutTheirNightsToo() throws {
        let description = DescriptionRules.describe(PressureRules.resolve([]),
                                                    analysisTier: Tuning.Analysis.targetsTier,
                                                    measuring: ["illumination", "substrate"])
        let light = try XCTUnwrap(description.measured.first { $0.target == "illumination" })
        let ground = try XCTUnwrap(description.measured.first { $0.target == "substrate" })
        XCTAssertTrue(light.hasFloor, "illumination has a night and didn't say so")
        XCTAssertFalse(ground.hasFloor)
        XCTAssertTrue(light.text.contains("/"), "got \"\(light.text)\"")
    }

    // MARK: Helpers

    private func richStore() -> GameStore {
        let store = GameStore(io: .temporary(name: "instruments-\(UUID().uuidString)"))
        store.mutate("plenty") { state in
            state.base.essence = 100_000
            for resource in ContentCatalog.shared.resources { state.base.resources.add(999, of: resource.id) }
        }
        return store
    }
}
