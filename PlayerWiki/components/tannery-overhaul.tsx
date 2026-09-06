import Link from '@/components/wiki-link';

export function TanneryOverhaul() {
  return <section className="article-section note-card">
    <h2>The complete Tannery first-pass plan</h2>
    <p><strong>Current behavior:</strong> early textiles, woven garments, Leather Guard and carrying improvements have reported implementations. The complete replacement below is not yet delivered.</p>
    <p><strong>Retained decisions:</strong> useful woven clothing before Ingots or Leather, no ordinary crafting Essence fee, real material colour and quality, and pack capacity of 8→11→14→23 plus Sela’s separate 2.</p>
    <p><strong>New Design-authored first-pass plan:</strong> mix actual Fibre strands and sections in Cord/Cloth; dress one Skin or Hide plus Salt into one Leather; choose Leather panels independently. Three clothing families contain seven variants, with consistent component prices, recovery and ordinary refit. Existing owned materials and garments keep their saved values and properties.</p>
    <p><Link href="/references/crafting-shop-overhaul">Read every Tannery recipe, garment and carrying rule</Link>.</p>
  </section>;
}
