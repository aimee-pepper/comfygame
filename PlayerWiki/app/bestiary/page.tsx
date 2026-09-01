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
          <h2>Use the in-game record first</h2>
          <p>The Bestiary in your campaign records encountered families and specimens. This reference never marks a creature as discovered for your own save.</p>
        </div>
        <div>
          <h2>Read the field before acting</h2>
          <p>Use Look and the active encounter presentation for the exact tile and creature in front of the party.</p>
          <p><Link href="/systems/exploration">Open Exploration</Link> · <Link href="/systems/combat">Open Combat</Link></p>
        </div>
      </section>
      <section className="article-section">
        <h2>Current named encounter profiles</h2>
        <p>These profiles describe the current named encounter types. World conditions influence whether a profile can appear; they never promise an encounter in a particular world.</p>
        <div className="table-wrap data-table"><table><thead><tr><th>Creature</th><th>Field profile</th><th>Combat</th></tr></thead><tbody>{content.creatures.map((creature) => <tr key={creature.id}><td><Link href={`/bestiary/${creature.slug}`}>{creature.name}</Link></td><td>{creature.isNocturnal ? 'Night profile' : 'Day profile'} · Sight {creature.sightRadius}</td><td>Tier {creature.tier} · {creature.maxHP} health · {creature.attack} attack</td></tr>)}</tbody></table></div>
      </section>
      <section className="article-section">
        <h2>Companionship stays individual</h2>
        <p>Animal attendance is decided by the exact visible individual in an active world. This directory does not promise that a named encounter profile is tameable or reveal a specimen’s current trust state.</p>
        <p><Link href="/systems/animals-companionship">Read Animals and companionship</Link></p>
      </section>
      <section className="article-section">
        <h2>Typical record flow</h2>
        <ol className="numbered-guide">{guide.workflow.map((step) => <li key={step}>{step}</li>)}</ol>
      </section>
      <RelatedGuides links={[{ label: 'Bestiary service guide', href: '/services/bestiary' }, { label: 'Combat guide', href: '/systems/combat' }, { label: 'Exploration guide', href: '/systems/exploration' }, { label: 'Animals and companionship', href: '/systems/animals-companionship' }, { label: 'All systems', href: '/systems' }]} />
    </SiteFrame>
  );
}
