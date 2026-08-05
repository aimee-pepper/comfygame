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
    func testContradictionIsVisibleEvenWhenItNetsToNothing() throws {
        let honest = PressureRules.resolve([sigil("sun", "illumination", .great)])
        let denied = PressureRules.resolve([
            sigil("sun", "illumination", .great, negating: ["thermal"]),
        ])

        let baseline = try XCTUnwrap(ContentCatalog.shared.pressureTarget("thermal")).baseline
        XCTAssertEqual(denied["thermal"].peak, baseline, accuracy: 0.001,
                       "The sun's heat is genuinely gone — the world is merely as warm as any other")
        XCTAssertGreaterThan(honest["thermal"].peak, baseline, "…where an honest sun would have warmed it")
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

    /// An unwritten page isn't a void — it's every target sitting at its baseline. Thermal starts
    /// temperate rather than frozen precisely so that every climate has to be *authored*.
    func testAnUnwrittenPageSitsAtTheBaseline() {
        let readings = PressureRules.resolve([])
        for target in ContentCatalog.shared.pressureTargets {
            XCTAssertEqual(readings[target.id].peak, target.baseline, accuracy: 0.001,
                           "'\(target.id)' should start at its baseline")
            XCTAssertEqual(readings[target.id].opposedMagnitude, 0)
        }
        XCTAssertEqual(readings.totalOpposed, 0)
        XCTAssertGreaterThan(readings["thermal"].peak, 0, "A world nobody wrote about is temperate")
        XCTAssertEqual(readings["illumination"].peak, 0, "…but nobody lit it")
    }

    // MARK: The teeth — cross-target constraints

    /// Dry caps life, whatever you wrote. Without this, every world is teeming.
    func testDryWorldsCannotBeTeeming() {
        let desert = PressureRules.resolve([
            sigil("sun", "illumination", .great),
            sigil("sand", "substrate", .overwhelming),
            sigil("canopy", "vitality", .overwhelming),   // asking for a jungle anyway
        ])
        XCTAssertLessThan(desert["vitality"].peak, 60, "A dry world can't carry a jungle")
        XCTAssertTrue(desert["vitality"].has("water-limited") || desert["vitality"].has("light-limited"))
    }

    /// …unless something down there is eating rather than photosynthesising. The exemption is the
    /// interesting case, not a loophole.
    func testLightlessWorldsNeedANonPhotosyntheticBase() {
        let deadDark = PressureRules.resolve([
            sigil("rain", "hydrology", .great),
            sigil("canopy", "vitality", .great),
        ])
        let fungalDark = PressureRules.resolve([
            sigil("rain", "hydrology", .great),
            sigil("fungus", "vitality", .great),
        ])

        XCTAssertTrue(deadDark["vitality"].has("light-limited"),
                      "No light and no fungus means no food web")
        XCTAssertFalse(fungalDark["vitality"].has("light-limited"),
                       "Fungal worlds feed themselves in the dark")
    }

    /// "Write Sea on a frozen world and you get a glacier whether you asked for one or not."
    func testHeatDecidesWhatFormWaterTakes() {
        let frozen = PressureRules.resolve([
            sigil("sea", "hydrology", .great),
            sigil("glacier", "thermal", .overwhelming),
        ])["hydrology"]

        XCTAssertGreaterThan(frozen.share(of: "frozen"), 0, "The sea froze over")
        XCTAssertLessThan(frozen.availableMagnitude, frozen.peak,
                          "…and frozen water is water the world can't use")
        XCTAssertTrue(frozen.has("frozen-over"))
    }

    /// Thick air holds heat and narrows the swing; thin air widens it. Same sun, opposite worlds.
    func testAirDecidesHowFarTheTemperatureSwings() {
        let buffered = PressureRules.resolve([
            sigil("sun", "illumination"),
            sigil("cloud", "atmosphere", .great),
        ])["thermal"]
        let exposed = PressureRules.resolve([
            sigil("sun", "illumination"),
            sigil("thin_air", "atmosphere", .great),
        ])["thermal"]

        XCTAssertLessThan(buffered.range, exposed.range, "Thin air is a wider swing")
        XCTAssertTrue(exposed.has("arid-swing"))
        XCTAssertTrue(buffered.has("thermally-buffered"))
    }

    // MARK: The energy budget

    /// The one mechanic that stops everything-creatures: size, armour and insulation all draw on
    /// the same purse, and a cold poor world can't fill it.
    func testColdAndPoorTogetherCapHowBigThingsGet() {
        let rich = PressureRules.resolve([
            sigil("sun", "illumination", .great),
            sigil("rain", "hydrology", .great),
            sigil("canopy", "vitality", .great),
        ])
        let coldAndPoor = PressureRules.resolve([
            sigil("glacier", "thermal", .great),
            sigil("void", "illumination", .great),
        ])

        XCTAssertGreaterThan(WorldConstraints.maximumCreatureSize(in: rich),
                             WorldConstraints.maximumCreatureSize(in: coldAndPoor))
        XCTAssertEqual(WorldConstraints.maximumCreatureSize(in: coldAndPoor), 0, accuracy: 0.001,
                       "A frozen dead world feeds nothing large")
    }

    // MARK: Reading a world's character

    /// Openness sets the ambush↔pursuit axis, which then constrains build, reach and crypsis.
    func testOpenGroundMakesPursuitAndEnclosedGroundMakesAmbush() {
        let open = WorldConstraints.character(of: PressureRules.resolve([sigil("sea", "relief", .great)]))
        let enclosed = WorldConstraints.character(of: PressureRules.resolve([sigil("canopy", "relief", .great)]))

        XCTAssertTrue(open.contains("pursuit"))
        XCTAssertTrue(enclosed.contains("ambush"))
    }

    /// Cold has four co-valid answers and the *other* targets pick between them — fur fails when
    /// it's wet, so wet-cold and dry-cold are different worlds.
    func testWetColdAndDryColdAreDifferentAnswers() {
        let wet = WorldConstraints.character(of: PressureRules.resolve([
            sigil("ice", "thermal", .great),
            sigil("rain", "hydrology", .overwhelming),
        ]))
        let dry = WorldConstraints.character(of: PressureRules.resolve([
            sigil("ice", "thermal", .great),
            sigil("sand", "substrate", .great),
        ]))

        XCTAssertTrue(wet.contains("wet-cold"))
        XCTAssertTrue(dry.contains("dry-cold"))
    }

    /// Iridescence needs light to signal in *and* something hard to refract it — neither alone.
    func testIridescenceNeedsBothLightAndHardGround() {
        let both = WorldConstraints.character(of: PressureRules.resolve([
            sigil("sun", "illumination", .great),
            sigil("granite", "substrate", .great),
        ]))
        let lightOnly = WorldConstraints.character(of: PressureRules.resolve([
            sigil("sun", "illumination", .great),
        ]))

        XCTAssertTrue(both.contains("iridescence-enabled"))
        XCTAssertFalse(lightOnly.contains("iridescence-enabled"))
    }

    // MARK: Silence is rolled, not defaulted

    /// A target nobody wrote about is **rolled**, not set to something sensible. Otherwise every
    /// under-specified world is the same tepid place, and leaving a slot open stops being a
    /// gamble worth taking.
    func testAnUnwrittenTargetIsRolledRatherThanDefaulted() {
        let page = [sigil("sun", "illumination", .great)]
        var distinct = Set<Double>()
        for seed in (1...25).map({ UInt64($0) &* 2_654_435_761 }) {
            distinct.insert(PressureRules.resolve(page, fillingUnwrittenWith: seed)["hydrology"].peak)
        }
        XCTAssertGreaterThan(distinct.count, 3,
                             "Unwritten hydrology should vary between worlds, not sit at a default")
    }

    /// Same seed, same world — the roll has to be reproducible or the pre-bind preview is lying.
    func testTheRollIsDeterministicInTheSeed() {
        let page = [sigil("sun", "illumination")]
        XCTAssertEqual(PressureRules.resolve(page, fillingUnwrittenWith: 777),
                       PressureRules.resolve(page, fillingUnwrittenWith: 777))
        XCTAssertNotEqual(PressureRules.resolve(page, fillingUnwrittenWith: 777),
                          PressureRules.resolve(page, fillingUnwrittenWith: 778))
    }

    /// Rolling never *replaces* what you wrote — it only speaks where you didn't.
    ///
    /// It can still change what you wrote, though, and deliberately: a rolled source drags its own
    /// secondaries in with it, so chance rolling heavy ash for the atmosphere will dim the sun you
    /// carefully specified. The world arguing back is the system working, not a leak.
    func testRollingSpeaksOnlyWhereYouWereSilent() {
        let page = [sigil("sun", "illumination", .great)]
        let rolled = PressureRules.rollUnwritten(after: page, seed: 4242)

        for extra in rolled {
            XCTAssertNotEqual(extra.target, "illumination", "You already said what the light is")
            XCTAssertNotEqual(extra.target, "thermal", "…and the sun said what the heat is")
        }
    }

    /// The consequence worth having: what chance brings can change the world you thought you wrote.
    func testWhatChanceBringsCanActOnWhatYouWrote() {
        let page = [sigil("sun", "illumination", .great)]
        let alone = PressureRules.resolve(page)["illumination"].peak
        let withRolls = (1...30).map {
            PressureRules.resolve(page, fillingUnwrittenWith: UInt64($0) &* 65_537)["illumination"].peak
        }
        XCTAssertTrue(withRolls.contains { $0 != alone },
                      "A rolled source's secondaries should be able to reach the light you wrote")
    }

    /// Chance draws from the whole pool — including sources the player has no way to write.
    func testChanceCanReachThingsThePlayerCannotWrite() {
        let rolled = PressureRules.rollUnwritten(after: [], seed: 99)
        XCTAssertFalse(rolled.isEmpty)
        let pool = Set(ContentCatalog.shared.pressureSources.map(\.id))
        for sigil in rolled {
            XCTAssertTrue(pool.contains(sigil.source))
        }
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
