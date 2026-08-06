import Foundation

/// What an animal actually is, as numbers rather than as a name.
///
/// **Identity is derived, never imposed** (decisions-session-15 §4). Traits are rolled from the
/// world's distributions and what the creature *is* — ambusher, tank, grazer — is read off them
/// afterwards. Deciding roles in advance would smuggle Earth's ecology into worlds that were never
/// meant to have it: not every world has grazers, and if nothing grows, nothing grazes.
///
/// The stored record is always the vector. Identity definitions can then change without breaking a
/// single save — the same rule the bestiary and materials both rely on.
struct CreatureTraits: Codable, Equatable, Sendable {
    /// All 0–100.
    var size: Double = 50
    /// Sleek ↔ bulky.
    var build: Double = 50
    /// How much it's wearing: sparse ↔ dense.
    var covering: Double = 50
    /// Soft ↔ hard. Biomineralisation lives here.
    var coveringHardness: Double = 50
    var boneDensity: Double = 50
    /// Close ↔ far. Reach of whatever it hits you with.
    var reach: Double = 50
    /// How much it can hurt you.
    var armament: Double = 50
    /// Blends in ↔ announces itself. Crypsis at one end, aposematism at the other.
    var conspicuousness: Double = 50
    /// How much it spends on looking expensive. Only affordable in rich worlds.
    var ornament: Double = 0
    /// Eyes ↔ everything else.
    var vision: Double = 50
    var nonVisualSense: Double = 50
    /// Makes its own light. Rare, and mostly a dark-world adaptation.
    var emanation: Double = 0

    /// What this costs the world to keep alive. One pool, drawn on by everything — the square-cube
    /// law, the defence-mobility trade and costly signalling in a single rule, which is what stops
    /// any world producing an everything-creature.
    var appetite: Double {
        (size * 0.35 + build * 0.1 + covering * 0.12 + coveringHardness * 0.1
         + armament * 0.15 + ornament * 0.18) / 10
    }
}

/// A species: a trait vector a world settled on, and the animals that vary around it.
///
/// **Two levels** (session 15 §1). A world holds a small **cast** of species, and every spawn is its
/// species plus small **jitter** — mostly coloration and minor form, never enough to change what it
/// is or how it fights. So you meet the same few animals repeatedly and each one is visibly its own
/// animal.
///
/// This is what the bestiary's two tiers were waiting for: the **species** is the entry, and
/// individual spawns are **specimens** under it.
struct Species: Codable, Equatable, Identifiable, Sendable {
    var id: InstanceID
    /// The centre this species varies around.
    var traits: CreatureTraits
    /// Which world it belongs to, so an anchored world keeps its cast forever.
    var worldSeed: UInt64

    /// Read off the traits, never stored. See `CreatureTraits`.
    var identity: String { CreatureIdentity.name(for: traits) }
}

/// Naming an animal from what it turned out to be.
///
/// Authored regions of trait space rather than a list of roles handed out in advance. A world that
/// produced nothing that hunts simply has no hunters in it.
enum CreatureIdentity {
    static func name(for traits: CreatureTraits) -> String {
        // Ordered so the most defining trait wins. Everything falls through to something.
        if traits.emanation > 60 { return "lantern" }
        if traits.coveringHardness > 70 && traits.build > 60 { return "bulwark" }
        if traits.armament > 65 && traits.conspicuousness < 35 { return "ambusher" }
        if traits.armament > 65 && traits.reach > 60 { return "courser" }
        if traits.armament > 65 { return "hunter" }
        if traits.conspicuousness > 70 { return "herald" }
        if traits.size < 30 && traits.covering < 40 { return "drifter" }
        if traits.armament < 30 && traits.size > 60 { return "browser" }
        if traits.nonVisualSense > 70 && traits.vision < 30 { return "groper" }
        return "creature"
    }
}
