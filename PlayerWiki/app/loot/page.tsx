import Link from '@/components/wiki-link';
import { GuideBreadcrumbs, RelatedGuides } from '@/components/guide-navigation';
import { PageIntro } from '@/components/page-intro';
import { SiteFrame } from '@/components/site-frame';
import { TruthPair } from '@/components/truth-pair';
import { lootPaths, qualityBands } from '@/lib/player-guide-status';
import { canonicalStackExample, materialIdentityHierarchy } from '@/lib/crafting-overview';

export default function LootAndMaterialsPage() {
  return <SiteFrame sidebar>
    <GuideBreadcrumbs items={[{ label: 'Reference', href: '/resources' }, { label: 'Loot & materials' }]} />
    <PageIntro eyebrow="Player guide" title="Loot & materials" summary="See what can return from a world, where it goes, and which parts of the material system are changing in a future update." />
    <section className="article-section">
      <h2>The important distinction</h2>
      <TruthPair current="World resources are mostly counted reserves. Creature and other physical materials can still be separate source-bearing samples. Return, trading, crafting, and recycling therefore do not all present stock in the same way." accepted="A creature or harvest produces a recognizable physical type or precise subtype. Matching species variants share a type-and-quality stack; expanding it reveals species, source world, inherited colour, quantity, and contribution values." acceptedLabel="Intended design" />
    </section>
    <section className="article-section">
      <h2>Where loot comes from</h2>
      <div className="status-card-grid">{lootPaths.map((path) => <article className="status-card" key={path.name}><h3>{path.name}</h3><TruthPair current={path.current} accepted={path.accepted} /></article>)}</div>
    </section>
    <section className="article-section">
      <h2>The intended material hierarchy</h2>
      <p>The structure is settled, but the complete catalogue still requires design with Aimee.</p>
      <div className="table-wrap"><table><thead><tr><th>Level</th><th>Example</th><th>Use</th></tr></thead><tbody>{materialIdentityHierarchy.map(([level, example, use]) => <tr key={level}><td><strong>{level}</strong></td><td>{example}</td><td>{use}</td></tr>)}</tbody></table></div>
      <div className="definition-grid"><div><h3>Resource quality</h3><p>{qualityBands.join(' · ')}</p><p>Each quality is its own stack. When quality affects the result, the player chooses the exact stack.</p></div><div><h3>Example stack</h3><p><strong>{canonicalStackExample}</strong></p><p>Species and colour remain inspectable inside it.</p></div></div>
    </section>
    <section className="article-section note-card"><h2>What stays separate</h2><p>Items, equipment, Pages, Curios, placed sites, Raw Essence, Motes, and authored guardian rewards keep their own identities. A depleted site remains part of its world’s history. Gold material is also separate from Gold Coins.</p></section>
    <RelatedGuides links={[{ label: 'Resources', href: '/resources' }, { label: 'Crafting systems', href: '/crafting' }, { label: 'Expedition Return', href: '/systems/expedition-return' }, { label: 'Trading offers', href: '/trading' }, { label: 'Recycler returns', href: '/recycling' }, { label: "What's changing", href: '/guide-status' }]} />
  </SiteFrame>;
}
