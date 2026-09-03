import Link from '@/components/wiki-link';
import { PageIntro } from '@/components/page-intro';
import { SiteFrame } from '@/components/site-frame';
import { content } from '@/lib/content';
import { systemGuideCategories } from '@/lib/system-guides';

const domainGroups = [
  {
    label: 'Writing a world',
    domains: ['Writing'],
    links: [['World Writing', '/systems/world-writing'], ['Action reference', '/actions'], ['Exploration guide', '/systems/exploration']],
  },
  {
    label: 'Worlds and exploration',
    domains: ['Exploration', 'World generation'],
    links: [['World reference', '/world'], ['Terrain', '/terrain'], ['Flora harvesting', '/flora'], ['Exploration guide', '/systems/exploration'], ['Site directory', '/sites'], ['Bestiary', '/bestiary'], ['Resources', '/resources']],
  },
  {
    label: 'Combat and party',
    domains: ['Combat planning', 'Combat progression', 'Gear', 'Party'],
    links: [['Combat guide', '/systems/combat'], ['Action reference', '/actions'], ['Conditions and effects', '/statuses'], ['Techniques and Gambits', '/techniques'], ['Equipment', '/equipment'], ['Party preparation', '/systems/party-preparation']],
  },
  {
    label: 'Village and facilities',
    domains: ['Home and return'],
    links: [['Village buildings, services, and construction', '/village']],
  },
  {
    label: 'Crafting, resources and progression',
    domains: ['Essence', 'Research', 'Campaign progression'],
    links: [['Crafting', '/crafting'], ['Resources', '/resources'], ['Economy and exchange', '/trading'], ['Recycler', '/recycling'], ['Current progression', '/resources/progression']],
  },
  {
    label: 'Campaign records and return',
    domains: ['Persistence', 'Compatibility', 'Return', 'Expeditions'],
    links: [['Getting started', '/getting-started'], ['Library and records', '/buildings/library'], ['People and records', '/people']],
  },
  {
    label: 'People',
    domains: ['People'],
    links: [['People', '/people'], ['Village', '/village']],
  },
];

export default function GlossaryPage() {
  const groupedTerms = domainGroups.map((group) => ({
    ...group,
    terms: content.terminology.filter((term) => group.domains.includes(term.domain)),
  })).filter((group) => group.terms.length);

  return <SiteFrame sidebar><PageIntro eyebrow="Reference" title="Glossary" summary="Plain-language definitions for Bookbinder's recurring terms, grouped by the part of the game where you encounter them." />
    {groupedTerms.map(group => <section className="article-section glossary-group" key={group.label}><div className="glossary-group-heading"><h2>{group.label}</h2><nav aria-label={`${group.label} guides`}>{group.links.map(([label, href]) => <Link href={href} key={href}>{label}</Link>)}</nav></div><dl className="definition-grid">{group.terms.map(term => <div id={term.slug} key={term.id}><dt><strong>{term.name}</strong></dt><dd>{term.summary}{term.aliases.length ? <small> Also called: {term.aliases.join(', ')}.</small> : null}</dd></div>)}</dl></section>)}
    <section className="article-section note-card"><h2>Current recipe availability</h2><p>The Crafting directory clearly marks what is playable now and what is planned. A named station, design, or result is not available in the game until its own page marks it as playable.</p><p><Link href="/crafting">Open current crafting recipes</Link> · <Link href="/village">Open Village buildings</Link></p></section>
    <section className="article-section note-card"><h2>Combat reference shortcuts</h2><p>Use <Link href="/actions">Action reference</Link> to compare the current face, cost, result, and unavailable state. Use <Link href="/statuses">Conditions and effects</Link> to keep encounter afflictions separate from world effects. Use <Link href="/techniques">Techniques and Gambits</Link> for the exact current actor, target, effect, and listed limit.</p></section>
    <section className="article-section glossary-group"><div className="glossary-group-heading"><h2>Player guides by task</h2><Link href="/systems">Open the Systems hub</Link></div><div className="definition-grid">{systemGuideCategories.map((category) => <div key={category.id}><dt><strong>{category.label}</strong></dt><dd><nav aria-label={`${category.label} player guides`}>{category.guides.map((guide) => <Link href={guide.href} key={guide.href}>{guide.label}</Link>)}</nav></dd></div>)}</div></section>
  </SiteFrame>;
}
