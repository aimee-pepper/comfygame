import Link from '@/components/wiki-link';

export function BlacksmithOverhaul() {
  return <section className="article-section note-card">
    <h2>The complete first Forge pass</h2>
    <p><strong>Current behavior — delivered in phone build324:</strong> Pointed Blade, Cutting Blade, Hand Maul and Shield open at T1; Long Spear, Helm, Rigid Guard and refitting at T2. These are seven equipment families. Pick remains the same owned tool; smelting/T3 and Pick/Axe/Scythe progression came in build322.</p>
    <p>Exact world-material and typed Bone components determine the result. Workmanship remains separate from quarter-precision Power/Protection. New prices use frozen component values, and same-item refit returns displaced current parts once. Coal is spent fuel, not a recoverable component.</p>
    <p>Bone source measurements, colour/Pattern and history remain with actual rewards through Return and trading. There is no extra Bone recovery roll or generic duplicate; unsupported older property-only services cannot consume new Bone.</p>
    <p>Engineering reports build324 installed and ordinarily launched on 6 September, with 16 distinct focused/native checks passed. Build325 also delivers the Forge presentation: clearly labelled part choices, numbered source pieces, and a review separating the result, returned parts and attached parts. Prices and crafting rules are unchanged. Iron Collar and later specialist batches remain pending.</p>
    <p><Link href="/references/crafting-shop-overhaul">Read all current Forge recipes, material choices and progression</Link>.</p>
  </section>;
}
