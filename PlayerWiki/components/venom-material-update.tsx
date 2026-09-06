import Link from '@/components/wiki-link';

export function VenomMaterialUpdate() {
  return <section className="article-section note-card">
    <h2>Venom material update</h2>
    <p><strong>Current behavior:</strong> Venom and its legacy Poison-coating recipe already exist. The new Plant Fibre compatibility update is ready for implementation, but is not delivered.</p>
    <p><strong>Decided intended behavior:</strong> At the built Apothecary, with Venom known, use 1 Stem or Leaf Fibre, 1 legacy Toxin, and 1 separate existing reactive world resource with Reactivity 55 or higher to make 1 Venom coating for 0 Essence. Every ingredient is spent separately. Legacy recipes remain available under their own rules.</p>
    <p>The coating keeps its appearance, existing Poison effect and ordinary 5 Gold sell value. Stronger or higher-quality ingredients do not strengthen it. Legacy Toxin is not converted into a new named substance, and finished Venom is not a recipe ingredient.</p>
    <p><strong>Still unfinished:</strong> Fully naming the toxic ingredients and any replacement for the separate reactive resource. Those changes are outside this ready adapter. <Link href="/references/design-decisions-september-4">Read the exact preparation and custody rules</Link>.</p>
  </section>;
}
