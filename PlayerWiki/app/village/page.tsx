import Link from '@/components/wiki-link';
import { DirectoryDetailsIntro, DirectoryIndex } from '@/components/directory-navigation';
import { GuideBreadcrumbs, RelatedGuides } from '@/components/guide-navigation';
import { PageIntro } from '@/components/page-intro';
import { PixelImage } from '@/components/pixel-image';
import { SiteFrame } from '@/components/site-frame';
import { buildCost } from '@/lib/content';
import { buildingActions, buildingStatus, villageBuildings } from '@/lib/village';

function accessSummary(building: (typeof villageBuildings)[number]) {
  if (building.status === 'scheduled') return 'Not yet implemented.';
  if (building.unlockedAtStart) return 'Available from the beginning of a campaign.';
  if (building.keeper) return <>Meet <Link href={`/people/${building.keeperID?.replaceAll('_', '-')}`}>{building.keeper}</Link>, then complete the foundation.</>;
  return 'Use its current Village route.';
}

export default function VillageDirectory() {
  return <SiteFrame sidebar>
    <GuideBreadcrumbs items={[{ label: 'Home', href: '/' }, { label: 'Village' }]} />
    <PageIntro eyebrow="Village" title="Village buildings and services" summary="Find every Village destination in one place: what it is for, where it stands, when it opens, and where to read its complete building, service, crafting, and Research details." />
    <DirectoryIndex label="Browse the Village" entries={villageBuildings.map((building) => ({ href: `/buildings/${building.slug}`, name: building.name, imageURL: building.assetURL, imageAlt: `${building.name} building visual` }))} />
    <DirectoryDetailsIntro title="Village at a glance" summary="This is the useful middle layer: one concise entry per destination. Open a building name for its complete construction, actions, services, recipes, results, custody, and related materials." />
    <section className="article-section"><div className="table-wrap data-table"><table><thead><tr><th aria-label="Visual" /><th>Destination</th><th>At a glance</th><th>Access and foundation</th><th>What it opens</th></tr></thead><tbody>{villageBuildings.map((building) => {
      const { service, systems } = buildingActions(building);
      return <tr key={building.id}>
        <td>{building.assetURL ? <PixelImage src={building.assetURL} alt={`${building.name} building visual`} /> : '—'}</td>
        <td><Link href={`/buildings/${building.slug}`}>{building.name}</Link><br /><small>{buildingStatus(building)}</small></td>
        <td><strong>{building.zone}.</strong> {building.blurb}</td>
        <td>{accessSummary(building)}{building.status === 'implemented' && !building.unlockedAtStart ? <><br /><strong>{buildCost(building)}</strong></> : null}</td>
        <td>{building.status === 'scheduled' ? 'No live action, service, recipe, or reward is published.' : service ? <><Link href={`/buildings/${building.slug}`}>{service.name}</Link> — {service.summary}</> : systems.length ? systems.map((system, index) => <span key={system.slug}>{index ? ' · ' : ''}<Link href={`/crafting/${system.slug}`}>{system.name}</Link> — {system.summary}</span>) : <Link href={`/buildings/${building.slug}`}>Read the complete destination entry</Link>}</td>
      </tr>;
    })}</tbody></table></div></section>
    <section className="article-section two-column"><div><h2>How a foundation appears</h2><p>Places that are already open are available from the beginning. For a locked current place, meet its named keeper first. Its foundation then appears at THE COTTAGE, where the current preview names the exact materials, Essence, area, and any shortfall.</p></div><div><h2>What construction changes</h2><p>Completing a foundation opens that place at its current starting tier. The building’s complete entry then links to its service, crafting, or Research work. Construction does not silently grant an item, recipe output, or unrelated capability unless that entry says it does.</p></div></section>
    <section className="article-section two-column"><div><h2>Confirm the current requirement</h2><p>The mounted foundation is the final authority for current cost and readiness. If stock, keeper, space, or the quoted requirement changes before completion, the build remains uncommitted and the named inputs stay where they are.</p></div><div><h2>Each facility has one complete entry</h2><p>Open a destination for its construction, keeper, service workflow, current actions, crafting and Research, results, custody, and first-use journey. A separate crafting-family page remains only when several recipes need their own comparison.</p></div></section>
    <section className="article-section note-card"><h2>Scheduled, not live</h2><p>Scheduled entries preserve only their accepted identity and placement. They do not promise a usable screen, construction cost, recipe, action, or reward until that route is implemented.</p></section>
    <RelatedGuides links={[{ label: 'Trading', href: '/trading' }, { label: 'Recycler', href: '/recycling' }, { label: 'Crafting', href: '/crafting' }, { label: 'Research', href: '/research' }, { label: 'Resources', href: '/resources' }, { label: 'Current progression', href: '/resources/progression' }]} />
  </SiteFrame>;
}
