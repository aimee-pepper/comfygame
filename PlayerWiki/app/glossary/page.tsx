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
    links: [['Exploration guide', '/systems/exploration'], ['Site directory', '/sites'], ['Bestiary', '/bestiary'], ['Resources', '/resources']],
  },
  {
    label: 'Combat and party',
    domains: ['Combat planning', 'Combat progression', 'Gear', 'Party'],
    links: [['Combat guide', '/systems/combat'], ['Equipment', '/equipment'], ['Party and Gear service', '/services/party-and-gear']],
  },
  {
    label: 'Village, resources and progression',
    domains: ['Home and return', 'Essence', 'Research', 'Campaign progression'],
    links: [['Village buildings', '/village'], ['Village services', '/services'], ['Crafting', '/systems/crafting'], ['Resources', '/resources']],
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
    <section className="article-section glossary-group"><div className="glossary-group-heading"><h2>Player guides by task</h2><Link href="/systems">Open the Systems hub</Link></div><div className="definition-grid">{systemGuideCategories.map((category) => <div key={category.id}><dt><strong>{category.label}</strong></dt><dd><nav aria-label={`${category.label} player guides`}>{category.guides.map((guide) => <Link href={guide.href} key={guide.href}>{guide.label}</Link>)}</nav></dd></div>)}</div></section>
  </SiteFrame>;
}
