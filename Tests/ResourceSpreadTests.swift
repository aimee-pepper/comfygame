import XCTest
@testable import Bookbinder

/// **A resource is a reason to write one world rather than another** (resources-skills-spec §1).
///
/// With four of them every world handed you the same handful of things, so the authoring system —
/// the actual game — had nothing to aim at. These tests defend the property that makes twenty-one
/// worth having: that what a world *is* decides what it pays.
final class ResourceSpreadTests: XCTestCase {

    private func yields(_ readings: PressureReadings) -> [ResourceID] {
        BookRules.yieldTable(from: readings).map(\.value)
    }

    /// A world written from a blank page, so the seed does the composing.
    private func rolled(_ seed: UInt64) -> PressureReadings {
        BookRules.readings(for: BookRules.resolveBook(page: Page()), seed: seed)
    }

    /// Nothing is universally available. A resource that appears in every world is a resource that
    /// gives you no reason to write anything in particular.
    func testNoResourceComesFromEverywhere() {
        let empty = PressureReadings(readings: [:])
        let common = Set(yields(empty))
        XCTAssertLessThan(common.count, ContentCatalog.shared.resources.count / 2,
                          "a blank world pays out most of the catalogue")
    }

    /// And the opposite failure: a world that is genuinely nothing still can't be a dead end.
    func testEveryWorldPaysSomething() throws {
        var seeds = SeedSequence(rootSeed: 12345)
        for _ in 0..<40 {
            XCTAssertFalse(yields(rolled(seeds.nextSeed())).isEmpty,
                           "a world that pays nothing at all is a wasted book")
        }
    }

    /// Every resource has to be reachable — one nobody can ever write for is dead content.
    func testEveryResourceIsReachableBySomeWorld() {
        var unreachable = Set(ContentCatalog.shared.resources.map(\.id))
        var seeds = SeedSequence(rootSeed: 99)
        // Motes are banked separately; Raw Essence is an independently placed wild drop. Neither
        // is allowed to consume an ordinary harvest-node draw.
        unreachable.remove(Resources.mote)
        unreachable.remove(Resources.essenceRaw)
        for _ in 0..<400 {
            for id in yields(rolled(seeds.nextSeed())) { unreachable.remove(id) }
        }
        XCTAssertTrue(unreachable.isEmpty,
                      "no world in four hundred paid: \(unreachable.map(\.rawValue).sorted())")
    }

    /// **What you write is what you get.**
    ///
    /// This is the whole claim the expanded catalogue rests on: a resource is a reason to write one
    /// world rather than another. Two books, the same two hundred seeds — one asking for life, one
    /// for a frozen ash-fall — and what they pay has to differ.
    func testWhatYouWriteDecidesWhatTheWorldPays() throws {
        let lively = BoundBook(symbols: ["terrain": "plains", "biome": "verdant",
                                         "bounty": "teeming_life"],
                               randomlyFilled: [], essencePaid: 0)
        let dead = BoundBook(symbols: ["terrain": "caverns", "biome": "frostbound",
                                       "bounty": "rich_ore"],
                             randomlyFilled: [], essencePaid: 0)

        var grew = 0, mined = 0, grewOnDead = 0
        var seeds = SeedSequence(rootSeed: 4242)
        for _ in 0..<200 {
            let seed = seeds.nextSeed()
            if yields(BookRules.readings(for: lively, seed: seed)).contains(Resources.fiber) { grew += 1 }
            if yields(BookRules.readings(for: dead, seed: seed)).contains(Resources.ore) { mined += 1 }
            if yields(BookRules.readings(for: dead, seed: seed)).contains(Resources.fiber) { grewOnDead += 1 }
        }
        XCTAssertGreaterThan(mined, 150, "a world written for ore didn't reliably hold any")
        XCTAssertGreaterThan(grew, grewOnDead,
                             "writing for life made no difference to what the world grew")
        // Deliberately loose on the life side. A book that asks for life outright still only grows
        // anything about 60% of the time, because `teeming_life` expands to one producer and two
        // *consumers* whose negative peaks cancel most of it — measured, written up as Q38, and not
        // something to fix by quietly retuning the designer's vocabulary.
        XCTAssertGreaterThan(grew, 100, "a world written for life almost never grew anything")
    }

    /// Why a world written for life comes out sterile — which cap is doing it.
    func testReportWhyLifeIsThin() {
        let lively = BoundBook(symbols: ["terrain": "plains", "biome": "verdant",
                                         "bounty": "teeming_life"],
                               randomlyFilled: [], essencePaid: 0)
        var seeds = SeedSequence(rootSeed: 4242)
        var uncapped: [Int] = [], capped: [Int] = [], water: [Int] = [], light: [Int] = []
        var waterLimited = 0, lightLimited = 0
        for _ in 0..<200 {
            let seed = seeds.nextSeed()
            let raw = PressureRules.resolveUnconstrained(
                BookRules.sigils(for: lively)
                + PressureRules.rollUnwritten(after: BookRules.sigils(for: lively), seed: seed))
            let done = BookRules.readings(for: lively, seed: seed)
            uncapped.append(Int(raw["vitality"].peak))
            capped.append(Int(done["vitality"].peak))
            water.append(Int(done["hydrology"].availableMagnitude))
            light.append(Int(done["illumination"].peak))
            if done["vitality"].has("water-limited") { waterLimited += 1 }
            if done["vitality"].has("light-limited") { lightLimited += 1 }
        }
        func med(_ a: [Int]) -> Int { a.sorted()[a.count / 2] }
        let dead = (0..<200).filter { capped[$0] < 3 }
        print("of the \(dead.count) sterile: median water \(dead.isEmpty ? -1 : med(dead.map { water[$0] })), median light \(dead.isEmpty ? -1 : med(dead.map { light[$0] })), median uncapped life \(dead.isEmpty ? -1 : med(dead.map { uncapped[$0] }))")
        print("""
        LIFE PROBE over 200 seeds, book = plains + verdant + teeming_life
          vitality before caps : median \(med(uncapped))  max \(uncapped.max()!)
          vitality after  caps : median \(med(capped))   below 3: \(capped.filter { $0 < 3 }.count)
          water available      : median \(med(water))
          illumination peak    : median \(med(light))
          water-limited \(waterLimited)   light-limited \(lightLimited)
        """)
    }

    /// **A world written for life has to be crawling with it.**
    ///
    /// Aimee, 6 Aug: *"a world with verdant and teeming life should be crawling with flora and
    /// fauna. effectively sterile shouldn't be anything near that."* It was: a book saying
    /// *plains + verdant + teeming life* came out effectively sterile 40% of the time, and even
    /// when it didn't it held about as many animals as an ash-choked cavern.
    ///
    /// Three separate things were doing it, and this test guards all three: light was a hard cap
    /// rather than a change of metabolism, usable water went to zero the moment a world froze, and
    /// the population term was measured against a vitality of 100 that nothing ever reaches.
    func testAWorldWrittenForLifeIsCrawlingWithIt() {
        let lively = BoundBook(symbols: ["terrain": "plains", "biome": "verdant",
                                         "bounty": "teeming_life"],
                               randomlyFilled: [], essencePaid: 0)
        // **The foil is a world written dead**, not merely one written dim. Since writing starts at
        // an ordinary world rather than at nothing, *caverns and ash* is a dusty, lightless place
        // that still holds a little of what an ordinary world holds — sterility has to be asked for,
        // with the suppressing focuses, and asking for it earns stability back (Aimee, 7 Aug).
        let barren = BoundBook(written: [], composition: [
            Sigil(id: InstanceID(rawValue: 1), source: "salt", target: "vitality", intensity: .great),
            Sigil(id: InstanceID(rawValue: 2), source: "wildfire", target: "vitality", intensity: .great),
        ], essencePaid: 0)

        var seeds = SeedSequence(rootSeed: 31337)
        var sterile = 0, livingAnimals = 0, deadAnimals = 0, livingSpecies = 0
        let runs = 80
        for _ in 0..<runs {
            let seed = seeds.nextSeed()
            if BookRules.readings(for: lively, seed: seed)["vitality"].peak < 3 { sterile += 1 }
            let alive = Worldgen.generate(book: lively, seed: seed, library: LibraryState())
            let dead = Worldgen.generate(book: barren, seed: seed, library: LibraryState())
            livingAnimals += alive.enemies.count
            livingSpecies += alive.cast.count
            deadAnimals += dead.enemies.count
        }
        XCTAssertLessThan(sterile, runs / 8,
                          "a book asking outright for life still came out sterile \(sterile)/\(runs)")
        XCTAssertGreaterThan(livingAnimals, deadAnimals * 3,
                             "a written-for-life world held no more than a salt flat")
        // And asking for less than a world ordinarily holds has to *calm* it, which is the other
        // half of the two-axis model and the reason a barren world is worth writing at all.
        XCTAssertGreaterThan(BookRules.stabilityScore(of: barren), 100 - 1,
                             "writing a world empty should have given stability back")
        XCTAssertGreaterThan(livingSpecies, runs * 3,
                             "a written-for-life world averaged under three species")
    }

    /// What a world written for life actually *has standing in it* — the number Aimee is asking
    /// about is not vitality, it's how much wildlife you meet.
    func testReportWhatALivingWorldHolds() {
        let lively = BoundBook(symbols: ["terrain": "plains", "biome": "verdant",
                                         "bounty": "teeming_life"],
                               randomlyFilled: [], essencePaid: 0)
        var seeds = SeedSequence(rootSeed: 808)
        var species: [Int] = [], animals: [Int] = [], budgets: [Int] = []
        for _ in 0..<60 {
            let world = Worldgen.generate(book: lively, seed: seeds.nextSeed(),
                                          library: LibraryState())
            species.append(world.cast.count)
            animals.append(world.enemies.count)
            budgets.append(Int(WorldConstraints.energyBudget(
                in: BookRules.readings(for: lively, seed: 0))))
        }
        var deadSeeds = SeedSequence(rootSeed: 808)
        let barren = BoundBook(symbols: ["terrain": "caverns", "biome": "ashen"],
                               randomlyFilled: [], essencePaid: 0)
        var deadAnimals: [Int] = [], deadSpecies: [Int] = []
        for _ in 0..<60 {
            let world = Worldgen.generate(book: barren, seed: deadSeeds.nextSeed(),
                                          library: LibraryState())
            deadAnimals.append(world.enemies.count)
            deadSpecies.append(world.cast.count)
        }
        func med(_ a: [Int]) -> Int { a.sorted()[a.count / 2] }
        print("""
        A DEAD WORLD holds, same 60 seeds of caverns + ashen:
          species: median \(med(deadSpecies))   animals: median \(med(deadAnimals))
        """)
        print("""
        A LIVING WORLD holds, over 60 seeds of plains + verdant + teeming_life:
          species in the cast : median \(med(species))  range \(species.min()!)–\(species.max()!)
          animals on the map  : median \(med(animals))  range \(animals.min()!)–\(animals.max()!)
          empty of animals    : \(animals.filter { $0 == 0 }.count) of 60
        """)
    }

    /// A printout of how often each resource turns up, so a rebalance can be judged rather than
    /// guessed at. Not an assertion — it fails nothing; it tells you what the numbers are.
    func testReportTheSpread() {
        var seeds = SeedSequence(rootSeed: 7)
        var seen: [ResourceID: Int] = [:]
        let worlds = 300
        for _ in 0..<worlds {
            for id in yields(rolled(seeds.nextSeed())) { seen[id, default: 0] += 1 }
        }
        let lines = seen.sorted { $0.value > $1.value }
            .map { "\($0.key.rawValue): \($0.value * 100 / worlds)%" }
        print("resource spread over \(worlds) worlds — " + lines.joined(separator: ", "))
    }

    /// **The exotic ones are gated, not merely favoured.** Mercury is something you go and write
    /// for; if a barren world hands it to you, richness stops meaning anything.
    func testAPoorWorldPaysNothingExotic() {
        let poor = PressureReadings(readings: [
            "substrate": PressureReading(target: "substrate", peak: 6, floor: 0,
                                         opposedMagnitude: 0, aspects: [:], forms: [:], tags: []),
            "vitality": PressureReading(target: "vitality", peak: 4, floor: 0,
                                        opposedMagnitude: 0, aspects: [:], forms: [:], tags: [])
        ])
        let paid = Set(yields(poor))
        for exotic: ResourceID in ["gold", "mercury", "adamant", "rift_glass", "ichor"] {
            XCTAssertFalse(paid.contains(exotic), "a barren world paid out \(exotic.rawValue)")
        }
    }

    // MARK: What grows, versus what merely lives

    /// **A world with a herd and no plants must not yield timber.**
    ///
    /// The six organic resources were driven by vitality's *peak*, which counts herds and swarms —
    /// so a plain full of grazing animals and nothing growing produced fibre, timber, resin and
    /// toxin. Every consumable, binding and haft in the material economy is downstream of that
    /// (`crafting-spec.md` PART FIVE), which is what makes flora a blocker rather than scenery.
    func testAWorldOfAnimalsAndNoPlantsGrowsNothing() {
        // Herds and swarms only: alive, and nothing in it makes anything.
        let grazed = PressureRules.resolve([
            Sigil(id: InstanceID(rawValue: 1), source: "herd", target: "vitality", intensity: .overwhelming),
            Sigil(id: InstanceID(rawValue: 2), source: "swarm", target: "vitality", intensity: .great),
        ])
        XCTAssertGreaterThan(grazed["vitality"].peak, 40, "fixture: this world is supposed to be alive")

        for organic: ResourceID in ["fiber", "timber", "pulp", "resin", "toxin"] {
            let resource = ContentCatalog.shared.resource(organic)
            XCTAssertEqual(resource?.abundance(in: grazed), 0,
                           "\(organic.rawValue) grew in a world with nothing growing in it")
        }
    }

    /// …and a world written for growth yields all of it.
    func testAWorldWrittenForGrowthYieldsWhatGrows() {
        let grown = PressureRules.resolve([
            Sigil(id: InstanceID(rawValue: 1), source: "root", target: "vitality", intensity: .overwhelming),
            Sigil(id: InstanceID(rawValue: 2), source: "bloom", target: "vitality", intensity: .great),
            Sigil(id: InstanceID(rawValue: 3), source: "wildfire", target: "thermal", intensity: .moderate),
        ])
        for organic: ResourceID in ["fiber", "timber", "pulp", "toxin"] {
            let resource = ContentCatalog.shared.resource(organic)
            XCTAssertGreaterThan(resource?.abundance(in: grown) ?? 0, 0,
                                 "\(organic.rawValue) didn't grow in a world written for growing")
        }
    }
}
