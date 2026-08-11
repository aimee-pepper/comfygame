# Combat-tree progression experience — current design

**Status:** implementation-ready companion to the graph and node-consumer contracts.
**Owner:** Game Design owns pacing and player understanding; Engineering owns point receipts,
purchase state and migration; Asset Design owns graph/glyph presentation only.
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

## First-point teaching

The Binder's first flexible point gets one short, dismissible overlay on the actual fan-and-fork graph:

- **Choose a direction:** every node is one point.
- **Lines show what it can lead to:** paired choices divide inside a discipline; dashed authored
  lines show the few adjacent-discipline hybrids.
- **Nothing is permanent:** the Essence Spring can return all spent points later.

The overlay points at the three rank-1 roots and leaves the full tree at its settled size. It never
reflows the graph, blocks inspection of node detail, or claims the player needs to spend immediately.
Subsequent people do not repeat it. DEBUG can reset the teaching flag independently of progression.

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
7. At 368×800 the point count, three roots, five graph depths and anchored Learn detail remain usable;
   the first-point teaching overlay does not resize the graph.
8. VoiceOver announces level, unspent points, owned/available state, prerequisites and the outcome of
   Learn/respec without relying on connector color.
