# Survey Needle — current design

**Status:** Game Design implementation authority for the first resource-seeking field instrument
**Owner:** Mara's Survey Post
**Roadmap position:** after adjacent consequence/Look feedback and ordinary resource-extraction capability;
it does not pre-empt the first-three-world loop
**Updated:** 21 August 2026

## Player promise

The **Survey Needle** is a reusable Field Kit instrument tuned at Home to one known World Resource. In a
world, one use spends one world turn and reports a broad direction and signal strength toward the nearest
remaining instance of that resource. It supports a deliberate hunt without clearing fog, naming a hidden
tile, drawing a route or guaranteeing that the player can harvest what they find.

Example:

> **Gold — strong signal, northeast.** The needle pulls hard between north and east.

The instrument is a planning aid, not a substitute for writing. If the player knows Gold exists but lacks
the Field Pick capability to extract it, the Needle can still lead them to the node; Look and interaction
then truthfully explain the missing capability. That makes extraction progression motivating rather than
hiding the resource until after the upgrade.

## Identity and acquisition

- Stable item ID: `survey_needle`.
- Player-facing class: **Field instrument**; exact, reusable Item; uncommon frame.
- Recipe appears at Mara's built Survey Post: `1 Copper + 1 Quartz + 1 Fibre + 8 Essence`.
- Crafting creates one exact instrument and uses the ordinary atomic output-capacity transaction.
- It occupies one prepared Field Kit item slot. It is not consumed on use and requires no ammunition,
  durability or repair.
- Trading Post may buy/sell the exact untuned or tuned object only after its catalogue entry is live. It
  never appears as ordinary rotating stock before Mara teaches its purpose.

The recipe's ingredients are fixed construction inputs, not component-quality sockets. Their quality band
does not change precision or appearance in the first slice.

## Tuning at Home

The Survey Post exposes **Tune instrument** as an anchored item action, not a separate full-screen list.

1. Select one exact stored/prepared Survey Needle.
2. Select one eligible World Resource from a six-across icon grid.
3. Preview the exact before/after target.
4. Confirm. Tuning costs `0 Essence`, consumes no resource and preserves the exact item identity.

Retuning is allowed any number of times at Home and never during an expedition. A prepared Needle keeps its
target across departures and relaunch. The player does not need to remove it from the Field Kit to retune it.

A resource is eligible when either:

- the campaign has legitimately encountered/collected that Resource ID; or
- the campaign owns a writable rune whose canonical resolved effect can explicitly request that Resource
  ID.

Thus owning the Gold rune is sufficient to tune for Gold before the first successful mining trip. Displaying
the resource name here reveals nothing the campaign did not already know. Unknown resource IDs, Creature
materials, Items, Diary/World Pages, sites, people, portals, Motes, quest objects and arbitrary terrain are
ineligible.

Raw Essence is eligible after the campaign's first legitimate Raw Essence knowledge/collection receipt.
Rift-glass is eligible only if it has an ordinary generated/harvestable resource identity in the current
campaign; authored singular Rift-glass rewards are not signals.

## Exact use transaction

In the Field Kit popover, an eligible tuned Needle offers **Seek · [Resource]**.

On use:

1. Revalidate the exact carried instance, tuned target, current world phase and party state.
2. Find all uncollected target-resource nodes in the current world that have a legal interaction position.
3. For each node, find the shortest currently walkable path from the party to any legal interaction position.
   The resource tile itself need not be enterable if ordinary harvesting interacts from an adjacent tile.
4. Choose the shortest path; equal lengths use stable tile order.
5. Spend exactly one world turn through the ordinary world-action transaction.
6. Freeze and show the signal receipt. Do not mutate the map, resource, fog or minimap.

If no target has a legal interaction path, the attempted use still spends one turn and returns:

> **No answering trace.** The needle cannot find [Resource] from here.

This is a legitimate field reading, not a stale-item failure. By contrast, a missing/stale Needle, untuned
instrument, combat state or invalid world phase refuses with zero turn spent and no mutation.

Deep-water nodes count only when an existing legal interaction position is reachable; the Needle does not
pretend the party can stand in deep water. A missing mining/harvest capability does not suppress an otherwise
reachable node because discovering that capability boundary is part of the intended progression.

## Signal grammar

The first slice quantizes the chosen path's initial direction to one of eight sectors:

`N, NE, E, SE, S, SW, W, NW`.

When the shortest path begins cardinally, use that cardinal sector. When equally short first steps exist in
two adjacent cardinal directions, combine them into the intervening diagonal sector. Stable grid order
resolves non-adjacent/equivalent ambiguity before presentation.

Strength uses broad path-length bands after reaching the legal interaction position:

| Remaining path steps | Signal | Presentation |
|---:|---|---|
| 0–2 | strong | firm pull; three short pulses |
| 3–8 | steady | clear pull; two pulses |
| 9+ | faint | slight pull; one pulse |

The UI never prints the step count, target coordinate, route or number of matching nodes. Signal strength is
not a probability and has no random wobble. Moving after a reading does not keep a live compass running; the
player must spend another turn for a new reading. This keeps seeking a deliberate stability trade rather
than permanent automatic navigation.

## Visual and interface language

- Show a compact brass-and-quartz needle immediately beside/around the party marker for 1.2 seconds.
- The needle points into the selected eight-way sector; one/two/three short pale-gold rings encode
  faint/steady/strong redundantly with the text result.
- It must remain visually distinct from Seamlight's continuous pale-blue portal arcs and the red/grey
  adjacent consequence cues.
- Do not draw a line beyond the party cell, highlight fog, pulse the hidden resource, or add a minimap POI.
- The Field Kit anchored detail names the tuned target, reusable status, one-turn cost and last reading.
- An untuned Needle says **Tune at Mara's Survey Post** and cannot be armed.

Motion is confirmation, not authority. If interrupted, the frozen text result remains in the field log and
the turn has still been spent. The effect never blocks movement after the transaction commits.

## Frozen data

```text
SurveyNeedleProfile {
  stableInstanceID
  targetResourceID?
  tuningVersion
}

SurveySignalReceipt {
  actionReceiptID
  needleStableInstanceID
  targetResourceID
  result             // signal | noAnsweringTrace
  sector?
  strength?
  rulesVersion
}
```

The receipt deliberately stores sector/strength rather than hidden target coordinates or path tiles. The
world action may use those transiently to calculate the reading, but save/history/debug disclosure must not
turn the instrument into an accidental map reveal.

Old saves decode with no Survey Needles. Unknown future tuning versions retain the exact Item as **Needs
retuning** and remain inert; never guess a new target.

## Progression boundary

The first slice has one instrument and one precision level. Do not add charges, universal target categories,
automatic continuous tracking, creature seeking, site seeking or minimap markers.

Later field-instrument progression may add separately authored instruments for medicinal flora or creature
sign only after the Survey Needle proves that seeking improves exploration rather than trivialising it. Those
tools must have their own knowledge and disclosure rules; `survey_needle` cannot silently become a universal
finder.

## Acceptance

1. Tuning is free, Home-only, exact-instance, atomic and accepts only legitimately known World Resources.
2. Gold-rune ownership permits Gold tuning before harvesting; unknown/unwritable resources do not leak.
3. Use spends exactly one world turn, consumes no item and freezes one deterministic result across relaunch.
4. Nearest-node selection follows shortest legal interaction path, not a straight line through deep water,
   chasm or collapsed ground.
5. Exact 2/3/8/9-step fixtures select strong/steady and steady/faint boundaries correctly.
6. Equal-path sector and target ties resolve identically across relaunch.
7. Collected/collapsed/unreachable targets retarget only on the next paid reading; no stale live arrow remains.
8. A harvest-capability shortfall does not hide an otherwise reachable node, and interaction later explains
   the missing tool/skill.
9. No use reveals fog, path tiles, target tile, node count, coordinate, site, portal or minimap POI.
10. Survey Needle, Seamlight and harm/drag cues remain distinguishable at ordinary phone scale and in
    grayscale/value proof.
