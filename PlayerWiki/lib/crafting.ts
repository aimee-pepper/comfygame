export interface CraftingSystem {
  slug: string;
  name: string;
  station: string;
  stationID: string;
  summary: string;
  access: string[];
  materialChoice: string;
  commitResult: string;
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
  readiness?: string;
}

export const craftingSystems: CraftingSystem[] = [
  {
    slug: 'apothecary',
    name: 'Apothecary preparations',
    station: 'The Apothecary',
    stationID: 'apothecary',
    summary:
      'Make remedies, coatings and field supplies from named resources and property-matched natural samples.',
    access: ['Build the Apothecary.', 'Use a recipe that is currently known.'],
    materialChoice: 'When a preparation asks for a sample, choose the exact weakest qualifying sample shown by that recipe. Scent Mask uses its separate exact creature-material selection.',
    commitResult: 'A committed preparation spends the named scalar resources, current Essence or Mote cost, and selected input only when output room is available; it produces the listed item.',
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
    stationID: 'blacksmith',
    summary:
      'Construct a Pointed Blade from an exact point and grip; material quality and family shape the finished weapon.',
    access: ['Build the Blacksmith.', 'Use the stable Pointed Blade schematic.'],
    materialChoice: 'Choose one exact point and one exact grip from the family allowed by each socket; the selected materials shape the current quality and combat form.',
    commitResult: 'A committed construction spends the selected point, grip, and shown Essence cost, then creates one persistent weapon.',
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
    stationID: 'tannery',
    summary:
      'Turn flexible, living and structural samples into coats, gloves and boots.',
    access: ['Build the Tannery.', 'Meet the current wear research or tier gate for the chosen pattern.'],
    materialChoice: 'Every named outer, lining, palm, binding, upper, and sole socket accepts only its shown families and properties; the primary selected pieces contribute most strongly to the result.',
    commitResult: 'A committed construction spends the selected exact stock and shown Essence together, then creates the selected protective item.',
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
    stationID: 'bowyer',
    summary:
      'Build far-reaching physical weapons without maintaining a separate ammunition inventory.',
    access: ['Build the Bowyer.', 'Meet the current broaden or masterwork research gate for the chosen design.'],
    materialChoice: 'Choose the limbs, cord, projectile, edges, pouch, or grip only from the families accepted by that socket; the current preview shows the quality supported by those selections.',
    commitResult: 'A committed construction consumes the shown exact components and creates the selected longbow, sling, or throwing set.',
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
    stationID: 'weaponsmith',
    summary:
      'Fit current points, edges and mauls around exact components and a learned fitting pattern.',
    access: ['Build the Weaponsmith.', 'Use the learned fitting pattern for the selected design.'],
    materialChoice: 'Choose the head or edge, supporting structure, and fitting from the exact metal or creature-material families accepted by each socket.',
    commitResult: 'A committed construction creates the chosen fitted weapon and freezes its selected material facts into the finished result.',
    howItWorks: [
      'Select the head or edge, supporting structure and fitting.',
      'Choose the current fitted design shown by the station.',
      'The finished weapon freezes its selected materials and resulting combat facts.',
    ],
  },
  {
    slug: 'armoury',
    name: 'Armoury rebuilding',
    station: 'The Armoury',
    stationID: 'armoury',
    summary:
      'Rebuild one existing protective item in place as a rigid, insulated or balanced construction.',
    access: ['Build the Armoury.', 'Choose an eligible stored or worn protective item.'],
    materialChoice: 'Choose the exact body, layer, lining, binding, and fitting samples accepted by the selected Rigid, Insulated, or Balanced profile.',
    commitResult: 'A committed rebuild spends the selected samples and shown Essence, replaces the protection profile, and preserves the item’s stable physical history.',
    howItWorks: [
      'Choose an eligible stored or worn protective item.',
      'Choose one exact sample for each layer, body, binding or fitting.',
      'The rebuild keeps the item identity but replaces its construction profile and spends the shown Essence.',
    ],
  },
  {
    slug: 'instruments',
    name: 'Field Instruments',
    station: 'The Survey Post',
    stationID: 'survey_post',
    summary:
      'Study permanent world-reading capabilities at the Survey Post, then improve them to Good or Fine precision.',
    access: ['Build the Survey Post and study one of the eight named Research nodes.'],
    materialChoice: 'Good and Fine improvements automatically use the weakest exact samples that meet the instrument’s displayed property requirement.',
    commitResult: 'Research grants one named subject at Crude precision. A committed improvement spends its shown Essence and qualifying samples, then raises that permanent capability to Good or Fine.',
    howItWorks: [
      'Study one named instrument from Field Instruments Research; it becomes a permanent capability rather than an item.',
      'Choose the owned subjects to pack at Home; departure freezes their set and precision for that world.',
      'Use Survey in the world to record every valid carried subject for one turn.',
      'At the Survey Post, review and commit a Good or Fine precision improvement when the exact costs are ready.',
    ],
  },
  {
    slug: 'distillery',
    name: 'Distilled Cores',
    station: 'The Distillery',
    stationID: 'distillery',
    summary:
      'Directly attune Heat, Caustic, or Light through qualifying exact materials and 16 Essence.',
    access: ['Auber has enabled and the Distillery is built.', 'The selected attunement, its exact material, catalyst, 16 Essence, and output storage are available.'],
    materialChoice: 'Choose the qualifying provenance-bearing sample and exact catalyst named by the selected attunement preview.',
    commitResult: 'A committed attunement spends 16 Essence and its listed inputs to create the selected Heat, Caustic, or Light Core. There is no blank-core step.',
    howItWorks: [
      'Choose Heat, Caustic, or Light attunement.',
      'Select a qualifying provenance-bearing sample and the exact catalyst.',
      'Spend 16 Essence to create the selected Core.',
    ],
  },
  {
    slug: 'channelworks',
    name: 'Heat Conduit Fixture',
    station: 'The Channelworks',
    stationID: 'channelworks',
    summary: 'Convert one valid player-made Heat Core into one stored Heat Conduit Fixture.',
    access: ['Oda has enabled and the Channelworks is built.', 'One valid Heat Core remains in the quoted custody and the Fixture has room.'],
    materialChoice: 'The process accepts the exact valid Heat Core named by the preview; it has no substitute catalyst or generic material selection.',
    commitResult: 'A committed process consumes the Heat Core and stores the Fixture. The current loop ends at that stored Fixture.',
    howItWorks: [
      'Select the valid Heat Core shown by the station.',
      'Review the exact input and output destination.',
      'Commit one Fixture only when the quoted Core and storage remain valid.',
    ],
  },
  {
    slug: 'anchorage',
    name: 'Anchor Frame',
    station: 'The Anchorage',
    stationID: 'anchorage',
    summary: 'Assemble one portable Anchor Frame from six distinct exact materials and Essence.',
    access: ['Tovin has enabled and the Anchorage is built.', 'Six distinct selected materials, 60 Essence, and output custody remain valid.'],
    materialChoice: 'Choose two materials with hardness 65+, two with density 65+, one with flexibility 55+, and one with reactivity 65+. No selected material may fill two positions.',
    commitResult: 'A committed frame spends its exact six selected units and 60 Essence, then stores one Frame in the quoted Storehouse or Waiting destination. Its later field use belongs to a valid natural anchoring route.',
    howItWorks: [
      'Fill each of the six distinct property positions.',
      'Review the selected material history and 60 Essence cost.',
      'Commit one portable Anchor Frame into the shown custody.',
    ],
  },
  {
    slug: 'refinery',
    name: 'Raw Essence refining',
    station: 'Essence Spring',
    stationID: 'essence_spring',
    summary:
      'Convert Raw Essence into spendable Essence Crystals at the current refinement rate.',
    access: ['Open the Essence Spring.'],
    materialChoice: 'Choose a stored Raw Essence amount or use the available refine-all action.',
    commitResult: 'A committed refinement converts the chosen Raw Essence at the exact rate shown in the current preview; later capability can improve that rate.',
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
    stationID: 'writing_desk',
    summary:
      'Prepare CMY and Depth ink applications for eligible source marks on a Page.',
    access: ['Open the Writing Desk and choose eligible source marks on a Page.'],
    materialChoice: 'Choose Cyan, Magenta, Yellow, and Depth proportions from Copper, Ichor, Sulfur, and Obsidian stock; Resin seals the vial.',
    commitResult: 'A committed preparation creates a 12-application vial. Binding spends one matching application for each inked source it uses.',
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
    readiness: 'Current once the Apothecary is built; this is the immediate prepared remedy at construction.',
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
    readiness: 'Current Tier 0 Bowyer recipe once the Bowyer is built.',
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
    readiness: 'Current Tier 1 Bowyer recipe after the named Broaden capability is available.',
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
    readiness: 'Current Tier 1 Bowyer recipe after the named Broaden capability is available.',
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
    readiness: 'Current Tier 0 Weaponsmith recipe once the Weaponsmith is built.',
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
    readiness: 'Current Tier 1 Weaponsmith recipe after the named Broaden capability is available.',
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
    readiness: 'Current Tier 1 Weaponsmith recipe after the named Broaden capability is available.',
  },
  {
    id: 'fitted-polearm',
    name: 'Fitted Polearm',
    system: 'weaponsmith',
    result: 'Fitted Polearm',
    ingredients: [
      ...e('Point', ['ore', 'adamant', 'obsidian', 'quartz']),
      ...e('Haft', ['timber', 'ore', 'adamant']),
      ...e('Fitting', ['copper', 'silver', 'gold', 'quartz', 'adamant']),
    ],
    readiness: 'Current Weaponsmith recipe after Maud’s fitting pattern is known.',
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
    readiness: 'Current Tier 0 Armoury profile once the Armoury is built.',
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
    readiness: 'Current Tier 1 Armoury profile after the named Broaden capability is available.',
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
    readiness: 'Current Tier 1 Armoury profile after the named Broaden capability is available.',
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
      { label: 'Toxin or Ichor catalyst', role: 'exact catalyst' },
      { label: '1 qualifying Reagent, Toxin, or Ichor sample', role: 'selected sample' },
      { label: '16 Essence', role: 'currency' },
    ],
  },
  {
    id: 'light-core',
    name: 'Light Core',
    system: 'distillery',
    result: 'Light Core',
    ingredients: [
      r('silver', 2),
      { label: '1 qualifying lustrous and hard sample', role: 'selected sample' },
      { label: '16 Essence', role: 'currency' },
    ],
  },
  {
    id: 'conduit-fixture',
    name: 'Conduit Fixture',
    system: 'channelworks',
    result: 'Conduit Fixture',
    ingredients: [{ label: '1 valid Heat Core', role: 'consumed item' }],
  },
  {
    id: 'anchor-frame',
    name: 'Anchor Frame',
    system: 'anchorage',
    result: 'Anchor Frame',
    ingredients: [
      { label: '2 distinct hard 65+ materials', role: 'selected materials' },
      { label: '2 distinct dense 65+ materials', role: 'selected materials' },
      { label: '1 flexible 55+ material', role: 'selected material' },
      { label: '1 reactive 65+ material', role: 'selected material' },
      { label: '60 Essence', role: 'currency' },
    ],
    notes: 'No exact material may fill two positions.',
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

export function recipeReadiness(recipe: CraftRecipe) {
  return recipe.readiness ?? 'Current once the named station, recipe knowledge, exact inputs, and output custody shown by its preview are ready.';
}

export const definedButNotLiveCrafting = [
] as const;

export const scheduledButNotLiveStations = [
  'Menagerie and Deep Works are scheduled construction concepts, not current player stations or recipe routes.',
] as const;

export function definedButNotLiveForSystem(slug: string) {
  return definedButNotLiveCrafting.filter((entry) => entry.system === slug);
}
