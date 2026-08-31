import Link from 'next/link';
import { PageIntro } from '@/components/page-intro';
import { PixelImage } from '@/components/pixel-image';
import { SiteFrame } from '@/components/site-frame';
import { consumables, consumableValue, humanize } from '@/lib/content';

export default function ConsumablesPage() {
  return <SiteFrame sidebar><PageIntro eyebrow="Reference" title="Consumables" summary="Consumables are supplies spent for an immediate effect. The exact available target and result depend on the item and the current party or world state." />
    <section className="article-section"><h2>Current supplies</h2><p className="catalogue-guidance">Select an item image or name to open its full entry.</p><div className="table-wrap data-table catalogue-summary"><table><thead><tr><th aria-label="Image" /><th>Item</th><th>Rarity</th><th>Effect</th><th>Potency</th></tr></thead><tbody>{consumables.map(item => <tr key={item.id}><td><Link href={`/items/${item.slug}`} aria-label={`Open ${item.name}`}><PixelImage src={item.assetURL} alt={`${item.name} icon`} /></Link></td><td><Link href={`/items/${item.slug}`}>{item.name}</Link><small>{item.summary}</small></td><td>{humanize(item.rarity)}</td><td>{consumableValue(item, 'effect')}</td><td>{consumableValue(item, 'potency')}</td></tr>)}</tbody></table></div></section>
  </SiteFrame>;
}
