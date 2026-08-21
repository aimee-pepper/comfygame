# Seamlight — current design

**Status:** approved concept; implementation-ready but non-preemptive  
**Roadmap position:** Band 1.6, after active Band 1.3 scaling acceptance and the landed Band 1.4–1.5
world-playability checkpoints are reconciled  
**Purpose:** help the player escape a collapsing world without revealing or teleporting them to an
exit

## Identity

**Seamlight** replaces the working name *Exit Torch*. It is a single-use Field Kit supply whose
light leans toward the nearest usable portal seam:

- a **Torch** improves local sight;
- a **Seamlight** helps the player navigate to a portal; and
- a **Waystone** immediately returns the party with its haul.

It is not a map, compass screen, minimap upgrade or additional Wayfarer's Table function.

## Field rule

- Using one outside combat consumes one Seamlight and one world turn.
- Guidance remains active for the expedition. A second use is refused without consumption.
- After movement or collapse, find the shortest currently walkable path to the nearest standing
  portal. Entry portals are valid exits and therefore valid targets.
- Aim along the **first step of that path**, not a straight line through deep water, chasms or
  collapsed ground. Equal routes use stable grid order so relaunch cannot make the cue jump.
- Reveal no portal tile, route tile, distance number or minimap point. Do not mutate fog-of-war.
- On a portal, the cue becomes a complete bright ring. The existing Portal action still returns Home.
- If malformed or legacy state has no reachable portal, refuse without spending the item or turn:
  **No portal seam answers the light.**

## Visual language

Render two or three soft, blurred arc bands around the party, concentrated toward the next path
step—signal-like, but diffuse light rather than a literal Wi-Fi icon.

- Far: faint, slow, widely spaced bands.
- Near: brighter, slightly more frequent and more complete bands.
- On the portal: one complete, softly breathing ring at maximum established brightness.
- Intensity derives from remaining walkable path length, clamped so pulse counting cannot disclose
  an exact distance.
- Do not cover terrain interaction marks, the party icon or Portal action. Keep it legible across
  generated palettes.

The animation is functional directional feedback, not optional decorative polish.

## Acquisition

- Catalogue ID `seamlight`; uncommon, stackable consumable.
- It may appear in Trading Post rotating stock before its recipe is known.
- Apothecary **Fieldwork** later provides the repeatable recipe: `1 quartz + 1 resin + 1 fiber`, `0
  Essence`.
- It uses the existing Field Kit preparation and exact-instance consumption transaction.

## Permanent progression

After the Scriptorium's inscription capability is available, one Seamlight can be sacrificed to
place **Seamward** on an exact Body or Keepsake item. Seamward automatically provides the same
fog-neutral guidance only after world collapse begins; it does not point out portals during ordinary
exploration. The complete system and costs are in `equipment-inscription-system-current.md`.

## Acceptance

1. One use consumes exactly one item and one world turn, persists through relaunch and refuses a
   duplicate without mutation.
2. Guidance follows shortest walkable-path direction and deterministically retargets after collapse.
3. Far/near/on-portal fixtures increase brightness monotonically without exposing exact distance.
4. No use, movement or relaunch writes portal, route or surrounding tiles into reveal/minimap state.
5. The full portal ring does not automatically return Home.
6. Trading Post, Apothecary, Field Kit and save decode share stable identity `seamlight`.
