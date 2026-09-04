# Resource, Crafting, World, and Ecology Plan V2

Status: intended-system authority and decision draft, reconciled against Aimee's Top Level Notes and later clarifications on 3 September 2026.

This document describes the intended game. It does not claim these systems are already implemented. The public Wiki must always distinguish **Implemented now** from **Intended design** until each part is delivered and verified.

## What this plan supersedes

Two older design conclusions are useful records of the current implementation but are not final-product
authority:

- the current twelve broad terrain cases are not enough to describe the final range of generated lands;
- the current twenty-three resource IDs are not a finished material catalogue;
- the six-band creature-material model is superseded by four quality bands for quality-bearing creature materials;
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
| `CraftMaterialQualityBand` uses Rough, Standard, Fine, Superior, Exceptional, and Peerless across material units | This mixes creature-material quality with simple mined stock and incorrectly permits Peerless raw materials | Poor, Common, Rare, and Exceptional only for approved quality-bearing creature materials; mined world resources and ordinary flora have no quality; Peerless remains finished gear only |
| many mined world resources are scalar balances while creature/flora samples are exact property-bearing units | The systems need shared transaction safety without pretending that Sand or Gold needs quality or species provenance | Simple exact-name quantity stacks for mined resources and ordinary flora; subtype + quality stacks and retained source units for creature materials whose generated variation matters |
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
9. Choose exact materials and, only for quality-bearing creature ingredients, their quality.
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
4. **Quality, where that material supports it** - Poor, Common, Rare, or Exceptional for approved quality-bearing creature materials, creating a separate default stack within the subtype.
5. **Species-specific item** - the generated species unit inside that quality-bearing stack, retaining its inherited colour, values, source, and history.

Example:

- **Scales** is a broad recipe category.
- **Fish Scales** and **Lizard Scales** are specific material types.
- **Armoured Fish Scales** is a precise subtype.
- Scales from two different generated fish species share one Armoured Fish Scales stack by default when their quality matches.
- Expanding that stack shows the contributing species, source worlds, colours, quantities, and inherited values.

This retains the connection between world pressures, generated species, and useful loot without forcing players to manage one item type per species.

### Starting physical-material registry

This is the starting taxonomy for the overhaul. It is deliberately smaller than a list of generated species
and more specific than the current generic `Reagent`, `Toxin`, `Ore`, or `Rubble` holdings. A subtype exists
only when the physical difference changes a recipe, a finished item's statistics, or its appearance. A
colourful name alone never creates another subtype. A named candidate is promoted into the playable registry
only after its producer, host, tool, processing, custody, trade, recycling, and at least two sensible consumers
are mapped.

| Source | Broad recipe category | Material type examples | Precise subtype examples | Species/source detail |
|---|---|---|---|---|
| Ground and geology | Structural stone | Granite, Limestone, Sandstone, Slate, Basalt, Marble | Dressed, cut, or broken forms belong to processing/state, not quality | Region and world |
| Ground and geology | Loose earth and aggregate | Sand, Clay, Silt, Gravel, Rubble | Rubble is a mixed raw find separated at the Recycler, not a finished recipe material | Region and world; one normal/green quantity stack per exact material, with Rubble retaining its underlying source-region batches |
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

- **Rubble** remains a familiar raw resource name, but stops acting as an interchangeable finished crafting
  material. It is a region-bound mixed geological find that the Recycler separates into real local materials.
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

The names in the starting registry are a taxonomy and candidate set, not permission to add filler. Each
candidate must have a believable geological host, at least two useful consumers or one widely reused processing
role, an understandable harvesting tier, and a clear reason to exist beside its neighbours. A candidate with
no complete path remains design-only rather than becoming empty inventory clutter. The final pass must map
every promoted material to terrain, world pressures, tools, recipes, buildings, trade, and World Writing before
its Sigil or clue order is designed.

No line in this table authorizes a material just because it sounds plausible. Before promotion, every type or
subtype needs a causal producer, at least two sensible consumers or one reusable processing role, player-facing
art/identity, and a complete custody path.

### Colour is inherited

Generated creatures should derive visible colour from the world. Their physical drops retain that colour information. When a coloured material is used in clothing or another visibly material-led object, its colour can contribute to the crafted result.

Colour is provenance and appearance data, not a reason to create another inventory stack. An expanded stack can show how many units of each inherited colour or species variant it contains. A recipe that cares about visible colour lets the player choose the contributing units deliberately.

Colour never creates another inventory stack. Equipment and other visibly material-led gear preserve separate
coloured regions for the materials the player chose: a haft, binding, lining, plate, blade, trim, or similar visible
part keeps its own selected material colour. This provides a modest but meaningful form of character
customization. Items whose colour must communicate their function at a glance use a standardized authored
appearance instead. A potion, remedy, or similar recognition-critical supply does not change colour because of
the materials used to make it.

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

### Quality-bearing creature materials

Approved quality-bearing creature materials use exactly four quality bands:

| Creature-material quality | Colour | Inventory behavior |
|---|---|---|
| Poor | White | Separate stack within the most-specific resolved type or subtype |
| Common | Green | Separate stack within the most-specific resolved type or subtype |
| Rare | Blue | Separate stack within the most-specific resolved type or subtype |
| Exceptional | Purple | Separate stack within the most-specific resolved type or subtype |

Creature materials are the confirmed use of this system. Flora-derived materials are ungraded by default and
stack by their resolved type or subtype; their species, colour, source, and useful measurements remain available
in expanded detail. A future recipe must prove a real recurring player decision before one particular flora
family can gain quality. Peerless is not a raw-material quality.

### Stack key

The default player-facing stack key for a quality-bearing material is:

> Most-specific resolved material type/subtype + creature-material quality

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

The source species does not split a creature material's default stack. A materially different subtype or
quality does. A mined material never receives a quality split in the first place.

### Inventory views and sorting

The player should not be locked to one presentation. Inventory can offer alternate views or sorting by broad category, material type, subtype, quality where applicable, species, source world, colour, quantity, or recent acquisition. These are projections over the same holdings; changing the view never moves, merges, spends, or duplicates anything.

The default for quality-bearing creature stock remains subtype + quality because it keeps crafting stock compact while preserving each species-specific item one level beneath it. Ungraded flora stock and mined stock remain one row per exact material type or subtype. A recipe picker may temporarily group by the ingredient scope it needs, but the confirmation names the exact material, applicable subtype/quality/source units, and quantity that will be consumed.

### Player-controlled selection

Where creature-material quality affects a result, the player chooses the exact stack and quantity. The game must not automatically prefer low quality or high quality. Mined and ordinary flora ingredients require only exact material/type and quantity selection because there is no higher or lower grade to substitute.

This allows the player to save strong materials for the Binder, spend them on a favourite companion, or deliberately make inexpensive equipment for someone used less often.

A quality-neutral recipe may suggest the lowest usable band, but the player still confirms that band and quantity. It never draws from another quality stack automatically. Within the confirmed band, outcome-neutral source lots may use the oldest eligible units without another picker.

### Source lots beneath a stack

The compact stack is a browsing view. It does not erase the exact units beneath it.

- The player chooses a visible stack first.
- **Choose source** appears only when source measurements, colour, provenance, price, or output would change.
- Outcome-neutral operations use the oldest eligible units and do not force an extra picker.
- If one source lot cannot fill a multi-unit socket, the player can combine lots. The preview names every lot and
  uses a quantity-weighted average of the recipe-named source measurement.
- Return loss, trade, processing, crafting, and recycling freeze and consume the same exact unit IDs.
- No preview can silently substitute another source lot before commitment.

This preserves the value of generated species without making every ordinary transaction feel like bookkeeping.

All mined, flora, and creature material holdings are slot-free in the Field and Storehouse. Equipment, consumables, Pages, Curios, and other discrete belongings continue to own item slots. A material quantity never enters Waiting merely because item slots are full.

For a partial Expedition Return, protected outbound units return first. Newly gathered units are partitioned by a deterministic ordering of run ID, exit turn, stack identity, and exact unit ID, then frozen in the Return receipt. Inventory order cannot be manipulated to save or lose the most valuable source lot, and relaunch cannot reroll the partition.

## Recipes

### Four ingredient forms

Recipes can combine static ingredients with one or more substitute slots:

| Ingredient scope | Example | Meaning |
|---|---|---|
| Static | 1 Resin | Only the named material performs this role |
| Broad category | 1 Scale material | Fish, lizard, armoured, and other scale types can qualify |
| Specific category | 1 Fish Scale material | Any qualifying fish-scale subtype or species variant can qualify |
| Precise material | 1 Armoured Fish Scales | Only this physically distinct subtype qualifies |

Every substitute slot explains its physical scope and presents every currently known, owned eligible material.
The recipe's complete authored eligibility list remains available in the Wiki after discovery rules permit it;
the in-game picker does not spoil undiscovered generated species or pretend an unknown subtype is already owned.
It never says only that a hidden numerical property is high enough.

### Properties and statistics

The existing property model can remain useful behind generation and crafted-stat calculation. It must not remain the player's recipe vocabulary.

- Recipes ask for recognizable materials and categories.
- A selected material contributes direct, previewed statistics.
- Higher creature-material quality directly improves the values contributed by that material.
- A Poor Hide might contribute less Armour than an Exceptional Hide.
- Material properties may influence viable statistics such as Armour, damage, accuracy, reach, status application, resistance, healing, or another actually implemented value.
- There is no durability system. Terms such as brittle, dependable, wear, or breakage cannot be used as implied mechanics.

The craft preview must show the exact before-and-after statistics produced by the player's current material selection.
Continuous contributions remain unrounded until every selected component affecting that statistic has been
added, then the finished statistic rounds once to its supported precision. A discrete statistic that cannot
show four meaningful bands does not receive a fake four-step scale; quality improves the item's primary Power
or protection instead.

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
material identity. Their deposits do not roll a crafting quality, and no quality multiplier is applied. Flora
materials likewise remain ungraded; a recipe may use a relevant plant measurement or inherited colour without
creating a quality band. A recipe
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

Each recipe marks its identity-bearing primary and structural secondary sockets. Primary sockets share 70% of
the score and secondary sockets share 30%; decorative, expendable, and minor fitting ingredients do not vote.
If only one designated quality-bearing group exists, it supplies the score. A secondary ingredient cannot name
the whole result merely because the main body is ungraded. An ungraded mined, flora, or standardized ingredient
in a designated quality socket contributes rank 1, the Fine workmanship baseline. A normal recipe with no
creature-quality socket therefore produces Fine work unless that exact recipe has a fixed named result. The
deterministic result and every contributing socket appear in the preview.

### Peerless equipment

Peerless is a legendary equipment quality, not a resource band.

Potential sources are:

- equipment dropped by high-level alpha creatures; and
- a small chance for a maximum-level crafting facility to produce a Peerless result when the recipe uses the required high-quality inputs.

At a maximum level-3 facility, an eligible craft using only Rare or Exceptional quality-bearing inputs has the
accepted Peerless chance in the tuning reference. Staffing the facility with its matching specialist improves
that chance, and the accepted bad-luck protection guarantees the twentieth consecutive eligible craft of the
same schematic at the same facility. Its progress is visible. A Peerless result resets only that schematic's
counter, so cheap work in another family cannot prepare an expensive item to become Peerless.

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
2. **Raw creature and flora materials** - scales, hides, pelts, bone, chitin, venom, oils, coloured fibres, and other recognizable generated parts.
3. **Processed materials** - ingots, glass, leather, cloth, cord, planks, prepared extracts, and other standardized useful stock.
4. **Finished components and items** - weapon parts, armour layers, instruments, remedies, conduits, buildings, and final equipment.

Processing should deepen facility use without creating busywork. A processing step is justified when it:

- changes how a material can be used;
- combines or purifies raw matter;
- creates a reusable intermediate shared by several recipes; or
- gives a facility a meaningful progression role.

Processing belongs to the specialist whose ordinary work makes the transformation understandable. It does not
return to a universal Workshop and does not require a new catch-all processing building.

| Processed material or action | Source material | Owning specialist and facility | Boundary |
|---|---|---|---|
| Region-supported stone, metal, mineral, or glass-bearing finds from Rubble | Rubble from one retained source-region batch | Noll · Recycler | A separate sorting action from gear dismantling; it cannot produce a material absent from that region |
| Named metal Ingot, only where a real recipe needs a smelted form | The exact named solid smeltable metal | Halloway · Blacksmith | The output is named, such as Iron Ingot; there is no universal Metal ingredient. Mercury remains Mercury, and non-metal minerals are not silently smelted |
| Glass | Sand or Quartz plus the exact recipe's authored fuel or flux | Halloway · Blacksmith furnace | Furnace work, not a generic mineral conversion. Rift-glass remains its own material rather than becoming ordinary Glass |
| Leather | Hide or Skin | Corrin · Tannery | Keeps applicable creature-material quality, colour, and provenance. Pelt remains Pelt unless a later recipe explicitly needs a distinct cured form |
| Cord and Cloth | The exact eligible Plant Fibre | Corrin · Tannery | Corrin owns flexible organic stock and bindings; Cord and Cloth remain separate outputs with separate consumers |
| Planks and Hafts | The exact eligible Log | Fen · Bowyer | Fen owns timber selection and shaping. Planks may serve construction; Hafts exist only where weapon or tool recipes consume them |
| Pulp and Paper | The exact eligible fibrous plant stock | Isolde · Scriptorium | Pulp stops dropping ready-made from plants. Pulp and Paper are alternate one-step outputs, so ordinary paper does not require processing the same stock twice. The Scriptorium owns paper stock as well as writing tools and ink |
| Named prepared extracts | The exact eligible leaf, root, flower, spore, sap, resin, venom, oil, or other named substance | Nessa · Apothecary | `Prepared Extract`, `Reagent`, and `Toxin` are recipe categories, not universal inventory items; the output keeps a useful physical name |
| Named Stone Block, only when a later recipe genuinely needs it | Two units of the same named structural stone | Grimmond · Deep Works | This is ordinary stone cut into an even building piece: Granite makes a Granite Block, Limestone makes a Limestone Block, and so on. Early construction may continue to use raw named stone. A Stone Block cannot become an opening-game dependency before Grimmond is reachable |
| Writing pigments and prepared ink | Exact eligible mineral pigment or botanical colour source | Isolde · Scriptorium | Scriptorium retains exclusive CMY+Depth writing-ink ownership; this does not move reactive stains or remedies from the Apothecary |

Auber's Distillery keeps its separate Raw Essence and direct Core-attunement role; there is no Blank Core step. It does not become the owner
of ordinary plant extracts merely because “distilling” could describe both actions. Sela's Wayfarer's Table
supports field packing, visible-flora knowledge, and organic yield; it is not turned into an unrelated mill.
Bracken's Armoury and Maud's Weaponsmith consume appropriate processed stock in their own recipes but do not
manufacture the general-purpose stock first.

Each process declares whether it preserves a creature-material band, standardizes the output as ungraded stock, or
uses a named recipe-defined result. Leather preserves one selected Hide or Skin band and cannot mix bands in a
batch. Glass, named metal Ingots, Planks, Hafts, Pulp, Paper, Cord, Cloth, pigments, and writing ink are
standardized ungraded stock. Named extracts use their own authored potency rule. Processing never applies a
quality multiplier that will be applied again to the finished item.

The first-pass conversion quantities, zero-Essence ordinary-processing rule, material price table, and
facility-affordability limits are settled in the first-pass tuning reference. Facility levels and any justified
recipe-specific exception are authored with each process's first two real consumers. Ownership, output identity,
and starting ratios are not another product-ownership question. An ordinary finished recipe has no more than one
mandatory processing step; two are reserved for exceptional or capstone work.

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

The opening expedition kit contains an exact owned Rock Pick, basic Axe, and basic Scythe. They fit a dedicated
three-place tool roll—one place for each class—rather than consuming ordinary item or Field Kit capacity. The
opening loadout packs all three by default, and a higher tier replaces the lower tier in that class. Holding
Interact selects only among packed tools; it does not grant an invisible account-wide capability. The accepted
three-level Pick, Axe, and Scythe ladders, material groups, yields, and turn costs are defined in the first-pass
rules. Upgrade recipes and their campaign unlocks remain part of the facility-and-recipe pass.

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
expedition. The preference persists between expeditions but activates only when the exact tool is packed. It is
a field-tool choice, not a weapon slot, item charge, or durability system. If the selected tool is no longer
available, the game clears that selection and explains why before any action is committed. Both hold controls
use the accepted 0.40-second threshold.

An encounter owns combat input. A traveller, site, portal, or authored hazard interaction takes precedence over
harvesting on the same tile. A direction toward a living creature never becomes an accidental tool swing. The
visible action label names the action that will occur; ambiguity or stale state refuses for zero turns.

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

The first-pass crown footprints and two-canopy sight rule are settled in the tuning reference. Tree work is
saved hit by hit, the last hit removes only that trunk's own crown, and overlapping standing crowns remain.
Regrowth and stump presentation remain part of the later flora-life-cycle pass.

## World generation

### Preserve the working foundation

The existing deterministic seed, frozen world receipt, land/water placement principles, reachability protections, and water-body distinction provide a useful foundation. The overhaul must not destroy those properties.

The present generator is therefore a migration baseline, not the final product. Its broad `Stone`, `Soil`,
`Sand`, `Rubble`, `Ash`, `Water`, `Deep Water`, `Ice`, `Mud`, `Growth`, `Groundcover`, and `Chasm` cases mix
several different ideas: underlying material, surface texture, liquid depth, vegetation, deposit, and absence
of ground. The final generator stores those ideas separately so two worlds can be physically different without
inventing an unrelated movement rule for every visual variation.

### Final world-generation layers

Every new-version world resolves and freezes these layers in dependency order:

1. **World size and regional arrangement** — total area, budgets, major regions, and how they meet.
2. **Relief and underlying geology** — slopes, basins, ridges, cliffs, chasms, passable connections, and physical formations.
3. **Hydrology and liquid** — river, pond, lake, sea, marsh, shallow/deep relationship, and liquid identity.
4. **Resolved climate** — temperature, illumination, atmosphere, weather, precipitation, and cycle after compatibility rules choose or transform conflicts.
5. **Derived surfaces and deposits** — bedrock, scree, gravel, sand, clay, loam, peat, mud, snow, ash, salt crust, and other outcomes caused by the preceding layers.
6. **Flora structure** — groundcover, ordinary plants, dangerous placed flora, shrubs, trunks, and canopies that fit the resolved habitat.
7. **Reserved written guarantees and ordinary resource hosts** — exact harvestable placements derived from the world, with required guaranteed sources reserved before later occupancy.
8. **Creature, site, traveller, hazard, and portal ecology** — compatible placements that respect the reserved traversal graph and cannot overwrite guaranteed sources.

Each layer owns a distinct fact in the frozen receipt. Rendering, Look, movement, harvesting, World History,
and relaunch all read that same result rather than deriving competing interpretations.

### Ground pattern and composition are separate

World generation first chooses how ground is arranged, then chooses the physical ground or liquid types that fill the available sockets.

The accepted initial regional-arrangement families are:

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

The accepted starting physical catalogue is intentionally compact but composable:

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
18×18 area at its largest. The accepted intended ladder is **12, 15, 18, 26, and 36**, making the largest world
exactly four times the ordinary world's area. Node, creature, site, stability, and return-route budgets scale
with passable area so a Vast world creates more meaningful choices rather than empty walking. Engineering must
not silently treat the current 28×28 maximum as the final answer.

### Direct targeting through World Writing

Players must be able to call at least some ground types, terrain structures, and base resources directly. A request such as `ground = granite` can make Granite one of the world's ground compositions rather than merely nudging an invisible probability.

Flora and fauna remain emergent, but their useful material categories can also receive direct pressure. A Chitin request can increase pressure toward creatures capable of producing Chitin without dictating a single species.

The final World Writing vocabulary should distinguish:

- direct ground or liquid declarations;
- direct base-resource declarations;
- ecological material pressure, such as Chitin;
- ordinary pressure-based influence;
- unwritten facets that remain generated.

Direct requests must matter, with a guarantee suited to the thing written:

- a ground declaration creates at least one entry-connected region occupying at least 20% of passable ground,
  with a visible example within 3–8 movement steps;
- a liquid declaration creates an entry-connected shoreline or otherwise safely observable body while topology
  and depth remain generated;
- a base-resource declaration creates at least one eligible entry-connected harvest source within 3–8 movement
  steps; that source is two common nodes, two uncommon nodes, one rare node, or one hand-gathering placement according to the named material; and
- an ecological request such as Chitin biases compatible anatomy and habitat without promising a named species
  or guaranteed drop.

At the first-pass yields, those source clusters contain 12 common, 8 uncommon, 2 rare, or 2 hand-gathered units. If the player's tool is too weak, the guaranteed source still appears and Look explains the missing tool;
writing cannot quietly fail merely because progression blocks extraction. Before Binding, the quote distinguishes
a presence guarantee from an ecological pressure and names any known tool requirement. The quoted first source
uses the published cluster yield; exact placement inside its distance band, hazards, and additional deposits remain generated.

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

Exact body-plan taxonomy, hybrid constraints, visual assembly, species naming, and loot tables belong to the next Game Design creature-generation pass. They are not unresolved product choices unless that pass finds a genuine visual or creative fork.

## Weather, atmosphere, and compatibility

Atmospheric and weather conditions must be visible beyond lighting changes. Miasma may use haze or animation; rain, ash, snow, and other precipitation need their own truthful presentation.

Generation needs an explicit compatibility and transformation pass:

- incompatible conditions cannot simply coexist in the resolved world;
- an impossible candidate combination does not reject the world or reroll its whole receipt;
- temperature or another relevant pressure deterministically selects rain versus snow and preserves the selected condition;
- rain plus miasma may become acid rain when that combination is authorized;
- ash and snow may coexist only when their physical source and temperature logic support it;
- the resolved combined condition owns its gameplay effect and visible presentation.

Resolution order is settled even though the full pair-by-pair matrix remains to be authored. An approved
transformation wins first. Otherwise the candidate with the greater total resolved support from the Page and
generated world pressures wins. A tie uses a stable hash of the frozen Page, world seed, and facet ID. When two
direct written guarantees cannot coexist, the pre-Bind preview says which one will dominate and which one remains
an influence; it never promises both. The saved world receipt owns the result through relaunch.

The full compatibility matrix, gameplay effects, and visual requirements remain a later Game Design pass. It
must enumerate which pairs transform, dominate, layer, or exclude one another without changing this resolution order.

## Rubble

Rubble is an ungraded mixed geological find. It is useful precisely because broken ground may contain several
materials, but recipes should use the real materials recovered from it rather than treating Rubble as a
universal crafting substance.

The intended behavior is:

- broken terrain can yield Rubble;
- the player's ordinary inventory shows one simple, normal/green Rubble quantity rather than qualities or a
  different item name for every world;
- its frozen source-region receipt defines the real stone, metal, mineral, or glass-bearing materials it can contain;
- combining visible Rubble stacks does not discard those underlying source-region batches;
- Noll's Recycler processes a selected quantity of Rubble separately from its gear-dismantling flow;
- the Recycler preview shows the frozen result for those selected units before commitment, and processing
  produces that result exactly once;
- common materials supported by the source region dominate the result. Less common materials occur less often,
  and a genuinely rare local material appears only as a low-chance bonus rather than replacing the ordinary
  return;
- Rubble never produces anything absent from its source region;
- the result may include a material the player saw in that region but could not reach or harvest directly, making the find useful without replacing tools or exploration;
- processing consumes the selected Rubble and adds every previewed material atomically. Cancel, stale state,
  insufficient quantity, invalid custody, or write failure changes nothing;
- preview, refusal, backgrounding, and relaunch never reroll the result.

The accepted Recycler rule is: choose any even quantity from 2 to 6 in one retained source-region batch; every
two Rubble produce one base result; the first is common; later base results are 75% common and 25% uncommon; a
transaction using at least four Rubble has one 5% chance for an additional rare local result. It is available at
Recycler level 1 and costs no Essence or world turn. The preview selects a source-world batch, freezes every
result, and commits atomically. This lets one six-unit common node be processed completely rather than leaving
two unusable units.

Ordinary encounters have a separate first-pass **Found nearby** rule: one frozen 12% roll after victory, awarding at most one non-creature object from the source region. Successful candidates use 75% common, 20% uncommon, and 5% rare weights, skipping a tier the region cannot support. The result is never another body part, a unique or story object, Page, Sigil, Mote, site/guardian/apex reward, or a rerollable substitute for exploration.

## Closed foundations before Sigil and clue design

Aimee has now closed the six foundation questions from this plan:

1. **Physical vocabulary** uses the category → type → optional subtype hierarchy above, with source/species detail beneath it.
2. **Land vocabulary** uses the seven accepted regional arrangements and the expanded physical geology, surface, liquid, and deposit catalogue.
3. **Written guarantee** gives a directly written ground or base resource one start-connected truthful source with the first-pass cluster quantity, while exact distance inside its 3–8 step band, hazards, and tool access remain part of the generated world.
4. **World sizes** use the intended 12/15/18/26/36 ladder.
5. **Material arithmetic** uses the accepted four creature-material quality bands and the reconciled baseline-plus-source stat formula in the tuning reference; mined and ordinary flora materials remain ungraded and use fixed authored contributions.
6. **Processing ownership** follows the specialist-and-facility matrix above, with no universal Workshop or catch-all processing station.

With those foundations closed, Game Design can produce the complete terrain→resource→flora→creature host matrix,
the exact recipe eligibility lists, and the harvesting tiers without guessing. Only then should the project
decide which land/material concepts deserve Sigils, when those Sigils drop, and which traveller clues are fair.

## The only remaining Aimee choice in this pass

1. **Waystone body.** Rift-glass, one Mote, and 12 Essence remain fixed. The permanent hard physical body still
   needs one approved named World material.

Complete recipe lists, facility tiers, creature bodies, ecology matrices, Sigil order, and clue teaching are
remaining Game Design production work. They are not being handed back to Aimee as vague decisions.

## Old-save material conversion

An exact receipt moves to its exact physical material. Existing creature-material bands map Rough→Poor,
Standard→Common, Fine/Superior→Rare, and Exceptional/Peerless→Exceptional when the source cannot support a new
calculation. Peerless never remains a raw-material band. Existing world/flora stock becomes ungraded without
losing its old sale value; that value stays on its legacy source lot. Generic Timber, Fibre, Toxin, and Reagent
remain visible Legacy stock unless their receipt proves an exact Log, Plant Fibre, or named substance. No
migration invents species, subtype, colour, world, or quality.

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
- **Choices for Aimee** - only unresolved creative or product preferences, never ordinary unfinished Game Design work;
- **Implementation status** - not started, structural work in progress, partially playable, delivered, or verified.

Crafting pages must include every facility, every recipe, exact static ingredients, complete substitute categories, output, stat preview rules, quality behavior, processing dependency, progression tier, and related acquisition routes.

World, ecology, creature, resource, inventory, Return, Storehouse, Trading Post, Recycler, equipment, and World Writing pages must cross-link to the same material identities. The Wiki cannot preserve a superseded name or recipe after the game changes.
