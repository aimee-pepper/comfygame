import Link from 'next/link';
import { PageIntro } from '@/components/page-intro';
import { PixelImage } from '@/components/pixel-image';
import { SiteFrame } from '@/components/site-frame';
import { curios, humanize } from '@/lib/content';

export default function CuriosPage() {
  return <SiteFrame sidebar><PageIntro eyebrow="Reference" title="Curios and key items" summary="These catalogue objects are neither ordinary equipment nor ordinary consumables. Some identify, transform, unlock a route, or belong to a specific expedition interaction." />
    <div className="table-wrap data-table"><table><thead><tr><th aria-label="Image" /><th>Item</th><th>Kind</th><th>Rarity</th><th>Description</th></tr></thead><tbody>{curios.map(item => <tr key={item.id}><td><PixelImage src={item.assetURL} alt={`${item.name} icon`} /></td><td><Link href={`/items/${item.slug}`}>{item.name}</Link></td><td>{humanize(item.category)}</td><td>{humanize(item.rarity)}</td><td>{item.summary}</td></tr>)}</tbody></table></div>
  </SiteFrame>;
}
