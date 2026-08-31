import Link from 'next/link';
import { PageIntro } from '@/components/page-intro';
import { SiteFrame } from '@/components/site-frame';

export default function Crafting() {
  return <SiteFrame sidebar><PageIntro eyebrow="System guide" title="Crafting and materials" summary="Returned resources support construction, supplies, equipment, research, and station work. Recipes describe the base object; its materials determine many of the useful differences." />
    <section className="article-section"><h2>Where crafting happens</h2><div className="step-grid"><article><span>1</span><h3>Choose a station</h3><p>Different stations own different recipes: medicine, metalwork, recycling, preparation, and other specialist work.</p></article><article><span>2</span><h3>Review exact stock</h3><p>The action uses the quantities and materials shown when the recipe is prepared.</p></article><article><span>3</span><h3>Commit the result</h3><p>Resources are consumed only when the station accepts and completes the exact recipe.</p></article></div></section>
    <section className="article-section two-column"><div><h2>Material effects</h2><p>Material choice can change an item’s combat values, durability, reactivity, or other properties. The item tables show the finished catalogue entries; resource pages show where each material tends to appear.</p><p><Link href="/resources">Browse resources</Link></p></div><div><h2>Construction</h2><p>Village buildings unlock services and new preparation options. Construction costs are listed on each Place page so you can plan a return haul around the next useful build.</p><p><Link href="/places">Browse places and stations</Link></p></div></section>
    <section className="article-section"><h2>Other useful stations</h2><ul><li><strong>Recycler:</strong> dismantles eligible gear into a previewed yield.</li><li><strong>Research:</strong> spends the shown cost to unlock a selected node.</li><li><strong>Trading Post:</strong> buys and sells eligible stock using the current listing and quantity.</li><li><strong>Firepit:</strong> manages who is travelling with the party and who remains at home.</li></ul></section>
    <nav className="next-links"><Link href="/resources">Resource table</Link><Link href="/equipment">Equipment table</Link></nav>
  </SiteFrame>;
}
