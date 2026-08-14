# Minimap Disclosure — Current

**Status:** settled default boundary from Aimee, 9 Aug 2026. Supersedes the earlier “navigation
promise” rule that made portals, writing and the singular apex visible through fog.

## Default rule

The minimap is a record of explored knowledge, not a second view of world generation. A point of
interest appears only when the player has legitimately revealed or discovered it.

- Unrevealed tiles are literally empty fog: no terrain tint, silhouette, marker, glow, direction or
  negative-space hint.
- The party/current position remains visible.
- Revealed terrain and passability classes may be remembered.
- Portals, writing, sites, resources/items, travellers, ordinary encounters, apexes, caches and
  hazards do not appear through fog by default.
- Revealing a tile permits its ordinary marker if that content family belongs on the minimap **and
  its own visibility rule is satisfied**. A revealed tile does not expose a sleeping crypsis enemy
  that the main map still legitimately hides.
  Discovery by a legitimate explicit effect may also reveal the affected tile/marker.
- The entrance portal is normally visible because the party begins on or beside a revealed entrance,
  not because portals bypass fog. Exit/return portals remain hidden until found or disclosed.
- A marker never reveals more identity than the player has learned. Generic writing/site/resource
  marks may remain generic after discovery.

“Not on the minimap” does not mean invisible on the main map once the tile itself is in sight. The
main map continues to show legitimately revealed content using its ordinary world grammar.

## Invested exceptions

A future skill-tree or station-tree node may buy information, and existing consumables may do so,
provided the effect is explicit and attributable rather than a passive default leak.

- The existing Farsight Draught is aligned: it spends an item to reveal the nearest undiscovered site
  and nearby terrain.
- Reliquary site revelation must be an explicit earned/selected research effect rather than a free
  consequence of merely unlocking the station.
- Future scouting/cartography effects should prefer a bounded region, bearing, category hint or
  actual revealed patch. Exact coordinates are appropriate only when the effect clearly promises
  exact discovery and charges commensurate progression or a consumable.
- A broad effect must name its scope (for example sites, writing or seams); “show every POI” is not a
  default convenience upgrade.
- No insight effect may reveal hidden identity, contents, guard state or reward unless it separately
  promises that knowledge.

The exact skill catalogue and costs are not settled by this boundary. First implement the honest
default and preserve extension points for knowledge sources.

## Engineering acceptance

1. With every content type forced under unrevealed fog, minimap output is identical to empty fog.
2. Revealing each tile adds only its permitted generic/known marker without reopening the screen.
3. Portal, diary/found writing, site, resource/drop, traveller, ordinary enemy, apex, cache and hazard
   each have hidden/revealed fixtures.
   The ordinary-enemy fixture also covers a revealed tile with a still-hidden crypsis creature: no
   minimap marker appears until that creature becomes legitimately visible/awake.
4. Tutorial, splash and generated asset inputs cannot set discovery merely by rendering a feature.
5. Asset composition receives game-owned `revealed`/`discovered` state; pixels never infer it.
6. VoiceOver exposes known landmarks and never enumerates hidden cells.
7. Old saves derive no new permanent discovery flags from the formerly always-visible markers.

## Historical note

Earlier current documents allowed portals and the location-only apex through fog, and an even earlier
map contract also allowed all writing. Aimee superseded that rule after seeing the minimap in play:
POIs should reward exploration unless the player deliberately invests in finding them. Archive those
rules as evolution history; do not preserve them in current behavior.
