import Link from '@/components/wiki-link';
import { GuideBreadcrumbs } from '@/components/guide-navigation';
import { PageIntro } from '@/components/page-intro';
import { SiteFrame } from '@/components/site-frame';

export default function LootAndMaterialsPage() {
  return <SiteFrame sidebar>
    <GuideBreadcrumbs items={[{ label: 'Reference', href: '/resources' }, { label: 'Loot & materials' }]} />
    <PageIntro eyebrow="Player guide route" title="Loot & materials" summary="Loot, material identity, quality, return, and custody now have one canonical overview so the same rules are not repeated across two pages." />
    <section className="article-section note-card">
      <h2>Continue to Resources</h2>
      <p>The Resources page starts with a visual index, follows with an at-a-glance consumer table, and then explains loot routes, material identity, quality, and custody at the appropriate depth.</p>
      <p><Link href="/resources#loot-and-custody">Open Resources at Loot, return, and custody</Link></p>
    </section>
  </SiteFrame>;
}
