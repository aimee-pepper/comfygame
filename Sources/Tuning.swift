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
        /// **A book starts here, and what moves it is measured rather than typed** (Q44).
        ///
        /// **Stability tracks deviation from what a world ordinarily has.** Asking for less calms
        /// it, asking for ordinary costs nothing, asking for more is the greed that destabilises —
        /// the Mystcraft model from research-pass-3, run in both directions. Which is why the bounty
        /// ladder is a decision rather than a tax you pay for turning up.
        ///
        /// **A fully stable world is reachable, and it is not an empty one.** Stack neutral and
        /// stabilising choices and you can hold a world open indefinitely — what that costs you is
        /// on the other axes: sight, danger, and what lives there. Stability is one dial among
        /// several, never a straight trade against yield.
        ///
        /// Measured against the current vocabulary, 7 Aug, after writing was moved to start at an
        /// ordinary world rather than at nothing:
        ///
        ///   | book                                      | score |      turns | what it costs you |
        ///   |-------------------------------------------|-------|------------|-------------------|
        ///   | Sparse Ore alone                          |   100 | indefinite | nothing to dig    |
        ///   | Plains · Frostbound · Sparse Ore · Dim Sky|   100 | indefinite | thin seams, dark  |
        ///   | Plains · Verdant · Ore · Dim Sky          |    75 |        375 | ordinary, dark    |
        ///   | Plains · Verdant · Rich Ore · Dim Sky     |    43 |        151 | dark, tier 3      |
        ///   | Plains · Verdant · Rich Ore · Gilded      |     0 |         60 | everything        |
        ///   | Caverns · Ashen · Rich Ore · Gilded       |    15 |         60 | everything        |
        ///
        /// **Verdant costs now, and that is the point** (Aimee, 7 Aug: *"a verdant lush world slowly
        /// scales up destabilization with how much more life than normal it has"*). It used to be
        /// free because it was hand-typed as free.
        static let baseStabilityScore: Int = 100

        /// **Stability per point of abundance asked for beyond ordinary** — the greed half of
        /// instability. Runs both directions: writing *less* than a world ordinarily has calms it.
        /// **[PLACEHOLDER]**
        static let stabilityPerAbundance: Double = 0.45
        /// **How heavily an ordinary subject's excess counts** — the deviation axis, applied to
        /// everything. Light, because being *strange* should cost less than being *rich*. Substrate
        /// and Vitality override it in `pressure_targets.json` at 1.8 and 1.5, which is where the
        /// two-axis model's *value* half lives: roughly five times the weight, so a gold-veined world
        /// costs far more than a merely mountainous one. **[PLACEHOLDER]**
        static let ordinaryGreedWeight: Double = 0.35  // PLACEHOLDER
        /// Essence per cell of the page you actually used. Bigger runes cost more ink.
        static let essencePerCell: Double = 0.6   // PLACEHOLDER
        /// How many rolls of the unwritten subjects the preview samples to find the stability band.
        /// Runs on every keystroke at the desk, so it's a handful rather than a hundred.
        static let stabilitySamples: Int = 20     // PLACEHOLDER
    }

    // MARK: - Pressures (the writing system's language half)

    enum Pressure {
        /// Every target speaks the same 0–100 scale, so the preview has one mental model.
        /// How much a favoured condition multiplies something's share. **[PLACEHOLDER]**
        static let affinityBonus: Double = 1.8
        static let scaleMaximum: Double = 100

        /// Diminishing returns on stacking. Each further contribution to the same target counts for
        /// this much of the last — three suns are brighter than one but not three times brighter.
        /// Without it the correct play is always "write the same rune as often as it fits".
        static let stackingFalloff: Double = 0.6   // PLACEHOLDER

        /// Peak−floor spread at which a world's day and night are meaningfully different runs.
        static let wideRangeThreshold: Double = 50 // PLACEHOLDER
        /// The floor below which a night counts as **true dark** — dark enough that living in it is
        /// a different trade from living in the day, which is what makes a nocturnal niche real.
        static let trueDarkFloor: Double = 5       // PLACEHOLDER
        /// …and the spread below which nothing ever changes.
        ///
        /// Both are read against an **ordinary** swing of 45 (illumination's day 45, night 0) rather
        /// than against a world that starts black, so "flat" means a third of ordinary rather than
        /// nothing at all. Enough cloud closes the day to a range of 13, which is the world the
        /// `constant` tag exists to name.
        static let flatRangeThreshold: Double = 15 // PLACEHOLDER

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
        /// **How much of what you wrote survives the dark.**
        ///
        /// Light used to be a hard cap, so a world you wrote for life came out sterile whenever
        /// illumination — a target you probably didn't write — happened to roll dark. Now darkness
        /// changes what grows rather than whether anything does: you keep this share of it, and
        /// what you keep is fungal (Aimee, 6 Aug; the metabolism answer to Q24, early).
        static let darkLifeFraction: Double = 0.6   // PLACEHOLDER
        /// **And how much survives no usable water.** Lower than the dark fraction, because
        /// dryness bites harder than darkness — but a desert or an ice sheet is sparse and hardy,
        /// not sterile, and usable water goes to zero the moment a world freezes over.
        static let dryLifeFraction: Double = 0.35   // PLACEHOLDER
        static let barrenThreshold: Double = 10

        // **What Scale and Count are worth** (`writing-desk-fixes.md` §3). Both were written,
        // displayed and consumed by nothing.
        /// The middle of a four-rung ladder, so *small* reduces and *vast* increases.
        static let middleRung: Double = 2
        /// How much a rung of Scale moves magnitude, on subjects with no separate extent.
        static let magnitudePerScaleRung: Double = 0.35 // PLACEHOLDER
        /// **Sublinear**, or Count is just a bigger Intensity: two suns are brighter than one and
        /// nothing like twice as bright.
        static let countExponent: Double = 0.55         // PLACEHOLDER
        /// How far a rung of either ladder pushes a subject's extent toward scattered.
        static let extentPerRung: Double = 9            // PLACEHOLDER
        /// **How deep a food web each point of production can carry.** Consumers add to vitality
        /// (Q38) and would otherwise be able to describe a rich web with nothing underneath it.
        static let trophicDepthPerProducer: Double = 1.2  // PLACEHOLDER
        /// Below this the world says so: things live here and there is nothing for them to eat.
        static let shallowFoodWeb: Double = 12            // PLACEHOLDER

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
        /// **No longer the size of a world** — size is written, via the Scale qualifier
        /// (session 13 §5). These remain only as the fallback for anything that has no book.
        static let gridWidth: Int = 18               // PLACEHOLDER
        static let gridHeight: Int = 18              // PLACEHOLDER
        /// How many tiles of the world are on screen at once.
        static var viewportTiles: Int { Tuning.Camera.viewportTiles }
        static let startingStability: Double = 100   // PLACEHOLDER

        /// **Stability is a number of steps.** Aimee's curve.
        ///
        /// Above each band it multiplies, so climbing out of the danger zone pays off sharply. The
        /// bands are deliberate cliffs, not a smooth curve: crossing one roughly doubles what you
        /// get, which gives the player thresholds to aim for rather than a gradient to squint at.
        ///
        /// **Rescaled for the bigger map.** Session 13 grew the world from 14×14 to 18×18 — 196
        /// tiles to 324, a 1.65× increase — and said stability must buy proportionally more turns
        /// "so runs aren't cut short simply by the map growing". The map grew and these didn't, so
        /// a stability-25 world bought 25 turns on a map that takes a hundred to cross: an arrival
        /// and an ejection rather than a tense scramble. **[PLACEHOLDER]** — needs device testing,
        /// which is where session 13 says the map numbers get settled.
        ///
        ///   | score  | turns            |
        ///   |--------|------------------|
        ///   | 5      | 60 (the floor)   |
        ///   | 25     | 60 (the floor)   |
        ///   | 26     | 91               |
        ///   | 50     | 175              |
        ///   | 51     | 255              |
        ///   | 75     | 375              |
        ///   | 76     | 532              |
        ///   | 100    | indefinite       |
        static let stabilityTurnBands: [(minimumScore: Int, multiplier: Double)] = [
            (minimumScore: 76, multiplier: 7),
            (minimumScore: 51, multiplier: 5),
            (minimumScore: 26, multiplier: 3.5),
            (minimumScore: 0, multiplier: 2),
        ]

        /// **No run is shorter than one day plus a traverse.**
        ///
        /// A greedy world should be *dangerous*, not pointless. Below this a player doesn't get the
        /// scramble they wrote — they get an arrival and an ejection, which reads as the game being
        /// broken rather than as a consequence they chose. It also guarantees every world, however
        /// reckless, sees at least one nightfall: below the floor the whole day/night system and
        /// the nocturnal roster were invisible on exactly the worlds most likely to be interesting.
        static var minimumTurnsPerRun: Int { Tuning.DayNight.turnsPerDay + 20 } // PLACEHOLDER
        /// What "indefinitely explorable" means in practice. Not truly infinite — every v0 world is
        /// disposable, and a world that genuinely never ends is what *anchoring* is for.
        static let indefiniteTurns: Int = 9_999
        /// Beyond this the countdown stops being information: no run lasts this long, so a
        /// five-digit number on the header reads as a bug rather than as safety.
        static let countdownCeiling: Int = 2_000
        /// Encounter difficulty tier before symbol modifiers.
        static let baseEnemyTier: Int = 1            // PLACEHOLDER
        /// Starting weight for every non-Reality resource in a world's yield table.
        static let baseResourceWeight: Double = 1.0  // PLACEHOLDER
        /// How much further things see you across open ground. Openness setting ambush-versus-
        /// pursuit is specced in the pressure model and did nothing until now.
        static let sightBonusInOpenGround: Int = 1   // PLACEHOLDER
        static let hazardThreshold: Double = 50      // PLACEHOLDER — hazards spawn at map edges
        static let crumbleThreshold: Double = 25     // PLACEHOLDER — tiles crumble inward
        static let collapseThreshold: Double = 0     // collapse (locked: 0 is the floor)
        /// Fraction of the haul kept when caught in collapse. Portal exit always keeps 100%.
        static let collapseHaulKeptFraction: Double = 0.5 // PLACEHOLDER
        /// Turns of tapping to fully harvest a node.
        static let harvestTurnsRange: ClosedRange<Int> = 1...3 // PLACEHOLDER
        /// What a creature that senses averagely notices you from. Real ranges are derived from a
        /// creature's own sensory allocation, so a thing that lives by its eyes and a thing that
        /// hunts by touch notice you from different distances — and at different times of day.
        static let defaultEnemySightRadius: Int = 4  // PLACEHOLDER
        /// How much of its eyesight a creature keeps after dark.
        static let nightVisionFraction: Double = 0.35 // PLACEHOLDER
        /// How far the non-visual senses reach relative to eyes. Shorter — but night-proof.
        static let nonVisualSenseReach: Double = 0.7  // PLACEHOLDER

        // Worldgen
        static let baseNodeCountRange: ClosedRange<Int> = 8...12   // PLACEHOLDER, scaled by book
        static let nodeYieldRange: ClosedRange<Int> = 1...3        // PLACEHOLDER, per pull
        /// How much richer a node is in a world that keeps its wealth in a few places. The reward
        /// half of "concentrated: fewer, and worth finding" — the cost half was built and this
        /// wasn't, so concentration was pure downside. **[PLACEHOLDER]**
        static let nodeYieldConcentrationBonus: Double = 1.2
        /// The least the spread term can scale node count by, at full concentration. Kept close to 1
        /// so arrangement can't outshout richness: at 0.6 a scattered poor world and a concentrated
        /// rich one produced the same number of nodes. **[PLACEHOLDER]**
        static let nodeSpreadFloor: Double = 0.8
        static let baseEnemyCountRange: ClosedRange<Int> = 3...5   // PLACEHOLDER, scaled by danger
        static let enemiesPerDangerTier: Int = 2                   // PLACEHOLDER
        /// **What vitality does to how many things are standing in a world.** Multipliers on the
        /// base count at nothing-lives-here and at teeming. The old term ran 0.5→1.5 and sat below
        /// 1 for anything short of a paradise, so a written-for-life world held about as much as a
        /// dead one — which is what made "Teeming Life" a word rather than a difference.
        static let enemyCountAtDeath: Double = 0.2                 // PLACEHOLDER
        static let enemyCountWhenTeeming: Double = 3.0             // PLACEHOLDER
        /// **The vitality at which a world counts as teeming**, rather than 100.
        ///
        /// Nothing reaches 100. Stacking falloff means the sixth contribution to a target counts
        /// for a fraction of the first, so the strongest life book the vocabulary can write —
        /// verdant *and* teeming life — resolves around here. Measuring "how alive is this" against
        /// a ceiling nothing touches made every world read as half-dead. **[PLACEHOLDER]**
        static let teemingVitality: Double = 55
        static let exitPortalCountRange: ClosedRange<Int> = 1...2  // brief: always ≥1
        static let minimumExitPortalDistance: Int = 6              // PLACEHOLDER — worth finding
        static let enemyFreeRadiusAroundEntry: Int = 3             // PLACEHOLDER — no ambush on arrival
        /// How far from the way in somebody is standing. Far enough that reaching them is a walk
        /// through a world you wrote for them, which is the entire point of the search loop.
        static let travellerMinimumDistance: Int = 6               // PLACEHOLDER
        /// Craters a meteor leaves. Hazards, and the reason to write one anyway is what it puts in
        /// the ground — it is the only sky focus that changes the ground. **[PLACEHOLDER]**
        static let meteorCraters: Int = 4
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
        /// Extra tiles per turn for every turn spent in a world that has already collapsed, so a
        /// dead world genuinely runs out instead of nibbling its edges while you carry on working.
        static let crumbleAccelerationPerTurn: Double = 0.6 // PLACEHOLDER
    }

    // MARK: - Encounters

    /// The danger↔time axis (contradiction-danger-spec §5).
    /// What the tree-taught skills need. All PLACEHOLDER.
    enum TreeSkills {
        /// Below this share of its health, Finish is worth the turn.
        static let finishThreshold: Double = 0.35
        /// Rounds a coating lasts beyond the skill's own.
        static let envenomExtraRounds: Int = 2
        /// **What everybody can do without spending a point.** Unbind and Mend are the floor; Sight
        /// and Read are here only until instruments exist to carry them (Aimee: they're object
        /// skills). Leaving them out entirely would make them unreachable, which is worse than
        /// leaving them free.
        static let baseline: Set<String> = ["unbind", "mend", "sight", "read"]
    }

    enum Danger {
        /// The most stability the danger runes can buy between them, however many are written.
        ///
        /// **[PROPOSAL in §5, and it pulls against a ruling — see questions-for-design Q23.]**
        /// Without a ceiling, six danger runes make an arbitrarily greedy world safe, which is the
        /// failure Mystcraft capped its scorched/lightning bonus to avoid. With one, a symbol no
        /// longer moves the meter by exactly its printed number — so the shortfall is reported as
        /// its own line rather than silently swallowed.
        static let maximumStabilityGift: Int = 40    // PLACEHOLDER
    }

    /// The third progression axis, alongside vocabulary and page space: how much you can *read*
    /// (decisions-session-8). Unlocked by crafted instruments, so the same book is a different
    /// object depending on how well you can read it.
    /// The page: what you are *capable* of writing, as opposed to what you can afford today.
    enum Page {
        static let startingWidth: Int = 6            // PLACEHOLDER — spec §3 proposes 6x6
        static let startingHeight: Int = 6           // PLACEHOLDER
        /// A compound costs this fraction of its parts, rounded up. Always worth learning, never
        /// free.
        static let compoundFootprintRate: Double = 0.6   // PLACEHOLDER — spec §3
    }

    /// Diaries, pages, and the search for people.
    enum Library {
        /// How many worlds the history keeps before it starts dropping the oldest **unkept** ones.
        /// The save is rewritten after every action, so this can't be unbounded.
        static let worldsRemembered: Int = 40          // PLACEHOLDER
        /// How many pages a world may hold.
        static let pagesPerWorldRange = 0...2          // PLACEHOLDER
        /// How much more likely a page is to surface somewhere its author would have been.
        static let atHomeWeight: Double = 4            // PLACEHOLDER
        /// After this many worlds without a match, a page stops waiting and surfaces anywhere.
        /// Nothing may become permanently unreachable through how a player happens to write.
        static let patienceInWorlds: Int = 8           // PLACEHOLDER
    }

    enum Analysis {
        /// Tier 1 — qualitative only. Sensations, no numbers, no attribution. Deliberately where
        /// everyone starts: the player is meant to write half-blind and learn by observing.
        static let startingTier: Int = 1
        /// Tier 2 — targets become readable.  [not built]
        static let targetsTier: Int = 2
        /// Tier 3 — attribution: which sigils are responsible for what, secondaries included.
        static let sigilAttributionTier: Int = 3
        /// Tier 4 — instability broken out, greed versus contradiction. **The red/green
        /// underlining lives here**, not at the start.
        static let attributionTier: Int = 4
        /// Tier 5 — the living layer: trait distributions, predicted spawns.  [not built]
        static let livingTier: Int = 5
    }

    enum Contradiction {
        /// The disclosed superlinear term. Small: it exists to say "several at once is worse than
        /// several separately", not to make stacking unthinkable.
        static let escalationPerAdditional: Int = 8   // PLACEHOLDER
    }

    /// Sites — the discrete placed things, as opposed to the pressures that bias what spawns.
    enum Sites {
        /// How many sites a world gets, before eligibility and placement have their say. A world
        /// with nothing in it is a chore to walk across; a world studded with them is a shopping
        /// list rather than a place.
        static let perWorldCountRange = 1...3          // PLACEHOLDER
        /// Turns spent searching that are worth a haptic and a line of narration, not silence.
        static let searchRevealsContentsAt: Int = 0    // PLACEHOLDER
    }

    /// The turning of a world's day (decisions-session-13 §2 and §6).
    /// Painting the ground. All PLACEHOLDER.
    /// Sampling the animals in a world. All PLACEHOLDER — creature-system-spec §10 flags most of
    /// these as the numbers most worth challenging once they can be seen on a phone.
    enum Life {
        /// How many species a world holds — a barren one at the bottom, a teeming one at the top.
        /// Small on purpose: free sampling is only safe because the cast is small, and a strange
        /// animal should be the one you remember from that world.
        static let castSizeRange = 2...6
        /// Vitality per species above the floor. Measured against `teemingVitality`, not against a
        /// hundred nothing reaches: 2 species on dead ground, the full range on a teeming one.
        static let vitalityPerExtraSpecies: Double = 13

        // MARK: The budget

        /// What even a dead world can spend, so nothing is empty for reasons the player can't see.
        static let baseBudget: Double = 40
        static let budgetPerVitality: Double = 2.0
        /// Superlinear, so extremes are dear. The exponent decides how rare a maxed axis is.
        static let costExponent: Double = 1.5
        /// How much bulk raises the price of covering and bone. [PROPOSAL] in spec §4.
        static let sizeCostCoupling: Double = 1.2
        /// How much of an axis one purchase buys.
        static let allocationStep: Double = 5
        /// The body every creature gets before anything else is bought. A thing has to exist.
        static let minimumSize: Double = 12

        /// The covering every creature is born in. Skin is not an adaptation — **coverage priced
        /// like armour left every animal effectively naked**, and since armour and insulation are
        /// both `hardness × coverage`, a world could buy plate that reached none of the creature.
        static let baselineCoverage: Double = 35

        /// What each axis costs at full value, before the size coupling. Size dominates; being
        /// covered in *something* is cheap, and being covered in plate or fur is where it costs.
        static func axisCost(_ axis: CostlyAxis) -> Double {
            switch axis {
            case .size: 120
            case .coveringHardness: 55
            case .coveringLength: 40
            case .coveringCoverage: 25
            case .boneDensity: 45
            case .armament: 90
            case .ornament: 60
            }
        }

        /// Where each axis starts before pressures have an opinion.
        ///
        /// **Not uniform, because the axes aren't uniform in number.** Covering is three axes and a
        /// body is one, so equal weights hand covering three times the draws and produce animals
        /// that are mostly upholstery. These weights are per-*category* fairness, with size ahead
        /// because it's the axis everything else is measured against.
        static func baseAxisWeight(_ axis: CostlyAxis) -> Double {
            switch axis {
            case .size: 3.0
            case .coveringHardness, .coveringLength: 0.9
            case .coveringCoverage: 1.4
            case .boneDensity: 1.1
            case .armament: 2.0
            case .ornament: 0.7
            }
        }

        // MARK: Thresholds

        /// Below this the three weapon axes together read as unarmed — a real and common answer.
        static let unarmedThreshold: Double = 25
        /// Trophic depth at which species start committing to a defence branch.
        static let predationThreshold: Double = 30
        /// What "sleek" means on the sinuous↔bulky axis.
        static let sleekBuild: Double = 62
        /// How well a region has to fit before a species takes its name rather than a composed one.
        static let identityMatchThreshold: Double = 0.78
        /// How far outside a region's band a value can sit before it stops counting at all.
        static let identityBandTolerance: Double = 25
        /// Below this share of sensory allocation, a creature keeps night hours.
        static let nocturnalVisionCeiling: Double = 28
        /// Below this it reads as blind.
        static let blindVisionCeiling: Double = 18
        /// Appetite per tier of formidability. Five tiers across what the richest world can feed.
        static let appetitePerTier: Double = 55

        /// How often a world that permits its own light actually grows some.
        static let emanationChanceWhenSourceless: Double = 0.55
        static let emanationChanceWhenVolatile: Double = 0.3

        // MARK: Jitter

        /// How far a single animal varies from its species. **Never enough to change what it is,
        /// how it fights, or what it drops** — texture only.
        static let jitter = Jitter()

        struct Jitter: Sendable {
            var coloration: Double = 10
            var sizeFraction: Double = 0.05
            var finish: Double = 5
        }
    }

    /// **What grows** (`flora-system-spec.md`). All PLACEHOLDER — §9 flags metabolism, cast size and
    /// the sight-blocking threshold as the three most worth challenging once they can be walked
    /// through on a phone.
    enum Flora {

        // MARK: The cast

        /// How many kinds of plant a world holds. Smaller than the animal cast on purpose: flora is
        /// mostly terrain, and §9.2 asks whether it needs a cast at all.
        static let castSizeRange = 1...4
        /// Vitality per extra kind, measured against `teemingVitality` rather than a hundred nothing
        /// reaches — 1 kind on thin ground, 4 on a teeming world.
        static let vitalityPerExtraSpecies: Double = 18

        // MARK: Metabolism — whether a world can live at all

        /// Below this, a route to a living is not on the table. What makes "nothing grows here" a
        /// state a world can actually be in.
        static let viabilityFloor: Double = 0.08
        /// Light at which photosynthesis starts paying, and at which it is doing all it can.
        static let photosynthesisFloor: Double = 8
        static let photosynthesisFull: Double = 55
        /// Usable water at which rot is doing all it can, and how much a decaying world adds outright.
        static let fungalFullMoisture: Double = 45
        /// **How far rot gets in full daylight, and in the dark.** Fungi live in a meadow too; they
        /// are simply not what the meadow stands on. The gap between these two is the difference
        /// between "there are mushrooms here" and "this world runs on mushrooms".
        static let fungalInLight: Double = 0.3
        static let fungalCeiling: Double = 0.85
        static let fungalDecayBonus: Double = 0.25
        /// Volatile share and substrate magnitude at which chemosynthesis is doing all it can. Both
        /// terms matter: a volatile share of a world with no rock in it is a share of nothing.
        static let chemosynthesisFullShare: Double = 0.45
        static let chemosynthesisFullSubstrate: Double = 40
        /// How well a world has to feed itself in the dark before the light cap stops applying at
        /// all. **This is the number that lets a lightless volcanic world teem.**
        static let darkFeedingThreshold: Double = 0.45

        // MARK: The budget

        /// What even a thin world can grow, so nothing is bare for reasons the player can't see.
        static let baseBudget: Double = 30
        static let budgetPerVitality: Double = 1.6
        static let costExponent: Double = 1.5
        /// How much height raises the price of tissue. Holding yourself up costs more the taller you
        /// get, which is why a canopy is expensive and a mat is not.
        static let statureCostCoupling: Double = 1.4
        static let allocationStep: Double = 5
        /// The tissue every plant is made of before anything else is bought.
        static let minimumTissue: Double = 15

        /// What each axis costs at full value. Stature dominates.
        static func axisCost(_ axis: FloraAxis) -> Double {
            switch axis {
            case .stature: 110
            case .tissue: 70
            case .defence: 65
            }
        }

        /// Where each axis starts before pressures have an opinion.
        static func baseAxisWeight(_ axis: FloraAxis) -> Double {
            switch axis {
            case .stature: 2.4
            case .tissue: 2.0
            case .defence: 1.2
            }
        }

        // MARK: Pressures → growth

        /// What the stature weight is multiplied by in the dark and in full light. **Light is a
        /// race**: where there is plenty of it, the way to get it is to be taller than your
        /// neighbour, which is why a lit world grows canopy and a dark one grows mats.
        static let statureInDark: Double = 0.45
        static let statureInFullLight: Double = 2.2
        /// Substrate below this counts as poor ground — the resource availability hypothesis's
        /// trigger, where slow growth defends what it cannot replace.
        static let poorSubstrate: Double = 0.35
        /// Trophic depth at which things eating you starts overriding what the soil said, and how
        /// much it overrides by. **Herbivore pressure wins** (§3).
        static let grazingThreshold: Double = 0.2
        static let defenceUnderGrazing: Double = 1.8

        // MARK: Defence

        /// Defence at which a plant is worth walking around at all.
        static let defendedThreshold: Double = 30
        /// …and at which it might stand up instead. Doubly gated (§6): a world where the undergrowth
        /// attacks you is a world you remember, and it shouldn't be common.
        static let activeDefenceThreshold: Double = 60
        static let activeDefenceWeight: Double = 0.5
        static let activeDefenceVitality: Double = 40
        static let activeDefenceGrazing: Double = 0.35
        /// How many of each predatory kind actually stand up in one world. A patch, not a field.
        static let predatorsPerKind: Int = 2
        /// What walking into it costs, at full defence. Thorns hurt more at once; poison less, and
        /// then it stays with you.
        static let thornDamage: Double = 6
        static let toxinDamage: Double = 3
        static let toxinRounds: Int = 3
        /// What one turn of that poison still working costs. Small, and it is the *duration* that
        /// makes it worth going round rather than the bite.
        static let poisonPerTurn: Int = 2

        // MARK: Flora → terrain

        /// The most of a world's passable ground that flora can take, at full productivity. Read
        /// against `Tuning.Terrain.maximumGrowthCoverage`, which this replaces.
        static let maximumCoverage: Double = 0.55
        /// Stature at or above which growth breaks a sightline. Below it the ground is covered and
        /// you can still see across it — **groundcover shouldn't hide anything; canopy should**
        /// (§5), built as two ground types rather than one with a hidden property (§9.5).
        static let sightBlockingStature: Double = 40
        /// How far one patch runs, by habit. Spreading makes swathes, clustered makes thickets,
        /// solitary makes single tiles.
        static let spreadingPatchLength: Int = 14
        static let clusteredPatchLength: Int = 5

        // MARK: Flora → harvest

        /// Stature at which woody tissue is worth cutting for timber rather than stripping for fibre.
        static let timberStature: Double = 45
        static let baseHarvest: Double = 1
        static let harvestPerStature: Double = 3
        /// How much likelier an organic node is to sit on ground that actually grows something.
        static let nodeGrowthPreference: Double = 6

        /// What harvested tissue is worth as a material. Same six properties gear reads.
        static let hardnessPerWoody: Double = 0.8
        static let densityPerWoody: Double = 0.6
        static let insulationPerFleshy: Double = 0.7
        static let flexibilityPerFibrous: Double = 0.9
        /// What eating rock leaves in the flask, before defence adds to it.
        static let chemosyntheticReactivity: Double = 45

        // MARK: A plant that fights back

        /// How a predatory plant reads to the creature system. It is armed with its defence and
        /// armoured by its woodiness, and it does not move — which the map enforces, not the traits.
        static let armamentFromDefence: Double = 1.6
        static let boneFromWoody: Double = 0.7
        static let sessileBuild: Double = 88

        // MARK: Naming

        static let identityMatchThreshold: Double = 0.76
        static let identityBandTolerance: Double = 25
    }

    enum Terrain {
        /// The most of a world that water can cover, at full saturation.
        static let maximumWaterCoverage: Double = 0.45
        /// How many separate bodies fully-pervasive water breaks into.
        static let pondsAtFullDispersion: Double = 7
        /// **How much of the ground the growth shades**, at no height and at full height. A canopy
        /// takes more of a world than a mat of the same abundance does. The ceiling itself is
        /// `Tuning.Flora.maximumCoverage`, since it is flora that paints it now.
        static let coverageAtGroundLevel: Double = 0.7
        static let coveragePerStature: Double = 0.6
        /// A backstop on the patch loop, so a world with more growing budget than open ground to
        /// spend it on can't spin.
        static let maximumGrowthPatches: Int = 200

        // **Chasms** — Substrate's word for less (Aimee, 7 Aug). All PLACEHOLDER.

        /// The most of a world that can be hole. Kept under half: past that a map stops being a
        /// place with holes in it and becomes a corridor puzzle, which is a different game.
        static let chasmCoverageCeiling: Double = 0.45
        /// How far past ordinary the substrate demand has to fall for the ceiling to be reached,
        /// as a multiple of ordinary. At 2 an *overwhelming* Chasm is the maximum, a *great* one is
        /// most of the way, and a moderate one is a world with some serious holes in it.
        static let chasmFullDeficitMultiple: Double = 2.0
        /// Coverage at which the only way out is the way you came in.
        static let rivenChasmCoverage: Double = 0.42
        /// Separate mouths the holes open from, at full coverage. A chasm is something the ground
        /// did in a place, not a uniform porosity.
        static let chasmMouthsAtFullCoverage: Double = 8
        /// How much of a world's solid ground has to be walkable-to from where you arrive before
        /// the generator stops bridging holes. Not 1: a shoal cut off by deep water can't be
        /// bridged by filling a chasm, and placement already refuses to strand anything.
        static let reachableGroundFraction: Double = 0.85
        /// A ceiling on the bridging loop, so a world of islands can't spin it.
        static let maximumChasmBridges: Int = 60
    }

    enum Camera {
        /// Tiles across the window onto the world. **[PLACEHOLDER]** — wants testing on device,
        /// which is where session 13 says the map numbers get settled.
        static let viewportTiles: Int = 11
    }

    enum DayNight {
        /// Turns in a full day. Short enough that a run sees four or five turns of it, long enough
        /// that it doesn't strobe. **[PLACEHOLDER]**
        static let turnsPerDay: Int = 40
        /// The share of a day that is night.
        static let nightFraction: Double = 0.4      // PLACEHOLDER
        /// How much of your sight the dark takes.
        static let sightLostAtNight: Int = 1        // PLACEHOLDER
    }

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
        static let minimumDamage: Int = 1
        /// Covering thin enough that a flensing skill finds nothing to open — the reading that
        /// makes Flense an answer to shaggy things and useless against plated ones.
        static let thinCovering: Double = 0.2   // PLACEHOLDER — a flensing skill finds nothing to open
        /// How much a Ward turns aside, when it's set against the right thing. Deliberately short of
        /// total: setting it correctly should be a good round, not an immunity.
        static let wardReduction: Double = 0.6  // PLACEHOLDER
        /// **Harm that outlives the blow** (Q42, Aimee: three of them). Keyed by `StatusKind`, so a
        /// fourth is a line here and a case there. Burn is short and hard, poison long and patient,
        /// dazzle costs accuracy rather than health.
        static let statusDamage: [String: Int] = ["burn": 4, "poison": 2, "dazzle": 0] // PLACEHOLDER
        static let statusRounds: [String: Int] = ["burn": 2, "poison": 4, "dazzle": 2]  // PLACEHOLDER
        /// How often a dazzled swing finds nothing.
        static let dazzleMissChance: Double = 0.35 // PLACEHOLDER
        /// **Ranks** (session 17 §4). Standing at the back turns aside this much of a melee blow,
        /// and costs you this much of your own — protected, and weaker at arm's length.
        static let backRankProtection: Double = 0.45  // PLACEHOLDER
        static let backRankMeleePenalty: Double = 0.5 // PLACEHOLDER
        /// **What insulation and reactivity are worth on gear** (Q36's addition). Four of the six
        /// material properties decide what the Blacksmith asks for; these two had no job at all, so
        /// a warm pelt and a volatile ichor were worth nothing to wear.
        static let insulationPerPoint: Double = 0.25  // PLACEHOLDER
        static let maximumInsulation: Double = 0.6    // PLACEHOLDER
        /// How volatile a weapon's stock has to be before it leaves something in the wound.
        static let coatingReactivity: Double = 55     // PLACEHOLDER
        /// Damage and healing wobble by ±this fraction of their power.
        static let damageVariance: Double = 0.25     // PLACEHOLDER
        static let consumableHealAmount: Int = 10    // PLACEHOLDER
        /// Resource units a defeated foe drops, multiplied by its tier. A tier-1 nuisance gives
        /// pocket change; a tier-3 horror is worth the fight.
        static let lootPerTierRange: ClosedRange<Int> = 1...2 // PLACEHOLDER
        /// Backstop so a misbehaving rule can never hang the app between player inputs.
        static let maxAutomaticTurnsPerInput: Int = 40

        // MARK: Traits → combat (creature-system-spec §7). All PLACEHOLDER.
        //
        // Scaled against a binder who hits for 6 and has 30 HP: an ordinary animal should take
        // three or four rounds, a huge armoured one should be a decision rather than a formality.

        static let baseFoeHP: Double = 4
        static let hpPerSize: Double = 0.22
        static let hpPerBulk: Double = 6
        static let hpPerBone: Double = 0.06

        static let baseFoeAttack: Double = 1
        static let attackPerArmament: Double = 0.055
        static let attackPerSize: Double = 0.025

        /// Armour soaks flat damage. Kept small — armour should make a fight longer, not unwinnable.
        static let armourPerCovering: Double = 0.06
        /// What a pierce attack ignores of the *party's* armour, and what pierce ignores of a foe's.
        static let pierceArmourIgnored: Double = 0.5
        /// How much the right damage type against the right covering is worth, and how much the
        /// wrong one costs (combat-depth-spec §1). **[PLACEHOLDER]** — big enough that the read is
        /// worth making, small enough that a bad matchup isn't a wasted fight.
        static let matchupBonus: Double = 0.6
        static let matchupPenalty: Double = 0.45
        /// Nothing is ever completely useless.
        static let minimumMatchup: Double = 0.4
        /// Crush hits harder and slower: this much extra damage, at a cost to initiative.
        static let crushDamageBonus: Double = 0.2
        static let crushInitiativePenalty: Int = 3
        /// Rend leaves a wound that keeps costing you.
        static let bleedDamage: Int = 2
        static let bleedRounds: Int = 3
        /// What each blow is worth when something reaches more than one of you at once.
        static let multiDeliveryShare: Double = 0.7
        static let areaDeliveryShare: Double = 0.6

        static let baseInitiative: Double = 50
        static let initiativePerSize: Double = 0.3
        static let initiativePerBone: Double = 0.15
        static let initiativePerCoverage: Double = 0.12
        static let initiativePerSleekness: Double = 0.3
        /// The party's place in the order. Ordinary — some things are faster than you.
        static let binderInitiative: Int = 42
        static let companionInitiative: Int = 40

        static let evasionPerSleekness: Double = 0.006
        static let evasionPerSize: Double = 0.002
        /// Nothing is untouchable.
        static let maximumEvasion: Double = 0.35

        /// What hitting a warning-coloured animal costs you, per point of its size.
        static let retaliationPerSize: Double = 0.06
    }

    /// What a creature leaves behind (creature-system-spec §8). All PLACEHOLDER.
    enum Materials {
        /// A creature has to actually be wearing something before it yields any of it.
        static let minimumCoverageToYield: Double = 15
        static let minimumArmamentToYield: Double = 30
        static let minimumBoneToYield: Double = 20
        static let minimumEmanationToYield: Double = 25

        /// Where the covering tips from one material into another.
        static let hardCoveringThreshold: Double = 55
        static let longCoveringThreshold: Double = 45
        static let denseCoveringThreshold: Double = 50
        /// Layered iridescence is what makes a hard covering chitin rather than plate.
        static let schillerThreshold: Double = 25

        /// Quantity scales with size, and nothing else.
        static let baseQuantity: Double = 1
        static let quantityPerSize: Double = 3

        /// Grade scales with trait extremity, with a little for a good surface.
        static let gradePerExtremity: Double = 85
        static let gradePerLustre: Double = 25
        /// Above this a property is worth naming on the item's row.
        static let notableProperty: Double = 35
    }

    /// Naming what a world grew (name-generation-spec). **[PLACEHOLDER]** — and the vocabulary in
    /// `Naming` is voice rather than mechanism, so it is Aimee's to rewrite.
    enum Naming {
        /// How far from its world's average a trait has to sit before it's worth naming.
        static let minimumDeviation: Double = 8
        /// How much further out earns the next, stronger word in a band.
        static let deviationPerWord: Double = 16
    }

    // MARK: - What the player has met

    enum Discovery {
        /// How many worlds to sample when building the reference distribution the global percentile
        /// is measured against. Enough for a stable tail, cheap enough to compute once on first
        /// look. **[PLACEHOLDER]**
        static let globalSampleWorlds: UInt64 = 240
        /// Where a measurement stops being ordinary and becomes worth a word.
        static let remarkablePercentile: Double = 0.9   // PLACEHOLDER
        /// Specimens kept per identity you've met. The bestiary's percentiles need a population,
        /// not a complete history, and the save is rewritten after every action.
        static let specimensKeptPerIdentity: Int = 24 // PLACEHOLDER
    }

    // MARK: - Economy

    enum Economy {
        static let startingEssence: Int = 40         // PLACEHOLDER
        /// **Far more room than it used to be** (Aimee, 5 Aug). Eight slots and four per tier
        /// capped the storehouse at twenty forever, which fights the hoarding pillar outright.
        static let startingInventorySlots: Int = 16  // PLACEHOLDER
        static let inventorySlotsPerStorehouseTier: Int = 6 // PLACEHOLDER
        /// The satchel is what you carry INTO a world, and is deliberately smaller than home
        /// storage — the gap is what forces "keep it or leave it" (decisions-log session 2). It
        /// still grows a long way, or the decision is made for you every single run.
        static let startingSatchelSlots: Int = 8    // PLACEHOLDER
        static let satchelSlotsPerTier: Int = 3     // PLACEHOLDER
        static let identifyCostEssence: Int = 5      // PLACEHOLDER
        /// Raw essence refines into this much essence at the Workshop. The join between what
        /// worlds give you and what the base runs on.
        static let essencePerRawEssence: Int = 2    // PLACEHOLDER

        // Locked caches — guaranteed Rare+ (design brief).
        static let cacheMoteRange: ClosedRange<Int> = 1...2 // PLACEHOLDER
        /// How often a cache holds a word for the page. Highest of the three, because the
        /// vocabulary is the deepest progression and caches are its only repeatable source.
        static let cacheFocusWeight: Double = 3.0   // PLACEHOLDER
        static let cacheSymbolWeight: Double = 1.0   // PLACEHOLDER
        static let cacheGambitWeight: Double = 1.0   // PLACEHOLDER
        static let cacheMoteWeight: Double = 0.8     // PLACEHOLDER — the fallback, so never a dud

        /// Chance a won encounter drops an unidentified curio.
        static let curioDropChance: Double = 0.35    // PLACEHOLDER
        /// Chance a won encounter drops something to wear, **per tier of what you fought**. Sites
        /// were the only source of gear, so a run that found no ruin came home with nothing.
        static let gearDropChance: Double = 0.12     // PLACEHOLDER
        /// Essence Spring trickle, credited on each return from a run (in-session event only —
        /// never wall-clock; see pillar 2).
        static let essenceSpringPerReturn: [Int] = [3, 7] // PLACEHOLDER — index = tier - 1
    }

    // MARK: - The party

    enum Party {
        /// **Up to five** (Aimee, 6 Aug). Quill is one of them, so four can be found.
        static let maximumSize: Int = 5 // PLACEHOLDER
    }

    // MARK: - Characters

    /// Stats, levels, and what the world levels to (`decisions-session-17.md` §1–3).
    /// All PLACEHOLDER — the shape is the decision, the numbers are Aimee's to move.
    enum Character {
        /// Where every stat starts, so a bonus is a *deviation* from ordinary and zero means zero.
        static let startingStat: Int = 10

        // **The combat trees, and the level cap they imply** (`docs/combat-trees-full.md`).

        /// One point a level. Depth comes from nodes getting stronger, not costlier.
        static let treePointsPerLevel: Int = 1
        /// **Derived, not chosen** (Aimee: *"they need to reach the end of each tree on any one
        /// branch per tree"*). Nine branches of eight nodes; three complete branches is 24 points,
        /// one a level with the first free — so the cap is 25, and a finished companion has three
        /// branches at full depth and six they never touched. It was 30, picked before the trees
        /// existed to derive it from.
        static let maximumLevel: Int = 25
        /// **What changing your mind costs**, at the Spring. Enough to be a decision, never enough
        /// to make a build permanent — nobody should be stuck with points they spent before they
        /// knew what a branch did. Scales with how much you are unspending. **[PLACEHOLDER]**
        static let respecBaseCost: Int = 20
        static let respecCostPerPoint: Int = 8
        /// What a finished build is called. **Emergent** — nothing is authored per companion, and a
        /// combination nobody named is still a real build; it just gets the general word.
        static let emergentClasses: [(String, Set<String>)] = [
            ("Rogue",       ["swiftness", "evasion", "shadow"]),
            ("Knight",      ["force", "fortitude", "kindling"]),
            ("Hunter",      ["precision", "evasion", "venom"]),
            ("Bulwark",     ["force", "protection", "fortitude"]),
            ("Assassin",    ["precision", "fortitude", "shadow"]),
            ("Skirmisher",  ["swiftness", "protection", "kindling"]),
            ("Duelist",     ["force", "evasion", "venom"]),
            ("Warden",      ["precision", "protection", "kindling"]),
            ("Harrier",     ["swiftness", "fortitude", "venom"]),
        ]

        /// Experience for the second level, and how sharply the cost rises. Superlinear: early
        /// levels arrive from ordinary play, later ones are gone and earned.
        static let experienceForSecondLevel: Int = 60
        static let experienceCurve: Double = 1.6
        /// How many stats a level raises, chosen by what somebody already leans toward — never
        /// rolled, because a bad level-up is a punishment for playing.
        static let statsPerLevel: Int = 2

        // What a point is worth. Each of these feeds something combat already computed.
        static let damagePerPoint: Double = 0.6
        static let healthPerFortitude: Int = 2
        static let armourPerFortitude: Double = 0.04
        static let evasionPerPoint: Double = 0.012
        static let maximumEvasion: Double = 0.35
        static let resiliencePerPoint: Double = 0.03
        static let maximumResilience: Double = 0.6
        static let perceptionPerSightTile: Int = 6
        static let skillPowerPerWit: Double = 0.04
        static let witPerCooldownRound: Int = 8
        static let minimumCooldown: Int = 1
        static let witPerGambitSlot: Int = 6

        // What a fight and a discovery are worth.
        static let experiencePerFoe: Int = 12
        static let experiencePerLevelGap: Double = 0.25
        static let minimumExperienceScale: Double = 0.1
        /// **Finding pays too** (§2) — a game whose progression is literacy shouldn't reward only
        /// killing. A first sighting is worth about a fight; a person is worth a great deal more.
        static let experienceForSpecies: Int = 14
        static let experienceForSite: Int = 20
        static let experienceForPage: Int = 25
        static let experienceForTraveller: Int = 120

        // What the world levels to (§3). Instability and greed already price risk; now they price
        // difficulty, which is a far more legible expression of the same trade.
        static let foeLevelPerPartyLevel: Double = 0.8
        static let stabilityPerFoeLevel: Double = 18
        static let greedPerFoeLevel: Double = 25
        static let foeStatPerLevel: Double = 1.09
    }

    // MARK: - The Blacksmith

    /// Reforging (`materials-crafting-spec.md` §7): making the piece you carry better rather than
    /// waiting for a better one to drop. All PLACEHOLDER.
    enum Smith {
        /// How far a piece can be pushed, indexed by `Rarity.order` — common, uncommon, rare,
        /// mythic. A common blade finishes; a mythic one keeps going. **This is what stops a
        /// common piece reforged four times from catching a mythic one**, which would make finding
        /// a mythic pointless.
        static let maximumLevelByRarity: [Int] = [1, 2, 3, 5] // PLACEHOLDER

        /// The property bar the first reforging asks stock to clear, and how much it rises each
        /// time. 0–100, same scale as material properties.
        static let baseThreshold: Double = 30       // PLACEHOLDER
        static let thresholdPerLevel: Double = 14   // PLACEHOLDER
        /// Never so high that no material in the game could clear it.
        static let maximumThreshold: Double = 82    // PLACEHOLDER

        static let samplesBase: Int = 2             // PLACEHOLDER
        static let samplesPerLevel: Int = 1         // PLACEHOLDER
        static let essenceBase: Int = 8             // PLACEHOLDER
        static let essencePerLevel: Int = 6         // PLACEHOLDER
    }
}
