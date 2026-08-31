# Player Wiki resource and crafting publication manifest V1

**Status:** implementation-facing wiki publication map. Stable IDs and repository paths appear here only;
they must never be rendered as player copy. This manifest maps the implemented-only source packets to
routes that already exist in the generated Player Wiki.

**Source packets:**

- `docs/player-wiki-crafting-systems-source-current.md`
- `docs/player-wiki-resource-source-copy-current.md`

**Current wiki limitation:** neither new source packet is an input to `GameWiki/scripts/generate.mjs` at
this checkpoint. Their copy is therefore approved source, not currently published output. A future
GameWiki-only integration must add both exact files to the closed input registry, project only the mapped
sections below, regenerate `wiki-data.json`/`manifest.json`, and preserve existing runtime/catalogue
authority. File existence alone is not publication approval.

## Publication rules

1. Player-visible titles and links use canonical names, never IDs or repository paths.
2. A route receives only implemented copy. Proposal and decision documents are forbidden generator inputs
   for player-facing fields.
3. Resource acquisition tendencies appear only after that resource is legitimately disclosed to the
   player. Search text, summaries and cross-links obey the same boundary.
4. An item page receives recipe/use copy only when the item itself is visible under existing catalogue and
   discovery rules.
5. A station page receives keeper/build/access copy only when existing station disclosure permits it.
6. Missing semantic routes fall back to the owning station page or `resources-crafting`; the generator
   must not alias a crafted recipe to a visually similar found-item page.
7. Unsupported or contradictory statements remain flagged in this manifest and are not projected.

## Crafting-system route map

| Source section | Primary existing route | Exact owner IDs | Secondary existing routes | Publication note |
|---|---|---|---|---|
| How making works | `resources-crafting` | — | `station/storehouse`, `station/essence-spring` | Replace/extend overview copy; keep scalar/exact/currency distinction intact. |
| Essence Spring — refining | `station/essence-spring` | station `essence_spring`; research `essence_second_pass`, `essence_continuous_settling` | `resource/essence-raw`, `resources-crafting` | Publish 2:1 and 3:1 rates only from current rules/tuning. |
| Apothecary — preparations | `station/apothecary` | station `apothecary` | `catalogue/consumables`, item routes below | Station page owns access/readiness; item pages own exact recipe/effect copy. |
| Blacksmith — pointed blades | `station/blacksmith` | station `blacksmith`; live recipe `pointed_blade` | `resources-crafting`, `catalogue/gear` | No exact crafted-recipe route exists. Do not link to fallback `item/blade-chipped` as though it were the crafted family. |
| Tannery — protective gear | `station/tannery` | station `tannery`; recipes `supple_coat`, `working_gloves`, `working_boots` | `resources-crafting`, `catalogue/gear` | No crafted-family routes exist; keep family copy on station/overview. |
| Bowyer — far weapons | `station/bowyer` | station `bowyer`; recipes `longbow`, `sling`, `throwing_set` | `resources-crafting`, `catalogue/gear` | Do not alias to catalogue fallbacks. |
| Weaponsmith — fitted weapons | `station/weaponsmith` | station `weaponsmith`; recipes `weaponsmith_fitted_point`, `weaponsmith_fitted_edge`, `weaponsmith_fitted_maul` | `resources-crafting`, `catalogue/gear` | Fitted Polearm remains absent because it is not in the current ordinary recipe list. |
| Armoury — rebuilding | `station/armoury` | station `armoury`; current Rigid/Insulated/Balanced profile owner | `resources-crafting`, `catalogue/gear` | Exact rebuilt output stays on its real item detail; no generic rebuilt-item route is invented. |
| Reforging | `resources-crafting` | existing reforge rules owner | owning eligible item route when already disclosed | No dedicated reforge route exists. Link to the exact item only after selection; otherwise overview. |
| Field instruments | `station/survey-post` | station `survey_post`; eight canonical `PressureTargetID` instrument subjects | `resources-crafting` | Instruments are not ordinary catalogue item routes here; grades and formulas remain on Survey Post. |
| Prepared ink | `station/scriptorium` | station `scriptorium`; Writing owner `writing_desk` | `station/writing-desk`, `resources-crafting` | No individual vial/colour routes exist. Do not invent item routes. |
| Personal Compounds | `station/scriptorium` | capability `compoundAssembly`; proven statement and personal Compound owners | `station/writing-desk`, `resources-crafting` | No dedicated Runebook route exists; keep formalization copy on Scriptorium. |
| Seamward inscription | `station/scriptorium` | inscription `seamward`; source item `seamlight` | `item/seamlight`, `catalogue/gear`, `resources-crafting` | No inscription route exists; link exact eligible gear only after selection. |
| Distilled Cores | `station/distillery` | station `distillery`; items `heat_core`, `caustic_core`, `light_core` | `item/heat-core`, `item/caustic-core`, `item/light-core`, `resources-crafting` | Item pages may state exact production/custody; downstream limits remain explicit. |
| Heat Conduit Fixture | `station/channelworks` | station `channelworks`; item `conduit_fixture` | `item/conduit-fixture`, `item/heat-core` | Publish that the current loop ends at the stored Fixture. No weapon promise. |
| Anchor Frame | `station/anchorage` | station `anchorage`; item `anchor_frame` | `item/anchor-frame`, `resources-crafting` | Item page owns exact six-selection/field-use summary after existing disclosure. |
| Recycler | `station/recycler` | station `recycler` | `resources-crafting`, exact disclosed item routes | Never imply universal scalar-to-sample conversion. |
| Output custody | `station/storehouse` | stations `storehouse`; Waiting inventory owner | `resources-crafting` | Merge/new/Waiting details remain rules-derived, not static promises per item. |

## Apothecary item route map

| Stable item ID | Existing route | Source family | Publishable implemented facts |
|---|---|---|---|
| `salve_lesser` | `item/salve-lesser` | Remedies | exact 25+ flexible material, Resin 1, healing role |
| `salve` | `item/salve` | Remedies | exact 40+ insulating material, Pulp 2, Spore 1, Resin 1, healing role |
| `salve_greater` | `item/salve-greater` | Remedies | exact 60+ reactive material, Ichor 1, Spore 2, Resin 2, healing role |
| `draught_clearing` | `item/draught-clearing` | Remedies | exact 35+ reactive material, Pulp 1, Salt 1, clears poison/bleeding |
| `draught_quenching` | `item/draught-quenching` | Remedies | exact 45+ insulating material, Reagent 1, Resin 1, clears burning/dazzle |
| `antidote_broad` | `item/antidote-broad` | Remedies | exact 65+ reactive material, Ichor/Reagent/Spore 1 each, clears one eligible affliction |
| `stonebark_tonic` | `item/stonebark-tonic` | Remedies | exact 45+ hard material, Timber 1, Resin 1, next-affliction protection |
| `venom` | `item/venom` | Coatings | exact 55+ reactive material, Toxin 1, Fibre 1, next-hit poison |
| `firebrand` | `item/firebrand` | Coatings | exact 60+ reactive material, Reagent 1, Sulfur 1, next-hit burning |
| `briar_oil` | `item/briar-oil` | Coatings | exact 50+ flexible material, Fibre 1, Resin 1, next-hit bleeding |
| `flashsalt` | `item/flashsalt` | Coatings | exact 55+ lustrous material, Reagent 1, Mercury 1, next-hit dazzle |
| `seamlight` | `item/seamlight` | Field preparations | Quartz/Resin/Fibre 1 each, portal guidance, zero illumination |
| `scent_mask` | `item/scent-mask` | Field preparations | exact Hide/Pelt/Down/Oil, Reagent 1, scent-only masking |
| `solvent` | `item/solvent` | Field preparations | exact 40+ reactive material, Reagent 1, Salt 1, exact carried Curio identification |
| `lure` | `item/lure` | Field preparations | exact 50+ reactive material, Toxin 1, Pulp 1, nearest eligible visible roaming target |
| `stillwater` | `item/stillwater` | Field preparations | exact 60+ lustrous material, Rift-glass/Mercury 1, Essence 6, Stability restoration |
| `waystone` | `item/waystone` | Field preparations | exact 70+ hard material, Rift-glass/Mote 1, Essence 12, full eligible haul return |
| `torch` | `item/torch` | Field preparations | exact 30+ reactive material, Resin 1, Timber 2, vision raised to Torch level |
| `farsight_draught` | `item/farsight-draught` | Field preparations | exact 50+ lustrous material, Quartz/Ichor 1, nearest eligible unrevealed site |

Every route above already exists. The wiki integration must retain catalogue disclosure and must not make a
hidden/unknown item searchable merely because recipe copy exists.

## Core, Fixture and Frame item routes

| Stable item ID | Existing route | Publishable implemented boundary |
|---|---|---|
| `heat_core` | `item/heat-core` | Distillery recipe, potency/provenance, and current conversion to Heat Conduit Fixture |
| `caustic_core` | `item/caustic-core` | Distillery recipe and stored/recoverable custody; no playable housing/effect |
| `light_core` | `item/light-core` | Distillery recipe and stored/recoverable custody; no Torch/Lantern/illumination claim |
| `conduit_fixture` | `item/conduit-fixture` | Heat Core conversion or authored Oda restoration; stored Fixture only |
| `anchor_frame` | `item/anchor-frame` | six distinct exact materials + Essence 60; pack/use at valid anchoring point |

## Resource route map

Each source heading in `player-wiki-resource-source-copy-current.md` projects to exactly one existing route.
The generator may add recipe/research/service cross-links, but the stable detail route does not change.

| Stable resource ID | Player title | Existing route | Disclosure/copy note |
|---|---|---|---|
| `rubble` | Rubble | `resource/rubble` | Current zero-use truth must remain visible; do not publish proposed Reliquary use. |
| `clay` | Clay | `resource/clay` | Publish Rank 0 tendency, five foundations and current studies. |
| `ore` | Iron Ore | `resource/ore` | Route keeps historical `ore` slug; player title remains Iron Ore. |
| `copper` | Copper | `resource/copper` | Publish Extraction 1, two foundations, Cyan and current studies. |
| `silver` | Silver | `resource/silver` | Publish Extraction 2, rare sale-only stock boundary, precision uses. |
| `gold` | Gold | `resource/gold` | Publish Extraction 2, precious sale-only boundary and Weaponsmith uses. |
| `quartz` | Quartz | `resource/quartz` | Publish current optical/station/research breadth; no proposed relief substitutions. |
| `obsidian` | Obsidian | `resource/obsidian` | Publish Depth ink and current zero building/research truth. |
| `salt` | Salt | `resource/salt` | Publish Tannery, Clearing, Solvent and Fitted Layers. |
| `sulfur` | Sulfur | `resource/sulfur` | Publish Firebrand, Heat Core and Yellow ink. |
| `mercury` | Mercury | `resource/mercury` | Publish Extraction 3, rare boundary, current preparation/instrument studies. |
| `adamant` | Adamant | `resource/adamant` | Publish Extraction 4 and current study/exact-material uses only. |
| `fiber` | Fibre | `resource/fiber` | Route uses American-spelled ID; player title remains Fibre. |
| `timber` | Timber | `resource/timber` | Publish flora, five foundations, current recipes/studies. |
| `pulp` | Pulp | `resource/pulp` | Publish flora, two foundations, preparations and compound/Spring studies. |
| `resin` | Resin | `resource/resin` | Publish secondary woody yield and all current binder/preparation uses. |
| `toxin` | Toxin | `resource/toxin` | Publish chemical-defence flora and current Venom/Lure/Caustic uses. |
| `spore` | Spore | `resource/spore` | Publish fungal acquisition and three remedies. |
| `reagent` | Reagent | `resource/reagent` | Use current name only; do not publish proposed “volatile extract” definition yet. |
| `ichor` | Ichor | `resource/ichor` | Preserve current scalar/exact custody distinction; do not claim a conversion. |
| `rift_glass` | Rift-glass | `resource/rift-glass` | Publish Extraction 3 and Stillwater/Waystone/Fine Scale only. |
| `essence_raw` | Raw Essence | `resource/essence-raw` | Current executable sources include direct pickups and selected searched sites; spoiler-gate site detail. |
| `mote` | Mote | `resource/mote` | Publish Reality custody, Constellation and Waystone; withhold unsupported Chaining debit. |

## Cross-link resolution

Player-facing bracket links in the source packets resolve as follows where an exact page already exists:

- station names → `station/<station-slug>`;
- resource names → the exact `resource/*` route above;
- consumable/Core/Fixture/Frame names → the exact `item/*` routes above;
- general Resources, Exact Materials, crafting readiness and output custody → `resources-crafting`;
- physical crafted-family summaries → their owning station plus `catalogue/gear`, never the found-item
  fallback route;
- ordinary consumable family summary → `catalogue/consumables`;
- Writing/ink summary → `station/scriptorium` and `station/writing-desk`;
- current systems without a dedicated route, including Reforging, Survey instrument grades, Waiting and
  prepared ink colours, remain anchored subsections on their owning existing page.

Do not emit a dead link for conceptual brackets such as [Damage Kinds] or [World Pressures]. Until a
dedicated semantic route exists, resolve them to the closest current top-level page (`combat`,
`world-writing`, `exploration` or `resources-crafting`) and keep the visible link label.

## Statements withheld because runtime or route authority is incomplete

| Statement | Why it cannot publish as current truth | Revisit owner |
|---|---|---|
| Rubble builds the Reliquary or another foundation | proposal only; current scalar Rubble has no such consumer | station-cost content after Aimee choice |
| Chaining spends one Mote | `research.json` declares it in a Base resource cost, but that transaction cannot own Reality Motes | typed research currency correction |
| Node/flora harvest produces exact physical material units | current extraction commit awards scalar primary/secondary counts; newer reserve prose is not the production transaction | extraction/material custody owner |
| Trading can order a discovered rare resource | proposed contract does not exist | Trading quote/stock owner |
| Physical Field Pick is the canonical Extraction unlock | recipe definition is dormant; current equipped tool authority is separate | extraction/tool progression decision |
| Late buildings require Mercury, Rift-glass or Adamant | proposed signature substitutions are not in station data | station content after Aimee choice |
| Revised Briar Oil, Flashsalt, Lure, Draught, Seamlight or Farsight ingredients/forms | current recipes still use the implemented inputs in this manifest | Apothecary content decision |
| Scalar resources convert into exact materials | no named conversion transaction exists | unresolved custody decision |
| Heat Conduit Fixture is an equippable weapon | current result is stored treasure-like custody only | future Channelworks consumer |
| Caustic/Light Cores provide playable effects | no downstream housing/effect exists | future Channelworks consumer |
| Infuse is available | held design only | future named trade-off/consumer |
| Lantern crafting or automatic illumination exists | Lantern runtime/acquisition remains separate and unresolved | Lantern owners, outside this packet |

## Generator integration boundary

Smallest future wiki-only slice:

1. Add the two source paths to the generator's exact closed inputs and provenance hashes.
2. Parse only headings/tables named in this manifest, or encode a reviewed mapping alongside the generator;
   never ingest arbitrary prose from proposal documents.
3. Extend resource records with current recipe/research/service uses from the approved source map while
   retaining catalogue-driven names, acquisition conditions, trade bands and construction uses.
4. Extend station/item route bodies with the mapped source sections; do not change runtime catalogue data.
5. Add deterministic source freshness, 23-resource exact coverage, route-existence, hidden-disclosure and
   forbidden-proposal tests.
6. Regenerate only GameWiki generated data/manifest and verify the wiki-only boundary.

## Publication gates

- Exactly 23 source resource headings map one-to-one to the 23 existing `resource/*` routes.
- Every mapped station and item route exists in the generated route list.
- No stable ID, source path, source hash or internal readiness enum renders in player-visible copy.
- Search and summaries reveal no resource, recipe, station or item earlier than its existing disclosure.
- All current ingredient counts, property floors, Essence/Mote costs and output roles match runtime source.
- Unsupported statements above are absent from route bodies, alt text, search and cross-link summaries.
- Physical family copy never aliases to catalogue fallback items.
- Regeneration is deterministic and modifies no runtime, project, schema or asset file.
