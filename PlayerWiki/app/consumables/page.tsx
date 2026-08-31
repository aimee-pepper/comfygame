import Link from 'next/link';
import { PageIntro } from '@/components/page-intro';
import { PixelImage } from '@/components/pixel-image';
import { SiteFrame } from '@/components/site-frame';
import { craftingRecipes, systemFor } from '@/lib/crafting';
import { consumableDuration, consumableEffect, consumableTarget, consumableValue, consumables, humanize } from '@/lib/content';

const recipeFor = (name: string) => craftingRecipes.find((recipe) => recipe.result === name);

export default function ConsumablesPage() {
  return <SiteFrame sidebar><PageIntro eyebrow="Reference" title="Consumables" summary="Plan identified supplies for the next Field Kit at home, then inspect one carried item for its exact effect and legal target before committing use." />
    <section className="article-section note-card"><h2>Carry and use</h2><p>Preparing a supply does not automatically pack it. Choose its quantity in the next Field Kit plan, review any shortage before departure, then select the carried item in the world. Cancelling, closing the detail, or losing the shown target does not complete the use.</p></section>
    <p className="catalogue-guidance">Select an item image or name to open its full entry.</p>
    <div className="table-wrap data-table catalogue-summary"><table><thead><tr><th aria-label="Image" /><th>Item</th><th>Rarity</th><th>Effect</th><th>Target</th><th>Value / duration</th><th>Current recipe route</th></tr></thead><tbody>{consumables.map(item => { const recipe = recipeFor(item.name); const system = recipe ? systemFor(recipe.system) : null; return <tr key={item.id}><td><Link href={`/items/${item.slug}`} aria-label={`Open ${item.name}`}><PixelImage src={item.assetURL} alt={`${item.name} icon`} /></Link></td><td><Link href={`/items/${item.slug}`}>{item.name}</Link><small>{item.summary}</small></td><td>{humanize(item.rarity)}</td><td>{consumableEffect(item)}</td><td>{consumableTarget(item)}</td><td>{consumableDuration(item) !== 'No duration listed' ? consumableDuration(item) : consumableValue(item, 'potency')}</td><td>{recipe && system ? <><Link href={`/crafting/${recipe.system}`}>{system.station}</Link><small>{recipe.name}</small></> : 'No current recipe published'}</td></tr>; })}</tbody></table></div>
  </SiteFrame>;
}
