import Link from 'next/link';
import { GuideBreadcrumbs, RelatedGuides } from '@/components/guide-navigation';
import { PageIntro } from '@/components/page-intro';
import { SiteFrame } from '@/components/site-frame';
import { content, humanize } from '@/lib/content';

function disclosedResult(site: (typeof content.sites)[number]) {
  if (site.isNaturalAnchor) return 'A natural anchor point, not a search reward';
  const resources = site.yields.map((yielded) => {
    const resource = content.resources.find((entry) => entry.id === yielded.resourceID);
    return `${yielded.quantity} ${resource?.name ?? humanize(yielded.resourceID)}`;
  });
  const items = site.itemIDs.map((id) => content.items.find((item) => item.id === id)?.name ?? humanize(id));
  const teachings = site.teaches.map((teaching) => `teaching: ${humanize(teaching)}`);
  const guardian = site.guardianID ? content.creatures.find((creature) => creature.id === site.guardianID)?.name : null;
  return [...resources, ...items, ...teachings, ...(guardian ? [`clear the current ${guardian} first`] : [])].join(', ') || 'No separate result is currently listed';
}

export default function SitesHazardsGuide() {
  return <SiteFrame sidebar>
    <GuideBreadcrumbs items={[{ label: 'Systems', href: '/systems' }, { label: 'Sites and hazards' }]} />
    <PageIntro eyebrow="Current field reference" title="Sites and hazards" summary="Use Look on revealed adjacent ground, read the exact entry warning before stepping, and search a discovered site until its current counter reaches completion." />
    <section className="article-section exploration-state-strip">{content.explorationVisuals.unsearchedSite && <figure><img src={content.explorationVisuals.unsearchedSite} alt="Unsearched site state" /><figcaption><strong>Unsearched site</strong><br />Read the current name and search counter before spending a turn.</figcaption></figure>}{content.explorationVisuals.searchedSite && <figure><img src={content.explorationVisuals.searchedSite} alt="Searched site state" /><figcaption><strong>Depleted site</strong><br />The site remains visible after its current search completes.</figcaption></figure>}</section>
    <section className="article-section"><h2>Look before moving</h2><p>Arm Look, choose one revealed adjacent tile, and read its current ground, movement cost, cracks, visible growth, feature, and any disclosed entry warning. Look does not move the party or spend a turn. An unrevealed tile stays unclear, so it does not provide an invented site, plant, or danger fact.</p><div className="definition-grid"><div><h3>Ordinary flora</h3><p>Visible ordinary growth has no entry harm. It is safe to enter; harvesting and any resource yield remain their own current action.</p></div><div><h3>Contact danger</h3><p>Thorn growth says “Entering will hurt the party.” Entering applies its immediate physical harm once.</p></div><div><h3>Poison danger</h3><p>Chemical growth says “Entering carries a lingering hazard.” Its entry harm is followed by the displayed lingering poison turns; entering again renews that poison rather than stacking a second copy.</p></div><div><h3>Active danger</h3><p>Coiled growth says “Entering will start an encounter.” It is an encounter choice, not an entry-damage or poison label.</p></div></div><p>The current Look copy keeps contact, chemical poison, and active encounter as distinct profiles. If the field presentation changes, follow the current tile’s exact Look result instead of assuming a combined contact-and-poison profile.</p></section>
    <section className="article-section"><h2>Search the exact site underfoot</h2><p>Use Tile shows the discovered site’s current name and remaining search turns. Search consumes one turn at a time. Before the final turn, the site remains in progress; on completion it becomes depleted and the disclosed contents are awarded. An active encounter, a guardian on the site, a changed tile, or an already depleted site leaves the search unavailable rather than spending a different action.</p><p>If an item does not fit the Field Kit, the current item decision asks you how to resolve that exact offered item instead of silently replacing carried supplies.</p></section>
    <section className="article-section"><h2>Current disclosed site rewards</h2><div className="table-wrap data-table"><table><thead><tr><th>Site</th><th>Search</th><th>Current disclosed result</th></tr></thead><tbody>{content.sites.map((site) => <tr key={site.id}><td><Link href={`/sites/${site.slug}`}>{site.name}</Link></td><td>{site.isNaturalAnchor ? 'Not searchable' : `${site.searchTurns} turn${site.searchTurns === 1 ? '' : 's'}`}</td><td>{disclosedResult(site)}</td></tr>)}</tbody></table></div><p>These rows describe the current authored contents once that site is discovered. They do not promise that an undiscovered site is present in every world.</p><p><Link href="/sites">Open the full site directory</Link></p></section>
    <RelatedGuides links={[{ label: 'Site directory', href: '/sites' }, { label: 'Exploration', href: '/systems/exploration' }, { label: 'Resource reference', href: '/resources' }, { label: 'Bestiary records', href: '/bestiary' }, { label: 'Field supplies', href: '/systems/field-supplies' }, { label: 'Combat', href: '/systems/combat' }]} />
  </SiteFrame>;
}
