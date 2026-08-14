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

### Party viewport fit — 10 Aug 2026

The ordinary five-person Party hub must show all five member buttons at once on a 368×800 phone.
Current oversized member tiles extend past the viewport despite sufficient room and create scrolling
with no information or readability benefit. Measure the space remaining after navigation and safe
areas, divide it across the roster grid, and preserve at least 44-point targets, name, Level, Health
and Rank. Do not solve the defect by clipping the final row, shrinking text below legibility or
hiding a settled field. Accessibility text sizes may reflow to fewer columns and scroll.

### Code audit and compact composition — 11 Aug 2026

The cause is explicit in the current view: an ordinary two-column grid gives every person a fixed
minimum height of 190 points, then places a full Satchel card above it. Five people therefore require
three 190-point rows before padding/navigation, even though each card carries only an icon, name,
Level, Health, Rank and optional nudge.

Recommended ordinary composition:

- make Satchel a compact one-line status/action above the people rather than a station-sized card;
- use a three-column, two-row identity grid for the maximum five-person active party at ordinary text
  size;
- use near-square cards derived from the measured remaining viewport, with a 32–40 point identity
  mark, name, compact `Lv`, Health and Rank labels, and a small with-you/upgrade badge;
- remove the decorative bottom Spacer/chevron allocation that currently makes every card look like a
  tall navigation row; the whole tile already communicates tap;
- two, one or zero companion states retain the same tile proportions instead of stretching to consume
  arbitrary height;
- large Dynamic Type may reduce to two/one columns and scroll; ordinary 368×800 may not.

Acceptance geometry is behavioral rather than one hard-coded height: after the navigation bar and
safe areas, the compact Satchel line plus all five identity tiles are visible with a small bottom
margin. Opening any tile still presents the existing member tabs and horizontal person paging.

## Minimap placement

The current accepted placement is **beside the D-pad**, filling the otherwise blank area directly
above the Portal-home action. D-pad and minimap form one horizontal navigation row; contextual
Survey/Harvest/Site/Anchor/Portal actions remain below or in their own action region. Do not stack
the minimap below the arrows on phone: that wastes the action-column space and lengthens the screen.
On genuinely compact widths the row may scale within tap/readability limits, but the ordinary phone
composition remains the accepted side-by-side arrangement.

## Minimap disclosure

The minimap is a memory/navigation surface, not an objective revealer:

- always show the party position;
- show revealed terrain classes, including ordinary/deep water, mud, low/tall growth, hazards and
  crumbled nothing, with redundant value/shape in the eventual asset profile;
- unrevealed tiles are literally empty fog and carry no contents marker;
- portals appear only when their tile is revealed or a legitimate invested effect discovers them;
- apex location is fog/discovery-gated like every other encounter by default;
- diary or other writing appears only after its tile is revealed/discovered—never from generation;
- sites appear only when revealed or explicitly discovered by a legitimate effect;
- a future active path may be drawn only from the real passable route returned by WorldRules.

The live `MinimapView` currently iterates all diary-page tiles without a reveal guard, disclosing the
guaranteed writing's exact location at entry. Add the reveal/discovery gate before the found-writing
system broadens beyond diary pages.

## Verification

1. Party roster has no five-attribute strip; the Stats tab retains every value and explanation.
2. Minimap is geometrically beside the D-pad and directly above the Portal-home action.
3. An unrevealed diary page/site never produces a minimap marker.
4. Revealing that tile adds its permitted marker without reopening the world screen.
5. Unrevealed portals and apexes produce no marker; legitimate reveal/discovery adds the marker.
6. Fog contains no terrain texture or point-of-interest hint.
7. VoiceOver names the minimap as an overview and exposes known landmarks without describing hidden
   cells individually.
8. At ordinary text size on 368×800, all five Party member tiles are simultaneously visible without
   scrolling; tapping any tile remains reliable and no card crosses the safe-area bounds.
