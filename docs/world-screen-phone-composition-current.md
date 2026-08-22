# World screen phone composition — current

**Status:** Game Design implementation authority for B1.8b
**Priority:** first-three-world playability; native checkpoint after current scaling and its dependency-safe
world rules, without waiting on later terrain animation
**Owners:** Engineering owns layout measurement, input and state; Asset owns map/control/event visual grammar;
Game Design owns hierarchy and copy; Aimee owns physical-phone acceptance
**Updated:** 21 August 2026

## Player result

The World screen keeps four things simultaneously understandable on an ordinary portrait phone:

1. party condition and collapse state;
2. a complete-row, unclipped view of the world around the party;
3. movement, minimap and the two local action verbs;
4. a compact truthful account of what just happened and what is being carried.

No tutorial, event, Field Kit label, resource strip or transient decision is allowed to recompute the map or
control geometry.

## Fixed vertical ownership

The native screen has four regions in this order:

```text
safe/navigation area
status region                 // Stability/collapse + party health
map viewport                  // receives all remaining flexible height
expedition controls           // carried strip + D-pad/minimap/action row
bottom safe area
```

The status and expedition-control regions measure their actual rendered content first. The map receives the
remaining height. No magic 520-point constant, screen-name special case or tutorial-dependent inset is legal.

### Status region

- one compact Stability/collapse row;
- one compact active-party health strip;
- names may abbreviate, but every visible health fraction remains truthful;
- this region never scrolls horizontally beyond its own clipped health strip and never widens the parent.

Collapse copy uses `collapse-hud-truth`: `~N turns until collapse`, `steady`, or `collapse underway`. It never
says `N turns left` or predicts the stochastic moment when the party's tile will fail.

### Map viewport

- width is the actual safe content width;
- tile size is `floor(widthPixels / viewportColumns)` in device pixels;
- rendered width is `tilePixels × viewportColumns`; center any subpoint remainder as inert backdrop;
- height contains only `floor(availableHeightPixels / tilePixels)` complete rows;
- a partial row is never drawn, clipped or implied by a cut grid line;
- show at least 5 complete rows in the shortest supported ordinary fixture; if less than 5 fit, the whole
  screen may vertically scroll as one emergency fallback, but map tile size does not shrink below the
  accepted readable minimum;
- camera follows/clamps to the party and never exposes blank space beyond world bounds;
- lifted sprite pixels may extend into the map's reserved art overdraw, but cannot be clipped by the viewport
  or mistaken for a material sidewall.

The map may show a window into a larger world. “Complete” means complete visible rows/cells and truthful
world-edge treatment, not fitting every generated world on one phone.

## Expedition controls

The complete control block is fixed below the map and never floats over it.

### Carried strip

- one 44–52 point row directly above navigation controls;
- horizontally scrolling resource/material/item icons stay inside the row and cannot widen the screen;
- use stable pictorial identities and aggregate same-kind quantities;
- **Field Kit** is one fixed trailing button; current turn count is one fixed trailing value;
- opening Field Kit is a sheet and does not resize the World screen behind it;
- no event prose, tutorial text or item description lives in this row.

### Navigation/action row

At ordinary 368-point width use two equal conceptual columns:

- left: four-direction D-pad, each target at least 44×44 points;
- right: 96×96 minimap over one two-button row;
- the two buttons are exactly **Use Tile** and **Look**;
- both buttons remain present in disabled/armed states so the layout never changes when an action appears;
- **Use Tile** acts only on the party's current tile and takes its exact current action from one rules-owned
  resolver;
- **Look** arms one no-turn adjacent inspection; the next D-pad direction inspects instead of moving, then
  disarms;
- armed copy is **Cancel** and the D-pad labels become Look north/east/south/west;
- tapping the map, Use Tile, Back, Field Kit or any non-direction surface disarms Look before the other action;
- a state/position change while armed disarms it; relaunch never restores an armed UI mode.

Use Tile's accessibility value and compact optional detail may say the resolved verb—Harvest, Search, Portal,
Take page, Survey, Open cache or Anchor—but the visible button label remains spatially stable. Disabled means
there is no valid current-tile transaction; activation revalidates and stale state mutates nothing.

## Minimap contract

- exact 96×96 square at ordinary width, with a visible one-pixel-or-greater border distinct from unexplored
  black;
- explored terrain/growth classes only;
- hidden space is opaque black;
- portal, item, resource, site, traveller and enemy POIs appear only after their own discovery rule allows it;
- remembered stationary POIs may remain only when the game already disclosed them;
- no current-fringe content, remote apex placement or arrival-splash content creates a minimap marker;
- a future earned locator skill may add a deliberately typed signal, but default exploration never does.

## Transient overlay stack

Overlays never participate in measurement. From lowest to highest:

1. map art and current field cues;
2. local pickup animation;
3. event toast;
4. required loot/capacity decision;
5. tutorial card;
6. floating DEBUG bug-report control.

Every overlay has a dim/translucent background sufficient to separate it from map art, stays inside safe
bounds and leaves the expedition controls geometrically unchanged.

### Event toast

The event toast is anchored inside the lower map viewport with at least 8 points clearance above the carried
strip. It does not sit underneath the D-pad/minimap pane.

- show at most the two latest concise event summaries;
- each summary wraps to at most two lines at ordinary text size;
- map movement and encounter opening remain visual and produce no filler line;
- resource/item collection names family + aggregate quantity once;
- detailed diary/page prose, long survey output and multi-object loot do not print in full here; their
  dedicated object/detail surface owns that content;
- toast is nonblocking and fades after the settled event interval; important transaction/refusal text remains
  until superseded by another player action or opened in detail;
- no line is truncated in the middle of a mechanically important quantity, blocker or outcome.

### Required decision overlay

Satchel replacement, site result or another required choice uses a centered/bottom-safe modal card above the
map and controls. It may block input until resolved but cannot resize either region. Exact item choices use
stable identities; cancellation changes nothing.

### Tutorial overlay

Tutorial is dead last in implementation priority. If retained in the current build, every World tutorial is
a semi-transparent floating card over the already-laid-out screen. It cannot add an inset, VStack child,
safe-area reservation or map-height input. The card leaves at least part of the map and the entire navigation
control block visibly recognizable; Got it/Not now remain reachable. Adding or removing it must produce
identical map/control frames byte-for-byte in the layout fixture.

### Floating bug-report control

The DEBUG bug-report affordance is above all ordinary overlays but avoids the system status/navigation areas
and required confirmation buttons. It captures the composed screen including lower overlays, not a
re-laid-out diagnostic view.

## Map input and modal modes

| State | Map tap | D-pad | Use Tile | Look |
|---|---|---|---|---|
| ordinary | adjacent step or deterministic travel request | one step | current tile action | arm Look |
| Look armed | disarm, then normal tap behavior | inspect adjacent tile, spend 0 turns, disarm | disarm, then current action | cancel |
| required decision | blocked | blocked | blocked | blocked |
| tutorial visible | follows tutorial's explicit interaction policy; geometry unchanged | same | same | same |
| encounter transition | blocked until encounter owns input | blocked | blocked | blocked |
| collapse underway | same actions against current truth | same | same | same |

Travel and step always validate current passability. Deep water, chasm, collapsed ground, solid obstruction and
map boundary use their distinct `terrain-blocked-feedback` reasons and spend no turn on refusal.

## Field consequence cues

B1.8a plugs into the map without changing this layout:

- red outer harm crescent and three grey inner slow lines occupy the party cell's four direction allocations;
- Look consumes the same rules-owned adjacent preview;
- hidden/fringe tiles and undiscovered content produce no cue;
- cues, Seamlight and pickup feedback have independent layers and cannot cover Use Tile/Look/minimap.

## Exact geometry receipt

Engineering exposes one DEBUG-only `WorldScreenLayoutReceipt` for fixtures and bug reports:

```text
WorldScreenLayoutReceipt
  safeFrame
  statusFrame
  mapViewportFrame
  mapRenderedFrame
  tileSidePixels
  viewportColumns
  viewportRows
  carriedStripFrame
  dpadFrame
  minimapFrame
  useTileFrame
  lookFrame
  eventToastFrame?
  decisionFrame?
  tutorialFrame?
  bugButtonFrame?
```

Receipt validation requires:

- all frames finite and within `safeFrame` except deliberate map-art overdraw contained by its reservation;
- map rendered width/height are exact integer multiples of tile side;
- no overlap between fixed status/map/control regions;
- transient overlays may overlap the map but never change any fixed-region frame;
- D-pad, Field Kit, Use Tile, Look and all overlay actions are at least 44 points;
- no content-driven parent width above safe width.

## Asset production boundary

Asset supplies reusable native-scale components, not a screenshot shell:

- restrained Stability/collapse meter states;
- compact party health strip grammar;
- map viewport border/backdrop and complete-row edge treatment;
- D-pad ordinary/pressed/Look states;
- minimap frame plus disclosure-neutral terrain/growth markers;
- Use Tile enabled/disabled and Look ordinary/armed states;
- carried-strip resource/item counters using shared identities;
- translucent event, required-decision and tutorial card surfaces;
- party-edge consequence cue collision overlay.

The map itself continues to consume accepted top-down terrain/flora/creature/atmosphere assets. This packet
does not authorize a second map renderer or side-view object.

## Required fixtures

1. 368×800 fresh world, no event, no tutorial;
2. same exact state with tutorial visible—fixed frame receipt identical;
3. one-line and maximum two-by-two-line event toast;
4. long diary-page recovery routed to detail rather than filling the toast;
5. empty carried strip and a 23-resource stress strip;
6. Use Tile disabled and each enabled verb;
7. Look armed plus all four direction inspections;
8. complete top/bottom/left/right world-edge camera clamps;
9. hidden versus discovered minimap POIs;
10. shortest supported phone fallback;
11. satchel replacement overlay;
12. combined harm/slow cue, Seamlight and top-edge pickup without control collision.

## Engineering acceptance

1. The bottom map row and border are complete in every viewport fixture; there is no fractional tile.
2. Tutorial/event/decision presence changes zero fixed frames.
3. Carried content cannot widen or cover the map, D-pad, minimap, Use Tile or Look.
4. The event toast stays above controls and routes long object prose to the object's detail surface.
5. Look spends zero turns, uses the exact adjacent preview and cancels on every specified off-mode action.
6. Use Tile stays fixed while its exact action/refusal updates atomically.
7. Unexplored minimap space and POIs obey disclosure after relaunch.
8. Collapse status, blocked movement and current action copy agree with the same saved world state.
9. 368×800 physical-phone evidence includes the complete map row, control block and any active overlay in one
   uncropped capture.
10. No accessibility reflow work beyond maintaining readable ordinary controls is part of this checkpoint;
    broader UI changes remain expected and must not be prematurely optimized around edge sizes.

## Player review

On the physical phone, Aimee should be able to move, Look, Use Tile, open Field Kit, read one event and inspect
the minimap without scrolling the World screen or losing sight of the map/control relationship. The first
review specifically checks the bottom grid line, tutorial frame invariance, Field Kit/resource clearance and
default POI nondisclosure.
