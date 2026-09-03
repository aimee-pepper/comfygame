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
  intended: 'Keep every concrete property derived from the creature or plant that produced a biological material. Use physical family, type, or subtype to decide whether it fits a recipe. The accepted calculation combines the recipe component’s stat ceiling, the source creature’s relevant measurement, and the selected biological quality multiplier. Mined materials such as Sand, Gold, and Granite have no quality and use a fixed authored contribution.',
  currentExceptions: 'Current creature and Flora harvests derive their values from the body or plant that produced them. Trading Post samples instead generate values from a range, and some Recycler returns use fixed records. The intended system must give those materials values supported by their real source rather than unrelated numbers.',
} as const;

export const materialCustodyFlow = [
  ['Field and combat rewards', 'Current holdings mix counted resources with individual samples that remember their source.', 'Receive mined resources as simple exact-name quantities. Receive biological materials as recognizable physical types or subtypes, with applicable quality, species, colour, world, and inherited values available in expanded detail.'],
  ['Expedition Return', 'The return can treat counted resources and individual material samples differently.', 'Decide recovered and lost quantities once for every exact-name mined stack and every subtype-and-quality biological stack. Together, those amounts must equal everything the party carried.'],
  ['Storehouse', 'World stock and creature samples are not yet one complete material inventory.', 'Stack mined resources by exact material and quantity. Stack approved biological materials by precise subtype plus quality. Neither consumes item slots; biological stacks can expand to show species-specific items and sources.'],
  ['Trading Post', 'Individual samples use hidden traits to set their price and determine merchant stock.', 'Buy and sell mined resources by exact material and quantity, or biological materials by subtype, quality band, and quantity. Resold biological stock keeps its band and species/source history.'],
  ['Crafting pickers', 'Several makers currently choose individual samples by hidden numerical thresholds.', 'Recipes list broad, specific, or precise physical categories. Where quality affects the result, the player deliberately chooses the stack and quantity.'],
  ['Recycler', 'Dismantling returns recorded construction samples or fixed salvage. It does not currently sort Rubble.', 'Keep gear dismantling exact. Add a separate Rubble process: select a quantity, preview its frozen region-supported results, then receive mostly common local materials with rarer local finds occurring less often. Every mined result remains ungraded, and preview or relaunch cannot reroll it.'],
  ['Closing and reopening the game', 'Old and new forms of material storage can coexist in a save.', 'Every stack, quantity, source-history link, pending return, trade offer, and recorded construction material reloads exactly once.'],
] as const;

export const qualityRules = [
  ['Poor', 'White biological-material band; separate stack within a subtype.'],
  ['Common', 'Green biological-material band; separate stack within a subtype.'],
  ['Rare', 'Blue biological-material band; separate stack within a subtype.'],
  ['Exceptional', 'Purple biological-material band; separate stack within a subtype.'],
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

export const materialPricing = qualityRules.map(([band]) => [band, 'Exact price will be set with the material and economy tables.'] as const);

export const canonicalStackExample = 'Rare Armoured Fish Scales × 3';

export const materialIdentityHierarchy = [
  ['Broad category', 'Scales', 'A flexible recipe can accept several physically related scale types.'],
  ['Type', 'Fish Scales', 'A narrower recipe accepts fish-scale subtypes but not every scale.'],
  ['Subtype', 'Armoured Fish Scales', 'An advanced recipe can require this materially distinct subtype.'],
  ['Quality', 'Poor, Common, Rare, Exceptional', 'Creates separate stacks only for approved quality-bearing biological materials. Mined materials do not use this level.'],
  ['Species-specific item', 'Armoured scales from one generated fish species', 'Lives inside its subtype-and-quality stack while retaining colour, values, source, and history.'],
] as const;

export const inventoryViews = [
  ['Default', 'Exact mined material, or biological subtype + quality', 'Sand and Gold each form one simple quantity stack. Rare Armoured Fish Scales stack together and can expand to show each species-specific item.'],
  ['Material', 'Category, type, or subtype', 'Browse related physical materials without merging their owned stacks.'],
  ['Quality', 'Poor, Common, Rare, Exceptional', 'Compare the grades available for deliberate crafting selection.'],
  ['Origin', 'Species, source world, or recent acquisition', 'Find the exact units and inherited colours behind a stack.'],
] as const;

export const progressionPlan = [
  ['Harvesting tools', 'Better Picks, Axes, and Scythes let the player collect increasingly difficult metals, trees, and plants. Advanced resources may exist before the player can harvest them.'],
  ['Processing facilities', 'Noll sorts Rubble; Halloway owns metal and Glass furnace work; Corrin makes Leather, Cord, and Cloth; Fen shapes Planks and Hafts; Isolde makes Pulp, Paper, pigments, and writing ink; Nessa makes named extracts; Grimmond owns later Dressed Stone. Each process arrives with real recipe consumers.'],
  ['Facility levels', 'Upgrading a facility opens later processing and recipe tiers instead of preventing advanced worlds from generating.'],
  ['Recipe tiers', 'Later recipes can ask for narrower or precise material subtypes and produce stronger results.'],
  ['World Writing', 'Players can directly call at least some ground, liquid, base resources, world sizes, and ecological material pressures such as Chitin. Unwritten facets remain generated.'],
] as const;

export const worldGenerationPlan = [
  ['Ground layout', 'Choose Homogeneous, Dominant, Banded, Patchwork, Clustered, Gradient, or Fractured, then fill the arrangement with recognizable ground types. Homogeneous uses one ground composition throughout; Dominant uses one main composition with smaller inclusions.'],
  ['Ground and liquid types', 'Use multiple recognizable dirt, sand, stone, mineral, and liquid types. Granite regions can host Granite; Sand can become a glassmaking input.'],
  ['Flora', 'Terrain, light, atmosphere, weather, water, and temperature all constrain what can grow. Dense tree canopy can conceal distant features until the party approaches or moves beneath it. Once revealed, a feature keeps its appropriate minimap record even if canopy hides it in the main view again.'],
  ['Creatures', 'Readable body plans and habitat rules support aquatic, land, amphibious, flying, and hybrid forms. Aquatic creatures can use shallow and deep water when their bodies suit that depth. Flying creatures follow relevant feeding, weather, and resting needs; perches are not universally required. Anatomy determines useful material types and subtypes.'],
  ['Environment', 'When two possible conditions conflict, temperature or another relevant pressure chooses which one appears; the world itself is not rejected. Compatible written combinations may transform, such as rain and miasma becoming acid rain when that rule is approved.'],
  ['World size', 'Writing can eventually request worlds on the accepted 12×12, 15×15, 18×18, 26×26, and 36×36 size ladder. The later Sigil pass will set acquisition and writing costs.'],
] as const;

export const incrementalDelivery = [
  ['One useful path at a time', 'An update can take one real material from gathering through Return and Storehouse into one useful recipe or service.'],
  ['Legacy compatibility', 'Untouched buildings may keep their current rules until their own slice is replaced. Their current limitation is shown honestly instead of delaying every update.'],
  ['Safe migration', 'Each update converts only the affected materials and saved crafting history. Repeating the migration must never lose or duplicate anything, change quality, or make an old save unreadable.'],
  ['Continuous publication', 'The Wiki changes with every delivered slice so implemented and intended behavior never blur together.'],
] as const;
