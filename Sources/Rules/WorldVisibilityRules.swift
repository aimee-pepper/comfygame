import Foundation

extension WorldRules {
    enum TileVisibility: Int, Comparable, Sendable {
        case hidden = 0
        case fringe = 1
        case full = 2

        static func < (lhs: TileVisibility, rhs: TileVisibility) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    /// Current sight is derived, never persisted. `Tile.isRevealed` remains the durable exploration
    /// record and is written only from `fullRadius`; the fringe may show vague terrain without
    /// teaching the minimap what is there.
    struct VisibilityProfile: Equatable, Sendable {
        let illumination: Double
        let fullRadius: Int
        let fringeWidth: Int
        let fringeOpacity: Double
        /// Blur represents particulate atmosphere only. Ordinary darkness and sight falloff are
        /// expressed through disclosure and brightness, never by defocusing terrain.
        let atmosphericBlurPoints: Double
        let obscurantDensity: Double
    }

    static func visibilityProfile(illumination rawIllumination: Double,
                                  baseRadius: Int = Tuning.World.baseVisionRadius,
                                  sightBonus: Int = 0,
                                  torchBonus: Int = 0,
                                  obscurantDensity rawDensity: Double = 0) -> VisibilityProfile {
        let illumination = min(100, max(0, rawIllumination + Double(max(0, torchBonus)) * 10))
        let density = min(100, max(0, rawDensity))
        let authoredRadius = max(1, baseRadius + sightBonus + torchBonus)

        let lightRadius: Int
        if illumination <= Tuning.Pressure.trueDarkFloor {
            lightRadius = 1
        } else if illumination < Tuning.Visibility.lowLightUpperBound {
            lightRadius = min(2, authoredRadius)
        } else if illumination < Tuning.Visibility.ordinaryLightFloor {
            let progress = (illumination - Tuning.Visibility.lowLightUpperBound)
                / (Tuning.Visibility.ordinaryLightFloor - Tuning.Visibility.lowLightUpperBound)
            lightRadius = Int((2 + Double(max(0, authoredRadius - 2)) * progress).rounded())
        } else {
            lightRadius = authoredRadius
        }

        let obscurantPenalty = Int(ceil(density / Tuning.Visibility.densityPerRadiusLoss))
        let fullRadius = max(Tuning.World.minimumVisionRadius, lightRadius - obscurantPenalty)
        let fringeWidth = illumination <= Tuning.Pressure.trueDarkFloor
            ? Tuning.Visibility.darkFringeWidth
            : max(1, Tuning.Visibility.defaultFringeWidth - Int(density / 60))
        // Even true darkness retains one vague, terrain-only fringe. Darkness limits disclosure;
        // it must not collapse the Euclidean/LOS visibility field into a hard 3x3 black edge.
        let lightFraction = min(1, max(0.25, (illumination - Tuning.Pressure.trueDarkFloor)
            / (Tuning.Visibility.ordinaryLightFloor - Tuning.Pressure.trueDarkFloor)))
        let obscurantTransmission = max(0, 1 - density / 125)

        return VisibilityProfile(
            illumination: illumination,
            fullRadius: fullRadius,
            fringeWidth: fringeWidth,
            fringeOpacity: Tuning.Visibility.defaultFringeOpacity * lightFraction * obscurantTransmission,
            atmosphericBlurPoints: density / 100 * Tuning.Visibility.maximumAtmosphericBlurPoints,
            obscurantDensity: density
        )
    }

    static func visibilityProfile(in run: WorldRun, party: Int = 0) -> VisibilityProfile {
        let light = BookRules.readings(for: run.book, seed: run.mapSeed)["illumination"]
        let currentLight = run.isNight ? light.floor : light.peak
        let symbolDelta = run.book.allSymbolIDs.reduce(0) {
            $0 + (ContentCatalog.shared.symbol($1)?.visionDelta ?? 0)
        }
        let atmosphere = run.worldVisualReceipt?.request.atmosphere
        let isObscurant = atmosphere?.medium == "smoke" || atmosphere?.medium == "ash"
        let obscurantDensity = isObscurant ? atmosphere?.density ?? 0 : 0
        return visibilityProfile(illumination: currentLight,
                                 baseRadius: run.tuning.baseVisionRadius + symbolDelta,
                                 sightBonus: party,
                                 torchBonus: run.torchVisionBonus,
                                 obscurantDensity: obscurantDensity)
    }

    static func visibility(of candidate: GridPoint, from origin: GridPoint,
                           in map: WorldMap, profile: VisibilityProfile) -> TileVisibility {
        guard map.contains(candidate), map.contains(origin) else { return .hidden }
        let dx = candidate.x - origin.x
        let dy = candidate.y - origin.y
        let distance = sqrt(Double(dx * dx + dy * dy))
        // Full sight is a discrete Euclidean circle, not a square disguised by cell-centre
        // padding. At radius one the four cardinal neighbours are full while the four diagonal
        // corners are fringe; larger radii follow the same closest-grid approximation.
        let fullBoundary = Double(profile.fullRadius)
        let fringeBoundary = Double(profile.fullRadius + profile.fringeWidth) + 0.5
        guard distance <= fringeBoundary,
              hasLineOfSight(from: origin, to: candidate, in: map,
                             standing: map[origin].elevation)
        else { return .hidden }
        if distance <= fullBoundary { return .full }
        return .fringe
    }

    static func visibility(of candidate: GridPoint, in run: WorldRun,
                           party: Int = 0) -> TileVisibility {
        visibility(of: candidate, from: run.playerPosition, in: run.map,
                   profile: visibilityProfile(in: run, party: party))
    }

    /// Exploration is durable terrain memory. Leaving current sight may dim a fully explored tile
    /// to the same terrain-only fringe used by the outer sight ring, but it never makes that ground
    /// opaque and unknown again. Transient entities still use `visibility` directly.
    static func terrainVisibility(current: TileVisibility, wasRevealed: Bool) -> TileVisibility {
        wasRevealed ? max(current, .fringe) : current
    }

    static func isCurrentlyVisible(_ enemy: WorldEnemy, in run: WorldRun,
                                   party: Int = 0) -> Bool {
        isCurrentlyVisible(enemy, in: run, profile: visibilityProfile(in: run, party: party))
    }

    /// One disclosure authority for both rules and presentation. Callers that already resolved the
    /// party-aware profile must pass it through instead of silently recomputing sight at party 0.
    static func isCurrentlyVisible(_ enemy: WorldEnemy, in run: WorldRun,
                                   profile: VisibilityProfile) -> Bool {
        visibility(of: enemy.position, from: run.playerPosition, in: run.map, profile: profile) == .full
            && isVisible(enemy, in: run)
    }
}
