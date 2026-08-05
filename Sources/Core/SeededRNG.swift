import Foundation

/// Deterministic, *serializable* RNG.
///
/// Why hand-rolled instead of `GKMersenneTwisterRandomSource` (the brief allows either):
/// pillar 2 requires that a force-quit mid-run resume exactly, which means the RNG's position in
/// its stream has to survive a save round-trip. SplitMix64's entire state is one `UInt64`, so
/// `Codable` conformance is exact and free — no replaying N draws on load, and no dependency on
/// GameplayKit's unpublished internals staying stable across OS versions.
///
/// Two distinct uses, deliberately kept apart:
///  - `mapSeed` on a run: worldgen re-derives a *fresh* RNG from it, so the same map regenerates
///    identically however many times we rebuild it.
///  - `rng` on a run: the live stream for in-run rolls (drops, combat). Advances and is saved.
struct SeededRNG: RandomNumberGenerator, Codable, Equatable, Sendable {
    /// The seed this stream started from. Kept for display/reproduction; never mutated.
    let seed: UInt64
    private(set) var state: UInt64
    /// Number of raw 64-bit draws taken. Diagnostics only — resume uses `state`, not a replay.
    private(set) var drawCount: Int

    init(seed: UInt64) {
        self.seed = seed
        self.state = seed
        self.drawCount = 0
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        drawCount += 1
        return z ^ (z >> 31)
    }

    /// A fresh independent stream derived from this seed plus a salt.
    /// Use for sub-streams that must be reproducible without disturbing the live stream
    /// (e.g. terrain pass vs. enemy-placement pass of the same map).
    func derived(_ salt: UInt64) -> SeededRNG {
        var mixer = SeededRNG(seed: seed &+ (salt &* 0x9E37_79B9_7F4A_7C15))
        return SeededRNG(seed: mixer.next())
    }

    // MARK: - Convenience

    mutating func int(in range: ClosedRange<Int>) -> Int {
        Int.random(in: range, using: &self)
    }

    mutating func double(in range: ClosedRange<Double>) -> Double {
        Double.random(in: range, using: &self)
    }

    mutating func chance(_ probability: Double) -> Bool {
        probability > 0 && double(in: 0...1) < probability
    }

    mutating func pick<T>(_ elements: [T]) -> T? {
        elements.isEmpty ? nil : elements[int(in: 0...(elements.count - 1))]
    }

    /// Weighted pick. Non-positive weights are skipped.
    mutating func pickWeighted<T>(_ elements: [(value: T, weight: Double)]) -> T? {
        let total = elements.reduce(0) { $0 + max(0, $1.weight) }
        guard total > 0 else { return nil }
        var roll = double(in: 0...total)
        for element in elements where element.weight > 0 {
            roll -= element.weight
            if roll <= 0 { return element.value }
        }
        return elements.last(where: { $0.weight > 0 })?.value
    }
}

/// Source of new seeds. Lives in the save so the seed sequence itself is deterministic and
/// resumable — a relaunch must not re-roll a seed the player already saw in a preview.
struct SeedSequence: Codable, Equatable, Sendable {
    private(set) var rootSeed: UInt64
    private(set) var issued: UInt64

    init(rootSeed: UInt64) {
        self.rootSeed = rootSeed
        self.issued = 0
    }

    /// A brand-new sequence rooted in real entropy. Called exactly once, at new-game.
    static func newGame() -> SeedSequence {
        SeedSequence(rootSeed: UInt64.random(in: UInt64.min...UInt64.max))
    }

    mutating func nextSeed() -> UInt64 {
        var stream = SeededRNG(seed: rootSeed).derived(issued)
        issued += 1
        return stream.next()
    }

    /// Peek without consuming — for pre-bind previews that must not burn a seed.
    func peekNextSeed() -> UInt64 {
        var stream = SeededRNG(seed: rootSeed).derived(issued)
        return stream.next()
    }
}
