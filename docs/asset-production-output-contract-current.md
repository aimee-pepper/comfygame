# Asset production output contract — current

**Status:** settled cross-lead production rule
**Owner:** Game Design sets semantic/art-quality acceptance; Asset Lead authors visual solutions; Engineering
integrates only approved/frozen outputs.
**Updated:** 21 August 2026

## Core rule

AssetLab may use HTML/CSS for review chrome, labels, controls and collision overlays. Depicted game art must
be a real reusable pixel-art product, not a CSS shape, arbitrary rectangle diagram or web mockup that only
resembles a sprite after screenshotting.

Passing deterministic exports, manifests and tests proves technical reproducibility. It does **not** prove
art quality. Game Design/Aimee must separately accept that the candidate is recognizable, beautiful,
coherent with the game's style and detailed enough for its native use.

## Every task declares its art product

The handoff must explicitly choose one of these products rather than forcing one universal format:

| Product | Use | Required output |
|---|---|---|
| Composite sprite | an object whose parts never recombine, such as one building state | lossless transparent RGBA PNG per real state/palette plus pivot/bounds |
| Scene sprite/layer kit | House, Library, village backdrop or another composed place | lossless base/layers at one logical pixel scale, shared origin, ownership overlays separate from art |
| Modular assembly kit | gear whose components/materials recombine | transparent aligned component PNGs, stable component/material IDs, attachment points, pivots and assembled reference fixtures |
| Animation strip/set | local pickup, hostile pose, attention or another real state change | exact frame order/durations, shared canvas/pivot and nonanimated fallback |
| Contact/atlas sheet | review and collision evidence only | lossless nearest-neighbour sheet generated from the production outputs; never the only source asset |

A building may correctly be one composite sprite. A material-responsive weapon should normally be a modular
kit: blade/head, guard, hilt/grip, wrap and pommel/fitting use a shared canvas and authored attachment points.
Do not split an object merely to inflate asset count, and do not flatten recombinable components into one
uneditable screenshot.

## Pixel and manifest requirements

- integer pixel coordinates and nearest-neighbour scaling;
- no accidental smoothing, subpixel placement or antialiasing;
- lossless RGBA PNG output for native candidates;
- stable asset, state, palette and component/material IDs;
- logical dimensions, display scale, pivot, bounds and attachment points in the manifest;
- source-command/file hash plus exported-file hash;
- deterministic regeneration and an export `--check` gate;
- colour and grayscale/value evidence where gameplay identity depends on recognition;
- transparent padding may not create false map geometry or change the interaction bounds.

The required logical resolution is task-specific and must support the promised detail at native size.
Technical compactness is not a virtue when a building becomes an unreadable 48×32 prop. The current
House/village/Library target uses a coherent 184-pixel logical phone width displayed at 2×; station façades
normally require at least 64×48 logical pixels and 112–144 displayed width, while House/Library use scene
art occupying most of the logical canvas.

## Visual quality acceptance

A production candidate passes only when:

1. the object/place is recognizable without relying on its text label;
2. form, materials, palette, lighting/value and functional fixtures communicate its identity;
3. it reads as intentional pixel art rather than bordered rectangles or placeholder geometry;
4. repeated families share a visual grammar without becoming recolours of one generic shape;
5. empty space is composed environment, not an unfinished flat field;
6. 400% nearest-neighbour crops reveal deliberate pixel clusters, not accidental web rasterization;
7. the full native-size scene remains readable in colour and grayscale;
8. art does not imply actions, knowledge or states absent from the feature packet.

## Review delivery

Every candidate supplies:

- exact local server command and HTTP URL that work in ordinary Chrome;
- a route linked from the AssetLab review navigation;
- a standalone lossless PNG contact sheet for file viewing/fallback;
- native-size composite proofs plus 400% nearest-neighbour detail crops;
- manifest/hash and test/regression results;
- explicit `integrationReady: false` until the named visual is approved and frozen.

An ES-module page opened directly through `file://` may legitimately fail browser security rules; the HTTP
route must still work. A static PNG fallback is required, but it does not excuse a broken ordinary-Chrome
review route.

## No silent promotion

Asset Lead does not commit/promote goldens or ask Engineering to integrate merely because exports are green.
After Game Design/Aimee accepts the actual art, Asset freezes that exact source/export identity and reports
the approved hashes. Engineering integrates only that frozen candidate and reports native comparison
evidence. Any visually material regeneration returns to candidate status.
