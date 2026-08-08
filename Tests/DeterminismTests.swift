import XCTest
@testable import Bookbinder

/// Seeded worldgen must be deterministic: the same seed always rebuilds the same world, and a
/// save/load in the middle changes nothing.
final class DeterminismTests: XCTestCase {

    func testSameSeedProducesSameSequence() {
        var a = SeededRNG(seed: 12345)
        var b = SeededRNG(seed: 12345)
        for _ in 0..<100 {
            XCTAssertEqual(a.next(), b.next())
        }
    }

    func testDifferentSeedsDiverge() {
        var a = SeededRNG(seed: 1)
        var b = SeededRNG(seed: 2)
        let drawsA = (0..<20).map { _ in a.next() }
        let drawsB = (0..<20).map { _ in b.next() }
        XCTAssertNotEqual(drawsA, drawsB)
    }

    func testDerivedStreamsAreIndependentAndReproducible() {
        let root = SeededRNG(seed: 777)
        var terrain = root.derived(1)
        var enemies = root.derived(2)
        var terrainAgain = root.derived(1)

        let first = (0..<10).map { _ in terrain.next() }
        let second = (0..<10).map { _ in enemies.next() }
        let firstAgain = (0..<10).map { _ in terrainAgain.next() }

        XCTAssertEqual(first, firstAgain, "A derived stream must be reproducible from its salt")
        XCTAssertNotEqual(first, second, "Different salts must give different streams")
    }

    func testEncodedRNGResumesMidStream() throws {
        var rng = SeededRNG(seed: 5150)
        for _ in 0..<25 { _ = rng.next() }
        let expected = (0..<5).map { _ in rng.next() }

        var rewound = SeededRNG(seed: 5150)
        for _ in 0..<25 { _ = rewound.next() }
        let encoded = try JSONEncoder().encode(rewound)
        var decoded = try JSONDecoder().decode(SeededRNG.self, from: encoded)

        XCTAssertEqual((0..<5).map { _ in decoded.next() }, expected)
    }

    func testSeedSequencePeekDoesNotConsume() {
        var seeds = SeedSequence(rootSeed: 4242)
        let peeked = seeds.peekNextSeed()
        XCTAssertEqual(seeds.peekNextSeed(), peeked, "Peeking twice must give the same seed")
        XCTAssertEqual(seeds.nextSeed(), peeked, "A preview must hand out the seed it previewed")
        XCTAssertNotEqual(seeds.nextSeed(), peeked, "Consuming must advance")
    }

    func testSeedSequenceSurvivesRoundTrip() throws {
        var seeds = SeedSequence(rootSeed: 8888)
        _ = seeds.nextSeed()
        _ = seeds.nextSeed()
        let expected = seeds.peekNextSeed()

        var decoded = try JSONDecoder().decode(SeedSequence.self, from: JSONEncoder().encode(seeds))
        XCTAssertEqual(decoded.nextSeed(), expected, "Relaunching must not re-roll the next world seed")
    }

    /// **The same page always makes the same book**, which is what the whole seeded-worldgen
    /// pillar stands on.
    ///
    /// This used to test random-filling empty *book slots*, and slots are gone — under-specification
    /// is a page that says nothing about a subject now, and the roll happens in
    /// `PressureRules.rollUnwritten` rather than at bind. So the seed-stability claim moved with it:
    /// a book is a pure function of its page, and what the *world* does with the silence is a
    /// function of the seed.
    func testBookResolutionIsStableForAPage() throws {
        let page = try pageWriting(["caverns"])
        XCTAssertEqual(BookRules.resolveBook(page: page), BookRules.resolveBook(page: page),
                       "Same page, same book")

        let book = BookRules.resolveBook(page: page)
        XCTAssertEqual(book.allSymbolIDs, ["caverns"])

        // And the silence resolves differently per seed, which is the surprise it exists to be.
        let sigils = BookRules.sigils(for: book)
        let one = PressureRules.resolve(sigils, fillingUnwrittenWith: 31337)
        let again = PressureRules.resolve(sigils, fillingUnwrittenWith: 31337)
        let other = PressureRules.resolve(sigils, fillingUnwrittenWith: 31338)
        XCTAssertEqual(one, again, "Same seed, same world")
        XCTAssertNotEqual(one, other, "Different seeds should fill the silence differently")
    }

    /// Writes symbols onto a fresh page, failing the test rather than silently producing a blank.
    private func pageWriting(_ ids: [SymbolID]) throws -> Page {
        var page = Page()
        for id in ids {
            let symbol = try XCTUnwrap(ContentCatalog.shared.symbol(id), "no symbol '\(id.rawValue)'")
            page = try XCTUnwrap(PageRules.placeAnywhere(symbol, hand: .refined, on: page),
                                 "'\(id.rawValue)' wouldn't fit on a blank page")
        }
        return page
    }

    /// Two different compositions must produce visibly different worlds (acceptance criterion).
    func testDifferentBooksDecayAtDifferentRates() {
        let calm = BoundBook(symbols: ["terrain": "plains", "biome": "frostbound", "quirk": "dim_sky"],
                             randomlyFilled: [], essencePaid: 0)
        let greedy = BoundBook(symbols: ["terrain": "caverns", "biome": "ashen", "bounty": "rich_ore", "quirk": "gilded_veins"],
                               randomlyFilled: [], essencePaid: 0)

        XCTAssertLessThan(BookRules.decayPerTurn(for: calm),
                          BookRules.decayPerTurn(for: greedy),
                          "A greedier book must burn its world down faster")
    }
}
