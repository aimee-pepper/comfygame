import Link from '@/components/wiki-link';

export function SolidDeposits() {
  return <section className="article-section note-card">
    <h2>Solid deposits and mining</h2>
    <p><strong>Current behavior:</strong> blocking deposits and deliberate adjacent mining are implemented. For the temporary recording setup in build344, newly generated ordinary 2D worlds omit Iron, Coal, Quartz, Sulfur, Mercury and Rift Glass deposits. Existing worlds and stock, the requested 3D trial, Clay, Salt and plant gathers retain their supported behavior. A written Iron guarantee that cannot be fulfilled is refused before spending.</p>
    <p><strong>Decided intended behavior:</strong> Substantial deposits and boulders block their physical base. With the required packed Pick selected, deliberately step toward an adjacent harvestable deposit to mine it. A successful hit takes one world turn and keeps you beside it. The final hit clears its base; your next step enters the cleared square normally.</p>
    <p>A missing, wrong or insufficient tool spends no mining turn and takes no material. Automatic routes go around deposits or stop; they never mine or switch tools for you. Small loose stones, herbs and low gathering patches stay walkable, with their existing gathering or pickup actions.</p>
    <p>Deposits can create detours and opened shortcuts. The route home, starter resources and tool access stay protected, with a reachable place to stand beside required deposits. You will not need an Iron Pick to reach your only starter Iron. Deliberately tool-gated areas come later.</p>
    <p><Link href="/references/design-decisions-september-4">Read the full mining decision and early source rules</Link></p>
  </section>;
}
