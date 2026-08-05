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

    private let defaults: UserDefaults

    private enum Keys {
        static let theme = "settings.theme"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let stored = defaults.string(forKey: Keys.theme) ?? ""
        self.theme = AppTheme(rawValue: stored) ?? .system
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
