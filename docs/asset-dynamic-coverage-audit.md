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

> **11 Aug correction:** the three-axis ownership remains valid, but the exact
> `world-grade-1.0.0` color formula below is frozen compatibility, not the future semantic model.
> `world-color-differentiation-current.md` removes Illumination and Vitality from inherent terrain
> recoloring and replaces universal novelty with calibrated relative diversity. Do not widen or
> reinterpret v1 in place.

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
is now frozen as `world-grade-1.0.0`; proof defaults remain forbidden as runtime inputs.

### Current depth ledger

| Family | Dynamic depth status | Remaining gap / risk |
|---|---|---|
| Terrain | **Integration-ready foundation:** 12 identities, state/adjacency, 4 neutral templates each, frozen world-grade mapping and deterministic placement input; lifted same-material terraces have a separate frozen compositor pack | Native must finish the accepted lifted compositor port and keep universal grid strokes/false sidewalls removed; unsupported raised water/ice/growth remain deliberately flat pending real facts |
| Flora | Strong species anatomy/habit/state/profile depth; live Swift adapter exists | Environmental grade is not yet a separate bounded input; harvested poses exist only where rules persist them; patch topology must remain placement-owned |
| Creatures | Strong species/specimen anatomy and world/fight profiles | Missing world-coherent environmental grading, sleeping/detected/crypsis/apex-state matrix, bestiary profile and animation; current presets are evidence, not full ecological capacity proof |
| Generated companions | Bounded structural generator and accepted straight-top-down sample profiles exist for people | No durable live generated-person identity/seed in the game contract yet; complete native catalogue reconciliation and portraits remain absent |
| Named characters | Authored 28-person identity, gear, grade and prone coverage; all 28×4 `mapTopDown` facings pass native grayscale collisions | Persisted native character identity/facing adapter remains the integration gate; legacy compact-upright `world` sprites are proof-only for explorable maps |
| Village stations | Authored functional silhouettes, tier/damage matrices, plus accepted Trading Post and Recycler identities | Coherent base-substrate/material accumulation, staffing occupants, construction breadth and side-view environmental adaptation remain shallow; Noll still needs a provisional authored person identity |
| Sites | Authored site silhouettes and physical state grammar | World adaptation is coarse palette-only; searched/exhausted transformation breadth is not proven per every site; guard occupant and passability must remain rule-owned |
| Resources | All 23 inventory identities are pairwise distinct; every applicable map family owns a distinct native-grayscale mass; six flora cues preserve exact host identity; Raw Essence/Mote exceptions and exhausted states are explicit; neutral resource-only sheen v1.1 is closed and vector-tested | Native body/sheens remain unintegrated; flora-linked cues must compose over the actual graded species; broader world-material adaptation must not weaken the accepted silhouette or disclosure boundary |
| Tile content | Ten semantic families plus collision evidence | Most are one canonical colored sprite. They need bounded same-meaning variants and shared world adaptation where appropriate, without weakening disclosure or traveller/drop distinctions |
| Portals/writing/cache | Semantically distinct and disclosure-tested | Still largely canonical single shapes; portal material/world variation, writing substrate variants and cache wear states are shallow |
| Minimap | Correct symbolic/disclosure boundary | Intentionally should **not** inherit decorative world variation. Validate hidden/revealed/discovered timing for every POI family after native art integration |
| Combat stage/UI | Static semantic grammar is golden | Dynamic visual depth intentionally deferred: animation, real world-graded actors, status motion and multiple backdrops remain uncovered |
| Splashes | Lifecycle compositor and disclosure boundary are golden | World scene palette currently uses four authored terrain categories, not the complete resolved world grade/material vocabulary; no animation by design |
| Bestiary/portraits | Not implemented | Critical later profile gap for generated creatures, specimens, companions and named cast |
| Equipment/items | Six-across 390pt icon grid, tapped detail, all eight slots, four truthful locations, independent selection/rarity, stable-instance snapshots and Pointed Blade craft checkpoint accepted | Five-identity economy bridge, complete item-family icon catalogue, material/provenance adaptation, drop/inventory/world correspondence and authored uniques remain; two-column prose cards are retired |

### Highest-priority shallow/collapsed outputs

1. Tile content, portals, caches and writing are still mostly one canonical colored glyph each.
2. Flora and creature identity are deep, but neither yet accepts the same resolved world-grade DTO as
   terrain; uncoordinated grading would make a world look assembled rather than native.
3. Generated/Binder/Quill persistence and native facing selection remain unresolved even though the
   straight-top-down visual profile itself is settled.

## Equipment and inventory dynamic-depth follow-up — 9 Aug 2026

Live-source audit establishes a richer identity boundary than the current blade/spear/bow proof:

- exactly eight persisted `GearSlot` raw values: `weapon`, `offhand`, `head`, `armor`, `hands`,
  `feet`, `tool`, `keepsake`; `armor` displays as Body and must never be renamed in serialized data;
- ordinary catalogue identity and SF Symbol icon are only the fallback. A physical instance may own
  `stableInstanceID`, family, construction tier, reforge rank, legacy credit, frozen slot/damage/
  reach/insulation/reactivity, consumed material samples, recipe version, specialist profile,
  display provenance and an authored unique-rule ID;
- resources are stackable pools and do not consume item slots, while physical `ItemStack` instances
  do. Raw Essence already delegates the accepted world-drop grammar, so inventory art must not create
  a second contradictory world identity;
- unidentified vs identified, ordinary catalogue vs crafted instance, worn vs stored, damaged/wild
  growth/reforged state, and authored unique rules are separate axes. Rarity color cannot own identity
  because the UI and grayscale/accessibility boundary require redundant shape/text.

Smallest future proof should begin with slot grammar, not all catalogue entries: eight unlabeled
native grayscale slot silhouettes; representative weapon close/mid/far families; light/heavy
protection; tool and keepsake; one found catalogue piece vs one persisted crafted instance across
world drop, inventory icon and character overlay. Material/provenance may adapt surface/detail while
slot and reach keep the large silhouette. Authored unique items retain authored identity and may not
be procedurally distorted. No equipment animation or complete lore-item catalogue is implied.
4. Stations/sites have authored identity but only coarse palette adaptation and insufficient
   same-state material/template breadth. Resources now meet the distinct-silhouette bar; their
   remaining gap is native integration and coherent host/world grading rather than family identity.
5. Splash scenes use a reduced authored terrain palette rather than the eventual full world material
   descriptor.
6. Bestiary and portrait families remain materially uncovered. Equipment now has an accepted spatial
   shell, but the full item catalogue, economy identity bridge and most animation families remain.

### Export defect found and corrected

The conformance PNG encoder previously parsed hex colors only while flora commands use CSS HSL/alpha.
Browser canvases were correct, but exported flora PNG pixels could be incorrect. The exporter now
parses both formats and keeps separate compressed-file and decoded-RGBA hashes. This is covered by the
full export test; earlier generated map packs must not be treated as current evidence.

## Sole-tester-first asset roadmap — 10 Aug 2026

**Status:** recommendations only; no game-code or economy-rule authorization. This ordering treats
reliable Essence continuity and early surplus offloading as the next playtest gates.

### What is already sufficient

- **Raw Essence on the map:** Resource v0.3 already delegates `essence_raw` to the accepted disclosed
  `wildDrop` footprint, distinct from nodes, travellers and ordinary item drops. It remains absent
  from the minimap and concealed by fog. Do not invent a second Essence node or redesign this sprite
  before the next playtest.
- **Named people:** Vance, Noll and Halloway already have accepted authored character descriptors and
  top-down catalogue coverage. Calling labels remain reference-only; their profession must not be
  encoded as anatomy.
- **Blacksmith place identity:** the accepted authored-place grammar includes a distinct side-view
  `blacksmith` forge across lifecycle stress states. It needs interaction-state composition, not a
  new building silhouette.

### Hard-blocker asset work, in order

1. **Essence continuity readout and pickup-to-wallet correspondence.** Keep the accepted Raw Essence
   world body, then prove its disclosed pickup row, inventory/return-report representation and refined
   Essence wallet are visibly different concepts. The UI must expose collected raw amount, refined
   equivalent, Spring yield and resulting ordinary-authored-bind runway through text plus stable icons;
   it must not imply that raw drops are already spendable Essence.
   - *Smallest acceptance evidence:* one native-phone color/grayscale strip showing concealed tile,
     revealed Raw Essence drop, pickup feedback, return report (`raw collected → refined + Spring →
     wallet/runway`) and insufficient/sufficient next-bind states, with VoiceOver order and exact
     accessible labels.

2. **Trading Post and Recycler place identities.** Neither station exists in the current 18-station
   AssetLab place catalogue. Author two side-view functional silhouettes: Trading Post as an open
   merchant counter/stock display/weighing workspace and Recycler as a dismantling/separation
   workspace. Trading Post represents rotating stock and buying eligible goods for gold; it must not
   imply generic resource-to-resource exchange. Its new stable station identity is `trading_post`,
   with no `exchange` migration alias. They must remain
   distinct from Storehouse, Workshop and Blacksmith by whole mass and negative space—not tiny signs,
   coins, recycle arrows or keeper-colored badges. Vance/Noll are independent occupants; staffing
   overlays must not mutate station identity.
   - *Smallest acceptance evidence:* unlabeled native color/grayscale row of Trading Post, Recycler,
     Storehouse, Workshop and Blacksmith in built state, plus compact foundation/built/damaged rows
     for the two new stations and staffed/un-staffed geometry equality.

3. **Inventory/offload decision grammar.** Build the minimum item/resource list components needed to
   make keep, sell and recycle safe: eligible, equipped, favorite/locked, unidentified, unique/
   narrative, zero-recovery and selected states; exact quantity/value/recovery preview; remaining
   inventory; confirmation and completed result. Destructive-state meaning must use shape, text and
   native control semantics rather than color alone. Bulk sale must visibly exclude protected rows;
   recycle preview must distinguish real crafted provenance from authored found-gear salvage.
   - *Smallest acceptance evidence:* two phone sheets, ordinary and large text, in color/grayscale:
     (a) mixed inventory bulk sale with at least one eligible resource, ordinary item, gear, equipped,
     locked, unidentified and unique row; (b) Recycler preview containing one crafted-provenance item,
     one found salvage-profile item, one zero-return item and one forbidden unique item. Include exact
     VoiceOver order and disabled-control behavior.

4. **Blacksmith first usable state.** Reuse the accepted forge and character identities. Asset work
   should cover only the first playtest actions: empty/no eligible item, eligible selection, material
   requirement, result preview, insufficient materials/Essence, confirm and completed state. Salvage
   belongs to Recycler; Blacksmith visuals must not imply it returns materials.
   - *Smallest acceptance evidence:* one phone color/grayscale state strip using the same persisted
     ordinary gear instance through inventory selection, Blacksmith preview and result, showing one
     visible material-surface change without rerolling its dominant identity. Include empty and
     insufficient states and large-text layout.

5. **Minimal item identity bridge.** Do not build the full equipment catalogue yet. Resolve only the
   ordinary items actually exercised by Trading Post/Recycler/Blacksmith fixtures: one world resource,
   one ordinary non-gear item, one authored found gear item, and one crafted gear instance. The same
   persisted item must retain its resolved icon across inventory, sell preview, recycle preview and
   Blacksmith preview. Raw Essence continues using its separate accepted resource/wallet grammar.
   - *Smallest acceptance evidence:* a four-item correspondence row across the relevant screens,
     native/grayscale, with pixel/identity assertions and malformed/missing-provenance fallbacks.

### Work that can pause until these checkpoints are playable

- further terrain-template breadth beyond the current top-down integration correction;
- combat or splash animation, additional combat backgrounds and status motion;
- bestiary, portraits and complete creature lifecycle matrices;
- full eight-slot equipment catalogue, specialist/unique/lore-item breadth and every material finish;
- broad station/site palette adaptation, tiers beyond those exercised by the opening stations, and
  additional site/resource families;
- portal/writing/cache decorative variants, minimap embellishment and complete world-entry palette
  adaptation;
- complete cast art revision, generated companion breadth and later-station identities.

### Roadmap acceptance rule

Asset work should advance only when it makes the next sole-tester action or consequence clearer.
Economy screens may use provisional numbers, but screenshots must be resolver-fed rather than
hand-labelled mock values. Visual golden acceptance does not finalize prices, recovery percentages or
character canon, and no icon may infer hidden provenance, identification, eligibility or value.

### Source-check corrections — 10 Aug 2026

The roadmap direction is accepted with four corrections from the current catalogues and economy
documents:

1. **Noll is a hard asset gap, not already covered.** Vance and Halloway have accepted descriptors and
   `mapTopDown` coverage, but Noll does not appear in `character-kit`, the accepted 28-person sheets or
   the live content catalogue. Noll remains a working design identity in
   `traveller-identity-noll-recycler-current.md`. Before a staffed Recycler proof, author a clearly
   provisional named descriptor and map/combat correspondence, then expand the authored-order fixture;
   do not borrow Vance, Halloway or a generated stranger as a placeholder.
2. **Move the minimal identity bridge before the destructive screen proofs and include a material
   sample.** Trading Post/Recycler/Blacksmith fixtures cannot prove persisted correspondence without their
   objects first. The smallest honest bridge is five identities, not four: one world-resource stack,
   one property-bearing material sample, one ordinary non-gear item, one authored found-gear item and
   one crafted gear instance. Material samples are required to prove real `consumedSamples`
   provenance and foundational Blacksmith inputs; a generic world-resource icon cannot substitute.
3. **Use a guaranteed foundational Blacksmith action.** Current gear design makes one Pointed Blade
   fixture the first crafted-instance implementation slice. The first usable proof should follow
   selected qualifying samples → exact Pointed Blade preview → new persisted output, including empty
   and insufficient states. Do not assume a same-item material-surface reforge is the guaranteed
   opening action; add that only when the live reforge path is the state under test. Salvage remains
   Recycler-owned.
4. **Keep Spring dividend and anti-lock subsidy separate.** The return report should show Raw Essence
   collected, 2:1 refined equivalent, ordinary tier-0 Spring return, any exact anti-lock shortfall as
   its own exceptional line, final spendable wallet and ordinary-authored-bind runway based on the
   recent median—not the 10-Essence blank minimum. Combining subsidy into “Spring yield” would hide
   the economy failure the telemetry is meant to expose.

Recommended dependency order is therefore: Essence continuity readout; Noll plus Trading Post/Recycler
place identities (parallel where practical); five-identity item/material bridge; safe Trading Post/
Recycler keep-sell-recycle screens; foundational Blacksmith craft states. The existing broad pause
list remains appropriate. Favorite/locked/unidentified/unique protections, exact atomic previews and
found-salvage-versus-crafted-receipt distinction agree with current design.
### Engineering sanity check — live inputs for the sole-tester roadmap (10 Aug 2026)

**Recommendations only; read-only review, with no AssetLab or game-code changes.** Reusing the
accepted Raw Essence `wildDrop` and authored Blacksmith place is sound. Trading Post and Recycler are
absent from both the live station catalogue/IDs and the AssetLab place catalogue, so their authored
silhouettes are genuinely new work rather than variants of an existing live station.

The Essence strip is mostly resolver-feedable today. `RunExitSummary.EssenceEconomy` persists raw
collected, refined equivalent, bind cost paid, Spring yield, subsidy and net runway; current base
resources/Essence plus `minimumBindCost` and `spendableEssence` can derive the insufficient/sufficient
bind states. One wording/data boundary matters: `refinedEquivalent` is the potential value of the raw
haul, not evidence that refinement occurred. `refineEssence` later mutates the resource pool and
wallet but does not append a refinement transaction to the exit summary. Therefore evidence may
truthfully show return-time raw, potential refined equivalent, Spring credit and current runway, or
a separate live Workshop refinement before/after result. It cannot label the whole
`raw → refined → wallet` chain as completed from the existing return record alone.

The proposed sell/recycle sheets are not resolver-feedable yet. There are no Trading Post/Recycler
station definitions, sale or recovery rules, preview/result DTOs, prices, recovery quantities,
favorite/locked state, or bulk-selection/exclusion contract. `identified` is persisted;
equipped/worn is derivable; an authored unique gear rule may exist as
`gearProfile.authoredUniqueRuleID`. Those facts do not define narrative protection, eligibility,
zero-return, or yield. Asset proofs should wait for a minimal rules-owned decision DTO rather than
inventing these values. It should expose stable row identity, action kind, selected quantity,
eligibility plus reason, protection states, unit/total return, remaining inventory and confirmed
result; exact enum and raw-value ownership belongs to Engineering/design.

The live Blacksmith can feed empty, target, requirements, material candidates, Essence shortfall,
confirmation and completion using `ReforgeTarget`, `SmithRules.Requirement/Readiness`, and persisted
gear identity. However, reforging consumes samples without recording them on the reforged profile;
only newly constructed physical gear persists `consumedSamples`. A reforge proof may show rank or
workmanship change, but not a truthful material-derived surface change unless that provenance is
persisted. The Design recommendation to use a foundational Pointed Blade construction therefore
matches the current live path: it can show material adaptation, while correctly producing a new
item rather than pretending the input gear remains the same instance.

The identity bridge must distinguish persistence units. A world resource is aggregated by
`ResourceID` and has no physical item instance. A property-bearing `MaterialSample` persists source,
grade and properties inside an inventory bin. Ordinary non-gear items have a bin/stack `InstanceID`
and may merge. Authored found gear and crafted gear have stable physical identity through
`gearProfile.stableInstanceID`, with crafted provenance in family, recipe, specialist and consumed
samples. Correspondence assertions should key each family accordingly, not pretend all five share
one identity model. Inventory/Blacksmith correspondence can proceed; Trading Post/Recycler columns remain
blocked until their live rule DTOs exist.

## Spatial game-interface visual-language review — 10 Aug 2026

**Status:** recommendations only; no AssetLab or game-code expansion authorized. Library is the sole
immediate proof from `game-interface-spatial-redesign-current.md`.

### Reusable identity sources

- **Stations:** accepted side-view place silhouettes have enough whole-mass identity for later Base
  tiles. Use each authored building with consistent padding and a label; do not replace it with a
  generic SF Symbol or crop it until only a tiny emblem remains.
- **Travellers:** accepted authored descriptors and `mapTopDown` figures can supply palette,
  crown/body/carry silhouette and a compact person cameo for known-person tiles. They are not
  portraits and must not be enlarged into invented faces. Calling, station, stats and signature do
  not select tile anatomy.
- **Creatures/flora:** accepted species silhouettes can support later Bestiary tiles only after
  legitimate discovery. Use species identity, not a generic paw/leaf glyph; specimen state and hidden
  traits remain inside disclosed detail.
- **Items/resources:** current item depth is insufficient for a broad Storehouse grid. The planned
  five-identity bridge should precede conversion. Resource, sample, ordinary item, found gear and
  crafted gear must not collapse into one square-container icon.
- **Writing:** accepted diary-page and found-writing map glyphs establish broad family distinction,
  but are too small and map-specific to become the complete Library tile set unchanged. Library tiles
  may reuse their page/book/mark vocabulary at a larger UI profile without inventing text, runes or
  location clues.

### Compact tile grammar

- Phone portrait uses two equal columns with square or nearly-square tiles, at least 44pt each and a
  stable artwork field above a short visible label. Large text reflows to one column.
- Tile silhouette owns destination recognition; color is secondary. Selection, progress and newly-
  added state are UI overlays outside identity art.
- Unknown people, species, note families and worlds are omitted unless game rules expose an anonymous
  slot. Never show a grid of silhouettes or `?` tiles whose count leaks the hidden catalogue.
- SF Symbols may remain for conventional controls such as back, search or sorting. They should not
  stand in for traveller, station, species, writing-family or item identity.

### Smallest Library acceptance proof

Produce one static 390pt portrait-phone shell from resolver-owned knowledge, with ordinary text and
large-text variants plus literal grayscale:

1. **People:** two-column tiles for six known travellers using compact non-portrait cameos, visible
   names and honest recovered-page counts. Include selected and newly-updated overlays. Unknown
   travellers and global hidden totals are absent. A focused diary example uses `Location` and
   `Other pages` peer tabs, proving each recovered page has one top-level home.
2. **World notes:** two-column tiles for only recovered fixture families—field notes, route marks,
   site fragments and working scraps—with distinct book/page/map-fragment mass rather than recolored
   copies. Omit one absent family to prove discovery safety.
3. **History:** show the tab transition into the existing chronological list. Do not force history
   entries into tiles when ordered comparison is the mechanic.

Acceptance requires native two-column layout without chosen-name truncation, one-column large-text
reflow, 44pt hit ownership, VoiceOver order of tabs then tiles then detail, grayscale identity, no
duplicate recovered page across People and World notes, and no SF Symbol as primary person/note
identity. This proof does not authorize portraits, Base conversion, Bestiary, inventory grid,
animation or new discovery rules.

### Equipment item-grid bridge — recommendations for the 10 Aug playtest review

- Location is separate from item identity: **Stored** is `base.inventory`; **Worn** names one
  traveller plus one of the eight serialized gear slots; **Overflow** is safe home `spillover`
  waiting to be sorted after a full Storehouse; **Carried** is current-run `satchelItems`, not worn
  gear or the instrument loadout.
- Stable item/family art owns the tile center. A separate fixed edge channel owns location using
  text plus shape: shelf `Stored`, person `Worn · Mara`, open tray `Overflow · safe`, satchel
  `Carried · current world`. Rarity/material color never carries location or accessibility.
- The slot filter is navigation, never mutation. Use `All | Weapon | …` with horizontal/overflow
  navigation rather than squeezing all nine choices into one phone row. Announce the selected slot
  and result count; an empty filter says `No matching pieces`, not `No inventory`.
- In a selected Weapon view, pin the chosen traveller's currently worn weapon as the comparison
  baseline. Other people's worn pieces remain wearer-labelled and are not equip candidates unless
  live rules authorize transfer. Overflow/Carried can appear for ownership accounting while their
  unavailable actions remain disabled with an exact reason.
- Comparison uses an aligned detail row/panel after selection, with signed damage/protection and
  known reach/damage family where applicable. Use `+`/`−` text and direction/shape, never green/red
  alone or an unqualified `better`. Do not disclose unknown properties, unique rules or provenance;
  non-gear resources/items have no equipment comparison.

Smallest evidence is one 390pt Storehouse/Equipment screen at ordinary and accessibility-large text,
each in color and literal grayscale. Use 8–10 real persisted fixtures spanning all four locations;
selected Weapon retains a worn Pointed Blade baseline plus stored stronger/weaker, carried and safely
overflowed weapons, while All also shows offhand/head/body/tool/keepsake. Two-column tiles collapse
to one column at large text. If movement is shown, use four labelled snapshots of one stable instance
with exact central-icon pixel equality—never duplicate one physical instance across locations in a
single state. Validate 44pt nonoverlapping hits; VoiceOver order filter → name → quantity → slot →
location/person → known status → detail/actions; no clipped badges; grayscale location/selection;
Overflow never implies loss; Carried and Worn never converge.

### Trading Post / Vance live DTO audit (10 Aug 2026)

**Recommendations only; read-only audit, with no game, AssetLab or Simulator changes.** Current
design documents describe the intended Trading Post economy, but the live code does not yet contain
that economy boundary. There is no `TradingPostState`, `goldCoins`, stock snapshot/line, refresh
sequence, sale/appraisal preview, revision token, transaction result, Trading Post station constant,
`trading_post` station catalogue entry, route or screen. No live buy/sell/appraisal rules were found.
The station integration matrix's claim that safe selling and rotating stock “exist” is therefore
ahead of the checked-in source and must not be used as an AssetLab fixture authority.

#### Truthful inputs available now

- Vance has a real `TravellerDef`: exact ID `vance`, name, calling, icon, blurb, authored order,
  campaign phase, three authored signature clues, diary lean and combat lean. AssetLab may fixture his
  accepted authored person identity and label him as the intended Trading Post owner only as a
  design annotation. Live data does not yet link him to a Trading Post station. Also, live
  `campaignPhase` remains `mid`, while current roadmap documents intend Vance as the first opening
  economy find; AssetLab must not present that reorder as implemented state.
- The authored `trading_post` place silhouette and its neutral foundation/built/tier/damaged proofs
  are valid AssetLab identities, but not live station availability or lifecycle facts.
- `ResourcePool` supplies exact resource ID and quantity. `MaterialSample` supplies kind, six
  properties, grade, source and qualifier. `ItemStack` supplies bin ID, catalogue ID, count,
  identified state, upgrade/wild-growth state, protected-return count, material receipts, optional
  distilled-core facts and optional gear profile. Physical gear supplies stable instance ID,
  family/construction/reforge/legacy/slot/damage/reach/material receipt/specialist/display provenance
  and authored unique-rule ID. Equipped location is derivable from actual Binder/roster ownership.
  These fields can support identity/location correspondence fixtures without claiming trade action.

#### Facts AssetLab cannot truthfully invent

Prices and price bands, gold wallet, stock lines/quantities, refresh timing, appraisal band, buy/sell
eligibility, favorite/locked state, narrative/nontransferable classification, bulk exclusion,
selection totals, inventory remainder, atomic confirmation, stale-preview handling and completed
receipts are not live resolver facts. The current item schema explicitly lacks favorite/locked flags;
rarity, `ItemDef.Kind`, identification and `authoredUniqueRuleID` are not substitutes for the missing
transfer policy. AssetLab may demonstrate component grammar using values prominently marked
noncanonical proof data, but a resolver-fed/golden Trading Post flow must wait for rules-owned DTOs.

#### Recommended closed UI resolver contract

Expose one versioned, recursively closed DTO produced by game rules rather than passing raw
`BaseState` into the renderer. Suggested top-level fields are:

- exact immutable versions and `stationID: "trading_post"`;
- station state (`unavailable`, `foundation`, `built`) and tier; keeper presence with exact
  `travellerID: "vance"`;
- wallet `goldCoins`, persisted stock revision/refresh sequence/outcome ID and refresh state
  (`awaitingFirstOutcome`, `current`);
- one screen mode (`browse`, `salePreview`, `saleConfirm`, `purchasePreview`, `completed`, `stale`),
  plus inventory revision and opaque rules-produced preview token;
- closed stock rows and owned rows using identity `oneOf` branches for resource, material sample,
  ordinary item and physical gear. Each branch carries its real persistence handle, display-safe
  resolved identity, quantity/location and rules-produced unit/total gold;
- selection quantity plus one eligibility enum and explicit localized/display reason. Protection
  reasons must include at least unidentified, equipped, locked, favorite, unique/narrative,
  nontransferable, legacy-masterwork, unavailable and stale; eligibility is never inferred by art;
- exact preview totals, removals, remaining inventory/stock and completed result/receipt, all supplied
  by the same atomic rules resolver.

The adapter should reject unknown fields/enums, duplicate handles, negative quantities/prices,
selected ineligible rows, totals inconsistent with rows, preview-token/revision mismatch and any
Vance/Trading Post identity mismatch. AssetLab should render only this disclosure-safe resolved DTO;
refresh RNG, price lookup, eligibility, atomic commit and migration remain game-owned.

# Progress update — 9 Aug 2026

The first remediation gate is implemented inside AssetLab: manifest v3 separates the authoring descriptor, exact game identity, visual-only render hints, structured adapter diagnostics, and pipeline versions, with an explicit creature/flora identity kind. Creature emanation now has exact light/heat/caustic allocation rather than a lossy dominant-kind authoring control; v3 descriptor migration is covered and emits an assumption warning. Creature topology is confined to render hints, optional defence maps to `null`, and flora tissue resultant values are derived explicitly. Unit and golden-regression suites pass with 0/36 accepted pixel changes. Final enum/unit spelling remains an engineering confirmation before integration; AssetLab has not modified or integrated with game code.

## Current checkpoint disposition — 10 Aug 2026 evening

This supersedes stale assumptions in the earlier roadmap sections without erasing their review
history:

- Raw Essence remains the accepted wildDrop and now participates in the disclosure-safe resource
  sheen contract without acquiring a second body. Resource v0.5 closes family readability and static/
  animated distinction in AssetLab; native integration remains.
- Trading Post (`trading_post`, never `exchange`) and Recycler authored place identities are accepted,
  including shared neutral pre-identity foundation, built/damaged stress, staffing-independent
  geometry and five-workplace native grayscale separation.
- The first Pointed Blade Blacksmith checkpoint is accepted across missing, shortfall, review,
  destructive confirm and newly Stored result states. It does not claim reforge or salvage.
- The spatial inventory shell is now six icons per 390pt row, not two-column prose cards. It has
  tapped detail, exact slot filtering, stable item identity, four truthful locations and orthogonal
  selection/rarity grammar.
- Noll remains the missing person identity. The working design document exists, but Noll is not in
  the accepted 28-person AssetLab catalogue or the live content catalogue. Do not stage Noll with a
  borrowed/generated figure.
- The immediate remaining economy-asset sequence is therefore: provisional reviewed Noll descriptor;
  five-identity resource/sample/nongear/found-gear/crafted-gear bridge; then resolver-backed Trading
  Post and Recycler keep/sell/recycle states. Essence telemetry wording/data and native action DTOs
  remain Engineering/game-rule dependencies, not values for AssetLab to invent.

### Player-facing screen grammar reconciliation

- Trading Post v0.2 follows the settled tangible-object grammar: exactly six stock icons and six
  holding icons per ordinary phone row, no permanent names below them, and one tapped detail surface
  before any explicit confirm action. Vance remains a separate person cameo and `trading_post` remains
  a place silhouette; neither is misrepresented as an object-grid cell.
- Common equipment/merchant visual coverage currently includes blade, spear, guard, hood, body,
  gloves, boots, tool, keepsake and material-sample silhouette families. These are pairwise checked by
  occupied-pixel identity rather than labels or color.
- Resource v0.5 already covers the complete 23-ID inventory catalogue with pairwise-distinct icon
  silhouettes, including Raw Essence through its accepted identity and Mote as inventory-only. Its
  map acquisition split remains separate: Mote has no map art and Raw Essence delegates wildDrop.
- Therefore the next actual pictorial gap in the new priority is consumable families plus the
  unidentified-curio restraint. Recipe-family glyphs follow; people/place/ordered-prose screens must
  not reuse the six-across object grammar merely for visual consistency.
## 11 Aug 2026 — exact compact item identity coverage after catalogue v0.2

Read-only reconciliation against `Sources/Content/Data/items.json` finds **78 live catalogue IDs**.
AssetLab catalogue-item v0.2 now owns reviewed 32px identities for **30/78**: eleven ordinary
equipment identities, all seventeen current consumables, and both identified curios. The two curios
share one disclosure-neutral unknown body before identification. The remaining **48/78** still rely
on generic/native fallback symbols and are not covered by the accepted AssetLab exact-ID map.

### Exact uncovered live IDs

- **5 treasure/Channelworks identities:** `essence_crystal`, `heat_core`, `caustic_core`,
  `light_core`, `conduit_fixture`.
- **2 carried key/progression identities:** `cache_key`, `anchor_frame`.
- **33 standard equipment progression identities:**
  - close blade line: `blade_keen`, `ripping_hook`, `the_long_grievance`;
  - awl/raking line: `raking_edge`, `blade_binders`, `hairsplitter`;
  - maul line: `banded_mace`, `anvilfall`, `the_settled_argument`;
  - pick/spear line: `warded_spear`, `parting_needle`, `the_kept_distance`;
  - off-hand: `banded_buckler`, `tower_guard`, `the_unarguable`;
  - head: `ridged_helm`, `visored_casque`, `crown_of_quiet`;
  - body: `guard_banded`, `guard_vault`, `the_standing_wall`;
  - hands: `studded_gloves`, `gauntlets_of_hold`, `the_sure_hands`;
  - feet: `shod_boots`, `longstriders`, `the_unhurried`;
  - tool: `balanced_pick`, `corebreaker`, `the_willing_edge`;
  - keepsake: `cold_compass`, `someones_ring`, `the_first_page`.
- **8 wild/apex-only weapon identities:** `two_natured_blade`, `long_fang`, `ranked_spear`,
  `rimed_edge` (display name Barbed Edge), `living_hook`, `quiet_knife`, `bloodletter`,
  `warded_haft`.

### Authoritative identity boundary

1. **Catalogue identity is authored.** Every known `catalogItemID` owns a reviewed dominant mass and
   negative-space silhouette at native 32px. It is never generated from SF Symbol name, rarity,
   tier, stats, price, effect, profession, provenance, array order, or item blurb. Progression lines
   may share construction ancestry, but exact IDs remain distinguishable in literal grayscale.
2. **Persisted found instances preserve catalogue identity.** Quantity, location, selected state,
   favorite/lock, equipped wearer, price and eligibility are independent tile/detail channels and
   never reroll the icon.
3. **Crafted gear is a separate authored-family adapter, not a generic procedural icon.** A live
   `GearInstanceProfile.familyID`/recipe ID owns the core construction silhouette (for example
   `pointed_blade`, not its `blade_chipped` catalogue fallback). Persisted material and construction
   receipt may supply bounded surface/accent detail only after a family mapping exists; they cannot
   distort the family silhouette or encode hidden stats. Provenance and exact consumed properties
   remain detail text.
4. **World materials and pooled resources are not catalogue items.** `ResourceID` uses the accepted
   Resource v0.6 identity. An individual world-material specimen keeps its legitimately known
   material-family cue and stable value identity, with grade/properties/source in detail; it does not
   create a player-facing “Sample” category or borrow a catalogue icon.
5. **Unknown presentation is disclosure-owned.** Unidentified curios share one opaque unknown body
   regardless of eventual result. Unknown catalogue IDs reject diagnostically rather than silently
   inheriting a known family or SF Symbol.
6. **Unique/lore/progression objects stay authored.** Anchor Frame, Cache Key, cores, Conduit fixture,
   Essence Crystal, mythic equipment and wild-only weapons must not be generated by recoloring an
   ordinary item. Their core silhouette is authored; only explicitly approved world/material
   adaptation may be procedural.

### Smallest next isolated AssetLab proof

Game Design's exact dominant-mass/collision brief for this slice is
`catalogue-item-identity-tier2-current.md`. It adds no tier badge/stat encoding and leaves pixel
execution with Asset.

Author the **eleven tier-2 catalogue counterparts** first: `blade_keen`, `raking_edge`, `banded_mace`,
`warded_spear`, `banded_buckler`, `ridged_helm`, `guard_banded`, `studded_gloves`, `shod_boots`,
`balanced_pick`, and `cold_compass`.

Evidence is one lossless native 32px six-across color/literal-grayscale sheet containing these eleven
beside the eleven already accepted tier-1 comparison identities. Physically related objects retain
bounded construction ancestry only where the authored object supports it; slot/mechanical pairings
such as Long Pick/Warded Spear or Pressed Leaf/Cold Compass must remain honestly different objects.
Tier cannot become a standardized size, band, symmetry, ornament, damage or reach code. The eight
displayed weapon identities remain mutually distinct; all 22 remain
distinct from accepted resource/material icons and the neutral unknown body. Rarity/tier badges,
names and stats remain outside icon pixels. Add an explicit closed `catalogItemID → authoredVisualID`
mapping, exact-ID coverage/unknown rejection, pairwise occupied-silhouette tests, and same-ID pixel
equality across Stored/Trading Post/Recycler/Blacksmith contexts.

After that reviewed slice, proceed in bounded sets rather than one 48-item wall: tier 3 (11), tier 4
(11), seven key/treasure objects, then eight wild-only weapons. The tier-3 semantic/collision brief is
already prepared in `catalogue-item-identity-tier3-current.md`; it does not authorize skipping the
tier-2 review. The subsequent mythic set is bounded by
`catalogue-item-identity-tier4-current.md`, which expressly forbids universal glow/ornament or
invented lore as tier coding. The seven-key/treasure set is bounded by
`catalogue-item-identity-key-treasure-current.md`, including the shared-but-distinct core grammar and
destination-disclosure restrictions. Crafted recipe-family identities are a separate adapter milestone and must not be
falsely counted as covered merely because they retain a catalogue fallback ID.

Game Design has now prepared semantic/collision briefs for all **48 visually uncovered exact live
catalogue IDs**: tier 2, tier 3, tier 4, key/treasure and wild/apex sets. This closes the design-input
gap only; AssetLab/native visual coverage remains 30/78 until each bounded sheet is authored,
reviewed and integrated. The final wild set uses
`catalogue-item-identity-wild-weapons-current.md` and explicitly rejects retired rime/cold imagery for
save ID `rimed_edge`.

The roadmap's remaining character-identity gap must not be read as another pass over the accepted
28-person named cast. `binder-quill-generated-visual-identity-current.md` scopes the actual missing
work: a persisted noncanonical Binder appearance, one authored Quill identity, and a generated-person
descriptor resolved and stored once. Portraits remain a later, separate family.

**Current execution reservation — 11 Aug 2026:** Aimee has reserved character, building/station,
weapon, inventory and item artwork from further AssetLab execution. Preserve the accepted proofs and
the 48 semantic briefs as reference; do not schedule their remaining sheets or expansions through
Asset Lead unless Aimee reopens that boundary. This changes work ownership/queueing, not the honest
30/78 accepted item-coverage count. P0 world-color production-pack work and later combat ability-node
glyphs are outside the reserved categories.
