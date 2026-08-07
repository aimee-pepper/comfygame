import Foundation

/// Levels, experience, and what a stat is actually worth.
///
/// `decisions-session-17.md` §1–2. The rule the whole thing is built on: **every stat feeds
/// something combat already computes**, so a character's Fortitude and a creature's armour meet in
/// the same `damageTaken` rather than in two parallel systems.
///
/// Nothing here advances on wall-clock time — experience arrives from player actions only, like
/// everything else (pillar 2).
enum CharacterRules {

    // MARK: Levels

    /// Total experience needed to *be* a given level. Superlinear, so the early levels come quickly
    /// and later ones are things you go and earn.
    static func experienceForLevel(_ level: Int) -> Int {
        guard level > 1 else { return 0 }
        let steps = Double(level - 1)
        return Int((Double(Tuning.Character.experienceForSecondLevel)
                    * pow(steps, Tuning.Character.experienceCurve)).rounded())
    }

    static func level(forExperience experience: Int) -> Int {
        var level = 1
        while level < Tuning.Character.maximumLevel,
              experience >= experienceForLevel(level + 1) { level += 1 }
        return level
    }

    /// **What a level gives you.** One point in each of two stats, chosen by what the character
    /// already leans toward, so somebody stays recognisably themselves as they grow.
    ///
    /// PLACEHOLDER: `companions-classes-spec-v2.md` gives classes their own growth, and this is the
    /// classless stand-in until that list arrives (it's Aimee's — `for-design.md` §1.1). Deliberately
    /// *not* random: a level-up that rolls badly is a punishment for playing.
    static func grow(_ character: inout CharacterState) {
        let ordered = Stat.allCases.sorted { character.stats[$0] > character.stats[$1] }
        for stat in ordered.prefix(Tuning.Character.statsPerLevel) {
            character.stats[stat] += 1
        }
        character.level += 1
    }

    /// Adds experience and levels up as far as it reaches. Returns the levels gained, so the UI can
    /// say so rather than silently changing a number.
    @discardableResult
    static func award(_ amount: Int, to character: inout CharacterState) -> Int {
        guard amount > 0, character.level < Tuning.Character.maximumLevel else { return 0 }
        character.experience += amount
        var gained = 0
        while character.level < Tuning.Character.maximumLevel,
              character.experience >= experienceForLevel(character.level + 1) {
            grow(&character)
            gained += 1
        }
        return gained
    }

    // MARK: What a stat is worth

    /// Damage a party member adds, on top of their weapon.
    ///
    /// **Might for crush, Finesse for pierce and rend** (session 17 §1). Which means a character
    /// and their weapon want to agree — a high-Might character carrying a piercing blade is
    /// wasting half of what they are, and that's a real equipping decision rather than "wear the
    /// highest tier".
    static func damageBonus(_ stats: CharacterStats, with kind: DamageKind?) -> Int {
        let relevant: Int = switch kind {
        case .crush: stats.might
        case .pierce, .rend: stats.finesse
        // Bare-handed, or a skill with no corner of its own: whichever you're better at.
        case nil: max(stats.might, stats.finesse)
        }
        return Int((Double(relevant - Tuning.Character.startingStat)
                    * Tuning.Character.damagePerPoint).rounded())
    }

    /// Health. Fortitude is the only thing that moves it, so it's legible.
    static func maximumHealth(_ character: CharacterState, base: Int) -> Int {
        base + (character.stats.fortitude - Tuning.Character.startingStat)
            * Tuning.Character.healthPerFortitude
    }

    /// **What your armour is worth to you.** The same plate does more for a sturdy character than a
    /// slight one — which is what stops Fortitude being a second health bar.
    static func armourMultiplier(_ stats: CharacterStats) -> Double {
        1 + Double(stats.fortitude - Tuning.Character.startingStat)
            * Tuning.Character.armourPerFortitude
    }

    /// Chance an attack simply misses you.
    static func evasion(_ stats: CharacterStats) -> Double {
        min(Tuning.Character.maximumEvasion,
            Double(stats.finesse - Tuning.Character.startingStat) * Tuning.Character.evasionPerPoint)
    }

    /// How much of a lingering harm you shrug off — bleed, burn, poison.
    static func resilience(_ stats: CharacterStats) -> Double {
        min(Tuning.Character.maximumResilience,
            Double(stats.fortitude - Tuning.Character.startingStat)
                * Tuning.Character.resiliencePerPoint)
    }

    /// Extra tiles of sight. **Perception is the only stat that does anything outside a fight**,
    /// which is deliberate — a party built to look at things should find more.
    static func sightBonus(_ stats: CharacterStats) -> Int {
        (stats.perception - Tuning.Character.startingStat) / Tuning.Character.perceptionPerSightTile
    }

    /// Skills hit harder and come back sooner with Wit.
    static func skillPower(_ base: Int, _ stats: CharacterStats) -> Int {
        base + Int((Double(base) * Double(stats.wit - Tuning.Character.startingStat)
                    * Tuning.Character.skillPowerPerWit).rounded())
    }

    static func cooldown(_ base: Int, _ stats: CharacterStats) -> Int {
        let shortened = base - (stats.wit - Tuning.Character.startingStat) / Tuning.Character.witPerCooldownRound
        return max(Tuning.Character.minimumCooldown, shortened)
    }

    /// **Wit governs how long a rule list you can hold** (session 17 §1), which ties the automation
    /// system to character growth — a sharper companion holds a longer hand, which is a nice
    /// expression of "literacy, not inventory".
    static func gambitSlots(_ stats: CharacterStats) -> Int {
        (stats.wit - Tuning.Character.startingStat) / Tuning.Character.witPerGambitSlot
    }

    // MARK: What a fight is worth

    /// **Experience for winning**, scaled by what you beat rather than flat — so picking on
    /// something far below you stops paying.
    static func experience(forDefeating foe: FoeState, partyLevel: Int) -> Int {
        let gap = Double(foe.level - partyLevel)
        let scale = max(Tuning.Character.minimumExperienceScale,
                        1 + gap * Tuning.Character.experiencePerLevelGap)
        return max(1, Int((Double(Tuning.Character.experiencePerFoe) * scale).rounded()))
    }

    /// **And for finding** (session 17 §2) — a first sighting, a site entered, a page recovered.
    /// The half that makes a careful explorer advance as surely as a fighter.
    enum Discovery {
        case species, site, page, traveller

        var experience: Int {
            switch self {
            case .species: Tuning.Character.experienceForSpecies
            case .site: Tuning.Character.experienceForSite
            case .page: Tuning.Character.experienceForPage
            case .traveller: Tuning.Character.experienceForTraveller
            }
        }
    }

    // MARK: What the world levels to

    /// **Mobs level too, three ways** (session 17 §3): slowly with the party, and faster in worlds
    /// that are unstable or greedy. That last pair is the point — the risk already priced into
    /// instability and greed now shows up as *difficulty* as well as danger, which is a far more
    /// legible expression of it than hazard frequency alone.
    static func foeLevel(partyLevel: Int, stability: Double, greed: Double) -> Int {
        let fromParty = Double(partyLevel) * Tuning.Character.foeLevelPerPartyLevel
        let fromInstability = (Tuning.World.startingStability - stability)
            / Tuning.Character.stabilityPerFoeLevel
        let fromGreed = greed / Tuning.Character.greedPerFoeLevel
        return max(1, Int((fromParty + fromInstability + fromGreed).rounded()))
    }

    /// How much a level is worth to something you're fighting. Applied to its derived stats rather
    /// than to its traits, so a levelled creature is still recognisably the creature it was.
    static func scaled(_ value: Int, toLevel level: Int) -> Int {
        guard level > 1 else { return value }
        return Int((Double(value) * pow(Tuning.Character.foeStatPerLevel, Double(level - 1))).rounded())
    }
}
