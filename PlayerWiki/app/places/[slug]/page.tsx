import type { Metadata } from 'next';
import Link from 'next/link';
import { notFound } from 'next/navigation';
import { PageIntro } from '@/components/page-intro';
import { SiteFrame } from '@/components/site-frame';
import { buildCost, content } from '@/lib/content';

export function generateStaticParams() { return content.stations.map(place => ({ slug: place.slug })); }
export async function generateMetadata({ params }: { params: Promise<{ slug: string }> }): Promise<Metadata> { const { slug } = await params; const place = content.stations.find(entry => entry.slug === slug); return place ? { title: place.name, description: place.blurb } : {}; }

export default async function PlaceDetail({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params; const place = content.stations.find(entry => entry.slug === slug); if (!place) notFound();
  return <SiteFrame sidebar><PageIntro eyebrow={place.zone} title={place.name} summary={place.blurb} />
    <section className="article-section"><h2>Using this place</h2><dl className="fact-grid"><div><dt>Location</dt><dd>{place.zone}</dd></div><div><dt>Available</dt><dd>{place.unlockedAtStart ? 'From the beginning' : 'After construction'}</dd></div><div><dt>Construction</dt><dd>{buildCost(place)}</dd></div><div><dt>Keeper</dt><dd>{place.keeper ? <Link href={`/people/${place.keeperID?.replaceAll('_', '-')}`}>{place.keeper}</Link> : 'No resident keeper'}</dd></div></dl>{place.buildBlurb && <p>{place.buildBlurb}</p>}</section>
    <section className="article-section"><h2>Progression</h2><p>This station begins at tier {place.startingTier} and currently has content through tier {place.catalogueMaxTier}. Its own screen shows the exact actions and requirements that are available now.</p></section>
    <nav className="next-links"><Link href="/places">Back to all places</Link></nav>
  </SiteFrame>;
}
