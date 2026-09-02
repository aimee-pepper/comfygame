# Resource, Crafting, World, and Ecology Plan V1

Status: Game Design direction from Aimee's Top Level Notes, organized for system design and future Player Wiki publication.

This document describes the intended game. It does not claim these systems are already implemented. The public Wiki must always distinguish **Implemented now** from **Intended design** until each part is delivered and verified.

## The player loop

Bookbinder's resource game should form one understandable cycle:

1. Decide what the Cottage, party, or next piece of equipment needs.
2. Look up which physical materials and processed goods can satisfy that recipe.
3. Write a world that directly calls useful terrain, ground, liquid, material, or ecological pressures.
4. Enter a generated world whose unwritten features remain surprising, but whose written requests matter.
5. Recognize useful regions, creatures, plants, trees, and resource nodes.
6. Use the right harvesting equipment to collect what the world already contains.
7. Return with the surviving haul.
8. Process raw resources at appropriate Cottage facilities.
9. Choose exact materials and qualities for a recipe.
10. Craft a result whose statistics and appearance clearly reflect those choices.
11. Improve harvesting tools, facilities, and recipe tiers so more of future worlds becomes usable.

Progression does not make advanced materials stop existing. It improves the player's ability to find deliberately, harvest, process, and use what generated worlds can already contain.

## Resource identity

### Physical materials remain meaningfully distinct

Creature and world materials must use recognizable physical names. Species-specific rewards matter, but species names do not create dozens of redundant inventory items.

The intended hierarchy is:

1. **Broad category** - a physical class used by flexible recipes, such as Scales.
2. **Specific material type** - a recognizable physical kind, such as Fish Scales.
3. **Precise subtype** - a materially different version required by advanced recipes, such as Armoured Fish Scales.
4. **Quality** - Poor, Common, Rare, or Exceptional, which creates a separate default stack within the subtype.
5. **Species-specific item** - the generated species unit inside that quality stack, retaining its inherited colour, values, source, and history.

Example:

- **Scales** is a broad recipe category.
- **Fish Scales** and **Lizard Scales** are specific material types.
- **Armoured Fish Scales** is a precise subtype.
- Scales from two different generated fish species share one Armoured Fish Scales stack by default when their quality matches.
- Expanding that stack shows the contributing species, source worlds, colours, quantities, and inherited values.

This retains the connection between world pressures, generated species, and useful loot without forcing players to manage one item type per species.

### Colour is inherited

Generated creatures should derive visible colour from the world. Their physical drops retain that colour information. When a coloured material is used in clothing or another visibly material-led object, its colour can contribute to the crafted result.

Colour is provenance and appearance data, not a reason to create another inventory stack. An expanded stack can show how many units of each inherited colour or species variant it contains. A recipe that cares about visible colour lets the player choose the contributing units deliberately.

Exact colour blending and multi-material appearance rules remain **Will discuss with Aimee**.

## Quality and inventory stacks

### Resource qualities

Resources use exactly four quality bands:

| Resource quality | Colour | Inventory behavior |
|---|---|---|
| Poor | White | Separate stack within the physical material type |
| Common | Green | Separate stack within the physical material type |
| Rare | Blue | Separate stack within the physical material type |
| Exceptional | Purple | Separate stack within the physical material type |

Peerless is not a resource quality.

### Stack key

The default player-facing material stack key is:

> Precise material subtype + resource quality

Examples:

- Common Fish Scales x8
- Rare Armoured Fish Scales x3
- Poor Granite x12
- Exceptional Red Fibre x2, if Red Fibre is ultimately approved as a distinct physical material rather than only a colour variant

Expanded detail shows:

- broad recipe categories the stack satisfies;
- species or world sources;
- inherited colours;
- exact quantities contributed by each source variant;
- the visible statistics the selected units would contribute to a craft;
- discovery history where disclosure is allowed.

The source species does not split the default stack. A materially different subtype or quality does.

### Inventory views and sorting

The player should not be locked to one presentation. Inventory can offer alternate views or sorting by broad category, material type, subtype, quality, species, source world, colour, quantity, or recent acquisition. These are projections over the same owned material units; changing the view never moves, merges, spends, or duplicates anything.

The default remains subtype + quality because it keeps common crafting stock compact while preserving each species-specific item one level beneath it. A recipe picker may temporarily group by the ingredient scope it needs, but the confirmation still names the exact subtype, quality, species-specific units, and quantity that will be consumed.

### Player-controlled selection

Where quality affects a result, the player chooses the exact stack and quantity. The game must not automatically prefer low quality or high quality.

This allows the player to save strong materials for the Binder, spend them on a favourite companion, or deliberately make inexpensive equipment for someone used less often.

Automatic lowest-grade allocation is acceptable only for a recipe whose result is explicitly quality-neutral. Every quality-neutral recipe must be identified as such rather than assumed.

## Recipes

### Three scopes of substitute ingredient

Recipes can combine static ingredients with one or more substitute slots:

| Ingredient scope | Example | Meaning |
|---|---|---|
| Static | 1 Resin | Only the named material performs this role |
| Broad category | 1 Scale material | Fish, lizard, armoured, and other scale types can qualify |
| Specific category | 1 Fish Scale material | Any qualifying fish-scale subtype or species variant can qualify |
| Precise material | 1 Armoured Fish Scales | Only this physically distinct subtype qualifies |

Every substitute slot presents its complete eligible physical list. It never says only that a hidden numerical property is high enough.

### Properties and statistics

The existing property model can remain useful behind generation and crafted-stat calculation. It must not remain the player's recipe vocabulary.

- Recipes ask for recognizable materials and categories.
- A selected material contributes direct, previewed statistics.
- Higher resource quality directly improves the values contributed by that material.
- A Poor Hide might contribute less Armour than an Exceptional Hide.
- Material properties may influence viable statistics such as Armour, damage, accuracy, reach, status application, resistance, healing, or another actually implemented value.
- There is no durability system. Terms such as brittle, dependable, wear, or breakage cannot be used as implied mechanics.

The craft preview must show the exact before-and-after statistics produced by the player's current material selection.

### Crafted item quality

Ordinary crafted equipment receives a result name from the quality of its selected inputs:

| Input result band | Crafted name |
|---|---|
| Mostly Poor | Rough |
| Mostly Common | Fine |
| Mostly Rare | Superior |
| Exceptional result | Exceptional |

The exact multi-input calculation remains **Will discuss with Aimee**. It must be deterministic and visible in the preview.

### Peerless equipment

Peerless is a legendary equipment quality, not a resource band.

Potential sources are:

- equipment dropped by high-level alpha creatures; and
- a small chance for a maximum-level crafting facility to produce a Peerless result when the recipe uses the required high-quality inputs.

Whether staffing the facility with its matching NPC improves that chance remains **Will discuss with Aimee**. Peerless chance, eligible input requirement, and bad-luck protection also remain open tuning decisions.

### No arbitrary single-use materials

Every ordinary or rare resource should have more than one physically sensible consumer. Bookbinder will not use singular quest materials as an exception because singular quests are not part of the intended game.

If a proposed material has only one arbitrary use, Game Design must either:

- find another natural consumer;
- fold it into a better physical category;
- make it a meaningful processed intermediate; or
- remove it.

## Raw, processed, and finished layers

Aimee approves the processed-material layer. The intended economy has four levels:

1. **Raw world materials** - ground, ore, sand, timber, fibre, resin, fluids, salts, and other directly harvested matter.
2. **Raw creature and flora materials** - scales, hides, pelts, bone, chitin, venom, oils, coloured fibres, and other generated biological matter.
3. **Processed materials** - ingots, glass, leather, cloth, cord, planks, prepared extracts, and other standardized useful stock.
4. **Finished components and items** - weapon parts, armour layers, instruments, remedies, conduits, buildings, and final equipment.

Processing should deepen facility use without creating busywork. A processing step is justified when it:

- changes how a material can be used;
- combines or purifies raw matter;
- creates a reusable intermediate shared by several recipes; or
- gives a facility a meaningful progression role.

The exact processed-material list and facility ownership remain **Will discuss with Aimee** before implementation.

## Harvesting and progression

### Progression is access, not world censorship

World generation may produce advanced materials at any point when the written and rolled world supports them. Progression controls whether the player can efficiently harvest and process them.

The main progression axes are:

- better harvesting tool tiers;
- construction of new processing facilities;
- facility upgrades;
- higher recipe tiers within upgraded facilities;
- learned World Writing vocabulary that targets desired ground, liquid, material, and ecological conditions.

### Mining and cutting tools

The game should provide a recognizable sequence of picks and axes. A starting Rock Pick and basic Axe may be found, built, or owned at the beginning. Each improved pick tier should open roughly two or three additional metal or mineral groups.

Exact metals, tier count, starting ownership, upgrade recipes, and harvest thresholds remain **Will discuss with Aimee**.

### Plants and scythes

Small ordinary plants can be gathered with a simple Scythe. More dangerous or difficult plants require higher harvesting tiers. Ordinary flora remains non-damaging; only explicitly dangerous placed flora owns its authored contact or poison behavior.

Tool gating should explain why a plant cannot yet be harvested without pretending the plant did not generate.

### Trees and canopy

Trees become real world structures rather than an absent resource abstraction.

- Outside a canopy, the player sees the leaves and crown.
- Beneath the canopy, the presentation reveals the trunk and the ground beneath it.
- The trunk becomes an eligible harvesting target when the player has the required Axe tier.
- Canopy presentation must not hide hazards, sites, portals, or occupied tiles from the rules.

Exact canopy footprint, movement, line-of-sight, regrowth, and tree-felling consequences remain **Will discuss with Aimee**.

## World generation

### Preserve the working foundation

The existing deterministic seed, frozen world receipt, land/water placement principles, reachability protections, and water-body distinction provide a useful foundation. The overhaul must not destroy those properties.

### Ground pattern and composition are separate

World generation first chooses how ground is arranged, then chooses the physical ground or liquid types that fill the available sockets.

Potential ground-pattern families include:

- Uniform - one dominant ground type;
- Striated - long bands or layers;
- Scattered - many separated patches;
- Clustered - a few large regions;
- Graded - one composition transitions into another;
- Fractured - broken pockets divided by hostile or impassable seams.

These names are working vocabulary. Final pattern names, counts, weighting, and visual language remain **Will discuss with Aimee**.

Each socket can then resolve to a granular physical type, such as:

- multiple dirts;
- multiple sands;
- multiple stones such as Granite;
- shallow and deep liquids with physically meaningful kinds;
- ice, mud, ash, or other compatible surfaces.

Physical terrain should create appropriate harvest opportunities. Granite ground can support Granite nodes. Sand can be collected and processed into glass. Resource presence is causally connected to the generated region rather than scattered without explanation.

### World size

World Writing may include size Sigils. The smallest world can be somewhat smaller than the current map; the largest may be approximately four times its current area.

- A small world is centered within the existing minimap region.
- A large world uses the same minimap viewport, which scrolls with the player.
- Size changes area, travel, placement capacity, and discovery opportunity without changing the fixed native UI target.

Exact dimensions, costs, unlock order, and generation budgets remain **Will discuss with Aimee**.

### Direct targeting through World Writing

Players must be able to call at least some ground types, terrain structures, and base resources directly. A request such as `ground = granite` can make Granite one of the world's ground compositions rather than merely nudging an invisible probability.

Flora and fauna remain emergent, but their useful material categories can also receive direct pressure. A Chitin request can increase pressure toward creatures capable of producing Chitin without dictating a single species.

The final World Writing vocabulary should distinguish:

- direct ground or liquid declarations;
- direct base-resource declarations;
- ecological material pressure, such as Chitin;
- ordinary pressure-based influence;
- unwritten facets that remain generated.

Direct requests must matter. They need not make every exact node safe, adjacent, or guaranteed unless the authored rule explicitly says so.

### Granular causal ecology

World features influence one another:

- exact ground and liquid types constrain flora;
- light, atmosphere, weather, temperature, water, and terrain shape flora;
- flora and terrain create habitats and food structures;
- creature body plans and mobility must fit those habitats;
- world colour influences creatures and their drops;
- generated physical anatomy determines recognizable loot;
- hazards and harvest requirements remain visible and truthful.

Examples:

- solid stone supports mosses, crusts, fissure growth, or rare rooted forms rather than arbitrary giant trees;
- sand can support adapted scrub or selected trees, but not every canopy form;
- deep water supports aquatic creatures;
- shore and shallow-water regions support amphibious or crocodile-like creatures;
- flying creatures can cross ground and water while still needing sensible perches, prey, or weather tolerance.

## Creature generation

The generator needs explicit, player-readable body-plan and habitat families capable of producing a broad range such as fish-like, bird-like, lion-like, amphibious, crocodile-like, and hybrid generated creatures.

The intended generator separates:

- body plan;
- locomotion and habitat access;
- size and build;
- covering and armour subtype;
- armament;
- colour and ornament;
- behaviour and encounter role;
- generated species identity;
- material yields.

Habitat access includes at least:

- land;
- shallow water;
- deep water;
- amphibious land and shallow water;
- flying or broadly traversing;
- any later explicitly authored special habitat.

The Bestiary and encounter copy must tell players what kind of creature they are seeing. Location alone cannot be the only clue.

Exact body-plan taxonomy, hybrid constraints, visual assembly, species naming, and loot tables remain **Will discuss with Aimee**.

## Weather, atmosphere, and compatibility

Atmospheric and weather conditions must be visible beyond lighting changes. Miasma may use haze or animation; rain, ash, snow, and other precipitation need their own truthful presentation.

Generation needs an explicit compatibility and transformation pass:

- incompatible conditions cannot simply coexist in the resolved world;
- an impossible candidate combination does not reject the world or reroll its whole receipt;
- temperature or another relevant pressure deterministically selects rain versus snow and preserves the selected condition;
- rain plus miasma may become acid rain when that combination is authorized;
- ash and snow may coexist only when their physical source and temperature logic support it;
- the resolved combined condition owns its gameplay effect and visible presentation.

The exact compatibility matrix, gameplay effects, and visual requirements remain **Will discuss with Aimee**.

## Rubble

Rubble is not an acceptable name for a specific finished resource. Aimee's preferred direction is now a mixed, region-causal raw find because it can provide a fun bounded grab bag from a zone the player could not fully explore or harvest with current tools.

The intended behavior is:

- broken terrain can yield a renamed mixed geological find such as Unsorted Stone or Mineral Debris;
- its frozen source-region receipt defines the real stone, ore, mineral, or glass-bearing materials it can contain;
- processing produces a bounded selection from that receipt, never a global bag of unrelated resources;
- the result may include a material the player saw in that region but could not reach or harvest directly, making the find useful without replacing tools or exploration;
- processing consumes the mixed find, so save/reload cannot reroll it indefinitely.

**Will discuss with Aimee:** final player-facing name, where it is collected, output count, how strongly the source receipt favors common versus inaccessible regional materials, and which facility processes it.

## Incremental delivery

This overhaul does not need to wait for one economy-wide release. Each bounded vertical slice may ship when it is coherent, save-safe, and truthful:

1. Introduce one canonical material producer or one world-region yield.
2. Carry that material through the exact Field, Return, and Storehouse path it needs.
3. Connect one useful recipe, trade, processing, or Recycler consumer.
4. Preserve untouched buildings through explicit legacy compatibility until their own slice is replaced.
5. Migrate only the stock and receipts owned by the promoted slice, idempotently and without loss.
6. Update the Player Wiki to show which parts are implemented and which still use the earlier system.

Aimee is the current tester and may knowingly enter an unlocked building whose overhaul has not arrived yet. That temporary limitation is acceptable when the page remains functional under its old rules or clearly explains its current boundary. It is not acceptable to corrupt stock, consume the wrong quality, break an existing save, or silently advertise intended behavior as live.

## Public Wiki contract

The Player Wiki is Aimee's complete view into systems she may not yet have reached in play. It must stay current across every arena.

Every affected page presents:

- **Implemented now** - exact live behavior, inputs, outputs, unlocks, limits, and known player-visible defects;
- **Intended design** - the settled target described here;
- **Will discuss with Aimee** - unresolved decisions that must not be presented as live or settled;
- **Implementation status** - not started, structural work in progress, partially playable, delivered, or verified.

Crafting pages must include every facility, every recipe, exact static ingredients, complete substitute categories, output, stat preview rules, quality behavior, processing dependency, progression tier, and related acquisition routes.

World, ecology, creature, resource, inventory, Return, Storehouse, Trading Post, Recycler, equipment, and World Writing pages must cross-link to the same material identities. The Wiki cannot preserve a superseded name or recipe after the game changes.
