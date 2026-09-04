import type { Metadata } from 'next';
import Link from '@/components/wiki-link';
import { notFound } from 'next/navigation';
import { PageIntro } from '@/components/page-intro';
import { PixelImage } from '@/components/pixel-image';
import { GuideBreadcrumbs, RelatedGuides } from '@/components/guide-navigation';
import { SiteFrame } from '@/components/site-frame';
import { TruthPair } from '@/components/truth-pair';
import { craftingSystems, definedButNotLiveForSystem, recipeReadiness, recipesFor, systemFor } from '@/lib/crafting';
import { craftingStatusFor } from '@/lib/player-guide-status';
import { content, humanize } from '@/lib/content';
import { serviceForStation } from '@/lib/services';
import { apothecaryFirstUse } from '@/lib/apothecary-first-use';
import { anchorageFirstAnchor } from '@/lib/anchorage-first-anchor';
import { blacksmithFirstUse } from '@/lib/blacksmith-first-use';
import { surveyPostFirstUse } from '@/lib/survey-post-first-use';

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
  if (!station.buildCost.length) return 'A construction cost is not available yet.';
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
  const publishedRecipes = recipes;
  const station = content.stations.find((entry) => entry.id === system.stationID);
  const service = station ? serviceForStation(station.id) : null;
  const relatedResources = [...new Set(recipes.flatMap((recipe) => recipe.ingredients.map((ingredient) => ingredient.resourceID).filter(Boolean)))].map((id) => content.resources.find((resource) => resource.id === id)).filter(Boolean);
  const outputItems = [...new Map(publishedRecipes.map((recipe) => {
    const item = resultItem(recipe);
    return [item?.id ?? recipe.result, { recipe, item }];
  })).values()];
  const notLive = definedButNotLiveForSystem(system.slug);
  const guideStatus = craftingStatusFor(system.slug);
  return (
    <SiteFrame sidebar>
      <GuideBreadcrumbs items={[{ label: 'Systems', href: '/systems' }, { label: 'Crafting systems', href: '/crafting' }, { label: system.name }]} />
      <PageIntro
        eyebrow={system.station}
        title={system.name}
        summary={system.summary}
      />
      {guideStatus && <section className="article-section">
        <p className="status-pill">{guideStatus.status}</p>
        <h2>How it works now and how it will change</h2>
        <TruthPair current={guideStatus.current} accepted={guideStatus.accepted} />
      </section>}
      <section className="article-section">
        {station?.assetURL && <div className="crafting-station"><PixelImage src={station.assetURL} alt={`${station.name} building visual`} size={72} /><p><strong>{station.name}</strong> is the current station visual for this system.</p></div>}
        <h2>Access and readiness</h2>
        <dl className="fact-grid">
          <div><dt>Availability</dt><dd>See the status above for whether this station and recipe family can be used now.</dd></div>
          <div><dt>Station access</dt><dd>{station ? <><Link href={`/buildings/${station.slug}`}>{station.name}</Link> · {constructionCost(station)}</> : 'Open the station named above.'}</dd></div>
          <div><dt>How to reach it</dt><dd><ul className="compact-list">{system.access.map((fact) => <li key={fact}>{fact}</li>)}</ul></dd></div>
        </dl>
      </section>
      <section className="article-section">
        <h2>How to use this station</h2>
        <ol className="numbered-guide">
          {system.howItWorks.map((step) => (
            <li key={step}>{step}</li>
          ))}
        </ol>
      </section>
      {system.slug === 'apothecary' && <section className="article-section"><h2>Lesser Salve is the first known preparation</h2><div className="definition-grid"><div><h3>What construction gives you</h3><p>The completed Apothecary teaches the Lesser Salve recipe only. It does not give a Salve, spend a flexible material, or consume Resin.</p><p><Link href="/buildings/apothecary">Read the complete Apothecary entry</Link></p></div><div><h3>What preparation needs</h3><p>{apothecaryFirstUse.firstRecipe}</p><p>A flexible material means one eligible material stored at Home, not a generic amount or an unrelated named object.</p></div></div><h3>If ingredients are missing</h3><ul className="compact-list">{apothecaryFirstUse.shortfalls.map((line) => <li key={line}>{line}</li>)}</ul><p>{apothecaryFirstUse.inference}</p></section>}
      {system.slug === 'blacksmith' && <section className="article-section"><h2>Pointed Blade is the first available weapon form</h2><p>Completing Halloway’s foundation teaches this Schematic but does not give you finished gear. The recipe uses one chosen point and one different chosen grip. The preview shows the final Essence price before you confirm.</p><ul className="compact-list">{blacksmithFirstUse.pointedBlade.map((line) => <li key={line}>{line}</li>)}</ul><p>{blacksmithFirstUse.stockBoundary}</p><p><Link href="/buildings/blacksmith">Read Halloway’s complete Blacksmith entry</Link></p></section>}
      {system.slug === 'blacksmith' && <section className="article-section note-card"><h2>Reforge changes one chosen item</h2><ul className="compact-list">{blacksmithFirstUse.reforgeBoundary.map((line) => <li key={line}>{line}</li>)}</ul></section>}
      {system.slug === 'anchorage' && <section className="article-section"><h2>Using an Anchor Frame in the field</h2><p>Build the Anchorage after <Link href="/people/tovin">Tovin</Link> joins the Village, then meet every requirement for one Frame:</p><ul className="compact-list">{anchorageFirstAnchor.frameRequirements.map((line) => <li key={line}>{line}</li>)}</ul><p>One material cannot fill two positions. The completed Frame goes to the Storehouse, or Waiting if storage is full, and can be packed later through the Field Kit. It works on valid clear ground. A discovered <Link href="/sites/atlas-seam">Atlas Seam</Link> can anchor a world without a Frame.</p><p><Link href="/buildings/anchorage">Read the complete first-anchor journey</Link></p></section>}
      {system.slug === 'instruments' && <section className="article-section"><h2>Study a permanent field skill</h2><p>After <Link href="/people/mara">Mara</Link> joins the Village and the <Link href="/buildings/survey-post">Survey Post</Link> is built, each Field Instruments Research entry teaches one named subject at Crude precision. It is a permanent skill rather than a physical item.</p><div className="table-wrap"><table><thead><tr><th>Instrument</th><th>Subject</th><th>Cost before discounts</th></tr></thead><tbody>{surveyPostFirstUse.instruments.map(([id, name, subject, cost]) => <tr key={id}><td>{name}</td><td>{subject}</td><td>{cost}</td></tr>)}</tbody></table></div><p>Check the Research preview before studying; it includes any staffing discount from Mara. A full Storehouse or Waiting area cannot block this purchase because it does not create an item.</p></section>}
      {system.slug === 'instruments' && <section className="article-section note-card"><h2>Good and Fine precision are playable now</h2><ul className="compact-list">{surveyPostFirstUse.improvementBoundary.map((line) => <li key={line}>{line}</li>)}</ul><p><Link href="/buildings/survey-post">Read packing, Survey, refusal, and relaunch boundaries</Link></p></section>}
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
              {publishedRecipes.map((recipe) => (
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
          {outputItems.length ? <ul className="compact-list">{outputItems.map(({ recipe, item }) => <li key={recipe.id}>{item ? <><Link href={resultLink(item)}>{recipe.result}</Link> — {item.summary}</> : <><strong>{recipe.result}</strong> — check the station preview to see where it will go and what it will do.</>}</li>)}</ul> : <p>This station process does not yet have a separate result page.</p>}
        </div>
        <div>
          <h2>Related routes</h2>
          <p>{station ? <><Link href={`/buildings/${station.slug}`}>{station.name}</Link> is the home of this craft. </> : null}Open each linked resource to learn how to obtain it and where else it is used. Open the finished item or equipment page for the complete result.</p>
        </div>
      </section>
      {notLive.length ? <section className="article-section note-card crafting-boundary"><h2>Planned recipes — not available yet</h2><ul className="compact-list">{notLive.map((entry) => <li key={entry.name}><strong>{entry.name}:</strong> {entry.detail}</li>)}</ul></section> : null}
      {guideStatus?.changes.length ? <section className="article-section"><h2>Recipe-by-recipe changes</h2><p>“Playable now” describes the game today. “Planned design” is not available yet; any ingredient list or stat value described as still being authored belongs to the remaining Game Design content pass.</p><div className="status-card-grid">{guideStatus.changes.map((change) => <article className="status-card" key={change.name}><h3>{change.name}</h3><TruthPair current={change.current} accepted={change.accepted} /></article>)}</div></section> : null}
      {system.slug === 'apothecary' && <section className="article-section note-card"><h2>What the first build does not grant</h2><p>{apothecaryFirstUse.catalogueBoundary}</p><ul className="compact-list">{apothecaryFirstUse.costs.map((line) => <li key={line}>{line}</li>)}</ul></section>}
      <section className="article-section note-card">
        <h2>Make it and receive the result</h2>
        <p>{system.commitResult}</p>
      </section>
      <RelatedGuides links={[{ label: 'All crafting systems', href: '/crafting' }, ...(station ? [{ label: station.name, href: `/buildings/${station.slug}` }] : []), { label: 'Village', href: '/village' }, ...relatedResources.slice(0, 3).flatMap((resource) => resource ? [{ label: resource.name, href: `/resources/${resource.slug}` }] : []), { label: 'All resources', href: '/resources' }]} />
    </SiteFrame>
  );
}
