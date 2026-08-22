# World arrival causal reveal — current

**Status:** Game Design implementation authority for the native entry splash. Uses the accepted AssetLab
lifecycle-splash grammar but adds a game-owned fact/description contract.
**Priority:** first-three-world causal presentation after Starter World Pages bind correctly and before
late-campaign splash variants.
**Owners:** Game Design owns disclosed facts and prose grammar; Engineering owns frozen input adapter and
native lifecycle; Asset Design owns deterministic scene composition; Aimee owns phone acceptance.
**Updated:** 21 August 2026

## Outcome

The arrival screen is the first answer to “what did my page make?” It combines a dynamically composed
image with a short concrete description of the same bound world. It is not a loading spinner, parameter
receipt, riddle, lore monologue or independent world generator.

## Frozen input

One `WorldArrivalReceipt` is created from the successfully bound world's persisted identity and reused on
relaunch. It contains, by stable ID/value rather than display text:

- world identity/seed and source Page identity/thumbnail receipt;
- actual resolved ground/material and water relationship;
- actual illumination and atmosphere medium/density;
- actual 1–4 flora species identities plus coverage/habit summaries;
- actual authored-vs-open provenance for eligible visual dimensions;
- entry-region visible facts;
- lifecycle outcome variant when reused on exit/return.

The splash consumes no new RNG and cannot select facts by rerunning Worldgen. If a field is absent or
unknown, omit its layer/sentence clause rather than substituting an invented generic fact.

### Exact persisted receipt

The v1 persisted object freezes:

```text
WorldArrivalReceipt
  schemaVersion
  receiptID
  runIndex + generationSeed
  sourcePagePhysicalReceipt
  rulesVisualReceiptID + rulesVisualSchemaVersion
  sceneReceiptVersion + sceneReceiptHash
  sceneReceipt
    worldSeed
    sourcePage
    dominantGround + waterRelationship + materialDescriptor
    illumination
    suspendedAtmosphere
    precipitation
    flora[]
    causalVisualFacts[]
    entryDisclosure?
    description
    firstMapCropReceipt
  descriptionGrammarVersion
  sceneCompositorVersion
```

`receiptID` is a deterministic stable hash/typed identity over the run, source-page revision/definition,
generation seed and receipt schema; it is not another RNG draw. `sceneReceipt` is the exact sanitized input
owned by the accepted compositor, not a screenshot and not a later projection from raw rules values. Its
`description` is the final frozen string, so later copy-table or catalogue changes cannot rewrite what the
player actually saw.
Versions are persisted independently: schema migration, prose grammar and scene compositor are not treated
as one global version.

The scene receipt stores already-resolved bands, motion classes, colors and relative crop cells. It does not
store a raw atmosphere density and ask a future renderer to choose a band, or preserve an optional
precipitation value that a future adapter may reinterpret. Engineering may keep richer rules provenance
beside it, but the renderer consumes one versioned byte-stable scene receipt and verifies its canonical hash.
The current pre-UI source prototype with empty causal facts, generic prose and a parallel field shape is not
presentation-eligible; it must not be promoted merely because it decodes.

Native promotion additionally freezes one `WorldArrivalRenderedSceneReceipt` before the bind mutation. It
pins the accepted visual program, the sanitized scene-receipt hash, a closed ordered integer `rect-v1`
command list and the resulting 160×100 RGBA hash. The exact command/conformance contract lives in
`world-arrival-asset-packet-current.md`. Active run and History retain that rendered receipt with the rich
arrival receipt, so display never re-runs the visual program and a later visual version need not keep old
generation code merely to preserve existing worlds.

`sourcePagePhysicalReceipt` contains only page dimensions, mark instance ID, opaque visual-asset key, Hand,
origin/cells/shape, authored ink, link endpoints and whether the mark was readable at bind. It cannot contain
`MarkContent`, `Sigil`, personal-compound expansion or a hidden semantic ID exposed as copy. The receipt may
freeze the legitimately visible page title and mark label/`??` exactly as shown at bind. Later Dictionary
learning does not retroactively change this historical arrival.

Rich rules provenance separately freezes each causal candidate's page mark ID, optional known semantic key,
bind-time display label and insertion order so the description can be generated without guessing. Those
fields do not expand the Asset ABI: the sanitized scene retains only the accepted five-field causal record
(`markID`, scope, contribution, result band and without-authored band), includes known/eligible facts only,
and treats `markID` as either the safe known semantic key or an opaque candidate key. The final frozen
description—not Asset—is the player-facing use of the rich label/order data.

The exact same receipt identity and byte-equivalent object is stored on the active `WorldRun` and its
immutable Library History record. One side may not regenerate or summarize the other. The run is the live
presentation owner; History is the permanent provenance owner after the run ends.

## Dynamic image

Use the accepted framed book-illustration/tableau composition and the same canonical asset identities as
the map:

1. ground/water establish the scene;
2. light/atmosphere grade it;
3. flora coverage and silhouettes establish ecology;
4. source Page thumbnail, title and action frame the reveal.

Creature ambience is omitted from native v1. A later extension may accept a separately sanitized visible
anatomy class, but complete generated cast identity is not part of the base receipt.

The scene is deterministic for the receipt. Two worlds similar in resolved visual facts must remain
visual relatives; opposed facts should separate proportionally. Do not add a novelty recolor because the
previous world looked similar.

### Site pin — intentionally open

It may be desirable for a real site to appear in the tableau, but the exact disclosure rule needs visual
playtesting. Record this as an open extension, not a blocker for the base splash.

Until settled, native v1 may depict only:

- a site already visible/disclosed from the actual entry region; or
- disclosure-neutral terrain structure that does not identify or locate a hidden site.

It may not pick an undiscovered site merely because it makes a prettier splash. Later options to test are
entry-visible only, distant non-identifying silhouette, or explicitly authored World-Page landmark.

## Generated description

Exact deterministic selection, thresholds, causal-contribution rules, copy tables and prohibited register are
owned by `world-arrival-description-grammar-current.md`. The summary below is subordinate to that grammar.

Generate exactly **two short sentences** in v1, 18–55 words total, from structured facts. The first sentence
grounds the place; the second names either contributing known authorship or one material environmental
relationship. A third tension sentence is held until the two-sentence surface proves insufficient in play.

### Clause order

1. dominant ground/water form;
2. illumination/air fact if visually/materially consequential;
3. ecological distribution or authored tension.

Examples of the intended register:

> Low grassland spreads between shallow pools. Clear light reaches clustered silver-leaf growth along the
> wet edges.

> Broken stone shelves close around narrow paths. Warm ash hangs in still air, and sparse rosettes gather
> wherever the floor opens.

These are readily parseable world descriptions. Do not use aphorisms, second-person prophecy, character
voice, metaphor that replaces facts, or phrases such as “the land remembers,” “a boundary is useful
evidence,” or “innocence.”

### Authored causality

When a resolved fact was causally changed by a known mark, the description uses the frozen contribution
kind: `reshaped`, `increased`, `reduced` or `none`. An increase may say `Your Verdant mark spread low growth
farther`; it may not say the mark created or drew in a family that the same seed already supplied. Unknown
marks never reveal their meaning. When a dimension was left open, say so only if the uncertainty affects
preparation or is central to the reveal; do not list every random dimension.

Causal ownership is mark-level and bind-time frozen. Self-contained Compound/legacy-rune/personal-Compound
marks and connected atomic **source** marks may own facts; target anchors and qualifier marks do not receive
separate causal credit. Qualifiers travel with their source candidate. The same-seed counterfactual removes
that complete candidate, retains all actual rolls for already-unwritten subjects, and uses the matching
target-keyed result from one empty-page baseline roll only for a newly silent subject. This prevents the
current skip-based unwritten stream from shifting unrelated answers. Candidate order is the frozen page
insertion order, not a stable-ID sort.

The closed typed scopes are `ground`, `water`, `flora`, `resource`, `light` and `atmosphere`. `resource` is
required for legitimate known authorship such as Ore; it does not disclose a random unrequested resource.
One mark may change several scopes but can be named only once in the two-sentence description, using the
earliest scope in the exact grammar order.

### Counterfactual generation boundary

The actual world is generated once and remains the only playable result. Causal classification may run pure
same-seed counterfactual **summary** passes during the successful bind transaction; those are analysis, not
replacement worlds. They receive the exact actual-generation inputs that could affect topology/flora/resource
placement (generator version, source page with one candidate removed, seed, scale, tuning, Library/write-host
state, starter guarantee, selected wild-page placement and fresh-expedition flags). Pressure input freezes
the actual world's rolled sigils plus one full-empty-page roll keyed by target: existing unwritten targets
retain their exact actual sigils, while only targets made newly silent by candidate removal receive their
empty-baseline sigils. The receipt factory is
not allowed to reconstruct missing inputs later from `book + seed` alone.

The summary path reuses the production generation stages and their existing derived RNG salts through the
last scope it needs. It may skip later sites/creatures/travellers only when those stages cannot feed back into
the compared ground, water, flora or world-resource result. Light/atmosphere-only candidates compare exact
resolved readings without generating a second map. Cache one summary per candidate-removed page fingerprint;
never regenerate separately for every scope changed by the same mark.

This is an extraction of shared production stages, not a second hand-written world model. `Worldgen.generate`
and the counterfactual summary factory must call the same deterministic topology, flora and resource-stage
functions with the same typed inputs and derived salts. The summary factory returns only immutable aggregate
bands/counts needed by the causal classifier; it cannot construct or persist `World`, `WorldRun` or tile
identity, place encounters/travellers/sites after its last required stage, award anything, or mutate campaign
state. A production-stage change therefore changes both paths together and invalidates stale frozen receipts
rather than allowing a visually plausible imitation to drift from actual generation.

Evaluate candidates in frozen page order. Once the first two distinct sentence candidates and the earliest
eligible structural fact are known, later candidates may be skipped only if their registered scopes cannot
precede either frozen selection. Otherwise evaluation continues. DEBUG records counterfactual count and
elapsed time so correctness does not silently become another long black-screen wait. A counterfactual failure
makes Bind an atomic no-op before Essence/page/ink/Field-Kit mutation; it never falls back to `wasWritten`.

### Starter receipt fixtures

These are exact expected outputs of the ordinary grammar for the three current-generator starter receipts,
not hand-authored runtime exceptions. The same fact-selection and clause rules must produce them from the
receipt; changing Worldgen requires revalidating both the receipt and this copy.

| Page | Frozen request | Disclosed description fixture |
|---|---|---|
| Open Flats | seed 67 · Plains + Verdant | Broad sandy ground runs between shallow pools. Your Plains mark opened the terrain, while your Verdant mark spread low growth farther along the few wet and stony edges. |
| Rainwashed Shore | seed 26 · Archipelago | Stone shelves break a wide run of shallow and deep water. Your Archipelago mark divided the route, while only the ground nearest the entry remained clearly visible. |
| Stone Hollow | seed 23 · Caverns + Ore | Stone closes around narrow paths and wet hollows. Your Caverns mark shaped the enclosure, while your Ore mark made ore more plentiful. |

The image may depict the matching flora shapes but these descriptions do not name creature identities,
resources other than the causally increased Ore relationship, hidden sites, portal locations or traveller
candidates. None of the starter sites is visible merely because Worldgen placed it elsewhere on the map.

## Lifecycle and loading boundary

App launch shows a separate correctly aligned functional loading surface. After selecting a save, load
progress may continue there. The world arrival reveal appears only after an expedition world is bound and
ready; it cannot conceal unbounded work behind a fake completed bar.

Dismissal enters the exact saved map. Relaunch during the reveal reproduces it; relaunch after dismissal
does not force it again unless current lifecycle authority explicitly resumes the pending transition.
Exit/return may reuse the scene with actual outcome treatment, but cannot rewrite entry history.

### Pending-reveal state machine

`WorldsState` stores an optional typed `pendingWorldArrivalReceiptID`, not a free Boolean and not a second
receipt copy.

Receipt persistence may land before the native reveal surface for source isolation, but **pending activation
and action blocking may not**. Until an actual reachable **Enter world** control owns the root presentation,
new binds freeze/store the receipt without creating an active pending ID. The one presentation-availability
authority, pending creation, root routing, action guard and dismissal tests are enabled atomically in the
native integration checkpoint. There is no shippable intermediate build in which a player can bind a world,
receive an invisible pending state and be unable to move.

| Current state | Result |
|---|---|
| successful new draft/Collected bind | validated rendered scene, active run, History and pending ID are committed atomically |
| Born anchored new bind | same new-world reveal behavior; anchoring does not skip it |
| anchored-realm revisit | no new v1 arrival reveal; the saved realm is not rebound or regenerated |
| app killed before **Enter world** | matching pending receipt appears again on relaunch |
| **Enter world** succeeds | clear only the matching pending ID, then show the already-saved map |
| app killed after dismissal | active map resumes; arrival does not replay |
| double dismissal / stale UI action | idempotent no-op after the first matching clear |
| pending ID does not match the active run receipt | clear/reconcile the orphan; never show another run's receipt |
| return/defeat state has no active run | clear any orphaned pending ID; History receipt remains immutable |
| legacy active run decodes with no arrival receipt | preserve the run and enter its map; do not invent or replay an arrival |

World movement/use/combat actions are unavailable while the matching reveal owns the root presentation;
**Enter world** is the only action that dismisses it. Dismissal spends no world turn and mutates no map,
receipt, History, RNG, page or resource. It only clears the matching pending ID in a flushed save mutation.
The guard covers every direct action path—not only directional stepping—including travel-to-tile, tile use,
harvest, search, survey, contact/recruit, carried-item use, loot or World-Page take/swap, anchoring and portal
return. A DEBUG or stale view action cannot mutate the run behind the reveal.

`firstMapCropReceipt` is frozen from the same party-aware current-visibility and terrain-memory authority as
the first native map frame. It is not a projection of `Tile.isRevealed` alone. A full cell may contain
terrain, elevation and flora; a fringe cell contains terrain and elevation but no flora, content or entity;
a remembered cell contains its remembered terrain and elevation but no transient flora, content or entity;
and a hidden cell is a typed hidden case with no ground, elevation, flora or adjacency payload. Hidden stone
and hidden deep water therefore serialize and render identically apart from their crop coordinate. The
transient fringe remains transient and is not written back into `Tile.isRevealed` merely to build the
receipt. Persisting a real hidden ground value and relying on the renderer to ignore it is not disclosure
safety.

The version-2 compositor JSON ABI is exact rather than dependent on a language's default optional encoding:

- the root payload always includes `entryDisclosure`, as either its typed object or explicit `null`;
- full, fringe and remembered crop cells contain exactly `x`, `y`, `ground`, `elevation`,
  `floraStableID`, `visibility`, with `floraStableID: null` when disclosure forbids flora;
- hidden crop cells contain exactly `x`, `y`, `visibility`;
- `dominantGround` is the grammar's `dominantDryGroundID`, excluding water, deep water and chasm and using
  its frozen tie order; a malformed world with no dry ground fails receipt construction rather than
  fabricating a material;
- the canonical scene hash covers this normalized encoded shape, including explicit nulls, and the Asset
  validator consumes the same versioned shape before native presentation may be enabled.

The legacy decode policy deliberately prefers a missing reveal over reconstructing one from a map the player
may already have explored or collapsed. New binds always require the complete receipt. A future schema that
cannot decode a new receipt follows the explicit save-version policy; it never falls back to plausible art or
new prose under an old receipt ID.

## Asset Design packet

1. Open Flats, Rainwashed Shore and Stone Hollow from their exact selected seeds and receipt fixtures, with image and concrete
   generated-description region together at 368×800.
2. One near-pair and one far-pair proving relative visual diversity.
3. One ash/open-color world proving ash does not turn the world black.
4. One site-free scene and one entry-visible-site candidate labelled as the open test, not settled native
   behavior.
5. First visible map crop beside each splash to prove camera/palette/ecology continuity.
6. Longest valid 55-word description and smallest-text ordinary case without clipping/scrolling.

## Engineering checkpoints

1. Add pure frozen `WorldArrivalReceipt` adapter and persistence; no native visual promotion.
2. Add rules-owned prose tokens/grammar with snapshot fixtures and prohibited-metaphor validation.
3. Export the accepted compositor's canonical command conformance corpus; mechanically port the command
   adapter and require byte-equal command JSON plus exact fixture pixels.
4. Freeze the validated `WorldArrivalRenderedSceneReceipt` on active run and History before the bind
   mutation; render only its closed command list in the native reveal.
5. Promote native arrival only after all three starter worlds pass ordinary-phone review; the exact starter
   validation gate is `node Scripts/validate_starter_world_receipts.mjs`.
6. Add lifecycle resume/dismiss/return outcome tests.
7. Keep site extension behind a separate named visual decision; do not block checkpoints 1–6.

## Acceptance

1. The three starter worlds are distinguishable before reading their titles.
2. The description contains only actual, legitimately disclosed receipt facts.
3. Unknown runes, hidden sites/resources/travellers and identifiable rare/apex creatures never leak.
4. Image, description and first map region agree on material, water, atmosphere, light and ecology.
5. Same receipt renders identically after relaunch; similar receipts remain related.
6. No description requires interpreting a riddle to understand the world.

## Explicit exclusions

- no LLM/network prose generation at runtime;
- no second **playable** world, renderer-side generation or post-bind reroll; the pure bind-time causal
  summary passes above are the sole permitted counterfactual generation;
- no hidden-site glamour shot;
- no long character narration;
- no world-summary counts or pressure table;
- no dependency on tutorial implementation.
