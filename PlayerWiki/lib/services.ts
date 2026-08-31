export interface ServiceGuide {
  slug: string;
  name: string;
  stationID: string;
  summary: string;
  useFor: string[];
  workflow: string[];
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
