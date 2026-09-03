export interface ServiceGuide {
  slug: string;
  name: string;
  stationID: string;
  summary: string;
  useFor: string[];
  workflow: string[];
  selection: string;
  result: string;
  relatedGuides: Array<{ label: string; href: string }>;
  remember: string[];
}

export const serviceGuides: ServiceGuide[] = [
  {
    slug: 'storehouse',
    name: 'Storehouse and inventory',
    stationID: 'storehouse',
    summary:
      'Review everything you have brought home, identify unknown objects, pack supplies into the Field Kit, and make room for anything waiting after a full return.',
    useFor: [
      'Browsing stored items and materials',
      'Identifying eligible unknown objects',
      'Moving eligible supplies between storage and the Field Kit',
      'Resolving the waiting pile when a return exceeds current space',
    ],
    workflow: [
      'Open Items or Materials.',
      'Inspect the stack, material, or item you want to manage.',
      'Choose an available action and check where the item will go and whether there is room.',
      'If the Storehouse is full, make an explicit keep-or-replace decision; returned loot is not silently discarded.',
    ],
    selection:
      'Choose the stack, material, or waiting item shown in the Storehouse. Items and materials use separate kinds of storage.',
    result:
      'Nothing moves until you confirm. If there is no room or the item has changed, your belongings stay where they are.',
    relatedGuides: [
      { label: 'Resources', href: '/resources' },
      { label: 'Consumables', href: '/consumables' },
      { label: 'Curios', href: '/curios' },
    ],
    remember: [
      'Materials have their own storage and do not use item slots.',
      'Identification and transfers always apply to the object you selected.',
      'Storehouse upgrades increase available storage.',
    ],
  },
  {
    slug: 'trading-post',
    name: 'Trading Post',
    stationID: 'trading_post',
    summary:
      'Buy from Vance’s changing stock, or sell identified items and materials that the Trading Post accepts.',
    useFor: [
      'Buying a currently listed item',
      'Selling eligible identified holdings',
      'Selling a chosen quantity of a material reserve',
    ],
    workflow: [
      'Choose Buy or Sell.',
      'Open the item or material you want to trade.',
      'Check the price, quantity, and available stock.',
      'Confirm the trade. If the stock or price has changed, you will be asked to review it again.',
    ],
    selection:
      'Choose a listed item, one of your identified belongings, or the quantity of material you want to sell. The price and stock shown apply to that choice.',
    result:
      'A completed trade updates your goods and currency together. If the stock, price, funds, item, or storage space has changed, nothing is exchanged.',
    relatedGuides: [
      { label: 'Resources', href: '/resources' },
      { label: 'Consumables', href: '/consumables' },
      { label: 'Curios', href: '/curios' },
    ],
    remember: [
      'The shop stock can rotate.',
      'Unidentified objects are not ordinary sale listings.',
      'Material sales come from material storage rather than Storehouse item slots.',
    ],
  },
  {
    slug: 'recycler',
    name: 'Recycler',
    stationID: 'recycler',
    summary:
      'Preview and dismantle eligible gear to recover the materials it can actually return.',
    useFor: [
      'Previewing the return from eligible gear',
      'Recovering useful material from equipment you no longer need',
    ],
    workflow: [
      'Choose an eligible stored item.',
      'Review the dismantling preview and the quantities you will receive.',
      'Confirm only when you are ready to give up that item and have room for the result.',
    ],
    selection:
      'Choose an eligible piece of stored gear and read its preview before dismantling it.',
    result:
      'The gear is removed only after a successful dismantle, and you receive exactly the materials shown. If the selection or available space changes, the gear stays intact.',
    relatedGuides: [
      { label: 'Equipment', href: '/equipment' },
      { label: 'Resources', href: '/resources' },
    ],
    remember: [
      'Previewing does not consume the item.',
      'Only a confirmed dismantle removes the item.',
      'The Recycler returns the materials defined for that item; it does not guess ingredients from the item’s name.',
    ],
  },
  {
    slug: 'apothecary',
    name: 'Apothecary',
    stationID: 'apothecary',
    summary:
      'Work with Nessa to prepare known remedies, coatings, and field supplies from the ingredients each recipe names.',
    useFor: [
      'Reviewing a known preparation and the ingredients you have available',
      'Choosing a suitable material when a recipe allows more than one option',
      'Preparing one supply for the Storehouse or the waiting area if storage is full',
    ],
    workflow: [
      'Recruit Nessa, then build the Apothecary foundation in Home → Make.',
      'Choose one currently known preparation and review every listed requirement.',
      'Select the ingredient you want to use if the recipe offers a choice.',
      'Check the ingredients and destination, then prepare the item.',
    ],
    selection:
      'Choose a known preparation and, when required, one suitable ingredient. Having part of another recipe may help you recognise it, but you still need every required ingredient before you can make it.',
    result:
      'A successful preparation uses the ingredients you selected and places the finished item in the Storehouse, or in Waiting if storage is full. Cancelling or lacking ingredients changes nothing.',
    relatedGuides: [
      { label: 'Nessa', href: '/people/nessa' },
      { label: 'Apothecary', href: '/buildings/apothecary' },
      { label: 'Apothecary preparations', href: '/crafting/apothecary' },
      { label: 'Field supplies', href: '/consumables' },
    ],
    remember: [
      'The first completed build teaches Lesser Salve but does not prepare one.',
      'Writing ink and vial preparation remain at the Scriptorium.',
      'Unknown recipes stay hidden until your ingredients or another discovery teach them.',
    ],
  },
  {
    slug: 'blacksmith',
    name: 'Blacksmith',
    stationID: 'blacksmith',
    summary:
      'Work with Halloway to make a Pointed Blade from selected materials and inspect an eligible piece of gear before reforging it.',
    useFor: [
      'Previewing a Pointed Blade before making it',
      'Selecting one material for the point and a different piece for the grip',
      'Checking whether a piece of gear stored at the Cottage can be reforged',
    ],
    workflow: [
      'Recruit Halloway, then build the Blacksmith foundation in Home → Make.',
      'Open Make, choose Pointed Blade, and review its two material slots, cost, result, and destination.',
      'Confirm the preview when the chosen materials and result are correct.',
      'Use Reforge only on the selected eligible item. It does not sell, dismantle, or silently replace a different piece of gear.',
    ],
    selection:
      'Choose the materials for a Pointed Blade or the stored piece of gear you want Halloway to inspect. Blacksmith stock can include suitable materials gathered from worlds and creatures.',
    result:
      'A finished craft creates one weapon and sends it to the Storehouse, or to Waiting if storage is full. Cancelling, losing an ingredient, or failing to save leaves the materials and selected item unchanged.',
    relatedGuides: [
      { label: 'Halloway', href: '/people/halloway' },
      { label: 'Blacksmith construction', href: '/buildings/blacksmith' },
      { label: 'Pointed Blade construction', href: '/crafting/blacksmith' },
      { label: 'Equipment and material effects', href: '/equipment' },
      { label: 'Recycler', href: '/buildings/recycler' },
    ],
    remember: [
      'The foundation teaches Pointed Blade but gives no gear or material stock.',
      'The Trading Post sells, the Recycler dismantles, and the Blacksmith makes or improves gear.',
      'Reforging will remain marked as planned until the game can show its full result before you confirm.',
    ],
  },
  {
    slug: 'anchorage',
    name: 'The Anchorage',
    stationID: 'anchorage',
    summary:
      'Work with Tovin to keep anchored realms in one portfolio and construct an Anchor Frame for a supported return journey.',
    useFor: [
      'Reviewing realms you have already held permanently',
      'Constructing an Anchor Frame from the required world materials',
      'Returning to a world you have already anchored',
    ],
    workflow: [
      'Recruit Tovin, then build the Anchorage foundation in Home → Realms.',
      'Review the empty portfolio or one already anchored realm.',
      'Craft an Anchor Frame from six different suitable materials and the Essence shown in the preview.',
      'At a revealed Atlas Seam, or when carrying a usable Frame, review the anchoring cost and confirm when you are ready.',
    ],
    selection:
      'Choose the realm, Anchor Frame preview, or revealed Atlas Seam shown on the page. A Frame and a Seam are two different ways to anchor a realm.',
    result:
      'Nothing is built, spent, or anchored until you confirm and the action succeeds. Cancelling or encountering a changed requirement leaves the building, materials, realm, and expedition unchanged.',
    relatedGuides: [
      { label: 'Tovin', href: '/people/tovin' },
      { label: 'Anchorage construction', href: '/buildings/anchorage' },
      { label: 'Anchor Frame', href: '/crafting/anchorage' },
      { label: 'Atlas Seam', href: '/sites/atlas-seam' },
      { label: 'Exploration', href: '/systems/exploration' },
    ],
    remember: [
      'Building the station grants no realm or Anchor Frame.',
      'Anchoring preserves a realm; it does not end an expedition or bank the current haul.',
      'Work assignments, deliveries, and passive production are not available yet.',
    ],
  },
  {
    slug: 'library',
    name: 'Library collections',
    stationID: 'library',
    summary:
      'Read recovered diaries, traveller records, the known dictionary, field notes and world history.',
    useFor: [
      'Reading diary pages exactly as recovered',
      'Reviewing people and their location clues',
      'Checking known Sigils and Compounds',
      'Opening recovered notes and visited-world history',
    ],
    workflow: [
      'Choose Diaries, People, Dictionary, Notes or History.',
      'Open a shelf or record.',
      'Read the recovered wording and any explicitly attached teaching.',
    ],
    selection:
      'Choose a collection, then the shelf or record you want to read.',
    result:
      'Opening a record changes what you are reading, not what the recovered record says. Unavailable wording remains unavailable rather than being filled in.',
    relatedGuides: [
      { label: 'People', href: '/people' },
      { label: 'Bestiary', href: '/bestiary' },
      { label: 'World Writing', href: '/systems/world-writing' },
    ],
    remember: [
      'The Library preserves recovered words; it does not translate clues into a checklist.',
      'Unknown meanings remain unknown until learned.',
      'Older records can remain represented even when their original prose is unavailable.',
    ],
  },
  {
    slug: 'survey-post',
    name: 'Survey Post',
    stationID: 'survey_post',
    summary:
      'Work with Mara to learn field instruments, choose which ones to take, and record readings during an expedition.',
    useFor: [
      'Studying one of the eight available Field Instruments',
      'Choosing which owned instruments are packed for the next expedition',
      'Reviewing observations recorded by a carried instrument in the world',
    ],
    workflow: [
      'Recruit Mara, then build the Survey Post foundation in Home → Study.',
      'Study an affordable instrument. You learn its basic use permanently; it is a skill rather than a physical item.',
      'Choose the next-trip loadout at Home, then Bind and depart.',
      'Use Survey in the world when no encounter is active to record the carried instruments’ readings for one turn.',
    ],
    selection:
      'Choose the instrument you want to study or add to your next loadout. The Field Kit shows only the instruments you packed before the expedition began.',
    result:
      'A study, loadout change, or Survey takes effect only after it saves successfully. If it cannot be completed, your learned instruments, packed set, observations, and world turn do not change.',
    relatedGuides: [
      { label: 'Mara', href: '/people/mara' },
      { label: 'Survey Post construction', href: '/buildings/survey-post' },
      { label: 'Instrument study and improvement boundary', href: '/crafting/instruments' },
      { label: 'Field supplies and Field Kit', href: '/consumables' },
      { label: 'World conditions', href: '/world' },
    ],
    remember: [
      'An instrument is a permanent field skill, not a physical Storehouse item, Field Kit supply, or piece of equipment.',
      'A Survey advances one turn and records observations; it does not promise a coordinate, resource, site, traveller, or map reveal.',
      'Precision improvements are planned, but are not listed as usable upgrades until the game can show their full cost and result before confirmation.',
    ],
  },
  {
    slug: 'firepit',
    name: 'Firepit and travelling party',
    stationID: 'firepit',
    summary:
      'Choose which recruited people travel with you and which remain safely at home.',
    useFor: [
      'Sending a travelling companion home',
      'Adding an available resident to the travelling party',
      'Reviewing party-capacity consequences before a transfer',
    ],
    workflow: [
      'Select a person at the fire.',
      'Review whether they are travelling or at home.',
      'Confirm the placement change.',
    ],
    selection:
      'Choose a recruited person and review whether they are travelling or at home before confirming a change.',
    result:
      'A completed placement change updates that person’s current location. If party capacity or the shown placement prevents it, their existing placement remains intact.',
    relatedGuides: [
      { label: 'People', href: '/people' },
      { label: 'Party and Gear', href: '/buildings/party' },
      { label: 'Equipment', href: '/equipment' },
    ],
    remember: [
      'The Firepit chooses placement; Party owns stats, gear, rank and Gambits.',
      'A refused transfer leaves the existing placement intact.',
      'Party capacity still applies.',
    ],
  },
  {
    slug: 'party-and-gear',
    name: 'Party, Gear and Gambits',
    stationID: 'party',
    summary:
      'Review the people travelling with you, equip stored gear, and prepare combat Gambits before entering a world.',
    useFor: [
      'Reviewing health, rank, and whether someone is at Home or in the party',
      'Equipping and removing eligible gear',
      'Editing the priority order and conditions of Gambits',
    ],
    workflow: [
      'Open a party member.',
      'Choose the character section, rank, Gear or Gambit editor you need.',
      'Make changes at home before the next encounter.',
    ],
    selection:
      'Choose one party member, then the Gear or Gambit you want to change. Gear keeps its equipment slot, and Gambits keep their shown priority order.',
    result:
      'A successful change saves the equipped item or Gambit order you chose. An ineligible gear choice or unfinished edit leaves the earlier setup unchanged.',
    relatedGuides: [
      { label: 'People', href: '/people' },
      { label: 'Equipment', href: '/equipment' },
      { label: 'Combat', href: '/systems/combat' },
    ],
    remember: [
      'Gear must satisfy its slot and ownership rules.',
      'Gambits are evaluated in their displayed priority order.',
      'This preparation is edited at home, not during a fight.',
    ],
  },
  {
    slug: 'essence-spring',
    name: 'Essence Spring',
    stationID: 'essence_spring',
    summary:
      'Refine Raw Essence into spendable Essence Crystals and manage progression that changes the return economy.',
    useFor: [
      'Refining a chosen amount of Raw Essence',
      'Reviewing how many Essence Crystals refining will provide',
      'Unlearning eligible combat techniques',
    ],
    workflow: [
      'Choose the Raw Essence amount or refine all.',
      'Review how many Essence Crystals you will receive at the displayed rate.',
      'Confirm the refinement.',
    ],
    selection:
      'Choose an amount of Raw Essence, or refine all of it, then review how many Essence Crystals you will receive.',
    result:
      'A successful refinement exchanges the chosen Raw Essence for the number of Essence Crystals shown. If the amount or rate changes before confirmation, your Raw Essence remains unchanged.',
    relatedGuides: [
      { label: 'Raw Essence', href: '/resources/essence-raw' },
      { label: 'Crafting systems', href: '/crafting' },
      { label: 'Combat', href: '/systems/combat' },
    ],
    remember: [
      'Raw Essence and spendable Essence are distinct.',
      'Progression can improve the refinement rate and returned-essence behavior.',
      'Always check the preview before refining; it shows the amount you will receive.',
    ],
  },
  {
    slug: 'bestiary',
    name: 'Bestiary',
    stationID: 'bestiary',
    summary:
      'Review the creatures encountered in generated worlds and compare an observed individual with its known species.',
    useFor: [
      'Reviewing encountered species',
      'Comparing observed traits and habitats',
      'Revisiting what has actually been disclosed',
    ],
    workflow: [
      'Open a recorded creature family.',
      'Choose an encountered species or record.',
      'Compare the observed individual with what you have learned about its species.',
    ],
    selection:
      'Choose an already recorded creature family and then an encountered species or record within it.',
    result:
      'The selected record changes the comparison you are viewing. It does not reveal creatures or traits that have not been encountered.',
    relatedGuides: [
      { label: 'Combat', href: '/systems/combat' },
      { label: 'Exploration', href: '/systems/exploration' },
      { label: 'Library collections', href: '/buildings/library' },
    ],
    remember: [
      'The Bestiary records creatures you have encountered; it does not reveal unseen species.',
      'Traveller writing lives in the Library; the Bestiary covers the other living things met in worlds.',
    ],
  },
];

export function serviceForStation(stationID: string) {
  return serviceGuides.find((guide) => guide.stationID === stationID);
}
export function serviceForSlug(slug: string) {
  return serviceGuides.find((guide) => guide.slug === slug);
}
