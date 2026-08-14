# Research-tree graph presentation — current design

**Status:** implementation-ready presentation correction; research mechanics/costs are unchanged.  
**Owner:** Game Design owns information architecture; Engineering owns deterministic layout and
interaction; Asset owns stable branch/node/connector grammar.  
**Supersedes:** `ResearchOutline`'s vertical prose-row presentation. It restores the earlier settled
decision that research prerequisites must be visible as actual edges.

## Boundary

Research is already a validated prerequisite DAG. It is not the same progression shape as combat:

- combat points create mutually competing routes and capstone builds;
- research is a station-owned body of knowledge the player may eventually complete;
- research edges answer **what leads to this**, not **which permanent class did I choose**.

No node, cost, prerequisite, keeper grant, station tier or completion state changes in this
checkpoint. The failure is presentation: an indented list makes dependency planning look like a
shop receipt and hides diamonds behind “also needs” prose.

## Branch hub

Keep the compact branch hub, with these corrections:

- two columns at ordinary phone type, one at accessibility sizes;
- tile identity is branch glyph/name plus `done / total` and `ready`; no disclosure-heavy full blurb;
- tapping the tile itself opens the graph; remove decorative chevrons/menu-row language;
- a short branch explanation belongs in the graph header/detail, not repeated in every hub tile;
- station-owned surfaces show only that station's branches. Workshop never claims another keeper's
  teaching.

## Native graph

Opening a branch shows one vertically scrollable, screen-width graph:

- topological ranks run top→bottom;
- up to three compact node columns fit the ordinary 368-point phone width;
- prerequisite edges render behind nodes and terminate at the exact stable node IDs;
- a multi-parent node has every incoming edge visible; no parent is demoted to an “also needs” line;
- independent roots share a visibly labelled root band. When a branch has more than three roots,
  the band wraps into compact rows without implying prerequisites between them;
- descendants are never collapsed or hidden by default. Filters may dim Completed/Locked, but the
  full route remains spatially present;
- no horizontal scrolling and no full-width description/cost row per node.

Nodes use 44×44 minimum targets inside compact glyph tiles. Stable states are redundant:

| State | Required grammar |
|---|---|
| Completed | filled node + check/notch |
| Supplied by keeper | distinct inset person/tool mark + text in detail |
| Available and affordable | open bright ring + reachable edge emphasis |
| Available, missing stock | open ring + material-notch warning |
| Prerequisite locked | closed/dashed shape |
| Selected | outer focus frame independent of ownership state |

Colour reinforces but never owns a state. Connector line style distinguishes satisfied, available
and locked edges in grayscale.

## Deterministic layout authority

Prerequisites own graph semantics; array order, name and price never own position. Add optional
authored presentation hints only where automatic layout cannot preserve a meaningful grouping:

```text
ResearchNodeDef {
  layoutGroup: String?      // siblings/independent studies that should remain together
  layoutOrder: Int?         // stable order inside a rank/group
  preferredColumn: 0...2?  // hint, not prerequisite semantics
}
```

The layout engine:

1. computes topological rank from the longest prerequisite path;
2. groups children near their parents and minimizes edge crossings deterministically;
3. applies valid authored hints without changing rank or edges;
4. breaks all remaining ties by stable node ID;
5. reports collisions, orphan hints and unavoidable crossings in DEBUG.

Costs must never order nodes. The current cheapest-first/name ordering is removed: balance edits or
renames cannot rearrange a player's mental map. Saved research stores stable completion IDs and is
therefore unaffected by visual position.

Branches with 1–3 nodes still render as small graphs rather than falling back to list rows. A
single-node branch is one root node and its detail, not a giant full-width button.

## Node detail and purchasing

Tap a node to open an anchored, edge-clamped detail over the graph. It shows:

- node name and concise authored blurb;
- exact grant using shared `ResearchWording`;
- every prerequisite by name and state;
- station/keeper requirement and whether it is satisfied;
- exact rules-owned cost, stock shortfall and Study action;
- **Supplied by keeper** when the node is granted rather than purchased.

The detail flips above/below and left/right at screen edges and never becomes a new navigation
screen. At accessibility sizes it may use a compact sheet while preserving the selected node and
return position. Study uses the existing atomic rules mutation; stale stock closes no route and
returns the updated shortfall without partial spend.

The graph updates completed/available states in place after purchase. It does not navigate back,
scroll to the top or automatically select/buy the next node.

## Large text and accessibility

The ordinary visual graph remains available through standard Dynamic Type sizes. At accessibility
sizes, use a topology-preserving rank outline as a secondary representation:

- group by topological rank;
- read node name/state followed by every exact prerequisite;
- keep sibling choices adjacent and diamonds named explicitly;
- anchored selection becomes the accessibility detail sheet.

This fallback is not the current cheapest-first depth-first outline. VoiceOver traversal is branch →
rank → node → state → prerequisites → grant/cost. Edges are never the only dependency statement.

## Acceptance

1. Every branch's displayed edge set equals its exact `requires` set; diamonds lose no parent.
2. Shuffling JSON arrays, changing prices or renaming nodes does not alter layout order except where
   the authored name itself changes visible text.
3. No cycles/dangling prerequisites, duplicate rank/column placements, clipped nodes or offscreen
   anchored details at 368×800 and 390×844.
4. Hold (15 nodes), Lexicon (19), Instruction (12), Instruments (8 independent roots) and every
   1–3-node specialist branch have native color/grayscale proofs.
5. A player can identify all currently available choices and the complete route to one locked node
   without opening each node individually.
6. Purchase, keeper-supplied, station-tier, missing-stock, stale commit and save/relaunch states update
   the same graph without changing node position.
7. VoiceOver and accessibility-large presentation communicate every prerequisite and purchase state
   without interpreting connector geometry.
8. No research surface renders the branch as full-width prose rows, decorative indentation or a
   cheapest-first shop list.

## Rollout

First prove one complex Workshop branch (**The Hold**) and one multi-root station branch (**Field
Instruments**) at phone size. Then replace `ResearchBranchScreen`/`ResearchOutline` for every branch
through the shared graph component. Do not maintain two ordinary presentations; the outline survives
only as the accessibility topology fallback.
