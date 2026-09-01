import type { Metadata } from 'next';
import Link from 'next/link';
import { notFound } from 'next/navigation';
import { GuideBreadcrumbs, RelatedGuides } from '@/components/guide-navigation';
import { PageIntro } from '@/components/page-intro';
import { PixelImage } from '@/components/pixel-image';
import { SiteFrame } from '@/components/site-frame';
import { buildCost, content, humanize } from '@/lib/content';
import { buildingActions, buildingForSlug, buildingStatus, villageBuildings } from '@/lib/village';

export function generateStaticParams() { return villageBuildings.map((building) => ({ slug: building.slug })); }
export async function generateMetadata({ params }: { params: Promise<{ slug: string }> }): Promise<Metadata> {
  const { slug } = await params; const building = buildingForSlug(slug);
  return building ? { title: building.name, description: building.blurb } : {};
}

export default async function BuildingDetail({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params; const building = buildingForSlug(slug); if (!building) notFound();
  const { service, systems, recipes } = buildingActions(building);
  const bundledResearch = content.researchNodes.filter((node) => node.constructionBundledWith === building.id);
  const resourceIDs = [...new Set([
    ...building.buildCost.map((cost) => cost.id ?? cost.resource ?? cost.resourceID),
    ...recipes.flatMap((recipe) => recipe.ingredients.map((ingredient) => ingredient.resourceID)),
  ].filter((id): id is string => Boolean(id)))];
  const resourceLinks = resourceIDs
    .map((id) => content.resources.find((resource) => resource.id === id))
    .filter((resource): resource is (typeof content.resources)[number] => Boolean(resource));
  return <SiteFrame sidebar>
    <GuideBreadcrumbs items={[{ label: 'Village', href: '/village' }, { label: building.name }]} />
    <div className="entity-heading">{building.assetURL ? <PixelImage src={building.assetURL} alt={`${building.name} building visual`} size={96} /> : null}<PageIntro eyebrow={buildingStatus(building)} title={building.name} summary={building.blurb} /></div>
    {building.status === 'scheduled' ? <section className="article-section note-card"><h2>Scheduled, not implemented</h2><p>This entry is not a live player route. Current sources publish its identity and placement only; no active actions, costs, recipes, or rewards are presented here.</p></section> : <><section className="article-section"><h2>Access and foundation</h2><dl className="fact-grid"><div><dt>Village area</dt><dd>{building.zone}</dd></div><div><dt>Current route</dt><dd>{humanize(building.route)}</dd></div><div><dt>When usable</dt><dd>{building.unlockedAtStart ? 'Available at the start of a campaign' : building.keeper ? <>Meet <Link href={`/people/${building.keeperID?.replaceAll('_', '-')}`}>{building.keeper}</Link>, then complete the foundation</> : 'Use the current Village route'}</dd></div><div><dt>Exact construction</dt><dd>{buildCost(building)}</dd></div></dl>{building.buildBlurb && <p>{building.buildBlurb}</p>}</section><section className="article-section two-column"><div><h2>Actions and services</h2>{service ? <><p><Link href={`/services/${service.slug}`}>{service.name}</Link></p><ul className="compact-list">{service.useFor.map((action) => <li key={action}>{action}</li>)}</ul></> : systems.length ? <ul className="compact-list">{systems.map((system) => <li key={system.slug}><Link href={`/crafting/${system.slug}`}>{system.name}</Link> — {system.summary}</li>)}</ul> : <p>No separate current service or crafting action is published.</p>}</div><div><h2>Results and research</h2>{recipes.length ? <ul className="compact-list">{recipes.map((recipe) => <li key={recipe.id}><Link href={`/crafting/${recipe.system}`}>{recipe.name}</Link> → {recipe.result}</li>)}</ul> : <p>No separate current recipe output is published.</p>}{bundledResearch.length ? <p>{bundledResearch.map((node) => <span key={node.id}><Link href={`/research/${node.name.toLowerCase().replaceAll(/[^a-z0-9]+/g, '-').replaceAll(/(^-|-$)/g, '')}`}>{node.name}</Link> {node.blurb}</span>)}</p> : null}</div></section></>}
    <section className="article-section"><h2>Related materials and next steps</h2>{resourceLinks.length ? <p>{resourceLinks.map((resource, index) => <span key={resource.id}>{index ? ' · ' : ''}<Link href={`/resources/${resource.slug}`}>{resource.name}</Link></span>)}</p> : <p>No live material route is published for this entry.</p>}<p><Link href="/resources/progression">Open the current progression checklist</Link></p></section>
    <RelatedGuides links={[{ label: 'Village directory', href: '/village' }, { label: 'Village services', href: '/services' }, { label: 'Crafting', href: '/crafting' }, { label: 'Resources', href: '/resources' }, { label: 'Village construction', href: '/systems/village-construction' }]} />
  </SiteFrame>;
}
