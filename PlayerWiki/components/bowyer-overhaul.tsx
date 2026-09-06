import Link from '@/components/wiki-link';

export function BowyerOverhaul() {
  return <section className="article-section note-card">
    <h2>The complete Bowyer first-pass plan</h2>
    <p><strong>Current behavior:</strong> Longbow, Sling and Throwing Set have existing crafting definitions and a native shop screen. The new whole-shop replacement is not yet implemented.</p>
    <p><strong>Retained decisions:</strong> three physical Far families—Pierce, Crush and Rend—with no ammunition inventory or replenishment chore.</p>
    <p><strong>New Design-authored first-pass plan:</strong> hardwood bow limbs, actual points and edges, prepared Cord and Cloth/Leather supports; all three recipes and refit included in Fen’s 30-Essence foundation. Ordinary crafting costs no Essence. The complete plan supplies Power, workmanship, prices, recovery and shared excursion-long coatings while preserving owned legacy weapons.</p>
    <p><Link href="/references/crafting-shop-overhaul">Read all Bowyer recipes, values and progression</Link>.</p>
  </section>;
}
