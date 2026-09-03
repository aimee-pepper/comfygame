import Link from '@/components/wiki-link';
import { DirectoryDetailsIntro, DirectoryIndex } from '@/components/directory-navigation';
import { PageIntro } from '@/components/page-intro';
import { PixelImage } from '@/components/pixel-image';
import { SiteFrame } from '@/components/site-frame';
import { craftingRecipes, systemFor } from '@/lib/crafting';
import { curios, humanize } from '@/lib/content';

const recipeFor = (name: string) => craftingRecipes.find((recipe) => recipe.result === name);

export default function CuriosPage() {
  return <SiteFrame sidebar><PageIntro eyebrow="Reference" title="Curios and key items" summary="These named objects are neither ordinary equipment nor ordinary consumables. Use the detail page for the current recipe route or its exact named station, world, or custody route." />
    <DirectoryIndex label="Browse known curios and key items" entries={curios.map((item) => ({ href: `/items/${item.slug}`, name: item.name, imageURL: item.assetURL, imageAlt: `${item.name} icon` }))} />
    <DirectoryDetailsIntro title="Compare known items" summary="Use this compact comparison for kind, rarity, current route, and custody; each item page holds the complete entry." />
    <p className="catalogue-guidance">Select an item image or name to open its full entry.</p>
    <div className="table-wrap data-table catalogue-summary"><table><thead><tr><th aria-label="Image" /><th>Known item</th><th>Kind</th><th>Rarity</th><th>Current route</th><th>Custody</th></tr></thead><tbody>{curios.map(item => { const recipe = recipeFor(item.name); const system = recipe ? systemFor(recipe.system) : null; return <tr key={item.id}><td><Link href={`/items/${item.slug}`} aria-label={`Open ${item.name}`}><PixelImage src={item.assetURL} alt={`${item.name} icon`} /></Link></td><td><Link href={`/items/${item.slug}`}>{item.name}</Link><small>{item.summary}</small></td><td>{humanize(item.category)}</td><td>{humanize(item.rarity)}</td><td>{recipe && system ? <><Link href={`/crafting/${recipe.system}`}>{system.station}</Link><small>{recipe.name}</small></> : 'Open the exact named route'}</td><td>{item.tradingPostDisposition === 'sellable' ? 'Identified and transferable' : 'Protected from ordinary sale'}</td></tr>; })}</tbody></table></div>
    <section className="article-section note-card"><h2>Rules shared by curios: Keep unknown results unknown</h2><p>This index lists named objects you already know. An unidentified curio is not labelled with its future result: study one safely at Home, use one Solvent on a carried unknown, or try it only when the world or combat screen offers a valid context. Cancel and an unavailable context leave it unresolved.</p></section>
  </SiteFrame>;
}
