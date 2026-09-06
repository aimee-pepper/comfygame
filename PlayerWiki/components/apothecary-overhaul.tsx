import Link from '@/components/wiki-link';

export function ApothecaryOverhaul() {
  return <section className="article-section note-card">
    <h2>The complete Apothecary overhaul</h2>
    <p><strong>Current behavior — delivered in phone build322:</strong> all 19 preparations use their complete recognizable-ingredient recipes, with acquisition learning, actual named plant/mineral sources, source colour/Pattern, storage and preparation history. Ordinary preparations cost no Essence; Stillwater and Waystone keep their stated supernatural costs.</p>
    <p>All four coatings stay on their exact weapon for one full excursion, including hits, encounters and reopening. Ending the excursion ends the preparation; individual afflictions keep their own durations. The former one-strike lifetime is superseded.</p>
    <p>Engineering reports the build installed and ordinarily launched on 6 September, with 39 focused tests and four native routes passed. The separately labelled legacy recipe route supports older stock; the older ingredient lists elsewhere are compatibility references. Mixed Cord/Cloth and advanced Forge/tool dependencies are included, while the full Tannery garment/refit and broader equipment-composition work remain pending.</p>
    <p><Link href="/references/crafting-shop-overhaul">See all 19 recipes and the shop-by-shop plan</Link>.</p>
  </section>;
}
