import Link from 'next/link';
import { GuideBreadcrumbs, RelatedGuides } from '@/components/guide-navigation';
import { PageIntro } from '@/components/page-intro';
import { PixelImage } from '@/components/pixel-image';
import { SiteFrame } from '@/components/site-frame';
import content from '@/data/player-content.json';

export default function Combat() {
  const weapon = content.items.find((item) => item.gear?.slot === 'weapon' && item.assetURL);
  const guard = content.items.find((item) => item.gear?.slot === 'armor' && item.assetURL);
  const traveller = content.travellers.find((person) => person.assetURL);

  return <SiteFrame sidebar><GuideBreadcrumbs items={[{ label: 'Systems', href: '/systems' }, { label: 'Combat' }]} /><PageIntro eyebrow="System guide" title="Combat" summary="Encounters are turn-based decisions between the party and one or more foes. Choose a target, match the action to its defences, and keep the party healthy enough to finish or withdraw." />
    <section className="article-section combat-reference"><h2>Read the encounter</h2><p>The live encounter screen puts the acting party member, their equipped weapon, and defensive gear beside the target cards. These current references make it easier to recognise the details worth reading before you commit.</p><div className="combat-reference-strip">
      {traveller && <Link className="combat-reference-card" href={`/people/${traveller.slug}`}><PixelImage src={traveller.assetURL} alt={`${traveller.name} character visual`} size={48} /><span><strong>Party member</strong>{traveller.name}</span></Link>}
      {weapon && <Link className="combat-reference-card" href={`/equipment/${weapon.slug}`}><PixelImage src={weapon.assetURL} alt={`${weapon.name} weapon visual`} size={48} /><span><strong>Weapon</strong>{weapon.name}</span></Link>}
      {guard && <Link className="combat-reference-card" href={`/equipment/${guard.slug}`}><PixelImage src={guard.assetURL} alt={`${guard.name} protective gear visual`} size={48} /><span><strong>Protection</strong>{guard.name}</span></Link>}
    </div></section>
    <section className="article-section"><h2>Your four main actions</h2><dl className="definition-grid"><div><dt>Attack</dt><dd>Use the acting character’s equipped weapon against an eligible foe.</dd></div><div><dt>Techniques</dt><dd>Choose a learned technique and any target it requires.</dd></div><div><dt>Item</dt><dd>Use an eligible combat supply on the exact ally or foe named by the item.</dd></div><div><dt>Withdraw</dt><dd>Attempt to leave the encounter when the current combat state allows it.</dd></div></dl></section>
    <section className="article-section two-column"><div><h2>Damage and defences</h2><p>Weapons identify a damage type and reach. Foe armour, resistances, position, and the acting character’s state can change whether an action is useful or available. Read the target cards before committing.</p></div><div><h2>Gambits</h2><p>Gambits are ordered rules for automated party decisions. A condition—such as an armour threshold—selects an action only when its exact requirement is true. Higher rules take priority.</p></div></section>
    <section className="article-section"><h2>Defeat</h2><p>Defeat ends the active expedition and resolves its return outcome. The durable campaign continues: review what was recovered, prepare again in the Village, and Bind a new world when ready.</p></section>
    <RelatedGuides links={[{ label: 'Party, Gear and Gambits', href: '/services/party-and-gear' }, { label: 'Compare equipment', href: '/equipment' }, { label: 'Combat supplies', href: '/consumables' }, { label: 'All systems', href: '/systems' }]} />
  </SiteFrame>;
}
