import Foundation

/// A named contradiction: a specific thing a player can write that a world cannot be.
///
/// **Contradiction is a catalogue, never a formula** (`docs/contradiction-danger-spec.md` §1).
/// Nothing is inferred from opposed magnitudes, and that restraint is the entire safety mechanism:
/// a sunny snowy world is *real* — sun producing heat, glacier sinking it, an equilibrium — and
/// nature is full of opposed forces. If opposition itself were penalised, players would learn to
/// avoid the interesting combinations, which is the opposite of what the writing system is for.
///
/// So every contradiction here is authored, testable, and nameable in the preview. The catalogue
/// can grow with the vocabulary without retuning anything.
struct ContradictionDef: Codable, Equatable, Identifiable, Sendable {
    var id: ContradictionID
    /// Shown verbatim in the preview: "The sun you have written does not warm."
    var name: String
    var blurb: String
    var kind: Kind
    /// Stable catalogue rows may be held when their current mechanical predicate cannot honestly
    /// establish the fiction they claim. They remain decodable/referenceable but never fire.
    var enabled: Bool
    /// `negation` only: the source whose nature is being denied.
    var source: PressureSourceID?
    /// `negation` only: the target the player wrote a Negate rune against.
    var negatedTarget: PressureTargetID?
    /// `assertion` only: the source that must actually be on the page. An assertion fires on what
    /// the player *wrote*, never on what a constraint or a chance-fill happened to produce.
    var requiresWrittenSource: PressureSourceID?
    /// `assertion` only: the state of the world that makes the assertion impossible.
    var conditions: [PressureCondition]
    /// Same units as the Stability headline.
    var instability: Int

    /// Negation entries carry no conditions and assertion entries carry no source/target, so every
    /// optional half decodes as absent rather than failing the whole catalogue.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(ContradictionID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        blurb = try container.decodeIfPresent(String.self, forKey: .blurb) ?? ""
        kind = try container.decode(Kind.self, forKey: .kind)
        enabled = try container.decodeIfPresent(Bool.self, forKey: .enabled) ?? true
        source = try container.decodeIfPresent(PressureSourceID.self, forKey: .source)
        negatedTarget = try container.decodeIfPresent(PressureTargetID.self, forKey: .negatedTarget)
        requiresWrittenSource = try container.decodeIfPresent(PressureSourceID.self, forKey: .requiresWrittenSource)
        conditions = try container.decodeIfPresent([PressureCondition].self, forKey: .conditions) ?? []
        instability = try container.decode(Int.self, forKey: .instability)
    }

    enum Kind: String, Codable, Sendable {
        /// Denying a property a source inherently has. Always deliberate, always visible — you had
        /// to write a Negate rune, so it can never happen by accident. The safest category, and
        /// where most contradiction should live.
        case negation
        /// A world asserting a state its own conditions forbid. Enumerated only, never inferred.
        case assertion
    }

    /// Whether this contradiction is present in a written page.
    ///
    /// Takes the sigils as well as the readings on purpose: an assertion must fire on what the
    /// player *asserted*, not on the resolved world. A world that ends up dark because of a
    /// chance-filled slot hasn't contradicted anything — nobody claimed otherwise.
    func fires(sigils: [Sigil], readings: PressureReadings) -> Bool {
        guard enabled else { return false }
        switch kind {
        case .negation:
            guard let source, let negatedTarget else { return false }
            return sigils.contains { $0.source == source && $0.negatedTargets.contains(negatedTarget) }
        case .assertion:
            guard let required = requiresWrittenSource else { return false }
            guard sigils.contains(where: { $0.source == required }) else { return false }
            return !conditions.isEmpty && conditions.allSatisfy { $0.holds(in: readings) }
        }
    }
}
