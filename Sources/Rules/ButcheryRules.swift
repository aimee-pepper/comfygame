import Foundation

/// Turning a defeated creature into the parts it was made of.
///
/// **No authored drop tables** (creature-system-spec §8). The covering it wore, the weapons it
/// carried and the skeleton that held it up are each read straight off the trait vector, so what a
/// world pays out is a consequence of what it grew rather than a table someone typed.
///
/// **Quantity scales with size. Quality scales with trait extremity.** So a world of monstrous
/// armoured things drops monstrous plates — which is the reason to write such a world.
enum ButcheryRules {

    /// Everything one creature leaves. Ordered so the most characteristic part comes first.
    static func materials(from traits: CreatureTraits, named source: String,
                          qualifier: String? = nil) -> [CraftMaterialUnitV1] {
        var samples: [CraftMaterialUnitV1] = []
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

            samples.append(unit(
                kind: kind,
                properties: MaterialProperties(
                    hardness: covering.hardness,
                    density: density,
                    insulation: covering.insulation,
                    flexibility: flexibility,
                    lustre: lustre
                ),
                quality: quality(of: [covering.hardness, covering.length, covering.coverage], lustre: lustre),
                source: source,
                qualifier: qualifier
            ))
        }

        // The weapons, where it had any worth taking.
        if !traits.armament.isUnarmed, traits.armament.total > Tuning.Materials.minimumArmamentToYield {
            let kind: MaterialFamilyID = switch traits.armament.dominant {
            case .pierce: .fang
            case .crush: .tusk
            case .rend: .claw
            }
            samples.append(unit(
                kind: kind,
                properties: MaterialProperties(
                    hardness: kind == .tusk ? traits.armament.total * 0.4 : traits.armament.total * 0.7,
                    density: kind == .tusk ? traits.armament.total * 0.8 : traits.boneDensity * 0.6,
                    insulation: 0,
                    flexibility: 0,
                    lustre: lustre,
                    reactivity: 0
                ),
                quality: quality(of: [traits.armament.total, traits.boneDensity], lustre: lustre),
                source: source,
                qualifier: qualifier
            ))
        }

        // The skeleton.
        if traits.boneDensity > Tuning.Materials.minimumBoneToYield {
            samples.append(unit(
                kind: .bone,
                properties: MaterialProperties(
                    hardness: traits.boneDensity * 0.6,
                    density: traits.boneDensity,
                    insulation: 0,
                    flexibility: max(0, 60 - traits.boneDensity * 0.5),
                    lustre: lustre * 0.4,
                    reactivity: 0
                ),
                quality: quality(of: [traits.boneDensity, traits.size], lustre: lustre),
                source: source,
                qualifier: qualifier
            ))
        }

        // Whatever it was doing instead of being ordinary.
        if let emanation = traits.emanation, emanation.strength > Tuning.Materials.minimumEmanationToYield {
            samples.append(unit(
                kind: .ichor,
                properties: MaterialProperties(
                    hardness: 0,
                    density: 0,
                    insulation: 0,
                    flexibility: 0,
                    lustre: lustre,
                    reactivity: emanation.strength
                ),
                quality: quality(of: [emanation.strength], lustre: lustre),
                source: source,
                qualifier: qualifier
            ))
        }

        return samples
    }

    /// Which material a covering is. Hardness, length and coverage between them say whether the
    /// animal was wearing plate, quills, a pelt, down or plain hide — and layered iridescence is
    /// what makes a hard covering chitin rather than plate.
    static func coveringMaterial(of traits: CreatureTraits) -> MaterialFamilyID {
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

    /// **Quality scales with trait extremity.** An animal that is remarkable in some direction leaves
    /// remarkable parts; a thoroughly average one leaves average ones, however big it is.
    ///
    /// Measured as distance from the middle rather than as height, so a *strikingly* bare or
    /// *strikingly* soft creature is as interesting as a heavily armoured one — extremity is the
    /// claim, not magnitude.
    ///
    /// Averaged across the contributing traits rather than taken from the most extreme of them: a
    /// single unusual number shouldn't carry the result. Top bands belong to animals that are
    /// remarkable throughout.
    static func quality(of values: [Double], lustre: Double) -> Double {
        guard !values.isEmpty else { return 0 }
        let extremity = values
            .map { abs($0 - 50) / 50 }
            .reduce(0, +) / Double(values.count)
        let polish = lustre / Tuning.Pressure.scaleMaximum * Tuning.Materials.gradePerLustre
        return min(100, max(0, extremity * Tuning.Materials.gradePerExtremity + polish))
    }

    private static func unit(kind: MaterialFamilyID, properties: MaterialProperties,
                             quality: Double, source: String, qualifier: String?) -> CraftMaterialUnitV1 {
        CraftMaterialUnitV1(schemaVersion: 1,
            stableUnitID: CraftMaterialUnitID(rawValue: "butchery-prototype-\(kind.rawValue)"),
            domain: .creature, familyID: kind,
            qualityBand: (try? .init(legacyGrade: quality)) ?? .rough,
            properties: properties,
            sourceReceipt: .legacy(originalKind: kind, frozenSource: source,
                                   qualifier: qualifier, migrationLocation: "butchery",
                                   originalIdentity: nil))
    }
}
