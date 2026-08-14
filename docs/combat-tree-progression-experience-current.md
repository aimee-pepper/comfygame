# Combat-tree progression experience — current design

**Status:** implementation-ready companion to the graph and node-consumer contracts.
**Owner:** Game Design owns pacing and player understanding; Engineering owns point receipts,
purchase state, migration and functional graph presentation; Asset Design owns layout,
accessibility and placeholder-state conformance only; Aimee owns final glyph art.
**Depends on:** `combat-tree-true-graph-current.md`, `combat-node-viability-current.md` and
`combat-progression-current.md`.

## What progression should feel like

A combat tree is a repeated build decision, not a reward screen the game fills automatically. Every
level after level 1 grants one standard combat point. The player may bank points indefinitely, and
no level-up, recruitment or migration silently spends a flexible point.

For an uninterrupted eight-node route, the important level windows are:

| Character level | Standard points earned | Pure-route result |
|---:|---:|---|
| 2 | 1 | A visible mechanical direction begins |
| 3 | 2 | Earliest first active technique through Fundamental B |
| 4 | 3 | Earliest Development-B technique in disciplines that place one there |
| 5 | 4 | Earliest Mastery-A technique; every pure discipline route has reached its second authored technique opportunity by here |
| 9 | 8 | First capstone route |
| 17 | 16 | Second capstone route |
| 25 | 24 | Third capstone route / standard level cap |

These are opportunities, not forced milestones. The graph does not infer techniques from depth:
Defense and Craft place several at Development B, while most second techniques sit at Mastery A.
Hybrid or broad investment can change/delay the sequence. Calling-lean bonus points may
advance an authored companion's starting identity, but never reduce or replace their 24 standard
level-earned points.

### Equipment-dependent nodes are disclosed, never forced

Force/Precision and some Craft effects deliberately reach full value only with a matching attack or
weapon. Fresh campaigns and rotating stock do not guarantee every damage kind. The selected node
detail therefore says both its exact requirement and whether this character's **current** loadout can
trigger it: for example, **Works now with your Crush weapon** or **Learnable now; needs a Crush
weapon to apply**. This is ordinary purchase information, not a tutorial overlay.

Current equipment never blocks learning: gear can change later, and a banked point may remain
unspent indefinitely. The graph must not describe a gear-dependent root as a universal damage bonus,
nor leave a player to discover only in combat that their current weapon cannot trigger it.

#### Fresh-save readiness audit — 11 August 2026

Current `GameState.newGame()` creates no equipped weapon. Against the exact node semantics, four of
the nine roots therefore may be inactive for a genuinely fresh character:

- Heavy Hand needs a Crush attack;
- Keen Eye needs a Pierce attack;
- Tainted Edge and Sparkhand need a landed direct weapon hit.

Quick Step, Thick Hide, Bulwark, Footwork and Quiet Step remain immediately operative without gear.
This is not proof that the four equipment roots are bad: delayed build synergies and banking are
legitimate, and changing them into generic bonuses would flatten the tree. It is a concrete early
progression risk, especially while Aimee is also testing whether a new party can survive its first
encounters.

Do not resolve this by inference or an invisible unarmed damage kind. During the controlled
fresh-save balance pass, record when the first combat point arrives, whether either traveller owns a
weapon then, which root the screen says works now, and whether an ordinary route to a suitable weapon
was visible through loot or the Trading Post. Acceptance is one of these evidenced outcomes:

1. suitable gear ordinarily appears before the choice and the applicability copy is sufficient;
2. banking the point feels like a meaningful visible option for only a short interval; or
3. if neither holds, add an explicit early equipment route/starting-loadout decision as its own
   balanced checkpoint.

Do not quietly grant a fixed starter weapon while encounter balance is being measured: +weapon tier
changes both fresh-party damage and which roots activate, so it would confound the current defeat
diagnosis. Do not make learning require current gear either; that would turn rotating loot into a
progression lock.

### Route-quality audit — no topology redesign required

The generated route audit reports 66–79 legal capstone paths per tree and at least 13 routes to every
individual capstone under the authored hybrid alternatives. Those counts are diagnostics, not a goal
to maximize. The five-node same-discipline capstone commitment prevents a cross-link from buying an
identity for free, while alternate parents let a related technique open a hybrid route without
turning the graph back into three isolated ladders.

The current 72 effects also remain differentiated at the decision level: offense separates weight,
target reading and tempo; defense separates endurance, protection and avoidance; Craft separates
affliction, emanation and encounter control. Similar-looking effects occupy different timing or
ownership boundaries—Sidestep preparation versus Ghost reserve, Slippery probability versus Watchful
opening-order protection, Vanish retreat versus Quiet Step prevention—and should not be collapsed
merely to reduce node count. The next design evidence comes from play and real consumers, not another
topology or naming pass.

## Level-up and point receipt

1. Experience resolution reports levels gained and combat points gained as separate facts.
2. A newly earned point increments a durable unspent-point balance before any presentation opens.
3. The expedition recap names which people gained points; it does not force the tree screen during a
   return sequence or discard later recap information.
4. Home Party tiles show a compact **point ready** badge. The character's Combat tab shows the exact
   count and retains it until spent.
5. Tapping the badge opens that person's last-viewed tree, not an arbitrarily recommended node.
6. Multiple levels earned at once produce the correct number of points and one concise notification,
   not several modal interruptions.

The game may highlight currently available nodes, but it must not call one **best**, preselect Learn,
or imply that an available capstone is mandatory.

## Persistent graph comprehension — not a tutorial checkpoint

The true-tree implementation must not wait on or create a first-point teaching overlay. Aimee has
placed tutorial work dead last; an instructional flag/modal is not part of graph migration,
presentation or acceptance.

The ordinary screen explains itself every time through:

- a compact persistent key: **1 point per node · solid line prerequisite · dashed line alternate
  hybrid route**;
- clear owned/available/blocked frames and connector shapes;
- anchored node detail naming exact parent alternatives and Learn consequences;
- the visible unspent-point count and optional **How this graph works** help action;
- respec availability/cost only inside the relevant detail/help, without claiming choices are free or
  consequence-less.

No first-point event opens, points at roots, changes focus, blocks taps, writes a tutorial receipt or
needs a DEBUG reset. The existing **point ready** badge is sufficient notification. A future tutorial
may reference this already-complete surface after higher priorities, but cannot become required graph
state or migration data.

## Purchase feedback

Selecting a node opens the anchored detail defined by the graph contract. **Learn** is enabled only
when the rules-owned transaction is legal. A successful purchase:

- changes that exact stable node to owned;
- decrements one unspent point;
- reveals newly available outgoing choices without moving existing nodes;
- names any newly learned active technique and where it appears in combat;
- updates remaining-capstone reachability in the same detail surface.

A stale or failed purchase changes nothing and leaves the detail open with a truthful reason. Buying
a passive never uses celebratory copy that implies a new combat button.

## Companion arrival

Authored and generated people may arrive with coherent lived experience already spent, as specified
by their calling/arrival plan. Their first Party inspection shows:

- **Known practice:** the owned route and any calling-lean nodes;
- **Your choices:** flexible unspent standard points, if any;
- the same graph and respec rules as the Binder.

Arrival plans resolve to stable node IDs and must form a legal connected owned set. If legacy or
future data cannot resolve an intended node, preserve the point as unspent and report the mismatch in
DEBUG; never substitute a similarly positioned node.

## Respec experience

Full Spring respec remains the sole ordinary rebuild action. Before confirmation it shows:

- exact Essence cost;
- total nodes forgotten;
- total points returned, split into standard and calling/free when useful for diagnosis;
- techniques and persistent choices that will be removed;
- an explicit statement that the character will have no purchased combat practice until points are
  spent again.

Confirmation clears owned nodes and node-specific selections/temporary derived state atomically,
then returns the exact budget. It does not auto-rebuild the previous route. Cancel and insufficient
Essence are zero-mutation outcomes.

## Long-campaign safeguards

- Level 25 does not award a 25th standard point.
- Max-level experience may still be recorded for telemetry, but cannot manufacture progression.
- Three capstones do not end character growth fiction; gear, Gambits, relationships, research and
  world knowledge remain other axes. The combat graph itself does not grow an infinite mastery bar.
- Unspent points and owned stable IDs survive save/load, party assignment, passing out, anchoring and
  campaign-slot changes.
- Respec cost remains DEBUG-tunable, but must be payable from ordinary play and must not compete with
  the player's minimum Essence runway for writing the next world.

## Acceptance

1. A no-lean level-1 character has 0 points; levels 2/3/4/5/9/17/25 have 1/2/3/4/8/16/24.
2. A legal pure path can expose its first technique at route point 2, its next authored technique at
   point 3 or 4, and its capstone no earlier than point 8 without automatic purchase.
3. Banking through several levels, relaunching and then spending preserves every point exactly once.
4. Multi-level expedition recaps and Party badges agree for every affected person.
5. Arrival plans are connected, stable-ID based and never consume more than standard plus authored
   free points available at that level.
6. Full respec failure/cancel/relaunch cannot lose Essence, points, choices or node ownership.
7. At 368×800 the point count, persistent key, three roots, five graph depths and anchored Learn
   detail remain usable without any tutorial overlay or first-point interruption.
8. VoiceOver announces level, unspent points, owned/available state, prerequisites and the outcome of
   Learn/respec without relying on connector color.
9. A character with no weapon, an off-kind weapon and a matching weapon sees truthful current-loadout
   applicability on every equipment-dependent node; all three may bank or learn the node without a
   hidden prerequisite.
