import type { Metadata } from 'next';
import Link from 'next/link';
import { notFound } from 'next/navigation';
import { PageIntro } from '@/components/page-intro';
import { PixelImage } from '@/components/pixel-image';
import { ItemCraftingRoutes } from '@/components/item-crafting-routes';
import { GuideBreadcrumbs, RelatedGuides } from '@/components/guide-navigation';
import { SiteFrame } from '@/components/site-frame';
import { equipment, humanize, itemProperties } from '@/lib/content';

export function generateStaticParams() { return equipment.map(item => ({ slug: item.slug })); }
export async function generateMetadata({ params }: { params: Promise<{ slug: string }> }): Promise<Metadata> {
  const { slug } = await params; const item = equipment.find(entry => entry.slug === slug); return item ? { title: item.name, description: item.summary } : {};
}

export default async function EquipmentDetail({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params; const item = equipment.find(entry => entry.slug === slug); if (!item || !item.gear) notFound();
  return <SiteFrame sidebar><GuideBreadcrumbs items={[{ label: 'Reference', href: '/equipment' }, { label: 'Equipment', href: '/equipment' }, { label: item.name }]} /><div className="entity-heading"><PixelImage src={item.assetURL} alt={`${item.name} icon`} size={96} /><PageIntro eyebrow={`${humanize(item.rarity)} ${humanize(item.gear.slot)}`} title={item.name} summary={item.summary} /></div>
    <section className="article-section"><h2>Current equipment facts</h2><dl className="fact-grid">{Object.entries(item.gear).map(([key, value]) => <div key={key}><dt>{humanize(key)}</dt><dd>{humanize(value)}</dd></div>)}</dl></section>
    <section className="article-section two-column"><div><h2>Eligibility</h2><p>This physical piece fits the {humanize(item.gear.slot)} slot. Its frozen piece profile supplies the slot and combat identity shown when you select it; a catalogue change does not rewrite a piece you already own.</p></div><div><h2>Material and reforge facts</h2><p>{itemProperties(item).length ? itemProperties(item).join('. ') : 'This current catalogue entry has no extra material field beyond its listed slot, tier and combat facts.'} Reforge rank and provenance belong to each physical piece, so inspect the selected piece before changing gear.</p></div></section>
    <ItemCraftingRoutes item={item} />
    <section className="article-section two-column"><div><h2>Custody and swapping</h2><p>Stored and Waiting pieces can be equipped at Home. A piece worn by another person is still shown and can make a same-slot swap. Gear carried in the active world remains visible but cannot be changed until the party returns.</p></div><div><h2>Trading and recycling</h2><p>{item.tradingPostDisposition === 'sellable' ? 'This item can be sold at the Trading Post.' : 'This item is protected from ordinary Trading Post sale.'} {item.recyclerDisposition === 'recyclable' ? 'The Recycler can preview and dismantle this gear.' : 'This item is not accepted as recyclable gear.'}</p></div></section>
    <RelatedGuides links={[{ label: 'All equipment', href: '/equipment' }, { label: 'Combat guide', href: '/systems/combat' }, { label: 'Conditions and effects', href: '/statuses' }, { label: 'Techniques and Gambits', href: '/techniques' }, { label: 'Party, Gear and Gambits', href: '/services/party-and-gear' }, { label: 'Blacksmith construction', href: '/crafting/blacksmith' }, { label: 'Armoury rebuilding', href: '/crafting/armoury' }]} />
  </SiteFrame>;
}
