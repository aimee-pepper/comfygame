import Link from '@/components/wiki-link';
import { DirectoryDetailsIntro, DirectoryIndex } from '@/components/directory-navigation';
import { GuideBreadcrumbs, RelatedGuides } from '@/components/guide-navigation';
import { PageIntro } from '@/components/page-intro';
import { SiteFrame } from '@/components/site-frame';
import { content, humanize } from '@/lib/content';

const category = (value: string) => ({ recentRuin: 'Recent ruin', oldRuin: 'Old ruin', landmark: 'Natural landmark', living: 'Living site', hazard: 'Hazard' }[value] ?? humanize(value));

function disclosedResult(site: (typeof content.sites)[number]) {
  if (site.isNaturalAnchor) return 'Natural anchor point; not a search reward';
  const resources = site.yields.map((yielded) => `${yielded.quantity} ${content.resources.find((entry) => entry.id === yielded.resourceID)?.name ?? humanize(yielded.resourceID)}`);
  const items = site.itemIDs.map((id) => content.items.find((item) => item.id === id)?.name ?? humanize(id));
  const teachings = site.teaches.map((teaching) => `Teaching: ${humanize(teaching)}`);
  const guardian = site.guardianID ? content.creatures.find((creature) => creature.id === site.guardianID)?.name : null;
  return [...resources, ...items, ...teachings, ...(guardian ? [`Clear ${guardian} first`] : [])].join(' · ') || 'No separate result currently listed';
}

export default function SitesDirectory() {
  return <SiteFrame sidebar>
    <GuideBreadcrumbs items={[{ label: 'Home', href: '/' }, { label: 'Sites and hazards' }]} />
    <PageIntro eyebrow="Current field reference" title="Sites and hazards" summary="Browse every current named site, then use the shared rules below for Look, entry warnings, Search, guardians, disclosed rewards, depletion, and return visits." />
    <DirectoryIndex label="Browse sites" entries={content.sites.map((site) => ({ href: `/sites/${site.slug}`, name: site.name }))} />
    <DirectoryDetailsIntro title="Compare site profiles" summary="Use the at-a-glance table for kind, search length, and world association without revealing whether a site exists in your current map." />
    <section className="article-section"><h2>Current named site profiles</h2><p>A world can contain only profiles that fit its current conditions. This directory never promises an undiscovered site in a particular world or marks a site as found in your campaign.</p><div className="table-wrap data-table"><table><thead><tr><th>Site</th><th>Kind</th><th>Search</th><th>World association</th><th>Disclosed result</th></tr></thead><tbody>{content.sites.map((site) => <tr key={site.id}><td><Link href={`/sites/${site.slug}`}>{site.name}</Link></td><td>{category(site.category)}</td><td>{site.isNaturalAnchor ? 'Not searchable' : `${site.searchTurns} turn${site.searchTurns === 1 ? '' : 's'}`}</td><td>{site.conditions.length ? site.conditions.join(' · ') : 'No additional condition listed'}</td><td>{disclosedResult(site)}</td></tr>)}</tbody></table></div></section>
    <section className="article-section exploration-state-strip">{content.explorationVisuals.unsearchedSite && <figure><img src={content.explorationVisuals.unsearchedSite} alt="Unsearched site state" /><figcaption><strong>Unsearched site</strong><br />Use Tile names the discovered site and its remaining search turns.</figcaption></figure>}{content.explorationVisuals.searchedSite && <figure><img src={content.explorationVisuals.searchedSite} alt="Depleted site state" /><figcaption><strong>Depleted site</strong><br />The site remains visible once its current search completes.</figcaption></figure>}</section>
    <section className="article-section"><h2>Look before moving</h2><p>Arm Look and choose revealed adjacent ground to read its terrain, movement cost, visible growth, feature, and disclosed entry warning. Look does not move the party or spend a turn; unrevealed ground does not reveal a hidden site, plant, or danger.</p><div className="definition-grid"><div><h3>Ordinary flora</h3><p>Visible ordinary growth is safe to enter. Harvesting remains a separate action.</p></div><div><h3>Contact danger</h3><p>Thorn growth says entry will hurt the party and applies its immediate physical harm once.</p></div><div><h3>Poison danger</h3><p>Chemical growth warns of lingering danger. Re-entry renews the displayed poison rather than stacking another copy.</p></div><div><h3>Active danger</h3><p>Coiled growth says entry will start an encounter. It is not passive entry damage.</p></div></div></section>
    <section className="article-section"><h2>Search the exact site underfoot</h2><p>Use Tile names a discovered site and its remaining Search turns. Search spends one turn at a time. The site becomes depleted only when its final current Search completes and its disclosed contents are awarded.</p><p>An encounter, guardian, changed tile, already-depleted site, or unresolved item-capacity choice leaves Search unavailable instead of spending a different action. Depletion remains part of that world’s history; the site does not vanish or become a different result.</p></section>
    <section className="article-section note-card"><h2>People’s location records</h2><p>Some people’s authored records include spoiler-marked location-hint stages. Read their exact wording on the person page, then compare it with the current named profiles here; a hint does not promise that a site is already present in an undiscovered world.</p><p><Link href="/people">Browse people and complete records</Link></p></section>
    <RelatedGuides links={[{ label: 'Exploration', href: '/systems/exploration' }, { label: 'People', href: '/people' }, { label: 'Resources', href: '/resources' }, { label: 'Flora', href: '/flora' }, { label: 'Bestiary', href: '/bestiary' }, { label: 'Combat', href: '/systems/combat' }]} />
  </SiteFrame>;
}
