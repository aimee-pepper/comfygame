import Link from '@/components/wiki-link';

export function CarryingProgression() {
  return <section className="article-section note-card">
    <h2>Room for the next journey</h2>
    <p><strong>Decided intended behavior:</strong> The first two pack projects belong to the opening Storehouse. Corrin makes the larger expansion once the Tannery is built. These are upcoming changes; the current costs and services below remain current until the update arrives.</p>
    <table><thead><tr><th>Pack project</th><th>Where</th><th>First-pass cost</th><th>Spaces before Sela</th></tr></thead><tbody>
      <tr><td>Opening pack</td><td>Already owned</td><td>Free</td><td>8</td></tr>
      <tr><td>Reinforced Stitching</td><td>Storehouse</td><td>5 Essence, 4 Plant Fibre</td><td>11</td></tr>
      <tr><td>Balanced Straps</td><td>Storehouse, after Stitching</td><td>10 Essence, 6 Plant Fibre, 1 Resin</td><td>14</td></tr>
      <tr><td>Deepened Satchel</td><td>Corrin, after both projects</td><td>20 Essence, 2 Plant Cloth, 2 Plant Cord, 1 Resin</td><td>23</td></tr>
    </tbody></table>
    <p>Carry opens with the Tannery, without another paid lesson. Leather, Ingots and later shop upgrades are optional paths. Sela’s built Wayfarer’s Table adds its separate <strong>2 spaces</strong> at any stage, for a final <strong>25</strong>. Its intended foundation costs 30 Essence, 6 Logs and 4 Plant Fibre after she joins.</p>
    <p>Older purchased capacity is preserved without granting the same benefit twice. Materials remain slot-free, harvesting tools keep their own roll, and your packing choices stay yours. Home shelving is separate and keeps all nine existing improvements. The earlier proposed 20-space pack ceiling has been replaced.</p>
    <p><strong>Tested in development:</strong> The two Storehouse projects reach 14 spaces and survive reopening. An arranged opening campaign then paid 10 Essence for its next Bind, entering with 14 spaces and 15 Essence remaining. Separate native checks saved Corrin’s expansion to 23, then Sela’s bonus to 25 after reopening. These checks preserve previous purchases and active expedition contents; the increased capacity applies at the next packing boundary.</p>
    <p><strong>Still to test:</strong> Full natural gathering and later affordability, and phone delivery. These prices are starting balance values, not a required shopping list. The separate Woven Gloves and Boots recipes now pass native crafting and recovery checks too, without requiring the pack projects.</p>
    <p><Link href="/references/design-decisions-september-4">Full decisions, woven equipment and recipes</Link></p>
  </section>;
}
