import Link from '@/components/wiki-link';

export function TanneryOverhaul() {
  return <section className="article-section note-card">
    <h2>The complete first Tannery pass</h2>
    <p><strong>Current behavior — delivered in phone build323:</strong> one eligible Skin or Hide plus Salt makes one Leather. All seven garment variants use exact selected components, with independent Leather panels and no crafting Essence fee. Mixed Cord/Cloth retains each actual source strand or section.</p>
    <p>Free ordinary refit/remake keeps the same item. Recovery returns only its currently attached components once; prepared Leather does not also return raw Hide or Salt. New item prices use those actual components, while older receipts keep their saved values. Carry remains 8→11→14→23 plus Sela’s separate 2.</p>
    <p>Ordered source-colour swatches now appear in stock, review and equipment details; unknown RGB stays unknown, and known Leather colour facts remain visible. Equipment comparisons preserve fractional Protection. Engineering reports the build installed and ordinarily launched on 6 September, with 47 focused checks and three native routes passed.</p>
    <p><strong>Still proposed:</strong> additional creature-material roles and remaining specialist makers are separate work. The first Forge equipment/Bone pass is delivered separately in build324.</p>
    <p><Link href="/references/crafting-shop-overhaul">Read every current Tannery recipe, garment and carrying rule</Link>.</p>
  </section>;
}
