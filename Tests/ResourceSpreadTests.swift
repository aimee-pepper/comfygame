import XCTest
@testable import Bookbinder

/// **A resource is a reason to write one world rather than another** (resources-skills-spec §1).
///
/// With four of them every world handed you the same handful of things, so the authoring system —
/// the actual game — had nothing to aim at. These tests defend the property that makes twenty-one
/// worth having: that what a world *is* decides what it pays.
final class ResourceSpreadTests: XCTestCase {

    private func yields(_ readings: PressureReadings) -> [ResourceID] {
        BookRules.yieldTable(from: readings).map(\.value)
    }

    /// A world written from a blank page, so the seed does the composing.
    private func rolled(_ seed: UInt64) -> PressureReadings {
        BookRules.readings(for: BookRules.resolveBook(page: Page()), seed: seed)
    }

    /// Nothing is universally available. A resource that appears in every world is a resource that
    /// gives you no reason to write anything in particular.
    func testNoResourceComesFromEverywhere() {
        let empty = PressureReadings(readings: [:])
        let common = Set(yields(empty))
        XCTAssertLessThan(common.count, ContentCatalog.shared.resources.count / 2,
                          "a blank world pays out most of the catalogue")
    }

    /// And the opposite failure: a world that is genuinely nothing still can't be a dead end.
    func testEveryWorldPaysSomething() throws {
        var seeds = SeedSequence(rootSeed: 12345)
        for _ in 0..<40 {
            XCTAssertFalse(yields(rolled(seeds.nextSeed())).isEmpty,
                           "a world that pays nothing at all is a wasted book")
        }
    }

    /// Every resource has to be reachable — one nobody can ever write for is dead content.
    func testEveryResourceIsReachableBySomeWorld() {
        var unreachable = Set(ContentCatalog.shared.resources.map(\.id))
        var seeds = SeedSequence(rootSeed: 99)
        // Motes are banked separately and never appear in the yield table.
        unreachable.remove(Resources.mote)
        for _ in 0..<400 {
            for id in yields(rolled(seeds.nextSeed())) { unreachable.remove(id) }
        }
        XCTAssertTrue(unreachable.isEmpty,
                      "no world in four hundred paid: \(unreachable.map(\.rawValue).sorted())")
    }

    /// **What you write is what you get.**
    ///
    /// This is the whole claim the expanded catalogue rests on: a resource is a reason to write one
    /// world rather than another. Two books, the same two hundred seeds — one asking for life, one
    /// for a frozen ash-fall — and what they pay has to differ.
    func testWhatYouWriteDecidesWhatTheWorldPays() throws {
        let lively = BoundBook(symbols: ["terrain": "plains", "biome": "verdant",
                                         "bounty": "teeming_life"],
                               randomlyFilled: [], essencePaid: 0)
        let dead = BoundBook(symbols: ["terrain": "caverns", "biome": "frostbound",
                                       "bounty": "rich_ore"],
                             randomlyFilled: [], essencePaid: 0)

        var grew = 0, mined = 0, grewOnDead = 0
        var seeds = SeedSequence(rootSeed: 4242)
        for _ in 0..<200 {
            let seed = seeds.nextSeed()
            if yields(BookRules.readings(for: lively, seed: seed)).contains(Resources.fiber) { grew += 1 }
            if yields(BookRules.readings(for: dead, seed: seed)).contains(Resources.ore) { mined += 1 }
            if yields(BookRules.readings(for: dead, seed: seed)).contains(Resources.fiber) { grewOnDead += 1 }
        }
        XCTAssertGreaterThan(mined, 150, "a world written for ore didn't reliably hold any")
        XCTAssertGreaterThan(grew, grewOnDead,
                             "writing for life made no difference to what the world grew")
        // Deliberately loose on the life side. A book that asks for life outright still only grows
        // anything about 60% of the time, because `teeming_life` expands to one producer and two
        // *consumers* whose negative peaks cancel most of it — measured, written up as Q38, and not
        // something to fix by quietly retuning the designer's vocabulary.
        XCTAssertGreaterThan(grew, 100, "a world written for life almost never grew anything")
    }

    /// A printout of how often each resource turns up, so a rebalance can be judged rather than
    /// guessed at. Not an assertion — it fails nothing; it tells you what the numbers are.
    func testReportTheSpread() {
        var seeds = SeedSequence(rootSeed: 7)
        var seen: [ResourceID: Int] = [:]
        let worlds = 300
        for _ in 0..<worlds {
            for id in yields(rolled(seeds.nextSeed())) { seen[id, default: 0] += 1 }
        }
        let lines = seen.sorted { $0.value > $1.value }
            .map { "\($0.key.rawValue): \($0.value * 100 / worlds)%" }
        print("resource spread over \(worlds) worlds — " + lines.joined(separator: ", "))
    }

    /// **The exotic ones are gated, not merely favoured.** Mercury is something you go and write
    /// for; if a barren world hands it to you, richness stops meaning anything.
    func testAPoorWorldPaysNothingExotic() {
        let poor = PressureReadings(readings: [
            "substrate": PressureReading(target: "substrate", peak: 6, floor: 0,
                                         opposedMagnitude: 0, aspects: [:], forms: [:], tags: []),
            "vitality": PressureReading(target: "vitality", peak: 4, floor: 0,
                                        opposedMagnitude: 0, aspects: [:], forms: [:], tags: [])
        ])
        let paid = Set(yields(poor))
        for exotic: ResourceID in ["gold", "mercury", "adamant", "rift_glass", "ichor"] {
            XCTAssertFalse(paid.contains(exotic), "a barren world paid out \(exotic.rawValue)")
        }
    }
}
