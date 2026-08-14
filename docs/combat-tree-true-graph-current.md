# Combat trees — true branching graph

**Status:** current Game Design authority; implementation-ready topology and node placement.
**Owner:** Game Design. Engineering owns schema/rules/migration and functional connector/state
rendering; Aimee owns final node/technique glyph art. AssetLab owns placeholder layout,
accessibility and conformance only, per `handmade-art-ownership-current.md`.
**Supersedes:** `combat-tree-graph-correction-current.md`. The prior three-column/eight-rank lattice
was an improvement in presentation, but remained three mostly linear ladders and did not create
enough build decisions.

**Machine-readable authority:** `combat-tree-v2-authority.json`. The JSON and this document must
change together; Asset and Engineering consume/validate the JSON rather than retyping topology.

**11 August implementation-readiness audit:** the generated authority contains all 72 unique stable
nodes, the true-graph and glyph contracts pass, and exhaustive legal-route enumeration finds 79
Offense, 67 Defense and 66 Craft eight-point capstone routes. Every capstone has at least 13 legal
routes; the larger centre-discipline counts are intentional because Precision, Protection and
Emanation are the authored bridges. No tutorial overlay is part of this gate.

## Design decision

Each of the three combat trees is a five-depth directed graph containing 24 nodes:

```text
depth 1       three discipline roots                         3 nodes
                         /       \
depth 2       two fundamentals per discipline                6 nodes
                         \       /
depth 3       two developments per discipline                6 nodes
                         /       \
depth 4       two masteries per discipline                   6 nodes
                         \       /
depth 5       three discipline capstones                     3 nodes
```

The complete tree is shown simultaneously. A discipline is a region of the graph, not a tab or a
list. Every root opens two genuinely different next purchases. Later nodes preserve those internal
forks and also admit specific adjacent-discipline hybrid parents. A player therefore chooses both
**what kind of fighter this person becomes** and **which route they take to get there**.

The three trees and their adjacent discipline order are:

| Tree | Left | Centre | Right |
|---|---|---|---|
| Offense | Force | Precision | Swiftness |
| Defense | Fortitude | Protection | Evasion |
| Craft | Venom | Emanation | Shadow |

Left and right never connect directly. Hybrid study passes through the centre discipline.

## Node placement

The 72 existing concepts are retained, but their former 1–8 order is now placement, not a purchase
ladder. Within each discipline:

| Graph role | Former node | Meaning |
|---|---:|---|
| Root | 1 | discipline identity; always functions without special equipment where possible |
| Fundamental A | 2 | passive/system-facing foundation |
| Fundamental B | 3 | usually the first active technique; exact node metadata owns this |
| Development A | 4 | reliable scaling or stance |
| Development B | 5 | conditional payoff or second tactical direction, sometimes a technique |
| Mastery A | 6 | second technique or deliberate utility in most disciplines |
| Mastery B | 7 | high-investment passive/system payoff |
| Capstone | 8 | encounter-defining discipline result |

This makes each discipline's first active technique reachable with two points, while the other
fundamental remains a meaningful alternative rather than a toll. A person can return for it later.
`grantsTechnique` is explicit per stable node and is never inferred from graph role. In particular,
Fall Back, Flense and Ambush are Development-B techniques, Corrode is not a technique merely because
it occupies Venom Mastery A, and Quench is a targeted technique even though its older content row did
not mark it consistently.

## Exact prerequisite grammar

Every node has a stable ID. For a lane `L`, `left(L)` and `right(L)` mean only an existing adjacent
lane in the same tree.

1. `L.root` has no node prerequisite.
2. `L.fundamentalA` and `L.fundamentalB` each require `L.root`.
3. `L.developmentA` requires either `L.fundamentalA`, or the adjacent lane's
   `fundamentalB` named in the authored hybrid table below.
4. `L.developmentB` requires either `L.fundamentalB`, or the adjacent lane's
   `fundamentalA` named below.
5. `L.masteryA` requires `L.developmentA` **or** its authored adjacent development parent.
6. `L.masteryB` requires `L.developmentB` **or** its authored adjacent development parent.
7. A capstone requires:
   - either mastery in its own discipline as a visible structural parent;
   - its own root;
   - at least one fundamental, one development and one mastery in its own discipline;
   - at least five owned nodes in its own discipline including the capstone; and
   - seven owned non-capstone nodes in the same tree that form one connected prerequisite subgraph
     with those required own-discipline nodes.

The capstone is therefore always the eighth point of a legal route or later. A five-point rush is
impossible. The seven preceding points need not be the same seven for every build, but disconnected
shopping in another discipline cannot serve as capstone practice. For this connectivity check,
ordinary prerequisite edges are undirected: the question is whether the purchased route is one
continuous graph, not which direction it is traversed for purchase.

The gate searches the owned set for a qualifying root-connected component. Extra disconnected
breadth nodes cannot contribute to its counts, but they also do not poison a valid route or force a
respec. This matters for grandfathered migration and deliberate broad builds.

Both same-discipline mastery→capstone connectors are always drawn. The additional root/depth,
five-discipline and connected-seven requirements are a separate visible gate; they must not be
encoded by removing the capstone's incoming edges or by drawing seven misleading direct lines.

The prerequisite rules above are additive and exact: every development/mastery always retains its
named same-discipline parent; the authored hybrid table adds only the listed alternative parents.
There is no inferred mirror edge and no generic “any adjacent node” rule.

## Stable identity convention

New stable IDs use `combat.{tree}.{discipline}.{slug}`, for example
`combat.offense.force.heavy_hand` and `combat.craft.emanation.emanant`. Names and positions may change
without changing IDs. The implementation must not derive an ID from an array index at runtime;
migration uses the frozen former `(discipline, index) → stable ID` table once.

The former internal discipline ID `kindling` maps one-way to `emanation` during graph migration, as
declared in the manifest. New state and node IDs use `emanation`; display text is never consulted to
perform the mapping, and `kindling` remains decode-only rather than a parallel writable alias.

### Authored hybrid edges

These are the only cross-discipline edges. Each arrow is an alternative parent, never a free node.

| Tree | Fundamental → development | Development → mastery | Hybrid purpose |
|---|---|---|---|
| Offense | Overbear → Steady Hand; Pry → Bracing Stance | Exploit → Shatter; Stagger → Finish | Weight creates openings; precision converts disruption into finishing |
| Offense | Pry → Second Wind; Quicken → Exploit | Flurry → Finish; Exploit → First Strike | Placement supports tempo; tempo exploits wounded/afflicted foes |
| Defense | Brace → Cover; Draw Off → Constitution | Shieldwall → Ward; Endurance → Interpose | Personal endurance becomes protection; guarding teaches survival under focus |
| Defense | Draw Off → Slippery; Sidestep → Cover | Feint → Interpose; Shieldwall → Untouchable | Reading threat becomes avoidance; formation discipline supports evasive mastery |
| Craft | Envenom → Attunement; Emanation Strike → Virulence | Snuff → Corrode; Corrode → Quench | Substances and projected afflictions share control and resistance |
| Craft | Emanation Strike → Opportunist; Conceal → Attunement | Ambush → Quench; Snuff → Vanish | Emanation shapes visibility; concealment creates controlled openings |

An edge never grants the destination's lane root. A hybrid route that wants that lane's capstone must
still buy its root and meet its five-node commitment.

## Native phone integration handoff — accepted v0.4 functional layout

**Status:** layout accepted; release promotion is blocked on production ownership and purchase, not
on Asset work. `CombatGraphLayout` and the DEBUG route explorer can display and exercise the graph,
but the explorer owns local fixture state. Production `CombatTreeView` still mutates legacy
`branchDepth` through `spendPoint(in:)`; `CharacterState` has no durable arbitrary
`Set<CombatNodeID>` purchase path. Do not ask Asset Design to revise or integrate the v0.4 graph as
if this were a styling problem. The next actionable native boundary is typed, persisted stable-node
ownership plus one atomic rules-owned legal-purchase transaction and migration gate. Until that
exists and the required consumers are live, the functioning legacy purchase screen remains available.

The current app UI is broadly provisional, but this graph must still be a coherent, attractive and
pleasant ordinary-phone playtest surface—not bare engineering scaffolding. This checkpoint proves
durable graph topology, stable-ID selection, connector semantics and rules-owned detail/purchase
boundaries while also testing whether the current layout communicates branching well. Container,
navigation chrome, typography and palette may change later; ordinary-phone layout iteration is in
scope, while accessibility/device-edge hardening and claims of final UI acceptance are not.

### Replace the legacy consumer, not only its styling

`Sources/Screens/CombatTreeView.swift` still renders three `StationCard` branch ladders, derives one
integer branch depth, and offers `Learn next`. It cannot express paired siblings, authored hybrid OR
parents, connected-route rejection, or the capstone gate. Native must consume stable-node topology from
`combat-tree-v2-authority.json` plus exact Effect copy, never the legacy branch array/index.

This is a **promotion gate**, not permission to ship a disabled production tree. While v2 ownership
and consumers are incomplete, the new graph is exercised through the DEBUG route explorer and native
acceptance surface; ordinary saves retain the functioning legacy purchase route. Production promotion
is one atomic checkpoint: graph presentation + stable-ID owned state + rules-owned legal purchase +
lossless point migration + real node consumers. A disabled `Learn` action in place of existing working
progression is a regression, not an honest intermediate state.

### Ordinary 368×800 geometry

- Present one selected 24-node tree below the compact person/points header and three-tree picker.
- Use 44×44pt node targets. In the 368pt plane, discipline centres are x **70, 184, 298**. At depths
  2–4, sibling A/B centres offset **−27/+27pt**. Roots and capstones use the discipline centre.
- Accepted depth centres are y **148, 246, 344, 442, 534**, a **98pt** step. Native may translate the
  plane below real navigation chrome, but retains these relative relationships and at least 10pt clear
  space between sibling frames. Full names belong in selected detail, not inside node targets.
- Capstones keep the 44pt target but use a distinct diamond role shape. Technique, capstone, purchase
  state and selected focus are separate layers from the replaceable central glyph.
- Nodes end at y556 in the proof; detail begins at **y574**, leaving 18pt. Reserve a non-covering detail
  approximately **352×178pt** (`x8…360`) with 44pt actions. It owns name, state/role, exact Effect,
  alternative parents joined by **OR**, capstone gate and the rules-owned action.
- Keep the compact connector key: `Solid: own discipline · dashed: authored hybrid`. Add no first-point
  tutorial overlay.

### Connector and node layering

Render in one stable coordinate space: background/guides → solid same-discipline connectors → dashed
manifest-listed hybrid connectors → node role frame and state fill/border → temporary central mark and
independent technique pip → selected focus ring → detail/key outside the graph plane. Connectors end at
frame edges and remain behind targets. Selection may emphasize its paths but cannot hide topology or
imply that OR parents are simultaneously required. Never infer mirrored or generic adjacent edges.

### Scroll, selection and purchase behavior

- Ordinary type keeps the complete five-depth graph at one stable scale. The screen may scroll graph
  and detail together for real navigation chrome; do not independently pan, horizontally scroll or zoom.
- A node tap selects by stable `CombatNodeID` and updates detail without purchasing. Selection survives
  redraw and remains visible when detail opens. Purchase occurs only through the detail action.
- Owned, available, blocked and selected are state/focus; technique and capstone are roles. Legality and
  refusal copy are rules-owned. Never restore `buy next` or infer availability from depth.
- DEBUG actor/fixture/A/B controls may sit above the graph only in DEBUG and never alter production
  topology.

### Large Text and VoiceOver

Accessibility-size reflow, exhaustive VoiceOver ordering and a device-size matrix are deliberately
deferred while the application-wide UI remains scheduled for redesign. This does not lower the current
ordinary-phone standard: nodes must remain comfortably tappable, branches traceable without relying on
colour alone, selected detail readable without covering the relevant route, and the whole surface
coherent and attractive enough for meaningful playtesting. Accessibility work returns after the
ordinary graph and broader interface direction are stable, unless Aimee explicitly promotes a concrete
issue that also affects her ordinary play path.

### `ResearchTreeLayout` reuse boundary

Reusable after graph-generic extraction: `GeometryReader` + `ZStack`, `Canvas` connectors behind stable-ID
buttons, positioned-node selection, `popover(item:)` adapting to an accessibility sheet, vertical
accessible cards/scroll, combined VoiceOver, and 44pt detail actions.

Do **not** reuse Research rank inference from `requires`, alphabetical ordering, three-per-row packing,
64pt/94pt geometry, required-AND connectors, completed/keeper/stock states, `Study`/cost behavior, or
generic `Requires A and B` speech. Combat parents are alternative OR paths and capstones add a separate
route/discipline gate. Research tile anatomy is also not the combat node contract.

### Native acceptance evidence

Render the exact installed commit at 368×800 ordinary. Prove all 24 stable IDs, every manifest edge,
sibling forks, authored hybrids, all state/focus channels, technique/capstone separation, readable
non-covering detail and comfortably tappable nodes. Also judge whether the graph looks intentional and
whether its branching can be understood in play; a technically complete but unpleasant engineering
surface does not pass. Pixel parity and final-design acceptance are unnecessary; graph/state/semantic
parity and playtest-quality ordinary-phone presentation are required. Record installed commit/build
provenance with all evidence.

## The three concrete graphs

### Offense

| Depth | Force | Precision | Swiftness |
|---:|---|---|---|
| 1 | Heavy Hand | Keen Eye | Quick Step |
| 2A | Follow Through | Weak Point | Light Touch |
| 2B | **Overbear** | **Pry** | **Quicken** |
| 3A | Bracing Stance | Steady Hand | Second Wind |
| 3B | Stagger | Exploit | Flurry |
| 4A | **Shatter** | **Finish** | **First Strike** |
| 4B | Momentum | Anatomy | Cascade |
| 5 | **Breaking Blow** | **Killing Stroke** | **Blur** |

- Force asks whether to commit first to armour pressure or the heavy-action technique.
- Precision asks whether to improve dense-target reliability or gain an armour-ignoring tool.
- Swiftness asks whether to mitigate gear tempo or deliberately borrow a future action.
- Hybrid edges create opening/finishing routes; they do not turn Crush, Pierce and initiative into
  interchangeable damage bonuses.

### Defense

| Depth | Fortitude | Protection | Evasion |
|---:|---|---|---|
| 1 | Thick Hide | Bulwark | Footwork |
| 2A | Iron Skin | Watchful | Light Frame |
| 2B | **Brace** | **Draw Off** | **Sidestep** |
| 3A | Constitution | Cover | Slippery |
| 3B | Endurance | Shieldwall | **Fall Back** |
| 4A | **Ward** | **Interpose** | Feint |
| 4B | Unyielding | Rally | Untouchable |
| 5 | **Immovable** | **Guardian** | **Ghost** |

- Fortitude splits passive armour from timed reduction.
- Protection splits encounter awareness from intentional threat control.
- Evasion splits tempo from a guaranteed answer to one attack.
- Protection is the bridge because it reads both hits that must be endured and hits that can be
  denied.

### Craft

| Depth | Venom | Emanation | Shadow |
|---:|---|---|---|
| 1 | Tainted Edge | Sparkhand | Quiet Step |
| 2A | Apothecary's Hand | Insulation | Low Profile |
| 2B | **Envenom** | **Emanation Strike** | **Conceal** |
| 3A | Virulence | Attunement | Opportunist |
| 3B | **Flense** | **Snuff** | **Ambush** |
| 4A | Corrode | Quench | Vanish |
| 4B | Distiller | Conduction | Shadowed |
| 5 | **Blight** | **Emanant** | **Unseen** |

- Venom splits item mastery from a self-contained combat coating.
- Emanation splits resistance from an active projected strike.
- Shadow splits world avoidance from combat concealment.
- Emanation is the bridge between changing bodies and changing what can perceive them. It remains
  physical/alchemical, not magic.

## Route examples and viability

These examples are exact legal routes; they are demonstrations, not prescribed classes.

| Build | Eight-point route | Result |
|---|---|---|
| Siegebreaker | Heavy Hand → Follow Through → Keen Eye → Pry → Bracing Stance → Exploit → Shatter → Breaking Blow | Crush capstone with deliberate opening/affliction leverage |
| Duelist | Keen Eye → Pry → Quick Step → Quicken → Exploit → Flurry → Finish → Killing Stroke | Precision capstone with tempo and recovery choices |
| Vanguard | Thick Hide → Brace → Endurance → Unyielding → Bulwark → Watchful → Cover → Immovable | Personal survival connected to formation protection through Cover |
| Skirmisher | Footwork → Light Frame → Slippery → Feint → Bulwark → Draw Off → Shieldwall → Ghost | Evasion capstone connected through threat-reading and formation discipline |
| Saboteur | Tainted Edge → Apothecary's Hand → Virulence → Sparkhand → Emanation Strike → Snuff → Corrode → Blight | Poison capstone reached through a connected projected-affliction control route |
| Nightflame | Quiet Step → Conceal → Ambush → Shadowed → Sparkhand → Insulation → Attunement → Unseen | Avoidance capstone connected to emanation through concealment-trained Attunement |

Before Learn, the detail must show:

- exact parent alternatives;
- the node's actual effect and whether it is a technique;
- capstones still reachable and minimum additional points;
- `Needs more practice in {discipline}` for the five-node gate;
- `Earliest at your eighth point in this route` where applicable.

This is structural information, not build advice. The player may bank points indefinitely.

## Balance requirements

The current exact semantic contracts remain in `combat-node-viability-current.md`, with these
additional viability rules:

1. Roots must affect ordinary early play. Weapon-kind roots also apply to the matching unarmed/basic
   attack family so a new character is not given a dead first point because of current equipment.
2. Every depth-2 pair must be a real choice: A cannot simply be weaker than B in every encounter.
3. Techniques have explicit target, action cost, once/cooldown rule and AI/gambit default.
4. World/economy nodes (Anatomy, Distiller, Quiet Step, Low Profile, Slippery, Watchful, Shadowed,
   Vanish) retain a combat-relevant route around them; no capstone route is forced to buy two nodes
   that do nothing in an encounter.
5. Apexes may resist displacement/execute, but the node receives its documented apex fallback rather
   than becoming inert.
6. Party effects aggregate strongest-once unless their contract explicitly says otherwise.
7. No capstone is merely a larger number. It changes armour rules, defeat rules, action economy,
   targetability, formation control, affliction spread, emanation identity or encounter opening.
8. No owned node may be strictly dominated by another node. Watchful changes a successful ambush's
   opening order while Slippery changes ambush probability; Bulwark retains a smaller solo benefit
   while its defining value remains same-rank protection.
9. First Strike and Ambush are not duplicate free attacks: First Strike spends the actor's first
   action for bonus damage/no retaliation regardless of opening state; Ambush is a conditional free
   attack and consumes the shared opening opportunity.

## Persistence and migration

```text
CombatGraphVersion = 2
CharacterState.ownedCombatNodes: Set<CombatNodeID>
CharacterState.combatNodeChoices: [CombatNodeID: StableChoiceID]
CharacterState.unspentCombatPoints: Int
```

- `branchDepth` is decode-only. A legacy depth maps to the first N former nodes of that discipline,
  which are all retained as stable IDs. The migration may yield a legal owned set that did not follow
  the new graph; it is grandfathered, not deleted or silently rerouted.
- A grandfathered set keeps every effect. The next purchase must be legal from the owned set.
- Full Essence Spring respec clears ownership/choices and returns every standard, calling and
  grandfathered spent point exactly once.
- New traveller leans and generated arrivals name exact node IDs and a graph version. No new content
  writes branch depths or “buy next” instructions.
- Unknown future IDs round-trip inertly and diagnostically; they never alias a known node.
- Graph role, depth, lane and `grantsTechnique` are independent authored fields. Neither native UI
  nor rules may infer one from another.
- Learning Insulation or Emanant opens a required Heat/Caustic/Light choice before atomic purchase;
  cancellation spends nothing. Emanation Strike's saved manual/gambit preference is ordinary action
  configuration, not a permanent node choice and not a prerequisite for either node.

## Native presentation

- Tree tabs are Offense, Defense and Craft. Inside one tab, all 24 nodes and all connectors form one
  graph.
- Depth runs vertically; disciplines occupy stable left/centre/right regions. Paired nodes at each
  middle depth visibly fan out from and back toward their discipline.
- Hybrid edges use the same connector grammar but cross only one region boundary.
- Node buttons are compact glyph tiles with 44×44pt targets. Descriptions live in an edge-clamped
  anchored detail, never in 24 full-width rows.
- Owned, available, blocked, selected, technique and capstone states remain distinguishable without
  colour. VoiceOver names every alternative parent.
- Dynamic Type may use a topology-preserving depth outline, but must expose sibling alternatives and
  hybrid parents; it may not revive `Learn next` or branch-depth lists.

## Acceptance gate

1. Catalogue validation proves 3 trees × 24 nodes, unique stable IDs, valid same-tree edges, no
   cycles and no left↔right direct hybrid.
2. Every root exposes two children; every discipline has at least two distinct legal eight-point
   capstone routes.
3. Exhaustive enumeration proves no capstone can be bought before point eight and every capstone is
   reachable.
4. The six exact routes above validate in order; at least 30 materially distinct eight-point
   capstone routes exist per tree.
5. Every one of 72 IDs has a scenario-level effect test; loadout-field presence is insufficient.
6. Legacy depth 0…8 in every discipline migrates without lost effects/points and respec is exact and
   idempotent.
7. Generated-person plans, authored leans, gambits and selected emanation choices survive save/load
   and catalogue reorder.
8. 368×800 color/grayscale proof shows one whole 24-node tree, all sibling forks, at least two hybrid
   edges, all three capstones, selected detail and its route controls without list presentation,
   clipped targets, cropped proof bounds or overlapping node labels. An export shorter than the
   authored phone viewport is failed evidence even if the source canvas contains the missing content.
9. VoiceOver and Large Text expose the same choices and prerequisites as the connector graph.
10. A DEBUG route explorer can grant points, preview legal next nodes, enumerate capstone routes and
    respec without mutating the ordinary save unless explicitly committed.

Numerical tuning remains reversible playtest work. Topology, stable identity, exact node placement,
authored hybrid edges, eight-point capstone floor and lossless migration are settled current design.
