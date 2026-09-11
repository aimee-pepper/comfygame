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
  ['Down', 'A separate soft body-feather layer. Its source and optional Insulated lining use are proposed, not implemented.'],
  ['Feather', 'A developed vane or flight feather.'],
  ['Fin', 'Legacy projected family. The new proposal recovers Membrane only from a real measured skin web; solid fleshy fins give no generic token.'],
  ['Scale', 'Overlapping individual hard covering.'],
  ['Plate', 'Legacy projected family. New anatomy resolves Armoured Scales, Chitin Plate or actual Shell rather than universal Plate.'],
  ['Chitin', 'A segmented, jointed hard case.'],
  ['Shell', 'A rigid enclosing or radial case.'],
  ['Quill', 'Legacy long hard covering. Build376 distinguishes Protective Spines from actual feather quills.'],
  ['Bone', 'Mineralized internal structure.'],
  ['Fang', 'Requires an actual tooth-bearing part; piercing damage alone does not establish a new typed source.'],
  ['Claw', 'Requires actual claw anatomy; rending damage or limbs alone do not establish a new typed source.'],
  ['Tusk', 'Requires an actual tusk; crushing damage alone does not establish a new typed source.'],
  ['Horn', 'A cranial horn used as bracing or crushing stock.'],
  ['Oil', 'Proposed actual oil reservoir and combustible chemistry, with an optional Heat Core use; not implemented. Water and insulation are insufficient.'],
  ['Venom', 'Proposed gland, duct, injection structure and Poison-preparation chemistry; not implemented. Contact toxicity alone is insufficient.'],
  ['Ichor', 'Proposed dye-bearing body fluid with explicit Magenta chemistry; not implemented. Emanation does not establish fluid or pigment.'],
] as const;

export const lootPaths = [
  {
    name: 'World deposits and plants',
    current:
      'Harvesting gives the resource named by the deposit or plant. Returned stock is still held as counted resources or individual material samples, depending on the source.',
    accepted:
      'Mined yields become simple exact-name quantities with one normal/green presentation and no quality. Flora yields are ungraded physical type/subtype stacks by default. Creature yields use quality where their material rules call for it. Ordinary plants remain safe; only clearly dangerous placements own contact harm.',
  },
  {
    name: 'Generated creatures',
    current:
      'Build376 enables solid creature materials in newly written books: Fur Pelt, Overlapping Scales, Armoured Scales, Chitin, Chitin Plate, Shell, Protective Spines, Flight Feathers, Contour Feathers and useful Horn. Actual body parts determine what can be recovered. Existing books, creatures and earned stock keep their saved rules; Hide and Bone retain their existing recovery paths. Matching subtype and quality share one stack with exact variants inside. New fluids remain unimplemented.',
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
      'The discovery and its position stay unchanged. Mined rewards move to exact-name quantity stacks; flora rewards move to ungraded type/subtype stacks; quality-bearing creature rewards move to subtype-and-quality stacks.',
  },
  {
    name: 'Nearby territory finds',
    current:
      'Ordinary encounters do not yet award nearby objects after a victory.',
    accepted:
      'A future ordinary victory has one frozen 12% chance to reveal one habitat-appropriate non-creature object marked “Found nearby.” A successful roll uses 75% common, 20% uncommon, and 5% rare regional candidates and cannot award a unique, Page, Sigil, Mote, site, guardian, or apex reward.',
  },
  {
    name: 'Expedition Return',
    current:
      'The expedition result divides eligible carried holdings into recovered and lost lines. Material totals group by subtype and quality, with exact source variants retained inside; build376 includes the new solid materials.',
    accepted:
      'Recovered plus lost will equal the exact carried quantity for every ungraded mined or flora stack and every quality-bearing creature stack. Protected stock brought from the Cottage returns in full, and replay cannot duplicate either side.',
  },
  {
    name: 'Trading, crafting, and recycling',
    current:
      'Different services currently use a mixture of counted resources, individual material samples, and finished items.',
    accepted:
      'Every trade, recipe, and Recycler choice names the exact material, applicable subtype and quality, and quantity involved. Mined and ordinary flora materials never show a quality choice. When creature-material quality matters, the player chooses it; another grade is never silently sold, crafted, or recycled. Source detail appears only when it changes the result.',
  },
] as const;

const apothecaryChanges: CraftingChange[] = ([
  ['Lesser Salve', "Delivered in build322: 1 Resin + 1 Stem/Leaf Fibre; 0 Essence; existing healing effect.", "Complete first pass: 1 Resin + 1 Stem/Leaf Fibre; 0 Essence; existing healing effect."],
  ['Salve', "Delivered in build322: 1 Cloth + 2 Soothing Leaf + 1 Resin; 0 Essence.", "Complete first pass: 1 Cloth + 2 Soothing Leaf + 1 Resin; 0 Essence."],
  ['Greater Salve', "Delivered in build322: 1 Cloth + 2 Soothing Leaf + 2 Restorative Spore + 2 Resin; 0 Essence.", "Complete first pass: 1 Cloth + 2 Soothing Leaf + 2 Restorative Spore + 2 Resin; 0 Essence."],
  ['Clearing Draught', "Delivered in build322: 1 Bitter Root + 1 Salt; 0 Essence.", "Complete first pass: 1 Bitter Root + 1 Salt; 0 Essence."],
  ['Quenching Draught', "Delivered in build322: 2 Soothing Leaf + 1 Salt; 0 Essence; presented as Quenching Balm.", "Complete first pass: 2 Soothing Leaf + 1 Salt; 0 Essence; presented as Quenching Balm."],
  ['Broad Antidote', "Delivered in build322: 1 Bitter Root + 1 Restorative Spore + 1 Salt; 0 Essence.", "Complete first pass: 1 Bitter Root + 1 Restorative Spore + 1 Salt; 0 Essence."],
  ['Stonebark Tonic', "Delivered in build322: 1 Tough Bark + 1 Resin; 0 Essence.", "Complete first pass: 1 Tough Bark + 1 Resin; 0 Essence."],
  ['Venom coating', "Delivered in build322: 1 Toxic Sap + 1 Stem/Leaf Fibre; 0 Essence; exact weapon retains coating for the excursion.", "Complete first pass: 1 Toxic Sap + 1 Stem/Leaf Fibre; 0 Essence; exact weapon retains coating for the excursion."],
  ['Firebrand', "Delivered in build322: 1 Sulfur + 1 Resin; 0 Essence; exact weapon retains coating for the excursion.", "Complete first pass: 1 Sulfur + 1 Resin; 0 Essence; exact weapon retains coating for the excursion."],
  ['Briar Oil', "Delivered in build322: 2 Stem/Leaf Fibre + 1 Resin; 0 Essence; mixed sources allowed; coating lasts the excursion.", "Complete first pass: 2 Stem/Leaf Fibre + 1 Resin; 0 Essence; mixed sources allowed; coating lasts the excursion."],
  ['Flashsalt', "Delivered in build322: 1 Quartz + 1 Sulfur + 1 Salt; 0 Essence; coating lasts the excursion.", "Complete first pass: 1 Quartz + 1 Sulfur + 1 Salt; 0 Essence; coating lasts the excursion."],
  ['Solvent', "Delivered in build322: 1 Bitter Root + 1 Sulfur; 0 Essence.", "Complete first pass: 1 Bitter Root + 1 Sulfur; 0 Essence."],
  ['Lure', "Delivered in build322: 1 Aromatic Leaf + 1 Stem/Leaf Fibre; 0 Essence.", "Complete first pass: 1 Aromatic Leaf + 1 Stem/Leaf Fibre; 0 Essence."],
  ['Stillwater', "Delivered in build322: 1 Rift-glass + 1 Mercury + 6 Essence.", "Complete first pass: 1 Rift-glass + 1 Mercury + 6 Essence."],
  ['Waystone', "Delivered in build322: 1 Rift-glass + 1 Quartz + 12 Essence + 1 Mote.", "Complete first pass: 1 Rift-glass + 1 Quartz + 12 Essence + 1 Mote."],
  ['Torch', "Delivered in build322: 1 Resin + 1 Log + 1 Stem/Leaf Fibre; 0 Essence.", "Complete first pass: 1 Resin + 1 Log + 1 Stem/Leaf Fibre; 0 Essence."],
  ['Farsight Draught', "Delivered in build322: 1 Quartz + 1 Restorative Spore; 0 Essence.", "Complete first pass: 1 Quartz + 1 Restorative Spore; 0 Essence."],
  ['Scent Mask', "Delivered in build322: 2 Aromatic Leaf + 1 Resin; 0 Essence.", "Complete first pass: 2 Aromatic Leaf + 1 Resin; 0 Essence."],
  ['Seamlight', "Delivered in build322: 1 Quartz + 1 Resin + 1 Stem/Leaf Fibre; 0 Essence; guides toward a portal without creating light.", "Complete first pass: 1 Quartz + 1 Resin + 1 Stem/Leaf Fibre; 0 Essence; guides toward a portal without creating light."],
] as const).map(([name, current, accepted]) => ({ name, current, accepted }));


export const craftingFamilyStatus: CraftingFamilyStatus[] = [
  {
    slug: 'refinery',
    name: 'Essence Spring',
    status: 'Playable now',
    current: 'Refine Raw Essence manually at 2 Essence each, or 3 after Second Pass. Continuous Settling can refine newly returned Raw Essence.',
    accepted: 'No replacement rate is specified here. Current rates remain the reference; future prices and progression are revisable tuning. Returned material storage becomes consistent.',
    changes: [
      { name: 'Refine Raw Essence', current: 'Choose a positive amount and spend it for the displayed return.', accepted: 'Unchanged.' },
      { name: 'Second Pass', current: 'Raises the return to 3 Essence for each Raw Essence.', accepted: 'Unchanged.' },
      { name: 'Continuous Settling', current: 'Refines newly returned Raw Essence when enabled; it is not passive offline production.', accepted: 'Unchanged.' },
    ],
  },
  {
    slug: 'apothecary',
    name: 'Apothecary',
    status: 'Playable now',
    current: 'All nineteen actual-ingredient preparations, acquisition learning, named sources, source colour and full-excursion exact-weapon coatings are delivered. The separately labelled legacy route preserves older stock.',
    accepted: 'Keep all nineteen results and their completed Field uses, while replacing arbitrary hidden-property samples with recognizable physical ingredients.',
    changes: apothecaryChanges,
  },
  {
    slug: 'blacksmith',
    name: 'Blacksmith',
    status: 'Playable now',
    current: 'Build324 delivers seven equipment families with exact world/Bone components, tier gates, quarter statistics, frozen prices and same-item refitting. Build376 adds2 Shell as a Shield face or1 useful Horn as a short blade grip, retaining ordinary supporting costs. Pick/Axe/Scythe, smelting and T3 retain their delivered tool progression.',
    accepted: 'Raw-material starter equipment, Ingots at T2, actual material identity, separate workmanship/statistics and current-component recovery. The first Forge pass implements these decisions. Build328 adds Iron Collar at T2 after Weaponsmith or Armoury construction; Peerless refinement remains unfinished.',
    changes: [
      { name: 'Pointed Blade', current: 'T1: choose a working point and separate short grip. Raw Iron uses 4 Iron +1 Coal, with 1 Log +2 Fibre grip; 0 Essence, Power2.0.', accepted: 'Exact Bone, Quartz, useful Horn grip and T2 Ingot alternatives follow the complete current recipe table.' },
      { name: 'Cutting Blade', current: 'T1: one complete cutting-edge bundle and separate short grip.', accepted: 'The working edge alone supplies Power; support quality can affect workmanship.' },
      { name: 'Hand Maul', current: 'T1: complete crushing-head bundle and paid haft/wrap.', accepted: 'No repeated stat bonus from the number of construction portions.' },
      { name: 'Long Spear', current: 'T2: complete point bundle and long haft/wrap.', accepted: 'Pierce/Mid identity; actual selected components determine Power.' },
      { name: 'Shield', current: 'T1: Iron, T2 Ingot, Softwood/Hardwood, Bone or2 Shell face and a separate brace/wrap.', accepted: 'The face supplies Protection; components retain their own source identity.' },
      { name: 'Helm', current: 'T2: complete hard working bundle plus the selected Fibre or Cloth lining.', accepted: 'Exact component price and recovery; lining adds no hidden Protection.' },
      { name: 'Rigid Guard', current: 'T2: complete structural bundle, lining and binding.', accepted: 'Quarter Protection and separate four-band workmanship.' },
      { name: 'Field Pick', current: 'The same owned tool advances through its existing T1–T3 route, alongside Axe and Scythe.', accepted: 'No second craftable Pick, free tool or tool-dismantling route.' },
      { name: 'Refit', current: 'T2: replace a chosen component bundle on the same owned piece and recover displaced current components once.', accepted: 'No old additive Reforge on new Forge gear; history and spent fuel do not create refunds.' },
    ],
  },
  {
    slug: 'tannery',
    name: 'Tannery',
    status: 'Playable now',
    current: 'Build323 delivers one-part Leather, seven garment variants, independent panels, exact component prices, same-item refit/remake and current-component recovery. Ordered source swatches retain actual textile colours; unknown RGB stays unknown.',
    accepted: 'Useful woven clothing before animal materials or Ingots, no ordinary crafting Essence toll, actual source quality/colour, and preserved Carry progression. The first complete Tannery pass now implements these decisions; additional creature-material roles remain separate proposals.',
    changes: [
      { name: 'Leather', current: 'One eligible Skin/Hide plus one Salt makes one Leather, preserving that source and its actual input value.', accepted: 'One-to-one preparation; no invented blend or automatic repricing of older material.' },
      { name: 'Seven garments', current: 'Woven, Buckled Woven and Leather Guards; Woven/Leather Gloves; Woven/Leather Boots. Leather panels are chosen independently.', accepted: 'Exact components and previewed Protection/workmanship, with no hidden-property sample or crafting Essence fee.' },
      { name: 'Refit and remake', current: 'Keep the same item, use the selected complete replacement bundle, and return displaced attached components once.', accepted: 'Prepared components recover without their raw ancestors; history never supplies a second refund.' },
    ],
  },
  {
    slug: 'bowyer',
    name: 'Bowyer',
    status: 'Playable now',
    current: 'Build325 delivers all three families and refit at Fen’s built Bowyer. Base foundation: 30 Essence, 6 Logs, 2 Cord, 2 Resin. Ordinary crafting and refit cost no Essence.',
    accepted: 'Actual selected parts determine quarter-Power, four-band workmanship and frozen component price. All three retain physical Far reach and excursion-long coatings without ammunition.',
    changes: [
      { name: 'Longbow', current: '1 Ingot, 2 Quartz or 1 Bone for points; 2 Hardwood Logs, 1 Resin and 1 Cord for support.', accepted: 'Pierce/Far; actual Hardwood limbs and source-preserving points.' },
      { name: 'Sling', current: '2 Clay plus 1 Coal, 1 Ingot or 1 Bone for shot; 2 Cord and a Cloth or Leather pouch.', accepted: 'Crush/Far; Clay offers an animal-free route without Forge upgrades.' },
      { name: 'Throwing Set', current: 'Choose each of two edges independently from 1 Ingot or 1 Bone; Cloth or Leather carrier plus 1 Cord.', accepted: 'Rend/Far; average the two edge contributions before final Power rounding.' },
      { name: 'Hafts', current: 'Maud teaches both recipes. At the Bowyer, 1 matching Log makes 1 Softwood or Hardwood Haft for no Essence; sale1/buy2 Gold.', accepted: 'Retain the actual source wood colour; Longbow limbs remain Logs.' },
      { name: 'Refit and recovery', current: 'Keep the same weapon during refit and return displaced attached components once.', accepted: 'Recover only current attached parts, without fuel, raw ancestors or historical duplicate refunds.' },
    ],
  },
  {
    slug: 'weaponsmith',
    name: 'Weaponsmith',
    status: 'Playable now',
    current: 'Build328 delivers four families and six damage/reach choices. Base foundation:40 Essence,4 Ingots,2 Hafts,2 Cord. Ordinary crafting and refit cost no Essence.',
    accepted: 'Actual source parts, quarter-Power,70/30 workmanship, frozen component values and same-item recovery. Polearm retains its diary-pattern gate.',
    changes: [
      { name: 'Fitted Point and Edge', current: 'Point uses2 Ingots,2 Quartz or1 Bone; Edge uses2 Ingots or1 Bone. Add1 Haft, Cord or Leather wrap, and1 Iron or Bone Collar.', accepted: 'Point is Pierce/Close; Edge Rend/Close. Softwood or Hardwood Haft is valid.' },
      { name: 'Fitted Maul', current: '2 Ingots or2 Bone,1 Hardwood Haft, Cord or Leather wrap, and1 Collar.', accepted: 'Crush/Close; actual working components determine Power.' },
      { name: 'Fitted Polearm', current: 'Requires Maud’s actual fitting diary. Choose Pierce/Rend/Crush with its corresponding head,2 Hardwood Hafts,2 Cord or2 Leather, and1 Collar.', accepted: 'Mid reach; construction does not grant the diary pattern.' },
      { name: 'Fitting and refit', current: 'Balanced adds1 Initiative; Driving adds0.75 Power. Home fitting changes use the same parts for no Essence.', accepted: 'Keep exact item identity; recover only current attached parts, never duplicate ancestors or fuel.' },
      { name: 'Collars', current: 'ForgeT2:2 Iron+Coal makes Iron Collar with Weaponsmith or Armoury construction knowledge. Built Maud:1 typed Bone makes Bone Collar. Both cost0 Essence.', accepted: 'Iron sale4/buy8; Bone preserves its actual source and band/value. Recover Collars as Collars.' },
    ],
  },
  {
    slug: 'armoury',
    name: 'Armoury',
    status: 'Changing in a future update',
    current: 'Rigid Shell, Insulated Layer, and Balanced Laminate rebuild one chosen eligible protective item.',
    accepted: 'Each profile keeps the item’s identity and replaces hidden property samples with named body, lining, binding, and fitting families.',
    changes: ['Rigid Shell', 'Insulated Layer', 'Balanced Laminate'].map((name) => ({ name, current: 'Playable by rebuilding one chosen item.', accepted: 'The same rebuild uses recognizable layer categories and player-selected creature-material quality where applicable, with fixed ungraded mined and flora contributions and all resulting stats shown before confirmation.' })),
  },
  {
    slug: 'instruments',
    name: 'Field Instruments',
    status: 'Changing in a future update',
    current: 'All eight instruments are permanent Research capabilities. Good and Fine precision upgrades are playable and automatically use the weakest individual samples that meet their property requirements.',
    accepted: 'The complete Design first-pass plan now specifies the foundation, eight initial instruments and sixteen improvements. Named parts replace property hunts; permanent ownership, actual field calibration and the separate page-lens gates stay intact. Implementation is pending; Good/Fine retain 20/50 Essence service fees as tuning.',
    changes: [
      { name: 'Level', current: 'Uses qualifying dense samples.', accepted: 'Good uses Ingot and Cord; Fine uses Ingots, a Hardwood Log and Cord. Initial study needs only Iron, a Log and Plant Fibre.' },
      { name: 'Hygrometer', current: 'Uses qualifying flexible samples.', accepted: 'Good uses Cord and Resin; Fine uses Cloth, Ingot and Resin. Initial study needs Plant Fibre, Iron and Resin.' },
      { name: 'Sunglass and Loupe', current: 'Use qualifying lustrous or hard samples.', accepted: 'Worked Quartz and Resin supply the optics, Ingots the Fine mounts; Good Sunglass also uses Coal for its smoked viewing surface. No unrelated feather, shell or hard sample substitutes.' },
      { name: 'Thermoscope and Barometer', current: 'Use qualifying insulating or dense samples.', accepted: 'Mercury, Quartz and Resin form their measuring chambers; Fine adds an Ingot support. Each has its complete distinct quantity table.' },
      { name: 'Vivometer', current: 'Uses qualifying reactive samples.', accepted: 'Restorative Spore, Quartz and Resin support calibration, with an Ingot for Fine. No generic Reagent, Ichor or unfinished animal-fluid source is required.' },
      { name: 'Chronometer', current: 'Uses qualifying lustrous samples.', accepted: 'Ingots, Quartz and Resin supply the mechanism and reference; Fine adds Mercury. It is an independent choice, without buying seven instruments first.' },
    ],
  },
  {
    slug: 'writing-ink',
    name: 'Scriptorium and prepared ink',
    status: 'Partly playable',
    current: 'Penmanship, prepared ink, Compound Assembly and Seamward exist under the older costs. Chaining lists a Mote its current purchase path cannot safely spend. The full replacement is pending.',
    accepted: 'The complete Design first pass specifies all writing/lens costs, Pulp and pigment sources while preserving hands, exact ink, Compounds, inscriptions and old campaigns. Build331 delivers the zero-rune opening with its paired introductory teaching and knowledge correction, independently of the later shop replacement. Lantern/Light details remain separately unresolved.',
    changes: [
      { name: 'Foundation and Brush', current: 'Foundation 60 Essence with Timber/Clay; Brush 45 Essence with Copper/Fibre/Timber.', accepted: 'Foundation 30 Essence, 8 Logs, 4 Clay; Brush 35 Essence, 2 Iron, 4 Plant Fibre, 1 Log. The existing hand/footprint progression stays.' },
      { name: 'Table and independent practices', current: 'Table 70, Ink Mixing 40, Compound Assembly 55 Essence with older material bills.', accepted: 'Table 35, Ink Mixing 30 and Compound Assembly 40 Essence with complete named ingredients. Ink, Compounds and Chaining remain independent Brush-child practices.' },
      { name: 'Chaining, frame and Fountain', current: '90 Essence/2 Mercury/1 Mote for Chaining, with Mote payment unfinished; frame 140 and Fountain 220 Essence.', accepted: 'Chaining retains its full bill and must spend actual Mote currency once; frame becomes 80 and Fountain 150 Essence with Ingots, Quartz, wood/seals as listed. Existing keeper-tier alternatives remain.' },
      { name: 'Page lens', current: 'Four sequential upgrades use 2/4/6/8 field-calibrated subjects and earlier ingredient lists.', accepted: 'Retain calibration and explanation depth; new fees are 40/70/110/160 Essence with the full named optical/calibration bills. No new Brush prerequisite.' },
      { name: 'Pulp and ink', current: 'Vials use Copper/Ichor/Sulfur/Obsidian and Resin; each gives 12 applications.', accepted: "Two Plant Fibre makes two Pulp. The new primary Magenta source is Dyer's Root, with explicit legacy Ichor support. Keep four measures per source, exact formulas, just-in-time preparation, Resin and 12 applications." },
      { name: 'Compounds and Seamward', current: 'Formalization costs 20 Essence/4 Pulp; Seamward uses a Seamlight, 10 Essence and Ash/prepared ink on eligible gear.', accepted: 'Retain those service bills, exact identity, knowledge and supported inscription behavior. Seamward guides during collapse and never creates illumination; erasure refunds nothing.' },
    ],
  },
  {
    slug: 'recycler',
    name: 'Recycler',
    status: 'Changing in a future update',
    current: 'Dismantles one selected eligible, unequipped piece and returns its recorded construction materials or listed salvage.',
    accepted: 'Returns each mined input and ordinary flora input to its exact-name or subtype ungraded stack, and each creature input to its recorded type/subtype, quality, colour/source detail, and quantity. Ambiguous old salvage remains visible Legacy stock until an exact use or exchange is chosen.',
    changes: [{ name: 'Dismantle gear', current: 'One selected eligible piece; protected, equipped, malformed, and undefined pieces are refused.', accepted: 'Keep the same protections and return the selected material types, qualities, and quantities recorded when the item was made.' }],
  },
  {
    slug: 'distillery',
    name: 'Distillery',
    status: 'Partly playable',
    current: 'Heat, Caustic, and Light Cores are made directly for 16 Essence plus their catalyst and one individual sample that meets the hidden requirements. There is no Blank Core step.',
    accepted: 'Complete first-pass plan: a 60-Essence foundation plus materials; all three named-material recipes cost 16 Essence and produce potency 60. Older Cores retain their real potency. Promote combat use only with delivered housings.',
    changes: [
      { name: 'Blank Core', current: 'Not available.', accepted: 'Do not add a Blank Core step.' },
      { name: 'Heat Core', current: '16 Essence, 2 Sulfur, and one qualifying reactive or insulating sample.', accepted: 'First pass: 16 Essence, 2 Sulfur and 1 World Resin, potency 60. Creature Oil remains a later producer-dependent alternative.' },
      { name: 'Caustic Core', current: '16 Essence, Toxin or Ichor catalyst, and one qualifying Reagent, Toxin, or Ichor sample.', accepted: 'First pass: 16 Essence, 2 Toxic Sap and 1 Salt, potency 60. Other proposed substances await actual producers; no generic Reagent/Toxin or extra property sample.' },
      { name: 'Light Core', current: '16 Essence, 2 Silver, and one qualifying lustrous and hard sample.', accepted: 'First pass: 16 Essence, 2 Silver and 1 Quartz, potency 60; combat use only when Light housing is playable.' },
    ],
  },
  {
    slug: 'channelworks',
    name: 'Channelworks',
    status: 'Partly playable',
    current: 'Heat Core can become a stored Heat Fixture. The stored Fixture is not yet an equippable combat housing.',
    accepted: 'Complete first-pass plan covers Heat, Caustic and Light at Close/Mid/Far reach. A 70-Essence foundation plus materials restores Oda’s one starter; her existing schematic opens Close/Far. Retuning and rebuild services are specified. Light never illuminates the world.',
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
    accepted: 'Replace six hidden numerical searches with visible structural categories. Its exact category lists and quality-neutral sockets remain Game Design content work and stay marked Planned until implemented.',
    changes: [{ name: 'Anchor Frame', current: 'Two hard, two dense, one flexible, and one reactive individual sample, plus 60 Essence.', accepted: 'Visible structural-member, load-bearing, binding, and responsive-component selections plus 60 Essence; the final category lists remain under review.' }],
  },
];

export function craftingStatusFor(slug: string) {
  return craftingFamilyStatus.find((entry) => entry.slug === slug);
}

export function futureResourceCopy(name: string) {
  if (name === 'Raw Essence') return 'Raw Essence remains a quality-free precursor. Return it to the Cottage and refine it at the Essence Spring.';
  if (name === 'Mote') return 'Motes remain permanent Reality currency, with no material quality or storage slot.';
  if (name === 'Ichor') return 'A proposed dye-bearing Ichor source now requires actual fluid anatomy and explicit Magenta chemistry. It is not implemented; emanation alone is insufficient. Existing stock keeps its supported uses and provenance.';
  if (name === 'Rubble') return 'Rubble will remain a simple, ungraded mixed find. Noll’s Recycler will separate selected Rubble into materials supported by its source region: mostly common finds, less-frequent uncommon finds, and only a small chance of a rare local bonus.';
  if (['Clay', 'Ore', 'Iron Ore', 'Copper', 'Silver', 'Gold', 'Quartz', 'Obsidian', 'Salt', 'Sulfur', 'Mercury', 'Adamant', 'Rift-glass'].includes(name)) {
    const intendedName = name === 'Ore' || name === 'Iron Ore' ? 'Iron' : name;
    return `${intendedName} will be one simple exact-name quantity stack. It has no Poor, Common, Rare, or Exceptional variants and always uses the normal/green presentation. Its source does not split the stack.`;
  }
  if (['Fibre', 'Timber', 'Pulp', 'Resin', 'Toxin', 'Spore', 'Reagent'].includes(name)) {
    const intendedName = name === 'Timber' ? 'an exact Log type' : name === 'Fibre' ? 'an exact Plant Fibre type' : name === 'Toxin' || name === 'Reagent' ? 'the named physical substance' : name;
    return `${name} moves to ${intendedName}. Ordinary flora-derived stock is ungraded and stacks by physical type or subtype; species, colour, source, and useful measurements remain in expanded detail. Reagent and Toxin become recipe categories rather than inventory items.`;
  }
  return `${name} will use a recognizable physical type or subtype. Creature materials use the four quality bands where approved; ordinary flora remains ungraded. Source world, species where relevant, and inherited colour remain available in expanded history without needlessly splitting the stack.`;
}

export const openDecisions: ReadonlyArray<{ title: string; body: string }> = [{ title: 'Spending a Mote on a missed refinement', body: 'Should a Mote used in an incomplete setup be spent with no lasting improvement on a miss, or should every spent Mote guarantee lasting progress? Game Design recommends lasting progress. This is the existing Aimee Homework question; early crafting work can continue.' }];
export const openDecisionSummary = 'Open choices are maintained in Aimee Homework. Recipe tables, balance numbers, and implementation remain team work.';

export const acceptedChoices = [
  {
    title: 'Visible equipment materials keep their colours',
    body: 'Equipment and other visibly material-led gear preserve separate coloured regions for the materials the player selected. Standardized recognition-critical items such as potions and remedies keep their authored colours instead, so they remain easy to tell apart at a glance.',
  },
  {
    title: 'Obsidian forms the Waystone’s hard body',
    body: 'The intended Waystone recipe uses 1 Obsidian, 1 Rift-glass, 1 Mote, and 12 Essence. Obsidian forms the rigid carried instrument while Rift-glass remains the part that crosses a world boundary.',
  },
] as const;

export const laterDesignWork = [
  {
    title: 'Recipe and facility content pass',
    body: 'Game Design still needs to assign every recipe’s exact material categories, quantities, facility tier, unlock, output statistics, and first two sensible consumers, then check each station against the settled processing ratios and affordability limits.',
  },
  {
    title: 'Creature and habitat pass',
    body: 'Game Design still needs to finish body plans, habitat rules, material quantities, encounter populations, and the frequency and conditions for alpha equipment drops. The four creature-material quality bands and ordinary crafted-stat arithmetic are already settled.',
  },
  {
    title: 'World ecology and Sigil pass',
    body: 'Game Design still needs the complete terrain-to-flora compatibility table, creature ecology, weather transformations, teachable land vocabulary, Sigil acquisition order, and clue progression. These are production tasks, not unanswered product choices.',
  },
] as const;

export const correctionStatus = [
  {
    label: 'Must change',
    title: 'Material storage',
    body: 'The current game mixes counted World resources, individual material samples, and family-only summaries. The intended default is one exact-name quantity stack for each mined material, one ungraded type/subtype stack for ordinary flora, and one subtype-and-quality stack for each approved creature material, with species-specific source lots and colour in expanded detail. Alternate inventory views change only how materials are sorted, never where they are stored or who owns them.',
  },
  {
    label: 'Must change',
    title: 'Physically arbitrary recipe samples',
    body: 'Several recipes still accept unrelated materials because a hidden property number is high enough. Their replacements will use visible broad, specific, or precise physical categories.',
  },
  {
    label: 'Verification pending',
    title: 'Scent Mask and Seamlight field access',
    body: 'Both can be made. Field Kit use is unverified for the current phone build; earlier guide descriptions disagreed. The intended field actions apply scent masking or portal guidance, respectively, without granting a free item.',
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
    body: 'The future Frame replaces hidden property searches with visible physical roles. Its exact category lists and quality-neutral sockets remain Game Design content work and must stay marked Planned until they are available in the game.',
  },
] as const;
