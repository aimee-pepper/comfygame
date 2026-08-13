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

    func testWorldHistoryRecordActionsRemainOutsideLongAnalysisContent() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let source = try String(
            contentsOf: root.appending(path: "Sources/Screens/WorldHistoryView.swift"),
            encoding: .utf8
        )
        let detailStart = try XCTUnwrap(source.range(of: "private struct VisitedWorldSheet"))
        let detail = String(source[detailStart.lowerBound...])

        XCTAssertTrue(detail.contains(".safeAreaInset(edge: .bottom, spacing: 0) { historyActionBar }"))
        XCTAssertTrue(detail.contains("Label(world.isKept ? \"Stop keeping\" : \"Keep\""))
        XCTAssertTrue(detail.contains("Button(role: .destructive)"))
        XCTAssertTrue(detail.contains("Label(\"Erase\", systemImage: \"trash\")"))
    }

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
    func testTheLensIsGatedOnSubjectsYouMeasured() throws {
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

        store.mutate("field readings taken") { state in
            for target in ContentCatalog.shared.pressureTargets.prefix(firstTier.needsInstruments) {
                state.reality.instruments.insert(target.id)
                state.reality.observations[target.id] = .init(count: 1, lowest: 20,
                                                               highest: 60, bestPrecision: .crude)
            }
        }
        XCTAssertTrue(EconomyRules.isAvailable(firstTier, in: store.state))
    }

    /// Buying an instrument gives you the tool, but calibration is earned in the field.
    func testBuyingAnInstrumentDoesNotCountAsAReading() throws {
        let store = richStore()
        let sunglass = try XCTUnwrap(ContentCatalog.shared.researchNode("sunglass"))
        XCTAssertFalse(store.state.reality.measures("illumination"))

        store.mutate("build it") { EconomyRules.complete(sunglass, in: &$0) }
        XCTAssertTrue(store.state.reality.instruments.contains("illumination"))
        XCTAssertFalse(store.state.reality.measures("illumination"))
        XCTAssertFalse(store.state.reality.measures("cycle"), "one instrument, one subject")

        // The physical kit currently lives beside the lens in Reality, so it survives this reset.
        store.resetBaseKeepingReality()
        XCTAssertTrue(store.state.reality.instruments.contains("illumination"))
        XCTAssertFalse(store.state.reality.measures("illumination"))
    }

    func testSurveyUsesEveryInstrumentAndCostsOneTurn() throws {
        let store = richStore()
        store.mutate("field kit") { state in
            state.reality.instruments = ["illumination", "thermal"]
        }
        XCTAssertTrue(store.bindAndDepart())
        let before = try XCTUnwrap(store.activeRun?.turnsTaken)

        store.survey()

        XCTAssertEqual(store.activeRun?.turnsTaken, before + 1)
        XCTAssertEqual(store.state.reality.observations.count, 2)
        XCTAssertTrue(store.state.reality.measures("illumination"))
        XCTAssertTrue(store.state.reality.measures("thermal"))
        XCTAssertEqual(store.state.reality.observations["illumination"]?.count, 1)
    }

    func testSurveyUsesOnlyTheInstrumentLoadoutFrozenAtDeparture() throws {
        let store = richStore()
        store.mutate("field kit") { state in
            state.reality.instruments = ["illumination", "thermal"]
            state.base.instrumentLoadout = ["illumination"]
            state.base.hasConfiguredInstrumentLoadout = true
        }
        XCTAssertTrue(store.bindAndDepart())
        XCTAssertEqual(store.activeRun?.carriedInstruments, ["illumination"])

        // Changing the next-trip preference cannot teleport a tool into this run.
        store.mutate("next kit") { $0.base.instrumentLoadout = ["thermal"] }
        store.survey()

        XCTAssertTrue(store.state.reality.measures("illumination"))
        XCTAssertFalse(store.state.reality.measures("thermal"))
        XCTAssertEqual(store.activeRun?.carriedInstruments, ["illumination"])
    }

    func testSurveyKnowledgeSurvivesTheRunAndAccumulatesCompactly() throws {
        let store = richStore()
        store.mutate("field kit") { $0.reality.instruments = ["illumination"] }
        XCTAssertTrue(store.bindAndDepart())
        store.survey()
        store.survey()

        let observation = try XCTUnwrap(store.state.reality.observations["illumination"])
        XCTAssertEqual(observation.count, 2)
        XCTAssertEqual(observation.bestPrecision, .crude)
        store.resetBaseKeepingReality()
        XCTAssertEqual(store.state.reality.observations["illumination"], observation)
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

    func testInstrumentGradeControlsReadoutPrecision() {
        let crude = WorldDescription.Reading.text(peak: 73, floor: 31, hasFloor: true,
                                                  precision: .crude)
        let good = WorldDescription.Reading.text(peak: 73, floor: 31, hasFloor: true,
                                                 precision: .good)
        let fine = WorldDescription.Reading.text(peak: 73, floor: 31, hasFloor: true,
                                                 precision: .fine)
        XCTAssertTrue(crude.contains("middling"))
        XCTAssertTrue(crude.contains("60–80"))
        XCTAssertEqual(good, "68–78 / 26–36")
        XCTAssertEqual(fine, "73 / 31")
    }

    func testTierThreeDisclosesOnlyCalibratedFocusEffects() throws {
        let page = sunPage()

        let lightOnly = BookProjection.project(
            page: page,
            analysisTier: Tuning.Analysis.sigilAttributionTier,
            measuring: ["illumination"]
        )
        let firstEffects = try XCTUnwrap(lightOnly.chains.first?.parts.first?.effects)
        XCTAssertEqual(firstEffects.map(\.targetID), ["illumination"])
        XCTAssertFalse(firstEffects.contains { $0.targetID == "thermal" },
                       "an unmeasured secondary reveals both its existence and exact contribution")

        let withThermal = BookProjection.project(
            page: page,
            analysisTier: Tuning.Analysis.sigilAttributionTier,
            measuring: ["illumination", "thermal"]
        )
        let revealed = try XCTUnwrap(withThermal.chains.first?.parts.first?.effects)
        XCTAssertEqual(Set(revealed.map(\.targetID)), ["illumination", "thermal"])
        XCTAssertEqual(revealed.first(where: { $0.targetID == "illumination" })?.text,
                       firstEffects.first?.text,
                       "instrument precision must not change deterministic focus contribution")
    }

    func testHistoryRetainsStructuredEffectsForLaterCalibration() {
        let page = sunPage()
        let book = BookRules.resolveBook(page: page)
        let record = LibraryRules.record(book: book, page: page, seed: 991,
                                         runIndex: 2, travellers: [])

        XCTAssertEqual(Set(record.focusEffects.map(\.targetID)), ["illumination", "thermal"])
        XCTAssertTrue(record.focusEffects.contains { !$0.isPrimary && $0.targetID == "thermal" })
        XCTAssertFalse(record.focusEffects.filter { ["illumination"].contains($0.targetID) }
            .contains { $0.targetID == "thermal" })
        XCTAssertTrue(record.focusEffects.filter { ["illumination", "thermal"].contains($0.targetID) }
            .contains { $0.targetID == "thermal" })
    }

    func testTierFiveLivingAnalysisComesFromTheTraitAllocators() {
        let readings = PressureRules.resolve([], fillingUnwrittenWith: 5515)
        let first = LivingAnalysisRules.analyze(readings)
        let second = LivingAnalysisRules.analyze(readings)

        XCTAssertEqual(first, second, "the lens rerolled its prediction while the page stood still")
        XCTAssertFalse(first.creatureTraits.isEmpty)
        XCTAssertFalse(first.ecologicalRoles.isEmpty)
        XCTAssertFalse(first.floraTraits.isEmpty)
        XCTAssertTrue(first.ecologicalRoles.allSatisfy { $0.contains("% in sample") })
        XCTAssertTrue(first.creatureTraits.allSatisfy { $0.contains("sampled middle range") })
    }

    func testVisitedWorldCapturesLivingAnalysisForLaterTierFiveReading() {
        let record = LibraryRules.record(book: BoundBook(written: ["teeming_life"], essencePaid: 0),
                                         page: Page(), seed: 991, runIndex: 2, travellers: [])
        XCTAssertNotNil(record.livingAnalysis)
        XCTAssertFalse(record.livingAnalysis?.creatureTraits.isEmpty ?? true)
        XCTAssertNotNil(record.clockAnalysis)
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

    private func sunPage() -> Page {
        var page = Page()
        page.runes = [
            PlacedRune(id: InstanceID(rawValue: 1), content: .target("illumination"),
                       hand: .crude, origin: PageCell(column: 0, row: 0), shapeID: "crude_block"),
            PlacedRune(id: InstanceID(rawValue: 2), content: .source("sun"),
                       hand: .crude, origin: PageCell(column: 2, row: 0), shapeID: "crude_block")
        ]
        page.links = [MarkLink(InstanceID(rawValue: 1), InstanceID(rawValue: 2))]
        return page
    }
}
