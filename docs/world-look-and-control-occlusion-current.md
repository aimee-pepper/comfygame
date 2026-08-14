# World Look mode and fixed-control occlusion — current correction

**Status:** P1 layout bug plus approved adjacent-inspection interaction; queued behind Trading Post and
the resource-visual checkpoint.  
**Owner:** Game Design; Engineering implements and verifies on phone.  
**Raised by:** Aimee's 10 Aug 2026 device playtest.

## Layout bug: scrolling information hides underneath controls

The direction/minimap pane is fixed to the bottom while the map's scrolling column contains event or
information text, the satchel/resource display and Field Kit. When that text grows, the last scroll
content can finish underneath the fixed pane. “It exists if dragged behind an opaque control” is not
reachable or acceptable.

Correction:

- keep the compact satchel/resource strip and Field Kit outside the variable narration/map scroll,
  pinned immediately above the direction/minimap control region;
- measure the actual fixed HUD/control region, including its safe-area inset and current contextual
  action height;
- give genuinely scrolling content a matching bottom margin/inset so its final variable element can
  still be brought completely above the pinned HUD;
- Field Kit and the full resource display must remain visible and tappable after the longest normal
  event/info message, tutorial overlay and accessibility reflow;
- the inset follows the rendered control height; do not hard-code one phone-specific number;
- tutorial/report overlays float without changing the map's measured layout, but must not trap the
  only reachable instance of Field Kit or a required action.

Acceptance: on 368×800, stage multi-line information, a non-empty resource haul and every ordinary
contextual tile action. Field Kit plus the compact resource strip remain visible above the
direction/minimap pane without scrolling through narration. Scroll to the end and show the final
variable element entirely above that pinned HUD. Repeat at a large accessibility text size.

### Code audit — 11 Aug 2026

Current `WorldView` places `eventLog` followed by `satchel(run)` inside the same vertical `ScrollView`,
while `controls(run)` is outside it. Longer narration therefore pushes the resource/Field Kit row down
as ordinary scroll content even though both are persistent expedition controls. This is the direct
structural cause; a larger arbitrary bottom padding alone would keep the row technically reachable but
would not satisfy the request to keep it visible. Move the satchel strip to the fixed HUD boundary and
reserve measured space for it.

## Look — approved interaction

Add **Look** beside **Use tile** in the world action region.

1. Tap **Look** to enter a clearly highlighted inspection mode.
2. Tap one direction on the existing direction pad.
3. The party does not move and no world turn passes.
4. A compact inspection surface describes that adjacent tile and Look mode ends.
5. Cancel, tapping Look again, changing screens or beginning another action ends the mode without a
   turn. An unavailable direction gives a short boundary message and also costs no turn.

This is a mode on the existing four-direction pad, not a second direction control. While armed, the
pad's accessibility label becomes “Look north/east/south/west,” and movement cannot occur from that
tap. The Look control itself must show armed state redundantly through label/icon/outline, not colour
alone.

## What Look reports

Look answers the travel decision the player is about to make:

- ground identity in player language;
- ordinary movement cost, including the exact additional world turns this party would currently
  spend;
- visible growth/flora and whether entering it is currently known to harm, poison or otherwise affect
  the party;
- visible cracking, chasm/deep-water impassability and other known traversal hazards;
- a legitimately visible occupant or interaction (“resource node,” “writing,” “traveller,” etc.) only
  to the same disclosure level the map already permits;
- current modifiers that change the answer when useful, such as a field skill or protection making
  this party's cost differ from the ordinary cost.

Use direct copy. Do not expose raw pressure values, generation tags, unrevealed POIs, hidden
creatures, unrecognized species traits or exact secret damage rolls.

### Contact/disclosure correction — 11 August 2026

Active flora does **not** react merely because the party approaches. Look describes the consequence
of the contemplated move, not a false adjacency trigger.

| Visible tile fact | Look copy boundary |
|---|---|
| Passable ordinary ground | Total turns to enter; when greater than one, also state the exact extra turns |
| Physical defended growth | **Entering will hurt the party**; visible barbs may be named, but no exact damage roll |
| Chemical defended growth | **Entering carries a lingering hazard**; do not disclose an unearned exact status/duration |
| Active-defence flora | **Entering will start an encounter**; adjacency and Look are safe, and hidden combat traits remain hidden |
| Cracking/impassable | State the visible structural warning or why entry is impossible |

Preferred examples are **“Mud · 4 turns to enter · 3 extra”**, **“Thorn growth · 1 turn to enter ·
entering will hurt the party”**, and **“Coiled growth · entering will start an encounter.”**
“Reacts when approached” is forbidden release copy.

The current first slice has no persisted flora-knowledge catalogue. Look may report visible entry
consequences needed for informed movement, but must not invent one by revealing exact defence
strength, tissue allocation, metabolism, damage/status magnitude or harvest quality. Sela's settled
flora-identification contribution may later deepen names and recognised properties through one
explicit capability/knowledge receipt; it is not permission for `inspect` to expose every generated
trait to every party now.

## Visibility and knowledge boundary

- Look targets only one adjacent cardinal tile selected through the direction pad.
- It does not reveal remote fog, discover a POI, advance creature awareness, trigger flora, harvest,
  search, collect or spend Stability.
- Normally an adjacent target is already visually revealed by the party's current sight. If concealment
  or a special state leaves it unrevealed, Look reports only **“You cannot make out that tile.”** It
  does not convert inspection into free scouting.
- Information comes from the live movement/hazard rules used by `step`; do not maintain a parallel
  prose table that can disagree with actual cost or damage.

## Verification

1. Look north then north movement reports the same terrain cost/effect that movement applies.
2. Looking costs zero turns, Stability, items and awareness transitions.
3. An armed Look direction can never accidentally move the party, including double-tap and VoiceOver.
4. Boundary, impassable, slow, harmful growth, unknown active flora and ordinary safe-ground fixtures
   produce distinct truthful descriptions.
5. Hidden POIs/enemies remain hidden; looking cannot change minimap disclosure.
6. Save/relaunch does not need to persist the transient armed mode; relaunch returns to ordinary
   movement safely.
7. At phone and large-text sizes, Look and Use tile remain independent ≥44-point controls and neither
   occludes the map, Field Kit, resource display or direction pad.
8. Active flora says entry starts an encounter and never says adjacency/approach triggers it;
   physical/chemical entry hazards remain noncombat consequences.
9. Slow ground reports both total entry time and exact extra turns from the frozen run tuning.
10. Inspection text contains no exact hidden flora trait, damage roll, status duration or harvest
    quality before a future rules-owned knowledge source explicitly permits it.
