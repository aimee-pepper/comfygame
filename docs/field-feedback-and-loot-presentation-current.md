# Field consequence and loot feedback — current

**Status:** Game Design implementation authority for the first explorable-world feedback slice. It
supersedes the generic “object-to-counter” motion in `core-loop-causal-presentation-plan-current.md`.
**Priority:** first-three-world causal presentation, after rules-owned consequence previews exist and
before adding broader seeker instruments.
**Owners:** Game Design owns disclosure, transaction and timing semantics; Asset Design owns cue/icon
grammar; Engineering owns rules-owned previews, native placement and animation lifecycle; Aimee owns
ordinary-phone visual acceptance.
**Updated:** 21 August 2026

## Outcome

The field should communicate what a known adjacent space will do **before** the player commits, and should
make successful collection feel spatially connected to the object without sending icons flying across the
screen or turning exploration into receipt management.

## Adjacent consequence cues

Evaluate exactly the four cardinal adjacent cells from one rules-owned preview after movement, visibility,
collapse and local-world-state changes.

| Consequence | Party-edge cue | Meaning |
|---|---|---|
| known direct damage/affliction | red outer crescent on that direction | entering or triggering that visible space will cause a known harmful effect |
| extra movement turns | three grey inner drag lines on that direction | entry costs more than one ordinary world turn |
| both | grey inner lines plus red outer crescent | both consequences apply |

Placement is relative to the map, not the screen controls: north cue above the party marker, east to its
right, south below and west left. The cue stays inside the party cell boundary/edge allocation and never
covers an adjacent resource, traveller, portal or target marker.

### Disclosure

- Mud/rubble/dense-growth slowdown can be inferred on first legitimate full visibility.
- A flora-harm crescent appears only after that campaign has been harmed by the exact flora
  species/defence, or a real earned recognition contribution identifies it.
- Hidden, fringe-only and unrevealed tiles never create cues.
- An undiscovered site/resource/creature does not become visible merely because its tile would have a
  consequence.
- Collapse/impassability uses the actual current tile truth; stale cues disappear in the same state update.

The cue is advisory. Use Tile/movement validates again atomically. A changed space may refuse with accurate
context without applying the stale predicted outcome.

### Look

**Look → direction** spends no turn and returns one compact structured result:

1. known terrain/material identity;
2. passable or exact blocker;
3. exact current entry-turn cost;
4. known harm/affliction source and effect;
5. visible usable content, if any.

Refusal copy must be selected from the actual blocker. At minimum, deep water, chasm, collapsed/crumbled
ground, solid obstruction and out-of-bounds each have distinct plain-language copy. “The ground crumbled
away” is legal only when ground actually collapsed.

## Successful pickup animation

### Why local rise is the default

A long object-to-satchel/counter flight creates visual clutter, crosses unrelated cells and implies that
the animation's destination owns the transaction. A short local rise preserves the cause—“I picked up the
thing here”—and lets the HUD quantity update independently. It is also robust when the compact carried
summary changes layout.

### Exact motion

On a successful committed pickup:

1. Update the authoritative quantity/ownership immediately. Animation never delays or owns the mutation.
2. Spawn the collected family/instance icon at the center of the source tile. If the source graphic was
   consumed, the feedback icon replaces it in the same frame so there is no blank flash.
3. Over **450 ms**, raise the icon **1.5 tile heights** along the screen's vertical axis.
4. Hold full opacity for the first 180 ms, then fade to zero over the remaining 270 ms.
5. A restrained scale `0.90 → 1.05 → 0.95` is permitted; rotation, bounce, sparkle explosion and a
   screen-length trail are not.
6. Display `×N` beside the icon only when one transaction awarded more than one unit.
7. Pulse the corresponding compact carried counter once when its value changes, but draw no connecting
   line and do not move the feedback icon toward it.

The motion is nonblocking. The player may move or open another valid surface; the feedback may finish or
be cancelled without affecting the receipt. It never spends an extra world turn and never plays on a
refused or duplicated transaction.

### Edge and burst behavior

- If a 1.5-tile rise would leave the map viewport, shorten the rise to the largest wholly visible distance.
  Do not reverse it downward or let it cover the world HUD.
- Same-family awards committed together produce one icon with aggregate `×N`.
- Different families committed together use at most three icons, staggered 70 ms and separated by a small
  horizontal offset within the source tile. Four or more families collapse to the three most
  consequential visible identities plus `+N kinds`; the return recap remains the complete record.
- An unidentified object uses its legitimate unknown silhouette; the animation cannot reveal its name.
- Reduced-motion presentation uses a 250 ms local opacity/scale confirmation with no translation. This is
  part of correct motion behavior, not a separate broad accessibility redesign.

### Contexts

- **World resource node/flora:** play at the harvested tile.
- **Loose item/page:** play at the recovered tile.
- **Creature victory:** do not spray every body part over the combat screen. After return to the map, one
  compact remains/recovery confirmation may play at the defeated encounter cell; complete creature
  materials are shown in the combat result/return collection.
- **Site multi-loot:** play one compact chest/site confirmation at the site; the anchored result tray owns
  the multi-object breakdown.
- **Home crafting/trade:** use destination-local result feedback, not this field animation.

## Asset Design packet

Provide one integrated native-scale sheet containing:

1. party marker with north/east/south/west harm cues;
2. north/east/south/west drag cues;
3. combined harm+drag on two different directions at once;
4. cues on dark, light, water-edge and growth-heavy visible backgrounds;
5. cue-free hidden/fringe cells;
6. 16px/actual-map resource, creature-material, item, unknown-page and unknown-object feedback icons;
7. the 0 ms, 180 ms and 450 ms pickup frames at ordinary and top-edge positions;
8. color and grayscale/value proof.

The visual test must be inspected on the same ordinary-phone scale as the native map. A contact sheet at a
larger design scale is insufficient because edge collisions and value contrast are the risk.

## Engineering checkpoints

1. Add one pure adjacent-consequence preview from current rules and campaign knowledge; no renderer
   inference.
2. Reuse that preview for Look copy and cue state; add exact contextual impassable reasons.
3. Integrate static cue shapes at the four party edges and prove no fog/content disclosure.
4. Add local pickup feedback driven by successful transaction receipts, with dedupe/relaunch protection.
5. Add burst aggregation and map-edge clamping.
6. Capture actual-phone combined-cue and top-edge pickup evidence; Aimee accepts/tunes visibility before
   later seeker instruments begin.

## Acceptance

1. Every cue corresponds to the current rules-owned result for that exact direction.
2. Known harmful flora cues appear after legitimate learning and not before.
3. Slow+harm remains readable together on all four directions without covering adjacent content.
4. Look and failed movement name deep water, chasm and collapse distinctly.
5. Pickup ownership is committed exactly once even if animation is cancelled, navigation changes or the
   app relaunches.
6. Nineteen Hides awarded in one receipt produce one local `Hides ×19` feedback, not nineteen animations.
7. Top-edge pickup remains within the map viewport.
8. Field feedback does not expose unidentified content, clear fog, alter minimap POIs or create extra
   counters.

## Explicit exclusions

- no full-screen loot rain;
- no icon flying to the top of the screen;
- no haptics/audio dependency for understanding;
- no seeker instrument in this checkpoint;
- no new hazard types merely to populate the cue grammar;
- no animation-driven game mutation.
