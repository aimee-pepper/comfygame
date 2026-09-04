import Link from '@/components/wiki-link';
import { GuideBreadcrumbs, RelatedGuides } from '@/components/guide-navigation';
import { SeptemberDecisions } from '@/components/september-decisions';
import { PageIntro } from '@/components/page-intro';
import { SiteFrame } from '@/components/site-frame';
import { buildCost, content, humanize } from '@/lib/content';
import { recipeReadiness } from '@/lib/crafting';
import { recyclerFirstUse } from '@/lib/recycler-first-use';
import { anchorageFirstAnchor } from '@/lib/anchorage-first-anchor';
import { apothecaryFirstUse } from '@/lib/apothecary-first-use';
import { blacksmithFirstUse } from '@/lib/blacksmith-first-use';
import { surveyPostFirstUse } from '@/lib/survey-post-first-use';
import { actionForSlug, actionsForStation } from '@/lib/action-reference';
import { buildingActions, buildingForSlug, buildingStatus, villageLocation } from '@/lib/village';
import { researchNodeSlug } from '@/lib/research';

function recipeRequirements(recipe: ReturnType<typeof buildingActions>['recipes'][number]) {
  return <ul className="compact-list">{recipe.ingredients.map((ingredient, index) => {
    const resource = ingredient.resourceID ? content.resources.find((entry) => entry.id === ingredient.resourceID) : null;
    const amount = ingredient.amount === undefined ? '' : `${ingredient.amount} × `;
    const label = resource?.name ?? humanize(ingredient.label);
    return <li key={`${recipe.id}-${index}`}>{amount}{resource ? <Link href={`/resources/${resource.slug}`}>{label}</Link> : label}{ingredient.role ? ` — ${ingredient.role}` : ''}</li>;
  })}</ul>;
}

export function FacilityDetail({ slug }: { slug: string }) {
  const building = buildingForSlug(slug);
  if (!building) return null;

  const { service, systems, recipes } = buildingActions(building);
  const publishedRecipes = building.id === 'survey_post' ? [] : recipes;
  const actions = building.status === 'implemented'
    ? [
      ...(!building.unlockedAtStart ? [actionForSlug('build-foundation')] : []),
      ...actionsForStation(building.id),
    ].filter((action): action is NonNullable<typeof action> => Boolean(action))
    : [];
  const bundledResearch = content.researchNodes.filter((node) => node.constructionBundledWith === building.id);
  const resourceIDs = [...new Set([
    ...building.buildCost.map((cost) => cost.id ?? cost.resource ?? cost.resourceID),
    ...publishedRecipes.flatMap((recipe) => recipe.ingredients.map((ingredient) => ingredient.resourceID)),
  ].filter((id): id is string => Boolean(id)))];
  const resourceLinks = resourceIDs
    .map((id) => content.resources.find((resource) => resource.id === id))
    .filter((resource): resource is (typeof content.resources)[number] => Boolean(resource));

  return <SiteFrame sidebar>
    <GuideBreadcrumbs items={[{ label: 'Village', href: '/village' }, { label: building.name }]} />
    <PageIntro eyebrow={buildingStatus(building)} title={building.name} summary={building.blurb} />
    <SeptemberDecisions topic={['blacksmith', 'apothecary', 'tannery'].includes(building.id) ? 'crafting' : 'progression'} />

    {(building.assetURL || building.contextAssetURL) && <section className="article-section place-visuals" aria-label={`${building.name} Village visual`}>
      {building.assetURL && <figure className="place-visual place-building"><img src={building.assetURL} alt={`${building.name} building visual`} /><figcaption>The current building visual for {building.name}.</figcaption></figure>}
      {building.contextAssetURL && <figure className="place-visual place-context"><img src={building.contextAssetURL} alt={`${villageLocation(building.zone)} Village setting`} /><figcaption>The {villageLocation(building.zone)} setting around {building.name}.</figcaption></figure>}
    </section>}

    {building.status === 'scheduled' ? <section className="article-section note-card">
      <h2>Planned</h2>
      <p>This place is part of the intended Village but is not available to visit or build yet. The description below explains what it is planned to add without presenting future actions or rewards as playable now.</p>
    </section> : <>
      <section className="article-section">
        <h2>Access and foundation</h2>
        <dl className="fact-grid">
          <div><dt>Village area</dt><dd>{villageLocation(building.zone)}</dd></div>
          <div><dt>Where to find it</dt><dd>{humanize(building.route)}</dd></div>
          <div><dt>When usable</dt><dd>{building.unlockedAtStart ? 'Available at the start of a campaign' : building.keeper ? <>Meet <Link href={`/people/${building.keeperID?.replaceAll('_', '-')}`}>{building.keeper}</Link>, then complete the foundation</> : 'Available after its listed requirement is complete'}</dd></div>
          <div><dt>Keeper</dt><dd>{building.keeper ? <Link href={`/people/${building.keeperID?.replaceAll('_', '-')}`}>{building.keeper}</Link> : 'No resident keeper'}</dd></div>
          <div><dt>Construction cost</dt><dd>{buildCost(building)}</dd></div>
        </dl>
        {building.id === 'blacksmith' ? <p>Halloway will raise a forge here when you bring iron and fibre for the work.</p> : building.buildBlurb && <p>{building.buildBlurb}</p>}
      </section>

      <section className="article-section">
        <h2>What this facility currently offers</h2>
        {service ? <div className="definition-grid">{service.useFor.map((entry) => <div key={entry}>{entry}</div>)}</div> : systems.length ? <div className="definition-grid">{systems.map((system) => <div key={system.slug}><h3><Link href={`/crafting/${system.slug}`}>{system.name}</Link></h3><p>{system.summary}</p></div>)}</div> : <p>This facility does not currently offer a separate service or crafting action.</p>}
      </section>

      {service && <>
        <section className="article-section"><h2>How to use it</h2><ol className="numbered-guide">{service.workflow.map((step) => <li key={step}>{step}</li>)}</ol></section>
        <section className="article-section two-column"><div><h2>Choose what to work with</h2><p>{service.selection}</p></div><div><h2>After you confirm</h2><p>{service.result}</p></div></section>
        <section className="article-section"><h2>Worth remembering</h2><div className="definition-grid">{service.remember.map((entry) => <div key={entry}>{entry}</div>)}</div></section>
      </>}

      {actions.length > 0 && <section className="article-section"><h2>Current actions here</h2><div className="definition-grid">{actions.map((action) => <div key={action.id}><h3><Link href={`/actions/${action.slug}`}>{action.name}</Link></h3><p>{action.availability}</p><small>{action.unavailable}</small></div>)}</div></section>}

      <section className="article-section">
        <h2>Current crafting and Research</h2>
        {publishedRecipes.length ? <div className="table-wrap"><table><thead><tr><th>Recipe</th><th>Output</th><th>Ingredients</th><th>Ready when</th></tr></thead><tbody>{publishedRecipes.map((recipe) => {
          const item = content.items.find((entry) => entry.name === recipe.result);
          const outputHref = item ? (item.gear ? `/equipment/${item.slug}` : `/items/${item.slug}`) : null;
          return <tr key={recipe.id}><td><Link href={`/crafting/${recipe.system}`}>{recipe.name}</Link></td><td>{outputHref ? <Link href={outputHref}>{recipe.result}</Link> : recipe.result}</td><td>{recipeRequirements(recipe)}</td><td>{recipeReadiness(recipe)}</td></tr>;
        })}</tbody></table></div> : building.id === 'survey_post' ? <p>Field Instruments are permanent Research skills rather than crafted objects. Paid precision improvements are planned, but will not be listed as available until the game can show their complete cost and result before confirmation.</p> : <p>This facility does not currently offer a crafting recipe.</p>}
        {bundledResearch.length > 0 && <p>{bundledResearch.map((node, index) => <span key={node.id}>{index ? ' · ' : ''}<Link href={`/research/${researchNodeSlug(node)}`}>{node.name}</Link> — {node.blurb}</span>)}</p>}
      </section>

      {systems.length > 0 && <section className="article-section two-column"><div><h2>Material choices</h2>{systems.map((system) => <p key={system.slug}><strong><Link href={`/crafting/${system.slug}`}>{system.name}:</Link></strong> {system.materialChoice}</p>)}</div><div><h2>Finished result and storage</h2>{systems.map((system) => <p key={system.slug}>{system.commitResult}</p>)}</div></section>}

      {building.id === 'apothecary' && <><section className="article-section"><h2>First remedy: Nessa to Lesser Salve</h2><p>Recruit <Link href="/people/nessa">Nessa</Link> to reveal the foundation. Your first Apothecary journey is:</p><ol className="numbered-guide">{apothecaryFirstUse.journey.map((step) => <li key={step}>{step}</li>)}</ol><div className="definition-grid"><div><h3>Build bundle</h3><p>{apothecaryFirstUse.construction}</p><p>Construction teaches Lesser Salve but gives no prepared item.</p></div><div><h3>First preparation</h3><p>{apothecaryFirstUse.firstRecipe}</p><p>The chosen material and Resin are used only after preparation succeeds.</p></div></div></section><section className="article-section two-column"><div><h2>Check what you have</h2><ul className="compact-list">{apothecaryFirstUse.shortfalls.map((line) => <li key={line}>{line}</li>)}</ul><p>{apothecaryFirstUse.inference}</p></div><div><h2>What this does and does not change</h2><ul className="compact-list">{apothecaryFirstUse.boundaries.map((line) => <li key={line}>{line}</li>)}</ul><p>{apothecaryFirstUse.catalogueBoundary}</p></div></section><section className="article-section note-card"><h2>Preparation costs are separate from construction</h2><ul className="compact-list">{apothecaryFirstUse.costs.map((line) => <li key={line}>{line}</li>)}</ul></section></>}

      {building.id === 'blacksmith' && <><section className="article-section"><h2>Third opening find: Halloway to Pointed Blade</h2><p>After <Link href="/people/halloway">Halloway</Link> joins the Village, her foundation appears in Home → Make. Her current request is: <em>“{blacksmithFirstUse.correctedRequest}”</em></p><ol className="numbered-guide">{blacksmithFirstUse.journey.map((step) => <li key={step}>{step}</li>)}</ol></section><section className="article-section two-column"><div><h2>Pointed Blade stays specific</h2><ul className="compact-list">{blacksmithFirstUse.pointedBlade.map((line) => <li key={line}>{line}</li>)}</ul><p>{blacksmithFirstUse.stockBoundary}</p></div><div><h2>Reforge one selected piece</h2><ul className="compact-list">{blacksmithFirstUse.reforgeBoundary.map((line) => <li key={line}>{line}</li>)}</ul></div></section><section className="article-section note-card"><h2>Storage and relaunch</h2><ul className="compact-list">{blacksmithFirstUse.refusalAndRelaunch.map((line) => <li key={line}>{line}</li>)}</ul></section></>}

      {building.id === 'anchorage' && <><section className="article-section"><h2>First anchored realm: Tovin and the Atlas Seam</h2><p>Recruit <Link href="/people/tovin">Tovin</Link> to reveal this foundation in Home → Realms. Its complete construction cost is <strong>{anchorageFirstAnchor.construction}</strong>; completion opens the realm list and Anchor Frame construction, but gives no realm or Frame.</p><ol className="numbered-guide">{anchorageFirstAnchor.journey.map((step) => <li key={step}>{step}</li>)}</ol></section><section className="article-section two-column"><div><h2>Where the Frame is kept</h2><ul className="compact-list">{anchorageFirstAnchor.frameCustody.map((line) => <li key={line}>{line}</li>)}</ul></div><div><h2>Confirm the Atlas Seam</h2><ul className="compact-list">{anchorageFirstAnchor.seamConfirmation.map((line) => <li key={line}>{line}</li>)}</ul></div></section><section className="article-section note-card"><h2>What the first anchor does not start</h2><ul className="compact-list">{anchorageFirstAnchor.firstRealm.map((line) => <li key={line}>{line}</li>)}</ul><h3>After closing and reopening the game</h3><ul className="compact-list">{anchorageFirstAnchor.relaunch.map((line) => <li key={line}>{line}</li>)}</ul></section></>}

      {building.id === 'recycler' && <section className="article-section"><h2>First use with Noll</h2><p>Recruit <Link href="/people/noll">Noll</Link>, then build the Recycler for <strong>{recyclerFirstUse.buildCost}</strong>. The completed bench previews recovery; it does not grant gear, resources, a recipe, or a Field Separation Kit.</p><div className="definition-grid"><div><h3>Honest empty state</h3><p>{recyclerFirstUse.emptyState}</p></div><div><h3>Before the irreversible choice</h3><p>{recyclerFirstUse.zeroOutput}</p></div></div><ul className="compact-list">{recyclerFirstUse.boundaries.map((line) => <li key={line}>{line}</li>)}</ul><p><Link href="/recycling">Read the Recycler return and protection reference</Link></p></section>}

      {building.id === 'survey_post' && <><section className="article-section"><h2>First reading: Mara to Survey</h2><p>Recruit <Link href="/people/mara">Mara</Link> to reveal this foundation in Home → Study. Its complete construction cost is <strong>{surveyPostFirstUse.construction}</strong>; building it opens Field Instruments research but grants no instrument, material, observation, map disclosure, or field action.</p><ol className="numbered-guide">{surveyPostFirstUse.journey.map((step) => <li key={step}>{step}</li>)}</ol></section><section className="article-section two-column"><div><h2>Eight permanent skills</h2><p>Studying an instrument permanently teaches its named subject at Crude precision. Its Research preview shows the price you will pay.</p><ul className="compact-list">{surveyPostFirstUse.instruments.map(([id, name, subject, cost]) => <li key={id}><strong>{name}</strong> · {subject} · {cost}</li>)}</ul></div><div><h2>Pack, then Survey</h2><ul className="compact-list">{surveyPostFirstUse.loadoutAndSurvey.map((line) => <li key={line}>{line}</li>)}</ul></div></section><section className="article-section note-card"><h2>If something changes or the game closes</h2><ul className="compact-list">{surveyPostFirstUse.refusalAndRelaunch.map((line) => <li key={line}>{line}</li>)}</ul><h3>Precision improvement is planned</h3><ul className="compact-list">{surveyPostFirstUse.improvementBoundary.map((line) => <li key={line}>{line}</li>)}</ul></section></>}

      {building.id === 'library' && <><section className="article-section"><h2>Library collections</h2><div className="definition-grid"><div><h3>Diaries</h3><p>Read recovered diary pages as they were written. Any lesson attached to a page appears with it.</p></div><div><h3>People</h3><p>Each person’s page keeps all of their currently available book pages together, with location clues clearly marked as spoilers.</p></div><div><h3>Dictionary</h3><p>Review known Sigils and Compounds. Unknown meanings remain unknown until they are learned.</p></div><div><h3>Notes and History</h3><p>Return to recovered notes and the history of worlds you have visited.</p></div></div></section><section className="article-section two-column"><div><h2>How records become useful</h2><p>A diary page may contain a clue about a person or teach something directly. The Dictionary keeps the writing vocabulary you have learned, while Notes and History preserve discoveries you can revisit.</p></div><div className="note-card"><h3>Research and records</h3><p>Some diary pages point toward a Research lead. Open that Research entry and check its requirements before preparing the next step.</p><p><Link href="/research">Open Research</Link></p></div></section><section className="article-section note-card"><h2>People and their books</h2><p>Use each person’s page to read all of their currently available book pages. Location clues are separated and clearly marked so you can avoid spoilers.</p><p><Link href="/people">Browse people and their books</Link></p></section></>}
    </>}

    <section className="article-section"><h2>Related materials and next steps</h2>{resourceLinks.length ? <p>{resourceLinks.map((resource, index) => <span key={resource.id}>{index ? ' · ' : ''}<Link href={`/resources/${resource.slug}`}>{resource.name}</Link></span>)}</p> : <p>This entry does not currently use a listed material.</p>}<p><Link href="/resources/progression">Open the current progression checklist</Link></p></section>
    <RelatedGuides links={[
      { label: 'Village', href: '/village' },
      ...(actions.length ? [{ label: 'Action reference', href: '/actions' }] : []),
      ...systems.map((system) => ({ label: system.name, href: `/crafting/${system.slug}` })),
      ...(service?.relatedGuides ?? []),
      ...(building.id === 'library' ? [{ label: 'People and complete records', href: '/people' }, { label: 'Bestiary', href: '/bestiary' }] : []),
      ...(building.id === 'trading_post' ? [{ label: 'Economy and exchange', href: '/trading' }] : []),
      ...(building.id === 'recycler' ? [{ label: 'Recycler returns', href: '/recycling' }] : []),
      ...(building.id === 'apothecary' ? [{ label: 'Nessa', href: '/people/nessa' }, { label: 'Lesser Salve', href: '/items/salve-lesser' }] : []),
      ...(building.id === 'blacksmith' ? [{ label: 'Halloway', href: '/people/halloway' }, { label: 'Equipment', href: '/equipment' }] : []),
      ...(building.id === 'anchorage' ? [{ label: 'Tovin', href: '/people/tovin' }, { label: 'Atlas Seam', href: '/sites/atlas-seam' }] : []),
      { label: 'Resources', href: '/resources' },
    ]} />
  </SiteFrame>;
}
