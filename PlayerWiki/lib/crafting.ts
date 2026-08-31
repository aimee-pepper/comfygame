export interface CraftingSystem {
  slug: string;
  name: string;
  station: string;
  summary: string;
  howItWorks: string[];
}

export interface CraftIngredient {
  resourceID?: string;
  label: string;
  amount?: number;
  role?: string;
}
export interface CraftRecipe {
  id: string;
  name: string;
  system: string;
  result: string;
  ingredients: CraftIngredient[];
  notes?: string;
}

export const craftingSystems: CraftingSystem[] = [
  {
    slug: 'apothecary',
    name: 'Apothecary preparations',
    station: 'The Apothecary',
    summary:
      'Make remedies, coatings and field supplies from named resources and property-matched natural samples.',
    howItWorks: [
      'Learn or infer the preparation.',
      'Choose any required natural sample that meets the shown property floor.',
      'Supply the named resources, Essence or Mote cost, then prepare one item.',
    ],
  },
  {
    slug: 'blacksmith',
    name: 'Blacksmith construction',
    station: 'Blacksmith',
    summary:
      'Construct a Pointed Blade from an exact point and grip; material quality and family shape the finished weapon.',
    howItWorks: [
      'Select one eligible point and one eligible grip.',
      'Review the resulting quality, combat shape and Essence cost.',
      'Constructing consumes those exact samples and creates one persistent weapon.',
    ],
  },
  {
    slug: 'tannery',
    name: 'Tannery construction',
    station: 'The Tannery',
    summary:
      'Turn flexible, living and structural samples into coats, gloves and boots.',
    howItWorks: [
      'Choose a distinct sample for every named part.',
      'Higher-quality primary pieces contribute most strongly to the result.',
      'The selected stock and shown Essence cost are consumed together.',
    ],
  },
  {
    slug: 'bowyer',
    name: 'Bowyer construction',
    station: 'The Bowyer',
    summary:
      'Build far-reaching physical weapons without maintaining a separate ammunition inventory.',
    howItWorks: [
      'Choose the limbs, cord, projectile or edges required by the design.',
      'The preview shows the quality the selected stock can support.',
      'Constructing creates a longbow, sling or throwing set.',
    ],
  },
  {
    slug: 'weaponsmith',
    name: 'Weaponsmith construction',
    station: 'The Weaponsmith',
    summary:
      'Fit advanced points, edges, mauls and polearms around exact components and a learned fitting pattern.',
    howItWorks: [
      'Select the head or edge, supporting structure and fitting.',
      'Choose the polearm consequence where that design is available.',
      'The finished weapon freezes its selected materials and resulting combat facts.',
    ],
  },
  {
    slug: 'armoury',
    name: 'Armoury rebuilding',
    station: 'The Armoury',
    summary:
      'Rebuild one existing protective item in place as a rigid, insulated or balanced construction.',
    howItWorks: [
      'Choose an eligible stored or worn protective item.',
      'Choose one exact sample for each layer, body, binding or fitting.',
      'The rebuild keeps the item identity but replaces its construction profile and spends the shown Essence.',
    ],
  },
  {
    slug: 'instruments',
    name: 'Instrument improvement',
    station: 'Workshop',
    summary:
      'Improve the precision of owned world-reading instruments with property-matched samples and Essence.',
    howItWorks: [
      'Each instrument asks for the property it measures best.',
      'Crude to Good uses two 35+ samples and 20 Essence.',
      'Good to Fine uses three 65+ samples and 50 Essence.',
    ],
  },
  {
    slug: 'distillery',
    name: 'Distillation and Channelworks',
    station: 'The Distillery / Channelworks',
    summary:
      'Attune Essence through a world-made sample, then give a Heat core a physical conduit at the Channelworks.',
    howItWorks: [
      'Choose Heat, Caustic or Light attunement.',
      'Select a qualifying provenance-bearing sample and the exact catalyst.',
      'Spend 16 Essence to create the core; a valid Heat Core can later become a Conduit Fixture.',
    ],
  },
  {
    slug: 'refinery',
    name: 'Raw Essence refining',
    station: 'Essence Spring',
    summary:
      'Convert Raw Essence into spendable Essence Crystals at the current refinement rate.',
    howItWorks: [
      'Choose an amount of stored Raw Essence or refine all.',
      'The preview shows the exact Crystal return.',
      'Later capability can improve the rate and settle newly returned Raw automatically.',
    ],
  },
  {
    slug: 'writing-ink',
    name: 'Prepared writing ink',
    station: 'Writing Desk',
    summary:
      'Prepare CMY and Depth ink applications for eligible source marks on a Page.',
    howItWorks: [
      'Choose Cyan, Magenta, Yellow and Depth proportions.',
      'Copper, Ichor, Sulfur and Obsidian supply those channels; Resin seals the vial.',
      'A prepared vial provides 12 applications, and Binding spends one matching application per inked source.',
    ],
  },
];

const r = (
  resourceID: string,
  amount: number,
  role = 'fixed cost',
): CraftIngredient => ({ resourceID, amount, label: resourceID, role });
const e = (
  label: string,
  resourceIDs: string[],
  role = 'eligible component',
): CraftIngredient[] =>
  resourceIDs.map((resourceID) => ({ resourceID, label, role }));

export const craftingRecipes: CraftRecipe[] = [
  {
    id: 'seamlight',
    name: 'Seamlight',
    system: 'apothecary',
    result: 'Seamlight',
    ingredients: [r('quartz', 1), r('resin', 1), r('fiber', 1)],
  },
  {
    id: 'scent-mask',
    name: 'Scent Mask',
    system: 'apothecary',
    result: 'Scent Mask',
    ingredients: [
      r('reagent', 1),
      { label: '1 creature Hide, Pelt, Down or Oil', role: 'selected sample' },
    ],
  },
  {
    id: 'lesser-salve',
    name: 'Lesser Salve',
    system: 'apothecary',
    result: 'Lesser Salve',
    ingredients: [
      r('resin', 1),
      { label: '1 flexible 25+ sample', role: 'selected sample' },
    ],
  },
  {
    id: 'salve',
    name: 'Salve',
    system: 'apothecary',
    result: 'Salve',
    ingredients: [
      r('pulp', 2),
      r('spore', 1),
      r('resin', 1),
      { label: '1 insulating 40+ sample', role: 'selected sample' },
    ],
  },
  {
    id: 'greater-salve',
    name: 'Greater Salve',
    system: 'apothecary',
    result: 'Greater Salve',
    ingredients: [
      r('ichor', 1),
      r('spore', 2),
      r('resin', 2),
      { label: '1 reactive 60+ sample', role: 'selected sample' },
    ],
  },
  {
    id: 'clearing-draught',
    name: 'Clearing Draught',
    system: 'apothecary',
    result: 'Clearing Draught',
    ingredients: [
      r('pulp', 1),
      r('salt', 1),
      { label: '1 reactive 35+ sample', role: 'selected sample' },
    ],
  },
  {
    id: 'quenching-draught',
    name: 'Quenching Draught',
    system: 'apothecary',
    result: 'Quenching Draught',
    ingredients: [
      r('reagent', 1),
      r('resin', 1),
      { label: '1 insulating 45+ sample', role: 'selected sample' },
    ],
  },
  {
    id: 'broad-antidote',
    name: 'Broad Antidote',
    system: 'apothecary',
    result: 'Broad Antidote',
    ingredients: [
      r('ichor', 1),
      r('reagent', 1),
      r('spore', 1),
      { label: '1 reactive 65+ sample', role: 'selected sample' },
    ],
  },
  {
    id: 'stonebark-tonic',
    name: 'Stonebark Tonic',
    system: 'apothecary',
    result: 'Stonebark Tonic',
    ingredients: [
      r('timber', 1),
      r('resin', 1),
      { label: '1 hard 45+ sample', role: 'selected sample' },
    ],
  },
  {
    id: 'venom',
    name: 'Venom',
    system: 'apothecary',
    result: 'Venom',
    ingredients: [
      r('toxin', 1),
      r('fiber', 1),
      { label: '1 reactive 55+ sample', role: 'selected sample' },
    ],
  },
  {
    id: 'firebrand',
    name: 'Firebrand',
    system: 'apothecary',
    result: 'Firebrand',
    ingredients: [
      r('reagent', 1),
      r('sulfur', 1),
      { label: '1 reactive 60+ sample', role: 'selected sample' },
    ],
  },
  {
    id: 'briar-oil',
    name: 'Briar Oil',
    system: 'apothecary',
    result: 'Briar Oil',
    ingredients: [
      r('fiber', 1),
      r('resin', 1),
      { label: '1 flexible 50+ sample', role: 'selected sample' },
    ],
  },
  {
    id: 'flashsalt',
    name: 'Flashsalt',
    system: 'apothecary',
    result: 'Flashsalt',
    ingredients: [
      r('reagent', 1),
      r('mercury', 1),
      { label: '1 lustrous 55+ sample', role: 'selected sample' },
    ],
  },
  {
    id: 'solvent',
    name: 'Solvent',
    system: 'apothecary',
    result: 'Solvent',
    ingredients: [
      r('reagent', 1),
      r('salt', 1),
      { label: '1 reactive 40+ sample', role: 'selected sample' },
    ],
  },
  {
    id: 'lure',
    name: 'Lure',
    system: 'apothecary',
    result: 'Lure',
    ingredients: [
      r('toxin', 1),
      r('pulp', 1),
      { label: '1 reactive 50+ sample', role: 'selected sample' },
    ],
  },
  {
    id: 'stillwater',
    name: 'Stillwater',
    system: 'apothecary',
    result: 'Stillwater',
    ingredients: [
      r('rift_glass', 1),
      r('mercury', 1),
      { label: '1 lustrous 60+ sample', role: 'selected sample' },
      { label: '6 Essence', role: 'currency' },
    ],
  },
  {
    id: 'waystone',
    name: 'Waystone',
    system: 'apothecary',
    result: 'Waystone',
    ingredients: [
      r('rift_glass', 1),
      { label: '1 hard 70+ sample', role: 'selected sample' },
      { label: '1 Mote', role: 'currency' },
      { label: '12 Essence', role: 'currency' },
    ],
  },
  {
    id: 'torch',
    name: 'Torch',
    system: 'apothecary',
    result: 'Torch',
    ingredients: [
      r('resin', 1),
      r('timber', 2),
      { label: '1 reactive 30+ sample', role: 'selected sample' },
    ],
  },
  {
    id: 'farsight',
    name: 'Farsight Draught',
    system: 'apothecary',
    result: 'Farsight Draught',
    ingredients: [
      r('quartz', 1),
      r('ichor', 1),
      { label: '1 lustrous 50+ sample', role: 'selected sample' },
    ],
  },
  {
    id: 'pointed-blade',
    name: 'Pointed Blade',
    system: 'blacksmith',
    result: 'Pointed Blade',
    ingredients: [
      ...e('Point', ['ore', 'adamant', 'obsidian', 'quartz']),
      ...e('Grip', ['fiber', 'timber', 'copper', 'silver', 'gold']),
    ],
    notes:
      'Creature Fang, Quill, Bone, Tusk, Horn, Hide, Pelt and Fin can also fill eligible sockets.',
  },
  {
    id: 'supple-coat',
    name: 'Supple Coat',
    system: 'tannery',
    result: 'Supple Coat',
    ingredients: [...e('Outer', ['fiber']), ...e('Lining', ['fiber'])],
    notes:
      'Creature Hide, Pelt, Fin, Scale, Down and Feather can also qualify.',
  },
  {
    id: 'working-gloves',
    name: 'Working Gloves',
    system: 'tannery',
    result: 'Working Gloves',
    ingredients: [...e('Hand', ['fiber']), ...e('Facing', [])],
    notes:
      'Uses property-bearing creature and world samples chosen for the shown sockets.',
  },
  {
    id: 'working-boots',
    name: 'Working Boots',
    system: 'tannery',
    result: 'Working Boots',
    ingredients: [
      ...e('Upper', ['fiber']),
      ...e('Sole', ['timber']),
      ...e('Binding', ['fiber', 'resin', 'copper', 'silver', 'gold']),
    ],
  },
  {
    id: 'longbow',
    name: 'Longbow',
    system: 'bowyer',
    result: 'Longbow',
    ingredients: [...e('Limbs', ['timber']), ...e('String', ['fiber'])],
    notes:
      'Horn, Quill, Bone, Hide and Fin can substitute in eligible sockets.',
  },
  {
    id: 'sling',
    name: 'Sling',
    system: 'bowyer',
    result: 'Sling',
    ingredients: [
      ...e('Cord', ['fiber']),
      ...e('Projectile', ['rubble', 'clay', 'ore', 'copper', 'adamant']),
      ...e('Pouch', ['fiber']),
    ],
  },
  {
    id: 'throwing-set',
    name: 'Throwing Set',
    system: 'bowyer',
    result: 'Throwing Set',
    ingredients: [
      ...e('Edges', ['ore', 'adamant', 'obsidian']),
      ...e('Carrier', ['fiber']),
    ],
  },
  {
    id: 'fitted-point',
    name: 'Fitted Point',
    system: 'weaponsmith',
    result: 'Fitted Point',
    ingredients: [
      ...e('Point', ['ore', 'adamant', 'obsidian', 'quartz']),
      ...e('Grip', ['fiber', 'timber', 'copper', 'silver', 'gold']),
      ...e('Fitting', ['copper', 'silver', 'gold', 'quartz', 'adamant']),
    ],
  },
  {
    id: 'fitted-edge',
    name: 'Fitted Edge',
    system: 'weaponsmith',
    result: 'Fitted Edge',
    ingredients: [
      ...e('Edge', ['ore', 'adamant', 'obsidian']),
      ...e('Grip', ['fiber', 'timber', 'copper', 'silver', 'gold']),
      ...e('Fitting', ['copper', 'silver', 'gold', 'quartz', 'adamant']),
    ],
  },
  {
    id: 'fitted-maul',
    name: 'Fitted Maul',
    system: 'weaponsmith',
    result: 'Fitted Maul',
    ingredients: [
      ...e('Head', ['rubble', 'ore', 'copper', 'adamant']),
      ...e('Brace', ['timber', 'ore', 'adamant']),
      ...e('Grip', ['fiber', 'timber', 'copper', 'silver', 'gold']),
    ],
  },
  {
    id: 'fitted-polearm',
    name: 'Fitted Polearm',
    system: 'weaponsmith',
    result: 'Fitted Polearm',
    ingredients: [
      ...e('Head', [
        'rubble',
        'ore',
        'copper',
        'adamant',
        'obsidian',
        'quartz',
      ]),
      ...e('Haft', ['timber', 'ore', 'adamant']),
      ...e('Binding', ['fiber', 'resin', 'copper', 'silver', 'gold']),
    ],
  },
  {
    id: 'rigid-shell',
    name: 'Rigid shell rebuild',
    system: 'armoury',
    result: 'Rebuilt protective item',
    ingredients: [
      ...e('Bodies', ['ore', 'copper', 'adamant']),
      ...e('Binding', ['fiber', 'resin', 'copper', 'silver', 'gold']),
    ],
  },
  {
    id: 'insulated-layer',
    name: 'Insulated layer rebuild',
    system: 'armoury',
    result: 'Rebuilt protective item',
    ingredients: [
      ...e('Linings', ['fiber']),
      ...e('Outer', ['ore', 'copper', 'adamant', 'timber']),
    ],
    notes: 'Many creature materials also qualify for the exact layers shown.',
  },
  {
    id: 'balanced-laminate',
    name: 'Balanced laminate rebuild',
    system: 'armoury',
    result: 'Rebuilt protective item',
    ingredients: [
      ...e('Body', ['ore', 'copper', 'adamant', 'timber']),
      ...e('Lining', ['fiber']),
      ...e('Binding', ['fiber', 'resin', 'copper', 'silver', 'gold']),
      ...e('Fitting', ['copper', 'silver', 'gold', 'quartz', 'adamant']),
    ],
  },
  {
    id: 'good-instrument',
    name: 'Good instrument',
    system: 'instruments',
    result: 'Good instrument',
    ingredients: [
      {
        label: '2 samples with the instrument property at 35+',
        role: 'selected samples',
      },
      { label: '20 Essence', role: 'currency' },
    ],
    notes: 'The required property depends on the instrument being improved.',
  },
  {
    id: 'fine-instrument',
    name: 'Fine instrument',
    system: 'instruments',
    result: 'Fine instrument',
    ingredients: [
      {
        label: '3 samples with the instrument property at 65+',
        role: 'selected samples',
      },
      { label: '50 Essence', role: 'currency' },
    ],
    notes: 'The required property depends on the instrument being improved.',
  },
  {
    id: 'heat-core',
    name: 'Heat Core',
    system: 'distillery',
    result: 'Heat Core',
    ingredients: [
      r('sulfur', 2),
      {
        label: '1 reactive 60+ and insulating 25+ sample',
        role: 'selected sample',
      },
      { label: '16 Essence', role: 'currency' },
    ],
  },
  {
    id: 'caustic-core',
    name: 'Caustic Core',
    system: 'distillery',
    result: 'Caustic Core',
    ingredients: [
      r('toxin', 2, 'catalyst option'),
      r('ichor', 1, 'catalyst option'),
      {
        label: '1 reactive 60+ Reagent, Toxin or Ichor sample',
        role: 'selected sample',
      },
      { label: '16 Essence', role: 'currency' },
    ],
    notes:
      'Choose one catalyst option: 2 Toxin or 1 Ichor. They are not both spent.',
  },
  {
    id: 'light-core',
    name: 'Light Core',
    system: 'distillery',
    result: 'Light Core',
    ingredients: [
      r('silver', 2),
      { label: '1 lustrous 60+ and hard 30+ sample', role: 'selected sample' },
      { label: '16 Essence', role: 'currency' },
    ],
  },
  {
    id: 'conduit-fixture',
    name: 'Conduit Fixture',
    system: 'distillery',
    result: 'Conduit Fixture',
    ingredients: [{ label: '1 valid Heat Core', role: 'consumed item' }],
  },
  {
    id: 'raw-essence',
    name: 'Refine Raw Essence',
    system: 'refinery',
    result: 'Essence Crystals',
    ingredients: [r('essence_raw', 1, 'input currency')],
    notes:
      'The output rate is shown before committing and can improve through progression.',
  },
  {
    id: 'prepared-ink',
    name: 'Prepared CMY + Depth ink vial',
    system: 'writing-ink',
    result: '12 writing applications',
    ingredients: [
      { resourceID: 'copper', label: 'Copper', role: 'Cyan stock as required' },
      {
        resourceID: 'ichor',
        label: 'Ichor',
        role: 'Magenta stock as required',
      },
      {
        resourceID: 'sulfur',
        label: 'Sulfur',
        role: 'Yellow stock as required',
      },
      {
        resourceID: 'obsidian',
        label: 'Obsidian',
        role: 'Depth stock as required',
      },
      r('resin', 1, 'vial seal'),
    ],
    notes:
      'Exact channel shortfalls determine which pigments are consumed; a zero channel costs none of that pigment.',
  },
];

export function recipesUsingResource(resourceID: string) {
  return craftingRecipes.filter((recipe) =>
    recipe.ingredients.some(
      (ingredient) => ingredient.resourceID === resourceID,
    ),
  );
}
export function systemFor(slug: string) {
  return craftingSystems.find((system) => system.slug === slug);
}
export function recipesFor(slug: string) {
  return craftingRecipes.filter((recipe) => recipe.system === slug);
}
