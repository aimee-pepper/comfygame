import Link from '@/components/wiki-link';
import { PageIntro } from '@/components/page-intro';
import { PixelImage } from '@/components/pixel-image';
import { SiteFrame } from '@/components/site-frame';
import { content } from '@/lib/content';
import { recipesUsingResource } from '@/lib/crafting';
import { TruthPair } from '@/components/truth-pair';
import { creatureMaterialFamilies, qualityBands, worldMaterialFamilies } from '@/lib/player-guide-status';

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
      <section className="article-section">
        <h2>Resources today and the approved material update</h2>
        <TruthPair
          current="The game currently mixes counted World resources with individual, source-bearing material samples. The table below describes those live acquisition and spending routes."
          accepted="Physical stock will use real material families and six quality bands everywhere it travels. Source species and place remain available as history, but will not split otherwise identical material into needless item types."
        />
        <p><Link href="/loot">Follow loot from the world to the Cottage</Link> · <Link href="/guide-status">See what is changing</Link></p>
      </section>
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
      <section className="article-section">
        <h2>Approved material families</h2>
        <p>This is the accepted replacement, not the inventory model in the current build.</p>
        <div className="definition-grid">
          <div><h3>World materials</h3><p>{worldMaterialFamilies.map(([name]) => name).join(' · ')}</p></div>
          <div><h3>Creature materials</h3><p>{creatureMaterialFamilies.map(([name]) => name).join(' · ')}</p></div>
          <div><h3>Quality bands</h3><p>{qualityBands.join(' · ')}</p></div>
          <div><h3>How a stack reads</h3><p><strong>Fine Hide ×3</strong>, under Creature materials. A material stack never uses an item slot, and a recipe never silently spends a higher grade than the one you approved.</p></div>
        </div>
      </section>
      <nav className="next-links">
        <Link href="/resources/progression">
          Compare resource roles and progression
        </Link>
        <Link href="/crafting">Crafting systems</Link>
      </nav>
    </SiteFrame>
  );
}
