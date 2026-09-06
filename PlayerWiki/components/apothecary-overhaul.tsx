import Link from '@/components/wiki-link';

export function ApothecaryOverhaul() {
  return <section className="article-section note-card">
    <h2>The complete Apothecary overhaul</h2>
    <p><strong>Current behavior:</strong> Lesser Salve has its new Plant Fibre recipe. Briar Oil’s new Fibre and Resin choices are reported delivered in phone build 310, with a separate flexible material still required. Venom’s ingredient update is not implemented. Existing coatings are still used up by a successful strike.</p>
    <p><strong>Decided intended behavior:</strong> recognizable ingredients, ordinary preparations without Essence fees, and all four weapon coatings lasting one excursion on their chosen weapon.</p>
    <p><strong>Proposed changes:</strong> all 19 recipes are being revised together, including remedies, coatings and field supplies. The older recipes shown here remain useful current references; they are not the final overhaul.</p>
    <p><Link href="/references/crafting-shop-overhaul">See all 19 recipes and the shop-by-shop plan</Link>.</p>
  </section>;
}
