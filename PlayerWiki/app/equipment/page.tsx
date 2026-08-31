import Link from 'next/link';
import { PageIntro } from '@/components/page-intro';
import { PixelImage } from '@/components/pixel-image';
import { SiteFrame } from '@/components/site-frame';
import { equipment, gearValue, humanize, itemProperties } from '@/lib/content';

const slots = ['weapon', 'offhand', 'head', 'armor', 'hands', 'feet', 'tool', 'keepsake'];

export default function EquipmentPage() {
  return <SiteFrame sidebar><PageIntro eyebrow="Reference" title="Equipment" summary="Compare every current gear entry by slot. Select an item name for its full description and properties; the table keeps icons compact so the useful facts stay visible." />
    {slots.map(slot => { const items = equipment.filter(item => item.gear?.slot === slot); if (!items.length) return null; return <section className="article-section" key={slot}><h2>{humanize(slot)}</h2><p className="catalogue-guidance">Select an item image or name to open its full entry.</p><div className="table-wrap data-table catalogue-summary"><table><thead><tr><th aria-label="Image" /><th>Item</th><th>Tier</th><th>Rarity</th><th>Damage / defence</th><th>Reach</th><th>Other properties</th></tr></thead><tbody>{items.map(item => <tr key={item.id}><td><Link href={`/equipment/${item.slug}`} aria-label={`Open ${item.name}`}><PixelImage src={item.assetURL} alt={`${item.name} icon`} /></Link></td><td><Link href={`/equipment/${item.slug}`}>{item.name}</Link><small>{item.summary}</small></td><td>{gearValue(item, 'tier')}</td><td><span className={`rarity rarity-${item.rarity}`}>{humanize(item.rarity)}</span></td><td>{gearValue(item, 'damage')}</td><td>{gearValue(item, 'reach')}</td><td>{itemProperties(item).slice(0, 2).join(' · ') || '—'}</td></tr>)}</tbody></table></div></section>; })}
  </SiteFrame>;
}
