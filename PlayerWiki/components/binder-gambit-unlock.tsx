import Link from '@/components/wiki-link';

export function BinderGambitUnlock() {
  return <section className="article-section note-card">
    <h2>The Binder’s own Gambits</h2>
    <p><strong>Current availability:</strong> If you have not unlocked Binder automation, your turns are manual. Opening Party does not grant this ability. Existing unlocked campaigns keep it. The replacement teaching below is not yet verified as delivered; the old Workshop wording does not establish an available route.</p>
    <p><strong>Decided intended behavior:</strong> Self-automation is earned. Recover <em>Let your own rules run</em> in a world, then read it in the Library. Reading unlocks the Binder’s ability to follow Gambits without writing a rule or changing any rule’s enabled state. Party uses what you have learned; it does not teach the ability.</p>
    <p><strong>First-pass timing:</strong> The current plan makes this later instruction eligible after Binder level 8, eight resolved expeditions, and all three opening Gambit teachings: Check yourself, Leave the fight, and Use your skill. These timing values can change during progression tuning.</p>
    <p><Link href="/references/design-decisions-september-4">Read the current design decisions</Link> · <Link href="/buildings/library">Library</Link></p>
  </section>;
}
