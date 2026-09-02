import Link from '@/components/wiki-link';
import { GuideBreadcrumbs, RelatedGuides } from '@/components/guide-navigation';
import { PageIntro } from '@/components/page-intro';
import { PixelImage } from '@/components/pixel-image';
import { SiteFrame } from '@/components/site-frame';
import { TruthPair } from '@/components/truth-pair';
import { content } from '@/lib/content';
import { creatureMaterialPropertyDerivations, materialScoreBoundary } from '@/lib/crafting-overview';
import { creatureMaterialFamilies } from '@/lib/player-guide-status';
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
        <h2>Individual records stay private</h2>
        <p>Animal attendance is decided by the exact visible individual in an active world. This directory does not promise that a named encounter profile is tameable or reveal a specimen’s current trust state.</p>
        <p><Link href="/systems/animals-companionship">Read Animals and companionship</Link></p>
      </section>
      <section className="article-section">
        <h2>Creature materials inherit real anatomy</h2>
        <TruthPair current="Generated creature drops already calculate their six material properties from the defeated creature’s saved covering, skeleton, armament, finish, and emanation. The current family list and grade model are older and incomplete, but the property values are not arbitrary labels." accepted="The canonical family, type, and subtype decide which recipe socket accepts the material. Its inherited numerical properties then contribute to concrete item statistics, while its four-band quality controls the strength of those contributions." acceptedLabel="Intended design" />
        <div className="table-wrap"><table><thead><tr><th>Material property</th><th>Current creature-derived calculation</th></tr></thead><tbody>{creatureMaterialPropertyDerivations.map(([property, calculation]) => <tr key={property}><td><strong>{property}</strong></td><td>{calculation}</td></tr>)}</tbody></table></div>
        <p className="note-card"><strong>Quality is separate:</strong> {materialScoreBoundary.currentGrade}</p>
      </section>
      <section className="article-section"><h2>Intended physical material families</h2><p>Generated species can still leave species-specific items, colours, values, and histories. Those units sit inside recognizable physical families and subtypes so recipes can ask for Scales, Fish Scales, or Armoured Fish Scales without requiring one named species.</p><div className="table-wrap"><table><thead><tr><th>Family</th><th>Physical meaning</th></tr></thead><tbody>{creatureMaterialFamilies.map(([family, meaning]) => <tr key={family}><td><strong>{family}</strong></td><td>{meaning}</td></tr>)}</tbody></table></div></section>
      <section className="article-section">
        <h2>Typical record flow</h2>
        <ol className="numbered-guide">{guide.workflow.map((step) => <li key={step}>{step}</li>)}</ol>
      </section>
      <RelatedGuides links={[{ label: 'Bestiary service guide', href: '/services/bestiary' }, { label: 'Combat guide', href: '/systems/combat' }, { label: 'Exploration guide', href: '/systems/exploration' }, { label: 'Animals and companionship', href: '/systems/animals-companionship' }, { label: 'All systems', href: '/systems' }]} />
    </SiteFrame>
  );
}
