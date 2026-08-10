# Dynamic Asset Coverage Audit

**Owner:** Asset lead  
**Date:** 9 Aug 2026  
**Scope:** Read-only inventory of current game code and current design authority, mapped against the
isolated `AssetLab/`. No game or Xcode files were changed.

## Executive finding

AssetLab proves the creature/flora visual grammar and one terrain-transition family, but it does
**not** yet cover the full dynamically rendered game. The largest immediate gaps are the complete
12-ground catalogue, multi-species flora casts, all tile-content overlays and state variants,
character generation, village architecture, sites, and entry/exit splash composition.

The tool also has descriptor-contract drift that must be corrected before integration: visual-only
topology is mixed into creature identity, while the live emanation and normalized finish structures
are simplified. Export manifests—not the current authoring controls—must become the exact adapter
boundary.

## Coverage matrix

| Render family | Live requirement | AssetLab today | Gap / disposition |
|---|---|---|---|
| Ground | 12 types: stone, soil, sand, ice, ash, shallow water, deep water, rubble, mud, tall growth, chasm, groundcover | soil, water, deep water | **Critical:** add nine types, crumbled state, adjacency/transition proof and passability fixtures |
| Water | shallow passable water, impassable deep water, frozen ice; shore/depth boundaries | shallow + deep only | Add ice and mixed shallow/deep/shore contour sheets; never imply deep-water passage |
| Flora cast | deterministic 1–4 species/world; seven regions plus composed forms | one species at a time | **Critical:** cast authoring/contact sheet and multi-species integrated map |
| Flora height | groundcover does not block sight; tall growth blocks sight and costs an extra turn | low/high minimap class; one sprite grammar | Add short turf/mat/reed/canopy silhouettes and explicit groundcover/tall-growth tiles |
| Flora ecology | bramble, canopy tree, succulent, mat, fungal bloom, reed, crust; photosynthetic/fungal/chemosynthetic | continuous descriptor, no curated region presets | Add seven truthful presets and test distinct world silhouettes; metabolism remains suggestive |
| Flora state | ordinary, physical hazard, chemical hazard, triggered active combatant, harvested/exhausted | neutral + triggered active | Add disclosure-safe thorn/toxin warnings and harvested/exhausted world states |
| Creatures | species + specimen world/fight; sleeping/awake, sessile, apex, crypsis/detection, defeated; animal companions | species/specimen world/fight only | Add state/profile layer without changing stable identity pixels; apex remains undisclosed until allowed |
| Creature contract | live vector has emanation light/heat/caustic allocation, optional defence, normalized finish; no stored topology | simplified emanation kind; required defence; independent finish; topology inside identity | **Critical contract drift:** split exact identity from visual render hints and add an explicit adapter fixture |
| Characters | 28 named travellers, Binder, and persistent generated companions; world/fight/portrait; equipment and passed-out states | none (combat UI uses creature placeholders) | **Critical new generator family:** authored identity descriptors for named cast + bounded generated-person variation |
| Village/base | side-view village with 18 catalogued stations, build/upgrade states and staffing/traveller accents | none | New side-view architecture kit; shared substrate plus station modules and construction/tier states |
| Sites | 9 implemented definitions; six current additional profiles; deep sign/Buried seam; searched/exhausted/guarded states | generic site square | New authored site-profile kit with procedural world palette/material adaptation |
| Tile content | empty, node, wild drop, hazard, entry/exit portal, locked cache, site, diary page, found writing, traveller | route, portal, generic site, party | Add semantic overlay catalogue and minimap collision sheet; entry and exit portals must differ |
| Resource nodes | 23 resources; organic nodes inherit flora, mineral nodes inherit world substrate; remaining/exhausted states | none | Generate node families from resolved resource facts; icons may remain authored, world nodes cannot all be one cube |
| World mutation | revealed/fog, elevation 0–3, cracking, crumbled/gone, night/day sight, stability hazard bands | fog, elevation, crack | Add crumbled/gone and lighting/state composition; fog must not leak content |
| Minimap | terrain/growth, party and legitimately discovered navigation facts; all POIs default hidden under fog | terrain/growth, route, party, portal, site | Enforce game-owned revealed/discovered timing for portal, writing, apex, site, resource/item, traveller and encounters; collision fixtures |
| Combat stage | 5v3/2v1, ranks/reach, selection/legal/cannot/protected, statuses and accessibility | accepted static golden + UI proof | Static boundary strong; still needs real character sprites, defeated/passed-out poses and later animation |
| Splashes | framed/page-like entry; exit variants for portal, collapse, defeat, abandon and anchored continuity | none | **Critical new compositor:** disclosure-safe world identity layers and lifecycle-specific exit compositions |
| Portraits/bestiary | bestiary species/specimens; later named traveller portraits | no portrait profile | Add creature bestiary profile and later named-cast portrait profile; generated companions need bounded portrait grammar |
| Equipment/items | visible character loadouts, crafted provenance, world objects | none | Decide silhouette-only fight equipment versus authored icons; do not procedurally invent lore-bearing uniques |

## Exact live inventories

### Ground and mutation

`GroundType` currently contains 12 cases. Deep water and chasm are impassable. Tall growth and mud
cost an extra world turn. Tall growth and rubble block sight; groundcover deliberately does not.
Tiles additionally carry elevation 0–3, reveal, cracking and crumbled states.

### Flora

Worlds contain a deterministic cast of one to four species. Current identity regions are bramble,
canopy tree, succulent, mat, fungal bloom, reed and crust, with composed names for unmatched forms.
Variation belongs between species and in patch topology, not per-tile specimen jitter. A useful
integrated proof must therefore show several stable species coexisting, not recolored copies of one
plant.

### World content and navigation

The map can contain resource nodes, wild drops, hazards, entry and exit portals, locked caches,
sites, diary pages, found writing and travellers. Enemy state additionally distinguishes asleep vs
awake, mobile vs sessile flora, and apex. The old always-visible minimap promise for portals, writing
and apex locations is retired; every POI now follows game-owned reveal/discovery state by default.

### Authored-but-procedurally-placed content

- 9 implemented site definitions, plus six current design profiles and the Deep Works sign family;
- 18 village stations/buildings;
- 28 named travellers;
- 23 resource families.

These need parameterized asset families or authored kits, not one generic icon. Their identity and
lore remain authored even where palette, damage, material, growth or placement adapts procedurally.

## Priority plan

### P0 — prevent false coverage

1. Expand World Lab to all 12 ground types and mutation states.
2. Add seven flora-region presets, 1–4-species cast sheets and a multi-species map proof.
3. Reconcile creature/flora export descriptors with live model shapes; move topology to render hints.
4. Add every tile-content/minimap symbol and disclosure/collision fixture.

**Progress in this audit:** item 1 now has all 12 live ground grammars, crumbled state and exact
passable/slow/sight/overgrown rule facts under test. Item 2 now has the seven identity-region presets
and distinct native silhouettes; the required 1–4-species integrated cast remains open.

### P1 — fill missing gameplay actors and places

5. Build character identity/render descriptors for named and generated people across world/fight.
6. Build the side-view village architecture kit for 18 stations and their construction/tier states.
7. Build site-profile and resource-node kits, including searched/exhausted/guarded/deep-sign states.

### P2 — composition profiles

8. Add creature bestiary and named-character portrait profiles.
9. Build disclosure-safe entry and lifecycle-specific exit splash compositors.
10. Add animation only after these static identity/state matrices are accepted.

## Placeholder decisions used to proceed

- `water` in code is **shallow/passable water**; AssetLab labels should say “shallow water.”
- Each live ground type gets a distinct value/shape grammar before biome palettes multiply it.
- Groundcover/tall growth are resolved terrain facts plus a stable flora-species overlay, not generic
  anonymous grass textures.
- Sites, buildings, named travellers and lore-bearing unique items remain authored identities with
  procedural palette/material/state variation; they are not unconstrained random generation.
- No game integration is authorized by this audit.

## Game Design review — authored/generated boundary and priority

**Disposition:** recommendations only. The inventory is accepted as an honest coverage ledger. The
twelve-ground and seven flora-region contact sheets close two isolated vocabulary gaps, but they do
not yet prove a composed world. No production integration is implied.

### Identity ownership

Use three boundaries rather than a binary “authored or generated” label:

1. **System-generated identities:** ordinary creature species/specimens, flora species and bounded
   generated companions. Their descriptor/seed is the durable identity; visual variation may express
   simulated anatomy, tissue and material facts but may not expose hidden mechanics directly.
2. **Authored identities with procedural adaptation:** the Binder, named travellers, stations, sites,
   resource families and lore-bearing unique items. Their silhouette/emblem/narrative identity is
   authored. World palette, local material, weathering, damage, construction tier and discovered or
   exhausted state may adapt within that identity.
3. **Generated composition from known facts:** terrain maps, flora patches, ordinary resource-node
   placement, entry splashes and encounter backdrops. Composition may be procedural, but it can use
   only facts legitimately known in that view and must preserve authored feature identity.

Do not procedurally regenerate a named traveller, station or site into a new recognizable identity
because its world palette changes. Conversely, do not force every ordinary creature/flora species
through an authored lookup table that disconnects its appearance from the traits that made it.

Resource **family** is authored, while an individual node is a hybrid: mineral nodes inherit local
substrate/material character, organic nodes inherit their actual flora species, and both retain an
authored family cue. A generic cube with a swapped label is insufficient; unconstrained invention of
a new resource identity is also wrong.

### Recommended next order

After the completed ground and region-preset sheets:

1. **Lock the live descriptor adapter.** Reconcile exact creature/flora identity fields first and
   move topology/state to render hints. Otherwise the multi-species proof may canonize a contract the
   game cannot truthfully export.
2. **Prove a 1–4-species integrated map.** Show stable distinct species across groundcover and tall
   growth, ordinary/harvested states, adjacency, route, party and native grayscale. Patch topology
   varies by habit; species pixels do not vary by tile.
3. **Add the ten tile-content families and minimap collisions.** This is ahead of character/base
   breadth because those overlays already control exploration decisions. Verify entry versus exit
   portal, writing types, traveller, site, cache, hazard, node/drop and disclosure timing without
   erasing route or terrain cost.
4. **Then build character descriptors**, beginning with the authored named-cast contract and a
   separate bounded generated-companion contract before producing portrait volume.
5. **Build stations, sites and resource nodes as authored kits**, then lifecycle splash composition.

The descriptor adapter and multi-species map may be developed together, but adapter fixtures must be
green before the composed sheet becomes a golden. Animation remains after these static identity,
state and collision matrices.

## Dynamic-depth re-audit — 9 Aug 2026

This pass corrects the earlier audit's central omission: semantic coverage is not sufficient dynamic
coverage. Every generated family is now evaluated across authored identity, shared world adaptation,
species/item identity, placement/specimen variation, lifecycle/state, camera/profile, disclosure,
accessibility and persisted determinism.

### Settled three-axis terrain model

1. **Ground identity/state** owns passability, adjacency, elevation, crumbling and cracking. Palette
   or decorative templates may never invent these facts.
2. **World grade** applies one coherent bounded RGB/value atmosphere to related terrain families from
   actual resolved world data. It suggests material atmosphere and never encodes exact pressure
   values, hidden mechanics or written rune identity.
3. **Placement feature template** selects a stable same-affordance detail silhouette from persisted
   world + coordinate + pipeline version. It may add compatible grain, pebbles, clumps, ripples,
   frost or ash, but never a resource, hazard, route, elevation, crack or site promise.

AssetLab now provides four named feature templates for each of the 12 ground families and bounded
world grading that changes colors without changing geometry. The conformance pack contains neutral,
warm and cool grade evidence and all feature variants. The exact live world-readings→grade mapping
is deliberately flagged as unresolved rather than using proof defaults.

### Current depth ledger

| Family | Dynamic depth status | Remaining gap / risk |
|---|---|---|
| Terrain | **Corrected foundation:** 12 identities, state/adjacency, 4 templates each, coherent grade input | Freeze native world-grade mapping and persisted template-index derivation; integrated phone/grayscale collision review still required |
| Flora | Strong species anatomy/habit/state/profile depth; live Swift adapter exists | Environmental grade is not yet a separate bounded input; harvested poses exist only where rules persist them; patch topology must remain placement-owned |
| Creatures | Strong species/specimen anatomy and world/fight profiles | Missing world-coherent environmental grading, sleeping/detected/crypsis/apex-state matrix, bestiary profile and animation; current presets are evidence, not full ecological capacity proof |
| Generated companions | Bounded structural generator exists for people | No durable live generated-person identity/seed in the game contract yet; portrait and top-down character profiles remain absent |
| Named characters | Authored 28-person identity, gear, grade and prone coverage | Current world sprites are compact upright figures, not accepted straight-top-down map sprites; warm/cold grading is only a coarse proof, not world-data adaptation |
| Village stations | Authored functional silhouettes, tier/damage matrices | Only small warm/cold/ash palette choices; missing coherent base-substrate/material accumulation, staffing accents, construction breadth and side-view environmental adaptation |
| Sites | Authored site silhouettes and physical state grammar | World adaptation is coarse palette-only; searched/exhausted transformation breadth is not proven per every site; guard occupant and passability must remain rule-owned |
| Resources | 23-family acquisition/source/profile/state coverage | Mineral template variety within each physical profile is shallow; world material grading is coarse; flora-linked nodes must inherit the actual graded species; no item/inventory icon depth audit yet |
| Tile content | Ten semantic families plus collision evidence | Most are one canonical colored sprite. They need bounded same-meaning variants and shared world adaptation where appropriate, without weakening disclosure or traveller/drop distinctions |
| Portals/writing/cache | Semantically distinct and disclosure-tested | Still largely canonical single shapes; portal material/world variation, writing substrate variants and cache wear states are shallow |
| Minimap | Correct symbolic/disclosure boundary | Intentionally should **not** inherit decorative world variation. Validate hidden/revealed/discovered timing for every POI family after native art integration |
| Combat stage/UI | Static semantic grammar is golden | Dynamic visual depth intentionally deferred: animation, real world-graded actors, status motion and multiple backdrops remain uncovered |
| Splashes | Lifecycle compositor and disclosure boundary are golden | World scene palette currently uses four authored terrain categories, not the complete resolved world grade/material vocabulary; no animation by design |
| Bestiary/portraits | Not implemented | Critical later profile gap for generated creatures, specimens, companions and named cast |
| Equipment/items | Blade/spear/bow and armour preservation proofs only | Missing full eight-slot visual mapping, crafted material/provenance adaptation, drop/inventory/world correspondence and authored unique-item catalogue |

### Highest-priority shallow/collapsed outputs

1. Tile content, portals, caches and writing are still mostly one canonical colored glyph each.
2. Flora and creature identity are deep, but neither yet accepts the same resolved world-grade DTO as
   terrain; uncoordinated grading would make a world look assembled rather than native.
3. Named/generated people lack a settled straight-top-down map profile.
4. Stations/sites/resources have authored identity but only coarse palette adaptation and insufficient
   same-state material/template breadth.
5. Splash scenes use a reduced authored terrain palette rather than the eventual full world material
   descriptor.
6. Bestiary, portrait, equipment/item and animation families remain materially uncovered.

### Export defect found and corrected

The conformance PNG encoder previously parsed hex colors only while flora commands use CSS HSL/alpha.
Browser canvases were correct, but exported flora PNG pixels could be incorrect. The exporter now
parses both formats and keeps separate compressed-file and decoded-RGBA hashes. This is covered by the
full export test; earlier generated map packs must not be treated as current evidence.
# Progress update — 9 Aug 2026

The first remediation gate is implemented inside AssetLab: manifest v3 separates the authoring descriptor, exact game identity, visual-only render hints, structured adapter diagnostics, and pipeline versions, with an explicit creature/flora identity kind. Creature emanation now has exact light/heat/caustic allocation rather than a lossy dominant-kind authoring control; v3 descriptor migration is covered and emits an assumption warning. Creature topology is confined to render hints, optional defence maps to `null`, and flora tissue resultant values are derived explicitly. Unit and golden-regression suites pass with 0/36 accepted pixel changes. Final enum/unit spelling remains an engineering confirmation before integration; AssetLab has not modified or integrated with game code.
