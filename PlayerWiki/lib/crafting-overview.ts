export const materialPropertyProblems = [
  ['Hardness', 'A hidden score currently used to decide whether some exact samples can fill a recipe slot.', 'A visible physical slot such as an edge, shell, plate, point, or structural member.'],
  ['Density', 'A hidden score currently used for some weights and load-bearing selections.', 'A visible material category such as a load-bearing stone, metal, bone, plate, or shell.'],
  ['Insulation', 'A hidden score currently used for warm layers and several unrelated recipes.', 'A visible lining category such as pelt, down, cloth, hide, or oil where oil physically makes sense.'],
  ['Flexibility', 'A hidden score currently used for grips, bindings, and some preparations.', 'A visible grip, binding, cord, cloth, hide, or other flexible physical category.'],
  ['Lustre', 'A hidden score currently used for optical and reflective selections.', 'A visible optical or reflective category such as quartz, silver, gold, feather, or quill.'],
  ['Reactivity', 'A hidden score currently used across chemical and magical recipes.', 'A visible ingredient category such as resin, toxin, spore, reagent, oil, venom, or ichor.'],
] as const;

export const materialCustodyFlow = [
  ['Field and combat rewards', 'Current holdings mix counted resources with individual, source-bearing samples.', 'Receive a recognizable physical type or subtype immediately, with species, colour, world, and inherited values retained in expandable detail.'],
  ['Expedition Return', 'The return can divide counted resources and exact samples through different paths.', 'Freeze one quantity outcome for every physical type-or-subtype and quality stack. Recovered plus lost must equal the exact carried amount.'],
  ['Storehouse', 'World stock and creature samples are not yet one complete material inventory.', 'Stack by physical type or precise subtype plus quality. Materials never consume item slots; expanding a stack shows its species/source variants.'],
  ['Trading Post', 'Exact samples use hidden traits in their price and merchant stock.', 'Buy and sell an exact family, quality band, and quantity. Resold stock keeps its band and history.'],
  ['Crafting pickers', 'Several makers select exact samples by numerical trait thresholds.', 'Recipes list broad, specific, or precise physical categories. Where quality affects the result, the player deliberately chooses the exact stack and quantity.'],
  ['Recycler', 'Dismantling returns exact recorded samples or fixed salvage.', 'Return the family, quality, and quantity in the construction receipt. Older fixed salvage must migrate losslessly through a published four-band mapping; it must never silently default to a made-up grade.'],
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
  ['Specific type', 'Fish Scales', 'A narrower recipe accepts fish-scale variants but not every scale.'],
  ['Precise subtype', 'Armoured Fish Scales', 'An advanced recipe requires this materially distinct subtype.'],
  ['Species variant', 'Scales from a generated species', 'Shown inside expanded stack history; it contributes colour and values without creating another item type.'],
  ['Quality', 'Poor, Common, Rare, Exceptional', 'Creates separate stacks within the physical type or subtype.'],
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
  ['Environment', 'Incompatible conditions resolve coherently. Some combinations transform, such as rain and miasma becoming acid rain when that rule is approved.'],
  ['World size', 'Writing can eventually request smaller or larger worlds. Exact dimensions and costs will be discussed with Aimee.'],
] as const;
