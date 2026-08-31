import type { Metadata } from 'next';
import Link from 'next/link';
import { notFound } from 'next/navigation';
import { PageIntro } from '@/components/page-intro';
import { PixelImage } from '@/components/pixel-image';
import { GuideBreadcrumbs, RelatedGuides } from '@/components/guide-navigation';
import { SiteFrame } from '@/components/site-frame';
import { craftingSystems, recipesFor, systemFor } from '@/lib/crafting';
import { content, humanize } from '@/lib/content';

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

export default async function CraftingSystemDetail({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = await params;
  const system = systemFor(slug);
  if (!system) notFound();
  const recipes = recipesFor(slug);
  const station = content.stations.find((entry) => system.station.includes(entry.name));
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
        <h2>How it works</h2>
        <ol className="numbered-guide">
          {system.howItWorks.map((step) => (
            <li key={step}>{step}</li>
          ))}
        </ol>
      </section>
      <section className="article-section">
        <h2>Recipes and requirements</h2>
        <div className="table-wrap">
          <table>
            <thead>
              <tr>
                <th>Recipe</th>
                <th aria-label="Result image" />
                <th>Result</th>
                <th>Requirements</th>
                <th>Notes</th>
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
                  <td>
                    {recipe.notes ??
                      'Use the exact stock shown by the station preview.'}
                  </td>
                </>; })()}</tr>
              ))}
            </tbody>
          </table>
        </div>
      </section>
      <RelatedGuides links={[{ label: 'All crafting systems', href: '/crafting' }, { label: 'Crafting basics', href: '/systems/crafting' }, { label: 'Resources', href: '/resources' }, { label: 'Village services', href: '/services' }]} />
    </SiteFrame>
  );
}
