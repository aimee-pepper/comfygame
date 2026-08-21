# Workshop and Constellation role audit — current review

**Status:** Game Design audit with recommendations for Aimee discussion. No native route/content removal is
authorized until the recommendations are accepted.
**Scope:** opening Binder House destinations, the 87-node research catalogue, Gambit capacity, Motes and the
single live Constellation node.
**Updated:** 21 August 2026

## Conclusion

The **Workshop is a relic and should stop being a standalone destination**. It does no coherent physical
crafting. Its current five branches collect unrelated systems that now have clear owners elsewhere.

The **Constellation does not currently earn a standalone House destination**. Its one purchase duplicates
the same Gambit-capacity axis already sold twice by Workshop research, while the promised Reality/reset
distinction has no current game event that makes it matter.

Recommended direction:

1. distribute every Workshop branch to the destination that actually owns its outcome;
2. remove Workshop as an interactive House hotspot once routes/deep links migrate;
3. remove Constellation as an opening House hotspot and hide its standalone screen for new campaigns;
4. preserve existing purchases exactly;
5. reintroduce a visible Constellation only when at least three genuinely campaign-wide/world-rule effects
   exist and are worth choosing between.

## Live audit

### Workshop

The live Workshop renders every research branch whose `station` is `nil`. That currently means **54 nodes**
across five branches:

| Branch | Nodes | Actual outcomes | Why Workshop is the wrong owner |
|---|---:|---|---|
| Instruction | 12 | Gambit selectors, thresholds, actions, +2 shared slots, automate Binder | party planning/behavior, not fabrication |
| The Hand | 2 | two writable symbols | written vocabulary/Dictionary |
| The Hold | 14 | Storehouse and satchel capacity | Storehouse construction and Tannery carry craft |
| The Lexicon | 19 | writable pressure focuses | Dictionary/knowledge |
| The Bargain | 7 | danger/stability-trade symbols | Dictionary/Writing knowledge |

The Workshop header shows Essence, Ore and Fibre, but the underlying branches consume many unrelated
resources and grant knowledge, capacities and Gambit rules. The physical fiction does not explain the
contents. It also makes the Binder House carry a generic menu for systems that later specialist buildings
already own.

### Constellation

The live Constellation contains exactly one maximum-rank-one node:

- **The Long Instruction** — costs 3 Motes and gives +1 Gambit slot to every current/future person.

The Workshop's Instruction branch already sells two +1 shared Gambit-slot nodes. The Constellation version
is distinguished mainly by persistence through a hypothetical Base reset, but no player-facing reset exists
and current design prohibits promising one. The visible screen is therefore a rare-currency wallet plus one
administrative capacity purchase—not a meaningful constellation or Reality-altering choice.

Motes themselves are not invalid. They are a rare Reality resource, a cache fallback, a world yield and an
ingredient in the existing Waystone recipe. Removing the standalone screen does not require deleting Motes.

## Recommended destination ownership

### 1. Party planning table — Instruction

Move the Instruction branch into **Party → Gambits → Planning** at the Binder House's party table.

- Global Gambit vocabulary remains campaign knowledge.
- The surface shows a true prerequisite graph, not a list.
- Nodes that unlock selectors/thresholds/actions state the new rule phrase.
- Capacity nodes appear beside the Gambit rules they enlarge.
- Diary-taught Gambit components continue to enter the same vocabulary without being repurchased.

The two current ordinary capacity nodes and The Long Instruction require one combined redesign before
migration. Do not ship three visually separate ways of buying the same `+1 slot` result.

Recommended first track:

1. **Longer Instruction I** — current ordinary research cost/effect;
2. **Longer Instruction II** — current chained ordinary research cost/effect;
3. **The Long Instruction** — optional rare 3-Mote capstone, campaign-wide and current/future.

This retains all paid effects and gives the Mote purchase a comprehensible relationship to the ordinary
track. It does not claim to alter Reality or survive an unimplemented reset. Existing Constellation purchase
migrates to capstone ownership; existing Workshop slot purchases migrate to ranks I/II.

### 2. Library Dictionary — The Hand, Lexicon and Bargain

Move all writable-vocabulary study into **Library → Dictionary → Study**:

- The Hand's two symbols join the symbol/rune study graph.
- Lexicon focuses join the focus vocabulary graph.
- Bargain danger/stability symbols form a clearly labelled danger-writing branch within the Dictionary.
- Known/unknown entries still obey encounter and meaning-disclosure rules.
- A learned entry remains learned regardless of route migration.

The Library root remains the five visual shelves. `Study` appears only after entering Dictionary; it does not
turn the Library room back into a tabbed research menu.

### 3. Storehouse — shelving capacity

Move `shelving_one...nine` to **Storehouse → Improvements**. Their costs and capacity effects remain until a
separate balance pass. The Storehouse building visibly grows storage bays/rooms at meaningful milestones.
Later Tannery prerequisite nodes remain explicit requirements where lining/construction is fictionally
needed, but the purchase occurs at the Storehouse because that is the structure being improved.

### 4. Tannery — satchel capacity

Move `satchel_one...five` to **Tannery → Carry**. Existing opening rungs require a migration-safe availability
route so a fresh player is not capacity-blocked before Corrin. Recommended behavior:

- current pre-Corrin ranks already owned remain owned;
- the opening Field Kit capacity remains sufficient for the first campaign band;
- Corrin's Tannery owns future constructed expansion;
- no duplicate satchel ladder remains at Storehouse/Workshop.

Exact early capacity and Corrin reachability must be proven before the route changes.

## Workshop removal and migration

Workshop removal is a navigation/content-owner migration, not deletion of progress.

Engineering sequence after approval:

1. Add stable destination ownership metadata for the five affected branch groups without changing node IDs,
   prerequisites, costs or grants.
2. Add deep-link adapters from legacy Workshop node/branch links to Party, Dictionary, Storehouse or Tannery.
3. Preserve `completedResearch`, partial research-lead progress and attention receipts by stable node ID.
4. Ensure unavailable Tannery routes do not hide already purchased satchel results or break opening capacity.
5. Remove Workshop from new House presentation and current station navigation.
6. Keep the stable `workshop` station ID as decode-only compatibility for old saves; it never renders as a
   destination and receives no future branches.
7. Remove legacy tutorial copy that routes Workshop refinement to Essence Spring only as part of the dead-last
   tutorial pass; do not pre-empt current work for it.

The physical house may retain a decorative workbench, but it is not tappable and does not imply a missing
generic crafting screen.

## Constellation options

### Option A — retire the standalone screen now (recommended)

- Migrate Long Instruction ownership into the Party/Gambit capstone.
- Hide the Constellation route and House hotspot for new campaigns.
- Preserve Motes and all current sources/other costs.
- Keep a decorative star chart/window in the Library or House if desired, with no tap target.
- Reintroduce the system only after three approved, nonredundant, live effects exist.

This minimizes misleading UI and avoids designing an impressive screen around one redundant upgrade.

### Option B — nest one star chart inside the Library

- Library includes a non-shelf wall chart leading to the current one-star detail.
- Long Instruction remains a Mote purchase.
- It no longer consumes a House hotspot.

This preserves the fiction but does not fix the functional redundancy. It is acceptable only as a temporary
compatibility surface.

### Option C — keep the standalone House destination

Not recommended. It spends prime opening navigation on one administrative upgrade and encourages Asset
Design to imply future content that has not been designed.

## When a Constellation may return

Game Design may propose the Constellation again only when all of the following are true:

1. at least three effects have implemented consumers and tests;
2. each affects the campaign/world rules broadly, not one station/person/item;
3. at least one real choice or prerequisite relationship exists;
4. Mote acquisition and costs are balanced against other Mote uses;
5. the Great Work/Reality fiction is settled enough that the screen can describe itself truthfully;
6. old Long Instruction ownership has one clear relationship to the new graph.

No fake locked stars, promised reset, decorative edges or fossil effects may be used to meet the count.

## House impact while open

Until Aimee decides:

- Writing Desk, Library, Party and yard Essence Spring are settled interactive House anchors.
- Storehouse and Firepit remain in The Commons.
- Workshop and Constellation are **not** approved as final interactive hotspots for new Asset work.
- Asset Design may reserve decorative workbench/star-chart space but may not label or wire it as navigation.

If both recommendations are accepted, the House has four opening interactive anchors plus the three district
arrows. This is not “too empty”: each anchor is a substantial spatial destination, and removing redundant
menus gives the cutaway room to read like a home.

## Decisions needed

1. Remove Workshop as a standalone destination and distribute its branches as specified?
2. Retire Constellation as a standalone destination now (Option A), temporarily nest it in Library (Option
   B), or keep it (Option C)?
3. If Option A/B, accept the combined three-rung Gambit-capacity track and exact old-purchase migration?
