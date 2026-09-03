import type { Metadata } from 'next';
import Link from '@/components/wiki-link';
import { notFound } from 'next/navigation';
import { GuideBreadcrumbs, RelatedGuides } from '@/components/guide-navigation';
import { PageIntro } from '@/components/page-intro';
import { PixelImage } from '@/components/pixel-image';
import { SiteFrame } from '@/components/site-frame';
import { buildCost, content, humanize } from '@/lib/content';
import { recyclerFirstUse } from '@/lib/recycler-first-use';
import { anchorageFirstAnchor } from '@/lib/anchorage-first-anchor';
import { blacksmithFirstUse } from '@/lib/blacksmith-first-use';
import { surveyPostFirstUse } from '@/lib/survey-post-first-use';
import { buildingActions, buildingForSlug, buildingStatus, villageBuildings } from '@/lib/village';
import { researchNodeSlug } from '@/lib/research';
import { FacilityDetail } from '@/components/facility-detail';

export function generateStaticParams() { return villageBuildings.map((building) => ({ slug: building.slug })); }
export async function generateMetadata({ params }: { params: Promise<{ slug: string }> }): Promise<Metadata> {
  const { slug } = await params; const building = buildingForSlug(slug);
  return building ? { title: building.name, description: building.blurb } : {};
}

export default async function BuildingDetail({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;
  if (!buildingForSlug(slug)) notFound();
  return <FacilityDetail slug={slug} />;
}

async function PreservedFormerBuildingDetail({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params; const building = buildingForSlug(slug); if (!building) notFound();
  const { service, systems, recipes } = buildingActions(building);
  const publishedRecipes = building.id === 'survey_post' ? [] : recipes;
  const bundledResearch = content.researchNodes.filter((node) => node.constructionBundledWith === building.id);
  const resourceIDs = [...new Set([
    ...building.buildCost.map((cost) => cost.id ?? cost.resource ?? cost.resourceID),
    ...publishedRecipes.flatMap((recipe) => recipe.ingredients.map((ingredient) => ingredient.resourceID)),
  ].filter((id): id is string => Boolean(id)))];
  const resourceLinks = resourceIDs
    .map((id) => content.resources.find((resource) => resource.id === id))
    .filter((resource): resource is (typeof content.resources)[number] => Boolean(resource));
  return <SiteFrame sidebar>
    <GuideBreadcrumbs items={[{ label: 'Village', href: '/village' }, { label: building.name }]} />
    <div className="entity-heading">{building.assetURL ? <PixelImage src={building.assetURL} alt={`${building.name} building visual`} size={96} /> : null}<PageIntro eyebrow={buildingStatus(building)} title={building.name} summary={building.blurb} /></div>
    {building.status === 'scheduled' ? <section className="article-section note-card"><h2>Scheduled, not implemented</h2><p>This entry is not a live player route. Current sources publish its identity and placement only; no active actions, costs, recipes, or rewards are presented here.</p></section> : <><section className="article-section"><h2>Access and foundation</h2><dl className="fact-grid"><div><dt>Village area</dt><dd>{building.zone}</dd></div><div><dt>Current route</dt><dd>{humanize(building.route)}</dd></div><div><dt>When usable</dt><dd>{building.unlockedAtStart ? 'Available at the start of a campaign' : building.keeper ? <>Meet <Link href={`/people/${building.keeperID?.replaceAll('_', '-')}`}>{building.keeper}</Link>, then complete the foundation</> : 'Use the current Village route'}</dd></div><div><dt>Exact construction</dt><dd>{buildCost(building)}</dd></div></dl>{building.id === 'blacksmith' ? <p>Halloway will raise a forge here when you bring iron and fibre for the work.</p> : building.buildBlurb && <p>{building.buildBlurb}</p>}</section>{building.id === 'recycler' && <section className="article-section note-card"><h2>Build the Recycler with Noll</h2><p>After <Link href="/people/noll">Noll</Link> joins the Village, this foundation costs exactly <strong>{recyclerFirstUse.buildCost}</strong>. Completion gives the tier-0 recovery preview only: no gear, resources, recipe, Field Separation Kit, or free dismantling result.</p><p>A shortfall, changed foundation, unavailable builder, or failed save leaves the current wallet and gear unchanged. <Link href="/services/recycler">Open the Recycler service</Link> when the foundation is complete.</p></section>}{building.id === 'blacksmith' && <section className="article-section note-card"><h2>Build the Blacksmith with Halloway</h2><p>After <Link href="/people/halloway">Halloway</Link> joins the Village, this foundation costs exactly <strong>{blacksmithFirstUse.construction}</strong>. Completion teaches Pointed Blade only: no blade, stock, salvage, Reforge, or equipment change is granted.</p><p>Cancel, a shortfall, a stale requirement, unavailable Halloway, or a failed save leaves the shown foundation and current resources unchanged. <Link href="/services/blacksmith">Open Halloway’s first-use journey</Link> after the foundation is complete.</p></section>}{building.id === 'anchorage' && <section className="article-section note-card"><h2>Build the Anchorage with Tovin</h2><p>After <Link href="/people/tovin">Tovin</Link> joins the Village, this foundation costs exactly <strong>{anchorageFirstAnchor.construction}</strong>. Completion opens an empty portfolio and Anchor Frame construction; it does not anchor a realm, grant a Frame, or start production.</p><p>Cancel, a shortfall, a stale requirement, or a failed save leaves the shown foundation and current resources unchanged. <Link href="/services/anchorage">Open the Anchorage journey</Link> only after the foundation is complete.</p></section>}{building.id === 'survey_post' && <section className="article-section note-card"><h2>Build the Survey Post with Mara</h2><p>After <Link href="/people/mara">Mara</Link> joins the Village, this foundation costs exactly <strong>{surveyPostFirstUse.construction}</strong>. Completion opens Field Instruments research but gives no instrument, material, observation, map disclosure, or field action.</p><p>Cancel, a shortfall, a stale requirement, unavailable Mara, or a failed save leaves the shown foundation and current resources unchanged. <Link href="/services/survey-post">Open Mara’s first-reading journey</Link> after the foundation is complete.</p></section>}<section className="article-section two-column"><div><h2>Actions and services</h2>{service ? <><p><Link href={`/services/${service.slug}`}>{service.name}</Link></p><ul className="compact-list">{service.useFor.map((action) => <li key={action}>{action}</li>)}</ul></> : systems.length ? <ul className="compact-list">{systems.map((system) => <li key={system.slug}><Link href={`/crafting/${system.slug}`}>{system.name}</Link> — {system.summary}</li>)}</ul> : <p>No separate current service or crafting action is published.</p>}</div><div><h2>Results and research</h2>{publishedRecipes.length ? <ul className="compact-list">{publishedRecipes.map((recipe) => <li key={recipe.id}><Link href={`/crafting/${recipe.system}`}>{recipe.name}</Link> → {recipe.result}</li>)}</ul> : building.id === 'survey_post' ? <p>Field Instruments Research grants permanent capabilities. Paid precision improvement remains unpublished until an exact typed receipt exists.</p> : <p>No separate current recipe output is published.</p>}{bundledResearch.length ? <p>{bundledResearch.map((node) => <span key={node.id}><Link href={`/research/${researchNodeSlug(node)}`}>{node.name}</Link> {node.blurb}</span>)}</p> : null}</div></section></>}
    <section className="article-section"><h2>Related materials and next steps</h2>{resourceLinks.length ? <p>{resourceLinks.map((resource, index) => <span key={resource.id}>{index ? ' · ' : ''}<Link href={`/resources/${resource.slug}`}>{resource.name}</Link></span>)}</p> : <p>No live material route is published for this entry.</p>}<p><Link href="/resources/progression">Open the current progression checklist</Link></p></section>
    <RelatedGuides links={[{ label: 'Village directory', href: '/village' }, { label: 'Village services', href: '/services' }, ...(building.id === 'trading_post' ? [{ label: 'Trading offer and sale terms', href: '/trading' }] : []), ...(building.id === 'recycler' ? [{ label: 'Recycler return reference', href: '/recycling' }] : []), ...(building.id === 'blacksmith' ? [{ label: 'Halloway', href: '/people/halloway' }, { label: 'Blacksmith journey', href: '/services/blacksmith' }, { label: 'Pointed Blade construction', href: '/crafting/blacksmith' }, { label: 'Equipment and material effects', href: '/systems/equipment-materials' }] : []), ...(building.id === 'anchorage' ? [{ label: 'Tovin', href: '/people/tovin' }, { label: 'Anchorage journey', href: '/services/anchorage' }, { label: 'Anchor Frame', href: '/crafting/anchorage' }, { label: 'Atlas Seam', href: '/sites/atlas-seam' }] : []), ...(building.id === 'survey_post' ? [{ label: 'Mara', href: '/people/mara' }, { label: 'Survey Post journey', href: '/services/survey-post' }, { label: 'Field Instruments', href: '/crafting/instruments' }, { label: 'Field supplies and Field Kit', href: '/systems/field-supplies' }, { label: 'World conditions', href: '/world' }] : []), { label: 'Crafting', href: '/crafting' }, { label: 'Resources', href: '/resources' }, { label: 'Village construction', href: '/systems/village-construction' }]} />
  </SiteFrame>;
}
