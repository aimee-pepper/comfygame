import Link from '@/components/wiki-link';
import { GuideBreadcrumbs, RelatedGuides } from '@/components/guide-navigation';
import { PageIntro } from '@/components/page-intro';
import { SiteFrame } from '@/components/site-frame';

export default function MenageriePage() {
  return (
    <SiteFrame sidebar>
      <GuideBreadcrumbs items={[{ label: 'Village', href: '/village' }, { label: 'Places and stations', href: '/places' }, { label: 'Menagerie' }]} />
      <PageIntro
        eyebrow="Animal companions"
        title="Menagerie"
        summary="The Home posting for joined animal companions and the place associated with learning Attend."
      />
      <section className="article-section">
        <h2>Current player relationship</h2>
        <p>Recruit Sabine and build the Menagerie to learn Attend. A joined animal rests here until you assign it to the travelling party, and a travelling animal returns here when its expedition ends.</p>
        <p><Link href="/systems/animals-companionship">Read the complete Animals and companionship guide</Link> before relying on eligibility, trust, party placement, or return behavior.</p>
      </section>
      <section className="article-section note-card">
        <h2>What this page does not invent</h2>
        <p><strong>Planned:</strong> the Menagerie’s artwork, foundation cost, and individual actions have not been finalized for players yet. They will be added here once those parts are ready for the game.</p>
      </section>
      <RelatedGuides links={[{ label: 'Animals and companionship', href: '/systems/animals-companionship' }, { label: 'Attend an animal', href: '/actions/attend-animal' }, { label: 'Bestiary records', href: '/bestiary' }, { label: 'Party preparation', href: '/systems/party-preparation' }]} />
    </SiteFrame>
  );
}
