import XCTest
@testable import Bookbinder

/// **Everything authored must be reachable by something writable.**
///
/// The generalisation of the Constellation fossil guard (`fossil-audit.md` §6): a thing that exists
/// in the catalogue and can never occur is a lie the game tells about itself, and grep can't find it
/// because the thing is *there*.
///
/// It also guards a whole class of silent breakage. Every clause, site and creature is gated on
/// absolute readings — "substrate above 58", "illumination below 10" — and those numbers were
/// authored against a scale where four subjects started at zero. Moving the floor to ordinary (7
/// Aug) shifted illumination by 45, substrate by 30, relief by 35 and vitality by 40 in one motion.
/// Nothing would have thrown. Content would just have quietly stopped happening.
final class ReachableContentTests: XCTestCase {

    /// A broad sweep of worlds: every source written against every target it can attach to, at each
    /// intensity, plus pairs, plus the compounds, plus a long tail of rolled worlds.
    private func sampleWorlds() -> [PressureReadings] {
        var out: [PressureReadings] = []
        var id: UInt64 = 0
        func sigil(_ s: PressureSourceID, _ t: PressureTargetID, _ i: Intensity) -> Sigil {
            id += 1
            return Sigil(id: InstanceID(rawValue: id), source: s, target: t, intensity: i)
        }

        let sources = ContentCatalog.shared.pressureSources.sorted { $0.id.rawValue < $1.id.rawValue }

        // One word at a time, at every strength.
        for source in sources {
            for target in source.attachesTo {
                for intensity in Intensity.allCases where intensity != .absent {
                    out.append(PressureRules.resolve([sigil(source.id, target, intensity)]))
                }
            }
        }

        // Two words at a time, at full strength — where the extremes live.
        for a in sources {
            for b in sources where b.id.rawValue > a.id.rawValue {
                guard let ta = a.attachesTo.first, let tb = b.attachesTo.first else { continue }
                out.append(PressureRules.resolve([
                    sigil(a.id, ta, .overwhelming), sigil(b.id, tb, .overwhelming),
                ]))
            }
        }

        // Every compound.
        for symbol in ContentCatalog.shared.symbols {
            out.append(PressureRules.resolve(BookRules.sigils(of: symbol)))
        }

        // And a tail of worlds nobody wrote, which is most of them.
        for seed in UInt64(1)...300 {
            out.append(PressureRules.resolve([], fillingUnwrittenWith: seed))
        }
        return out
    }

    // MARK: Descriptions

    /// A clause the world can never satisfy is a sentence the game will never say.
    func testEveryDescriptionClauseCanBeSaid() {
        let worlds = sampleWorlds()
        var said: Set<String> = []
        for world in worlds {
            for clause in DescriptionRules.describe(world, contradictions: []).clauses {
                said.insert(clause.id)
            }
        }
        let never = ContentCatalog.shared.descriptionClauses
            .map(\.id).filter { !said.contains($0) }.sorted()
        XCTAssertTrue(never.isEmpty, "clauses no world can ever say: \(never.joined(separator: ", "))")
    }

    /// …and one that fires for *every* world says nothing at all. Exempted: the per-group fallbacks,
    /// whose whole job is to have something to say when nothing else applies.
    func testNoDescriptionClauseFiresForEveryWorld() {
        let worlds = sampleWorlds()
        var count: [String: Int] = [:]
        for world in worlds {
            for clause in DescriptionRules.describe(world, contradictions: []).clauses {
                count[clause.id, default: 0] += 1
            }
        }
        let fallbacks = Set(ContentCatalog.shared.descriptionClauses
            .filter { $0.conditions.isEmpty }.map(\.id))
        for (id, fired) in count where !fallbacks.contains(id) {
            XCTAssertLessThan(fired, worlds.count,
                              "'\(id)' is true of every world, so it distinguishes nothing")
        }
    }

    // MARK: Sites

    func testEverySiteCanOccurSomewhere() {
        let worlds = sampleWorlds()
        // Some sites are gated on the world having *argued with itself*, so the sample has to carry
        // a contradiction as well as a set of readings.
        let named = Array(ContentCatalog.shared.contradictions.prefix(1))
        var possible: Set<SiteID> = []
        for world in worlds {
            for site in ContentCatalog.shared.sites where site.isEligible(in: world, contradictions: named) {
                possible.insert(site.id)
            }
        }
        let never = ContentCatalog.shared.sites
            .map(\.id).filter { !possible.contains($0) }
            .map(\.rawValue).sorted()
        XCTAssertTrue(never.isEmpty, "sites no world can host: \(never.joined(separator: ", "))")
    }

    // MARK: Creatures and resources

    func testEveryCreatureCanLiveSomewhere() {
        let worlds = sampleWorlds()
        var possible: Set<CreatureID> = []
        for world in worlds {
            for creature in ContentCatalog.shared.creatures where creature.affinity(in: world) > 0 {
                possible.insert(creature.id)
            }
        }
        let never = ContentCatalog.shared.creatures
            .map(\.id).filter { !possible.contains($0) }
            .map(\.rawValue).sorted()
        XCTAssertTrue(never.isEmpty, "creatures with nowhere to live: \(never.joined(separator: ", "))")
    }

    func testEveryResourceCanBeFoundSomewhere() {
        let worlds = sampleWorlds()
        var possible: Set<ResourceID> = []
        for world in worlds {
            for resource in ContentCatalog.shared.resources where resource.abundance(in: world) > 0 {
                possible.insert(resource.id)
            }
        }
        let never = ContentCatalog.shared.resources
            .filter { !$0.isRealityCurrency }
            .map(\.id).filter { !possible.contains($0) }
            .map(\.rawValue).sorted()
        XCTAssertTrue(never.isEmpty, "resources no world yields: \(never.joined(separator: ", "))")
    }

    func testIsoldePhaseHasWritableWorldRoutesForEveryBrushMaterial() {
        var state = GameState.newGame()
        state.reality.library.foundTravellers.insert("isolde")
        let writable = ContentCatalog.shared.symbols.filter {
            state.base.ownedSymbols.contains($0.id)
        }
        XCTAssertFalse(writable.isEmpty)

        var routed: Set<ResourceID> = []
        for symbol in writable {
            let sigils = BookRules.sigils(of: symbol)
            for seed in UInt64(1)...64 {
                let readings = PressureRules.resolve(sigils, fillingUnwrittenWith: seed)
                for resource in ContentCatalog.shared.resources
                where resource.abundance(in: readings) > 0 {
                    routed.insert(resource.id)
                }
            }
        }

        let brushMaterials: Set<ResourceID> = ["copper", "fiber", "timber"]
        XCTAssertEqual(routed.intersection(brushMaterials), brushMaterials,
                       "the Isolde-phase writable vocabulary must route every Brush material")
    }

    // MARK: Contradictions

    func testEveryContradictionCanFire() {
        var fired: Set<ContradictionID> = []
        var id: UInt64 = 0
        func sigil(_ s: PressureSourceID, _ t: PressureTargetID, _ i: Intensity,
                   negating: Set<PressureTargetID> = []) -> Sigil {
            id += 1
            return Sigil(id: InstanceID(rawValue: id), source: s, target: t, intensity: i,
                         negatedTargets: negating)
        }
        let sources = ContentCatalog.shared.pressureSources.sorted { $0.id.rawValue < $1.id.rawValue }

        // Opposed pairs, and denials — the two shapes a contradiction has.
        for a in sources {
            for b in sources where b.id.rawValue > a.id.rawValue {
                guard let ta = a.attachesTo.first, let tb = b.attachesTo.first else { continue }
                let page = [sigil(a.id, ta, .overwhelming), sigil(b.id, tb, .overwhelming)]
                for c in ContradictionRules.fired(in: page) { fired.insert(c.id) }
            }
            for target in a.attachesTo {
                for denied in ContentCatalog.shared.pressureTargets.map(\.id) {
                    let page = [sigil(a.id, target, .overwhelming, negating: [denied])]
                    for c in ContradictionRules.fired(in: page) { fired.insert(c.id) }
                }
            }
        }

        let never = ContentCatalog.shared.contradictions
            .filter(\.enabled)
            .map(\.id).filter { !fired.contains($0) }
            .map(\.rawValue).sorted()
        XCTAssertTrue(never.isEmpty, "contradictions nothing can trigger: \(never.joined(separator: ", "))")
    }

    // MARK: Conditions

    /// **A condition that can never hold is a rule that does nothing**, and it is invisible: the
    /// content it gates still occurs, just never for the reason it claims. Ichor preferred worlds
    /// with an `unexplained` light tag that nothing has ever produced.
    ///
    /// This is the measurement that found it, kept as a test — the same move as the Constellation
    /// guard, applied to every gate in the catalogue rather than to one of them.
    func testEveryAuthoredConditionCanHoldSomewhere() {
        let worlds = sampleWorlds()
        var dead: [String] = []
        func check(_ label: String, _ conditions: [(String, PressureCondition)]) {
            for (owner, condition) in conditions where !worlds.contains(where: { condition.holds(in: $0) }) {
                dead.append("\(label) \(owner): \(condition)")
            }
        }
        check("creature", ContentCatalog.shared.creatures.flatMap { c in
            (c.requires + c.favours).map { (c.id.rawValue, $0) } })
        check("resource", ContentCatalog.shared.resources.flatMap { r in
            (r.requires + r.favours).map { (r.id.rawValue, $0) } })
        check("site", ContentCatalog.shared.sites.flatMap { s in
            s.conditions.map { (s.id.rawValue, $0) } })
        check("clause", ContentCatalog.shared.descriptionClauses.flatMap { c in
            c.conditions.map { (c.id, $0) } })

        XCTAssertTrue(dead.isEmpty, "conditions no world can satisfy:\n" + dead.joined(separator: "\n"))
    }

    // MARK: Travellers

    /// **A signature clue has to discriminate.** Both directions matter and the guard above only
    /// caught one of them: a clue nothing satisfies hides a person forever, and a clue *everything*
    /// satisfies is not a clue at all — it just means the search loop hands them to you.
    ///
    /// This is the case that got past me twice. Isolde's threshold was `substrate ≥ 30` while
    /// substrate's ordinary value is exactly 30, so "there is something in the rock that holds a
    /// light" was true of any world with ordinary rock in it, and she turned up in two thirds of
    /// blank books. I set that number when substrate started at zero; moving the floor emptied it
    /// without touching the file.
    func testEverySignatureClueTellsWorldsApart() {
        var worlds: [PressureReadings] = []
        for seed in UInt64(1)...400 {
            worlds.append(BookRules.readings(for: BookRules.resolveBook(page: Page()), seed: seed))
        }
        for traveller in ContentCatalog.shared.travellers {
            for clue in traveller.signature {
                let hits = worlds.count { clue.condition.holds(in: $0) }
                let share = Double(hits) / Double(worlds.count)
                XCTAssertGreaterThan(share, 0.01,
                    "\(traveller.id.rawValue): '\(clue.passage)' is true of almost nothing, so they can't be found")
                XCTAssertLessThan(share, 0.85,
                    "\(traveller.id.rawValue): '\(clue.passage)' is true of \(Int(share * 100))% of worlds, "
                    + "so it isn't a clue — check it against the subject's ordinary value")
            }
        }
    }

    /// Accidental matches should remain uncommon, while early travellers must still be
    /// discoverable before the player has access to the broader authored vocabulary.
    func testTravellerAccidentalMatchRateFitsCampaignPhase() {
        var worlds: [PressureReadings] = []
        for seed in UInt64(1)...400 {
            worlds.append(BookRules.readings(for: BookRules.resolveBook(page: Page()), seed: seed))
        }
        for traveller in ContentCatalog.shared.travellers {
            let hits = worlds.count { traveller.isFound(in: $0) }
            let share = Double(hits) / Double(worlds.count)
            XCTAssertLessThan(share, 0.4,
                "\(traveller.name) is standing in \(Int(share * 100))% of blank books — that isn't a search")

            let minimumAccidentalShare: Double
            switch traveller.campaignPhase {
            case .opening:
                minimumAccidentalShare = 0.02
            case .earlyMid, .startOfMid:
                minimumAccidentalShare = 0.005
            case .mid:
                minimumAccidentalShare = 0.001
            case .midLate, .late, .endgame, nil:
                // Later hunts may require deliberate writing. Joint reachability is validated
                // separately; a mandatory blank-book accident would make the clue system a lie.
                minimumAccidentalShare = 0
            }
            let percentage = String(format: "%.2f", share * 100)
            let phase = traveller.campaignPhase?.rawValue ?? "unphased"
            XCTAssertGreaterThanOrEqual(share, minimumAccidentalShare,
                "\(traveller.name) turns up in \(percentage)% of blank books — "
                + "that may be a wall for a \(phase) traveller")
        }
    }
}
