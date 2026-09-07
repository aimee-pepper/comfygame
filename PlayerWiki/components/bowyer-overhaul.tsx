import Link from '@/components/wiki-link';

export function BowyerOverhaul() {
  return <section className="article-section note-card">
    <h2>The complete Bowyer first pass</h2>
    <p><strong>Current behavior — delivered in build 325:</strong> Fen’s built Bowyer includes Longbow (Pierce/Far), Sling (Crush/Far), Throwing Set (Rend/Far), and refitting. Its base foundation costs 30 Essence, 6 Logs, 2 Cord and 2 Resin. Crafting and refitting cost no Essence.</p>
    <p>Choose actual points, shot or two independent throwing edges, with the required wood and textile or Leather supports. Review shows the resulting Power, workmanship, price and components. Refitting keeps the same weapon and returns displaced attached parts; recovery returns current components once. These weapons use no ammunition inventory and retain excursion-long coatings.</p>
    <p>Once Maud teaches the recipes, one Softwood or Hardwood Log becomes one matching Haft at the Bowyer for no Essence. It keeps its original wood colour and sells for 1 Gold or buys for 2. Longbow limbs still use Hardwood Logs.</p>
    <p><Link href="/references/crafting-shop-overhaul">Read all Bowyer recipes, values and progression</Link>.</p>
  </section>;
}
