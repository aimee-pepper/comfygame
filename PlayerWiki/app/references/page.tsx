import { ExternalLink } from 'lucide-react';
import Link from '@/components/wiki-link';
import { GuideBreadcrumbs } from '@/components/guide-navigation';
import { PageIntro } from '@/components/page-intro';
import { SiteFrame } from '@/components/site-frame';
import { designReferences } from '@/lib/design-references';

const basePath = (process.env.NEXT_PUBLIC_BASE_PATH ?? '').replace(/\/+$/, '');
const assetSplashListHref = `${basePath}/reference-assets/world-splash-five-layer-inventory-v1.html`;
export default function ReferencesPage() {
  return <SiteFrame sidebar>
    <GuideBreadcrumbs items={[{ label: 'Home', href: '/' }, { label: 'References' }]} />
    <PageIntro eyebrow="Review references" title="References for Aimee" summary="Working visual inventories and review surfaces kept together for quick access." />
    <section className="article-section note-card" aria-labelledby="asset-splash-list-heading">
      <h2 id="asset-splash-list-heading">Asset Splash List</h2>
      <p>Open the five-layer World Splash asset inventory, including every required asset family and the locked moving/static layer split.</p>
      <nav aria-label="Asset Splash List reference">
        <a href={assetSplashListHref}>Open the Asset Splash List <ExternalLink size={14} aria-hidden="true" /></a>
      </nav>
      <p><small>This is a review reference, not player-facing game authority.</small></p>
    </section>
    <section className="article-section" aria-labelledby="resource-crafting-plans-heading">
      <h2 id="resource-crafting-plans-heading">Resource, crafting, and generated-world plans</h2>
      <p>Read these three complete plans as normal Wiki pages. They preserve Aimee's accepted direction, clearly marked open decisions, and the incremental implementation order.</p>
      <div className="topic-grid">
        {designReferences.map((reference) => <Link className="topic-card" href={`/references/${reference.slug}`} key={reference.slug}><span><strong>{reference.title}</strong><small>{reference.summary}</small></span></Link>)}
      </div>
    </section>
  </SiteFrame>;
}
