import Link from '@/components/wiki-link';

export function ArmouryOverhaul() {
  return <section className="article-section note-card">
    <h2>The complete Armoury first-pass plan</h2>
    <p><strong>Current behavior:</strong> protective rebuilds exist with earlier material and grade rules. The full typed-material replacement is pending implementation.</p>
    <p><strong>Retained decisions:</strong> rebuild the same ordinary protective piece. Rigid and Balanced support all five protective slots; Insulated supports Head, Body, Hands and Feet, excluding shields.</p>
    <p><strong>New Design-authored first-pass plan:</strong> 14 complete profile/slot choices, a 35-Essence foundation plus prepared materials, no ordinary rebuild/refit Essence fee, and explicit Protection/Heat Ward tradeoffs. Linings count once; returned old components cannot be refunded again from history.</p>
    <p><Link href="/references/crafting-shop-overhaul">Read all Armoury materials, values and mixed-loadout examples</Link>.</p>
  </section>;
}
