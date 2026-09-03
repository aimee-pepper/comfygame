import type { Metadata } from 'next';
import Link from '@/components/wiki-link';
import { notFound } from 'next/navigation';
import { GuideBreadcrumbs, RelatedGuides } from '@/components/guide-navigation';
import { PageIntro } from '@/components/page-intro';
import { SiteFrame } from '@/components/site-frame';
import { content } from '@/lib/content';
import { statusForSlug, statusReferences } from '@/lib/status-reference';

export function generateStaticParams() { return statusReferences.map((status) => ({ slug: status.slug })); }
export async function generateMetadata({ params }: { params: Promise<{ slug: string }> }): Promise<Metadata> {
  const { slug } = await params; const status = statusForSlug(slug); return status ? { title: status.name, description: status.summary } : {};
}

export default async function StatusDetail({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params; const status = statusForSlug(slug); if (!status) notFound();
  const items = status.itemSlugs.map((itemSlug) => content.items.find((item) => item.slug === itemSlug)).filter((item): item is NonNullable<typeof item> => Boolean(item));
  return <SiteFrame sidebar>
    <GuideBreadcrumbs items={[{ label: 'Systems', href: '/systems' }, { label: 'Combat', href: '/systems/combat' }, { label: 'Conditions and effects', href: '/statuses' }, { label: status.name }]} />
    <PageIntro eyebrow={status.category} title={status.name} summary={status.summary} />
    <section className="article-section"><h2>Current rule</h2><dl className="fact-grid"><div><dt>Source</dt><dd>{status.sources}</dd></div><div><dt>Effect</dt><dd>{status.effect}</dd></div><div><dt>Duration</dt><dd>{status.duration}</dd></div><div><dt>Where it applies</dt><dd>{status.boundary}</dd></div></dl></section>
    <section className="article-section two-column"><div><h2>Clear or prevent</h2><p>{status.clearing}</p>{items.length ? <ul className="compact-list">{items.map((item) => <li key={item.id}><Link href={`/items/${item.slug}`}>{item.name}</Link> — {item.summary}</li>)}</ul> : null}</div><div><h2>Keep the boundary clear</h2><p>{status.persistence}</p><p>Read the mounted detail and the combat or Field Kit result before committing an action. A current target or state that no longer fits leaves the shown condition in place.</p></div></section>
    <RelatedGuides links={[{ label: 'All conditions and effects', href: '/statuses' }, { label: 'Combat', href: '/systems/combat' }, { label: 'Consumables and Field Kit', href: '/consumables' }, { label: 'Exploration', href: '/systems/exploration' }]} />
  </SiteFrame>;
}
