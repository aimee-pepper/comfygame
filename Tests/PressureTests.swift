import XCTest
@testable import Bookbinder

/// The writing system's language half.
///
/// These test **properties, not the numbers** — every value in `pressure_sources.json` is flagged
/// PLACEHOLDER and will move in a balance pass. What must survive that pass is the behaviour the
/// design is built on: cyclic sources leave the nights black, constant ones don't, occlusion never
/// inverts, contradiction stays visible, and where a sigil sits never matters.
final class PressureTests: XCTestCase {

    private var nextID: UInt64 = 0
    private func sigil(_ source: PressureSourceID,
                       _ target: PressureTargetID,
                       _ intensity: Intensity = .moderate,
                       negating: Set<PressureTargetID> = []) -> Sigil {
        nextID += 1
        return Sigil(id: InstanceID(rawValue: nextID), source: source, target: target,
                     intensity: intensity, negatedTargets: negating)
    }

    // MARK: The invariant the whole architecture rests on

    /// **The page is a budget, not a syntax.** Sigils are self-contained and neighbours never
    /// interact, so the same set in any order must produce a byte-identical world.
    ///
    /// Guarded rather than assumed, because it's the kind of property that rots the first time
    /// someone thinks "well, adjacent water sigils could pool…". If adjacency ever becomes
    /// desirable it should be a decision, never a discovery.
    func testResolutionIsIndependentOfOrder() {
        let page = [
            sigil("sun", "illumination", .great),
            sigil("canopy", "illumination"),
            sigil("fungus", "illumination", .faint),
            sigil("magma", "thermal"),
        ]

        let reference = PressureRules.resolve(page)
        for permutation in permutations(of: page) {
            XCTAssertEqual(PressureRules.resolve(permutation), reference,
                           "Order changed the world; the page is supposed to be a budget, not a syntax")
        }
    }

    private func permutations(of sigils: [Sigil]) -> [[Sigil]] {
        guard sigils.count > 1 else { return [sigils] }
        return sigils.indices.flatMap { index -> [[Sigil]] in
            var rest = sigils
            let picked = rest.remove(at: index)
            return permutations(of: rest).map { [picked] + $0 }
        }
    }

    // MARK: The worked examples from the spec

    /// "Blazing days, black nights." A cyclic source lifts the peak and leaves the floor alone.
    func testACyclicSourceLeavesTheNightsBlack() {
        let light = PressureRules.resolve([sigil("sun", "illumination", .great)])["illumination"]

        XCTAssertGreaterThan(light.peak, 60, "A great sun should be bright")
        XCTAssertEqual(light.floor, 0, "…and it sets")
        XCTAssertTrue(light.has("wide-range"), "Wide range means a diurnal and a nocturnal niche")
    }

    /// "A lightless world that is nonetheless lit." A constant source lifts both, so nothing is
    /// ever fully dark — and nothing is ever bright either.
    func testAConstantSourceLightsTheFloorAndFlattensTheRange() {
        let light = PressureRules.resolve([sigil("fungus", "illumination")])["illumination"]

        XCTAssertGreaterThan(light.floor, 0)
        XCTAssertEqual(light.peak, light.floor, accuracy: 0.001, "No day, no night — just this")
        XCTAssertTrue(light.has("constant"))
        XCTAssertTrue(light.has("sourceless"), "Lit, but not by anything in the sky")
    }

    /// Adding a floor to a cyclic world narrows the range, and takes the true-dark niche with it.
    func testAddingAConstantSourceRemovesTrueNight() {
        let sunAlone = PressureRules.resolve([sigil("sun", "illumination", .great)])["illumination"]
        let sunAndFungus = PressureRules.resolve([
            sigil("sun", "illumination", .great),
            sigil("fungus", "illumination"),
        ])["illumination"]

        XCTAssertGreaterThan(sunAndFungus.floor, sunAlone.floor, "The nights are never fully black now")
        XCTAssertLessThan(sunAndFungus.range, sunAlone.range, "…so the range narrows")
    }

    /// "Bright above, dim below." Occlusion pushes the peak down without inverting anything.
    func testOcclusionDimsWithoutInverting() {
        let open = PressureRules.resolve([sigil("sun", "illumination", .great)])["illumination"]
        let shaded = PressureRules.resolve([
            sigil("sun", "illumination", .great),
            sigil("canopy", "illumination", .great),
        ])["illumination"]

        XCTAssertLessThan(shaded.peak, open.peak)
        XCTAssertGreaterThanOrEqual(shaded.peak, shaded.floor, "Peak may never resolve below floor")
        XCTAssertTrue(shaded.has("elevation"), "A two-storey world")
    }

    /// The floor rule: if occlusion would drive the peak under the floor, they converge into a
    /// uniformly murky world rather than an impossible one.
    func testPeakNeverFallsBelowFloor() {
        let murk = PressureRules.resolve([
            sigil("magma", "illumination"),
            sigil("void", "illumination", .overwhelming),
            sigil("ash", "illumination", .overwhelming),
        ])["illumination"]

        XCTAssertGreaterThanOrEqual(murk.peak, murk.floor)
        XCTAssertGreaterThanOrEqual(murk.peak, 0)
    }

    // MARK: Implicit secondaries, and denying them

    /// "You cannot have bright without hot unless you do something about it."
    func testASourceContributesToTargetsYouDidNotBind() {
        let readings = PressureRules.resolve([sigil("sun", "illumination", .great)])

        XCTAssertGreaterThan(readings["illumination"].peak, 0)
        XCTAssertGreaterThan(readings["thermal"].peak, 0, "The sun warms whether you asked or not")
    }

    /// A sun that does not warm. The most important test here: the *thing you did* has to stay
    /// visible. Read the net alone and this world looks like one nobody wrote.
    func testContradictionIsVisibleEvenWhenItNetsToNothing() {
        let honest = PressureRules.resolve([sigil("sun", "illumination", .great)])
        let denied = PressureRules.resolve([
            sigil("sun", "illumination", .great, negating: ["thermal"]),
        ])

        XCTAssertEqual(denied["thermal"].peak, 0, "The heat is genuinely gone")
        XCTAssertEqual(honest["thermal"].opposedMagnitude, 0, "Nothing was fought over")
        XCTAssertGreaterThan(denied["thermal"].opposedMagnitude, 0,
                             "…but the force spent denying it must still be on the books")
        XCTAssertGreaterThan(denied.totalOpposed, honest.totalOpposed)
        XCTAssertEqual(denied["illumination"].peak, honest["illumination"].peak,
                       "Denying the heat doesn't dim the light")
    }

    /// Contradiction is measured gross. Two suns denied are twice the crime of one.
    func testOpposedMagnitudeScalesWithHowHardYouPush() {
        let once = PressureRules.resolve([sigil("sun", "illumination", .moderate, negating: ["thermal"])])
        let harder = PressureRules.resolve([sigil("sun", "illumination", .overwhelming, negating: ["thermal"])])

        XCTAssertGreaterThan(harder["thermal"].opposedMagnitude, once["thermal"].opposedMagnitude)
    }

    // MARK: Stacking

    /// Three suns are brighter than one, but not three times brighter — otherwise the correct play
    /// is always "write the same rune as many times as it fits".
    func testStackingDiminishes() {
        let one = PressureRules.resolve([sigil("moon", "illumination")])["illumination"].peak
        let three = PressureRules.resolve([
            sigil("moon", "illumination"),
            sigil("moon", "illumination"),
            sigil("moon", "illumination"),
        ])["illumination"].peak

        XCTAssertGreaterThan(three, one, "More is more")
        XCTAssertLessThan(three, one * 3, "…but not linearly")
    }

    func testNothingExceedsTheScale() {
        let blinding = (0..<8).map { _ in sigil("sun", "illumination", .overwhelming) }
        let light = PressureRules.resolve(blinding)["illumination"]
        XCTAssertLessThanOrEqual(light.peak, Tuning.Pressure.scaleMaximum)
        XCTAssertGreaterThanOrEqual(light.floor, 0)
    }

    func testAnEmptyPageIsAnEmptyWorld() {
        let readings = PressureRules.resolve([])
        for reading in readings.inOrder {
            XCTAssertEqual(reading.peak, 0)
            XCTAssertEqual(reading.opposedMagnitude, 0)
        }
        XCTAssertEqual(readings.totalOpposed, 0)
    }

    // MARK: Content

    func testEveryTargetResolvesAndOnlyTwoCarryAFloor() {
        let dual = ContentCatalog.shared.pressureTargets.filter(\.dualValued).map(\.id.rawValue).sorted()
        XCTAssertEqual(dual, ["illumination", "thermal"],
                       "Dim and dark are different pressures; the other six don't need two numbers")
        XCTAssertEqual(ContentCatalog.shared.pressureTargets.count, 8)
    }

    func testEverySourceIsWritable() {
        for source in ContentCatalog.shared.pressureSources {
            XCTAssertFalse(source.targets.isEmpty, "'\(source.id)' binds to nothing")
            for target in source.targets {
                XCTAssertNotNil(ContentCatalog.shared.pressureTarget(target))
            }
        }
    }
}
