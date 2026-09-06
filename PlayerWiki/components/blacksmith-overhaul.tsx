import Link from '@/components/wiki-link';

export function BlacksmithOverhaul() {
  return <section className="article-section note-card">
    <h2>The complete Forge first-pass plan</h2>
    <p><strong>Current behavior:</strong> early raw-Iron gear, level-2 tool improvements and T2 ingots have reported implementations. The full new shop plan is not yet delivered.</p>
    <p><strong>Retained decisions:</strong> stone opening tools, raw-material starter gear before ingots, real component identity and separate workmanship/statistics.</p>
    <p><strong>New Design-authored first-pass plan:</strong> T1–T3, all three level-3 tools, seven equipment families and one coherent Pick route, Bone/metal/Quartz/wood choices, consistent value, component recovery and deterministic refit. Pick 2 supplies the Quartz needed to reach Pick 3 and Rift-glass. Existing owned items retain their saved stats and prices.</p>
    <p><Link href="/references/crafting-shop-overhaul">Read all Forge recipes, material choices and progression</Link>.</p>
  </section>;
}
