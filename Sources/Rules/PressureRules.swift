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

    /// Resolve a page into the world it describes, constraints and all.
    ///
    /// The cross-target constraints are applied here rather than left to callers, because a reading
    /// that hasn't been through them is a reading that says a lightless world is teeming.
    static func resolve(_ sigils: [Sigil]) -> PressureReadings {
        WorldConstraints.apply(to: resolveUnconstrained(sigils))
    }

    /// Resolve a page **and roll for everything it didn't mention**.
    ///
    /// A target nobody wrote about isn't set to some sensible default — it's *rolled*, from the
    /// whole pool of sources, at a random intensity. That's what makes an under-specified book a
    /// surprise rather than a blank: you find out what the world decided, and it may well be
    /// something you couldn't have written yourself.
    ///
    /// Deterministic in the seed, so the pre-bind preview's ranges stay honest and the same book
    /// always produces the same world.
    static func resolve(_ sigils: [Sigil], fillingUnwrittenWith seed: UInt64) -> PressureReadings {
        WorldConstraints.apply(to: resolveUnconstrained(sigils + rollUnwritten(after: sigils, seed: seed)))
    }

    /// One rolled sigil for each target the page left silent.
    static func rollUnwritten(after sigils: [Sigil], seed: UInt64) -> [Sigil] {
        var rng = SeededRNG(seed: seed).derived(0x51611)
        let written = Set(sigils.flatMap { sigil -> [PressureTargetID] in
            ContentCatalog.shared.pressureSource(sigil.source)?.targets ?? []
        })

        var rolled: [Sigil] = []
        for target in ContentCatalog.shared.pressureTargetsInOrder where !written.contains(target.id) {
            // Anything that can push on this target, whether or not the player could write it.
            let pool = ContentCatalog.shared.pressureSources
                .filter { $0.contribution(to: target.id) != nil }
                .sorted { $0.id.rawValue < $1.id.rawValue }
            guard let source = rng.pick(pool) else { continue }
            let intensity = rng.pick(Intensity.allCases.filter { $0 != .absent }) ?? .moderate
            rolled.append(Sigil(id: InstanceID(rawValue: rng.next()),
                                source: source.id, target: target.id, intensity: intensity))
        }
        return rolled
    }

    /// Raw resolution, before the targets are allowed to argue with each other. Exposed for tests
    /// that need to see a single target's arithmetic in isolation.
    /// The aspect Scale and Count push on, for subjects that have one.
    static let extentAspect = "dispersion"

    /// **What Scale does to a subject.**
    ///
    /// Where a subject has an extent separate from its amount — water, rock, life — Scale spreads
    /// it and leaves the magnitude alone. Where it doesn't, extent *is* magnitude: a vaster sun is
    /// a brighter one, and pretending otherwise is a rule nobody can learn by playing
    /// (`writing-desk-fixes.md` §3).
    static func scaleMultiplier(_ sigil: Sigil, target: PressureTargetDef) -> Double {
        guard sigil.scale > 0 else { return 1 }
        let rungsAboveMiddle = Double(sigil.scale) - Tuning.Pressure.middleRung
        // Relief keeps its old job — Scale on the land is world size, read elsewhere.
        guard !target.aspects.contains(where: { $0.id == Self.extentAspect }), target.id != "relief"
        else { return 1 }
        return max(0.2, 1 + rungsAboveMiddle * Tuning.Pressure.magnitudePerScaleRung)
    }

    /// **What Count does.** Sublinear, deliberately: two suns are brighter than one and not twice
    /// as bright, or Count is simply a bigger Intensity.
    static func countMultiplier(_ sigil: Sigil) -> Double {
        guard sigil.count > 1 else { return 1 }
        return pow(Double(sigil.count), Tuning.Pressure.countExponent)
    }

    /// How far toward *scattered* this sigil pushes a subject's extent. Scale spreads, and so does
    /// Count — many small springs are dispersed in a way one great lake is not.
    static func extentPush(_ sigil: Sigil) -> Double {
        var push = 0.0
        if sigil.scale > 0 { push += Double(sigil.scale) - Tuning.Pressure.middleRung }
        if sigil.count > 1 { push += Double(sigil.count) - 1 }
        return push
    }

    static func resolveUnconstrained(_ sigils: [Sigil]) -> PressureReadings {
        var readings: [PressureTargetID: PressureReading] = [:]

        for target in ContentCatalog.shared.pressureTargets {
            var positivePeak: [Double] = [], negativePeak: [Double] = []
            var positiveFloor: [Double] = [], negativeFloor: [Double] = []
            var deniedForce = 0.0
            var producedPeak = 0.0
            var tags: Set<String> = []
            var aspectDeltas: [String: Double] = [:]
            var formWeights: [String: Double] = [:]

            for sigil in sigils {
                guard let source = ContentCatalog.shared.pressureSource(sigil.source) else { continue }
                guard let contribution = source.contribution(to: target.id) else { continue }

                // **Intensity, Scale and Count all reach the resolver now.** Two of the three used
                // to be written, displayed and consumed by nothing, which made *vast sun* a plain
                // sun and *countless suns* one sun (Aimee, 6 Aug).
                let amplitude = sigil.intensity.multiplier
                    * scaleMultiplier(sigil, target: target)
                    * countMultiplier(sigil)
                let peak = contribution.peak * amplitude
                let floor = (target.dualValued ? contribution.floor : 0) * amplitude


                if sigil.negatedTargets.contains(target.id) {
                    // Denial *removes* the contribution rather than inverting it — a sun that does
                    // not warm stops warming; it doesn't start chilling, and it certainly doesn't
                    // cancel out somebody else's magma. But the force spent arguing with the
                    // source's own nature stays on the books, which is what makes the
                    // contradiction visible when the net comes to nothing.
                    deniedForce += abs(peak) + abs(floor)
                    continue
                }

                // Producers and decomposers are what a food web *stands on*. Kept separately so
                // the constraints pass can tell "alive because things grow here" from "alive
                // because I wrote a herd and nothing for it to eat".
                if peak > 0, contribution.character == "producing" || contribution.character == "decomposing" {
                    producedPeak += peak
                }
                if peak >= 0 { positivePeak.append(peak) } else { negativePeak.append(-peak) }
                if floor >= 0 { positiveFloor.append(floor) } else { negativeFloor.append(-floor) }
                tags.formUnion(contribution.tags)

                // Aspects are directional pushes rather than magnitudes — dispersion is pulled
                // toward concentrated or pervasive — so they sum plainly rather than diminishing.
                for (aspect, delta) in contribution.aspects {
                    aspectDeltas[aspect, default: 0] += delta * amplitude
                }
                // **Scale spreads a subject that has an extent; Count scatters anything.** *A vast
                // sea* is a different world from *a great sea* at the same volume, and *many small
                // springs* is different again — which is the distinction session 14 was protecting
                // when it refused to collapse the three ladders into one word.
                if target.aspects.contains(where: { $0.id == Self.extentAspect }) {
                    aspectDeltas[Self.extentAspect, default: 0] +=
                        extentPush(sigil) * Tuning.Pressure.extentPerRung
                }
                // Form is a share of what this source brought, not a value of its own.
                if let form = contribution.form, peak > 0 {
                    formWeights[form, default: 0] += peak
                }
            }

            let peakUp = diminished(positivePeak), peakDown = diminished(negativePeak)
            let floorUp = diminished(positiveFloor), floorDown = diminished(negativeFloor)

            // **What was asked for, before the world was allowed to refuse it.**
            //
            // Greed bills this rather than the clamped peak. Now that writing starts at the ordinary
            // value rather than at zero, an extravagant ask runs into the ceiling routinely — gold
            // written *greatly* on a substrate that already sits at 30 lands past 100 — and billing
            // the clamped figure would price a world riddled with veins the same as a merely rich
            // one. You are charged for the demand; the clamp is the world's answer, not your ask.
            let demand = target.baseline + peakUp - peakDown

            var peak = clamp(demand)
            // The floor has an ordinary of its own: an unremarkable world is lit by day and dark by
            // night, and inheriting the daytime ordinary made every night as bright as noon.
            let floorOrdinary = target.baselineFloor ?? target.baseline
            var floor = target.dualValued ? clamp(floorOrdinary + floorUp - floorDown) : peak

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
                demand: demand,
                floor: floor,
                opposedMagnitude: opposed,
                aspects: aspects,
                forms: forms,
                tags: tags.union(derivedTags(target: target, peak: peak, floor: floor, tags: tags)),
                producedPeak: producedPeak
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
    /// **What the page asked for, before clamping.** Equal to `peak` inside 0–100, and outside it
    /// this is the only record of how far past the end of the scale the demand went. Greed reads it;
    /// everything describing the world reads `peak`, because the world is what it is.
    var demand: Double = 0
    /// The low value. Equal to `peak` on single-valued targets.
    var floor: Double
    /// Force applied in conflicting directions and cancelled. Gross, never net.
    var opposedMagnitude: Double
    /// Named scalars beyond the magnitude — dispersion, salinity, motion, clarity.
    var aspects: [String: Double]
    /// Proportions across the target's form buckets, summing to 1 (or empty).
    var forms: [String: Double]
    var tags: Set<String>
    /// **How much of this came from sources that make rather than take.**
    ///
    /// Only vitality reads it, and only to cap trophic depth (audit #9's refinement to Q38): a page
    /// of nothing but herds and swarms shouldn't describe a rich food web with nothing at the
    /// bottom of it. Producers set the ceiling; consumers fill it.
    var producedPeak: Double = 0

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
        readings[target] ?? PressureReading(target: target, peak: 0, demand: 0, floor: 0,
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
