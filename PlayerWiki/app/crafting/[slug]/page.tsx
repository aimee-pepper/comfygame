import type { Metadata } from 'next';
import Link from 'next/link';
import { notFound } from 'next/navigation';
import { PageIntro } from '@/components/page-intro';
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
    <>
      {amount}
      {body}
      {ingredient.role ? <small> — {ingredient.role}</small> : null}
    </>
  );
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
  return (
    <SiteFrame sidebar>
      <PageIntro
        eyebrow={system.station}
        title={system.name}
        summary={system.summary}
      />
      <section className="article-section">
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
                <th>Result</th>
                <th>Requirements</th>
                <th>Notes</th>
              </tr>
            </thead>
            <tbody>
              {recipes.map((recipe) => (
                <tr key={recipe.id}>
                  <td>
                    <strong>{recipe.name}</strong>
                  </td>
                  <td>{recipe.result}</td>
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
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </section>
      <nav className="next-links">
        <Link href="/crafting">All crafting systems</Link>
        <Link href="/resources">Resources</Link>
      </nav>
    </SiteFrame>
  );
}
