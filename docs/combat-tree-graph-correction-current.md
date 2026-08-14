# Combat trees — current graph design

**Status:** superseded 11 Aug 2026 by `combat-tree-true-graph-current.md`; retained as design history.  
**Owner:** Game Design owns graph/progression; Engineering owns migration/rules/native layout; Asset
owns stable node glyphs and connector grammar.  
**Superseded by:** the five-depth fan/fork graph. This three-lane/eight-rank proposal correctly
rejected the live lists, but two crossover ranks left too much of each lane as a linear ladder.

## Design result

Bookbinder has **three actual combat trees**, not nine lists:

| Tree | Left lane | Centre lane | Right lane |
|---|---|---|---|
| **Offense** | Force | Precision | Swiftness |
| **Defense** | Fortitude | Protection | Evasion |
| **Craft** | Venom | Emanation | Shadow |

Each tree contains its existing 24 nodes in a three-lane, eight-rank prerequisite graph. The lanes
are disciplines, not sealed shopping lists. A player may stay in one lane for a pure specialization
or cross to an adjacent lane at two authored junction ranks for a hybrid route.

One complete route costs eight points. Level 25 still provides 24 standard points: enough for three
capstone routes, conventionally one per tree, without forcing that distribution. Partial and hybrid
investment remains legal. Calling leans remain bonus lived experience above the standard budget.

## Exact graph grammar

Every current node receives a stable semantic ID. Its existing `index` becomes **rank** 1…8 and its
existing branch becomes **lane**.

```text
rank 1       Force root        Precision root        Swiftness root
                 |                   |                    |
rank 2       Force node        Precision node        Swiftness node
                 |                   |                    |
rank 3       Force node        Precision node        Swiftness node
                 | \             /  |  \             /  |
rank 4       Force junction    Precision junction    Swiftness junction
                 |                   |                    |
rank 5       Force node        Precision node        Swiftness node
                 | \             /  |  \             /  |
rank 6       Force junction    Precision junction    Swiftness junction
                 |                   |                    |
rank 7       Force mastery     Precision mastery     Swiftness mastery
                 |                   |                    |
rank 8       Force capstone    Precision capstone    Swiftness capstone
```

The same shape applies to Defense and Craft.

### Prerequisites

- Rank 1 is a root and has no node prerequisite.
- Ranks 2 and 3 require the prior rank in the same lane.
- Rank 4 requires **any one** rank-3 node in the same or an immediately adjacent lane.
- Rank 5 requires rank 4 in the same lane.
- Rank 6 requires **any one** rank-5 node in the same or an immediately adjacent lane.
- Rank 7 requires rank 6 in the same lane.
- Rank 8 requires rank 7 in the same lane **and at least five owned nodes in that capstone's lane**.

There are no left↔right jumps across the centre lane in one edge. A Force route may cross into
Precision, not directly into Swiftness; Fortitude crosses through Protection; Venom crosses through
Emanation. The centre lanes are chosen deliberately because they can meaningfully bridge the two
outer disciplines.

The five-node capstone commitment prevents a player zigzagging through unrelated cheap nodes and
claiming a discipline's defining mastery. It still permits up to three off-lane choices in an
eight-point hybrid route. Limited points—not artificial mutually exclusive locks—create lasting
build difference. Full Spring respec remains the safe way to rebuild.

## The 72-node content

All existing node names, intended effects, skills and capstones remain in their current lane and rank
for the first implementation. `combat-node-viability-current.md` is the authoritative trigger and
composition contract: the live build currently stores many effect fields without consuming them, so
preserving a field alone is not an implemented effect.

### Offense

| Rank | Force | Precision | Swiftness |
|---:|---|---|---|
| 1 | Heavy Hand | Keen Eye | Quick Step |
| 2 | Follow Through | Weak Point | Light Touch |
| 3 | **Overbear** | **Pry** | **Quicken** |
| 4 | Bracing Stance | Steady Hand | Second Wind |
| 5 | Stagger | Exploit | Flurry |
| 6 | **Shatter** | **Finish** | **First Strike** |
| 7 | Momentum | Anatomy | Cascade |
| 8 | **Breaking Blow** | **Killing Stroke** | **Blur** |

Force↔Precision hybrids trade weight against finding/breaking openings. Precision↔Swiftness hybrids
trade deliberate placement against tempo and finishing. Force and Swiftness require Precision as the
bridge; raw weight cannot turn directly into speed without learning control.

### Defense

| Rank | Fortitude | Protection | Evasion |
|---:|---|---|---|
| 1 | Thick Hide | Bulwark | Footwork |
| 2 | Iron Skin | Watchful | Light Frame |
| 3 | **Brace** | **Draw Off** | **Sidestep** |
| 4 | Constitution | Cover | Slippery |
| 5 | Endurance | Shieldwall | **Fall Back** |
| 6 | **Ward** | **Interpose** | Feint |
| 7 | Unyielding | Rally | Untouchable |
| 8 | **Immovable** | **Guardian** | **Ghost** |

Fortitude↔Protection converts personal durability into taking responsibility for others.
Protection↔Evasion turns formation awareness into interception, movement and refusal. Fortitude and
Evasion cannot cross directly because absorbing a hit and avoiding it are the outer opposed answers.

### Craft

| Rank | Venom | Emanation | Shadow |
|---:|---|---|---|
| 1 | Tainted Edge | Sparkhand | Quiet Step |
| 2 | Apothecary's Hand | Insulation | Low Profile |
| 3 | **Envenom** | **Emanation Strike** | **Conceal** |
| 4 | Virulence | Attunement | Opportunist |
| 5 | **Flense** | **Snuff** | **Ambush** |
| 6 | Corrode | Quench | Vanish |
| 7 | Distiller | Conduction | Shadowed |
| 8 | **Blight** | **Emanant** | **Unseen** |

Venom↔Emanation links prepared substances to projected affliction/resistance. Emanation↔Shadow links
light/heat/caustic control to concealment and encounter timing. Venom and Shadow cannot cross directly:
the Emanation lane is the practiced bridge between altering a body and altering what can perceive it.

Bold non-capstone entries grant active techniques. Existing rule effects remain authoritative; this
table changes purchase routes, not combat math.

## Why this is a viable tree rather than decorated lists

- At rank 4 and rank 6, the player chooses among multiple legal next nodes supported by explicit
  prerequisite edges.
- A pure route reaches its lane capstone in eight points; a hybrid route also reaches a capstone in
  eight only if it has made a five-node commitment to that final discipline.
- The same partial spend can lead to different capstones, but not every capstone remains reachable
  from every shallow investment.
- Buying a side node consumes a real scarce point. It is not a cosmetic branch the player eventually
  receives for free.
- Three simultaneous lane columns make build direction and alternatives visible before purchase.
- Respec preserves experimentation without erasing the consequence of point allocation during play.

## Proven build routes

These are examples, not named classes or locked presets. They demonstrate that crossover choices
produce mechanically coherent eight-point builds rather than dead ends. `Lane 1–3` means the first
three ranks of that lane; every following number is the named lane's node at that rank.

| Working identity | Exact eight-point route | What the route does |
|---|---|---|
| **Siegebreaker** | Force 1–3 → Precision 4–5 → Force 6–8 | Keeps Force commitment, borrows critical/status exploitation, then returns for armour breaking |
| **Duelist** | Precision 1–3 → Swiftness 4–5 → Precision 6–8 | Trades early gap-finding into recovery/multi-target tempo, then returns for finishing mastery |
| **Raider** | Swiftness 1–3 → Precision 4–5 → Swiftness 6–8 | Begins with tempo, borrows accurate exploitation, then converts kills into escalating action economy |
| **Sentinel** | Fortitude 1–3 → Protection 4–8 | Turns personal staying power into covering, interception and back-rank guardianship |
| **Skirmisher** | Evasion 1–3 → Protection 4–5 → Evasion 6–8 | Uses awareness and formation briefly, then returns to feints and refusal |
| **Bodyguard** | Protection 1–8 | The pure responsibility route: see danger, draw it, share it, deny it |
| **Saboteur** | Venom 1–3 → Emanation 4–5 → Venom 6–8 | Starts poison, learns attunement/suppression, then returns to corrosion and spreading blight |
| **Nightflame** | Shadow 1–3 → Emanation 4–5 → Shadow 6–8 | Concealment gains projected-damage leverage before returning to escape and encounter control |
| **Conduit** | Emanation 1–8 | The pure projected-affliction route with its own producer, resistance, cure and chain |

Every pure lane remains legal. These hybrids prove the two intended crossover shapes: leave a lane at
rank 4 and commit to the adjacent lane, or borrow ranks 4–5 and return at rank 6. A path that keeps
crossing away from its intended capstone may remain a useful partial build, but the interface must not
pretend the capstone is still reachable within the remaining standard budget.

### No-hidden-trap purchase preview

Selecting any available node shows, before Learn:

- which capstones remain structurally reachable from the resulting owned set;
- the minimum additional points needed for each reachable capstone;
- **Needs more commitment in [lane]** when rank prerequisites are met but the five-node gate is not;
- **Not reachable with your remaining standard points** when applicable, without prohibiting the
  purchase—the player may deliberately make a broad partial build or have calling points available.

This is deterministic graph analysis, not build advice. It does not label a route good/bad or choose
for the player. DEBUG path enumeration uses the same rules authority as the purchase preview, so UI
cannot promise a capstone that the mutation later rejects.

## Durable schema and migration

```text
CombatNodeDef {
  id: CombatNodeID
  tree: CombatTreeID
  lane: CombatBranchID
  rank: 1...8
  column: left | centre | right
  prerequisite: root | all([CombatNodeID]) | any([CombatNodeID])
  capstoneMinimumLaneSpend: Int?
}

CharacterState.ownedCombatNodes: Set<CombatNodeID>
```

- Purchase validates exact stable node ID, prerequisites, lane-spend gate and available point in one
  atomic mutation. Array position never grants ownership.
- `branchDepth` becomes decode-only legacy state. `(lane, depth)` maps to the first `depth` stable IDs
  in that same lane. This always forms a valid pure path and preserves every previous effect/skill.
- Existing traveller leans and generated arrival plans use the same explicit legacy mapping. New
  authored leans/plans name node IDs or validated graph steps rather than mutable depth.
- Generated-person cadence and legacy branch-step migration are authoritative in
  `generated-companion-arrival-builds-current.md`; new plans persist explicit node IDs and validated
  route-template IDs, never “buy next in branch.”
- Spent points derive from the owned-node set. Full Spring respec clears the set and returns standard
  plus calling/free points exactly once.
- A completed specialization is ownership of its capstone. Emergent class names continue to derive
  from capstone lanes; three known capstones produce the existing 27 named combinations, while other
  distributions remain **Adept** until deliberately named.
- Save decoding rejects no healthy legacy build. Unknown future node IDs are retained as tolerant
  inactive records where feasible and surfaced diagnostically rather than aliasing another node.

## Native phone layout

The selected Offense/Defense/Craft tree appears as one graph—not one branch card at a time:

- three fixed lane columns with names and progress at the top;
- eight compact ranks vertically, with real same-lane and crossover connectors behind node buttons;
- 44×44-point node targets with stable glyphs; owned/available/blocked/selected/capstone states use
  shape, fill, line and accessible text rather than color alone;
- tap any node for an edge-clamped anchored detail showing effect, technique, exact prerequisites,
  route/lane commitment and Learn action;
- no full descriptions under every node and no global **Learn next** button;
- the ordinary 368×800 layout fits the complete 3×8 graph by using compact glyph nodes and a concise
  sticky tree header. If actual typography requires minimal vertical scrolling, the whole graph is
  one bounded canvas; it never becomes eight full-width prose rows;
- Dynamic Type uses a topology-preserving accessibility outline grouped by rank with explicit
  “requires X or Y” relationships. This is the one fallback allowed to read vertically, because it
  retains real choice and prerequisites rather than restoring bought-in-order depth.

VoiceOver reads tree → rank → lane → node/effect/state/prerequisite. Connector geometry is not the
only statement of dependency.

## Validation and acceptance

1. Exactly three trees, three unique lanes per tree and eight unique ranks per lane exist; all 72
   stable node IDs are unique.
2. Graph validation rejects cycles, missing/cross-tree prerequisites, illegal outer-lane jumps,
   unreachable nodes and capstones without the five-lane-spend gate.
3. Every rank-4/rank-6 junction exposes the authored same/adjacent choices; unrelated outer jumps are
   impossible and cost nothing.
4. Pure lane paths reach their capstone in exactly eight points. Exhaustive hybrid paths can reach a
   capstone only with at least five nodes in its lane.
5. Every node effect and granted skill passes the scenario-consumer matrix in
   `combat-node-viability-current.md`; no graphical/loadout-only node is treated as functional.
6. Every legacy lane/depth 0…8 migrates to identical bought effects, skills, spent/unspent points and
   completed-capstone/class result. Round-trip is idempotent.
7. Calling leans, generated people, respec and max-level/free-point budgets survive migration without
   duplicate or lost ownership.
8. A 368×800 color/grayscale proof shows all three lanes, crossover edges, all eight ranks, selected
   detail and a reachable capstone without prose-row presentation or clipped targets.
9. VoiceOver can discover every available route and exact prerequisite without interpreting lines.
10. DEBUG path enumeration reports pure/hybrid capstone reach, first/second technique timing and
    capstone timing for all three trees before the version becomes the new-save default.
11. The nine proven routes above purchase in order with eight points each and yield the stated final
    capstone; exhaustive analysis reports no capstone as reachable when its minimum cost exceeds the
    character's remaining standard plus free points.

## Tuning boundary

The topology, stable IDs, junction ranks 4/6, adjacent-only crossover, five-node capstone commitment,
eight-point path and lossless migration are current design. Node numeric effects, cooldowns, XP curve
and individual node rank may be tuned after simulation/device play, but moving a node requires a
versioned graph migration and cannot silently reinterpret an existing owned ID.
