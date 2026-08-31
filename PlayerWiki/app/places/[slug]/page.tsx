import type { Metadata } from 'next';
import Link from 'next/link';
import { notFound } from 'next/navigation';
import { PageIntro } from '@/components/page-intro';
import { GuideBreadcrumbs, RelatedGuides } from '@/components/guide-navigation';
import { SiteFrame } from '@/components/site-frame';
import { content, humanize } from '@/lib/content';
import { craftingSystems, recipesFor } from '@/lib/crafting';
import { serviceForStation } from '@/lib/services';

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
  const systems = craftingSystems.filter((system) =>
    system.station.includes(place.name),
  );
  const recipes = systems.flatMap((system) => recipesFor(system.slug));
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
        {place.buildBlurb && <p>{place.buildBlurb}</p>}
      </section>
      <section className="article-section">
        <h2>What this place currently offers</h2>
        {service ? <div className="definition-grid">{service.useFor.map((action) => <div key={action}>{action}</div>)}</div> : <p>No separate service action list is currently published for this place.</p>}
      </section>
      <section className="article-section">
        <h2>Current crafting at this place</h2>
        {recipes.length ? <div className="table-wrap"><table><thead><tr><th>Recipe</th><th>Output</th><th>Crafting system</th></tr></thead><tbody>{recipes.map((recipe) => { const system = systems.find((entry) => entry.slug === recipe.system); const item = content.items.find((entry) => entry.name === recipe.result); const outputHref = item ? (item.gear ? `/equipment/${item.slug}` : `/items/${item.slug}`) : null; return <tr key={recipe.id}><td><Link href={`/crafting/${recipe.system}`}>{recipe.name}</Link></td><td>{outputHref ? <Link href={outputHref}>{recipe.result}</Link> : recipe.result}</td><td>{system?.name ?? humanize(recipe.system)}</td></tr>; })}</tbody></table></div> : <p>No current crafting recipe is published for this place.</p>}
      </section>
      <RelatedGuides links={[{ label: 'All places', href: '/places' }, ...(service ? [{ label: `How to use ${service.name}`, href: `/services/${service.slug}` }] : []), ...systems.map((system) => ({ label: system.name, href: `/crafting/${system.slug}` })), { label: 'All village services', href: '/services' }, { label: 'All resources', href: '/resources' }]} />
    </SiteFrame>
  );
}
