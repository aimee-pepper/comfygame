import Link from 'next/link';
import { PageIntro } from '@/components/page-intro';
import { PixelImage } from '@/components/pixel-image';
import { SiteFrame } from '@/components/site-frame';
import { content } from '@/lib/content';
import { serviceGuides } from '@/lib/services';

export default async function SearchPage({ searchParams }: { searchParams: Promise<{ q?: string }> }) {
  const q = ((await searchParams).q ?? '').trim().toLowerCase();
  const categories = [
    { label: 'Resources', entries: content.resources.map(entry => ({ name: entry.name, summary: entry.summary, href: `/resources/${entry.slug}`, type: 'Resource', assetURL: entry.assetURL, alt: `${entry.name} inventory icon` })) },
    { label: 'Equipment', entries: content.items.filter(entry => entry.gear).map(entry => ({ name: entry.name, summary: entry.summary, href: `/equipment/${entry.slug}`, type: 'Equipment', assetURL: entry.assetURL, alt: `${entry.name} icon` })) },
    { label: 'Supplies', entries: content.items.filter(entry => !entry.gear && entry.consumable).map(entry => ({ name: entry.name, summary: entry.summary, href: `/items/${entry.slug}`, type: 'Supply', assetURL: entry.assetURL, alt: `${entry.name} icon` })) },
    { label: 'Curios and key items', entries: content.items.filter(entry => !entry.gear && !entry.consumable).map(entry => ({ name: entry.name, summary: entry.summary, href: `/items/${entry.slug}`, type: 'Curio or key item', assetURL: entry.assetURL, alt: `${entry.name} icon` })) },
    { label: 'People', entries: content.travellers.map(entry => ({ name: entry.name, summary: entry.summary, href: `/people/${entry.slug}`, type: 'Person', assetURL: entry.assetURL, alt: `${entry.name} character visual` })) },
    { label: 'Village places', entries: content.stations.map(entry => ({ name: entry.name, summary: entry.blurb, href: `/places/${entry.slug}`, type: 'Place', assetURL: entry.assetURL ?? entry.contextAssetURL, alt: entry.assetURL ? `${entry.name} building visual` : `${entry.zone} town setting` })) },
    { label: 'Village services', entries: serviceGuides.map(entry => { const station = content.stations.find((candidate) => candidate.id === entry.stationID); return { name: entry.name, summary: entry.summary, href: `/services/${entry.slug}`, type: 'Service guide', assetURL: station?.assetURL ?? station?.contextAssetURL ?? null, alt: station?.assetURL ? `${station.name} building visual` : `${station?.zone ?? 'Village'} town setting` }; }) },
    { label: 'World records', entries: (() => { const guide = serviceGuides.find((entry) => entry.slug === 'bestiary'); const station = content.stations.find((entry) => entry.id === 'bestiary'); return guide ? [{ name: 'Bestiary', summary: guide.summary, href: '/bestiary', type: 'World record guide', assetURL: station?.assetURL ?? station?.contextAssetURL ?? null, alt: station?.assetURL ? `${station.name} building visual` : 'Village setting' }] : []; })() },
    { label: 'Glossary', entries: content.terminology.map(entry => ({ name: entry.name, summary: entry.summary, href: `/glossary#${entry.slug}`, type: 'Term', assetURL: null, alt: '' })) },
  ];
  const groups = q ? categories.map((category) => ({ ...category, entries: category.entries.filter(entry => `${entry.name} ${entry.summary} ${entry.type} ${category.label}`.toLowerCase().includes(q)) })).filter((category) => category.entries.length) : [];
  const resultCount = groups.reduce((total, group) => total + group.entries.length, 0);
  return <SiteFrame sidebar><PageIntro eyebrow="Player Wiki" title={q ? `Search results for “${q}”` : 'Search'} summary={q ? `${resultCount} matching player-facing entries.` : 'Enter a name, item, resource, place, or game term in the search field.'} />
    {q && !groups.length && <section className="article-section note-card"><h2>No matching player entries</h2><p>Try a shorter name, an item type, a resource, or a Village service.</p></section>}
    {groups.map(group => <section className="article-section search-group" key={group.label}><h2>{group.label} <span>{group.entries.length}</span></h2><div className="table-wrap data-table catalogue-summary"><table><thead><tr><th aria-label="Image" /><th>Result</th><th>Type</th><th>Summary</th></tr></thead><tbody>{group.entries.map(result => <tr key={result.href}><td>{result.assetURL ? <Link href={result.href} aria-label={`Open ${result.name}`}><PixelImage src={result.assetURL} alt={result.alt} /></Link> : '—'}</td><td><Link href={result.href}>{result.name}</Link></td><td>{result.type}</td><td>{result.summary}</td></tr>)}</tbody></table></div></section>)}
  </SiteFrame>;
}
