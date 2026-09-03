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
    <GuideBreadcrumbs items={[{ label: 'Home', href: '/' }, { label: 'Research' }]} />
    <PageIntro eyebrow="Player reference" title="Research" summary="Browse every current branch and node, then use the shared rules below for access, prerequisites, cost, Study, permanence, and refusal. Each node page contains its complete individual facts." />
    <DirectoryIndex label="Browse Research" entries={content.researchNodes.map((node) => ({ href: `/research/${researchNodeSlug(node)}`, name: node.name }))} />
    <DirectoryDetailsIntro title="Compare Research by branch" summary="Scan prerequisites, base cost, and current result; the full node page holds its complete dependencies and related routes." />
    {content.researchBranches.map((branch) => {
      const nodes = content.researchNodes.filter((node) => node.branch === branch.id);
      const station = branch.stationID ? content.stations.find((entry) => entry.id === branch.stationID) : null;
      return <section className="article-section" key={branch.id}><h2>{branch.name}</h2><p>{branch.blurb} {station ? <>Taught at <Link href={`/buildings/${station.slug}`}>{station.name}</Link>.</> : 'Available through the current Research screen.'}</p><div className="table-wrap data-table"><table><thead><tr><th>Node</th><th>Ready when</th><th>Base cost</th><th>Current result</th></tr></thead><tbody>{nodes.map((node) => <tr key={node.id}><td><Link href={`/research/${researchNodeSlug(node)}`}>{node.name}</Link></td><td>{readiness(node)}</td><td>{cost(node)}</td><td>{node.blurb}</td></tr>)}</tbody></table></div></section>;
    })}
    <section className="article-section two-column"><div><h2>How to access Research</h2><p>Open the current Research screen from the Village. A branch tied to a specific building requires that place when its detail says so; other current branches remain on the shared Research screen.</p></div><div><h2>Use the current detail</h2><p>Every visible node names its earlier upgrades, other requirements, published base cost, and result. The in-game detail is the final authority for current readiness, missing stock, keeper supply, and current cost.</p></div></section>
    <section className="article-section"><h2>Studying and keeping an upgrade</h2><div className="definition-grid"><div><h3>Choose one node</h3><p>Open its branch and exact detail. Every listed prerequisite must be complete first.</p></div><div><h3>Review the current cost</h3><p>The tables above show the published base cost; the live detail shows the exact current cost before Study.</p></div><div><h3>Confirm once</h3><p>A completed Study permanently keeps that upgrade. It is not a repeating purchase.</p></div><div><h3>If it cannot complete</h3><p>If readiness or cost has changed, no partial cost is taken and existing Research progress remains unchanged.</p></div></div></section>
    <RelatedGuides links={[{ label: 'Study research', href: '/actions/study-research' }, { label: 'Library', href: '/buildings/library' }, { label: 'Resources', href: '/resources' }, { label: 'Crafting', href: '/crafting' }, { label: 'World Writing', href: '/systems/world-writing' }]} />
  </SiteFrame>;
}
