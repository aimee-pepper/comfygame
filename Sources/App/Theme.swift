import SwiftUI
import UIKit

/// Shared semantic colours for the approved pixel UI. Screens select roles; appearance owns the
/// literal colour, and appearance remains a device preference rather than campaign state.
enum PixelUITheme {
    struct RGB: Equatable, Sendable {
        let red: Double
        let green: Double
        let blue: Double

        var relativeLuminance: Double {
            func channel(_ value: Double) -> Double {
                value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
            }
            return 0.2126 * channel(red) + 0.7152 * channel(green) + 0.0722 * channel(blue)
        }
    }

    struct Palette: Equatable, Sendable {
        let screen: RGB
        let headerB: RGB
        let surface: RGB
        let surfaceRaised: RGB
        let surfaceInset: RGB
        let edge: RGB
        let edgeDark: RGB
        let text: RGB
        let muted: RGB
        let neutral: RGB
        let neutralHighlight: RGB
        let primary: RGB
        let primaryHighlight: RGB
        let danger: RGB
        let shadow: RGB
        let wood: RGB
        let woodHighlight: RGB
        let woodDark: RGB
        let shelfInscription: RGB
        let coverOchre: RGB
        let coverTeal: RGB
        let coverMauve: RGB
        let clasp: RGB
    }

    static let light = Palette(
        screen: rgb(0xE6CFA1), headerB: rgb(0xEED9AA), surface: rgb(0xF0DFBC),
        surfaceRaised: rgb(0xEAD6AA), surfaceInset: rgb(0xD8BD88), edge: rgb(0x62472E),
        edgeDark: rgb(0x32261D), text: rgb(0x2D2118), muted: rgb(0x665542),
        neutral: rgb(0xCFAA72), neutralHighlight: rgb(0xEFD39D), primary: rgb(0x2F718F),
        primaryHighlight: rgb(0x63A7BD), danger: rgb(0x943D35), shadow: rgb(0x2F241C),
        wood: rgb(0x7E5434), woodHighlight: rgb(0xB17B48), woodDark: rgb(0x3C281B),
        shelfInscription: rgb(0xEFD39C),
        coverOchre: rgb(0xC99656), coverTeal: rgb(0x73908A), coverMauve: rgb(0x9A6C78),
        clasp: rgb(0xD7B66F))

    static let dark = Palette(
        screen: rgb(0x111B1D), headerB: rgb(0x263B3E), surface: rgb(0x223538),
        surfaceRaised: rgb(0x2A4043), surfaceInset: rgb(0x19292C), edge: rgb(0x607B78),
        edgeDark: rgb(0x0A1214), text: rgb(0xF2EAD9), muted: rgb(0xA9BFBA),
        neutral: rgb(0x31484B), neutralHighlight: rgb(0x526C6E), primary: rgb(0x347DA7),
        primaryHighlight: rgb(0x69AFD4), danger: rgb(0xEF8A82), shadow: rgb(0x05090A),
        wood: rgb(0x4A3529), woodHighlight: rgb(0x765537), woodDark: rgb(0x17100D),
        shelfInscription: rgb(0xEFD39C),
        coverOchre: rgb(0x8C6944), coverTeal: rgb(0x506F6D), coverMauve: rgb(0x72515F),
        clasp: rgb(0xC5A663))

    static func palette(for scheme: ColorScheme) -> Palette { scheme == .dark ? dark : light }

    static func contrastRatio(_ foreground: RGB, _ background: RGB) -> Double {
        let brighter = max(foreground.relativeLuminance, background.relativeLuminance)
        let darker = min(foreground.relativeLuminance, background.relativeLuminance)
        return (brighter + 0.05) / (darker + 0.05)
    }

    static let screen = adaptive(\.screen)
    static let headerB = adaptive(\.headerB)
    static let surface = adaptive(\.surface)
    static let surfaceRaised = adaptive(\.surfaceRaised)
    static let surfaceInset = adaptive(\.surfaceInset)
    static let edge = adaptive(\.edge)
    static let edgeDark = adaptive(\.edgeDark)
    /// High-contrast text specifically for the darkest selection/chrome role.
    static let textOnEdgeDark = Color(uiColor: UIColor { traits in
        let value = traits.userInterfaceStyle == .dark ? dark.text : light.screen
        return UIColor(red: value.red, green: value.green, blue: value.blue, alpha: 1)
    })
    static let text = adaptive(\.text)
    static let muted = adaptive(\.muted)
    static let neutral = adaptive(\.neutral)
    static let neutralHighlight = adaptive(\.neutralHighlight)
    static let primary = adaptive(\.primary)
    static let primaryHighlight = adaptive(\.primaryHighlight)
    static let danger = adaptive(\.danger)
    static let shadow = adaptive(\.shadow)
    static let wood = adaptive(\.wood)
    static let woodHighlight = adaptive(\.woodHighlight)
    static let woodDark = adaptive(\.woodDark)
    static let shelfInscription = adaptive(\.shelfInscription)
    static let coverOchre = adaptive(\.coverOchre)
    static let coverTeal = adaptive(\.coverTeal)
    static let coverMauve = adaptive(\.coverMauve)
    static let clasp = adaptive(\.clasp)

    private static func adaptive(_ role: KeyPath<Palette, RGB>) -> Color {
        Color(uiColor: UIColor { traits in
            let value = (traits.userInterfaceStyle == .dark ? dark : light)[keyPath: role]
            return UIColor(red: value.red, green: value.green, blue: value.blue, alpha: 1)
        })
    }

    private static func rgb(_ hex: UInt32) -> RGB {
        RGB(red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255)
    }
}

/// Keeps the authored face exactly where it is while making that complete face the control.
///
/// The pressed treatment is deliberately immediate: it is direct acknowledgement of a finger
/// going down, not an animation or a gameplay outcome. Disabled controls keep their existing
/// appearance and never borrow the enabled pressed treatment.
private struct FullFacePressFeedbackModifier: ViewModifier {
    let id: String
    @Environment(\.isEnabled) private var isEnabled
    @GestureState private var isPressed = false
#if DEBUG
    @Environment(\.fullFacePressFixtureID) private var fixtureID
#endif

    func body(content: Content) -> some View {
#if DEBUG
        let visiblyPressed = isEnabled && (isPressed || fixtureID == id)
#else
        let visiblyPressed = isEnabled && isPressed
#endif
        content
            .contentShape(Rectangle())
            .overlay {
                if visiblyPressed {
                    Rectangle()
                        .fill(PixelUITheme.edgeDark.opacity(0.18))
                        .overlay(Rectangle().stroke(PixelUITheme.primaryHighlight, lineWidth: 2))
                        .allowsHitTesting(false)
                }
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .updating($isPressed) { _, pressed, _ in pressed = true },
                isEnabled: isEnabled
            )
#if DEBUG
            .background(FullFacePressProbe(id: id, isEnabled: isEnabled,
                                           isPressed: visiblyPressed))
#endif
    }
}

extension View {
    func fullFacePressFeedback(_ id: String) -> some View {
        modifier(FullFacePressFeedbackModifier(id: id))
    }
}

#if DEBUG
struct FullFacePressMeasurement: Equatable {
    var frame: CGRect
    var isEnabled: Bool
    var isPressed: Bool
}

@MainActor enum FullFacePressMeasurements {
    static var values: [String: FullFacePressMeasurement] = [:]
    static func reset() { values = [:] }
}

private struct FullFacePressFixtureIDKey: EnvironmentKey {
    static let defaultValue: String? = nil
}

extension EnvironmentValues {
    var fullFacePressFixtureID: String? {
        get { self[FullFacePressFixtureIDKey.self] }
        set { self[FullFacePressFixtureIDKey.self] = newValue }
    }
}

private struct FullFacePressProbe: UIViewRepresentable {
    let id: String
    let isEnabled: Bool
    let isPressed: Bool

    func makeUIView(context: Context) -> UIView { UIView(frame: .zero) }

    func updateUIView(_ view: UIView, context: Context) {
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            FullFacePressMeasurements.values[id] = .init(
                frame: view.convert(view.bounds, to: window),
                isEnabled: isEnabled,
                isPressed: isPressed
            )
        }
    }
}
#endif

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
        var displayName: String {
            switch self {
            case .legacy: "Older rules · low yield"
            case .lean: "Low yield"
            case .recommended: "Recommended yield"
            case .generous: "High yield"
            }
        }
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
            case .current: "Level only · older rules"
            case .reserved: "Gentler scaling"
            case .recommended: "Recommended scaling"
            case .pressing: "Stronger scaling"
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
    /// DEBUG testing safety. Encounter creation freezes this preference into its own receipt, so
    /// changing the toggle can never rewrite a fight already in progress.
    var debugGodModeEnabled = false
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
        debugGodModeEnabled = try c.decodeIfPresent(Bool.self,
            forKey: .debugGodModeEnabled) ?? false
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

/// A compact, persistent decision surface for ordinary-phone detail and transaction screens.
/// Scrollable evidence stays above it; the action and its current truth remain in reach.
struct PersistentActionBar<Actions: View>: View {
    let message: String
    var messageTint: Color = .secondary
    @ViewBuilder let actions: () -> Actions

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            actions()
            Text(message)
                .font(.caption)
                .foregroundStyle(messageTint)
                .lineLimit(2)
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(.bar)
        .overlay(alignment: .top) { Divider() }
    }
}
