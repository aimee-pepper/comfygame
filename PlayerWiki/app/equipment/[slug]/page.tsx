import type { Metadata } from 'next';
import Link from 'next/link';
import { notFound } from 'next/navigation';
import { PageIntro } from '@/components/page-intro';
import { PixelImage } from '@/components/pixel-image';
import { ItemCraftingRoutes } from '@/components/item-crafting-routes';
import { GuideBreadcrumbs, RelatedGuides } from '@/components/guide-navigation';
import { SiteFrame } from '@/components/site-frame';
import { equipment, humanize } from '@/lib/content';

export function generateStaticParams() { return equipment.map(item => ({ slug: item.slug })); }
export async function generateMetadata({ params }: { params: Promise<{ slug: string }> }): Promise<Metadata> {
  const { slug } = await params; const item = equipment.find(entry => entry.slug === slug); return item ? { title: item.name, description: item.summary } : {};
}

export default async function EquipmentDetail({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params; const item = equipment.find(entry => entry.slug === slug); if (!item || !item.gear) notFound();
  return <SiteFrame sidebar><GuideBreadcrumbs items={[{ label: 'Reference', href: '/equipment' }, { label: 'Equipment', href: '/equipment' }, { label: item.name }]} /><div className="entity-heading"><PixelImage src={item.assetURL} alt={`${item.name} icon`} size={96} /><PageIntro eyebrow={`${humanize(item.rarity)} ${humanize(item.gear.slot)}`} title={item.name} summary={item.summary} /></div>
    <section className="article-section"><h2>Equipment facts</h2><dl className="fact-grid">{Object.entries(item.gear).map(([key, value]) => <div key={key}><dt>{humanize(key)}</dt><dd>{humanize(value)}</dd></div>)}</dl></section>
    <ItemCraftingRoutes item={item} />
    <section className="article-section two-column"><div><h2>Trading</h2><p>{item.tradingPostDisposition === 'sellable' ? 'This item can be sold at the Trading Post.' : 'This item is protected from ordinary Trading Post sale.'}</p></div><div><h2>Recycling</h2><p>{item.recyclerDisposition === 'recyclable' ? 'The Recycler can preview and dismantle this gear.' : 'This item is not accepted as recyclable gear.'}</p></div></section>
    <RelatedGuides links={[{ label: 'All equipment', href: '/equipment' }, { label: 'Combat guide', href: '/systems/combat' }, { label: 'Party, Gear and Gambits', href: '/services/party-and-gear' }]} />
  </SiteFrame>;
}
