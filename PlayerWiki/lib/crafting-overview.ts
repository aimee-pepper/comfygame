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
  currentGrade: 'The live 0–100 grade is separate from the six properties. It averages each contributing trait’s distance from 50, multiplies that extremity by 85, adds up to 25 from Lustre, then clamps the result to 0–100. Because unusually low traits can raise this grade, it must not become the new four-band quality formula.',
  intended: 'Keep every concrete property derived from the source creature, plant, or World material. Use physical family/type/subtype for recipe eligibility. Use Poor, Common, Rare, or Exceptional quality to scale the selected material’s previewed contribution to the finished item. The exact per-property, per-component stat conversion still needs to be settled with Aimee before implementation.',
  currentExceptions: 'Current creature and Flora harvests are morphology-derived. Trading Post supplier samples instead synthesize property ranges, and some Recycler returns use fixed property records. Those paths must emit or preserve canonical material receipts rather than inventing unrelated values.',
} as const;

export const materialCustodyFlow = [
  ['Field and combat rewards', 'Current holdings mix counted resources with individual, source-bearing samples.', 'Receive a recognizable physical type or subtype immediately, with species, colour, world, and inherited values retained in expandable detail.'],
  ['Expedition Return', 'The return can divide counted resources and exact samples through different paths.', 'Freeze one quantity outcome for every precise subtype and quality stack. Recovered plus lost must equal the exact carried amount.'],
  ['Storehouse', 'World stock and creature samples are not yet one complete material inventory.', 'Default-stack by precise subtype plus quality. Materials never consume item slots; expanding a stack shows its species-specific items and sources.'],
  ['Trading Post', 'Exact samples use hidden traits in their price and merchant stock.', 'Buy and sell an exact subtype, quality band, and quantity. Resold stock keeps its band and species/source history.'],
  ['Crafting pickers', 'Several makers select exact samples by numerical trait thresholds.', 'Recipes list broad, specific, or precise physical categories. Where quality affects the result, the player deliberately chooses the exact stack and quantity.'],
  ['Recycler', 'Dismantling returns exact recorded samples or fixed salvage.', 'Return the subtype, quality, species-specific items, and quantity in the construction receipt. Older fixed salvage must migrate losslessly through a published four-band mapping; it must never silently default to a made-up grade.'],
  ['Cold relaunch', 'Old and new custody forms can coexist in a save.', 'Every stack, quantity, source-history link, pending return, trade line, and construction receipt reloads exactly once.'],
] as const;

export const qualityRules = [
  ['Poor', 'White resource band; separate stack.'],
  ['Common', 'Green resource band; separate stack.'],
  ['Rare', 'Blue resource band; separate stack.'],
  ['Exceptional', 'Purple resource band; separate stack.'],
] as const;

export const coatingLifecycle = {
  current: 'The current combat implementation consumes a weapon coating on the next eligible successful strike.',
  intended: 'Every weapon coating lasts for exactly one world excursion. It is bound to the chosen weapon and active world, survives travel, encounters, backgrounding and cold relaunch in that same excursion, and ends only when that excursion ends. It is never consumed merely because one strike, turn, encounter, or amount of real time passed.',
  migration: 'If an older save contains a live prepared coating in an active encounter, preserve it on that exact weapon for the remainder of that same excursion. Do not create a coating from inventory and do not carry one into a later world.',
} as const;

export const starterRuneFlow = {
  current: 'A fresh campaign currently knows 12 compound symbols and 15 source symbols and owns three starter World Pages: Open Flats, Rainwashed Shore, and Stone Hollow.',
  intended: 'A new campaign begins with no known runes. Its first excursion is a broadly generated, frozen introductory world with Illumination and Sun guaranteed on a safe unavoidable path. Rune knowledge survives return, defeat, interruption, and cold relaunch. After both discoveries return home, Writing teaches Illumination as the subject and Sun as its source, then the player joins them and binds the first player-authored world. Every unwritten facet of that world remains generated.',
  recovery: 'Leaving before both discoveries never deadlocks the campaign. The same frozen introductory world remains available, already learned rune knowledge stays learned, and the missing discovery remains safely reachable until collected. The introductory route does not depend on voluntary return or a loss-prone haul.',
  legacy: 'Existing campaigns keep every known rune and owned World Page. Nothing is revoked, duplicated, or replaced during migration.',
} as const;

export const materialPricing = qualityRules.map(([band]) => [band, 'Exact price will be set with the material and economy tables.'] as const);

export const canonicalStackExample = 'Rare Armoured Fish Scales × 3';

export const materialIdentityHierarchy = [
  ['Broad category', 'Scales', 'A flexible recipe can accept several physically related scale types.'],
  ['Type', 'Fish Scales', 'A narrower recipe accepts fish-scale subtypes but not every scale.'],
  ['Subtype', 'Armoured Fish Scales', 'An advanced recipe can require this materially distinct subtype.'],
  ['Quality', 'Poor, Common, Rare, Exceptional', 'Creates the default separate stacks within each subtype.'],
  ['Species-specific item', 'Armoured scales from one generated fish species', 'Lives inside its subtype-and-quality stack while retaining colour, values, source, and history.'],
] as const;

export const inventoryViews = [
  ['Default', 'Subtype + quality', 'Rare Armoured Fish Scales stack together; expand the stack to inspect each species-specific item.'],
  ['Material', 'Category, type, or subtype', 'Browse related physical materials without merging their owned stacks.'],
  ['Quality', 'Poor, Common, Rare, Exceptional', 'Compare the grades available for deliberate crafting selection.'],
  ['Origin', 'Species, source world, or recent acquisition', 'Find the exact units and inherited colours behind a stack.'],
] as const;

export const progressionPlan = [
  ['Harvesting tools', 'Better Picks, Axes, and Scythes let the player collect increasingly difficult metals, trees, and plants. Advanced resources may exist before the player can harvest them.'],
  ['Processing facilities', 'Raw materials become a modest set of useful intermediates such as ingots, glass, leather, cloth, cord, planks, and prepared extracts. The exact list and owners remain under discussion.'],
  ['Facility levels', 'Upgrading a facility opens later processing and recipe tiers instead of preventing advanced worlds from generating.'],
  ['Recipe tiers', 'Later recipes can ask for narrower or precise material subtypes and produce stronger results.'],
  ['World Writing', 'Players can directly call at least some ground, liquid, base resources, world sizes, and ecological material pressures such as Chitin. Unwritten facets remain generated.'],
] as const;

export const worldGenerationPlan = [
  ['Ground layout', 'Choose an arrangement such as uniform, striated, scattered, clustered, graded, or fractured, then fill its regions with granular ground types. Final names and weights will be discussed with Aimee.'],
  ['Ground and liquid types', 'Use multiple recognizable dirt, sand, stone, mineral, and liquid types. Granite regions can host Granite; Sand can become a glassmaking input.'],
  ['Flora', 'Terrain, light, atmosphere, weather, water, and temperature all constrain what can grow. Trees gain real canopy and trunk behavior.'],
  ['Creatures', 'Readable body plans and habitat rules support aquatic, land, amphibious, flying, and hybrid forms. Anatomy determines useful material types and subtypes.'],
  ['Environment', 'When condition candidates are incompatible, temperature or another relevant pressure deterministically selects one; the world itself is not rejected. Compatible authored combinations may transform, such as rain and miasma becoming acid rain when that rule is approved.'],
  ['World size', 'Writing can eventually request smaller or larger worlds. Exact dimensions and costs will be discussed with Aimee.'],
] as const;

export const incrementalDelivery = [
  ['One useful path at a time', 'A first slice can take one canonical material from a current producer through Field acquisition, Return, Storehouse, and one useful recipe or service.'],
  ['Legacy compatibility', 'Untouched buildings may keep their current rules until their own slice is replaced. Their current limitation is shown honestly instead of delaying every update.'],
  ['Safe migration', 'Each slice migrates only the stock and receipts it owns, idempotently and without loss, duplication, silent quality changes, or unreadable saves.'],
  ['Continuous publication', 'The Wiki changes with every delivered slice so implemented and intended behavior never blur together.'],
] as const;
