import Link from '@/components/wiki-link';
import { PageIntro } from '@/components/page-intro';
import { PixelImage } from '@/components/pixel-image';
import { SiteFrame } from '@/components/site-frame';
import { definedButNotLiveCrafting, craftingSystems, recipeReadiness, recipesFor, scheduledButNotLiveStations } from '@/lib/crafting';
import { content, humanize } from '@/lib/content';

function stationVisual(system: (typeof craftingSystems)[number]) {
  return content.stations.find((station) => station.id === system.stationID);
}

function resultItem(recipe: ReturnType<typeof recipesFor>[number]) {
  return content.items.find((item) => item.name === recipe.result) ?? null;
}

function resultHref(item: NonNullable<ReturnType<typeof resultItem>>) {
  return item.gear ? `/equipment/${item.slug}` : `/items/${item.slug}`;
}

function ingredientLabel(
  ingredient: ReturnType<typeof recipesFor>[number]['ingredients'][number],
) {
  const resource = ingredient.resourceID
    ? content.resources.find((entry) => entry.id === ingredient.resourceID)
    : null;
  const name = resource?.name ?? humanize(ingredient.label);
  const amount = ingredient.amount === undefined ? '' : `${ingredient.amount} × `;
  return (
    <span className="recipe-ingredient">
      {resource?.assetURL && <PixelImage src={resource.assetURL} alt={`${resource.name} icon`} size={24} />}
      {amount}
      {resource ? <Link href={`/resources/${resource.slug}`}>{name}</Link> : name}
      {ingredient.role && <small> — {ingredient.role}</small>}
    </span>
  );
}

export default function CraftingSystemsPage() {
  return (
    <SiteFrame sidebar>
      <PageIntro
        eyebrow="Production guide"
        title="Crafting systems"
        summary="Each workshop has its own inputs, selection rules and finished results. Open a system for its complete current recipe list and links back to the resources it uses."
      />
      <section className="article-section">
        <div className="topic-grid">
          {craftingSystems.map((system) => (
            <Link
              className="topic-card"
              href={`/crafting/${system.slug}`}
              key={system.slug}
            >
              {stationVisual(system)?.assetURL && <PixelImage src={stationVisual(system)!.assetURL} alt={`${stationVisual(system)!.name} building visual`} size={56} />}
              <span>
                <strong>{system.name}</strong>
                <small>
                  {system.station} · {recipesFor(system.slug).length} documented
                  recipes
                </small>
                <small>{system.summary}</small>
                <small><strong>Ready when:</strong> {system.access[0]}</small>
              </span>
            </Link>
          ))}
        </div>
      </section>
      <section className="article-section crafting-reachability">
        <h2>What is available now</h2>
        <p>Every entry below is a current player recipe or station process. The station must be usable, the named recipe or capability must be known, the exact inputs must be present, and the preview must still quote a legal output destination before you commit.</p>
        <div className="crafting-reachability-grid">
          {craftingSystems.map((system) => {
            const station = stationVisual(system);
            const recipes = recipesFor(system.slug);
            return <article className="crafting-reachability-card" key={system.slug}>
              <div className="crafting-reachability-heading">
                {station?.assetURL && <PixelImage src={station.assetURL} alt={`${station.name} building visual`} size={40} />}
                <div><p className="crafting-live-state">Current player route</p><h3><Link href={`/crafting/${system.slug}`}>{system.name}</Link></h3><p>{station ? <Link href={`/buildings/${station.slug}`}>{station.name}</Link> : system.station}</p></div>
              </div>
              <dl>
                <div><dt>Ready when</dt><dd>{system.access[0]}</dd></div>
                <div><dt>Craft family</dt><dd>{system.summary}</dd></div>
              </dl>
              {recipes.length ? <ul className="crafting-reachability-recipes">{recipes.map((recipe) => <li key={recipe.id}><strong>{recipe.name}</strong><span>→ {recipe.result}</span><small>{recipeReadiness(recipe)}</small></li>)}</ul> : <p className="muted-copy">This current station process has no separately published recipe rows.</p>}
            </article>;
          })}
        </div>
      </section>
      <section className="article-section note-card crafting-boundary">
        <h2>Defined or scheduled is not available now</h2>
        <ul className="compact-list">{definedButNotLiveCrafting.map((entry) => <li key={entry.name}><strong>{entry.name}:</strong> {entry.detail}</li>)}{scheduledButNotLiveStations.map((entry) => <li key={entry}>{entry}</li>)}</ul>
      </section>
      <section className="article-section recipe-directory">
        <h2>All current recipes by station</h2>
        <p>Each row keeps the published output, ingredient quantity or selection requirement, and the current player-facing use together. Open a station guide for its operation steps.</p>
        {craftingSystems.map((system) => {
          const recipes = recipesFor(system.slug);
          const station = stationVisual(system);
          if (!recipes.length) return null;
          return <section className="recipe-directory-group" id={system.slug} key={system.slug}><div className="recipe-directory-heading"><div>{station?.assetURL && <PixelImage src={station.assetURL} alt={`${station.name} building visual`} size={48} />}<div><h3>{system.name}</h3><p>{station ? <Link href={`/buildings/${station.slug}`}>{station.name}</Link> : system.station} · <Link href={`/crafting/${system.slug}`}>How this station works</Link></p></div></div><span>{recipes.length} {recipes.length === 1 ? 'recipe' : 'recipes'}</span></div><div className="table-wrap"><table><thead><tr><th>Recipe</th><th>Output</th><th>Exact ingredients and costs</th><th>Ready when</th><th>Primary use</th></tr></thead><tbody>{recipes.map((recipe) => { const item = resultItem(recipe); return <tr key={recipe.id}><td><strong>{recipe.name}</strong></td><td>{item?.assetURL && <PixelImage src={item.assetURL} alt={`${item.name} icon`} size={32} />} {item ? <Link href={resultHref(item)}>{recipe.result}</Link> : recipe.result}</td><td><ul className="compact-list">{recipe.ingredients.map((ingredient, index) => <li key={`${recipe.id}-${index}`}>{ingredientLabel(ingredient)}</li>)}</ul></td><td>{recipeReadiness(recipe)}</td><td>{item?.summary ?? recipe.notes ?? 'No published player-facing use is currently listed.'}</td></tr>; })}</tbody></table></div></section>;
        })}
      </section>
      <nav className="next-links">
        <Link href="/systems/crafting">How crafting works</Link>
        <Link href="/village">Village buildings</Link>
        <Link href="/resources">Resource table</Link>
      </nav>
    </SiteFrame>
  );
}
