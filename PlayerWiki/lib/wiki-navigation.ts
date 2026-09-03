export type WikiNavigationLink = {
  href: string;
  label: string;
};

export type WikiNavigationSection = {
  label: string;
  links: WikiNavigationLink[];
};

// The site-wide player hierarchy. Each directory appears once here; detail pages
// remain reachable from their directory so the sidebar does not become a second index.
export const primaryWikiLinks: WikiNavigationLink[] = [
  { href: '/getting-started', label: 'Start here' },
  { href: '/world', label: 'Worlds' },
  { href: '/people', label: 'Characters' },
  { href: '/village', label: 'Village' },
  { href: '/crafting', label: 'Crafting & items' },
  { href: '/systems', label: 'Game systems' },
  { href: '/references', label: 'Aimee Reference' },
];

export const wikiNavigationSections: WikiNavigationSection[] = [
  {
    label: 'Start here',
    links: [
      { href: '/systems', label: 'Systems overview' },
      { href: '/getting-started', label: 'Getting started' },
      { href: '/journey', label: 'Your current journey' },
      { href: '/resources/progression', label: 'Current progression' },
      { href: '/guide-status', label: "What's playable now" },
    ],
  },
  {
    label: 'Worlds and exploration',
    links: [
      { href: '/systems/world-writing', label: 'World Writing' },
      { href: '/systems/exploration', label: 'Exploration' },
      { href: '/world', label: 'World conditions' },
      { href: '/terrain', label: 'Terrain' },
      { href: '/flora', label: 'Flora' },
      { href: '/systems/sites-hazards', label: 'Sites and hazards' },
      { href: '/sites', label: 'Site directory' },
      { href: '/bestiary', label: 'Bestiary' },
    ],
  },
  {
    label: 'Characters and combat',
    links: [
      { href: '/people', label: 'People' },
      { href: '/systems/party-preparation', label: 'Party and Gear' },
      { href: '/systems/animals-companionship', label: 'Animals and companionship' },
      { href: '/systems/combat', label: 'Combat' },
      { href: '/systems/combat-techniques-gambits', label: 'Techniques and Gambits guide' },
      { href: '/techniques', label: 'Techniques and Gambits reference' },
      { href: '/statuses', label: 'Conditions and effects' },
    ],
  },
  {
    label: 'Village and facilities',
    links: [
      { href: '/village', label: 'Village overview' },
      { href: '/places', label: 'Places and stations' },
      { href: '/services', label: 'Village services' },
      { href: '/systems/village-construction', label: 'Village construction' },
    ],
  },
  {
    label: 'Crafting and items',
    links: [
      { href: '/crafting', label: 'Crafting systems' },
      { href: '/systems/crafting', label: 'Crafting rules' },
      { href: '/resources', label: 'Resources' },
      { href: '/loot', label: 'Loot and materials' },
      { href: '/systems/inventory-custody', label: 'Inventory and custody' },
      { href: '/equipment', label: 'Equipment' },
      { href: '/systems/equipment-materials', label: 'Material effects' },
      { href: '/consumables', label: 'Consumables' },
      { href: '/systems/field-supplies', label: 'Field supplies' },
      { href: '/curios', label: 'Curios and key items' },
      { href: '/trading', label: 'Trading' },
      { href: '/recycling', label: 'Recycler' },
      { href: '/systems/economy-exchange', label: 'Economy and exchange' },
    ],
  },
  {
    label: 'Knowledge and records',
    links: [
      { href: '/systems/research', label: 'Research guide' },
      { href: '/research', label: 'Research directory' },
      { href: '/systems/knowledge-records', label: 'Library and records' },
      { href: '/services/library', label: 'Library service' },
    ],
  },
  {
    label: 'Quick reference',
    links: [
      { href: '/actions', label: 'Action reference' },
      { href: '/glossary', label: 'Glossary' },
    ],
  },
  {
    label: 'Aimee Reference',
    links: [{ href: '/references', label: 'Plans and production references' }],
  },
];
