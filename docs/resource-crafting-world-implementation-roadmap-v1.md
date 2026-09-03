# Resource, Crafting, Creature, and World Implementation Roadmap V1

Status: ordered Game Design roadmap. This roadmap does not dispatch Engineering and does not authorize unresolved mechanics.

## Delivery principle

This program is larger than a recipe correction. It changes generation, loot, inventory, crafting, equipment, World Writing, saves, and the public Wiki. It will ship as small compatible vertical slices rather than one long all-or-nothing cutover. A slice may move one producer and its immediate custody/consumer path to the new model while untouched buildings continue using explicit legacy compatibility.

Aimee is currently the primary tester and does not need every building overhaul to finish before receiving another update. A partial rollout is acceptable when its current boundary is visible and understood. It is never acceptable for a partial rollout to lose stock, make a save unreadable, substitute quality silently, publish intended behavior as live, or leave a touched transaction split between incompatible identities.

Every phase has four states:

1. **Design closed** - Aimee has accepted its player behavior and vocabulary.
2. **Source complete** - every named producer, consumer, save owner, and presentation path uses the new contract.
3. **Focused verified** - deterministic generation, atomic transactions, migration, and refusals pass.
4. **Mounted verified** - Game Design plays the real fixed 368x800/default-text journey through production controls.

The public Player Wiki updates at each delivered state, not only when the entire program ends. Phase numbers below describe dependency lanes, not mandatory release barriers; a bounded vertical slice may cross several phases and ship as soon as its own path is complete.

## First playable vertical slice

After the minimum registries and compatibility bridge exist, ship one representative path before broad conversion:

1. One canonical physical subtype from one existing producer.
2. One quality band assignment and species-specific unit beneath its default subtype + quality stack.
3. Field acquisition, Expedition Return, and Storehouse custody for that material.
4. One recipe using a static ingredient plus a broad, type, or subtype category slot.
5. Explicit player quality selection if that recipe's result changes with quality.
6. One trade or Recycler round trip where currently reachable.
7. One old-save/current-reserve migration example.
8. Cold relaunch and exact quantity preservation.

That slice is useful proof and may be phone-delivered even though other resources, recipes, and buildings still use the prior model.

## Phase 0 - Close the remaining design choices

### Required design order

Do not finalize Sigil acquisition, traveller land clues, or exact World Writing unlock order before the
material and land model they describe is stable. Close Phase 0 in this order:

1. canonical physical-material registry and the mapping from every current resource/material;
2. category/type/subtype recipe eligibility and concrete stat-contribution rules;
3. final regional land, geology, surface, liquid, deposit, and ecology model;
4. causal terrain/flora/creature/resource host matrices;
5. harvesting and processing progression over that finished physical model;
6. only then World Writing vocabulary, Sigil acquisition order, and clue learnability.

The rewritten traveller clues remain the prose-quality benchmark. Their mechanical conditions are provisional
until step 6 proves the player has learned the terms and can deliberately produce the described land.

### Decisions to settle with Aimee

1. Final physical material category/type/subtype registry.
2. Mixed geological find name, collection frequency, region-weighted outputs, and processing owner.
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

- Stable IDs for material broad categories and physical types/subtypes; four quality bands only for approved quality-bearing biological materials. Mined world resources have one ungraded normal/green state.
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
- Field controls: movement-centre hold for quick-use items, Interact hold for field-tool selection, Interact for eligible underfoot harvesting, and a direction into an adjacent blocking harvest target for the selected tool.
- Tree canopy/trunk placement and under-canopy presentation.
- Exact mined material and quantity, or exact biological type/subtype, quality, colour/source and quantity where that domain supports quality; plus depletion and custody receipt.
- Truthful blocked copy that names the required tool tier.

### Preserve

- Advanced resources may still generate before they are harvestable.
- Ordinary flora remains safe.
- Dangerous flora contact/poison identity remains explicit.
- Canopies may deliberately conceal distant sites, creatures, resources, and undiscovered paths through one saved visibility rule. They cannot overwrite placed identities, erase established knowledge, disagree with Look or the minimap, or cause avoidable contact damage before the required warning.

### Focused gates

- Ineligible tools do not consume turns or nodes unless the accepted rule explicitly charges an attempt.
- Opening either hold menu, changing or cancelling a tool selection, and refusing a wrong-tool or invalid target are zero-turn and mutation-free.
- A committed harvest adds the exact yield once and depletes the exact placement once.
- Stale node, moved player, changed tool, full/invalid custody, replay, and write failure are inert.
- Relaunch preserves live and depleted placements.
- Relaunch preserves canopy concealment, revealed areas, discovered site/portal knowledge, and any visibility change caused by harvesting a tree.

### Mounted gate

Play a progression from basic gathering through at least one blocked advanced node, acquire the required tool, revisit, harvest, return, and cold relaunch.

## Phase 5 - Incremental material custody migration

### Build one retained-owner path at a time

- Exact-name ungraded stacks for mined world resources plus physical type/subtype + four-band stack authority for approved quality-bearing biological materials.
- Source-species/world/colour sub-lot history under each stack.
- A compatibility reader that can project untouched legacy stock into an exact current consumer without rewriting or losing it.
- A new writer only for the producer promoted in the current slice.
- The smallest complete connected path for that producer: carried presentation, partial/full Return, Storehouse, then each promoted trade, crafting, equipment-receipt, or Recycler consumer.
- Idempotent old-save and legacy-reserve migration scoped to the owners in that slice.
- Active and anchored worlds remain on their saved generation versions until a specific world-compatible slice owns their migration.

Suggested custody delivery order:

1. One generated creature material or one terrain material end to end.
2. Field and combat reward writers, one producer family at a time.
3. Carried inventory and Expedition Return for promoted materials.
4. Storehouse default stacks plus alternate views.
5. Trading Post lines for promoted materials.
6. One crafting family at a time.
7. Equipment receipts and Recycler for the corresponding crafted family.
8. Repeat until every legacy producer and consumer has been retired.

### Migration rules

- Preserve every unit count, applicable quality, source, colour, ownership location, pending Return line, trade line, selected quote, and equipment receipt.
- Keep scalar mined holdings ungraded and map them directly to their exact named resource. Map old biological grades to Poor/Common/Rare/Exceptional through one published deterministic table.
- Never invent species provenance.
- Preserve materially distinct old samples as distinct types/subtypes when the new registry requires it.
- Combine only samples that share the new stack key.
- Migration is idempotent and fail-closed.
- Old and anchored world generation receipts remain on their original version.

### Focused gates

- Before/after quantity census by custody owner and stack key.
- Multi-species same-stack aggregation with expandable source detail.
- Distinct physical subtype and quality remain separate for quality-bearing stock; mined stock never gains a quality field or split.
- Partial Return proves recovered plus lost equals carried.
- Trade, craft, recycle, and relaunch cannot duplicate or delete stock.
- Materials never consume item slots.
- A still-legacy building remains usable under its prior rule or truthfully unavailable for that exact route; it never consumes a promoted stack through an unverified projection.

### Mounted gate

Collect several species variants and qualities, inspect carried detail, partially return, inspect Storehouse, sell and buy, choose a stack in crafting, recycle a receipt-backed item, and cold relaunch.

## Phase 6 - Introduce the processed-material economy

### Build one facility/process family at a time

Recommended first vertical slices after Phase 0 decisions:

1. One metal-processing route only if Phase 0 proves that a real recipe needs a distinct processed form
2. Hide to Leather
3. Fibre to Cord/Cloth
4. Timber to Planks/Hafts
5. Sand or suitable mineral input to Glass
6. Biological/mineral inputs to Prepared Extracts

Each process defines:

- owning facility and required level;
- static inputs and substitute categories;
- explicit player selection;
- applicable biological quality and colour transfer; mined inputs remain ungraded;
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

- Material type/subtype contribution tables mapped only to real game statistics, with quality multipliers limited to approved biological inputs and fixed contributions for mined materials.
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
- Each biological quality band raises its intended contribution; Sand, Gold, Granite and other mined materials have no band to raise.
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
8. Inspect simple exact-name mined stacks and physical type/subtype + quality biological stacks with their source/colour details.
9. Process raw materials.
10. Select low-quality and high-quality biological inputs for appropriate crafts, and confirm mined ingredients offer quantity selection without a fabricated quality choice.
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
- The Aimee Reference section remains available.

## Recommended delivery grouping

The safest rolling program groups are:

1. **Design and registries** - no gameplay mutation.
2. **First material vertical slice** - one producer through custody and one useful consumer.
3. **Producer expansion** - creature, terrain, flora, and tree families one coherent path at a time.
4. **Processing and recipes** - one facility family at a time with compatibility for the rest.
5. **Crafted statistics and Peerless** - after deterministic ordinary outputs exist for the affected family.
6. **World generation and Writing targeting** - incremental generation versions; old worlds remain frozen.
7. **Atmosphere resolution** - condition candidates choose or transform from saved pressures without rejecting the world.
8. **Legacy removal** - only after each old caller has been independently replaced.

Phone deliveries may contain both migrated and explicitly legacy systems. No delivery may strand a player inside one touched transaction, invalidate an existing world, corrupt a save, silently change quality, or make an otherwise supported live recipe impossible.
