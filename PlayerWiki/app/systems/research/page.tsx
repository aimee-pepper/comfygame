import Link from 'next/link';
import type { ReactNode } from 'react';
import { GuideBreadcrumbs, RelatedGuides } from '@/components/guide-navigation';
import { PageIntro } from '@/components/page-intro';
import { SiteFrame } from '@/components/site-frame';
import { content, humanize } from '@/lib/content';
import { researchNodeSlug } from '@/lib/research';

const systemGuideForBranch: Record<string, { label: string; href: string }> = {
  instruction: { label: 'Party, Gear and Gambits', href: '/services/party-and-gear' },
  hand: { label: 'World Writing', href: '/systems/world-writing' },
  hold: { label: 'Storehouse and inventory', href: '/services/storehouse' },
  spring: { label: 'Essence Spring', href: '/services/essence-spring' },
  lexicon: { label: 'World Writing', href: '/systems/world-writing' },
  bargain: { label: 'Trading Post', href: '/services/trading-post' },
  penmanship: { label: 'World Writing', href: '/systems/world-writing' },
  instruments: { label: 'Exploration', href: '/systems/exploration' },
  lens: { label: 'World Writing', href: '/systems/world-writing' },
  tannery_wear: { label: 'Crafting systems', href: '/crafting' },
  tannery_carry: { label: 'Crafting systems', href: '/crafting' },
  tannery_keep: { label: 'Storehouse and inventory', href: '/services/storehouse' },
  bowyer_craft: { label: 'Crafting systems', href: '/crafting' },
  armoury_craft: { label: 'Crafting systems', href: '/crafting' },
  weaponsmith_craft: { label: 'Crafting systems', href: '/crafting' },
};

function publishedCost(node: (typeof content.researchNodes)[number]) {
  const parts: ReactNode[] = [];
  if (node.cost.essence > 0) parts.push(`${node.cost.essence} Essence`);
  for (const [id, amount] of Object.entries(node.cost.resources).sort(([left], [right]) => left.localeCompare(right))) {
    const resource = content.resources.find((entry) => entry.id === id);
    parts.push(<span key={id}>{amount} {resource ? <Link href={`/resources/${resource.slug}`}>{resource.name}</Link> : humanize(id)}</span>);
  }
  return parts.length ? parts.flatMap((part, index) => index ? [' · ', part] : [part]) : 'Free';
}

function requirements(node: (typeof content.researchNodes)[number], names: Map<string, string>) {
  const parts: ReactNode[] = [];
  if (node.requires.length) parts.push(<>Earlier upgrades: {node.requires.map((id) => names.get(id) ?? humanize(id)).join(', ')}</>);
  if (node.needsStationTier > 0) parts.push(`Station tier ${node.needsStationTier}`);
  if (node.needsInstruments > 0) parts.push(`${node.needsInstruments} field readings`);
  if (node.needsLifetimeRawRefined > 0) parts.push(`${node.needsLifetimeRawRefined} Raw Essence refined`);
  if (node.constructionBundledWith) {
    const station = content.stations.find((entry) => entry.id === node.constructionBundledWith);
    parts.push(station ? <>Included when <Link href={`/places/${station.slug}`}>{station.name}</Link> is built</> : 'Included with current construction');
  }
  return parts.length ? parts.flatMap((part, index) => index ? [' · ', part] : [part]) : 'No earlier upgrade is listed.';
}

export default function ResearchGuide() {
  const names = new Map(content.researchNodes.map((node) => [node.id, node.name]));
  const nodesFor = (branchID: string) => content.researchNodes.filter((node) => node.branch === branchID);
  return <SiteFrame sidebar>
    <GuideBreadcrumbs items={[{ label: 'Systems', href: '/systems' }, { label: 'Research' }]} />
    <PageIntro eyebrow="Current system guide" title="Research" summary="Research is a set of visible branches, not a flat shop. Open the branch that matches the system you want to develop, meet every listed requirement, then Study the exact node and cost currently shown." />
    <section className="article-section two-column"><div><h2>How to access it</h2><p>Open the current Research screen from the Village. Branches taught at a specific building require that building when the screen says so; other current branches remain on the Research screen without a separate Player Wiki place page.</p></div><div className="note-card"><h3>Use the current detail</h3><p>Every node remains visible so you can see its earlier upgrades and published cost. The Research detail shows whether it is ready, missing stock, supplied by its keeper, or still locked.</p></div></section>
    <section className="article-section"><h2>Studying and keeping an upgrade</h2><div className="definition-grid"><div><h3>Choose one node</h3><p>Open the branch and then the exact visible node. Every listed earlier upgrade must be complete before a node can be studied.</p></div><div><h3>Review the current cost</h3><p>The table shows the published base cost. The in-game detail shows the current cost and any missing stock before you Study.</p></div><div><h3>Confirm once</h3><p>A completed Study keeps its upgrade and applies the node’s documented result. It is not a repeating purchase.</p></div><div><h3>If it cannot complete</h3><p>If a requirement or the displayed cost has changed, no partial cost is taken and the current Research progress remains unchanged.</p></div></div></section>
    <section className="article-section"><h2>Current branches and nodes</h2>{content.researchBranches.map((branch) => {
      const nodes = nodesFor(branch.id);
      const station = branch.stationID ? content.stations.find((entry) => entry.id === branch.stationID) : null;
      const guide = systemGuideForBranch[branch.id];
      return <article className="article-section" key={branch.id}><h3>{branch.name}</h3><p>{branch.blurb}</p><p>{station ? <>Taught at <Link href={`/places/${station.slug}`}>{station.name}</Link>.</> : 'Available through the current Research screen.'} {guide && <><Link href={guide.href}>See {guide.label}</Link>.</>}</p><div className="table-wrap data-table"><table><thead><tr><th>Node</th><th>Earlier upgrades and other requirements</th><th>Published base cost</th><th>Current result</th></tr></thead><tbody>{nodes.map((node) => <tr key={node.id}><td><Link href={`/research/${researchNodeSlug(node)}`}>{node.name}</Link></td><td>{requirements(node, names)}</td><td>{publishedCost(node)}</td><td>{node.blurb}</td></tr>)}</tbody></table></div></article>;
    })}</section>
    <section className="article-section note-card"><h2>Need one node’s full reference?</h2><p><Link href="/research">Open the Research directory</Link> for linked node pages with exact prerequisites, costs, result and bundled-construction facts.</p></section>
    <RelatedGuides links={[{ label: 'Study research', href: '/actions/study-research' }, { label: 'Research directory', href: '/research' }, { label: 'Library collections', href: '/services/library' }, { label: 'Resources', href: '/resources' }, { label: 'Crafting systems', href: '/crafting' }, { label: 'World Writing', href: '/systems/world-writing' }, { label: 'All systems', href: '/systems' }]} />
  </SiteFrame>;
}
