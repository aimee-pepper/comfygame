export type PlayerGuide = {
  label: string;
  href: string;
  summary: string;
};

export type SystemGuideCategory = {
  id: 'worlds' | 'characters' | 'village' | 'crafting' | 'knowledge';
  label: string;
  summary: string;
  guides: PlayerGuide[];
};

export const playerStartGuides: PlayerGuide[] = [
  { label: 'Getting started', href: '/getting-started', summary: 'Create a campaign and begin the current route.' },
  { label: 'Your current journey', href: '/journey', summary: 'Move from Writing through a world and back to the Village.' },
  { label: 'Current progression', href: '/resources/progression', summary: 'Choose a current next task without assuming a future gate order.' },
];

// The player-facing home for each distinct system or canonical category. Redirect-only legacy
// routes are intentionally absent so the Systems hub, sidebar, search, and glossary agree.
export const systemGuideCategories: SystemGuideCategory[] = [
  {
    id: 'worlds',
    label: 'Worlds and exploration',
    summary: 'Write a world, enter it, and read the living places and encounters it contains.',
    guides: [
      { label: 'World Writing', href: '/systems/world-writing', summary: 'Prepare Pages, marks, links, and inks before Binding.' },
      { label: 'Exploration', href: '/systems/exploration', summary: 'Enter a world, move, Look, use tiles, and return.' },
      { label: 'Sites and hazards', href: '/sites', summary: 'Read current sites, Search rules, and disclosed entry hazards.' },
    ],
  },
  {
    id: 'characters',
    label: 'Characters and combat',
    summary: 'Prepare the travelling party, understand an encounter, and choose the supplies that support it.',
    guides: [
      { label: 'Combat', href: '/systems/combat', summary: 'Read turns, targets, techniques, items, Withdraw, and defeat.' },
      { label: 'Techniques and Gambits', href: '/techniques', summary: 'Compare current technique targets and cooldowns, then arrange rule parts.' },
      { label: 'Party, Gear and Gambits', href: '/systems/party-preparation', summary: 'Choose companions, equip them, and prepare their priorities.' },
      { label: 'Animals and companionship', href: '/systems/animals-companionship', summary: 'Meet animals, build trust, and prepare a companion.' },
    ],
  },
  {
    id: 'village',
    label: 'Village and facilities',
    summary: 'Find the Village places, keepers, and foundations that make new work available.',
    guides: [
      { label: 'Village', href: '/village', summary: 'Compare every destination, keeper, foundation, and current service in one guide.' },
    ],
  },
  {
    id: 'crafting',
    label: 'Crafting and items',
    summary: 'Work with materials, recipes, equipment, supplies, storage, trade, and recycling.',
    guides: [
      { label: 'Crafting', href: '/crafting', summary: 'Choose a station, exact inputs, material rules, and the current result.' },
      { label: 'Equipment', href: '/equipment', summary: 'Compare eight slots, item facts, material effects, and reforge routes.' },
      { label: 'Inventory and custody', href: '/systems/inventory-custody', summary: 'Follow current items between storage, the Field Kit, and worn gear.' },
      { label: 'Consumables and Field Kit', href: '/consumables', summary: 'Prepare carried supplies and choose their current use targets.' },
      { label: 'Economy and exchange', href: '/trading', summary: 'Trade, refine, and recycle through the current Village screens.' },
    ],
  },
  {
    id: 'knowledge',
    label: 'Knowledge and records',
    summary: 'Study Research, recovered teachings, the Library, and the records that preserve what you learn.',
    guides: [
      { label: 'Research', href: '/research', summary: 'Study current branches, requirements, costs, and results.' },
      { label: 'Library and records', href: '/buildings/library', summary: 'Use Library, people, Research, and Bestiary records together.' },
    ],
  },
];

export const systemGuides = systemGuideCategories.flatMap((category) => category.guides);
