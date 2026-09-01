import Link from '@/components/wiki-link';
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
              <th>Current recipe and service uses</th>
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
                  <td>{resource.consumerAuthority.acquisition}</td>
                  <td>
                    <ul className="compact-list">
                      <li><strong>Craft / process:</strong> {resource.consumerAuthority.recipeConsumers.length ? resource.consumerAuthority.recipeConsumers.join('; ') : 'No current process listed'}</li>
                      <li><strong>Service / research:</strong> {resource.consumerAuthority.otherConsumers.length ? resource.consumerAuthority.otherConsumers.join('; ') : 'No other current sink listed'}</li>
                      {recipes.length > 0 && <li><strong>Current recipe pages:</strong> {recipes.map((recipe, index) => <span key={recipe.id}>{index ? ', ' : ''}<Link href={`/crafting/${recipe.system}`}>{recipe.name}</Link></span>)}</li>}
                    </ul>
                  </td>
                  <td>{buildings.length ? <><strong>Yes</strong><ul className="compact-list">{buildings.map((station) => { const cost = station.buildCost.find((entry) => (entry.id ?? entry.resource ?? entry.resourceID) === resource.id); return <li key={station.id}><Link href={`/buildings/${station.slug}`}>{station.name}</Link> · {cost?.quantity ?? cost?.amount ?? '?'}</li>; })}</ul></> : <strong>No</strong>}</td>
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
