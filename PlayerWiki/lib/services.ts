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
      'Review everything brought home, identify unknown objects, move supplies into the Field Kit, and resolve returns that arrived while storage was full.',
    useFor: [
      'Browsing stored items and reserve-backed resources',
      'Identifying eligible unknown objects',
      'Moving eligible supplies between storage and the Field Kit',
      'Resolving the waiting pile when a return exceeds current space',
    ],
    workflow: [
      'Open Items or Materials.',
      'Inspect the exact stack or resource entry.',
      'Choose the available action and review its current destination or capacity.',
      'If the Storehouse is full, make an explicit keep-or-replace decision; returned loot is not silently discarded.',
    ],
    selection:
      'Choose the exact stack, resource, or waiting item shown on the current Storehouse screen. Item capacity and the resource reserve are shown separately.',
    result:
      'Only the confirmed transfer or keep-or-replace choice changes custody. If there is no room or the shown choice is no longer available, the current holdings stay where they are.',
    relatedGuides: [
      { label: 'Resources', href: '/resources' },
      { label: 'Consumables', href: '/consumables' },
      { label: 'Curios', href: '/curios' },
    ],
    remember: [
      'Resources use their own reserve and do not consume item slots.',
      'Identification and transfers use the exact object currently shown.',
      'Storehouse upgrades increase available storage.',
    ],
  },
  {
    slug: 'trading-post',
    name: 'Trading Post',
    stationID: 'trading_post',
    summary:
      'Buy from Vance’s current ordinary stock and sell eligible identified holdings or reserve-backed materials.',
    useFor: [
      'Buying a currently listed item',
      'Selling eligible identified holdings',
      'Selling a chosen quantity of a material reserve',
    ],
    workflow: [
      'Choose Buy or Sell.',
      'Open the exact listing or material row.',
      'Review price, quantity and current stock.',
      'Confirm the transaction; a changed or unaffordable listing remains uncommitted.',
    ],
    selection:
      'Choose the exact current listing, identified holding, or material quantity. The displayed price, quantity, and stock describe that choice.',
    result:
      'A completed purchase or sale updates the shown holding and currency. If stock, funds, identity, or capacity no longer match, the displayed offer stays uncommitted.',
    relatedGuides: [
      { label: 'Resources', href: '/resources' },
      { label: 'Consumables', href: '/consumables' },
      { label: 'Curios', href: '/curios' },
    ],
    remember: [
      'The shop stock can rotate.',
      'Unidentified objects are not ordinary sale listings.',
      'Material sales draw from the resource reserve rather than Storehouse item slots.',
    ],
  },
  {
    slug: 'recycler',
    name: 'Recycler',
    stationID: 'recycler',
    summary:
      'Dismantle eligible gear into a previewed material yield without inventing material provenance.',
    useFor: [
      'Previewing the return from eligible gear',
      'Recovering useful material from equipment you no longer need',
    ],
    workflow: [
      'Choose an eligible stored item.',
      'Review the exact dismantling preview and resulting quantities.',
      'Commit Dismantle only when the shown item and available capacity still match.',
    ],
    selection:
      'Choose an eligible stored gear item and read the exact preview before dismantling it.',
    result:
      'Only a completed dismantle removes the shown gear and adds its previewed yield. A changed selection or unavailable capacity leaves the gear in place.',
    relatedGuides: [
      { label: 'Equipment', href: '/equipment' },
      { label: 'Resources', href: '/resources' },
    ],
    remember: [
      'Previewing does not consume the item.',
      'Only a committed dismantle removes the source item.',
      'The Recycler returns authored yields; it does not infer arbitrary ingredients from an item name.',
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
      'Choose the current collection and then the exact shelf or record you want to read.',
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
    slug: 'firepit',
    name: 'Firepit and travelling party',
    stationID: 'firepit',
    summary:
      'Choose which recruited people travel with you and which remain safely at home.',
    useFor: [
      'Sending a current companion home',
      'Adding an available resident to the travelling party',
      'Reviewing party-capacity consequences before a transfer',
    ],
    workflow: [
      'Select a person at the fire.',
      'Review whether they are travelling or at home.',
      'Confirm the exact placement change.',
    ],
    selection:
      'Choose the exact recruited person and review their current travelling or home placement before confirming a change.',
    result:
      'A completed placement change updates that person’s current location. If party capacity or the shown placement prevents it, their existing placement remains intact.',
    relatedGuides: [
      { label: 'People', href: '/people' },
      { label: 'Party, Gear and Gambits', href: '/services/party-and-gear' },
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
      'Reviewing health, rank and current placement',
      'Equipping and removing eligible gear',
      'Editing the priority order and conditions of Gambits',
    ],
    workflow: [
      'Open a party member.',
      'Choose the character section, rank, Gear or Gambit editor you need.',
      'Make changes at home before the next encounter.',
    ],
    selection:
      'Choose one party member, then the exact Gear or Gambit face you intend to change. Gear and Gambits keep their displayed slot and priority context.',
    result:
      'A completed change keeps the shown equipped item or Gambit order for later preparation. An ineligible gear choice or unfinished edit leaves the current setup unchanged.',
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
      'Reviewing the current refinement return',
      'Unlearning eligible combat techniques',
    ],
    workflow: [
      'Choose the Raw Essence amount or refine all.',
      'Review the exact Crystal return at the current rate.',
      'Commit the refinement.',
    ],
    selection:
      'Choose the exact Raw Essence amount or the available refine-all option, then read the current Crystal return.',
    result:
      'Only a completed refinement exchanges the selected Raw Essence for the shown Essence Crystals. If the amount or rate no longer matches, the current reserve remains unchanged.',
    relatedGuides: [
      { label: 'Raw Essence', href: '/resources/raw-essence' },
      { label: 'Crafting systems', href: '/crafting' },
      { label: 'Combat', href: '/systems/combat' },
    ],
    remember: [
      'Raw Essence and spendable Essence are distinct.',
      'Progression can improve the refinement rate and returned-essence behavior.',
      'The current preview is the authority for the result.',
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
      'Comparing observed traits and habitat records',
      'Revisiting what has actually been disclosed',
    ],
    workflow: [
      'Open a recorded creature family.',
      'Choose an encountered species or record.',
      'Compare the observed individual with the retained species information.',
    ],
    selection:
      'Choose an already recorded creature family and then an encountered species or record within it.',
    result:
      'The selected record changes the comparison you are viewing. It does not reveal creatures or traits that have not been encountered.',
    relatedGuides: [
      { label: 'Combat', href: '/systems/combat' },
      { label: 'Exploration', href: '/systems/exploration' },
      { label: 'Library collections', href: '/services/library' },
    ],
    remember: [
      'The Bestiary records disclosed encounters rather than revealing unseen creatures.',
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
