import SwiftUI
import UIKit

/// Appearance preference.
///
/// This game is meant to be played in bed, so the dark theme isn't a nicety — it's a feature of the
/// thing. `system` follows the phone (including its sunset schedule); the other two override it,
/// because "my phone is in light mode but I'm in bed" is the exact case that matters here.
enum AppTheme: String, CaseIterable, Identifiable, Sendable {
    case system, light, dark

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    var icon: String {
        switch self {
        case .system: "iphone"
        case .light: "sun.max"
        case .dark: "moon.stars"
        }
    }

    /// `nil` hands the decision back to the system.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

/// App preferences, deliberately kept **out of the save file**.
///
/// Appearance isn't game state: it isn't part of the fiction, no game rule reads it, and wiping a
/// save shouldn't reset how the app looks. So it lives in `UserDefaults` rather than in one of the
/// three persistence layers — which also keeps `GameState` honest as purely the game.
@MainActor
final class AppSettings: ObservableObject {
    @Published var theme: AppTheme {
        didSet { defaults.set(theme.rawValue, forKey: Keys.theme) }
    }
    @Published var debugTuning: DebugTuningProfile {
        didSet {
            guard let data = try? JSONEncoder().encode(debugTuning) else { return }
            defaults.set(data, forKey: Keys.debugTuning)
        }
    }

    private let defaults: UserDefaults

    private enum Keys {
        static let theme = "settings.theme"
        static let debugTuning = DebugTuningProfile.storageKey
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let stored = defaults.string(forKey: Keys.theme) ?? ""
        self.theme = AppTheme(rawValue: stored) ?? .system
        self.debugTuning = DebugTuningProfile.load(from: defaults)
    }
}

/// Balancing values are deliberately separate from `GameState`: they describe the development
/// environment that creates the next run, not anything the player earned or discovered.
struct DebugTuningProfile: Codable, Equatable, Sendable {
    enum RawEssenceProfile: String, Codable, CaseIterable, Sendable {
        case legacy, lean, recommended, generous
        var displayName: String { rawValue.capitalized }
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
        var displayName: String {
            switch self {
            case .current: "Legacy · level only"
            case .reserved: "A · Reserved"
            case .recommended: "B · Recommended start"
            case .pressing: "C · Pressing"
            }
        }
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
        case natural
        case gentle
        case clearApproach

        var displayName: String {
            switch self {
            case .natural: "Natural"
            case .gentle: "Gentle"
            case .clearApproach: "Clear approach"
            }
        }
    }

    static let storageKey = "debug.tuning.profile.v1"
    static let currentEncounterScalingProfileSchemaVersion = 2
    static let defaults = DebugTuningProfile()
    static var legacyFrozenRunDefaults: DebugTuningProfile {
        var value = DebugTuningProfile()
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
    /// How many authored-order positions beyond the recruited frontier may appear blindly.
    /// Applied only when the next world is generated; the one-traveller cap is structural.
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
    /// Version 2 promotes Recommended for newly bound runs. WorldRun stores its own frozen tuning,
    /// so this preference migration never rewrites an existing expedition or encounter.
    var encounterScalingProfileSchemaVersion = Self.currentEncounterScalingProfileSchemaVersion
    var encounterScalingProfile: EncounterScalingProfile = .recommended
    var debugCombatV2BinderAttackEnabled = false
    /// Exact stable node IDs for the Binder-only combat-v2 comparison harness. These are frozen
    /// into an encounter; changing this preference never mutates a fight already in progress.
    var debugCombatV2BinderNodeIDs: Set<CombatNodeID> = []
    /// Typed choices are independent of ownership so turning a DEBUG node off can preserve the
    /// last selection without making it active. Encounter entry validates both together.
    var debugCombatV2BinderChoices: [CombatNodeID: StableChoiceID] = [:]
    /// Explicit companion ownership for the DEBUG combat-v2 initiative comparison. Keys are the
    /// current roster indices used by Combatant; release ownership does not read this harness.
    var debugCombatV2CompanionNodeIDs: [Int: Set<CombatNodeID>] = [:]
    var debugCombatV2CompanionChoices: [Int: [CombatNodeID: StableChoiceID]] = [:]

    var isDefault: Bool { self == .defaults }

    static var active: DebugTuningProfile { load(from: .standard) }

    static func load(from defaults: UserDefaults) -> DebugTuningProfile {
        guard let data = defaults.data(forKey: storageKey),
              var profile = try? JSONDecoder().decode(DebugTuningProfile.self, from: data)
        else { return .defaults }
        // Preference-only migration. Codable is also used inside frozen WorldRun snapshots, where
        // changing Legacy under an active expedition would be a correctness bug.
        if profile.encounterScalingProfileSchemaVersion
            < currentEncounterScalingProfileSchemaVersion {
            if profile.encounterScalingProfile == .current {
                profile.encounterScalingProfile = .recommended
            }
            profile.encounterScalingProfileSchemaVersion = currentEncounterScalingProfileSchemaVersion
            if let migrated = try? JSONEncoder().encode(profile) {
                defaults.set(migrated, forKey: storageKey)
            }
        }
        return profile
    }

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        rawEssenceFrequencyMultiplier = try c.decodeIfPresent(Double.self,
                                                               forKey: .rawEssenceFrequencyMultiplier) ?? 1
        rawEssenceYieldMultiplier = try c.decodeIfPresent(Double.self,
                                                           forKey: .rawEssenceYieldMultiplier) ?? 1
        rawEssenceProfile = try c.decodeIfPresent(RawEssenceProfile.self,
                                                   forKey: .rawEssenceProfile) ?? .recommended
        resourceNodeDensityMultiplier = try c.decodeIfPresent(Double.self,
                                                               forKey: .resourceNodeDensityMultiplier) ?? 1
        creatureDensityMultiplier = try c.decodeIfPresent(Double.self,
                                                           forKey: .creatureDensityMultiplier) ?? 1
        additionalPageChance = try c.decodeIfPresent(Double.self, forKey: .additionalPageChance)
            ?? Tuning.Library.additionalPageChance
        diaryWritingShare = try c.decodeIfPresent(Double.self, forKey: .diaryWritingShare)
            ?? Tuning.Library.diaryWritingShare
        diaryPatienceWorlds = try c.decodeIfPresent(Int.self, forKey: .diaryPatienceWorlds)
            ?? Tuning.Library.patienceInWorlds
        blindDiscoveryWindow = min(6, max(1, try c.decodeIfPresent(Int.self,
            forKey: .blindDiscoveryWindow) ?? 3))
        travellerClueEvidenceWeight = max(0, try c.decodeIfPresent(Double.self,
            forKey: .travellerClueEvidenceWeight) ?? 1)
        travellerAuthoredEvidenceWeight = max(0, try c.decodeIfPresent(Double.self,
            forKey: .travellerAuthoredEvidenceWeight) ?? 2)
        travellerArrivalChanceFloor = min(1, max(0, try c.decodeIfPresent(Double.self,
            forKey: .travellerArrivalChanceFloor) ?? 0.25))
        travellerArrivalNearMissIncrement = min(1, max(0, try c.decodeIfPresent(Double.self,
            forKey: .travellerArrivalNearMissIncrement) ?? 0.25))
        stabilityDurationMultiplier = try c.decodeIfPresent(Double.self,
                                                              forKey: .stabilityDurationMultiplier) ?? 1
        collapseRecoveryFraction = try c.decodeIfPresent(Double.self,
                                                           forKey: .collapseRecoveryFraction)
            ?? Tuning.World.collapseHaulKeptFraction
        apexChanceMultiplier = try c.decodeIfPresent(Double.self,
                                                       forKey: .apexChanceMultiplier) ?? 1
        baseVisionRadius = try c.decodeIfPresent(Int.self, forKey: .baseVisionRadius)
            ?? Tuning.World.baseVisionRadius
        slowGroundExtraTurns = try c.decodeIfPresent(Int.self, forKey: .slowGroundExtraTurns) ?? 1
        activeFloraFrequencyMultiplier = try c.decodeIfPresent(Double.self,
            forKey: .activeFloraFrequencyMultiplier) ?? 1
        floraHazardSeverityMultiplier = try c.decodeIfPresent(Double.self,
            forKey: .floraHazardSeverityMultiplier) ?? 1
        openingEncounterEnvelope = try c.decodeIfPresent(OpeningEncounterEnvelope.self,
            forKey: .openingEncounterEnvelope) ?? .natural
        let savedProfileVersion = try c.decodeIfPresent(Int.self,
            forKey: .encounterScalingProfileSchemaVersion) ?? 1
        encounterScalingProfileSchemaVersion = savedProfileVersion
        encounterScalingProfile = try c.decodeIfPresent(EncounterScalingProfile.self,
            forKey: .encounterScalingProfile) ?? .current
        debugCombatV2BinderNodeIDs = try c.decodeIfPresent(Set<CombatNodeID>.self,
            forKey: .debugCombatV2BinderNodeIDs) ?? []
        debugCombatV2BinderChoices = try c.decodeIfPresent([CombatNodeID: StableChoiceID].self,
            forKey: .debugCombatV2BinderChoices) ?? [:]
        debugCombatV2BinderAttackEnabled = try c.decodeIfPresent(Bool.self,
            forKey: .debugCombatV2BinderAttackEnabled) ?? false
        debugCombatV2CompanionNodeIDs = try c.decodeIfPresent([Int: Set<CombatNodeID>].self,
            forKey: .debugCombatV2CompanionNodeIDs) ?? [:]
        debugCombatV2CompanionChoices = try c.decodeIfPresent(
            [Int: [CombatNodeID: StableChoiceID]].self,
            forKey: .debugCombatV2CompanionChoices) ?? [:]
    }
}

/// Colours that can't be left to the system semantics, because their *meaning* has to survive
/// inversion.
///
/// The map is the case in point. Using `.primary.opacity(…)` for fog reads correctly in light mode
/// and backwards in dark: fog ends up brighter than the ground you've walked. So the map states are
/// pinned per scheme, and the rule they follow is the same in both — **the more you know about a
/// tile, the more present it looks.** Explored ground sits forward, fog recedes, and a crumbled tile
/// is a hole in the page.
enum Palette {

    /// Ground you have seen.
    static let mapFloor = dynamic(light: .white, dark: rgb(0x2A, 0x2A, 0x2E))

    /// Fog of war — quieter than the floor in both schemes.
    static let mapFog = dynamic(light: rgb(0xD6, 0xD6, 0xDA), dark: rgb(0x12, 0x12, 0x15))

    /// Crumbled away. Nothing to stand on, and it should read as nothing.
    static let mapVoid = dynamic(light: rgb(0x8E, 0x8E, 0x93), dark: .black)

    /// Hairline between tiles. Low contrast on purpose — it's a grid, not a cage.
    static let mapGrid = dynamic(light: rgb(0xFF, 0xFF, 0xFF, alpha: 0.75),
                                 dark: rgb(0x48, 0x48, 0x4A, alpha: 0.55))

    // MARK: Construction

    private static func dynamic(light: UIColor, dark: UIColor) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        })
    }

    private static func rgb(_ red: Int, _ green: Int, _ blue: Int, alpha: Double = 1) -> UIColor {
        UIColor(red: Double(red) / 255, green: Double(green) / 255, blue: Double(blue) / 255, alpha: alpha)
    }
}
