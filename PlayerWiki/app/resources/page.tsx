import Link from 'next/link';
import { PageIntro } from '@/components/page-intro';
import { PixelImage } from '@/components/pixel-image';
import { SiteFrame } from '@/components/site-frame';
import { content } from '@/lib/content';
import { recipesUsingResource } from '@/lib/crafting';

function buildingCount(resourceID: string) {
  return content.stations.filter((station) =>
    station.buildCost.some(
      (cost) => (cost.id ?? cost.resource ?? cost.resourceID) === resourceID,
    ),
  ).length;
}

export default function ResourcesPage() {
  return (
    <SiteFrame sidebar>
      <PageIntro
        eyebrow="Reference"
        title="Resources"
        summary="World resources are shaped by pressures in the Page and the world that Binding generates. Use this table to compare where each resource tends to appear and what it currently builds."
      />
      <div className="table-wrap data-table">
        <table>
          <thead>
            <tr>
              <th aria-label="Image" />
              <th>Resource</th>
              <th>Trade band</th>
              <th>Crafts used in</th>
              <th>Building material?</th>
            </tr>
          </thead>
          <tbody>
            {content.resources.map((resource) => {
              const recipes = recipesUsingResource(resource.id);
              const buildings = buildingCount(resource.id);
              return (
                <tr key={resource.id}>
                  <td>
                    <PixelImage
                      src={resource.assetURL}
                      alt={`${resource.name} inventory icon`}
                    />
                  </td>
                  <td>
                    <Link href={`/resources/${resource.slug}`}>
                      {resource.name}
                    </Link>
                    <small>{resource.summary}</small>
                  </td>
                  <td>{resource.tradeBand}</td>
                  <td>
                    {recipes.length ? (
                      <>
                        {recipes.slice(0, 3).map((recipe, index) => (
                          <span key={recipe.id}>
                            {index ? ', ' : ''}
                            <Link href={`/crafting/${recipe.system}`}>
                              {recipe.name}
                            </Link>
                          </span>
                        ))}
                        {recipes.length > 3
                          ? ` +${recipes.length - 3} more`
                          : ''}
                      </>
                    ) : (
                      'No current recipe'
                    )}
                  </td>
                  <td>
                    {buildings
                      ? `Yes — ${buildings} ${buildings === 1 ? 'building' : 'buildings'}`
                      : 'No'}
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
      <nav className="next-links">
        <Link href="/resources/progression">
          Compare resource roles and progression
        </Link>
        <Link href="/crafting">Crafting systems</Link>
      </nav>
    </SiteFrame>
  );
}
