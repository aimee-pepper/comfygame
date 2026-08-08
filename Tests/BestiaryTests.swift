import XCTest
@testable import Bookbinder

/// **Personal and global, both shown** (session 3 §4a). Only the personal half existed, and it was
/// displayed nowhere — the bestiary had no screen at all, so every specimen, trait vector and
/// derived identity went into the save unreadable.
final class BestiaryTests: XCTestCase {

    private func traits(size: Double) -> CreatureTraits {
        var t = CreatureTraits()
        t.size = size
        return t
    }

    private func log(sizes: [Double], key: String = "thing") -> DiscoveryLog {
        var discovery = DiscoveryLog()
        discovery.recordSpecies(key, runIndex: 1)
        for size in sizes { discovery.recordSpecimen(traits(size: size), of: key, runIndex: 1) }
        return discovery
    }

    // MARK: The two halves say different things

    /// **The whole reason the spec asked for both.** Personal drifts as you see more; global
    /// doesn't. A player who has only ever met giants should be told their next giant is ordinary
    /// *for a giant* and still enormous *for an animal* — one number cannot say both.
    func testTheTwoPercentilesDisagreeAndThatIsThePoint() throws {
        // Somebody who has only met very large ones. The newest is the smallest they've seen.
        let discovery = log(sizes: [90, 92, 94, 96])
        let smallestGiant = try XCTUnwrap(discovery.specimens(of: "thing").min { $0.traits.size < $1.traits.size })

        let personal = BestiaryRules.personalPercentile(of: smallestGiant, by: .size, in: discovery)
        let global = BestiaryRules.globalPercentile(of: smallestGiant.traits, by: .size)

        XCTAssertEqual(personal, 0, accuracy: 0.01, "the smallest of what you've seen is your bottom")
        XCTAssertGreaterThan(global, 0.8,
                             "…and it is still a very large animal by the standards of everything alive")
    }

    /// The reference is what the generator actually makes, so it has a spread rather than a point.
    func testTheGlobalScaleIsMeasuredAgainstWhatWorldsActuallyGrow() {
        let tiny = BestiaryRules.globalPercentile(of: traits(size: 0), by: .size)
        let huge = BestiaryRules.globalPercentile(of: traits(size: 100), by: .size)
        let middling = BestiaryRules.globalPercentile(of: traits(size: 50), by: .size)

        XCTAssertLessThan(tiny, 0.2, "nothing is smaller than the smallest thing that lives")
        XCTAssertGreaterThan(huge, 0.9)
        XCTAssertTrue((0.1...0.95).contains(middling),
                      "a middling animal should land somewhere in the middle, not at a clamp")
        XCTAssertLessThan(tiny, middling)
        XCTAssertLessThan(middling, huge)
    }

    /// Every measure has to discriminate, or the row it draws is decoration.
    func testEveryMeasureTellsAnimalsApart() {
        for measure in BestiaryRules.Measure.allCases {
            var low = CreatureTraits(), high = CreatureTraits()
            switch measure {
            case .size: low.size = 0; high.size = 100
            case .covering:
                low.covering = Covering(hardness: 0, length: 0, coverage: 0)
                high.covering = Covering(hardness: 100, length: 100, coverage: 100)
            case .armament:
                high.armament.pierce = 100
                high.armament.crush = 100
                high.armament.rend = 100
            case .ornament: low.ornament = 0; high.ornament = 100
            case .bone: low.boneDensity = 0; high.boneDensity = 100
            }
            XCTAssertLessThan(BestiaryRules.globalPercentile(of: low, by: measure),
                              BestiaryRules.globalPercentile(of: high, by: measure),
                              "\(measure.displayName) reads the same for opposite animals")
        }
    }

    // MARK: Honesty about small samples

    /// A percentile over two animals is not the same claim as one over forty, and printing them
    /// identically teaches the player to distrust every other number on screen.
    func testAPercentileSaysHowManyItWasMeasuredAgainst() throws {
        let discovery = log(sizes: [10, 90])
        let biggest = try XCTUnwrap(discovery.specimens(of: "thing").max { $0.traits.size < $1.traits.size })
        XCTAssertEqual(BestiaryRules.peerCount(of: biggest, in: discovery), 2)

        let remark = BestiaryRules.remark(
            personal: BestiaryRules.personalPercentile(of: biggest, by: .size, in: discovery),
            peers: 2,
            global: 0,
            measure: .size)
        XCTAssertEqual(remark, "the largest of 2 you've seen",
                       "a superlative has to say what it beat")
    }

    /// One specimen is no population at all, so nothing is claimed about it personally.
    func testASingleSpecimenMakesNoPersonalClaim() throws {
        let discovery = log(sizes: [50])
        let only = try XCTUnwrap(discovery.specimens(of: "thing").first)
        XCTAssertEqual(BestiaryRules.peerCount(of: only, in: discovery), 1)
        XCTAssertNil(BestiaryRules.remark(personal: 1, peers: 1, global: 0, measure: .size),
                     "'the largest of 1 you've seen' is not a compliment")
    }

    // MARK: The screen

    /// Recording something has to make it appear. This is the half that never existed.
    func testMeetingSomethingPutsItInTheBestiary() {
        var discovery = DiscoveryLog()
        XCTAssertTrue(BestiaryRules.entries(in: discovery).isEmpty)

        discovery.recordSpecies("stalker", runIndex: 3)
        discovery.recordSpecimen(traits(size: 70), of: "stalker", runIndex: 3)

        let entries = BestiaryRules.entries(in: discovery)
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries.first?.firstSeenRunIndex, 3)
        XCTAssertEqual(entries.first?.specimens.count, 1)
        XCTAssertFalse(entries.first?.name.isEmpty ?? true, "an entry with no name is a blank row")
    }

    /// A kind you have heard of but never met stays a silhouette — an empty record must not
    /// become a bestiary page (session 3).
    func testAKindYouHaveNotMetIsNotListed() {
        var discovery = DiscoveryLog()
        discovery.species["rumour"] = DiscoveryRecord()
        XCTAssertTrue(BestiaryRules.entries(in: discovery).isEmpty,
                      "something never seen turned up in the bestiary")
    }

    @MainActor
    func testTheBestiaryIsSomewhereYouCanActuallyGo() throws {
        let station = try XCTUnwrap(ContentCatalog.shared.station("bestiary"))
        XCTAssertEqual(station.route, "bestiary")
        XCTAssertTrue(station.unlockedAtStart, "there is nothing to unlock about writing down what you saw")
        XCTAssertNotNil(AppRoute(rawValue: station.route), "the station points at no screen")
    }
}
