import type { Metadata } from 'next';
import Link from 'next/link';
import { notFound } from 'next/navigation';
import { PageIntro } from '@/components/page-intro';
import { PixelImage } from '@/components/pixel-image';
import { GuideBreadcrumbs, RelatedGuides } from '@/components/guide-navigation';
import { SiteFrame } from '@/components/site-frame';
import { craftingSystems, definedButNotLiveForSystem, recipeReadiness, recipesFor, systemFor } from '@/lib/crafting';
import { content, humanize } from '@/lib/content';
import { serviceForStation } from '@/lib/services';

export function generateStaticParams() {
  return craftingSystems.map((system) => ({ slug: system.slug }));
}
export async function generateMetadata({
  params,
}: {
  params: Promise<{ slug: string }>;
}): Promise<Metadata> {
  const { slug } = await params;
  const system = systemFor(slug);
  return system ? { title: system.name, description: system.summary } : {};
}

function ingredientLabel(ingredient: {
  resourceID?: string;
  label: string;
  amount?: number;
  role?: string;
}) {
  const resource = ingredient.resourceID
    ? content.resources.find((entry) => entry.id === ingredient.resourceID)
    : null;
  const label = resource?.name ?? humanize(ingredient.label);
  const amount =
    ingredient.amount === undefined ? '' : `${ingredient.amount} × `;
  const body =
    ingredient.resourceID && resource ? (
      <Link href={`/resources/${resource.slug}`}>{label}</Link>
    ) : (
      label
    );
  return (
    <span className="recipe-ingredient">
      {resource?.assetURL && <PixelImage src={resource.assetURL} alt={`${resource.name} icon`} size={24} />}
      {amount}
      {body}
      {ingredient.role ? <small> — {ingredient.role}</small> : null}
    </span>
  );
}

function resultItem(recipe: ReturnType<typeof recipesFor>[number]) {
  return content.items.find((item) => item.name === recipe.result) ?? null;
}

function resultLink(item: NonNullable<ReturnType<typeof resultItem>>) {
  return item.gear ? `/equipment/${item.slug}` : `/items/${item.slug}`;
}

function constructionCost(station: (typeof content.stations)[number]) {
  if (station.unlockedAtStart) return 'Available at the start of a campaign.';
  if (!station.buildCost.length) return 'No current construction cost is published.';
  return <>{station.buildCost.map((cost, index) => {
    const id = cost.id ?? cost.resource ?? cost.resourceID;
    const resource = id ? content.resources.find((entry) => entry.id === id) : null;
    const quantity = cost.quantity ?? cost.amount ?? '?';
    const label = resource?.name ?? humanize(id);
    return <span key={`${station.id}-${id}-${index}`}>{index ? ', ' : ''}{quantity} {resource ? <Link href={`/resources/${resource.slug}`}>{label}</Link> : label}</span>;
  })}</>;
}

export default async function CraftingSystemDetail({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = await params;
  const system = systemFor(slug);
  if (!system) notFound();
  const recipes = recipesFor(slug);
  const station = content.stations.find((entry) => entry.id === system.stationID);
  const service = station ? serviceForStation(station.id) : null;
  const relatedResources = [...new Set(recipes.flatMap((recipe) => recipe.ingredients.map((ingredient) => ingredient.resourceID).filter(Boolean)))].map((id) => content.resources.find((resource) => resource.id === id)).filter(Boolean);
  const outputItems = [...new Map(recipes.map((recipe) => {
    const item = resultItem(recipe);
    return [item?.id ?? recipe.result, { recipe, item }];
  })).values()];
  const notLive = definedButNotLiveForSystem(system.slug);
  return (
    <SiteFrame sidebar>
      <GuideBreadcrumbs items={[{ label: 'Systems', href: '/systems' }, { label: 'Crafting systems', href: '/crafting' }, { label: system.name }]} />
      <PageIntro
        eyebrow={system.station}
        title={system.name}
        summary={system.summary}
      />
      <section className="article-section">
        {station?.assetURL && <div className="crafting-station"><PixelImage src={station.assetURL} alt={`${station.name} building visual`} size={72} /><p><strong>{station.name}</strong> is the current station visual for this system.</p></div>}
        <h2>Access and readiness</h2>
        <dl className="fact-grid">
          <div><dt>Current state</dt><dd>Current player station process</dd></div>
          <div><dt>Station access</dt><dd>{station ? <><Link href={`/buildings/${station.slug}`}>{station.name}</Link> · {constructionCost(station)}</> : 'Open the station named above.'}</dd></div>
          <div><dt>Current route</dt><dd><ul className="compact-list">{system.access.map((fact) => <li key={fact}>{fact}</li>)}</ul></dd></div>
        </dl>
      </section>
      <section className="article-section">
        <h2>Current workflow</h2>
        <ol className="numbered-guide">
          {system.howItWorks.map((step) => (
            <li key={step}>{step}</li>
          ))}
        </ol>
      </section>
      <section className="article-section">
        <h2>Material choices</h2>
        <p>{system.materialChoice}</p>
      </section>
      <section className="article-section">
        <h2>Current recipes and requirements</h2>
        <p>Each row below is currently available only when its listed readiness, exact inputs, and the station’s final preview all agree. Material alternatives appear only where the current recipe exposes that socket.</p>
        <div className="table-wrap">
          <table>
            <thead>
              <tr>
                <th>Recipe</th>
                <th aria-label="Result image" />
                <th>Output</th>
                <th>Exact inputs</th>
                <th>Ready when</th>
                <th>Recipe-specific effect</th>
              </tr>
            </thead>
            <tbody>
              {recipes.map((recipe) => (
                <tr key={recipe.id}>{(() => { const item = resultItem(recipe); return <>
                  <td><strong>{recipe.name}</strong></td>
                  <td>{item?.assetURL && <PixelImage src={item.assetURL} alt={`${item.name} icon`} size={32} />}</td>
                  <td>{item ? <Link href={resultLink(item)}>{recipe.result}</Link> : recipe.result}</td>
                  <td>
                    <ul className="compact-list">
                      {recipe.ingredients.map((ingredient, index) => (
                        <li key={`${recipe.id}-${index}`}>
                          {ingredientLabel(ingredient)}
                        </li>
                      ))}
                    </ul>
                  </td>
                  <td>{recipeReadiness(recipe)}</td>
                  <td>
                    {recipe.notes ?? 'The station-wide material and result rule above applies to this recipe.'}
                  </td>
                </>; })()}</tr>
              ))}
            </tbody>
          </table>
        </div>
      </section>
      <section className="article-section two-column crafting-output-guide">
        <div>
          <h2>Results and their use</h2>
          {outputItems.length ? <ul className="compact-list">{outputItems.map(({ recipe, item }) => <li key={recipe.id}>{item ? <><Link href={resultLink(item)}>{recipe.result}</Link> — {item.summary}</> : <><strong>{recipe.result}</strong> — use the station’s quoted destination and result description.</>}</li>)}</ul> : <p>No separately published result entry is available for this current station process.</p>}
        </div>
        <div>
          <h2>Related routes</h2>
          <p>{station ? <><Link href={`/buildings/${station.slug}`}>{station.name}</Link> holds this station. </> : null}Open each linked resource for its current acquisition and other published consumers; the item or equipment guide retains the result’s player-facing facts.</p>
        </div>
      </section>
      {notLive.length ? <section className="article-section note-card crafting-boundary"><h2>Defined, but not a current recipe</h2><ul className="compact-list">{notLive.map((entry) => <li key={entry.name}><strong>{entry.name}:</strong> {entry.detail}</li>)}</ul></section> : null}
      <section className="article-section note-card">
        <h2>Commit and result</h2>
        <p>{system.commitResult}</p>
      </section>
      <RelatedGuides links={[{ label: 'All crafting systems', href: '/crafting' }, ...(station ? [{ label: station.name, href: `/buildings/${station.slug}` }] : []), { label: 'Village buildings', href: '/village' }, { label: 'Crafting basics', href: '/systems/crafting' }, ...(service ? [{ label: `Use ${service.name}`, href: `/services/${service.slug}` }] : []), ...relatedResources.slice(0, 3).flatMap((resource) => resource ? [{ label: resource.name, href: `/resources/${resource.slug}` }] : []), { label: 'All resources', href: '/resources' }]} />
    </SiteFrame>
  );
}
