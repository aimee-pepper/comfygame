import Link from 'next/link';
import { PageIntro } from '@/components/page-intro';
import { PixelImage } from '@/components/pixel-image';
import { SiteFrame } from '@/components/site-frame';
import { curios, humanize } from '@/lib/content';

export default function CuriosPage() {
  return <SiteFrame sidebar><PageIntro eyebrow="Reference" title="Curios and key items" summary="These catalogue objects are neither ordinary equipment nor ordinary consumables. Some identify, transform, unlock a route, or belong to a specific expedition interaction." />
    <section className="article-section"><h2>Current curios</h2><p className="catalogue-guidance">Select an item image or name to open its full entry.</p><div className="table-wrap data-table catalogue-summary"><table><thead><tr><th aria-label="Image" /><th>Item</th><th>Kind</th><th>Rarity</th><th>Description</th></tr></thead><tbody>{curios.map(item => <tr key={item.id}><td><Link href={`/items/${item.slug}`} aria-label={`Open ${item.name}`}><PixelImage src={item.assetURL} alt={`${item.name} icon`} /></Link></td><td><Link href={`/items/${item.slug}`}>{item.name}</Link><small>{item.summary}</small></td><td>{humanize(item.category)}</td><td>{humanize(item.rarity)}</td><td>{item.summary}</td></tr>)}</tbody></table></div></section>
  </SiteFrame>;
}
