import Foundation

/// Tier-5 lens output. It samples the same allocators worldgen uses, so these are distributions of
/// possible species rather than authored guesses or a leaked exact spawn list.
struct LivingAnalysis: Codable, Equatable, Sendable {
    var creatureTraits: [String]
    var ecologicalRoles: [String]
    var floraTraits: [String]

    var isEmpty: Bool { creatureTraits.isEmpty && ecologicalRoles.isEmpty && floraTraits.isEmpty }
}

enum LivingAnalysisRules {
    private static let sampleCount = 96

    static func analyze(_ readings: PressureReadings) -> LivingAnalysis {
        var creatureRNG = SeededRNG(seed: 0x1A11_515).derived(0xC0FFEE)
        let tendencies = WorldTendencies(readings: readings)
        let creatures = (0..<sampleCount).map { _ in
            LifeRules.sampleSpecies(in: tendencies, rng: &creatureRNG)
        }

        var roleCounts: [String: Int] = [:]
        for traits in creatures {
            let role = CreatureIdentity.match(traits).region?.displayName ?? "unclassified forms"
            roleCounts[role, default: 0] += 1
        }
        let roles = roleCounts
            .map { (role: $0.key, count: $0.value) }
            .sorted { $0.count == $1.count ? $0.role < $1.role : $0.count > $1.count }
            .map { "\($0.role.capitalisedSentence): \(percent($0.count)) likely" }

        var floraRNG = SeededRNG(seed: 0xF10A_515).derived(0xC0FFEE)
        let conditions = GrowingConditions(readings: readings)
        let flora = FloraRules.castSize(for: readings) == 0 ? [] : (0..<sampleCount).map { _ in
            FloraRules.sampleSpecies(in: conditions, rng: &floraRNG)
        }

        var metabolism: [Metabolism: Int] = [:]
        for traits in flora { metabolism[traits.metabolism, default: 0] += 1 }
        var floraLines = ranges(flora.map(\.stature), named: "Stature")
            + ranges(flora.map(\.defence), named: "Defence")
        floraLines += metabolism.map { kind, count in
            "\(kind.displayName.capitalisedSentence): \(percent(count)) likely"
        }.sorted()

        return LivingAnalysis(
            creatureTraits: ranges(creatures.map(\.size), named: "Size")
                + ranges(creatures.map { $0.covering.armourValue }, named: "Armour")
                + ranges(creatures.map { $0.armament.total }, named: "Armament"),
            ecologicalRoles: roles,
            floraTraits: floraLines
        )
    }

    private static func ranges(_ values: [Double], named name: String) -> [String] {
        guard !values.isEmpty else { return [] }
        let ordered = values.sorted()
        let low = ordered[ordered.count / 4]
        let high = ordered[(ordered.count * 3) / 4]
        return ["\(name): usually \(Int(low.rounded()))–\(Int(high.rounded()))"]
    }

    private static func percent(_ count: Int) -> String {
        "\(Int((Double(count) / Double(sampleCount) * 100).rounded()))%"
    }
}
