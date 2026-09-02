# Resource, Crafting, Creature, and World Implementation Roadmap V1

Status: ordered Game Design roadmap. This roadmap does not dispatch Engineering and does not authorize unresolved mechanics.

## Delivery principle

This program is larger than a recipe correction. It changes generation, loot, inventory, crafting, equipment, World Writing, saves, and the public Wiki. Work may be developed behind internal boundaries, but no player build may expose a half-migrated economy in which one producer writes new material stacks while another current consumer still expects legacy samples.

Every phase has four states:

1. **Design closed** - Aimee has accepted its player behavior and vocabulary.
2. **Source complete** - every named producer, consumer, save owner, and presentation path uses the new contract.
3. **Focused verified** - deterministic generation, atomic transactions, migration, and refusals pass.
4. **Mounted verified** - Game Design plays the real fixed 368x800/default-text journey through production controls.

The public Player Wiki updates at each delivered state, not only when the entire program ends.

## Phase 0 - Close the remaining design choices

### Decisions to settle with Aimee

1. Final physical material category/type/subtype registry.
2. Rubble removal versus world-causal processing.
3. Ground and liquid type catalogue.
4. Ground layout style set.
5. World size tiers and dimensions.
6. Creature body-plan and habitat grammar.
7. Terrain/flora compatibility matrix.
8. Pick, Axe, and Scythe tiers and starting tool route.
9. Processed-material list and facility ownership.
10. Facility upgrade depth and recipe-tier progression.
11. Exact category eligibility for every recipe.
12. Material-to-stat contribution table.
13. Multi-input crafted-quality formula.
14. Peerless alpha/crafting chance and matching-NPC staffing effect.
15. Direct World Writing resource vocabulary and guarantee strength.
16. Weather/atmosphere compatibility and transformation matrix.
17. Colour inheritance, selection, and crafted appearance behavior.

### Deliverables

- One stable material registry draft.
- One complete current recipe-to-future ingredient matrix.
- One current resource producer/consumer matrix.
- One world-condition compatibility matrix.
- One creature body-plan/habitat/material-yield matrix.
- One facility/process/upgrade matrix.
- One stat contribution and quality calculation proposal.

### Exit gate

No structural implementation starts until all decisions needed by its first vertical slice are closed. Decisions for unrelated later slices may remain marked **Will discuss with Aimee**.

## Phase 1 - Add versioned registries without changing gameplay

### Build

- Stable IDs for material broad categories, physical types, precise subtypes, and four resource quality bands.
- Stable IDs for body plans, habitat access, ground/liquid types, layout styles, tool classes/tiers, processed materials, recipe ingredient scopes, facility tiers, and world sizes.
- Authored eligibility registries rather than ad hoc switch statements.
- Versioned generation and material-receipt envelopes.
- Validation proving every ID, cross-reference, recipe category, producer, consumer, and migration mapping is closed.

### Preserve

- Current saves and live behavior remain unchanged.
- Old IDs continue decoding.
- No new registry is yet advertised as playable.

### Exit gate

- Registry validation covers every existing resource, material sample, recipe, facility, creature yield, terrain type, Return line, Trading line, and Recycler result.
- No orphan type or one-consumer rare ordinary material remains unexplained.

## Phase 2 - Prototype world regions and causal resource hosting

### Build behind a new generation version

- Ground-layout style selection separated from physical composition.
- Granular ground and liquid region types.
- Region receipts that own material composition and eligible resource hosts.
- Deterministic node clustering derived from the region rather than global random scattering.
- Versioned world dimensions and minimap transform.
- Compatibility with current entry, portal, site, encounter, and reachability placement.

### Do not yet change

- Existing/anchored world maps.
- Current public World Writing promises.
- Live resource custody or recipes.

### Focused gates

- Same seed and receipt reproduce identical regions, nodes, and dimensions across relaunch.
- Old world versions reproduce their old map exactly.
- Every entry and required route remains reachable.
- Large maps scroll the minimap; small maps center without changing fixed UI size.
- Granite and other granular regions host only compatible nodes.

### Mounted gate

Use development-only authored worlds to inspect each accepted layout style and size. This does not make those options player-reachable yet.

## Phase 3 - Rebuild creature generation and ecological placement

### Build behind the same versioned world receipt

- Body plan and habitat access.
- Continuous traits inside valid body-plan ranges.
- Player-readable species identity.
- World-derived colour.
- Terrain, water, flora, weather, and atmosphere compatibility.
- Material type/subtype projection from generated anatomy.
- Stable generated species and encounter identity.

### Focused gates

- Representative seeds produce aquatic, terrestrial, amphibious, flying, fish-like, bird-like, lion-like, crocodile-like, and accepted hybrid forms.
- Creatures never spawn outside legal habitat.
- Encounter and Bestiary copy reveal a readable kind without leaking undiscovered details.
- Colour and anatomy reproduce on relaunch.
- Material projections are physically consistent and deterministic.

### Mounted gate

Encounter and inspect one naturally generated member of each accepted body-plan/habitat family. Verify map placement, name, appearance, Bestiary identity, combat behavior, and disclosed material potential.

## Phase 4 - Add tool-gated harvesting and trees

### Build

- Rock Pick/basic Pick, Axe, and Scythe ownership routes accepted in Phase 0.
- Tool-tier requirements on resource nodes, tree trunks, ordinary plants, and dangerous harvestable flora.
- Tree canopy/trunk placement and under-canopy presentation.
- Exact harvested type/subtype, quality, colour/source, quantity, depletion, and custody receipt.
- Truthful blocked copy that names the required tool tier.

### Preserve

- Advanced resources may still generate before they are harvestable.
- Ordinary flora remains safe.
- Dangerous flora contact/poison identity remains explicit.
- Sites, portals, enemies, and other foreground owners cannot be hidden or overwritten by canopies.

### Focused gates

- Ineligible tools do not consume turns or nodes unless the accepted rule explicitly charges an attempt.
- A committed harvest adds the exact yield once and depletes the exact placement once.
- Stale node, moved player, changed tool, full/invalid custody, replay, and write failure are inert.
- Relaunch preserves live and depleted placements.

### Mounted gate

Play a progression from basic gathering through at least one blocked advanced node, acquire the required tool, revisit, harvest, return, and cold relaunch.

## Phase 5 - Global material custody migration

### Build as one cumulative cutover

- New physical type/subtype + four-band material stack authority.
- Source-species/world/colour sub-lot history under each stack.
- Field and combat reward writers.
- Carried inventory presentation.
- Partial and full Expedition Return.
- Storehouse.
- Trading Post buy/sell stock and pricing.
- Every current crafting picker and quote.
- Equipment construction receipts.
- Recycler.
- Active and anchored worlds.
- Old-save and legacy reserve migration.

### Migration rules

- Preserve every unit count, quality, source, colour, ownership location, pending Return line, trade line, selected quote, and equipment receipt.
- Map old grades to Poor/Common/Rare/Exceptional through one published deterministic table.
- Never invent species provenance.
- Preserve materially distinct old samples as distinct types/subtypes when the new registry requires it.
- Combine only samples that share the new stack key.
- Migration is idempotent and fail-closed.
- Old and anchored world generation receipts remain on their original version.

### Focused gates

- Before/after quantity census by custody owner and stack key.
- Multi-species same-stack aggregation with expandable source detail.
- Distinct physical subtype and quality remain separate.
- Partial Return proves recovered plus lost equals carried.
- Trade, craft, recycle, and relaunch cannot duplicate or delete stock.
- Materials never consume item slots.

### Mounted gate

Collect several species variants and qualities, inspect carried detail, partially return, inspect Storehouse, sell and buy, choose a stack in crafting, recycle a receipt-backed item, and cold relaunch.

## Phase 6 - Introduce the processed-material economy

### Build one facility/process family at a time

Recommended first vertical slices after Phase 0 decisions:

1. Ore to Ingot
2. Hide to Leather
3. Fibre to Cord/Cloth
4. Timber to Planks/Hafts
5. Sand or suitable mineral input to Glass
6. Biological/mineral inputs to Prepared Extracts

Each process defines:

- owning facility and required level;
- static inputs and substitute categories;
- explicit player selection;
- quality and colour transfer;
- quantity conversion;
- output custody;
- repeat consumers;
- unlock and Wiki links.

### Focused gates

- Preview names every selected stack and exact output.
- Quality result follows one visible rule.
- Stale/cancelled/failed commits consume nothing.
- Output appears once in the correct stack and remains through relaunch.
- Every promoted intermediate has at least two meaningful current or same-release consumers.

## Phase 7 - Replace the recipe engine and migrate every maker

### Core engine

- Static ingredient lines.
- Broad category lines.
- Specific category lines.
- Precise subtype lines.
- Explicit quantity and player-chosen quality.
- Direct stat contribution preview.
- Atomic exact-stack consumption.
- No hidden property threshold as eligibility.

### System migration order

1. One simple quality-neutral preparation, if Phase 0 identifies one.
2. One stat-bearing weapon with two selected components.
3. One multi-layer protective item.
4. Apothecary preparations and weapon coatings.
5. Tannery.
6. Bowyer.
7. Blacksmith forms and Reforge replacement/refit behavior.
8. Weaponsmith.
9. Armoury.
10. Field Instruments.
11. Distillery.
12. Channelworks.
13. Anchorage.
14. Scriptorium and prepared ink.
15. Cottage construction and Research material costs.
16. Recycler compatibility for every new construction receipt.

This order may change after Phase 0 resolves facility ownership, but every live maker must be included before legacy recipe eligibility is removed.

### Focused gates for each maker

- All live and intended recipes are enumerated.
- Every category has an explicit closed eligibility list.
- The player can deliberately select low or high quality when quality matters.
- Exact preview equals exact committed output.
- Higher quality is never substituted silently.
- Result name, statistics, colour, custody, history, trade and recycle receipt survive relaunch.

## Phase 8 - Crafted quality, statistics, and Peerless gear

### Build

- Material type/subtype and quality contribution tables mapped only to real game statistics.
- Deterministic multi-input result-quality calculation.
- Rough/Fine/Superior/Exceptional crafted names.
- Peerless alpha-drop route.
- If approved, maximum-facility all-high-quality Peerless craft chance and matching-NPC modifier.

### Prohibited

- Durability, brittleness, wear, repair, or breakage.
- Vague material adjectives with no implemented statistic.
- Hidden output rolls not shown by an accepted preview rule, except the explicitly approved Peerless chance.

### Focused gates

- Exact selected inputs produce exact previewed ordinary statistics.
- Each quality band raises the intended contribution.
- Peerless never exists as raw material.
- Peerless production cannot be save-scummed through an unfrozen random result.
- Staffing affects chance only if Aimee approves it and the exact staffed state is durably owned.

## Phase 9 - World Writing targeting and world size

### Build

- Ground and liquid declaration vocabulary.
- Direct base-resource vocabulary.
- Ecological material pressure such as Chitin.
- World-size vocabulary.
- Rune acquisition, Dictionary disclosure, Page grammar, preview, Binding, frozen receipt, generation and World History support.

### Rules

- Written facts have a strong, truthful effect.
- Unwritten facts remain generated.
- Direct base-resource targeting provides the accepted guarantee strength.
- Ecological material targeting pressures anatomy/habitat without forcing one named species.
- Tool requirements still govern harvesting.
- Existing campaigns and Pages remain valid.

### Focused gates

- Every new Sigil changes only its authored target.
- Same Page and seed produce the same world.
- A targeted ground/resource appears according to the accepted direct-call rule.
- A Chitin request measurably changes eligible creature populations without eliminating unrelated ecology.
- World preview and World History describe only disclosed facts.

### Mounted gate

Write and play at least one direct ground/resource request, one ecological material request, and each world-size tier. Verify intended influence, surprises in unwritten facets, harvesting access, Return and relaunch.

## Phase 10 - Environmental compatibility and visible atmosphere

### Build

- Deterministic weather/atmosphere compatibility and transformation pass.
- Saved resolved condition identity.
- Mechanics, World Splash facts, exploration copy, map effects, animation/haze/particles, audio if authored, and history from the same receipt.

### Focused gates

- Rain and snow do not coexist when temperature makes that impossible.
- Rain plus miasma becomes acid rain only under the accepted rule.
- Ash and snow coexist only under an accepted physically coherent combination.
- Relaunch preserves the same resolved condition and animation state.
- Hidden conditions are not disclosed early.

### Mounted gate

Play every accepted base and transformed condition at 368x800/default text. Verify visibility, action truth, hazards, harvesting, and persistence.

## Phase 11 - Remove legacy owners

Remove legacy paths only after the complete reader/writer census proves they have no current caller:

- per-sample recipe eligibility;
- hidden numerical recipe thresholds;
- old quality vocabulary;
- old species-fragmenting display identity;
- scalar/material duplicate custody;
- obsolete loot projection;
- old fixed-size-only generation assumptions;
- Rubble as a finished resource if Aimee removes it;
- compatibility adapters that have completed migration.

Old-save decoding remains as long as supported saves require it.

## Phase 12 - Full player journey and publication

### Mounted journey

1. Start or load a compatible campaign.
2. Write a world that targets a ground/resource and an ecological material pressure.
3. Enter a correctly sized generated world.
4. Inspect granular ground, water, flora, tree canopy, weather, and creatures.
5. Encounter an unharvestable advanced node without losing it.
6. Harvest accessible world, flora, tree, and creature materials.
7. Return with a deterministic partial and full-haul example.
8. Inspect physical type/subtype + quality stacks and their source/colour details.
9. Process raw materials.
10. Select low-quality inputs for one craft and high-quality inputs for another.
11. Confirm previewed statistics and crafted names.
12. Sell/buy eligible stock.
13. Recycle a receipt-backed item.
14. Upgrade a tool or facility and revisit a previously inaccessible material.
15. Cold relaunch and verify world, stock, equipment, facilities, receipts, and knowledge.

### Public Wiki promotion gate

- Every page clearly distinguishes Implemented now, Intended design, and Will discuss with Aimee.
- Every delivered current recipe exactly matches the runtime.
- Every future recipe remains visibly future until implemented.
- Every material links to acquisition, processing, recipes, equipment, storage, trade, Return, recycling, relevant terrain/flora/creatures, and World Writing.
- No internal IDs or hidden numerical property requirements appear as player instructions.
- The References for Aimee section remains available.

## Recommended delivery grouping

The safest program groups are:

1. **Design and registries** - no gameplay mutation.
2. **Versioned generation foundation** - new worlds only, old worlds frozen.
3. **Harvest and global custody cutover** - all material producers/consumers together.
4. **Processing and recipe-engine cutover** - compatibility until every maker migrates.
5. **Crafted statistics and Peerless** - after deterministic ordinary output is stable.
6. **World Writing targeting** - after the new generator and resources can honor it.
7. **Atmosphere and compatibility** - one resolved environment receipt.
8. **Legacy removal and end-to-end promotion**.

No phone delivery should strand a player between old and new material identities, invalidate an existing world, or make a live recipe impossible.
