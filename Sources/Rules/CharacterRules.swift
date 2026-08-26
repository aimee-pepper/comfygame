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

/// Pure, deterministic encounter-scaling simulation. Candidate coefficients remain DEBUG choices;
/// the full-party reference is correctness and is used even when comparison scaling is off.
enum EncounterScalingRules {
    static let additivePartyPowerRulesVersion = "additive-party-power-v1"

    struct PartyMemberInput: Equatable, Sendable {
        var identity: String
        var level: Int
    }

    struct Contribution: Codable, Equatable, Sendable {
        var identity: String
        var level: Int
        var rawLevelRatio: Double
        var contribution: Double
    }

    struct PartyPowerLedger: Codable, Equatable, Sendable {
        var scalingRulesVersion: String
        var anchorLevel: Int
        /// Binder first, followed by companions in stable identity order.
        var contributions: [Contribution]
        var uncappedBudget: Double
        var cappedBudget: Double
    }

    /// Binder-anchored additive party pressure. The Binder's 1.0 entry is explicit in telemetry;
    /// companions cannot subtract power, and order cannot affect the sum.
    static func partyPower(anchorLevel: Int,
                           companions: [PartyMemberInput]) -> PartyPowerLedger {
        let anchor = max(1, anchorLevel)
        let binder = Contribution(identity: "binder", level: anchor,
                                  rawLevelRatio: 1, contribution: 1)
        let stableCompanions = companions.sorted {
            if $0.identity != $1.identity { return $0.identity < $1.identity }
            return $0.level < $1.level
        }.prefix(max(0, Tuning.Party.maximumSize - 1))
        let companionEntries = stableCompanions.map { member in
            let level = max(1, member.level)
            let ratio = pow(Tuning.Character.foeStatPerLevel, Double(level - anchor))
            return Contribution(identity: member.identity, level: level,
                                rawLevelRatio: ratio,
                                contribution: min(1.5, max(0.25, 0.5 * ratio)))
        }
        let all = [binder] + companionEntries
        let uncapped = all.reduce(0) { $0 + $1.contribution }
        return PartyPowerLedger(scalingRulesVersion: additivePartyPowerRulesVersion,
                                anchorLevel: anchor, contributions: all,
                                uncappedBudget: uncapped, cappedBudget: min(3, uncapped))
    }

    struct AdditivePressure: Codable, Equatable, Sendable {
        var realFoeCount: Int
        var shortfall: Double
        var wholePressureSlots: Int
        var fractionalShortfall: Double
        var totalHPAdditionFraction: Double
    }

    static func additivePressure(partyPowerBudget: Double,
                                 realFoeCount: Int) -> AdditivePressure {
        let count = max(0, realFoeCount)
        let shortfall = max(0, partyPowerBudget - Double(count))
        let whole = Int(floor(shortfall))
        let fraction = shortfall - Double(whole)
        return AdditivePressure(realFoeCount: count, shortfall: shortfall,
                                wholePressureSlots: whole,
                                fractionalShortfall: fraction,
                                totalHPAdditionFraction: 0.15 * Double(whole) + 0.30 * fraction)
    }

    static func additiveApexValues(ledger: PartyPowerLedger, worldLevel: Int,
                                   partyCount: Int) -> (levelFloor: Int, hp: Double,
                                                        offence: Double, slots: Int) {
        let extra = max(0, ledger.cappedBudget - 1)
        let count = min(Tuning.Party.maximumSize, max(1, partyCount))
        let slots = count <= 2 ? 1 : (count <= 4 ? 2 : 3)
        return (max(worldLevel, ledger.anchorLevel + 2),
                min(2.4, 1 + 0.70 * extra),
                min(1.4, 1 + 0.20 * extra), slots)
    }

    struct Profile: Equatable, Sendable {
        let equivalentsPerExtraMember: Double
        let missingFoeLevelCap: Int
        let remainderThreshold: Double?
        let apexLevelOffset: Int
        let apexHPPerMember: Double
        let apexHPCap: Double
        let apexOffencePerMember: Double
        let apexOffenceCap: Double
        let apexSlots: [Int]

        static let reserved = Profile(equivalentsPerExtraMember: 0.35, missingFoeLevelCap: 1,
                                      remainderThreshold: nil, apexLevelOffset: 1,
                                      apexHPPerMember: 0.25, apexHPCap: 2,
                                      apexOffencePerMember: 0.06, apexOffenceCap: 1.25,
                                      apexSlots: [1, 1, 2, 2, 2])
        static let recommended = Profile(equivalentsPerExtraMember: 0.5, missingFoeLevelCap: 2,
                                         remainderThreshold: nil, apexLevelOffset: 2,
                                         apexHPPerMember: 0.35, apexHPCap: 2.4,
                                         apexOffencePerMember: 0.10, apexOffenceCap: 1.4,
                                         apexSlots: [1, 1, 2, 2, 3])
        static let pressing = Profile(equivalentsPerExtraMember: 0.65, missingFoeLevelCap: 2,
                                      remainderThreshold: 0.35, apexLevelOffset: 3,
                                      apexHPPerMember: 0.45, apexHPCap: 2.8,
                                      apexOffencePerMember: 0.12, apexOffenceCap: 1.5,
                                      apexSlots: [1, 1, 2, 2, 3])
    }

    struct Preview: Codable, Equatable, Sendable {
        struct FinalFoe: Codable, Equatable, Sendable {
            let id: InstanceID
            let level: Int
            let maxHP: Int
            let attack: Int
            let armour: Int
            let isApex: Bool
        }
        let partyLevels: [Int]
        let upperMedian: Int
        let partyCount: Int
        let visibleFoeCount: Int
        let foeIDs: [InstanceID]
        let groupingRadius: Int
        let inclusionReasons: [String: String]
        let stabilityLevelContribution: Double
        let greedLevelContribution: Double
        let ordinaryBudget: Double
        let missingFoeConversion: Int
        let remainder: Double
        let remainderRoll: UInt32
        let remainderUpgrade: Int
        let apexLevelFloor: Int
        let apexHPMultiplier: Double
        let apexOffenceMultiplier: Double
        let apexActionSlots: Int
        var finalFoes: [FinalFoe] = []

        /// Additive v1 fields are optional so historical upper-median previews remain evidence
        /// rather than making a mid-encounter save unreadable.
        var scalingRulesVersion: String? = nil
        var partyPowerLedger: PartyPowerLedger? = nil
        var anchorLevel: Int? = nil
        var uncappedPartyPowerBudget: Double? = nil
        var cappedPartyPowerBudget: Double? = nil
        var realFoeCount: Int? = nil
        var shortfall: Double? = nil
        var wholePressureSlots: Int? = nil
        var fractionalShortfall: Double? = nil
        var totalHPAdditionFraction: Double? = nil
        var hpAllocationByFoeID: [String: Int]? = nil
        var exclusionReasons: [String: String]? = nil
        /// Exact creation inputs frozen by WorldRules. Older encounters omit these fields.
        var worldLevel: Int? = nil
        var triggerFoeID: InstanceID? = nil
        var scalingProfile: String? = nil
        var scalingProfileSchemaVersion: Int? = nil

        /// Historical decode/display only. Additive Recommended never applies this adjustment.
        var totalOrdinaryLevelAdjustment: Int { missingFoeConversion + remainderUpgrade }
    }

    static func partyLevels(in state: GameState) -> [Int] {
        [state.base.binderCharacter.level] + state.base.activeParty.compactMap {
            state.base.rosterIndex(for: $0).map { state.base.roster[$0].character.level }
        }
    }

    static func companionInputs(in state: GameState) -> [PartyMemberInput] {
        state.base.activeParty.compactMap { id in
            guard let index = state.base.rosterIndex(for: id) else { return nil }
            let companion = state.base.roster[index]
            let identity: String
            if let traveller = companion.traveller {
                identity = "traveller:\(traveller.rawValue)"
            } else if companion.name.trimmingCharacters(in: .whitespacesAndNewlines)
                .localizedCaseInsensitiveCompare("Quill") == .orderedSame {
                identity = "quill"
            } else {
                // Generated-person IDs are not live yet. This reorder-stable legacy identity is
                // evidence only until that migration lands; it deliberately never uses roster order.
                let name = companion.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                let calling = companion.calling.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                identity = "legacy-person:\(name)|\(calling)"
            }
            return PartyMemberInput(identity: identity, level: companion.character.level)
        }
    }

    static func upperMedian(_ levels: [Int]) -> Int {
        let ordered = levels.sorted()
        return ordered.isEmpty ? 1 : ordered[ordered.count / 2]
    }

    static func additivePreview(anchorLevel: Int, companions: [PartyMemberInput],
                                visibleFoes: [WorldEnemy], worldLevel: Int,
                                stability: Double = Tuning.World.startingStability,
                                greed: Double = 0, groupingRadius: Int,
                                inclusionReasons: [String: String],
                                exclusionReasons: [String: String]) -> Preview {
        let ledger = partyPower(anchorLevel: anchorLevel, companions: companions)
        let pressure = additivePressure(partyPowerBudget: ledger.cappedBudget,
                                        realFoeCount: visibleFoes.count)
        let count = min(Tuning.Party.maximumSize, 1 + companions.count)
        let levels = [max(1, anchorLevel)] + companions.prefix(max(0, count - 1)).map { max(1, $0.level) }
        let apex = additiveApexValues(ledger: ledger, worldLevel: worldLevel,
                                      partyCount: count)
        var result = Preview(
            partyLevels: levels, upperMedian: upperMedian(levels), partyCount: count,
            visibleFoeCount: visibleFoes.count, foeIDs: visibleFoes.map(\.id),
            groupingRadius: groupingRadius, inclusionReasons: inclusionReasons,
            stabilityLevelContribution: (Tuning.World.startingStability - stability)
                / Tuning.Character.stabilityPerFoeLevel,
            greedLevelContribution: greed / Tuning.Character.greedPerFoeLevel,
            ordinaryBudget: ledger.cappedBudget, missingFoeConversion: 0,
            remainder: 0, remainderRoll: 0, remainderUpgrade: 0,
            apexLevelFloor: apex.levelFloor, apexHPMultiplier: apex.hp,
            apexOffenceMultiplier: apex.offence, apexActionSlots: apex.slots)
        result.scalingRulesVersion = additivePartyPowerRulesVersion
        result.partyPowerLedger = ledger
        result.anchorLevel = ledger.anchorLevel
        result.uncappedPartyPowerBudget = ledger.uncappedBudget
        result.cappedPartyPowerBudget = ledger.cappedBudget
        result.realFoeCount = pressure.realFoeCount
        result.shortfall = pressure.shortfall
        result.wholePressureSlots = pressure.wholePressureSlots
        result.fractionalShortfall = pressure.fractionalShortfall
        result.totalHPAdditionFraction = pressure.totalHPAdditionFraction
        result.hpAllocationByFoeID = [:]
        result.exclusionReasons = exclusionReasons
        return result
    }

    static func preview(profile: Profile, partyLevels: [Int], visibleFoes: [WorldEnemy],
                        mapSeed: UInt64, triggerID: InstanceID, worldLevel: Int,
                        stability: Double = Tuning.World.startingStability, greed: Double = 0,
                        groupingRadius: Int = 1) -> Preview {
        let count = max(1, min(Tuning.Party.maximumSize, partyLevels.count))
        let levels = Array(partyLevels.prefix(count))
        let median = upperMedian(levels)
        let budget = 1 + profile.equivalentsPerExtraMember * Double(count - 1)
        let desiredWhole = min(Tuning.Encounter.maxFoes, max(1, Int(floor(budget))))
        let missing = min(profile.missingFoeLevelCap, max(0, desiredWhole - visibleFoes.count))
        let remainder = budget - floor(budget)
        let roll = stableRemainder(mapSeed: mapSeed, triggerID: triggerID)
        let fires: Bool
        if let threshold = profile.remainderThreshold { fires = remainder >= threshold }
        else { fires = remainder > 0 && Double(roll) / Double(UInt32.max) < remainder }
        let extra = max(0, count - 1)
        return Preview(partyLevels: levels, upperMedian: median, partyCount: count,
                       visibleFoeCount: visibleFoes.count, foeIDs: visibleFoes.map(\.id),
                       groupingRadius: groupingRadius,
                       inclusionReasons: Dictionary(uniqueKeysWithValues: visibleFoes.enumerated().map {
                           (String($0.element.id.rawValue), $0.offset == 0 ? "triggering map entity" : "awake within radius \(groupingRadius)")
                       }),
                       stabilityLevelContribution: (Tuning.World.startingStability - stability)
                           / Tuning.Character.stabilityPerFoeLevel,
                       greedLevelContribution: greed / Tuning.Character.greedPerFoeLevel,
                       ordinaryBudget: budget, missingFoeConversion: missing, remainder: remainder,
                       remainderRoll: roll, remainderUpgrade: fires ? 1 : 0,
                       apexLevelFloor: max(worldLevel, median + profile.apexLevelOffset),
                       apexHPMultiplier: min(profile.apexHPCap, 1 + profile.apexHPPerMember * Double(extra)),
                       apexOffenceMultiplier: min(profile.apexOffenceCap, 1 + profile.apexOffencePerMember * Double(extra)),
                       apexActionSlots: profile.apexSlots[count - 1])
    }

    private static func stableRemainder(mapSeed: UInt64, triggerID: InstanceID) -> UInt32 {
        let payload = "bookbinder-encounter-scaling-v1|\(mapSeed)|\(triggerID.rawValue)"
        var hash: UInt32 = 2_166_136_261
        for byte in payload.utf8 { hash = (hash ^ UInt32(byte)) &* 16_777_619 }
        return hash
    }
}
