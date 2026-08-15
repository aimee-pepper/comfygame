import Foundation

/// Command-line equivalent of the app's DEBUG tuning value. Kept deliberately value-for-value so
/// the web lab calls the same `Worldgen.generate` entry point without importing UIKit.
struct DebugTuningProfile: Codable, Equatable, Sendable {
    enum RawEssenceProfile: String, Codable, CaseIterable, Sendable {
        case legacy, lean, recommended, generous
        var dropRange: ClosedRange<Int> {
            switch self {
            case .legacy: 2...4
            case .lean: 4...6
            case .recommended: 5...7
            case .generous: 6...8
            }
        }
        var amountRange: ClosedRange<Int> { self == .legacy ? 1...2 : 2...3 }
    }

    enum EncounterScalingProfile: String, Codable, CaseIterable, Sendable {
        case current, reserved, recommended, pressing
        var rules: EncounterScalingRules.Profile? {
            switch self {
            case .current: nil
            case .reserved: .reserved
            case .recommended: .recommended
            case .pressing: .pressing
            }
        }
    }

    enum OpeningEncounterEnvelope: String, Codable, CaseIterable, Sendable {
        case natural, gentle, clearApproach
    }

    static let currentEncounterScalingProfileSchemaVersion = 2
    static let defaults = DebugTuningProfile()
    static var legacyFrozenRunDefaults: DebugTuningProfile {
        var value = Self()
        value.encounterScalingProfileSchemaVersion = 1
        value.encounterScalingProfile = .current
        return value
    }

    var rawEssenceFrequencyMultiplier = 1.0
    var rawEssenceYieldMultiplier = 1.0
    var rawEssenceProfile: RawEssenceProfile = .recommended
    var resourceNodeDensityMultiplier = 1.0
    var creatureDensityMultiplier = 1.0
    var additionalPageChance = Tuning.Library.additionalPageChance
    var diaryWritingShare = Tuning.Library.diaryWritingShare
    var diaryPatienceWorlds = Tuning.Library.patienceInWorlds
    var blindDiscoveryWindow = 3
    var travellerClueEvidenceWeight = 1.0
    var travellerAuthoredEvidenceWeight = 2.0
    var travellerArrivalChanceFloor = 0.25
    var travellerArrivalNearMissIncrement = 0.25
    var stabilityDurationMultiplier = 1.0
    var collapseRecoveryFraction = Tuning.World.collapseHaulKeptFraction
    var apexChanceMultiplier = 1.0
    var baseVisionRadius = Tuning.World.baseVisionRadius
    var slowGroundExtraTurns = 1
    var activeFloraFrequencyMultiplier = 1.0
    var floraHazardSeverityMultiplier = 1.0
    var openingEncounterEnvelope: OpeningEncounterEnvelope = .natural
    var encounterScalingProfileSchemaVersion = 2
    var encounterScalingProfile: EncounterScalingProfile = .recommended
    var debugCombatV2BinderAttackEnabled = false
    var debugCombatV2BinderNodeIDs: Set<CombatNodeID> = []
    var debugCombatV2BinderChoices: [CombatNodeID: StableChoiceID] = [:]
    var debugCombatV2CompanionNodeIDs: [Int: Set<CombatNodeID>] = [:]
    var debugCombatV2CompanionChoices: [Int: [CombatNodeID: StableChoiceID]] = [:]
}

/// World generation calls vision only after every terrain/content placement has completed. The web
/// lab intentionally reveals the complete result, so this bridge keeps that final presentation
/// step local without importing the app's combat/travel action surface.
enum WorldRules {
    static func visionRadius(for book: BoundBook, seed: UInt64, base: Int) -> Int { base }
    static func reveal(around point: GridPoint, in map: inout WorldMap, radius: Int) {
        for candidate in map.allPoints { map[candidate].isRevealed = true }
    }
}

/// Persisted encounter receipts mention this value type. The generator does not calculate combat,
/// but the exact Codable shape is required to compile the shared world models.
enum CombatDerivedStatsRules {
    struct AttackBonusComponent: Codable, Equatable, Sendable {
        var nodeID: CombatNodeID
        var amount: Int
    }
    struct PreMatchupAttackBonus: Codable, Equatable, Sendable {
        var components: [AttackBonusComponent]
        var total: Int { components.reduce(0) { $0 + $1.amount } }
    }
}

struct LivingAnalysis: Codable, Equatable, Sendable {
    var creatureTraits: [String]
    var ecologicalRoles: [String]
    var floraTraits: [String]
    var isEmpty: Bool { creatureTraits.isEmpty && ecologicalRoles.isEmpty && floraTraits.isEmpty }
}

enum LivingAnalysisRules {
    static func analyze(_ readings: PressureReadings) -> LivingAnalysis {
        LivingAnalysis(creatureTraits: [], ecologicalRoles: [], floraTraits: [])
    }
}

enum TutorialRules {
    static func semanticRequests(on page: Page) -> [String] {
        PageRules.chains(on: page).map { chain in
            "\(chain.target) ← " + chain.parts.map { part in
                (part.qualifiers.map(\.name) + [part.source]
                    + part.negates.sorted().map { "not \($0)" }).joined(separator: " · ")
            }.joined(separator: " + ")
        }.sorted()
    }
}

/// `GameState`'s tolerant decoder references this migration hook. The generator bridge never
/// decodes a campaign, so it has no roster projections to reconcile.
enum RosterPlacementRules {
    static func reconcileLegacyProjections(in state: inout GameState) -> Bool { false }
}
