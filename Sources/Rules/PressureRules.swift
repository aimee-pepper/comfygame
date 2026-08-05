import Foundation

/// Resolving a page of sigils into the pressures a world is under.
///
/// This is the **language half** of the writing system, and it is deliberately independent of the
/// page: resolution consumes an *unordered set* of sigils and never asks where any of them sit.
/// Position is a packing constraint and nothing else (locked in decisions-log session 5), which is
/// why this can be finished, tested and played long before the grid or a single drawn rune exists.
///
/// Three things come out, and they're kept apart on purpose — a world can be pleasant to walk
/// through and still produce very strange creatures:
///
///  - **net values** on a shared 0–100 scale, which drive player-facing effects
///  - **opposed magnitude**, tracked *gross*, which drives contradiction instability
///  - **modality tags**, the qualitative facts that aren't scalar
enum PressureRules {

    // MARK: Resolution

    static func resolve(_ sigils: [Sigil]) -> PressureReadings {
        var readings: [PressureTargetID: PressureReading] = [:]

        for target in ContentCatalog.shared.pressureTargets {
            var positivePeak: [Double] = [], negativePeak: [Double] = []
            var positiveFloor: [Double] = [], negativeFloor: [Double] = []
            var deniedForce = 0.0
            var tags: Set<String> = []
            var aspectDeltas: [String: Double] = [:]
            var formWeights: [String: Double] = [:]

            for sigil in sigils {
                guard let source = ContentCatalog.shared.pressureSource(sigil.source) else { continue }
                guard let contribution = source.contribution(to: target.id) else { continue }

                let scale = sigil.intensity.multiplier
                let peak = contribution.peak * scale
                let floor = (target.dualValued ? contribution.floor : 0) * scale

                if sigil.negatedTargets.contains(target.id) {
                    // Denial *removes* the contribution rather than inverting it — a sun that does
                    // not warm stops warming; it doesn't start chilling, and it certainly doesn't
                    // cancel out somebody else's magma. But the force spent arguing with the
                    // source's own nature stays on the books, which is what makes the
                    // contradiction visible when the net comes to nothing.
                    deniedForce += abs(peak) + abs(floor)
                    continue
                }

                if peak >= 0 { positivePeak.append(peak) } else { negativePeak.append(-peak) }
                if floor >= 0 { positiveFloor.append(floor) } else { negativeFloor.append(-floor) }
                tags.formUnion(contribution.tags)

                // Aspects are directional pushes rather than magnitudes — dispersion is pulled
                // toward concentrated or pervasive — so they sum plainly rather than diminishing.
                for (aspect, delta) in contribution.aspects {
                    aspectDeltas[aspect, default: 0] += delta * scale
                }
                // Form is a share of what this source brought, not a value of its own.
                if let form = contribution.form, peak > 0 {
                    formWeights[form, default: 0] += peak
                }
            }

            let peakUp = diminished(positivePeak), peakDown = diminished(negativePeak)
            let floorUp = diminished(positiveFloor), floorDown = diminished(negativeFloor)

            var peak = clamp(target.baseline + peakUp - peakDown)
            var floor = target.dualValued ? clamp(target.baseline + floorUp - floorDown) : peak

            // Floor may never exceed peak. When retention or occlusion drives them past each other
            // they **converge on the midpoint** — a uniformly murky world, or one with no
            // meaningful difference between its days and its nights. Snapping one to the other
            // would invent heat (or light) that nothing in the page asked for.
            if floor > peak {
                let midpoint = (peak + floor) / 2
                peak = midpoint
                floor = midpoint
            }
            if !target.dualValued { floor = peak }

            // Contradiction has two shapes, and both have to count. Denying a source's own
            // nature is one (a sun that does not warm). Writing a world both blazing and smothered
            // is the other. Read the *net* instead of the gross and neither one is visible: the
            // first looks like silence, the second like a world nobody wrote.
            let opposed = deniedForce
                + min(peakUp, peakDown)
                + (target.dualValued ? min(floorUp, floorDown) : 0)

            var aspects: [String: Double] = [:]
            for aspect in target.aspects {
                aspects[aspect.id] = clamp(aspect.baseline + (aspectDeltas[aspect.id] ?? 0))
            }

            let formTotal = formWeights.values.reduce(0, +)
            let forms = formTotal > 0 ? formWeights.mapValues { $0 / formTotal } : [:]

            readings[target.id] = PressureReading(
                target: target.id,
                peak: peak,
                floor: floor,
                opposedMagnitude: opposed,
                aspects: aspects,
                forms: forms,
                tags: tags.union(derivedTags(target: target, peak: peak, floor: floor, tags: tags))
            )
        }
        return PressureReadings(readings: readings)
    }

    /// Stacking sums with diminishing returns: three suns are brighter than one but not three times
    /// brighter. Without this the correct strategy is always "write the same rune as many times as
    /// it fits", which is a spreadsheet rather than a decision.
    static func diminished(_ contributions: [Double]) -> Double {
        var total = 0.0
        for (index, value) in contributions.sorted(by: >).enumerated() {
            total += value * pow(Tuning.Pressure.stackingFalloff, Double(index))
        }
        return total
    }

    private static func clamp(_ value: Double) -> Double {
        min(Tuning.Pressure.scaleMaximum, max(0, value))
    }

    /// Tags that fall out of the resolved numbers rather than being authored on a source.
    private static func derivedTags(target: PressureTargetDef,
                                    peak: Double,
                                    floor: Double,
                                    tags: Set<String>) -> Set<String> {
        guard target.dualValued else { return [] }
        var derived: Set<String> = []
        let range = peak - floor
        if range >= Tuning.Pressure.wideRangeThreshold { derived.insert("wide-range") }
        if range <= Tuning.Pressure.flatRangeThreshold { derived.insert("constant") }
        // Lit, but not by anything in the sky.
        if target.id == "illumination", floor > 0, !tags.contains("celestial") { derived.insert("sourceless") }
        return derived
    }
}

/// One target's resolved state.
struct PressureReading: Equatable, Sendable {
    var target: PressureTargetID
    /// The high value — the brightest, hottest, wettest it gets. Single-valued targets use this.
    var peak: Double
    /// The low value. Equal to `peak` on single-valued targets.
    var floor: Double
    /// Force applied in conflicting directions and cancelled. Gross, never net.
    var opposedMagnitude: Double
    /// Named scalars beyond the magnitude — dispersion, salinity, motion, clarity.
    var aspects: [String: Double]
    /// Proportions across the target's form buckets, summing to 1 (or empty).
    var forms: [String: Double]
    var tags: Set<String>

    /// Its own pressure: dim and dark are different, and so are "always the same" and "swings".
    var range: Double { peak - floor }

    func has(_ tag: String) -> Bool { tags.contains(tag) }
    func aspect(_ id: String) -> Double { aspects[id] ?? 0 }
    func share(of form: String) -> Double { forms[form] ?? 0 }

    /// **Frozen water is water the world can't use.** A glacier world reads as soaking wet and is
    /// biologically a desert — true of real polar deserts, and the number every downstream pressure
    /// should actually be reading.
    var availableMagnitude: Double { peak * (1 - share(of: "frozen")) }
}

struct PressureReadings: Equatable, Sendable {
    var readings: [PressureTargetID: PressureReading]

    subscript(target: PressureTargetID) -> PressureReading {
        readings[target] ?? PressureReading(target: target, peak: 0, floor: 0,
                                            opposedMagnitude: 0, aspects: [:], forms: [:], tags: [])
    }

    var inOrder: [PressureReading] {
        ContentCatalog.shared.pressureTargets
            .sorted { $0.order < $1.order }
            .map { self[$0.id] }
    }

    /// Total force written in conflicting directions across every target.
    ///
    /// The second origin of instability, alongside greed: a world can be perfectly ordinary to
    /// stand in and violently unstable because of what you *asked* for and then took back.
    var totalOpposed: Double { readings.values.reduce(0) { $0 + $1.opposedMagnitude } }
}
