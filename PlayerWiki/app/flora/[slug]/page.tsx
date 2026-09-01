import type { Metadata } from 'next';
import Link from 'next/link';
import { notFound } from 'next/navigation';
import { GuideBreadcrumbs, RelatedGuides } from '@/components/guide-navigation';
import { PageIntro } from '@/components/page-intro';
import { PixelImage } from '@/components/pixel-image';
import { SiteFrame } from '@/components/site-frame';
import { floraForSlug, floraHarvestProfiles, resourcesFor } from '@/lib/world-reference';

export function generateStaticParams() { return floraHarvestProfiles.map((flora) => ({ slug: flora.slug })); }
export async function generateMetadata({ params }: { params: Promise<{ slug: string }> }): Promise<Metadata> { const flora = floraForSlug((await params).slug); return flora ? { title: flora.name, description: flora.summary } : {}; }

export default async function FloraDetailPage({ params }: { params: Promise<{ slug: string }> }) {
  const flora = floraForSlug((await params).slug);
  if (!flora) notFound();
  const resource = resourcesFor([flora.resultID])[0];
  return <SiteFrame sidebar><GuideBreadcrumbs items={[{ label: 'World reference', href: '/world' }, { label: 'Flora and harvesting', href: '/flora' }, { label: flora.name }]} /><PageIntro eyebrow="Flora harvest relationship" title={flora.name} summary={flora.summary} />
    <section className="article-section terrain-detail-heading">{resource?.assetURL && <PixelImage src={resource.assetURL} alt={`${resource.name} inventory icon`} size={72} />}<div><h2>Current output</h2><p>{resource ? <><Link href={`/resources/${resource.slug}`}>{resource.name}</Link> is the current resource relationship for this exact Flora profile.</> : flora.summary}</p><p>Only the revealed plant establishes this output. The ground label does not replace the Field Guide’s exact identity.</p></div></section>
    <section className="article-section note-card"><h2>Inspect before acting</h2><p>Use Look and the current Field Guide for the exact revealed tile. This reference does not assign a hidden plant, an encounter, or an entry consequence from a harvest relationship.</p></section>
    <RelatedGuides links={[{ label: 'All Flora harvest relationships', href: '/flora' }, ...(resource ? [{ label: resource.name, href: `/resources/${resource.slug}` }] : []), { label: 'Terrain profiles', href: '/terrain' }, { label: 'Exploration', href: '/systems/exploration' }, { label: 'World conditions', href: '/world' }]} />
  </SiteFrame>;
}
