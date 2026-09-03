import cohesivePlan from '../../docs/resource-crafting-world-ecology-cohesive-plan-v1.md?raw';
import overhaulPlan from '../../docs/resource-crafting-world-overhaul-structure-v1.md?raw';
import implementationRoadmap from '../../docs/resource-crafting-world-implementation-roadmap-v1.md?raw';
import characterBackgroundVoice from '../../docs/full-cast-background-and-voice-guide-current.md?raw';
import rewrittenWorldClues from '../../docs/full-cast-world-clue-rewrite-current.md?raw';

export interface DesignReferenceLink {
  href: string;
  title: string;
  summary: string;
}

export interface DesignReference {
  slug: string;
  title: string;
  summary: string;
  source: string;
  systemLinks: DesignReferenceLink[];
}

const systemLinks: DesignReferenceLink[] = [
  { href: '/journey', title: 'The player loop', summary: 'How Writing, exploration, return, Village work, preparation, and the next journey connect.' },
  { href: '/resources', title: 'Materials and resource identity', summary: 'World and creature materials, their acquisition, consumers, and intended physical vocabulary.' },
  { href: '/systems/inventory-custody', title: 'Materials, stacks, and storage', summary: 'Simple mined-resource stacks, biological subtype-and-quality stacks, alternate views, deliberate selection, return, storage, and reopening the game.' },
  { href: '/crafting', title: 'Recipes and ingredient categories', summary: 'Static ingredients, broad types, precise subtypes, previews, quality, and commit rules.' },
  { href: '/resources/progression', title: 'Harvesting and processing progression', summary: 'Current tasks beside the intended tool, facility, processing, and recipe progression.' },
  { href: '/equipment', title: 'Equipment materials and quality', summary: 'How selected materials affect equipment now and in the accepted intended design.' },
  { href: '/world', title: 'World generation and resource hosting', summary: 'World pressures, ground, water, weather, ecology, and intended causal material placement.' },
  { href: '/bestiary', title: 'Creatures, ecology, and physical drops', summary: 'Current encounters beside the intended anatomy, habitat, and physical-material rules.' },
  { href: '/systems/world-writing', title: 'World Writing and targeting', summary: 'How written pressures work now and how accepted resource and world-size targeting will fit.' },
  { href: '/crafting', title: 'Individual crafting systems', summary: 'Open the separate Apothecary, maker, instrument, Distillery, Channelworks, Anchorage, and refining guides.' },
];

const characterLinks: DesignReferenceLink[] = [
  { href: '/people', title: 'People', summary: 'Browse all twenty-nine travellers in campaign order and open each person\'s complete page.' },
  { href: '/village', title: 'The Village', summary: 'See where recruited specialists contribute and which facilities are available or planned.' },
  { href: '/journey', title: 'The player journey', summary: 'See where meetings, recruitment, recovered pages, and later story beats fit into play.' },
];

export const designReferences: DesignReference[] = [
  {
    slug: 'character-background-and-voice',
    title: 'Character Background and Voice Guide',
    summary: 'The human background, personality, social habits, humour, speaking style, and world-clue boundaries for all twenty-nine travellers.',
    source: characterBackgroundVoice,
    systemLinks: characterLinks,
  },
  {
    slug: 'rewritten-world-clues',
    title: 'Rewritten World Clues',
    summary: 'The complete plain-language clue set for all twenty-nine travellers, ready for Aimee review before Engineering integration.',
    source: rewrittenWorldClues,
    systemLinks: characterLinks,
  },
  {
    slug: 'resource-crafting-world-ecology-plan',
    title: 'Resource, Crafting, World, and Ecology Plan',
    summary: 'The organized intended player loop, material hierarchy, recipes, progression, ecology, world generation, and Wiki contract.',
    source: cohesivePlan,
    systemLinks,
  },
  {
    slug: 'resource-crafting-world-overhaul',
    title: 'Resource, Crafting, Creature, and World Overhaul Structure',
    summary: 'The system-by-system current foundation, intended structure, preserved behavior, structural work, and decisions still to discuss.',
    source: overhaulPlan,
    systemLinks,
  },
  {
    slug: 'resource-crafting-world-roadmap',
    title: 'Resource, Crafting, Creature, and World Implementation Roadmap',
    summary: 'The incremental vertical-slice rollout, migration rules, delivery gates, and complete player-journey destination.',
    source: implementationRoadmap,
    systemLinks: [],
  },
];

export function designReferenceFor(slug: string) {
  return designReferences.find((reference) => reference.slug === slug);
}
