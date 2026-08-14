# DEBUG combat-tree route explorer — current design

**Status:** staged testing surface; Stage A topology/route proof is active, later fixture tooling is
added only when required by production consumer implementation  
**Owner:** Game Design owns test questions and disclosure; Engineering owns isolated state and rules
integration; Asset Design may refine functional layout/accessibility only.  
**Priority:** ships with the combat-v2 DEBUG gate, before ordinary-save promotion; not a tutorial.

## Purpose

The combat trees contain 72 nodes, hundreds of legal capstone routes and effects that operate in
field contact, encounter opening, direct hits, mitigation, consequences and economy. A static graph
proves topology but cannot show whether a route creates the intended play. The explorer lets Aimee:

- inspect every legal route and exact node effect;
- assemble a temporary build without earning or spending campaign points;
- compare two builds under the same actor, party, foe and saved-RNG fixture;
- launch a controlled encounter or field-contact scenario; and
- export a compact receipt suitable for a bug report.

It never teaches the player what to choose and never records tutorial progress.

## Delivery stages

This brief describes the eventual DEBUG support surface, **not one prerequisite mega-feature**.

- **Stage A — active now:** the native 24-node graph for each tree, exact connectors and Effect copy,
  8/17/25 point presets, local stable-ID ownership, legal Learn/reset, selected detail and proof that
  ordinary campaign state cannot mutate. This is the only explorer scope required before Engineering
  begins production stable-ID ownership, migration, purchase and node consumers.
- **Stage B — consumer work:** add the smallest deterministic fixture and contribution receipt needed
  to prove each implemented group of effects. Do not build unused scenario families in advance.
- **Stage C — comparison/export:** A/B snapshots, route enumeration, controlled-run automation and
  reporter attachment become worthwhile after the underlying consumers are real and stable.

Later stages may not delay production consumers, encounter scaling or another higher live-roadmap
item. Accessibility-size reflow and exhaustive assistive-technology acceptance wait for the broader UI
direction to stabilize unless Aimee explicitly promotes a concrete issue.

## Isolation boundary

Opening the explorer creates a `CombatRouteSandbox` copied from a selected actor's current legal
combat facts. Sandbox mutations never write campaign ownership, unspent points, choices, equipment,
HP, inventory, outcome IDs, bestiary knowledge, gambits or world state.

There are exactly two exits:

- **Discard** — always available; destroys the sandbox;
- **Apply through normal rules…** — DEBUG-only explicit bridge that previews the exact ordinary
  Spring-respec/purchase transactions and costs before a second confirmation. It is absent when the
  selected route cannot be reached legally from the campaign state. There is no silent “save build.”

Force-quit/relaunch discards an uncommitted sandbox. Exporting a receipt does not commit it.

## Screen structure

### 1. Fixture bar

Compact selectors choose:

- actor and exact persisted equipment/profile;
- party size/composition and formation;
- scenario family: field contact, approach, creature ambush, ordinary 2v1, ordinary 5v3, apex;
- deterministic fixture/seed;
- tree tab: Offense, Defense, Craft.

Selectors open anchored sheets/popovers rather than permanent full-width lists. Hidden creature facts
remain hidden in ordinary campaign mode; DEBUG clearly labels any revealed fixture facts.

### 2. True graph

Render the exact 24-node fan-and-fork graph from `combat-tree-v2-authority.json`. The explorer adds
testing state without changing the ordinary graph grammar:

- owned in campaign;
- sandbox-added;
- legal next;
- blocked, with every unsatisfied alternative parent/gate;
- selected detail;
- active technique and capstone markers.

One-tap **Add** is allowed only for a currently legal node and consumes one sandbox point. **Remove**
removes the selected node plus every sandbox-added dependent that would become disconnected; the
confirmation names those dependents. Campaign-owned nodes cannot be removed except after enabling a
separate **Simulate full respec** switch, which remains sandbox-only.

### 3. Route tools

- **Points:** stepper for temporary available points; default equals the selected actor's earned
  total, with an explicit unlimited-testing toggle.
- **Capstone routes:** choose a capstone to enumerate legal minimum routes, sorted first by fewest
  changes from the current sandbox, then stable node-ID order. Route count is shown; the UI never
  labels one “best.”
- **Apply route to sandbox:** previews added/removed nodes and permanent-choice prompts, then commits
  only to sandbox state.
- **A/B snapshot:** freeze current sandbox as A or B. Both snapshots use the exact same fixture and
  RNG sequence.

### 4. Observable comparison

The comparison is organized by rules phase, not by raw model fields:

1. field/contact;
2. opening order and disclosure;
3. actor derived stats/actions;
4. direct-hit preview range;
5. mitigation/survival;
6. secondary consequence queue;
7. encounter/expedition receipts and external yield.

Each changed row names the contributing stable node(s), before/after value and applicability. It
must say **No observable difference in this fixture** when a legitimate node has no effect here; it
must never imply that the node is inert globally. Selecting that row offers the closest controlled
fixture in which the node is expected to matter.

No comparison exposes undiscovered campaign information. Controlled fixtures are synthetic and
labelled; a copied live encounter uses only facts already disclosed to that save.

## Controlled run

**Run fixture** starts a throwaway encounter/field simulation using the same production rules and
the selected sandbox build. It records actions, rolls and node-contribution receipts. It cannot
award XP, loot, pages, travellers, knowledge, currency or outcome progress. Leaving returns to the
unchanged explorer state.

The explorer may also run both A and B automatically in headless deterministic mode and summarize
the first divergence. This summary is evidence, not a balance score.

## Export and reporter integration

**Export route receipt** writes versioned JSON plus a compact text summary containing:

- graph/effect-copy versions and hashes;
- actor identity kind, level, equipment stable profile IDs and formation;
- fixture ID/seed and disclosed scenario facts;
- ordered A/B node IDs and permanent choices;
- legal-route validation and point totals;
- first observable divergence and contribution ledger;
- app/build/save-slot diagnostic IDs without player-authored save contents.

The floating DEBUG bug reporter may attach this receipt and its screenshot. Aimee still assigns no
severity; the report enters the ordinary untriaged queue.

## Eventual complete-explorer acceptance gates

Only gates 1, 2 (legal-next and capstone legality, not enumeration UI), the campaign-isolation portion
of 3, the ordinary-phone portion of 8, and 9 apply to Stage A. The remaining gates attach to the later
stage that actually implements their corresponding tool.

1. All 72 stable IDs appear exactly once across the three graph tabs and use the exact current Effect
   copy and optional technique grant.
2. Legal-next results, capstone gates and route enumeration match the authority/audit for every
   subset tested; Offense/Defense/Craft retain 79/67/66 minimum-route counts for the frozen corpus.
3. Add/remove, route application, permanent Heat/Caustic/Light choice and full-respec simulation are
   atomic sandbox operations; cancel or relaunch mutates no campaign fact.
4. A/B consumes identical fixture facts and saved-RNG sequence. Reversing A/B reverses the displayed
   delta without changing either outcome.
5. Every node has at least one linked positive fixture and counterfactual fixture; the comparison
   reads a production consumer rather than merely showing a changed loadout field.
6. Controlled runs grant no durable reward, discovery, expenditure or outcome receipt.
7. Export round-trips exact stable IDs, choices, versions and fixture, and attaches idempotently to
   the reporter queue.
8. On ordinary 368×800, the full topology remains a graph; current controls and selected detail are
   usable without obscuring nodes, the branching reads clearly and the surface looks intentional
   enough for playtesting. Accessibility-size reflow and exhaustive VoiceOver ordering are deferred
   until the broader UI direction is stable.
9. Release builds contain no route explorer, unlimited-points switch or synthetic hidden facts.

## Non-goals

- no automatic “optimal build” recommendation;
- no DPS tier list or single aggregate power score;
- no campaign-save editor disguised as testing;
- no glyph-art requirement beyond labelled functional placeholders;
- no tutorial, coach mark, first-point modal or progression interruption.
