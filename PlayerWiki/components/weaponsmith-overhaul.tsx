import Link from '@/components/wiki-link';

export function WeaponsmithOverhaul() {
  return <section className="article-section note-card">
    <h2>The complete Weaponsmith first pass</h2>
    <p><strong>Current behavior — delivered in build328:</strong> Maud’s foundation costs 40 Essence, 4 Ingots, 2 Hafts and 2 Cord. It includes Point, Edge, Maul, both fittings and ordinary refit. Polearm still needs Maud’s diary pattern.</p>
    <p><strong>Retained decisions:</strong> three Close damage families and a Mid Polearm with an explicit damage choice and Maud’s existing diary-teaching requirement. No wearer lock, ammunition or repair chore.</p>
    <p><strong>Delivered choices:</strong> actual Hafts, Iron or source-preserving Bone Collars, zero-Essence crafting/refit, and Balanced (+1 Initiative) or Driving (+0.75 Power). Home fitting adjustments use the same parts at no cost. Review shows exact stats, price and returned components; recovery returns only attached parts, preserving prepared Collars and Hafts. All six damage/reach choices retain excursion-long coatings.</p>
    <p><Link href="/references/crafting-shop-overhaul">Read every Weaponsmith recipe, fitting and producer</Link>.</p>
  </section>;
}
