import type { Metadata } from 'next';
import Link from '@/components/wiki-link';
import { notFound } from 'next/navigation';
import { GuideBreadcrumbs, RelatedGuides } from '@/components/guide-navigation';
import { PageIntro } from '@/components/page-intro';
import { SiteFrame } from '@/components/site-frame';
import { content, humanize } from '@/lib/content';
import { anchorageFirstAnchor } from '@/lib/anchorage-first-anchor';

const category = (value: string) => ({ recentRuin: 'Recent ruin', oldRuin: 'Old ruin', landmark: 'Natural landmark', living: 'Living site', hazard: 'Hazard' }[value] ?? humanize(value));
const itemHref = (item: (typeof content.items)[number]) => item.gear ? `/equipment/${item.slug}` : `/items/${item.slug}`;

export function generateStaticParams() { return content.sites.map((site) => ({ slug: site.slug })); }
export async function generateMetadata({ params }: { params: Promise<{ slug: string }> }): Promise<Metadata> {
  const { slug } = await params;
  const site = content.sites.find((entry) => entry.slug === slug);
  return site ? { title: site.name, description: site.blurb } : {};
}

export default async function SiteDetail({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;
  const site = content.sites.find((entry) => entry.slug === slug);
  if (!site) notFound();
  const items = site.itemIDs.map((id) => content.items.find((item) => item.id === id)).filter(Boolean) as (typeof content.items)[number][];
  const guardian = site.guardianID ? content.creatures.find((creature) => creature.id === site.guardianID) : null;
  return <SiteFrame sidebar>
    <GuideBreadcrumbs items={[{ label: 'Sites and hazards', href: '/sites' }, { label: site.name }]} />
    <PageIntro eyebrow={category(site.category)} title={site.name} summary={site.blurb} />
    <section className="article-section"><h2>Where it may appear</h2><dl className="fact-grid"><div><dt>Placement</dt><dd>{humanize(site.placement)}{site.minimumDistanceFromEntry !== null ? ` · at least ${site.minimumDistanceFromEntry} tiles from entry` : ''}</dd></div><div><dt>Search</dt><dd>{site.isNaturalAnchor ? 'Natural anchor point · not searchable' : `${site.searchTurns} turn${site.searchTurns === 1 ? '' : 's'} to complete`}</dd></div><div><dt>Conditions</dt><dd>{site.conditions.length ? site.conditions.join(' · ') : 'No additional condition listed'}</dd></div><div><dt>After use</dt><dd>{site.isNaturalAnchor ? 'Used for anchoring rather than searching' : 'Search progresses one turn at a time; the site then remains depleted'}</dd></div></dl><p>These conditions show where this kind of site can appear. They do not reveal whether one exists in an unexplored part of your world.</p></section>
    <section className="article-section"><h2>What it provides</h2>{site.isNaturalAnchor ? <p>Atlas Seam can anchor its world. It does not provide a search reward.</p> : <div className="two-column"><div><h3>Resources</h3>{site.yields.length ? <ul className="compact-list">{site.yields.map((yielded) => { const resource = content.resources.find((entry) => entry.id === yielded.resourceID); return <li key={yielded.resourceID}>{yielded.quantity} {resource ? <Link href={`/resources/${resource.slug}`}>{resource.name}</Link> : humanize(yielded.resourceID)}</li>; })}</ul> : <p>No material reward is currently listed.</p>}<h3>Items</h3>{items.length ? <ul className="compact-list">{items.map((item) => <li key={item.id}><Link href={itemHref(item)}>{item.name}</Link></li>)}</ul> : <p>No separate item is currently listed.</p>}</div><div><h3>Knowledge and encounter</h3>{site.teaches.length ? <ul className="compact-list">{site.teaches.map((teaching) => <li key={teaching}>Teaches: {humanize(teaching)}</li>)}</ul> : <p>No separate lesson is currently listed.</p>}{guardian ? <p><strong>Guardian:</strong> defeat the <Link href={`/bestiary/${guardian.slug}`}>{guardian.name}</Link> before searching this site.</p> : <p>No fixed guardian is currently listed.</p>}</div></div>}</section>
    <section className="article-section"><h2>Look and depletion</h2><p>Use Look for the actual revealed tile, including any current entry warning. Use Tile then shows this discovered site’s remaining counter. If the site is already depleted, the current action remains unavailable rather than silently awarding a replacement result.</p></section>
    {site.id === anchorageFirstAnchor.seamID && <section className="article-section note-card"><h2>Anchor one world</h2><p>An Atlas Seam is not searched and does not reveal coordinates elsewhere in the map. After the Anchorage is built, Look shows this Seam’s current Essence cost. Confirming preserves this world through this Seam at the displayed cost.</p><ul className="compact-list">{anchorageFirstAnchor.seamConfirmation.map((line) => <li key={line}>{line}</li>)}</ul><p>Success preserves the world and its current state, but the expedition continues with its current haul. It does not reset the world, make a delivery, or begin passive production.</p><p><Link href="/buildings/anchorage">Read Tovin’s first-anchor journey</Link> · <Link href="/crafting/anchorage">Review the Anchor Frame alternative</Link></p></section>}
    <RelatedGuides links={[{ label: 'All sites and hazards', href: '/sites' }, { label: 'Exploration', href: '/systems/exploration' }, { label: 'Resources', href: '/resources' }, ...(guardian ? [{ label: guardian.name, href: `/bestiary/${guardian.slug}` }] : [])]} />
  </SiteFrame>;
}
