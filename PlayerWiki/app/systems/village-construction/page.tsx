import Link from '@/components/wiki-link';
import { DirectoryDetailsIntro, DirectoryIndex } from '@/components/directory-navigation';
import { GuideBreadcrumbs, RelatedGuides } from '@/components/guide-navigation';
import { PageIntro } from '@/components/page-intro';
import { PixelImage } from '@/components/pixel-image';
import { SiteFrame } from '@/components/site-frame';
import { buildCost, content } from '@/lib/content';
import { craftingSystems } from '@/lib/crafting';
import { serviceForStation } from '@/lib/services';

function recipeSystemsFor(station: (typeof content.stations)[number]) {
  return craftingSystems.filter((system) => system.station.includes(station.name));
}

export default function VillageConstructionGuide() {
  return <SiteFrame sidebar>
    <GuideBreadcrumbs items={[{ label: 'Systems', href: '/systems' }, { label: 'Village construction' }]} />
    <PageIntro eyebrow="Current Village guide" title="Village construction and planning" summary="Every current Village destination is listed here once. Start with the places already open, then meet the named keeper for a foundation, review its exact materials, and build only when the current screen says it is ready." />
    <DirectoryIndex label="Browse construction entries" entries={content.stations.map((station) => ({ href: `/buildings/${station.slug}`, name: station.name, imageURL: station.assetURL, imageAlt: `${station.name} building visual` }))} />
    <DirectoryDetailsIntro title="Compare foundations" summary="This table keeps only the construction facts needed for planning. Open a building for its complete actions, recipes, research, and service links." />
    <section className="article-section">
      <h2>Every current Village destination</h2>
      <div className="table-wrap data-table"><table><thead><tr><th aria-label="Visual" /><th>Place</th><th>Access and exact requirement</th><th>What opens there</th></tr></thead><tbody>{content.stations.map((station) => {
        const service = serviceForStation(station.id);
        const systems = recipeSystemsFor(station);
        const bundledResearch = content.researchNodes.filter((node) => node.constructionBundledWith === station.id);
        return <tr key={station.id}><td>{station.assetURL ? <PixelImage src={station.assetURL} alt={`${station.name} building visual`} /> : '—'}</td><td><Link href={`/buildings/${station.slug}`}>{station.name}</Link><br /><small>{station.blurb}</small></td><td>{station.unlockedAtStart ? 'Available at the start of a campaign.' : <><Link href={`/people/${station.keeperID?.replaceAll('_', '-')}`}>Meet {station.keeper}</Link>, then build this foundation.<br /><strong>{buildCost(station)}</strong></>}</td><td>{service ? <Link href={`/services/${service.slug}`}>{service.name}</Link> : systems.length ? systems.map((system, index) => <span key={system.slug}>{index ? ' · ' : ''}<Link href={`/crafting/${system.slug}`}>{system.name}</Link></span>) : <Link href={`/buildings/${station.slug}`}>Open the building guide</Link>}{bundledResearch.map((node) => <span key={node.id}><br /><Link href="/systems/research">Research included with construction: {node.name}</Link></span>)}</td></tr>;
      })}</tbody></table></div>
    </section>
    <section className="article-section two-column">
      <div><h2>How a foundation appears</h2><p>For a locked current place, first meet its named keeper and add them to the Library. Its foundation then appears on Home. Opening a foundation shows the exact construction cost and the current shortfall; the Builder, materials, Essence, and available space are checked again when you choose Build it.</p></div>
      <div><h2>What construction changes</h2><p>Completing a foundation opens that place at Tier 0. Its own screen then holds the service, crafting, or study action listed above. If the shown requirement changes before construction completes, the foundation remains available to review and the build does not silently substitute a different cost.</p></div>
    </section>
    <section className="article-section note-card"><h2>Use the exact current requirement</h2><p>The mounted foundation remains the final check for stock, tier, keeper, and current cost. Construction is one action: when it cannot complete, the named materials and current holdings stay in place. Follow the building, service, crafting, or Research link for deeper facts instead of repeating those systems here.</p></section>
    <RelatedGuides links={[{ label: 'All places and stations', href: '/places' }, { label: 'Village services', href: '/services' }, { label: 'Crafting systems', href: '/crafting' }, { label: 'Research', href: '/systems/research' }, { label: 'Resources', href: '/resources' }, { label: 'All systems', href: '/systems' }]} />
  </SiteFrame>;
}
