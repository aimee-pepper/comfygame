# Current playtest UI corrections — Party and world navigation

**Status:** Settled user-request audit; implementation corrections only.  
**Updated:** 9 Aug 2026

## Party member stats

Aimee's requested structure is now mostly present: roster overview → tap a person → swipe between
people → Gear / Training / Stats / Gambits. The remaining mismatch is that the roster overview still
renders all five core attributes beneath every person.

Current correction:

- roster cards retain thumbnail/icon, name, Level, maximum Health, front/back Rank, “with you” and
  the useful “something better is on the shelf” nudge;
- remove Might/Finesse/Fortitude/Perception/Wit values from the roster card;
- the **Stats** tab remains the complete home for core attributes, their explanations, XP progress
  and rank control;
- opening a person and swiping between people must preserve the selected inner tab where practical,
  so comparing Stats or Gear does not bounce back to Gear on every swipe.

The overview stays an identity/status chooser rather than becoming a compressed second Stats page.

## Minimap placement

The minimap now exists, but it sits beside the D-pad in the contextual-action column. The requested
placement is directly **below the movement arrows** as one navigation unit.

Use a left navigation column containing D-pad then 112×112 minimap. Contextual Survey/Harvest/Site/
Anchor/Portal actions remain in the adjacent column. On compact-height devices the whole controls
region may scroll or the minimap may collapse behind an explicit “Map” disclosure, but it should
open in place under navigation rather than as a detached modal.

## Minimap disclosure

The minimap is a memory/navigation surface, not an objective revealer:

- always show the party position;
- show revealed terrain classes, including ordinary/deep water, mud, low/tall growth, hazards and
  crumbled nothing, with redundant value/shape in the eventual asset profile;
- unrevealed tiles are literally empty fog and carry no contents marker;
- portals may remain visible as navigation promises;
- apex location remains visible from entry because that is separately settled apex behavior;
- diary or other writing appears only after its tile is revealed/discovered—never from generation;
- sites appear only when revealed or explicitly discovered by a legitimate effect;
- a future active path may be drawn only from the real passable route returned by WorldRules.

The live `MinimapView` currently iterates all diary-page tiles without a reveal guard, disclosing the
guaranteed writing's exact location at entry. Add the reveal/discovery gate before the found-writing
system broadens beyond diary pages.

## Verification

1. Party roster has no five-attribute strip; the Stats tab retains every value and explanation.
2. Minimap is geometrically beneath the D-pad in the same navigation column.
3. An unrevealed diary page/site never produces a minimap marker.
4. Revealing that tile adds its permitted marker without reopening the world screen.
5. Portal and apex behavior match their explicit always-known rules.
6. Fog contains no terrain texture or point-of-interest hint.
7. VoiceOver names the minimap as an overview and exposes known landmarks without describing hidden
   cells individually.
