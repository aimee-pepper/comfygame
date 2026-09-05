# Resource, Harvesting, and World First-Pass Rules

> **Updated 4 September 2026 — decided intended behavior, not current phone behavior.** Costs, recipes, upgrades, and character order are revisable first-pass tuning. Starter tools are stone; basic Blacksmith gear and first Pick/Axe improvements use raw materials; basic healing no longer needs Quartz. Blacksmith T2 Iron Ingots, the early maker priority, ordinary source opportunities, and the first cloth/Leather specialist paths are now specified. Their quantities remain first-pass tuning. The new Peerless refinement route remains a proposal. Recipe tracking highlights relevant sources as soon as normally visible, without prior inspection or tool readiness. See **Design Decisions · 4 September** in Aimee Reference for the complete current/intended comparison and the exact early recipes. These changes supersede older cost/order freezes and the old Peerless chance and twentieth-copy rule.

> **Status:** These are the accepted first-pass values and ownership decisions for the resource, harvesting, terrain, canopy, and Rubble subjects Aimee has discussed so far, reconciled through the first coherence and play-feel pass. They describe the intended game, not what the current build already does. Nothing on this page should be presented as implemented until its own game slice has shipped and been tested.

This page keeps the accepted first-pass rules in one place so they can be read and adjusted together. It deliberately stops before the next design subjects: generated creature body plans, the full flora catalogue, Sigil acquisition order, clue progression, complete recipes, facility upgrade costs, and the final parallax-world art catalogue.

## Creature-material quality

Creature materials use four quality bands. Mined resources and ordinary flora do not use this table: Sand is always Sand, Gold is always Gold, Stem Fibre is always Stem Fibre, and all remain normal green stacks.

| Creature-material quality | Display colour | Quality score | Stat multiplier |
|---|---:|---:|---:|
| Poor | White | 0–24 | ×0.75 |
| Common | Green | 25–59 | ×1.00 |
| Rare | Blue | 60–84 | ×1.25 |
| Exceptional | Purple | 85–100 | ×1.50 |

The score comes from the creature and the world that actually produced the part:

> **Quality score = round(75% part expression + 25% source-world Danger).**

The part expression is the unrounded average of the two real creature measurements that produced that physical part. Source-world Danger contributes the following value:

| World Danger | Value used in the quality score |
|---:|---:|
| 0 | 20 |
| 1 | 35 |
| 2 | 50 |
| 3 | 65 |
| 4 | 80 |
| 5 | 95 |

Source measurements are clamped to 0–100. The final score is rounded half up once, after the two weighted parts are combined. Species name never changes the band by itself.

Each physical part uses measurements that make sense for that part. Covering and flexibility can describe Hide; covering and insulation can describe Pelt; armour and coverage can describe Scales; hardness and armour can describe Shell or Chitin; mass and skeletal strength can describe Bone; natural-weapon strength and skeletal strength can describe Fang, Claw, Tusk, or Horn. The final creature-generation catalogue still needs its own design pass, so this page does not invent unapproved body parts or species mappings.

Flora-derived materials are ungraded. They stack by their resolved physical type or subtype, while species, colour, source world, and any useful source measurements remain available beneath that stack. A recipe may use a relevant plant measurement or inherited colour in its preview, but it does not turn that plant into Poor, Common, Rare, or Exceptional stock.

## How a selected creature material changes an item

A recipe chooses a material because it is the correct physical family, type, or subtype. Its numerical measurements do **not** make an unrelated material eligible. Once a valid material is selected, its real source measurements and quality change the finished item's concrete statistics.

Every physically eligible material supplies a recognizable baseline for its role. Its real source measurement then supplies the remaining variation, and quality scales that complete contribution:

> **Role base = common-quality ceiling × (0.50 + source measurement ÷ 200).**
>
> **Material contribution = role base × quality multiplier.**

Do not round an individual component. Add every contribution to the same finished statistic, then round that final statistic once to the precision that statistic already supports. Continuous equipment values use quarter-point precision internally and one decimal in the preview. A discrete statistic that cannot show four meaningful bands does not receive a fake four-step quality scale; that material's quality improves the item's primary Power or protection instead.

This baseline is not a hidden eligibility rule. The authored physical type or subtype has already established that the material can perform the job. The source measurement distinguishes two valid examples of that material without allowing an unrelated object to qualify.

Every recipe names which source measurement and finished-item statistic that component uses. The crafting preview shows the final number before anything is spent.

| Component's job in the recipe | Common-quality ceiling at a source measurement of 100 | Permitted source measurement |
|---|---:|---|
| Primary weapon component | 4 damage | The recipe-named natural weapon, Hardness, or other appropriate attack measurement |
| Primary protective component | 4 Armour | Covering protection, Hardness, or structural Density |
| Secondary damage or protection component | 2 points | The recipe-named supporting measurement |
| Grip, binding, or other handling component | 2 Initiative | Flexibility or lightness, only where the finished item already supports Initiative |
| Insulating layer | 20 ward points | Insulation against the exact supported damage type |
| Valuable visible finish | +30% sale value | Lustre, only where that item can visibly use the finish |
| Reactive component | 2 potency steps | Reactivity, only for a recipe with an existing named reactive effect |

These are per-role common-quality ceilings, not extra recipe requirements. Rare and Exceptional material may exceed the common-quality ceiling through its multiplier. A finished item cannot receive a made-up statistic merely because a material has a high value. Mined materials have fixed, recipe-authored contributions and no quality multiplier.

### Finished crafted quality

Each equipment recipe explicitly marks the sockets that define the object's quality and assigns their weights. Primary identity-bearing sockets share 70% of the result score and secondary structural sockets share 30%. Decorative, expendable, and minor fitting ingredients do not vote. Within each present group, average the input band ranks, combine the weighted group averages, and round half up:

| Rounded result | Finished quality name |
|---:|---|
| 0 | Rough |
| 1 | Fine |
| 2 | Superior |
| 3 | Exceptional |

Poor, Common, Rare, and Exceptional have ranks 0, 1, 2, and 3 respectively. If a recipe has only one designated quality-bearing group, that group supplies the whole score. A secondary ingredient never supplies the whole result merely because the recipe has no quality-bearing primary ingredient. An ungraded mined, flora, or standardized ingredient in a designated quality socket contributes rank 1, the Fine workmanship baseline. A normal recipe with no creature-quality socket therefore produces Fine work unless that exact recipe has a fixed named result. This is one visible rule, not an invisible per-recipe adjustment.

**Unsettled proposal, updated 4 September:** refine an existing eligible piece toward Peerless. One Mote, a maximum-level shop, and its attending matching keeper would together guarantee success; one or two advantages would still offer a disclosed chance. Partial odds, Mote spending on a miss, preview behavior, and old bad-luck progress remain open. The former 3%/5% chance and twentieth-copy guarantee are reopened, not an additional settled rule. Peerless remains finished equipment only and never an ordinary progression requirement.

## Mined and gathered world materials

Every mined or hand-gathered geological material is one exact named normal/green stack. It has no Poor, Rare, species, or source-world variant. Source history can still say where the player found it, but that history never fragments the stack or changes its strength.

| Access | Initial material groups | Yield from one placement |
|---|---|---:|
| Hand gathering | Sand, Clay, Gravel, Salt crust, Ochre | 2 units, then depleted |
| Pick level 1 · Rock Pick | Rubble; Granite, Limestone, Sandstone, Slate; Iron, Copper, Tin; Coal | Common node: 3 pulls of 2 units |
| Pick level 2 | Basalt, Marble, Quartz; Silver, Gold, Mercury; Sulfur, Alum, Saltpeter | Uncommon node: 2 pulls of 2 units |
| Pick level 3 | Obsidian, Adamant, Rift-glass | Rare node: 2 pulls of 1 unit |

The upgraded-tool recipes and individual finished-item or foundation recipes are intentionally not set on this page. The shared first-pass processing ratios are settled below; the later recipe and facility pass will connect them to complete consumer lists and unlock costs.

## Geological placement in a generated world

Each world receives a mineral-node budget of:

> **max(3, round(passable land tiles ÷ 28)).**

Each ordinary node slot chooses only among materials supported by its resolved region. The starting rarity weights are 70% common, 25% uncommon, and 5% rare.

Written guarantees depend on what the player named:

- **Ground declaration:** at least one meaningful entry-connected region uses that ground. It occupies at least one generated region and at least 20% of passable ground, with a visible example within 3–8 movement steps of entry.
- **Liquid declaration:** at least one entry-connected shoreline or otherwise safely observable body uses that liquid. Its topology and depth remain generated.
- **Base-resource declaration:** at least one eligible, entry-connected harvest source appears within 3–8 movement steps of entry. A source is a useful cluster, not a token placement: two common nodes, two uncommon nodes, one rare node, or one hand-gathering placement according to the named material.
- **Ecological-material request:** pressures compatible anatomy and habitat; it does not promise a named species or a guaranteed drop.

A guaranteed resource source counts against the ordinary node budget and keeps each placement's ordinary yield; it is not a bonus cache. At the first-pass yields above, a common source therefore contains 12 units, an uncommon source 8 units, a rare source 2 units, and a hand-gathered source 2 units. The first placement is 3–8 movement steps from entry; when the source has a second node, it is in the same region and no more than 4 passable steps from the first. The exact distance inside those bands, safe route shape, hazards, and required tool remain part of the generated result. Before Binding, the quote distinguishes a presence guarantee from a habitat pressure and names any tool requirement the Binder already knows.

An advanced node may exist before the player owns the required Pick. Look names the required Pick level. Trying the wrong or insufficient tool costs no turn and does not reduce the node.

## World sizes

| Generated size | Starting weight | Player-facing scale |
|---|---:|---|
| 12×12 | 10% | Small |
| 15×15 | 25% | Compact |
| 18×18 | 40% | Ordinary |
| 26×26 | 20% | Large |
| 36×36 | 5% | Vast; exactly four times the area of an 18×18 world |

These are generation weights before an explicit written size pressure modifies the result. Every size keeps comparable useful decisions per minute: node, creature, site, return-route, and stability budgets scale with passable area rather than leaving a Vast world mostly empty. Every mandatory route and written guarantee remains in the entry-connected traversal graph.

## Regional arrangements

Arrangement controls the large-scale shape of the land. It is separate from which actual ground, water, weather, plants, resources, creatures, and sites fill the world.

| Arrangement | Starting weight | Concrete starting rule |
|---|---:|---|
| Homogeneous | 10% | Exactly one ground composition throughout |
| Dominant | 30% | Two ground types on 12×12 and 15×15 worlds; three on larger worlds. The main type fills 75%. |
| Banded | 15% | 2, 2, 3, 4, or 5 bands across the five world sizes. Every band is at least 3 tiles wide. |
| Patchwork | 15% | 3, 4, 5, 7, or 9 patches across the five world sizes. |
| Clustered | 15% | 2, 2, 3, 4, or 5 major clusters across the five world sizes. |
| Gradient | 10% | Two endpoint ground types with 3, 3, 4, 6, or 8 transition bands across the five world sizes. |
| Fractured | 5% | 2, 2, 3, 4, or 5 regions across the five world sizes, divided by one-tile breaks on the first three sizes and one-to-two-tile breaks on the last two. |

Every arrangement must still produce a start-connected playable world. Impossible environmental combinations are resolved rather than causing the entire world to be rejected:

1. Use an authored transformation when the pair has one, such as an approved rain-and-miasma result.
2. Otherwise total the resolved written and generated pressure strength supporting each candidate; the stronger candidate appears.
3. If support is exactly tied, use a stable hash of the frozen Page, world seed, and facet ID. Reloading cannot change the winner.
4. If two directly written guarantees cannot coexist, the pre-Bind preview names which request will dominate and which will remain an influence rather than quietly promising both. The player may edit or accept that result.

The selected or transformed condition is saved in the world receipt. Later generation reads that saved result instead of resolving the conflict again.

## Harvesting controls and turn costs

The basic Rock Pick, Axe, and Scythe are exact owned field tools in the opening expedition kit. They are packed in a dedicated three-place tool roll, one Pick, one Axe, and one Scythe, rather than consuming the item or Field Kit spaces meant for remedies, Pages, and other useful supplies. A higher tier replaces the lower tier in that tool-class place. The opening loadout packs all three by default, but the tools remain real owned expedition objects rather than invisible account-wide capabilities. Holding the centre of the movement arrows opens quick-use or Field Kit items. Holding Interact opens the field-tool selector containing only packed tools. Both holds use a 0.40-second threshold.

Opening either menu, choosing or changing a tool, cancelling, selecting the wrong tool, lacking the required level, targeting something that moved, encountering stale state, or failing custody costs 0 turns and changes nothing. Every successful harvest hit costs exactly 1 world turn.

The active field-tool preference persists between expeditions and through a cold relaunch. At expedition start it becomes active only if that exact tool is packed; otherwise the game clears the active choice and explains why. Underfoot passable plants and explicit loose-earth gathering placements use Interact. An adjacent blocking trunk or mineral node uses the movement direction facing that placement. Ordinary movement never harvests a plant accidentally.

Interaction ownership is deterministic. An active encounter owns combat input. A traveller, site, portal, or authored hazard interaction takes precedence over harvesting on the same tile. A direction toward a living creature never becomes an accidental tool swing. The visible action label always names the action that will occur; an ambiguous or stale target refuses for zero turns.

| Harvestable placement | Required tool | Successful work and yield |
|---|---|---|
| Low or groundcover plant | Scythe level 1 | 1 hit · 1 unit |
| Medium ordinary plant | Scythe level 1 | 1 hit · 2 units |
| Tall or tough ordinary plant | Scythe level 2 | 1 hit · 3 units |
| Explicitly dangerous harvestable plant | Scythe level 3 | 1 hit · 4 units; its separately disclosed danger still applies |
| Small softwood trunk | Axe level 1 | 1 hit · 2 Logs |
| Mature softwood or small hardwood trunk | Axe level 2 | 2 hits · 5 Logs total |
| Large hardwood, dense, or resinous trunk | Axe level 3 | 3 hits · 9 Logs total |

Multiple-hit trees save their completed hits. Leaving, returning, backgrounding, or relaunching cannot restore work already completed or grant the yield twice.

## Canopy and discovery

| Tree size | Saved crown footprint |
|---|---|
| Small | Five-tile cross |
| Mature | 3×3 square · 9 tiles |
| Large | Radius-two diamond · 13 tiles |

A sight line can pass through one canopy tile. A second consecutive canopy tile conceals tiles beyond it. While the party is beneath a canopy, its own tile and the eight adjacent tiles receive the local canopy exception before that same rule continues outward. This removes canopy concealment only; it does not bypass other sight restrictions. Foreground art fading does not reveal fogged or otherwise concealed content.

The final successful Axe hit removes only that trunk's own crown footprint. An overlapping crown from another standing tree remains.

Once a feature has been fully revealed, its normal minimap record remains revealed permanently. Canopy may later cover it in the main world view, but cannot restore fog or erase a known resource, creature, site, hazard, or portal marker.

The accepted three-quarter view targets trees at their reachable trunk base: use the selected Axe, valid-base highlight, “Chop tree” action label, and trunk impact. Art overlap does not change the footprint, turn cost, or tool requirement. Water uses local bed/surface heights; legal ground connections govern movement between elevations. Exact art sizes and fade timing follow the bounded in-game proof.

## Aquatic and flying habitat boundaries

Both shallow and deep water support aquatic creatures. Shore and shallow water can also support amphibious or crocodile-like creatures when their generated body plan supports movement between water and land. Flying creatures may cross ground and water; they do not receive a universal perch requirement. Their actual food, nesting, weather, and body-plan relationships belong to the upcoming creature-generation pass.

## Sorting Rubble at Noll's Recycler

Rubble is one ungraded normal/green inventory stack, but each unit retains its hidden source-region batch so the Recycler can return only materials that truly existed there.

| Rule | First-pass value |
|---|---|
| Input | Any even quantity from 2 to 6 Rubble from one retained source-region batch |
| Access | Recycler level 1, the initially built Recycler |
| Additional cost | 0 Essence and no world turn |
| Base output | 1 mined-material unit for each 2 Rubble |
| First output | 100% common local material |
| Each later output | 75% common local material; 25% uncommon local material |
| Rare bonus | 5% chance for one additional rare local material when sorting at least 4 Rubble; at most one bonus per transaction |

If the source region has no uncommon material, the second unit is common. If it has no rare material, the bonus cannot occur. The common, uncommon, and rare pools contain only materials in that exact source-region receipt.

The ordinary inventory still shows one Rubble stack. Inside the Recycler, retained batches are grouped by source world. The oldest eligible batch is selected by default, and the player may choose another before opening the preview.

The preview freezes the result for the exact selected units. Confirming consumes exactly that Rubble and grants the previewed materials exactly once. Cancelling, refusing, backgrounding, or relaunching never rerolls the preview. A full destination, stale stock, changed batch, or failed save spends nothing and grants nothing. Because a common Rubble source yields six units, all six can be processed as one transaction without leaving an unusable remainder.

## Nearby finds after an ordinary encounter

An ordinary victorious encounter has one frozen 12% chance to reveal one habitat-appropriate object marked **Found nearby**. This is a search of the surrounding region, not an extra body part. It may occasionally give the player a sample from terrain they could see but could not yet safely reach or harvest.

When the roll succeeds, the source region builds a candidate pool from its real unplaced loose finds and harvest materials. The candidate rarity weights are 75% common, 20% uncommon, and 5% rare; a tier is skipped when the region has no eligible object in it. The result can never be a unique or story item, Page, Sigil, Mote, site reward, guardian reward, apex reward, or another creature material.

The roll belongs to the exact encounter ID and is frozen before the victory reward appears. Reloading, backgrounding, or leaving and returning cannot reroll it. If no eligible regional object exists, no nearby find is awarded and the normal encounter rewards remain unchanged.

## Where processing belongs

There is no universal processing station and no return of the standalone Workshop. Each transformation belongs to the existing specialist whose work makes it easiest to understand.

| Processed material or action | Source | Owner and place |
|---|---|---|
| Sort Rubble into region-supported finds | Rubble from one retained region batch | Noll · Recycler |
| Make a named metal Ingot when a real recipe needs smelted metal | Exact named solid smeltable metal | Halloway · Blacksmith |
| Make ordinary Glass | Sand or Quartz with the recipe's named fuel or flux | Halloway · Blacksmith furnace |
| Make Leather | Hide or Skin | Corrin · Tannery |
| Make Cord or Cloth | Exact eligible Plant Fibre | Corrin · Tannery |
| Make Planks or recipe-specific Hafts | Exact eligible Log | Fen · Bowyer |
| Make Pulp or Paper | Exact eligible fibrous plant stock | Isolde · Scriptorium |
| Make named prepared extracts | Exact eligible plant or creature substance | Nessa · Apothecary |
| Dress named structural stone when a later recipe needs it | Exact named stone | Grimmond · Deep Works |
| Make writing pigments and prepared ink | Exact eligible mineral or botanical colour source | Isolde · Scriptorium |

The processed output keeps a recognizable identity. There is no universal Metal, Reagent, Toxin, or Prepared Extract item. Every process declares exactly one quality behavior:

- **Preserve:** Leather retains the selected Hide or Skin's creature-material quality, inherited colour, and source detail. One batch cannot mix quality bands.
- **Standardize:** Glass, refined named metals, Planks, Hafts, Pulp, Paper, Cord, Cloth, pigments, and writing ink are ungraded processed stock. Their exact raw source and colour remain in the batch receipt where relevant, but the output does not invent creature-material quality.
- **Recipe-defined:** a named extract has an authored potency calculation and disclosure. It does not inherit a generic quality multiplier unless that exact recipe says it does.

Quality is applied once when the final stat-bearing item is calculated; processing never multiplies it a second time. Pelt remains Pelt unless a later recipe has a real need for a distinct cured form. Rift-glass remains Rift-glass rather than becoming ordinary Glass.

Auber's Distillery keeps its separate Essence and Core work. Sela's Wayfarer's Table keeps field packing, flora knowledge, and organic-yield work. Armoury and Weaponsmith recipes may consume processed stock but do not duplicate its general production.

The first-pass conversion rules are below. Each is one immediate Cottage transaction and costs no Essence unless the finished recipe or a later explicitly magical process names an Essence cost. A common finished recipe may require at most one mandatory processing step; a second is reserved for an exceptional or capstone item. Opening recipes and foundations may use raw Logs, named stone, and plant fibre so a later specialist never becomes a retroactive prerequisite.

| Process | First-pass input | First-pass output |
|---|---|---|
| Smelt a named solid metal when a real recipe requires it | 2 matching raw metal + 1 Coal | 1 matching named Ingot |
| Make ordinary Glass from bulk material | 2 Sand + 1 Coal | 1 Glass |
| Make clear Glass from crystal | 1 Quartz + 1 Coal | 1 Glass |
| Make Leather | 2 Hide or Skin of one quality band + 1 Salt | 1 Leather of that band |
| Make Cord | 2 eligible Plant Fibre | 1 Cord |
| Make Cloth | 4 eligible Plant Fibre | 1 Cloth |
| Make Planks | 1 eligible Log | 2 matching Planks |
| Make a Haft | 1 eligible Log | 1 matching Haft |
| Make Pulp | 2 eligible fibrous plant units | 2 Pulp |
| Make Paper | 2 eligible fibrous plant units | 4 Paper sheets |
| Cut a named Stone Block | 2 matching named stone | 1 matching named Stone Block, such as a Granite Block |
| Prepare a writing pigment | 1 eligible mineral or botanical colour source | 4 measures of that pigment |

Named extracts do not use a universal conversion ratio; each one is the preparation recipe itself. Rift-glass cannot be converted into ordinary Glass. A process is promoted only with at least two real consumers or one broadly reused consumer family, so these ratios do not authorize empty intermediate stock.

Equipment and other visibly material-led gear preserve separate colour regions for their selected visible
components. Standardized recognition-critical supplies, including potions and remedies, keep their authored
colour so two functionally different supplies remain easy to distinguish at a glance.

## Stack lots and exact transactions

The compact stack is the browsing surface, not permission to erase meaningful differences underneath it.

- Choose the visible material stack first.
- Show **Choose source** only when source measurements, colour, provenance, price, or output would change.
- Default to the oldest eligible units only when every eligible unit produces the same result.
- Freeze exact unit IDs, quantities, source lots, contributions, output appearance, price, source and destination in the quote.
- A multi-unit socket may combine source lots only when one lot lacks enough units. The preview lists every contributing lot and uses a quantity-weighted average of the relevant source measurement.
- Return loss, trade, processing, crafting, and recycling use the same exact-lot rule. No system independently picks a different unit from the visible stack.

Mined, flora, and creature material stacks are slot-free in the Field and Storehouse. Neither one visible stack nor each unit inside it consumes an item slot. Item slots remain for equipment, consumables, Pages, Curios, and other discrete belongings; a material cannot be moved into Waiting merely because item slots are full.

When Expedition Return recovers only part of a material stack, protected outbound units return first. Newly gathered units are partitioned by a deterministic ordering of the exact run ID, exit turn, stack identity, and unit ID, then frozen in the Return receipt. Inventory order cannot bias which source lot survives, and replay or relaunch cannot choose a more valuable unit.

The player never navigates source-lot detail for an outcome-neutral operation. This keeps generated provenance meaningful without turning every ordinary recipe into inventory bookkeeping.

## Old saves and retired generic materials

Migration never guesses a physical identity:

1. Convert an old holding directly only when its receipt proves the exact new material.
2. Keep an ambiguous holding as a visible `Legacy` stack with its old name, quantity, value, and receipt.
3. Compatible legacy recipes may consume that stack until it is exhausted.
4. The Trading Post may buy it at its preserved old value, and the Recycler may offer a previewed conservative exchange when no legacy consumer remains.
5. A Legacy stack never satisfies a new physical category by inference and never receives invented species, colour, quality, or world provenance.

Existing six-band creature stock maps deterministically when no exact receipt supports recalculation:

| Existing material band | New creature-material band |
|---|---|
| Rough | Poor |
| Standard | Common |
| Fine | Rare |
| Superior | Rare |
| Exceptional | Exceptional |
| Peerless | Exceptional |

Peerless is not retained as a raw-material band; it belongs only to a finished item. Existing world or flora
stock loses no value when its visible quality split is removed. Its old band and sale value remain on the source
lot receipt for legacy trade or exchange, while crafting treats the resolved physical material as ungraded. Exact
Pulp and Resin can enter their matching ungraded stacks. Generic Timber, Fibre, Toxin, or Reagent remains Legacy
unless its receipt proves the exact Log, Plant Fibre, or named physical substance it should become.

The compatibility bridge remains until every supported save can either use or deliberately exchange every retained unit.

## Vocabulary used in the economy

The game keeps three unrelated ideas visibly distinct:

- **Creature-material quality:** Poor, Common, Rare, Exceptional.
- **Regional abundance:** plentiful, occasional, scarce.
- **Market value tier:** staple, valuable, precious, extraordinary.

Gold can therefore be an ungraded normal/green material while belonging to the Precious market tier. The interface never labels it “Common-quality Gold.”

## First-pass material prices and affordability

Raw-material price is based on the physical material the player owns, not on a hidden recipe property or species name.

| Material class | Cottage sell value per unit | Trading Post buy price per unit |
|---|---:|---:|
| Hand-gathered earth, ordinary fibre, common Log, Rubble | 1 Gold | 2 Gold |
| Common stone, common metal, common plant part | 2 Gold | 4 Gold |
| Uncommon mineral, uncommon metal, reactive plant part | 6 Gold | 12 Gold |
| Rare mineral or unusual metal | 18 Gold | 36 Gold |
| Creature Hide, Skin, Pelt, Down, Feather, Fin | 3 Gold at Common quality | 6 Gold at Common quality |
| Creature Scale, Plate, Chitin, Shell, Quill, Bone, Fang, Claw, Tusk, Horn | 4 Gold at Common quality | 8 Gold at Common quality |
| Creature Oil, Venom, or Ichor | 5 Gold at Common quality | 10 Gold at Common quality |

Poor, Common, Rare, and Exceptional creature material use market multipliers ×0.5, ×1, ×2, and ×4, rounded up to a minimum of 1 Gold. Species, inherited colour, world, and source measurements do not silently alter the ordinary raw-material price. A special authored merchant request may quote a different price, but it must name that request and freeze it before commitment.

Trading Post stock uses the displayed buy price. Selling uses the displayed sell value. Buying back an ordinary material therefore costs twice its ordinary sale value; no hidden mood, random appraisal, or source-lot ordering changes that ratio. Finished equipment and authored curios keep their own item prices rather than inheriting this raw-material table.

A closed buy → process or craft → sell loop cannot return as much Gold as it cost unless an authored commission
explicitly advertises that exception. The ordinary resale value of an output is capped below the visible purchase
cost of all consumed inputs, and Recycler salvage never returns more recorded material than the item contains.
This prevents infinite Gold without reducing the value of materials the player actually gathered.

The source quantities above are a balance yardstick, not a requirement that the player already knows direct resource Writing. Opening facilities use broadly hosted materials and should be reachable in roughly two ordinary expeditions without a later Sigil. Once direct resource Writing is learned, no early material line costs more than one written common source, a middle facility should take two to four targeted expeditions, and a late or capstone facility four to six. No single middle or late material line costs more than two written uncommon or two written rare sources without an explicitly exceptional reason. Essence and campaign gates may still matter, but raw-material quantities cannot disguise excessive grind. Every exact station and recipe receives a follow-up affordability pass against these limits before its material-overhaul slice ships.

## Canonical transaction examples

These examples are acceptance rules, not optional illustrations:

1. Two generated fish species contribute Rare Armoured Fish Scales. They appear as one `Rare Armoured Fish Scales` stack with two source lots beneath it. If colour or source measurement changes a crafted result, the recipe shows **Choose source**; otherwise it uses the oldest eligible units.
2. Common and Exceptional Tough Rawhide remain separate stacks. A recipe quoting Common never consumes Exceptional, even when the Common stack becomes insufficient after the preview.
3. Sand, Gold, and Granite never display quality, never open a quality picker, and never receive a species modifier.
4. A partial Expedition Return partitions every exact carried unit between recovered and lost. Protected outbound units return first; newly gathered units use the frozen deterministic partition rather than inventory order. The two sides add back to the carried quantity, and replay grants neither side twice.
5. Selling two units, buying one unit, crafting with three units, processing a batch, or recycling one item each freezes the exact source units and destination before commitment. A stale quote changes nothing.
6. Leather made from Rare Hide remains Rare Leather, while Glass, Planks, Cord, Cloth, Pulp, Paper, pigment, ink, and named metal Ingots are ungraded. No process applies the same quality multiplier twice.
7. Ambiguous old stock remains visibly Legacy stock. It can use an explicit legacy recipe, be sold at its preserved value, or accept a quoted conservative Recycler exchange; it never becomes a new subtype or quality through guessing.
8. After a cold relaunch, quantities, quality stacks, source lots, selected transaction, pending Return result, trade offer, construction history, and Peerless progress are the same logical state.

## Coherence and play-feel audit

| Risk found in the combined design | Resolution in this first pass |
|---|---|
| Hidden properties could make an unrelated object satisfy a recipe. | Physical family, type, and subtype alone decide eligibility. Measurements change only a valid result. |
| Quality on stone, metals, Sand, and ordinary plants would create bookkeeping without an interesting choice. | Only creature materials use the four raw-material bands. Geological and ordinary flora stock is ungraded. |
| Species-specific stacks could turn a generated ecology into inventory clutter. | Species, colour, values, and history live in source lots beneath the physical stack and open only when they change a decision. |
| A written resource could technically succeed with one token unit. | The guarantee reserves a useful cluster with a disclosed first-pass yield and cannot be overwritten by later placement. |
| Processing could become compulsory busywork or require a late specialist for an opening recipe. | Ordinary work uses at most one mandatory process; opening foundations may use raw stock; an intermediate exists only with two consumers or one broadly reused family. |
| Larger worlds could mean only more empty walking. | Resource, creature, site, stability, and return-route budgets scale with passable area. |
| Dense canopy could be cosmetic, or could erase information the player had already earned. | It can genuinely conceal the main view, while revealed minimap records remain known. |
| Tool shortcuts could cause accidental harvests, attacks, or lost turns. | Input priority is explicit; menus, mistakes, stale targets, and unavailable tools cost zero turns. |
| Packing three required harvesting tools could consume the spaces meant for actual expedition choices. | One Pick, one Axe, and one Scythe use a dedicated tool roll; remedies, Pages, and Field Kit items keep their own capacity. |
| Two impossible written conditions could produce a hidden winner or a false guarantee. | Approved transformations resolve first; otherwise total pressure strength decides, stable receipt hashing breaks a tie, and the pre-Bind preview discloses any written request that becomes influence instead of a guarantee. |
| Rubble sorting or nearby finds could become a reloadable source of rare stock. | Results are frozen to the exact transaction or encounter and have strict local candidate and reward exclusions. |
| Special processing could produce empty intermediate stock. | No process is promoted until its real consumer path is named. |
| Buying, processing, and reselling could create infinite Gold. | Ordinary output resale stays below purchased input cost; only an explicit commission may break that rule. |
| Old stock could be guessed into a more valuable subtype or silently lose its former value. | Exact receipts migrate; ambiguous stock stays visibly Legacy; removed flora quality survives as legacy lot value rather than recipe power. |
| Opening construction could accidentally depend on a resource-targeting Sigil learned later. | Opening costs use broadly hosted stock and the two-expedition target does not assume direct resource Writing. |

The resulting play loop is deliberate rather than automatic: write toward a useful region, read the terrain,
pack the right tool, gather recognizable stock, choose when a meaningful source difference matters, and make an
item whose preview explains the consequence. Randomness can provide discovery and delight, but never replaces a
player's confirmed material, quality, destination, or guaranteed written result.

## What remains for the next design passes

The following subjects are intentionally not filled with guessed numbers here:

- generated creature body plans, body-part availability, species ecology, encounter makeup, and creature-to-drop quantities;
- complete flora species and harvest catalogues beyond the size-and-tool rules above;
- Sigil acquisition order, teachable land vocabulary, and clue progression;
- every recipe's exact ingredients, output statistics, station tier, and unlock;
- the station-by-station affordability pass and any justified exception to the first-pass material price table;
- upgraded tool recipes and their campaign unlocks;
- the full compatibility matrix for combined environmental pressures; and
- final parallax-world visual assets and geometry.

Those are separate conversations. Adding numbers for them here would make this page look complete by quietly deciding systems Aimee has not covered yet.
