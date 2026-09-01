import Link from 'next/link';
import { PageIntro } from '@/components/page-intro';
import { SiteFrame } from '@/components/site-frame';
import { content } from '@/lib/content';
import { systemGuideCategories } from '@/lib/system-guides';

const domainGroups = [
  {
    label: 'Writing a world',
    domains: ['Writing'],
    links: [['World Writing', '/systems/world-writing'], ['Exploration guide', '/systems/exploration']],
  },
  {
    label: 'Worlds and exploration',
    domains: ['Exploration', 'World generation'],
    links: [['World reference', '/world'], ['Terrain', '/terrain'], ['Flora harvesting', '/flora'], ['Exploration guide', '/systems/exploration'], ['Site directory', '/sites'], ['Bestiary', '/bestiary'], ['Resources', '/resources']],
  },
  {
    label: 'Combat and party',
    domains: ['Combat planning', 'Combat progression', 'Gear', 'Party'],
    links: [['Combat guide', '/systems/combat'], ['Conditions and effects', '/statuses'], ['Techniques and Gambits', '/techniques'], ['Equipment', '/equipment'], ['Party and Gear service', '/services/party-and-gear']],
  },
  {
    label: 'Village, resources and progression',
    domains: ['Home and return', 'Essence', 'Research', 'Campaign progression'],
    links: [['Village buildings', '/village'], ['Village services', '/services'], ['Current crafting recipes', '/crafting'], ['Crafting basics', '/systems/crafting'], ['Resources', '/resources'], ['Current progression', '/resources/progression']],
  },
  {
    label: 'Campaign records and return',
    domains: ['Persistence', 'Compatibility', 'Return', 'Expeditions'],
    links: [['Getting started', '/getting-started'], ['Library service', '/services/library']],
  },
  {
    label: 'People',
    domains: ['People'],
    links: [['People', '/people'], ['Village services', '/services']],
  },
];

export default function GlossaryPage() {
  const groupedTerms = domainGroups.map((group) => ({
    ...group,
    terms: content.terminology.filter((term) => group.domains.includes(term.domain)),
  })).filter((group) => group.terms.length);

  return <SiteFrame sidebar><PageIntro eyebrow="Reference" title="Glossary" summary="Plain-language definitions for Bookbinder's recurring terms, grouped by the part of the game where you encounter them." />
    {groupedTerms.map(group => <section className="article-section glossary-group" key={group.label}><div className="glossary-group-heading"><h2>{group.label}</h2><nav aria-label={`${group.label} guides`}>{group.links.map(([label, href]) => <Link href={href} key={href}>{label}</Link>)}</nav></div><dl className="definition-grid">{group.terms.map(term => <div id={term.slug} key={term.id}><dt><strong>{term.name}</strong></dt><dd>{term.summary}{term.aliases.length ? <small> Also called: {term.aliases.join(', ')}.</small> : null}</dd></div>)}</dl></section>)}
    <section className="article-section note-card"><h2>Current recipe availability</h2><p>The Crafting directory lists only current player recipes and station processes. A named station, design, or result is not a playable route until its own page marks it current and shows its readiness.</p><p><Link href="/crafting">Open current crafting recipes</Link> · <Link href="/village">Open Village buildings</Link></p></section>
    <section className="article-section note-card"><h2>Combat reference shortcuts</h2><p>Use <Link href="/statuses">Conditions and effects</Link> to keep encounter afflictions separate from world effects. Use <Link href="/techniques">Techniques and Gambits</Link> for the exact current actor, target, effect, and listed limit.</p></section>
    <section className="article-section glossary-group"><div className="glossary-group-heading"><h2>Player guides by task</h2><Link href="/systems">Open the Systems hub</Link></div><div className="definition-grid">{systemGuideCategories.map((category) => <div key={category.id}><dt><strong>{category.label}</strong></dt><dd><nav aria-label={`${category.label} player guides`}>{category.guides.map((guide) => <Link href={guide.href} key={guide.href}>{guide.label}</Link>)}</nav></dd></div>)}</div></section>
  </SiteFrame>;
}
