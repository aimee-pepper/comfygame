import Link from 'next/link';
import { GuideBreadcrumbs, RelatedGuides } from '@/components/guide-navigation';
import { PageIntro } from '@/components/page-intro';
import { SiteFrame } from '@/components/site-frame';
import { content, humanize } from '@/lib/content';

const category = (value: string) => ({ recentRuin: 'Recent ruin', oldRuin: 'Old ruin', landmark: 'Natural landmark', living: 'Living site', hazard: 'Hazard' }[value] ?? humanize(value));

export default function SitesDirectory() {
  return <SiteFrame sidebar>
    <GuideBreadcrumbs items={[{ label: 'Systems', href: '/systems' }, { label: 'Sites and hazards', href: '/systems/sites-hazards' }, { label: 'Site directory' }]} />
    <PageIntro eyebrow="Current field reference" title="Site directory" summary="Browse the current named site profiles, their world-condition associations, and the disclosed result after a completed search." />
    <section className="article-section exploration-state-strip">{content.explorationVisuals.unsearchedSite && <figure><img src={content.explorationVisuals.unsearchedSite} alt="Unsearched site state" /><figcaption><strong>Unsearched site</strong><br />Use Tile names the discovered site and its remaining search turns.</figcaption></figure>}{content.explorationVisuals.searchedSite && <figure><img src={content.explorationVisuals.searchedSite} alt="Depleted site state" /><figcaption><strong>Depleted site</strong><br />The site remains visible once its current search completes.</figcaption></figure>}</section>
    <section className="article-section"><h2>Current named site profiles</h2><p>A world can contain only profiles that fit its current conditions. This directory never promises an undiscovered site in a particular world or marks a site as found in your campaign.</p><div className="table-wrap data-table"><table><thead><tr><th>Site</th><th>Kind</th><th>Search</th><th>World association</th></tr></thead><tbody>{content.sites.map((site) => <tr key={site.id}><td><Link href={`/sites/${site.slug}`}>{site.name}</Link></td><td>{category(site.category)}</td><td>{site.isNaturalAnchor ? 'Not searchable' : `${site.searchTurns} turn${site.searchTurns === 1 ? '' : 's'}`}</td><td>{site.conditions.length ? site.conditions.join(' · ') : 'No additional condition listed'}</td></tr>)}</tbody></table></div></section>
    <section className="article-section"><h2>Look, then search</h2><p>Look stays the source for the revealed tile’s exact feature and entry warning. On a discovered site, Use Tile shows the current search counter; a completed search makes that site depleted rather than replacing it with a different result.</p><p><Link href="/systems/sites-hazards">Read the site and hazard guide</Link></p></section>
    <RelatedGuides links={[{ label: 'Sites and hazards guide', href: '/systems/sites-hazards' }, { label: 'Exploration', href: '/systems/exploration' }, { label: 'Resources', href: '/resources' }, { label: 'Bestiary', href: '/bestiary' }]} />
  </SiteFrame>;
}
