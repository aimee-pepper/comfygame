# Found-writing breadth — Route marks, Site fragments and Working scraps

**Status:** Implementation-facing second slice under `found-writing-system-current.md`. Family
weights and route length are reversible playtest values; disclosure and reward boundaries are
current.

## Shared persisted payload

Extend each `FoundWritingRecord` tolerantly with optional family-specific facts:

- stable template/fact ID;
- exact generated prose, frozen at world generation;
- zero or more route points;
- optional site definition and instance IDs;
- optional recipe-lead ID;
- collection/reward-applied state where the reward is not already permanent elsewhere.

Old field notes decode with all optional facts absent. Prose never rerolls on load or anchored revisit.
Library labels are **Field note**, **Route mark**, **Site fragment** and **Working scrap** rather than
raw enum spelling.

## Route mark

### Eligibility

A Route mark needs a contiguous **2–4-tile** local segment beginning beside the writing tile that:

- is in the start-connected passable region;
- is not already fully revealed when content is selected;
- contains no traveller, diary/found writing, portal, site, cache, hazard, resource node/drop or
  active creature;
- does not point toward or name an undiscovered landmark;
- demonstrates a real nearby relationship: ordinary versus slow ground, a safe edge beside an
  impassable tile, or a turn around sight-blocking terrain.

If no honest segment exists, its weight flows to Field note.

### Collection effect

Collecting the mark reveals those exact terrain tiles and records them as a known local route. It
does not reveal beyond the segment, auto-walk the party, spend a turn beyond the movement that found
the writing, or expose contents. Because the eligible segment is content-free, ordinary tile reveal
cannot leak a hidden point of interest.

Generated prose uses direction relative to the page and the observed relation, for example:

- “I kept east where the mud thinned; the darker middle took twice the effort.”
- “The safe turn is north, along the rim—not through the hollow.”
- “Past the reeds, bend west before the broken stone closes the view.”

Direction is computed from the persisted route; prose does not guess from screen orientation.

## Site fragment

### Eligibility and host

A Site fragment is eligible only when its referenced site is legitimately revealed at collection:

- the writing occupies that visible site's tile/host; or
- the site was already discovered by ordinary movement before a separately placed fragment becomes
  collectable.

For deterministic generation, prefer the hosted form. A loose fragment must not depend on future
movement order to avoid disclosure leakage. If no suitable site/host exists, its weight flows to
Field note.

### Content and effect

Each `SiteDef` supplies 2–4 authored fragment lines appropriate before searching and, optionally,
1–2 lines usable only after exhaustion. The record freezes site family, instance and selected line.
Collection adds that prose beneath the already-known site in World History; it does not search the
site, reveal contents/yields, reduce search turns, consume the site's contents draw or add Stability.

Fragments may describe human use, visible construction or plainly observable damage. They may not
name hidden loot, a guarding species not yet seen, analysis-only cause or a remote linked site.

The current fifteen-site pre-search corpus and stable line IDs are in
`site-fragment-corpus-current.md`.

## Working scrap

### First-slice lead definition

A Working scrap teaches **one exact ordinary recipe** the player can meaningfully use now. It is not
generic research currency or a discount coupon.

Eligible recipes are:

- not already known;
- owned by a built station or currently available opening Workshop capability;
- past all meeting/station/tier prerequisites required to understand the family;
- not diary-exclusive, singular, endgame-held or dependent on an unimplemented system;
- craftable in principle from resources/material kinds that exist in the live catalogue, though the
  player need not currently own them.

Collection adds the stable recipe ID to that recipe system's known set and records the scrap in the
Library. It grants no item, research completion, station tier, ingredient, essence or analysis. The
remaining work—finding the stock and paying the recipe—is why this is a lead rather than a free craft.

If no recipe is eligible, Working scrap is absent and its weight flows to Field note. A selected
recipe is reserved by stable ID at generation so save/reload cannot reroll it; if another source
teaches it before collection, the scrap remains readable but applies no duplicate reward and grants
no compensation currency.

Initial eligible systems are Apothecary inference recipes and, once implemented, ordinary
Blacksmith/Tannery inference recipes. Traveller diary patterns, Channelworks attunements, Anchor
Frames, instruments and Great Work operations are excluded.

## Selection and placement order

1. Resolve the eligible family pools and exact payload before choosing a host.
2. Apply the current 55/20/15/10 other-writing weights; ineligible weight flows to Field note.
3. Reserve route points, site host and recipe ID before ordinary optional contents can conflict.
4. Place the writing under the shared reachable-distance promise.
5. Persist record and reward target with the run; collection is idempotent.

A guaranteed writing never fails because a specialist family cannot be placed. It becomes a Field
note rather than moving beyond the safe placement band.

## Verification

1. Route segments are 2–4 contiguous passable, content-free tiles and reveal no POI/enemy.
2. A Route mark survives save/load and anchored revisit with identical prose and points.
3. Every Site fragment references a site visible at collection and never changes its search state.
4. Every implemented site family with fragment content has a pre-search-safe authored line.
5. Working scraps choose only known-live, prerequisite-reachable, nonexclusive recipes.
6. Duplicate prior recipe learning makes collection reward-idempotent without reroll/compensation.
7. Exhausting all site/recipe eligibility still preserves one reachable writing through Field note.
8. Forced-family debug fixtures explain ineligibility rather than violating disclosure to satisfy
   the force.
