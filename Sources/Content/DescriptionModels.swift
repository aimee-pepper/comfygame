import Foundation

/// One sentence the world-description panel can say about a world.
///
/// The panel is the only place the pressure model becomes visible to the player, and it's the
/// surface a Library hint page is matched against — the clue says *a vault under cold stone*, the
/// desk says *frozen over, enclosed, hard stone underfoot*, and the player does the join. So the
/// wording here is gameplay, not flavour: it must describe **what the world is like**, never list
/// conditions and never name a sigil, target or value (`contradiction-danger-spec.md` §6).
struct DescriptionClauseDef: Codable, Equatable, Identifiable, Sendable {
    var id: String
    /// Which part of the world this talks about. One clause per group survives, so the panel says
    /// several things about several subjects rather than six things about the weather.
    var group: String
    var text: String
    var polarity: Polarity
    /// Highest priority wins within a group. A clause at priority 1 with no conditions is the
    /// group's fallback, so every group always has something to say.
    var priority: Int
    var conditions: [PressureCondition]

    /// Whether the clause is true of a world.
    func holds(in readings: PressureReadings) -> Bool {
        conditions.allSatisfy { $0.holds(in: readings) }
    }

    /// Drives the red/green underline, so the description doubles as the instability explanation —
    /// you read *why* a world is fragile in the same sentence that tells you what it's like.
    ///
    /// **PLACEHOLDER: authored, and it shouldn't stay that way.** Polarity is a property of what
    /// made the world, and right now it's hand-declared per clause. When instability becomes
    /// derived (decisions-session-6, Q19 option 4) this should fall out of the same profiling
    /// rather than being asserted here.
    enum Polarity: String, Codable, Sendable {
        case stabilising, destabilising, neutral
    }
}

/// What the panel shows: prose about the world, plus any contradictions named outright.
struct WorldDescription: Equatable, Sendable {
    var clauses: [DescriptionClauseDef]
    /// What the world contradicts. **Shown by name only at analysis tier 4** — below that the
    /// player is told something is wrong and left to work out what. Figuring out what your own
    /// writing did to a world is the game, not a usability problem (decisions-session-8).
    var contradictions: [ContradictionDef]
    /// How well the player can currently *read* a world. Attribution grows with it; description
    /// never does, so the panel's deduction job works from the very first book.
    var analysisTier: Int = Tuning.Analysis.startingTier
    /// **The numbers, for the subjects you own an instrument for** (`crafting-spec.md` PART TWO).
    ///
    /// Tier 2 of the page lens is *"target values for subjects you own the field instrument for"*,
    /// and that gate is the best idea in the whole analysis axis: **the lens only shows you what you
    /// have already been out and measured**, so field readings are the currency prediction is bought
    /// with, and the lens grows subject by subject as the kit does rather than in one jump.
    ///
    /// Empty below tier 2, and empty for anything unmeasured however high the lens goes.
    var measured: [Reading] = []
    /// Tier-4 sentence marking derived from the page's actual greed arithmetic, keyed by subject.
    /// Empty on descriptions that have no written page context (and below the tier it is ignored).
    var derivedPolarity: [String: DescriptionClauseDef.Polarity] = [:]

    /// One subject, read off properly.
    struct Reading: Equatable, Identifiable, Sendable {
        var target: PressureTargetID
        var name: String
        var icon: String
        var peak: Double
        var floor: Double
        /// True for Illumination and Thermal, the two that have a day and a night.
        var hasFloor: Bool
        var precision: RealityState.InstrumentPrecision = .fine

        var id: PressureTargetID { target }
        var text: String {
            Self.text(peak: peak, floor: floor, hasFloor: hasFloor, precision: precision)
        }

        static func text(peak: Double, floor: Double, hasFloor: Bool,
                         precision: RealityState.InstrumentPrecision) -> String {
            switch precision {
            case .crude:
                let midpoint = (peak + floor) / 2
                let band: String = switch midpoint {
                case ..<25: "very low"
                case ..<45: "low"
                case ..<60: "middling"
                case ..<80: "high"
                default: "very high"
                }
                let values = hasFloor
                    ? "\(broad(peak)) / \(broad(floor))"
                    : broad(peak)
                return "\(band) · \(values)"
            case .good:
                let values = hasFloor
                    ? "\(narrow(peak)) / \(narrow(floor))"
                    : narrow(peak)
                return values
            case .fine:
                return hasFloor
                    ? "\(Int(peak.rounded())) / \(Int(floor.rounded()))"
                    : "\(Int(peak.rounded()))"
            }
        }

        private static func broad(_ value: Double) -> String {
            let low = max(0, Int((value / 20).rounded(.down) * 20))
            let high = min(100, low + 20)
            return "\(low)–\(high)"
        }

        private static func narrow(_ value: Double) -> String {
            "\(max(0, Int(value.rounded()) - 5))–\(min(100, Int(value.rounded()) + 5))"
        }
    }

    /// Whether the lens is ground finely enough to put numbers on anything at all.
    var showsNumbers: Bool { analysisTier >= Tuning.Analysis.targetsTier }

    var sentence: String { clauses.map(\.text).joined(separator: " ") }
    var isEmpty: Bool { clauses.isEmpty && contradictions.isEmpty }

    /// Whether the panel may say *which* things are destabilising — the red/green underlining.
    var showsAttribution: Bool { analysisTier >= Tuning.Analysis.attributionTier }
    /// Contradictions the player can currently read by name.
    var namedContradictions: [ContradictionDef] { showsAttribution ? contradictions : [] }
    /// Below the attribution tier a contradiction still *registers* — you can tell the world is
    /// wrong, you just can't tell how. Describing without attributing is the panel's whole job.
    var hasUnreadableWrongness: Bool { !showsAttribution && !contradictions.isEmpty }
}
