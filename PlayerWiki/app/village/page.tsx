import Link from '@/components/wiki-link';
import { DirectoryDetailsIntro, DirectoryIndex } from '@/components/directory-navigation';
import { GuideBreadcrumbs, RelatedGuides } from '@/components/guide-navigation';
import { PageIntro } from '@/components/page-intro';
import { PixelImage } from '@/components/pixel-image';
import { SiteFrame } from '@/components/site-frame';
import { buildCost } from '@/lib/content';
import { buildingActions, buildingStatus, villageBuildings, villageLocation } from '@/lib/village';

function accessSummary(building: (typeof villageBuildings)[number]) {
  if (building.status === 'scheduled') return 'Planned — not available yet.';
  if (building.unlockedAtStart) return 'Available from the beginning of a campaign.';
  if (building.keeper) return <>Meet <Link href={`/people/${building.keeperID?.replaceAll('_', '-')}`}>{building.keeper}</Link>, then complete the foundation.</>;
  return 'Open it from its shown Cottage area.';
}

export default function VillageDirectory() {
  return <SiteFrame sidebar>
    <GuideBreadcrumbs items={[{ label: 'Home', href: '/' }, { label: 'Village' }]} />
    <PageIntro eyebrow="Village" title="Village buildings and services" summary="Find every Village destination in one place: what it is for, where it stands, when it opens, and where to read its complete building, service, crafting, and Research details." />
    <DirectoryIndex label="Browse the Village" entries={villageBuildings.map((building) => ({ href: `/buildings/${building.slug}`, name: building.name, imageURL: building.assetURL, imageAlt: `${building.name} building visual` }))} />
    <DirectoryDetailsIntro title="Village at a glance" summary="Each destination has one concise entry here. Open a building name for its construction, actions, services, recipes, results, storage, and related materials." />
    <section className="article-section"><div className="table-wrap data-table"><table><thead><tr><th aria-label="Visual" /><th>Destination</th><th>At a glance</th><th>Access and foundation</th><th>What it opens</th></tr></thead><tbody>{villageBuildings.map((building) => {
      const { service, systems } = buildingActions(building);
      return <tr key={building.id}>
        <td>{building.assetURL ? <PixelImage src={building.assetURL} alt={`${building.name} building visual`} /> : '—'}</td>
        <td><Link href={`/buildings/${building.slug}`}>{building.name}</Link><br /><small>{buildingStatus(building)}</small></td>
        <td><strong>{villageLocation(building.zone)}.</strong> {building.blurb}</td>
        <td>{accessSummary(building)}{building.status === 'implemented' && !building.unlockedAtStart ? <><br /><strong>{buildCost(building)}</strong></> : null}</td>
        <td>{building.status === 'scheduled' ? <><strong>Planned —</strong> {building.blurb}</> : service ? <><Link href={`/buildings/${building.slug}`}>{service.name}</Link> — {service.summary}</> : systems.length ? systems.map((system, index) => <span key={system.slug}>{index ? ' · ' : ''}<Link href={`/crafting/${system.slug}`}>{system.name}</Link> — {system.summary}</span>) : <Link href={`/buildings/${building.slug}`}>Read the complete destination entry</Link>}</td>
      </tr>;
    })}</tbody></table></div></section>
    <section className="article-section two-column"><div><h2>How a foundation appears</h2><p>Some places are open from the beginning. For another available building, meet its named keeper first. Its foundation then appears at THE COTTAGE, where the preview lists the materials, Essence, area, and anything you are missing.</p></div><div><h2>What construction changes</h2><p>Completing a foundation opens that place at its starting tier. The building’s complete entry then links to its services, crafting, or Research. Building it does not give you a finished item or an unrelated ability unless that entry says so.</p></div></section>
    <section className="article-section two-column"><div><h2>Check the requirement before building</h2><p>The in-game foundation shows the price and whether you are ready. If your materials, keeper, available space, or the requirement changes before completion, nothing is spent and you can review the build again.</p></div><div><h2>Each facility has one complete entry</h2><p>Open a destination for its construction, keeper, services, actions, crafting and Research, results, storage, and first-use journey. A separate crafting-family page is used only when several recipes need their own comparison.</p></div></section>
    <section className="article-section note-card"><h2>Planned places</h2><p>A Planned label means the place and its purpose belong to the intended Village, but you cannot visit or build it yet. Future costs, recipes, actions, and rewards will appear only after they are actually available in the game.</p></section>
    <RelatedGuides links={[{ label: 'Trading', href: '/trading' }, { label: 'Recycler', href: '/recycling' }, { label: 'Crafting', href: '/crafting' }, { label: 'Research', href: '/research' }, { label: 'Resources', href: '/resources' }, { label: 'Current progression', href: '/resources/progression' }]} />
  </SiteFrame>;
}
