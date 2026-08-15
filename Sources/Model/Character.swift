import Foundation

/// What somebody *is*, as opposed to what they're holding.
///
/// `decisions-session-17.md` §1: characters get stats, and it names the gap honestly — a companion
/// was a name, a constant, a rule list and some gear. No level, no stats. That came from one line in
/// the one-evening v0 brief (*"no leveling tonight; power comes from gear/upgrades"*) and quietly
/// became the design.
///
/// **Five stats, each feeding something combat already does**, so both sides of a fight run one
/// system rather than two: a creature's armour and a character's Fortitude arrive at the same
/// `damageTaken`.
struct CharacterStats: Codable, Equatable, Sendable {
    /// Damage, and crush hardest of all.
    var might: Int = Tuning.Character.startingStat
    /// Damage with pierce and rend, and not being where the blow landed.
    var finesse: Int = Tuning.Character.startingStat
    /// Health, how much armour is worth, and how well you shrug off what lingers.
    var fortitude: Int = Tuning.Character.startingStat
    /// How far you see, and whether a cryptic thing gets to open the fight.
    var perception: Int = Tuning.Character.startingStat
    /// **Was Focus** (`vocabulary-settled.md`, 6 Aug): *focus* is the writing word now, and the
    /// stat was the cheaper of the two to rename because it wasn't built yet. Skill potency,
    /// cooldowns, and how long a rule list you can hold.
    var wit: Int = Tuning.Character.startingStat

    init(might: Int = Tuning.Character.startingStat,
         finesse: Int = Tuning.Character.startingStat,
         fortitude: Int = Tuning.Character.startingStat,
         perception: Int = Tuning.Character.startingStat,
         wit: Int = Tuning.Character.startingStat) {
        self.might = might
        self.finesse = finesse
        self.fortitude = fortitude
        self.perception = perception
        self.wit = wit
    }

    /// Tolerant, per the policy in `Migrations.swift`.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let start = Tuning.Character.startingStat
        might = try c.decodeIfPresent(Int.self, forKey: .might) ?? start
        finesse = try c.decodeIfPresent(Int.self, forKey: .finesse) ?? start
        fortitude = try c.decodeIfPresent(Int.self, forKey: .fortitude) ?? start
        perception = try c.decodeIfPresent(Int.self, forKey: .perception) ?? start
        // Reads the old name, so a save written between session 17 landing and the rename keeps
        // whatever it had.
        wit = try c.decodeIfPresent(Int.self, forKey: .wit)
            ?? c.decodeIfPresent(Int.self, forKey: .focus) ?? start
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(might, forKey: .might)
        try c.encode(finesse, forKey: .finesse)
        try c.encode(fortitude, forKey: .fortitude)
        try c.encode(perception, forKey: .perception)
        try c.encode(wit, forKey: .wit)
    }

    /// Includes the retired `focus`, so a save written before the rename still reads.
    private enum CodingKeys: String, CodingKey {
        case might, finesse, fortitude, perception, wit
        case focus
    }

    subscript(stat: Stat) -> Int {
        get {
            switch stat {
            case .might: might
            case .finesse: finesse
            case .fortitude: fortitude
            case .perception: perception
            case .wit: wit
            }
        }
        set {
            switch stat {
            case .might: might = newValue
            case .finesse: finesse = newValue
            case .fortitude: fortitude = newValue
            case .perception: perception = newValue
            case .wit: wit = newValue
            }
        }
    }

    static func + (lhs: CharacterStats, rhs: CharacterStats) -> CharacterStats {
        CharacterStats(might: lhs.might + rhs.might,
                       finesse: lhs.finesse + rhs.finesse,
                       fortitude: lhs.fortitude + rhs.fortitude,
                       perception: lhs.perception + rhs.perception,
                       wit: lhs.wit + rhs.wit)
    }
}

enum Stat: String, Codable, CaseIterable, Sendable {
    case might, finesse, fortitude, perception, wit

    var displayName: String { rawValue.capitalisedSentence }

    /// What it's *for*, in the player's words. Shown beside the number, because a stat you can't
    /// spend is a stat you don't understand.
    var job: String {
        switch self {
        case .might: "Damage, and crushing weapons most of all"
        case .finesse: "Damage with piercing and rending weapons, and being harder to hit"
        case .fortitude: "Health, and how much your armour is worth"
        case .perception: "How far you see, and not being ambushed"
        case .wit: "How hard your skills hit, how fast they come back, and how long a rule list you can hold"
        }
    }

    var icon: String {
        switch self {
        case .might: "figure.strengthtraining.traditional"
        case .finesse: "scissors"
        case .fortitude: "heart.fill"
        case .perception: "eye.fill"
        case .wit: "brain.head.profile"
        }
    }
}

/// A party member's own progression: what they are, how far along, and what they've learned.
///
/// **Nobody dies** (session 17 §6). This holds nothing about death because there isn't any — a
/// companion passes out and is revived at home, and the Binder passing out is treated exactly like
/// a world collapsing.
struct CharacterState: Codable, Equatable, Sendable {
    var stats: CharacterStats = CharacterStats()
    var level: Int = 1
    /// **Earned by fighting *and* by finding** (session 17 §2). A game whose progression is
    /// literacy shouldn't pay only for killing, and it means a careful explorer advances as surely
    /// as a fighter does.
    var experience: Int = 0
    /// Front or back. Front takes the melee and deals it; back is protected and weaker in melee.
    var rank: Rank = .front

    /// **How far into each branch this person has bought**, keyed by branch.
    ///
    /// A depth rather than a set of node ids, because nodes are bought in order — so the depth *is*
    /// the purchase history, an out-of-order state is unrepresentable, and a re-cut branch can't
    /// leave somebody holding a node that no longer exists.
    var branchDepth: [CombatBranchID: Int] = [:]

    /// Stable graph-v2 ownership. `nil` means this character has not yet reconciled a legacy
    /// branch-depth save; an explicit empty set is canonical and must stay empty on relaunch.
    var ownedCombatNodeIDs: Set<CombatNodeID>?
    /// Stable typed selections belonging to purchased nodes. Opening depths currently require no
    /// choice, but persistence lives beside ownership so later typed nodes cannot become indexes.
    var combatNodeChoices: [CombatNodeID: StableChoiceID] = [:]

    /// Points that didn't come from levelling — a calling's starting lean. Kept as a count rather
    /// than baked into `branchDepth` alone, so the budget stays honest and a respec hands them back
    /// rather than quietly deleting them.
    var freePoints: Int = 0

    init(stats: CharacterStats = CharacterStats(), level: Int = 1,
         experience: Int = 0, rank: Rank = .front) {
        self.stats = stats
        self.level = level
        self.experience = experience
        self.rank = rank
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        stats = try c.decodeIfPresent(CharacterStats.self, forKey: .stats) ?? CharacterStats()
        level = try c.decodeIfPresent(Int.self, forKey: .level) ?? 1
        experience = try c.decodeIfPresent(Int.self, forKey: .experience) ?? 0
        rank = try c.decodeIfPresent(Rank.self, forKey: .rank) ?? .front
        branchDepth = try c.decodeIfPresent([CombatBranchID: Int].self, forKey: .branchDepth) ?? [:]
        ownedCombatNodeIDs = try c.decodeIfPresent(Set<CombatNodeID>.self,
                                                    forKey: .ownedCombatNodeIDs)
        combatNodeChoices = try c.decodeIfPresent([CombatNodeID: StableChoiceID].self,
                                                   forKey: .combatNodeChoices) ?? [:]
        freePoints = try c.decodeIfPresent(Int.self, forKey: .freePoints) ?? 0
    }

    /// What the next level costs, and how far along you are.
    var experienceForNextLevel: Int { CharacterRules.experienceForLevel(level + 1) }
    var experienceIntoThisLevel: Int { experience - CharacterRules.experienceForLevel(level) }
    var experienceThisLevelCosts: Int {
        max(1, experienceForNextLevel - CharacterRules.experienceForLevel(level))
    }
}

/// Front or back (session 17 §4, Q34). Standard, and it becomes a real composition decision the
/// moment characters have stats: a fragile high-Wit scholar standing behind a high-Fortitude
/// front-liner is a choice rather than a positional fiddle.
enum Rank: String, Codable, CaseIterable, Sendable {
    case front, back

    var displayName: String { rawValue.capitalisedSentence }
    var blurb: String {
        switch self {
        case .front: "Takes the melee, and deals it in full."
        case .back: "Harder to reach, and weaker at arm's length."
        }
    }
}
