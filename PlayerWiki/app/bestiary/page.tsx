import Link from 'next/link';
import { GuideBreadcrumbs, RelatedGuides } from '@/components/guide-navigation';
import { PageIntro } from '@/components/page-intro';
import { PixelImage } from '@/components/pixel-image';
import { SiteFrame } from '@/components/site-frame';
import { content } from '@/lib/content';
import { serviceForSlug } from '@/lib/services';

export default function BestiaryPage() {
  const guide = serviceForSlug('bestiary');
  const station = content.stations.find((entry) => entry.id === 'bestiary');
  if (!guide || !station) return null;
  const visualURL = station.assetURL ?? station.contextAssetURL;
  const visualLabel = station.assetURL
    ? `${station.name} building visual`
    : `${station.zone} town setting`;

  return (
    <SiteFrame sidebar>
      <GuideBreadcrumbs items={[{ label: 'Systems', href: '/systems' }, { label: 'Bestiary' }]} />
      <div className="entity-heading">
        <PixelImage src={visualURL} alt={visualLabel} size={96} />
        <PageIntro eyebrow="World records" title="Bestiary" summary={guide.summary} />
      </div>
      <p className="service-visual-note">The current retained building visual for {station.name}.</p>
      <section className="article-section two-column">
        <div>
          <h2>What you can browse in game</h2>
          <ul>
            {guide.useFor.map((item) => <li key={item}>{item}</li>)}
          </ul>
        </div>
        <div>
          <h2>Keep encounters readable</h2>
          <p>Use the Combat guide to read the active encounter, and the Exploration guide to inspect the world before moving onto an exact tile.</p>
          <p><Link href="/systems/combat">Open Combat</Link> · <Link href="/systems/exploration">Open Exploration</Link></p>
        </div>
      </section>
      <section className="article-section note-card bestiary-empty-state">
        <h2>Individual records</h2>
        <p>No individual creature record is currently published to this Player Wiki. The in-game Bestiary remains the place to review species and observed individuals after discovery, without revealing unseen creatures here.</p>
      </section>
      <section className="article-section">
        <h2>Typical record flow</h2>
        <ol className="numbered-guide">
          {guide.workflow.map((step) => <li key={step}>{step}</li>)}
        </ol>
      </section>
      <RelatedGuides links={[{ label: 'Bestiary service guide', href: '/services/bestiary' }, { label: 'Combat guide', href: '/systems/combat' }, { label: 'Exploration guide', href: '/systems/exploration' }, { label: 'All systems', href: '/systems' }]} />
    </SiteFrame>
  );
}
