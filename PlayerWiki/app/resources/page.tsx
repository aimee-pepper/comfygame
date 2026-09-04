import { SeptemberDecisions } from '@/components/september-decisions';
import Link from '@/components/wiki-link';
import { DirectoryDetailsIntro, DirectoryIndex } from '@/components/directory-navigation';
import { PageIntro } from '@/components/page-intro';
import { PixelImage } from '@/components/pixel-image';
import { SiteFrame } from '@/components/site-frame';
import { content } from '@/lib/content';
import { recipesUsingResource } from '@/lib/crafting';
import { TruthPair } from '@/components/truth-pair';
import { lootPaths, qualityBands } from '@/lib/player-guide-status';
import { canonicalStackExample, floraMaterialPropertyDerivations, intendedMaterialCatalogue, materialIdentityHierarchy, materialScoreBoundary } from '@/lib/crafting-overview';

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
    <SeptemberDecisions topic="progression" />
      <DirectoryIndex label="Browse resources" entries={content.resources.map((resource) => ({ href: `/resources/${resource.slug}`, name: resource.name, imageURL: resource.assetURL, imageAlt: `${resource.name} inventory icon` }))} />
      <DirectoryDetailsIntro title="Compare resources" summary="See how every current resource is found, what recipes, services, and buildings use it, and whether it can be traded before opening its complete entry." />
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
                      <li><strong>Craft / process:</strong> {resource.consumerAuthority.recipeConsumers.length ? resource.consumerAuthority.recipeConsumers.join('; ') : 'No current recipe or process'}</li>
                      <li><strong>Service / Research:</strong> {resource.consumerAuthority.otherConsumers.length ? resource.consumerAuthority.otherConsumers.join('; ') : 'No other current use'}</li>
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
        <h2>Rules shared by resources and materials</h2>
        <TruthPair
          current="The game currently stores some World resources as quantities and other gathered materials as individual samples that remember where they came from. The table above shows how each one is currently found and used."
          accepted="Mined stock will use one exact-name quantity stack with no quality: Sand is Sand and Gold is Gold, always in the normal/green presentation. Ordinary flora stock is also ungraded and stacks by physical type or subtype. Creature stock uses recognizable categories, types, subtypes, and four quality bands, while species, world, colour, and inherited values remain available in expanded history."
          acceptedLabel="Intended design"
        />
        <p><a href="#loot-and-custody">Follow materials from the world to the Cottage</a> · <Link href="/guide-status">See what is changing</Link></p>
      </section>
      <section className="article-section" id="loot-and-custody">
        <h2>Gathering, return, and storage</h2>
        <p>These paths explain where a found material goes. Open its resource or item page to learn exactly what it is and where it can be used.</p>
        <div className="status-card-grid">{lootPaths.map((path) => <article className="status-card" key={path.name}><h3>{path.name}</h3><TruthPair current={path.current} accepted={path.accepted} /></article>)}</div>
      </section>
      <section className="article-section">
        <h2>Intended material identity</h2>
        <p>The hierarchy is settled. Game Design will promote each remaining physical type or subtype only after its producer, use, storage, trade, and recycling path are complete.</p>
        <div className="table-wrap"><table><thead><tr><th>Level</th><th>Example</th><th>Player meaning</th></tr></thead><tbody>{materialIdentityHierarchy.map(([level, example, meaning]) => <tr key={level}><td><strong>{level}</strong></td><td>{example}</td><td>{meaning}</td></tr>)}</tbody></table></div>
        <div className="definition-grid"><div><h3>Mined resources</h3><p><strong>Sand · Gold · Granite</strong></p><p>One exact-name quantity stack each, with no quality variants. All use the normal/green presentation.</p></div><div><h3>Creature-material quality</h3><p>{qualityBands.join(' · ')}</p><p>White, green, blue, and purple respectively. Each approved creature subtype and quality has its own default stack.</p></div><div><h3>How a creature stack reads</h3><p><strong>{canonicalStackExample}</strong>. Expand it to inspect every species-specific item, source world, inherited colour, quantity, and visible stat contribution.</p></div><div><h3>Inventory views</h3><p>The default shows mined materials by exact name, ordinary flora by type or subtype, and creature materials by subtype + quality. Alternate views never move or merge stock.</p></div><div><h3>Selection</h3><p>Mined and ordinary flora recipes ask only for material and quantity. When creature-material quality affects a result, the player chooses which quality to spend.</p></div><div><h3>Peerless</h3><p>Peerless is reserved for legendary equipment, not raw materials.</p></div></div>
      </section>
      <section className="article-section"><h2>Planned physical-material catalogue</h2><p>This is the intended starting set, not a claim that every entry is available in the current build. A subtype enters the game only when it has a truthful producer, useful recipe or processing role, complete custody, trade and recycling behavior, and appropriate art.</p><div className="table-wrap"><table><thead><tr><th>Source</th><th>Recipe category</th><th>Physical types and subtypes</th><th>Quality</th></tr></thead><tbody>{intendedMaterialCatalogue.map(([source, category, materials, quality]) => <tr key={`${source}-${category}`}><td>{source}</td><td><strong>{category}</strong></td><td>{materials}</td><td>{quality}</td></tr>)}</tbody></table></div><p>Reagent and Toxin are future recipe headings over named physical substances, not inventory items. Generic Ore becomes the actual metal. Timber becomes Logs before processing and Planks after it. Pulp becomes processed stock rather than a plant drop.</p></section>
      <section className="article-section note-card"><h2>What stays separate</h2><p>Items, equipment, Pages, Curios, placed sites, Raw Essence, Motes, and special guardian rewards remain separate from ordinary material stacks. A depleted site remains part of its world’s history. Gold material is also separate from Gold Coins.</p></section>
      <section className="article-section">
        <h2>Flora materials inherit their plant</h2>
        <p>Current harvested plant samples already derive properties from the saved plant traits. These values remain part of the intended material system and will contribute to concrete crafted-item statistics rather than acting as universal recipe passwords.</p>
        <div className="table-wrap"><table><thead><tr><th>Property</th><th>Current Flora-derived calculation</th></tr></thead><tbody>{floraMaterialPropertyDerivations.map(([property, calculation]) => <tr key={property}><td><strong>{property}</strong></td><td>{calculation}</td></tr>)}</tbody></table></div>
        <p className="note-card"><strong>Current exceptions:</strong> {materialScoreBoundary.currentExceptions}</p>
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
