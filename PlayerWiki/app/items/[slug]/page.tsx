import type { Metadata } from 'next';
import Link from 'next/link';
import { notFound } from 'next/navigation';
import { PageIntro } from '@/components/page-intro';
import { PixelImage } from '@/components/pixel-image';
import { ItemCraftingRoutes } from '@/components/item-crafting-routes';
import { GuideBreadcrumbs, RelatedGuides } from '@/components/guide-navigation';
import { SiteFrame } from '@/components/site-frame';
import { content, humanize } from '@/lib/content';

export function generateStaticParams() { return content.items.filter(item => !item.gear).map(item => ({ slug: item.slug })); }
export async function generateMetadata({ params }: { params: Promise<{ slug: string }> }): Promise<Metadata> { const { slug } = await params; const item = content.items.find(entry => entry.slug === slug); return item ? { title: item.name, description: item.summary } : {}; }

export default async function ItemDetail({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params; const item = content.items.find(entry => entry.slug === slug); if (!item) notFound();
  return <SiteFrame sidebar><GuideBreadcrumbs items={[{ label: 'Reference', href: item.consumable ? '/consumables' : '/curios' }, { label: item.consumable ? 'Consumables' : 'Curios and key items', href: item.consumable ? '/consumables' : '/curios' }, { label: item.name }]} /><div className="entity-heading"><PixelImage src={item.assetURL} alt={`${item.name} icon`} size={96} /><PageIntro eyebrow={`${humanize(item.rarity)} ${humanize(item.category)}`} title={item.name} summary={item.summary} /></div>
    {item.consumable && <section className="article-section"><h2>Current use</h2><dl className="fact-grid">{Object.entries(item.consumable).map(([key, value]) => <div key={key}><dt>{humanize(key)}</dt><dd>{humanize(value)}</dd></div>)}</dl></section>}
    <ItemCraftingRoutes item={item} />
    <section className="article-section two-column"><div><h2>Trading</h2><p>{item.tradingPostDisposition === 'sellable' ? 'This item can be sold at the Trading Post.' : 'This object is protected from ordinary sale.'}</p></div><div><h2>Using it</h2><p>{item.consumable ? 'Use the exact eligible target shown by the item action.' : 'Its use belongs to the world, station, or route that names it.'}</p></div></section>
    <RelatedGuides links={[{ label: item.consumable ? 'All consumables' : 'All curios and key items', href: item.consumable ? '/consumables' : '/curios' }, { label: 'Crafting systems', href: '/crafting' }, { label: 'All resources', href: '/resources' }, { label: 'All systems', href: '/systems' }]} />
  </SiteFrame>;
}
