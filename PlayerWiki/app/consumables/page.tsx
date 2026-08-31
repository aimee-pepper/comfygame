import Link from 'next/link';
import { PageIntro } from '@/components/page-intro';
import { PixelImage } from '@/components/pixel-image';
import { SiteFrame } from '@/components/site-frame';
import { consumables, consumableValue, humanize } from '@/lib/content';

export default function ConsumablesPage() {
  return <SiteFrame sidebar><PageIntro eyebrow="Reference" title="Consumables" summary="Consumables are supplies spent for an immediate effect. The exact available target and result depend on the item and the current party or world state." />
    <div className="table-wrap data-table"><table><thead><tr><th aria-label="Image" /><th>Item</th><th>Rarity</th><th>Effect</th><th>Potency</th></tr></thead><tbody>{consumables.map(item => <tr key={item.id}><td><PixelImage src={item.assetURL} alt={`${item.name} icon`} /></td><td><Link href={`/items/${item.slug}`}>{item.name}</Link><small>{item.summary}</small></td><td>{humanize(item.rarity)}</td><td>{consumableValue(item, 'effect')}</td><td>{consumableValue(item, 'potency')}</td></tr>)}</tbody></table></div>
  </SiteFrame>;
}
