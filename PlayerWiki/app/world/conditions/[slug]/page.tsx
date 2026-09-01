import type { Metadata } from 'next';
import { notFound } from 'next/navigation';
import { GuideBreadcrumbs, RelatedGuides } from '@/components/guide-navigation';
import { PageIntro } from '@/components/page-intro';
import { SiteFrame } from '@/components/site-frame';
import { conditionForSlug, worldConditions } from '@/lib/world-reference';

export function generateStaticParams() { return worldConditions.map((condition) => ({ slug: condition.slug })); }
export async function generateMetadata({ params }: { params: Promise<{ slug: string }> }): Promise<Metadata> { const condition = conditionForSlug((await params).slug); return condition ? { title: condition.name, description: condition.blurb } : {}; }

export default async function WorldConditionPage({ params }: { params: Promise<{ slug: string }> }) {
  const condition = conditionForSlug((await params).slug);
  if (!condition) notFound();
  return <SiteFrame sidebar><GuideBreadcrumbs items={[{ label: 'World reference', href: '/world' }, { label: 'World conditions', href: '/world' }, { label: condition.name }]} /><PageIntro eyebrow="World condition" title={condition.name} summary={condition.blurb} />
    <section className="article-section"><h2>What it shapes</h2><p>{condition.detail}</p></section>
    <section className="article-section note-card"><h2>In a bound world</h2><p>Use the current Writing preview and revealed world detail for the exact result. This reference explains the condition; it does not promise a particular coordinate, site, creature, or deposit.</p></section>
    <RelatedGuides links={[{ label: 'All world conditions', href: '/world' }, { label: 'World Writing', href: '/systems/world-writing' }, { label: 'Exploration', href: '/systems/exploration' }, { label: 'Terrain profiles', href: '/terrain' }, { label: 'Flora harvesting', href: '/flora' }]} />
  </SiteFrame>;
}
