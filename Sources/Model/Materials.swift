import Foundation

/// What a creature leaves behind.
///
/// **No authored drop tables** (creature-system-spec §8): the parts that composed the creature
/// compose what it leaves. A world that grows monstrous armoured things drops monstrous plates —
/// which is the reason to write such a world, and it can't be true of a table someone typed out.
///
/// A material is a *kind* plus the properties it inherited from the animal it came off, so two
/// plates are not interchangeable. That's the whole economy of this: what you can make depends on
/// where you've been.
enum MaterialKind: String, Codable, CaseIterable, Equatable, Sendable {
    // From covering
    case plate, quill, pelt, down, hide, chitin
    // From armament
    case fang, tusk, claw
    // From the skeleton
    case bone
    // From whatever it was doing instead of being ordinary
    case ichor

    // Flora, for when `flora-system-spec.md` lands. Declared now so the material economy has one
    // vocabulary rather than two.
    case timber, fibre, pulp, toxin, reagent

    var displayName: String { rawValue.capitalisedSentence }

    /// **[PLACEHOLDER]** — session 11's glyph guidance applies to these too.
    var icon: String {
        switch self {
        case .plate, .chitin: "shield.lefthalf.filled"
        case .quill: "line.diagonal"
        case .pelt, .down, .hide: "square.stack.3d.down.right"
        case .fang, .claw: "triangle"
        case .tusk, .bone: "oval"
        case .ichor, .toxin, .reagent: "drop"
        case .timber: "rectangle.portrait"
        case .fibre: "scribble"
        case .pulp: "circle.dotted"
        }
    }
}

/// What a material is good for. Inherited from the traits that produced it, so a pelt off a
/// cold-world animal genuinely insulates better than one off a temperate animal.
struct MaterialProperties: Codable, Equatable, Sendable {
    var hardness: Double = 0
    var density: Double = 0
    var insulation: Double = 0
    var flexibility: Double = 0
    var lustre: Double = 0
    var reactivity: Double = 0

    init(hardness: Double = 0, density: Double = 0, insulation: Double = 0,
         flexibility: Double = 0, lustre: Double = 0, reactivity: Double = 0) {
        self.hardness = hardness
        self.density = density
        self.insulation = insulation
        self.flexibility = flexibility
        self.lustre = lustre
        self.reactivity = reactivity
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        hardness = try c.decodeIfPresent(Double.self, forKey: .hardness) ?? 0
        density = try c.decodeIfPresent(Double.self, forKey: .density) ?? 0
        insulation = try c.decodeIfPresent(Double.self, forKey: .insulation) ?? 0
        flexibility = try c.decodeIfPresent(Double.self, forKey: .flexibility) ?? 0
        lustre = try c.decodeIfPresent(Double.self, forKey: .lustre) ?? 0
        reactivity = try c.decodeIfPresent(Double.self, forKey: .reactivity) ?? 0
    }

    /// The property this material is really about — what a player would name it by.
    var dominant: (name: String, value: Double) {
        let all = [("hard", hardness), ("dense", density), ("warm", insulation),
                   ("supple", flexibility), ("lustrous", lustre), ("volatile", reactivity)]
        let best = all.max { $0.1 < $1.1 } ?? ("plain", 0)
        return (best.0, best.1)
    }
}

/// One drop: a kind, what it inherited, and how good an example of itself it is.
struct MaterialSample: Codable, Equatable, Sendable {
    var kind: MaterialKind
    var properties: MaterialProperties
    /// 0–100. **Grade scales with trait extremity** — an ordinary animal gives ordinary parts.
    var grade: Double
    /// Which animal it came off, so the storehouse can say where a thing is from.
    var source: String

    init(kind: MaterialKind, properties: MaterialProperties, grade: Double, source: String) {
        self.kind = kind
        self.properties = properties
        self.grade = grade
        self.source = source
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        kind = try c.decodeIfPresent(MaterialKind.self, forKey: .kind) ?? .hide
        properties = try c.decodeIfPresent(MaterialProperties.self, forKey: .properties)
            ?? MaterialProperties()
        grade = try c.decodeIfPresent(Double.self, forKey: .grade) ?? 0
        source = try c.decodeIfPresent(String.self, forKey: .source) ?? ""
    }

    /// What it's called on screen. Grade first where it's remarkable, because that's the thing
    /// worth carrying home.
    var displayName: String {
        let quality = switch grade {
        case ..<25: "poor "
        case 25..<55: ""
        case 55..<75: "fine "
        case 75..<90: "superb "
        default: "extraordinary "
        }
        return "\(quality)\(kind.rawValue)".capitalisedSentence
    }

    var rarity: Rarity {
        switch grade {
        case ..<40: .common
        case 40..<65: .uncommon
        case 65..<85: .rare
        default: .mythic
        }
    }
}
