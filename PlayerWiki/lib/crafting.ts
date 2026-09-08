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
  resourceIDs?: string[];
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
      'Make remedies, coatings and field supplies from the named physical ingredients in each recipe.',
    access: ['Build the Apothecary.', 'Use a recipe that is currently known.'],
    materialChoice: 'Select actual ingredient portions. Standardized preparations do not require an extra hidden-property sample; source details remain recorded.',
    commitResult: 'The named resources, Essence or Mote cost, and chosen material are spent together after the result has somewhere to go. You then receive the listed item.',
    howItWorks: [
      'Learn or infer the preparation.',
      'Choose the actual named ingredients shown by the recipe.',
      'Supply the named resources, Essence or Mote cost, then prepare one item.',
    ],
  },
  {
    slug: 'blacksmith',
    name: 'Blacksmith construction',
    station: 'Blacksmith',
    stationID: 'blacksmith',
    summary:
      'Construct seven Forge equipment families from actual working and support bundles; T1 opens four families and T2 opens the rest.',
    access: ['Build the Blacksmith.', 'Meet the selected recipe’s tier and knowledge requirements.'],
    materialChoice: 'Choose complete working and support bundles allowed by the equipment recipe. Exact parts determine statistics and separate workmanship.',
    commitResult: 'Making the selected Forge item spends its complete chosen component bundles together for no Essence.',
    howItWorks: [
      'Select a known equipment recipe and its complete working and support bundles.',
      'Review the resulting workmanship, combat statistics and complete ingredient cost.',
      'Constructing consumes the chosen components and fuel once, then creates the selected equipment.',
    ],
  },
  {
    slug: 'tannery',
    name: 'Tannery construction',
    station: 'The Tannery',
    stationID: 'tannery',
    summary:
      'Prepare Cord, Cloth and Leather, then craft the seven woven or Leather garment variants.',
    access: ['Build the Tannery.', 'Learn the required wear Research or reach the tier shown by the chosen pattern.'],
    materialChoice: 'Choose the Cord, Cloth, Leather panels and other named parts in the selected garment recipe. Exact source colours and independent Leather properties stay preserved.',
    commitResult: 'Making the garment spends its chosen components together for no Essence, then stores the selected Guard, Gloves or Boots.',
    howItWorks: [
      'Choose the actual Cloth, Leather, Cord and other components in the selected variant.',
      'Woven gear is Fine; Leather panels determine the Leather garment’s workmanship.',
      'Ordinary garment crafting and refit cost no Essence; selected components are consumed together.',
    ],
  },
  {
    slug: 'bowyer',
    name: 'Bowyer construction',
    station: 'The Bowyer',
    stationID: 'bowyer',
    summary:
      'Build far-reaching physical weapons without maintaining a separate ammunition inventory.',
    access: ['Build the Bowyer.', 'Learn the Research required by the chosen design.'],
    materialChoice: 'Choose the limbs, cord, projectile, edges, pouch, or grip from the material families accepted by that part of the recipe. The preview shows the quality those choices support.',
    commitResult: 'Making the weapon consumes the components in the preview and stores the selected longbow, sling, or throwing set.',
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
      'Build fitted points, edges, mauls, and polearms from compatible heads, supports, fittings, and a learned pattern.',
    access: ['Build the Weaponsmith.', 'Use the learned fitting pattern for the selected design.'],
    materialChoice: 'Choose the head or edge, supporting structure, and fitting from the metal or creature-material families accepted by each part of the recipe.',
    commitResult: 'Making the weapon spends all materials shown in the preview and stores their material details on the finished piece.',
    howItWorks: [
      'Select the head or edge, supporting structure and fitting.',
      'Choose one fitted design available at the station.',
      'The finished weapon keeps its selected materials and the combat statistics they produce.',
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
    materialChoice: 'Choose the body, layer, lining, binding, and fitting materials accepted by the selected Rigid, Insulated, or Balanced profile.',
    commitResult: 'Rebuilding spends the chosen materials and displayed Essence, replaces the protection profile, and keeps the same item and its history.',
    howItWorks: [
      'Choose an eligible stored or worn protective item.',
      'Choose one material for each layer, body, binding, or fitting.',
      'The rebuild keeps the same item but replaces its construction profile and spends the displayed Essence.',
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
    materialChoice: 'Good and Fine improvements automatically use the weakest materials that meet the instrument’s displayed requirement.',
    commitResult: 'Research teaches one named subject at Crude precision. An improvement spends its displayed Essence and qualifying materials, then permanently raises that subject to Good or Fine.',
    howItWorks: [
      'Study one named instrument from Field Instruments Research; it becomes a permanent capability rather than an item.',
      'Choose the owned subjects to pack at Home; departure freezes their set and precision for that world.',
      'Use Survey in the world to record every valid carried subject for one turn.',
      'At the Survey Post, review and confirm a Good or Fine precision improvement when you have all of its costs.',
    ],
  },
  {
    slug: 'distillery',
    name: 'Distilled Cores',
    station: 'The Distillery',
    stationID: 'distillery',
    summary:
      'Distil a Heat, Caustic, or Light Core from suitable materials, its named catalyst, and 16 Essence.',
    access: ['Meet Auber and build the Distillery.', 'Have the required material, catalyst, 16 Essence, and room for the finished Core.'],
    materialChoice: 'Choose a suitable material sample and the catalyst named by the selected attunement preview.',
    commitResult: 'Distilling spends 16 Essence and the listed ingredients together, then stores the selected Heat, Caustic, or Light Core. There is no blank-core step.',
    howItWorks: [
      'Choose Heat, Caustic, or Light attunement.',
      'Select a suitable material sample and the required catalyst.',
      'Spend 16 Essence to create the selected Core.',
    ],
  },
  {
    slug: 'channelworks',
    name: 'Heat Conduit Fixture',
    station: 'The Channelworks',
    stationID: 'channelworks',
    summary: 'Convert one valid player-made Heat Core into one stored Heat Conduit Fixture.',
    access: ['Meet Oda and build the Channelworks.', 'Have the Heat Core shown by the preview and room to store the Fixture.'],
    materialChoice: 'The process uses the specific Heat Core selected in the preview. It does not accept another catalyst or a generic material in its place.',
    commitResult: 'Confirming consumes the selected Heat Core and stores one Fixture. The playable process currently ends with that stored Fixture.',
    howItWorks: [
      'Select the valid Heat Core shown by the station.',
      'Review the selected Core and where the Fixture will be stored.',
      'Confirm only while that Core and storage space are still available.',
    ],
  },
  {
    slug: 'anchorage',
    name: 'Anchor Frame',
    station: 'The Anchorage',
    stationID: 'anchorage',
    summary: 'Assemble one portable Anchor Frame from six different materials and Essence.',
    access: ['Tovin has enabled and the Anchorage is built.', 'Six different selected materials, 60 Essence, and enough output space remain available.'],
    materialChoice: 'Choose two materials with hardness 65+, two with density 65+, one with flexibility 55+, and one with reactivity 65+. No selected material may fill two positions.',
    commitResult: 'Making a Frame spends the six chosen materials and 60 Essence together, then places one Frame in the Storehouse or Waiting destination shown. You can later use it at a suitable natural anchor.',
    howItWorks: [
      'Fill each of the six distinct property positions.',
      'Review the selected material history and 60 Essence cost.',
      'Create one portable Anchor Frame and place it in the destination shown.',
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
    commitResult: 'Refining converts the chosen Raw Essence at the rate shown in the preview. Later Research can improve that rate.',
    howItWorks: [
      'Choose an amount of stored Raw Essence or refine all.',
      'The preview shows how many Essence Crystals you will receive.',
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
    commitResult: 'Preparing the ink creates a vial with 12 applications. Binding spends one matching application for each inked source it uses.',
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
  {"id": "seamlight", "name": "Seamlight", "system": "apothecary", "result": "Seamlight", "ingredients": [{"label": "1 Quartz", "role": "component or cost", "resourceIDs": ["quartz"]}, {"label": "1 Resin", "role": "component or cost", "resourceIDs": ["resin"]}, {"label": "1 Plant Fibre", "role": "component or cost", "resourceIDs": ["fiber"]}], "notes": "Current actual-ingredient recipe, delivered322. Supported older stock has a separately labelled legacy route."},
  {"id": "scent-mask", "name": "Scent Mask", "system": "apothecary", "result": "Scent Mask", "ingredients": [{"label": "2 Aromatic Leaf", "role": "component or cost"}, {"label": "1 Resin", "role": "component or cost", "resourceIDs": ["resin"]}], "notes": "Current actual-ingredient recipe, delivered322. Supported older stock has a separately labelled legacy route."},
  {"id": "lesser-salve", "name": "Lesser Salve", "system": "apothecary", "result": "Lesser Salve", "ingredients": [{"label": "1 Resin", "role": "component or cost", "resourceIDs": ["resin"]}, {"label": "1 Plant Fibre", "role": "component or cost", "resourceIDs": ["fiber"]}], "notes": "Current actual-ingredient recipe, delivered322. Supported older stock has a separately labelled legacy route."},
  {"id": "salve", "name": "Salve", "system": "apothecary", "result": "Salve", "ingredients": [{"label": "1 Cloth", "role": "component or cost"}, {"label": "2 Soothing Leaf", "role": "component or cost"}, {"label": "1 Resin", "role": "component or cost", "resourceIDs": ["resin"]}], "notes": "Current actual-ingredient recipe, delivered322. Supported older stock has a separately labelled legacy route."},
  {"id": "greater-salve", "name": "Greater Salve", "system": "apothecary", "result": "Greater Salve", "ingredients": [{"label": "1 Cloth", "role": "component or cost"}, {"label": "2 Soothing Leaf", "role": "component or cost"}, {"label": "2 Restorative Spore", "role": "component or cost"}, {"label": "2 Resin", "role": "component or cost", "resourceIDs": ["resin"]}], "notes": "Current actual-ingredient recipe, delivered322. Supported older stock has a separately labelled legacy route."},
  {"id": "clearing-draught", "name": "Clearing Draught", "system": "apothecary", "result": "Clearing Draught", "ingredients": [{"label": "1 Bitter Root", "role": "component or cost"}, {"label": "1 Salt", "role": "component or cost", "resourceIDs": ["salt"]}], "notes": "Current actual-ingredient recipe, delivered322. Supported older stock has a separately labelled legacy route."},
  {"id": "quenching-draught", "name": "Quenching Draught", "system": "apothecary", "result": "Quenching Draught", "ingredients": [{"label": "2 Soothing Leaf", "role": "component or cost"}, {"label": "1 Salt", "role": "component or cost", "resourceIDs": ["salt"]}], "notes": "Current actual-ingredient recipe, delivered322. Supported older stock has a separately labelled legacy route."},
  {"id": "broad-antidote", "name": "Broad Antidote", "system": "apothecary", "result": "Broad Antidote", "ingredients": [{"label": "1 Bitter Root", "role": "component or cost"}, {"label": "1 Restorative Spore", "role": "component or cost"}, {"label": "1 Salt", "role": "component or cost", "resourceIDs": ["salt"]}], "notes": "Current actual-ingredient recipe, delivered322. Supported older stock has a separately labelled legacy route."},
  {"id": "stonebark-tonic", "name": "Stonebark Tonic", "system": "apothecary", "result": "Stonebark Tonic", "ingredients": [{"label": "1 Tough Bark", "role": "component or cost"}, {"label": "1 Resin", "role": "component or cost", "resourceIDs": ["resin"]}], "notes": "Current actual-ingredient recipe, delivered322. Supported older stock has a separately labelled legacy route."},
  {"id": "venom", "name": "Venom", "system": "apothecary", "result": "Venom", "ingredients": [{"label": "1 Toxic Sap", "role": "component or cost"}, {"label": "1 Plant Fibre", "role": "component or cost", "resourceIDs": ["fiber"]}], "notes": "Current actual-ingredient recipe, delivered322. Supported older stock has a separately labelled legacy route."},
  {"id": "firebrand", "name": "Firebrand", "system": "apothecary", "result": "Firebrand", "ingredients": [{"label": "1 Sulfur", "role": "component or cost", "resourceIDs": ["sulfur"]}, {"label": "1 Resin", "role": "component or cost", "resourceIDs": ["resin"]}], "notes": "Current actual-ingredient recipe, delivered322. Supported older stock has a separately labelled legacy route."},
  {"id": "briar-oil", "name": "Briar Oil", "system": "apothecary", "result": "Briar Oil", "ingredients": [{"label": "2 Plant Fibre", "role": "component or cost", "resourceIDs": ["fiber"]}, {"label": "1 Resin", "role": "component or cost", "resourceIDs": ["resin"]}], "notes": "Current actual-ingredient recipe, delivered322. Supported older stock has a separately labelled legacy route."},
  {"id": "flashsalt", "name": "Flashsalt", "system": "apothecary", "result": "Flashsalt", "ingredients": [{"label": "1 Quartz", "role": "component or cost", "resourceIDs": ["quartz"]}, {"label": "1 Sulfur", "role": "component or cost", "resourceIDs": ["sulfur"]}, {"label": "1 Salt", "role": "component or cost", "resourceIDs": ["salt"]}], "notes": "Current actual-ingredient recipe, delivered322. Supported older stock has a separately labelled legacy route."},
  {"id": "solvent", "name": "Solvent", "system": "apothecary", "result": "Solvent", "ingredients": [{"label": "1 Bitter Root", "role": "component or cost"}, {"label": "1 Sulfur", "role": "component or cost", "resourceIDs": ["sulfur"]}], "notes": "Current actual-ingredient recipe, delivered322. Supported older stock has a separately labelled legacy route."},
  {"id": "lure", "name": "Lure", "system": "apothecary", "result": "Lure", "ingredients": [{"label": "1 Aromatic Leaf", "role": "component or cost"}, {"label": "1 Plant Fibre", "role": "component or cost", "resourceIDs": ["fiber"]}], "notes": "Current actual-ingredient recipe, delivered322. Supported older stock has a separately labelled legacy route."},
  {"id": "stillwater", "name": "Stillwater", "system": "apothecary", "result": "Stillwater", "ingredients": [{"label": "1 Rift-glass", "role": "component or cost", "resourceIDs": ["rift_glass"]}, {"label": "1 Mercury", "role": "component or cost", "resourceIDs": ["mercury"]}, {"label": "6 Essence", "role": "component or cost"}], "notes": "Current actual-ingredient recipe, delivered322. Supported older stock has a separately labelled legacy route."},
  {"id": "waystone", "name": "Waystone", "system": "apothecary", "result": "Waystone", "ingredients": [{"label": "1 Rift-glass", "role": "component or cost", "resourceIDs": ["rift_glass"]}, {"label": "1 Quartz", "role": "component or cost", "resourceIDs": ["quartz"]}, {"label": "12 Essence", "role": "component or cost"}, {"label": "1 Mote", "role": "component or cost", "resourceIDs": ["mote"]}], "notes": "Current actual-ingredient recipe, delivered322. Supported older stock has a separately labelled legacy route."},
  {"id": "torch", "name": "Torch", "system": "apothecary", "result": "Torch", "ingredients": [{"label": "1 Resin", "role": "component or cost", "resourceIDs": ["resin"]}, {"label": "1 Log", "role": "component or cost", "resourceIDs": ["timber"]}, {"label": "1 Plant Fibre", "role": "component or cost", "resourceIDs": ["fiber"]}], "notes": "Current actual-ingredient recipe, delivered322. Supported older stock has a separately labelled legacy route."},
  {"id": "farsight", "name": "Farsight Draught", "system": "apothecary", "result": "Farsight Draught", "ingredients": [{"label": "1 Quartz", "role": "component or cost", "resourceIDs": ["quartz"]}, {"label": "1 Restorative Spore", "role": "component or cost"}], "notes": "Current actual-ingredient recipe, delivered322. Supported older stock has a separately labelled legacy route."},
  {"id": "pointed-blade", "name": "Pointed Blade", "system": "blacksmith", "result": "Pointed Blade", "ingredients": [{"label": "4 Iron + 1 Coal; or 2 Ingots; or 2 Quartz; or 1 Bone", "role": "component or cost", "resourceIDs": ["ore", "quartz"]}, {"label": "1 Log + 2 Fibre; or 1 Bone grip", "role": "component or cost", "resourceIDs": ["fiber", "timber"]}, {"label": "0 Essence", "role": "component or cost"}], "notes": "T1; Ingots require T2. Close, Pierce. Choose complete separate working/support bundles; source parts determine statistics."},
  {"id": "cutting-blade", "name": "Cutting Blade", "system": "blacksmith", "result": "Cutting Blade", "ingredients": [{"label": "4 Iron + 1 Coal; or 2 Ingots; or 1 Bone", "role": "component or cost", "resourceIDs": ["ore"]}, {"label": "1 Log + 2 Fibre; or 1 Bone grip", "role": "component or cost", "resourceIDs": ["fiber", "timber"]}, {"label": "0 Essence", "role": "component or cost"}], "notes": "T1; Ingots require T2. Close, Rend. Choose complete separate working/support bundles; source parts determine statistics."},
  {"id": "hand-maul", "name": "Hand Maul", "system": "blacksmith", "result": "Hand Maul", "ingredients": [{"label": "4 Iron + 1 Coal; or 2 Ingots; or 2 Bone", "role": "component or cost", "resourceIDs": ["ore"]}, {"label": "1 Log + 2 Fibre; or 2 Bone + 2 Fibre", "role": "component or cost", "resourceIDs": ["fiber", "timber"]}, {"label": "0 Essence", "role": "component or cost"}], "notes": "T1; Ingots require T2. Close, Crush. Choose complete separate working/support bundles; source parts determine statistics."},
  {"id": "long-spear", "name": "Long Spear", "system": "blacksmith", "result": "Long Spear", "ingredients": [{"label": "4 Iron + 1 Coal; or 2 Ingots; or 2 Quartz; or 1 Bone", "role": "component or cost", "resourceIDs": ["ore", "quartz"]}, {"label": "2 Logs + 4 Fibre; or 3 Bone + 4 Fibre", "role": "component or cost", "resourceIDs": ["fiber", "timber"]}, {"label": "0 Essence", "role": "component or cost"}], "notes": "T2; Ingots require T2. Mid, Pierce. Choose complete separate working/support bundles; source parts determine statistics."},
  {"id": "shield", "name": "Shield", "system": "blacksmith", "result": "Shield", "ingredients": [{"label": "4 Iron + 1 Coal; or 2 Ingots; or 2 Softwood Logs; or 2 Hardwood Logs; or 2 Bone", "role": "component or cost", "resourceIDs": ["ore", "timber"]}, {"label": "1 Log + 2 Fibre; or 1 Bone + 2 Fibre", "role": "component or cost", "resourceIDs": ["fiber", "timber"]}, {"label": "0 Essence", "role": "component or cost"}], "notes": "T1; Ingots require T2. Offhand protection. Choose complete separate working/support bundles; source parts determine statistics."},
  {"id": "helm", "name": "Helm", "system": "blacksmith", "result": "Helm", "ingredients": [{"label": "4 Iron + 1 Coal; or 2 Ingots; or 2 Bone", "role": "component or cost", "resourceIDs": ["ore"]}, {"label": "4 Fibre; or 1 Cloth lining", "role": "component or cost", "resourceIDs": ["fiber"]}, {"label": "0 Essence", "role": "component or cost"}], "notes": "T2; Ingots require T2. Head protection. Choose complete separate working/support bundles; source parts determine statistics."},
  {"id": "rigid-guard", "name": "Rigid Guard", "system": "blacksmith", "result": "Rigid Guard", "ingredients": [{"label": "8 Iron + 2 Coal; or 4 Ingots; or 4 Bone", "role": "component or cost", "resourceIDs": ["ore"]}, {"label": "Lining: 4 Fibre or 1 Cloth; binding: 2 Fibre or 1 Cord", "role": "component or cost", "resourceIDs": ["fiber"]}, {"label": "0 Essence", "role": "component or cost"}], "notes": "T2; Ingots require T2. Body protection. Choose complete separate working/support bundles; source parts determine statistics."},
  {"id": "woven-guard", "name": "Woven Guard", "system": "tannery", "result": "Woven Guard", "ingredients": [{"label": "1 Cloth, 1 Cord", "role": "component or cost"}, {"label": "0 Essence", "role": "component or cost"}], "notes": "Current garment variant, delivered323. Preserve actual textile constituents and independent Leather panels."},
  {"id": "buckled-woven-guard", "name": "Buckled Woven Guard", "system": "tannery", "result": "Buckled Woven Guard", "ingredients": [{"label": "2 Cloth, 1 Cord, 1 Iron Ingot", "role": "component or cost"}, {"label": "0 Essence", "role": "component or cost"}], "notes": "Current garment variant, delivered323. Preserve actual textile constituents and independent Leather panels."},
  {"id": "leather-guard", "name": "Leather Guard", "system": "tannery", "result": "Leather Guard", "ingredients": [{"label": "2 separately chosen Leather panels, 1 Cord", "role": "component or cost"}, {"label": "0 Essence", "role": "component or cost"}], "notes": "Current garment variant, delivered323. Preserve actual textile constituents and independent Leather panels."},
  {"id": "woven-gloves", "name": "Woven Gloves", "system": "tannery", "result": "Woven Gloves", "ingredients": [{"label": "1 Cloth, 1 Cord", "role": "component or cost"}, {"label": "0 Essence", "role": "component or cost"}], "notes": "Current garment variant, delivered323. Preserve actual textile constituents and independent Leather panels."},
  {"id": "leather-gloves", "name": "Leather Gloves", "system": "tannery", "result": "Leather Gloves", "ingredients": [{"label": "1 Leather, 1 Cord", "role": "component or cost"}, {"label": "0 Essence", "role": "component or cost"}], "notes": "Current garment variant, delivered323. Preserve actual textile constituents and independent Leather panels."},
  {"id": "woven-boots", "name": "Woven Boots", "system": "tannery", "result": "Woven Boots", "ingredients": [{"label": "1 Cloth, 1 Cord, 1 Resin", "role": "component or cost", "resourceIDs": ["resin"]}, {"label": "0 Essence", "role": "component or cost"}], "notes": "Current garment variant, delivered323. Preserve actual textile constituents and independent Leather panels."},
  {"id": "leather-boots", "name": "Leather Boots", "system": "tannery", "result": "Leather Boots", "ingredients": [{"label": "1 Leather, 1 Cord, 1 Resin", "role": "component or cost", "resourceIDs": ["resin"]}, {"label": "0 Essence", "role": "component or cost"}], "notes": "Current garment variant, delivered323. Preserve actual textile constituents and independent Leather panels."},
  {"id": "plant-cord", "name": "Plant Cord", "system": "tannery", "result": "Plant Cord", "ingredients": [{"label": "2 Stem and/or Leaf Fibre", "role": "component or cost", "resourceIDs": ["fiber"]}, {"label": "0 Essence", "role": "component or cost"}], "notes": "Preserve actual source portions and colours."},
  {"id": "plant-cloth", "name": "Plant Cloth", "system": "tannery", "result": "Plant Cloth", "ingredients": [{"label": "4 Stem and/or Leaf Fibre", "role": "component or cost", "resourceIDs": ["fiber"]}, {"label": "0 Essence", "role": "component or cost"}], "notes": "Preserve actual source portions and colours."},
  {"id": "leather", "name": "Leather", "system": "tannery", "result": "Leather", "ingredients": [{"label": "1 eligible Skin/Hide and 1 Salt", "role": "component or cost", "resourceIDs": ["salt"]}, {"label": "0 Essence", "role": "component or cost"}], "notes": "Preserve actual source portions and colours."},
  {"id": "longbow", "name": "Longbow", "system": "bowyer", "result": "Longbow", "ingredients": [{"label": "Maintained points: 1 Iron Ingot or 2 Quartz or 1 Bone", "role": "component or cost", "resourceIDs": ["quartz"]}, {"label": "2 Hardwood Logs, 1 Resin, 1 Cord", "role": "component or cost", "resourceIDs": ["resin", "timber"]}, {"label": "0 Essence", "role": "component or cost"}], "notes": "Current Far weapon; no separate ammunition inventory. Exact chosen components and same-item refit retain their source."},
  {"id": "sling", "name": "Sling", "system": "bowyer", "result": "Sling", "ingredients": [{"label": "Shot: 2 Clay + 1 Coal or 1 Iron Ingot or 1 Bone", "role": "component or cost", "resourceIDs": ["clay"]}, {"label": "2 Cord; pouch of 1 Cloth or 1 Leather", "role": "component or cost"}, {"label": "0 Essence", "role": "component or cost"}], "notes": "Current Far weapon; no separate ammunition inventory. Exact chosen components and same-item refit retain their source."},
  {"id": "throwing-set", "name": "Throwing Set", "system": "bowyer", "result": "Throwing Set", "ingredients": [{"label": "Two edges, each independently 1 Iron Ingot or 1 Bone", "role": "component or cost"}, {"label": "Carrier of 1 Cloth or 1 Leather, plus 1 Cord", "role": "component or cost"}, {"label": "0 Essence", "role": "component or cost"}], "notes": "Current Far weapon; no separate ammunition inventory. Exact chosen components and same-item refit retain their source."},
  {"id": "fitted-point", "name": "Fitted Point (Pierce/Close)", "system": "weaponsmith", "result": "Fitted Point", "ingredients": [{"label": "2 Ingots or 2 Quartz or 1 Bone", "role": "component or cost", "resourceIDs": ["quartz"]}, {"label": "1 Softwood/Hardwood Haft; 1 Cord or 1 Leather", "role": "component or cost"}, {"label": "1 Iron or Bone Collar", "role": "component or cost", "resourceIDs": ["ore"]}, {"label": "0 Essence", "role": "component or cost"}], "notes": "Polearm requires the actual fitting diary. Balanced and Driving retain their current effects."},
  {"id": "fitted-edge", "name": "Fitted Edge (Rend/Close)", "system": "weaponsmith", "result": "Fitted Edge", "ingredients": [{"label": "2 Ingots or 1 Bone", "role": "component or cost"}, {"label": "1 Softwood/Hardwood Haft; 1 Cord or 1 Leather", "role": "component or cost"}, {"label": "1 Iron or Bone Collar", "role": "component or cost", "resourceIDs": ["ore"]}, {"label": "0 Essence", "role": "component or cost"}], "notes": "Polearm requires the actual fitting diary. Balanced and Driving retain their current effects."},
  {"id": "fitted-maul", "name": "Fitted Maul (Crush/Close)", "system": "weaponsmith", "result": "Fitted Maul", "ingredients": [{"label": "2 Ingots or 2 Bone", "role": "component or cost"}, {"label": "1 Hardwood Haft; 1 Cord or 1 Leather", "role": "component or cost"}, {"label": "1 Iron or Bone Collar", "role": "component or cost", "resourceIDs": ["ore"]}, {"label": "0 Essence", "role": "component or cost"}], "notes": "Polearm requires the actual fitting diary. Balanced and Driving retain their current effects."},
  {"id": "fitted-polearm", "name": "Fitted Polearm (Pierce/Mid)", "system": "weaponsmith", "result": "Fitted Polearm", "ingredients": [{"label": "2 Ingots or 2 Quartz or 1 Bone", "role": "component or cost", "resourceIDs": ["quartz"]}, {"label": "2 Hardwood Hafts; 2 Cord or 2 Leather", "role": "component or cost"}, {"label": "1 Iron or Bone Collar", "role": "component or cost", "resourceIDs": ["ore"]}, {"label": "0 Essence", "role": "component or cost"}], "notes": "Polearm requires the actual fitting diary. Balanced and Driving retain their current effects."},
  {"id": "fitted-polearm-rend-mid", "name": "Fitted Polearm (Rend/Mid)", "system": "weaponsmith", "result": "Fitted Polearm", "ingredients": [{"label": "2 Ingots or 1 Bone", "role": "component or cost"}, {"label": "2 Hardwood Hafts; 2 Cord or 2 Leather", "role": "component or cost"}, {"label": "1 Iron or Bone Collar", "role": "component or cost", "resourceIDs": ["ore"]}, {"label": "0 Essence", "role": "component or cost"}], "notes": "Polearm requires the actual fitting diary. Balanced and Driving retain their current effects."},
  {"id": "fitted-polearm-crush-mid", "name": "Fitted Polearm (Crush/Mid)", "system": "weaponsmith", "result": "Fitted Polearm", "ingredients": [{"label": "2 Ingots or 2 Bone", "role": "component or cost"}, {"label": "2 Hardwood Hafts; 2 Cord or 2 Leather", "role": "component or cost"}, {"label": "1 Iron or Bone Collar", "role": "component or cost", "resourceIDs": ["ore"]}, {"label": "0 Essence", "role": "component or cost"}], "notes": "Polearm requires the actual fitting diary. Balanced and Driving retain their current effects."},






























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
    notes: 'Many creature materials can also fill the layers shown in the recipe.',
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
      'The output rate is shown before you confirm and can improve through progression.',
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
      (ingredient) => ingredient.resourceID === resourceID || ingredient.resourceIDs?.includes(resourceID),
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
  return recipe.readiness ?? 'Available when its station is open, the recipe is known, the shown ingredients are ready, and there is room for the result.';
}

export const definedButNotLiveCrafting = [
] as const;

export const scheduledButNotLiveStations = [
  'The Menagerie and Deep Works are planned buildings. They are not available crafting stations yet.',
] as const;

export function definedButNotLiveForSystem(slug: string) {
  return definedButNotLiveCrafting.filter((entry) => entry.system === slug);
}
