# Resource, Crafting, Creature, and World Overhaul Structure V1

Status: implementation-planning authority derived from Aimee's Top Level Notes.

This document separates current runtime foundations from the intended system. It is not an Engineering dispatch. It authorizes bounded, compatible vertical slices, not incoherent partial mechanics. Every **Will discuss with Aimee** section is deliberately unresolved.

## Scope

The overhaul has ten connected owners:

1. Material identity and inventory
2. Creature generation and creature loot
3. Ground, liquid, and world layout generation
4. Flora, trees, and ecological placement
5. Resource placement and harvesting tools
6. Processing facilities and intermediate materials
7. Recipe definitions and ingredient selection
8. Crafted equipment statistics and quality
9. World Writing and direct resource targeting
10. Weather, atmosphere, environmental compatibility, and presentation

The Player Wiki is an eleventh cross-system publication owner. It changes with every promoted slice.

## 1. Material identity and inventory

### Implemented now

- World resources and generated material samples use more than one custody model.
- Generated material samples can retain exact source, qualifier, grade, and continuous properties.
- Some screens summarize by family while recipes and durable storage still operate on exact units.
- Current quality vocabulary and display names do not match Aimee's four resource bands.

### Intended structure

- Separate physical hierarchy: broad category, specific type, optional precise subtype, quality, then species-specific item/unit.
- Default-stack by precise subtype plus Poor/Common/Rare/Exceptional.
- Provide alternate sorting and views by category, type, subtype, quality, species, source world, colour, quantity, or recency without changing custody.
- Expand a stack to inspect source species, world, inherited colour, quantities, and stat contributions.
- Preserve source identity without making every species a separate item type.
- Materials remain outside ordinary item-slot capacity.
- Every transaction freezes exact stack, selected contributing units where needed, quantity, source and destination.

### Structural change

The final model spans Field holdings, Return, Storehouse, Trading Post, crafting pickers, equipment receipts, Recycler, active worlds, anchored worlds, pending transactions, and old reserves. Delivery is incremental: each promoted owner moves through a read-old/write-new compatibility bridge, while untouched owners keep their current representation until their own coherent slice ships.

### Will discuss with Aimee

- Final physical type and subtype registry.
- Whether inherited colour selection consumes named sub-lots or another deterministic quantity receipt.
- Player-facing expanded-history depth before a source species has been discovered.
- Whether any quality-neutral physical recipe exists.

## 2. Creature generation and loot

### Implemented now

- World pressures shape a continuous creature trait budget.
- Appendage, covering, armament, size, colour, and other traits already influence generated creatures.
- Runtime presentation can reduce broad movement identity to fish-like, bird-like, or land icons, while generated names describe traits.
- Loot projection derives several physical materials from anatomy, but older and newer reward paths coexist in source history.

### Intended structure

- Generate a readable body-plan family before or alongside continuous traits.
- Support aquatic, terrestrial, amphibious/shallow-water, flying/broadly traversing, and later explicitly authored habitat classes.
- Support recognizable ranges including fish-like, bird-like, lion-like, crocodile-like, and hybrids without hardcoding those real animals as the only possibilities.
- Compose a generated species identity players can understand in encounters and the Bestiary.
- Generate world-derived colour and carry it into physical loot.
- Derive specific material types and precise subtypes from anatomy: Fish Scales, Armoured Fish Scales, Pelt, Hide, Chitin, Shell, Bone, Venom, and other settled families.
- Retain species-specific variation inside stack history and crafted-stat contributions.

### Preserve

- Deterministic seeded generation.
- Pressure-sensitive anatomy.
- Existing combat trait relationships that remain mechanically valid.
- Discovered-species and specimen knowledge boundaries.

### Structural change

Body-plan, habitat, material-yield, naming, Bestiary, encounter disclosure, map placement, colour, reward, and save receipts must share one versioned generated-species receipt.

### Will discuss with Aimee

- Closed body-plan and hybrid grammar.
- Exact habitat matrix and whether flying creatures ignore terrain movement entirely or only placement restrictions.
- Which anatomical differences create a new material subtype rather than a stronger stat roll.
- Colour palettes, inheritance, and crafted appearance rules.
- Species encounter and population frequency.

## 3. World layout, ground, and liquid generation

### Implemented now

- The current generator has deterministic map creation, passability protection, elevation, chasms, water coverage, water dispersion, mud and growth placement.
- Current ground vocabulary is limited to stone, soil, sand, ice, ash, water, deep water, rubble, mud, and growth.
- Ground cells are largely selected from weighted options; water has stronger large-body-versus-scattered placement logic than ordinary ground.
- Current maps use a fixed generated size and current minimap behavior.

### Intended structure

- Separate regional arrangement from material composition.
- Add authored layout styles such as Uniform, Striated, Scattered, Clustered, Graded, and Fractured after Aimee approves final terms.
- Fill layout regions with granular ground and liquid types: multiple dirt, sand, stone, mineral, and liquid identities.
- Let each physical region host matching harvest nodes and ecological opportunities.
- Add written world-size control from slightly below the current map to approximately four times its current area.
- Center small maps in the minimap and scroll the minimap viewport across larger maps.

### Preserve

- Stable seed and frozen receipt behavior.
- Entry reachability and passable-ground guarantees.
- Existing useful water topology work.
- Existing distinctions among ponds, larger standing bodies, flowing water, ice, mud, chasms, and elevation where compatible.

### Structural change

Map receipts need versioned layout style, world dimensions, region identities, physical ground/liquid composition, resource-host facts, and compatibility resolution. Old and anchored worlds must never regenerate into a different map.

### Will discuss with Aimee

- Final layout style set and weights.
- Exact granular ground and liquid catalogue.
- Exact size tiers and map dimensions.
- Travel, encounter density, site count, portal distance, stability, and reward scaling by area.
- Whether regions have hard borders, blended borders, or both depending on style.

## 4. Flora, trees, and ecology

### Implemented now

- Flora generation already reads water, light, temperature, atmospheric, substrate, vitality, and other pressures.
- Growth can alter terrain presentation and cover.
- Dangerous flora has separate placement/contact authority in the current design lineage.
- The current presentation does not yet provide Aimee's complete tree-canopy experience.

### Intended structure

- Exact terrain composition constrains viable flora in addition to light, atmosphere, weather, temperature, water, and vitality.
- Solid stone favours moss, crust, fissure, or specially rooted life; sand, mud, deep water, ice, and other surfaces each have distinct eligibility.
- Ordinary flora remains safe.
- Dangerous flora remains explicitly generated and disclosed rather than inferred from an ordinary species description.
- Trees occupy real canopy and trunk structures.
- Canopy view changes when the player moves beneath it, revealing the trunk and ground below.
- Tree harvesting requires an appropriate Axe tier; small plants use a Scythe tier; difficult or dangerous plants require better tools.

### Structural change

Flora identity, placement, terrain underlay, canopy footprint, disclosure, dangerous-placement profile, harvest output, tool requirement, depletion, persistence, and relaunch must share one stable placed-instance record.

### Will discuss with Aimee

- Tree sizes, canopy geometry, occlusion and reveal animation.
- Whether harvested trees leave stumps, regrow, or remain depleted for the world's life.
- Complete terrain-to-flora compatibility matrix.
- Scythe and Axe tier count and exact eligible plant groups.

## 5. Resources and harvesting tools

### Implemented now

- Ore quantity and several pressure relationships influence world resource placement.
- Many scalar resources can appear through terrain, flora, sites, or rewards.
- Current harvesting does not provide the complete staged Pick/Axe/Scythe access progression Aimee describes.
- Rubble exists as both ground vocabulary and a player-facing resource concept.

### Intended structure

- Place resources causally from exact ground, liquid, flora, creature, site, and environmental receipts.
- Advanced materials may generate before the player can harvest them.
- Harvest attempts truthfully name the required tool class and tier.
- Better Picks unlock roughly two or three additional metal/mineral groups per tier.
- Axes unlock increasingly difficult woods and trunks.
- Scythes unlock increasingly difficult or dangerous flora.
- A starting Rock Pick and basic Axe may be starting, found, or early crafted equipment after Aimee chooses the opening.
- Extracted material receives a physical type/subtype, quality, source, colour where applicable, and quantity exactly once.

### Structural change

World placement, Look, harvesting, tool custody/equipment, depletion, carried materials, Return and persistence need a single candidate-first transaction. No node disappears or yields stock before the durable commit succeeds.

### Will discuss with Aimee

- Metal/mineral progression list and exact Pick tiers.
- Axe and Scythe tiers.
- Starting tool ownership versus early discovery/crafting.
- Node yields, harvest turn costs, tool effects, and whether tools are equipped or persistent capabilities.
- Mixed geological find name, collection frequency, regional output weighting, and processing owner.

## 6. Processing facilities and intermediates

### Implemented now

- Current Cottage facilities craft items, refine Raw Essence, distil Cores, prepare ink, rebuild equipment, and recycle some objects.
- A universal processed-material progression does not yet connect raw ore, hides, fibre, timber, sand, and extracts.

### Intended structure

- Raw materials become a modest set of recognizable, reusable intermediates.
- Examples under consideration include Ingots, Glass, Leather, Cloth, Cord, Planks, and Prepared Extracts.
- Each intermediate has several physically sensible consumers.
- Processing facilities gain upgrade tiers that unlock later material transformations and recipe tiers.
- Processing adds capability, not repetitive busywork.

### Structural change

Each process needs an exact input category, accepted subtypes, quality behavior, output quality, colour/provenance transfer, quantity conversion, facility tier, unlock, quote, atomic commit, custody destination, and Recycler behavior.

### Will discuss with Aimee

- Final intermediate list.
- Which current or new facilities own smelting, glassmaking, tanning, milling, weaving, carpentry, extraction, and sorting.
- Conversion ratios and quality inheritance.
- Facility upgrade count, construction costs, NPC staffing contribution, and campaign unlock order.

## 7. Recipe engine and ingredient selection

### Implemented now

- Current recipes include fixed resource costs, exact-item selections, family allowlists, and hidden continuous-property thresholds.
- Several makers automatically find qualifying samples rather than letting the player choose the quality that serves their goal.

### Intended structure

Each ingredient line uses one of four explicit forms:

1. Exact material
2. Broad physical category
3. Specific physical category
4. Precise subtype

The picker shows all held stacks that satisfy the authored category. Selection displays:

- material type/subtype;
- quality;
- available quantity;
- source/colour detail when relevant;
- direct stat contribution;
- resulting item quality;
- complete cost and output custody.

The player chooses quality wherever quality affects the result. Commit consumes exactly the confirmed selections. Stale stock never causes silent substitution.

### Structural change

Every current recipe needs a versioned ingredient definition. Current property-threshold recipes remain compatibility evidence only and must not survive as the new recipe foundation.

### Will discuss with Aimee

- Exact category hierarchy and substitution lists for every recipe.
- Which recipes are quality-neutral.
- How a picker chooses source-colour sub-lots within one stack.
- Whether a recipe can combine several variants from one stack or requires visually coherent units.

## 8. Equipment statistics and quality

### Implemented now

- Equipment has current combat statistics and some crafted material receipts.
- Generated sample properties can contribute to outputs.
- Existing design language sometimes implies qualities such as brittleness or durability that are not game systems.

### Intended structure

- Only existing or explicitly approved statistics receive material contributions.
- Resource quality directly scales those contributions.
- The preview exposes every contribution and resulting final statistic.
- Crafted equipment names use Rough, Fine, Superior, or Exceptional according to the deterministic result-quality calculation.
- Peerless equipment comes from high-level alpha drops or an approved maximum-facility craft chance, never from Peerless raw resources.
- There is no equipment durability mechanic.

### Structural change

Define one stable stat-contribution table by physical material type/subtype and quality. Preserve existing equipment identity, ownership, equipped state, history, and legal combat form during migration.

### Will discuss with Aimee

- Exact stat contributions for every material and recipe socket.
- Multi-input crafted-quality formula.
- Peerless alpha eligibility, maximum-facility chance, bad-luck protection, and staffing bonus.
- Colour composition for multi-material equipment.

## 9. World Writing and resource targeting

### Implemented now

- Written Sigils resolve pressure targets and unwritten facets are filled deterministically.
- The current system affects broad substrate, water, thermal, light, atmosphere, vitality, and relief behavior.
- The current vocabulary does not provide the complete ground, liquid, size, and material targeting Aimee wants.

### Intended structure

- Directly declare selected base ground, liquid, and resource facts.
- Apply ecological material pressure for emergent flora/fauna outputs such as Chitin.
- Add world-size vocabulary.
- Preserve partially generated worlds: unwritten facets still roll from the frozen seed.
- Show enough truthful preview information for the player to understand what they targeted without guaranteeing unwritten discoveries.

### Structural change

New Sigils require vocabulary acquisition, Rune Dictionary disclosure, Page grammar, pressure resolution, world receipt, preview, generation, World History, and old-page compatibility together.

### Will discuss with Aimee

- Which resources are directly callable.
- Whether direct calls guarantee presence, guarantee one reachable node, or establish a dominant region.
- Sigil grammar for ground, liquid, material category, and world size.
- Ink, Page-space, progression, and unlock costs.
- How ecological requests such as Chitin influence creature generation without forcing one species.

## 10. Weather, atmosphere, and compatibility

### Implemented now

- Weather and atmosphere influence generated systems and descriptions.
- Lighting has visible effects.
- Complete visible rain, snow, ash, miasma, and transformed-combination presentation is not yet implemented.
- Some generated combinations can appear contradictory to the player.

### Intended structure

- Resolve incompatible conditions through a deterministic compatibility layer.
- Never reject an otherwise valid world merely because two raw condition candidates conflict.
- Let relevant pressures, such as temperature, deterministically select rain or snow and retain only the winner in the resolved receipt.
- Transform authorized combinations, such as rain plus miasma becoming acid rain.
- Permit unusual combinations such as ash and snow only when their causes and temperature can coexist.
- Give every resolved condition matching gameplay behavior, arrival disclosure, world presentation, exploration feedback, and persistence.

### Structural change

The resolved environment receipt must own both mechanics and visuals. Rendering may not independently infer a different condition from raw pressures.

### Will discuss with Aimee

- Complete compatibility and transformation matrix.
- Which conditions are mutually exclusive, dominant, layered, or transformed.
- Exact damage/status/visibility/movement/harvest effects.
- Animation, haze, particle, colour, and sound requirements.

## 11. Mixed geological find

Rubble cannot remain a specific final crafting resource.

Aimee prefers a region-causal mixed raw find because it can give the player a bounded grab bag from a zone they could not fully explore or harvest yet.

- Rename it to an intuitive mixed find such as Unsorted Stone or Mineral Debris.
- Its exact source-region receipt freezes which local materials are eligible before the player obtains it.
- A processing facility separates it into only those supported materials.
- It may yield an otherwise inaccessible regional material, but cannot yield anything absent from that region.
- It never rerolls on preview, refusal, relaunch, or repeated inspection.
- It supplements exploration and harvesting tools rather than replacing their dependable yields.

**Will discuss with Aimee:** name, acquisition frequency, output count, regional weighting, quality inheritance, and processing-facility owner.

## 12. Player Wiki publication owner

Every implementation slice updates the public Player Wiki in the same promotion boundary.

Each page must show:

- current live behavior;
- intended behavior;
- implementation status;
- exact ingredients and substitution lists;
- acquisition and processing routes;
- quality and statistic contribution;
- unlock and facility tier;
- known unavailable behavior;
- cross-links to terrain, creatures, flora, equipment, facilities, Return, storage, trade, recycling, and World Writing.

The Wiki cannot be postponed until the end of the overhaul. Aimee uses it to inspect systems she cannot yet reach in play.

## Cross-system non-negotiable invariants

- Generated worlds and species remain deterministic across relaunch.
- Existing and anchored worlds never reroll under a new generator.
- Old saves preserve knowledge, inventory, equipment, qualities, colours, sources, quantities, and receipts losslessly.
- No material is lost, duplicated, silently upgraded, silently downgraded, or silently substituted.
- No higher-quality stack is consumed without explicit player selection when quality matters.
- Recipe categories are authored physical sets, never hidden numerical thresholds.
- Species matter through generated anatomy, colour, source history, and material values without needless species-item fragmentation.
- No durability mechanic is introduced.
- Advanced resources are not suppressed merely because the player's tool is too weak.
- Rare ordinary resources have multiple meaningful consumers.
- Every unsuccessful, stale, cancelled, or failed write is presentation- and inventory-inert.
- Compatible vertical slices may ship independently. Untouched consumers remain on explicit legacy behavior until migrated; no slice may require every building overhaul to finish first.
