# Resource, Crafting, World, and Ecology Plan V2

Status: intended-system authority and decision draft, reconciled against Aimee's Top Level Notes and later clarifications on 3 September 2026.

This document describes the intended game. It does not claim these systems are already implemented. The public Wiki must always distinguish **Implemented now** from **Intended design** until each part is delivered and verified.

## What this plan supersedes

Two older design conclusions are useful records of the current implementation but are not final-product
authority:

- the current twelve broad terrain cases are not enough to describe the final range of generated lands;
- the current twenty-three resource IDs are not a finished material catalogue;
- the six-band creature-material model is superseded by four quality bands for quality-bearing biological materials;
- mined world resources are simple named holdings with one normal/green presentation and no quality axis;
- family-only material identity is superseded by category, type, subtype, quality, and source detail; and
- hidden material-property thresholds cannot decide whether an unrelated material satisfies a recipe.

The current connected-region, water-topology, reachability, frozen-receipt, habitat, and anatomy calculations
remain valuable foundations. The overhaul replaces their temporary vocabularies and consumers rather than
discarding the deterministic work underneath them.

### Current implementation mismatches

| Current implementation | Why it cannot be the final model | Intended correction |
|---|---|---|
| `MaterialFamilyID` puts generic world stock and creature parts in one flat family enum | It cannot express category → type → subtype, and names such as `ore`, `plate`, `reagent`, and `toxin` hide the actual material | Versioned physical-material registry with explicit hierarchy and domain |
| `CraftMaterialQualityBand` uses Rough, Standard, Fine, Superior, Exceptional, and Peerless across material units | This mixes creature-material quality with simple mined stock and incorrectly permits Peerless raw materials | Poor, Common, Rare, and Exceptional only for approved quality-bearing biological materials; mined world resources have no quality; Peerless remains finished gear only |
| many mined world resources are scalar balances while creature/flora samples are exact property-bearing units | The systems need shared transaction safety without pretending that Sand or Gold needs quality or species provenance | Simple exact-name quantity stacks for mined resources; subtype + quality stacks and retained source units only for materials whose biological variation matters |
| several recipes accept broad family lists plus hidden property floors | A player can be told an unrelated object qualifies because an invisible number is high enough | Authored exact/category/type/subtype ingredient slots; properties affect only previewed finished-item stats |
| `GroundType` mixes geology, loose surface, water depth, deposits, vegetation, and missing ground | More visuals or resources cannot make this small mixed enum produce genuinely varied worlds | Separate frozen layers for region pattern, relief, geology, surface, hydrology, deposits, flora, and occupancy |
| current World Resource placement starts from a global catalogue filtered by host rules | Host filtering improves plausibility but still treats resources as additions after the land | Each region creates its own eligible resource pool from its actual formation and ecology |
| current size ladder ends at 28×28 | This is roughly 2.4 times an ordinary 18×18 world, not the intended roughly four-times area | Validate the proposed 36×36 upper tier with matching budgets and minimap scrolling |

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
9. Choose exact materials and, only for quality-bearing biological ingredients, their quality.
10. Craft a result whose statistics and appearance clearly reflect those choices.
11. Improve harvesting tools, facilities, and recipe tiers so more of future worlds becomes usable.

Progression improves the tools, knowledge, and facilities that let players deliberately find, harvest, process, and use more demanding materials.

## Resource identity

### Physical materials remain meaningfully distinct

Creature and world materials must use recognizable physical names. Species-specific rewards matter, but species names do not create dozens of redundant inventory items.

The intended hierarchy is:

1. **Broad category** - a physical class used by flexible recipes, such as Scales.
2. **Specific material type** - a recognizable physical kind, such as Fish Scales.
3. **Precise subtype** - a materially different version required by advanced recipes, such as Armoured Fish Scales.
4. **Quality, where that material supports it** - Poor, Common, Rare, or Exceptional for approved quality-bearing biological materials, creating a separate default stack within the subtype.
5. **Species-specific item** - the generated species unit inside that quality-bearing stack, retaining its inherited colour, values, source, and history.

Example:

- **Scales** is a broad recipe category.
- **Fish Scales** and **Lizard Scales** are specific material types.
- **Armoured Fish Scales** is a precise subtype.
- Scales from two different generated fish species share one Armoured Fish Scales stack by default when their quality matches.
- Expanding that stack shows the contributing species, source worlds, colours, quantities, and inherited values.

This retains the connection between world pressures, generated species, and useful loot without forcing players to manage one item type per species.

### Starting physical-material registry

This is the recommended starting registry for our design discussion. It is deliberately smaller than a list
of generated species and more specific than the current generic `Reagent`, `Toxin`, `Ore`, or `Rubble`
holdings. A subtype exists only when the physical difference changes a recipe, a finished item's statistics,
or its appearance. A colourful name alone never creates another subtype.

| Source | Broad recipe category | Material type examples | Precise subtype examples | Species/source detail |
|---|---|---|---|---|
| Ground and geology | Structural stone | Granite, Limestone, Sandstone, Slate, Basalt, Marble | Dressed, cut, or broken forms belong to processing/state, not quality | Region and world |
| Ground and geology | Loose earth and aggregate | Sand, Clay, Gravel | Mineral Debris only if the mixed-find system is approved | Region and world; one normal/green quantity stack per exact material |
| Ground and geology | Common metal | Iron, Copper, Tin | A distinct processed form only when a real recipe actually uses it | Deposit, region, and world; one normal/green quantity stack per exact material |
| Ground and geology | Precious and unusual metal | Silver, Gold, Mercury, Adamant | A distinct processed form only when a real recipe actually uses it | Deposit, region, and world; one normal/green quantity stack per exact material |
| Ground and geology | Crystal and mineral glass | Quartz, Obsidian, Rift-glass | Physically distinct crystal or glass forms | Deposit, region, and world |
| Ground and geology | Reactive mineral | Salt, Sulfur, Alum, Saltpeter | Distinct minerals retained only when recipes use their different functions | Deposit, liquid margin, region, and world |
| Ground and geology | Mineral pigment | Ochre | Additional mineral pigments only when ink, dye, paint, or finishing recipes use them | Deposit, region, and world |
| Ground and geology | Fuel-bearing material | Coal | Additional fuels only when processing creates a meaningful recurring demand | Formation, region, and world |
| Flora | Wood | Softwood Log, Hardwood Log | Physically distinct trunk wood such as dense or resinous wood, if recipes need it | Generated plant species, colour, and world |
| Flora | Plant Fibre | Stem Fibre, Leaf Fibre, Bark Fibre | A materially different tough or silky fibre | Generated plant species, colour, and world |
| Flora | Plant Part | Leaf, Root, Flower, Spore, Sap, Resin | Toxic Sap, Irritant Spore, or another visible physical subtype | Generated plant species, colour, and world |
| Creature | Skin | Smooth Skin, Aquatic Skin, Membrane | Thick, tough, or armoured forms only where anatomy supports them | Generated creature species, colour, and world |
| Creature | Hide | Rawhide | Tough Rawhide or another visibly thicker structural subtype | Generated creature species, colour, and world |
| Creature | Pelt | Fur Pelt | Short, thick, or otherwise physically different pelts | Generated creature species, colour, and world |
| Creature | Scales | Fish Scales, Reptile Scales | Armoured Fish Scales and equivalent anatomical subtypes | Generated creature species, colour, and world |
| Creature | Feathers | Flight Feathers, Down, Quills | A physically different feather structure, not a rarity adjective | Generated creature species, colour, and world |
| Creature | Shell and Chitin | Shell, Chitin, Carapace | Layered Shell or Chitin Plate where anatomy supports it | Generated creature species, colour, and world |
| Creature | Hard Animal Part | Bone, Fang, Tusk, Horn, Claw | Hollow Bone, Dense Bone, or another structural subtype | Generated creature species, colour, and world |
| Creature | Animal Fluid | Oil, Venom, Ichor | A physically distinct secretion only when its effect differs | Generated creature species, colour, and world |

This registry changes several current nouns:

- **Rubble** stops being a finished resource. Its possible successor is the region-bound mixed find described later.
- generic **Ore** becomes the actual metal it represents, such as **Iron**. Copper, Silver, Gold, Mercury, and Adamant likewise keep their plain names. A processed form is added only when an actual crafting loop needs a distinct intermediate; the system does not force every metal through an ore/ingot vocabulary.
- **Timber** becomes a raw Log type and a processed Plank type instead of one word covering both states.
- **Pulp** is processed stock rather than something a plant drops ready-made.
- **Reagent** is a recipe category over named leaves, roots, flowers, spores, saps, resins, venoms, and prepared extracts; it is not one universal substance.
- **Toxin** is likewise an eligibility category. The inventory holds the actual Toxic Sap, Irritant Spore, Venom, or other named substance.
- **Plate** is not a universal animal material. The anatomy resolves to Armoured Scales, Chitin Plate, Shell, a scute-like Hide subtype, or another truthful physical part.
- **Fin** is a source part; its useful harvested material resolves to the actual Skin/Membrane or rigid structure rather than a generic fin token unless a recipe truly needs a whole fin.
- world-node **Ichor** is retired from new generation. Ichor is a creature material unless a separately authored world source is approved.
- **Raw Essence** and **Motes** are arcane currencies/resources, not ordinary physical materials. They do not gain creature provenance or resource-quality bands.

Mined world resources are intentionally simple. Sand is **Sand**. Gold is **Gold**. Granite is **Granite**.
Each stacks only by its exact material identity and quantity and always uses the normal/green presentation.
They do not gain Poor, Common, Rare, or Exceptional variants, and the deposit or world that supplied them
does not split the player-facing stack.

### Ground and geology need a complete functional catalogue

The ground catalogue should not be as endlessly variable as generated flora and fauna, because a rock does not
need a species identity. It does need enough breadth to make regions feel materially different and to support
the whole Cottage economy. The intended catalogue therefore covers distinct functions rather than stopping at
four stones, a few metals, and two salts:

- **construction stone** for foundations, masonry, fixtures, and architecture;
- **fine or workable stone** for carving, instruments, fittings, and decorative work;
- **loose earth and aggregate** for glass, mortar, ceramics, fill, and construction;
- **common metals** for tools, weapons, fittings, and mechanisms;
- **precious and unusual metals** for trade, advanced equipment, instruments, inscriptions, and late recipes;
- **crystals and mineral glass** for optics, focuses, cutting edges, inks, and Channelworks;
- **reactive minerals** for remedies, tanning, dyes, preservation, distillation, and chemical processing;
- **mineral pigments** for inks, dyes, painted finishes, and appearance-led crafts; and
- **fuel-bearing materials** only where an actual processing loop consumes them repeatedly.

The names in the starting registry are a working discussion set, not permission to add filler. Each candidate
must have a believable geological host, at least two useful consumers or one widely reused processing role,
an understandable harvesting tier, and a clear reason to exist beside its neighbours. The final pass must map
every approved material to terrain, world pressures, tools, recipes, buildings, trade, and World Writing before
its Sigil or clue order is designed.

No line in this table authorizes a material just because it sounds plausible. Before promotion, every type or
subtype needs a causal producer, at least two sensible consumers or one reusable processing role, player-facing
art/identity, and a complete custody path.

### Colour is inherited

Generated creatures should derive visible colour from the world. Their physical drops retain that colour information. When a coloured material is used in clothing or another visibly material-led object, its colour can contribute to the crafted result.

Colour is provenance and appearance data, not a reason to create another inventory stack. An expanded stack can show how many units of each inherited colour or species variant it contains. A recipe that cares about visible colour lets the player choose the contributing units deliberately.

Exact colour blending and multi-material appearance rules remain **Will discuss with Aimee**.

## Quality and inventory stacks

### Mined world resources

Mined ground and deposit resources have no quality axis. Their default stack key is simply:

> Exact material identity

Examples:

- Sand x12
- Gold x3
- Granite x8

All three use the normal/green presentation. Their source world may remain in acquisition history where useful,
but source never creates another stack and never changes their crafting strength. Crafting uses their authored,
fixed material contribution.

### Quality-bearing biological materials

Approved quality-bearing biological materials use exactly four quality bands:

| Biological material quality | Colour | Inventory behavior |
|---|---|---|
| Poor | White | Separate stack within the most-specific resolved type or subtype |
| Common | Green | Separate stack within the most-specific resolved type or subtype |
| Rare | Blue | Separate stack within the most-specific resolved type or subtype |
| Exceptional | Purple | Separate stack within the most-specific resolved type or subtype |

Creature materials are the confirmed use of this system. Whether any flora-derived material also needs quality
bands remains **Will discuss with Aimee**; it must not inherit them automatically. Peerless is not a raw-material
quality.

### Stack key

The default player-facing stack key for a quality-bearing material is:

> Most-specific resolved material type/subtype + biological-material quality

If a material has no meaningful subtype, its type is the stack key. A subtype is not invented merely to fill
every level of the hierarchy.

Examples:

- Common Fish Scales x8
- Rare Armoured Fish Scales x3
- Sand x12, as a simple ungraded mined holding
- Gold x3, as a simple ungraded mined holding

Expanded detail shows:

- broad recipe categories the stack satisfies;
- species or world sources;
- inherited colours;
- exact quantities contributed by each source variant;
- the visible statistics the selected units would contribute to a craft;
- discovery history where disclosure is allowed.

The source species does not split a biological material's default stack. A materially different subtype or
quality does. A mined material never receives a quality split in the first place.

### Inventory views and sorting

The player should not be locked to one presentation. Inventory can offer alternate views or sorting by broad category, material type, subtype, quality where applicable, species, source world, colour, quantity, or recent acquisition. These are projections over the same holdings; changing the view never moves, merges, spends, or duplicates anything.

The default for quality-bearing biological stock remains subtype + quality because it keeps crafting stock compact while preserving each species-specific item one level beneath it. Mined stock remains one row per exact material. A recipe picker may temporarily group by the ingredient scope it needs, but the confirmation names the exact material, applicable subtype/quality/source units, and quantity that will be consumed.

### Player-controlled selection

Where biological-material quality affects a result, the player chooses the exact stack and quantity. The game must not automatically prefer low quality or high quality. Mined ingredients require only exact material and quantity selection because there is no higher or lower grade to substitute.

This allows the player to save strong materials for the Binder, spend them on a favourite companion, or deliberately make inexpensive equipment for someone used less often.

Automatic lowest-grade allocation is acceptable only for a recipe whose result is explicitly quality-neutral. Every quality-neutral recipe must be identified as such rather than assumed.

## Recipes

### Four ingredient forms

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
- Higher biological-material quality directly improves the values contributed by that material.
- A Poor Hide might contribute less Armour than an Exceptional Hide.
- Material properties may influence viable statistics such as Armour, damage, accuracy, reach, status application, resistance, healing, or another actually implemented value.
- There is no durability system. Terms such as brittle, dependable, wear, or breakage cannot be used as implied mechanics.

The craft preview must show the exact before-and-after statistics produced by the player's current material selection.

The current six generated material properties are not being replaced by physical recipe slots. They remain
possible internal measurements of the creature, plant, or deposit that produced a material. Their job is to
calculate concrete finished-item results after a physically eligible material has been selected.

For creature materials, the base values must come from the frozen creature that actually produced the part:

- covering structure and coverage can contribute to the Armour or protection of an eligible armour recipe;
- insulation can contribute to a named resistance or ward already owned by the finished item;
- the creature's pierce, rend, or crush anatomy can contribute to an eligible weapon's damage result;
- mass and flexibility can contribute to an already-supported initiative, accuracy, or similar final statistic;
- venom or other reactive anatomy can contribute to the exact supported status potency or duration; and
- colour and lustre can affect appearance or value where that finished item supports them.

Mined world materials such as Granite, Iron, Obsidian, Sand, and Gold have authored fixed contributions by
material identity. Their deposits do not roll a crafting quality, and no quality multiplier is applied. Plants
may supply permitted biological variation only after their own quality rule is explicitly approved. A recipe
never asks for “hardness 55”; it asks for Armoured Fish Scales, any Scales, Iron, Gold, Sand, or another
understandable physical input. The preview says
“+2 Armour” or “+1 damage,” not “high hardness.”

Subtype assignment may use anatomy or formation data once, during generation. For example, sufficiently
protective overlapping scales may become the explicit subtype **Armoured Fish Scales**. From that point onward,
recipes test the subtype ID, not a hidden threshold. This preserves causal variation without making the player
reverse-engineer invisible numbers.

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

1. **Raw world materials** - stone, named metals, sand, timber, fibre, resin, fluids, salts, and other directly harvested matter.
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

### Field tool and quick-item controls

Aimee's leading control direction separates supplies from harvesting tools while keeping both close to movement:

- holding the centre of the movement arrows opens the quick-use or Field Kit item menu;
- holding **Interact** opens the field-tool selector for available tools such as the Scythe, Axe, or Pick;
- choosing a tool makes it the active field tool and costs no turn;
- tapping **Interact** uses the active tool on an eligible harvestable feature beneath the party, such as a
  passable plant tile; and
- pressing a movement direction toward an adjacent solid harvestable feature uses the active tool against that
  feature, such as swinging the Axe at a blocking tree trunk instead of attempting an impossible move.

The target's physical position determines the input: underfoot features use Interact, while adjacent blocking
features use a direction. Walking across ordinary passable flora never harvests it by accident. Opening a menu,
changing the active tool, backing out, choosing the wrong tool, or pressing toward an ineligible target costs no
turn and changes nothing. Only the rules-confirmed harvest pays its normal turn cost and changes the exact node
and carried yield.

The currently selected tool stays visibly identified and survives backgrounding and cold relaunch during the
expedition. It is a field-tool choice, not a weapon slot, item charge, or durability system. If the selected tool
is no longer available, the game clears that selection and explains why before any action is committed.

Exact button art, hold timing, menu composition, and whether the selection persists between expeditions remain
**Will discuss with Aimee** after the interaction is tried at the fixed native layout.

### Plants and scythes

Small ordinary plants can be gathered with a simple Scythe. More dangerous or difficult plants require higher harvesting tiers. Ordinary flora remains non-damaging; only explicitly dangerous placed flora owns its authored contact or poison behavior.

Tool gating should explain why a plant cannot yet be harvested without pretending the plant did not generate.

### Trees and canopy

Trees become real world structures rather than an absent resource abstraction.

- Outside a canopy, the player sees the leaves and crown.
- Beneath the canopy, the presentation reveals the trunk and the ground beneath it.
- The trunk becomes an eligible harvesting target when the player has the required Axe tier.
- Dense canopy can intentionally limit the player's view. Distant ground, resources, creatures, sites, and
  undiscovered passages may remain concealed until the party approaches, moves beneath the leaves, or gains a
  clear line of sight.
- Concealment is owned by the world rules and frozen receipt, not created accidentally by drawing leaves over
  information the rules consider visible. Look, movement, the minimap, discovery, and rendering must agree.
- Once a concealed feature is revealed, it registers in the minimap according to that feature's normal map
  rules. Canopy can cover the feature in the main world view again, but it cannot restore fog, remove the
  revealed minimap state, or make the player rediscover it.
- A dangerous placement can be concealed at a distance, but it must receive its proper warning before the
  player commits an avoidable contact action. Forest cover cannot create unexplained invisible damage.
- A known portal or discovered site remains known. Canopy may obstruct the immediate view, but cannot erase its
  saved identity, block its interaction without explanation, or make it disappear from established knowledge.
- Harvesting or removing a trunk can open the view beneath its canopy; that change belongs to the saved placed
  tree rather than being recomputed differently after relaunch.

Exact canopy footprint, movement, line-of-sight, regrowth, and tree-felling consequences remain **Will discuss with Aimee**.

## World generation

### Preserve the working foundation

The existing deterministic seed, frozen world receipt, land/water placement principles, reachability protections, and water-body distinction provide a useful foundation. The overhaul must not destroy those properties.

The present generator is therefore a migration baseline, not the final product. Its broad `Stone`, `Soil`,
`Sand`, `Rubble`, `Ash`, `Water`, `Deep Water`, `Ice`, `Mud`, `Growth`, `Groundcover`, and `Chasm` cases mix
several different ideas: underlying material, surface texture, liquid depth, vegetation, deposit, and absence
of ground. The final generator stores those ideas separately so two worlds can be physically different without
inventing an unrelated movement rule for every visual variation.

### Final world-generation layers

Every new-version world resolves and freezes these layers in order:

1. **World size** — total explorable area and generation budgets.
2. **Regional arrangement** — how many major regions exist and how they meet.
3. **Relief and landform** — elevation, slopes, basins, ridges, cliffs, chasms, and passable connections.
4. **Underlying geology** — Granite, Limestone, Sandstone, Basalt, metal-bearing rock, and other approved physical formations.
5. **Surface form** — exposed bedrock, broken stone, gravel, sand, clay soil, loam, peat, mud, or another approved walkable surface.
6. **Hydrology and liquid** — river, pond, lake, sea, marsh, shallow/deep relationship, and fresh, salt, brine, mineral, or another approved liquid type.
7. **Surface deposits and weather state** — snow, settled ash, salt crust, rain, airborne ash, miasma, and other compatible conditions without erasing the ground below.
8. **Flora structure** — groundcover, ordinary plants, dangerous placed flora, shrubs, trunks, and canopies that fit the resolved habitat.
9. **Resource hosts** — exact deposits and harvestable material placements derived from the preceding physical layers.
10. **Creature and site ecology** — habitats, food/cover relationships, generated body plans, and compatible sites after the land actually exists.

Each layer owns a distinct fact in the frozen receipt. Rendering, Look, movement, harvesting, World History,
and relaunch all read that same result rather than deriving competing interpretations.

### Ground pattern and composition are separate

World generation first chooses how ground is arranged, then chooses the physical ground or liquid types that fill the available sockets.

The recommended initial regional-arrangement families are:

- **Homogeneous** — one physical ground composition fills every ground socket in the world. Hydrology,
  deposits, flora, sites, and occupied tiles remain separate layers and do not count as a second ground type;
- **Dominant** — one main composition with a small number of subordinate inclusions;
- **Banded** — long readable bands or layers;
- **Patchwork** — several separated patches of comparable importance;
- **Clustered** — a few large contiguous regions;
- **Gradient** — composition changes progressively across the map; and
- **Fractured** — regions are divided by breaks, chasms, water, or hostile seams while preserving a valid route.

These are generation structures, not clues that expect the player to decode phrases such as “short views” or
“narrow seams.” If a pattern later becomes writable, its Rune Dictionary entry, preview, arrival copy, and
field presentation must teach the same plain meaning.

Each socket can then resolve to a granular physical type, such as:

- multiple dirts;
- multiple sands;
- multiple stones such as Granite;
- shallow and deep liquids with physically meaningful kinds;
- ice, mud, ash, or other compatible surfaces.

Physical terrain should create appropriate harvest opportunities. Granite ground can support Granite nodes. Sand can be collected and processed into glass. Resource presence is causally connected to the generated region rather than scattered without explanation.

The recommended first physical catalogue is intentionally compact but composable:

- **geology:** Granite, Limestone, Sandstone, Slate, Basalt, Marble, Obsidian-bearing volcanic formation, Quartz-bearing formation, fuel-bearing formation, and approved metal-bearing formations;
- **loose/surface ground:** broken stone or scree, gravel, sand, clay soil, loam, peat, and mud;
- **liquids:** fresh water, salt water, brine, and mineral water, each with separate shallow/deep topology where applicable;
- **surface deposits:** snow, settled ash, and salt crust; and
- **non-material structure:** chasms, groundcover, trunks, and canopies remain separate from the material under them.

This creates useful combinations such as Granite bedrock beneath snow, Basalt scree beneath settled ash,
salt-crusted sand, or a muddy Limestone riverbank. Those combinations are receipt facts, not new enum
cases improvised by the renderer.

Resource placement follows the resolved region:

- stone and metal nodes come from the region's geology and formation;
- sand, clay, salt, and other bulk finds come from compatible surfaces or margins;
- wood, fibre, resin, spores, and named plant parts come from generated flora that can live there;
- creature materials come only from the anatomy of generated creatures that can inhabit the region;
- sites may add authored rewards only through their own explicit result; and
- Raw Essence and Motes keep their separate supernatural acquisition rules.

A world never rolls “any resource” after terrain generation. It builds eligible candidates from actual regions,
then places a deterministic subset according to abundance, world size, access, and occupancy.

### World size

World Writing may include size Sigils. The smallest world can be somewhat smaller than the current map; the largest may be approximately four times its current area.

- A small world is centered within the existing minimap region.
- A large world uses the same minimap viewport, which scrolls with the player.
- Size changes area, travel, placement capacity, and discovery opportunity without changing the fixed native UI target.

The current live ladder is 12, 15, 18, 23, and 28 tiles across. It provides only about 2.4 times the ordinary
18×18 area at its largest. The recommended intended ladder is **12, 15, 18, 26, and 36**, making the largest
world exactly four times the ordinary world's area. This remains a design target until performance, placement
budgets, stability costs, and the fixed minimap behavior are verified; Engineering must not silently treat the
current 28×28 maximum as the final answer.

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

Recommended guarantee for a directly written physical ground or base resource: the frozen world must contain
at least one start-connected truthful source of it. If the player's tool is too weak, that source still appears
and Look explains the missing tool; writing cannot quietly fail merely because progression blocks extraction.
Amount, distance, hazards, and additional deposits remain generated. Ecological requests such as Chitin bias
compatible anatomy and habitats but do not promise a named species.

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
- both shallow and deep water support aquatic creatures, with each generated creature's body plan and movement
  deciding which depths suit it;
- shore and shallow-water regions also support amphibious or crocodile-like creatures that can use both water
  and nearby land; and
- flying creatures can cross ground and water. Their habitats still need to suit their feeding, weather, and
  resting needs, but a perch is required only when that particular creature's body plan calls for one.

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
- aquatic shallow and deep water, with per-creature depth suitability;
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
- its frozen source-region receipt defines the real stone, metal, mineral, or glass-bearing materials it can contain;
- processing produces a bounded selection from that receipt, never a global bag of unrelated resources;
- the result may include a material the player saw in that region but could not reach or harvest directly, making the find useful without replacing tools or exploration;
- processing consumes the mixed find, so save/reload cannot reroll it indefinitely.

**Will discuss with Aimee:** final player-facing name, where it is collected, output count, how strongly the source receipt favors common versus inaccessible regional materials, and which facility processes it.

## Decisions to close before Sigil and clue design

The dependency audit leaves six genuine product decisions. Everything else above is a structural correction,
not a choice Engineering should improvise.

1. **Physical vocabulary.** Approve or revise the starting registry, especially Skin versus Hide versus Pelt,
   and the proposed removal of generic Plate, Fin, Reagent, Toxin, Timber, Pulp-as-a-drop, and world Ichor.
2. **Land vocabulary.** Approve or revise the seven regional arrangements and the initial geology, surface,
   liquid, and deposit catalogue.
3. **Written guarantee.** Confirm the recommendation that a directly written ground or base resource guarantees
   at least one start-connected source, while tool access, amount, distance, and danger remain generated.
4. **World sizes.** Confirm whether the intended 12/15/18/26/36 ladder should replace the current
   12/15/18/23/28 ladder.
5. **Material arithmetic.** Set the four biological-material quality thresholds/multipliers and the recipe-slot formulas that turn
   frozen creature measurements into concrete item statistics. Mined materials instead use fixed authored
   contributions with no quality roll. These are balance tables, not recipe eligibility.
6. **Processing ownership.** Set the first processed-material list and which existing or planned Cottage
   facility owns any metal processing that real recipes require, plus glass, leather, cloth/cord, planks/pulp,
   plant extracts, and mixed geological sorting.

After those six choices, Game Design can produce the complete terrain→resource→flora→creature host matrix,
the exact recipe eligibility lists, and the harvesting tiers without guessing. Only then should the project
decide which land/material concepts deserve Sigils, when those Sigils drop, and which traveller clues are fair.

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
