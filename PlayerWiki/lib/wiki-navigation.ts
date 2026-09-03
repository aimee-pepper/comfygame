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
      { href: '/sites', label: 'Sites and hazards' },
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
      { href: '/techniques', label: 'Techniques and Gambits' },
      { href: '/statuses', label: 'Conditions and effects' },
    ],
  },
  {
    label: 'Village and facilities',
    links: [{ href: '/village', label: 'Village' }],
  },
  {
    label: 'Crafting and items',
    links: [
      { href: '/crafting', label: 'Crafting' },
      { href: '/resources', label: 'Resources' },
      { href: '/systems/inventory-custody', label: 'Inventory and storage' },
      { href: '/equipment', label: 'Equipment' },
      { href: '/consumables', label: 'Consumables and Field Kit' },
      { href: '/curios', label: 'Curios and key items' },
      { href: '/trading', label: 'Economy and exchange' },
      { href: '/recycling', label: 'Recycler' },
    ],
  },
  {
    label: 'Knowledge and records',
    links: [
      { href: '/research', label: 'Research' },
      { href: '/buildings/library', label: 'Library and records' },
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
