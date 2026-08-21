# World-resource extraction progression — current

**Status:** Game Design implementation authority; not yet implemented. Replaces the vague “three-resource
capability experiment” in the earlier core-loop plan with a complete data-driven mineral-extraction
progression and an explicit vertical-slice order.
**Priority:** after the first-three-world survival/causal-presentation baseline; before specialist resource
economy expansion. The Gold rune may become known before Gold is extractable by design.
**Owner:** Game Design owns capability/pacing; Engineering owns node rules, tools, projection, receipts and
migration; Asset Design owns functional node/tool/readiness cues; Aimee owns final art.
**Updated:** 21 August 2026

## Corrected design premise

It is legitimate and desirable for the player to learn that Gold worlds are possible before they can mine
Gold. The unavailable resource becomes a concrete progression goal: improve a pick, then deliberately
write the world that pays that capability back.

The problem to avoid is not “the player might write Gold before they can collect it.” The problem is an
**undisclosed** or arbitrary gate. When the player knows the Gold rune and the active party lacks the
required tool, the Writing Desk and node inspection must say so plainly. The player remains free to bind
that page anyway.

## Progression axis: equipped extraction tool, not Binder level

Mining access is determined by the highest qualifying **Field Pick family** equipped in the active
expedition party. It is not derived from Binder level, generic weapon tier, a hidden Mining XP bar or the
presence of an unequipped pick at Home.

Use one integer `ExtractionRank`:

| Rank | Qualifying current lineage | Player meaning |
|---:|---|---|
| 0 | no qualifying pick | loose/soft/common material can be gathered by hand/basic kit |
| 1 | Bent Pick or crafted Field Pick tier 1 | ordinary worked seams |
| 2 | Balanced Pick or Field Pick tier 2 | valuable/hard seams including Gold |
| 3 | Corebreaker or Field Pick tier 3 | dangerous/strange seams |
| 4 | The Willing Edge or Field Pick tier 4 | extreme endgame material |

Runtime recognizes stable gear family/profile plus tier. Display names, SF Symbols and catalogue ordering
never determine capability. Compatibility mappings for the four existing named tools are explicit data.

If several active party members equip qualifying tools, use the highest rank once. Tools do not stack.
The tool is ordinary equipped gear in the `tool` slot; it does not also consume a Field Kit supply bin.
Leaving the tool at Home or on a non-travelling person provides no extraction capability.

## Complete first-pass resource table

This table is the implementation authority for current named resources:

| Resource | Extraction system | Required rank | Reason |
|---|---|---:|---|
| Rubble | mineral/ground | 0 | loose material |
| Clay | mineral/ground | 0 | soft hand-workable deposit |
| Iron Ore | mineral/ground | 0 | opening construction runway; Blacksmith itself requires Iron |
| Salt | mineral/ground | 0 | exposed/soluble deposit |
| Sulfur | mineral/ground | 0 | exposed deposit; environmental hazard is separate from extraction |
| Copper | mineral/ground | 1 | ordinary worked seam |
| Quartz | mineral/ground | 1 | hard but foundational instrument material |
| Obsidian | mineral/ground | 1 | brittle worked deposit |
| Silver | mineral/ground | 2 | valuable narrow seam |
| Gold | mineral/ground | 2 | deliberate mid-progression payoff |
| Mercury | mineral/ground | 3 | dangerous/strange extraction |
| Rift-glass | mineral/ground | 3 | unstable/contradiction material |
| Adamant | mineral/ground | 4 | extreme late material |
| Fibre | flora harvest | n/a | current flora-harvest rules; no pick |
| Timber | flora harvest | n/a | current flora-harvest rules; no pick |
| Pulp | flora harvest | n/a | current flora-harvest rules; no pick |
| Resin | flora/exudate harvest | n/a | current flora/exudate rules; no pick |
| Toxin | flora harvest | n/a | current flora-harvest rules; no pick |
| Spore | flora harvest | n/a | current flora-harvest rules; no pick |
| Reagent | flora/volatile harvest | n/a | current source rules; no pick in this slice |
| Raw Essence | direct pickup | 0 | continuation resource; never tool-gated |
| Mote | direct Reality pickup | 0 | never tool-gated |

Generic Ichor leaves this table when the creature-material overhaul lands. Ichor becomes a creature
material with a real emanating-creature source rather than an ordinary world node.

Rank 0 Iron is deliberate: Halloway's Blacksmith requires Iron Ore, so putting all Iron behind a pick that
only Halloway can make would create a progression deadlock. The Field Pick family begins improving access
after ordinary Iron can build the forge.

## Node state and transaction

Each mineral resource definition declares `requiredExtractionRank`. The world node freezes the ResourceID,
amount/yield receipt and requirement when the world is bound; renderer code does not infer requirement from
rarity or colour.

Node interaction has exactly these states:

1. **Undiscovered:** ordinary fog/disclosure rules; no requirement cue.
2. **Visible, requirement unknown to player:** node silhouette is visible; Look may identify only what
   current resource knowledge allows.
3. **Known and extractable:** Look names resource, expected world-turn cost and equipped qualifying tool;
   Use Tile is enabled.
4. **Known but under-equipped:** Look names the exact requirement and current party rank; Use Tile refuses
   without spending a turn or changing the node.
5. **Exhausted:** node uses its exhausted visual and cannot be harvested again.

The extraction transaction validates the currently active party and exact equipped gear again at commit.
A stale preview or equipment change produces a no-turn, no-yield, no-node-mutation refusal. A valid action
spends the current authored node-harvest world turn, awards the exact world resource and exhausts/reduces
the node atomically. The tool is not consumed, damaged or given durability.

Higher rank than required grants access only in v1. It does not multiply yield or reduce turn cost. Those
bonuses may be tested later once access pacing is accepted; hiding a yield multiplier in the first slice
would make it impossible to tell whether the gate or the economy caused a balance change.

## Writing Desk and World Page disclosure

### Player-authored known resource

When the draft contains a known source that explicitly asks for a gated mineral, **The world** projection
shows one practical preparation line:

> Gold may form here. Your departing party needs Extraction 2 (a Balanced Pick or better) to mine it.

If the selected party already qualifies:

> Gold may form here. Balanced Pick covers its Extraction 2 requirement.

This is preparation information, not a binding blocker. Bind & Depart remains available when every other
rule is legal.

### Unknown mark / collected World Page

An unidentified mark never leaks Gold, its requirement or its presence through the tool warning. The
projection may state only that part of the page remains unread. Once the resource is legitimately
identified, future projections may show the requirement.

### Open/random world dimensions

The Desk does not list every resource that might randomly resolve in an unwritten substrate. Finding an
unexpected inaccessible seam in a generated world is allowed; Look records it in the Dictionary/resource
record as a future goal.

## Tool acquisition and improvement

- Rank 0 supports all materials required to find Halloway and construct the Blacksmith, including Iron.
- Halloway's foundational Field Pick recipe creates rank 1 when made from qualifying ordinary materials.
- Blacksmith improvements/current tier-2 tool lineage provide rank 2 and therefore Gold/Silver access.
- Weaponsmith/advanced maker progression may provide rank 3 only when the campaign reaches those stations;
  the exact maker remains subordinate to the existing gear-family authority.
- Rank 4 remains the existing mythic Willing Edge lineage/endgame acquisition. Do not add an early recipe
  merely to complete the table.

The requirement display always names capability and a known qualifying example. It does not imply that
only the named catalogue item works.

## Presentation and asset contract

1. Resource-node family silhouette remains primary. A small pick-notch requirement badge may appear only
   after the resource/requirement is legitimately known.
2. Rank uses one to four redundant notch/chevron marks; colour may support but not own the distinction.
3. Under-equipped selection shows the same node, not a generic padlock replacing its identity.
4. Look/detail names `Extraction N`, current best equipped tool and exact refusal.
5. The Writing projection uses the same capability icon/text authority as the field node.
6. Exhausted state is materially distinct from under-equipped. “Cannot yet mine” and “already mined” must
   not share a greyed-out presentation.

Asset first proves Iron rank 0, Gold rank 2, Adamant rank 4 and exhausted Gold in map/detail color and
grayscale. Once accepted, the same grammar applies data-driven to the complete table.

## What the former “three-resource experiment” meant

It was intended as a vertical implementation proof, not a proposal to leave only three resources gated:

1. **Iron** proves rank-0 collection and the no-deadlock opening.
2. **Gold** proves a known, deliberately writable resource that requires a later pick.
3. **Adamant** proves the maximum requirement and future-goal presentation.

Under this corrected authority, those three are the first automated/UI fixtures. After the transaction and
presentation pass, Engineering applies the same data field to the complete mineral table in the same
feature sequence. The mechanic is no longer waiting on an experiment to decide whether progression exists.

## Engineering checkpoint order

1. Add `requiredExtractionRank` catalogue validation and frozen node receipt; no UI yet.
2. Add qualifying Field Pick family/rank resolver and active-party derived receipt.
3. Implement no-turn refusal and valid atomic harvest for Iron/Gold/Adamant fixtures.
4. Add Look/Use Tile and Writing projection from the same rules-owned preview.
5. Extend the data table to every current mineral resource; fail catalogue validation if a mineral omits a
   rank.
6. Integrate requirement/exhausted asset grammar and ordinary-phone proof.
7. Add World Generator Web columns for resource, node count, required rank and reachable/extractable count
   under a selected test-party tool rank.

## Acceptance

1. A no-pick fresh party can collect every material needed to construct the Blacksmith.
2. Known Gold writing truthfully warns an under-equipped player but never blocks a legal bind.
3. Unknown collected-page marks do not leak Gold or its requirement.
4. Under-equipped Use Tile spends zero turns, awards nothing and leaves the exact node unchanged.
5. Adequately equipped Use Tile spends/awards/exhausts exactly once across relaunch and repeated taps.
6. A pick at Home, in Storehouse or on a non-travelling person never contributes.
7. Any qualifying current/future Field Pick profile of the same rank works; display name is irrelevant.
8. World history preserves the frozen node/resource even if later balance changes its catalogue rank.
9. Tool durability, random breakage and hidden mining XP do not exist.
10. Phone play confirms that learning Gold before rank 2 creates a desirable goal rather than an unclear
    failure; tuning may change the exact Gold rank but not the disclosed capability grammar.

## Explicit exclusions

- no Binder-level mining gate;
- no pick durability/repair;
- no partial Gold yield while under-equipped;
- no automatic tool teleport from Home;
- no tool requirement for Raw Essence or Motes;
- no flora-harvest progression in this slice;
- no anchoring or Deep Works implementation as a prerequisite.
