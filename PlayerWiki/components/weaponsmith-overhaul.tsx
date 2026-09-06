import Link from '@/components/wiki-link';

export function WeaponsmithOverhaul() {
  return <section className="article-section note-card">
    <h2>The complete Weaponsmith first-pass plan</h2>
    <p><strong>Current behavior:</strong> older fitted-weapon recipes use broad material families and earlier crafting calculations. The complete new replacement is pending implementation.</p>
    <p><strong>Retained decisions:</strong> three Close damage families and a Mid Polearm with an explicit damage choice and Maud’s existing diary-teaching requirement. No wearer lock, ammunition or repair chore.</p>
    <p><strong>New Design-authored first-pass plan:</strong> real Hafts and Collars, a 40-Essence foundation plus prepared materials, zero-Essence ordinary crafting/refit, and a choice of Balanced (+1 Initiative) or Driving (+0.75 Power). Complete recipes, source-based workmanship, values, recovery and legacy preservation are specified together.</p>
    <p><Link href="/references/crafting-shop-overhaul">Read every Weaponsmith recipe, fitting and producer</Link>.</p>
  </section>;
}
