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
  visualReceiptID + visualSchemaVersion
  dominantGround + waterRelationship + materialDescriptor
  illumination
  suspendedAtmosphere?
  precipitation?
  flora[]
  causalVisualFacts[]
  entryDisclosure?
  firstMapCropReceipt
  descriptionGrammarVersion
  finalDescription
  sceneCompositorVersion
```

`receiptID` is a deterministic stable hash/typed identity over the run, source-page revision/definition,
generation seed and receipt schema; it is not another RNG draw. `finalDescription` is frozen beside the
structured facts so later copy-table or catalogue changes cannot rewrite what the player actually saw.
Versions are persisted independently: schema migration, prose grammar and scene compositor are not treated
as one global version.

`sourcePagePhysicalReceipt` contains only page dimensions, mark instance ID, opaque visual-asset key, Hand,
origin/cells/shape, authored ink, link endpoints and whether the mark was readable at bind. It cannot contain
`MarkContent`, `Sigil`, personal-compound expansion or a hidden semantic ID exposed as copy. The receipt may
freeze the legitimately visible page title and mark label/`??` exactly as shown at bind. Later Dictionary
learning does not retroactively change this historical arrival.

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

### Starter receipt fixtures

These are exact expected outputs of the ordinary grammar for the three current-generator starter receipts,
not hand-authored runtime exceptions. The same fact-selection and clause rules must produce them from the
receipt; changing Worldgen requires revalidating both the receipt and this copy.

| Page | Frozen request | Disclosed description fixture |
|---|---|---|
| Open Flats | seed 67 · Plains + Verdant | Broad sandy ground runs between shallow pools. Your Plains mark opened the terrain, while your Verdant mark spread low growth farther along the few wet and stony edges. |
| Rainwashed Shore | seed 26 · Archipelago | Stone shelves break a wide run of shallow and deep water. Your Archipelago mark divided the route, while sparse growth settled on the open stone. |
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

| Current state | Result |
|---|---|
| successful new draft/Collected bind | active run, History and pending ID are committed atomically |
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
3. Integrate accepted scene compositor from the frozen receipt in DEBUG and compare to map identities.
4. Promote native arrival only after all three starter worlds pass ordinary-phone review; the exact starter
   validation gate is `node Scripts/validate_starter_world_receipts.mjs`.
5. Add lifecycle resume/dismiss/return outcome tests.
6. Keep site extension behind a separate named visual decision; do not block checkpoints 1–5.

## Acceptance

1. The three starter worlds are distinguishable before reading their titles.
2. The description contains only actual, legitimately disclosed receipt facts.
3. Unknown runes, hidden sites/resources/travellers and identifiable rare/apex creatures never leak.
4. Image, description and first map region agree on material, water, atmosphere, light and ecology.
5. Same receipt renders identically after relaunch; similar receipts remain related.
6. No description requires interpreting a riddle to understand the world.

## Explicit exclusions

- no LLM/network prose generation at runtime;
- no second world-generation pass;
- no hidden-site glamour shot;
- no long character narration;
- no world-summary counts or pressure table;
- no dependency on tutorial implementation.
