import Link from 'next/link';
import { GuideBreadcrumbs, RelatedGuides } from '@/components/guide-navigation';
import { PageIntro } from '@/components/page-intro';
import { PixelImage } from '@/components/pixel-image';
import { SiteFrame } from '@/components/site-frame';
import { buildCost } from '@/lib/content';
import { buildingActions, buildingStatus, villageBuildings } from '@/lib/village';

export default function VillageDirectory() {
  return <SiteFrame sidebar>
    <GuideBreadcrumbs items={[{ label: 'Village services', href: '/services' }, { label: 'Village directory' }]} />
    <PageIntro eyebrow="Village reference" title="Village buildings and services" summary="Find each current Village destination, when it becomes usable, its published foundation requirement, and the service, station work, or Research it connects to." />
    <section className="article-section"><h2>Current Village</h2><p>Open a building for its exact current requirement, actions, recipes, and related resources. A displayed live entry is a current player route; a scheduled entry is clearly marked and is not an available screen.</p><div className="village-directory">{villageBuildings.map((building) => {
      const { service, systems, recipes } = buildingActions(building);
      return <article className="village-directory-card" key={building.id}>
        <div className="village-card-heading">{building.assetURL ? <PixelImage src={building.assetURL} alt={`${building.name} building visual`} size={48} /> : null}<div><p className={`village-status ${building.status}`}>{buildingStatus(building)}</p><h2><Link href={`/buildings/${building.slug}`}>{building.name}</Link></h2><p>{building.blurb}</p></div></div>
        <dl className="village-card-facts"><div><dt>Access</dt><dd>{building.status === 'scheduled' ? 'Not yet implemented' : building.unlockedAtStart ? 'Available at the start' : building.keeper ? <>Meet <Link href={`/people/${building.keeperID?.replaceAll('_', '-')}`}>{building.keeper}</Link>, then build</> : 'Use the current Village route'}</dd></div><div><dt>Foundation</dt><dd>{building.status === 'scheduled' ? 'No live construction action published' : buildCost(building)}</dd></div><div><dt>Current work</dt><dd>{building.status === 'scheduled' ? 'No live action or recipe is published' : service ? <Link href={`/services/${service.slug}`}>{service.name}</Link> : systems.length ? systems.map((system, index) => <span key={system.slug}>{index ? ' · ' : ''}<Link href={`/crafting/${system.slug}`}>{system.name}</Link></span>) : 'Open the current building detail'}</dd></div><div><dt>Outputs</dt><dd>{building.status === 'scheduled' ? 'Not published as live' : recipes.length ? recipes.slice(0, 3).map((recipe, index) => <span key={recipe.id}>{index ? ' · ' : ''}<Link href={`/crafting/${recipe.system}`}>{recipe.result}</Link></span>) : service ? 'See the service detail' : 'No separate current output list published'}</dd></div></dl>
      </article>;
    })}</div></section>
    <section className="article-section note-card"><h2>Scheduled, not live</h2><p>Scheduled entries preserve only their current published identity and placement. They do not promise a usable screen, cost, recipe, or reward until that route is implemented.</p></section>
    <RelatedGuides links={[{ label: 'Village services', href: '/services' }, { label: 'Crafting directory', href: '/crafting' }, { label: 'Resources', href: '/resources' }, { label: 'Current progression', href: '/resources/progression' }, { label: 'Village construction guide', href: '/systems/village-construction' }]} />
  </SiteFrame>;
}
