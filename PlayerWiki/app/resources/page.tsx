import Link from '@/components/wiki-link';
import { PageIntro } from '@/components/page-intro';
import { PixelImage } from '@/components/pixel-image';
import { SiteFrame } from '@/components/site-frame';
import { content } from '@/lib/content';
import { recipesUsingResource } from '@/lib/crafting';
import { TruthPair } from '@/components/truth-pair';
import { qualityBands } from '@/lib/player-guide-status';
import { canonicalStackExample, materialIdentityHierarchy } from '@/lib/crafting-overview';

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
        <h2>Resources today and the intended material overhaul</h2>
        <TruthPair
          current="The game currently mixes counted World resources with individual, source-bearing material samples. The table below describes those live acquisition and spending routes."
          accepted="Physical stock will use recognizable broad categories, specific types, and precise subtypes with four resource qualities. Species, world, colour, and inherited values remain available in expanded history without needlessly splitting otherwise identical stock."
          acceptedLabel="Intended design"
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
        <h2>Intended material identity</h2>
        <p>The hierarchy is settled; the complete physical type/subtype catalogue is still being designed with Aimee.</p>
        <div className="table-wrap"><table><thead><tr><th>Level</th><th>Example</th><th>Player meaning</th></tr></thead><tbody>{materialIdentityHierarchy.map(([level, example, meaning]) => <tr key={level}><td><strong>{level}</strong></td><td>{example}</td><td>{meaning}</td></tr>)}</tbody></table></div>
        <div className="definition-grid"><div><h3>Resource qualities</h3><p>{qualityBands.join(' · ')}</p><p>White, green, blue, and purple respectively. Each subtype and quality has its own default stack.</p></div><div><h3>How a stack reads</h3><p><strong>{canonicalStackExample}</strong>. Expand it to inspect every species-specific item, source world, inherited colour, quantity, and visible stat contribution.</p></div><div><h3>Inventory views</h3><p>The default groups subtype + quality. Alternate views can sort by material, quality, species, source, colour, quantity, or recency without moving or merging stock.</p></div><div><h3>Selection</h3><p>When quality affects the result, the player chooses which quality to spend. No recipe silently substitutes another grade.</p></div><div><h3>Peerless</h3><p>Peerless is reserved for legendary equipment, not raw resources.</p></div></div>
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
