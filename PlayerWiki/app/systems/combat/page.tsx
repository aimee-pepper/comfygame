import Link from 'next/link';
import { PageIntro } from '@/components/page-intro';
import { SiteFrame } from '@/components/site-frame';

export default function Combat() {
  return <SiteFrame sidebar><PageIntro eyebrow="System guide" title="Combat" summary="Encounters are turn-based decisions between the party and one or more foes. Choose a target, match the action to its defences, and keep the party healthy enough to finish or withdraw." />
    <section className="article-section"><h2>Your four main actions</h2><dl className="definition-grid"><div><dt>Attack</dt><dd>Use the acting character’s equipped weapon against an eligible foe.</dd></div><div><dt>Techniques</dt><dd>Choose a learned technique and any target it requires.</dd></div><div><dt>Item</dt><dd>Use an eligible combat supply on the exact ally or foe named by the item.</dd></div><div><dt>Withdraw</dt><dd>Attempt to leave the encounter when the current combat state allows it.</dd></div></dl></section>
    <section className="article-section two-column"><div><h2>Damage and defences</h2><p>Weapons identify a damage type and reach. Foe armour, resistances, position, and the acting character’s state can change whether an action is useful or available. Read the target cards before committing.</p></div><div><h2>Gambits</h2><p>Gambits are ordered rules for automated party decisions. A condition—such as an armour threshold—selects an action only when its exact requirement is true. Higher rules take priority.</p></div></section>
    <section className="article-section"><h2>Defeat</h2><p>Defeat ends the active expedition and resolves its return outcome. The durable campaign continues: review what was recovered, prepare again in the Village, and Bind a new world when ready.</p></section>
    <nav className="next-links"><Link href="/equipment">Compare equipment</Link><Link href="/consumables">Combat supplies</Link></nav>
  </SiteFrame>;
}
