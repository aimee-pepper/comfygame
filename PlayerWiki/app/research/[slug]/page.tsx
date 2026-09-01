import type { Metadata } from 'next';
import Link from 'next/link';
import { notFound } from 'next/navigation';
import { GuideBreadcrumbs, RelatedGuides } from '@/components/guide-navigation';
import { PageIntro } from '@/components/page-intro';
import { SiteFrame } from '@/components/site-frame';
import { content, humanize } from '@/lib/content';
import { researchBranchFor, researchNodeForSlug, researchNodeSlug, researchPrerequisiteNames } from '@/lib/research';

export function generateStaticParams() { return content.researchNodes.map((node) => ({ slug: researchNodeSlug(node) })); }
export async function generateMetadata({ params }: { params: Promise<{ slug: string }> }): Promise<Metadata> {
  const { slug } = await params; const node = researchNodeForSlug(slug); return node ? { title: node.name, description: node.blurb } : {};
}

export default async function ResearchNodeDetail({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params; const node = researchNodeForSlug(slug); if (!node) notFound();
  const branch = researchBranchFor(node.branch);
  const station = branch?.stationID ? content.stations.find((entry) => entry.id === branch.stationID) : null;
  const bundled = node.constructionBundledWith ? content.stations.find((entry) => entry.id === node.constructionBundledWith) : null;
  const prerequisites = researchPrerequisiteNames(node);
  const resourceCosts = Object.entries(node.cost.resources).sort(([left], [right]) => left.localeCompare(right));
  return <SiteFrame sidebar>
    <GuideBreadcrumbs items={[{ label: 'Systems', href: '/systems' }, { label: 'Research', href: '/systems/research' }, { label: 'Research directory', href: '/research' }, { label: node.name }]} />
    <PageIntro eyebrow={branch?.name ?? 'Research'} title={node.name} summary={node.blurb} />
    <section className="article-section"><h2>Current node details</h2><dl className="fact-grid"><div><dt>Branch</dt><dd>{branch?.name ?? 'Current Research'}</dd></div><div><dt>Research screen</dt><dd>{station ? <Link href={`/places/${station.slug}`}>{station.name}</Link> : 'Current Research screen'}</dd></div><div><dt>Earlier upgrades</dt><dd>{prerequisites.length ? prerequisites.join(', ') : 'No earlier upgrade listed'}</dd></div><div><dt>Other requirements</dt><dd>{[node.needsStationTier > 0 ? `Station tier ${node.needsStationTier}` : null, node.needsInstruments > 0 ? `${node.needsInstruments} field readings` : null, node.needsLifetimeRawRefined > 0 ? `${node.needsLifetimeRawRefined} Raw Essence refined` : null].filter(Boolean).join(' · ') || 'No other requirement listed'}</dd></div></dl></section>
    <section className="article-section two-column"><div><h2>Base cost</h2>{node.cost.essence === 0 && resourceCosts.length === 0 ? <p>Free.</p> : <ul className="compact-list">{node.cost.essence > 0 && <li>{node.cost.essence} Essence</li>}{resourceCosts.map(([id, amount]) => { const resource = content.resources.find((entry) => entry.id === id); return <li key={id}>{amount} {resource ? <Link href={`/resources/${resource.slug}`}>{resource.name}</Link> : humanize(id)}</li>; })}</ul>}<p>Read the live Research detail before Study; it confirms the current cost and readiness.</p></div><div><h2>Result</h2><p>{node.blurb}</p>{bundled && <p><strong>Bundled construction:</strong> this node is included when <Link href={`/places/${bundled.slug}`}>{bundled.name}</Link> is built.</p>}</div></section>
    <section className="article-section"><h2>Study and retain</h2><p>Choose this visible node only after its listed requirements and current cost are ready. A completed Study keeps this upgrade. If the current requirement or cost has changed, return to the Research detail; the node does not take a partial cost.</p></section>
    <RelatedGuides links={[{ label: 'Research directory', href: '/research' }, { label: 'Research guide', href: '/systems/research' }, { label: 'Library collections', href: '/services/library' }, ...(station ? [{ label: station.name, href: `/places/${station.slug}` }] : []), { label: 'All resources', href: '/resources' }]} />
  </SiteFrame>;
}
