import Link from '@/components/wiki-link';
import { GuideBreadcrumbs, RelatedGuides } from '@/components/guide-navigation';
import { PageIntro } from '@/components/page-intro';
import { SiteFrame } from '@/components/site-frame';
import { TruthPair } from '@/components/truth-pair';
import { creatureMaterialFamilies, lootPaths, qualityBands, worldMaterialFamilies } from '@/lib/player-guide-status';

export default function LootAndMaterialsPage() {
  return <SiteFrame sidebar>
    <GuideBreadcrumbs items={[{ label: 'Reference', href: '/resources' }, { label: 'Loot & materials' }]} />
    <PageIntro eyebrow="Player guide" title="Loot & materials" summary="See what can return from a world, where it goes, and which parts of the material system are changing in a future update." />
    <section className="article-section">
      <h2>The important distinction</h2>
      <TruthPair current="World resources are mostly counted reserves. Creature and other physical materials can still be separate source-bearing samples. Return, trading, crafting, and recycling therefore do not all present stock in the same way." accepted="A creature or harvest produces the correct physical material from the start. Different physical materials stay distinct, while different species do not create needless item types. Quality creates separate stacks within a real material family." />
    </section>
    <section className="article-section">
      <h2>Where loot comes from</h2>
      <div className="status-card-grid">{lootPaths.map((path) => <article className="status-card" key={path.name}><h3>{path.name}</h3><TruthPair current={path.current} accepted={path.accepted} /></article>)}</div>
    </section>
    <section className="article-section">
      <h2>The approved family list</h2>
      <p>This list describes the accepted future material model. It does not claim that the current build has already migrated your stock.</p>
      <div className="definition-grid"><div><h3>World materials</h3><p>{worldMaterialFamilies.map(([name]) => name).join(' · ')}</p></div><div><h3>Creature materials</h3><p>{creatureMaterialFamilies.map(([name]) => name).join(' · ')}</p></div><div><h3>Quality</h3><p>{qualityBands.join(' · ')}</p><p>Each quality band is its own stack. The game chooses the lowest eligible band by default and never silently spends a better one.</p></div><div><h3>Source history</h3><p>A family stack may remember which creatures or places contributed to it. That history can be inspected, but it does not fragment the stack.</p></div></div>
    </section>
    <section className="article-section note-card"><h2>What stays separate</h2><p>Items, equipment, Pages, Curios, placed sites, Raw Essence, Motes, and authored guardian rewards keep their own identities. A depleted site remains part of its world’s history. Gold material is also separate from Gold Coins.</p></section>
    <RelatedGuides links={[{ label: 'Resources', href: '/resources' }, { label: 'Crafting systems', href: '/crafting' }, { label: 'Expedition Return', href: '/systems/expedition-return' }, { label: 'Trading offers', href: '/trading' }, { label: 'Recycler returns', href: '/recycling' }, { label: "What's changing", href: '/guide-status' }]} />
  </SiteFrame>;
}
