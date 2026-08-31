import Link from 'next/link';
import { PageIntro } from '@/components/page-intro';
import { SiteFrame } from '@/components/site-frame';
import { content } from '@/lib/content';

export default async function SearchPage({ searchParams }: { searchParams: Promise<{ q?: string }> }) {
  const q = ((await searchParams).q ?? '').trim().toLowerCase();
  const entries = [
    ...content.resources.map(entry => ({ name: entry.name, summary: entry.summary, href: `/resources/${entry.slug}`, kind: 'Resource' })),
    ...content.items.map(entry => ({ name: entry.name, summary: entry.summary, href: entry.gear ? `/equipment/${entry.slug}` : `/items/${entry.slug}`, kind: entry.gear ? 'Equipment' : 'Item' })),
    ...content.travellers.map(entry => ({ name: entry.name, summary: entry.summary, href: `/people/${entry.slug}`, kind: 'Person' })),
    ...content.stations.map(entry => ({ name: entry.name, summary: entry.blurb, href: `/places/${entry.slug}`, kind: 'Place' })),
    ...content.terminology.map(entry => ({ name: entry.name, summary: entry.summary, href: `/glossary#${entry.slug}`, kind: 'Glossary' })),
  ];
  const results = q ? entries.filter(entry => `${entry.name} ${entry.summary} ${entry.kind}`.toLowerCase().includes(q)) : [];
  return <SiteFrame sidebar><PageIntro eyebrow="Player Wiki" title={q ? `Search results for “${q}”` : 'Search'} summary={q ? `${results.length} matching player-facing entries.` : 'Enter a name, item, resource, place, or game term in the search field.'} />
    {q && <div className="table-wrap data-table"><table><thead><tr><th>Result</th><th>Type</th><th>Summary</th></tr></thead><tbody>{results.map(result => <tr key={`${result.kind}-${result.href}`}><td><Link href={result.href}>{result.name}</Link></td><td>{result.kind}</td><td>{result.summary}</td></tr>)}</tbody></table></div>}
  </SiteFrame>;
}
