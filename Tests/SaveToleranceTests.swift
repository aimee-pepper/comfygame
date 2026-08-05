import XCTest
@testable import Bookbinder

/// Two ways a save can betray the interruptibility pillar, both of which have already happened.
///
/// A save that won't load — or that loads *quietly wrong* — is the worst bug this project can ship,
/// because it's the one failure the player can't recover from by playing more carefully.
@MainActor
final class SaveToleranceTests: XCTestCase {

    /// **Decoder drift.** Several layer structs have hand-written `init(from:)` for tolerance.
    /// Encoding stays synthesised, so adding a stored property writes a field that the decoder
    /// then ignores — the value is on disk, and it comes back empty. Silent, and invisible until
    /// someone notices their Storehouse forgot something.
    ///
    /// Round-tripping a fully-populated save catches it: whatever went in must come back out.
    func testAFullSaveSurvivesARoundTripUnchanged() throws {
        let original = makePopulatedState()
        let reloaded = try SaveCodec.decode(try SaveCodec.encode(original))

        // Compared layer by layer, so a failure names which one drifted rather than printing the
        // entire save twice.
        XCTAssertEqual(reloaded.base, original.base, "Base layer lost something in the round trip")
        XCTAssertEqual(reloaded.reality, original.reality, "Reality layer lost something")
        XCTAssertEqual(reloaded.worlds, original.worlds, "Worlds layer lost something")
    }

    /// The specific field that drifted, called out so the failure reads as a sentence.
    func testTheStorehouseSpilloverSurvivesARoundTrip() throws {
        var state = makePopulatedState()
        state.base.spillover = [ItemStack(id: InstanceID(rawValue: 41),
                                          catalogID: ItemID(rawValue: "cache_key"))]
        let reloaded = try SaveCodec.decode(try SaveCodec.encode(state))
        XCTAssertEqual(reloaded.base.spillover.map(\.id), state.base.spillover.map(\.id))
    }

    /// **Strict decoding.** `Migrations.swift` promises that adding a field never breaks an old
    /// save. A struct using synthesised `Codable` *throws* when a field is missing rather than
    /// defaulting, so the first field added to it quarantines every save written before it.
    ///
    /// This is checked on the fields added since the last release rather than on all of them:
    /// `map.width` has no sensible default and a save without it is corrupt, not old.
    func testASaveWrittenBeforeTonightStillLoads() throws {
        let data = try SaveCodec.encode(makePopulatedState())
        let root = try XCTUnwrap(try JSONSerialization.jsonObject(with: data) as? [String: Any])

        // Every field added while sites and the spillover were built. Each stands in for the shape
        // of a save written before it existed.
        let recentlyAdded = [
            ["base", "spillover"],
            ["worlds", "activeRun", "sites"]
        ]

        for path in recentlyAdded {
            let pruned = try JSONSerialization.data(withJSONObject: removing(path, from: root))
            let reloaded = try SaveCodec.decode(pruned)
            XCTAssertNotNil(reloaded.worlds.activeRun,
                            "a save without '\(path.joined(separator: "."))' lost its in-progress world")
        }
    }

    /// A tripwire, not a rule.
    ///
    /// Some fields genuinely can't go missing — a map with no `tiles` is corrupt, not old, and
    /// there's no honest default for it. But most *can*, and the ones that can't are exactly the
    /// structs where adding a field next to them will quarantine somebody's save.
    ///
    /// So this pins the current set. If it shrinks, lovely. If it **grows**, someone added a field
    /// to a struct that decodes strictly, and this fails while that's still cheap to fix — which is
    /// the failure mode that has already cost us twice.
    func testTheSetOfLoadBearingFieldsHasNotGrown() throws {
        let data = try SaveCodec.encode(makePopulatedState())
        let root = try XCTUnwrap(try JSONSerialization.jsonObject(with: data) as? [String: Any])

        var failures: [String] = []
        var checked = 0
        for path in collectionPaths(in: root) {
            checked += 1
            let pruned = try JSONSerialization.data(withJSONObject: removing(path, from: root))
            if (try? SaveCodec.decode(pruned)) == nil { failures.append(path.joined(separator: ".")) }
        }

        // Known strict. Each is genuinely required — a map without tiles isn't an old map, it's a
        // broken one — or belongs to a struct nobody has extended yet.
        //
        // **Do not add a field here to make this test pass.** `reality.discovery.*` was on this
        // list for exactly one commit, and in that commit it ate a real save on a real phone: the
        // entry was added the same night the field was, so the tripwire reported the bug and got
        // filed as a known quantity instead of fixed. If a *newly added* field shows up in this
        // failure, that is the test working. Give its struct a tolerant decoder.
        let known: Set<String> = [
            "base.bookDraft.slots",
            "base.inventory.stacks",
            "base.resources.amounts",
            "worlds.activeRun.book",
            "worlds.activeRun.book.randomlyFilled",
            "worlds.activeRun.book.symbols",
            "worlds.activeRun.map",
            "worlds.activeRun.map.entry",
            "worlds.activeRun.map.tiles",
            "worlds.activeRun.playerPosition",
            "worlds.activeRun.rng",
            "worlds.activeRun.satchel.amounts",
            "worlds.activeRun.satchelItems.stacks"
        ]

        XCTAssertGreaterThan(checked, 8, "the walk isn't finding the save's collections")
        let added = Set(failures).subtracting(known)
        XCTAssertTrue(added.isEmpty, """
            new load-bearing fields. Whichever struct owns one needs a tolerant decoder \
            (`decodeIfPresent` + default) before the next field lands next to it, or the first save \
            written without it is quarantined on launch:
            \(added.sorted().joined(separator: "\n"))
            """)
    }

    /// A real save, off a real phone, written the night before sites existed.
    ///
    /// The synthetic tests above all build their fixture with *today's* code, so they can only ever
    /// prove that today's saves round-trip. This one is the actual file that got quarantined —
    /// keeping it means the regression can't come back quietly, and it's a template for every
    /// future schema change: keep a real save from before it.
    func testLastNightsRealSaveStillLoads() throws {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appending(path: "Fixtures/save-pre-sites-2026-08-04.json")
        let state = try SaveCodec.decode(try Data(contentsOf: url))

        // Spot-check each layer, so a partial decode can't pass as a success.
        XCTAssertEqual(state.base.essence, 87)
        XCTAssertEqual(state.base.resources[Resources.ore], 81)
        XCTAssertEqual(state.base.resources[Resources.fiber], 30)
        XCTAssertEqual(state.base.ownedSymbols.count, 12)
        XCTAssertEqual(state.base.completedResearch.count, 3)
        XCTAssertEqual(state.base.inventory.stacks.count, 8)
        XCTAssertEqual(state.reality.lifetime.encountersWon, 19)
        XCTAssertEqual(state.reality.lifetime.worldTurnsTaken, 414)
        XCTAssertEqual(state.worlds.runIndex, 6)

        // Fields that didn't exist when it was written come back empty rather than throwing.
        XCTAssertTrue(state.reality.discovery.sites.isEmpty)
        XCTAssertTrue(state.base.spillover.isEmpty)
    }

    // MARK: Helpers

    /// A save with something in every layer, including an in-progress run — the case that actually
    /// bit, since losing the world someone is standing in is worse than losing a resource count.
    private func makePopulatedState() -> GameState {
        let store = GameStore(io: .temporary(name: "tolerance-\(UUID().uuidString)"))
        // Pinned: a new game roots its seed sequence in real entropy, and this test walks whatever
        // the world happens to contain. Without a fixed seed the *shape* of the save varies run to
        // run and the tripwire below reports a different set each time.
        store.mutate("test: pin the seed") { state in
            state.worlds.seeds = SeedSequence(rootSeed: 20_260_805)
        }
        store.mutate("test: populate") { state in
            state.base.essence = 120
            state.base.resources.add(7, of: Resources.ore)
            state.base.inventory.add(ItemStack(id: InstanceID(rawValue: 1),
                                               catalogID: ItemID(rawValue: "curio_humming_shard")))
            state.base.spillover = [ItemStack(id: InstanceID(rawValue: 2),
                                              catalogID: ItemID(rawValue: "cache_key"))]
            state.reality.motes = 3
        }
        // Fully specified, so the book is the same every run and nothing is left to chance.
        store.setSymbol("caverns", in: "terrain")
        store.setSymbol("frostbound", in: "biome")
        store.setSymbol("common_ore", in: "bounty")
        store.setSymbol("dim_sky", in: "quirk")
        store.bindAndDepart()
        store.mutate("test: populate the run") { state in
            state.worlds.activeRun?.satchel.add(4, of: Resources.fiber)
            state.worlds.activeRun?.turnsTaken = 6
        }
        return store.state
    }

    /// Paths to every array and dictionary-shaped field in the tree.
    private func collectionPaths(in object: [String: Any], prefix: [String] = []) -> [[String]] {
        object.keys.sorted().flatMap { key -> [[String]] in
            let path = prefix + [key]
            switch object[key] {
            case is [Any]:
                return [path]
            case let nested as [String: Any]:
                // A nested object is either a struct (descend) or a dictionary field (a
                // collection in its own right). Descending covers both usefully.
                return [path] + collectionPaths(in: nested, prefix: path)
            default:
                return []
            }
        }
    }

    /// The tree with one field removed.
    private func removing(_ path: [String], from object: [String: Any]) -> [String: Any] {
        guard let key = path.first else { return object }
        var copy = object
        guard path.count > 1 else {
            copy.removeValue(forKey: key)
            return copy
        }
        if let nested = copy[key] as? [String: Any] {
            copy[key] = removing(Array(path.dropFirst()), from: nested)
        }
        return copy
    }
}
