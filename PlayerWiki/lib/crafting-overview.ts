export const materialPropertyProblems = [
  ['Hardness', 'Currently used as a hidden eligibility threshold by several recipes.', 'Family/type/subtype decides eligibility; Hardness remains and contributes to appropriate concrete item stats.'],
  ['Density', 'Currently used as a hidden eligibility threshold for some weights and load-bearing selections.', 'Physical construction decides eligibility; Density remains and contributes to appropriate weight, force, or structural stats.'],
  ['Insulation', 'Currently used as a hidden eligibility threshold for warm layers and several unrelated recipes.', 'A physical lining or insulating material decides eligibility; Insulation remains and contributes to concrete protection or resistance stats.'],
  ['Flexibility', 'Currently used as a hidden eligibility threshold for grips, bindings, and some preparations.', 'A physical grip, binding, cord, cloth, hide, or similar subtype decides eligibility; Flexibility remains and contributes to appropriate handling stats.'],
  ['Lustre', 'Currently used as a hidden eligibility threshold for optical and reflective selections.', 'A physical optical or reflective material decides eligibility; Lustre remains and contributes only to an approved concrete stat or effect.'],
  ['Reactivity', 'Currently used as a hidden eligibility threshold across chemical and magical recipes.', 'A physical reactive ingredient decides eligibility; Reactivity remains and contributes to an approved potency, status, or magical stat.'],
] as const;

export const creatureMaterialPropertyDerivations = [
  ['Hardness', 'Covering material keeps the creature’s exact covering Hardness. Fang and Claw use 70% of total armament; Tusk uses 40%. Bone uses 60% of Bone Density.'],
  ['Density', 'Hard covering uses 60% covering Hardness + 40% Bone Density; soft covering uses 30% coverage. Tusk uses 80% total armament; Fang/Claw use 60% Bone Density. Bone keeps exact Bone Density.'],
  ['Insulation', 'Covering Insulation is covering length × coverage ÷ 100. Armament, Bone, and Ichor currently contribute zero Insulation.'],
  ['Flexibility', 'Covering Flexibility is (100 − covering Hardness) × (0.5 + covering length ÷ 200), floored at zero. Bone uses 60 − half Bone Density, floored at zero.'],
  ['Lustre', 'The creature finish supplies Lustre as shine + schiller. Covering and armament keep it; Bone keeps 40%; Ichor keeps the full value.'],
  ['Reactivity', 'Ichor keeps the creature’s emanation strength as Reactivity. Ordinary covering, armament, and Bone currently contribute zero Reactivity.'],
] as const;

export const floraMaterialPropertyDerivations = [
  ['Hardness', 'Woody tissue × 0.8.'],
  ['Density', 'Woody tissue × 0.6.'],
  ['Insulation', 'Fleshy tissue × 0.7.'],
  ['Flexibility', 'Fibrous tissue × 0.9.'],
  ['Lustre', 'The plant’s exact finish Lustre.'],
  ['Reactivity', 'Chemical defence strength when present, plus 45 for chemosynthetic metabolism, capped at 100.'],
] as const;

export const materialScoreBoundary = {
  currentGrade: 'The current 0–100 grade is separate from the six properties. It averages each contributing trait’s distance from 50, multiplies that extremity by 85, adds up to 25 from Lustre, then limits the result to 0–100. Because unusually low traits can raise this grade, it must not become the new four-band quality formula.',
  intended: 'Keep every concrete property derived from the creature or plant that produced a material. Use physical family, type, or subtype to decide whether it fits a recipe. For a quality-bearing creature part, its physical type supplies half of the role’s Common-quality ceiling, its source measurement supplies the other half, and its selected quality scales that complete value. Components are added before the finished statistic rounds once. Mined and standardized materials such as Sand, Gold, Granite, Glass, and Planks have no quality and use fixed authored contributions.',
  currentExceptions: 'Current creature and Flora harvests derive their values from the body or plant that produced them. Trading Post samples instead generate values from a range, and some Recycler returns use fixed records. The intended system must give those materials values supported by their real source rather than unrelated numbers.',
} as const;

export const materialCustodyFlow = [
  ['Field and combat rewards', 'Current holdings mix counted resources with individual samples that remember their source.', 'Receive mined resources as simple exact-name quantities, flora materials as ungraded physical type/subtype stacks, and creature materials as recognizable physical types or subtypes with quality. Species, colour, world, and inherited values remain available in expanded detail.'],
  ['Expedition Return', 'The return can treat counted resources and individual material samples differently.', 'Decide recovered and lost quantities once for every exact-name mined stack, ungraded flora stack, and subtype-and-quality creature stack. Protected outbound units return first; newly gathered units use a frozen deterministic partition rather than inventory order. Together, recovered and lost equal everything the party carried.'],
  ['Storehouse', 'World stock and creature samples are not yet one complete material inventory.', 'Stack mined resources by exact material and quantity, flora by physical type/subtype, and approved creature materials by precise subtype plus quality. Materials are slot-free and never enter Waiting merely because item slots are full; generated stacks can expand to show species-specific source lots.'],
  ['Trading Post', 'Individual samples use hidden traits to set their price and determine merchant stock.', 'Buy and sell mined resources and ordinary flora by exact material or subtype and quantity, or creature materials by subtype, quality band, and quantity. Resold creature stock keeps its band and species/source history.'],
  ['Crafting pickers', 'Several makers currently choose individual samples by hidden numerical thresholds.', 'Recipes list broad, specific, or precise physical categories. Choose a stack and quantity first. Choose an exact source lot only when its measurements, colour, value, or output change the result.'],
  ['Recycler', 'Dismantling returns recorded construction samples or fixed salvage. It does not currently sort Rubble.', 'Keep gear dismantling exact. Add a separate Rubble process for 2, 4, or 6 units from one source-region batch. Every pair gives one local result; the first is common, later results are 75% common and 25% uncommon, and a four-or-more transaction has one 5% rare-local bonus chance. The preview freezes every result.'],
  ['Closing and reopening the game', 'Old and new forms of material storage can coexist in a save.', 'Every stack, quantity, source-history link, pending return, trade offer, and recorded construction material reloads exactly once.'],
] as const;

export const qualityRules = [
  ['Poor', 'White creature-material band; separate stack within a subtype.'],
  ['Common', 'Green creature-material band; separate stack within a subtype.'],
  ['Rare', 'Blue creature-material band; separate stack within a subtype.'],
  ['Exceptional', 'Purple creature-material band; separate stack within a subtype.'],
] as const;

export const craftedQualityRules = [
  ['0', 'Rough', 'Mostly Poor creature-quality contributions.'],
  ['1', 'Fine', 'The fixed baseline for an ungraded designated socket or a mostly Common result.'],
  ['2', 'Superior', 'Mostly Rare creature-quality contributions.'],
  ['3', 'Exceptional', 'An Exceptional ordinary result.'],
] as const;

export const coatingLifecycle = {
  current: 'Right now, a weapon coating is used up by the next successful strike that can apply it.',
  intended: 'Every weapon coating lasts for exactly one world excursion. It is bound to the chosen weapon and active world, survives travel, encounters, backgrounding and cold relaunch in that same excursion, and ends only when that excursion ends. It is never consumed merely because one strike, turn, encounter, or amount of real time passed.',
  migration: 'If an older save contains an active prepared coating during an encounter, keep it on that weapon for the remainder of the same excursion. Do not create a coating from inventory and do not carry one into a later world.',
} as const;

export const starterRuneFlow = {
  current: 'A fresh campaign currently knows 12 compound symbols and 15 source symbols and owns three starter World Pages: Open Flats, Rainwashed Shore, and Stone Hollow.',
  intended: 'A new campaign begins with no known runes. Its first excursion is a broadly generated introductory world with Illumination and Sun guaranteed on a safe unavoidable path. Those discoveries survive return, defeat, interruption, and closing the game. Once both are brought home, Writing teaches Illumination as the subject and Sun as its source; the player joins them and binds the first world they shape themselves. Everything they did not write remains generated.',
  recovery: 'Leaving before both discoveries never blocks the campaign. The same introductory world remains available, already learned rune knowledge stays learned, and the missing discovery remains safely reachable until collected. This opening journey does not depend on a voluntary return or on bringing home vulnerable cargo.',
  legacy: 'Existing campaigns keep every known rune and owned World Page. Nothing is revoked, duplicated, or replaced during migration.',
} as const;

export const materialPricing = [
  ['Poor', '×0.5 of the creature material’s Common value'],
  ['Common', '×1 of the creature material’s Common value'],
  ['Rare', '×2 of the creature material’s Common value'],
  ['Exceptional', '×4 of the creature material’s Common value'],
] as const;

export const canonicalStackExample = 'Rare Armoured Fish Scales × 3';

export const materialIdentityHierarchy = [
  ['Broad category', 'Scales', 'A flexible recipe can accept several physically related scale types.'],
  ['Type', 'Fish Scales', 'A narrower recipe accepts fish-scale subtypes but not every scale.'],
  ['Subtype', 'Armoured Fish Scales', 'An advanced recipe can require this materially distinct subtype.'],
  ['Quality', 'Poor, Common, Rare, Exceptional', 'Creates separate stacks only for approved quality-bearing creature materials. Mined and ordinary flora materials do not use this level.'],
  ['Species-specific item', 'Armoured scales from one generated fish species', 'Lives inside its subtype-and-quality stack while retaining colour, values, source, and history.'],
] as const;

export const intendedMaterialCatalogue = [
  ['Ground and geology', 'Structural stone', 'Granite, Limestone, Sandstone, Slate, Basalt, Marble', 'Ungraded'],
  ['Ground and geology', 'Loose earth and aggregate', 'Sand, Clay, Silt, Gravel, Rubble', 'Ungraded'],
  ['Ground and geology', 'Common metal', 'Iron, Copper, Tin', 'Ungraded'],
  ['Ground and geology', 'Precious and unusual metal', 'Silver, Gold, Mercury, Adamant', 'Ungraded'],
  ['Ground and geology', 'Crystal and mineral glass', 'Quartz, Obsidian, Rift-glass', 'Ungraded'],
  ['Ground and geology', 'Reactive mineral', 'Salt, Sulfur, Alum, Saltpeter', 'Ungraded'],
  ['Ground and geology', 'Pigment and fuel', 'Ochre, Coal', 'Ungraded'],
  ['Flora', 'Wood', 'Softwood Log, Hardwood Log; denser or resinous wood only when physically useful', 'Ungraded'],
  ['Flora', 'Plant Fibre', 'Stem Fibre, Leaf Fibre, Bark Fibre', 'Ungraded'],
  ['Flora', 'Plant part', 'Leaf, Root, Flower, Spore, Sap, Resin; named physical forms such as Toxic Sap or Irritant Spore', 'Ungraded'],
  ['Creature', 'Skin, Hide, and Pelt', 'Smooth Skin, Aquatic Skin, Membrane, Rawhide, Fur Pelt; tougher or armoured forms where anatomy supports them', 'Poor · Common · Rare · Exceptional'],
  ['Creature', 'Scales', 'Fish Scales, Reptile Scales; Armoured Scales where anatomy supports them', 'Poor · Common · Rare · Exceptional'],
  ['Creature', 'Feathers', 'Flight Feathers, Down, Quills', 'Poor · Common · Rare · Exceptional'],
  ['Creature', 'Shell and Chitin', 'Shell, Chitin, Carapace, Chitin Plate', 'Poor · Common · Rare · Exceptional'],
  ['Creature', 'Hard animal part', 'Bone, Fang, Tusk, Horn, Claw; Hollow or Dense Bone where anatomy supports them', 'Poor · Common · Rare · Exceptional'],
  ['Creature', 'Animal fluid', 'Oil, Venom, Ichor', 'Poor · Common · Rare · Exceptional'],
] as const;

export const inventoryViews = [
  ['Default', 'Exact mined material, flora type/subtype, or creature subtype + quality', 'Sand and Gold each form one simple quantity stack. Stem Fibre is ungraded. Rare Armoured Fish Scales stack together and can expand to show each species-specific source lot.'],
  ['Material', 'Category, type, or subtype', 'Browse related physical materials without merging their owned stacks.'],
  ['Quality', 'Poor, Common, Rare, Exceptional', 'Compare the grades available for deliberate crafting selection.'],
  ['Origin', 'Species, source world, or recent acquisition', 'Find the exact units and inherited colours behind a stack.'],
] as const;

export const progressionPlan = [
  ['Harvesting tools', 'The opening expedition kit contains an owned stone Pick, stone Axe, and stone Scythe in a dedicated three-place tool roll. They do not consume the item or Field Kit spaces used for supplies. Better packed tools replace the lower tier in their class and collect increasingly difficult metals, trees, and plants.'],
  ['Processing facilities', 'Noll sorts Rubble; Halloway owns metal and Glass furnace work; Corrin makes Leather, Cord, and Cloth; Fen shapes Planks and Hafts; Isolde makes Pulp, Paper, pigments, and writing ink; Nessa makes named extracts; Grimmond cuts later named Stone Blocks. Each process arrives with real recipe consumers.'],
  ['Facility levels', 'The basic Blacksmith makes starter gear and improves the Pick and Axe directly from raw stock. Later upgrades open useful processing; Ingot making at T2 alongside specialist buildings is proposed, not settled. T1 recipes remain usable.'],
  ['Recipe tiers', 'Later recipes can ask for narrower or precise material subtypes and produce stronger results.'],
  ['World Writing', 'Players can directly call at least some ground, liquid, base resources, world sizes, and ecological material pressures such as Chitin. Unwritten facets remain generated.'],
] as const;

export const worldGenerationPlan = [
  ['Generation order', 'Resolve size and arrangement, relief and geology, hydrology, climate, derived surfaces, Flora, reserved resource guarantees, then creatures, sites, travellers, hazards, and portals. Later placements cannot overwrite a written guarantee or required route.'],
  ['Ground layout', 'Choose Homogeneous, Dominant, Banded, Patchwork, Clustered, Gradient, or Fractured, then fill the arrangement with recognizable ground types. Homogeneous uses one ground composition throughout; Dominant uses one main composition with smaller inclusions.'],
  ['Ground and liquid types', 'Use multiple recognizable dirt, sand, stone, mineral, and liquid types. Granite regions can host Granite; Sand can become a glassmaking input.'],
  ['Flora', 'Terrain, light, atmosphere, weather, water, and temperature all constrain what can grow. Dense tree canopy can conceal distant features until the party approaches or moves beneath it. Once revealed, a feature keeps its appropriate minimap record even if canopy hides it in the main view again.'],
  ['Creatures', 'Readable body plans and habitat rules support aquatic, land, amphibious, flying, and hybrid forms. Aquatic creatures can use shallow and deep water when their bodies suit that depth. Flying creatures follow relevant feeding, weather, and resting needs; perches are not universally required. Anatomy determines useful material types and subtypes.'],
  ['Environment', 'An approved combined condition resolves first. Otherwise the condition with greater total Page-and-world support appears; an exact tie uses the frozen Page and world seed, so reopening cannot change it. The pre-Bind preview identifies any directly written request that must remain an influence instead of a guarantee. The world itself is never rejected just because two raw conditions conflict.'],
  ['World size', 'Writing can eventually request worlds on the accepted 12×12, 15×15, 18×18, 26×26, and 36×36 size ladder. The later Sigil pass will set acquisition and writing costs.'],
] as const;

export const sourceLotRules = [
  ['Choose the stack first', 'Ordinary inventory stays compact. Source detail is not the first step of every transaction.'],
  ['Open source detail only when it matters', 'Choose source appears only when measurements, colour, provenance, price, or output would change.'],
  ['Use an exact frozen quote', 'The preview owns the exact unit IDs, quantity, contributing lots, result, value, source, and destination.'],
  ['Combine only when needed', 'If one lot cannot fill a multi-unit socket, the selected lots are listed and their recipe-named measurement is averaged by quantity.'],
  ['Keep neutral work quick', 'When every eligible unit gives the same result, the oldest eligible units are used without an extra picker.'],
] as const;

export const processingQualityRules = [
  ['Preserves quality', 'Leather keeps one selected Hide or Skin quality band, colour, and source receipt. A batch cannot mix bands.'],
  ['Standardized and ungraded', 'Glass, named metal Ingots, Planks, Hafts, Pulp, Paper, Cord, Cloth, pigments, and writing ink do not acquire creature-material quality.'],
  ['Recipe-defined', 'A named extract uses that recipe’s disclosed potency rule instead of inheriting a generic material multiplier.'],
  ['Applied once', 'Processing never multiplies quality and then lets the finished recipe multiply the same quality again.'],
] as const;

export const craftedAppearanceRules = [
  ['Equipment and visible gear', 'Every material component region keeps its selected colour, with a consistent silhouette and preserved shading. Quality uses the name highlight and thumbnail border, not a recolouring of the item artwork. A haft, binding, lining, plate, blade, or trim can therefore contribute its own region to the finished object.'],
  ['Potions and recognizable supplies', 'Keep the standardized authored colour used to identify the item at a glance. Ingredient colour does not recolour a potion, remedy, or another supply whose appearance communicates its function.'],
  ['Inventory and history', 'Colour remains source and appearance detail beneath the material stack. It never creates another stack or changes recipe eligibility by itself.'],
] as const;

export const processingConversions = [
  ['Named metal Ingot', '2 matching raw solid metal + 1 Coal', '1 matching named Ingot', 'Halloway · Blacksmith'],
  ['Ordinary Glass', '2 Sand + 1 Coal, or 1 Quartz + 1 Coal', '1 Glass', 'Halloway · Blacksmith'],
  ['Leather', '2 Hide or Skin from one quality band + 1 Salt', '1 Leather of that quality', 'Corrin · Tannery'],
  ['Cord', '2 eligible Plant Fibre', '1 Cord', 'Corrin · Tannery'],
  ['Cloth', '4 eligible Plant Fibre', '1 Cloth', 'Corrin · Tannery'],
  ['Planks', '1 eligible Log', '2 matching Planks', 'Fen · Bowyer'],
  ['Haft', '1 eligible Log', '1 matching Haft', 'Fen · Bowyer'],
  ['Pulp', '2 eligible fibrous plant units', '2 Pulp', 'Isolde · Scriptorium'],
  ['Paper', '2 eligible fibrous plant units', '4 Paper sheets', 'Isolde · Scriptorium'],
  ['Named Stone Block', '2 matching units of one named stone', '1 matching block, such as a Granite Block', 'Grimmond · Deep Works'],
  ['Writing pigment', '1 eligible mineral or botanical colour source', '4 pigment measures', 'Isolde · Scriptorium'],
] as const;

export const materialPriceRules = [
  ['Hand-gathered earth, ordinary fibre, common Log, Rubble', '1 Gold', '2 Gold'],
  ['Common stone, common metal, common plant part', '2 Gold', '4 Gold'],
  ['Uncommon mineral, uncommon metal, reactive plant part', '6 Gold', '12 Gold'],
  ['Rare mineral or unusual metal', '18 Gold', '36 Gold'],
  ['Hide, Skin, Pelt, Down, Feather, Fin', '3 Gold at Common', '6 Gold at Common'],
  ['Scale, Plate, Chitin, Shell, Quill, Bone, Fang, Claw, Tusk, Horn', '4 Gold at Common', '8 Gold at Common'],
  ['Oil, Venom, Ichor', '5 Gold at Common', '10 Gold at Common'],
] as const;

export const legacyMigrationRules = [
  ['Exact receipt', 'Move the holding directly only when its saved receipt proves the exact new material.'],
  ['Ambiguous old stock', 'Keep a visible Legacy stack with its old name, amount, value, and history. Never invent a subtype, species, colour, quality, or world.'],
  ['Use or exchange', 'An explicit legacy recipe may consume it. Otherwise the Trading Post keeps its old value and the Recycler may show a conservative exchange before anything moves.'],
  ['Repeat-safe', 'Running migration or reopening the game cannot convert, lose, or duplicate the same unit twice.'],
] as const;

export const legacyBandMigrationRules = [
  ['Rough', 'Poor'],
  ['Standard', 'Common'],
  ['Fine', 'Rare'],
  ['Superior', 'Rare'],
  ['Exceptional', 'Exceptional'],
  ['Peerless', 'Exceptional'],
] as const;

export const economySafetyRules = [
  ['No ordinary buy-loop profit', 'Buying every input, processing or crafting it, and selling the output returns less Gold than the inputs cost unless an authored commission clearly says otherwise.'],
  ['No invented salvage', 'Recycler output never exceeds the exact materials recorded on the selected item.'],
  ['Gathering still matters', 'The resale cap prevents a shop exploit; it does not reduce the value of materials the player gathered in a world.'],
] as const;

export const writingGuaranteeRules = [
  ['Written ground', 'Creates a meaningful entry-connected region using that ground.'],
  ['Written liquid', 'Creates an entry-connected shoreline or otherwise safely observable body using that liquid.'],
  ['Written base resource', 'Creates one eligible start-connected source: two common nodes, two uncommon nodes, one rare node, or one hand-gathering placement. Its first placement is 3–8 steps from entry; a second node is in the same region within 4 passable steps. The preview names any harvesting tool already known to be required.'],
  ['Written ecological material', 'Pressures compatible habitats and anatomy without promising a named species or guaranteed drop.'],
] as const;

export const conditionResolutionRules = [
  ['Transform when an authored combination exists', 'An approved combined result, such as a future acid-rain rule, resolves before either input tries to erase the other.'],
  ['Otherwise follow the stronger support', 'The candidate with greater total support from the Page and generated world pressures appears.'],
  ['Freeze an exact tie', 'A stable hash of the frozen Page, world seed, and facet decides an exact tie. Reloading cannot reroll it.'],
  ['Disclose a guarantee conflict', 'If two directly written requests cannot both be guaranteed, the pre-Bind preview names which one will dominate and which one remains an influence. The player may edit or accept the Page.'],
] as const;

export const incrementalDelivery = [
  ['One useful path at a time', 'An update can take one real material from gathering through Return and Storehouse into one useful recipe or service.'],
  ['Legacy compatibility', 'Untouched buildings may keep their current rules until their own slice is replaced. Their current limitation is shown honestly instead of delaying every update.'],
  ['Safe migration', 'Each update converts only the affected materials and saved crafting history. Repeating the migration must never lose or duplicate anything, remap the same band twice, or make an old save unreadable.'],
  ['Continuous publication', 'The Wiki changes with every delivered slice so implemented and intended behavior never blur together.'],
] as const;
