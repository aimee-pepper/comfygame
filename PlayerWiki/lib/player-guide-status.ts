export type GuideStatus =
  | 'Playable now'
  | 'Partly playable'
  | 'Changing in a future update'
  | 'Not playable yet';

export interface CraftingChange {
  name: string;
  current: string;
  accepted: string;
}

export interface CraftingFamilyStatus {
  slug: string;
  name: string;
  status: GuideStatus;
  current: string;
  accepted: string;
  changes: CraftingChange[];
}

export const qualityBands = [
  'Poor',
  'Common',
  'Rare',
  'Exceptional',
] as const;

export const worldMaterialFamilies = [
  ['Rubble', 'Broken ordinary stone.'],
  ['Clay', 'Workable earth and fired stock.'],
  ['Iron Ore', 'Iron-bearing structural stock.'],
  ['Copper', 'Conductive base metal.'],
  ['Silver', 'Pale conductive precious metal.'],
  ['Gold', 'A workable precious material, separate from Gold Coins.'],
  ['Quartz', 'Natural clear crystal, separate from Rift-glass.'],
  ['Obsidian', 'Volcanic glass with a usable edge.'],
  ['Salt', 'Mineral salt used in preparations.'],
  ['Sulfur', 'A volatile yellow mineral.'],
  ['Mercury', 'A liquid-metal ingredient.'],
  ['Adamant', 'Dense, enduring high-order material.'],
  ['Fibre', 'Spun plant and world fibre.'],
  ['Timber', 'Workable structural wood.'],
  ['Pulp', 'Pressed plant and paper stock.'],
  ['Resin', 'Plant adhesive and reactive carrier.'],
  ['Toxin', 'A harmful botanical extract, separate from creature Venom.'],
  ['Spore', 'Gathered fungal and propagule stock.'],
  ['Reagent', 'A volatile chemosynthetic extract.'],
  ['Rift-glass', 'Reality-stressed glass from unstable ground.'],
] as const;

export const creatureMaterialFamilies = [
  ['Hide', 'Short, soft, or bare skin prepared for wrapping and tanning.'],
  ['Pelt', 'Hide with long, dense fur still attached.'],
  ['Down', 'Soft insulating underfeather.'],
  ['Feather', 'A developed vane or flight feather.'],
  ['Fin', 'Flexible fin tissue and rays.'],
  ['Scale', 'Overlapping individual hard covering.'],
  ['Plate', 'A broad dermal armour plate.'],
  ['Chitin', 'A segmented, jointed hard case.'],
  ['Shell', 'A rigid enclosing or radial case.'],
  ['Quill', 'A long hardened covering shaft.'],
  ['Bone', 'Mineralized internal structure.'],
  ['Fang', 'A dominant piercing tooth.'],
  ['Claw', 'A dominant rending armament.'],
  ['Tusk', 'A dense protruding crushing structure.'],
  ['Horn', 'A cranial horn used as bracing or crushing stock.'],
  ['Oil', 'Insulating aquatic body oil.'],
  ['Venom', 'A toxic creature secretion.'],
  ['Ichor', 'A reactive or emanating creature fluid.'],
] as const;

export const lootPaths = [
  {
    name: 'World deposits and plants',
    current:
      'Harvesting gives the resource named by the deposit or plant. Returned stock is still held as counted resources or individual material samples, depending on the source.',
    accepted:
      'Mined yields become simple exact-name quantities with one normal/green presentation and no quality. Biological yields use quality only where their own material rules call for it. Ordinary plants remain safe; only clearly dangerous placements own contact harm.',
  },
  {
    name: 'Generated creatures',
    current:
      'A creature’s saved body already determines familiar materials such as Hide, Pelt, Scale, Bone, Venom, and Ichor. Those rewards are still stored as separate samples for each source creature.',
    accepted:
      'Creatures emit a recognizable physical type and subtype. Species-specific items of the same subtype and quality share a default stack, while species, colour, and inherited values remain visible in expanded history.',
  },
  {
    name: 'Named threats and guardians',
    current:
      'Paper Moths, Ink Hounds, Margin Wraiths, apexes, and site guardians use their own stated rewards. They do not automatically gain ordinary generated-creature materials.',
    accepted:
      'Their special rewards remain separate, with no extra ordinary creature material added by accident.',
  },
  {
    name: 'Sites, caches, Pages, and loose finds',
    current:
      'Each placed discovery keeps its own Search, depletion, and storage rules. A depleted site remains part of that world’s history rather than turning into another reward.',
    accepted:
      'The discovery and its position stay unchanged. Mined rewards move to exact-name quantity stacks; quality-bearing biological rewards move to subtype-and-quality stacks.',
  },
  {
    name: 'Nearby territory finds',
    current:
      'Ordinary encounters do not yet award nearby objects after a victory.',
    accepted:
      'A future victorious encounter may rarely reveal one habitat-appropriate object marked “Found nearby.” It is not a body part and is never guaranteed.',
  },
  {
    name: 'Expedition Return',
    current:
      'The expedition result divides eligible carried holdings into recovered and lost lines. Material lines may still be shown as individual samples or broad family groupings.',
    accepted:
      'Recovered plus lost will equal the exact carried quantity for every ungraded mined stack and every quality-bearing biological stack. Protected stock brought from the Cottage returns in full, and replay cannot duplicate either side.',
  },
  {
    name: 'Trading, crafting, and recycling',
    current:
      'Different services currently use a mixture of counted resources, individual material samples, and finished items.',
    accepted:
      'Every trade, recipe, and Recycler choice names the exact material, applicable subtype and quality, and quantity involved. Mined materials never show a quality choice. When biological quality matters, the player chooses it; another grade is never silently sold, crafted, or recycled.',
  },
] as const;

const apothecaryChanges: CraftingChange[] = ([
  ['Lesser Salve', 'One flexible sample at 25 or better, plus 1 Resin.', '1 Fibre and 1 Resin.'],
  ['Salve', 'One insulating sample at 40 or better, plus 2 Pulp, 1 Spore, and 1 Resin.', '2 Pulp, 1 Spore, and 1 Resin.'],
  ['Greater Salve', 'One reactive sample at 60 or better, plus 1 Ichor, 2 Spore, and 2 Resin.', '1 Creature Ichor, 2 Spore, and 2 Resin.'],
  ['Clearing Draught', 'One reactive sample at 35 or better, 1 Pulp, and 1 Salt.', '1 Reagent, 1 Pulp, and 1 Salt; displayed as Clearing Wash.'],
  ['Quenching Draught', 'One insulating sample at 45 or better, 1 Reagent, and 1 Resin.', '1 Creature Oil, 1 Reagent, and 1 Resin; displayed as Quenching Balm.'],
  ['Broad Antidote', 'One reactive sample at 65 or better, 1 Ichor, 1 Reagent, and 1 Spore.', '1 Creature Venom, 1 Reagent, and 1 Spore.'],
  ['Stonebark Tonic', 'One hard sample at 45 or better, 1 Timber, and 1 Resin.', '1 Timber and 1 Resin.'],
  ['Venom coating', 'One reactive sample at 55 or better, 1 Toxin, and 1 Fibre.', '1 Creature Venom or World Toxin, plus 1 Fibre.'],
  ['Firebrand', 'One reactive sample at 60 or better, 1 Reagent, and 1 Sulfur.', '1 Creature Oil or World Resin, 1 Reagent, and 1 Sulfur.'],
  ['Briar Oil', 'One flexible sample at 50 or better, 1 Fibre, and 1 Resin.', '1 Creature Oil, 1 Fibre, and 1 Resin.'],
  ['Flashsalt', 'One lustrous sample at 55 or better, 1 Reagent, and 1 Mercury.', '1 Salt, 1 Mercury, and 1 Quartz.'],
  ['Solvent', 'One reactive sample at 40 or better, 1 Reagent, and 1 Salt.', '1 Reagent and 1 Salt.'],
  ['Lure', 'One reactive sample at 50 or better, 1 Toxin, and 1 Pulp.', '1 creature Hide, Pelt, Down, or Oil, plus 1 Pulp.'],
  ['Stillwater', 'One lustrous sample at 60 or better, 1 Rift-glass, 1 Mercury, and 6 Essence.', '1 Silver, 1 Rift-glass, 1 Mercury, and 6 Essence.'],
  ['Waystone', 'One hard sample at 70 or better, 1 Rift-glass, 1 Mote, and 12 Essence.', 'Rift-glass, Mote, and Essence stay; its permanent hard World material is still being chosen.'],
  ['Torch', 'One reactive sample at 30 or better, 1 Resin, and 2 Timber.', '2 Timber and 1 Resin.'],
  ['Farsight Draught', 'One lustrous sample at 50 or better, 1 Quartz, and 1 Ichor.', '1 Quartz and 1 Creature Ichor.'],
  ['Scent Mask', 'One individual creature Hide, Pelt, Down, or Oil, plus 1 Reagent.', 'A visible scent-bearing creature-material category and Reagent; the final eligible type/subtype list will be reviewed with Aimee.'],
  ['Seamlight', '1 Quartz, 1 Resin, and 1 Fibre. It can be made, but it cannot yet be used from the Field Kit.', 'The recipe stays the same; the completed field action will guide toward a portal without creating light.'],
] as const).map(([name, current, accepted]) => ({ name, current, accepted }));

export const craftingFamilyStatus: CraftingFamilyStatus[] = [
  {
    slug: 'refinery',
    name: 'Essence Spring',
    status: 'Playable now',
    current: 'Refine Raw Essence manually at 2 Essence each, or 3 after Second Pass. Continuous Settling can refine newly returned Raw Essence.',
    accepted: 'The rates and progression stay the same. The future material update only makes returned material storage consistent.',
    changes: [
      { name: 'Refine Raw Essence', current: 'Choose a positive amount and spend it for the displayed return.', accepted: 'Unchanged.' },
      { name: 'Second Pass', current: 'Raises the return to 3 Essence for each Raw Essence.', accepted: 'Unchanged.' },
      { name: 'Continuous Settling', current: 'Refines newly returned Raw Essence when enabled; it is not passive offline production.', accepted: 'Unchanged.' },
    ],
  },
  {
    slug: 'apothecary',
    name: 'Apothecary',
    status: 'Partly playable',
    current: 'Nineteen preparations can be learned and made. Scent Mask can use an animal material in the Field, and Seamlight can guide the party toward a portal.',
    accepted: 'Keep all nineteen results and their completed Field uses, while replacing arbitrary hidden-property samples with recognizable physical ingredients.',
    changes: apothecaryChanges,
  },
  {
    slug: 'blacksmith',
    name: 'Blacksmith',
    status: 'Partly playable',
    current: 'Pointed Blade and the separate Reforge service are playable. Seven other defined forms are not available from the station.',
    accepted: 'Eight named schematics use physical component families. Reforge becomes one-component Refitting while preserving older workmanship.',
    changes: [
      { name: 'Pointed Blade', current: 'One chosen point and a different chosen grip.', accepted: 'A Point family and a Grip family, each with an explicit quality band.' },
      { name: 'Cutting Blade', current: 'Defined, but not unlockable or playable.', accepted: 'One Edge and one Grip after a future explicit unlock.' },
      { name: 'Hand Maul', current: 'Defined, but not unlockable or playable.', accepted: 'One Crush Head and one Haft after a future explicit unlock.' },
      { name: 'Long Spear', current: 'Defined, but not unlockable or playable.', accepted: 'One Point, one Haft, and one Binding after a future explicit unlock.' },
      { name: 'Shield', current: 'Defined, but not unlockable or playable.', accepted: 'One Rigid Body, one Haft, and one Binding after a future explicit unlock.' },
      { name: 'Helm', current: 'Defined, but not unlockable or playable.', accepted: 'One Hard Shell and one Lining after a future explicit unlock.' },
      { name: 'Rigid Guard', current: 'Defined, but not unlockable or playable.', accepted: 'Two Rigid Body quantities and one Binding after a future explicit unlock.' },
      { name: 'Field Pick', current: 'Defined, but not unlockable or playable.', accepted: 'A non-Quartz Point, a Crush Head, and a Haft once hard-node use is ready.' },
      { name: 'Reforge', current: 'Improves one chosen eligible piece while preserving its identity and history.', accepted: 'Refitting replaces one chosen component; paid older ranks remain as workmanship.' },
    ],
  },
  {
    slug: 'tannery',
    name: 'Tannery',
    status: 'Changing in a future update',
    current: 'Supple Coat, Working Gloves, and Working Boots use individually selected samples that must meet hidden physical requirements.',
    accepted: 'The same three patterns move to player-selected physical type/subtype and four-band quality stacks. Their final category lists and stat contributions remain under design review.',
    changes: ['Supple Coat', 'Working Gloves', 'Working Boots'].map((name) => ({ name, current: 'Playable with the current individually selected material recipe.', accepted: 'Use visible physical part categories and player-selected quality; preview the resulting Armour and other real stat contributions.' })),
  },
  {
    slug: 'bowyer',
    name: 'Bowyer',
    status: 'Changing in a future update',
    current: 'Longbow, Sling, and Throwing Set are playable through their current station and study gates.',
    accepted: 'The same three weapons keep their recognizable parts and use player-selected physical types/subtypes. Mined parts stay ungraded; approved biological parts retain their four-band quality choice.',
    changes: ['Longbow', 'Sling', 'Throwing Set'].map((name) => ({ name, current: 'Playable with individually selected material samples.', accepted: 'The same parts selected from visible physical categories, with direct previewed stat contributions.' })),
  },
  {
    slug: 'weaponsmith',
    name: 'Weaponsmith',
    status: 'Changing in a future update',
    current: 'Fitted Point, Fitted Edge, Fitted Maul, and Fitted Polearm are playable. Polearm appears after Maud’s fitting pattern is known.',
    accepted: 'All four keep their damage choices and name the physical material categories needed for each part.',
    changes: ['Fitted Point', 'Fitted Edge', 'Fitted Maul', 'Fitted Polearm'].map((name) => ({ name, current: 'Playable by choosing a head, support, and fitting that meet the current requirements.', accepted: 'The same form uses visible head, support, and fitting categories. Mined choices have no quality; biological quality is chosen only where it affects the result.' })),
  },
  {
    slug: 'armoury',
    name: 'Armoury',
    status: 'Changing in a future update',
    current: 'Rigid Shell, Insulated Layer, and Balanced Laminate rebuild one chosen eligible protective item.',
    accepted: 'Each profile keeps the item’s identity and replaces hidden property samples with named body, lining, binding, and fitting families.',
    changes: ['Rigid Shell', 'Insulated Layer', 'Balanced Laminate'].map((name) => ({ name, current: 'Playable by rebuilding one chosen item.', accepted: 'The same rebuild uses recognizable layer categories and player-selected biological quality where applicable, with fixed ungraded mined contributions and all resulting stats shown before confirmation.' })),
  },
  {
    slug: 'instruments',
    name: 'Field Instruments',
    status: 'Changing in a future update',
    current: 'All eight instruments are permanent Research capabilities. Good and Fine precision upgrades are playable and automatically use the weakest individual samples that meet their hidden requirements.',
    accepted: 'Keep the current instrument precision tiers and costs unless separately changed. Replace hidden property searches with visible physical categories; mined inputs have no quality, while the player chooses biological quality where it affects the result.',
    changes: [
      { name: 'Sunglass and Chronometer', current: 'Use qualifying lustrous samples.', accepted: 'Quartz, Silver, Gold, Feather, or Quill.' },
      { name: 'Thermoscope', current: 'Uses qualifying insulating samples.', accepted: 'Fibre, Resin, Pelt, Down, Hide, or Oil.' },
      { name: 'Hygrometer', current: 'Uses qualifying flexible samples.', accepted: 'Fibre, Hide, Pelt, or Fin.' },
      { name: 'Loupe', current: 'Uses qualifying hard samples.', accepted: 'Iron, Adamant, Obsidian, Quartz, Bone, Scale, Chitin, Shell, or another approved physical subtype.' },
      { name: 'Level and Barometer', current: 'Use qualifying dense samples.', accepted: 'An approved structural stone, Iron, Adamant, Bone, Chitin, Shell, or another approved physical subtype.' },
      { name: 'Vivometer', current: 'Uses qualifying reactive samples.', accepted: 'Resin, Toxin, Spore, Reagent, Oil, Venom, or Ichor.' },
    ],
  },
  {
    slug: 'writing-ink',
    name: 'Scriptorium and prepared ink',
    status: 'Partly playable',
    current: 'Penmanship, prepared ink, Compound Assembly, and Seamward are playable after their listed requirements. Chaining lists a Mote in its price, but the game cannot safely spend that Mote yet.',
    accepted: 'Keep the actions and ink measure math, move physical ingredients to material stacks, and keep Chaining unavailable until it can spend one Mote exactly once or leave the entire cost untouched.',
    changes: [
      { name: 'Brush', current: '45 Essence, 2 Copper, 6 Fibre, and 4 Timber.', accepted: 'Same cost from World material stacks.' },
      { name: 'Writing Desk', current: '70 Essence, 6 Clay, and 8 Timber.', accepted: 'Unchanged.' },
      { name: 'Ink Mixing', current: '40 Essence, 2 Copper, 2 Quartz, and 4 Resin.', accepted: 'Same cost from World material stacks.' },
      { name: 'Prepared ink vial', current: 'Copper, Ichor, Sulfur, and Obsidian supply Cyan, Magenta, Yellow, and Depth. One resource makes four measures; Resin seals a 12-use vial.', accepted: 'Keep the exact math; Creature Ichor replaces legacy Ichor after migration.' },
      { name: 'Compound Assembly', current: '55 Essence, 4 Pulp, 4 Resin, and 2 Quartz; formalizing a proven statement then costs 20 Essence and 4 Pulp.', accepted: 'Same costs from material stacks.' },
      { name: 'Seamward', current: 'Playable with identified Seamlight, 10 Essence, ash or prepared ink, and eligible empty gear.', accepted: 'Unchanged; it guides to a portal and never creates illumination.' },
      { name: 'Chaining', current: 'Names 90 Essence, 2 Mercury, and 1 Mote, but it cannot yet spend the Mote safely.', accepted: 'Keep the same price once the game can spend that one Mote exactly once.' },
      { name: 'Press', current: '140 Essence, 6 Quartz, and 4 Silver.', accepted: 'Unchanged.' },
      { name: 'Fountain Pen', current: '220 Essence, 4 Quartz, 8 Resin, and 6 Silver.', accepted: 'Unchanged.' },
    ],
  },
  {
    slug: 'recycler',
    name: 'Recycler',
    status: 'Changing in a future update',
    current: 'Dismantles one selected eligible, unequipped piece and returns its recorded construction materials or listed salvage.',
    accepted: 'Returns each mined input to its exact-name ungraded stack and each biological input to its recorded type/subtype, quality, colour/source detail, and quantity. The old-salvage migration mapping remains to be designed.',
    changes: [{ name: 'Dismantle gear', current: 'One selected eligible piece; protected, equipped, malformed, and undefined pieces are refused.', accepted: 'Keep the same protections and return the selected material types, qualities, and quantities recorded when the item was made.' }],
  },
  {
    slug: 'distillery',
    name: 'Distillery',
    status: 'Partly playable',
    current: 'Heat, Caustic, and Light Cores are made directly for 16 Essence plus their catalyst and one individual sample that meets the hidden requirements. There is no Blank Core step.',
    accepted: 'Keep direct attunement and 16 Essence. Use named material families, and advertise a Core as a goal only when its housing is playable.',
    changes: [
      { name: 'Blank Core', current: 'Not available.', accepted: 'Do not add a Blank Core step.' },
      { name: 'Heat Core', current: '16 Essence, 2 Sulfur, and one qualifying reactive or insulating sample.', accepted: '16 Essence, 2 Sulfur, and 1 World Resin or Creature Oil.' },
      { name: 'Caustic Core', current: '16 Essence, Toxin or Ichor catalyst, and one qualifying Reagent, Toxin, or Ichor sample.', accepted: '16 Essence and named Reagent, Toxin, Venom, or Ichor families; publish as a goal when Caustic housing is playable.' },
      { name: 'Light Core', current: '16 Essence, 2 Silver, and one qualifying lustrous and hard sample.', accepted: '16 Essence, 2 Silver, and 1 Quartz; combat use only when Light housing is playable.' },
    ],
  },
  {
    slug: 'channelworks',
    name: 'Channelworks',
    status: 'Partly playable',
    current: 'Heat Core can become a stored Heat Fixture. The stored Fixture is not yet an equippable combat housing.',
    accepted: 'Heat, then Caustic, then Light become permanent Mid-reach combat Conduits. Light is combat-only and never world illumination.',
    changes: [
      { name: 'Heat Conduit', current: 'A Heat Core can become a stored Fixture; no equipped combat use yet.', accepted: 'A Mid-reach Heat weapon whose Attack can deliver Heat and Burn.' },
      { name: 'Caustic Conduit', current: 'Caustic Cores can be stored, but no fixture or combat use is available.', accepted: 'A later Mid-reach Caustic weapon whose Attack can deliver Caustic and Poison.' },
      { name: 'Light Conduit', current: 'Light Cores can be stored, but no fixture or combat use is available.', accepted: 'A later Mid-reach combat Light weapon that may Dazzle and never lights the world.' },
    ],
  },
  {
    slug: 'anchorage',
    name: 'Anchorage',
    status: 'Changing in a future update',
    current: 'Anchor Frame automatically chooses six different samples that meet its hidden requirements and spends 60 Essence. The completed Frame can be placed in the Field.',
    accepted: 'Replace six hidden numerical searches with visible structural categories. Aimee will review the final eligible types, quality rule, and player wording before this change is added.',
    changes: [{ name: 'Anchor Frame', current: 'Two hard, two dense, one flexible, and one reactive individual sample, plus 60 Essence.', accepted: 'Visible structural-member, load-bearing, binding, and responsive-component selections plus 60 Essence; the final category lists remain under review.' }],
  },
];

export function craftingStatusFor(slug: string) {
  return craftingFamilyStatus.find((entry) => entry.slug === slug);
}

export function futureResourceCopy(name: string) {
  if (name === 'Raw Essence') return 'Raw Essence remains a quality-free precursor. Return it to the Cottage and refine it at the Essence Spring.';
  if (name === 'Mote') return 'Motes remain permanent Reality currency, with no material quality or storage slot.';
  if (name === 'Ichor') return 'Ichor will use its settled physical source category and one of four resource qualities. Older stock must move into the new system without inventing a creature source.';
  if (name === 'Rubble') return 'Rubble will not remain a finished resource with no physical identity. Aimee will choose removal or a renamed mixed find processed only into materials supported by its source region.';
  if (['Clay', 'Ore', 'Iron Ore', 'Copper', 'Silver', 'Gold', 'Quartz', 'Obsidian', 'Salt', 'Sulfur', 'Mercury', 'Adamant', 'Rift-glass'].includes(name)) {
    const intendedName = name === 'Ore' || name === 'Iron Ore' ? 'Iron' : name;
    return `${intendedName} will be one simple exact-name quantity stack. It has no Poor, Common, Rare, or Exceptional variants and always uses the normal/green presentation. Its source does not split the stack.`;
  }
  return `${name} will use a recognizable physical type or subtype. Quality applies only if this biological material is explicitly approved for the four-band system; source world, species where relevant, and inherited colour remain available in expanded history without needlessly splitting the stack.`;
}

export const openDecisions = [
  {
    title: 'Final material and recipe taxonomy',
    body: 'Aimee has settled the hierarchy: broad category, specific physical type, optional precise subtype, then species/source and four quality bands only where biological variation matters. Mined resources use plain exact names, one normal/green presentation, and no quality. The complete type/subtype registry and every recipe eligibility list still need joint review.',
  },
  {
    title: 'Mixed geological find',
    body: 'Aimee prefers replacing finished Rubble with a mixed find shaped by its region. Processing it could yield a small grab bag from that zone, including an occasional material the player could not yet reach or harvest. Its name, frequency, number of results, regional weighting, and processing facility remain open. Any mined results remain ungraded.',
  },
  {
    title: 'Harvest and facility progression',
    body: 'The intended progression uses better Picks, Axes, and Scythes, processing facilities, facility levels, and later recipe tiers. Exact tools, materials per tier, processed goods, facility owners, and upgrade costs remain open.',
  },
  {
    title: 'Crafted statistics and Peerless equipment',
    body: 'Biological-material quality directly improves real item statistics. Mined materials use fixed authored contributions with no quality roll. Exact contributions, the multi-input result-quality rule, alpha drops, maximum-facility Peerless chance, and a possible matching-NPC bonus remain open.',
  },
  {
    title: 'World generation and direct targeting',
    body: 'Aimee has settled that players can directly call at least some terrain and base resources and can pressure ecological materials such as Chitin. Exact ground/liquid catalogues, layout styles, world sizes, compatibility rules, and guarantee strength remain open.',
  },
  {
    title: 'Waystone’s hard body',
    body: 'The current Waystone accepts any sufficiently hard sample. Its intended recipe keeps Rift-glass, one Mote, and 12 Essence, but its permanent hard World material still needs a final choice.',
  },
] as const;

export const correctionStatus = [
  {
    label: 'Must change',
    title: 'Material storage',
    body: 'The current game mixes counted World resources, individual material samples, and family-only summaries. The intended default is one exact-name quantity stack for each mined material and one subtype-and-quality stack for each approved biological material, with species-specific items and colour in expanded detail. Alternate inventory views change only how materials are sorted, never where they are stored or who owns them.',
  },
  {
    label: 'Must change',
    title: 'Physically arbitrary recipe samples',
    body: 'Several recipes still accept unrelated materials because a hidden property number is high enough. Their replacements will use visible broad, specific, or precise physical categories.',
  },
  {
    label: 'Must change',
    title: 'Scent Mask and Seamlight field access',
    body: 'Both can be made, but neither can yet be used properly through the Field Kit. The correction adds a clear action for each item without granting either one for free.',
  },
  {
    label: 'Must change',
    title: 'Chaining’s Mote payment',
    body: 'Chaining lists a Mote in its price, but the game cannot safely spend that Mote yet. It stays unavailable until it can spend the Mote exactly once or leave every part of the cost untouched.',
  },
  {
    label: 'Planned, not broken',
    title: 'Later Blacksmith forms and Conduits',
    body: 'Seven Blacksmith forms and the Caustic and Light combat housings are planned for later progression. They should appear only after their unlocks and gameplay uses are ready.',
  },
  {
    label: 'Decision complete',
    title: 'Anchor Frame ingredient model',
    body: 'The future Frame replaces hidden property searches with visible physical roles. Its final category lists and quality rule still require Aimee review and must remain marked Planned until they are available in the game.',
  },
] as const;
