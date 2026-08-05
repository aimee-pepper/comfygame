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

    /// Random-filling empty book slots is part of worldgen, so it has to be seed-stable too.
    func testBookResolutionIsStableForASeed() {
        let owned = Set(ContentCatalog.shared.starterSymbolIDs)
        var draft = BookDraft()
        draft[.terrain] = "caverns"

        let first = BookRules.resolveBook(draft: draft, ownedSymbols: owned, seed: 31337)
        let second = BookRules.resolveBook(draft: draft, ownedSymbols: owned, seed: 31337)
        let other = BookRules.resolveBook(draft: draft, ownedSymbols: owned, seed: 31338)

        XCTAssertEqual(first, second, "Same seed, same book")
        XCTAssertEqual(first.symbols[.terrain], "caverns", "A chosen symbol is never overwritten")
        XCTAssertFalse(first.randomlyFilled.contains(.terrain))
        XCTAssertTrue(first.randomlyFilled.contains(.biome), "Empty slots are random-filled, not left blank")
        XCTAssertNotEqual(first.symbols, other.symbols, "Different seeds should fill differently")
    }

    /// Two different compositions must produce visibly different worlds (acceptance criterion).
    func testDifferentBooksDecayAtDifferentRates() {
        let calm = BoundBook(symbols: [.terrain: "plains", .biome: "frostbound", .quirk: "dim_sky"],
                             randomlyFilled: [], essencePaid: 0)
        let greedy = BoundBook(symbols: [.terrain: "caverns", .biome: "ashen", .bounty: "rich_ore", .quirk: "gilded_veins"],
                               randomlyFilled: [], essencePaid: 0)

        XCTAssertLessThan(BookRules.decayPerTurn(for: calm), BookRules.decayPerTurn(for: greedy),
                          "A greedier book must burn its world down faster")
    }
}
