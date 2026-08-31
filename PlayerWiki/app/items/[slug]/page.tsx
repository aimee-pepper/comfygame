import type { Metadata } from 'next';
import Link from 'next/link';
import { notFound } from 'next/navigation';
import { PageIntro } from '@/components/page-intro';
import { PixelImage } from '@/components/pixel-image';
import { ItemCraftingRoutes } from '@/components/item-crafting-routes';
import { GuideBreadcrumbs, RelatedGuides } from '@/components/guide-navigation';
import { SiteFrame } from '@/components/site-frame';
import { consumableDuration, consumableEffect, consumableTarget, content, humanize } from '@/lib/content';

export function generateStaticParams() { return content.items.filter(item => !item.gear).map(item => ({ slug: item.slug })); }
export async function generateMetadata({ params }: { params: Promise<{ slug: string }> }): Promise<Metadata> { const { slug } = await params; const item = content.items.find(entry => entry.slug === slug); return item ? { title: item.name, description: item.summary } : {}; }

export default async function ItemDetail({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params; const item = content.items.find(entry => entry.slug === slug); if (!item) notFound();
  return <SiteFrame sidebar><GuideBreadcrumbs items={[{ label: 'Reference', href: item.consumable ? '/consumables' : '/curios' }, { label: item.consumable ? 'Consumables' : 'Curios and key items', href: item.consumable ? '/consumables' : '/curios' }, { label: item.name }]} /><div className="entity-heading"><PixelImage src={item.assetURL} alt={`${item.name} icon`} size={96} /><PageIntro eyebrow={`${humanize(item.rarity)} ${humanize(item.category)}`} title={item.name} summary={item.summary} /></div>
    {item.consumable && <><section className="article-section"><h2>Current use</h2><dl className="fact-grid"><div><dt>Effect</dt><dd>{consumableEffect(item)}</dd></div><div><dt>Target</dt><dd>{consumableTarget(item)}</dd></div><div><dt>Current value</dt><dd>{humanize(item.consumable.potency)}</dd></div><div><dt>Duration</dt><dd>{consumableDuration(item)}</dd></div></dl></section><section className="article-section two-column"><div><h2>Field Kit and carrying</h2><p>Choose this identified item in the next Field Kit plan at home. It travels only when the plan is confirmed for departure; inspect its carried detail before use.</p></div><div><h2>Commit the shown use</h2><p>The selected item stays available until its exact target and action can complete. Cancelling, closing the detail, or finding an unavailable target leaves the item unspent.</p></div></section></>}
    {!item.consumable && <section className="article-section two-column"><div><h2>Identification and knowledge</h2><p>An unknown curio stays unknown until one exact example is studied at Home, identified with Solvent while carried, or tried in a valid current context. The result is not revealed by this guide before that action. Once a family is known, later matching examples can reveal immediately.</p></div><div><h2>Use and custody</h2><p>Keep the exact object in its shown Storehouse, Waiting, or carried location. The current station or world action names the available use; if the selected object or context changes, reopen the detail instead of assuming another object was used.</p></div></section>}
    <ItemCraftingRoutes item={item} />
    <section className="article-section two-column"><div><h2>Trading</h2><p>{item.tradingPostDisposition === 'sellable' ? 'An identified transferable object can be sold at the Trading Post. Unknown curios stay protected from ordinary sale.' : 'This object is protected from ordinary sale.'}</p></div><div><h2>Recycler</h2><p>{item.recyclerDisposition === 'recyclable' ? 'The Recycler can preview and dismantle this eligible item.' : 'The Recycler does not treat this object as recyclable gear.'} Previewing or cancelling never changes the selected object.</p></div></section>
    <RelatedGuides links={[{ label: item.consumable ? 'All consumables' : 'All curios and key items', href: item.consumable ? '/consumables' : '/curios' }, ...(item.consumable ? [{ label: 'Field supplies', href: '/systems/field-supplies' }] : [{ label: 'Knowledge and records', href: '/systems/knowledge-records' }, { label: 'Storehouse and inventory', href: '/services/storehouse' }, { label: 'Recycler', href: '/services/recycler' }, { label: 'Trading Post', href: '/services/trading-post' }]), { label: 'Crafting systems', href: '/crafting' }, { label: 'All resources', href: '/resources' }, { label: 'All systems', href: '/systems' }]} />
  </SiteFrame>;
}
