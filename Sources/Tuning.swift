import Foundation

/// Every gameplay number lives here so Aimee can rebalance without hunting through logic.
///
/// Rules for this file:
///  - Nothing here is a design decision. Everything is `// PLACEHOLDER` until playtested.
///  - No number that affects gameplay may be written inline anywhere else in the codebase.
///  - Nothing in here may be time-based. Decay/instability advances on *player turns only*
///    (pillar 2). If you ever need a `TimeInterval` for gameplay, it's a design bug.
enum Tuning {

    // MARK: - Persistence (not gameplay — these are engineering values)

    /// Debounce window for the background save. Brief specifies ≤100ms.
    static let saveDebounceMilliseconds: Int = 80

    /// Save-file schema version. Bump when `GameState`'s shape changes incompatibly and add a
    /// step in `Migrations.swift`.
    static let saveSchemaVersion: Int = 1

    // MARK: - Book authoring

    enum Book {
        // NOTE: there is deliberately no slot-count constant here. How many slots a book has
        // is content (`Content/Data/slots.json`), not tuning — see decisions-log session 2.
        static let baseBindCostEssence: Int = 10     // PLACEHOLDER
        /// Multiplier applied to each symbol's own essence cost when totalling a bind.
        static let symbolCostMultiplier: Double = 1.0 // PLACEHOLDER
        /// Flat charge for a slot left to chance, whatever rolls into it.
        ///
        /// Encodes the locked principle "precision costs, serendipity is cheap" (decisions-log
        /// session 2). It must stay BELOW the cheapest symbol — currently 2 — or leaving a slot
        /// empty stops being attractive and the pressure valve closes.
        static let randomSlotCostEssence: Int = 1 // PLACEHOLDER
        /// **A book starts here and every symbol adds its own number to it.** No conversion, no
        /// hidden multiplier — a symbol reading "−25 stability" moves the headline by exactly 25.
        ///
        /// **Stability tracks deviation from what a world would naturally have.** Asking for less
        /// than the baseline calms it, asking for the baseline costs nothing, asking for more is the
        /// greed that destabilises — the Mystcraft model from research-pass-3, run in both
        /// directions. Which is why the bounty slot is a decision (Sparse Ore +10, Ore 0, Rich Ore
        /// −45) rather than a tax you pay for turning up.
        ///
        /// **A fully stable world is reachable, and it is not an empty one.** Stack neutral and
        /// stabilising choices and you can hold a world open indefinitely — what that costs you is
        /// on the other axes: sight, danger, and what lives there. Stability is one dial among
        /// several, never a straight trade against yield.
        ///
        /// Calibrated against the current symbol set (14×14 = 196 tiles):
        ///
        ///   | book                                      | score |      turns | what it costs you |
        ///   |-------------------------------------------|-------|------------|-------------------|
        ///   | Plains · Verdant · Sparse Ore · Dim Sky   |   100 | indefinite | thin seams, dark  |
        ///   | Plains · Verdant · Ore · Dim Sky          |   100 | indefinite | ordinary, dark    |
        ///   | Plains · Verdant · Rich Ore · Dim Sky     |    67 |        201 | dark, tier 3      |
        ///   | Plains · Verdant · Rich Ore · Gilded      |    25 |         25 | tier 3, and brief |
        ///   | Caverns · Ashen · Rich Ore · Gilded       |     2 |          2 | everything        |
        static let baseStabilityScore: Int = 100
    }

    // MARK: - Pressures (the writing system's language half)

    enum Pressure {
        /// Every target speaks the same 0–100 scale, so the preview has one mental model.
        static let scaleMaximum: Double = 100

        /// Diminishing returns on stacking. Each further contribution to the same target counts for
        /// this much of the last — three suns are brighter than one but not three times brighter.
        /// Without it the correct play is always "write the same rune as often as it fits".
        static let stackingFalloff: Double = 0.6   // PLACEHOLDER

        /// Peak−floor spread at which a world's day and night are meaningfully different runs.
        static let wideRangeThreshold: Double = 50 // PLACEHOLDER
        /// …and the spread below which nothing ever changes.
        static let flatRangeThreshold: Double = 5  // PLACEHOLDER

        // Cross-target constraints — "the teeth". All PLACEHOLDER.
        /// How strongly air density pulls the thermal swing together (or, thin, pushes it apart).
        static let atmosphereThermalRetention: Double = 0.35
        /// Thermal floor below which standing water freezes.
        static let freezingFloor: Double = 25
        /// Thermal peak above which standing water goes airborne.
        static let evaporatingPeak: Double = 75
        /// Productivity a world can carry per point of *usable* water, and per point of light.
        static let vitalityPerWater: Double = 1.4
        static let vitalityPerLight: Double = 1.2
        static let barrenThreshold: Double = 10

        // The energy budget: one purse for size, armour, insulation, weapons and ornament.
        static let budgetPerProductivity: Double = 1.0
        /// Below this the world is cold enough that staying warm costs real energy.
        static let comfortableFloor: Double = 40
        static let insulationCostPerDegree: Double = 0.6

        // Reading a world's character.
        static let openTerrainThreshold: Double = 55
        static let coldFloor: Double = 30
        static let hotPeak: Double = 70
        static let wetThreshold: Double = 45
        static let aridThreshold: Double = 25
        static let iridescenceLight: Double = 40
        static let aphoticPeak: Double = 10
    }

    // MARK: - Worlds

    enum World {
        static let gridWidth: Int = 14               // PLACEHOLDER
        static let gridHeight: Int = 14              // PLACEHOLDER
        static let startingStability: Double = 100   // PLACEHOLDER

        /// **Stability is a number of steps.** Aimee's curve.
        ///
        /// At the bottom it's literal and brutal: a stability of 5 buys you five moves, 10 buys
        /// ten. Above each band it multiplies, so climbing out of the danger zone pays off sharply:
        ///
        ///   | score  | turns            |
        ///   |--------|------------------|
        ///   | 0      | 1 — you arrive, and it goes |
        ///   | 5      | 5                |
        ///   | 25     | 25               |
        ///   | 26     | 52               |
        ///   | 50     | 100              |
        ///   | 75     | 225 (≈ the whole 14×14 map) |
        ///   | 100    | indefinite       |
        ///
        /// The bands are deliberate cliffs, not a smooth curve: 25 → 26 doubles what you get, which
        /// gives the player thresholds to aim for rather than a gradient to squint at. If that ever
        /// feels too sharp, interpolating between bands is a one-line change here.
        static let stabilityTurnBands: [(minimumScore: Int, multiplier: Int)] = [
            (minimumScore: 76, multiplier: 4),
            (minimumScore: 51, multiplier: 3),
            (minimumScore: 26, multiplier: 2),
            (minimumScore: 0, multiplier: 1),
        ]
        /// What "indefinitely explorable" means in practice. Not truly infinite — every v0 world is
        /// disposable, and a world that genuinely never ends is what *anchoring* is for.
        static let indefiniteTurns: Int = 9_999
        /// Encounter difficulty tier before symbol modifiers.
        static let baseEnemyTier: Int = 1            // PLACEHOLDER
        /// Starting weight for every non-Reality resource in a world's yield table.
        static let baseResourceWeight: Double = 1.0  // PLACEHOLDER
        static let hazardThreshold: Double = 50      // PLACEHOLDER — hazards spawn at map edges
        static let crumbleThreshold: Double = 25     // PLACEHOLDER — tiles crumble inward
        static let collapseThreshold: Double = 0     // collapse (locked: 0 is the floor)
        /// Fraction of the haul kept when caught in collapse. Portal exit always keeps 100%.
        static let collapseHaulKeptFraction: Double = 0.5 // PLACEHOLDER
        /// Turns of tapping to fully harvest a node.
        static let harvestTurnsRange: ClosedRange<Int> = 1...3 // PLACEHOLDER
        /// Fallback for a creature with no sight of its own. Real values live on the creature
        /// (`CreatureDef.sightRadius`) so that some things can see you coming from further off.
        static let defaultEnemySightRadius: Int = 2  // PLACEHOLDER

        // Worldgen
        static let baseNodeCountRange: ClosedRange<Int> = 8...12   // PLACEHOLDER, scaled by book
        static let nodeYieldRange: ClosedRange<Int> = 1...3        // PLACEHOLDER, per pull
        static let baseEnemyCountRange: ClosedRange<Int> = 3...5   // PLACEHOLDER, scaled by danger
        static let enemiesPerDangerTier: Int = 2                   // PLACEHOLDER
        static let exitPortalCountRange: ClosedRange<Int> = 1...2  // brief: always ≥1
        static let minimumExitPortalDistance: Int = 6              // PLACEHOLDER — worth finding
        static let enemyFreeRadiusAroundEntry: Int = 3             // PLACEHOLDER — no ambush on arrival
        static let wildDropCountRange: ClosedRange<Int> = 2...4    // PLACEHOLDER
        static let wildDropAmountRange: ClosedRange<Int> = 1...2   // PLACEHOLDER
        /// Chance a world contains a locked cache.
        ///
        /// Coupled to key supply, and the coupling is the whole design (decisions session 5 flags
        /// this). Worlds are disposable, so a cache you can't open dies with its world — that's the
        /// intended tease only while keys roughly keep pace. Current rates:
        ///
        ///   keys per run  ≈ foes defeated × curioDropChance × P(curio is the knot) ≈ 4 × 0.35 × 0.5 ≈ 0.7
        ///   caches per run ≈ lockedCacheChance                                                  = 0.4
        ///
        /// So key supply outruns cache supply after the first run or two, and the *first* cache is
        /// reliably unopenable — which is the moment the design wants. If playtesting says
        /// otherwise, move these two together, never one alone.
        static let lockedCacheChance: Double = 0.4                 // PLACEHOLDER

        // Sight
        /// Raised from 2 on the designer's flag (decisions session 5): at 2 you see ~24 of 196
        /// tiles, which reads as groping rather than exploring, and leaves a vision-reducing quirk
        /// nowhere to cut. At 3 a quirk can take a ring off and still leave you seeing.
        static let baseVisionRadius: Int = 3         // PLACEHOLDER
        static let minimumVisionRadius: Int = 1      // even Dim Sky leaves you your own tile + 1
        /// Hazard tiles appear this often (in player turns) past the hazard threshold.
        static let hazardSpawnInterval: Int = 2      // PLACEHOLDER
        static let hazardDamage: Int = 4             // PLACEHOLDER
        /// Tiles lost per turn past the crumble threshold.
        static let crumbleTilesPerTurn: Int = 3      // PLACEHOLDER
    }

    // MARK: - Encounters

    enum Encounter {
        static let partySize: Int = 2                // PLACEHOLDER — Binder + 1 companion
        static let maxFoes: Int = 3                  // PLACEHOLDER
        static let startingGambitSlots: Int = 2      // PLACEHOLDER
        /// Fleeing always succeeds but costs the run stability.
        static let fleeStabilityCost: Double = 3     // PLACEHOLDER
        /// Turns after fleeing before a bump can start another fight, so the foe you just escaped
        /// can't walk straight back into you.
        static let fleeGraceTurns: Int = 2           // PLACEHOLDER
        static let binderMaxHP: Int = 30             // PLACEHOLDER
        static let companionMaxHP: Int = 24          // PLACEHOLDER
        static let binderAttack: Int = 6             // PLACEHOLDER
        static let companionBaseAttack: Int = 5      // PLACEHOLDER
        static let attackPerWeaponTier: Int = 2      // PLACEHOLDER
        static let defencePerArmorTier: Int = 1      // PLACEHOLDER
        static let minimumDamage: Int = 1            // a hit always does something
        /// Damage and healing wobble by ±this fraction of their power.
        static let damageVariance: Double = 0.25     // PLACEHOLDER
        static let consumableHealAmount: Int = 10    // PLACEHOLDER
        /// Resource units a defeated foe drops, multiplied by its tier. A tier-1 nuisance gives
        /// pocket change; a tier-3 horror is worth the fight.
        static let lootPerTierRange: ClosedRange<Int> = 1...2 // PLACEHOLDER
        /// Backstop so a misbehaving rule can never hang the app between player inputs.
        static let maxAutomaticTurnsPerInput: Int = 40
    }

    // MARK: - Economy

    enum Economy {
        static let startingEssence: Int = 40         // PLACEHOLDER
        static let startingInventorySlots: Int = 8   // PLACEHOLDER
        static let inventorySlotsPerStorehouseTier: Int = 4 // PLACEHOLDER
        /// The satchel is what you carry INTO a world, and is deliberately smaller than home
        /// storage — the gap is what forces "keep it or leave it" (decisions-log session 2).
        static let startingSatchelSlots: Int = 4    // PLACEHOLDER
        static let satchelSlotsPerTier: Int = 2     // PLACEHOLDER
        static let identifyCostEssence: Int = 5      // PLACEHOLDER
        /// Raw essence refines into this much essence at the Workshop. The join between what
        /// worlds give you and what the base runs on.
        static let essencePerRawEssence: Int = 2    // PLACEHOLDER

        // Locked caches — guaranteed Rare+ (design brief).
        static let cacheMoteRange: ClosedRange<Int> = 1...2 // PLACEHOLDER
        static let cacheSymbolWeight: Double = 1.0   // PLACEHOLDER
        static let cacheGambitWeight: Double = 1.0   // PLACEHOLDER
        static let cacheMoteWeight: Double = 0.8     // PLACEHOLDER — the fallback, so never a dud

        /// Chance a won encounter drops an unidentified curio.
        static let curioDropChance: Double = 0.35    // PLACEHOLDER
        /// Essence Spring trickle, credited on each return from a run (in-session event only —
        /// never wall-clock; see pillar 2).
        static let essenceSpringPerReturn: [Int] = [3, 7] // PLACEHOLDER — index = tier - 1
    }
}
