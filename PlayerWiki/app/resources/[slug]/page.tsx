import type { Metadata } from 'next';
import Link from 'next/link';
import { notFound } from 'next/navigation';
import { PageIntro } from '@/components/page-intro';
import { PixelImage } from '@/components/pixel-image';
import { SiteFrame } from '@/components/site-frame';
import { content, humanize } from '@/lib/content';
import { recipesUsingResource, systemFor } from '@/lib/crafting';

export function generateStaticParams() {
  return content.resources.map((resource) => ({ slug: resource.slug }));
}
export async function generateMetadata({
  params,
}: {
  params: Promise<{ slug: string }>;
}): Promise<Metadata> {
  const { slug } = await params;
  const resource = content.resources.find((entry) => entry.slug === slug);
  return resource
    ? { title: resource.name, description: resource.summary }
    : {};
}

export default async function ResourceDetail({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = await params;
  const resource = content.resources.find((entry) => entry.slug === slug);
  if (!resource) notFound();
  const craftUses = recipesUsingResource(resource.id);
  const buildUses = content.stations.flatMap((station) =>
    station.buildCost
      .filter(
        (cost) => (cost.id ?? cost.resource ?? cost.resourceID) === resource.id,
      )
      .map((cost) => ({
        station,
        quantity: cost.quantity ?? cost.amount ?? '?',
      })),
  );
  return (
    <SiteFrame sidebar>
      <div className="entity-heading">
        <PixelImage
          src={resource.assetURL}
          alt={`${resource.name} inventory icon`}
          size={96}
        />
        <PageIntro
          eyebrow={`${resource.tradeBand} resource`}
          title={resource.name}
          summary={resource.summary}
        />
      </div>
      <section className="article-section">
        <h2>Where it tends to appear</h2>
        <p>
          <strong>Primary pressure:</strong> {resource.drivenBy}
        </p>
        <div className="two-column">
          <div>
            <h3>Required conditions</h3>
            <ul>
              {resource.requires.map((line) => (
                <li key={line}>{line}</li>
              ))}
            </ul>
          </div>
          <div>
            <h3>Conditions that help</h3>
            <ul>
              {resource.favours.map((line) => (
                <li key={line}>{line}</li>
              ))}
            </ul>
          </div>
        </div>
      </section>
      <section className="article-section">
        <h2>Current uses</h2>
        <ul>
          {resource.currentUses.map((line) => (
            <li key={line}>{line}</li>
          ))}
        </ul>
      </section>
      <section className="article-section">
        <h2>Craft recipes</h2>
        {craftUses.length ? (
          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>Recipe</th>
                  <th>System</th>
                  <th>How this resource is used</th>
                </tr>
              </thead>
              <tbody>
                {craftUses.map((recipe) => {
                  const ingredient = recipe.ingredients.find(
                    (entry) => entry.resourceID === resource.id,
                  )!;
                  const system = systemFor(recipe.system);
                  return (
                    <tr key={recipe.id}>
                      <td>
                        <Link href={`/crafting/${recipe.system}`}>
                          {recipe.name}
                        </Link>
                      </td>
                      <td>{system?.name ?? humanize(recipe.system)}</td>
                      <td>
                        {ingredient.amount
                          ? `${ingredient.amount} required`
                          : humanize(ingredient.role ?? 'eligible component')}
                        {ingredient.role && ingredient.amount
                          ? ` · ${ingredient.role}`
                          : ''}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        ) : (
          <p>
            This resource is not consumed by a currently documented crafting
            recipe.
          </p>
        )}
      </section>
      <section className="article-section">
        <h2>Building recipes</h2>
        {buildUses.length ? (
          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>Building</th>
                  <th>Quantity</th>
                </tr>
              </thead>
              <tbody>
                {buildUses.map(({ station, quantity }) => (
                  <tr key={station.id}>
                    <td>
                      <Link href={`/places/${station.slug}`}>
                        {station.name}
                      </Link>
                    </td>
                    <td>{quantity}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        ) : (
          <p>This resource is not a material in a current building recipe.</p>
        )}
      </section>
      <nav className="next-links">
        <Link href="/resources">Back to all resources</Link>
        <Link href="/crafting">Crafting systems</Link>
      </nav>
    </SiteFrame>
  );
}
