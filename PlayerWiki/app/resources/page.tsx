import Link from 'next/link';
import { PageIntro } from '@/components/page-intro';
import { PixelImage } from '@/components/pixel-image';
import { SiteFrame } from '@/components/site-frame';
import { content } from '@/lib/content';
import { recipesUsingResource } from '@/lib/crafting';

function buildingUses(resourceID: string) {
  return content.stations.flatMap((station) =>
    station.buildCost.some(
      (cost) => (cost.id ?? cost.resource ?? cost.resourceID) === resourceID,
    )
      ? [station]
      : [],
  );
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
              <th>How obtained</th>
              <th>Crafts used in</th>
              <th>Building material?</th>
              <th>Trade status</th>
            </tr>
          </thead>
          <tbody>
            {content.resources.map((resource) => {
              const recipes = recipesUsingResource(resource.id);
              const buildings = buildingUses(resource.id);
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
                  <td>{resource.acquisition}</td>
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
                  <td>{buildings.length ? <>Yes — {buildings.slice(0, 2).map((station, index) => <span key={station.id}>{index ? ', ' : ''}<Link href={`/places/${station.slug}`}>{station.name}</Link></span>)}{buildings.length > 2 ? ` +${buildings.length - 2} more` : ''}</> : 'No'}</td>
                  <td>{resource.tradeStatus}</td>
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
