import type { Metadata } from 'next';
import Link from 'next/link';
import { notFound } from 'next/navigation';
import { PageIntro } from '@/components/page-intro';
import { GuideBreadcrumbs, RelatedGuides } from '@/components/guide-navigation';
import { SiteFrame } from '@/components/site-frame';
import { content, humanize } from '@/lib/content';
import { craftingSystems, recipeReadiness, recipesFor } from '@/lib/crafting';
import { serviceForStation } from '@/lib/services';
import { actionForSlug, actionsForStation } from '@/lib/action-reference';
import { apothecaryFirstUse } from '@/lib/apothecary-first-use';
import { blacksmithFirstUse } from '@/lib/blacksmith-first-use';

function constructionRequirements(place: (typeof content.stations)[number]) {
  if (place.unlockedAtStart) return 'Available at the start of a campaign.';
  if (!place.buildCost.length) return 'No current construction cost is published.';
  return <>{place.buildCost.map((cost, index) => {
    const id = cost.id ?? cost.resource ?? cost.resourceID;
    const resource = id ? content.resources.find((entry) => entry.id === id) : null;
    const quantity = cost.quantity ?? cost.amount ?? '?';
    return <span key={`${place.id}-${id}-${index}`}>{index ? ', ' : ''}{quantity} {resource ? <Link href={`/resources/${resource.slug}`}>{resource.name}</Link> : humanize(id)}</span>;
  })}</>;
}

function recipeRequirements(recipe: ReturnType<typeof recipesFor>[number]) {
  return <ul className="compact-list">{recipe.ingredients.map((ingredient, index) => {
    const resource = ingredient.resourceID ? content.resources.find((entry) => entry.id === ingredient.resourceID) : null;
    const amount = ingredient.amount === undefined ? '' : `${ingredient.amount} × `;
    const label = resource?.name ?? humanize(ingredient.label);
    return <li key={`${recipe.id}-${index}`}>{amount}{resource ? <Link href={`/resources/${resource.slug}`}>{label}</Link> : label}{ingredient.role ? ` — ${ingredient.role}` : ''}</li>;
  })}</ul>;
}

export function generateStaticParams() {
  return content.stations.map((place) => ({ slug: place.slug }));
}
export async function generateMetadata({
  params,
}: {
  params: Promise<{ slug: string }>;
}): Promise<Metadata> {
  const { slug } = await params;
  const place = content.stations.find((entry) => entry.slug === slug);
  return place ? { title: place.name, description: place.blurb } : {};
}

export default async function PlaceDetail({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = await params;
  const place = content.stations.find((entry) => entry.slug === slug);
  if (!place) notFound();
  const service = serviceForStation(place.id);
  const systems = craftingSystems.filter((system) => system.stationID === place.id);
  const recipes = systems.flatMap((system) => recipesFor(system.slug));
  const actions = [
    ...(!place.unlockedAtStart ? [actionForSlug('build-foundation')] : []),
    ...actionsForStation(place.id),
  ].filter((action): action is NonNullable<typeof action> => Boolean(action));
  return (
    <SiteFrame sidebar>
      <GuideBreadcrumbs items={[{ label: 'Village services', href: '/services' }, { label: 'Places and stations', href: '/places' }, { label: place.name }]} />
      <PageIntro
        eyebrow={place.zone}
        title={place.name}
        summary={place.blurb}
      />
      <section
        className="article-section place-visuals"
        aria-label={`${place.name} town visual`}
      >
        {place.assetURL && (
          <figure className="place-visual place-building">
            <img src={place.assetURL} alt={`${place.name} building visual`} />
            <figcaption>
              The current town building visual for {place.name}.
            </figcaption>
          </figure>
        )}
        <figure className="place-visual place-context">
          <img src={place.contextAssetURL} alt={`${place.zone} town context`} />
          <figcaption>
            {place.assetURL
              ? `The current ${place.zone} context around this service.`
              : `The current retained town context for ${place.name}.`}
          </figcaption>
        </figure>
      </section>
      <section className="article-section">
        <h2>Using this place</h2>
        <dl className="fact-grid">
          <div>
            <dt>Location</dt>
            <dd>{place.zone}</dd>
          </div>
          <div>
            <dt>When usable</dt>
            <dd>{place.unlockedAtStart ? 'From the beginning' : 'After its construction is complete'}</dd>
          </div>
          <div>
            <dt>Exact construction</dt>
            <dd>{constructionRequirements(place)}</dd>
          </div>
          <div>
            <dt>Keeper</dt>
            <dd>
              {place.keeper ? (
                <Link href={`/people/${place.keeperID?.replaceAll('_', '-')}`}>
                  {place.keeper}
                </Link>
              ) : (
                'No resident keeper'
              )}
            </dd>
          </div>
        </dl>
        {place.id === 'blacksmith' ? <p>Halloway will raise a forge here when you bring iron and fibre for the work.</p> : place.buildBlurb && <p>{place.buildBlurb}</p>}
      </section>
      <section className="article-section">
        <h2>What this place currently offers</h2>
        {service ? <div className="definition-grid">{service.useFor.map((action) => <div key={action}>{action}</div>)}</div> : <p>No separate service action list is currently published for this place.</p>}
      </section>
      {place.id === 'apothecary' && <section className="article-section"><h2>Build it with Nessa</h2><p>Recruiting <Link href="/people/nessa">Nessa</Link> reveals this foundation in Home → Make. Its complete current requirement is <strong>{apothecaryFirstUse.construction}</strong>.</p><div className="definition-grid"><div><h3>Completion teaches, not grants</h3><p>The first committed construction teaches Lesser Salve. It does not create an item or prepay its Resin and selected material.</p></div><div><h3>Review again after a refusal</h3><p>A shortfall, changed requirements, unavailable builder, or failed save does not spend stock or teach the recipe. Review the displayed foundation again before trying.</p></div></div><p><Link href="/services/apothecary">Follow the first-use journey</Link> · <Link href="/crafting/apothecary">Open Apothecary preparations</Link></p></section>}
      {place.id === 'blacksmith' && <section className="article-section"><h2>Build it with Halloway</h2><p>Recruiting <Link href="/people/halloway">Halloway</Link> reveals this foundation in Home → Make. Its complete current requirement is <strong>{blacksmithFirstUse.construction}</strong>.</p><div className="definition-grid"><div><h3>Completion teaches, not grants</h3><p>The first durable construction teaches Pointed Blade only. It does not create gear, grant material stock, infer salvage, or complete a Reforge.</p></div><div><h3>Review again after a refusal</h3><p>A shortfall, changed requirements, unavailable Halloway, or failed save does not spend stock or teach the Schematic. Review the displayed foundation again before trying.</p></div></div><p><Link href="/services/blacksmith">Follow the first-use journey</Link> · <Link href="/crafting/blacksmith">Open Pointed Blade construction</Link></p></section>}
      {place.id === 'library' && <section className="article-section note-card"><h2>People and complete records</h2><p>Use the Library’s collections for recovered records, then open a person’s Player Wiki page to read their complete current authored book pages. Location-hint stages stay clearly marked as spoilers.</p><p><Link href="/people">Browse complete people records</Link></p></section>}
      {actions.length > 0 && <section className="article-section">
        <h2>Current actions here</h2>
        <div className="definition-grid">{actions.map((action) => <div key={action.id}><h3><Link href={`/actions/${action.slug}`}>{action.name}</Link></h3><p>{action.availability}</p><small>{action.unavailable}</small></div>)}</div>
      </section>}
      <section className="article-section">
        <h2>Current crafting at this place</h2>
        {recipes.length ? <div className="table-wrap"><table><thead><tr><th>Recipe</th><th>Output</th><th>Exact inputs</th><th>Ready when</th></tr></thead><tbody>{recipes.map((recipe) => { const item = content.items.find((entry) => entry.name === recipe.result); const outputHref = item ? (item.gear ? `/equipment/${item.slug}` : `/items/${item.slug}`) : null; return <tr key={recipe.id}><td><Link href={`/crafting/${recipe.system}`}>{recipe.name}</Link></td><td>{outputHref ? <Link href={outputHref}>{recipe.result}</Link> : recipe.result}</td><td>{recipeRequirements(recipe)}</td><td>{recipeReadiness(recipe)}</td></tr>; })}</tbody></table></div> : <p>No current crafting recipe is published for this place.</p>}
      </section>
      {systems.length > 0 && <section className="article-section two-column"><div><h2>Material choices</h2>{systems.map((system) => <p key={system.slug}><strong><Link href={`/crafting/${system.slug}`}>{system.name}:</Link></strong> {system.materialChoice}</p>)}</div><div><h2>Result and custody</h2>{systems.map((system) => <p key={system.slug}>{system.commitResult}</p>)}</div></section>}
      <RelatedGuides links={[{ label: 'All places', href: '/places' }, ...(actions.length ? [{ label: 'Action reference', href: '/actions' }] : []), ...(service ? [{ label: `How to use ${service.name}`, href: `/services/${service.slug}` }] : []), ...(place.id === 'library' ? [{ label: 'People and complete records', href: '/people' }] : []), ...systems.map((system) => ({ label: system.name, href: `/crafting/${system.slug}` })), { label: 'All village services', href: '/services' }, { label: 'All resources', href: '/resources' }]} />
    </SiteFrame>
  );
}
