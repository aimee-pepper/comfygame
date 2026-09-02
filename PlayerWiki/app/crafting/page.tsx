import Link from '@/components/wiki-link';
import { PageIntro } from '@/components/page-intro';
import { PixelImage } from '@/components/pixel-image';
import { SiteFrame } from '@/components/site-frame';
import { TruthPair } from '@/components/truth-pair';
import { definedButNotLiveCrafting, craftingSystems, recipeReadiness, recipesFor, scheduledButNotLiveStations } from '@/lib/crafting';
import { craftingFamilyStatus } from '@/lib/player-guide-status';
import { canonicalStackExample, coatingLifecycle, materialCustodyFlow, materialIdentityHierarchy, materialPricing, materialPropertyProblems, progressionPlan, qualityRules, starterRuneFlow, worldGenerationPlan } from '@/lib/crafting-overview';
import { content, humanize } from '@/lib/content';

function stationVisual(system: (typeof craftingSystems)[number]) {
  return content.stations.find((station) => station.id === system.stationID);
}

function statusHref(slug: string) {
  return slug === 'recycler' ? '/recycling' : `/crafting/${slug}`;
}

function resultItem(recipe: ReturnType<typeof recipesFor>[number]) {
  return content.items.find((item) => item.name === recipe.result) ?? null;
}

function resultHref(item: NonNullable<ReturnType<typeof resultItem>>) {
  return item.gear ? `/equipment/${item.slug}` : `/items/${item.slug}`;
}

function ingredientLabel(
  ingredient: ReturnType<typeof recipesFor>[number]['ingredients'][number],
) {
  const resource = ingredient.resourceID
    ? content.resources.find((entry) => entry.id === ingredient.resourceID)
    : null;
  const name = resource?.name ?? humanize(ingredient.label);
  const amount = ingredient.amount === undefined ? '' : `${ingredient.amount} × `;
  return (
    <span className="recipe-ingredient">
      {resource?.assetURL && <PixelImage src={resource.assetURL} alt={`${resource.name} icon`} size={24} />}
      {amount}
      {resource ? <Link href={`/resources/${resource.slug}`}>{name}</Link> : name}
      {ingredient.role && <small> — {ingredient.role}</small>}
    </span>
  );
}

export default function CraftingSystemsPage() {
  return (
    <SiteFrame sidebar>
      <PageIntro
        eyebrow="Production guide"
        title="Crafting systems"
        summary="A complete guide to every current maker and processor, every live recipe, and the intended physical-material system that will replace the game's hidden numerical sample rules."
      />
      <section className="article-section">
        <h2>Every crafting and processing system</h2>
        <p>This guide keeps the game you can play today separate from the intended implementation. A future recipe is never presented as a current one. The physical-material structure below is accepted, but it is not yet implemented; the few recipe lists and numerical values that remain open are marked clearly.</p>
        <div className="status-card-grid">{craftingFamilyStatus.map((entry) => <article className="status-card" key={entry.slug}><p className="status-pill">{entry.status}</p><h3><Link href={statusHref(entry.slug)}>{entry.name}</Link></h3><TruthPair current={entry.current} accepted={entry.accepted} acceptedLabel="Intended implementation" /></article>)}</div>
      </section>
      <section className="article-section note-card">
        <h2>The current material foundation is being replaced</h2>
        <p>The current game stores many natural materials as individual samples and lets recipes ask for hidden scores. That can make an unrelated object valid merely because a number is high enough. These six terms describe the current implementation; they are not the intended player-facing recipe language.</p>
        <div className="table-wrap"><table><thead><tr><th>Current hidden trait</th><th>What it measures now</th><th>Recognisable physical replacement</th></tr></thead><tbody>{materialPropertyProblems.map(([name, current, replacement]) => <tr key={name}><td><strong>{name}</strong></td><td>{current}</td><td>{replacement}</td></tr>)}</tbody></table></div>
        <p><strong>Intended rule:</strong> recipes name real materials and real parts. The numerical property model may remain behind world generation, but it will not decide whether a player can craft a recipe.</p>
      </section>
      <section className="article-section">
        <h2>The intended material inventory</h2>
        <p>Materials remain genuinely different physical things. Species-specific drops matter, but species names do not create needless inventory types. A broad recipe can accept Scales, a narrower one can accept Fish Scales, and an advanced one can require Armoured Fish Scales. Any generated species variant inside that eligible type can be used. A complete stack can read <strong>{canonicalStackExample}</strong>.</p>
        <div className="table-wrap"><table><thead><tr><th>Identity level</th><th>Example</th><th>How it is used</th></tr></thead><tbody>{materialIdentityHierarchy.map(([level, example, use]) => <tr key={level}><td><strong>{level}</strong></td><td>{example}</td><td>{use}</td></tr>)}</tbody></table></div>
        <h3>Quality and stacks</h3>
        <div className="table-wrap"><table><thead><tr><th>Resource quality</th><th>Inventory behavior</th><th>Intended sale price</th></tr></thead><tbody>{qualityRules.map(([band, behavior], index) => <tr key={band}><td><strong>{band}</strong></td><td>{behavior}</td><td>{materialPricing[index][1]}</td></tr>)}</tbody></table></div>
        <ul className="compact-list"><li>The same physical type or precise subtype and quality combine into one quantity stack.</li><li>Species, world, encounter, inherited colour, and acquisition source remain available in expanded history without splitting otherwise identical stock.</li><li>Materials never occupy ordinary item slots or spill into Waiting because the item grid is full.</li><li>When quality changes the result, the player chooses the exact quality and quantity. The game does not decide whether to save or spend the player's best materials.</li><li>Peerless is reserved for legendary equipment, not raw resources.</li></ul>
      </section>
      <section className="article-section">
        <h2>One material identity from discovery to reuse</h2>
        <div className="table-wrap"><table><thead><tr><th>Player surface</th><th>Implemented now</th><th>Intended implementation</th></tr></thead><tbody>{materialCustodyFlow.map(([surface, current, intended]) => <tr key={surface}><td><strong>{surface}</strong></td><td>{current}</td><td>{intended}</td></tr>)}</tbody></table></div>
      </section>
      <section className="article-section">
        <h2>How progression will work</h2>
        <p>Advanced worlds are not withheld merely because the player is early in the campaign. Progress comes from better harvesting tools, new processing facilities, facility levels, later recipe tiers, and more precise World Writing.</p>
        <div className="definition-grid">{progressionPlan.map(([name, body]) => <article key={name}><h3>{name}</h3><p>{body}</p></article>)}</div>
      </section>
      <section className="article-section two-column">
        <div><h2>Raw, processed, and finished</h2><p>The intended economy has raw world materials, raw creature and flora materials, a deliberately modest processed layer, and finished components or items. Useful shared intermediates may include Ingots, Glass, Leather, Cloth, Cord, Planks, and Prepared Extracts. Their final list and facility owners remain under discussion.</p><p>A processing step must change what a material can do, combine or purify it, or create stock shared by several recipes. It should not exist only to add busywork.</p></div>
        <div><h2>Crafted quality and statistics</h2><p>Selected material quality contributes directly to real item statistics shown in the preview. Mostly Poor inputs can produce a Rough item; mostly Common a Fine item; Rare a Superior item; and an Exceptional result an Exceptional item. The exact multi-input formula remains under discussion.</p><p>Peerless is legendary equipment, never a resource stack. It may come from high-level alpha drops or an approved maximum-facility craft chance. Bookbinder will not add an equipment durability system.</p></div>
      </section>
      <section className="article-section">
        <h2>How generated worlds will support crafting</h2>
        <p>Resources will come from the world that generated them rather than feeling randomly scattered. The existing deterministic seed, frozen receipt, reachability protection, and useful land/water work remain foundations for the overhaul.</p>
        <div className="definition-grid">{worldGenerationPlan.map(([name, body]) => <article key={name}><h3>{name}</h3><p>{body}</p></article>)}</div>
        <p><strong>Rubble is unresolved:</strong> it will not remain a finished resource with no physical identity. Aimee will choose between removing it or turning a renamed mixed find into a world-causal processing input.</p>
      </section>
      <section className="article-section two-column">
        <div className="note-card"><h2>Weapon coatings</h2><TruthPair current={coatingLifecycle.current} accepted={coatingLifecycle.intended} acceptedLabel="Locked intended rule" /><p><strong>Existing saves:</strong> {coatingLifecycle.migration}</p></div>
        <div className="note-card"><h2>The first two runes</h2><TruthPair current={starterRuneFlow.current} accepted={starterRuneFlow.intended} acceptedLabel="Locked intended opening" /><p><strong>If the introduction is interrupted:</strong> {starterRuneFlow.recovery}</p><p><strong>Existing campaigns:</strong> {starterRuneFlow.legacy}</p></div>
      </section>
      <section className="article-section">
        <div className="topic-grid">
          {craftingSystems.map((system) => (
            <Link
              className="topic-card"
              href={`/crafting/${system.slug}`}
              key={system.slug}
            >
              {stationVisual(system)?.assetURL && <PixelImage src={stationVisual(system)!.assetURL} alt={`${stationVisual(system)!.name} building visual`} size={56} />}
              <span>
                <strong>{system.name}</strong>
                <small>
                  {system.station} · {recipesFor(system.slug).length} documented
                  recipes
                </small>
                <small>{system.summary}</small>
                <small><strong>Ready when:</strong> {system.access[0]}</small>
              </span>
            </Link>
          ))}
        </div>
      </section>
      <section className="article-section crafting-reachability">
        <h2>What is available now</h2>
        <p>Every entry below is a current player recipe or station process. The station must be usable, the named recipe or capability must be known, the exact inputs must be present, and the preview must still quote a legal output destination before you commit.</p>
        <div className="crafting-reachability-grid">
          {craftingSystems.map((system) => {
            const station = stationVisual(system);
            const recipes = recipesFor(system.slug);
            return <article className="crafting-reachability-card" key={system.slug}>
              <div className="crafting-reachability-heading">
                {station?.assetURL && <PixelImage src={station.assetURL} alt={`${station.name} building visual`} size={40} />}
                <div><p className="crafting-live-state">Current player route</p><h3><Link href={`/crafting/${system.slug}`}>{system.name}</Link></h3><p>{station ? <Link href={`/buildings/${station.slug}`}>{station.name}</Link> : system.station}</p></div>
              </div>
              <dl>
                <div><dt>Ready when</dt><dd>{system.access[0]}</dd></div>
                <div><dt>Craft family</dt><dd>{system.summary}</dd></div>
              </dl>
              {recipes.length ? <ul className="crafting-reachability-recipes">{recipes.map((recipe) => <li key={recipe.id}><strong>{recipe.name}</strong><span>→ {recipe.result}</span><small>{recipeReadiness(recipe)}</small></li>)}</ul> : <p className="muted-copy">This current station process has no separately published recipe rows.</p>}
            </article>;
          })}
        </div>
      </section>
      <section className="article-section note-card crafting-boundary">
        <h2>Defined or scheduled is not available now</h2>
        <ul className="compact-list">{definedButNotLiveCrafting.map((entry) => <li key={entry.name}><strong>{entry.name}:</strong> {entry.detail}</li>)}{scheduledButNotLiveStations.map((entry) => <li key={entry}>{entry}</li>)}</ul>
      </section>
      <section className="article-section recipe-directory">
        <h2>All current recipes by station</h2>
        <p>Each row keeps the published output, ingredient quantity or selection requirement, and the current player-facing use together. Open a station guide for its operation steps.</p>
        {craftingSystems.map((system) => {
          const recipes = recipesFor(system.slug);
          const station = stationVisual(system);
          if (!recipes.length) return null;
          return <section className="recipe-directory-group" id={system.slug} key={system.slug}><div className="recipe-directory-heading"><div>{station?.assetURL && <PixelImage src={station.assetURL} alt={`${station.name} building visual`} size={48} />}<div><h3>{system.name}</h3><p>{station ? <Link href={`/buildings/${station.slug}`}>{station.name}</Link> : system.station} · <Link href={`/crafting/${system.slug}`}>How this station works</Link></p></div></div><span>{recipes.length} {recipes.length === 1 ? 'recipe' : 'recipes'}</span></div><div className="table-wrap"><table><thead><tr><th>Recipe</th><th>Output</th><th>Exact ingredients and costs</th><th>Ready when</th><th>Primary use</th></tr></thead><tbody>{recipes.map((recipe) => { const item = resultItem(recipe); return <tr key={recipe.id}><td><strong>{recipe.name}</strong></td><td>{item?.assetURL && <PixelImage src={item.assetURL} alt={`${item.name} icon`} size={32} />} {item ? <Link href={resultHref(item)}>{recipe.result}</Link> : recipe.result}</td><td><ul className="compact-list">{recipe.ingredients.map((ingredient, index) => <li key={`${recipe.id}-${index}`}>{ingredientLabel(ingredient)}</li>)}</ul></td><td>{recipeReadiness(recipe)}</td><td>{item?.summary ?? recipe.notes ?? 'No published player-facing use is currently listed.'}</td></tr>; })}</tbody></table></div></section>;
        })}
      </section>
      <section className="article-section">
        <h2>Complete current-to-intended recipe comparison</h2>
        <p>Every recipe or service change is listed beside the behavior in the current build. “Intended implementation” never means that ingredient or action is available today.</p>
        {craftingFamilyStatus.map((entry) => <section className="recipe-directory-group" id={`${entry.slug}-comparison`} key={`${entry.slug}-comparison`}><div className="recipe-directory-heading"><div><div><h3><Link href={statusHref(entry.slug)}>{entry.name}</Link></h3><p className="status-pill">{entry.status}</p></div></div><span>{entry.changes.length} {entry.changes.length === 1 ? 'entry' : 'entries'}</span></div><div className="status-card-grid">{entry.changes.map((change) => <article className="status-card" key={`${entry.slug}-${change.name}`}><h3>{change.name}</h3><TruthPair current={change.current} accepted={change.accepted} acceptedLabel="Intended implementation" /></article>)}</div></section>)}
      </section>
      <section className="article-section note-card">
        <h2>Will discuss with Aimee</h2>
        <ul className="compact-list"><li>The final material type/subtype catalogue and every recipe's broad, specific, or precise substitution list.</li><li>Rubble removal or processing.</li><li>The processed-material list and which facilities own smelting, glassmaking, tanning, weaving, carpentry, and extraction.</li><li>Exact harvesting tool tiers, facility levels, and recipe-tier unlocks.</li><li>Material-to-stat values, multi-input crafted quality, and colour blending.</li><li>Peerless equipment chance, alpha eligibility, and whether matching-NPC staffing improves a maximum-level craft.</li><li>Ground-layout names, granular terrain/liquid catalogue, world-size values, and environmental compatibility.</li><li><strong>Waystone body:</strong> Adamant, Obsidian, or a closed choice between them.</li></ul>
      </section>
      <nav className="next-links">
        <Link href="/systems/crafting">How crafting works</Link>
        <Link href="/village">Village buildings</Link>
        <Link href="/resources">Resource table</Link>
      </nav>
    </SiteFrame>
  );
}
