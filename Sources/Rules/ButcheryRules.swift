import Foundation

/// Turning a defeated creature into the parts it was made of.
///
/// **No authored drop tables** (creature-system-spec §8). The covering it wore, the weapons it
/// carried and the skeleton that held it up are each read straight off the trait vector, so what a
/// world pays out is a consequence of what it grew rather than a table someone typed.
///
/// **Quantity scales with size. Grade scales with trait extremity.** So a world of monstrous
/// armoured things drops monstrous plates — which is the reason to write such a world.
enum ButcheryRules {

    /// Everything one creature leaves. Ordered so the most characteristic part comes first.
    static func materials(from traits: CreatureTraits, named source: String) -> [MaterialSample] {
        var samples: [MaterialSample] = []
        let covering = traits.covering
        let lustre = traits.finish.lustre

        // The covering: one kind, decided by hardness, length and how much of the animal it reached.
        if covering.coverage > Tuning.Materials.minimumCoverageToYield {
            let kind = coveringMaterial(of: traits)
            let hard = covering.hardness > Tuning.Materials.hardCoveringThreshold
            let density: Double = hard
                ? covering.hardness * 0.6 + traits.boneDensity * 0.4
                : covering.coverage * 0.3
            // Hard things don't bend; long soft things do.
            let flexibility: Double = max(0, 100 - covering.hardness) * (0.5 + covering.length / 200)

            samples.append(MaterialSample(
                kind: kind,
                properties: MaterialProperties(
                    hardness: covering.hardness,
                    density: density,
                    insulation: covering.insulation,
                    flexibility: flexibility,
                    lustre: lustre
                ),
                grade: grade(of: [covering.hardness, covering.length, covering.coverage], lustre: lustre),
                source: source
            ))
        }

        // The weapons, where it had any worth taking.
        if !traits.armament.isUnarmed, traits.armament.total > Tuning.Materials.minimumArmamentToYield {
            let kind: MaterialKind = switch traits.armament.dominant {
            case .pierce: .fang
            case .crush: .tusk
            case .rend: .claw
            }
            samples.append(MaterialSample(
                kind: kind,
                properties: MaterialProperties(
                    hardness: kind == .tusk ? traits.armament.total * 0.4 : traits.armament.total * 0.7,
                    density: kind == .tusk ? traits.armament.total * 0.8 : traits.boneDensity * 0.6,
                    insulation: 0,
                    flexibility: 0,
                    lustre: lustre,
                    reactivity: 0
                ),
                grade: grade(of: [traits.armament.total, traits.boneDensity], lustre: lustre),
                source: source
            ))
        }

        // The skeleton.
        if traits.boneDensity > Tuning.Materials.minimumBoneToYield {
            samples.append(MaterialSample(
                kind: .bone,
                properties: MaterialProperties(
                    hardness: traits.boneDensity * 0.6,
                    density: traits.boneDensity,
                    insulation: 0,
                    flexibility: max(0, 60 - traits.boneDensity * 0.5),
                    lustre: lustre * 0.4,
                    reactivity: 0
                ),
                grade: grade(of: [traits.boneDensity, traits.size], lustre: lustre),
                source: source
            ))
        }

        // Whatever it was doing instead of being ordinary.
        if let emanation = traits.emanation, emanation.strength > Tuning.Materials.minimumEmanationToYield {
            samples.append(MaterialSample(
                kind: .ichor,
                properties: MaterialProperties(
                    hardness: 0,
                    density: 0,
                    insulation: 0,
                    flexibility: 0,
                    lustre: lustre,
                    reactivity: emanation.strength
                ),
                grade: grade(of: [emanation.strength], lustre: lustre),
                source: source
            ))
        }

        return samples
    }

    /// Which material a covering is. Hardness, length and coverage between them say whether the
    /// animal was wearing plate, quills, a pelt, down or plain hide — and layered iridescence is
    /// what makes a hard covering chitin rather than plate.
    static func coveringMaterial(of traits: CreatureTraits) -> MaterialKind {
        let c = traits.covering
        let hard = c.hardness > Tuning.Materials.hardCoveringThreshold
        let long = c.length > Tuning.Materials.longCoveringThreshold
        let dense = c.coverage > Tuning.Materials.denseCoveringThreshold

        if hard {
            if traits.finish.schiller > Tuning.Materials.schillerThreshold { return .chitin }
            return long ? .quill : .plate
        }
        if long { return dense ? .pelt : .down }
        return .hide
    }

    /// How many of each part a body is worth. **Quantity scales with size** — nothing else.
    static func quantity(from traits: CreatureTraits, rng: inout SeededRNG) -> Int {
        let scaled = Tuning.Materials.baseQuantity
            + traits.size / Tuning.Pressure.scaleMaximum * Tuning.Materials.quantityPerSize
        let rounded = max(1, Int(scaled.rounded()))
        return max(1, rounded + rng.int(in: -1...1))
    }

    /// **Grade scales with trait extremity.** An animal that is remarkable in some direction leaves
    /// remarkable parts; a thoroughly average one leaves average ones, however big it is.
    ///
    /// Measured as distance from the middle rather than as height, so a *strikingly* bare or
    /// *strikingly* soft creature is as interesting as a heavily armoured one — extremity is the
    /// claim, not magnitude.
    ///
    /// Averaged across the contributing traits rather than taken from the most extreme of them: a
    /// single unusual number shouldn't carry a grade, or a thick plate that happens to be short
    /// scores for its shortness. Top grades belong to animals that are remarkable *throughout*.
    static func grade(of values: [Double], lustre: Double) -> Double {
        guard !values.isEmpty else { return 0 }
        let extremity = values
            .map { abs($0 - 50) / 50 }
            .reduce(0, +) / Double(values.count)
        let polish = lustre / Tuning.Pressure.scaleMaximum * Tuning.Materials.gradePerLustre
        return min(100, max(0, extremity * Tuning.Materials.gradePerExtremity + polish))
    }
}
