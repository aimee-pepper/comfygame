# Resource, Crafting, Creature, and World Overhaul Structure V1

Status: implementation-planning authority derived from Aimee's Top Level Notes and reconciled through the first cross-system coherence and play-feel pass.

This document separates current runtime foundations from the intended system. It is not an Engineering dispatch. It authorizes bounded, compatible vertical slices, not incoherent partial mechanics. A subject is reserved for Aimee only when it needs her creative or product preference; ordinary system completion remains Game Design work.

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
- Current quality vocabulary and display names do not match Aimee's four bands for quality-bearing creature materials, while mined world resources and ordinary flora should not have quality at all.

### Intended structure

- Separate physical hierarchy: broad category, specific type, optional precise subtype, then quality and species-specific unit only for creature materials whose generated variation matters.
- Mined world resources and ordinary flora stack by exact material/type and quantity with one normal/green presentation. Quality-bearing creature materials default-stack by precise subtype plus Poor/Common/Rare/Exceptional.
- Provide alternate sorting and views by category, type, subtype, quality, species, source world, colour, quantity, or recency without changing custody.
- Expand a stack to inspect source species, world, inherited colour, quantities, and stat contributions.
- Preserve source identity without making every species a separate item type.
- Materials remain outside ordinary item-slot capacity.
- Every transaction freezes exact stack, selected contributing units where needed, quantity, source and destination.
- The compact stack is selected first. Exact source lots appear only when source measurements, colour, value, or output change; outcome-neutral transactions use deterministic oldest-first allocation without extra bookkeeping.
- A multi-unit socket may combine lots only when one lot is insufficient. The quote lists the lots and uses a quantity-weighted average of the recipe-named source measurement.

### Structural change

The final model spans Field holdings, Return, Storehouse, Trading Post, crafting pickers, equipment receipts, Recycler, active worlds, anchored worlds, pending transactions, and old reserves. Delivery is incremental: each promoted owner moves through a read-old/write-new compatibility bridge, while untouched owners keep their current representation until their own coherent slice ships.

### Still to complete

- Promote only candidate material types with a causal producer, host, tool, custody path, trade and Recycler behavior, and two sensible consumers or one reusable processing role.
- Keep flora-derived materials ungraded by default; a future exception needs a demonstrated recurring choice.
- Discovery-safe history shows no undiscovered species name. Known source lots can be expanded in full.
- Aimee's remaining visual choice is how several selected source colours appear on one finished object.

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

### Later creature-design pass

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
- Add the accepted layout styles Homogeneous, Dominant, Banded, Patchwork, Clustered, Gradient, and Fractured. Homogeneous means every ground socket uses one physical ground composition; Dominant still permits smaller subordinate inclusions.
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

### Settled and still to tune

- The accepted arrangement set and starting weights are Homogeneous, Dominant, Banded, Patchwork, Clustered, Gradient, and Fractured as listed in the tuning authority.
- The accepted size ladder is 12, 15, 18, 26, and 36 tiles across.
- Region borders follow the arrangement: Banded and Fractured may be hard; Gradient blends; the other styles use readable contiguous boundaries rather than one universal border treatment.
- Exact travel, encounter, site, portal, stability, and reward budgets still require an economy/play-time tuning pass.
- Every mandatory route and written guarantee remains in the entry-connected traversal graph.

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
- Dense canopy intentionally limits distant visibility for ground, resources, creatures, sites, and undiscovered passages. Look, movement, map knowledge, and rendering use the same saved visibility state.
- Once a concealed feature is revealed, its appropriate minimap state remains revealed even if canopy later covers it in the main world view again.
- Immediate dangerous contact remains truthfully warned before commitment, while known portals and discovered sites retain their saved identity even when foliage obstructs the local view.
- Tree harvesting requires an appropriate Axe tier; small plants use a Scythe tier; difficult or dangerous plants require better tools.

### Structural change

Flora identity, placement, terrain underlay, canopy footprint, disclosure, dangerous-placement profile, harvest output, tool requirement, depletion, persistence, and relaunch must share one stable placed-instance record.

### Settled and still to design

- Small, mature, and large crown footprints, the two-consecutive-canopy sight rule, saved reveal, and saved multi-hit felling are settled in the tuning authority.
- The opening Scythe/Axe tiers, eligible size groups, yields, and turn costs are settled there as well.
- Stumps, regrowth, complete flora families, and the terrain-to-flora compatibility matrix remain in the later flora-life-cycle pass.

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
- The opening expedition kit contains an exact owned Rock Pick, basic Axe, and basic Scythe in a dedicated three-place tool roll. One Pick, one Axe, and one Scythe fit without consuming ordinary item or Field Kit capacity; a higher tier replaces the lower tier in its class. Only tools packed with the active expedition party appear in the field-tool selector.
- A mined or ordinary flora yield receives its exact material identity and quantity once, with no quality roll. A quality-bearing creature yield additionally receives type/subtype, quality, source and colour where applicable.
- Holding the movement-pad centre opens quick-use/Field Kit items; holding Interact selects a field tool. Interact applies the selected tool to an eligible underfoot feature, while a direction into an adjacent blocking feature applies it there. Menu, selection, cancel, wrong-tool, and ineligible-target paths are zero-turn; only a committed harvest changes time, node state, or custody.

### Structural change

World placement, Look, harvesting, tool custody/equipment, depletion, carried materials, Return and persistence need a single candidate-first transaction. No node disappears or yields stock before the durable commit succeeds.

### Settled first pass

- Three tool levels, starting material groups, node yields, harvest turn costs, 0.40-second holds, and saved active preference are settled in the tuning authority.
- The preference activates only when the exact tool is packed; it never becomes an invisible global capability.
- A traveller, site, portal, authored hazard, or encounter takes precedence over harvesting on the same target.
- Rubble is the retained mixed find and Noll's Recycler owns its accepted level-1 sorting rule.
- Upgrade recipes and their campaign unlocks still belong to the exact recipe/facility pass.

## 6. Processing facilities and intermediates

### Implemented now

- Current Cottage facilities craft items, refine Raw Essence, distil Cores, prepare ink, rebuild equipment, and recycle some objects.
- A coherent processed-material progression does not yet connect raw ore, hides, fibre, timber, sand, and extracts across their specialist facilities.

### Intended structure

- Raw materials become a modest set of recognizable, reusable intermediates.
- The accepted first set is a named metal Ingot only where a real recipe needs smelted metal, plus Glass, Leather, Cord, Cloth, Planks, Hafts where a recipe uses them, Pulp, Paper, named prepared extracts, writing pigments/ink, and later Dressed Stone where it has real consumers. An Ingot is not a mandatory extra step for every metal recipe.
- Each intermediate has several physically sensible consumers.
- Processing facilities gain upgrade tiers that unlock later material transformations and recipe tiers.
- Processing adds capability, not repetitive busywork.

Accepted ownership is:

- Noll's Recycler sorts region-backed Rubble;
- Halloway's Blacksmith performs named-metal furnace work and ordinary Glass making;
- Corrin's Tannery makes Leather, Cord, and Cloth;
- Fen's Bowyer shapes Logs into Planks and recipe-specific Hafts;
- Isolde's Scriptorium makes Pulp, Paper, writing pigments, and prepared ink;
- Nessa's Apothecary makes physically named plant and creature extracts; and
- Grimmond's Deep Works dresses named stone only for later recipes that genuinely require it.

Auber's Distillery retains Essence/Core distillation rather than absorbing ordinary extracts. Sela's
Wayfarer's Table remains a field workspace. Bracken's Armoury and Maud's Weaponsmith consume appropriate
stock but do not duplicate its general production. No process returns to the standalone Workshop.

### Structural change

Each process needs an exact input category, accepted subtypes, applicable quality behavior, colour/provenance transfer where relevant, quantity conversion, facility tier, unlock, quote, atomic commit, custody destination, and Recycler behavior. A mined input does not acquire quality merely because it is processed.

Every process declares one of three quality behaviors: preserve one selected creature-material band, standardize as ungraded processed stock, or use a named recipe-defined output. Leather preserves one Hide/Skin band. Glass, named metal Ingots, Planks, Hafts, Pulp, Paper, Cord, Cloth, pigments, and writing ink are ungraded. Named extracts use their own authored potency. Quality is never multiplied during processing and again in the final item.

An ordinary finished recipe uses at most one mandatory processing step. A second step is reserved for an exceptional or capstone item. Opening foundations may use raw Logs, named stone, and plant fibre so a late specialist never becomes an early prerequisite.

### Still to author

- Validate the settled first-pass conversion ratios and price classes against each process's first two recurring consumers; author only justified recipe-specific exceptions.
- Facility upgrade count, construction costs, staffing contribution, and campaign unlock order.

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

The picker shows all known held stacks that satisfy the authored category. Selection displays:

- material type/subtype;
- quality;
- available quantity;
- source/colour detail when relevant;
- direct stat contribution;
- resulting item quality;
- complete cost and output custody.

Source-lot detail appears only when it changes a visible result. The quote freezes exact units and uses the same selection for trade, processing, crafting, recycling, and persistence. Undiscovered species and subtypes are never listed merely to make an eligibility table look complete.

The player chooses quality wherever quality affects the result. Commit consumes exactly the confirmed selections. Stale stock never causes silent substitution.

### Structural change

Every current recipe needs a versioned ingredient definition. Current property-threshold recipes remain compatibility evidence only and must not survive as the new recipe foundation.

### Still to author

- Exact category and substitution lists for every recipe.
- Which recipes are quality-neutral.
- Recipe-specific identity-bearing quality sockets; an ungraded designated socket uses the fixed Fine rank-1 workmanship baseline.
- Aimee's remaining colour-composition choice for recipes using more than one visible source colour.

## 8. Equipment statistics and quality

### Implemented now

- Equipment has current combat statistics and some crafted material receipts.
- Generated sample properties can contribute to outputs.
- Existing design language sometimes implies qualities such as brittleness or durability that are not game systems.

### Intended structure

- Only existing or explicitly approved statistics receive material contributions.
- Quality scales contributions only for approved quality-bearing creature inputs. Mined and ordinary flora materials use fixed authored contributions by exact material identity.
- The preview exposes every contribution and resulting final statistic.
- Crafted equipment names use Rough, Fine, Superior, or Exceptional according to the deterministic result-quality calculation.
- Peerless equipment comes from high-level alpha drops or an approved maximum-facility craft chance, never from Peerless raw resources.
- There is no equipment durability mechanic.
- Continuous component values are summed before one final rounding. Discrete values that cannot express four meaningful bands do not receive a fake quality scale; quality improves primary Power/protection instead.

### Structural change

Define one stable stat-contribution table by physical material type/subtype, with a quality multiplier only for approved quality-bearing inputs. Preserve existing equipment identity, ownership, equipped state, history, and legal combat form during migration.

### Settled rule and remaining content work

- The baseline-plus-source contribution formula, role ceilings, and 70/30 identity-socket result rule are in the tuning authority. Each material/recipe socket still needs its content row and a combat-balance check.
- Peerless crafting uses the accepted maximum-facility chance, staffing bonus, and twentieth eligible craft protection, scoped to one schematic at one facility with visible progress. It is never a progression gate.
- Alpha eligibility and multi-material colour composition remain later content/visual decisions.

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

### Settled guarantee and remaining content work

- Ground declarations create a meaningful entry-connected region; liquid declarations create an observable connected body or shoreline; base resources create one start-connected source; ecological materials bias habitat and anatomy without naming a species or guaranteeing a drop. A base-resource source uses the settled first-pass cluster size: two common nodes, two uncommon nodes, one rare node, or one hand-gathering placement.
- The pre-Bind quote distinguishes guarantees from pressures and names known tool requirements.
- The callable registry, Sigil grammar, Page space, ink costs, acquisition order, and exact Chitin-pressure strength remain the later land/material and Sigil content passes.

## 10. Weather, atmosphere, and compatibility

### Implemented now

- Weather and atmosphere influence generated systems and descriptions.
- Lighting has visible effects.
- Complete visible rain, snow, ash, miasma, and transformed-combination presentation is not yet implemented.
- Some generated combinations can appear contradictory to the player.

### Intended structure

- Resolve incompatible conditions through a deterministic compatibility layer: approved transformation first, then greater total resolved support, then a stable frozen-receipt hash for an exact tie.
- Never reject an otherwise valid world merely because two raw condition candidates conflict.
- When two direct written guarantees cannot coexist, disclose before Binding which one becomes the resolved guarantee and which remains an influence. Never silently promise both.
- Let relevant pressures, such as temperature, deterministically select rain or snow and retain only the winner in the resolved receipt.
- Transform authorized combinations, such as rain plus miasma becoming acid rain.
- Permit unusual combinations such as ash and snow only when their causes and temperature can coexist.
- Give every resolved condition matching gameplay behavior, arrival disclosure, world presentation, exploration feedback, and persistence.

### Structural change

The resolved environment receipt must own both mechanics and visuals. Rendering may not independently infer a different condition from raw pressures.

### Later environment-design pass

- Complete compatibility and transformation matrix.
- Which conditions are mutually exclusive, dominant, layered, or transformed.
- Exact damage/status/visibility/movement/harvest effects.
- Animation, haze, particle, colour, and sound requirements.

## 11. Rubble sorting

Rubble remains a simple, ungraded raw-resource name, but cannot remain a universal finished crafting material.
It is a region-causal mixed find that gives the player a bounded grab bag from a zone they could not fully
explore or harvest yet.

- Its exact source-region receipt freezes which local materials are eligible before the player obtains it.
- Visible Rubble stacks by name and quantity while its underlying batches retain those source receipts.
- Noll's Recycler separates a selected quantity into only those supported materials, in a flow distinct from
  dismantling gear.
- Common local materials dominate. Uncommon results are less frequent, and a genuinely rare local material is
  only a low-chance bonus rather than a replacement for the ordinary return.
- It may yield an otherwise inaccessible regional material, but cannot yield anything absent from that region.
- The preview is frozen for the selected units and commits atomically; preview, cancellation, refusal, and
  relaunch cannot reroll it.
- It supplements exploration and harvesting tools rather than replacing their dependable yields.

The accepted rule allows 2, 4, or 6 Rubble from one source-region batch. Every two units produce one base result; the first is common and later results are 75% common/25% uncommon. Sorting at least four units has one 5% chance for an additional rare local result. It is available at Recycler level 1 and costs no Essence or world turn. The selected source-world batch and every result are frozen in the preview. Rubble and every mined output remain ungraded.

## 12. Migration and producer closure

Ambiguous legacy stock cannot be renamed into a physical material by guesswork. Exact receipts migrate exactly; ambiguous holdings remain visible Legacy stacks with their old quantity and value. Existing creature bands map Rough→Poor, Standard→Common, Fine/Superior→Rare, and Exceptional/Peerless→Exceptional when no exact source permits recalculation. World/flora quality does not survive as recipe power, but its old value remains on the legacy source receipt. Compatible old recipes may consume ambiguous stock, the Trading Post may buy it at its preserved value, and the Recycler may offer a conservative previewed exchange once no legacy consumer remains. Legacy stock never satisfies a new physical category by inference.

Before any old type is removed, the producer census covers nodes, ambient gathering placements, flora, creatures, sites, caches, merchant lots, Recycler/salvage output, anchored production, authored rewards, pending Returns, equipment receipts, and old reserves. Every promoted material has a host, tool, custody path, price, processing rule, Recycler rule, and two sensible consumers or one widely reused processing role.

## 13. Player Wiki publication owner

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
- Old saves preserve knowledge, inventory, equipment, colours, sources, quantities, and receipts. A retired material band is recorded and deterministically mapped or retained as legacy value; it is never silently discarded.
- No material is lost, duplicated, silently upgraded, silently downgraded, or silently substituted.
- No higher-quality stack is consumed without explicit player selection when quality matters.
- Raw-material trade uses the first-pass two-to-one buy/sell spread and visible class/quality values from the tuning authority; source species and colour never create a hidden price modifier.
- An ordinary buy → process/craft → sell loop always returns less Gold than the purchased inputs cost; only a clearly authored commission may override that rule.
- Early, middle, and late facility costs are checked against the first-pass targeted-expedition limits before their material slice ships.
- Recipe categories are authored physical sets, never hidden numerical thresholds.
- Species matter through generated anatomy, colour, source history, and material values without needless species-item fragmentation.
- No durability mechanic is introduced.
- Look may reveal a resource before its tool is unlocked; the refusal names the required tool and leaves the source unchanged.
- Rare ordinary resources have multiple meaningful consumers.
- Every unsuccessful, stale, cancelled, or failed write is presentation- and inventory-inert.
- Compatible vertical slices may ship independently. Untouched consumers remain on explicit legacy behavior until migrated; no slice may require every building overhaul to finish first.
