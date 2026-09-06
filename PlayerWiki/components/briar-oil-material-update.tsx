import Link from '@/components/wiki-link';

export function BriarOilMaterialUpdate() {
  return <section className="article-section note-card">
    <h2>Briar Oil material update</h2>
    <p><strong>Current behavior:</strong> Briar Oil and its older recipe already exist. The new material compatibility update is specified, but has not been implemented or delivered.</p>
    <p><strong>Decided intended behavior:</strong> At the built Apothecary, with the recipe known, use 1 Stem or Leaf Fibre, 1 Resin, and 1 separate existing flexible world resource with Flexibility 50 or higher to make 1 Briar Oil for 0 Essence. Two new Fibre portions and Resin alone do not satisfy that third requirement. Legacy preparation choices keep their existing rules.</p>
    <p>The coating keeps its familiar appearance, existing Bleed effect and ordinary 5 Gold sell value. Preparing it does not pack it automatically. Ingredient quality or colour does not strengthen the coating.</p>
    <p><strong>Unsettled later proposal:</strong> A fully new-material recipe using 2 Plant Fibre and 1 Resin. This is separate from the ready compatibility update. <Link href="/references/design-decisions-september-4">Read the exact material and use rules</Link>.</p>
  </section>;
}
