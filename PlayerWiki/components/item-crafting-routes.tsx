import Link from 'next/link';
import { craftingRecipes, systemFor } from '@/lib/crafting';
import { type Item, content, humanize } from '@/lib/content';

function ingredientLabel(
  ingredient: (typeof craftingRecipes)[number]['ingredients'][number],
) {
  const resource = ingredient.resourceID
    ? content.resources.find((entry) => entry.id === ingredient.resourceID)
    : null;
  const name = resource?.name ?? humanize(ingredient.label);
  const amount = ingredient.amount === undefined ? '' : `${ingredient.amount} × `;
  return <>{amount}{resource ? <Link href={`/resources/${resource.slug}`}>{name}</Link> : name}{ingredient.role && <small> — {ingredient.role}</small>}</>;
}

export function ItemCraftingRoutes({ item }: { item: Item }) {
  const routes = craftingRecipes.filter((recipe) => recipe.result === item.name);
  const resources = [...new Set(routes.flatMap((recipe) => recipe.ingredients.map((ingredient) => ingredient.resourceID).filter(Boolean)))].map((id) => content.resources.find((resource) => resource.id === id)).filter(Boolean);

  return (
    <>
      <section className="article-section">
        <h2>Current acquisition</h2>
        {routes.length ? <div className="item-route-list">{routes.map((recipe) => { const system = systemFor(recipe.system); return <article className="note-card" key={recipe.id}><h3><Link href={`/crafting/${recipe.system}`}>{recipe.name}</Link></h3><p>Prepared at {system?.station ?? humanize(recipe.system)}. Its current output is {recipe.result}.</p><ul className="compact-list">{recipe.ingredients.map((ingredient, index) => <li key={`${recipe.id}-${index}`}>{ingredientLabel(ingredient)}</li>)}</ul></article>; })}</div> : <p>No current station preparation or construction recipe is published for this exact item. This guide does not infer another acquisition route.</p>}
      </section>
      {resources.length > 0 && <section className="article-section">
        <h2>Related resources</h2>
        <nav className="item-resource-links" aria-label={`Resources used for ${item.name}`}>{resources.map((resource) => resource && <Link href={`/resources/${resource.slug}`} key={resource.id}>{resource.name}</Link>)}</nav>
      </section>}
    </>
  );
}
