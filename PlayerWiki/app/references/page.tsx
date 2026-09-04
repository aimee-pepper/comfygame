import Link from '@/components/wiki-link';
import { GuideBreadcrumbs } from '@/components/guide-navigation';
import { PageIntro } from '@/components/page-intro';
import { SiteFrame } from '@/components/site-frame';
import { designReferences } from '@/lib/design-references';

export default function ReferencesPage() {
  const characterReference = designReferences.find((reference) => reference.slug === 'character-background-and-voice');
  const clueReference = designReferences.find((reference) => reference.slug === 'rewritten-world-clues');
  const resourceReferences = designReferences.filter((reference) => !['character-background-and-voice', 'rewritten-world-clues'].includes(reference.slug));

  return <SiteFrame sidebar>
    <GuideBreadcrumbs items={[{ label: 'Home', href: '/' }, { label: 'Aimee Reference' }]} />
    <PageIntro eyebrow="Project reference" title="Aimee Reference" summary="A clearly labelled home for Aimee's system plans, implementation roadmaps, and visual production references." />
    <section className="article-section note-card">
      <h2>Asset Homework</h2>
      <p>A running hand-authoring list for spare moments: bright and dark sky studies, cloud shapes, the Library books in progress, and clear status for final export specifications.</p>
      <Link href="/references/asset-homework">Open Asset Homework</Link>
    </section>
    <section className="article-section note-card" aria-labelledby="screen-authoring-map-heading">
      <h2 id="screen-authoring-map-heading">Screen Authoring Map</h2>
      <p>See the complete in-game screen hierarchy as a colour-coded tree: Aimee-authored compositions, implemented Asset/Engineering updates, partial or asset-ready work, and screens still using default UI.</p>
      <nav aria-label="Screen Authoring Map reference">
        <Link href="/references/screen-authoring-map">Open the Screen Authoring Map</Link>
      </nav>
    </section>
    <section className="article-section note-card" aria-labelledby="asset-splash-list-heading">
      <h2 id="asset-splash-list-heading">World Splash Asset Inventory</h2>
      <p>Read the normal Wiki page for the final five-layer parallax inventory, its completeness audit, the world varieties the recovered list does not yet cover, and the prescribed expansion.</p>
      <nav aria-label="Asset Splash List reference">
        <Link href="/references/world-splash-assets">Open the World Splash Asset Inventory</Link>
      </nav>
      <p><small>This is a planning and art-production reference, not a claim that unfinished world variants are already playable.</small></p>
    </section>
    {characterReference ? <section className="article-section note-card" aria-labelledby="character-background-voice-heading">
      <h2 id="character-background-voice-heading">Character Background and Voice Guide</h2>
      <p>Review the settled background, personality, speaking style, and clue-writing boundaries for every traveller before their world clues are rewritten.</p>
      <nav aria-label="Character Background and Voice reference">
        <Link href={`/references/${characterReference.slug}`}>Open the Character Background and Voice Guide</Link>
      </nav>
    </section> : null}
    {clueReference ? <section className="article-section note-card" aria-labelledby="rewritten-world-clues-heading">
      <h2 id="rewritten-world-clues-heading">Rewritten World Clues</h2>
      <p>Read all 137 proposed location clues in their verified character voices, plus the correction that turns Tovin's one-off Isolde clue into a normal relationship page. This copy is ready for review but is not yet implemented in the game.</p>
      <nav aria-label="Rewritten World Clues reference">
        <Link href={`/references/${clueReference.slug}`}>Open the Rewritten World Clues</Link>
      </nav>
    </section> : null}
    <section className="article-section" aria-labelledby="resource-crafting-plans-heading">
      <h2 id="resource-crafting-plans-heading">Resource, crafting, and generated-world plans</h2>
      <p>Each page contains its complete authored plan, clearly marked open decisions, and implementation order. Related subject pages remain linked beneath the plan for deeper current-game reference.</p>
      <div className="topic-grid">
        {resourceReferences.map((reference) => <Link className="topic-card" href={`/references/${reference.slug}`} key={reference.slug}><span><strong>{reference.title}</strong><small>{reference.summary}</small></span></Link>)}
      </div>
    </section>
  </SiteFrame>;
}
