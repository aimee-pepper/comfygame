import Link from '@/components/wiki-link';
import type { ReactNode } from 'react';
import { DirectoryDetailsIntro, DirectoryIndex } from '@/components/directory-navigation';
import { GuideBreadcrumbs, RelatedGuides } from '@/components/guide-navigation';
import { PageIntro } from '@/components/page-intro';
import { SiteFrame } from '@/components/site-frame';
import { content, humanize } from '@/lib/content';
import { researchNodeSlug, researchPrerequisiteNames } from '@/lib/research';

function cost(node: (typeof content.researchNodes)[number]) {
  const parts: ReactNode[] = [];
  if (node.cost.essence > 0) parts.push(`${node.cost.essence} Essence`);
  for (const [id, amount] of Object.entries(node.cost.resources).sort(([left], [right]) => left.localeCompare(right))) {
    const resource = content.resources.find((entry) => entry.id === id);
    parts.push(<span key={id}>{amount} {resource ? <Link href={`/resources/${resource.slug}`}>{resource.name}</Link> : humanize(id)}</span>);
  }
  return parts.length ? parts.flatMap((part, index) => index ? [' · ', part] : [part]) : 'Free';
}

function readiness(node: (typeof content.researchNodes)[number]) {
  const parts = [...researchPrerequisiteNames(node)];
  if (node.needsStationTier > 0) parts.push(`Station tier ${node.needsStationTier}`);
  if (node.needsInstruments > 0) parts.push(`${node.needsInstruments} field readings`);
  if (node.needsLifetimeRawRefined > 0) parts.push(`${node.needsLifetimeRawRefined} Raw Essence refined`);
  return parts.length ? parts.join(' · ') : 'No earlier requirement listed';
}

export default function ResearchDirectory() {
  return <SiteFrame sidebar>
    <GuideBreadcrumbs items={[{ label: 'Systems', href: '/systems' }, { label: 'Research', href: '/systems/research' }, { label: 'Research directory' }]} />
    <PageIntro eyebrow="Player reference" title="Research directory" summary="Browse every current Research node by branch. Open a node to see its current prerequisites, base cost, result, linked station, and any bundled construction." />
    <DirectoryIndex label="Browse Research" entries={content.researchNodes.map((node) => ({ href: `/research/${researchNodeSlug(node)}`, name: node.name }))} />
    <DirectoryDetailsIntro title="Compare Research by branch" summary="Scan prerequisites, base cost, and current result; the full node page holds its complete dependencies and related routes." />
    {content.researchBranches.map((branch) => {
      const nodes = content.researchNodes.filter((node) => node.branch === branch.id);
      const station = branch.stationID ? content.stations.find((entry) => entry.id === branch.stationID) : null;
      return <section className="article-section" key={branch.id}><h2>{branch.name}</h2><p>{branch.blurb} {station ? <>Taught at <Link href={`/places/${station.slug}`}>{station.name}</Link>.</> : 'Available through the current Research screen.'}</p><div className="table-wrap data-table"><table><thead><tr><th>Node</th><th>Ready when</th><th>Base cost</th><th>Current result</th></tr></thead><tbody>{nodes.map((node) => <tr key={node.id}><td><Link href={`/research/${researchNodeSlug(node)}`}>{node.name}</Link></td><td>{readiness(node)}</td><td>{cost(node)}</td><td>{node.blurb}</td></tr>)}</tbody></table></div></section>;
    })}
    <RelatedGuides links={[{ label: 'Research guide', href: '/systems/research' }, { label: 'Library collections', href: '/services/library' }, { label: 'Resources', href: '/resources' }, { label: 'Crafting systems', href: '/crafting' }]} />
  </SiteFrame>;
}
