import Link from '@/components/wiki-link';
import { GuideBreadcrumbs } from '@/components/guide-navigation';
import { PageIntro } from '@/components/page-intro';
import { SiteFrame } from '@/components/site-frame';
import { designReferences } from '@/lib/design-references';

export default function ReferencesPage() {
  return <SiteFrame sidebar>
    <GuideBreadcrumbs items={[{ label: 'Home', href: '/' }, { label: 'Aimee Reference' }]} />
    <PageIntro eyebrow="Project reference" title="Aimee Reference" summary="A clearly labelled home for Aimee's system plans, implementation roadmaps, and visual production references." />
    <section className="article-section note-card" aria-labelledby="asset-splash-list-heading">
      <h2 id="asset-splash-list-heading">World Splash Asset Inventory</h2>
      <p>Read the normal Wiki page for the final five-layer parallax inventory, its completeness audit, the world varieties the recovered list does not yet cover, and the prescribed expansion.</p>
      <nav aria-label="Asset Splash List reference">
        <Link href="/references/world-splash-assets">Open the World Splash Asset Inventory</Link>
      </nav>
      <p><small>This is a planning and art-production reference, not a claim that unfinished world variants are already playable.</small></p>
    </section>
    <section className="article-section" aria-labelledby="resource-crafting-plans-heading">
      <h2 id="resource-crafting-plans-heading">Resource, crafting, and generated-world plans</h2>
      <p>Use these plans for the accepted direction, clearly marked open decisions, and implementation order. Player-facing system details live on their existing Wiki pages instead of being repeated here.</p>
      <div className="topic-grid">
        {designReferences.map((reference) => <Link className="topic-card" href={`/references/${reference.slug}`} key={reference.slug}><span><strong>{reference.title}</strong><small>{reference.summary}</small></span></Link>)}
      </div>
    </section>
  </SiteFrame>;
}
