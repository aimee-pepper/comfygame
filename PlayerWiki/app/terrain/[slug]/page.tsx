import type { Metadata } from 'next';
import Link from '@/components/wiki-link';
import { notFound } from 'next/navigation';
import { GuideBreadcrumbs, RelatedGuides } from '@/components/guide-navigation';
import { PageIntro } from '@/components/page-intro';
import { PixelImage } from '@/components/pixel-image';
import { SiteFrame } from '@/components/site-frame';
import { resourcesFor, terrainForSlug, terrainProfiles } from '@/lib/world-reference';

export function generateStaticParams() { return terrainProfiles.map((terrain) => ({ slug: terrain.slug })); }
export async function generateMetadata({ params }: { params: Promise<{ slug: string }> }): Promise<Metadata> { const terrain = terrainForSlug((await params).slug); return terrain ? { title: terrain.name, description: terrain.movement } : {}; }

export default async function TerrainDetailPage({ params }: { params: Promise<{ slug: string }> }) {
  const terrain = terrainForSlug((await params).slug);
  if (!terrain) notFound();
  const resources = resourcesFor(terrain.resourceIDs);
  return <SiteFrame sidebar><GuideBreadcrumbs items={[{ label: 'World reference', href: '/world' }, { label: 'Terrain', href: '/terrain' }, { label: terrain.name }]} /><PageIntro eyebrow="Terrain profile" title={terrain.name} summary={terrain.movement} />
    <section className="article-section terrain-detail-heading">{terrain.assetURL && <PixelImage src={terrain.assetURL} alt={`${terrain.name} terrain visual`} size={72} />}<dl className="fact-grid"><div><dt>Movement</dt><dd>{terrain.movement}</dd></div><div><dt>Sight</dt><dd>{terrain.sight}</dd></div><div><dt>Resource relationship</dt><dd>{terrain.host}</dd></div></dl></section>
    <section className="article-section"><h2>Related current resources</h2>{resources.length ? <nav aria-label={`${terrain.name} related resources`}>{resources.map((resource) => <Link href={`/resources/${resource.slug}`} key={resource.id}>{resource.name}</Link>)}</nav> : <p>No resource is assigned to this terrain profile by itself.</p>}<p>Terrain eligibility does not promise that a particular unrevealed tile contains a resource node.</p></section>
    <RelatedGuides links={[{ label: 'All terrain profiles', href: '/terrain' }, { label: 'World conditions', href: '/world' }, { label: 'Exploration', href: '/systems/exploration' }, { label: 'Resources', href: '/resources' }, { label: 'Flora harvesting', href: '/flora' }]} />
  </SiteFrame>;
}
