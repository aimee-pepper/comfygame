export type PlayerGuide = {
  label: string;
  href: string;
  summary: string;
};

export type SystemGuideCategory = {
  id: 'journey' | 'combat' | 'village';
  label: string;
  summary: string;
  guides: PlayerGuide[];
};

export const playerStartGuides: PlayerGuide[] = [
  { label: 'Getting started', href: '/getting-started', summary: 'Create a campaign and begin the current route.' },
  { label: 'Your current journey', href: '/journey', summary: 'Move from Writing through a world and back to the Village.' },
  { label: 'Current progression', href: '/resources/progression', summary: 'Choose a current next task without assuming a future gate order.' },
];

// The player-facing home for each published /systems route. Keep every route in exactly one
// category so the Systems hub, sidebar, search, and glossary agree about where it belongs.
export const systemGuideCategories: SystemGuideCategory[] = [
  {
    id: 'journey',
    label: 'Journey and worlds',
    summary: 'Write a world, enter it, and read the living places and encounters it contains.',
    guides: [
      { label: 'World Writing', href: '/systems/world-writing', summary: 'Prepare Pages, marks, links, and inks before Binding.' },
      { label: 'Exploration', href: '/systems/exploration', summary: 'Enter a world, move, Look, use tiles, and return.' },
      { label: 'Sites and hazards', href: '/systems/sites-hazards', summary: 'Read current sites and disclosed flora profiles before entering.' },
      { label: 'Animals and companionship', href: '/systems/animals-companionship', summary: 'Meet animals, build trust, and prepare a companion.' },
    ],
  },
  {
    id: 'combat',
    label: 'Combat and preparation',
    summary: 'Prepare the travelling party, understand an encounter, and choose the supplies that support it.',
    guides: [
      { label: 'Combat', href: '/systems/combat', summary: 'Read turns, targets, techniques, items, Withdraw, and defeat.' },
      { label: 'Combat techniques and Gambits', href: '/systems/combat-techniques-gambits', summary: 'Compare current technique targets and cooldowns, then arrange rule parts.' },
      { label: 'Party, Gear and Gambits', href: '/systems/party-preparation', summary: 'Choose companions, equip them, and prepare their priorities.' },
      { label: 'Equipment and material effects', href: '/systems/equipment-materials', summary: 'Compare eight slots, material selections, and reforge routes.' },
      { label: 'Inventory and custody', href: '/systems/inventory-custody', summary: 'Follow current items between storage, the Field Kit, and worn gear.' },
      { label: 'Field supplies', href: '/systems/field-supplies', summary: 'Prepare carried supplies and choose their current use targets.' },
    ],
  },
  {
    id: 'village',
    label: 'Village, crafting and records',
    summary: 'Build a current place, work with named materials, and read the records that support later choices.',
    guides: [
      { label: 'Village construction', href: '/systems/village-construction', summary: 'Meet a keeper and review each current foundation requirement.' },
      { label: 'Crafting basics', href: '/systems/crafting', summary: 'Choose a station, exact inputs, and the current result.' },
      { label: 'Economy and exchange', href: '/systems/economy-exchange', summary: 'Trade, refine, and recycle through the current Village screens.' },
      { label: 'Research', href: '/systems/research', summary: 'Study current branches, requirements, costs, and results.' },
      { label: 'Knowledge and records', href: '/systems/knowledge-records', summary: 'Use Library, people, Research, and Bestiary records together.' },
    ],
  },
];

export const systemGuides = systemGuideCategories.flatMap((category) => category.guides);
