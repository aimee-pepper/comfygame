import Link from '@/components/wiki-link';
import { GuideBreadcrumbs, RelatedGuides } from '@/components/guide-navigation';
import { PageIntro } from '@/components/page-intro';
import { PixelImage } from '@/components/pixel-image';
import { SiteFrame } from '@/components/site-frame';
import { buildCost, content } from '@/lib/content';
import { craftingSystems, recipesFor } from '@/lib/crafting';
import { serviceForStation } from '@/lib/services';

function recipeSystemsFor(station: (typeof content.stations)[number]) {
  return craftingSystems.filter((system) => system.station.includes(station.name));
}

export default function VillageConstructionGuide() {
  return <SiteFrame sidebar>
    <GuideBreadcrumbs items={[{ label: 'Systems', href: '/systems' }, { label: 'Village construction' }]} />
    <PageIntro eyebrow="Current Village guide" title="Village construction and planning" summary="Every current Village destination is listed here once. Start with the places already open, then meet the named keeper for a foundation, review its exact materials, and build only when the current screen says it is ready." />
    <section className="article-section two-column">
      <div><h2>How a foundation appears</h2><p>For a locked current place, first meet its named keeper and add them to the Library. Its foundation then appears on Home. Opening a foundation shows the exact construction cost and the current shortfall; the Builder, materials, Essence, and available space are checked again when you choose Build it.</p></div>
      <div><h2>What construction changes</h2><p>Completing a foundation opens that place at Tier 0. Its own screen then holds the service, crafting, or study action listed below. If the shown requirement changes before construction completes, the foundation remains available to review and the build does not silently substitute a different cost.</p></div>
    </section>
    <section className="article-section">
      <h2>Every current Village destination</h2>
      <div className="table-wrap data-table"><table><thead><tr><th aria-label="Visual" /><th>Place</th><th>Access and exact requirement</th><th>What opens there</th><th>Current recipes, service, or study</th></tr></thead><tbody>{content.stations.map((station) => {
        const service = serviceForStation(station.id);
        const systems = recipeSystemsFor(station);
        const recipes = systems.flatMap((system) => recipesFor(system.slug));
        const bundledResearch = content.researchNodes.filter((node) => node.constructionBundledWith === station.id);
        return <tr key={station.id}><td>{station.assetURL ? <PixelImage src={station.assetURL} alt={`${station.name} building visual`} /> : '—'}</td><td><Link href={`/places/${station.slug}`}>{station.name}</Link><br /><small>{station.blurb}</small></td><td>{station.unlockedAtStart ? 'Available at the start of a campaign.' : <><Link href={`/people/${station.keeperID?.replaceAll('_', '-')}`}>Meet {station.keeper}</Link>, then build this foundation.<br /><strong>{buildCost(station)}</strong></>}</td><td>{service ? <Link href={`/services/${service.slug}`}>{service.name}</Link> : systems.length ? systems.map((system, index) => <span key={system.slug}>{index ? ' · ' : ''}<Link href={`/crafting/${system.slug}`}>{system.name}</Link></span>) : 'Open the current place detail.'}{bundledResearch.map((node) => <span key={node.id}><br /><Link href="/systems/research">Research included with construction: {node.name}</Link></span>)}</td><td>{recipes.length ? recipes.map((recipe, index) => <span key={recipe.id}>{index ? ', ' : ''}<Link href={`/crafting/${recipe.system}`}>{recipe.name}</Link></span>) : service ? service.useFor.map((action, index) => <span key={action}>{index ? ' · ' : ''}{action}</span>) : <>No separate recipe list is currently published; use the <Link href={`/places/${station.slug}`}>place guide</Link> for the current screen.</>}</td></tr>;
      })}</tbody></table></div>
    </section>
    <section className="article-section">
      <h2>Use the exact current requirement</h2>
      <p>Resource names in the table link to their current sources and consumers. A station’s current detail is the final check for stock, tier, keeper and any recipe-specific requirement. Construction is one action: when it cannot complete, the named materials and current holdings stay in place.</p>
      <div className="definition-grid"><div><h3>Current foundations</h3><p>Trading Post, Recycler, Blacksmith, Tannery, Bowyer, Armoury, Weaponsmith, Scriptorium, Survey Post, Apothecary, Reliquary, Wayfarer’s Table, Distillery, Channelworks, and Anchorage are each listed with their exact present cost.</p></div><div><h3>Places already open</h3><p>Writing Desk, Storehouse, Party, Essence Spring, Library, Firepit, and Bestiary are available at the start. Their individual pages show the current route and player-facing use.</p></div><div><h3>Recipes and actions</h3><p>Follow a recipe link for exact ingredients and output. Follow a service link for its current selection, confirmation, and retained-result behavior.</p></div><div><h3>Research</h3><p>When a construction includes a research result, the table names that current node and links to the Research guide.</p></div></div>
    </section>
    <RelatedGuides links={[{ label: 'All places and stations', href: '/places' }, { label: 'Village services', href: '/services' }, { label: 'Crafting systems', href: '/crafting' }, { label: 'Research', href: '/systems/research' }, { label: 'Resources', href: '/resources' }, { label: 'All systems', href: '/systems' }]} />
  </SiteFrame>;
}
