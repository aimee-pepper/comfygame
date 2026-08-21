# Starting town — Band 1 integration boundary

**Status:** superseded opening-scene proposal; retained for history. Current authority is
`home-house-and-village-current.md`.
**Date:** 14 August 2026  
**Priority:** early Home spatial identity; no later-station breadth

## Historical slice

Integrate one spatial **Home** scene and keep Make, Study and Realms on their already-functional
destination grids. Do not make the complete generated-town system a prerequisite for replacing the
opening Home list.

The Home scene owns exactly five destination hotspots:

1. Writing Desk
2. Storehouse
3. Firepit
4. Essence Spring
5. Workshop

Party remains the persistent bottom utility. It is not a room or town hotspot. Bind & Depart remains
the persistent primary shortcut even though the Writing Desk is also a place the player may enter.
Library, Constellation and Bestiary remain distinct destinations under Study; a single generic
“Study” hotspot must not collapse them or move Library into Home.

Unknown future stations remain absent. Trading Post, Recycler and Blacksmith appear under Make in
their settled order when known; this first slice does not need to draw every later district.

## Asset correction

The current `town-starting-v1` is a tall illustration placed in a substantially wider 520-point
viewport with `scaledToFill`. That necessarily crops it, while hotspot positions are calculated as
if the uncropped image still filled the viewport. Visible rooms and their tap targets can therefore
diverge.

Create a phone-composed starting-town asset whose native aspect matches the actual scene region,
targeting roughly **4:5**. Preserve the current identities but remove excess sky/road/forest before
shrinking destinations. The scene must make these five regions visibly separable:

- left building upper work surface: Writing Desk;
- left building lower tool bay: Workshop;
- right building and crates: Storehouse;
- lower-left spring;
- lower-right Firepit.

Do not add a Party room. The visible books currently suggesting a generic Study should instead read
as the Binder's writing/work records; the actual Library keeps its own Study destination.

Asset metadata owns normalized hotspot rectangles in the same coordinate space as the exported
image. Native code must consume those rectangles rather than duplicate hand-entered coordinates.

## Layout contract

- Measure the scene from the space remaining between the compact Base/tabs region and persistent
  Party/Bind & Depart row. Do not hard-code 520 points.
- On the ordinary 368×800 fixture, the full scene, all five labels/targets and both bottom actions
  are visible without scrolling.
- Preserve at least 44×44-point targets. Labels may sit within or just above their owned region, but
  cannot obscure another hotspot.
- Use aspect-fit or an exact matching aspect; never apply unaccounted `scaledToFill` cropping to a
  coordinate-owned scene.
- If the measured region cannot retain truthful targets, fall back to the accepted three-column
  Home grid. A partially misregistered scenic map is not an acceptable intermediate state.
- Tutorial and DEBUG surfaces remain overlays and cannot resize this region.

## Package split

The Band-1 checkpoint may include:

- corrected starting-town scene + hotspot metadata;
- the Home-only native scene adapter;
- opening-route navigation and compact-phone tests;
- only the exact PBX resource entries required by that scene.

Hold separately:

- generated visual breadth for future stations;
- empty-district pagination and four-station page layouts;
- later building sprite catalogues;
- broad town generator scripts/registries not consumed by the Home slice.

Those are not rejected; they simply cannot keep the opening spatial Home change uncommittable.

## Acceptance

1. Pixel/coordinate fixtures prove every hotspot centre lands on its intended visible place after
   ordinary-phone layout.
2. Home exposes exactly the five destinations above; Party has no hotspot and Study is not merged.
3. Writing Desk and Bind & Depart both reach the correct existing writing route without duplicate
   campaign state.
4. All destinations and bottom actions fit at 368×800 with no ordinary scrolling or clipping.
5. Missing/malformed scene metadata fails closed to the current station grid.
6. Existing station lifecycle, tab ordering, first-return focus and save data remain unchanged.
